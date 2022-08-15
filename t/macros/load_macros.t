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

use WeBWorK::PG;

my %baseMacros = ('PG.pl' => 1, 'PGstandard.pl' => 1);

my %brokenMacros = ('answerDiscussion.pl' => 1);

opendir my $dir, "$ENV{PG_ROOT}/macros" or die "Unable to open pg macro directory: $!";
my @macro_files = sort grep { !/^\./ && /\.pl$/ && !$baseMacros{$_} && !$brokenMacros{$_} } readdir $dir;
closedir $dir;

for (@macro_files) {
	subtest $_ => sub {
		my $pg = WeBWorK::PG->new(r_source => \"DOCUMENT(); loadMacros('PGstandard.pl', '$_'); ENDDOCUMENT();");

		is($pg->{errors},   '', 'macro loads without errors');
		is($pg->{warnings}, '', 'macro loads without warnings');

		$pg->free;
	};
}

done_testing;
