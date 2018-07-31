########################################################################### 
#
#  Implements the Point object
#
package Value::Point;
my $pkg = 'Value::Point';

use strict; no strict "refs";
our @ISA = qw(Value);

#
#  Convert a value to a point.  The value can be
#    a list of numbers, or an reference to an array of numbers
#    a point or vector object (demote a vector)
#    a matrix if it is  n x 1  or  1 x n
#    a string that evaluates to a point
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $p = shift; $p = [$p,@_] if scalar(@_) > 0;
  $p = Value::makeValue($p,context=>$context) if defined($p) && !ref($p);
  return $p if Value::isFormula($p) && Value::classMatch($self,$p->type);
  my $isFormula = 0; my @d; @d = $p->dimensions if Value::classMatch($p,'Matrix');
  if (Value::classMatch($p,'Point','Vector')) {$p = $p->data}
  elsif (scalar(@d) == 1) {$p = [$p->value]}
  elsif (scalar(@d) == 2 && $d[0] == 1) {$p = ($p->value)[0]}
  elsif (scalar(@d) == 2 && $d[1] == 1) {$p = ($p->transpose->value)[0]}
  else {
    $p = [$p] if defined($p) && ref($p) ne 'ARRAY';
    Value::Error("Points must have at least one coordinate")
      unless defined($p) && scalar(@{$p}) > 0;
    foreach my $x (@{$p}) {
      $x = Value::makeValue($x,context=>$context);
      $isFormula = 1 if Value::isFormula($x);
      Value::Error("Coordinate of Point can't be %s",Value::showClass($x))
        unless Value::isNumber($x);
    }
  }
  return $self->formula($p) if $isFormula;
  bless {data => $p, context=>$context}, $class;
}

#
#  Try to promote arbitrary data to a point
#
sub promote {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $x = (scalar(@_) ? shift: $self);
  return $self->new($context,$x,@_) if scalar(@_) > 0 || ref($x) eq 'ARRAY';
  $x = Value::makeValue($x,context=>$context);
  return $x->inContext($context) if ref($x) eq $class;
  Value::Error("Can't convert %s to %s",Value::showClass($x),Value::showClass($self));
}

############################################
#
#  Operations on points
#

sub add {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  my @l = $l->value; my @r = $r->value;
  Value::Error("Can't add Points with different numbers of coordinates")
    unless scalar(@l) == scalar(@r);
  my @s = ();
  foreach my $i (0..scalar(@l)-1) {push(@s,$l[$i] + $r[$i])}
  return $self->inherit($other)->make(@s);
}

sub sub {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  my @l = $l->value; my @r = $r->value;
  Value::Error("Can't subtract Points with different numbers of coordinates")
    unless scalar(@l) == scalar(@r);
  my @s = ();
  foreach my $i (0..scalar(@l)-1) {push(@s,$l[$i] - $r[$i])}
  return $self->inherit($other)->make(@s);
}

sub mult {
  my ($l,$r) = @_; my $self = $l;
  Value::Error("Points can only be multiplied by Numbers") unless Value::isNumber($r);
  my @coords = ();
  foreach my $x ($l->value) {push(@coords,$x*$r)}
  return $self->make(@coords);
}

sub div {
  my ($l,$r,$flag) = @_; my $self = $l;
  Value::Error("Can't divide by a Point") if $flag;
  Value::Error("Points can only be divided by Numbers") unless Value::isNumber($r);
  Value::Error("Division by zero") if $r == 0;
  my @coords = ();
  foreach my $x ($l->value) {push(@coords,$x/$r)}
  return $self->make(@coords);
}

sub power {
  my ($l,$r,$flag) = @_;
  Value::Error("Can't raise Points to powers") unless $flag;
  Value::Error("Can't use Points in exponents");
}

#
#  Promote to vectors and do it there
#
sub cross {
  my ($l,$r,$flag) = @_;
  my $context = $l->context;
  $l = $context->Package("Vector")->promote($context,$l);
  $l->cross($r,$flag);
}

#
#  If points are different length, shorter is smaller,
#  Otherwise, do lexicographic comparison.
#
sub compare {
  my ($self,$l,$r) = Value::checkOpOrderWithPromote(@_);
  my @l = $l->value; my @r = $r->value;
  return scalar(@l) <=> scalar(@r) unless scalar(@l) == scalar(@r);
  my $cmp = 0;
  foreach my $i (0..scalar(@l)-1) {
    $cmp = $l[$i] <=> $r[$i];
    last if $cmp;
  }
  return $cmp;
}

sub neg {
  my $self = promote(@_); my @coords = ();
  foreach my $x ($self->value) {push(@coords,-$x)}
  return $self->make(@coords);
}

#
#  abs() is norm of vector
#
sub abs {
  my $self = promote(@_); my $s = 0;
  foreach my $x ($self->value) {$s += $x*$x}
  return CORE::sqrt($s);
}

###########################################################################

1;
