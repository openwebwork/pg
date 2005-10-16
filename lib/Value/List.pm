########################################################################### 
#
#  Implements the List object
#
package Value::List;
my $pkg = 'Value::List';

use strict;
use vars qw(@ISA);
@ISA = qw(Value);

use overload
       '+'   => sub {shift->add(@_)},
       '.'   => sub {shift->_dot(@_)},
       'x'   => sub {shift->cross(@_)},
       '<=>' => sub {shift->compare(@_)},
       'cmp' => sub {shift->compare_string(@_)},
  'nomethod' => sub {shift->nomethod(@_)},
        '""' => sub {shift->stringify(@_)};

#
#  Make a List out of a list of entries or a
#    reference to an array of entries, or the data from a Value object
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $p = shift; my $isFormula = 0;
  my $isSingleton = (scalar(@_) == 0 && !(Value::isValue($p) && $p->class eq 'List'));
  $p = $p->data if (Value::isValue($p) && $p->class eq 'List' && scalar(@_) == 0);
  $p = [$p,@_] if (ref($p) ne 'ARRAY' || scalar(@_) > 0);
  my $type;
  foreach my $x (@{$p}) {
    $x = Value::makeValue($x) unless ref($x);
    $isFormula = 1 if Value::isFormula($x);
    if (Value::isValue($x)) {
      if (!$type) {$type = $x->type}
        else {$type = 'unknown' unless $type eq $x->type}
    } else {$type = 'unknown'}
  }
  return $p->[0] if ($isSingleton && $type eq 'List' && !$p->[0]{open});
  return $self->formula($p) if $isFormula;
  bless {data => $p, type => $type}, $class;
}

#
#  Return the proper data
#
sub typeRef {
  my $self = shift;
  return Value::Type($self->class, $self->length, Value::Type($self->{type},1));
}

sub isOne {0}
sub isZero {0}

#
#  Turn arbitrary data into a List
#
sub promote {
  my $x = shift;
  return $x if (ref($x) eq $pkg && scalar(@_) == 0);
  return $pkg->new($x,@_)
    if (scalar(@_) > 0 || !Value::isValue($x) || Value::isComplex($x));
  return $pkg->make(@{$x->data});
}

############################################
#
#  Operations on lists
#

#
#  Add is concatenation
#
sub add {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->add($l,!$flag)}
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  $l = $pkg->make($l) if Value::class($l) =~ m/Point|Vector|Matrix/;
  $r = $pkg->make($r) if Value::class($r) =~ m/Point|Vector|Matrix/;
  ($l,$r) = (promote($l)->data,promote($r)->data);
  return $pkg->new(@{$l},@{$r});
}
sub dot {my $self = shift; $self->add(@_)}

#
#  Lexicographic compare
#
sub compare {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->compare($l,!$flag)}
  ($l,$r) = (promote($l)->data,promote($r)->data);
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp};
  my $cmp = 0; my $n = scalar(@{$l}); $n = scalar(@{$r}) if scalar(@{$r}) < $n;
  foreach my $i (0..$n-1) {
    $cmp = $l->[$i] <=> $r->[$i];
    return $cmp if $cmp;
  }
  return scalar(@{$l}) <=> scalar(@{$r});
}

###########################################################################

1;

