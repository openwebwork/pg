#########################################################################
#
#  Implements the Interval class
#
package Parser::List::Interval;
use strict; use vars qw(@ISA);
@ISA = qw(Parser::List);

#
#  Check that the number of endpoints is OK
#  And that they are numbers or infinity.
#
sub _check {
  my $self = shift;
  my $length = $self->{type}{length}; my $coords = $self->{coords};
  $self->Error("Intervals can have only two endpoints") if ($length > 2);
  $self->Error("Intervals must have at least one endpoint") if ($length == 0);
  $self->Error("Coordinates of intervals can only be numbers or infinity")
    if !$coords->[0]->isNumOrInfinity ||
       ($length == 2 && !$coords->[1]->isNumOrInfinity);
  $self->Error("Infinite intervals require two endpoints")
    if ($length == 1 && $coords->[0]{isInfinite});
  $self->Error("The left endpoint of an interval can't be positive infinity")
    if ($coords->[0]{isInfinity});
  $self->Error("The right endpoint of an interval can't be negative infinity")
    if ($length == 2 && $coords->[1]{isNegativeInfinity});
  $self->Error("Infinite endpoints must be open")
    if ($self->{open} ne '(' && $coords->[0]{isInfinite}) ||
       ($self->{close} ne ')' && $length == 2 && $coords->[1]{isInfinite});
}

#
#  Use the Value.pm class to produce the result
#
sub _eval {
  my $self = shift;
  my $type = 'Value::'.$self->type;
  return $type->new($self->{open},@_,$self->{close});
}

#
#  Insert appropriate Value.pm calls to generate the result.
#
sub perl {
  my $self = shift; my $parens = shift;
  my $perl; my @p = ();
  foreach my $x (@{$self->{coords}}) {push(@p,$x->perl)}
  $perl = $self->type.'('.join(',',"'".$self->{open}."'",@p,"'".$self->{close}."'").')';
  $perl = '('.$perl.')' if $parens;
  return $perl;
}

#########################################################################

1;

