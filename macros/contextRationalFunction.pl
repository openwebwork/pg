################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2010 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/contextRationalFunction.pl,v 1.1 2010/03/31 21:01:14 dpvc Exp $
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

contextRationalFunction.pl - Only allow rational functions
                             (and their products and powers)

=head1 DESCRIPTION

Implements a context in which students can only enter rational
functions, with some control over whether a single division is
allowed, or whether products of rational functions are allowed.

Select the context using:

	Context("RationalFunction");

The RationalFunction context supports all the flags of the
PolynomialFactors context, except for strictDivision, since rational
functions allow division of polynomials.

In addition, there is a singleQuotients flag that controls whether
products of rational functions are allowed or not.  By default, they
are allowed, but you can set this flag to 1 in order to force the
student answer to be as a single fraction.

Finally, there is also a strict context that does not allow
operations even within the coefficients.  Select it using:

	Context("RationalFunction-Strict");

In addition to disallowing operations within the coefficients, this
context does not reduce constant operations (since they are not
allowed), and sets the singlePowers, singleFactors, singleQuotients,
and stricPowers flags automatically.  In addition, it disables all the
functions, though they can be re-enabled, if needed.

=cut

##################################################

loadMacros(
  "MathObjects.pl",
  "contextPolynomialFactors.pl"
);

sub _contextRationalFunction_init {RationalFunction::Init()}

##############################################

package RationalFunction::BOP::multiply;
our @ISA = qw(PolynomialFactors::BOP::multiply);

sub checkFactors {
  my $self = shift; my ($l,$r) = @_;
  $self->SUPER::checkFactors($l,$r);
  if (($l->{isPoly}||0) >= 6 || ($r->{isPoly}||0) >= 6) {
    $self->Error("You can not use multiplication with rational functions as operands ".
                 "(do you need parentheses around the denominator?)")
      if $self->context->flag("singleQuotients");
    $self->{isPoly} = 7; # product containing rational functions
  }
  return 1;
}

##############################################

package RationalFunction::BOP::divide;
our @ISA = qw(PolynomialFactors::BOP::divide);

sub checkPolynomial {
  my $self = shift; my ($l,$r) = ($self->{lop},$self->{rop});
  if ((!$l->{isPoly} || $l->{isPoly} == 2) && LimitedPolynomial::isConstant($r)) {
    $self->{isPoly} = $l->{isPoly};
    $self->{powers} = $l->{powers}; delete $l->{powers};
    $self->{exponents} = $l->{exponents}; delete $l->{exponents};
  } elsif (($l->{isPoly}||0) >= 6 || ($r->{isPoly}||0) >= 6) {
    $self->Error("Only one polynomial division is allowed in a rational function");
  } else {
    PolynomialFactors::markFactor($l);
    PolynomialFactors::markFactor($r);
    $self->checkFactors($l,$r);
  }
  return 1;
}

sub checkFactors {
  my $self = shift; my ($l,$r) = @_;
  my $single = $self->context->flag("singleFactors");
  $self->Error("Only one constant multiple or fraction is allowed (combine or cancel them)")
    if $l->{factors}{0} && $r->{factors}{0} && $self->context->flag("singleFactors");
  $self->{factors} = $l->{factors}; delete $l->{factors};
  foreach my $factor (keys %{$r->{factors}}) {
    if ($single && $self->{factors}{$factor}) {
      $self->Error("Each factor can appear only once (combine or cancel like factors)") unless $factor eq "0";
      $self->Error("Only one constant coefficient or negation is allowed (combine or cancel them)");
    }
    $self->{factors}{$factor} = 1;
  }
  delete $r->{factors};
  $self->{isPoly} = 6; # rational function
  return 1;
}

##############################################

package RationalFunction::BOP::power;
our @ISA = qw(PolynomialFactors::BOP::power);

sub checkPolynomial {
  my $self = shift; my ($l,$r) = ($self->{lop},$self->{rop});
  $self->SUPER::checkPolynomial;
  $self->{isPoly} = 6 if ($l->{isPoly}||0) >= 6;
  return 1;
}

##############################################

package RationalFunction::UOP::minus;
our @ISA = qw(PolynomialFactors::UOP::minus);

sub checkPolynomial {
  my $self = shift;
  $self->SUPER::checkPolynomial;
  $self->{isPoly} = 6 if ($self->{op}{isPoly}||0) >= 6;
  return 1;
}

##############################################

package RationalFunction;
our @ISA = ('PolynomialFactors');

sub Init {
  #
  #  Build the new context that calls the
  #  above classes rather than the usual ones
  #

  my $context = $main::context{RationalFunction} = Parser::Context->getCopy("PolynomialFactors");
  $context->{name} = "RationalFunction";
  $context->operators->set(
     '*' => {class => 'RationalFunction::BOP::multiply'},
    '* ' => {class => 'RationalFunction::BOP::multiply'},
    ' *' => {class => 'RationalFunction::BOP::multiply'},
     ' ' => {class => 'RationalFunction::BOP::multiply'},
     '/' => {class => 'RationalFunction::BOP::divide'},
    ' /' => {class => 'RationalFunction::BOP::divide'},
    '/ ' => {class => 'RationalFunction::BOP::divide'},
     '^' => {class => 'RationalFunction::BOP::power'},
    '**' => {class => 'RationalFunction::BOP::power'},
    'u-' => {class => 'RationalFunction::UOP::minus'},
  );
  $context->flags->set(strictPowers => 1);

  #
  #  A context where coefficients can't include operations
  #
  $context = $main::context{"RationalFunction-Strict"} = $context->copy;
  $context->flags->set(
    strictCoefficients => 1,
    singlePowers => 1, singleFactors => 1, singleQuotients => 1,
    reduceConstants => 0,
  );
  $context->functions->disable("All");  # can be re-enabled if needed

  main::Context("RationalFunction");  ### FIXME:  probably should require author to set this explicitly
}

1;
