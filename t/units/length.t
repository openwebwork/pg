#!/usr/bin/env perl

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

use lib "$ENV{PG_ROOT}/lib";

use Units;
use Parser::Legacy::NumberWithUnits;

loadMacros('parserNumberWithUnits.pl');

my $micron     = NumberWithUnits(1,   'um');
my $picometer  = NumberWithUnits(1E6, 'pm');
my $femtometer = NumberWithUnits(1E9, 'fm');

subtest 'LaTeX output' => sub {
	is $picometer->TeX, '1\times 10^{6}\ {\rm pm}', 'LaTeX output for 1E6 picometers';

	my $todo = todo 'Display units with greek mu';
	is $micron->TeX, '1\ {\rm \mu m}', 'LaTeX output for micrometers';
};

subtest 'Equivalent to micrometer' => sub {
	is check_score($picometer,  $micron), 1, '1 micrometer in picometers';
	is check_score($femtometer, $micron), 1, '1 micrometer in femtometers';
};

done_testing();
