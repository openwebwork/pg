#!/usr/bin/env perl

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

use lib "$ENV{PG_ROOT}/lib";

use Units qw(evaluate_units);
use Parser::Legacy::NumberWithUnits;

loadMacros('parserNumberWithUnits.pl');

my $cubic_meter = NumberWithUnits(1, 'm^3');
my $liter       = NumberWithUnits(1, 'L');
my $milliliter  = NumberWithUnits(1, 'ml');
my $deciliter   = NumberWithUnits(1, 'dL');

subtest 'metric LaTeX output' => sub {
	is $cubic_meter->TeX, '1\ {\rm m^{3}}', 'LaTeX output for 1 cubic meter';
	is $liter->TeX,       '1\ {\rm L}',     'LaTeX output for 1 liter';
	is $deciliter->TeX,   '1\ {\rm dL}',    'LaTeX output for 1 deciliter';
	is $milliliter->TeX,  '1\ {\rm ml}',    'LaTeX output for 1 milliliter';
};

subtest 'metric unit aliases' => sub {
	is { evaluate_units('ml') }, { evaluate_units('cc') }, '1 mL = 1 cc';
};

subtest 'metric volume conversion' => sub {
	is multiply_by(1000, evaluate_units('L')),  { evaluate_units('m^3') }, '1000 L = 1 m^3';
	is multiply_by(1000, evaluate_units('ml')), { evaluate_units('L') },   '1000 ml = 1 L';
	is multiply_by(10,   evaluate_units('dL')), { evaluate_units('L') },   '10 dL = 1 L';
};

my $gallon = NumberWithUnits(1, 'gal');
my $quart  = NumberWithUnits(1, 'qt');
my $pint   = NumberWithUnits(1, 'pt');
my $cup    = NumberWithUnits(1, 'cup');

subtest 'U.S. Units LaTeX output' => sub {
	is $gallon->TeX, '1\ {\rm gal}', 'LaTeX output for 1 gallon';
	is $quart->TeX,  '1\ {\rm qt}',  'LaTeX output for 1 quart';
	is $pint->TeX,   '1\ {\rm pt}',  'LaTeX output for 1 pint';
	is $cup->TeX,    '1\ {\rm cup}', 'LaTeX output for 1 cup';
};

subtest 'metric unit aliases' => sub {
	is { evaluate_units('cup') },    { evaluate_units('cups') },    'cups alias';
	is { evaluate_units('pt') },     { evaluate_units('pint') },    'pint alias';
	is { evaluate_units('pt') },     { evaluate_units('pints') },   'pints alias';
	is { evaluate_units('qt') },     { evaluate_units('quart') },   'quart alias';
	is { evaluate_units('qt') },     { evaluate_units('quarts') },  'pint alias';
	is { evaluate_units('gallon') }, { evaluate_units('gal') },     'gal alias';
	is { evaluate_units('gallon') }, { evaluate_units('gallons') }, 'gallons alias';
};

subtest 'U.S. volume conversion' => sub {
	is multiply_by(3.78541, evaluate_units('L')), { evaluate_units('gal') }, '3.785412 L = 1 gal';
	# Switch to check_score to do fuzzy comparison since cups/pints/quart/gallons are defined in
	# terms of cubic meters.
	is check_score(NumberWithUnits(2, 'cup'),   $pint),   1, '2 cups = 1 pint';
	is check_score(NumberWithUnits(2, 'pint'),  $quart),  1, '2 pints = 1 quart';
	is check_score(NumberWithUnits(4, 'quart'), $gallon), 1, '4 quarts = 1 gallon';
};

sub multiply_by {
	my ($conversion, %unit) = @_;
	$unit{factor} *= $conversion;
	return \%unit;
}

done_testing();
