###########################################################################
#
#  Implements the Matrix class.
#
#    @@@ Still needs lots of work @@@

=head1 Value::Matrix class

This is the Math Object code for a Matrix.

=head2 References:

=over

=item MathObject Matrix methods: L<http://webwork.maa.org/wiki/Matrix_(MathObject_Class)>

=item MathObject Contexts: L<http://webwork.maa.org/wiki/Common_Contexts>

=item CPAN RealMatrix docs: L<http://search.cpan.org/~leto/Math-MatrixReal-2.09/lib/Math/MatrixReal.pm>

=back

=head2 Matrix-Related libraries and macros:

=over

=item L<MatrixReal1>

=item L<MatrixReduce.pl>

=item L<Matrix>

=item L<MatrixCheckers.pl> -- checking whether vectors form a basis

=item L<MatrixReduce.pl>  -- tools for  row reduction via elementary matrices

=item L<MatrixUnits.pl>   -- Generates unimodular matrices with real entries

=item L<PGmatrixmacros.pl>

=item L<PGmorematrixmacros.pl>

=item L<PGnumericalmacros.pl>

=item L<tableau.pl>

=item L<quickMatrixEntry.pl>

=item L<LinearProgramming.pl>

=back

=head2 Contexts

=over

=item C<Matrix>

Allows students to enter C<[[3,4],[3,6]]>

=item C<Complex-Matrix>

Allows complex entries

=back


=head2 Creation of Matrices

Using the C<Matrix>, C<Vector> or C<ColumnVector> methods

Examples:

    $M1 = Matrix([1,2],[3,4]);
    $M2 = Matrix([5,6],[7,8]);

Commands added in Value::matrix

Conversion:

    $matrix->value produces [[3,4,5],[1,3,4]] recursive array references of numbers (not MathObjects)
    $matrix->wwMatrix   produces CPAN MatrixReal1 matrix, used for computation subroutines

Information

    $matrix->dimension:  ARRAY

Access values

    row : MathObjectMatrix
    column : MathObjectMatrix
    element : Real or Complex value

Update values

    setElement

See C<change_matrix_entry()> in MatrixReduce and L<http://webwork.maa.org/moodle/mod/forum/discuss.php?d=2970>

Passthrough methods covering subroutines in Matrix.pm which overrides or
augment CPAN's MatrixReal1.pm.  Matrix is a specialized subclass of MatrixReal1.pm

The actual calculations for these methods are done in C<pg/lib/Matrix.pm>

    trace
    proj
    proj_coeff
    L
    R
    PL
    PR

Passthrough methods covering subroutines in C<pg/lib/MatrixReal1.pm> (this has been modified to handle complex numbers)
The actual calculations are done in C<MatrixReal1.pm> subroutines.

The commands below are Value::Matrix B<methods> unless otherwise noted.

    condition
    det
    inverse
    is_symmetric
    decompose_LR
    dim
    norm_one
    norm_max
    kleene
    normalize
    solve_LR($v)    - LR decomposition
    solve($M,$v)    - function version of solve_LR
    order_LR        - order of LR decomposition matrix (number of non-zero equations)(also order() )
    order($M)       - function version of order_LR
    solve_GSM
    solve_SSM
    solve_RM

=head2 Fractions in Matrices

One can use fractions in Matrices by including C<Context("Fraction")>.  For example

    Context("Fraction");
    $A = Matrix([
      [Fraction(1,1), Fraction(1,2), Fraction(1,3)],
      [Fraction(1,2), Fraction(1,3), Fraction(1,4)],
      [Fraction(1,3), Fraction(1,4), Fraction(1,5)]]);

and operations will be done using rational arithmetic.   Also helpful is the method
C<apply_fraction_to_matrix_entries> in the L<MatrixReduce.pl> macro.   Some additional information can be
found in L<https://webwork.maa.org/moodle/mod/forum/discuss.php?d=2978>.

=head2 methods

=cut

package Value::Matrix;
my $pkg = 'Value::Matrix';

use strict;
use warnings;
no strict "refs";
use Matrix;
use Complex1;
our @ISA = qw(Value);

#
#  Convert a value to a matrix.  The value can be:
#     a list of numbers or list of (nested) references to arrays of numbers,
#     a point, vector or matrix object, a matrix-valued formula, or a string
#     that evaluates to a matrix
#
sub new {    #internal
	my $self    = shift;
	my $class   = ref($self) || $self;
	my $context = (Value::isContext($_[0]) ? shift : $self->context);
	my $M       = shift;
	$M = [] unless defined $M;
	$M = [ $M, @_ ]                                if scalar(@_) > 0;
	$M = @{$M}[0]                                  if ref($M) =~ m/^Matrix(Real1)?/;
	$M = Value::makeValue($M, context => $context) if ref($M) ne 'ARRAY';
	return bless { data => $M->data, context => $context }, $class
		if (Value::classMatch($M, 'Point', 'Vector', 'Matrix') && scalar(@_) == 0);
	return $M if Value::isFormula($M) && Value::classMatch($self, $M->type);
	my @M = (ref($M) eq 'ARRAY' ? @{$M} : $M);
	Value::Error("Matrices must have at least one entry") unless scalar(@M) > 0;
	return $self->matrixMatrix($context, @M)
		if ref($M[0]) eq 'ARRAY'
		|| Value::classMatch($M[0], 'Matrix', 'Vector', 'Point')
		|| (Value::isFormula($M[0]) && $M[0]->type =~ m/Matrix|Vector|Point/);
	return $self->numberMatrix($context, @M);
}

#
#  (Recursively) make a matrix from a list of array refs
#  and report errors about the entry types
#
sub matrixMatrix {    #internal
	my $self    = shift;
	my $class   = ref($self) || $self;
	my $context = shift;
	my ($x, $m);
	my @M         = ();
	my $isFormula = 0;
	for $x (@_) {
		if (Value::isFormula($x)) { push(@M, $x); $isFormula = 1 }
		else {
			$m = $self->new($context, $x);
			push(@M, $m);
			$isFormula = 1 if Value::isFormula($m);
		}
	}
	my ($type, $len) = ($M[0]->entryType->{name}, $M[0]->length);
	for $x (@M) {
		Value::Error("Matrix rows must all be the same type")
			unless (defined($x->entryType) && $type eq $x->entryType->{name});
		Value::Error("Matrix rows must all be the same length") unless ($len eq $x->length);
	}
	return $self->formula([@M]) if $isFormula;
	bless { data => [@M], context => $context }, $class;
}

#
#  Form a 1 x n matrix from a list of numbers
#  (could become a row of an  m x n  matrix)
#
sub numberMatrix {    #internal
	my $self      = shift;
	my $class     = ref($self) || $self;
	my $context   = shift;
	my @M         = ();
	my $isFormula = 0;
	for my $x (@_) {
		$x = Value::makeValue($x, context => $context);
		Value::Error("Matrix row entries must be numbers: $x ") unless _isNumber($x);
		push(@M, $x);
		$isFormula = 1 if Value::isFormula($x);
	}
	return $self->formula([@M]) if $isFormula;
	bless { data => [@M], context => $context }, $class;
}

=head3 value

Returns the array of arrayrefs of the matrix.

Usage:

    my $A = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ] ]);
    $A->value;

    # returns ([1,2,3,4],[5,6,7,8],[9,10,11,12])

=cut

sub value {
	my $self = shift;
	my $M    = $self->data;
	return @{$M} unless Value::classMatch($M->[0], 'Matrix');
	return map { [ $_->value ] } @$M;
}

=head3 dimensions

Returns the dimensions of the matrix as an array

Usage:

    my $A = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ] ]);
    $A->dimensions;

returns the array C<(3,4)>

    my $B = Matrix([ [ [ 1, 2 ], [ 3, 4 ] ], [ [ 5, 6 ], [ 7, 8 ] ] ]);
    $B->dimensions;

returns C<(2,2,2)>

=cut

#
#  Recursively get the dimensions of the matrix.
#  Returns (n) for a 1 x n, or (n,m) for an n x m, etc.
#
sub dimensions {
	my $self = shift;
	my $r    = $self->length;
	my $v    = $self->data;
	return ($r,) unless Value::classMatch($v->[0], 'Matrix');
	return ($r, $v->[0]->dimensions);
}

#
#  Return the proper type for the matrix
#
sub typeRef {
	my $self = shift;
	return Value::Type($self->class, $self->length, $Value::Type{number})
		unless Value::classMatch($self->data->[0], 'Matrix');
	return Value::Type($self->class, $self->length, $self->data->[0]->typeRef);
}

=head3 isSquare

Return true is the matrix is square, false otherwise

Usage:

    my $A = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ] ]);
    my $B = Matrix([ [ 1, 0, 0 ], [ 0, 1, 0 ], [ 0, 0, 1 ] ]);

    $A->isSquare; # is '' (false)
    $B->isSquare; # is 1 (true);

=cut

sub isSquare {
	my $self = shift;
	my @d    = $self->dimensions;

	return 1 if scalar(@d) == 1 && $d[0] == 1;
	return 0 if scalar(@d) != 2;
	return $d[0] == $d[1];
}

=head3 isRow

Return true if the matix is 1-dimensional (i.e., is a matrix row)

Usage:

    my $A = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ] ]);
    my $row_vect = Matrix([ 1, 2, 3, 4 ]);

    $A->isRow;         # is '' (false)
    $row_vect->isRow;  # is 1 (true)

=cut

sub isRow {
	my $self = shift;
	my @d    = $self->dimensions;
	return scalar(@d) == 1;
}

=head3 C<isOne>, check for identity matrix.

Usage:

    $A = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ], [13, 14, 15, 16] ]);
    $A->isOne;  # is false

    $B = Matrix([ [ 1, 0, 0 ], [ 0, 1, 0 ], [ 0, 0, 1 ] ]);
    $B->isOne; # is true;

=cut

sub isOne {
	my $self = shift;
	return 0 unless $self->isSquare;
	my $i = 0;
	for my $row (@{ $self->{data} }) {
		my $j = 0;
		for my $k (@{ $row->{data} }) {
			return 0 unless $k eq (($i == $j) ? "1" : "0");
			$j++;
		}
		$i++;
	}
	return 1;
}

=head3 C<isZero>, check for zero matrix.

Usage:

    $A = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ], [13, 14, 15, 16] ]);
    $A->isZero;  # is false

    $B = Matrix([ [ 0, 0, 0 ], [ 0, 0, 0 ], [ 0, 0, 0 ] ]);
    $B->isZero; # is true;

=cut

sub isZero {
	my $self = shift;
	for my $x (@{ $self->{data} }) { return 0 unless $x->isZero }
	return 1;
}

#
#  See if the matrix is triangular, diagonal, symmetric, orthogonal
#

sub isUpperTriangular {
	my $self = shift;
	my @d    = $self->dimensions;
	return 1 if scalar(@d) == 1;
	return 0 if scalar(@d) > 2;
	for my $i (2 .. $d[0]) {
		for my $j (1 .. ($i - 1 < $d[1] ? $i - 1 : $d[1])) {
			return 0 unless $self->element($i, $j) == 0;
		}
	}
	return 1;
}

sub isLowerTriangular {
	my $self = shift;
	my @d    = $self->dimensions;
	if (scalar(@d) == 1) {
		for ((@{ $self->{data} })[ 1 .. $#{ $self->{data} } ]) {
			return 0 unless $_ == 0;
		}
	}
	return 0 if scalar(@d) > 2;
	for my $i (1 .. $d[0] - 1) {
		for my $j ($i + 1 .. $d[1]) {
			return 0 unless $self->element($i, $j) == 0;
		}
	}
	return 1;
}

sub isDiagonal {
	my $self = shift;
	return $self->isSquare && $self->isUpperTriangular && $self->isLowerTriangular;
}

sub isSymmetric {
	my $self = shift;
	return 0 unless $self->isSquare;
	my $d = ($self->dimensions)[0];
	return 1 if $d == 1;
	for my $i (1 .. $d - 1) {
		for my $j ($i + 1 .. $d) {
			return 0 unless $self->element($i, $j) == $self->element($j, $i);
		}
	}
	return 1;
}

sub isOrthogonal {
	my $self = shift;
	return 0 unless $self->isSquare;
	my @d = $self->dimensions;
	if (scalar(@d) == 1) {
		return 0 unless ($self->{data}->[0] == 1 || $self->{data}->[0] == -1);
	}
	my $M = $self * $self->transpose;
	return $M->isOne;
}

#
#  See if the matrix is in (reduced) row echelon form
#

sub isREF {
	my $self = shift;
	my @d    = $self->dimensions;
	return 1 if scalar(@d) == 1;
	return 0 if scalar(@d) > 2;
	my $k = 0;
	for my $i (1 .. $d[0]) {
		for my $j (1 .. $d[1]) {
			if ($j <= $k) {
				return 0 unless $self->element($i, $j) == 0;
			} elsif ($self->element($i, $j) != 0) {
				$k = $j;
				last;
			} elsif ($j == $d[1]) {
				$k = $d[1] + 1;
			}
		}
	}
	return 1;
}

sub isRREF {
	my $self = shift;
	my @d    = $self->dimensions;
	return 1 if scalar(@d) == 1;
	return 0 if scalar(@d) > 2;
	my $k = 0;
	for my $i (1 .. $d[0]) {
		for my $j (1 .. $d[1]) {
			if ($j <= $k) {
				return 0 unless $self->element($i, $j) == 0;
			} elsif ($self->element($i, $j) != 0) {
				return 0 unless $self->element($i, $j) == 1;
				for my $m (1 .. $i - 1) {
					return 0 unless $self->element($m, $j) == 0;
				}
				$k = $j;
				last;
			} elsif ($j == $d[1]) {
				$k = $d[1] + 1;
			}
		}
	}
	return 1;
}

sub _isNumber {
	my $n = shift;
	return Value::isNumber($n) || Value::classMatch($n, 'Fraction');
}

#
#  Make arbitrary data into a matrix, if possible
#
sub promote {
	my $self    = shift;
	my $class   = ref($self) || $self;
	my $context = (Value::isContext($_[0]) ? shift : $self->context);
	my $x       = (scalar(@_)              ? shift : $self);
	return $self->new($context, $x, @_) if scalar(@_) > 0 || ref($x) eq 'ARRAY';
	$x = Value::makeValue($x, context => $context);
	return $x->inContext($context)              if ref($x) eq $class;
	return $self->make($context, @{ $x->data }) if Value::classMatch($x, 'Point', 'Vector');
	Value::Error("Can't convert %s to %s", Value::showClass($x), Value::showClass($self));
}

#
#  Don't inherit ColumnVector flag
#
sub noinherit {
	my $self = shift;
	return ("ColumnVector", "wwM", "lrM", $self->SUPER::noinherit);
}

############################################
#
#  Operations on matrices
#

sub add {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	my @l = @{ $l->data };
	my @r = @{ $r->data };
	Value::Error("Can't add Matrices with different dimensions")
		unless scalar(@l) == scalar(@r);
	my @s = ();
	for my $i (0 .. scalar(@l) - 1) { push(@s, $l[$i] + $r[$i]) }
	return $self->inherit($other)->make(@s);
}

sub sub {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	my @l = @{ $l->data };
	my @r = @{ $r->data };
	Value::Error("Can't subtract Matrices with different dimensions")
		unless scalar(@l) == scalar(@r);
	my @s = ();
	for my $i (0 .. scalar(@l) - 1) { push(@s, $l[$i] - $r[$i]) }
	return $self->inherit($other)->make(@s);
}

sub mult {
	my ($l, $r, $flag) = @_;
	my $self  = $l;
	my $other = $r;

	#  Perform constant multiplication.

	if (_isNumber($r)) {
		my @coords = ();
		for my $x (@{ $l->data }) { push(@coords, $x * $r) }
		return $self->make(@coords);
	}

	#  Make points and vectors into columns if they are on the right.
	$r = !$flag && Value::classMatch($r, 'Point', 'Vector') ? ($self->promote($r))->transpose : $self->promote($r);

	if ($flag) { my $tmp = $l; $l = $r; $r = $tmp }
	my @dl = $l->dimensions;
	my @dr = $r->dimensions;
	if (scalar(@dl) == 1) { @dl = (1, @dl); $l = $self->make($l) }
	if (scalar(@dr) == 1) { @dr = (@dr, 1); $r = $self->make($r)->transpose }
	Value::Error("Can only multiply 2-dimensional matrices") if scalar(@dl) > 2 || scalar(@dr) > 2;
	Value::Error("Matrices of dimensions %dx%d and %dx%d can't be multiplied", @dl, @dr) unless ($dl[1] == $dr[0]);

	#  Perform matrix multiplication.

	my @l = $l->value;
	my @r = $r->value;
	my @M = ();
	for my $i (0 .. $dl[0] - 1) {
		my @row = ();
		for my $j (0 .. $dr[1] - 1) {
			my $s = 0;
			for my $k (0 .. $dl[1] - 1) { $s += $l[$i]->[$k] * $r[$k]->[$j] }
			push(@row, $s);
		}
		push(@M, $self->make(@row));
	}
	$self = $self->inherit($other) if Value::isValue($other);
	return $self->make(@M);
}

sub div {
	my ($l, $r, $flag) = @_;
	my $self = $l;
	Value::Error("Can't divide by a Matrix") if $flag;
	Value::Error("Matrices can only be divided by Numbers") unless _isNumber($r);
	Value::Error("Division by zero") if $r == 0;
	my @coords = ();
	for my $x (@{ $l->data }) { push(@coords, $x / $r) }
	return $self->make(@coords);
}

sub power {
	my ($l, $r, $flag) = @_;
	my $self    = shift;
	my $context = $self->context;
	Value::Error("Can't use Matrices in exponents") if $flag;
	Value::Error("Only square matrices can be raised to a power") unless $l->isSquare;
	$r = Value::makeValue($r, context => $context);
	if (_isNumber($r) && $r =~ m/^-\d+$/) {
		$l = $l->inverse;
		$r = -$r;
		$self->Error("Matrix is not invertible") unless defined($l);
	}
	Value::Error("Matrix powers must be non-negative integers") unless _isNumber($r) && $r =~ m/^\d+$/;
	return $context->Package("Matrix")->I($l->length, $context) if $r == 0;
	my $M = $l;
	for my $i (2 .. $r) { $M = $M * $l }
	return $M;
}

#  Do lexicographic comparison (row by row)
sub compare {
	my ($self, $l, $r) = Value::checkOpOrderWithPromote(@_);
	Value::Error("Can't compare Matrices with different dimensions")
		unless join(',', $l->dimensions) eq join(',', $r->dimensions);
	my @l = @{ $l->data };
	my @r = @{ $r->data };
	for my $i (0 .. scalar(@l) - 1) {
		my $cmp = $l[$i] <=> $r[$i];
		return $cmp if $cmp;
	}
	return 0;
}

sub neg {
	my $self   = promote(@_);
	my @coords = ();
	foreach my $x (@{ $self->data }) { push(@coords, -$x) }
	return $self->make(@coords);
}

sub conj { shift->twiddle(@_) }

sub twiddle {
	my $self   = promote(@_);
	my @coords = ();
	for my $x (@{ $self->data }) { push(@coords, ($x->can("conj") ? $x->conj : $x)); }
	return $self->make(@coords);
}

=head3 C<transpose>

Take the transpose of a matrix.

Usage:

    $A = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ] ]);
    $A->transpose;

=cut

sub transpose {
	my $self = promote(@_);
	my @d    = $self->dimensions;
	if (scalar(@d) == 1) { @d = (1, @d); $self = $self->make($self) }
	Value::Error("Can't transpose %d-dimensional matrices", scalar(@d)) unless scalar(@d) == 2;

	my @M = ();
	my $M = $self->data;
	for my $j (0 .. $d[1] - 1) {
		my @row = ();
		for my $i (0 .. $d[0] - 1) { push(@row, $M->[$i]->data->[$j]) }
		push(@M, $self->make(@row));
	}
	return $self->make(@M);
}

=head3 C<I>, identity matrix

Get an identity matrix of the requested size

    Value::Matrix->I(n)

Usage:

    Value::Matrix->I(3); # returns a 3 by 3 identity matrix.
    $A->I; # return an n by n identity matrix, where n is the number of rows of A

=cut

sub I {
	my $self    = shift;
	my $d       = shift;
	my $context = shift || $self->context;
	$d = ($self->dimensions)[0] if !defined $d && ref($self);

	Value::Error("You must provide a dimension for the Identity matrix") unless defined $d;
	Value::Error("Dimension must be a positive integer")                 unless $d =~ m/^[1-9]\d*$/;

	my @M    = ();
	my $REAL = $context->Package('Real');

	for my $i (0 .. $d - 1) {
		push(@M, $self->make($context, map { $REAL->new(($_ == $i) ? 1 : 0) } 0 .. $d - 1));
	}
	return $self->make($context, @M);
}

=head3 C<E>, elementary matrix contruction

Get an elementary matrix of the requested size and type. These include matrix that upon left multiply will
perform row operations.

=over

=item * Row Swap

To perform a row swap between rows C<i> and C<j>, then C<E(n,[i, j])>.

Usage:

    my $E1 = Value::Matrix->E(3, [ 1, 3 ]);

returns the matrix
    [[0, 0, 1],
    [0, 1, 0],
    [1, 0, 0]]

or if the matrix C<$A> exists then

    $A->E([1, 3]);

where the size of the resulting matrix is the number of rows of C<$A>.

=item * Multiply a row by a constant

To create the matrix that will multiply a row C<i>, by constant C<k>, then C<E(n,[i],k)>

Usage:

    my $E2 = Value::Matrix->E(4, [2], 3);

generates the matrix

    [ [ 1, 0, 0, 0 ],
      [ 0, 4, 0, 0 ],
      [ 0, 0, 1, 0 ],
      [ 0, 0, 0, 1 ] ]

or if the matrix C<$A> exists then

    $A->E([4], 3);

will generate the elementary matrix of size number of rows of C<$A>, which multiplies row 4 by 3.

=item * Multiply a row by a constant and add to another row.

To create the matrix that will multiply a row C<i>, by constant C<k> and add to row C<j> then C<E(n,[i, j],k)>

Usage:

    Value::Matrix->E(4, [ 3, 2 ], -3);

generates the matrix:

    [ [ 1, 0, 0, 0 ],
      [ 0, 1, 0, 0 ],
      [ 0, -3, 1, 0 ],
      [ 0, 0, 0, 1 ] ]

or if the matrix C<$A> exists then

    $A->E([3, 4], -5);

will generate the elementary matrix of size number of rows of C<$A>, which multiplies row 3 by -5 and adds to row 4.

=back

=cut

sub E {
	my ($self, $d, $rows, $k, $context) = @_;
	if (ref $d eq 'ARRAY') {
		($rows, $k, $context) = ($d, $rows, $k);
		$d = ($self->dimensions)[0] if ref($self);
	}
	$context = $self->context unless $context;
	my @ij = @{$rows};

	Value::Error("You must provide a dimension for an Elementary matrix")             unless defined $d;
	Value::Error("Dimension must be a positive integer")                              unless $d =~ m/^[1-9]\d*$/;
	Value::Error("Either one or two rows must be specified for an Elementary matrix") unless (@ij == 1 || @ij == 2);
	Value::Error(
		"If only one row is specified for an Elementary matrix, then a number to scale by must also be specified")
		if (@ij == 1 && !defined $k);

	for (@ij) {
		Value::Error("Row indices must be integers between 1 and $d")
			unless ($_ =~ m/^[1-9]\d*$/ && $_ >= 1 && $_ <= $d);
	}
	@ij = map { $_ - 1 } (@ij);

	my @M    = ();
	my $REAL = $context->Package('Real');

	for my $i (0 .. $d - 1) {
		my @row = (0) x $d;
		$row[$i] = 1;
		if (@ij == 1) {
			$row[$i] = $k if ($i == $ij[0]);
		} elsif (defined $k) {
			$row[ $ij[1] ] = $k if ($i == $ij[0]);
		} else {
			($row[ $ij[0] ], $row[ $ij[1] ]) = ($row[ $ij[1] ], $row[ $ij[0] ]) if ($i == $ij[0] || $i == $ij[1]);
		}
		push(@M, $self->make($context, map { $REAL->new($_) } @row));
	}
	return $self->make($context, @M);
}

=head3 C<P>, create a permutation matrix

Creates a permutation matrix of the requested size.

C<< Value::Matrix->P(n,(cycles)) >> in general where C<cycles> is a sequence of array references
of the cycles.

If one has an existing matrix C<$A>, then C<< $A->P(cycles) >> generals a permutation matrix of the
same size as C<$A>.

Usage:

    Value::Matrix->P(3,[1, 2, 3]);  # corresponds to cycle (123) applied to rows of I_3.

returns the matrix [[0,1,0],[0,0,1],[1,0,0]]

    Value::Matrix->P(6,[1,3],[2,4,6]);  # permutation matrix on cycle product (13)(246)

returns the matrix
    [[0,0,1,0,0,0],
    [0,0,0,0,0,1],
    [1,0,0,0,0,0],
    [0,1,0,0,0,0],
    [0,0,0,0,1,0],
    [0,0,0,1,0,0]]

    $A = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ], [13, 14, 15, 16] ]);
    $P3 = $A->P([1,4]);

returns the matrix [[0,0,0,1],[0,1,0,0],[0,0,1,0],[1,0,0,0]]

=cut

sub P {
	my ($self, $d, @cycles) = @_;
	if (ref $d eq 'ARRAY') {
		unshift(@cycles, $d);
		$d = ($self->dimensions)[0] if ref($self);
	}
	my $context = $self->context;
	$d = ($self->dimensions)[0] if !defined $d && ref($self) && $self->isSquare;

	Value::Error("You must provide a dimension for a Permutation matrix") unless defined $d;
	Value::Error("Dimension must be a positive integer")                  unless $d =~ m/^[1-9]\d*$/;
	for my $c (@cycles) {
		Value::Error("Permutation cycles should be array references") unless (ref($c) eq 'ARRAY');
		for (@$c) {
			Value::Error("Permutation cycle indices must be integers between 1 and $d")
				unless ($_ =~ m/^[1-9]\d*$/ && $_ >= 1 && $_ <= $d);
		}
		my %cycle_hash = map { $_ => '' } (@$c);
		Value::Error("A permutation cycle should not repeat an index") unless (@$c == keys %cycle_hash);
	}
	my @M    = ();
	my $REAL = $context->Package('Real');

	# Make an identity matrix
	for my $i (0 .. $d - 1) {
		push(@M, $self->make($context, map { $REAL->new(($_ == $i) ? 1 : 0) } 0 .. $d - 1));
	}

	# Then apply the permutation cycles to it
	for my $c (@cycles) {
		my $swap;
		for my $i (0 .. $#$c, 0) {
			($swap, $M[ $c->[$i] - 1 ]) = ($M[ $c->[$i] - 1 ], $swap);
		}
	}

	return $self->make($context, @M);
}

=head3 C<Zero>

Create a zero matrix of requested size.  If called on existing matrix, creates a matrix as
the same size as given matrix.

Usage:
    Value::Matrix->Zero(m,n);  # creates a m by n zero matrix.
    Value::Matrix->Zero(n);    # creates an n ny n zero matrix.

    my $A1 = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ] ]);
    $A1->Zero;    # generates a zero matrix as same size as $A1.

=cut

sub Zero {
	my ($self, $m, $n, $context) = @_;
	$context = $self->context unless $context;
	$n       = $m                     if !defined $n && defined $m;
	$m       = ($self->dimensions)[0] if !defined $m && ref($self);
	$n       = ($self->dimensions)[1] if !defined $n && ref($self);

	Value::Error("You must provide dimensions for the Zero matrix") unless defined $m          && defined $n;
	Value::Error("Dimension must be a positive integer")            unless $m =~ m/^[1-9]\d*$/ && $n =~ m/^[1-9]\d*$/;
	my @M    = ();
	my $REAL = $context->Package('Real');

	for my $i (0 .. $m - 1) {
		push(@M, $self->make($context, map { $REAL->new(0) } 0 .. $n - 1));
	}
	return $self->make($context, @M);
}

=head3 C<row>

Extract a given row from the matrix.

Usage:

    my $A1 = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ] ]);
    $A1->row(2);  # returns the row Matrix [5,6,7,8]

=cut

sub row {
	my $self = (ref($_[0]) ? $_[0] : shift);
	my $M    = $self->promote(shift);
	my $i    = shift;
	Value::Error("Row must be a positive integer") unless $i =~ m/^[1-9]\d*$/;
	$i-- if $i > 0;
	if ($M->isRow) { return if $i != 0 && $i != -1; return $M }
	return $M->data->[$i];
}

=head3 C<column>

Extract a given column from the matrix.

Usage:

    $A1 = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ] ]);
    $A1->column(2);  # returns the column Matrix [[2],[6],[10]]

=cut

sub column {
	my $self = (ref($_[0]) ? $_[0] : shift);
	my $M    = $self->promote(shift);
	my $j    = shift;
	Value::Error("Column must be a positive integer") unless $j =~ m/^[1-9]\d*$/;
	return if $j == 0;
	$j--   if $j > 0;
	my @d = $M->dimensions;
	if (scalar(@d) == 1) {
		return if $j + 1 > $d[0] || $j < -$d[0];
		return $M->data->[$j];
	}
	return if $j + 1 > $d[1] || $j < -$d[1];
	my @col = ();
	for my $row (@{ $M->data }) { push(@col, $self->make($row->data->[$j])) }
	return $self->make(@col);
}

=head3 C<element>

Extract an element from the given row/col.

Usage:

    $A    = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ] ]);
    $A->element(2,3); # returns 7

    $B = Matrix([ [ [ 1, 2 ], [ 3, 4 ] ], [ [ 5, 6 ], [ 7, 8 ] ] ]);
    $B->element(1,2,1); # returns 3;

    $row = Matrix([4,3,2,1]);
    $row->element(2); # returns 3;
=cut

sub element {
	my $self = (ref($_[0]) ? $_[0] : shift);
	my $M    = $self->promote(shift);
	return $M->extract(@_);
}

=head3 C<setElement>

Assign an element in the matrix to a value.

Inputs: indices as an arrayref and the value in a form that can be parsed.

Note: this mutates the matrix itself.

Usage:

    $A = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ] ]);
    $A->setElement([2,3],-5);

=cut

sub setElement {
	my ($self, $ind, $value) = @_;

	Value::Error("The index $ind->[0] does not exist in the matrix") unless defined $self->{data}[ $ind->[0] - 1 ];

	# Drill down into the matrix
	my $el = \($self->{data}[ $ind->[0] - 1 ]);
	for my $i (1 .. scalar(@$ind) - 1) {
		Value::Error("The index $ind->[$i] does not exist in the matrix") unless defined $$el->{data}[ $ind->[$i] - 1 ];
		$el = \($$el->{data}[ $ind->[$i] - 1 ]);
	}

	# update the value of $el
	$$el = Value::makeValue($value);
}

# The subroutine extractElements is used in the subMatrix routine.  This called recursively to handle
# any dimension of a Matrix. initially $indices needs to be [] and $elements an arrayref of the
# elements to be extracted.
#
# Through subsequent passes through the subroutine, the indices in the $elements arguments are passed to the $indices.

sub extractElements {
	my ($self, $indices, $elements) = @_;

	# These need to be copies of the array arguments.
	my @ind_copy      = @$indices;
	my @elements_copy = @$elements;

	my $ind = shift @elements_copy;
	push(@ind_copy, [ 1 .. scalar(@$ind) ]);

	my @M;
	for my $i (@$ind) {
		push(@M,
			ref $self->element($i) eq 'Value::Matrix'
			? $self->element($i)->extractElements(\@ind_copy, \@elements_copy)
			: $self->element($i));
	}

	return $self->make($self->context, @M);
}

=head3 C<subMatrix>


Return a submatrix of the matrix.  If the indices are array refs, the given rows and
columns (or more) of the matrix are returns as a Matrix object.

If the input are integers, then the submatrix with those indices removed.

Usage:

    $A = Matrix([[1,2,3,4],[5,6,7,8],[9,10,11,12]]);

    $A->subMatrix([2..3],[2..4]);  # returns a Matrix([[6,7,8],[10,11,12]])

    $A->subMatrix(2,3);  # returns Matrix([ [ 1, 2, 4 ], [ 9, 10, 12 ] ]);

    $A->subMatrix([3,1,2],[1,4,2]);  # returns Matrix([9,12,10],[1,4,2],[5,8,6]);

This subroutine can be used on non 2D matrices.  For example,

    $B = Matrix([2, 4, 6, 8]);
    $B->subMatrix([1, 3]);   # returns Matrix([2, 6]);
    $B->subMatrix(2);        # returns Matrix([2, 6, 8]);

And for 3D matrices:

    $C = Matrix([ [ [ 1, 2, 3 ], [ 4, 5, 6 ] ], [ [ 7, 8, 9 ], [ 10, 11, 12 ] ] ]);
    $C->subMatrix([1, 2], [1, 2], [1, 3]);    # returns Matrix([ [ [ 1, 3 ], [ 4, 6 ] ], [ [ 7, 9 ], [ 10, 12 ] ] ]);

    $C->subMatrix(1,2,3); # returns Matrix([ [ [ 7, 8 ] ] ]);

=cut

sub subMatrix {
	my ($self, @ind) = @_;
	my @dim = $self->dimensions;
	my @indices;    # Indices to keep for submatrix.

	# check that the input is appropriate for the size of the matrix.
	Value::Error("The indices must be array refs the same size as the dimension of the matrix.") unless $#dim == $#ind;

	# check that inputs are either all integers or all array refs
	my @index_types = keys %{ { map { ref $_, 1 } @ind } };

	Value::Error('The inputs must both be integers or array refs.')
		unless scalar(@index_types) == 1 && ($index_types[0] eq '' || $index_types[0] eq 'ARRAY');

	for my $i (0 .. $#ind) {
		if ($index_types[0] eq '') {    # input is a scalar (integer)
			Value::Error("The input $ind[$i] is not a valid index")
				unless $ind[$i] >= 1 && $ind[$i] <= $dim[$i] && int($ind[$i]) == $ind[$i];
			push(@indices, [ grep { $_ != $ind[$i] } (1 .. $dim[$i]) ]);

		} elsif ($index_types[0] eq 'ARRAY') {    # input are array refs
			for my $j (@{ $ind[$i] }) {
				Value::Error("The input $j is not a valid index") unless int($j) == $j && $j >= 1 && $j <= $dim[$i];
			}
			push(@indices, $ind[$i]);
		}
	}

	return $self->extractElements([], \@indices);
}

=head3 C<removeRow>

Remove a row from a matrix.

Usage:

    $A = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ], [13, 14, 15, 16] ]);
    $A->removeRow(3);

results in C<[[1,2,3,4],[5,6,7,8],[13,14,15,16]]>.

=cut

sub removeRow {
	my ($self, $row) = @_;
	my $context = $self->context;
	my @d       = $self->dimensions;
	Value::Error("The method removeRow is only valid for 2D matrices.") unless scalar(@d) == 2;
	my ($nrow, $ncol) = @d;
	Value::Error("The input $row is not a valid row.")
		unless ref($row) eq '' && $row >= 1 && $row <= $nrow && int($row) == $row;

	my @M = ();
	for my $r (1 .. $nrow) { push(@M, $self->row($r)) unless $r eq $row; }
	return $self->make($context, @M);
}

=head3

Remove a column from a matrix.

Usage:

    $A = Matrix([ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ], [ 9, 10, 11, 12 ], [13, 14, 15, 16] ]);
    $A->removeColumn(2);

results in C<[[1,3,4],[5,7,8],[9,11,12],[13,15,16]]>.

=cut

sub removeColumn {
	my ($self, $col) = @_;
	my $context = $self->context;
	my @d       = $self->dimensions;
	Value::Error("The method removeColumn is only valid for 2D matrices.") unless scalar(@d) eq 2;
	my ($nrow, $ncol) = @d;
	Value::Error("The input $col is not a valid column.")
		unless ref($col) eq '' && $col >= 1 && $col <= $ncol && int($col) == $col;

	my @M = ();
	for my $r (1 .. $nrow) {
		my @row = ();
		for my $c (1 .. $ncol) { push(@row, $self->element($r, $c)) unless $c eq $col; }
		push(@M, $self->make($context, @row));
	}
	return $self->make($context, @M);
}

#  Convert MathObject Matrix to old-style Matrix
sub wwMatrix {
	my $self = (ref($_[0]) ? $_[0] : shift);
	my $M    = $self->promote(shift);
	my $j    = shift;
	my $wwM;
	return $self->{wwM} if defined($self->{wwM});
	my @d = $M->dimensions;
	Value->Error("Matrix must be two-dimensional to convert to MatrixReal1") if scalar(@d) > 2;
	if (scalar(@d) == 1) {
		$wwM = new Matrix(1, $d[0]);
		for my $j (0 .. $d[0] - 1) {
			$wwM->[0][0][$j] = $self->wwMatrixEntry($M->data->[$j]);
		}
	} else {
		$wwM = new Matrix(@d);
		for my $i (0 .. $d[0] - 1) {
			my $row = $M->data->[$i];
			for my $j (0 .. $d[1] - 1) {
				$wwM->[0][$i][$j] = $self->wwMatrixEntry($row->data->[$j]);
			}
		}
	}
	$self->{wwM} = $wwM;
	return $wwM;
}

sub wwMatrixEntry {
	my $self = shift;
	my $x    = shift;
	return $x->value                                    if $x->isReal;
	return Complex1::cplx($x->Re->value, $x->Im->value) if $x->isComplex;
	return $x;
}

sub wwMatrixLR {
	my $self = shift;
	return $self->{lrM} if defined($self->{lrM});
	$self->wwMatrix;
	$self->{lrM} = $self->{wwM}->decompose_LR;
	return $self->{lrM};
}

sub wwColumnVector {
	my $self = shift;
	my $v    = shift;
	my $V    = $self->new($v);
	$V = $V->transpose if Value::classMatch($v, 'Vector');
	return $V->wwMatrix;
}

###################################
#
#  From MatrixReal1.pm
#

sub det {
	my $self = shift;
	$self->wwMatrixLR;
	Value->Error("Can't take determinant of non-square matrix") unless $self->isSquare;
	return Value::makeValue($self->{lrM}->det_LR);
}

sub inverse {
	my $self = shift;
	$self->wwMatrixLR;
	Value->Error("Can't take inverse of non-square matrix") unless $self->isSquare;
	my $I = $self->{lrM}->invert_LR;
	return (defined($I) ? $self->new($I) : $I);
}

sub decompose_LR {
	my $self = (shift)->copy;
	my $LR   = $self->wwMatrixLR;
	return $self->new($LR)->with(lrM => $LR);
}

sub dim {
	my $self = shift;
	return $self->wwMatrix->dim();
}

sub norm_one {
	my $self = shift;
	return Value::makeValue($self->wwMatrix->norm_one());
}

sub norm_max {
	my $self = shift;
	return Value::makeValue($self->wwMatrix->norm_max());
}

sub kleene {
	my $self = shift;
	return $self->new($self->wwMatrix->kleene());
}

sub normalize {
	my $self = shift;
	my $v    = $self->wwColumnVector(shift);
	my ($M, $b) = $self->wwMatrix->normalize($v);
	return ($self->new($M), $self->new($b));
}

sub solve { shift->solve_LR(@_) }

sub solve_LR {
	my $self = shift;
	my $v    = $self->wwColumnVector(shift);
	my ($d, $b, $M) = $self->wwMatrixLR->solve_LR($v);
	$b = $self->new($b) if defined($b);
	$M = $self->new($M) if defined($M);
	return ($d, $b, $M);
}

sub condition {
	my $self = shift;
	my $I    = $self->new(shift)->wwMatrix;
	return $self->new($self->wwMatrix->condition($I));
}

sub order { shift->order_LR(@_) }

sub order_LR {    #  order of LR decomposition matrix (number of non-zero equations)
	my $self = shift;
	return $self->wwMatrixLR->order_LR;
}

sub solve_GSM {
	my $self = shift;
	my $x0   = $self->wwColumnVector(shift);
	my $b    = $self->wwColumnVector(shift);
	my $e    = shift;
	my $v    = $self->wwMatrix->solve_GSM($x0, $b, $e);
	$v = $self->new($v) if defined($v);
	return $v;
}

sub solve_SSM {
	my $self = shift;
	my $x0   = $self->wwColumnVector(shift);
	my $b    = $self->wwColumnVector(shift);
	my $e    = shift;
	my $v    = $self->wwMatrix->solve_SSM($x0, $b, $e);
	$v = $self->new($v) if defined($v);
	return $v;
}

sub solve_RM {
	my $self = shift;
	my $x0   = $self->wwColumnVector(shift);
	my $b    = $self->wwColumnVector(shift);
	my $w    = shift;
	my $e    = shift;
	my $v    = $self->wwMatrix->solve_RM($x0, $b, $w, $e);
	$v = $self->new($v) if defined($v);
	return $v;
}

sub is_symmetric {
	my $self = shift;
	return $self->wwMatrix->is_symmetric;
}

###################################
#
#  From Matrix.pm
#

sub trace {
	my $self = shift;
	return Value::makeValue($self->wwMatrix->trace);
}

sub proj {
	my $self = shift;
	my $v    = $self->new(shift)->wwMatrix;
	return $self->new($self->wwMatrix->proj($v));
}

sub proj_coeff {
	my $self = shift;
	my $v    = $self->new(shift)->wwMatrix;
	return $self->new($self->wwMatrix->proj_coeff($v));
}

sub L {
	my $self = shift;
	return $self->new($self->wwMatrixLR->L);
}

sub R {
	my $self = shift;
	return $self->new($self->wwMatrixLR->R);
}

sub PL {
	my $self = shift;
	return $self->new($self->wwMatrixLR->PL);
}

sub PR {
	my $self = shift;
	return $self->new($self->wwMatrixLR->PR);
}

############################################
#
#  Generate the various output formats
#

#
#  Use array environment to lay out matrices
#
sub TeX {
	my $self     = shift;
	my $equation = shift;
	my $def      = ($equation->{context} || $self->context)->lists->get('Matrix');
	my $open     = shift || $self->{open}  || $def->{open};
	my $close    = shift || $self->{close} || $def->{close};
	$open  =~ s/([{}])/\\$1/g;
	$close =~ s/([{}])/\\$1/g;
	my $TeX     = '';
	my @entries = ();
	my $d;

	if ($self->isRow) {
		for my $x (@{ $self->data }) {
			if (Value::isValue($x)) {
				$x->{format} = $self->{format} if defined $self->{format};
				push(@entries, $x->TeX($equation));
			} else {
				push(@entries, $x);
			}
		}
		$TeX .= join(' &', @entries) . "\n";
		$d = scalar(@entries);
	} else {
		for my $row (@{ $self->data }) {
			for my $x (@{ $row->data }) {
				if (Value::isValue($x)) {
					$x->{format} = $self->{format} if defined $self->{format};
					push(@entries, $x->TeX($equation));
				} else {
					push(@entries, $x);
				}
			}
			$TeX .= join(' &', @entries) . '\cr' . "\n";
			$d       = scalar(@entries);
			@entries = ();
		}
	}
	$TeX =~ s/\\cr\n$/\n/;
	return '\left' . $open . '\begin{array}{' . ('c' x $d) . '}' . "\n" . $TeX . '\end{array}\right' . $close;
}

1;
