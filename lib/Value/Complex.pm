##########################################################################

package Value::Complex;
my $pkg = 'Value::Complex';

use strict; no strict "refs";
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
  return $x->inContext($context) if Value::isComplex($x) || (Value::isFormula($x) && $x->{tree}->isComplex);
  $x = $x->data if Value::isReal($x);
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
  my $c = bless {$self->hash, data => [@_[0,1]], context => $context}, $class;
  foreach my $x (@{$c->{data}}) {$x = $context->Package("Real")->make($context,$x) unless Value::isValue($x)}
  return $c;
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
#  Get the data from the promoted item
#    (guarantees that we have an array with two elements)
#
sub promoteData {
  my $self = shift;
  return $self->value if Value::isComplex($self) && scalar(@_) == 0;
  return ($self->promote(@_))->value;
}

##################################################
#
#  Binary operations
#

sub add {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  my ($a,$b) = $l->value; my ($c,$d) = $r->value;
  return $self->inherit($other)->make($a + $c, $b + $d);
}

sub sub {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  my ($a,$b) = $l->value; my ($c,$d) = $r->value;
  return $self->inherit($other)->make($a - $c, $b - $d);
}

sub mult {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  my ($a,$b) = $l->value; my ($c,$d) = $r->value;
  return $self->inherit($other)->make($a*$c - $b*$d, $b*$c + $a*$d);
}

sub div {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  my ($a,$b) = $l->value; my ($c,$d) = $r->value;
  my $x = $c*$c + $d*$d;
  Value::Error("Division by zero") if $x->value == 0;
  return $self->inherit($other)->make(($a*$c + $b*$d)/$x,($b*$c - $a*$d)/$x);
}

sub power {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  my ($a,$b) = $l->value; my ($c,$d) = $r->value;
  return $self->inherit($other)->make(1,0) if ($a->value == 1 && $b->value == 0) || ($c->value == 0 && $d->value == 0);
  return $self->inherit($other)->make(0,0) if $c->value > 0 && ($a->value == 0 && $b->value == 0);
  return exp($r * log($l))
 }

sub modulo {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  return $self->inherit($other)->make(0) if abs($r)->value == 0; # non-fuzzy check
  my $m = Re($l/$r)->value;
  my $n = int($m); $n-- if $n > $m; # act as floor() rather than int()
  return $l - $n*$r;
}

sub compare {
  my ($self,$l,$r) = Value::checkOpOrderWithPromote(@_);
  #
  #  Handle periodic Complex numbers
  #
  my $m = $self->getFlag("period");
  if (defined $m) {
    $l = $l->with(period=>undef);  # make sure tests below don't use period
    $r = $r->with(period=>undef);
    if ($self->getFlag("logPeriodic")) {
      return 1 if abs($l)->value == 0 || abs($r)->value == 0; # non-fuzzy checks
      $l = log($l); $r = log($r);
    }
    $m = $self->promote($m); my $m2 = $m/2;
    $m2 = 3*$m/2 if $m2 == -$l; # make sure we don't get zero tolerances accidentally
    return $l + (($l-$r+$m2) % $m) <=> $l + $m2; # tolerances appropriate to $l centered in $m
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
  my $self = shift; my ($a,$b) = $self->value;
  return $self->make(-$a,-$b);
}

sub conj {(shift)->twiddle(@_)}
sub twiddle {
  my $self = shift; my ($a,$b) = $self->value;
  return $self->make($a,-$b);
}

sub exp {
  my $self = shift; my ($a,$b) = $self->value;
  my $e = CORE::exp($a);
  my ($c,$s) = (CORE::cos($b),CORE::sin($b));
  return $self->make($e*$c,$e*$s);
}

sub log {
  my $self = shift;
  my ($r,$t) = ($self->mod,$self->arg);
  Value::Error("Can't compute log of zero") if ($r == 0);
  return $self->make(CORE::log($r),$t);
}

sub sqrt {(shift)**(.5)}

##################################################
#
#   Trig functions
#

# sin(z) = (exp(iz) - exp(-iz))/(2i)
sub sin {
  my $self = shift; my ($a,$b) = $self->value;
  my $e = CORE::exp($b); my $e1 = 1/$e;
  $self->make(CORE::sin($a)*($e+$e1)/2, CORE::cos($a)*($e-$e1)/2);
}

# cos(z) = (exp(iz) + exp(-iz))/2
sub cos {
  my $self = shift; my ($a,$b) = $self->value;
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
sub acos {my $z = shift; CORE::log($z + CORE::sqrt($z*$z - 1)) * (-$i)}

# asin(z) = -i log(iz + sqrt(1 - z^2))
sub asin {my $z = shift; CORE::log($z*$i + CORE::sqrt(1 - $z*$z)) * (-$i)}

# atan(z) = (i/2) log((i+z)/(i-z))
sub atan {my $z = shift; CORE::log(($z+$i)/($i-$z))*($i/2)}

# asec(z) = acos(1/z)
sub asec {acos(1/$_[0])}

# acsc(z) = asin(1/z)
sub acsc {asin(1/$_[0])}

# acot(z) = atan(1/z)
sub acot {atan(1/$_[0])}

# atan2(z1,z2) = atan(z1/z2)
sub atan2 {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  $self = $self->inherit($other);
  my ($a,$b) = $l->value; my ($c,$d) = $r->value;
  if ($c->value == 0 && $d->value == 0) {
    return $self->make(0,0) if ($a->value == 0 && $b->value == 0);
    return $self->make(($a->value > 0 ? $pi/2 : -$pi/2),0);
  }
  ($a,$b) = atan($l/$r)->value;
  $a += $pi if $c->value < 0; $a -= 2*$pi if $a->value > $pi;
  return $self->make($a,$b);
}

##################################################
#
#   Hyperbolic functions
#

# sinh(z) = (exp(z) - exp(-z))/2
sub sinh {
  my $self = shift; my ($a,$b) = $self->value;
  my $e = CORE::exp($a); my $e1 = 1/$e;
  $self->make(CORE::cos($b)*($e-$e1)/2, CORE::sin($b)*($e+$e1)/2);
}

# cosh(z) = (exp(z) + exp(-z))/2
sub cosh {
  my $self = shift; my ($a,$b) = $self->value;
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
sub asinh {my $z = shift; CORE::log($z + CORE::sqrt($z*$z + 1))}

# acosh(z) = log(z + sqrt(z^2 - 1))
sub acosh {my $z = shift; CORE::log($z + CORE::sqrt($z*$z - 1))}

# atanh(z) = (1/2) log((1+z) / (1-z))
sub atanh {my $z = shift; CORE::log((1+$z)/(1-$z))/2}

# asech(z) = acosh(1/z)
sub asech {acosh(1/$_[0])}

# acsch(z) = asinh(1/z)
sub acsch {asinh(1/$_[0])}

# acoth(z) = (1/2) log((1+z)/(z-1))
sub acoth {my $z = shift; CORE::log((1+$z)/($z-1))/2}

##################################################

sub pdot {
  my $self = shift;
  my $z = $self->stringify;
  return $z if $z !~ /[-+]/;
  return "($z)";
}

sub string {my $self = shift; Value::Complex::format($self->{format},$self->value,'string',@_)}
sub TeX {my $self = shift; Value::Complex::format($self->{format},$self->value,'TeX',@_)}

#
#  Try to make a pretty version of the number
#
sub format {
  my $format = shift;
  my ($a,$b) = (shift,shift);
  my $method = shift || 'string';
  my $equation = shift;
  $a = Value::Real->make($a) unless ref($a);
  $b = Value::Real->make($b) unless ref($b);
  $a->{format} = $b->{format} = $format if defined $format;
  my $bi = 'i';
  return $a->$method($equation) if $b == 0;
  $bi = CORE::abs($b)->with(format=>$format)->$method($equation,1) . 'i' if CORE::abs($b) !~ m/^1(\.0*)?$/;
  $bi = '-' . $bi if $b < 0;
  return $bi if $a == 0;
  $bi = '+' . $bi if $b > 0;
  $a = $a->$method($equation); $a = "($a)" if $a =~ m/E/i;
  return $a.$bi;
}

sub perl {
  my $self = shift; my $parens = shift;
  my $s = Value::Complex::format($self->{format},$self->value,"string",$self->{equation});
  $s =~ s/(\d)i$/\1*i/; $s = "(".$s.")" if $parens;
  return $s;
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

