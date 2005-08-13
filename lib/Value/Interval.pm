########################################################################### 
#
#  Implements the Interval class
#
package Value::Interval;
my $pkg = 'Value::Interval';

use strict;
use vars qw(@ISA);
@ISA = qw(Value);

use overload
       '+'   => sub {shift->add(@_)},
       '-'   => sub {shift->sub(@_)},
       '.'   => \&Value::_dot,
       'x'   => sub {shift->cross(@_)},
       '<=>' => sub {shift->compare(@_)},
       'cmp' => sub {shift->compare_string(@_)},
  'nomethod' => sub {shift->nomethod(@_)},
        '""' => sub {shift->stringify(@_)};

#
#  Convert a value to an interval.  The value consists of
#    an open paren string, one or two real numbers or infinities,
#    and a close paren string.
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  if (scalar(@_) == 1 && !ref($_[0])) {
    my $x = Value::makeValue($_[0]);
    if (Value::isFormula($x)) {
      return $x if $x->type eq 'Interval';
      Value::Error("Formula does not return an Interval");
    }
    return promote($x);
  }
  my ($open,$a,$b,$close) = @_;
  if (!defined($close)) {$close = $b; $b = $a}
  Value::Error("Interval() must be called with 3 or 4 arguments")
    unless defined($open) && defined($a) && defined($b) && defined($close) && scalar(@_) <= 4;
  $a = Value::makeValue($a); $b = Value::makeValue($b);
  return $self->formula($open,$a,$b,$close) if Value::isFormula($a) || Value::isFormula($b);
  Value::Error("Endpoints of intervals must be numbers on infinities") unless
    isNumOrInfinity($a) && isNumOrInfinity($b);
  my ($ia,$ib) = (isInfinity($a),isInfinity($b));
  my ($nia,$nib) = (isNegativeInfinity($a),isNegativeInfinity($b));
  Value::Error("Can't make an interval only out of Infinity") if ($ia && $ib) || ($nia && $nib);
  Value::Error("Left endpoint must be less than right endpoint")
    unless $nia || $ib || ($a <= $b && !$ia && !$nib);
  $open  = '(' if $open  eq '[' && $nia; # should be error ?
  $close = ')' if $close eq ']' && $ib;  # ditto?
  Value::Error("Open parenthesis of interval must be '(' or '['")
    unless $open eq '(' || $open eq '[';
  Value::Error("Close parenthesis of interval must be ')' or ']'")
    unless $close eq ')' || $close eq ']';
  return $self->formula($open,$a,$b,$close)
    if Value::isFormula($a) || Value::isFormula($b);
  Value::Error("Single point intervals must use '[' and ']'")
    if $a == $b && ($open ne '[' || $close ne ']');
  bless {
    data => [$a,$b], open => $open, close => $close,
    leftInfinite => $nia, rightInfinite => $ib,
    canBeInterval => 1,
  }, $class;
}

#
#  Similarly for make, but without the error checks
#
sub make {
  my $self = shift; my $class = ref($self) || $self;
  my ($open,$a,$b,$close) = @_;
  $close = $b, $b = $a unless defined($close);
  bless {
    data => [$a,$b], open => $open, close => $close,
    leftInfinite => isNegativeInfinity($a), rightInfinite => isInfinity($b),
    canBeInterval => 1,
  }, $class
}

#
#  Make a formula out of the data for an interval
#
sub formula {
  my $self = shift;
  my ($open,$a,$b,$close) = @_;
  my $formula = Value::Formula->blank;
  ($a,$b) = Value::toFormula($formula,$a,$b);
  $formula->{tree} = $formula->{context}{parser}{List}->new($formula,[$a,$b],0,
     $formula->{context}{parens}{$open},$Value::Type{number},$open,$close);
  return $formula;
}

#
#  Tests for infinities
#
sub isNumOrInfinity {
  my $n = shift;
  return isInfinity($n) || isNegativeInfinity($n) || Value::isNumber($n);
}
sub isInfinity {
  my $n = shift;
  return $n->{tree}{isInfinity} if Value::isFormula($n);
  $n = Value::makeValue($n); return 0 unless ref($n);
  return $n->{isInfinite} && !$n->{isNegative};
}
sub isNegativeInfinity {
  my $n = shift;
  return $n->{tree}{isNegativeInfinity} if Value::isFormula($n);
  $n = Value::makeValue($n); return 0 unless ref($n);
  return $n->{isInfinite} && $n->{isNegative};
}

sub isOne {0}
sub isZero {0}

#
#  Return the open and close parens as well as the endpoints
#
sub value {
  my $self = shift;
  my ($a,$b) = @{$self->data};
  return ($a,$b,$self->{open},$self->{close});
}

#
#  Return the number of endpoints
#
sub length {
  my $self = shift;
  my ($a,$b) = $self->data;
  return $a == $b ? 1 : 2;
}

#
#  Convert points and lists to intervals, when needed
#
sub promote {
  my $x = shift;
  return $pkg->new($x,@_) if scalar(@_) > 0 || ref($x) eq 'ARRAY';
  return $x if ref($x) eq $pkg;
  $x = Value::makeValue($x);
  return Value::Set->new($x) if Value::class($x) eq 'Real';
  my $open  = $x->{open};  $open  = '(' unless defined($open);
  my $close = $x->{close}; $close = ')' unless defined($close);
  return $pkg->new($open,$x->value,$close)
    if Value::class($x) =~ m/^(Point|List)$/ && $x->length == 2 &&
       ($open eq '(' || $open eq '[') && ($close eq ')' || $close eq ']');
  Value::Error("Can't convert %s to an Interval",Value::showClass($x));
}

############################################
#
#  Operations on intervals
#

#
#  Addition forms unions
#
sub add {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->add($l,!$flag)}
  $r = promote($r); if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  Value::Union::form($l,$r);
}
sub dot {my $self = shift; $self->add(@_)}

#
#  Subtraction can split into a union
#
sub sub {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->sub($l,!$flag)}
  $r = promote($r); if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  Value::Union::form(subIntervalInterval($l,$r));
}

#
#  Subtract an interval from another
#    (returns the resulting interval(s), set
#     or nothing for emtpy set)
#
sub subIntervalInterval {
  my ($l,$r) = @_;
  my ($a,$b) = $l->value; my ($c,$d) = $r->value;
  my @union = ();
  if ($d <= $a) {
    $l->{open} = '(' if $d == $a && $r->{close} eq ']';
    push(@union,$l) unless $a == $b && $l->{open} eq '(';
  } elsif ($c >= $b) {
    $l->{close} = ')' if $c == $b && $r->{open} eq '[';
    push(@union,$l) unless $a == $b && $l->{close} eq ')';
  } else {
    if ($a == $c) {
      push(@union,Value::Set->new($a))
	if $l->{open} eq '[' && $r->{open} eq '(';
    } elsif ($a < $c) {
      my $close = ($r->{open} eq '[')? ')': ']';
      push(@union,Value::Interval->new($l->{open},$a,$c,$close));
    }
    if ($d == $b) {
      push(@union,Value::Set->new($b))
	if $l->{close} eq ']' && $r->{close} eq ')';
    } elsif ($d < $b) {
      my $open = ($r->{close} eq ']') ? '(': '[';
      push(@union,Value::Interval->new($open,$d,$b,$l->{close}));
    }
  }
  return @union;
}

#
#  Lexicographic order, but with type of endpoint included
#    in the test.
#
sub compare {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->compare($l,!$flag)}
  $r = promote($r); if ($flag) {my $tmp = $l; $l = $r; $r = $tmp};
  my ($la,$lb) = @{$l->data}; my ($ra,$rb) = @{$r->data};
  my $cmp = $la <=> $ra; return $cmp if $cmp;
  my $ignoreEndpointTypes = $l->getFlag('ignoreEndpointTypes');
  $cmp = $l->{open} cmp $r->{open}; return $cmp if $cmp && !$ignoreEndpointTypes;
  $cmp = $lb <=> $rb; return $cmp if $cmp || $ignoreEndpointTypes;
  return $l->{close} cmp $r->{close};
}

############################################
#
#  Utility routines
#

sub reduce {shift}
sub isReduced {1}
sub sort {shift}

###########################################################################

1;
