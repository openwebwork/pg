########################################################################### 
#
#  Implements the Matrix class.
#  
#    @@@ Still needs lots of work @@@
#
package Value::Matrix;
my $pkg = 'Value::Matrix';

use strict;
use vars qw(@ISA);
@ISA = qw(Value);

use overload
       '+'   => \&add,
       '-'   => \&sub,
       '*'   => \&mult,
       '/'   => \&div,
       '**'  => \&power,
       '.'   => \&Value::_dot,
       'x'   => \&Value::cross,
       '<=>' => \&compare,
       'cmp' => \&compare,
       'neg' => sub {$_[0]->neg},
  'nomethod' => \&Value::nomethod,
        '""' => \&stringify;

#
#  Convert a value to a matrix.  The value can be:
#     a list of numbers or list of (nested) references to arrays of numbers
#     a point, vector or matrix object
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $M = shift;
  return bless {data => $M->data}, $class 
    if (Value::class($M) =~ m/Point|Vector|Matrix/ && scalar(@_) == 0);
  $M = [$M,@_] if ((defined($M) && ref($M) ne 'ARRAY') || scalar(@_) > 0);
  Value::Error("Matrices must have at least one entry") unless defined($M) && scalar(@{$M}) > 0;
  return $self->numberMatrix(@{$M}) if Value::isNumber($M->[0]);
  return $self->matrixMatrix(@{$M});
}

#
#  (Recusrively) make a matrix from a list of array refs
#  and report errors about the entry types
#
sub matrixMatrix {
  my $self = shift; my $class = ref($self) || $self;
  my ($x,$m); my @M = (); my $isFormula = 0;
  foreach $x (@_) {
    if (Value::isFormula($x)) {push(@M,$x); $isFormula = 1} else {
      $m = $pkg->new($x); push(@M,$m);
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
  bless {data => [@M]}, $class;
}

#
#  Form a 1 x n matrix from a list of numbers
#  (could become a row of an  m x n  matrix)
#
sub numberMatrix {
  my $self = shift; my $class = ref($self) || $self;
  my @M = (); my $isFormula = 0;
  foreach my $x (@_) {
    Value::Error("Matrix row entries must be numbers") unless (Value::isNumber($x));
    $x = Value::Real->make($x) if !Value::isFormula($x);
    push(@M,$x); $isFormula = 1 if Value::isFormula($x);
  }
  return $self->formula([@M]) if $isFormula;
  bless {data => [@M]}, $class;
}

#
#  Recursively get the entries in the matrix and return
#  an array of (references to arrays of ... ) numbers
#
sub value {
  my $self = shift;
  my $M = $self->data;
  return @{$M} if Value::class($M->[0]) ne 'Matrix';
  my @M = ();
  foreach my $x (@{$M}) {push(@M,[$x->value])}
  return @M;
}
#
#  The number of rows in the matrix (for n x m)
#  or the number of entries in a 1 x n matrix
#
sub length {return scalar(@{shift->{data}})}
#
#  Recursively get the dimensions of the matrix.
#  Returns (n) for a 1 x n, or (n,m) for an n x m, etc.
#
sub dimensions {
  my $self = shift;
  my $r = $self->length;
  my $v = $self->data;
  return ($r,) if (Value::class($v->[0]) ne 'Matrix');
  return ($r,$v->[0]->dimensions);
}
#
#  Return the proper type for the matrix
#
sub typeRef {
  my $self = shift;
  return Value::Type($self->class, $self->length, $Value::Type{number})
    if (Value::class($self->data->[0]) ne 'Matrix');
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
#  Make arbitrary data into a matrix, if possible
#
sub promote {
  my $x = shift;
  return $pkg->new($x,@_) if scalar(@_) > 0 || ref($x) eq 'ARRAY';
  return $x if ref($x) eq $pkg;
  return $pkg->make(@{$x->data}) if Value::class($x) =~ m/Point|Vector/;
  Value::Error("Can't convert ".Value::showClass($x)." to a Matrix");
}

############################################
#
#  Operations on matrices
#

sub add {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->add($l,!$flag)}
  ($l,$r) = (promote($l)->data,promote($r)->data);
  Value::Error("Matrix addition with different dimensions")
    unless scalar(@{$l}) == scalar(@{$r});
  my @s = ();
  foreach my $i (0..scalar(@{$l})-1) {push(@s,$l->[$i] + $r->[$i])}
  return $pkg->make(@s);
}

sub sub {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->sub($l,!$flag)}
  ($l,$r) = (promote($l)->data,promote($r)->data);
  Value::Error("Matrix subtraction with different dimensions")
    unless scalar(@{$l}) == scalar(@{$r});
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp};
  my @s = ();
  foreach my $i (0..scalar(@{$l})-1) {push(@s,$l->[$i] - $r->[$i])}
  return $pkg->make(@s);
}

sub mult {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->mult($l,!$flag)}
  #
  #  Constant multiplication
  #
  if (Value::matchNumber($r) || Value::isComplex($r)) {
    my @coords = ();
    foreach my $x (@{$l->data}) {push(@coords,$x*$r)}
    return $pkg->make(@coords);
  }
  #
  #  Make points and vectors into columns if they are on the right
  #
  if (!$flag && Value::class($r) =~ m/Point|Vector/)
    {$r = (promote($r))->transpose} else {$r = promote($r)}
  #
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  my @dl = $l->dimensions; my @dr = $r->dimensions;
  if (scalar(@dl) == 1) {@dl = (1,@dl); $l = $pkg->make($l)}
  if (scalar(@dr) == 1) {@dr = (1,@dr); $r = $pkg->make($r)}
  Value::Error("Can only multiply 2-dimensional matrices") if scalar(@dl) > 2 || scalar(@dr) > 2;
  Value::Error("Matices of dimensions $dl[0]x$dl[1] and $dr[0]x$dr[1] can't be multiplied")
    unless ($dl[1] == $dr[0]);
  #
  #  Do matrix multiplication
  #
  my @l = $l->value; my @r = $r->value;
  my @M = ();
  foreach my $j (0..$dr[1]-1) {
    my @row = ();
    foreach my $i (0..$dl[0]-1) {
      my $s = 0;
      foreach my $k (0..$dl[1]-1) {$s += $l[$i]->[$k] * $r[$k]->[$j]}
      push(@row,$s);
    }
    push(@M,$pkg->make(@row));
  }
  return $pkg->make(@M);
}

sub div {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->div($l,!$flag)}
  Value::Error("Can't divide by a Matrix") if $flag;
  Value::Error("Matrices can only be divided by numbers")
    unless (Value::matchNumber($r) || Value::isComplex($r));
  Value::Error("Division by zero") if $r == 0;
  my @coords = ();
  foreach my $x (@{$l->data}) {push(@coords,$x/$r)}
  return $pkg->make(@coords);
}

sub power {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->power($l,!$flag)}
  Value::Error("Can't use Matrices in exponents") if $flag;
  Value::Error("Only square matrices can be raised to a power") unless $l->isSquare;
  return Value::Matrix::I($l->length) if $r == 0;
  Value::Error("Matrix powers must be positive integers") unless $r =~ m/^[1-9]\d*$/;
  my $M = $l; foreach my $i (2..$r) {$M = $M*$l}
  return $M;
}

#
#  Do lexicographic comparison
#
sub compare {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->compare($l,!$flag)}
  ($l,$r) = (promote($l)->data,promote($r)->data);
  Value::Error("Matrix comparison with different dimensions")
    unless scalar(@{$l}) == scalar(@{$r});
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp};
  my $cmp = 0;
  foreach my $i (0..scalar(@{$l})-1) {
    $cmp = $l->[$i] <=> $r->[$i];
    last if $cmp;
  }
  return $cmp;
}

sub neg {
  my $p = promote(@_)->data;
  my @coords = ();
  foreach my $x (@{$p}) {push(@coords,-$x)}
  return $pkg->make(@coords);
}

#
#  Transpose an  n x m  matrix
#
sub transpose {
  my $self = shift;
  my @d = $self->dimensions;
  if (scalar(@d) == 1) {@d = (1,@d); $self = $pkg->make($self)}
  Value::Error("Can't transpose ".scalar(@d)."-dimensional matrices") unless scalar(@d) == 2;
  my @M = (); my $M = $self->data;
  foreach my $j (0..$d[1]-1) {
    my @row = ();
    foreach my $i (0..$d[0]-1) {push(@row,$M->[$i]->data->[$j])}
    push(@M,$pkg->make(@row));
  }
  return $pkg->make(@M);
}

#
#  Get an identity matrix of the requested size
#
sub I {
  my $d = shift; $d = shift if ref($d) eq $pkg;
  my @M = (); my @Z = split('',0 x $d);
  foreach my $i (0..$d-1) {
    my @row = @Z; $row[$i] = 1;
    push(@M,$pkg->make(@row));
  }
  return $pkg->make(@M);
}

#
#  Extract a given row from the matrix
#
sub row {
  my $M = promote(shift); my $i = shift;
  return if $i == 0; $i-- if $i > 0;
  if ($M->isRow) {return if $i != 0; return $M}
  return $M->data->[$i];
}

#
#  Extract a given element from the matrix
#
sub element {
  my $M = promote(shift);
  return $M->extract(@_);
}

#
#  Extract a given column from the matrix
#
sub column {
  my $M = promote(shift); my $j = shift;
  return if $j == 0; $j-- if $j > 0;
  my @d = $M->dimensions; my @col = ();
  return if $j+1 > $d[1];
  return $M->data->[$j] if scalar(@d) == 1;
  foreach my $row (@{$M->data}) {push(@col,$pkg->make($row->data->[$j]))}
  return $pkg->make(@col);
}

# @@@ removeRow, removeColumn @@@
# @@@ Det, inverse @@@

############################################
#
#  Generate the various output formats
#

sub stringify {
  my $self = shift;
  my $open  = $$Value::context->lists->get('Matrix')->{open};
  my $close = $$Value::context->lists->get('Matrix')->{close};
  return $open.join(',',@{$self->data}).$close
    if (Value::class($self->data->[0]) ne 'Matrix');
  return $open.join(",\n ",@{$self->data}).$close;
}

sub string {
  my $self = shift; my $equation = shift;
  my $open  = shift || $$Value::context->lists->get('Matrix')->{open};
  my $close = shift || $$Value::context->lists->get('Matrix')->{close};
  my @coords = ();
  foreach my $x (@{$self->data}) {
    if (Value::isValue($x)) {push(@coords,$x->string($equation,$open,$close))}
      else {push(@coords,$x)}
  }
  return $open.join(',',@coords).$close;
}

#
#  Use \matrix to lay out matrices
#
sub TeX {
  my $self = shift; my $equation = shift;
  my $open  = shift || $$Value::context->lists->get('Matrix')->{open};
  my $close = shift || $$Value::context->lists->get('Matrix')->{close};
  $open = '\{' if $open eq '{'; $close = '\}' if $close eq '}';
  my $TeX = ''; my @entries = (); my $d;
  if ($self->isRow) {
    foreach my $x (@{$self->data}) {
      push(@entries,(Value::isValue($x))? $x->TeX($equation,$open,$close): $x);
    }
    $TeX .= join(' &',@entries) . "\n";
    $d = scalar(@entries);
  } else {
    foreach my $row (@{$self->data}) {
      foreach my $x (@{$row->data}) {
        push(@entries,(Value::isValue($x))? $x->TeX($equation,$open,$close): $x);
      }
      $TeX .= join(' &',@entries) . '\cr'."\n";
      $d = scalar(@entries); @entries = ();
    }
  }
  return '\left'.$open.'\begin{array}{'.('c'x$d).'}'."\n".$TeX.'\end{array}\right'.$close;
}
  
###########################################################################

1;

