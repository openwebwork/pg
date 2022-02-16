#!/usr/bin/env perl

use strict;
use warnings;

my $pg_dir;

BEGIN {
	$pg_dir = $ENV{PG_ROOT};
	die "The pg directory must be defined in PG_ROOT" unless (-e $pg_dir);
}

use lib "$pg_dir/lib";
use File::Slurp;
use Renderer::Problem;
use Data::Dumper;

my $file_path = "/opt/webwork/libraries/webwork-open-problem-library/OpenProblemLibrary/Michigan/5e/Chap4Sec3/Q30.pg";
my $problem_source = read_file($file_path);

my $problem = Renderer::Problem->new(problem_source => $problem_source);
$problem->render;