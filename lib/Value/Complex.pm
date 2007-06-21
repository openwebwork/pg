##########################################################################

package Value::Complex;
my $pkg = 'Value::Complex';

use strict;
our @ISA = qw(Value);
our $i; our $pi;

#
#  Check that the inputs are:
#    one or two real numbers, or
#    an array ref of one or two reals, or
#    a Value::Complex object
#    a formula returning a real or complex
#  Make a formula if either part is a formula
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $x = shift; $x = [$x,@_] if scalar(@_) > 0;
  $x = $x->data if ref($x) eq $class || Value::isReal($x);
  $x = [$x] unless ref($x) eq 'ARRAY'; $x->[1] = 0 unless defined($x->[1]);
  Value::Error("Can't convert ARRAY of length %d to a Complex Number",scalar(@{$x}))
    unless (scalar(@{$x}) == 2);
  $x->[0] = Value::makeValue($x->[0],context=>$context);
  $x->[1] = Value::makeValue($x->[1],context=>$context);
  return $x->[0] if Value::isComplex($x->[0]) && scalar(@_) == 0;
  Value::Error("Real part can't be %s",Value::showClass($x->[0]))
     unless (Value::isRealNumber($x->[0]));
  Value::Error("Imaginary part can't be %s",Value::showClass($x->[1]))
     unless (Value::isRealNumber($x->[1]));
  return $self->formula($x) if Value::isFormula($x->[0]) || Value::isFormula($x->[1]);
  bless {data => $x, context => $context}, $class;
}

sub make {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  while (scalar(@_) < 2) {push(@_,0)}
  bless {data => [@_], context => $context}, $class;
}

#
#  Create a new a+b*i formula from the two parts
#
sub formula {
  my $self = shift; my $value = shift;
  my $formula = $self->Package("Formula")->blank($self->context);
  my ($l,$r) = Value::toFormula($formula,@{$value});
  my $I = $formula->Item("Value")->new($formula,$i);
  $r = $formula->Item("BOP")->new($formula,'*',$r,$I);
  $formula->{tree} = $formula->Item("BOP")->new($formula,'+',$l,$r);
  return $formula;
}

#
#  Return the complex type
#
sub typeRef {return $Value::Type{complex}}
sub length {2}

sub isZero {shift eq "0"}
sub isOne {shift eq "1"}

##################################################

#
#  Return a complex if it already is one, otherwise make it one
#    (Guarantees that we have both parts in an array ref)
#
sub promote {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $x = (scalar(@_) ? shift : $self);
  return $x->inContext($context) if ref($x) eq $class && scalar(@_) == 0;
  return $self->new($context,$x,@_);
}
#
#  Get the data from the promoted item
#    (guarantees that we have an array with two elements)
#
sub promoteData {
  my $self = shift;
  return $self->value if Value::isValue($self) && scalar(@_) == 0;
  return ($self->promote(@_))->value;
}

##################################################
#
#  Binary operations
#

sub add {
  my ($l,$r) = @_; my $self = $l;
  my ($a,$b) = $l->value; my ($c,$d) = $r->value;
  return $self->make($a + $c, $b + $d);
}

sub sub {
  my ($self,$l,$r) = Value::checkOpOrder(@_);
  my ($a,$b) = $l->value; my ($c,$d) = $r->value;
  return $self->make($a - $c, $b - $d);
}

sub mult {
  my ($l,$r) = @_; my $self = $l;
  my ($a,$b) = $l->value; my ($c,$d) = $r->value;
  return $self->make($a*$c - $b*$d, $b*$c + $a*$d);
}

sub div {
  my ($self,$l,$r) = Value::checkOpOrder(@_);
  my ($a,$b) = $l->value; my ($c,$d) = $r->value;
  my $x = $c*$c + $d*$d;
  Value::Error("Division by zero") if $x == 0;
  return $self->make(($a*$c + $b*$d)/$x,($b*$c - $a*$d)/$x);
}

sub power {
  my ($self,$l,$r) = Value::checkOpOrder(@_);
  my ($a,$b) = $l->value; my ($c,$d) = $r->value;
  return Value::makeValue(1) if ($a eq '1' && $b == 0) || ($c == 0 && $d == 0);
  return Value::makeValue(0) if $c > 0 && ($a == 0 && $b == 0);
  return exp($r * log($l))
 }

sub modulo {
  my ($self,$l,$r) = Value::checkOpOrder(@_);
  return $self->make(0) if $r->value == 0; # non-fuzzy check
  my $m = Re($l/$r)->value;
  my $n = int($m); $n-- if $n > $m; # act as floor() rather than int()
  return $self->make($l - $n*$r);
}

sub compare {
  my ($self,$l,$r) = Value::checkOpOrder(@_);
  #
  #  Handle periodic Complex numbers
  #
  my $m = $self->{period};
  if (defined $m) {
    if ($self->{logPeriodic}) {
      return 1 if $l->value == 0 || $r->value == 0; # non-fuzzy checks
      $l = log($l); $r = log($r);
    }
    return (($l-$r+$m/2) % $m) <=> $m/2;
  }

  my ($a,$b) = $l->value; my ($c,$d) = $r->value;
  return ($a <=> $c) if $a != $c;
  return ($b <=> $d);
}

##################################################
#
#   Numeric functions
#

sub arg {
  my ($a,$b) = promoteData(@_);
  return CORE::atan2($b,$a);
}

sub mod {
  my ($a,$b) = promoteData(@_);
  return CORE::sqrt($a*$a+$b*$b);
}

sub Re {return (promoteData(@_))[0]}
sub Im {return (promoteData(@_))[1]}

sub abs {norm(@_)}
sub norm {
  my ($a,$b) = promoteData(@_);
  return CORE::sqrt($a*$a+$b*$b);
}

sub neg {
  my $self = promote(@_);
  my ($a,$b) = $self->value;
  return $self->make(-$a,-$b);
}

sub conj {(shift)->twiddle(@_)}
sub twiddle {
  my $self = promote(@_);
  my ($a,$b) = $self->value;
  return $self->make($a,-$b);
}

sub exp {
  my $self = promote(@_);
  my ($a,$b) = $self->value;
  my $e = CORE::exp($a);
  my ($c,$s) = (CORE::cos($b),CORE::sin($b));
  return $self->make($e*$c,$e*$s);
}

sub log {
  my $self = promote(@_);
  my ($r,$t) = ($self->mod,$self->arg);
  Value::Error("Can't compute log of zero") if ($r == 0);
  return $self->make(CORE::log($r),$t);
}

sub sqrt {promote(@_)**(.5)}

##################################################
#
#   Trig functions
#

# sin(z) = (exp(iz) - exp(-iz))/(2i)
sub sin {
  my $self = promote(@_);
  my ($a,$b) = $self->value;
  my $e = CORE::exp($b); my $e1 = 1/$e;
  $self->make(CORE::sin($a)*($e+$e1)/2, CORE::cos($a)*($e-$e1)/2);
}

# cos(z) = (exp(iz) + exp(-iz))/2
sub cos {
  my $self = promote(@_);
  my ($a,$b) = $self->value;
  my $e = CORE::exp($b); my $e1 = 1/$e;
  $self->make(CORE::cos($a)*($e+$e1)/2, CORE::sin($a)*($e1-$e)/2);
}

# tan(z) = sin(z) / cos(z)
sub tan {CORE::sin($_[0])/CORE::cos($_[0])}

# sec(z) = 1 / cos(z)
sub sec {1/CORE::cos($_[0])}

# csc(z) = 1 / sin(z)
sub csc {1/CORE::sin($_[0])}

# cot(z) = cos(z) / sin(z)
sub cot {CORE::cos($_[0])/CORE::sin($_[0])}

# acos(z) = -i log(z + sqrt(z^2 - 1))
sub acos {my $z = promote(@_); -$i * CORE::log($z + CORE::sqrt($z*$z - 1))}

# asin(z) = -i log(iz + sqrt(1 - z^2))
sub asin {my $z = promote(@_); -$i * CORE::log($i*$z + CORE::sqrt(1 - $z*$z))}

# atan(z) = (i/2) log((i+z)/(i-z))
sub atan {my $z = promote(@_); ($i/2)*CORE::log(($i+$z)/($i-$z))}

# asec(z) = acos(1/z)
sub asec {acos(1/$_[0])}

# acsc(z) = asin(1/z)
sub acsc {asin(1/$_[0])}

# acot(z) = atan(1/z)
sub acot {atan(1/$_[0])}

# atan2(z1,z2) = atan(z1/z2)
sub atan2 {
  my ($self,$l,$r) = Value::checkOpOrder(@_);
  my ($a,$b) = $l->value; my ($c,$d) = $r->value;
  if ($b == 0) {
    return CORE::atan2($a,$c) if $b == 0;
    return $self->make($pi/2,0) if $a == 0;
  }
  ($a,$b) = atan($l/$r)->value;
  $a += $pi if $c <0; $a -= 2*$pi if $a > $pi;
  return $self->make($a,$b);
}

##################################################
#
#   Hyperbolic functions
#

# sinh(z) = (exp(z) - exp(-z))/2
sub sinh {
  my $self = promote(@_);
  my ($a,$b) = $self->value;
  my $e = CORE::exp($a); my $e1 = 1/$e;
  $self->make(CORE::cos($b)*($e-$e1)/2, CORE::sin($b)*($e+$e1)/2);
}

# cosh(z) = (exp(z) + exp(-z))/2
sub cosh {
  my $self = promote(@_);
  my ($a,$b) = $self->value;
  my $e = CORE::exp($a); my $e1 = 1/$e;
  $self->make(CORE::cos($b)*($e+$e1)/2, CORE::sin($b)*($e-$e1)/2);
}

# tanh(z) = sinh(z) / cosh(z)
sub tanh {sinh($_[0])/cosh($_[0])}

# sech(z) = 1 / cosh(z)
sub sech {1/cosh($_[0])}

# csch(z) = 1 / sinh(z)
sub csch {1/sinh($_[0])}

# coth(z) = cosh(z) / sinh(z)
sub coth {cosh($_[0]) / sinh($_[0])}

# asinh(z) = log(z + sqrt(z^2 + 1))
sub asinh {my $z = promote(@_); CORE::log($z + CORE::sqrt($z*$z + 1))}

# acosh(z) = log(z + sqrt(z^2 - 1))
sub acosh {my $z = promote(@_); CORE::log($z + CORE::sqrt($z*$z - 1))}

# atanh(z) = (1/2) log((1+z) / (1-z))
sub atanh {my $z = promote(@_); CORE::log((1+$z)/(1-$z))/2}

# asech(z) = acosh(1/z)
sub asech {acosh(1/$_[0])}

# acsch(z) = asinh(1/z)
sub acsch {asinh(1/$_[0])}

# acoth(z) = (1/2) log((1+z)/(z-1))
sub acoth {my $z = promote(@_); CORE::log((1+$z)/($z-1))/2}

##################################################

sub pdot {
  my $self = shift;
  my $z = $self->stringify;
  return $z if $z !~ /[-+]/;
  return "($z)";
}

sub string {my $self = shift; Value::Complex::format($self->value,'string',@_)}
sub TeX {my $self = shift; Value::Complex::format($self->value,'TeX',@_)}

#
#  Try to make a pretty version of the number
#
sub format {
  my ($a,$b) = (shift,shift);
  my $method = shift || 'string';
  my $equation = shift;
  $a = Value::Real->make($a) unless ref($a);
  $b = Value::Real->make($b) unless ref($b);
  my $bi = 'i';
  return $a->$method($equation) if $b == 0;
  $bi = CORE::abs($b)->$method($equation,1) . 'i' if CORE::abs($b) ne 1;
  $bi = '-' . $bi if $b < 0;
  return $bi if $a == 0;
  $bi = '+' . $bi if $b > 0;
  $a = $a->$method($equation); $a = "($a)" if $a =~ m/E/i;
  return $a.$bi;
}

#
#  Values for i and pi
#
$i = $pkg->make(0,1);
$pi = 4*CORE::atan2(1,1);

#
#  So that we can use 1+3*i rather than 1+3*$i, etc.
#
sub i () {return $i}
sub pi () {return $pi}

###########################################################################

1;

