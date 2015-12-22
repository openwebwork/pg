########################################################################### 
#
#  Implements the Interval class
#
package Value::Interval;
my $pkg = 'Value::Interval';

use strict; no strict "refs";
our @ISA = qw(Value);

#
#  Convert a value to an interval.  The value consists of
#    an open paren string, one or two real numbers or infinities,
#    and a close paren string.
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  if (scalar(@_) == 1) {
    my $x = Value::makeValue($_[0],context=>$context);
    if (Value::isFormula($x)) {
      return $x if $x->type eq 'Interval';
      Value::Error("Formula does not return an Interval");
    }
    return $self->promote($context,$x);
  }
  my @params = @_;
  Value::Error("Interval can't be empty") unless scalar(@params) > 0;
  Value::Error("Too many arguments for Interval") if scalar(@params) > 4;
  return $context->Package("Set")->new($context,@params) if scalar(@params) == 1;
  @params = ('(',@params,')') if (scalar(@params) == 2);
  my ($open,$a,$b,$close) = @params;
  ($b,$close) = ($a,$b) unless defined($close);
  ($a,$b,$open) = ($open,$a,$b) if !ref($b) && ($b eq '(' || $b eq '[');
  $a = Value::makeValue($a,context=>$context); $b = Value::makeValue($b,context=>$context);
  return $self->formula($open,$a,$b,$close) if Value::isFormula($a) || Value::isFormula($b);
  Value::Error("Endpoints of intervals must be numbers or infinities") unless
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
  return $context->Package("Set")->new($context,$a) if $a == $b;
  bless {
    $self->hashNoInherit,
    data => [$a,$b], open => $open, close => $close,
    leftInfinite => $nia, rightInfinite => $ib,
    context => $context,
  }, $class;
}

#
#  Similarly for make, but without the error checks
#
sub make {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my ($open,$a,$b,$close) = @_;
  ($open,$a,$b,$close) = ("(",$open,$a,")") unless defined($b);
  ($b,$close) = ($a,$b) unless defined($close);
  ($a,$b,$open) = ($open,$a,$b) if !ref($b) && ($b eq '(' || $b eq '[');
  bless {
    data => [$a,$b], open => $open, close => $close,
    leftInfinite => isNegativeInfinity($a), rightInfinite => isInfinity($b),
    context => $context,
  }, $class
}

#
#  Make a formula out of the data for an interval
#
sub formula {
  my $self = shift;
  my ($open,$a,$b,$close) = @_;
  my $context = $self->context;
  my $formula = $context->Package("Formula")->blank($context);
  ($a,$b) = Value::toFormula($formula,$a,$b);
  $formula->{tree} = $formula->Item("List")->new($formula,[$a,$b],0,
     $context->{parens}{$open},$Value::Type{number},$open,$close);
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

sub canBeInUnion {1}
sub isSetOfReals {1}

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
  my ($a,$b) = $self->value;
  return $a == $b ? 1 : 2;
}

#
#  Only transfer flags to the endpoints
#
sub transferFlags {
  my $self = shift;
  foreach my $flag (@_) {
    next unless defined $self->{$flag};
    foreach my $i (0,1) {$self->{data}[$i]->{$flag} = $self->{$flag}}
  }
}

#
#  Convert points and lists to intervals, when needed
#
sub promote {
  my $self = shift;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $x = (scalar(@_) ? shift : $self);
  return $self->new($context,$x,@_) if scalar(@_) > 0;
  $x = Value::makeValue($x,context=>$context);
  return $x->inContext($context) if $x->isSetOfReals;
  return $context->Package("Set")->new($context,$x) if Value::isReal($x);
  my $open  = $x->{open};  $open  = '(' unless defined($open);
  my $close = $x->{close}; $close = ')' unless defined($close);
  return $self->new($context,$open,$x->value,$close) if $x->canBeInUnion;
  Value::Error("Can't convert %s to %s",Value::showClass($x),Value::showClass($self));
}

############################################
#
#  Operations on intervals
#

#
#  Addition forms unions
#
sub add {
  my ($self,$l,$r) = Value::checkOpOrderWithPromote(@_);
  Value::Union::form($self->context,$l,$r);
}
sub dot {my $self = shift; $self->add(@_)}

#
#  Subtraction can split into a union
#
sub sub {
  my ($self,$l,$r) = Value::checkOpOrderWithPromote(@_);
  Value::Union::form($self->context,Value::Union::subUnionUnion([$l],[$r]));
}

#
#  Subtract an interval from another
#    (returns the resulting interval(s), set
#     or nothing for emtpy set)
#
sub subIntervalInterval {
  my ($l,$r) = @_; $l = $l->copy; $r = $r->copy;
  my ($a,$b) = $l->value; my ($c,$d) = $r->value;
  my $self = $l; my $context = $self->context;
  my @union = ();
  if ($d <= $a) {
    $l->{open} = '(' if $d == $a && $r->{close} eq ']';
    push(@union,$l) unless $a == $b && $l->{open} eq '(';
  } elsif ($c >= $b) {
    $l->{close} = ')' if $c == $b && $r->{open} eq '[';
    push(@union,$l) unless $a == $b && $l->{close} eq ')';
  } else {
    if ($a == $c) {
      push(@union,$context->Package("Set")->make($context,$a))
	if $l->{open} eq '[' && $r->{open} eq '(';
    } elsif ($a < $c) {
      my $close = ($r->{open} eq '[')? ')': ']';
      push(@union,$context->Package("Interval")->make($context,$l->{open},$a,$c,$close));
    }
    if ($d == $b) {
      push(@union,$context->Package("Set")->make($context,$b))
	if $l->{close} eq ']' && $r->{close} eq ')';
    } elsif ($d < $b) {
      my $open = ($r->{close} eq ']') ? '(': '[';
      push(@union,$context->Package("Interval")->make($context,$open,$d,$b,$l->{close}));
    }
  }
  return @union;
}

#
#  Lexicographic order, but with type of endpoint included
#    in the test.
#
sub compare {
  my ($self,$l,$r) = Value::checkOpOrderWithPromote(@_);
  my ($la,$lb) = $l->value; my ($ra,$rb) = $r->value;
  my $cmp = $la <=> $ra; return $cmp if $cmp;
  my $ignoreEndpointTypes = $l->getFlag('ignoreEndpointTypes');
  $cmp = $r->{open} cmp $l->{open}; return $cmp if $cmp && !$ignoreEndpointTypes;
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


#
#  Tests for containment, subsets, etc.
#

sub contains {
  my $self = shift; my $other = $self->promote(@_);
  return ($other - $self)->isEmpty;
}

sub isSubsetOf {
  my $self = shift; my $other = $self->promote(@_);
  return $other->contains($self);
}

sub isEmpty {0}

sub intersect {
  my $self = shift; my $other = $self->promote(@_);
  return $self-($self-$other);
}

sub intersects {
  my $self = shift; my $other = $self->promote(@_);
  return !$self->intersect($other)->isEmpty;
}

###########################################################################

1;
