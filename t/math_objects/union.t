#!/usr/bin/env perl

=head1 MathObjects - Union

Test creation and manipulation of Union math objects (unions of Intervals and Sets).

=cut

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

loadMacros('MathObjects.pl');

Context('Interval');

subtest 'Creating a Union of disjoint Intervals' => sub {
	my $u = Compute('(-inf,0) U (0,inf)');

	is $u->class, 'Union', 'a Union of disjoint intervals has class Union';
	ok Value::isValue($u), 'a Union is a value';
	ok $u->isSetOfReals,   'a Union is a set of reals';

	is check_score($u, '(0,inf) U (-inf,0)'), 1, 'order of the members of a Union does not matter';
};

subtest 'Overlapping and adjacent Intervals are merged when reduced' => sub {
	my $overlap  = Compute('[0,2) U [1,3)');
	my $adjacent = Compute('[0,1) U [1,2)');

	ok $overlap->isReduced,  'overlapping intervals are automatically reduced';
	ok $adjacent->isReduced, 'adjacent intervals are automatically reduced';

	is scalar(@{ $overlap->data }),  1, 'the reduced Union has a single member';
	is scalar(@{ $adjacent->data }), 1, 'the reduced Union has a single member';

	is check_score($overlap,  '[0,3)'), 1, 'overlapping intervals merge into their span';
	is check_score($adjacent, '[0,2)'), 1, 'adjacent intervals merge into their span';
};

subtest 'contains and isSubsetOf' => sub {
	my $u = Compute('[0,1) U [2,3)');

	ok $u->contains(Compute('0.5')),  'a Union contains a value in one of its members';
	ok !$u->contains(Compute('1.5')), 'a Union does not contain a value in the gap';

	ok Compute('[0,0.5)')->isSubsetOf($u),  'an Interval inside one member is a subset';
	ok !Compute('[0,1.5)')->isSubsetOf($u), 'an Interval spanning the gap is not a subset';
};

subtest 'Intersection of a Union' => sub {
	my $u = Compute('[0,1) U [2,3)');

	is check_score($u->intersect(Compute('[0.5,2.5)')), '[0.5,1) U [2,2.5)'), 1,
		'intersecting a Union with an Interval intersects each member';
};

subtest 'A Union of a Set and an Interval' => sub {
	my $u = Set(1, 2) + Compute('[3,4)');

	is $u->class,                        'Union', 'a Set unioned with a disjoint Interval is a Union';
	is check_score($u, '[3,4) U {1,2}'), 1,       'the Union contains both members';
};

subtest 'Errors constructing invalid Unions' => sub {
	like(
		dies { Compute('5 U [0,1)') },
		qr/Operands of 'U' must be intervals or sets/,
		'a Union operand must be an Interval or a Set'
	);
	like(dies { Union() }, qr/Empty unions are not allowed/, 'a Union must have at least one member');
};

Context('Numeric');

done_testing();
