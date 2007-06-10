##########################################################################
#
#  Implements "fuzzy" real numbers (two are equal when they are "close enough")
#

package Value::Real;
my $pkg = 'Value::Real';

use strict;
our @ISA = qw(Value);

#
#  Check that the input is a real number or a formula
#  or a string that evaluates to a number
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $x = shift; $x = [$x,@_] if scalar(@_) > 0;
  return $x if ref($x) eq $pkg;
  $x = [$x] unless ref($x) eq 'ARRAY';
  Value::Error("Can't convert ARRAY of length %d to %s",scalar(@{$x}),Value::showClass($self))
    unless (scalar(@{$x}) == 1);
  if (Value::isRealNumber($x->[0])) {
    return $self->formula($x->[0]) if Value::isFormula($x->[0]);
    return (bless {data => $x, context=>$context}, $class);
  }
  $x = Value::makeValue($x->[0],context=>$context);
  return $x if Value::isRealNumber($x);
  Value::Error("Can't convert %s to %s",Value::showClass($x),Value::showClass($self));
}

#
#  Check that result is a number
#
sub make {
  my $self = shift;
  my $n = (Value::isContext($_[0]) ? $_[1] : $_[0]);
  return $self->SUPER::make(@_) unless $n eq "nan";
  Value::Error("Result is not a real number");
}

#
#  Create a new formula from the number
#
sub formula {
  my $self = shift; my $value = shift;
  $self->Package("Formula")->new($self->context,$value);
}

#
#  Return the real number type
#
sub typeRef {return $Value::Type{number}}
sub length {1}

#
#  return the real number
#
sub value {(shift)->{data}[0]}

sub isZero {shift eq "0"}
sub isOne {shift eq "1"}


##################################################

#
#  Return a real if it already is one, otherwise make it one
#
sub promote {
  my $self = shift;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $x = (scalar(@_) ? shift : $self);
  return $x->inContext($context) if ref($x) eq $pkg && scalar(@_) == 0;
  return $self->new($context,$x,@_);
}


##################################################
#
#  Binary operations
#

sub add {
  my ($l,$r) = @_; my $self = $l;
  return $self->make($l->{data}[0] + $r->{data}[0]);
}

sub sub {
  my ($self,$l,$r) = Value::checkOpOrder(@_);
  return $self->make($l->{data}[0] - $r->{data}[0]);
}

sub mult {
  my ($l,$r) = @_; my $self = $l;
  return $self->make($l->{data}[0] * $r->{data}[0]);
}

sub div {
  my ($self,$l,$r) = Value::checkOpOrder(@_);
  Value::Error("Division by zero") if $r->{data}[0] == 0;
  return $self->make($l->{data}[0] / $r->{data}[0]);
}

sub power {
  my ($self,$l,$r) = Value::checkOpOrder(@_);
  my $x = $l->{data}[0] ** $r->{data}[0];
  return $self->make($x) unless $x eq 'nan';
  Value::Error("Can't raise a negative number to a power") if ($l->{data}[0] < 0);
  Value::Error("Result of exponention is not a number");
}

sub modulo {
  my ($self,$l,$r) = Value::checkOpOrder(@_);
  $l = $l->{data}[0]; $r = $r->{data}[0];
  return $self->make(0) if $r->value == 0; # non-fuzzy check
  my $m = $l/$r;
  my $n = int($m); $n-- if $n > $m; # act as floor() rather than int()
  return $self->make($l - $n*$r);
}

sub compare {
  my ($self,$l,$r) = Value::checkOpOrder(@_);
  #
  #  Handle periodic Reals
  #
  my $m = $self->{period};
  if (defined $m) {
    if ($self->{logPeriodic}) {
      return 1 if $l->value == 0 || $r->value == 0; # non-fuzzy checks
      $l = log($l); $r = log($r);
    }
    return (($l-$r+$m/2) % $m) <=> $m/2;
  }

  my ($a,$b) = ($l->{data}[0],$r->{data}[0]);
  if ($self->getFlag('useFuzzyReals')) {
    my $tolerance = $self->getFlag('tolerance');
    if ($self->getFlag('tolType') eq 'relative') {
      my $zeroLevel = $self->getFlag('zeroLevel');
      if (abs($a) < $zeroLevel || abs($b) < $zeroLevel) {
	$tolerance = $self->getFlag('zeroLevelTol');
      } else {
	$tolerance = $tolerance * abs($a);
      }
    }
    return 0 if abs($a-$b) < $tolerance;
  }
  return $a <=> $b;
}

##################################################
#
#   Numeric functions
#

sub abs {my $self = shift; $self->make(CORE::abs($self->{data}[0]))}
sub neg {my $self = shift; $self->make(-($self->{data}[0]))}
sub exp {my $self = shift; $self->make(CORE::exp($self->{data}[0]))}
sub log {my $self = shift; $self->make(CORE::log($self->{data}[0]))}

sub sqrt {
  my $self = shift;
  return $self->make(CORE::sqrt($self->{data}[0]));
}

##################################################
#
#   Trig functions
#

sub sin {my $self = shift; $self->make(CORE::sin($self->{data}[0]))}
sub cos {my $self = shift; $self->make(CORE::cos($self->{data}[0]))}

sub atan2 {
  my ($self,$l,$r) = Value::checkOpOrder(@_);
  return $self->make(CORE::atan2($l->{data}[0],$r->{data}[0]));
}

##################################################

sub string {
  my $self = shift; my $equation = shift; my $prec = shift;
  my $n = $self->{data}[0]; my $format = $self->{format};
  $format = ($equation->{context} || $self->context)->{format}{number} unless defined $format;
  if ($format) {
    $n = sprintf($format,$n);
    if ($format =~ m/#\s*$/) {$n =~ s/(\.\d*?)0*#$/$1/; $n =~ s/\.$//}
  }
  $n = uc($n); # force e notation to E
  $n = 0 if abs($n) < $self->getFlag('zeroLevelTol');
  $n = "(".$n.")" if ($n < 0 || $n =~ m/E/i) && defined($prec) && $prec >= 1;
  return $n;
}

sub TeX {
  my $n = (shift)->string(@_);
  $n =~ s/E\+?(-?)0*([^)]*)/\\times 10^{$1$2}/i; # convert E notation to x10^(...)
  return $n;
}


###########################################################################

1;
