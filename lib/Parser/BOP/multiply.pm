#########################################################################
#
#  Implement multiplication.
#
package Parser::BOP::multiply;
use strict;
our @ISA = qw(Parser::BOP);

#
#  Check that operand types are compatible for multiplication.
#
sub _check {
  my $self = shift;
  return if $self->checkStrings();
  return if $self->checkLists();
  return if $self->checkNumbers();
  my ($ltype,$rtype) = $self->promotePoints('Matrix');
  if ($ltype->{name} eq 'Number' && $rtype->{name} =~ m/Vector|Matrix/) {
    $self->{type} = {%{$rtype}};
  } elsif ($ltype->{name} =~ m/Vector|Matrix/ && $rtype->{name} eq 'Number') {
    $self->{type} = {%{$ltype}};
  } elsif ($ltype->{name} eq 'Matrix' && $rtype->{name} eq 'Vector') {
    $self->checkMatrixSize($ltype,transposeVectorType($rtype));
  } elsif ($ltype->{name} eq 'Vector' && $rtype->{name} eq 'Matrix') {
    $self->checkMatrixSize(Value::Type('Matrix',1,$ltype),$rtype);
  } elsif ($ltype->{name} eq 'Matrix' && $rtype->{name} eq 'Matrix') {
    $self->checkMatrixSize($ltype,$rtype);
  } elsif ($self->context->flag("allowBadOperands")) {
    $self->{type} = $Value::Type{number};
  } else {$self->Error("Operands of '*' are not of compatible types")}
}

#
#  Return the type of a vector as a column vector.
#
sub transposeVectorType {
  my $vtype = shift;
  Value::Type('Matrix',$vtype->{length},
     Value::Type('Matrix',1,$vtype->{entryType},formMatrix => 1),
     formMatrix =>1 );
}

#
#  Do the multiplication.
#
sub _eval {$_[1] * $_[2]}

#
#  Remove multiplication by one.
#  Reduce multiplication by zero to appropriately sized zero.
#  Factor out negatives.
#  Move a number from the right to the left.
#  Move a function apply from the left to the right.
#
sub _reduce {
  my $self = shift;
  my $reduce = $self->{equation}{context}{reduction};
  return $self->{rop} if $self->{lop}{isOne} && $reduce->{'1*x'};
  return $self->{lop} if $self->{rop}{isOne} && $reduce->{'x*1'};
  return $self->makeZero($self->{rop},$self->{lop}) if $self->{lop}{isZero} && $reduce->{'0*x'};
  return $self->makeZero($self->{lop},$self->{rop}) if $self->{rop}{isZero} && $reduce->{'x*0'};
  return $self->makeNeg($self->{lop}{op},$self->{rop}) if $self->{lop}->isNeg && $reduce->{'(-x)*y'};
  return $self->makeNeg($self->{lop},$self->{rop}{op}) if $self->{rop}->isNeg && $reduce->{'x*(-y)'};
  $self->swapOps 
     if (($self->{rop}->class eq 'Number' && $self->{lop}->class ne 'Number' && $reduce->{'x*n'}) ||
        ($self->{lop}->class eq 'Function' && $self->{rop}->class ne 'Function' && $reduce->{'fn*x'}));
  return $self;
}

sub makeNeg {
  my $self = shift;
  $self = $self->SUPER::makeNeg(@_);
  $self->{op}{noParens} = 1;
  return $self;
}

$Parser::reduce->{'1*x'} = 1;
$Parser::reduce->{'x*1'} = 1;
$Parser::reduce->{'0*x'} = 1;
$Parser::reduce->{'x*0'} = 1;
$Parser::reduce->{'(-x)*y'} = 1;
$Parser::reduce->{'x*(-y)'} = 1;
$Parser::reduce->{'x*n'} = 1;
$Parser::reduce->{'fn*x'} = 1;

sub string {
  my ($self,$precedence,$showparens,$position,$outerRight) = @_;
  my $string; my $bop = $self->{def};
  $position = '' unless defined($position);
  $showparens = '' unless defined($showparens);
  my $extraParens = $self->context->flag('showExtraParens');
  my $addparens =
      defined($precedence) && !$self->{noParens} &&
      ($showparens eq 'all' || (($showparens eq 'extra' || $bop->{fullparens}) && $extraParens > 1) ||
       $precedence > $bop->{precedence} || ($precedence == $bop->{precedence} &&
        ($bop->{associativity} eq 'right' || ($showparens eq 'same' && $extraParens))));
  $outerRight = !$addparens && ($outerRight || $position eq 'right');

  $string = $self->{lop}->string($bop->{precedence},$bop->{leftparens},'left',$outerRight).
            $bop->{string}.
            $self->{rop}->string($bop->{precedence},$bop->{rightparens},'right');

  $string = $self->addParens($string) if $addparens;
  return $string;
}

sub TeX {
  my ($self,$precedence,$showparens,$position,$outerRight) = @_;
  my $TeX; my $bop = $self->{def}; my $cdot;
  $position = '' unless defined($position);
  $showparens = '' unless defined($showparens);
  my $mult = (defined($bop->{TeX}) ? $bop->{TeX} : $bop->{string});
  ($mult,$cdot) = @{$mult} if ref($mult) eq 'ARRAY';
  $cdot = '\cdot ' unless $cdot;

  my $addparens =
      defined($precedence) && !$self->{noParens} &&
      ($showparens eq 'all' || $precedence > $bop->{precedence} ||
      ($precedence == $bop->{precedence} &&
        ($bop->{associativity} eq 'right' || $showparens eq 'same')));
  $outerRight = !$addparens && ($outerRight || $position eq 'right');

  my $left  = $self->{lop}->TeX($bop->{precedence},$bop->{leftparens},'left',$outerRight);
  my $right = $self->{rop}->TeX($bop->{precedence},$bop->{rightparens},'right');
  $mult = $cdot if $right =~ m/^\d/ ||
     ($left =~ m/\d+$/ && $self->{rop}{isConstant} &&
      $self->{rop}->type eq 'Number' && $self->{rop}->class ne 'Constant');
  $right = '\!'.$right if $mult eq '' && substr($right,0,5) eq '\left';
  $TeX = $left.$mult.$right;

  $TeX = '\left('.$TeX.'\right)' if $addparens;
  return $TeX;
}

#########################################################################

1;
