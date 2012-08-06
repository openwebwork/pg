########################################################################### 

package Value::Union;
my $pkg = 'Value::Union';

use strict; no strict "refs";
our @ISA = qw(Value);

#
#  Convert a value to a union of intervals.  The value must be
#      a list of two or more Interval, Union or Point objects.
#      Points will be converted to intervals if they are length 1 or 2.
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  if (scalar(@_) == 1 && !ref($_[0])) {
    my $x = Value::makeValue($_[0],context=>$context);
    if (Value::isFormula($x)) {
      return $x if $x->type =~ m/Interval|Union|Set/;
      Value::Error("Formula does not return an Interval, Set or Union");
    }
    $x = $self->promote($context,$x); $x = $self->make($context,$x) unless $x->type eq 'Union';
    return $x;
  }
  my @intervals = (); my $isFormula = 0;
  foreach my $xx (@_) {
    next if $xx eq ''; my $x = Value::makeValue($xx,context=>$context);
    if ($x->isFormula) {
      if ($x->type =~ m/Point|List/ && $x->length == 2 &&
	  $x->typeRef->{entryType}{name} eq 'Number') {
	$x->{tree} = $x->Item("List")->new($x->{tree}{equation},$x->{tree}{coords},$x->{tree}{isConstant},
					   $context->{parens}{interval},$x->typeRef->{entryType},'(',')');
      }
      if ($x->type eq 'Union') {push(@intervals,map {new Parser($context,$_)} ($x->{tree}->makeUnion))}
      elsif ($x->isSetOfReals) {push(@intervals,$x)}
      else {Value::Error("Unions can be taken only for Intervals or Sets")}
      $isFormula = 1;
    } else {
      if ($x->classMatch('Union')) {push(@intervals,$x->value)}
      elsif ($x->isSetOfReals) {push(@intervals,$x)}
      elsif ($x->canBeInUnion)
	{push(@intervals,$x = $context->Package("Interval")->new($context,$x->{open}||"(",$x->value,$x->{close}||")"))}
      else {Value::Error("Unions can be taken only for Intervals or Sets")}
    }
  }
  Value::Error("Empty unions are not allowed") if scalar(@intervals) == 0;
  return $self->formula(@intervals) if $isFormula;
  my $union = form($context,@intervals);
  $union = $self->make($context,$union) unless $union->type eq 'Union';
  return $union;
}

#
#  Make a union or interval or set, depending on how
#  many there are in the union.
#
sub form {
  my $context = shift;
  return $_[0]->inContext($context) if scalar(@_) == 1;
  return $context->Package("Set")->new($context) if scalar(@_) == 0;
  my $union = $context->Package("Union")->make($context,@_);
  $union = $union->reduce if $union->getFlag('reduceUnions');
  return $union;
}

#
#  Return the appropriate data.
#
sub typeRef {
  my $self = shift;
  return Value::Type($self->class, $self->length, $self->data->[0]->typeRef);
}

sub isOne {0}
sub isZero {0}

sub canBeInUnion {1}
sub isSetOfReals {1}

#
#  Recursively convert the list of intervals to a tree of unions
#
sub formula {
  my $self = shift;
  my $formula = $self->Package("Formula")->blank($self->context);
  $formula->{tree} = recursiveUnion($formula,Value::toFormula($formula,@_));
  return $formula
}
sub recursiveUnion {
  my $formula = shift; my $right = pop(@_);
  return $right if (scalar(@_) == 0);
  return $formula->Item("BOP")->new($formula,'U',recursiveUnion($formula,@_),$right);
}

#
#  Try to promote arbitrary data to a set
#
sub promote {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $x = (scalar(@_) ? shift : $self);
  $x = Value::makeValue($x,context=>$context);
  return $context->Package("Set")->new($context,$x,@_) if scalar(@_) > 0 || Value::isReal($x);
  return $x->inContext($context) if ref($x) eq $class;
  $x = $context->Package("Interval")->promote($context,$x) if $x->canBeInUnion;
  return $self->make($context,$x) if $x->isSetOfReals;
  Value::Error("Can't convert %s to an Interval, Set or Union",Value::showClass($x));
}

############################################
#
#  Operations on unions
#

#
#  Addition forms unions
#
sub add {
  my ($self,$l,$r) = Value::checkOpOrderWithPromote(@_);
  $l = $self->make($l) unless $l->type eq 'Union';
  $r = $self->make($r) unless $r->type eq 'Union';
  form($self->context,$l->value,$r->value);
}
sub dot {my $self = shift; $self->add(@_)}

#
#  Subtraction can split intervals into unions
#
sub sub {
  my ($self,$l,$r) = Value::checkOpOrderWithPromote(@_);
  $l = $l->reduce; $l = $self->make($l) unless $l->type eq 'Union';
  $r = $r->reduce; $r = $self->make($r) unless $r->type eq 'Union';
  form($self->context,subUnionUnion($l->data,$r->data));
}

#
#  Which routines to call for the various combinations
#    of sets and intervals to do subtraction
#
my %subCall = (
  SetSet => \&Value::Set::subSetSet,
  SetInterval => \&Value::Set::subSetInterval,
  IntervalSet => \&Value::Set::subIntervalSet,
  IntervalInterval => \&Value::Interval::subIntervalInterval,
);

#
#  Subtract a union from another by running through both lists
#  and subtracting everything in the second list from everything
#  in the first.
#
sub subUnionUnion {
  my ($l,$r) = @_;
  my @union = (@{$l});
  foreach my $J (@{$r}) {
    my @newUnion = ();
    foreach my $I (@union)
      {push(@newUnion,&{$subCall{$I->type.$J->type}}($I,$J))}
    @union = @newUnion;
  }
  return @union;
}

#
#  Sort the intervals lexicographically, and then
#    compare interval by interval.
#
sub compare {
  my ($self,$l,$r) = Value::checkOpOrderWithPromote(@_);
  if ($self->getFlag('reduceUnionsForComparison')) {$l = $l->reduce; $r = $r->reduce}
  $l = $self->make($l) unless $l->type eq 'Union';
  $r = $self->make($r) unless $r->type eq 'Union';
  my @l = $l->sort->value; my @r = $r->sort->value;
  while (scalar(@l) && scalar(@r)) {
    my $cmp = shift(@l) <=> shift(@r);
    return $cmp if $cmp;
  }
  return scalar(@l) - scalar(@r);
}

############################################
#
#  Utility routines
#

#
#  Reduce unions to simplest form
#
sub reduce {
  my $self = shift;
  return $self if $self->{isReduced};
  my @singletons = (); my @intervals = ();
  foreach my $x ($self->value) {
    if ($x->type eq 'Set') {push(@singletons,$x->value)}
    elsif ($x->{data}[0] == $x->{data}[1]) {push(@singletons,$x->{data}[0])}
    else {push(@intervals,$x->copy)}
  }
  my @union = (); my @set = (); my $prevX;
  @intervals = (CORE::sort {$a <=> $b} @intervals);
  ELEMENT: foreach my $x (sort {$a <=> $b} @singletons) {
    next if defined($prevX) && $prevX == $x; $prevX = $x;
    foreach my $I (@intervals) {
      my ($a,$b) = $I->value;
      last if $x < $a;
      if ($x > $a && $x < $b) {next ELEMENT}
      elsif ($x == $a) {$I->{open} = '['; next ELEMENT}
      elsif ($x == $b) {$I->{close} = ']'; next ELEMENT}
    }
    push(@set,$x);
  }
  while (scalar(@intervals) > 1) {
    my $I = shift(@intervals); my $J = $intervals[0];
    my ($a,$b) = $I->value; my ($c,$d) = $J->value;
    if ($b < $c || ($b == $c && $I->{close} eq ')' && $J->{open} eq '(')) {
      push(@union,$I);
    } else {
      if ($a < $c) {$J->{data}[0] = $a; $J->{open} = $I->{open}}
              else {$J->{open} = '[' if $I->{open} eq '['}
      if ($b > $d) {$J->{data}[1] = $b; $J->{close} = $I->{close}}
              else {$J->{close} = ']' if $b == $d && $I->{close} eq ']'}
    }
  }
  my $context = $self->context;
  push(@union,@intervals);
  push(@union,$context->Package("Set")->make($context,@set)) unless scalar(@set) == 0;
  return $context->Package("Set")->new($context) if scalar(@union) == 0;
  return $union[0]->inContext($context) if scalar(@union) == 1;
  return $self->make(@union)->with(isReduced=>1);
}

#
#  True if a union is reduced.
#
#  (In array context, is a pair whose first entry is true or
#   false, and when true the second value is the reason the
#   set is not reduced.)
#
sub isReduced {
  my $self = shift;
  return 1 if $self->{isReduced};
  return $self->{data}[0]->isReduced if ($self->length == 1);
  my @I; my @S; my $Sn = 0; my $error;
  foreach my $x (@{$self->{data}})
    {if ($x->type eq 'Interval') {push(@I,$x)} else {$Sn++; push(@S,@{$x->{data}})}}
  my $U = $self->make(@I); my $sU = $U->sort;
  my $S = $self->Package("Set")->new($self->context,@S);
  foreach my $i (0..$sU->length-2) {
    my ($x,$y) = ($sU->{data}[$i],$sU->{data}[$i+1]);
    if ($x->intersects($y)) {$error = "overlaps"; last}
    if (($x + $y)->reduce->type ne 'Union') {$error = "uncombined intervals"; last}
  }
  $error = "overlaps in sets" if !$error && $S->intersects($U);
  $error = "uncombined sets" if !$error && $Sn > 1 && !$self->getFlag('reduceSets');
  $error = "repeated elements in set" if !$error && !$S->isReduced;
  return $error eq "" unless $error && wantarray;
  return (0,$error);
}

#
#  Sort a union lexicographically
#
sub sort {
  my $self = shift;
  $self->make(CORE::sort {$a <=> $b} $self->value);
}


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

sub isEmpty {
  my $self = (shift)->reduce;
  $self->type eq 'Set' && $self->isEmpty;
}

sub intersect {
  my $self = shift; my $other = $self->promote(@_);
  return $self-($self-$other);
}

sub intersects {
  my $self = shift; my $other = $self->promote(@_);
  return !$self->intersect($other)->isEmpty;
}

############################################
#
#  Generate the various output formats
#

sub pdot {
  my $self = shift;
  my $text = $self->stringify;
  $text = '('.$text.')' if $self->length > 1;
  return $text;
}

sub string {
  my $self = shift; my $equation = shift; shift; shift; my $prec = shift;
  my $op = ($equation->{context} || $self->context)->{operators}{'U'};
  my @intervals = ();
  foreach my $x (@{$self->data}) {
    $x->{format} = $self->{format} if defined $self->{format};
    push(@intervals,$x->string($equation))
  }
  my $string = join($op->{string} || ' U ',@intervals);
  $string = '('.$string.')' if $prec > ($op->{precedence} || 1.5);
  return $string;
}

sub TeX {
  my $self = shift; my $equation = shift; shift; shift; my $prec = shift;
  my $op = ($equation->{context} || $self->context)->{operators}{'U'};
  my @intervals = ();
  foreach my $x (@{$self->data}) {push(@intervals,$x->TeX($equation))}
  my $TeX = join($op->{TeX} || $op->{string} || ' U ',@intervals);
  $TeX = '\left('.$TeX.'\right)' if $prec > ($op->{precedence} || 1.5);
  return $TeX;
}

###########################################################################

1;

