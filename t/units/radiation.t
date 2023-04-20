#!/usr/bin/env perl

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

use lib "$ENV{PG_ROOT}/lib";

use Units;
use Parser::Legacy::NumberWithUnits;

loadMacros('parserNumberWithUnits.pl');

my $sievert     = NumberWithUnits(1,   'Sv');
my $sievert_mSv = NumberWithUnits(1E3, 'mSv');
my $sievert_uSv = NumberWithUnits(1E6, 'uSv');

my $becquerel         = NumberWithUnits(1, 'Bq');
my $reciprocal_second = NumberWithUnits(1, 's^-1');

subtest 'LaTeX output' => sub {
	is $sievert->TeX, '1\ {\rm Sv}', 'LaTeX output for 1 sievert';

	my $todo = todo 'Display units with greek mu';
	is $sievert_uSv->TeX, '1\times 10^{6}\ {\rm \mu Sv}', 'LaTeX output for microSieverts';
};

subtest 'Equivalent dose' => sub {
	is check_score($sievert_mSv, $sievert), 1, '1 Sv in mSv';
	is check_score($sievert_uSv, $sievert), 1, '1 Sv in uSv';
};

subtest 'Radioactivity' => sub {
	is check_score($becquerel, $reciprocal_second), 1, 'a becquerel is a reciprocal second';
};

done_testing();
