#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

my $pg_dir;

BEGIN {
	$pg_dir = $ENV{PG_ROOT};
	die 'The pg directory must be defined in PG_ROOT' unless (-e $pg_dir);
}

use lib "$pg_dir/lib";
use File::Slurp;
use Renderer::Problem;

my $file_path = '/opt/webwork/libraries/webwork-open-problem-library/OpenProblemLibrary/Utah/Quantitative_Analysis/set4_Derivatives/pr_15.pg';
my $problem_source = read_file($file_path);

my $problem = Renderer::Problem->new(
	problem_source => $problem_source,
	translationOptions => {
		problem_seed => 1324
	});
print Dumper $problem->{translationOptions};
my $translated_problem = $problem->render;

print Dumper $translated_problem->{body_text};
print Dumper $translated_problem->{errors};
