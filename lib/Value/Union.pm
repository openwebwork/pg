########################################################################### 

package Value::Union;
my $pkg = 'Value::Union';

use strict;
use vars qw(@ISA);
@ISA = qw(Value);

use overload
       '+'   => sub {shift->add(@_)},
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
    return promote($x);
  }
  Value::Error("Empty unions are not allowed") if scalar(@_) == 0;
  my @intervals = (); my $isFormula = 0;
  foreach my $xx (@_) {
    my $x = $xx; $x = Value::makeValue($x);
    if (Value::isFormula($x)) {
      $x->{tree}->typeRef->{name} = 'Interval'
	if ($x->type =~ m/Point|List/ && $x->length == 2 &&
	    $x->typeRef->{entryType}{name} eq 'Number');
      if ($x->type =~ m/Interval|Set/) {push(@intervals,$x)}
      elsif ($x->type eq 'Union') {push(@intervals,$x->{tree}->makeUnion)}
      else {Value::Error("Unions can be taken only for Intervals and Sets")}
      $isFormula = 1;
    } else {
      if (Value::class($x) eq 'Point' || Value::class($x) eq 'List') {
        if ($x->length == 1) {$x = Value::Interval->new('[',$x->value,$x->value,']')}
        elsif ($x->length == 2) {$x = Value::Interval->new($x->{open},$x->value,$x->{close})}
      }
      if (Value::class($x) =~ m/Interval|Set/) {push(@intervals,$x)}
      elsif (Value::class($x) eq 'Union') {push(@intervals,@{$x->{data}})}
      else {Value::Error("Unions can be taken only for Intervals or Sets")}
    }
  }
  return $self->formula(@intervals) if $isFormula;
  bless {data => [@intervals], canBeInterval => 1}, $class;
}

#
#  Set the canBeInterval flag
#
sub make {
  my $self = shift;
  $self = $self->SUPER::make(@_);
  $self->{canBeInterval} = 1;
  return $self;
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
  my $x = shift;
  return Value::Set->new($x,@_)
    if scalar(@_) > 0 || ref($x) eq 'ARRAY' || Value::isRealNumber($x);
  return $x if Value::class($x) =~ m/Interval|Union|Set/;
  return Value::Interval::promote($x) if Value::class($x) eq 'List';
  Value::Error("Can't convert %s to an Interval, Set or Union",Value::showClass($x));
}

############################################
#
#  Operations on unions
#

#
#  Addition forms additional unions
#
sub add {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->add($l,!$flag)}
  $r = promote($r);
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  Value::Error("Unions can only be added to Intervals, Sets or Unions")
    unless Value::class($l) =~ m/Interval|Union|Set/ &&
           Value::class($r) =~ m/Interval|Union|Set/;
  $l = $pkg->make($l) if ($l->class ne 'Union');
  $r = $pkg->make($r) if ($r->class ne 'Union');
  return $pkg->make(@{$l->data},@{$r->data});
}
sub dot {my $self = shift; $self->add(@_)}

#
#  @@@ Needs work @@@
#  
#  Sort the intervals lexicographically, and then
#    compare interval by interval.
#
sub compare {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->add($l,!$flag)}
  $r = promote($r);
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp};
  my @l = sort {$a <=> $b} $l->value; my @r = sort {$a <=> $b} $r->value;
  while (scalar(@l) && scalar(@r)) {
    my $cmp = shift(@l) <=> shift(@r);
    return $cmp if $cmp;
  }
  return scalar(@l) - scalar(@r);
}

# @@@ simplify (combine intervals, if possible) @@@

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
  my $self = shift; my $equation = shift;
  my $context = $equation->{context} || $$Value::context;
  my $union = $context->{operators}{'U'}{string} || ' U ';
  my @intervals = ();
  foreach my $x (@{$self->data}) {push(@intervals,$x->string($equation))}
  return join($union,@intervals);
}

sub TeX {
  my $self = shift; my $equation = shift;
  my $context = $equation->{context} || $$Value::context;
  my @intervals = (); my $op = $context->{operators}{'U'};
  foreach my $x (@{$self->data}) {push(@intervals,$x->TeX($equation))}
  return join($op->{TeX} || $op->{string} || ' U ',@intervals);
}

###########################################################################

1;

