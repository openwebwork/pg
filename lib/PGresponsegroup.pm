################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/lib/PGresponsegroup.pm,v 1.2 2010/05/25 22:13:52 gage Exp $
# 
# This program is free software; you can redistribute it and/or modify it under
# the terms of either: (a) the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version, or (b) the "Artistic License" which comes with this package.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
# Artistic License for more details.
################################################################################
package PGresponsegroup;

use strict;
use Exporter;
use PGUtil  qw(not_null) ;
use PGanswergroup;
use Tie::IxHash;

#############################################
# An object which contains the student response(s)
# 1. needs to be able to hold one or more responses
# 2. needs space for auxiliary answer labels
#      for example all of the entries in an array
# 3. needs to coordinate answer labels with the PGanswergroup holding it
#    We'll accomplish this by having it point to it's enclosing answergroup
# 4. may have additional methods for processing and storing response strings
#      the responses for radio buttons should be of the form   response_label=>[button1, button2, button3,  ...]
# 5. should be called with at least one label, response pair
# 6. By convention the first response usually has the same label as the parent answergroup.
#    This is always true if there is only a single response.
#############################################
our @ISA= qw(PGanswergroup);

###
# new ( label, response, label, response)
#
# create a new empty response group object
# Optionally append label/response pairs
###
sub new {
	my $class = shift;
	my $answergroup_label = shift;
	my $self = {
	    answergroup_label  => $answergroup_label,    # enclosing answergroup that created this responsegroup
		response_order     => [],         # response labels
		responses          => {},         # response label/response value pair, 
		                             # value could be an arrayref in the case of radio or checkbox groups        
	};
	bless $self, $class;
	$self->append_responses(@_);
	return $self;
		
}
###############
# append_response (label, response)
#
# Append label/response pairs to the response hash.
# order is recorded in the response_order array
###############

sub append_response{

	my $self = shift;
	my $response_label = shift;
	my $response_value =shift;
	if (not_null($response_label) ) {
		if (not exists ($self->{responses}->{$response_label}) ) {
			push @{ $self->{response_order}} , $response_label;
			$self->{responses}->{$response_label} = $response_value;
		} else {
			$self->internal_debug_message( "PGresponsegroup::append_response error: there is already an answer labeled $response_label", caller(2),"\n");
		}
	} else {
		    $self->internal_debug_message(  "PGresponsegroup::append_response error: undefined or empty response label");
	}
	#warn "\n content of responses  is ",join(' ',%{$self->{responses}});
}

###############
# append_response (label, response, label, responses)
#
# Append label/response pairs to the response hash.
# order is recorded in the response_order array
###############

sub append_responses {   #no error checking
	my $self = shift;
	my @response_list  = @_;
	#warn "working with @response_list,", caller(2);
	while (@response_list) {
		$self->append_response(shift @response_list , shift @response_list);
	}
}

################
# replace_response(label, response)
#
# replace the response to one response label entry
################
sub replace_response {
	my $self = shift;
	my $response_label = shift;
	my $response_value = shift;
	if (defined $self->{responses}->{$response_label}) {  
		$self->{responses}->{$response_label}=$response_value if defined $response_value;
		return $self->{responses}->{$response_label};
	} else {
		warn "response label |$response_label| not defined" ;
		return undef;
    }
}
################
# extend_response(label, response)
#
# extend the annonymous response to one response label entry  -- used for check boxes and radio buttons
################
sub extend_response {
	my $self = shift;
	my $response_label = shift;
	my $new_value_key  = shift;
	my $selected       = shift;
	if (defined $self->{responses}->{$response_label}) {  
		my $response_value = $self->{responses}->{$response_label};		
		!defined($response_value) && do{ $response_value = {} };
		ref($response_value) !~/HASH/ && do{ 
		            $self->internal_debug_message("PGresponsegroup::extend_response: error in storing hash ", ref($response_value),$response_value);
		            $response_value = {$response_value=>$selected};
		          }; 
		    #should not happen this means that a non-hash entry was made into this response label
		    # this converts it to a hash entry		     
		$response_value->{$new_value_key} =  $selected;
		$self->{responses}->{$response_label} = $response_value;
		return $response_value;  
		# a hash of key/value pairs -- the key labels the radio button or checkbox, 
		# the value whether it is selected
	} else {
		$self->internal_debug_message("PGresponsegroup::extend_response: response label |$response_label| not defined") ;
		return undef;
    }
	
}
################
# get_response(label)
#
# returns  response for that label entry
################
sub get_response {
	my $self = shift;
	my $response_label = shift;
	$self->{responses}->{$response_label};
}
sub get_answergroup_label {
	my $self = shift;
	if ( ! not_null ($self->{answergroup_label}) ) { #if $answergroup is not yet defined
		$self->{answergroup_label} = ${$self->{response_order}}[0];
	}
	if ( not_null ($self->{answergroup_label}) ) { #if $answergroup is now defined
		return $self->{answergroup_label};
	} else {
		warn "This answer group has no labeled responses.";
	}
}

	

		

################
# clear()
#
# sets PGresponse group to empty
################
sub clear {
	my $self = shift;
	$self->{response_order}=[];
	$self->{responses} ={};
}
################
# response_labels()
#
# returns entry ordered list of response labels
################


sub response_labels {
	my $self = shift;
	@{$self->{response_order}};
}

################
#values()
#
# returns entry ordered list of response values
################

sub values {
	my $self = shift;
	my @out = ();
	foreach my $key ( @{$self->{response_order}} ) {
		push @out, $self->get_response($key);
	}
	@out;
}
# synonym for values
sub responses {
    my $self = shift;
	$self->values(@_);
}

sub data {
	my $self = shift;
	return { %$self };
}
1;
