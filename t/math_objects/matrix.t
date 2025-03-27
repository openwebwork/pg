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
subtest 'Creating degree 1 matrices (row vector)' => sub {
	ok my $M1 = Matrix(1, 2, 3), 'Create a row vector';
	is $M1->class, 'Matrix', 'M1 is a Matrix';
	my $M2 = Compute('[1,2,3]');
	is $M2->class,     'Matrix',    'Creation using Compute results in a Matrix.';
	is [ $M1->value ], [ 1, 2, 3 ], 'M1 is the row matrix [1,23]';
	is [ $M2->value ], [ 1, 2, 3 ], 'M2 is the row matrix [1,23]';
	is $M1->degree,    1,           'M1 is a degree 1 matrix.';
	is $M2->degree,    1,           'M2 is a degree 1 matrix.';
};

subtest 'Creating Matrices' => sub {
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

subtest 'Creating Tensors (degree 3)' => sub {
	my $values = [ [ [ 1, 2 ], [ 3, 4 ] ], [ [ 5, 6 ], [ 7, 8 ] ] ];
	ok my $M3 = Matrix([ [ 1, 2 ], [ 3, 4 ] ], [ [ 5, 6 ], [ 7, 8 ] ]), 'Creation of a tensor';
	is $M3->class, 'Matrix', 'Checking the result is a Matrix';
	# is $M3->value, $values, 'yay';
	# print Dumper ref($M3->value);
	is $M3->degree, 3, 'M3 is a degree 3 matrix.';
};

subtest 'Matrix Dimensions' => sub {
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

subtest 'isSquare and isOne' => sub {
	my $A = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ] ]);
	my $B = Matrix([ [ 1, 0, 0 ], [ 0, 1, 0 ], [ 0, 0, 1 ] ]);
	ok !$A->isSquare, 'The matrix A is not square.';
	ok $B->isSquare,  'The matrix B is square.';

	my $row_vect = Matrix([ 1, 2, 3, 4 ]);
	ok $row_vect->isRow, 'The matrix [[1,2,3,4]] is a row vector.';
	ok !$A->isRow,       'The matrix A is not a row vector.';

	ok !$A->isOne, 'The matrix A is not an identity matrix.';
	ok $B->isOne,  'The matrix B is an identity matrix.';

	# tensors (degree 3)
	my $D = Matrix([ [ [ 1, 0 ], [ 0, 1 ] ], [ [ 1, 0 ], [ 0, 1 ] ] ]);
	my $E = Matrix([ [ [ 1, 2 ], [ 3, 4 ] ] ]);
	my $F = Matrix([ [ [ 1, 2 ] ], [ [ 3, 4 ] ] ]);
	ok $D->isOne,     "The tensor D's last two dimensions is an identity";
	ok !$E->isOne,    "The tensor E's last two dimensions is not an identity";
	ok $E->isSquare,  'The tensor E is square.';
	ok !$F->isSquare, 'The tensor F is not square.';
};

subtest 'Triangular Matrices' => sub {
	my $A1 = Matrix([ [ 1, 2, 3, 4 ], [ 0, 6, 7, 8 ], [ 0, 0,  11, 12 ], [ 0,  0,  0,  16 ] ]);
	my $A2 = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ], [ 13, 14, 15, 16 ] ]);
	ok $A1->isUpperTriangular,  'test for upper triangular matrix';
	ok !$A2->isUpperTriangular, 'not an upper triangular matrix';
	my $B1 = Matrix([ [ 1, 0, 0, 0 ], [ 5, 6, 0, 0 ], [ 9, 10, 11, 0 ], [ 13, 14, 15, 16 ] ]);
	ok $B1->isLowerTriangular, 'test for lower triangular matrix';
	my $B2 = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ] ]);
	ok !$B2->isLowerTriangular, 'not a lower triangular matrix.';

};

subtest 'Transpose' => sub {
	my $A = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ] ]);
	my $B = Matrix([ [ 1, 5, 9 ], [ 2, 6, 10 ], [ 3, 7, 11 ], [ 4, 8, 12 ] ]);
	is $A->transpose->TeX, $B->TeX, 'Test the tranpose of a matrix.';

	my $row       = Matrix([ 1, 2, 3, 4 ]);
	my $row_trans = Matrix([ [1], [2], [3], [4] ]);
	is $row->transpose->TeX, $row_trans->TeX, 'Transpose of a Matrix with one row.';

	my $C = Matrix([ [ [ 1, 2 ], [ 3, 4 ] ], [ [ 5, 6 ], [ 7, 8 ] ] ]);
	like dies {
		$C->transpose;
	}, qr/Can't transpose \d+-dimensional matrices/, "Can't tranpose a three-d matrix.";
};

subtest 'Extract an element' => sub {
	my $A   = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ] ]);
	my $B   = Matrix([ [ [ 1, 2 ], [ 3, 4 ] ], [ [ 5, 6 ], [ 7, 8 ] ] ]);
	my $row = Matrix([ 1, 2, 3, 4 ]);

	is $A->element(1, 1),    1,  'extract an element from a 2D matrix.';
	is $A->element(3, 2),    10, 'extract an element from a 2D matrix.';
	is $B->element(1, 2, 1), 3,  'extract an element from a 3D matrix.';
	is $row->element(2),     2,  'extract an element from a row matrix';
};

subtest 'Extract a column' => sub {
	my $A1  = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ] ]);
	my $col = Matrix([ [2], [6], [10] ]);
	is $A1->column(2)->TeX, $col->TeX, 'Extract a column from a matrix.';

	like dies {
		$A1->column(-1);
	}, qr/Column must be a positive integer/, 'Test that an error is thrown for passing a non-positive integer.';
};

subtest 'Identity matrix' => sub {
	my $I = Value::Matrix->I(3);
	my $B = Matrix([ [ 1, 0, 0 ], [ 0, 1, 0 ], [ 0, 0, 1 ] ]);
	my $A = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ] ]);

	is $I->TeX,    $B->TeX, 'Create a 3 x 3 identity matrix.';
	is $A->I->TeX, $B->TeX, 'Create a 3 x 3 identity matrix by using an existing matrix.';
};

subtest 'Permutation matrices' => sub {
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

subtest 'Zero matrix' => sub {
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

subtest 'Add Matrices' => sub {
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

subtest 'Subtract Matrices' => sub {
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

subtest 'Multiply Matrices' => sub {

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

	#tensors
	# my $M1 = Matrix([ [ [ 1, 0 ], [ 0, 1 ] ], [ [ 1, 0 ], [ 0, 1 ] ] ]);
	# my $M2 = Matrix([ [ [ 1, 2 ], [ 3, 4 ] ], [ [ 5, 6 ], [ 7, 8 ] ] ]);
	# my $M3 = Matrix([ [ [ 2, 2 ], [ 3, 5 ] ], [ [ 6, 6 ], [ 7, 9 ] ] ]);
	# ok $M1 + $M2 == $M3, 'Checking the sum of two tensors';

	# my $row3 = Matrix([ 1, 2, 3, 4 ]);
	# like dies { $row1 + $row3 }, qr/Can't add Matrices with different dimensions/,
	# 	'Test that adding row matrices of different dimsensions throws an error.';

	# my $C = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ] ]);
	# like dies { $A + $C }, qr/Can't add Matrices with different dimensions/,
	# 	'Test that adding matrices of different dimsensions throws an error.';

	# my $M4 = Matrix([ [ [ 1, 2 ], [ 3, 4 ] ] ]);
	# like dies { $M3 + $M4 }, qr/Can't add Matrices with different dimensions/,
	# 	'Test that adding tensors of different dimsensions throws an error.';
};

subtest 'Elementary Matrices' => sub {
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
