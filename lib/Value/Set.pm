########################################################################### 

package Value::Set;
my $pkg = 'Value::Set';

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
  if ($pclass =~ m/Point|Vector|Set/) {$p = $p->data}
  elsif ($pclass eq 'Matrix' && scalar(@d) == 1) {$p = [$p->value]}
  elsif ($pclass eq 'Matrix' && scalar(@d) == 2 && $d[0] == 1) {$p = ($p->value)[0]}
  elsif ($pclass eq 'Matrix' && scalar(@d) == 2 && $d[1] == 1) {$p = ($p->transpose->value)[0]}
  else {
    $p = [$p] if (defined($p) && ref($p) ne 'ARRAY');
    foreach my $x (@{$p}) {
      $x = Value::makeValue($x);
      $isFormula = 1 if Value::isFormula($x);
      Value::Error("An element of sets can't be %s",Value::showClass($x))
        unless Value::isRealNumber($x);
    }
  }
  return $self->formula($p) if $isFormula;
  my $def = $$Value::context->lists->get('Set');
  bless {
    data => $p, canBeInterval => 1,
    open => $def->{open}, close => $def->{close}
  }, $class;
}

#
#  Set the canBeInterval flag
#
sub make {
  my $self = shift; my $def = $$Value::context->lists->get('Set');
  $self = $self->SUPER::make(@_);
  $self->{canBeInterval} = 1;
  $self->{open} = $def->{open}; $self->{close} = $def->{close};
  return $self;
}

sub isOne {0}
sub isZero {0}

#
#  Try to promote arbitrary data to a set
#
sub promote {
  my $x = shift;
  return $pkg->new($x,@_)
    if scalar(@_) > 0 || ref($x) eq 'ARRAY' || Value::isRealNumber($x);
  return $x if Value::class($x) =~ m/Interval|Union|Set/;
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
  $r = promote($r);
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  Value::Error("Sets can only be added to Intervals, Sets or Unions")
    unless Value::class($l) =~ m/Interval|Union|Set/ &&
           Value::class($r) =~ m/Interval|Union|Set/;
  return Value::Union->new($l,$r)
    unless Value::class($l) eq 'Set' && Value::class($r) eq 'Set';
  my @combined = (sort {$a <=> $b} (@{$l->data},@{$r->data}));
  my @entries = ();
  while (scalar(@combined)) {
    push(@entries,shift(@combined));
    shift(@combined) while (scalar(@combined) && $entries[-1] == $combined[0]);
  }
  return $pkg->make(@entries);
}
sub dot {my $self = shift; $self->add(@_)}

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
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp};
  my @l = sort {$a <=> $b} @{$l->data}; my @r = sort {$a <=> $b} @{$r->data};
  while (scalar(@l) && scalar(@r)) {
    my $cmp = shift(@l) <=> shift(@r);
    return $cmp if $cmp;
  }
  return scalar(@l) - scalar(@r);
}

###########################################################################

1;

