##########################################################################
#
#  Implements "fuzzy" real numbers (two are equal when they are "close enough")
#

package Value::Real;
my $pkg = 'Value::Real';

use strict; no strict "refs";
our @ISA = qw(Value);

#
#  Check that the input is a real number or a formula
#  or a string that evaluates to a number
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $x = shift; $x = [$x,@_] if scalar(@_) > 0;
  return $x->inContext($context) if Value::isReal($x);
  $x = [$x] unless ref($x) eq 'ARRAY';
  Value::Error("Can't convert ARRAY of length %d to %s",scalar(@{$x}),Value::showClass($self))
    unless (scalar(@{$x}) == 1);
  if (Value::matchNumber($x->[0])) {
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
  return $self->SUPER::make(@_) unless lc("$n") eq "nan" or lc("$n") eq "-nan";
  Value::Error("Result is not a real number");
}

#
#  Create a new formula from the number
#
sub formula {
  my $self = shift; my $value = shift;
  my $context = $self->context;
  $context->Package("Formula")->new($context,$value);
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

sub transferFlags {}


##################################################
#
#  Binary operations
#

sub add {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  return $self->inherit($other)->make($l->{data}[0] + $r->{data}[0]);
}

sub sub {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  return $self->inherit($other)->make($l->{data}[0] - $r->{data}[0]);
}

sub mult {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  return $self->inherit($other)->make($l->{data}[0] * $r->{data}[0]);
}

sub div {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  Value::Error("Division by zero") if $r->{data}[0] == 0;
  return $self->inherit($other)->make($l->{data}[0] / $r->{data}[0]);
}

sub power {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  my $x = $l->{data}[0] ** $r->{data}[0];
  return $self->inherit($other)->make($x) unless lc($x) eq 'nan' or lc($x) eq '-nan';
  Value::Error("Can't raise a negative number to a non-integer power") if ($l->{data}[0] < 0);
  Value::Error("Result of exponention is not a number");
}

sub modulo {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  $l = $l->{data}[0]; $r = $r->{data}[0];
  return $self->inherit($other)->make(0) if $r == 0; # non-fuzzy check
  my $m = $l/$r;
  my $n = int($m); $n-- if $n > $m; # act as floor() rather than int()
  return $self->inherit($other)->make($l - $n*$r);
}

sub compare {
  my ($self,$l,$r) = Value::checkOpOrderWithPromote(@_);
  #
  #  Handle periodic Reals
  #
  my $m = $self->getFlag("period");
  if (defined $m) {
    $l = $l->with(period=>undef);  # make sure tests below don't use period
    $r = $r->with(period=>undef);
    if ($self->getFlag("logPeriodic")) {
      return 1 if $l->value == 0 || $r->value == 0; # non-fuzzy checks
      $l = log($l); $r = log($r);
    }
    $m = $self->promote($m); my $m2 = $m/2;
    $m2 = 3*$m/2 if $m2 == -$l; # make sure we don't get zero tolerances accidentally
    return $l + (($l-$r+$m2) % $m) <=> $l + $m2; # tolerances appropriate to $l centered in $m
  }

  my ($a,$b) = ($l->{data}[0],$r->{data}[0]);
  if ($self->getFlag('useFuzzyReals')) {
    my $tolerance = $self->getFlag('tolerance');
    my $zeroLevel = $self->getFlag('zeroLevel');
    if ($self->getFlag('tolType') eq 'digits') {
      return 0 if (abs($a) < $zeroLevel and abs($b) < $zeroLevel);
      return $a <=> $b if (abs($a) < $zeroLevel or abs($b) < $zeroLevel);
      # convert tolerance values meant for relative to a digits tolerance
      $tolerance = -log($tolerance)/log(10) if ($tolerance > 0 and $tolerance < 1);
      my $digits = (1 > int($tolerance) ? 1 : int($tolerance + 0.5)) - 1;
      my $extraDigits =  int($self->getFlag('tolExtraDigits'));
      my $tdigits = (0 < $extraDigits ? $extraDigits + $digits : $digits);
      my $exp = substr(sprintf("%E", $b), -3) - 15;      # Adjust $a by an amount in the round-off error
      $a += ($a <=> 0) * "1E$exp";                       #   range so that it rounds better in sprintf
      $b += ($b <=> 0) * "1E$exp";                       # Same for $b
      my $bd = sprintf("%.${tdigits}E", $b);             # Round $b to the number of tdigits
      $bd =~ s/^.*\.(.*?)0*E.*$/$1/;                     # Get the decimal part without trailing zeros
      my $bn = length($bd);                              # Number of those decimal digits
      $bn = $digits if ($bn < $digits);                  #  (with a minimum of $digits);
      my $aE = sprintf("%.${bn}E", $a);                  # Round $a to $bn digits
      my $bE = sprintf("%.${bn}E", $b);                  # Round $b to $bn digits
      return 0 if $aE eq $bE;                            # Return equal if they are
      if ($self->getFlag('tolTruncation')) {             # If truncation is allowed
        $aE = sprintf("%.15E", $a);                      #   Get $a to full resolution
        $aE =~ s/\.(\d{$bn}).*E/.\1E/; $aE =~ s/\.E/E/;  #   Truncate it to the required number of digits
        return 0 if $aE eq $bE;                          #   Return equal if they are
      }                                                  #
      return $a <=> $b;                                  # Otherwise compare numbers as perl reals
    }
    if ($self->getFlag('tolType') eq 'relative') {
      if (CORE::abs($a) < $zeroLevel || CORE::abs($b) < $zeroLevel) {
	$tolerance = $self->getFlag('zeroLevelTol');
      } else {
	$tolerance = $tolerance * CORE::abs($a);
      }
    }
    return 0 if CORE::abs($a-$b) < $tolerance;
  }
  return $a <=> $b;
}

##################################################
#
#   Numeric functions
#

sub abs  {my $self = shift; $self->make(CORE::abs($self->{data}[0]))}
sub neg  {my $self = shift; $self->make(-($self->{data}[0]))}
sub exp  {my $self = shift; $self->make(CORE::exp($self->{data}[0]))}
sub log  {my $self = shift; $self->make(CORE::log($self->{data}[0]))}
sub sqrt {my $self = shift; $self->make(CORE::sqrt($self->{data}[0]))}

##################################################
#
#   Trig functions
#

sub sin {my $self = shift; $self->make(CORE::sin($self->{data}[0]))}
sub cos {my $self = shift; $self->make(CORE::cos($self->{data}[0]))}

sub atan2 {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  return $self->inherit($other)->make(CORE::atan2($l->{data}[0],$r->{data}[0]));
}

##################################################

sub string {
  my $self = shift; my $equation = shift; shift; shift; my $prec = shift;
  my $n = $self->{data}[0];
  my $format = $self->getFlag("format",$equation->{format} ||
			        ($equation->{context} || $self->context)->{format}{number});
  if ($format) {
    $n = sprintf($format,$n);
    if ($format =~ m/#\s*$/) {$n =~ s/(\.\d*?)0*#$/$1/; $n =~ s/\.$//}
  }
  $n = uc($n); # force e notation to E
  $n = 0 if CORE::abs($n) < $self->getFlag('zeroLevelTol');
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
