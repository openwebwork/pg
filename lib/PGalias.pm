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

package PGalias;
use parent PGcore;    # This is so that a PGalias object can call the PGcore warning_message and debug_message methods.

use strict;
use warnings;

use UUID::Tiny ':std';
use PGcore;
use PGresource;

sub new {
	my ($class, $envir, %options) = @_;
	warn 'PGlias must be called with an environment' unless ref($envir) =~ /HASH/;
	my $self = bless { envir => $envir, resource_list => {}, %options }, $class;

	$self->{probFileName}      = $envir->{probFileName} // '';
	$self->{htmlDirectory}     = $envir->{htmlDirectory};
	$self->{htmlURL}           = $envir->{htmlURL};
	$self->{tempDirectory}     = $envir->{tempDirectory};
	$self->{templateDirectory} = $envir->{templateDirectory};
	$self->{tempURL}           = $envir->{tempURL};
	$self->{displayMode}       = $envir->{displayMode};

	# Find auxiliary files even when the main file is in templates/tmpEdit.
	# FIXME: This shouldn't be done here.  Instead the front end should pass in the problem source with the file name.
	# The other instance of this in PGloadfiles.pm needs to be removed.
	$self->{probFileName} =~ s!(^|/)tmpEdit/!$1!;

	# Create an ID which is unique for the given psvn, problemSeed, and problemUUID.  It is the responsibility of the
	# caller to pass in a problemUUID that will provide the required uniqueness.  That could include a course name, a
	# student login name, etc.
	$self->{unique_id_stub} = create_uuid_as_string(UUID_V3, UUID_NS_URL,
		join('-', $envir->{psvn} // (), $envir->{problemSeed}, $envir->{problemUUID} // ()));

	# Check the parameters.
	$self->warning_message('The displayMode is not defined')    unless $self->{displayMode};
	$self->warning_message('The htmlDirectory is not defined.') unless $self->{htmlDirectory};
	$self->warning_message('The htmlURL is not defined.')       unless $self->{htmlURL};
	$self->warning_message('The tempURL is not defined.')       unless $self->{tempURL};

	return $self;
}

# This cache's auxiliary files within a single PG problem.
sub add_resource {
	my ($self, $aux_file_id, $resource) = @_;
	if (ref($resource) =~ /PGresource/) {
		$self->{resource_list}{$aux_file_id} = $resource;
	} else {
		$self->warning_message(qq{"$aux_file_id" does not refer to a valid resource.});
	}
	return;
}

sub get_resource {
	my ($self, $aux_file_id) = @_;
	return $self->{resource_list}{$aux_file_id};
}

sub make_resource_object {
	my ($self, $aux_file_id, $ext) = @_;
	return PGresource->new(
		$self,                                            # parent alias of resource
		$aux_file_id,                                     # resource file name
		$ext,                                             # resource type
		WARNING_messages => $self->{WARNING_messages},    # connect warning message channels
		DEBUG_messages   => $self->{DEBUG_messages},
	);
}

sub make_alias {
	my ($self, $aux_file_id) = @_;
	$self->warning_message('Empty string used as input into the function alias') unless $aux_file_id;

	# Determine the file extension, if there is one. Files without extensions are flagged with errors.
	my $ext;
	if ($aux_file_id =~ m/\.([^\.]+)$/) {
		$ext = $1;
	} else {
		$self->warning_message(qq{The file name "$aux_file_id" does not have an extension. }
				. 'Every file name used as an argument to alias must have an extension. The permissable extensions are '
				. '.gif, .jpg, .png, .svg, .pdf, .mp4, .mpg, .ogg, .webm, .css, .js, .nb, .csv, .tgz, and .html.');
		return;
	}

	# Checks to see if a resource exists for this particular aux_file_id.
	# If not, then create one.  Otherwise, return the URI for the existing resource.
	unless (defined $self->get_resource($aux_file_id)) {
		$self->add_resource($aux_file_id, $self->make_resource_object($aux_file_id, $ext));
	} else {
		return $self->get_resource($aux_file_id)->uri;
	}

	# $output_location is a URL in HTML mode and a complete directory path in TeX mode.
	my $output_location;

	if ($ext eq 'html') {
		$output_location = $self->alias_for_html($aux_file_id, $ext);
	} elsif ($ext =~ /^(gif|jpg|png|svg|pdf|mp4|mpg|ogg|webm|css|js|nb|csv|tgz)$/) {
		if ($self->{displayMode} =~ /^HTML/ or $self->{displayMode} eq 'PTX') {
			$output_location = $self->alias_for_html($aux_file_id, $ext);
		} elsif ($self->{displayMode} eq 'TeX') {
			$output_location = $self->alias_for_tex($aux_file_id, $ext);
		} else {
			$self->warning_message("Error creating resource alias. Unrecognizable displayMode: $self->{displayMode}");
		}
	} else {
		# $ext is not recognized
		$self->warning_message(qq{Error creating resource alias. Files with extension "$ext" are not allowed.\n}
				. qq{(Path to problem file is "$self->{probFileName}".)});
	}

	$self->warning_message(qq{Unable to form a URL for the auxiliary file "$aux_file_id" used in this problem.})
		unless $output_location;

	return $output_location;
}

sub alias_for_html {
	my ($self, $aux_file_id, $ext) = @_;

	my $resource_object = $self->get_resource($aux_file_id);

	if ($aux_file_id =~ /https?:/) {
		# External URL.
		$resource_object->uri($aux_file_id);
		return $resource_object->uri;    # External URLs need no further processing.
	}

	# Get the directories that might contain auxiliary files.
	my @aux_files_directories = @{ $self->{envir}{ $ext eq 'html' ? 'htmlPath' : 'imagesPath' } };
	if ($self->{probFileName}) {
		# Replace "." with the current pg problem file directory.
		@aux_files_directories =
			map { $_ eq '.' ? $self->{templateDirectory} . $self->directoryFromPath($self->{probFileName}) : $_ }
			@aux_files_directories;
	} else {
		@aux_files_directories = grep { $_ ne '.' } @aux_files_directories;
	}

	# Find the complete path to the original file.
	my $file_path =
		$aux_file_id =~ m|^/| ? $aux_file_id : $self->find_file_in_directories($aux_file_id, \@aux_files_directories);

	unless ($file_path) {
		$self->warning_message(qq{Unable to find file "$aux_file_id".});
		return;
	}

	# Store the complete path to the original file, and calculate and store the URI (which is a URL suitable for the
	# browser relative to the current site).
	if ($file_path =~ m|^$self->{tempDirectory}|) {
		# File is in the course temporary directory.
		$resource_object->uri($file_path =~ s|$self->{tempDirectory}|$self->{tempURL}|r);
		$resource_object->path($file_path);
	} elsif ($file_path =~ m|^$self->{htmlDirectory}|) {
		# File is in the course html directory.
		$resource_object->uri($file_path =~ s|$self->{htmlDirectory}|$self->{htmlURL}|r);
		$resource_object->path($file_path);
	} else {
		# Resource is in a directory which is not public.
		# Most often this is the directory containing the .pg file.
		# These files need to be linked to from the public html temporary directory.
		$resource_object->path($file_path);
		$self->warning_message("File extension for resource $file_path is not defined") unless $ext;
		$resource_object->create_unique_id($ext);

		# Create a link from the original file to an alias in the temporary public html directory.
		$self->create_link_to_tmp_file($resource_object, $ext eq 'html' ? 'html' : 'images');
	}

	# Return the URI of the resource.
	return $resource_object->uri;
}

sub alias_for_tex {
	my ($self, $aux_file_id, $ext) = @_;

	my $resource_object = $self->get_resource($aux_file_id);

	if ($aux_file_id =~ /https?:/) {
		# External URL.
		$resource_object->uri($aux_file_id);
		return $resource_object->uri;    # External URLs need no further processing.
	}

	# Get the directories that might contain auxiliary files.
	my @aux_files_directories = @{ $self->{envir}{ $ext eq 'html' ? 'htmlPath' : 'imagesPath' } };
	if ($self->{probFileName}) {
		# Replace "." with the current pg problem file directory.
		my $current_pg_directory = $self->directoryFromPath($self->{probFileName});
		$current_pg_directory  = $self->{templateDirectory} . $current_pg_directory;
		@aux_files_directories = map { $_ eq '.' ? $current_pg_directory : $_ } @aux_files_directories;
	} else {
		@aux_files_directories = grep { $_ ne '.' } @aux_files_directories;
	}

	# Find complete path to the original file.
	my $file_path =
		$aux_file_id =~ m|^/| ? $aux_file_id : $self->find_file_in_directories($aux_file_id, \@aux_files_directories);

	unless ($file_path) {
		$self->warning_message(qq{Unable to find "$aux_file_id" in any of the allowed auxiliary file directories.});
		return;
	}

	# Store the complete path to the original file.
	if ($file_path =~ m|^$self->{tempDirectory}|) {
		# File is in the course temporary directory.
		$resource_object->path($file_path);
	} elsif ($file_path =~ m|^$self->{htmlDirectory}|) {
		# File is in the course html directory.
		$resource_object->path($aux_file_id);
	} else {
		$resource_object->path($file_path);
	}

	if ($ext eq 'gif' || $ext eq 'svg') {
		# Convert gif and svg files to png files.
		$self->convert_file_to_png_for_tex($resource_object, $ext eq 'html' ? 'html' : 'images');
	} else {
		# Path and URI are the same in this case.
		$resource_object->uri($resource_object->path);
	}

	# An alias is not needed in this case because nothing is being served over the web.
	# Return the full path to the image file.
	return $resource_object->uri && -r $resource_object->uri ? $resource_object->uri : '';
}

sub create_link_to_tmp_file {
	my ($self, $resource_object, $subdir) = @_;

	my $ext  = $resource_object->{type};
	my $link = "$subdir/$resource_object->{unique_id}";

	# Insure that link path exists and all intermediate directories have been created.
	my $linkPath = $self->surePathToTmpFile($link);

	if (-e $resource_object->path) {
		if (-e $linkPath) {
			# Destroy the old link.
			unlink($linkPath) or $self->warning_message(qq{Unable to unlink alias file at "$linkPath".});
		}

		# Create a new link, and the URI to this link.
		if (symlink($resource_object->path, $linkPath)) {
			$resource_object->uri(($self->{tempURL} =~ s|/$||r) . "/$link");
		} else {
			$self->warning_message(
				qq{The macro alias cannot create a link from "$linkPath"  to "} . $resource_object->path . '"');
		}
	} else {
		$self->warning_message('Cannot find the file: "'
				. $resource_object->fileName . '" '
				. ($resource_object->path ? ' at "' . $resource_object->path . '"' : ' anywhere'));
	}

	return;
}

sub convert_file_to_png_for_tex {
	my ($self, $resource_object, $target_directory) = @_;

	$resource_object->create_unique_id($resource_object->{type});
	my $targetFilePath =
		$self->surePathToTmpFile("$target_directory/" . ($resource_object->{unique_id} =~ s|\.[^/\.]*$|.png|r));
	$self->debug_message('target filePath ', $targetFilePath, "\n");
	my $sourceFilePath = $resource_object->path;
	$self->debug_message('convert filePath ', $sourceFilePath, "\n");

	my $conversion_command = WeBWorK::PG::IO::externalCommand('convert');
	my $returnCode         = system "$conversion_command '${sourceFilePath}[0]' $targetFilePath";
	if ($returnCode || !-e $targetFilePath) {
		$resource_object->warning_message(
			qq{Failed to convert "$sourceFilePath" to "$targetFilePath" using "$conversion_command": $!});
	}

	$resource_object->uri($targetFilePath);

	return;
}

sub find_file_in_directories {
	my ($self, $file_name, $directories) = @_;
	for my $dir (@$directories) {
		$dir =~ s|/$||;    # Remove final / if present.
		my $file_path = "$dir/$file_name";
		return $file_path if -r $file_path;
	}
	return;                # No file found.
}

1;

=head1 NAME

PGalias - Create aliases for auxiliary resources.

=head2 new

Usage: C<< PGalias->new($envir, %options) >>

The C<PGalias> constructor. The C<$envir> hash containing the problem
environment is required. The C<%options> can contain C<WARNING_messages> and
C<DEBUG_messages> which should be array references. These are passed on to all
C<PGresource> objects constructed for each problem resource and are used by both
modules to store warning and debug messages.

One C<PGalias> object is created for each C<PGcore> object (which is unique for
each problem).  This object is used to construct unique ids for problem
resources and maintain a list of the resources used by a problem. A
unique_id_stub is generated for this C<PGalias> object which is the basis for
the unique ids generated for resource files (except equation images for the
"images" display mode) used by the problem.

=head2 get_resource

Usage: C<< $pgAlias->get_resource($aux_file_id) >>

Returns the C<PGresource> object corresponding to C<$aux_file_id>.

=head2 make_alias

Usage: C<< $pgAlias->make_alias($aux_file_id) >>

This is the workhorse of the C<PGalias> module.  Its front end is C<alias> in
L<PG.pl>.

C<make_alias> takes the name of an auxiliary resource (html file, png file,
etc.) and creates a file name or URL appropriate to the current display mode.
It also does any necessary conversions behind the scenes.

It returns the URL of the resource if the display mode is HTML or PTX, and the
full file path if the display mode is TeX.

=head2 alias_for_html

Usage: C<< $pgAlias->alias_for_html($aux_file_id, $ext) >>

Returns the URL alias for the resource identified by C<$aux_file_id> with the
file name extension C<$ext>.

=head2 alias_for_tex

Usage: C<< $pgAlias->alias_for_tex($aux_file_id, $ext) >>

Returns the full file path alias for the resource identified by C<$aux_file_id>
with the file name extension C<$ext>.

=head2 create_link_to_tmp_file

Usage: C<< $pgAlias->create_link_to_tmp_file($resource_object, $subdir) >>

Creates a symbolic link in the subdirectory C<$subdir> of the publicly
accessible temporary directory to the file (usually in a course's templates
directory) represented by the C<PGresource> referenced by C<$resource_object>.
The link name is the file unique id alias.

=head2 convert_file_to_png_for_tex

Usage: C<< $pgAlias->convert_file_to_png_for_tex($resource_object, $target_directory) >>

Converts a "gif" or "svg" file to a "png" file. The "png" file is saved in
C<$target_directory> and the file name is the unique id alias for the
C<PGresource> referenced by C<$resource_object>.

=head2 find_file_in_directories

Usage: C<< $pgAlias->find_file_in_directories($file_name, $directories) >>

Finds the first directory in the array of directory names referenced to by
C<$directories> that contains a readable file named C<$file_name>, and returns
the full path of that file.

=cut
