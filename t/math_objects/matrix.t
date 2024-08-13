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
subtest 'Creating Matrices' => sub {
	my $values = [ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ] ];
	my $A      = Matrix($values);
	is $A->class,     'Matrix', 'Input as array ref is a Matrix.';
	is [ $A->value ], $values,  'The entry values is correct.';
	my $B = Matrix('[[1,2,3,4],[5,6,7,8], [9,10,11,12]]');
	is $B->class, 'Matrix', 'Input as a string is a Matrix.';
	my $C = Compute('[[1,2,3,4],[5,6,7,8], [9,10,11,12]]');
	is $C->class, 'Matrix', 'Input using Compute is a Matrix.';
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

subtest 'Set an individual element' => sub {
	my $A1 = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7,  8 ], [ 9, 10, 11, 12 ] ]);
	my $A2 = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, -5, 8 ], [ 9, 10, 11, 12 ] ]);
	$A1->setElement([ 2, 3 ], -5);
	is $A1->TeX, $A2->TeX, 'Setting an individual element.';

	my $B1 = Matrix([ [ [ 1, 2 ], [ 3, 4 ] ], [ [ 5, 6 ], [ 7, 8 ] ] ]);
	$B1->setElement([ 1, 2, 2 ], 10);
	my $B2 = Matrix([ [ [ 1, 2 ], [ 3, 10 ] ], [ [ 5, 6 ], [ 7, 8 ] ] ]);
	is $B1->TeX, $B2->TeX, 'Setting an element in a 2x2x2 matrix.';
};

subtest 'Extract a row' => sub {
	my $A1  = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ] ]);
	my $row = Matrix([ 5, 6, 7, 8 ]);
	is $A1->row(2)->TeX, $row->TeX, 'Extract a row from a matrix.';

	like dies {
		$A1->row(-1);
	}, qr/Row must be a positive integer/, 'Test that an error is thrown for passing a non-positive integer.';
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

subtest 'Submatrix' => sub {
	my $A    = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ] ]);
	my $s1   = $A->subMatrix([ 2 .. 3 ], [ 2 .. 4 ]);
	my $sub1 = Matrix([ [ 6, 7, 8 ], [ 10, 11, 12 ] ]);
	my $s2   = $A->subMatrix(2, 3);
	my $sub2 = Matrix([ [ 1, 2, 4 ], [ 9, 10, 12 ] ]);
	my $s3   = $A->subMatrix([ 3, 1, 2 ], [ 1, 4, 2 ]);
	my $sub3 = Matrix([ [ 9, 12, 10 ], [ 1, 4, 2 ], [ 5, 8, 6 ] ]);

	is $s1->TeX, $sub1->TeX, 'Finding a submatrix giving the rows/cols in ordered form.';
	is $s2->TeX, $sub2->TeX, 'Finding a submatrix given the row/col to remove.';
	is $s3->TeX, $sub3->TeX, 'Finding a submatrix with rearranging rows/cols.';

	my $B = Matrix([ 2, 4, 6, 8 ]);

	is $B->subMatrix([3])->TeX, Matrix([6])->TeX, 'Finding a submatrix of a 1D matrix by passing in arrayref';
	is $B->subMatrix(3)->TeX, Matrix([ 2, 4, 8 ])->TeX,
		'Finding a submatrix of a 1D matrix by passing in an integer';

	my $B3     = Matrix([ [ [ 1, 2, 3 ], [ 4, 5, 6 ] ], [ [ 7, 8, 9 ], [ 10, 11, 12 ] ] ]);
	my $B3sub1 = Matrix([ [ [ 1, 3 ], [ 4, 6 ] ], [ [ 7, 9 ], [ 10, 12 ] ] ]);
	my $B3sub2 = Matrix([ [ [ 7, 8 ] ] ]);
	is $B3->subMatrix([ 1, 2 ], [ 1, 2 ], [ 1, 3 ])->TeX, $B3sub1->TeX,
		'Finding a submatrix of a 3D matrix by specifying indices.';
	is $B3->subMatrix(1, 2, 3)->TeX, $B3sub2->TeX,
		'Finding a submatrix of a 3D matrix by specifying integers (indices to eliminate).';

	like dies {
		$A->subMatrix(-1, 2);
	}, qr/The input -?\d+ is not a valid index/, 'check that error is thrown for an invalid row.';
	like dies {
		$A->subMatrix(10, 2);
	}, qr/The input -?\d+ is not a valid index/, 'check that error is thrown for an invalid row.';
	like dies {
		$A->subMatrix(2, -3);
	}, qr/The input -?\d+ is not a valid index/, 'check that error is thrown for an invalid column.';
	like dies {
		$A->subMatrix(2, 10);
	}, qr/The input -?\d+ is not a valid index/, 'check that error is thrown for an invalid column.';

	like dies {
		$A->subMatrix(1.1, 2);
	}, qr/The input -?[\.\d]+ is not a valid index/, 'check that error is thrown for an non integer row.';
	like dies {
		$A->subMatrix(1, 2.5);
	}, qr/The input -?[\.\d]+ is not a valid index/, 'check that error is thrown for an non integer column.';

	like dies {
		$A->subMatrix([ 1, 1.1, 2 ], [ 2, 3 ]);
	}, qr/The input -?[\.\d]+ is not a valid index/, 'check that error is thrown for an non integer row.';
	like dies {
		$A->subMatrix([ 1, 2 ], [ 2.5, 3 ]);
	}, qr/The input -?[\.\d]+ is not a valid index/, 'check that error is thrown for an non integer column.';

	like dies {
		$A->subMatrix([ 1, 2, 3 ], 2);
	}, qr/The inputs must both be integers or array refs/, 'check that error is thrown for mixing inputs.';
};

subtest 'Remove Row/Col' => sub {
	my $A = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ], [ 13, 14, 15, 16 ] ]);
	is $A->removeRow(2)->TeX, Matrix([ [ 1, 2, 3, 4 ], [ 9, 10, 11, 12 ], [ 13, 14, 15, 16 ] ])->TeX,
		'remove a row from a matrix.';

	like dies {
		$A->removeRow(5);
	}, qr/The input (.*) is not a valid row/, 'Testing for a row that doesn\' t exist . ';

	like dies {
		Matrix([ [ [ 1, 2 ], [ 3, 10 ] ], [ [ 5, 6 ], [ 7, 8 ] ] ])->removeRow(2);
	}, qr/The method removeRow is only valid for 2D matrices\./, '
        Try to remove a row of a 3 D matrix . ';

	is $A->removeColumn(3)->TeX, Matrix([ [ 1, 2, 4 ], [ 5, 6, 8 ], [ 9, 10, 12 ], [ 13, 14, 16 ] ])->TeX,
		' Remove a column from a matrix . ';

	like dies {
		$A->removeColumn(7);
	}, qr/The input (.*) is not a valid column/, ' Testing
        for a column that doesn \'t exist.';

	like dies {
		Matrix([ [ [ 1, 2 ], [ 3, 10 ] ], [ [ 5, 6 ], [ 7, 8 ] ] ])->removeColumn(2);
	}, qr/The method removeColumn is only valid for 2D matrices\./, 'Try to remove a column of a 3D matrix.';

};

done_testing;
