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
       '+'   => \&add,
       '.'   => \&Value::_dot,
       'x'   => \&Value::cross,
       '<=>' => \&compare,
       'cmp' => \&compare,
  'nomethod' => \&Value::nomethod,
        '""' => \&stringify;

#
#  Convert a value to an interval.  The value consists of
#    an open paren string, one or two real numbers or infinities,
#    and a close paren string.
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my ($open,$a,$b,$close) = @_;
  if (!defined($close)) {$close = $b; $b = $a}
  Value::Error("Endpoints of intervals must be numbers") unless
    isNumOrInfinity($a) && isNumOrInfinity($b);
  my ($ia,$ib) = (isInfinity($a),isInfinity($b));
  my ($nia,$nib) = (isNegativeInfinity($a),isNegativeInfinity($b));
  Value::Error("Can't make an interval only out of Infinity") if ($ia && $ib) || ($nia && $nib);
  Value::Error("Left endpoint must be less than right endpoint")
    unless $nia || $ib || ($a <= $b && !$ia && !$nib);
  $open  = '(' if $open  eq '[' && $nia;
  $close = ')' if $close eq ']' && $ib;
  Value::Error("Open parenthesis of interval must be '(' or '['")
    unless $open eq '(' || $open eq '[';
  Value::Error("Close parenthesis of interval must be ')' or ']'")
    unless $close eq ')' || $close eq ']';
  Value::Error("Single point intervals must use '[' and ']'")
    if Value::matchNumber($a) && Value::matchNumber($b) && $a == $b &&
      ($open ne '[' || $close ne ']');
  return $self->formula($open,$a,$b,$close)
    if Value::isFormula($a) || Value::isFormula($b);
  if ($$Value::context->flag('useFuzzyReals')) {
    $a = Value::Real->make($a) unless $nia;
    $b = Value::Real->make($b) unless $ib;
  }
  bless {
    data => [$a,$b], open => $open, close => $close,
    leftInfinite => $nia, rightInfinite => $ib,
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
  $formula->{tree} = Parser::List->new($formula,[$a,$b],0,
     $formula->{context}{parens}{$open},$Value::Type{number},$open,$close);
#   return $formula->eval if scalar(%{$formula->{variables}}) == 0;
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
  return 1 if !ref($n) && $n eq 'INF';
  return (Value::isFormula($n) && $n->{tree}{isInfinity});
}
sub isNegativeInfinity {
  my $n = shift;
  return 1 if !ref($n) && $n eq '-INF';
  return (Value::isFormula($n) && $n->{tree}{isNegativeInfinity});
}

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
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  Value::Error("Intervals can only be added to Intervals")
    unless Value::class($l) eq 'Interval' && Value::class($r) eq 'Interval';
  return Value::Union->new($l,$r);
}
sub dot {add(@_)}


#
#  Lexicographic order, but with type of endpoint included
#    in the test.
#
sub compare {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->compare($l,!$flag)}
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp};
  if (Value::class($l) eq 'Interval' && Value::class($r) eq 'Interval') {
    my ($la,$lb) = @{$l->data}; my ($ra,$rb) = @{$r->data};
    my $cmp = $la <=> $ra; return $cmp if $cmp;
    $cmp = $l->{open} cmp $r->{open}; return $cmp if $cmp;
    $cmp = $lb <=> $rb; return $cmp if $cmp;
    return $l->{close} cmp $r->{close};
  } else {
    $l = $l->data if Value::isValue($l);
    $r = $r->data if Value::isValue($r);
    return $l <=> $r;
  }
}

############################################
#
#  Generate the various output formats.
#

sub stringify {
  my $self = shift;
  my ($a,$b) = @{$self->data};
  $a = $a->string if Value::isReal($a);
  $b = $b->string if Value::isReal($b);
  return $self->{open}.$a.$self->{close} 
    if $a == $b && !$self->{leftInfinte} && !$self->{rightInfinite};
  return $self->{open}.$a.','.$b.$self->{close};
}

sub TeX {
  my $self = shift;
  my ($a,$b) = @{$self->data};
  $a = ($self->{leftInfinite})? '-\infty' : (Value::isReal($a) ? $a->TeX: $a);
  $b = ($self->{rightInfinite})? '\infty' : (Value::isReal($b) ? $b->TeX: $b);
  return $self->{open}.$a.$self->{close} 
    if !$self->{leftInfinte} && !$self->{rightInfinite} && $a == $b;
  return $self->{open}.$a.','.$b.$self->{close};
}

###########################################################################

1;

