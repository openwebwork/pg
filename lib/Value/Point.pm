########################################################################### 
#
#  Implements the Point object
#
package Value::Point;
my $pkg = 'Value::Point';

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
       'x'   => \&cross,
       '<=>' => \&compare,
       'cmp' => \&compare,
       'neg' => sub {$_[0]->neg},
       'abs' => sub {$_[0]->abs},
  'nomethod' => \&Value::nomethod,
        '""' => \&stringify;

#
#  Convert a value to a point.  The value can be
#    a list of numbers, or an reference to an array of numbers
#    a point or vector object (demote a vector)
#    a matrix if it is  n x 1  or  1 x n
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $p = shift; $p = [$p,@_] if (scalar(@_) > 0);
  my $pclass = Value::class($p); my $isFormula = 0;
  my @d; @d = $p->dimensions if $pclass eq 'Matrix';
  if ($pclass =~ m/Point|Vector/) {$p = $p->data}
  elsif ($pclass eq 'Matrix' && scalar(@d) == 1) {$p = [$p->value]}
  elsif ($pclass eq 'Matrix' && scalar(@d) == 2 && $d[0] == 1) {$p = ($p->value)[0]}
  elsif ($pclass eq 'Matrix' && scalar(@d) == 2 && $d[1] == 1) {$p = ($p->transpose->value)[0]}
  else {
    $p = [$p] if (defined($p) && ref($p) ne 'ARRAY');
    Value::Error("Points must have at least one coordinate")
      unless defined($p) && scalar(@{$p}) > 0;
    foreach my $x (@{$p}) {
      $isFormula = 1 if Value::isFormula($x);
      Value::Error("Coordinate of Point can't be ".Value::showClass($x))
        unless Value::isNumber($x);
      $x = Value::Real->make($x);
    }
  }
  return $self->formula($p) if $isFormula;
  bless {data => $p}, $class;
}

#
#  The number of coordinates
#
sub length {return scalar(@{shift->{data}})}

#
#  Try to promote arbitrary data to a point
#
sub promote {
  my $x = shift;
  return $pkg->new($x,@_) if scalar(@_) > 0 || ref($x) eq 'ARRAY';
  return $x if ref($x) eq $pkg;
  Value::Error("Can't convert ".Value::showClass($x)." to a Point");
}

############################################
#
#  Operations on points
#

sub add {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->add($l,!$flag)}
  ($l,$r) = (promote($l)->data,promote($r)->data);
  Value::Error("Point addition with different number of coordiantes")
    unless scalar(@{$l}) == scalar(@{$r});
  my @s = ();
  foreach my $i (0..scalar(@{$l})-1) {push(@s,$l->[$i] + $r->[$i])}
  return $pkg->make(@s);
}

sub sub {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->sub($l,!$flag)}
  ($l,$r) = (promote($l)->data,promote($r)->data);
  Value::Error("Point subtraction with different number of coordiantes")
    unless scalar(@{$l}) == scalar(@{$r});
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp};
  my @s = ();
  foreach my $i (0..scalar(@{$l})-1) {push(@s,$l->[$i] - $r->[$i])}
  return $pkg->make(@s);
}

sub mult {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->mult($l,!$flag)}
  Value::Error("Points can only be multiplied by numbers")
    unless (Value::matchNumber($r) || Value::isComplex($r));
  my @coords = ();
  foreach my $x (@{$l->data}) {push(@coords,$x*$r)}
  return $pkg->make(@coords);
}

sub div {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->div($l,!$flag)}
  Value::Error("Can't divide by a point") if $flag;
  Value::Error("Points can only be divided by numbers")
    unless (Value::matchNumber($r) || Value::isComplex($r));
  Value::Error("Division by zero") if $r == 0;
  my @coords = ();
  foreach my $x (@{$l->data}) {push(@coords,$x/$r)}
  return $pkg->make(@coords);
}

sub power {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->power($l,!$flag)}
  Value::Error("Can't raise Points to powers") unless $flag;
  Value::Error("Can't use Points in exponents");
}

#
#  Promote to vectors and do it there
#
sub cross {
  my ($l,$r,$flag) = @_;
  $l = Value::Vector::promote($l);
  $l->cross($r,$flag);
}

#
#  If points are different length, shorter is smaller,
#  Otherwise, do lexicographic comparison.
#
sub compare {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->compare($l,!$flag)}
  ($l,$r) = (promote($l)->data,promote($r)->data);
  return scalar(@{$l}) <=> scalar(@{$r}) unless scalar(@{$l}) == scalar(@{$r});
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
#  abs() is norm of vector
#
sub abs {
  my $p = promote(@_)->data;
  my $s = 0;
  foreach my $x (@{$p}) {$s += $x*$x}
  return CORE::sqrt($s);
}


############################################
#
#  Generate the various output formats
#

sub stringify {
  my $self = shift;
  return $self->TeX(undef,$self->{open},$self->{close}) if $$Value::context->flag('StringifyAsTeX');
  return $self->string(undef,$self->{open},$self->{close});
}

sub string {
  my $self = shift; my $equation = shift;
  my $def = ($equation->{context} || $$Value::context)->lists->get('Point');
  my $open = shift || $def->{open}; my $close = shift || $def->{close};
  my @coords = ();
  foreach my $x (@{$self->data}) {
    if (Value::isValue($x)) {push(@coords,$x->string($equation))} else {push(@coords,$x)}
  }
  return $open.join(',',@coords).$close;
}

sub TeX {
  my $self = shift; my $equation = shift;
  my $def = ($equation->{context} || $$Value::context)->lists->get('Point');
  my $open = shift || $def->{open}; my $close = shift || $def->{close};
  my @coords = ();
  foreach my $x (@{$self->data}) {
    if (Value::isValue($x)) {push(@coords,$x->TeX($equation))} else {push(@coords,$x)}
  }
  return '\left'.$open.join(',',@coords).'\right'.$close;
}
  
###########################################################################

1;

