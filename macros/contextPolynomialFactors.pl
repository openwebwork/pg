################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2010 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/contextPolynomialFactors.pl,v 1.2 2010/03/31 21:45:42 dpvc Exp $
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

contextPolynomialFactors.pl - Allow only entry of polynomials, and
                              their products and powers

=head1 DESCRIPTION

Implements a context in which students can only enter products and
powers of polynomials

Select the context using:

	Context("PolynomialFactors");

If you set the "singlePowers" flag, then only one monomial of each
degree can be included in each factor polynomial:

	Context("PolynomialFactors")->flags->set(singlePowers=>1);

If you set the "singleFactors" flag, then factors can not be repeated.
For example,

	Context("PolynomialFactors")->flags->set(singleFactors=>1);
	Formula("(x+1)^2*(x+1)");

will generate an error indicating that factors can appear only once.
Note, however, that this only catches factors that appear exactly the
same in both cases, so (x+1)*(1+x) would be allowed, as would
-(x-1)*(1-x).  Note also that there is no check for whether the
factors are irreducible, so (x^2-1)*(x+1)*(x-1) would be allowed.
Also, there is no check for whether constants have been factored out,
so 3*(x+1)*(3x+3) would be allowed.  This still needs more work to
make it very useful.

There are two additional flags that control whether division by a
constant or raising to a power are allowed to be performed on a
product or factors or only on a single factor at at time.  These are
strictDivision and strictPowers.  By default, strictDivisions is 0, so
(x*(x+1))/3 is allowed, while strictPowers is 1, so (x*(x+1))^3 is not
(it must be written x^3*(x+1)^3).

Finally, there is also a strict context that does not allow
operations even within the coefficients.  Select it using:

	Context("PolynomialFactors-Strict");

In addition to disallowing operations within the coefficients, this
context does not reduce constant operations (since they are not
allowed), and sets the singlePowers, singleFactors, strictDivision,
and stricPowers flags automatically.  In addition, it disables all the
functions, though they can be re-enabled, if needed.

=cut

##################################################

loadMacros(
  "MathObjects.pl",
  "contextLimitedPolynomial.pl"
);

sub _contextPolynomialFactors_init {PolynomialFactors::Init()}

##############################################

package PolynomialFactors::BOP::add;
our @ISA = qw(LimitedPolynomial::BOP::add);

sub checkPolynomial {
  my $self = shift;
  my ($l,$r) = ($self->{lop},$self->{rop});
  $self->Error("Addition is allowed only between monomials")
    if $r->{isPoly} || ($l->{isPoly} && $l->{isPoly} > 2);
  $self->checkPowers;
}

##############################################

package PolynomialFactors::BOP::subtract;
our @ISA = qw(LimitedPolynomial::BOP::subtract);

sub checkPolynomial {
  my $self = shift;
  my ($l,$r) = ($self->{lop},$self->{rop});
  $self->Error("Subtraction is allowed only between monomials")
    if $r->{isPoly} || ($l->{isPoly} && $l->{isPoly} > 2);
  $self->checkPowers;
}

##############################################

package PolynomialFactors::BOP::multiply;
our @ISA = qw(LimitedPolynomial::BOP::multiply);

sub checkPolynomial {
  my $self = shift; my ($l,$r) = ($self->{lop},$self->{rop});
  my $lOK = (LimitedPolynomial::isConstant($l) || $l->{isPower} ||
	     $l->class eq 'Variable' || ($l->{isPoly} && $l->{isPoly} == 2));
  my $rOK = ($r->{isPower} || $r->class eq 'Variable');
  return $self->checkExponents if $lOK and $rOK;
  $self->Error("Coefficients must come before variables or factors")
    if LimitedPolynomial::isConstant($r) && ($l->{isPower} || $l->class eq 'Variable');
  if ($l->{isPoly} || $r->{isPoly}) {
    PolynomialFactors::markFactor($l);
    PolynomialFactors::markFactor($r);
    return $self->checkFactors($l,$r);
  }
  return 1;
}

sub checkFactors {
  my $self = shift; my ($l,$r) = @_;
  my $single = $self->context->flag("singleFactors");
  $self->{factors} = $l->{factors}; delete $l->{factors};
  foreach my $factor (keys %{$r->{factors}}) {
    if ($single && $self->{factors}{$factor}) {
      $self->Error("Each factor can appear only once (combine like factors)") unless $factor eq "0";
      $self->Error("Only one constant coefficient or negation is allowed (combine them)");
    }
    $self->{factors}{$factor} = 1;
  }
  delete $r->{factors};
  $self->{isPoly} = 4; # product of factors
  return 1;
}

sub checkStrict {
  my $self = shift;
  $self->Error("You can only use '%s' between coefficents and variables or between factors",$self->{bop});
}

##############################################

package PolynomialFactors::BOP::divide;
our @ISA = qw(LimitedPolynomial::BOP::divide);

sub checkPolynomial {
  my $self = shift; my ($l,$r) = ($self->{lop},$self->{rop});
  $self->Error("In a polynomial, you can only divide by numbers")
    unless LimitedPolynomial::isConstant($r);
  if ($l->{isPoly} && $l->{isPoly} != 2) {
    $self->Error("You can only divide a single term or factor by a number")
      if $l->{isPoly} == 3 || ($self->context->flag("strictDivision") && $l->{isPoly} != 1);
    PolynomialFactors::markOpFactor($self,$l);
    $self->Error("Only one constant multiple or fraction is allowed (combine them)")
      if $self->{factors}{0} && $self->context->flag("singleFactors");
    $self->{factors}{0} = 1; # mark as constant multiple;
    $self->{isPoly} = 3;  # factor over a number
  } else {
    $self->{isPoly} = $l->{isPoly};
    $self->{powers} = $l->{powers}; delete $l->{powers};
    $self->{exponents} = $l->{exponents}; delete $l->{exponents};
  }
  return 1;
}

##############################################

package PolynomialFactors::BOP::power;
our @ISA = qw(LimitedPolynomial::BOP::power);

sub checkPolynomial {
  my $self = shift; my ($l,$r) = ($self->{lop},$self->{rop});
  $self->Error("Exponents must be constant in a polynomial")
    unless LimitedPolynomial::isConstant($r);
  my $n = Parser::Evaluate($r);
  $r->Error($$Value::context->{error}{message}) if $$Value::context->{error}{flag};
  $n = $n->value;
  $self->Error("Exponents must be positive integers in a polynomial")
    unless $n > 0 && $n == int($n);
  if ($l->{isPoly}) {
    $self->Error("You can only raise a single term or factor to a power")
      if $l->{isPoly} > 2 && $self->context->flag("strictPowers");
    PolynomialFactors::markOpFactor($self,$l);
    $self->{isPoly} = 5; # factor to a power
  } else {
    LimitedPolynomial::markPowers($l);
    $self->{exponents} = $l->{exponents}; delete $l->{exponents};
    foreach my $i (@{$self->{exponents}}) {$i = $n if $i}
    $self->{isPower} = 1;
  }
  return 1;
}

sub checkStrict {
  my $self = shift;
  $self->Error("You can only use powers of a variable or factor");
}

##############################################

package PolynomialFactors::UOP::minus;
our @ISA = qw(LimitedPolynomial::UOP::minus);

sub checkPolynomial {
  my $self = shift; my $op = $self->{op};
  if ($op->{isPoly} && $self->context->flag("singleFactors")) {
    $self->Error("Double negatives are not allowed") if $op->{isPoly} == 2;
    $self->Error("Only one factor or constant can be negated") if $op->{isPoly} == 4;
  }
  PolynomialFactors::markOpFactor($self,$op);
  $self->{factors}{0} = 1; # mark as constant multiple
  return 1;
}

##############################################

package PolynomialFactors::Formula;
our @ISA = ('Value::Formula');

sub cmp_postprocess {}

##############################################

package PolynomialFactors;
our @ISA = ('LimitedPolynomal');

sub markFactor {
  my $self = shift;
  return if $self->{factors};
  $self->{factors} = {};
  if ($self->class eq 'Variable') {
    $self->{factors}{$self->{name}} = 1;
  } elsif ($self->class eq 'Number') {
    $self->{factors}{0} = 1;
  } elsif ($self->{isPoly} && $self->{isPoly} == 1) {
    $self->{factors}{$self->string} = 1;
  } elsif ($self->{isPower}) {
    $self->{factors}{$self->{lop}->string} = 1;
  }
}

sub markOpFactor {
  my $self = shift; my $op = shift;
  markFactor($op);
  $self->{factors} = $op->{factors};
  delete $op->{factors};
}

sub Init {
  #
  #  Build the new context that calls the
  #  above classes rather than the usual ones
  #

  my $context = $main::context{PolynomialFactors} = Parser::Context->getCopy("LimitedPolynomial");
  $context->{name} = "PolynomialFactors";
  $context->operators->set(
     '+' => {class => 'PolynomialFactors::BOP::add'},
     '-' => {class => 'PolynomialFactors::BOP::subtract'},
     '*' => {class => 'PolynomialFactors::BOP::multiply'},
    '* ' => {class => 'PolynomialFactors::BOP::multiply'},
    ' *' => {class => 'PolynomialFactors::BOP::multiply'},
     ' ' => {class => 'PolynomialFactors::BOP::multiply'},
     '/' => {class => 'PolynomialFactors::BOP::divide'},
    ' /' => {class => 'PolynomialFactors::BOP::divide'},
    '/ ' => {class => 'PolynomialFactors::BOP::divide'},
     '^' => {class => 'PolynomialFactors::BOP::power'},
    '**' => {class => 'PolynomialFactors::BOP::power'},
    'u-' => {class => 'PolynomialFactors::UOP::minus'},
  );
  $context->flags->set(strictPowers => 1);
  $context->{value}{'Formula()'} = "PolynomialFactors::Formula";
  $context->{value}{'Formula'} = "PolynomialFactors::Formula";
  $context->{parser}{'Formula'} = "PolynomialFactors::Formula";

  #
  #  A context where coefficients can't include operations
  #
  $context = $main::context{"PolynomialFactors-Strict"} = $context->copy;
  $context->flags->set(
    strictCoefficients => 1, strictDivision => 1,
    singlePowers => 1, singleFactors => 1,
    reduceConstants => 0,
  );
  $context->functions->disable("All");  # can be re-enabled if needed

  main::Context("PolynomialFactors");  ### FIXME:  probably should require author to set this explicitly
}

1;
