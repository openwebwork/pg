################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2022 The WeBWorK Project, http://github.com/openwebwork
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
use feature 'say';

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

	# load the default configuration file
	my $self = loadDefaults();

	# Then load any overrides.
	loadOverrides($self);

	# reset the pg_root if passed in as an argument.
	$self->{environment}->{pg_root} = $args{pg_root} if defined $args{pg_root};

	# add the course_name if passed in.
	$self->{environment}->{course_name} = $args{course_name} if defined $args{course_name};

	processEnvironment($self);
	processDirectories($self);
	processURLs($self);
	processEnvVars($self);


	bless $self, $class;

	return $self;
}

=head3 loadConfiguration

This subroutine loads the configuration file either in the given directory or
in the conf directory of PG_ROOT.

=cut

sub loadDefaults {
	my $pg_dir = $ENV{PG_ROOT};
	my $defaults_file = "$pg_dir/conf/pg_defaults.yml";
		die "Cannot read the configuration file $defaults_file" unless -r $defaults_file;
	my $options = LoadFile($defaults_file);
	my $config = {};

	for my $key (qw/perl_modules modules environment renderer hardcopy directories URLs
		ansEvalDefaults env_vars site userRoles permissionLevels/) {
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
	return unless -r $overrides_file;
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
		$config->{directories}->{course_directory}
			= "$config->{directories}->{courses}/$config->{environment}->{course_name}";
		$config->{directories}->{template_dir} = "$config->{directories}->{course_directory}/templates";
	}

	return;
}

=head3 processDirectories

This processes the configuration file for directories

=cut

sub processDirectories {
	my $config = shift;

	# Sets the htdocs, temp_dir, equation_cache and help_files directories.
	$config->{directories}->{htdocs} = $config->{environment}->{pg_root} . "/" .
		$config->{directories}->{renderer_dirs}->{htdocs};
	$config->{directories}->{temp_dir} = $config->{directories}->{htdocs} . "/" .
		$config->{directories}->{renderer_dirs}->{temp_dir};
	$config->{directories}->{equation_cache} = $config->{directories}->{temp_dir} . "/" .
		$config->{directories}->{renderer_dirs}->{equation_cache};
	$config->{directories}->{help_files} = $config->{directories}->{htdocs} . "/" .
		$config->{directories}->{renderer_dirs}->{help_files};

	delete $config->{directories}->{renderer_dirs};

	# Create some course configuration directories

	if ($config->{directories}->{course_directory}) {
		$config->{directories}->{course_templates} = $config->{directories}->{course_directory} .
			'/templates';
		$config->{directories}->{course_html} = $config->{directories}->{course_directory} .
			'/html';
	}

	my @macrosPath = @{$config->{environment}->{macrosPath}};
	unshift(@macrosPath,$config->{environment}->{pg_macros});
	$config->{environment}->{macrosPath} = \@macrosPath;


	# Sets the applet path
	my @appletPath = map {
		"$config->{directories}->{htdocs}/$_"
	} @{$config->{environment}->{appletPath}};

	$config->{environment}->{appletPath} = \@appletPath;
	return;
}

# This sets all of the URLs
sub processURLs {
	my $self = shift;

	# This might need to look up in the configuration.  Does this need to be an
	# absolute URL?
	$self->{URLs}->{htdocs} = "/htdocs";
	$self->{URLs}->{course_html} = "FIXME";
	$self->{URLs}->{html_temp} = "FIXME";
	$self->{URLs}->{local_help} = $self->{URLs}->{htdocs} . '/' . $self->{directories}->{help_files};
	$self->{URLs}->{temp_dir} = $self->{URLs}->{htdocs} . '/' . $self->{directories}->{temp_dir};
	$self->{URLs}->{mathjax} = $self->{URLs}->{htdocs} . '/' . $self->{URLs}->{mathjax};
}

sub processEnvVars {
	my $self = shift;

	# The following need to be processed.

	$self->{env_vars}->{VIEW_PROBLEM_DEBUGGING_INFO} =
		$self->{userRoles}->{$self->{permissionLevels}->{view_problem_debugging_info}};

	# ie file paths are printed for 'gage'
  # PRINT_FILE_NAMES_PERMISSION_LEVEL}
  #       $userRoles{ $permissionLevels{print_path_to_problem} };
   # (file paths are also printed for anyone with this permission or higher)
# $pg{specialPGEnvironmentVars}{ALWAYS_SHOW_HINT_PERMISSION_LEVEL} =
#         $userRoles{ $permissionLevels{always_show_hint} };
   # (hints are automatically shown to anyone with this permission or higher)
# $pg{specialPGEnvironmentVars}{ALWAYS_SHOW_SOLUTION_PERMISSION_LEVEL} =
#         $userRoles{ $permissionLevels{always_show_solution} };
   # (solutions are automatically shown to anyone with this permission or higher)
# $pg{specialPGEnvironmentVars}{VIEW_PROBLEM_DEBUGGING_INFO} =
#         $userRoles{ $permissionLevels{view_problem_debugging_info} };
 # (variable whether to show the debugging info from a problem to a student)

# $pg{specialPGEnvironmentVars}{use_knowls_for_hints}     = $pg{options}{use_knowls_for_hints};
# $pg{specialPGEnvironmentVars}{use_knowls_for_solutions} = $pg{options}{use_knowls_for_solutions};

# Locations of CAPA resources. (Only necessary if you need to use converted CAPA
# problems.)
################################################################################
# "Special" PG environment variables. (Stuff that doesn't fit in anywhere else.)
################################################################################

#  $pg{specialPGEnvironmentVars}{CAPA_Tools}             = "$courseDirs{templates}/Contrib/CAPA/macros/CAPA_Tools/",
#  $pg{specialPGEnvironmentVars}{CAPA_MCTools}           = "$courseDirs{templates}/Contrib/CAPA/macros/CAPA_MCTools/",
#  $pg{specialPGEnvironmentVars}{CAPA_GraphicsDirectory} = "$courseDirs{templates}/Contrib/CAPA/CAPA_Graphics/",
#  $pg{specialPGEnvironmentVars}{CAPA_Graphics_URL}      = "$webworkURLs{htdocs}/CAPA_Graphics/",

#  push @{$pg{directories}{macrosPath}},
#    "$courseDirs{templates}/Contrib/CAPA/macros/CAPA_Tools",
#    "$courseDirs{templates}/Contrib/CAPA/macros/CAPA_MCTools";



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

	warn "The courses directory: '$self->{directories}->{courses_dir}'
		does not exist" unless -d $self->{directories}->{courses};

	if (defined $self->{directories}->{course_directory}) {
		warn "The course directory: '$self->{directories}->{course_directory}'
			does not exist" unless -d $self->{directories}->{course_directory};

		warn "The templates directory: '$self->{directories}->{courses_dir}/templates'
			does not exist" unless -d $self->{directories}->{template_dir};
	}

	# Ensure the PG_ROOT/htdocs directories exist.

	warn "The htdocs directory: '$self->{directories}->{htdocs}' does not exist."
		unless -d $self->{directories}->{htdocs};

	warn "The htdocs directory: '$self->{directories}->{temp_dir}' does not exist."
		unless -d $self->{directories}->{temp_dir};

	warn "The htdocs directory: '$self->{directories}->{temp_dir}' is not writable."
		unless -W $self->{directories}->{temp_dir};

	warn "The htdocs directory: '$self->{directories}->{equation_cache}' does not exist."
		unless -d $self->{directories}->{equation_cache};

	warn "The htdocs directory: '$self->{directories}->{equation_cache}' is not writable."
		unless -W $self->{directories}->{equation_cache};


	warn "The htdocs directory: '$self->{directories}->{help_files}' does not exist."
		unless -d $self->{directories}->{help_files};


	# Make sure either the courses directory or the OPL directory is set.

	warn "Either the OPL root directory or the course_name must be set"
		unless (defined $self->{directories}->{course_directory} && -d $self->{directories}->{course_directory}) ||
			(defined $self->{directories}->{OPL} && -d $self->{directories}->{OPL});

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
