#!/usr/bin/env perl

=head1 MathObjects - Vector

Test creation and manipulation of Vector math objects.

=cut

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

loadMacros('MathObjects.pl');

Context('Vector');

subtest 'Creating a Vector' => sub {
	my $v1 = Vector(1, 2, 3);
	my $v2 = Vector([ 1, 2, 3 ]);
	my $v3 = Compute('<1,2,3>');
	my $v4 = Compute('i + 2j + 3k');

	for my $v ($v1, $v2, $v3, $v4) {
		is $v->class, 'Vector', 'a Vector has class Vector';
		is $v->type,  'Vector', 'a Vector has type Vector';

		ok Value::isValue($v),   'a Vector is a value';
		ok !Value::isNumber($v), 'a Vector is not a number';

		is [ $v->value ], [ 1, 2, 3 ], 'the coordinates are correct';
	}
};

subtest 'ijk notation' => sub {
	is Vector(1, 2, 3)->ijk, 'i+2j+3k', 'ijk string form of a 3-space vector';

	like(
		dies { Vector(1, 2, 3, 4)->ijk },
		qr/Method 'ijk' can only be used on Vectors in 3-space/,
		'ijk is not defined for vectors with more than 3 coordinates'
	);
};

subtest 'Dot product' => sub {
	my $v1 = Vector(1, 2, 3);
	my $v2 = Vector(4, 5, 6);

	is $v1->dot($v2)->value, 32, 'dot product of two vectors';

	like(
		dies { $v1->dot(Vector(1, 2)) },
		qr/Can't dot Vectors with different numbers of coordinates/,
		'dot product requires matching dimensions'
	);
};

subtest 'Cross product' => sub {
	my $v1 = Vector(1, 2, 3);
	my $v2 = Vector(4, 5, 6);

	is check_score($v1->cross($v2), '<-3,6,-3>'), 1, 'cross product of two 3-space vectors';

	like(
		dies { $v1->cross(Vector(1, 2)) },
		qr/Vectors for cross product must be in 3-space/,
		'cross product requires 3-space vectors'
	);
};

subtest 'Norm and unit vector' => sub {
	my $v = Vector(3, 4);

	is $v->norm->value, 5, 'norm (length) of a vector';
	is $v->abs->value,  5, 'abs is the same as norm';

	is check_score($v->unit, '<3/5, 4/5>'), 1, 'unit vector has length 1 and same direction';
};

subtest 'Parallel vectors' => sub {
	my $v1 = Vector(1, 2, 3);

	ok $v1->isParallel(Vector(2,   4, 6)),  'parallel vectors (same direction) are detected';
	ok $v1->isParallel(Vector(-1, -2, -3)), 'parallel vectors (opposite direction) are detected';
	ok !$v1->isParallel(Vector(1,  2, 4)),  'nonparallel vectors are not parallel';
};

subtest 'Arithmetic with Vectors' => sub {
	my $v1 = Vector(1, 2, 3);
	my $v2 = Vector(4, 5, 6);

	is check_score($v1 + $v2, '<5,7,9>'),    1, 'addition of vectors';
	is check_score($v1 - $v2, '<-3,-3,-3>'), 1, 'subtraction of vectors';
	is check_score(2 * $v1,   '<2,4,6>'),    1, 'scalar multiplication of a vector';
	is check_score(-$v1,      '<-1,-2,-3>'), 1, 'negation of a vector';

	ok $v1 == Vector(1, 2, 3), 'equality of vectors';
	ok $v1 != $v2,             'inequality of vectors';

	like(
		dies { $v1 + Vector(1, 2) },
		qr/Can't add Vectors with different numbers of coordinates/,
		'addition requires matching dimensions'
	);
	like(
		dies { $v1 - Vector(1, 2) },
		qr/Can't subtract Vectors with different numbers of coordinates/,
		'subtraction requires matching dimensions'
	);
	like(
		dies { $v1 * $v2 },
		qr/Vectors can only be multiplied by Numbers/,
		'a vector cannot be multiplied by another vector with *'
	);
	like(dies { $v1 / 0 }, qr/Division by zero/,              'division by zero is an error');
	like(dies { $v1**2 },  qr/Can't raise Vectors to powers/, 'a vector cannot be raised to a power');
};

Context('Numeric');

done_testing();
