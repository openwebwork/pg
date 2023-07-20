#!/usr/bin/env perl

=head1 PGauxiliaryFunctions

Test methods in PGauxiliaryFunctions.

=cut

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

use lib "$ENV{PG_ROOT}/lib";

loadMacros('PGstandard.pl', 'MathObjects.pl');
use Data::Dumper;

Context('Interval');

subtest 'Build a basic interval' => sub {
	my $i1 = Interval(5, 10);
	is $i1->{data}[0]->{data}[0], 5,   'check left endpoint';
	is $i1->{data}[1]->{data}[0], 10,  'check right endpoint';
	is $i1->{open},               '(', 'check that the left endpoint is open';
	is $i1->{close},              ')', 'check that the right endpoint is open';
	is $i1->isEmpty,              0,   'check that the interval is not empty';
	is $i1->isReduced,            1,   'check that the interval is reduced.';

	my $i2 = Compute('[5,10]');
	is ref $i2,                   'Value::Interval', 'check that Compute creates and interval';
	is $i2->{data}[0]->{data}[0], 5,                 'check left endpoint';
	is $i2->{data}[1]->{data}[0], 10,                'check right endpoint';
	is $i2->{open},               '[',               'check that the left endpoint is closed';
	is $i2->{close},              ']',               'check that the right endpoint is closed';
	is $i2->isEmpty,              0,                 'check that the interval is not empty';
	is $i2->isReduced,            1,                 'check that the interval is reduced.';

	my $i3 = Interval('(', 5, 10, ')');
	is $i3->{data}[0]->{data}[0], 5,   'check left endpoint';
	is $i3->{data}[1]->{data}[0], 10,  'check right endpoint';
	is $i3->{open},               '(', 'check that the left endpoint is open';
	is $i3->{close},              ')', 'check that the right endpoint is open';
	is $i3->isEmpty,              0,   'check that the interval is not empty';
	is $i3->isReduced,            1,   'check that the interval is reduced.';
};

subtest 'Check that construction of intervals' => sub {
	ok Interval(0,   1) == Interval('(0,1)');
	ok Interval(0,   1) != Interval('[0,1]');
	ok Interval('(', 0, 1, ')') == Interval('(0,1)');
};

subtest 'Tests with intervals with infinite endpoints' => sub {
	my $i1 = Compute('[5,infinity)');
	ok !$i1->{leftInfinite}, 'check that the left endpoint is not infinite';
	ok $i1->{rightInfinite}, 'check that the right endpoint is infinite';
	is $i1->{open},  '[', 'check that the left endpoint is closed';
	is $i1->{close}, ')', 'check that the right endpoint is open';

	my $i2 = Compute('(-infinity,4)');
	ok $i2->{leftInfinite},   'check that the left endpoint is infinite';
	ok !$i2->{rightInfinite}, 'check that the right endpoint is not infinite';
	is $i2->{open},  '(', 'check that the left endpoint is open';
	is $i2->{close}, ')', 'check that the right endpoint is open';

	my $i3 = Compute('(-infinity,infinity)');
	ok $i3->{leftInfinite},  'check that the left endpoint is infinite';
	ok $i3->{rightInfinite}, 'check that the right endpoint is infinite';
	is $i3->{open},  '(', 'check that the left endpoint is open';
	is $i3->{close}, ')', 'check that the right endpoint is open';
};

subtest 'Build some illegal intervals' => sub {

	like dies { Compute('(3,2)') }, qr/Left endpoint must be less than right endpoint/,
		'Build an interval with left end greater than right';
	like dies { Compute('(infinity,2)') }, qr/The left endpoint of an interval can't be positive infinity/,
		'Build an interval with infinite left end';
	like dies { Compute('(3,-infinity)') }, qr/The right endpoint of an interval can't be negative infinity/,
		'Build an interval with infinite right end';
	like dies { Compute('[-infinity,3]') }, qr/Infinite endpoints must be open/, 'infinite left end is closed';
	like dies { Compute('[-3,infinity]') }, qr/Infinite endpoints must be open/, 'infinite right end is closed';
};

subtest 'Check unions and intersections' => sub {
	my $i1 = Compute('(1,5]');
	my $i2 = Compute('[2,7)');
	ok Compute("$i1 U $i2") == Compute('(1,7)'), 'find the union with finite intervals';
	ok $i1+ $i2 == Compute('(1,7)'),             'Find the union using perl + operator';
	ok $i1->intersect($i2) == Compute('[2,5]'),  'find the intersection with finite intervals';
	ok $i2->intersect($i1) == Compute('[2,5]'),  'find the intersection with finite intervals';

	my $i3 = Compute('(-infinity,7)');
	my $i4 = Compute('[4,infinity)');
	ok Compute("$i3 U $i4") == Compute('R'),    'find the union with infinite intervals';
	ok $i3+ $i4 == Compute('R'),                'find the union with infinite intervals using perl + operator';
	ok $i3->intersect($i4) == Compute('[4,7)'), 'find the intersection with infinite intervals';
	ok $i4->intersect($i3) == Compute('[4,7)'), 'find the intersection with infinite intervals';

	ok Interval('[1,2]')->intersect(Interval('(3,4)'))->isEmpty,
		'Check that non-overlapping intervals have empty intersection.';
};

subtest 'Check differences of intervals' => sub {
	ok Compute('(0,6]-(0,2]') == Interval('(2,6]'),  'Find the difference of two finite intervals';
	ok Compute('(0,6]-(-2,2]') == Interval('(2,6]'), 'Find the difference of two finite intervals';
	ok Compute('[0,6]-(1,2)') == Compute('[0,1]U[2,6]'),
		'Check a difference of intervals with one interval within the other';
	ok Compute('R-[-1,1]') == Compute('(-infinity,-1)U(1,infinity)'),
		'Check a difference of intervals with an infinite interval';
};

subtest 'Check subsets of intervals' => sub {
	ok Interval('[0,6]')->contains('[1,2]'),   'Check for subsets of finite intervals';
	ok Interval('[1,2]')->isSubsetOf('[0,6]'), 'Check for subsets of finite intervals';

	ok Interval('(-infinity,3)')->contains('[1,2]'),  'Check for subsets of infinite intervals';
	ok Interval('[1,2]')->isSubsetOf('(0,infinity)'), 'Check for subsets of infinite intervals';
};

done_testing();
