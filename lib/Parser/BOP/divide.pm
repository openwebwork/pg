#########################################################################
#
#  Implements division
#
package Parser::BOP::divide;
use strict;
our @ISA = qw(Parser::BOP);

#
#  Check that operand types are OK.
#  Check for division by zero.
#
sub _check {
  my $self = shift;
  return if $self->checkStrings();
  return if $self->checkLists();
  $self->Error("Division by zero") if $self->{rop}{isZero};
  return if $self->checkNumbers();
  my ($ltype,$rtype) = $self->promotePoints();
  if ($ltype->{name} =~ m/Vector|Matrix/ && $rtype->{name} eq 'Number') {$self->{type} = {%{$ltype}}}
  elsif ($self->context->flag("allowBadOperands")) {$self->{type} = $Value::Type{number}}
  else {$self->Error("Division is allowed only for Numbers or a Vector, Point, or Matrix and a Number")}
}

#
#  Do the division.
#
sub _eval {$_[1] / $_[2]}

#
#  Remove division by 1.
#  Error for division by zero.
#  Reduce zero divided by anything (non-zero) to zero.
#  Factor out negatives.
#
sub _reduce {
  my $self = shift;
  my $reduce = $self->{equation}{context}{reduction};
  return $self->{lop} if $self->{rop}{isOne} && $reduce->{'x/1'};
  $self->Error("Division by zero"), return $self if $self->{rop}{isZero};
  return $self->{lop} if $self->{lop}{isZero} && $reduce->{'0/x'};
  return $self->makeNeg($self->{lop}{op},$self->{rop})
    if $self->{lop}->isNeg && $reduce->{'(-x)/y'};
  return $self->makeNeg($self->{lop},$self->{rop}{op})
    if $self->{rop}->isNeg && $reduce->{'x/(-y)'};
  return $self;
}

$Parser::reduce->{'x/1'} = 1;
$Parser::reduce->{'0/x'} = 1;
$Parser::reduce->{'(-x)/y'} = 1;
$Parser::reduce->{'x/(-y)'} = 1;

#
#  Use \frac for TeX version.
#
sub TeX {
  my $self = shift;
  my ($precedence,$showparens,$position,$outerRight) = @_;
  my $TeX; my $bop = $self->{def};
  return $self->SUPER::TeX(@_) if $self->{def}{noFrac};
  $showparens = '' unless defined($showparens);
  my $addparens =
      defined($precedence) &&
      ($showparens eq 'all' || ($precedence > $bop->{precedence} && $showparens ne 'nofractions') ||
      ($precedence == $bop->{precedence} &&
        ($bop->{associativity} eq 'right' || $showparens eq 'same')));

  $TeX = '\frac{'.($self->{lop}->TeX).'}{'.($self->{rop}->TeX).'}';

  $TeX = '\left('.$TeX.'\right)' if ($addparens);
  return $TeX;
}

#########################################################################

1;
