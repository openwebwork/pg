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
sub _eval {$_[1] ** $_[2]}

#
#  Return 1 for power of zero or base of 1.
#  Return base if power is 1.
#  Return 1/base if power is -1.
#
sub _reduce {
  my $self = shift;
  return Parser::Number->new($self->{equation},1)
   if ($self->{rop}{isZero} || $self->{lop}{isOne});
  return $self->{lop} if ($self->{rop}{isOne});
  if ($self->{rop}->isNeg && $self->{rop}->string eq '-1') {
    $self = Parser::BOP->new($self->{equation},'/',
       Parser::Number->new($self->{equation},1),$self->{lop});
    $self = $self->reduce;
  }
  return $self;
}

#
#  Put exponent in braces for TeX
#
sub TeX {
  my ($self,$precedence,$showparens,$position) = @_;
  my $TeX; my $bop = $self->{def};
  my $symbol = (defined($bop->{TeX}) ? $bop->{TeX} : $bop->{string});
  $self->{lop}->TeX($bop->{precedence},$bop->{leftparens},'left').
    $symbol.'{'.$self->{rop}->TeX.'}';
}

#########################################################################

1;

