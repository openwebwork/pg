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
  $p = $p->data if (Value::isValue($p) && Scalar(@_) == 0);
  $p = [$p,@_] if (ref($p) ne 'ARRAY' || scalar(@_) > 0);
  foreach my $x (@{$p}) {$isFormula = 1,last if Value::isFormula($x)}
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
    if (scalar(@_) > 0 || Value::isValue($x) || Value::isComplex($x));
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
  my $cmp = 0;
  foreach my $i (0..min(scalar(@{$l}),scalar(@{$r}))-1) {
    $cmp = $l->[$i] <=> $r->[$i];
    last if $cmp;
  }
  return $cmp if $cmp;
  return scalar(@{$l}) <=> scalar(@{$r});
}

############################################
#
#  Generate the various output formats.
#

sub stringify {
  my $self = shift;
  '('.join(',',@{$self->data}).')';
}

sub string {
  my $self = shift; my $equation = shift;
  my $open = shift || $Value::parens{List}{open};
  my $close = shift || $Value::parens{List}{close};
  my @coords = ();
  foreach my $x (@{$self->data}) {
    if (Value::isValue($x)) 
      {push(@coords,$x->string($equation,$open,$close))} else {push(@coords,$x)}
  }
  return $open.join(',',@coords).$close;
}
sub TeX {
  my $self = shift; my $equation = shift;
  my $open = shift || $Value::parens{List}{open};
  my $close = shift || $Value::parens{List}{close};
  $open = '\{' if $open eq '{'; $close = '\}' if $close eq '}';
  my @coords = (); my $str = $equation->{context}{strings};
  foreach my $x (@{$self->data}) {
    if (Value::isValue($x)) {push(@coords,$x->TeX($equation,$open,$close))}
    elsif (defined($str->{$x}) && $str->{$x}{TeX}) {push(@coords,$str->{$x}{TeX})}
    else {push(@coords,$x)}
  }
  return '\left'.$open.join(',',@coords).'\right'.$close;
}

###########################################################################

1;

