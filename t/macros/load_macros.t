#!/usr/bin/env perl

=head1 Test macro loading

This tests the pg/macro files to see that they all load without errors or
warnings.

Note that macros that are broken are listed in C<%brokenMacros> and testing of
these macros is skipped.  These macros should be fixed or considered for
deletion.

=cut

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
use lib "$ENV{PG_ROOT}/lib";

use Test2::V0;
use File::Find;

use WeBWorK::PG;

my %baseMacros = (
	'PG.pl'                   => 1,
	'PGstandard.pl'           => 1,
	'PGbasicmacros.pl'        => 1,
	'PGanswermacros.pl'       => 1,
	'PGauxiliaryFunctions.pl' => 1,
	'customizeLaTeX.pl'       => 1,
	'PGnumericevaluators.pl'  => 1,
	'PGfunctionevaluators.pl' => 1,
	'PGstringevaluators.pl'   => 1,
	'PGmiscevaluators.pl'     => 1,
	'PGcommonFunctions.pl'    => 1
);

my %brokenMacros = ('answerDiscussion.pl' => 1);

# Find all macro files inside the $ENV{PG_ROOT}/macros directory.
my @macro_files;
find(
	sub {
		# Must be a file that has the ".pl" suffix.
		return unless -f && /\.pl$/;
		push @macro_files, $_;
	},
	"$ENV{PG_ROOT}/macros"
);

@macro_files = sort grep { !$baseMacros{$_} && !$brokenMacros{$_} } @macro_files;

for (@macro_files) {
	subtest $_ => sub {
		my $pg = WeBWorK::PG->new(
			r_source         => \"DOCUMENT(); loadMacros('PGstandard.pl', '$_'); ENDDOCUMENT();",
			debuggingOptions => { view_problem_debugging_info => 1 }
		);

		is($pg->{errors},   '', 'macro loads without errors');
		is($pg->{warnings}, '', 'macro loads without warnings');

		$pg->free;
	};
}

done_testing;
