#########################################################################
#
#  Implements ubstraction
#
package Parser::BOP::subtract;
use strict; use vars qw(@ISA);
@ISA = qw(Parser::BOP);

#
#  Check that the operand types match.
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
#  Do subtraction
#
sub _eval {$_[1] - $_[2]}

#
#  Remove subtracting zero
#  Turn subtraction from zero into negation.
#  Turn subtracting a negative into addition.
#  Factor out common negatives.
#
sub _reduce {
  my $self = shift;
  return $self->{lop} if ($self->{rop}{isZero});
  return Parser::UOP::Neg($self->{rop}) if ($self->{lop}{isZero});
  if ($self->{rop}->isNeg) {
    $self = Parser::BOP->new($self->{equation},'+',$self->{lop},$self->{rop}{op});
    $self = $self->reduce;
  } elsif ($self->{lop}->isNeg) {
    $self = Parser::UOP::Neg
      (Parser::BOP->new($self->{equation},'+',$self->{lop}{op},$self->{rop}));
    $self = $self->reduce;
  }
  return $self;
}

#########################################################################

1;

