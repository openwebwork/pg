#########################################################################
#
#  Implement addition.
#
package Parser::BOP::add;
use strict; use vars qw(@ISA);
@ISA = qw(Parser::BOP);

#
#  Check that the operand types are compatible.
#
sub _check {
  my $self = shift;
  return if ($self->checkStrings());
  return if ($self->checkLists());
  return if ($self->checkNumbers());
  my ($ltype,$rtype) = $self->promotePoints();
  if (Parser::Item::typeMatch($ltype,$rtype)) {$self->{type} = $ltype}
  else {$self->matchError($ltype,$rtype)}
}

#
#  Do addition.
#
sub _eval {$_[1] + $_[2]}

#
#  Remove addition with zero.
#  Turn addition of negative into subtraction.
#
sub _reduce {
  my $self = shift;
  return $self->{lop} if ($self->{rop}{isZero});
  return $self->{rop} if ($self->{lop}{isZero});
  if ($self->{rop}->isNeg) {
    $self = Parser::BOP->new($self->{equation},'-',$self->{lop},$self->{rop}{op});
    $self = $self->reduce;
  } elsif ($self->{lop}->isNeg) {
    $self = Parser::BOP->new($self->{equation},'-',$self->{rop},$self->{lop}{op});
    $self = $self->reduce;
  }
  return $self;
}

#########################################################################

1;

