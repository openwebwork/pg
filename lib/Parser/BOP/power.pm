#########################################################################
#
#  Implements exponentiation
#
package Parser::BOP::power;
use strict; use vars qw(@ISA);
@ISA = qw(Parser::BOP);

#
#  Check that operand types are OK.
#  For non-numbers, promote to Matrix and check
#    that the sizes are OK and that the exponents are numbers
sub _check {
  my $self = shift;
  return if ($self->checkStrings());
  return if ($self->checkLists());
  return if ($self->checkNumbers());
  my ($ltype,$rtype) = $self->promotePoints('Matrix');
  if ($rtype->{name} eq 'Number') {
    if ($ltype->{name} eq 'Matrix') {$self->checkMatrixSize($ltype,$ltype)}
    else {$self->Error("You can only raise a Number to a power")}
  } else {$self->Error("Exponents must be Numbers")}
}

#
#  Do perl exponentiation
#
sub _eval {
  my $x = $_[1] ** $_[2];
  return $x unless $x eq 'nan';
  $_[0]->Error("Can't raise a negative number to a power")
    if Value::isNumber($_[1]) && Value::makeValue($_[1])->value < 0;
  $_[0]->Error("Result of exponentiation is not a number");
}

#
#  Return 1 for power of zero or base of 1.
#  Return base if power is 1.
#  Return 1/base if power is -1.
#
sub _reduce {
  my $self = shift; my $equation = $self->{equation};
  my $reduce = $equation->{context}{reduction};
  my $parser = $equation->{context}{parser};
  return $parser->{Number}->new($equation,1)
    if (($self->{rop}{isZero} && !$self->{lop}{isZero} && $reduce->{'x^0'}) ||
	($self->{lop}{isOne} && $reduce->{'1^x'}));
  return $self->{lop} if ($self->{rop}{isOne});
  if ($self->{rop}->isNeg && $self->{rop}->string eq '-1' && $reduce->{'x^(-1)'}) {
    $self = $parser->{BOP}->new($equation,'/',
      $parser->{Number}->new($equation,1),$self->{lop});
    $self = $self->reduce;
  }
  return $self;
}

$Parser::reduce->{'x^0'} = 1;
$Parser::reduce->{'1^x'} = 1;
$Parser::reduce->{'x^(-1)'} = 1;


#
#  Put exponent in braces for TeX
#
sub TeX {
  my ($self,$precedence,$showparens,$position,$outerRight) = @_;
  my $TeX; my $bop = $self->{def};
  my $extraParens = $self->{equation}{context}->flag('showExtraParens');
  my $addparens =
      defined($precedence) &&
      (($showparens eq 'all' && $extraParens) || $precedence > $bop->{precedence} ||
      ($precedence == $bop->{precedence} &&
        ($bop->{associativity} eq 'right' || $showparens eq 'same')));
  my $outerRight = !$addparens && ($outerRight || $position eq 'right');

  my $symbol = (defined($bop->{TeX}) ? $bop->{TeX} : $bop->{string});
  if ($self->{lop}->class eq 'Function' && $self->{rop}->class eq 'Number' &&
      $self->{lop}{def}{simplePowers} &&
      $self->{rop}{value} > 0 && int($self->{rop}{value}) == $self->{rop}{value}) {
    $TeX = $self->{lop}->TeX($precedence,$showparens,$position,$outerRight,
			     $symbol.'{'.$self->{rop}->TeX.'}');
    $addparens = 0;
  } else {
    $TeX = $self->{lop}->TeX($bop->{precedence},$bop->{leftparens},'left',$outerRight).
      $symbol.'{'.$self->{rop}->TeX.'}';
  }

  $TeX = '\left('.$TeX.'\right)' if $addparens;
  return $TeX;
}

#########################################################################

1;

