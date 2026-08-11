#!/usr/bin/env perl

=head1 MathObjects - Matrix linear algebra

Test the linear algebra methods of Matrix math objects that are passed through to
C<MatrixReal1.pm> (C<det>, C<inverse>, C<trace>, C<norm_one>, C<norm_max>, C<solve>, C<order>) and
the C<power> operator, which are not covered by C<t/math_objects/matrix.t>.

=cut

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

loadMacros('MathObjects.pl');

Context('Matrix');

subtest 'Determinant' => sub {
	is check_score(Matrix([ 2, 1 ], [ 1, 1 ])->det, '1'), 1, 'determinant of a 2x2 matrix';
	is check_score(Matrix([ 1, 2, 3 ], [ 0, 1, 4 ], [ 5, 6, 0 ])->det, '1'), 1, 'determinant of a 3x3 matrix';

	like(
		dies { Matrix([ 1, 2, 3 ], [ 4, 5, 6 ])->det },
		qr/Can't take determinant of non-square matrix/,
		'determinant requires a square matrix'
	);
	like(
		dies { Matrix([ [ 1, 2 ], [ 3, 4 ] ], [ [ 5, 6 ], [ 7, 8 ] ])->det },
		qr/Matrix must be two-dimensional/,
		'determinant is not defined for a degree 3 tensor'
	);
};

subtest 'Inverse' => sub {
	my $A = Matrix([ 2, 1 ], [ 1, 1 ]);
	is check_score($A->inverse, '[[1,-1],[-1,2]]'), 1, 'inverse of an invertible 2x2 matrix';
	ok $A * $A->inverse == Value::Matrix->I(2), 'a matrix times its inverse is the identity';

	my $singular = Matrix([ 1, 2 ], [ 2, 4 ]);
	ok !defined($singular->inverse), 'inverse of a singular matrix is undefined';
};

subtest 'Trace' => sub {
	is Matrix([ 2, 1 ], [ 1, 1 ])->trace, 3, 'trace of a 2x2 matrix';
	is Matrix([ 1, 0, 0 ], [ 0, 2, 0 ], [ 0, 0, 3 ])->trace, 6, 'trace of a 3x3 diagonal matrix';
};

subtest 'Norms' => sub {
	my $A = Matrix([ 2, 1 ], [ 1, 1 ]);
	is $A->norm_one->value, 3, 'norm_one is the maximum absolute column sum';
	is $A->norm_max->value, 3, 'norm_max is the maximum absolute row sum';
};

subtest 'Solving a linear system' => sub {
	my $A = Matrix([ 2, 1 ], [ 1, 1 ]);
	my $b = Matrix([5],      [6]);

	my ($d, $x) = $A->solve($b);
	ok $A * $x == $b, 'the solution satisfies A x = b';
};

subtest 'Order of the LR decomposition' => sub {
	is Matrix([ 2, 1 ], [ 1, 1 ])->order, 2, 'order of a full-rank 2x2 matrix';
};

subtest 'Matrix powers' => sub {
	my $A = Matrix([ 2, 1 ], [ 1, 1 ]);

	is check_score($A**2, '[[5,3],[3,2]]'), 1, 'squaring a matrix';
	ok $A**0 == Value::Matrix->I(2), 'a matrix to the 0 power is the identity';
	ok $A**-1 == $A->inverse,        'a matrix to the -1 power is its inverse';

	like(
		dies { Matrix([ 1, 2, 3 ], [ 4, 5, 6 ])**2 },
		qr/Only square matrices can be raised to a power/,
		'only square matrices can be raised to a power'
	);
	like(dies { $A**1.5 }, qr/Matrix powers must be non-negative integers/, 'a matrix power must be an integer');
};

Context('Numeric');

done_testing();
