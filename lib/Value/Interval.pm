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
       'cmp' => \&Value::cmp,
  'nomethod' => \&Value::nomethod,
        '""' => \&Value::stringify;

#
#  Convert a value to an interval.  The value consists of
#    an open paren string, one or two real numbers or infinities,
#    and a close paren string.
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  if (scalar(@_) == 1 && !ref($_[0])) {
    my $num = $$Value::context->{pattern}{signedNumber};
    my $inf = $$Value::context->{pattern}{infinite};
    @_ = ($1,$2,$3,$4) if $_[0] =~ m/^ *(\(|\[) *($num|$inf) *, *($num|$inf) *(\)|\]) *$/;
  }
  my ($open,$a,$b,$close) = @_;
  if (!defined($close)) {$close = $b; $b = $a}
  Value::Error("Interval() must be called with 3 or 4 arguments")
    unless defined($open) && defined($a) && defined($b) && defined($close);
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
  my $open  = $x->{open};  $open  = '(' unless defined($open);
  my $close = $x->{close}; $close = ')' unless defined($close);
  return $pkg->new($open,@{$x->data},$close)
    if Value::class($x) =~ m/^(Point|List)$/ && $x->length == 2 &&
       ($open eq '(' || $open eq '[') && ($close eq ')' || $close eq ']');
  Value::Error("Can't convert ".Value::showClass($x)." to an Interval");
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
  $r = promote($r);
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
  $r = promote($r);
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp};
  my ($la,$lb) = @{$l->data}; my ($ra,$rb) = @{$r->data};
  my $cmp = $la <=> $ra; return $cmp if $cmp;
  $cmp = $l->{open} cmp $r->{open}; return $cmp if $cmp;
  $cmp = $lb <=> $rb; return $cmp if $cmp;
  return $l->{close} cmp $r->{close};
}

############################################
#
#  Generate the various output formats.
#

sub string {
  my $self = shift; my $equation = shift;
  my ($a,$b) = @{$self->data};
  $a = $a->string($equation) if Value::isValue($a);
  $b = $b->string($equation) if Value::isValue($b);
#  return $self->{open}.$a.$self->{close} 
#    if !$self->{leftInfinte} && !$self->{rightInfinite} && $a == $b;
  return $self->{open}.$a.','.$b.$self->{close};
}

sub TeX {
  my $self = shift; my $equation = shift;
  my ($a,$b) = @{$self->data};
  $a = $a->TeX($equation) if Value::isValue($a);
  $b = $b->TeX($equation) if Value::isValue($b);
  my $open = $self->{open}; my $close = $self->{close};
  $open = '\{' if $open eq '{'; $close = '\}' if $close eq '}';
  $open = '\left'.$open if $open; $close = '\right'.$close if $close;
#  return $open.$a.$close if !$self->{leftInfinte} && !$self->{rightInfinite} && $a == $b;
  return $open.$a.','.$b.$close;
}

###########################################################################

1;
