#!/usr/bin/env perl

my $pg_dir;

BEGIN {
	$pg_dir = $ENV{PG_ROOT};
	die "The pg directory must be defined in PG_ROOT" unless (-e $pg_dir);
}

use lib "$pg_dir/lib";

use PGEnvironment;

# my $pg_env = PGEnvironment->new(course_name => "test");
my $pg_env = PGEnvironment->new();

$pg_env->checkEnvironment();
