#!/usr/bin/env perl

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

use lib "$ENV{PG_ROOT}/lib";

use Units;
use Parser::Legacy::NumberWithUnits;

loadMacros('parserNumberWithUnits.pl');

my $second      = NumberWithUnits(1, 's');
my $millisecond = NumberWithUnits(1, 'ms');
my $microsecond = NumberWithUnits(1, 'us');
my $nanosecond  = NumberWithUnits(1, 'ns');    # used in optics

my $min  = NumberWithUnits(1, 'min');
my $hour = NumberWithUnits(1, 'hour');
my $day  = NumberWithUnits(1, 'day');
my $year = NumberWithUnits(1, 'yr');

subtest 'LaTeX output' => sub {
	is $second->TeX, '1\ {\rm s}', 'LaTeX output for 1 second';

	my $todo = todo 'Display units with greek mu';
	is $microsecond->TeX, '1\ {\rm \mu s}', 'LaTeX output for 1 microsecond';
};

subtest 'Shorter times' => sub {
	is check_score($millisecond * Real(1000), $second), 1, 'a thousand millis in a second';
	is check_score($microsecond * Real(1E6),  $second), 1, 'a million micros in a second';
	is check_score($nanosecond * Real(1E9),   $second), 1, 'a billion nanos in a second';
};

subtest 'Longer times' => sub {
	is check_score($min / Real(60),                  $second), 1, '60 seconds in each minute run';
	is check_score($hour / Real(3600),               $second), 1, '60 minutes in an hour';
	is check_score($day / Real(24 * 3600),           $second), 1, '24 hours a day';
	is check_score($year / Real(365.25 * 24 * 3600), $second), 1, 'an extra day every 4 years';
};

done_testing();
