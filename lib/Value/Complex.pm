##########################################################################

package Value::Complex;
my $pkg = 'Value::Complex';

use strict;
use vars qw(@ISA $i $pi);
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
       'cmp' => \&Value::cmp,
       '~'   => sub {$_[0]->conj},
       'neg' => sub {$_[0]->neg},
       'abs' => sub {$_[0]->norm},
       'sqrt'=> sub {$_[0]->sqrt},
       'exp' => sub {$_[0]->exp},
       'log' => sub {$_[0]->log},
       'sin' => sub {$_[0]->sin},
       'cos' => sub {$_[0]->cos},
     'atan2' => \&atan2,
  'nomethod' => \&Value::nomethod,
        '""' => \&Value::stringify;

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
  my $x = shift; $x = [$x,@_] if scalar(@_) > 0;
  $x = $x->data if ref($x) eq $pkg || Value::isReal($x);
  $x = [$x] unless ref($x) eq 'ARRAY'; $x->[1] = 0 unless defined($x->[1]);
  Value::Error("Can't convert ARRAY of length ".scalar(@{$x})." to a Complex Number") 
    unless (scalar(@{$x}) == 2);
  $x->[0] = Value::makeValue($x->[0]); $x->[1] = Value::makeValue($x->[1]);
  return $x->[0] if Value::isComplex($x->[0]) && scalar(@_) == 0;
  Value::Error("Real part can't be ".Value::showClass($x->[0]))
     unless (Value::isRealNumber($x->[0]));
  Value::Error("Imaginary part can't be ".Value::showClass($x->[1]))
     unless (Value::isRealNumber($x->[1]));
  return $self->formula($x) if Value::isFormula($x->[0]) || Value::isFormula($x->[1]);
  bless {data => $x}, $class;
}

#
#  Create a new a+b*i formula from the two parts
#
sub formula {
  my $self = shift; my $value = shift;
  my $formula = Value::Formula->blank;
  my ($l,$r) = Value::toFormula($formula,@{$value});
  my $parser = $formula->{context}{parser};
  my $I = $parser->{Value}->new($formula,$i);
  $r = $parser->{BOP}->new($formula,'*',$r,$I);
  $formula->{tree} = $parser->{BOP}->new($formula,'+',$l,$r);
#   return $formula->eval if scalar(%{$formula->{variables}}) == 0;
  return $formula;
}

#
#  Return the complex type
#
sub typeRef {return $Value::Type{complex}}

sub isZero {shift eq "0"}
sub isOne {shift eq "1"}

##################################################

#
#  Return a complex if it already is one, otherwise make it one
#    (Guarantees that we have both parts in an array ref)
#
sub promote {
  my $x = shift;
  return $x if (ref($x) eq $pkg && scalar(@_) == 0);
  return $pkg->new($x,@_);
}
#
#  Get the data from the promoted item
#    (guarantees that we have an array with two elements)
#
sub promoteData {@{(promote(shift))->data}}

##################################################
#
#  Binary operations
#

sub add {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->add($l,!$flag)}
  my ($a,$b) = (@{$l->data});
  my ($c,$d) = promoteData($r);
  return $pkg->make($a + $c, $b + $d);
}

sub sub {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->sub($l,!$flag)}
  $r = promote($r);
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  my ($a,$b) = (@{$l->data});
  my ($c,$d) = (@{$r->data});
  return $pkg->make($a - $c, $b - $d);
}

sub mult {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->mult($l,!$flag)}
  my ($a,$b) = (@{$l->data});
  my ($c,$d) = promoteData($r);
  return $pkg->make($a*$c - $b*$d, $b*$c + $a*$d);
}

sub div {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->div($l,!$flag)}
  $r = promote($r);
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  my ($a,$b) = (@{$l->data});
  my ($c,$d) = (@{$r->data});
  my $x = $c*$c + $d*$d;
  Value::Error("Division by zero") if $x == 0;
  return $pkg->make(($a*$c + $b*$d)/$x,($b*$c - $a*$d)/$x);
}

sub power {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->power($l,!$flag)}
  $r = promote($r);
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  my ($a,$b) = (@{$l->data});
  my ($c,$d) = (@{$r->data});
  return Value::Real->make(1) if ($a eq '1' && $b == 0) || ($c == 0 && $d == 0);
  return Value::Real->make(0) if $c > 0 && ($a == 0 && $b == 0);
  return exp($r * log($l))
 }

sub equal {
  my ($l,$r,$flag) = @_;
  my ($a,$b) = (@{$l->data});
  my ($c,$d) = promoteData($r);
  return $a == $c && $b == $d;
}

sub compare {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->power($l,!$flag)}
  $r = promote($r);
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  my ($a,$b) = (@{$l->data});
  my ($c,$d) = (@{$r->data});
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

sub Re {return (promote(@_))->data->[0]}
sub Im {return (promote(@_))->data->[1]}

sub abs {norm(@_)}
sub norm {
  my ($a,$b) = promoteData(@_);
  return CORE::sqrt($a*$a+$b*$b);
}

sub neg {
  my ($a,$b) = promoteData(@_);
  return $pkg->make(-$a,-$b);
}

sub conj {
  my ($a,$b) = promoteData(@_);
  return $pkg->make($a,-$b);
}

sub exp {
  my ($a,$b) = promoteData(@_);
  my $e = CORE::exp($a);
  my ($c,$s) = (CORE::cos($b),CORE::sin($b));
  return $pkg->make($e*$c,$e*$s);
}

sub log {
  my $z = promote(@_);
  my ($r,$t) = ($z->mod,$z->arg);
  Value::Error("Can't compute log of zero") if ($r == 0);
  return $pkg->make(CORE::log($r),$t);
}

sub sqrt {
  my $z = promote(@_);
  $z->power(.5);
}

##################################################
#
#   Trig functions
#

# sin(z) = (exp(iz) - exp(-iz))/(2i)
sub sin {
  my ($a,$b) = promoteData(@_);
  my $e = CORE::exp($b); my $e1 = 1/$e;
  $pkg->make(CORE::sin($a)*($e+$e1)/2, CORE::cos($a)*($e-$e1)/2);
}

# cos(z) = (exp(iz) + exp(-iz))/2
sub cos {
  my ($a,$b) = promoteData(@_);
  my $e = CORE::exp($b); my $e1 = 1/$e;
  $pkg->make(CORE::cos($a)*($e+$e1)/2, CORE::sin($a)*($e1-$e)/2);
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
  my ($l,$r,$flag) = @_;
  if ($flag) {my $tmp = $l; $l = $r; $r = $l}
  my ($a,$b) = promoteData($l);
  my ($c,$d) = promoteData($r);
  if ($b == 0) {
    return CORE::atan2($a,$c) if $b == 0;
    return $pkg->make($pi/2,0) if $a == 0;
  }
  ($a,$b) = @{atan($l/$r)->data};
  $a += $pi if $c <0; $a -= 2*$pi if $a > $pi;
  return $pkg->make($a,$b);
}

##################################################
#
#   Hyperbolic functions
#

# sinh(z) = (exp(z) - exp(-z))/2
sub sinh {
  my ($a,$b) = promoteData(@_);
  my $e = CORE::exp($a); my $e1 = 1/$e;
  $pkg->make(CORE::cos($b)*($e-$e1)/2, CORE::sin($b)*($e+$e1)/2);
}

# cosh(z) = (exp(z) + exp(-z))/2
sub cosh {
  my ($a,$b) = promoteData(@_);
  my $e = CORE::exp($a); my $e1 = 1/$e;
  $pkg->make(CORE::cos($b)*($e+$e1)/2, CORE::sin($b)*($e-$e1)/2);
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

sub string {my $self = shift; Value::Complex::format(@{$self->data},'string',@_)}
sub TeX {my $self = shift; Value::Complex::format(@{$self->data},'TeX',@_)}

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
  $bi = abs($b)->$method($equation,1) . 'i' if abs($b) ne 1;
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
$pi = 4*atan2(1,1);

#
#  So that we can use 1+3*i rather than 1+3*$i, etc.
#
sub i () {return $i}
sub pi () {return $pi}

###########################################################################

1;

