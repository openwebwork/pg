#!/usr/bin/env perl

=head1 NAME

pg-critic.pl -- Analyze a pg file for use of old and current methods.

=head1 SYNOPSIS

    pg-critic.pl [options] file1 file2 ...

=head1 DESCRIPTION

This script analyzes the input files for old/deprecated functions and macros as well
as features for current best practices features.

See L<PGProblemCritic.pm> for details on what features are determined presence.

=head1 OPTIONS

The option C<-v> or C<--verbose> gives more information (on STDOUT) as the
script is run.

The option C<-s> or C<--score> will return a score for each given PG problem.

=cut

use strict;
use warnings;
use experimental 'signatures';
use feature 'say';

use Mojo::File qw(curfile);
use Getopt::Long;
use Data::Dumper;

use lib curfile->dirname->dirname . '/lib';

use WeBWorK::PG::PGProblemCritic qw(analyzePGfile);

my $verbose = 0;
my $score   = 0;
GetOptions(
	"v|verbose" => \$verbose,
	's|score'   => \$score
);

die 'arguments must have a list of pg files' unless @ARGV > 0;

# Give a problem an assessment score:

my $rubric = {
	metadata => -5,
	good     => {
		PGML           => 20,
		solution       => 30,
		hint           => 10,
		scaffold       => 50,
		custom_checker => 50,
		multianswer    => 30,
		answer_hints   => 20,
		nicetable      => 10,
	},
	bad => {
		BEGIN_TEXT              => -10,
		beginproblem            => -5,
		oldtable                => -25,
		num_cmp                 => -75,
		str_cmp                 => -75,
		fun_cmp                 => -75,
		context_texstrings      => -5,
		multiple_loadmacros     => -20,
		showPartialCorrect      => -5,
		old_multiple_choice     => -20,
		lines_below_enddocument => -5,
	},
	deprecated_macros => -10
};

sub scoreProblem ($prob) {
	my $score = 0;
	$score += (1 - $prob->{metadata}{$_}) * $rubric->{metadata} for (keys %{ $prob->{metadata} });
	$score += $prob->{good}{$_} * $rubric->{good}{$_}           for (keys %{ $prob->{good} });
	$score += $prob->{bad}{$_} * $rubric->{bad}{$_}             for (keys %{ $prob->{bad} });
	$score += $rubric->{deprecated_macros}                      for (@{ $prob->{deprecated_macros} });
	return $score;
}

for (grep { $_ =~ /\.pg$/ } @ARGV) {
	say $_ if $verbose;
	my $features = analyzePGfile($_);
	# print Dumper $features if $verbose;
	if ($score) {
		print Dumper scoreProblem($features) if $verbose;
	}
}

1;
