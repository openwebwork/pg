#########################################################################
#
#  Implements unary plus
#
package Parser::UOP::plus;
use strict;
our @ISA = qw(Parser::UOP);

#
#  Check that the operand is OK
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
#  Plus doesn't change the value
#
sub _eval {$_[1]}

#
#  Remove the redundant plus sign
#
sub _reduce {
  my $self = shift;
  my $reduce = $self->{equation}{context}{reduction};
  return $self->{op} if $reduce->{'+x'};
  return $self;
}

$Parser::reduce->{'+x'} = 1;

#########################################################################

1;
