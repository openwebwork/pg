#########################################################################
#
#  Implements the base Unary Operator class
#
package Parser::UOP;
use strict; no strict "refs";
our @ISA = qw(Parser::Item);

$Parser::class->{UOP} = 'Parser::UOP';

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $equation = shift; my $context = $equation->{context};
  my ($uop,$op,$ref) = @_; my $def;
  ($uop,$def) = $context->operators->resolve($uop);
  my $UOP = bless {
    uop => $uop, op => $op,
    def => $def, ref => $ref, equation => $equation
  }, $def->{class};
  $UOP->weaken;
  $UOP->{isConstant} = 1 if $op->{isConstant};
  $UOP->_check;
  $UOP = $UOP->Item("Value")->new($equation,[$UOP->eval])
    if $op->{isConstant} && (!$UOP->isNeg || $op->isNeg) &&
       ($context->flag('reduceConstants') || $op->{isInfinity});
  return $UOP;
}

#
#  Stub for checking if the BOP can operate on the given operands.
#  (Implemented in subclasses.)
#
sub _check {}

##################################################

#
#  Evaluate the operand and then perform the operation on it
#
sub eval {
  my $self = shift;
  $self->_eval($self->{op}->eval);
}
#
#  Stub for sub-classes.
#
sub _eval {return $_[1]}


#
#  Reduce the operand.
#  If it is constant and we are not negation (we want to be able to factor it out),
#    return the value of the operation.
#
sub reduce {
  my $self = shift; my $uop = $self->{def};
  my $equation = $self->{equation};
  $self->{op} = $self->{op}->reduce;
  return $self->Item("Value")->new($equation,[$self->eval])
    if $self->{op}{isConstant} && !$self->isNeg;
  $self->_reduce;
}
#
#  Stub for sub-classes.
#
sub _reduce {shift}

sub substitute {
  my $self = shift; my $uop = $self->{def};
  my $equation = $self->{equation}; my $context = $equation->{context};
  $self->{op} = $self->{op}->substitute;
  return $self->Item("Value")->new($equation,[$self->eval])
    if $self->{op}{isConstant} && $context->flag('reduceConstants');
  return $self;
}

#
#  Copy the operand as well as the rest of the object
#
sub copy {
  my $self = shift; my $equation = shift;
  my $new = $self->SUPER::copy($equation);
  $new->{op} = $self->{op}->copy($equation);
  return $new;
}

##################################################
#
#  Service routines for checking the types of operands.
#


#
#  Error if the operand is a string
#
sub checkString {
  my $self = shift; return 0 if $self->context->flag("allowBadOperands");
  my $type = $self->{op}->typeRef;
  return 0 if ($type->{name} ne 'String');
  my $name = $self->{def}{string} || $self->{uop};
  $self->Error("Operand of '%s' can't be %s",$name,
	       ($self->{op}{isInfinite}? 'an infinity': 'a word'));
  return 1;
}

#
#  Error if operand is a list
#
sub checkList {
  my $self = shift;  return 0 if $self->context->flag("allowBadOperands");
  my $type = $self->{op}->typeRef;
  return 0 if ($type->{name} ne 'List');
  my $name = $self->{def}{string} || $self->{uop};
  $self->Error("Operand of '%s' can't be a list",$name);
  return 1;
}


#
#  Determine if the operand is an infinity and set the type
#
sub checkInfinite {
  my $self = shift;
  my $uop = $self->{def};
  return 0 unless $self->{op}->{isInfinite} && $uop->{allowInfinite};
  $self->{type} = $self->{op}->typeRef;
  return 1;
}

#
#  Determine if the operand is a number, and set the type
#    to complex or number according to the type of operand.
#
sub checkNumber {
  my $self = shift;
  return 0 if !($self->{op}->isNumber);
  if ($self->{op}->isComplex) {$self->{type} = $Value::Type{complex}}
  else {$self->{type} = $Value::Type{number}}
  return 1;
}

##################################################
#
#  Service routines for adjusting the values of operands.
#

#
#  Produce a reduced negation of an item.
#
sub Neg {
  my $self = shift;
  my $equation = $self->{equation};
  $self->Error("Can't reduce:  negation operator is not defined")
    if (!defined($equation->{context}->operators->resolveDef('u-')));
  return ($self->Item("UOP")->new($equation,'u-',$self))->reduce;
}

#
#  Get the variables used in the operand
#
sub getVariables {
  my $self = shift;
  $self->{op}->getVariables;
}

##################################################
#
#  Generate the various output formats.
#


#
#  Produce a string version of the equation.
#
#  We add parentheses if the precedence of the operator is less
#    than the parent operation.
#  Add the operator before or after the operand according to the
#    associativity of the operator.
#
sub string {
  my ($self,$precedence,$showparens,$position,$outerRight) = @_;
  my $string; my $uop = $self->{def}; $position = '' unless defined($position);
  my $extraParens = $self->context->flag('showExtraParens');
  my $addparens = (defined($precedence) && $precedence >= $uop->{precedence}) ||
                    (($position eq 'right' || $outerRight) && $extraParens);
  if ($uop->{associativity} eq "right") {
    $string = $self->{op}->string($uop->{precedence}).$uop->{string};
  } else {
    $string = $uop->{string}.$self->{op}->string($uop->{precedence});
  }
  $string = $self->addParens($string) if $addparens;
  return $string;
}

#
#  Produce the TeX form
#
sub TeX {
  my ($self,$precedence,$showparens,$position,$outerRight) = @_;
  $showparens = $showparens//'';
  my $TeX; my $uop = $self->{def}; $position = '' unless defined($position);
  my $fracparens = ($uop->{nofractionparens}) ? "nofractions" : "";
  my $extraParens = $self->context->flag('showExtraParens');
  my $addparens = (defined($precedence) && $precedence >= $uop->{precedence}) ||
                    (($position eq 'right' || $outerRight) && ($extraParens || $showparens eq "UOP"));
  $TeX = (defined($uop->{TeX}) ? $uop->{TeX} : $uop->{string});
  if ($uop->{associativity} eq "right") {
    $TeX = $self->{op}->TeX($uop->{precedence},$fracparens) . $TeX;
  } else {
    $TeX = $TeX . $self->{op}->TeX($uop->{precedence},$fracparens);
  }
  $TeX = '\left('.$TeX.'\right)' if $addparens;
  return $TeX;
}

#
#  Produce a Perl expression
#
sub perl {
  my $self = shift; my $parens = shift;
  my $uop = $self->{def}; my $perl;
  if ($uop->{isCommand}) {
    $perl = ($uop->{perl} || ref($self).'->call').'('.$self->{op}->perl.')';
  } else {
    $perl = ($uop->{perl} || $uop->{string})." ".$self->{op}->perl(1);
  }
  $perl = '('.$perl.')' if $parens;
  return $perl;
}

#########################################################################
#
#  Load the subclasses.
#

END {
  use Parser::UOP::undefined;
  use Parser::UOP::plus;
  use Parser::UOP::minus;
  use Parser::UOP::factorial;
}

#########################################################################

1;
