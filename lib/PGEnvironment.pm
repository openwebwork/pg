################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2021 The WeBWorK Project, http://github.com/openwebwork
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
package PGEnvironment;

use strict;
use warnings;

=pod

=head1 PGEnvironment

This is a substitute for the CourseEnvironment module on the webwork2 side
however is much slimmed down.  It loads only configuration options need for
PG when not run in full mode.

If the the WeBWorK::CourseEnvironment module is found the lib path, then the
necessary configuration options are loaded.

Otherwise, defaults are loaded from PG_ROOT/conf/pg_defaults.yml

=cut

my $ce;
my $pg_dir;

use YAML::XS qw/LoadFile/;

use Data::Dumper;

BEGIN {
	$pg_dir = $ENV{PG_ROOT};
	die "The environmental variable PG_ROOT must be a directory" unless -d $pg_dir;
}

sub new {
	my ($invocant, %args) = @_;
	my $class = ref($invocant) || $invocant;

	my $self = {};

	if (defined($ce)) {
		$self->{webworkDirs}         = $ce->{webworkDirs};
		$self->{externalPrograms}    = $ce->{externalPrograms};
		$self->{pg_dir}              = $ce->{pg_dir};
		$self->{webwork_courses_dir} = $ce->{webwork_courses_dir};
	} else {
		$self = loadConfiguration();
		loadOverrides($self);

		# reset the pg_root if passed in as an argument.
		$self->{environment}->{pg_root} = $args{pg_root} if defined $args{pg_root};

		# add the course_name if passed in.
		$self->{environment}->{course_name} = $args{course_name} if defined $args{course_name};
		processEnvironment($self);
		processDirectories($self);

	}

	bless $self, $class;

	return $self;
}

=head3 loadConfiguration

This subroutine loads the configuration file either in the given directory or
in the conf directory of PG_ROOT.

=cut

sub loadConfiguration {
	my $pg_dir = $ENV{PG_ROOT};
	my $defaults_file = "$pg_dir/conf/pg_defaults.yml";
		die "Cannot read the configuration file $defaults_file" unless -r $defaults_file;
	my $options = LoadFile($defaults_file);
	my $config = {};

	for my $key (qw/perl_modules modules environment renderer hardcopy/) {
		$config->{$key} = $options->{$key}
	}
	return $config;
}

=head3 loadOverrides

This method loads all override configurations from the conf/pg_overrides.yml file

=cut

sub loadOverrides {
	my $config = shift;
	my $pg_dir = $ENV{PG_ROOT};
	my $overrides_file = "$pg_dir/conf/pg_overrides.yml";
		die "Cannot read the configuration file $overrides_file" unless -r $overrides_file;
	my $overrides = LoadFile($overrides_file);

	# Recursively copy the overrides onto the configuration.  This copies 4 levels deep.
	# Perhaps we should find a better way.
	for my $level1 (keys %$overrides) {
		for my $level2 (keys %{$overrides->{$level1}}) {
			if(ref $overrides->{$level1}->{$level2} eq 'HASH') {
				# copy one more level
				for my $level3 (keys %{$overrides->{$level1}->{$level2}}) {
					if(ref $overrides->{$level1}->{$level2}->{$level3} eq 'HASH') {
						for my $level4 (keys %{$overrides->{$level1}->{$level2}->{$level3}}) {
							$config->{$level1}->{$level2}->{$level3}->{$level4}
								= $overrides->{$level1}->{$level2}->{$level3}->{$level4};
						}
					} else {
						$config->{$level1}->{$level2}->{$level3} = $overrides->{$level1}->{$level2}->{$level3};
					}
				}
			} else {
				$config->{$level1}->{$level2} = $overrides->{$level1}->{$level2};
			}
		}
	}
	return;
}

=head3 processEnvironment

This subroutine processes the settings in the environment field/hash of the
configuration.

=cut

sub processEnvironment {
	my $config = shift;

	$config->{environment}->{pg_root} = $ENV{PG_ROOT}
		unless defined $config->{environment}->{pg_root};
	$config->{environment}->{pg_lib} = "$config->{environment}->{pg_root}/lib";
	$config->{environment}->{pg_macros} = "$config->{environment}->{pg_root}/macros";

	# Define the course_directory
	if (defined $config->{environment}->{course_name}) {
		$config->{environment}->{course_directory}
			= "$config->{environment}->{courses_dir}/$config->{environment}->{course_name}";
		$config->{environment}->{template_dir} = "$config->{environment}->{course_directory}/templates";
	}

	return;
}

=head3 processDirectories

This processes the configuration file for directories

=cut

sub processDirectories {
	my $config = shift;

	# Sets the htdocs, temp_dir, equation_cache and help_files directories.
	$config->{renderer}->{htdocs} = $config->{environment}->{pg_root} . "/" .
		$config->{environment}->{renderer_dirs}->{htdocs};
	$config->{renderer}->{temp_dir} = $config->{renderer}->{htdocs} . "/" .
		$config->{environment}->{renderer_dirs}->{temp_dir};
	$config->{renderer}->{equation_cache} = $config->{renderer}->{temp_dir} . "/" .
		$config->{environment}->{renderer_dirs}->{equation_cache};
	$config->{renderer}->{help_files} = $config->{renderer}->{htdocs} . "/" .
		$config->{environment}->{renderer_dirs}->{help_files};

	# Remap the macrosDirectories to absolute paths:
	my @macrosPath;
	if (defined($config->{environment}->{course_directory})) {
		@macrosPath = map { "$config->{environment}->{course_directory}/Library/macros/$_" }
			@{$config->{environment}->{macrosPath}};
	} elsif (defined $config->{environment}->{OPL_dir} ) {
		@macrosPath = map { "$config->{environment}->{OPL_dir}/macros/$_" }
			@{$config->{environment}->{macrosPath}};
	} else {
		die "either the course name or OPL_dir must be set.";
	}

	$config->{environment}->{macrosPath} = \@macrosPath;


	# Sets the applet path
	my @appletPath = map {
		"$config->{renderer}->{htdocs}/$_"
	} @{$config->{environment}->{appletPath}};

	$config->{environment}->{appletPath} = \@appletPath;
	return;
}

# This checks that the directories exists and other settings are consistent.



sub checkEnvironment {
	my $self = shift;

	# Check the structure of the PG_ROOT directory
	warn "The directory PG_ROOT: '$self->{environment}->{pg_root}' does not exist"
		unless -d $self->{environment}->{pg_root};
	warn "The directory PG_ROOT/lib: '$self->{environment}->{pg_lib}' does not exist"
		unless -d $self->{environment}->{pg_lib};
	warn "The directory PG_ROOT/macros: '$self->{environment}->{pg_macros}'
		does not exist" unless -d $self->{environment}->{pg_macros};

	# Check for the courses directory and if the course_name is passed in is correct.

	warn "The courses directory: '$self->{environment}->{courses_dir}'
		does not exist" unless -d $self->{environment}->{courses_dir};

	if (defined $self->{environment}->{course_directory}) {
		warn "The course directory: '$self->{environment}->{course_directory}'
			does not exist" unless -d $self->{environment}->{course_directory};

		warn "The templates directory: '$self->{environment}->{courses_dir}/templates'
			does not exist" unless -d $self->{environment}->{template_dir};
	}

	# Ensure the PG_ROOT/htdocs directories exist.

	warn "The htdocs directory: '$self->{renderer}->{htdocs}' does not exist."
		unless -d $self->{renderer}->{htdocs};

	warn "The htdocs directory: '$self->{renderer}->{temp_dir}' does not exist."
		unless -d $self->{renderer}->{temp_dir};

	warn "The htdocs directory: '$self->{renderer}->{temp_dir}' is not writable."
		unless -W $self->{renderer}->{temp_dir};

	warn "The htdocs directory: '$self->{renderer}->{equation_cache}' does not exist."
		unless -d $self->{renderer}->{equation_cache};

	warn "The htdocs directory: '$self->{renderer}->{equation_cache}' is not writable."
		unless -W $self->{renderer}->{equation_cache};


	warn "The htdocs directory: '$self->{renderer}->{help_files}' does not exist."
		unless -d $self->{renderer}->{help_files};


	# Make sure either the courses directory or the OPL directory is set.

	warn "Either the OPL root directory or the course_name must be set"
		unless (defined $self->{environment}->{course_directory} && -d $self->{environment}->{course_directory}) ||
			(defined $self->{environment}->{OPL_dir} && -d $self->{environment}->{OPL_dir});

	# Check that all of the diretories in the macros path are defined.

	for my $path (@{$self->{environment}->{macrosPath}}) {
		warn "The macro library: '$path' does not exist." unless -d $path;
	}

	# Check that all of the diretories in the applet path are defined.

	for my $path (@{$self->{environment}->{appletPath}}) {
		warn "The applet directory: '$path' does not exist." unless -d $path;
	}


	# Check that the external programs are in the proper place.

	for my $prog (keys %{$self->{environment}->{externalPrograms}}) {
		# If there are arguments in the program, parse out the arguments.
		my @args = split(/$prog\s/, $self->{environment}->{externalPrograms}->{$prog});
		warn "The $prog program at '$self->{environment}->{externalPrograms}->{$prog}' does not exist"
			unless (-e $args[0]);
		warn "The $prog program at '$self->{environment}->{externalPrograms}->{$prog}' is not executable"
			unless (-x $args[0]);
	}
}

1;
