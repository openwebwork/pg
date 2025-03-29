#!/usr/bin/env perl

=head1 MathObjects - Matrix

Tests creation and manipulation of Matrix math objects.

=cut

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

loadMacros('MathObjects.pl');

Context('Matrix');
use Data::Dumper;
subtest 'Creating a degree 1 Matrix (row vector)' => sub {
	ok my $M1 = Matrix(1, 2, 3), 'Create a row vector';
	is $M1->class, 'Matrix', 'M1 is a Matrix';
	my $M2 = Compute('[1,2,3]');
	is $M2->class,     'Matrix',    'Creation using Compute results in a Matrix.';
	is [ $M1->value ], [ 1, 2, 3 ], 'M1 is the row matrix [1,2,3]';
	is [ $M2->value ], [ 1, 2, 3 ], 'M2 is the row matrix [1,2,3]';
	is $M1->degree,    1,           'M1 is a degree 1 matrix.';
	is $M2->degree,    1,           'M2 is a degree 1 matrix.';
};

subtest 'Creating a degree 2 Matrix' => sub {
	my $values = [ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ] ];
	my $A      = Matrix($values);
	is $A->class,     'Matrix', 'Input as array ref is a Matrix.';
	is [ $A->value ], $values,  'The entry values is correct.';
	my $B = Matrix('[[1,2,3,4],[5,6,7,8], [9,10,11,12]]');
	is $B->class, 'Matrix', 'Input as a string is a Matrix.';
	my $C = Compute('[[1,2,3,4],[5,6,7,8], [9,10,11,12]]');
	is $C->class,  'Matrix', 'Input using Compute is a Matrix.';
	is $A->degree, 2,        'A is a degree 2 matrix.';
	is $C->degree, 2,        'C is a degree 2 matrix.';
};

subtest 'Creating a degree 3 Matrix (tensor)' => sub {
	my $values = [ [ [ 1, 2 ], [ 3, 4 ] ], [ [ 5, 6 ], [ 7, 8 ] ] ];
	ok my $M3 = Matrix([ [ 1, 2 ], [ 3, 4 ] ], [ [ 5, 6 ], [ 7, 8 ] ]), 'Creation of a tensor';
	is $M3->class, 'Matrix', 'Checking the result is a Matrix';
	# is $M3->value, $values, 'yay';
	# print Dumper ref($M3->value);
	is $M3->degree, 3, 'M3 is a degree 3 matrix.';
};

subtest 'Get dimensions' => sub {
	my $A       = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ] ]);
	my $B       = Matrix([ [ 1, 0, 0 ], [ 0, 1, 0 ], [ 0, 0, 1 ] ]);
	my $C       = Matrix([ [ [ 1, 2 ], [ 3, 4 ] ], [ [ 5, 6 ], [ 7, 8 ] ] ]);
	my $row     = Matrix([ 1, 2, 3, 4 ]);
	my @dimsA   = $A->dimensions;
	my @dimsB   = $B->dimensions;
	my @dimsC   = $C->dimensions;
	my @dimsRow = $row->dimensions;
	is \@dimsA,   [ 3, 4 ],    'The dimensions of A are correct.';
	is \@dimsB,   [ 3, 3 ],    'The dimensions of B are correct.';
	is \@dimsC,   [ 2, 2, 2 ], 'The dimensions of C are correct.';
	is \@dimsRow, [4],         'The dimensions of a row vector are correct.';
};

subtest 'Use isSquare, isOne, and isRow methods' => sub {
	my $A1 = Matrix([ 1, 2, 3, 4 ]);
	my $B1 = Matrix([1]);
	my $C1 = Matrix([2]);
	ok !$A1->isSquare, 'The matrix A1 is not square.';
	ok $B1->isSquare,  'The matrix B1 is square.';
	ok $C1->isSquare,  'The matrix C1 is square.';
	ok !$A1->isOne,    'The matrix A1 is not an identity.';
	ok $B1->isOne,     'The matrix B1 is an identity.';
	ok !$C1->isOne,    'The matrix C1 is not an identity.';
	ok $A1->isRow,     'The matrix A1 is a row.';
	ok $B1->isRow,     'The matrix B1 is a row.';
	ok $C1->isRow,     'The matrix C1 is a row.';

	my $A2 = Matrix([ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ]);
	my $B2 = Matrix([ 1, 0 ], [ 0, 1 ]);
	my $C2 = Matrix([ 2, 0 ], [ 1, 2 ]);
	ok !$A2->isSquare, 'The matrix A2 is not square.';
	ok $B2->isSquare,  'The matrix B2 is square.';
	ok $C2->isSquare,  'The matrix C2 is square.';
	ok !$A2->isOne,    'The matrix A2 is not an identity.';
	ok $B2->isOne,     'The matrix B2 is an identity.';
	ok !$C2->isOne,    'The matrix C2 is not an identity.';
	ok !$A2->isRow,    'The matrix A2 is not a row.';
	ok !$B2->isRow,    'The matrix B2 is not a row.';
	ok !$C2->isRow,    'The matrix C2 is not a row.';

	my $A3 = Matrix([ [ 1, 2, 3 ], [ 4, 5, 6 ] ], [ [ 7, 8, 9 ], [ 10, 11, 12 ] ]);
	my $B3 = Matrix([ [ 1, 0 ], [ 0, 1 ] ], [ [ 1, 0 ], [ 0, 1 ] ]);
	my $C3 = Matrix([ [ 2, 0 ], [ 0, 1 ] ], [ [ 1, 0 ], [ 0, 1 ] ]);
	ok !$A3->isSquare, 'The matrix A3 is not square.';
	ok $B3->isSquare,  'The matrix B3 is square.';
	ok $C3->isSquare,  'The matrix C3 is square.';
	ok !$A3->isOne,    'The matrix A3 is not an identity.';
	ok $B3->isOne,     'The matrix B3 is an identity.';
	ok !$C3->isOne,    'The matrix C3 is not an identity.';
	ok !$A3->isRow,    'The matrix A3 is not a row.';
	ok !$B3->isRow,    'The matrix B3 is not a row.';
	ok !$C3->isRow,    'The matrix C3 is not a row.';
};

subtest 'Use tests for triangular matrices' => sub {
	my $A1 = Matrix([ [ 1, 2, 3, 4 ], [ 0, 6, 7, 8 ], [ 0, 0, 11, 12 ], [ 0, 0, 0, 16 ] ]);
	my $A2 = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ], [ 13, 14, 15, 16 ] ]);
	my $A3 = Matrix($A1, $A1);
	my $A4 = Matrix($A2, $A1);
	ok $A1->isUpperTriangular,  'test for upper triangular matrix';
	ok !$A2->isUpperTriangular, 'not an upper triangular matrix';
	ok $A3->isUpperTriangular,  'test for upper triangular degree 3 matrix';
	ok !$A4->isUpperTriangular, 'not an upper triangular degree 3 matrix';
	my $B1 = Matrix([ [ 1, 0, 0, 0 ], [ 5, 6, 0, 0 ], [ 9, 10, 11, 0 ], [ 13, 14, 15, 16 ] ]);
	my $B2 = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ] ]);
	my $B3 = Matrix($B1, $B1);
	my $B4 = Matrix($B2, $B2);
	ok $B1->isLowerTriangular,  'test for lower triangular matrix';
	ok !$B2->isLowerTriangular, 'not a lower triangular matrix.';
	ok $B3->isLowerTriangular,  'test for lower triangular degree 3 matrix';
	ok !$B4->isLowerTriangular, 'not a lower triangular degree 3 matrix.';

};

subtest 'Test if a Matrix is symmetric' => sub {
	my $A = Matrix(5);
	ok $A->isSymmetric, 'test a degree 1 Matrix of length 1 is symmetric';
	my $B = Matrix([ 1, 2 ], [ 2, 3 ]);
	my $C = Matrix([ 1, 2 ], [ 3, 4 ]);
	ok $B->isSymmetric,  'test a degree 2 symmetric Matrix';
	ok !$C->isSymmetric, 'test a degree 2 nonsymmetric Matrix';
	my $D = Matrix($B, $B);
	my $E = Matrix($B, $C);
	ok $D->isSymmetric,  'test a degree 3 symmetric Matrix';
	ok !$E->isSymmetric, 'test a degree 3 nonsymmetric Matrix';
};

subtest 'Test if a Matrix is orthogonal' => sub {
	my $A = Matrix(-1);
	my $B = Matrix( 2);
	ok $A->isOrthogonal,  'test a degree 1 orthogonal Matrix';
	ok !$B->isOrthogonal, 'test a degree 1 nonorthogonal Matrix';
	my $C = Matrix([ 3 / 5, 4 / 5 ], [ -4 / 5, 3 / 5 ]);
	my $D = Matrix([ 1, 2 ], [ 3, 4 ]);
	ok $C->isOrthogonal,  'test a degree 2 orthogonal Matrix';
	ok !$D->isOrthogonal, 'test a degree 2 nonorthogonal Matrix';
	# uncomment these once transposition is valid for higher degree Matrices
	#my $E = Matrix($C, [ [ 0, 1 ], [ -1, 0 ] ]);
	#my $F = Matrix($D, $C);
	#ok $E->isOrthogonal,  'test a degree 3 orthogonal Matrix';
	#ok !$F->isOrthogonal, 'test a degree 3 nonorthogonal Matrix';
};

subtest 'Test if Matrix is in (R)REF' => sub {
	my $A1 = Matrix(0);
	my $A2 = Matrix(1);
	my $A3 = Matrix(2);
	my $A4 = Matrix(1, 3, 4);
	my $A5 = Matrix(2, 3, 4);
	my $A6 = Matrix(0, 3, 4);
	my $A7 = Matrix(0, 1, 4);
	ok $A1->isRREF,  "$A1 is in RREF";
	ok $A2->isRREF,  "$A2 is in RREF";
	ok !$A3->isRREF, "$A3 is not in RREF";
	ok $A4->isRREF,  "$A4 is in RREF";
	ok !$A5->isRREF, "$A5 is not in RREF";
	ok !$A6->isRREF, "$A6 is not in RREF";
	ok $A7->isRREF,  "$A7 is in RREF";

	my $B1 = Matrix([ 1, 2, 3 ], [ 0, 4, 5 ]);
	my $B2 = Matrix([ 1, 2, 3 ], [ 0, 1, 5 ]);
	my $B3 = Matrix([ 1, 0, 3 ], [ 0, 1, 5 ]);
	my $B4 = Matrix([ 0, 1, 3 ], [ 2, 1, 5 ]);
	ok $B1->isREF,   "$B1 is in REF";
	ok !$B1->isRREF, "$B1 is not in RREF";
	ok $B2->isREF,   "$B2 is in REF";
	ok !$B2->isRREF, "$B2 is not in RREF";
	ok $B3->isREF,   "$B3 is in REF";
	ok $B3->isRREF,  "$B3 is in RREF";
	ok !$B4->isREF,  "$B4 is not in REF";
	ok !$B4->isRREF, "$B4 is not in RREF";
};

subtest 'Transpose a Matrix' => sub {
	my $A = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ] ]);
	my $B = Matrix([ [ 1, 5, 9 ], [ 2, 6, 10 ], [ 3, 7, 11 ], [ 4, 8, 12 ] ]);
	is $A->transpose->TeX, $B->TeX, 'Test the tranpose of a matrix.';

	my $row       = Matrix([ 1, 2, 3, 4 ]);
	my $row_trans = Matrix([ [1], [2], [3], [4] ]);
	is $row->transpose->TeX, $row_trans->TeX, 'Transpose of a degree 1 Matrix.';

	my $C = Matrix([ [ [ 1, 2 ], [ 3, 4 ] ], [ [ 5, 6 ], [ 7, 8 ] ] ]);
	like dies {
		$C->transpose;
	}, qr/Can't transpose \d+-dimensional matrices/, "Can't tranpose a three-d matrix.";
};

subtest 'Extract an element' => sub {
	my $A   = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ] ]);
	my $B   = Matrix([ [ [ 1, 2 ], [ 3, 4 ] ], [ [ 5, 6 ], [ 7, 8 ] ] ]);
	my $row = Matrix([ 1, 2, 3, 4 ]);

	is $A->element(1, 1),    1,  'extract an element from a degree 2 matrix.';
	is $A->element(3, 2),    10, 'extract an element from a degree 2 matrix.';
	is $B->element(1, 2, 1), 3,  'extract an element from a degree 3 matrix.';
	is $row->element(2),     2,  'extract an element from a degree 1 matrix.';
};

subtest 'Extract a column' => sub {
	my $A1  = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ] ]);
	my $col = Matrix([ [2], [6], [10] ]);
	is $A1->column(2)->TeX, $col->TeX, 'Extract a column from a matrix.';

	like dies {
		$A1->column(-1);
	}, qr/Column must be a positive integer/, 'Test that an error is thrown for passing a non-positive integer.';
};

subtest 'Construct an identity matrix' => sub {
	my $I = Value::Matrix->I(3);
	my $B = Matrix([ [ 1, 0, 0 ], [ 0, 1, 0 ], [ 0, 0, 1 ] ]);
	my $A = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ] ]);

	is $I->TeX,    $B->TeX, 'Create a 3 x 3 identity matrix.';
	is $A->I->TeX, $B->TeX, 'Create a 3 x 3 identity matrix by using an existing matrix.';
};

subtest 'Construct a permutation matrix' => sub {
	my $P1 = Value::Matrix->P(3, [ 1, 2, 3 ]);
	is $P1->TeX, Matrix([ [ 0, 0, 1 ], [ 1, 0, 0 ], [ 0, 1, 0 ] ])->TeX, 'Create permuation matrix on cycle (123)';

	my $P2 = Value::Matrix->P(6, [ 1, 3 ], [ 2, 4, 6 ]);
	is $P2->TeX,
		Matrix([
			[ 0, 0, 1, 0, 0, 0 ],
			[ 0, 0, 0, 0, 0, 1 ],
			[ 1, 0, 0, 0, 0, 0 ],
			[ 0, 1, 0, 0, 0, 0 ],
			[ 0, 0, 0, 0, 1, 0 ],
			[ 0, 0, 0, 1, 0, 0 ]
		])->TeX, 'Create a permutation matrix on cycle product (13)(246)';

	my $A  = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ], [ 13, 14, 15, 16 ] ]);
	my $P3 = $A->P([ 1, 4 ]);
	is $P3->TeX,
		Matrix([ [ 0, 0, 0, 1 ], [ 0, 1, 0, 0 ], [ 0, 0, 1, 0 ], [ 1, 0, 0, 0 ] ])->TeX,
		'Create a permutation matrix based on an existing matrix.';
};

subtest 'Construct a zero matrix' => sub {
	my $Z1 = Matrix([ [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]);
	my $Z2 = Matrix([ [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]);
	is Value::Matrix->Zero(3, 4)->TeX, $Z1->TeX, 'Create a 3 by 4 zero matrix.';
	is Value::Matrix->Zero(4)->TeX,    $Z2->TeX, 'Create a 4 by 4 zero matrix.';

	my $A1 = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ] ]);
	is $A1->Zero->TeX, $Z1->TeX, 'Create a zero matrix with same size as the given one.';

	like dies {
		Value::Matrix->Zero(4, 0);
	}, qr/Dimension must be a positive integer/, 'Test that an error is thrown for passing a non-positive integer.';
};

subtest 'Add matrices' => sub {
	my $row1 = Matrix(1, 2, 3);
	my $row2 = Matrix(4, 5, 6);
	my $sum1 = Matrix(5, 7, 9);
	ok $row1+ $row2 == $sum1, 'Checking the sum of two row matrices.';

	my $A    = Matrix([ [ 1, 2, 3 ], [  4, 5,  6 ], [  7,  8, 9 ] ]);
	my $B    = Matrix([ [ 0, 1, 0 ], [ -1, 2, -3 ], [ -2, -1, 0 ] ]);
	my $sum2 = Matrix([ [ 1, 3, 3 ], [  3, 7,  3 ], [  5,  7, 9 ] ]);
	ok $A+ $B == $sum2, 'Checking the sum of two 3 by 3 matrices.';

	#tensors
	my $M1 = Matrix([ [ [ 1, 0 ], [ 0, 1 ] ], [ [ 1, 0 ], [ 0, 1 ] ] ]);
	my $M2 = Matrix([ [ [ 1, 2 ], [ 3, 4 ] ], [ [ 5, 6 ], [ 7, 8 ] ] ]);
	my $M3 = Matrix([ [ [ 2, 2 ], [ 3, 5 ] ], [ [ 6, 6 ], [ 7, 9 ] ] ]);
	ok $M1 + $M2 == $M3, 'Checking the sum of two tensors';

	my $row3 = Matrix([ 1, 2, 3, 4 ]);
	like dies { $row1 + $row3 }, qr/Can't add Matrices with different dimensions/,
		'Test that adding row matrices of different dimsensions throws an error.';

	my $C = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ] ]);
	like dies { $A + $C }, qr/Can't add Matrices with different dimensions/,
		'Test that adding matrices of different dimsensions throws an error.';

	my $M4 = Matrix([ [ [ 1, 2 ], [ 3, 4 ] ] ]);
	like dies { $M3 + $M4 }, qr/Can't add Matrices with different dimensions/,
		'Test that adding tensors of different dimsensions throws an error.';
};

subtest 'Subtract matrices' => sub {
	my $row1  = Matrix( 1,  2,  3);
	my $row2  = Matrix( 4,  5,  6);
	my $diff1 = Matrix(-3, -3, -3);
	ok $row1 - $row2 == $diff1, 'Checking the difference of two row matrices.';

	my $A     = Matrix([ [ 1, 2, 3 ], [  4, 5,  6 ], [  7,  8, 9 ] ]);
	my $B     = Matrix([ [ 0, 1, 0 ], [ -1, 2, -3 ], [ -2, -1, 0 ] ]);
	my $diff2 = Matrix([ [ 1, 1, 3 ], [  5, 3,  9 ], [  9,  9, 9 ] ]);
	ok $A - $B == $diff2, 'Checking the difference of two 3 by 3 matrices.';

	#tensors
	my $M1 = Matrix([ [ [ 1,  0 ], [  0,  1 ] ], [ [ 1,   0 ], [  0,  1 ] ] ]);
	my $M2 = Matrix([ [ [ 1,  2 ], [  3,  4 ] ], [ [ 5,   6 ], [  7,  8 ] ] ]);
	my $M3 = Matrix([ [ [ 0, -2 ], [ -3, -3 ] ], [ [ -4, -6 ], [ -7, -7 ] ] ]);
	ok $M1 - $M2 == $M3, 'Checking the difference of two tensors';

	my $row3 = Matrix([ 1, 2, 3, 4 ]);
	like dies { $row1 - $row3 }, qr/Can't subtract Matrices with different dimensions/,
		'Test that subtracting row matrices of different dimsensions throws an error.';

	my $C = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ] ]);
	like dies { $A - $C }, qr/Can't subtract Matrices with different dimensions/,
		'Test that subtracting matrices of different dimsensions throws an error.';

	my $M4 = Matrix([ [ [ 1, 2 ], [ 3, 4 ] ] ]);
	like dies { $M3 - $M4 }, qr/Can't subtract Matrices with different dimensions/,
		'Test that subtracting tensors of different dimsensions throws an error.';
};

subtest 'Multiply matrices' => sub {

	my $A     = Matrix([ [ 1, 2, 3 ],   [ 4, 5, 6 ],     [ 7, 8, 9 ] ]);
	my $B     = Matrix([ [ 0, 1, 0 ],   [ -1, 2, -3 ],   [ -2, -1, 0 ] ]);
	my $prod1 = Matrix([ [ -8, 2, -6 ], [ -17, 8, -15 ], [ -26, 14, -24 ] ]);
	my $C     = Matrix([ [ 1, -5, -2, -5 ],   [ 0, -5, 5, -4 ],     [ 4, 1, -1, 1 ] ]);
	my $prod2 = Matrix([ [ 13, -12, 5, -10 ], [ 28, -39, 11, -34 ], [ 43, -66, 17, -58 ] ]);
	ok $A*$B == $prod1, 'Checking the product of two 3 by 3 matrices.';
	ok $A*$C == $prod2, 'Checking the product of a 3 by 3 and 3 by 4 matrix';

	like dies { $C * $A }, qr/Matrices of dimensions \d+x\d+ and \d+x\d+ can't be multiplied/,
		'Test that multiplying row matrices of incompatible dimsensions throws an error.';

	# multiply degree 2 and 1 matrices.

	my $row   = Matrix(1,  2,  3);
	my $prod3 = Matrix(14, 32, 50);
	ok $A*$row == $prod3, 'Multiply a 3 by 3 matrix and a row matrix of length 3 (the row is promoted to a matrix)';

	my $col   = Matrix([ [1],  [2],  [3] ]);
	my $prod4 = Matrix([ [14], [32], [50] ]);
	ok $A*$col == $prod4, 'Multiply a 3 by 3 matrix and a column matrix of length 3';

	my $v     = Vector(1,  2,  3);
	my $prod5 = Vector(14, 32, 50);
	ok $A*$v == $prod5, 'Multiply a 3 by 3 matrix and a vector of length 3';
};

subtest 'Construct an elementary matrix' => sub {
	my $E1 = Value::Matrix->E(3, [ 1, 3 ]);
	is $E1->TeX, Matrix([ [ 0, 0, 1 ], [ 0, 1, 0 ], [ 1, 0, 0 ] ])->TeX, 'Elementary Matrix with a row swap';

	my $E2 = Value::Matrix->E(4, [2], 3);
	is $E2->TeX, Matrix([ [ 1, 0, 0, 0 ], [ 0, 3, 0, 0 ], [ 0, 0, 1, 0 ], [ 0, 0, 0, 1 ] ])->TeX,
		'Elementary Matrix with row multiple.';

	my $E3 = Value::Matrix->E(4, [ 3, 2 ], -3);
	is $E3->TeX, Matrix([ [ 1, 0, 0, 0 ], [ 0, 1, 0, 0 ], [ 0, -3, 1, 0 ], [ 0, 0, 0, 1 ] ])->TeX,
		'Elementary Matrix with row multiple and add.';
};

done_testing;
