################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/contextLimitedPolynomial.pl,v 1.24 2010/04/01 00:21:45 dpvc Exp $
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


Uses library module   lib/LimitedPolynomial.pm

=cut

loadMacros("MathObjects.pl");

sub _contextLimitedPolynomial_init{
	Init();
} # don't load it again

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
