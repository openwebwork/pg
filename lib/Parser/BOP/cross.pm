#########################################################################
#
#  Implement cross product of vectors.
#
package Parser::BOP::cross;
use strict;
our @ISA = qw(Parser::BOP);

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
    elsif ($self->context->flag("allowBadOperands")) {$self->{type} = $Value::Type{number}}
    else {$self->Error("Operands of '><' must by in three-space")}
  }
  elsif ($self->context->flag("allowBadOperands")) {$self->{type} = $Value::Type{number}}
  else {$self->Error("Operands of '><' must be Vectors")}
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
  my $reduce = $self->{equation}{context}{reduction};
  return $self->{lop} if $self->{lop}{isZero} && $reduce->{'0><x'};
  return $self->{rop} if $self->{rop}{isZero} && $reduce->{'x><0'};
  return $self->makeNeg($self->{lop}{op},$self->{rop}) if $self->{lop}->isNeg && $reduce->{'(-x)><y'};
  return $self->makeNeg($self->{lop},$self->{rop}{op}) if $self->{rop}->isNeg && $reduce->{'x><(-y)'};
  return $self;
}

$Parser::reduce->{'0><x'} = 1;
$Parser::reduce->{'x><0'} = 1;
$Parser::reduce->{'x><(-y)'} = 1;
$Parser::reduce->{'(-x)><y'} = 1;

#########################################################################

1;
