#!/usr/bin/env perl

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

use lib "$ENV{PG_ROOT}/lib";

use Units;
use Parser::Legacy::NumberWithUnits;

loadMacros('parserNumberWithUnits.pl');

my $Flops = { name => 'flops', conversion => { factor => 1, s => -1 } };
my $bogomips;

my $inv_sec = NumberWithUnits(4, 's^-1');

subtest 'Unknown unit' => sub {
	like
		dies { $bogomips = NumberWithUnits(4, 'flops') },
		qr/^Unrecognizable unit: \|flops\|/,
		"Dies if it can't find the unit";
};

subtest 'Add a new unit' => sub {
	my $todo = todo 'This will work when adding a new unit is fixed';
	ok(
		#lives { $bogomips = NumberWithUnits( 4, 'flops', {newUnit => $Flops}) },
		lives { $bogomips = NumberWithUnits(4, 'flops', { newUnit => 'flops' }) },
		"Can add a new unit in NumberWithUnits"
	) or note($@);

	ok(lives { check_score($bogomips, $inv_sec) }, 'This will work when adding a new unit is fixed');
};

subtest 'Overwrite an existing unit' => sub {
	my $Hurts = { name => 'Hz', conversion => { factor => 1, s => -1 } };
	my $donut = NumberWithUnits(4, 'Hz', { newUnit => $Hurts });
	my $cps   = NumberWithUnits(4, 'cycles*s^-1');

	my $todo = todo 'Will adding a newUnit overwrite the existing unit?';
	is check_score($donut, $cps),     0, "We redefined the Hertz";
	is check_score($donut, $inv_sec), 1, "Redefined as inverse seconds";
};

done_testing();
