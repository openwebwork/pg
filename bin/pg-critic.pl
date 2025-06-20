#!/usr/bin/env perl

=head1 NAME

pg-critic.pl -- Analyze a pg file for use of old and current methods.

=head1 SYNOPSIS

    pg-critic.pl [options] file1 file2 ...

Options:

   -s|--score          Give a score for each file.
   -f|--format         Format of the output.  Default ('text') is a plain text listing of the filename
                       and the score.  'JSON' will make a JSON file.
                       For output format 'JSON', the filename output must also be assigned,
                       however for 'text', the output is optional.
   -o|--output-file    Filename for the output.  Note: this is required if JSON is the output format.
   -d|--details        Include the details in the output.  (Only used if the format is JSON).
   -v|--verbose        Increase the verbosity of the output.
   -h|--help           Show the help message.

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
use Mojo::Util qw(dumper);
use Mojo::JSON qw(encode_json);
use Getopt::Long;
use Pod::Usage;

use lib curfile->dirname->dirname . '/lib';

use WeBWorK::PG::PGProblemCritic qw(analyzePGfile);

my ($verbose, $show_score, $details, $show_help) = (0, 1, 0, 0);
my ($format, $filename) = ('text', '');
GetOptions(
	's|score'         => \$show_score,
	'f|format=s'      => \$format,
	'o|output-file=s' => \$filename,
	'd|details'       => \$details,
	"v|verbose"       => \$verbose,
	'h|help'          => \$show_help
);
pod2usage(2) if $show_help || !$show_score;

die 'arguments must have a list of pg files' unless @ARGV > 0;
die "The output format must be 'text' or 'JSON'" if (scalar(grep { $_ eq $format } qw(text JSON)) == 0);

my $output_file;
unless ($format eq 'text' && $filename eq '') {
	die "The output-file is required if using the format: $format" if $filename eq '';
	$output_file = Mojo::File->new($filename);
	my $dir = $output_file->dirname->realpath;
	die "The output directory $dir does not exist or is not a directory" unless -d $dir->to_string;
}

# Give a problem an assessment score:

my $rubric = {
	metadata => -5,    # score for each missing required metadta
	good     => {
		PGML           => 20,
		solution       => 30,
		hint           => 10,
		scaffold       => 50,
		custom_checker => 50,
		multianswer    => 30,
		answer_hints   => 20,
		nicetable      => 10,
		contexts       => { base_n        => 10, units         => 10, boolean           => 10, reaction   => 10 },
		parsers        => { radio_buttons => 10, checkbox_list => 10, radio_multianswer => 10, graph_tool => 10 },
		macros         => {
			random_person => 10,
			plots         => 10,
			tikz          => 10,
			plotly3D      => 10,
			latex_image   => 10,
			scaffold      => 10,
			answer_hints  => 10,
		}
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
		lines_below_enddocument => -5,
		macros                  => { ww_plot => -20, PGchoicemacros => -20 }
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

my @scores;

for (grep { $_ =~ /\.pg$/ } @ARGV) {
	say $_ if $verbose;
	my $features  = analyzePGfile($_);
	my $file_info = { file => $_, score => scoreProblem($features) };
	$file_info->{details} = $features if $details;
	push(@scores, $file_info);
}

if ($format eq 'text') {
	my $output_str = '';
	for my $score (@scores) {
		$output_str .= "filename: $score->{file}; score: $score->{score}\n";
	}
	if ($filename eq '') {
		say $output_str;
	} else {
		$output_file->spew($output_str);
		say "Results written in text format to $output_file" if $verbose;
	}
} elsif ($format eq 'JSON') {
	$output_file->spew(encode_json(\@scores));
	say "Results written in JSON format to $output_file" if $verbose;
}

1;
