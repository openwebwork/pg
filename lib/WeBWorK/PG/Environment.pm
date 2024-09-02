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

package WeBWorK::PG::Environment;

use strict;
use warnings;
use feature 'signatures';
no warnings qw(experimental::signatures);

=pod

=head1 WeBWorK::PG::Environment

This is a substitute for the CourseEnvironment module on the webwork2 side.  It
loads configuration options needed for PG.  This is used in WeBWorK::PG and
WeBWorK::PG::IO.

The configuration is initially loaded from
$ENV{PG_ROOT}/conf/pg_config.dist.yml.  If it is desired to change the default
values, then copy the $ENV{PG_ROOT}/conf/pg_config.dist.yml to
$ENV{PG_ROOT}/conf/pg_config.yml, and make changes in the copy.  The default
values will be overriden with the changed values in the copy.  Note that invalid
values added to the copy will cause a warning to be issued.

If the WeBWorK::CourseEnvironment module is found, then the configuration
options are overridden with the values from a webwork2 course environment
instance.  This is provided to maintain compatibility with webwork2, and should
be removed at the end of life for webwork2.

Optionally a course name may be provided to use the webwork2 course environment
for that course.

Note that the only values used in WeBWorK::PG::IO are
$pg_envir->{directories}{permitted_read_dir}, $pg_envir->{directories}{tmp}, and
the programs in the $pg_envir->{externalPrograms} hash.

Also note that for the standalone renderer this is used in
WeBWorK::PG::Translator, and there the values of $pg_envir->{directories}{root}
and $pg_envir->{modules} are used.

=cut

use YAML::XS qw/LoadFile/;

sub new ($invocant, $courseName = '___') {
	my $class = ref $invocant || $invocant;

	my $pg_root = $ENV{PG_ROOT};
	die 'The pg directory must be defined in PG_ROOT.' unless -d $pg_root;

	my $ce;

	eval {
		require WeBWorK::CourseEnvironment;
		$ce = WeBWorK::CourseEnvironment->new({ webwork_dir => $ENV{WEBWORK_ROOT}, courseName => $courseName });
	};

	# First load the pg config dist file (used for default values).
	my $defaults_file = "$pg_root/conf/pg_config.dist.yml";
	die "Cannot read the pg defaults file $defaults_file" unless -r $defaults_file;

	my $pg_envir = LoadFile($defaults_file);

	# Now Load the pg config file if it exists.
	my $config_file = "$pg_root/conf/pg_config.yml";
	$pg_envir = deepCopy($pg_envir, LoadFile($config_file)) if -r $config_file;

	# Override pg settings and things needed by WeBWorK::PG::IO with settings from the course environment.  Pick and
	# choose the important values from the webwork2 course environment.  Some values in the PG configuration are not
	# overriden.  These are the values that are used in the WeBWorK::PG and WeBWorK::PG::IO.  Note that in WeBWorK::PG
	# most values for the translator environment are taken from the options passed in, and the values in the pg
	# environment are used for the default values.
	if (defined $ce) {
		deepCopy($pg_envir, $ce->{pg});

		$pg_envir->{directories}{OPL}                = $ce->{problemLibrary}{root};
		$pg_envir->{directories}{Contrib}            = $ce->{contribLibrary}{root};
		$pg_envir->{directories}{tmp}                = $ce->{webworkDirs}{tmp};
		$pg_envir->{directories}{permitted_read_dir} = $ce->{webwork_courses_dir};
		$pg_envir->{directories}{equationCache}      = $ce->{webworkDirs}{equationCache};
		$pg_envir->{externalPrograms}                = $ce->{externalPrograms};
		$pg_envir->{URLs}{equationCache}             = $ce->{webworkURLs}{equationCache};
		$pg_envir->{equationCacheDB}                 = $ce->{webworkFiles}{equationCacheDB};
	}

	# Note that placeholders used in $pg_envir->{URLs}{html}, $pg_envir->{directories}{OPL}, and
	# $pg_envir->{directories}{Contrib} are set on the first iteration, and those carry over to anywhere those
	# placeholders are used in other settings on the second iteration.
	for (1 .. 2) {
		$pg_envir = replacePlaceholders(
			$pg_envir,
			{
				pg_root     => $pg_root,
				render_root => $ENV{RENDER_ROOT} // $pg_root,
				pg_root_url => $ENV{baseURL}     // $pg_envir->{URLs}{html},
				OPL_dir     => $pg_envir->{directories}{OPL},
				Contrib_dir => $pg_envir->{directories}{Contrib}
			}
		);
	}

	return bless $pg_envir, $class;
}

# Recursively copy the source hash into the target hash, overriding key values in the target.  If a value in the source
# has a ref that does not match that of the corresponding target value, then it is skipped and a warning is issued.
# Anything not in the target is copied in.
sub deepCopy ($target, $source) {
	if (ref $target eq 'HASH' && ref $source eq 'HASH') {
		for (keys %$source) {
			$target->{$_} = deepCopy($target->{$_}, $source->{$_});
		}
	} elsif (ref $target eq ref $source || !defined $target) {
		$target = $source;
	} else {
		warn 'invalid source field detected -- skipping';
	}

	return $target;
}

# Recursively deplace variable placeholders in the $input object.
sub replacePlaceholders ($input, $values) {
	if (ref $input eq 'HASH') {
		for (keys %$input) {
			$input->{$_} = replacePlaceholders($input->{$_}, $values);
		}
	} elsif (ref $input eq 'ARRAY') {
		for (0 .. $#$input) {
			$input->[$_] = replacePlaceholders($input->[$_], $values);
		}
	} else {
		$input =~ s/\$(\w+)/defined $values->{$1} ? $values->{$1} : ''/gex;
	}

	return $input;
}

1;
