########################################################################### 

package Value::Union;
my $pkg = 'Value::Union';

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
#  Convert a value to a union of intervals.  The value must be
#      a list of two or more Interval, Union or Point objects.
#      Points will be converted to intervals if they are length 1 or 2.
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  if (scalar(@_) == 1 && !ref($_[0])) {
    my $x = Value::makeValue($_[0]);
    if (Value::isFormula($x)) {
      return $x if $x->type =~ m/Interval|Union|Set/;
      Value::Error("Formula does not return an Interval, Set or Union");
    }
    $x = promote($x); $x = $pkg->make($x) unless $x->type eq 'Union';
    return $x;
  }
  my @intervals = (); my $isFormula = 0;
  foreach my $xx (@_) {
    next if $xx eq ''; my $x = Value::makeValue($xx);
    if ($x->isFormula) {
      $x->{tree}->typeRef->{name} = 'Interval'
	if ($x->type =~ m/Point|List/ && $x->length == 2 &&
	    $x->typeRef->{entryType}{name} eq 'Number');
      if ($x->type eq 'Union') {push(@intervals,$x->{tree}->makeUnion)}
      elsif ($x->isSetOfReals) {push(@intervals,$x)}
      else {Value::Error("Unions can be taken only for Intervals and Sets")}
      $isFormula = 1;
    } else {
      if ($x->type ne 'Interval' && $x->canBeInUnion) 
        {$x = Value::Interval->new($x->{open},$x->value,$x->{close})}
      if ($x->class eq 'Union') {push(@intervals,$x->value)}
      elsif ($x->isSetOfReals) {push(@intervals,$x)}
      else {Value::Error("Unions can be taken only for Intervals or Sets")}
    }
  }
  Value::Error("Empty unions are not allowed") if scalar(@intervals) == 0;
  return $self->formula(@intervals) if $isFormula;
  my $union = form(@intervals);
  $union = $self->make($union) unless $union->type eq 'Union';
  return $union;
}

#
#  Make a union or interval or set, depending on how
#  many there are in the union, and mark the
#  
#
sub form {
  return $_[0] if scalar(@_) == 1;
  return Value::Set->new() if scalar(@_) == 0;
  my $union = $pkg->make(@_);
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
  my $selft = shift;
  my $formula = Value::Formula->blank;
  $formula->{tree} = recursiveUnion($formula,Value::toFormula($formula,@_));
  return $formula
}
sub recursiveUnion {
  my $formula = shift; my $right = pop(@_);
  return $right if (scalar(@_) == 0);
  return $formula->{context}{parser}{BOP}->
    new($formula,'U',recursiveUnion($formula,@_),$right);
}

#
#  Try to promote arbitrary data to a set
#
sub promote {
  my $x = Value::makeValue(shift);
  return Value::Set->new($x,@_) if scalar(@_) > 0 || Value::isRealNumber($x);
  return $x if ref($x) eq $pkg;
  $x = Value::Interval::promote($x) if $x->canBeInUnion;
  return $pkg->make($x) if Value::isValue($x) && $x->isSetOfReals;
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
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->add($l,!$flag)}
  $r = promote($r); if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  form($l->value,$r->value);
}
sub dot {my $self = shift; $self->add(@_)}

#
#  Subtraction can split intervals into unions
#
sub sub {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->sub($l,!$flag)}
  $r = promote($r); if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  $l = $l->reduce; $l = $pkg->make($l) unless $l->type eq 'Union';
  $r = $r->reduce; $r = $pkg->make($r) unless $r->type eq 'Union';
  form(subUnionUnion($l->data,$r->data));
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
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->compare($l,!$flag)}
  $r = promote($r);
  if ($l->getFlag('reduceUnionsForComparison')) {
    $l = $l->reduce; $l = $pkg->make($l) unless $l->type eq 'Union';
    $r = $r->reduce; $r = $pkg->make($r) unless $r->type eq 'Union';
  }
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp};
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
  push(@union,@intervals);
  push(@union,Value::Set->make(@set)) unless scalar(@set) == 0;
  return Value::Set->new() if scalar(@union) == 0;
  return $union[0] if scalar(@union) == 1;
  return $pkg->make(@union)->with(isReduced=>1);
}

#
#  True if a union is reduced
#
sub isReduced {
  my $self = shift;
  return 1 if $self->{isReduced};
  my $reduced = $self->reduce;
  return unless $reduced->type eq 'Union' && $reduced->length == $self->length;
  my @R = $reduced->sort->value; my @S = $self->sort->value;
  foreach my $i (0..$#R) {
    return unless $R[$i] == $S[$i] && $R[$i]->length == $S[$i]->length;
  }
  return 1;
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
  my $self = shift; my $other = promote(shift);
  return ($other - $self)->isEmpty;
}

sub isSubsetOf {
  my $self = shift; my $other = promote(shift);
  return $other->contains($self);
}

sub isEmpty {
  my $self = (shift)->reduce;
  $self->type eq 'Set' && $self->isEmpty;
}

sub intersect {
  my $self = shift; my $other = shift;
  return $self-($self-$other);
}

sub intersects {
  my $self = shift; my $other = shift;
  return !$self->intersect($other)->isEmpty;
}

############################################
#
#  Generate the various output formats
#

sub stringify {
  my $self = shift;
  return $self->TeX if $$Value::context->flag('StringifyAsTeX');
  $self->string;
}

sub string {
  my $self = shift; my $equation = shift; shift; shift; my $prec = shift;
  my $op = ($equation->{context} || $$Value::context)->{operators}{'U'};
  my @intervals = ();
  foreach my $x (@{$self->data}) {push(@intervals,$x->string($equation))}
  my $string = join($op->{string} || ' U ',@intervals);
  $string = '('.$string.')' if $prec > ($op->{precedence} || 1.5);
  return $string;
}

sub TeX {
  my $self = shift; my $equation = shift; shift; shift; my $prec = shift;
  my $op = ($equation->{context} || $$Value::context)->{operators}{'U'};
  my @intervals = ();
  foreach my $x (@{$self->data}) {push(@intervals,$x->TeX($equation))}
  my $TeX = join($op->{TeX} || $op->{string} || ' U ',@intervals);
  $TeX = '\left('.$TeX.'\right)' if $prec > ($op->{precedence} || 1.5);
  return $TeX;
}

###########################################################################

1;

