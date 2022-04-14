#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

my $pg_dir;

BEGIN {
	$pg_dir = $ENV{PG_ROOT};
	die "The pg directory must be defined in PG_ROOT" unless (-e $pg_dir);
}

use lib "$pg_dir/lib";
use File::Slurp;
use Renderer::Problem;

my $file_path = "/opt/webwork/libraries/webwork-open-problem-library/Contrib/Fitchburg/TeacherPrep/Arithmetic/add_lattice.pg";
my $problem_source = read_file($file_path);

my $problem = Renderer::Problem->new(problem_source => $problem_source);
my $translated_problem = $problem->render;
print Dumper keys %$translated_problem;
print Dumper $translated_problem->{body_text};