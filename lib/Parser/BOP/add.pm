#########################################################################
#
#  Implement addition.
#
package Parser::BOP::add;
use strict;
our @ISA = qw(Parser::BOP);

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
  my $equation = $self->{equation};
  my $reduce = $equation->{context}{reduction};
  return $self->{lop} if $self->{rop}{isZero} && $reduce->{'x+0'};
  return $self->{rop} if $self->{lop}{isZero} && $reduce->{'0+x'};
  if ($self->{rop}->isNeg && $reduce->{'x+(-y)'}) {
    $self = $self->Item("BOP")->new($equation,'-',$self->{lop},$self->{rop}{op});
    $self = $self->reduce;
  } elsif ($self->{lop}->isNeg && $reduce->{'(-x)+y'}) {
    $self = $self->Item("BOP")->new($equation,'-',$self->{rop},$self->{lop}{op});
    $self = $self->reduce;
  }
  return $self;
}

$Parser::reduce->{'0+x'} = 1;
$Parser::reduce->{'x+0'} = 1;
$Parser::reduce->{'x+(-y)'} = 1;
$Parser::reduce->{'(-x)+y'} = 1;

#########################################################################

1;
