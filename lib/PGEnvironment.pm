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

BEGIN {
	eval {
		require WeBWorK::CourseEnvironment;
		# WeBWorK::CourseEnvironment->import();
		$ce = WeBWorK::CourseEnvironment->new({ webwork_dir => $ENV{WEBWORK_ROOT} });
	} or do {
		my $error = $@;

		$pg_dir = $ENV{PG_ROOT};
		die "The environmental variable PG_ROOT must be a directory" unless -d $pg_dir;
	};
}

sub new {
	my ($invocant, @rest) = @_;
	my $class = ref($invocant) || $invocant;

	my $self = {};

	if (defined($ce)) {
		$self->{webworkDirs}      = $ce->{webworkDirs};
		$self->{externalPrograms} = $ce->{externalPrograms};
		$self->{pg_dir}           = $ce->{pg_dir};
	} else {
		## load from an conf file;
		$self->{pg_dir} = $ENV{PG_ROOT};

		my $defaults_file = $self->{pg_dir} . "/conf/pg_defaults.yml";
		die "Cannot read the configuration file found at $defaults_file" unless -r $defaults_file;

		my $options = LoadFile($defaults_file);
		$self->{webworkDirs}      = $options->{webworkDirs};
		$self->{externalPrograms} = $options->{externalPrograms};

	}

	bless $self, $class;

	return $self;
}

1;
