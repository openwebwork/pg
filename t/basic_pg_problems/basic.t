use warnings;
use strict;

# package main;

use Test::More;
use Test::Exception;

# The following needs to include at the top of any testing down to END OF TOP_MATERIAL.

my $pg_dir;

BEGIN {
	die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
	$pg_dir = $ENV{PG_ROOT};
}

use lib "$pg_dir/lib";

use File::Slurp;
use Renderer::Problem;
use Data::Dumper;

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

# done_testing;
