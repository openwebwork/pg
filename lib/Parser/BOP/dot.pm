#########################################################################
#
#  Implement vector dot product.
#
package Parser::BOP::dot;
use strict; use vars qw(@ISA);
@ISA = qw(Parser::BOP);

#
#  Check that the operands are vectors of compatible types.
#
sub _check {
  my $self = shift;
  return if ($self->checkStrings());
  return if ($self->checkLists());
  return if ($self->checkNumbers());
  my ($ltype,$rtype) = $self->promotePoints();
  if ($ltype->{name} eq 'Vector' && $rtype->{name} eq 'Vector') {
    if (Parser::Item::typeMatch($ltype,$rtype)) {$self->{type} = $Value::Type{number}}
    else {$self->matchError($ltype,$rtype)}
  } else {$self->Error("Operands for dot product must be Vectors")}
}

#
#  Use perl '.' for dot product
#   (see Value.pm; special care must be taken to make string concatenation
#    work with this.)
#
sub _eval {$_[1] . $_[2]}

#
#  Return zero if one operand is zero.
#  Factor out negatives.
#
sub _reduce {
  my $self = shift;
  return $self->{equation}{context}{parser}{Number}->new($self->{equation},0)
    if ($self->{lop}{isZero} || $self->{rop}{isZero});
  return $self->makeNeg($self->{lop}{op},$self->{rop}) if ($self->{lop}->isNeg);
  return $self->makeNeg($self->{lop},$self->{rop}{op}) if ($self->{rop}->isNeg);
  return $self;
}

#########################################################################

1;

