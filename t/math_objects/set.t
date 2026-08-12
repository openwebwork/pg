#!/usr/bin/env perl

=head1 MathObjects - Set

Test creation and manipulation of Set math objects.

=cut

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

loadMacros('MathObjects.pl');

Context('Interval');

subtest 'Creating a Set' => sub {
	my $s1 = Set(1, 2, 3);
	my $s2 = Compute('{1,2,3}');

	for my $s ($s1, $s2) {
		is $s->class, 'Set', 'a Set has class Set';

		ok Value::isValue($s),   'a Set is a value';
		ok $s->isSetOfReals,     'a Set is a set of reals';
		ok !Value::isNumber($s), 'a Set is not a number';

		is [ $s->value ], [ 1, 2, 3 ], 'the elements are correct';
	}
};

subtest 'Sets sort and deduplicate their elements' => sub {
	is check_score(Set(3, 1, 2, 1), '{1,2,3}'), 1, 'a Set is sorted and deduplicated';
};

subtest 'isEmpty' => sub {
	ok Set()->isEmpty,   'a Set with no elements is empty';
	ok !Set(1)->isEmpty, 'a Set with an element is not empty';
};

subtest 'contains and isSubsetOf' => sub {
	my $s = Set(1, 2, 3);

	ok $s->contains(Compute('2')),  'a Set contains one of its elements';
	ok !$s->contains(Compute('4')), 'a Set does not contain a value that is not an element';

	ok Set(1,  2)->isSubsetOf($s), 'a Set of matching elements is a subset';
	ok !Set(1, 4)->isSubsetOf($s), 'a Set with an extra element is not a subset';
	ok Set()->isSubsetOf($s), 'the empty Set is a subset of every Set';
};

subtest 'Union of Sets (the + operator)' => sub {
	my $s1 = Set(1, 2, 3);
	my $s2 = Set(3, 4, 5);

	is check_score($s1 + $s2, '{1,2,3,4,5}'), 1, 'union of two Sets removes duplicate elements';
	is(($s1 + $s2)->class, 'Set', 'union of two Sets is a Set');
};

subtest 'Intersection of Sets' => sub {
	my $s1 = Set(1, 2, 3);
	my $s2 = Set(2, 3, 4);

	is check_score($s1->intersect($s2),             '{2,3}'), 1, 'intersection of two Sets';
	is check_score(Set(1, 2)->intersect(Set(3, 4)), '{}'),    1, 'intersection of disjoint Sets is empty';
};

subtest 'Sets combined with Intervals produce a Union or a Set' => sub {
	my $s = Set(1, 2, 3);

	is check_score($s->intersect(Compute('[2,5)')), '{2,3}'), 1,
		'intersection of a Set and an Interval can be a Set';
	is(($s + Compute('[4,5)'))->class, 'Union', 'union of a Set and a disjoint Interval is a Union');
};

subtest 'Errors constructing invalid Sets' => sub {
	like(
		dies { Set([ 1, 2 ], [ 3, 4 ]) },
		qr/An element of a set can't be a List of Numbers/,
		'a Set element must be a real number'
	);
};

Context('Numeric');

done_testing();
