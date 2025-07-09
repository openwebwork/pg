#!/usr/bin/env perl

=head1 NAME

pg-critic.pl - Command line interface to critque PG problem code.

=head1 SYNOPSIS

    pg-critic.pl [options] file1 file2 ...

Options:

    -f|--format         Format of the output, either 'text' or 'json'.
                        'text' is the default and will output a plain text
                        listing of the results. 'json' will output results in
                        JavaScript Object Notation.
    -o|--output-file    Filename to write output to. If not provided output will
                        be printed to STDOUT.
    -n|--no-details     Only show the filename and score and do not include the
                        details in the output for each file.
    -s|--strict         Disable "## no critic" annotations and force all
                        policies to be enforced.
    -h|--help           Show the help message.

=head1 DESCRIPTION

C<pg-critic.pl> is a PG problem source code analyzer.  It is the executable
front-end to the L<WeBWorK::PG::Critic> module, which attempts to identify
usage of old or deprecated PG features, as well as usage of newer features and
current best practices in coding a problem.

=cut

use Mojo::Base -signatures;

use Mojo::File qw(curfile path);
use Mojo::JSON qw(encode_json);
use Getopt::Long;
use Pod::Usage;

use lib curfile->dirname->dirname . '/lib';

use WeBWorK::PG::Critic qw(critiquePGFile);

GetOptions(
	'f|format=s'      => \my $format,
	'o|output-file=s' => \my $filename,
	'n|no-details'    => \my $noDetails,
	's|strict'        => \my $force,
	'h|help'          => \my $show_help
);
pod2usage(2) if $show_help;

$format //= 'text';

$format = lc($format);

unless (@ARGV) {
	say 'A list of pg problem files must be provided.';
	pod2usage(2);
}
unless ($format eq 'text' || $format eq 'json') {
	say 'The output format must be "text" or "json"';
	pod2usage(2);
}

sub scoreProblem (@violations) {
	my $score = 0;
	for (@violations) {
		if ($_->policy =~ /^Perl::Critic::Policy::PG::/) {
			$score += $_->explanation->{score} // 0;
		} else {
			# Deduct 5 points for any of the default Perl::Critic::Policy violations.
			# These will not have a score in the explanation.
			$score -= 5;
		}
	}
	return $score;
}

my @results;

for (@ARGV) {
	my @violations = critiquePGFile($_, $force);

	my (@positivePGResults, @negativePGResults, @perlCriticResults);
	if (!$noDetails) {
		@positivePGResults =
			grep { $_->policy =~ /^Perl::Critic::Policy::PG::/ && $_->explanation->{score} > 0 } @violations;
		@negativePGResults =
			grep { $_->policy =~ /^Perl::Critic::Policy::PG::/ && $_->explanation->{score} < 0 } @violations;
		@perlCriticResults = grep { $_->policy !~ /^Perl::Critic::Policy::PG::/ } @violations;
	}

	push(
		@results,
		{
			file  => $_,
			score => scoreProblem(@violations),
			$noDetails
			? ()
			: (
				positivePGResults => \@positivePGResults,
				negativePGResults => \@negativePGResults,
				perlCriticResults => \@perlCriticResults
			)
		}
	);
}

Perl::Critic::Violation::set_format('%m at line %l, column %c. (%p)');

my $outputMethod = $format eq 'json' ? \&encode_json : sub {
	my $results = shift;

	return join(
		"\n",
		map { (
			"filename: $_->{file}",
			"score: $_->{score}",
			@{ $_->{positivePGResults} // [] }
			? ('positive pg critic results:', map { "\t" . $_->to_string } @{ $_->{positivePGResults} })
			: (),
			@{ $_->{negativePGResults} // [] }
			? ('negative pg critic results:', map { "\t" . $_->to_string } @{ $_->{negativePGResults} })
			: (),
			@{ $_->{perlCriticResults} // [] }
			? ('perl critic results:', map { "\t" . $_->to_string } @{ $_->{perlCriticResults} })
			: ()
		) } @$results
	);
};

if ($filename) {
	eval { path($filename)->spew($outputMethod->(\@results), 'UTF-8') };
	if   ($@) { say "Unable to write results to $filename: $@"; }
	else      { say "Results written in $format format to $filename"; }
} else {
	say $outputMethod->(\@results);
}

1;
