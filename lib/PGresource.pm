################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2024 The WeBWorK Project, https://github.com/openwebwork
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
use parent PGcore;  # This is so that a PGresource object can call the PGcore warning_message and debug_message methods.

use strict;
use warnings;

use Scalar::Util;
use UUID::Tiny ':std';

sub new {
	my ($class, $parent_alias, $id, $type, %options) = @_;
	warn "PGresource must be called with a PGalias parent object."
		unless ref($parent_alias) =~ /PGalias/;

	my $self = bless {
		id           => $id,                             # auxiliary file name
		parent_alias => $parent_alias,
		type         => $type =~ s/^\.//r,               # file extension
		probFileName => $parent_alias->{probFileName},
		unique_id    => undef,
		path         => undef,                           # complete file path to resource
		uri          => undef,                           # URL path (or complete file path for TeX) to resource
		%options
	}, $class;

	Scalar::Util::weaken($self->{parent_alias});

	$self->warning_message("PGresource must be called with a name.") unless $id;
	$self->warning_message("PGresource must be called with a type.") unless $type;

	# Use this to check if the warning and debug channels have been hooked up to PGcore and PGalias correctly.
	#$self->warning_message("Test warning message from resource object");
	#$self->debug_message("Test debug message from resource object");

	return $self;
}

sub create_unique_id {
	my ($self, $ext) = @_;
	my $fileName = $self->fileName;

	if ($self->{unique_id}) {
		$self->warning_message("unique id already exists for $fileName.");
		return $self->{unique_id};
	}

	$self->warning_message(qq{Auxiliary file "$fileName" missing resource path.}) unless $self->path;
	$self->warning_message(qq{Auxiliary file "$fileName" missing unique_id_stub.})
		unless $self->{parent_alias}{unique_id_stub};

	my $unique_id_seed = $self->path . $self->{probFileName} . $self->{id};
	$self->{unique_id} =
		$self->{parent_alias}{unique_id_stub} . '___' . create_uuid_as_string(UUID_V3, UUID_NS_URL, $unique_id_seed);
	$self->{unique_id} .= ".$ext" if $ext;

	return $self->{unique_id};
}

sub uri {
	my ($self, $uri) = @_;
	$self->{uri} = $uri if $uri;
	return $self->{uri};
}

sub path {
	my ($self, $path) = @_;
	$self->{path} = $path if $path;
	return $self->{path};
}

sub unique_id {
	my $self = shift;
	return $self->{unique_id};
}

sub fileName {
	my ($self, $fileName) = @_;
	$self->{id} = $fileName if $fileName;
	return $self->{id};
}

1;

=head1 NAME

PGresource - Store information for an auxiliary resource.

=head2 new

Usage: C<< PGresource->new($parent_alias, $id, $type, %options) >>

The C<PGresource> constructor. The C<$parent_alias>, C<$id>, and C<$type>
parameters are required. The C<$parent_alias> must be the parent C<PGalias>
object that calls this constructor (and this is the only situation where this
object should be constructed).  The C<$id> should be the file name (or external
URL) of the auxiliary resource to be represented by this C<PGresource> object.
The C<$type> should be the file extension.  The C<%options> should contain
C<WARNING_messages> and C<DEBUG_messages> which should be array references.
These are used to store warning and debug messages.

=head2 create_unique_id

Usage: C<< $pgResource->create_unique_id($ext) >>

This is the primary method of the C<PGresource> module. This generates a unique
id for the auxiliary resource that it represents. That id takes into account the
unique id stub of the parent C<PGalias> object, the full path to the resource,
the problem file name, and the resource file name.

=head2 uri

Usage: C<< $pgResource->uri($uri) >>

Get or set the URI of the resource.

=head2 path

Usage: C<< $pgResource->path($path) >>

Get or set the path of the resource.

=head2 unique_id

Usage: C<< $pgResource->unique_id >>

Get the unique id of the resource. Note that the unique id is set by calling
C<create_unique_id>.

=head2 fileName

Usage: C<< $pgResource->fileName($fileName) >>

Get or set the file name (or id) of the resource.

=cut
