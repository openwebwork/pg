#########################################################################
#
#  Implement cross product of vectors.
#  
package Parser::BOP::cross;
use strict; use vars qw(@ISA);
@ISA = qw(Parser::BOP);

#
#  Promote points to vectors, if possible.
#  Check that they are of length three.
#  
sub _check {
  my $self = shift;
  my ($ltype,$rtype) = $self->promotePoints();
  if ($ltype->{name} eq 'Vector' && $rtype->{name} eq 'Vector') {
    if ($ltype->{length} == 3 && $rtype->{length} == 3 &&
        $ltype->{entryType}{length} == 1 && $rtype->{entryType}{length} == 1)
          {$self->{type} = {%{$ltype}}}
    else {$self->Error("Operands of '><' must by in three-space")}
  } else {$self->Error("Operands of '><' must be Vectors")}
}

#
#  Use 'x' as cross product in perl (see Value.pm for more).
#  
sub _eval {$_[1] x $_[2]}

#
#  Return the zero vector if one operand is zero.
#  Factor out negatives.
#
sub _reduce {
  my $self = shift;
  return $self->{lop} if ($self->{lop}{isZero});
  return $self->{rop} if ($self->{rop}{isZero});
  return $self->makeNeg($self->{lop}{op},$self->{rop}) if ($self->{lop}->isNeg);
  return $self->makeNeg($self->{lop},$self->{rop}{op}) if ($self->{rop}->isNeg);
  return $self;
}

#########################################################################

1;

