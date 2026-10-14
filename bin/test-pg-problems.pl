#!/usr/bin/env perl

=head1 NAME

test-pg-problems.pl - Run tests on a list of PG problems.  

=head1 SYNOPSIS

test-pg-problems.pl [options] file(s)

  Options:
    -i|--input-dir         Directory to read PG files from. If not specified, files will be read 
                           from the command line arguments. (default: '')
    -r|--recursive         If a directory is given, then this could run all file recursively 
                           in subdirectories. (default: false)
    -v|--verbose           Increase the verbosity of the output.  (Default: false)
    -f|--format            Format that the tests will return in (TEXT, YAML or JSON).  (Default: TEXT)
    -o|--output-file       Filename to write output to. If not provided output will
                           be printed to STDOUT.
    -p|--pg-root           The PG_ROOT directory.  This is not needed if the environment variable 
                           is defined.
    -l|--library-root.     The root of the library for which the problems are defined. 
                           If not defined, this will be set to the standard location of the 
                           webwork-open-problem-library.
    -c|--pg-critic         Run the pg-critic on the file(s).  (Default: false) 
    -n|--num-seeds         If the specific seeds are not given, this is the number of seeds to 
                           randomly select for testing.  (Default: 5)
    -s|--seed              Set the seed to be run.  If separated by commas, this will run
                           the test for each given seed. This will override the -n flag.
    -m|--metadata          Check the subject/chapter/section categories. 

=head1 DESCRIPTION

Run tests on a list of files or a directory of files.  If the pg problem has metadata with testing
Information, then use the information to run the tests.  See below for details.  If not, some 
number of random seeds (given by the C<num-seeds> option) will be selected. 

=head2 TESTING DETAILS

If in the metadata for the problem, there is a C<testing> option, then tests will be run for 
every seed given and then tested against the answers (as an array) in the answers.  For example, 

    testing:
    - seed: 1234
      answers:
      - 3^(-4)
      - e^(-3)
      - 4*e^(0.815)
    - seed: 123456
      answers:
      - 0.1111111
      - 0.1353352832
      - 9.6110180035

This will run the problem for each seed and then compare the returned answers to those in the 
C<answers> array above. 

If there is no C<testing> field in the metadata, then the script will use the correct 
answers.  This can be done by either some number of random seeds with the C<--num-seeds> flag
or the C<--seeds> for specified seeds.  

=cut

use strict;
use warnings;
use feature 'say';
use v5.36;

use Mojo::Util qw(dumper);
$Data::Dumper::Maxdepth = 3;
use Mojo::JSON qw(encode_json);
use YAML::XS;
use Getopt::Long;
use Pod::Usage;

my ($pg_root, $ww_root);

BEGIN {
	use Mojo::File qw(curfile path);

	$pg_root = $ENV{PG_ROOT} ? Mojo::File->new($ENV{PG_ROOT}) : curfile->dirname->dirname;
	$ww_root = $ENV{WW_ROOT} ? Mojo::File->new($ENV{WW_ROOT}) : $pg_root->dirname->child('webwork2');
	require lib;
	lib->import("$pg_root/lib", "$ww_root/lib");
}

use WeBWorK::PG;
use WeBWorK::PG::Localize;
use WeBWorK::PG::ProblemParser;
use WeBWorK::PG::Critic qw(critiquePGFile);

GetOptions(
	'i|input-dir=s'   => \my $input_dir,
	'r|recursive'     => \my $recursive,
	'f|format=s'      => \my $format,
	'o|output-file=s' => \my $output_file,
	'c|pg-critic'     => \my $pg_critic,
	'l|library-root'  => \my $library_root,
	'p|pg-root'       => \$pg_root,
	's|seed=s'        => \my $seeds,
	'n|num-seeds=i'   => \my $num_seeds,
	'm|metadata'      => \my $metadata,
	'v|verbose'       => \my $verbose,
	'h|help'          => \my $show_help
);
pod2usage(2) if $show_help;

$format //= 'text';
$format = lc($format);
$num_seeds //= 5;

unless (grep { $_ =~ $format } ('text', 'json', 'yaml')) {
	say 'The output format must be "TEXT", "JSON" or "YAML"';
	pod2usage(2);
}

die 'The environmental variable PG_ROOT must be defined or pass in the option --pg-root'
	unless -d $pg_root;

die 'The problems should either be as a list on the command line or within the input-dir but not both'
	if (@ARGV && $input_dir);

$library_root = Mojo::File->new($pg_root)->dirname->child('libraries', 'webwork-open-problem-library')
	unless $library_root;

die "The library_root: $library_root is not a directory" unless -d $library_root;

my @pg_problems;

if (@ARGV) {
	@pg_problems = grep { $_ =~ /\.pg$/ } map { Mojo::File->new($_) } @ARGV;
} else {    #
	unless ($input_dir) {
		pod2usage(2);
		die 'The problems should either be as a list on the command line or within the input-dir but not both';
	}
	@pg_problems =
		$recursive
		? @{ path->child($input_dir)->list_tree->grep(sub { $_ =~ /\.pg$/ })->to_array }
		: @{ path->child($input_dir)->list->grep(sub { $_ =~ /\.pg$/ })->to_array };
}

my @seeds;
@seeds = split(/\s*,\s*/, $seeds) if $seeds;

# Store the results of the tests in an array of hashes.
# Each hash will have the problem path, and an array of test results.
my @problem_results;

for my $filename (@pg_problems) {
	say "Testing problem: $filename" if $verbose;

	my $pg_problem =
		WeBWorK::PG::ProblemParser->new(pg_root => $pg_root, path => $filename, library_root => $library_root);
	my $pg = WeBWorK::PG->new(r_source => \$pg_problem->{problem_source});

	my $test_result = { path => "$filename" };

	# PG Critic results:
	if ($pg_critic) {
		my @violations           = critiquePGFile($filename, 0);
		my @pgCriticViolations   = grep { $_->policy =~ /^Perl::Critic::Policy::PG::/ } @violations;
		my @perlCriticViolations = grep { $_->policy !~ /^Perl::Critic::Policy::PG::/ } @violations;
		$test_result->{pg_critic_violations} =
			[ map { { description => $_->description, explanation => $_->explanation, policy => $_->policy } }
				@pgCriticViolations ]
			if @pgCriticViolations;
		$test_result->{perl_critic_violations} =
			[ map { { description => $_->description, explanation => $_->explanation, policy => $_->policy } }
				@perlCriticViolations ]
			if @perlCriticViolations;
	}

	# Check if the subject/chapter/section metadata exists in the taxonomy.
	if ($metadata) {
		my $errors = $pg_problem->checkDBmetadata;
		$test_result->{metadata_errors} = $errors if (values %$errors);
	}

	my @test_runs;
	# If testing is placed in the file, then test against each entry:
	if ($pg_problem->{metadata}{testing}) {
		say "Using testing data defined within the problem." if $verbose;

		my @all_answer_labels;
		push(@all_answer_labels, @{ $pg->{pgcore}{PG_ANSWERS_HASH}{$_}{response}{response_order} })
			for (keys %{ $pg->{pgcore}{PG_ANSWERS_HASH} });

		for my $test (@{ $pg_problem->{metadata}{testing} }) {
			my $correct_answers = {};
			$correct_answers->{ $all_answer_labels[$_] } = $test->{answers}[$_] // '' for (0 .. $#all_answer_labels);
			push(@test_runs, runSingleTest($pg_problem, $test->{seed}, $correct_answers));
		}
	} else {    # If not, run some number of random seeds and return the results.
		say "Testing using random seeds." if $verbose;
		my $pg_random = PGrandom->new();
		$num_seeds = scalar(@seeds) if @seeds;

		for (1 .. $num_seeds) {
			# run the problem with a random seed and then test against the correct answers.
			my $seed = @seeds ? $seeds[ $_ - 1 ] : int($pg_random->rand(10000));

			push(@test_runs, runSingleTest($pg_problem, $seed));
		}
	}
	push(@problem_results, { %$test_result, test_runs => \@test_runs });
}

my $run_output;
if ($format eq 'json') {
	$run_output = encode_json(\@problem_results);
} elsif ($format eq 'yaml') {
	my $yaml = YAML::XS->new;
	$run_output = $yaml->dump(\@problem_results);
} elsif ($format eq 'text') {
	$run_output = "";
	for my $run (@problem_results) {
		$run_output .= "Problem: $run->{path}\n";
		if ($run->{pg_critic_violations}) {
			$run_output .= "PG Critic Violations:\n";
			for my $violation (@{ $run->{pg_critic_violations} }) {
				$run_output .= "  - Policy: $violation->{policy}\n";
				$run_output .= "    Explanation: $violation->{explanation}{explanation}\n";
			}
		}
		if ($run->{metadata_errors}) {
			$run_output .= "  Metadata Errors:\n";
			for (keys %{ $run->{metadata_errors} }) {
				$run_output .= "    $_: $run->{metadata_errors}{$_}\n";
			}
		}
		for (@{ $run->{test_runs} }) {
			if ($_->{deprecated}) {
				$run_output .= "    Test not run: $_->{deprecated}";
				next;
			}
			$run_output .= "  Seed: $_->{seed}\n";
			$run_output .= "  Score: $_->{score}\n";
			$run_output .= "  Warnings: $_->{warnings}\n" if $_->{warnings};
			$run_output .= "  Errors: $_->{errors}\n"     if $_->{errors};
			$run_output .= "\n";
		}
	}
}

if ($output_file) {
	my $output_path = Mojo::File->new($output_file);
	$output_path->spurt($run_output);
	say "Output written to: $output_file" if $verbose;
} else {
	say $run_output;
}

sub runSingleTest($pg_problem, $seed, $correct_answers = undef) {
	$correct_answers = $pg_problem->extractAllCorrectAnswers($seed) unless defined($correct_answers);
	if ($correct_answers->{deprecated}) {
		return $correct_answers;
	}
	my $pg = WeBWorK::PG->new(
		r_source    => \$pg_problem->{problem_source},
		problemSeed => $seed,
		inputs_ref  => $correct_answers,
		$pg_problem->pg_options
	);

	my $result = {
		seed  => $seed,
		score => $pg->{result}{score}
	};
	$result->{warnings} = $pg->{warnings} if $pg->{warnings};
	$result->{errors}   = $pg->{errors}   if $pg->{errors};
	return $result;
}

1;
