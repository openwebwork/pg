########################################################################### 
#
#  Implements the Matrix class.
#
#    @@@ Still needs lots of work @@@
#
package Value::Matrix;
my $pkg = 'Value::Matrix';

use strict; no strict "refs";
use Matrix; use Complex1;
our @ISA = qw(Value);

#
#  Convert a value to a matrix.  The value can be:
#     a list of numbers or list of (nested) references to arrays of numbers,
#     a point, vector or matrix object, a matrix-valued formula, or a string
#     that evaluates to a matrix
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $M = shift; $M = [] unless defined $M; $M = [$M,@_] if scalar(@_) > 0;
  $M = @{$M}[0] if ref($M) =~ m/^Matrix(Real1)?/;
  $M = Value::makeValue($M,context=>$context) if ref($M) ne 'ARRAY';
  return bless {data => $M->data, context=>$context}, $class
    if (Value::classMatch($M,'Point','Vector','Matrix') && scalar(@_) == 0);
  return $M if Value::isFormula($M) && Value::classMatch($self,$M->type);
  my @M = (ref($M) eq 'ARRAY' ? @{$M} : $M);
  Value::Error("Matrices must have at least one entry") unless scalar(@M) > 0;
  return $self->matrixMatrix($context,@M) if ref($M[0]) eq 'ARRAY' ||
    Value::classMatch($M[0],'Matrix','Vector','Point') ||
    (Value::isFormula($M[0]) && $M[0]->type =~ m/Matrix|Vector|Point/);
  return $self->numberMatrix($context,@M);
}

#
#  (Recursively) make a matrix from a list of array refs
#  and report errors about the entry types
#
sub matrixMatrix {
  my $self = shift; my $class = ref($self) || $self;
  my $context = shift;
  my ($x,$m); my @M = (); my $isFormula = 0;
  foreach $x (@_) {
    if (Value::isFormula($x)) {push(@M,$x); $isFormula = 1} else {
      $m = $self->new($context,$x); push(@M,$m);
      $isFormula = 1 if Value::isFormula($m);
    }
  }
  my ($type,$len) = ($M[0]->entryType->{name},$M[0]->length);
  foreach $x (@M) {
    Value::Error("Matrix rows must all be the same type")
      unless (defined($x->entryType) && $type eq $x->entryType->{name});
    Value::Error("Matrix rows must all be the same length") unless ($len eq $x->length);
  }
  return $self->formula([@M]) if $isFormula;
  bless {data => [@M], context=>$context}, $class;
}

#
#  Form a 1 x n matrix from a list of numbers
#  (could become a row of an  m x n  matrix)
#
sub numberMatrix {
  my $self = shift; my $class = ref($self) || $self;
  my $context = shift;
  my @M = (); my $isFormula = 0;
  foreach my $x (@_) {
    $x = Value::makeValue($x,context=>$context);
    Value::Error("Matrix row entries must be numbers") unless Value::isNumber($x);
    push(@M,$x); $isFormula = 1 if Value::isFormula($x);
  }
  return $self->formula([@M]) if $isFormula;
  bless {data => [@M], context=>$context}, $class;
}

#
#  Recursively get the entries in the matrix and return
#  an array of (references to arrays of ... ) numbers
#
sub value {
  my $self = shift;
  my $M = $self->data;
  return @{$M} unless Value::classMatch($M->[0],'Matrix');
  my @M = ();
  foreach my $x (@{$M}) {push(@M,[$x->value])}
  return @M;
}

#
#  Recursively get the dimensions of the matrix.
#  Returns (n) for a 1 x n, or (n,m) for an n x m, etc.
#
sub dimensions {
  my $self = shift;
  my $r = $self->length;
  my $v = $self->data;
  return ($r,) unless Value::classMatch($v->[0],'Matrix');
  return ($r,$v->[0]->dimensions);
}

#
#  Return the proper type for the matrix
#
sub typeRef {
  my $self = shift;
  return Value::Type($self->class, $self->length, $Value::Type{number})
    unless Value::classMatch($self->data->[0],'Matrix');
  return Value::Type($self->class, $self->length, $self->data->[0]->typeRef);
}

#
#  True if the matrix is a square matrix
#
sub isSquare {
  my $self = shift;
  my @d = $self->dimensions;
  return 0 if scalar(@d) > 2;
  return 1 if scalar(@d) == 1 && $d[0] == 1;
  return $d[0] == $d[1];
}

#
#  True if the matrix is 1-dimensional (i.e., is a matrix row)
#
sub isRow {
  my $self = shift;
  my @d = $self->dimensions;
  return scalar(@d) == 1;
}

#
#  See if the matrix is an Indenity matrix
#
sub isOne {
  my $self = shift;
  return 0 unless $self->isSquare;
  my $i = 0;
  foreach my $row (@{$self->{data}}) {
    my $j = 0;
    foreach my $k (@{$row->{data}}) {
      return 0 unless $k eq (($i == $j)? "1": "0");
      $j++;
    }
    $i++;
  }
  return 1;
}

#
#  See if the matrix is all zeros
#
sub isZero {
  my $self = shift;
  foreach my $x (@{$self->{data}}) {return 0 unless $x->isZero}
  return 1;
}

#
#  Make arbitrary data into a matrix, if possible
#
sub promote {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $x = (scalar(@_) ? shift : $self);
  return $self->new($context,$x,@_) if scalar(@_) > 0 || ref($x) eq 'ARRAY';
  $x = Value::makeValue($x,context=>$context);
  return $x->inContext($context) if ref($x) eq $class;
  return $self->make($context,@{$x->data}) if Value::classMatch($x,'Point','Vector');
  Value::Error("Can't convert %s to %s",Value::showClass($x),Value::showClass($self));
}

#
#  Don't inherit ColumnVector flag
#
sub noinherit {
  my $self = shift;
  return ("ColumnVector",$self->SUPER::noinherit);
}

############################################
#
#  Operations on matrices
#

sub add {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  my @l = @{$l->data}; my @r = @{$r->data};
  Value::Error("Can't add Matrices with different dimensions")
    unless scalar(@l) == scalar(@r);
  my @s = ();
  foreach my $i (0..scalar(@l)-1) {push(@s,$l[$i] + $r[$i])}
  return $self->inherit($other)->make(@s);
}

sub sub {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  my @l = @{$l->data}; my @r = @{$r->data};
  Value::Error("Can't subtract Matrices with different dimensions")
    unless scalar(@l) == scalar(@r);
  my @s = ();
  foreach my $i (0..scalar(@l)-1) {push(@s,$l[$i] - $r[$i])}
  return $self->inherit($other)->make(@s);
}

sub mult {
  my ($l,$r,$flag) = @_; my $self = $l; my $other = $r;
  #
  #  Constant multiplication
  #
  if (Value::matchNumber($r) || Value::isComplex($r)) {
    my @coords = ();
    foreach my $x (@{$l->data}) {push(@coords,$x*$r)}
    return $self->make(@coords);
  }
  #
  #  Make points and vectors into columns if they are on the right
  #
  if (!$flag && Value::classMatch($r,'Point','Vector'))
    {$r = ($self->promote($r))->transpose} else {$r = $self->promote($r)}
  #
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  my @dl = $l->dimensions; my @dr = $r->dimensions;
  if (scalar(@dl) == 1) {@dl = (1,@dl); $l = $self->make($l)}
  if (scalar(@dr) == 1) {@dr = (@dr,1); $r = $self->make($r)->transpose}
  Value::Error("Can only multiply 2-dimensional matrices") if scalar(@dl) > 2 || scalar(@dr) > 2;
  Value::Error("Matices of dimensions %dx%d and %dx%d can't be multiplied",@dl,@dr)
    unless ($dl[1] == $dr[0]);
  #
  #  Do matrix multiplication
  #
  my @l = $l->value; my @r = $r->value; my @M = ();
  foreach my $i (0..$dl[0]-1) {
    my @row = ();
    foreach my $j (0..$dr[1]-1) {
      my $s = 0;
      foreach my $k (0..$dl[1]-1) {$s += $l[$i]->[$k] * $r[$k]->[$j]}
      push(@row,$s);
    }
    push(@M,$self->make(@row));
  }
  $self = $self->inherit($other) if Value::isValue($other);
  return $self->make(@M);
}

sub div {
  my ($l,$r,$flag) = @_; my $self = $l;
  Value::Error("Can't divide by a Matrix") if $flag;
  Value::Error("Matrices can only be divided by Numbers")
    unless (Value::matchNumber($r) || Value::isComplex($r));
  Value::Error("Division by zero") if $r == 0;
  my @coords = ();
  foreach my $x (@{$l->data}) {push(@coords,$x/$r)}
  return $self->make(@coords);
}

sub power {
  my ($l,$r,$flag) = @_; my $self = shift; my $context = $self->context;
  Value::Error("Can't use Matrices in exponents") if $flag;
  Value::Error("Only square matrices can be raised to a power") unless $l->isSquare;
  $r = Value::makeValue($r,context=>$context);
  if ($r->isNumber && $r =~ m/^-\d+$/) {$l = $l->inverse; $r = -$r}
  Value::Error("Matrix powers must be non-negative integers") unless $r->isNumber && $r =~ m/^\d+$/;
  return $context->Package("Matrix")->I($l->length,$context) if $r == 0;
  my $M = $l; foreach my $i (2..$r) {$M = $M*$l}
  return $M;
}

#
#  Do lexicographic comparison (row by row)
#
sub compare {
  my ($self,$l,$r) = Value::checkOpOrderWithPromote(@_);
  Value::Error("Can't compare Matrices with different dimensions")
    unless join(',',$l->dimensions) eq join(',',$r->dimensions);
  my @l = @{$l->data}; my @r = @{$r->data};
  foreach my $i (0..scalar(@l)-1) {
    my $cmp = $l[$i] <=> $r[$i];
    return $cmp if $cmp;
  }
  return 0;
}

sub neg {
  my $self = promote(@_); my @coords = ();
  foreach my $x (@{$self->data}) {push(@coords,-$x)}
  return $self->make(@coords);
}

sub conj {shift->twiddle(@_)}
sub twiddle {
  my $self = promote(@_); my @coords = ();
  foreach my $x (@{$self->data}) {push(@coords,($x->can("conj") ? $x->conj : $x))}
  return $self->make(@coords);
}

#
#  Transpose an  n x m  matrix
#
sub transpose {
  my $self = promote(@_);
  my @d = $self->dimensions;
  if (scalar(@d) == 1) {@d = (1,@d); $self = $self->make($self)}
  Value::Error("Can't transpose %d-dimensional matrices",scalar(@d)) unless scalar(@d) == 2;
  my @M = (); my $M = $self->data;
  foreach my $j (0..$d[1]-1) {
    my @row = ();
    foreach my $i (0..$d[0]-1) {push(@row,$M->[$i]->data->[$j])}
    push(@M,$self->make(@row));
  }
  return $self->make(@M);
}

#
#  Get an identity matrix of the requested size
#
sub I {
  my $self = shift; my $d = shift; my $context = shift || $self->context;
  $d = ($self->dimensions)[0] if !defined $d && ref($self) && $self->isSquare;
  Value::Error("You must provide a dimension for the Identity matrix") unless defined $d;
  Value::Error("Dimension must be a positive integer") unless $d =~ m/^[1-9]\d*$/;
  my @M = (); my @Z = split('',0 x $d);
  foreach my $i (0..$d-1) {
    my @row = @Z; $row[$i] = 1;
    push(@M,$self->make($context,@row));
  }
  return $self->make($context,@M);
}

#
#  Extract a given row from the matrix
#
sub row {
  my $self = (ref($_[0]) ? $_[0] : shift);
  my $M = $self->promote(shift); my $i = shift;
  return if $i == 0; $i-- if $i > 0;
  if ($M->isRow) {return if $i != 0 && $i != -1; return $M}
  return $M->data->[$i];
}

#
#  Extract a given column from the matrix
#
sub column {
  my $self = (ref($_[0]) ? $_[0] : shift);
  my $M = $self->promote(shift); my $j = shift;
  return if $j == 0; $j-- if $j > 0;
  my @d = $M->dimensions;
  if (scalar(@d) == 1) {
    return if $j+1 > $d[0] || $j < -$d[0];
    return $M->data->[$j];
  }
  return if $j+1 > $d[1] || $j < -$d[1];
  my @col = ();
  foreach my $row (@{$M->data}) {push(@col,$self->make($row->data->[$j]))}
  return $self->make(@col);
}

#
#  Extract a given element from the matrix
#
sub element {
  my $self = (ref($_[0]) ? $_[0] : shift);
  my $M = $self->promote(shift);
  return $M->extract(@_);
}

# @@@ assign @@@
# @@@ removeRow, removeColumn @@@
# @@@ Minor @@@


##################################################
#
#  Convert MathObject Matrix to old-style Matrix
#
sub wwMatrix {
  my $self = (ref($_[0]) ? $_[0] : shift);
  my $M = $self->promote(shift); my $j = shift; my $wwM;
  return $self->{wwM} if defined($self->{wwM});
  my @d = $M->dimensions;
  Value->Error("Matrix must be two-dimensional to convert to MatrixReal1") if scalar(@d) > 2;
  if (scalar(@d) == 1) {
    $wwM = new Matrix(1,$d[0]);
    foreach my $j (0..$d[0]-1) {
      $wwM->[0][0][$j] = $self->wwMatrixEntry($M->data->[$j]);
    }
  } else {
    $wwM = new Matrix(@d);
    foreach my $i (0..$d[0]-1) {
      my $row = $M->data->[$i];
      foreach my $j (0..$d[1]-1) {
	$wwM->[0][$i][$j] = $self->wwMatrixEntry($row->data->[$j]);
      }
    }
  }
  $self->{wwM} = $wwM;
  return $wwM;
}
sub wwMatrixEntry {
  my $self = shift; my $x = shift;
  return $x->value if $x->isReal;
  return Complex1::cplx($x->Re->value,$x->Im->value) if $x->isComplex;
  return $x;
}
sub wwMatrixLR {
  my $self = shift;
  return $self->{lrM} if defined($self->{lrM});
  $self->wwMatrix;
  $self->{lrM} = $self->{wwM}->decompose_LR;
  return $self->{lrM};
}


###################################
#
#  From MatrixReal1.pm
#

sub det {
  my $self = shift; $self->wwMatrixLR;
  Value->Error("Can't take determinant of non-square matrix") unless $self->isSquare;
  return Value::makeValue($self->{lrM}->det_LR);
}

sub inverse {
  my $self = shift; $self->wwMatrixLR;
  Value->Error("Can't take inverse of non-square matrix") unless $self->isSquare;
  return $self->new($self->{lrM}->invert_LR);
}

sub decompose_LR {
  my $self = shift;
  return $self->wwMatrixLR;
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
  my $v = $self->new(shift)->wwMatrix;
  my ($M,$b) = $self->wwMatrix->normalize($v);
  return ($self->new($M),$self->new($b));
}

sub solve {shift->solve_LR(@_)}
sub solve_LR {
  my $self = shift;
  my $v = $self->new(shift)->wwMatrix;
  my ($d,$b,$M) = $self->lrMatrix->solve_LR($v);
  return ($d,$self->new($b),$self->new($M));
}

sub condition {
  my $self = shift;
  my $I = $self->new(shift)->wwMatrix;
  return $self->new($self->wwMatrix->condition($I));
}

sub order {shift->order_LR(@_)}
sub order_LR {
  my $self = shift;
  return $self->wwMatrixLR->order_LR;
}

sub solve_GSM {
  my $self = shift;
  my $x0 = $self->new(shift)->wwMatrix;
  my $b  = $self->new(shift)->wwMatrix;
  my $e  = shift;
  my $v = $self->wwMatrix->solve_GSM($x0,$b,$e);
  $v = $self->new($v) if defined($v);
  return $v;
}

sub solve_SSM {
  my $self = shift;
  my $x0 = $self->new(shift)->wwMatrix;
  my $b  = $self->new(shift)->wwMatrix;
  my $e  = shift;
  my $v = $self->wwMatrix->solve_SSM($x0,$b,$e);
  $v = $self->new($v) if defined($v);
  return $v;
}

sub solve_RM {
  my $self = shift;
  my $x0 = $self->new(shift)->wwMatrix;
  my $b  = $self->new(shift)->wwMatrix;
  my $w = shift; my $e = shift;
  my $v = $self->wwMatrix->solve_RM($x0,$b,$w,$e);
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
  my $v = $self->new(shift)->wwMatrix;
  return $self->new($self->wwMatrix->proj($v));
}

sub proj_coeff {
  my $self = shift;
  my $v = $self->new(shift)->wwMatrix;
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
  my $self = shift; my $equation = shift;
  my $def = ($equation->{context} || $self->context)->lists->get('Matrix');
  my $open  = shift || $self->{open} || $def->{open};
  my $close = shift || $self->{close} || $def->{close};
  $open =~ s/([{}])/\\$1/g; $close =~ s/([{}])/\\$1/g;
  my $TeX = ''; my @entries = (); my $d;
  if ($self->isRow) {
    foreach my $x (@{$self->data}) {
      if (Value::isValue($x)) {
	$x->{format} = $self->{format} if defined $self->{format};
	push(@entries,$x->TeX($equation));
      } else {push(@entries,$x)}
    }
    $TeX .= join(' &',@entries) . "\n";
    $d = scalar(@entries);
  } else {
    foreach my $row (@{$self->data}) {
      foreach my $x (@{$row->data}) {
	if (Value::isValue($x)) {
	  $x->{format} = $self->{format} if defined $self->{format};
	  push(@entries,$x->TeX($equation));
	} else {push(@entries,$x)}
      }
      $TeX .= join(' &',@entries) . '\cr'."\n";
      $d = scalar(@entries); @entries = ();
    }
  }
  $TeX =~ s/\\cr\n$/\n/;
  return '\left'.$open.'\begin{array}{'.('c'x$d).'}'."\n".$TeX.'\end{array}\right'.$close;
}

###########################################################################

1;

