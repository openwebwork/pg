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
  my $self = shift; my $type = $self->{type};
  $self->Error("Intervals can have have only two endpoints") if ($type->{length} > 2);
  $self->Error("Intervals must have at least one endpoint") if ($type->{length} == 0);
  $self->Error("Coordinates of intervals can only be numbers or infinity")
    if (!$self->{coords}->[0]->isNumOrInfinity ||
       ($type->{length} == 2 && !$self->{coords}->[1]->isNumOrInfinity));
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

