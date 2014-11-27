################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/lib/PGanswergroup.pm,v 1.1 2010/05/14 11:39:02 gage Exp $
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
package PGanswergroup;
use Exporter;
use PGUtil qw(not_null);
use PGresponsegroup;

our @ISA=qw(PGcore);

#############################################
# An object which contains an answer label and 
# an answer evaluator 
# and the links to and contents of all associated answer blanks
# (i.e the student responses)
#############################################
# Notes
# Answergroup -- input to a single answerEvaluator, may have several answer blanks
#    for example an array or a radio button group or several checkboxes
# 1. create a answerEvaluator label name
# 2. provide space for an answerEvaluator
# 3. indicate that an answer blank or blanks has been published to receive the responses
# for example store the number of response strings associated with this answerEvaluator label name
# 4. space for the contents of the responses is provided in the PGresponse group
# 5. provide a method for applying the evaluator to the responses
#
# use Tie: IxHash??? to create ordered hash? (see Perl Cookbook)

sub new {
	my $class = shift;	
	my $label = shift;
	my $self = {
	    ans_label => $label,
		ans_eval  => undef,                         # usually an AnswerEvaluator, sometimes a CODE
		response  => new PGresponsegroup($label),    # A PGresponse object which holds the responses 
		                                            # which make up the answer
		active    => 1,                             # whether this answer group is currently active (for multistate problems)

		@_,
	};
	bless $self, $class;	
	return $self;

}

sub evaluate {     # applies the answer evaluator to the student response and returns an answer hash



}

sub complete {    # test to see if answer evaluator and appropriate response blanks are all present



}
sub ans_eval {
	my $self = shift;
	my $ans_eval = shift;
	$self->{ans_eval}= $ans_eval if ref($ans_eval);
	$self->{ans_eval};
}
sub append_responses { #add or modify a response to the PGresponsegroup object
	my $self = shift;
	my @response_list = @_;  # ordered list of label/ value pairs
    $self->{response}->append_responses(@response_list);		
}

sub insert_responses    {        # add a group of responses ( label/value pairs)
	my $self = shift;
	my @response_list = @_;
	$self->{response}->clear();
	$self->{response}->append_responses(@response_list);
}

sub insert_response_value { # add a response value(with  label defined by answer group label)
	my $self = shift;
	my $value = shift;
	$self->{response}->append_reponse($self->{ans_label}, $value);
}
sub replace_response { # add a response value(with  label defined by answer group label)
	my $self = shift;
	my $response_label = shift;
	my $value = shift;
	$self->{response}->replace_response($response_label, $value);
}
sub insert {         # add new values to PGanswergroup keys preserve existing values
	my $self = shift;
	my @in = @_;
	my %hash = ();
	if ( ref($in[0]=~/HASH/) ) {
		%hash = %{$in[0]};
	} else {
		%hash = @in;
	}
	foreach my $key (keys %hash) {
	    next if not_null( $self->{$key} );
		$self->{$key} = $hash{$key};
	}
	$self;	
}


sub replace {     # add new values ot PGanswergroup, overwriting existing values when duplicated
	my $self = shift;
	my @in = @_;
	my %hash = ();
	if ( ref($in[0]=~/HASH/) ) {
		%hash = %{$in[0]};
	} else {
		%hash = @in;
	}
	foreach my $key (keys %hash) {
		$self->{$key} = $hash{$key};
	}
	$self;	
}




sub delete_from_hash {   # don't want to redefine delete
	my $self = shift;
	my @in = @_;
	my %hash = ();
	if ( ref($in[0]=~/HASH/) ) {
		%hash = %{$in[0]};
	} else {
		%hash = @in;
	}
	foreach my $key (keys %hash) {
		$self->{$key} = undef;
	}
	$self;	
}


1;
