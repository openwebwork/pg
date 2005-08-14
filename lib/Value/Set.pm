########################################################################### 

package Value::Set;
my $pkg = 'Value::Set';

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

#  Convert a value to a Set.  The value can be
#    a list of numbers, or an reference to an array of numbers
#    a point, vector or set object
#    a matrix if it is  n x 1  or  1 x n
#    a string that evaluates to a point
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $p = shift; $p = [$p,@_] if (scalar(@_) > 0);
  $p = Value::makeValue($p) if (defined($p) && !ref($p));
  return $p if (Value::isFormula($p) && $p->type eq Value::class($self));
  my $pclass = Value::class($p); my $isFormula = 0;
  my @d; @d = $p->dimensions if $pclass eq 'Matrix';
  if ($pclass eq 'List' && $p->typeRef->{entryType}{name} eq 'Number') {$p = $p->data}
  elsif ($pclass =~ m/Point|Vector|Set/) {$p = $p->data}
  elsif ($pclass eq 'Matrix' && scalar(@d) == 1) {$p = [$p->value]}
  elsif ($pclass eq 'Matrix' && scalar(@d) == 2 && $d[0] == 1) {$p = ($p->value)[0]}
  elsif ($pclass eq 'Matrix' && scalar(@d) == 2 && $d[1] == 1) {$p = ($p->transpose->value)[0]}
  else {
    $p = [$p] if (defined($p) && ref($p) ne 'ARRAY');
    foreach my $x (@{$p}) {
      $x = Value::makeValue($x);
      $isFormula = 1 if Value::isFormula($x);
      Value::Error("An element of a set can't be %s",Value::showClass($x))
        unless Value::isRealNumber($x);
    }
  }
  return $self->formula($p) if $isFormula;
  my $def = $$Value::context->lists->get('Set');
  my $set = bless {data => $p, open => $def->{open}, close => $def->{close}}, $class;
  $set = $set->reduce if $self->getFlag('reduceSets');
  return $set;
}

#
#  Set the canBeInterval flag
#
sub make {
  my $self = shift;
  my $def = $$Value::context->lists->get('Set');
  $self = $self->SUPER::make(@_);
  $self->{open} = $def->{open}; $self->{close} = $def->{close};
  return $self;
}

sub isOne {0}
sub isZero {0}

sub canBeInUnion {1}
sub isSetOfReals {1}

#
#  Try to promote arbitrary data to a set
#
sub promote {
  my $x = Value::makeValue(shift);
  return $pkg->new($x,@_) if scalar(@_) > 0 || Value::isRealNumber($x);
  return $x if ref($x) eq $pkg;
  $x = Value::Interval::promote($x) if $x->canBeInUnion;
  return $x if $x->isSetOfReals;
  return $pkg->new($x->value)
    if $x->type eq 'List' && $x->typeRef->{entryType}{name} eq 'Number';
  Value::Error("Can't convert %s to a Set",Value::showClass($x));
}

############################################
#
#  Operations on sets
#

#
#  Addition forms additional sets
#
sub add {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->add($l,!$flag)}
  $r = promote($r); if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  Value::Union::form($l,$r);
}
sub dot {my $self = shift; $self->add(@_)}

#
#  Subtraction removes items from a set
#
sub sub {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->sub($l,!$flag)}
  $r = promote($r); if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  return Value::Union::form(subIntervalSet($l,$r)) if Value::class($l) eq 'Interval';
  return Value::Union::form(subSetInterval($l,$r)) if Value::class($r) eq 'Interval';
  return Value::Union::form(subSetSet($l,$r));
}

#
#  Subtract one set from another
#    (return the resulting set or nothing for empty set)
#
sub subSetSet {
  my @l = $_[0]->sort->value; my @r = $_[1]->sort->value;
  my @entries = ();
  while (scalar(@l) && scalar(@r)) {
    if ($l[0] < $r[0]) {
      push(@entries,shift(@l));
    } else {
      while ($l[0] == $r[0]) {shift(@l); last if scalar(@l) == 0};
      shift(@r);
    }
  }
  push(@entries,@l);
  return () unless scalar(@entries);
  return $pkg->make(@entries);
}

#
#  Subtract a set from an interval
#    (returns a collection of intervals)
#
sub subIntervalSet {
  my $I = (shift)->copy; my $S = shift;
  my @union = (); my ($a,$b) = $I->value;
  foreach my $x ($S->reduce->value) {
    next if $x < $a;
    if ($x == $a) {
      return @union if $a == $b;
      $I->{open} = '(';
    } elsif ($x < $b) {
      push(@union,Value::Interval->make($I->{open},$a,$x,')'));
      $I->{open} = '('; $I->{data}[0] = $x;
    } else {
      $I->{close} = ')' if ($x == $b);
      last;
    }
  }
  return (@union,$I);
}

#
#  Subtract an interval from a set
#    (returns the resulting set or nothing for the empty set)
#    
sub subSetInterval {
  my $S = shift; my $I = shift;
  my ($a,$b) = $I->value;
  my @entries = ();
  foreach my $x ($S->value) {
    push(@entries,$x)
      if ($x < $a || $x > $b) ||
         ($x == $a && $I->{open}  ne '[') ||
	 ($x == $b && $I->{close} ne ']');
  }
  return () unless scalar(@entries);
  return $pkg->make(@entries);
}

#
#  Compare two sets lexicographically on their sorted contents
#
sub compare {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->compare($l,!$flag)}
  $r = promote($r);
  if ($r->class eq 'Interval') {
    return ($flag? 1: -1) if $l->length == 0;
    my ($a,$b) = $r->value; my $c = $l->{data}[0];
    return (($flag) ? $a <=> $c : $c <=> $a)
      if ($l->length == 1 && $a == $b) || $a != $c;
    return ($flag? 1: -1);
  }
  if ($l->getFlag('reduceSetsForComparison')) {$l = $l->reduce; $r = $r->reduce}
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
#  Remove repeated values
#
sub reduce {
  my $self = shift;
  return $self if $self->{isReduced} || $self->length < 2;
  my @data = $self->sort->value; my @set = ();
  while (scalar(@data)) {
    push(@set,shift(@data));
    shift(@data) while (scalar(@data) && $set[-1] == $data[0]);
  }
  return $self->make(@set)->with(isReduced=>1);
}

#
#  True if the set is reduced
#
sub isReduced {
  my $self = shift;
  return 1 if $self->{isReduced} || $self->length < 2;
  return $self->reduce->length == $self->length;
}

#
#  Sort the data for a set
#
sub sort {
  my $self = shift;
  return $self->make(CORE::sort {$a <=> $b} $self->value);
}


#
#  Tests for containment, subsets, etc.
#

sub contains {
  my $self = shift; my $other = promote(shift)->reduce;
  return unless $other->type eq 'Set';
  return ($other-$self)->isEmpty;
}

sub isSubsetOf {
  my $self = shift; my $other = promote(shift);
  return $other->contains($self);
}

sub isEmpty {(shift)->length == 0}

sub intersect {
  my $self = shift; my $other = shift;
  return $self-($self-$other);
}

sub intersects {
  my $self = shift; my $other = shift;
  return !$self->intersect($other)->isEmpty;
}

###########################################################################

1;
