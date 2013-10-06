#########################################################################
#
#  Implements the base Binary Operator class
#

package Parser::BOP;
use strict; no strict "refs";
our @ISA = qw(Parser::Item);

$Parser::class->{BOP} = 'Parser::BOP';

#
#  Make a new instance of a BOP
#
#  Make left and right operands into lists if they are comma operators
#    and this operator isn't itself a comma.
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $equation = shift; my $context = $equation->{context};
  my ($bop,$lop,$rop,$ref) = @_;
  my $def = $context->{operators}{$bop};
  if (!$def->{isComma}) {
    $lop = $self->Item("List",$context)->new($equation,[$lop->makeList],
       $lop->{isConstant},$context->{parens}{start}) if ($lop->type eq 'Comma');
    $rop = $self->Item("List",$context)->new($equation,[$rop->makeList],$rop->{isConstant},
       $context->{parens}{start}) if ($rop->type eq 'Comma');
  }
  my $BOP = bless {
    bop => $bop, lop => $lop, rop => $rop,
    def => $def, ref => $ref, equation => $equation,
  }, $def->{class};
  $BOP->weaken;
  $BOP->{isConstant} = 1 if ($lop->{isConstant} && $rop->{isConstant});
  $BOP->_check;
  $BOP = $BOP->Item("Value")->new($equation,[$BOP->eval])
    if $BOP->{isConstant} && !$def->{isComma} && $context->flag('reduceConstants');
  return $BOP;
}

#
#  Stub for checking if the BOP can operate on the given operands.
#  (Implemented in subclasses.)
#
sub _check {}

##################################################

#
#  Evaluate the left and right operands and peform the
#  required operation on the results.
#
sub eval {
  my $self = shift;
  $self->_eval($self->{lop}->eval,$self->{rop}->eval);
}
#
#  Stub for sub-classes.
#
sub _eval {return $_[1]}

#
#  Reduce the left and right operands.
#  If they are constant (and it's not a comma), make a constant value of them.
#  Otherwise, reduce the result.
#
sub reduce {
  my $self = shift; my $bop = $self->{def};
  $self->{lop} = $self->{lop}->reduce;
  $self->{rop} = $self->{rop}->reduce;
  return $self->Item("Value")->new($self->{equation},[$self->eval])
    if (!$bop->{isComma} && $self->{lop}{isConstant} && $self->{rop}{isConstant});
  $self->_reduce;
}
#
#  Stub for sub-classes.
#
sub _reduce {shift}

#
#  Substitute in the left and right operands.
#
sub substitute {
  my $self = shift; my $bop = $self->{def};
  $self->{lop} = $self->{lop}->substitute;
  $self->{rop} = $self->{rop}->substitute;
  my $equation = $self->{equation}; my $context = $equation->{context};
  return $self->Item("Value")->new($equation,[$self->eval])
    if !$bop->{isComma} && $self->{lop}{isConstant} && $self->{rop}{isConstant} &&
        $context->flag('reduceConstants');
  return $self;
}

#
#  Copy the left and right operands as well as the rest
#    of the equations.
#
sub copy {
  my $self = shift; my $equation = shift;
  my $new = $self->SUPER::copy($equation);
  $new->{lop} = $self->{lop}->copy($equation);
  $new->{rop} = $self->{rop}->copy($equation);
  return $new;
}

##################################################
#
#  Service routines for checking the types of operands.
#


#
#  Error if one of the operands is a string.
#
sub checkStrings {
  my $self = shift; return 0 if $self->context->flag("allowBadOperands");
  my $ltype = $self->{lop}->typeRef; my $rtype = $self->{rop}->typeRef;
  my $name = $self->{def}{string} || $self->{bop};
  if ($ltype->{name} eq 'String') {
    $self->Error("Operands of '%s' can't be %s",$name,
		 ($self->{lop}{isInfinite}? 'infinities': 'words'));
    return 1;
  }
  if ($rtype->{name} eq 'String') {
    $self->Error("Operands of '%s' can't be %s",$name,
		 ($self->{rop}{isInfinite}? 'infinities': 'words'));
    return 1;
  }
  return 0;
}

#
#  Error if one of the operands is a list.
#
sub checkLists {
  my $self = shift; return 0 if $self->context->flag("allowBadOperands");
  my $ltype = $self->{lop}->typeRef; my $rtype = $self->{rop}->typeRef;
  return 0 if ($ltype->{name} ne 'List' and $rtype->{name} ne 'List');
  my $name = $self->{def}{string} || $self->{bop};
  $self->Error("Operands of '%s' can't be lists",$name);
  return 1;
}

#
#  Determine if both operands are numbers, and promote to
#    complex numbers if one is complex.
#
sub checkNumbers {
  my $self = shift;
  return 0 if !($self->{lop}->isNumber && $self->{rop}->isNumber) &&
              !$self->context->flag("allowBadOperands");
  if ($self->{lop}->isComplex || $self->{rop}->isComplex) {
    $self->{type} = $Value::Type{complex};
  } else {
    $self->{type} = $Value::Type{number};
  }
  return 1;
}

#
#  Check if two matrices can be multiplied.
#
sub checkMatrixSize {
  my $self = shift;
  my ($lm,$rm) = @_;
  my ($ltype,$rtype) = ($lm->{entryType},$rm->{entryType});
  if ($ltype->{entryType}{name} eq 'Number' &&
      $rtype->{entryType}{name} eq 'Number') {
    my ($lr,$lc) = ($lm->{length},$ltype->{length});
    my ($rr,$rc) = ($rm->{length},$rtype->{length});
    if ($lc == $rr) {
      my $rowType = Value::Type('Matrix',$rc,$Value::Type{number},formMatrix=>1);
      $self->{type} = Value::Type('Matrix',$lr,$rowType,formMatrix=>1);
    } else {$self->Error("Matrices of dimensions %dx%d and %dx%d can't be multiplied",$lr,$lc,$rr,$rc)}
  } else {$self->Error("Matrices are too deep to be multiplied")}
}

#
#  Promote point operands to vectors or matrices.
#
sub promotePoints {
  my $self = shift; my $class = shift;
  my $ltype = $self->{lop}->typeRef;
  my $rtype = $self->{rop}->typeRef;
  if ($ltype->{name} eq 'Point' ||
      ($ltype->{name} eq 'Matrix' && !$ltype->{entryType}{entryType})) {
    $ltype = {%{$ltype}, name => 'Vector'};
    $ltype = Value::Type($class,1,Value::Type($class,1,$ltype->{entryType}))
      if ($ltype->{length} == 1 && $class);
  }
  if ($rtype->{name} eq 'Point' ||
      ($rtype->{name} eq 'Matrix' && !$rtype->{entryType}{entryType})) {
    $rtype = {%{$rtype}, name => 'Vector'};
    $rtype = Value::Type($class,1,Value::Type($class,1,$rtype->{entryType}))
      if ($rtype->{length} == 1 && $class);
  }
  return ($ltype,$rtype);
}

#
#  Report an error if the operand types don't match.
#
sub matchError {
  my $self = shift; return if $self->context->flag("allowBadOperands");
  my ($ltype,$rtype) = @_;
  my ($op,$ref) = ($self->{bop});
  if ($ltype->{name} eq $rtype->{name})
       {$self->Error("Operands for '%s' must be of the same length",$op)}
  else {$self->Error("Operands for '%s' must be of the same type",$op)}
}

##################################################
#
#  Service routines for adjusting the values of operands.
#

#
#  Return a zero, or a list of zeros of the proper length.
#
sub makeZero {
  my $self = shift; my $op = shift; my $zero = shift;
  return $zero if ($op->isNumber);
  if ($zero->isNumber && $op->type =~ m/Point|Vector/) {
    my $context = $op->{equation}{context};
    my $value = $context->Package($op->type)->new($context,($zero->{value})x$op->length);
    $value = $self->Item("Value")->new($op->{equation},$value);
    $value->{value}{ijk} = 1 if $op->class eq "Constant" && $op->{def}{value}{ijk};
    return $value;
  }
  return $self;
}

#
#  Produce a negated version of a BOP.
#
sub makeNeg {
  my $self = shift;
  $self->{lop} = shift; $self->{rop} = shift;
  return Parser::UOP::Neg($self);
}

#
#  Reverse the operands (left <=> right).
#
sub swapOps {
  my $self = shift;
  my $tmp = $self->{lop}; $self->{lop} = $self->{rop}; $self->{rop} = $tmp;
  return $self;
}

#
#  Get the variables from the two operands
#
sub getVariables {
  my $self = shift;
  return {%{$self->{lop}->getVariables},%{$self->{rop}->getVariables}};
}

##################################################
#
#  Generate the various output formats.
#


#
#  Produce a string version of the BOP.
#
#  Parentheses are added when either:
#    we are told to from our parent
#    the BOP says to (fullparens)
#    the BOP's precedence is lower than it's parent's, or
#    the precedences are equal and either
#       the associativity is right
#       or we are supposed to show parens for the same precedence
#
sub string {
  my ($self,$precedence,$showparens,$position,$outerRight) = @_;
  my $string; my $bop = $self->{def};
  $position = '' unless defined($position);
  $showparens = '' unless defined($showparens);
  my $extraParens = $self->context->flag('showExtraParens');
  my $addparens =
      defined($precedence) &&
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

#
#  Produce the TeX version of the BOP.
#
sub TeX {
  my ($self,$precedence,$showparens,$position,$outerRight) = @_;
  my $TeX; my $bop = $self->{def};
  $position = '' unless defined($position);
  $showparens = '' unless defined($showparens);
  my $extraParens = $self->context->flag('showExtraParens');
  my $addparens =
      defined($precedence) &&
      (($showparens eq 'all' && $extraParens > 1) || $precedence > $bop->{precedence} ||
      ($precedence == $bop->{precedence} &&
        ($bop->{associativity} eq 'right' || ($showparens eq 'same' && $extraParens))));
  $outerRight = !$addparens && ($outerRight || $position eq 'right');

  $TeX = $self->{lop}->TeX($bop->{precedence},$bop->{leftparens},'left',$outerRight).
         (defined($bop->{TeX}) ? $bop->{TeX} : $bop->{string}) .
         $self->{rop}->TeX($bop->{precedence},$bop->{rightparens},'right');

  $TeX = '\left('.$TeX.'\right)' if $addparens;
  return $TeX;
}

#
#  Produce the perl version of the BOP.
#
sub perl {
  my $self= shift; my $parens = shift;
  my $bop = $self->{def}; my $perl;
  if ($bop->{isCommand}) {
    $perl =
      ($bop->{perl} || ref($self).'->call').
        '('.$self->{lop}->perl.','.$self->{rop}->perl.')';
  } else {
    $perl =
        $self->{lop}->perl(1).
	" ".($bop->{perl} || $bop->{string})." ".
        $self->{rop}->perl(2);
  }
  $perl = '('.$perl.')' if $parens;
  return $perl;
}

#########################################################################
#
#  Load the subclasses.
#

END {
  use Parser::BOP::undefined;
  use Parser::BOP::comma;
  use Parser::BOP::union;
  use Parser::BOP::add;
  use Parser::BOP::subtract;
  use Parser::BOP::multiply;
  use Parser::BOP::divide;
  use Parser::BOP::power;
  use Parser::BOP::cross;
  use Parser::BOP::dot;
  use Parser::BOP::underscore;
  use Parser::BOP::equality;
}

#########################################################################

1;
