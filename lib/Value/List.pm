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
       '+'   => \&add,
       '.'   => \&Value::_dot,
       'x'   => \&Value::cross,
       '<=>' => \&compare,
       'cmp' => \&compare,
  'nomethod' => \&Value::nomethod,
        '""' => \&stringify;

#
#  Make a List out of a list of entries or a
#    reference to an array of entries, or the data from a Value object
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $p = shift; my $isFormula = 0;
  $p = $p->data if (Value::isValue($p) && scalar(@_) == 0);
  $p = [$p,@_] if (ref($p) ne 'ARRAY' || scalar(@_) > 0);
  foreach my $x (@{$p}) {
    $isFormula = 1,last if Value::isFormula($x);
    $x = Value::makeValue($x) unless ref($x);
  }
  return $self->formula($p) if $isFormula;
  bless {data => $p}, $class;
}

#
#  Return the proper data
#
sub length {return scalar(@{shift->{data}})}
sub typeRef {
  my $self = shift;
  return Value::Type($self->class, $self->length, $Value::Type{unknown});
}

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
sub dot {add(@_)}

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

############################################
#
#  Generate the various output formats.
#

sub stringify {
  my $self = shift;
  return $self->TeX() if $$Value::context->flag('StringifyAsTeX');
  my $open = $self->{open}; my $close = $self->{close};
  $open  = $$Value::context->lists->get('List')->{open} unless defined($open);
  $close = $$Value::context->lists->get('List')->{close} unless defined($close);
  $open.join(', ',@{$self->data}).$close;
}

sub string {
  my $self = shift; my $equation = shift;
  my $def = ($equation->{context} || $$Value::context)->lists->get('List');
  my $open = shift; my $close = shift;
  $open  = $def->{open} unless defined($open);
  $close = $def->{close} unless defined($close);
  my @coords = ();
  foreach my $x (@{$self->data}) {
    if (Value::isValue($x)) 
      {push(@coords,$x->string($equation))} else {push(@coords,$x)}
  }
  return $open.join(', ',@coords).$close;
}
sub TeX {
  my $self = shift; my $equation = shift;
  my $context = $equation->{context} || $$Value::context;
  my $def = $context->lists->get('List');
  my $open = shift; my $close = shift;
  $open  = $def->{open} unless defined($open);
  $close = $def->{close} unless defined($close);
  $open = '\{' if $open eq '{'; $close = '\}' if $close eq '}';
  $open = '\left'.$open if $open; $close = '\right'.$close if $close;
  my @coords = (); my $str = $context->{strings};
  foreach my $x (@{$self->data}) {
    if (Value::isValue($x)) {push(@coords,$x->TeX($equation))}
    elsif (defined($str->{$x}) && $str->{$x}{TeX}) {push(@coords,$str->{$x}{TeX})}
    else {push(@coords,$x)}
  }
  return $open.join(',',@coords).$close;
}

###########################################################################

1;

