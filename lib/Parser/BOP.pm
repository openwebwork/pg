#########################################################################
#
#  Implements the base Binary Operator class
#

package Parser::BOP;
use strict; use vars qw(@ISA);
@ISA = qw(Parser::Item);

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
    $lop = Parser::List->new($equation,[$lop->makeList],
       $lop->{isConstant},$context->{parens}{start}) if ($lop->type eq 'Comma');
    $rop = Parser::List->new($equation,[$rop->makeList],$rop->{isConstant},
       $context->{parens}{start}) if ($rop->type eq 'Comma');
  }
  my $BOP = bless {
    bop => $bop, lop => $lop, rop => $rop,
    def => $def, ref => $ref, equation => $equation,
  }, $def->{class};
  $BOP->_check;
  $BOP->{isConstant} = 1 if ($lop->{isConstant} && $rop->{isConstant});
  $BOP = Parser::Value->new($equation,[$BOP->eval])
    if ($BOP->{isConstant} && !$def->{isComma});
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
  return Parser::Value->new($self->{equation},[$self->eval])
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
  return Parser::Value->new($self->{equation},[$self->eval])
    if (!$bop->{isComma} && $self->{lop}{isConstant} && $self->{rop}{isConstant});
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
  my $self = shift;
  my $ltype = $self->{lop}->typeRef; my $rtype = $self->{rop}->typeRef;
  my $name = $self->{def}{string} || $self->{bop};
  if ($ltype->{name} eq 'String') {
    $self->Error("Operands of '$name' can't be ".
		 ($self->{lop}{isInfinite}? 'infinities': 'words'));
    return 1;
  }
  if ($rtype->{name} eq 'String') {
    $self->Error("Operands of '$name' can't be ".
		 ($self->{rop}{isInfinite}? 'infinities': 'words'));
    return 1;
  }
  return 0;
}

#
#  Error if one of the operands is a list.
#
sub checkLists {
  my $self = shift;
  my $ltype = $self->{lop}->typeRef; my $rtype = $self->{rop}->typeRef;
  return 0 if ($ltype->{name} ne 'List' and $rtype->{name} ne 'List');
  my $name = $self->{def}{string} || $self->{bop};
  $self->Error("Operands of '$name' can't be lists");
  return 1;
}

#
#  Determine if both operands are numbers, and promote to
#    complex numbers if one is complex.
#
sub checkNumbers {
  my $self = shift;
  return 0 if !($self->{lop}->isNumber && $self->{rop}->isNumber);
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
  if ($lm->{entryType}{entryType}{name} eq 'Number' &&
      $rm->{entryType}{entryType}{name} eq 'Number') {
    my ($lr,$lc) = ($lm->{length},$lm->{entryType}{length});
    my ($rr,$rc) = ($rm->{length},$rm->{entryType}{length});
    if ($lc == $rr) {
      my $rowType = Value::Type('Matrix',$rc,$Value::Type{number},formMatrix=>1);
      $self->{type} = Value::Type('Matrix',$lr,$rowType,formMatrix=>1);
    } else {$self->Error("Matrix dimensions are incompatible for multiplication")}
  } else {$self->Error("Matrices are too deep to be multiplied")}
}

#
#  Promote point operands to vectors or matrices.
#
sub promotePoints {
  my $self = shift; my $class = shift;
  my $ltype = $self->{lop}->typeRef;
  my $rtype = $self->{rop}->typeRef;
  if ($ltype->{name} eq 'Point') {
    $ltype = {%{$ltype}, name => 'Vector'};
    $ltype = Value::Type($class,1,Value::Type($class,1,$ltype->{entryType}))
      if ($ltype->{length} == 1 && $class);
  }
  if ($rtype->{name} eq 'Point') {
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
  my $self = shift;
  my ($ltype,$rtype) = @_;
  my ($op,$ref) = ($self->{bop});
  if ($ltype->{name} eq $rtype->{name}) 
       {$self->Error("Operands for '$op' must be of the same length")}
  else {$self->Error("Operands for '$op' must be of the same type")}
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
    $op->{coords} = []; $op->{isZero} = 1;
    foreach my $i (0..($op->length-1)) {push(@{$op->{coords}},$zero)}
    return $op
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
  my $self = shift;
  my $precedence = shift; my $showparens = shift;
  my $string; my $bop = $self->{def};
  my $addparens = 
      defined($precedence) &&
      ($showparens eq 'all' || $bop->{fullparens} || $precedence > $bop->{precedence} ||
      ($precedence == $bop->{precedence} &&
        ($bop->{associativity} eq 'right' || $showparens eq 'same')));

  $string = $self->{lop}->string($bop->{precedence},$bop->{leftparens},'left').
            $bop->{string}.
            $self->{rop}->string($bop->{precedence},$bop->{rightparens},'right');

  if ($addparens) {
    if ($bop->{fullparens} and $string =~ m/\(/)
      {$string = "[".$string."]"} else {$string = "(".$string.")"}
  }
  return $string;
}

#
#  Produce the TeX version of the BOP.
#
sub TeX {
  my ($self,$precedence,$showparens,$position) = @_;
  my $TeX; my $bop = $self->{def};
  my $addparens =
      defined($precedence) &&
      ($showparens eq 'all' || $precedence > $bop->{precedence} ||
      ($precedence == $bop->{precedence} &&
        ($bop->{associativity} eq 'right' || $showparens eq 'same')));

  $TeX = $self->{lop}->TeX($bop->{precedence},$bop->{leftparens},'left').
         (defined($bop->{TeX}) ? $bop->{TeX} : $bop->{string}) .
         $self->{rop}->TeX($bop->{precedence},$bop->{rightparens},'right');

  $TeX = '\left('.$TeX.'\right)' if ($addparens);
  return $TeX;
}

#
#  Produce the perl version of the BOP.
#
sub perl {
  my $self= shift; my $parens = shift;
  my $bop = $self->{def};
  my ($lparen,$rparen); if (!$bop->{isCommand}) {$lparen = 1; $rparen = 2}
  my $perl =
        $self->{lop}->perl($lparen).
        (defined($bop->{perl}) ? $bop->{perl} : $bop->{string}).
        $self->{rop}->perl($rparen);
  $perl = '('.$perl.')' if $parens;
  return $perl;
}

#########################################################################
#
#  Load the subclasses.
#

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

#########################################################################

1;

