#########################################################################
#
#  Implements unary minus
#
package Parser::UOP::minus;
use strict; use vars qw(@ISA);
@ISA = qw(Parser::UOP);

#
#  Check that the operand is OK.
#
sub _check {
  my $self = shift;
  return if ($self->checkInfinite);
  return if ($self->checkString);
  return if ($self->checkList);
  return if ($self->checkNumber);
  $self->{type} = {%{$self->{op}->typeRef}};
}

#
#  Negate the operand.
#
sub _eval {-($_[1])}

#
#  Remove double negatives.
#
sub _reduce {
  my $self = shift; my $op = $self->{op};
  my $reduce = $self->{equation}{context}{reduction};
  $self = $op->{op} if $op->isNeg && $reduce->{'-(-x)'};
  return $self;
}

$Parser::reduce->{'-(-x)'} = 1;

#########################################################################

1;

