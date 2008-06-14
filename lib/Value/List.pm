###########################################################################
#
#  Implements the List object
#
package Value::List;
my $pkg = 'Value::List';

use strict; no strict "refs";
our @ISA = qw(Value);

#
#  Make a List out of a list of entries or a
#    reference to an array of entries, or the data from a Value object
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $def = $context->lists->get("List");
  my $p = shift; my $isFormula = 0;
  my $isSingleton = (scalar(@_) == 0 && !(Value::isValue($p) && $p->classMatch('List')));
  $p = $p->data if (Value::isValue($p) && $p->classMatch('List') && scalar(@_) == 0);
  $p = [] unless defined $p;
  $p = [$p,@_] if ref($p) ne 'ARRAY' || scalar(@_) > 0;
  my $type;
  foreach my $x (@{$p}) {
    $x = Value::makeValue($x,context=>$context) unless ref($x);
    $isFormula = 1 if Value::isFormula($x);
    if (Value::isValue($x)) {
      if (!$type) {$type = $x->type}
        else {$type = 'unknown' unless $type eq $x->type}
    } else {$type = 'unknown'}
    if (!$isSingleton && $x->type eq 'List') {
      $x->{open}  = $def->{nestedOpen}  unless $x->{open};
      $x->{close} = $def->{nestedClose} unless $x->{close};
    }
  }
  return $p->[0] if ($isSingleton && $type eq 'List' && !$p->[0]{open});
  return $self->formula($p) if $isFormula;
  my $list = bless {data => $p, type => $type, context=>$context}, $class;
  $list->{correct_ans} = $p->[0]{correct_ans}
    if $isSingleton && defined scalar(@{$p}) && defined $p->[0]{correct_ans};
  if (scalar(@{$p}) == 0) {
    $list->{open}  = $def->{nestedOpen};
    $list->{close} = $def->{nestedClose};
  }
  return $list;
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
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $x = (scalar(@_) ? shift : $self);
  return $x->inContext($context) if ref($x) eq $class && scalar(@_) == 0;
  return $self->new($context,$x,@_)
    if (scalar(@_) > 0 || !Value::isValue($x) || Value::isComplex($x));
  return $self->make($context,$x->value);
}

############################################
#
#  Operations on lists
#

#
#  Add is concatenation
#
sub add {
  my ($self,$l,$r) = Value::checkOpOrder(@_);
  $l = Value::makeValue($l) unless Value::isValue($l);
  $r = Value::makeValue($r) unless Value::isValue($r);
  $l = $self->make($l) unless Value::classMatch($l,'List');
  $r = $self->make($r) unless Value::classMatch($r,'List');
  return $self->new($l->value,$r->value);
}
sub dot {my $self = shift; $self->add(@_)}

#
#  Lexicographic compare
#
sub compare {
  my ($self,$l,$r) = Value::checkOpOrderWithPromote(@_);
  my @l = $l->value; my @r = $r->value;
  my $cmp = 0; my $n = scalar(@l); $n = scalar(@r) if scalar(@r) < $n;
  foreach my $i (0..$n-1) {
    $cmp = $l[$i] <=> $r[$i];
    return $cmp if $cmp;
  }
  return scalar(@l) <=> scalar(@r);
}

###########################################################################

1;

