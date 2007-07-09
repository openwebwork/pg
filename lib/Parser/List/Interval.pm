#########################################################################
#
#  Implements the Interval class
#
package Parser::List::Interval;
use strict;
our @ISA = qw(Parser::List);

#
#  Check that the number of endpoints is OK
#  And that they are numbers or infinity.
#
sub _check {
  my $self = shift;
  my $length = $self->{type}{length}; my $coords = $self->{coords};
  $self->Error("Intervals can have only two endpoints") if $length > 2;
  $self->Error("Intervals must have two endpoints") if $length < 2;
  $self->Error("Coordinates of intervals can only be numbers or infinity")
    if (!$coords->[0]->isNumOrInfinity || !$coords->[1]->isNumOrInfinity) &&
      !$self->context->flag("allowBadOperands");
  $self->Error("The left endpoint of an interval can't be positive infinity")
    if $coords->[0]{isInfinity};
  $self->Error("The right endpoint of an interval can't be negative infinity")
    if $coords->[1]{isNegativeInfinity};
  $self->Error("Infinite endpoints must be open")
    if ($self->{open} ne '(' && $coords->[0]{isInfinite}) ||
       ($self->{close} ne ')' && $coords->[1]{isInfinite});
}

sub canBeInUnion {1}

#
#  Use the Value.pm class to produce the result
#
sub _eval {
  my $self = shift; my @ab = @{(shift)};
  $self->Package($self->type)->new($self->context,$self->{open},@ab,$self->{close});
}

#
#  Insert appropriate Value.pm calls to generate the result.
#
sub perl {
  my $self = shift; my $parens = shift;
  my $perl; my @p = ();
  foreach my $x (@{$self->{coords}}) {push(@p,$x->perl)}
  $perl = $self->Package($self->type).'->new('.join(',',"'".$self->{open}."'",@p,"'".$self->{close}."'").')';
  $perl = '('.$perl.')' if $parens;
  return $perl;
}

#########################################################################

1;
