#########################################################################
#
#  Implements function calls
#

package Parser::Function;
use strict; use vars qw(@ISA);
@ISA = qw(Parser::Item);

$Parser::class->{Function} = 'Parser::Function';

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $equation = shift; my $context = $equation->{context};
  my ($name,$params,$constant,$ref) = @_;
  my $def = $context->{functions}{$name};
  $name = $def->{alias}, $def = $context->{functions}{$name} if defined $def->{alias};
  my $fn = bless {
    name => $name, params => $params,
    def => $def, ref => $ref, equation => $equation,
  }, $def->{class};
  $fn->_check;
  $fn = $context->{parser}{Value}->new($equation,[$fn->eval]) if $constant;
  return $fn;
}

#
#  Stub to check if arguments are OK.
#  (Implemented in sub-classes.)
#
sub _check {}

##################################################

#
#  Evaluate all the arguments and then perform the function
#
sub eval {
  my $self = shift; my @params = ();
  foreach my $x (@{$self->{params}}) {push(@params,$x->eval)}
  $self->_eval(@params);
}
#
#  Stub for sub-classes
#
sub _eval {shift; return @_}

#
#  Reduce all the arguments and compute the function if they are
#    all constant.
#  Otherwise, let the sub-classes reduce it.
#
sub reduce {
  my $self = shift;
  my @params = (); my $constant = 1;
  foreach my $x (@{$self->{params}})
    {$x = $x->reduce; $constant = 0 unless $x->{isConstant}}
  return $self->{equation}{context}{parser}{Value}->
    new($self->{equation},[$self->eval]) if $constant;
  $self->_reduce;
}
#
#  Stub for sub-classes.
#
sub _reduce {shift}

#
#  Substitute in each argument.
#
sub substitute {
  my $self = shift;
  my @params = (); my $constant = 1;
  foreach my $x (@{$self->{params}})
    {$x = $x->substitute; $constant = 0 unless $x->{isConstant}}
  return $self->{equation}{context}{parser}{Value}->
    new($self->{equation},[$self->eval]) if $constant;
  return $self;
}

#
#  Copy the arguments as well as the function object
#
sub copy {
  my $self = shift; my $equation = shift;
  my $new = $self->SUPER::copy($equation);
  $new->{params} = [];
  foreach my $x (@{$self->{params}}) {push(@{$new->{params}},$x->copy($equation))}
  return $new;
}

#
#  Create a new formula if the function's arguments are formulas
#  Otherwise evaluate the function call.
#  
#  (This is used to "overload" function calls so that they will
#   work in Value.pm to produce formulas when called on formulas.)
#
sub call {
  my $self = shift; my $name = shift;
  my $context = Parser::Context->current;
  my $fn = $context->{functions}{$name};
  Value::Error("No definition for function '$name'") unless defined($fn);
  my $isFormula = 0;
  foreach my $x (@_) {return $self->formula($name,@_) if Value::isFormula($x)}
  my $class = $fn->{class};
  $class->_call($name,@_);
}
#
#  Stub for sub-classes.
#  (Default is return the argument)
#
sub _call {shift; shift; shift}

#
#  Create a formula that consists of a function call on the
#    given arguments.  They are converted to formulas as well.
#
sub formula {
  my $self = shift; my $name = shift;
  my $formula = Value::Formula->blank;
  my @args = Value::toFormula($formula,@_);
  $formula->{tree} = $formula->{context}{parser}{Function}->new($formula,$name,[@args]);
#  return $formula->eval if scalar(%{$formula->{variables}}) == 0;
  return $formula;
}

##################################################
#
#  Service routines for checking the arguments
#

#
#  Check that the function has a single numeric argument
#    and check if it is allowed to be complex.
#
sub checkNumeric {
  my $self = shift;
  return if ($self->checkArgCount(1));
  my $arg = $self->{params}->[0];
  if ($arg->isComplex) {
    if (!($self->{def}{nocomplex})) {$self->{type} = $Value::Type{complex}}
    else {$self->Error("Function '$self->{name}' doesn't accept Complex inputs")}
  } elsif ($arg->isNumber) {
    $self->{type} = $Value::Type{number};
  } else {$self->Error("The input for '$self->{name}' must be a number")}
}

#
#  Error if the argument is not a single vector
#
sub checkVector {
  my $self = shift;
  return if ($self->checkArgCount(1));
  if ($self->{params}->[0]->type =~ m/Point|Vector/) {
    $self->{type} = $Value::Type{number};
  } else {$self->Error("Function '$self->{name}' requires a Vector input")}
}

#
#  Error if the argument isn't a single complex number
#    and return a real.
#
sub checkReal {
  my $self = shift;
  return if ($self->checkArgCount(1));
  if ($self->{params}->[0]->isNumber) {
    $self->{type} = $Value::Type{number};
  } else {$self->Error("Function '$self->{name}' requires a Complex input")}
}

#
#  Error if the argument isn't a singe complex number
#    and return a complex.
#
sub checkComplex {
  my $self = shift;
  return if ($self->checkArgCount(1));
  if ($self->{params}->[0]->isNumber) {
    $self->{type} = $Value::Type{complex};
  } else {$self->Error("Function '$self->{name}' requires a Complex input")}
}

##################################################
#
#  Service routines for arguments
#

#
#  Check if the function's inverse can be written f^{-1}
#
sub checkInverse {
  my $equation = shift;
  my $fn = shift; my $op = shift; my $rop = shift;
  $op = $equation->{context}{operators}{$op->{name}};
  $fn = $equation->{context}{functions}{$fn->{name}};
  return ($fn->{inverse} && $op->{isInverse} && $rop->{value}->string eq "-1");
}

#
#  Check that there are the right number of arguments
#
sub checkArgCount {
  my $self = shift; my $count = shift;
  my $name = $self->{name};
  my $args = scalar(@{$self->{params}});
  if ($args == $count) {
    return 0 if ($count == 0 || $self->{params}->[0]->length > 0);
    $self->Error("Function '$name' requires a non-empty input list");
  } elsif ($args < $count) {
    $self->Error("Function '$name' has too few inputs");
  } else {
    $self->Error("Function '$name' has too many inputs");
  }
  return 1;
}

#
#  Find all the variables used in the arguments
#
sub getVariables {
  my $self = shift; my $vars = {};
  foreach my $x (@{$self->{params}}) {$vars = {%{$vars},%{$x->getVariables}}}
  return $vars;
}

##################################################
#
#  Generate the different output formats
#

#
#  Produce the string form.
#  
#  Put parentheses around the funciton call if
#    the function call is on the left of the parent operation
#    and the precedence of the parent is higher than function call
#    (e.g., powers, etc.)
#
sub string {
  my ($self,$precedence,$showparens,$position,$outerRight,$power) = @_;
  my $string; my $fn = $self->{equation}{context}{operators}{'fn'};
  my @pstr = (); my $fn_precedence = $fn->{precedence};
  $fn_precedence = $fn->{parenPrecedence}
    if ($position && $position eq 'right' && $fn->{parenPrecedence});
  foreach my $x (@{$self->{params}}) {push(@pstr,$x->string)}
  $string = ($self->{def}{string} || $self->{name})."$power".'('.join(',',@pstr).')';
  $string = '('.$string.')'
    if (defined($precedence) and $precedence > $fn_precedence);
  return $string;
}

#
#  Produce the TeX form.
#
sub TeX {
  my ($self,$precedence,$showparens,$position,$outerRight,$power) = @_;
  my $TeX; my $fn = $self->{equation}{context}{operators}{'fn'};
  my @pstr = (); my $fn_precedence = $fn->{precedence};
  $fn_precedence = $fn->{parenPrecedence}
    if ($position && $position eq 'right' && $fn->{parenPrecedence});
  $fn = $self->{def};
  my $name = '\mathop{\rm '.$self->{name}.'}';
  $name = $fn->{TeX} if defined($fn->{TeX});
  foreach my $x (@{$self->{params}}) {push(@pstr,$x->TeX)}
  if ($fn->{braceTeX}) {$TeX = $name.'{'.join(',',@pstr).'}'}
    else {$TeX = $name."$power".'\!\left('.join(',',@pstr).'\right)'}
  $TeX = '\left('.$TeX.'\right)'
    if (defined($precedence) and $precedence > $fn_precedence);
  return $TeX;
}

#
#  Produce the perl form.
#
sub perl {
  my $self = shift; my $parens = shift;
  my $fn = $self->{def}; my @p = ();
  foreach my $x (@{$self->{params}}) {push(@p,$x->perl)}
  my $perl = ($fn->{perl}? $fn->{perl} : $self->{name}).'('.join(',',@p).')';
  $perl = '('.$perl.')' if $parens == 1;
  return $perl;
}

#########################################################################
#
#  Load the subclasses.
#

use Parser::Function::undefined;
use Parser::Function::trig;
use Parser::Function::hyperbolic;
use Parser::Function::numeric;
use Parser::Function::numeric2;
use Parser::Function::complex;
use Parser::Function::vector;

#########################################################################

1;

