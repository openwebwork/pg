########################################################################### 

package Value::Union;
my $pkg = 'Value::Union';

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
#  Convert a value to a union of intervals.  The value must be
#      a list of two or more Interval, Union or Point objects.
#      Points will be converted to intervals if they are length 1 or 2.
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  @_ = split("U",@_[0]) if scalar(@_) == 1 && !ref($_[0]);
  Value::Error("Unions must be of at least two intervals") unless scalar(@_) > 1;
  my @intervals = (); my $isFormula = 0;
  foreach my $xx (@_) {
    my $x = $xx; $x = Value::Interval->new($x) if !ref($x);
    if (Value::isFormula($x)) {
      $x->{tree}->typeRef->{name} = 'Interval' if ($x->type eq 'Point' && $x->length == 1);
      if ($x->type eq 'Interval') {push(@intervals,$x)}
      elsif ($x->type eq 'Union') {push(@intervals,$x->{tree}->makeUnion)}
      else {Value::Error("Unions can be taken only for Intervals")}
      $isFormula = 1;
    } else {
      if (Value::class($x) eq 'Point' || Value::class($x) eq 'List') {
        if ($x->length == 1) {$x = Value::Interval->new('[',$x->value,$x->value,']')}
        elsif ($x->length == 2) {$x = Value::Interval->new($x->{open},$x->value,$x->{close})}
      }
      if (Value::class($x) eq 'Interval') {push(@intervals,$x)}
      elsif (Value::class($x) eq 'Union') {push(@intervals,@{$x->{data}})}
      else {Value::Error("Unions can be taken only for Intervals")}
    }
  }
  return $self->formula(@intervals) if $isFormula;
  bless {data => [@intervals], canBeInterval => 1}, $class;
}

#
#  Return the appropriate data.
#
sub length {return scalar(@{shift->{data}})}
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
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  Value::Error("Unions can only be added to Intervals or Unions")
    unless Value::class($l) =~ m/Interval|Union/ &&
           Value::class($r) =~ m/Interval|Union/;
  $l = $pkg->make($l) if ($l->class eq 'Interval');
  $r = $pkg->make($r) if ($r->class eq 'Interval');
  return $pkg->make(@{$l->data},@{$r->data});
}
sub dot {add(@_)}

#
#  @@@ Needs work @@@
#  
#  Sort the intervals lexicographically, and then
#    compare interval by interval.
#
sub compare {
  my ($l,$r,$flag) = @_;
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp};
  return  1 if Value::class($r) ne 'Union';
  return -1 if Value::class($l) ne 'Union';
  my @l = sort(@{$l->data}); my @r = sort(@{$r->data});
  return scalar(@l) <=> scalar(@r) unless scalar(@l) == scalar(@r);
  my $cmp = 0;
  foreach my $i (0..$#l) {
    $cmp = $l[$i] <=> $r[$i];
    last if $cmp;
  }
  return $cmp;
}

# @@@ simplify (combine intervals, if possible) @@@

############################################
#
#  Generate the various output formats
#

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

