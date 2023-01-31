#!/usr/bin/env perl

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

use lib "$ENV{PG_ROOT}/lib";

use Units;
use Parser::Legacy::NumberWithUnits;

loadMacros('parserNumberWithUnits.pl');

my $watt      = NumberWithUnits(1,    'W');
my $milliwatt = NumberWithUnits(1E3,  'mW');
my $megawatt  = NumberWithUnits(1E-6, 'MW');

my $amp      = NumberWithUnits(1,    'amp');
my $ampere   = NumberWithUnits(1,    'A');
my $milliamp = NumberWithUnits(1000, 'mA');

my $tesla      = NumberWithUnits(1,    'T');
my $millitesla = NumberWithUnits(1000, 'mT');
my $ten_gauss  = NumberWithUnits(10,   'G');
my $one_mT     = NumberWithUnits(1,    'mT');

my $coulomb      = NumberWithUnits(1,    'C');
my $millicoulomb = NumberWithUnits(1000, 'mC');
my $microcoulomb = NumberWithUnits(1E6,  'uC');
my $nanocoulomb  = NumberWithUnits(1E9,  'nC');

subtest 'Power units' => sub {
	is check_score($milliwatt, $watt), 1, '1000 milliwatts is 1 watt';
	is check_score($megawatt,  $watt), 1, '10^-6 megawatts is 1 watt';
};

subtest 'LaTeX output' => sub {
	is $millicoulomb->TeX, '1000\ {\rm mC}', 'LaTeX output for a thousand coulombs';

	my $todo = todo 'Display units with greek mu';
	is $microcoulomb->TeX, '1\times 10^{6}\ {\rm \mu C}', 'LaTeX output for micrometers';
};

subtest 'Current' => sub {
	is check_score($amp,      $ampere), 1, '1 amp is 1 ampere';
	is check_score($milliamp, $ampere), 1, '1000 milliamps is 1 ampere';
};

subtest 'Charge' => sub {
	is check_score($millicoulomb, $coulomb), 1, '1000 millicoulombs is 1 coulomb';
	is check_score($nanocoulomb,  $coulomb), 1, '10^9 nanocoulombs is 1 coulomb';
};

subtest 'Magnetic field' => sub {
	is check_score($millitesla, $tesla),     1, '1000 milliTesla is 1 Tesla';
	is check_score($one_mT,     $ten_gauss), 1, '1 milliTesla is 10 Gauss';
};

done_testing();
