################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/lib/PGalias.pm,v 1.6 2010/05/15 18:41:23 gage Exp $
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

package PGresource;
use strict;
use Exporter;
use UUID::Tiny  ':std';
use PGcore;
our @ISA= qw( PGcore ) ;

sub new {
	my $class        = shift;	
	my $parent_alias = shift;
	my $id           = shift;
	my $type         = shift;
	my %options      = @_;
	$type =~s/^\.//; # remove initial period if included in type.
	my $self = {

		id           	=>  $id,
		parent_alias 	=>  $parent_alias,
		type         	=>  $type, # gif eps pdf html pg (macro: pl) (applets: java js fla geogebra (ggb) )
		parent_file_id  =>  $parent_alias->{pgFileName},  # file id for the file requesting the resource
		
		path		 	=>  { content => undef,       # file path to resource
							  is_complete=>0,
							  is_accessible => 0,
							},
		uri			 	=>  { content => undef,       # usually url path to resource
							  is_complete=>0,
							  is_accessible => 0,
							},
		return_uri   	=>  '',
		recorded_uri 	=> '',
		convert      	=> { needed  => 0,
							  from_type => undef,
							  from_path => undef,
							  to_type	=> undef,
							  to_path	=> undef,
							},
		copy_link    	=>  { type => undef,  # copy or link or orig (original file, no copy or link needed)
							  link_to_path => undef,   # the path of the alias 
							  copy_to_path => undef,   # the path of the duplicate file
							 },
		cache_info	 	=>  {},
		unique_id    	=>  undef, 
		%options,
	};
	bless $self, $class;
	$self->warning_message( "PGresource must be called with an  alias object") unless ref($parent_alias) =~ /PGalias/;
	$self->warning_message(  "PGresource must be called with a name" ) unless $id;
	$self->warning_message(  "PGresource must be called with a type") unless $type;
	# $self->warning_message( "Test warning message from resource object");
	# Use this to check if the warning and debug channels have been hooked up to PGcore and PGalias correctly.
	return $self;
}

sub uri {
	my $self = shift;
	my $uri = shift;
	$self->{uri}->{content} = $uri if $uri;
	$self->{uri}->{content};
}
sub path {
	my $self = shift;
	my $url = shift;
	$self->{path}->{content}=$url if $url;
	$self->{path}->{content};
}

sub create_unique_id {
	my $self = shift;
	if ($self->{unique_id} ) {
		$self->warning_message( "unique id already exists for ". $self->{id} );
		return $self->{unique_id};
	}
	$self->warning_message( "missing resource path ") unless $self->path;
	$self->warning_message( "missing pg file name"  ) unless $self->{parent_file_id};
	$self->warning_message( "missing problem psvn"  ) unless $self->{parent_alias}->{psvn}; 
	$self->warning_message( "missing unique_id_stub") unless $self->{parent_alias}->{unique_id_stub};
	my $unique_id_seed = $self->path() . $self->{parent_file_id}.$self->{parent_alias}->{psvn}; 
	$self->{unique_id} = $self->{parent_alias}->{unique_id_stub} .
	      '___'. create_uuid_as_string( UUID_V3, UUID_NS_URL, $unique_id_seed );
	$self->{unique_id};
}

sub unique_id {
	my $self =shift;
	my $unique_id = shift;
	$self->{unique_id} = $unique_id if $unique_id;
	$self->{unique_id};
}


1;