################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader$
# 
# This program is free software; you can redistribute it and/or modify it under
# the terms of either: (a) the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version, or (b) the "Artistic License" which comes with this package.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
# Artistic License for more details.
################################################################################

=head1 NAME

contextLimitedPolynomial.pl - Allow only entry of polynomials.

=head1 DESCRIPTION

Implements a context in which students can only enter (expanded)
polynomials (i.e., sums of multiples of powers of x).

Select the context using:

	Context("LimitedPolynomial");

If you set the "singlePowers" flag, then only one monomial of each
degree can be included in the polynomial:

	Context("LimitedPolynomial")->flags->set(singlePowers=>1);

There is also a strict limited context that does not allow
operations even within the coefficients.  Select it using:

	Context("LimitedPolynomial-Strict");

In addition to disallowing operations within the coefficients,
this context does not reduce constant operations (since they are
not allowed), and sets the singlePowers flag automatically.  In
addition, it disables all the functions, though they can be
re-enabled, if needed.

=cut

loadMacros("MathObjects.pl");

sub _contextLimitedPolynomial_init {LimitedPolynomial::Init()}; # don't load it again

##################################################
#
#  Handle common checking for BOPs
#

package LimitedPolynomial;

#
#  Mark a variable as having power 1
#  Mark a number as being present (when strict coefficients are used)
#  Mark a monomial as having its given powers
#
sub markPowers {
  my $self = shift;
  if ($self->class eq 'Variable') {
    my $vIndex = LimitedPolynomial::getVarIndex($self);
    $self->{index} = $vIndex->{$self->{name}};
    $self->{exponents} = [(0) x scalar(keys %{$vIndex})];
    $self->{exponents}[$self->{index}] = 1;
  } elsif ($self->class eq 'Number') {
    my $vIndex = LimitedPolynomial::getVarIndex($self);
    $self->{exponents} = [(0) x scalar(keys %{$vIndex})];
  }
  if ($self->{exponents}) {
    my $power = join(',',@{$self->{exponents}});
    $self->{powers}{$power} = 1;
  }
}

#
#  Get a hash of variable names that point to indices
#  within the array of powers for a monomial
#
sub getVarIndex {
  my $self = shift;
  my $equation = $self->{equation};
  if (!$equation->{varIndex}) {
    $equation->{varIndex} = {}; my $i = 0;
    foreach my $v ($equation->{context}->variables->names)
      {$equation->{varIndex}{$v} = $i++}
  }
  return $equation->{varIndex};
}

#
#  Check for a constant expression
#
sub isConstant {
  my $self = shift;
  return 1 if $self->{isConstant} || $self->class eq 'Constant';
  return scalar(keys(%{$self->getVariables})) == 0;
}

##################################################
#
#  Handle common checking for BOPs
#


package LimitedPolynomial::BOP;
our @ISA = ();


#
#  Do original check and then if the operands are numbers, its OK.
#  Otherwise, do an operator-specific check for if the polynomial is OK.
#  Otherwise report an error.
#

sub _check {
  my $self = shift;
  my $super = ref($self); $super =~ s/^.*?::/Parser::/;

  &{$super."::_check"}($self);
  if (LimitedPolynomial::isConstant($self->{lop}) &&
      LimitedPolynomial::isConstant($self->{rop})) {
    $self->checkStrict if $self->context->flag("strictCoefficients");
    return;
  }
  return if $self->checkPolynomial;
  $self->Error("Your answer doesn't look like a polynomial");
}

#
#  filled in by subclasses
#
sub checkPolynomial {return 0}

#
#  Check that the exponents of a monomial are OK
#  and record the new exponent array
#
sub checkExponents {
  my $self = shift;
  my ($l,$r) = ($self->{lop},$self->{rop});
  LimitedPolynomial::markPowers($l);
  LimitedPolynomial::markPowers($r);
  my $exponents = $self->{exponents} = $r->{exponents};
  delete $r->{exponents}; delete $r->{powers};
  if ($l->{exponents}) {
    my $single = $self->context->flag('singlePowers');
    foreach my $i (0..scalar(@{$exponents})-1) {
      $self->Error("A variable can appear only once in each term of a polynomial")
	if $exponents->[$i] && $l->{exponents}[$i] && $single;
      $exponents->[$i] += $l->{exponents}[$i];
    }
  }
  delete $l->{exponents}; delete $l->{powers};
  $self->{isPower} = 1; $self->{isPoly} = $l->{isPoly};
  return 1;
}

#
#  Check that the powers of combined monomials are OK
#  and record the new power list
#
sub checkPowers {
  my $self = shift;
  my ($l,$r) = ($self->{lop},$self->{rop});
  my $single = $self->context->flag('singlePowers');
  LimitedPolynomial::markPowers($l);
  LimitedPolynomial::markPowers($r);
  $self->{isPoly} = 1;
  $self->{powers} = $l->{powers} || {}; delete $l->{powers};
  return 1 unless $r->{powers};
  foreach my $n (keys(%{$r->{powers}})) {
    $self->Error("Simplified polynomials can have at most one term of each degree")
      if $self->{powers}{$n} && $single;
    $self->{powers}{$n} = 1;
  }
  delete $r->{powers};
  return 1;
}

#
#  Report an error when both operands are constants
#  and strictCoefficients is in effect.
#
sub checkStrict {
  my $self = shift;
  $self->Error("Can't use '%s' between constants",$self->{bop});
}


##############################################
#
#  Now we get the individual replacements for the operators
#  that we don't want to allow.  We inherit everything from
#  the original Parser::BOP class, and just add the
#  polynomial checks here.  Note that checkPolynomial
#  only gets called if at least one of the terms is not
#  a number.
#

package LimitedPolynomial::BOP::add;
our @ISA = qw(LimitedPolynomial::BOP Parser::BOP::add);

sub checkPolynomial {
  my $self = shift;
  my ($l,$r) = ($self->{lop},$self->{rop});
  $self->Error("Addition is allowed only between monomials") if $r->{isPoly};
  $self->checkPowers;
}

##############################################

package LimitedPolynomial::BOP::subtract;
our @ISA = qw(LimitedPolynomial::BOP Parser::BOP::subtract);

sub checkPolynomial {
  my $self = shift;
  my ($l,$r) = ($self->{lop},$self->{rop});
  $self->Error("Subtraction is allowed only between monomials") if $r->{isPoly};
  $self->checkPowers;
}

##############################################

package LimitedPolynomial::BOP::multiply;
our @ISA = qw(LimitedPolynomial::BOP Parser::BOP::multiply);

sub checkPolynomial {
  my $self = shift;
  my ($l,$r) = ($self->{lop},$self->{rop});
  my $lOK = (LimitedPolynomial::isConstant($l) || $l->{isPower} ||
	     $l->class eq 'Variable' || ($l->{isPoly} && $l->{isPoly} == 2));
  my $rOK = ($r->{isPower} || $r->class eq 'Variable');
  return $self->checkExponents if $lOK and $rOK;
  $self->Error("Coefficients must come before variables in a polynomial")
    if LimitedPolynomial::isConstant($r) && ($l->{isPower} || $l->class eq 'Variable');
  $self->Error("Multiplication can only be used between coefficients and variables");
}

sub checkStrict {
  my $self = shift;
  $self->Error("You can only use '%s' between coefficents and variables in a polynomial",$self->{bop});
}

##############################################

package LimitedPolynomial::BOP::divide;
our @ISA = qw(LimitedPolynomial::BOP Parser::BOP::divide);

sub checkPolynomial {
  my $self = shift;
  my ($l,$r) = ($self->{lop},$self->{rop});
  $self->Error("In a polynomial, you can only divide by numbers")
    unless LimitedPolynomial::isConstant($r);
  $self->Error("You can only divide a single term by a number")

    if $l->{isPoly} && $l->{isPoly} != 2;
  $self->{isPoly} = $l->{isPoly};
  $self->{powers} = $l->{powers}; delete $l->{powers};
  $self->{exponents} = $l->{exponents}; delete $l->{exponents};
  return 1;
}

sub checkStrict {
  my $self = shift;
  $self->Error("You can only use '%s' to form numeric fractions",$self->{bop}) if $self->{lop}->class eq 'BOP';
}

##############################################

package LimitedPolynomial::BOP::power;
our @ISA = qw(LimitedPolynomial::BOP Parser::BOP::power);

sub checkPolynomial {
  my $self = shift;
  my ($l,$r) = ($self->{lop},$self->{rop});
  $self->Error("You can only raise a variable to a power in a polynomial")
    unless $l->class eq 'Variable';
  $self->Error("Exponents must be constant in a polynomial")
    unless LimitedPolynomial::isConstant($r);
  my $n = Parser::Evaluate($r);
  $r->Error($$Value::context->{error}{message}) if $$Value::context->{error}{flag};
  $n = $n->value;
  $self->Error("Exponents must be positive integers in a polynomial")
    unless $n > 0 && $n == int($n);
  LimitedPolynomial::markPowers($l);
  $self->{exponents} = $l->{exponents}; delete $l->{exponents};
  foreach my $i (@{$self->{exponents}}) {$i = $n if $i}
  $self->{isPower} = 1;
  return 1;
}

sub checkStrict {
  my $self = shift;
  $self->Error("You can only use powers of a variable in a polynomial");
}

##############################################
##############################################
#
#  Now we do the same for the unary operators
#

package LimitedPolynomial::UOP;

sub _check {
  my $self = shift;

  my $super = ref($self); $super =~ s/^.*?::/Parser::/;
  &{$super."::_check"}($self);
  my $op = $self->{op};
  return if LimitedPolynomial::isConstant($op);
  $self->{isPoly} = 2;
  $self->{powers} = $op->{powers}; delete $op->{powers};
  $self->{exponents} = $op->{exponents}; delete $op->{exponents};
  return if $self->checkPolynomial;
  $self->Error("You can only use '%s' with monomials",$self->{def}{string});
}

sub checkPolynomial {return !(shift)->{op}{isPoly}}


##############################################

package LimitedPolynomial::UOP::plus;
our @ISA = qw(LimitedPolynomial::UOP Parser::UOP::plus);

##############################################

package LimitedPolynomial::UOP::minus;
our @ISA = qw(LimitedPolynomial::UOP Parser::UOP::minus);

##############################################
##############################################
#
#  Don't allow absolute values
#

package LimitedPolynomial::List::AbsoluteValue;
our @ISA = qw(Parser::List::AbsoluteValue);

sub _check {
  my $self = shift;
  $self->SUPER::_check;
  return if LimitedPolynomial::isConstant($self->{coords}[0]);
  $self->Error("Can't use absolute values in polynomials");
}

##############################################
##############################################
#
#  Only allow numeric function calls
#

package LimitedPolynomial::Function;

sub _check {
  my $self = shift;
  my $super = ref($self); $super =~ s/LimitedPolynomial/Parser/;
  &{$super."::_check"}($self);
  my $arg = $self->{params}->[0];
  return if LimitedPolynomial::isConstant($arg);
  $self->Error("Function '%s' can only be used with numbers",$self->{name});
}


package LimitedPolynomial::Function::numeric;
our @ISA = qw(LimitedPolynomial::Function Parser::Function::numeric);

package LimitedPolynomial::Function::trig;
our @ISA = qw(LimitedPolynomial::Function Parser::Function::trig);

package LimitedPolynomial::Function::hyperbolic;
our @ISA = qw(LimitedPolynomial::Function Parser::Function::hyperbolic);

##############################################
##############################################

package LimitedPolynomial;

sub Init {
  #
  #  Build the new context that calls the
  #  above classes rather than the usual ones
  #

  my $context = $main::context{LimitedPolynomial} = Parser::Context->getCopy("Numeric");
  $context->{name} = "LimitedPolynomial";
  $context->operators->set(
     '+' => {class => 'LimitedPolynomial::BOP::add'},
     '-' => {class => 'LimitedPolynomial::BOP::subtract'},
     '*' => {class => 'LimitedPolynomial::BOP::multiply'},
    '* ' => {class => 'LimitedPolynomial::BOP::multiply'},
    ' *' => {class => 'LimitedPolynomial::BOP::multiply'},
     ' ' => {class => 'LimitedPolynomial::BOP::multiply'},
     '/' => {class => 'LimitedPolynomial::BOP::divide'},
    ' /' => {class => 'LimitedPolynomial::BOP::divide'},
    '/ ' => {class => 'LimitedPolynomial::BOP::divide'},
     '^' => {class => 'LimitedPolynomial::BOP::power'},
    '**' => {class => 'LimitedPolynomial::BOP::power'},
    'u+' => {class => 'LimitedPolynomial::UOP::plus'},
    'u-' => {class => 'LimitedPolynomial::UOP::minus'},
  );
  #
  #  Remove these operators and functions
  #
  $context->lists->set(
    AbsoluteValue => {class => 'LimitedPolynomial::List::AbsoluteValue'},
  );
  $context->operators->undefine('_','!','U');
  $context->functions->disable("atan2");
  #
  #  Hook into the numeric, trig, and hyperbolic functions
  #
  foreach ('ln','log','log10','exp','sqrt','abs','int','sgn') {
    $context->functions->set(
      "$_"=>{class => 'LimitedPolynomial::Function::numeric'}
    );
  }
  foreach ('sin','cos','tan','sec','csc','cot',
           'asin','acos','atan','asec','acsc','acot') {
    $context->functions->set(
       "$_"=>{class => 'LimitedPolynomial::Function::trig'},
       "${_}h"=>{class => 'LimitedPolynomial::Function::hyperbolic'}
    );
  }
  #
  #  Don't convert -ax-b to -(ax+b), or -ax+b to b-ax, etc.
  #
  $context->reduction->set("(-x)-y"=>0,"(-x)+y"=>0);

  #
  #  A context where coefficients can't include operations
  #
  $context = $main::context{"LimitedPolynomial-Strict"} = $context->copy;
  $context->flags->set(strictCoefficients=>1, singlePowers=>1, reduceConstants=>0);
  $context->functions->disable("All");  # can be re-enabled if needed

  main::Context("LimitedPolynomial");  ### FIXME:  probably should require author to set this explicitly
}

1;
