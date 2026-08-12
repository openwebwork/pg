#!/usr/bin/env perl

=head1 MathObjects - Point

Test creation and manipulation of Point math objects.

=cut

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

loadMacros('MathObjects.pl');

Context('Point');

subtest 'Creating a Point' => sub {
	my $p1 = Point(1, 2, 3);
	my $p2 = Point([ 1, 2, 3 ]);
	my $p3 = Compute('(1,2,3)');

	for my $p ($p1, $p2, $p3) {
		is $p->class, 'Point', 'a Point has class Point';
		is $p->type,  'Point', 'a Point has type Point';

		ok Value::isValue($p),   'a Point is a value';
		ok !Value::isNumber($p), 'a Point is not a number';

		is [ $p->value ], [ 1, 2, 3 ], 'the coordinates are correct';
	}
};

subtest 'Adding and subtracting Points' => sub {
	my $p1 = Point(1, 2, 3);
	my $p2 = Point(4, 5, 6);

	is check_score($p1 + $p2, '(5,7,9)'),    1, 'sum of two Points is a Point';
	is check_score($p1 - $p2, '(-3,-3,-3)'), 1, 'difference of two Points is a Point';
	is(($p1 + $p2)->class, 'Point', 'sum of two Points has class Point');

	like(
		dies { $p1 + Point(1, 2) },
		qr/Can't add Points with different numbers of coordinates/,
		'addition requires matching dimensions'
	);
	like(
		dies { $p1 - Point(1, 2) },
		qr/Can't subtract Points with different numbers of coordinates/,
		'subtraction requires matching dimensions'
	);
};

subtest 'A Point combined with a Vector produces a Vector' => sub {
	my $p = Point(1, 2, 3);
	my $v = Vector(1, 1, 1);

	ok $p + $v == Vector(2, 3, 4), 'Point plus Vector is a Vector';
	is(($p + $v)->class, 'Vector', 'Point plus Vector has class Vector');
};

subtest 'Scalar multiplication and division' => sub {
	my $p = Point(1, 2, 3);

	is check_score(2 * $p, '(2,4,6)'),    1, 'scalar multiplication of a Point';
	is check_score(-$p,    '(-1,-2,-3)'), 1, 'negation of a Point';

	like(
		dies { $p * Point(1, 2, 3) },
		qr/Points can only be multiplied by Numbers/,
		'a Point cannot be multiplied by another Point'
	);
	like(dies { $p / 0 }, qr/Division by zero/,             'division by zero is an error');
	like(dies { $p**2 },  qr/Can't raise Points to powers/, 'a Point cannot be raised to a power');
};

subtest 'Comparing Points' => sub {
	ok Point(1, 2, 3) == Point(1, 2, 3), 'equal Points compare as equal';
	ok Point(1, 2, 3) != Point(1, 2, 4), 'different Points compare as not equal';
};

Context('Numeric');

done_testing();
