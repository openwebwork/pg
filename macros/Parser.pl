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

Parser.pl - Macro-based fronted to the MathObjects system.

=cut

###########################################################################
##
##  Set up the functions needed by the Parser.
##

# ^uses $Parser::installed
# ^uses $Value::installed
if (!$Parser::installed) {
  die "\n************************************************************\n" .
        "* This problem requires the Parser.pm package, which doesn't\n".
        "* seem to be installed.  Please contact your WeBWorK system\n".
        "* administrator and ask him or her to install it first.\n".
        "************************************************************\n\n"
}
if (!$Value::installed) {
  die "\n************************************************************\n" .
        "* This problem requires the Value.pm package, which doesn't\n".
        "* seem to be installed.  Please contact your WeBWorK system\n".
        "* administrator and ask him or her to install it first.\n".
        "************************************************************\n\n"
}

# ^uses loadMacros
loadMacros("Value.pl");
loadMacros("PGcommonFunctions.pl");

=head1 MACROS

=head1 Formula

	Formula("formula");

The main way to get a MathObject Formula object (an equation that depends on one
or more variables).

=cut

# ^function Formula
# ^uses Value::Package
sub Formula {Value->Package("Formula()")->new(@_)}

=head2 Compute

	Compute("formula"[, var=>value, ...]);

Compute the value of a formula and return a MathObject appropriate to its
value.  Set the object so that the correct answer will be shown exatly as in the
given string rather than by its usual stringification.  If the value is a
Formula and any var=>value pairs are specified, then the formula will be
evaluated using the given variable values.  E.g.,

	$x = Compute("x+3",x=>2)

will produce the equivalent of $x = Real(5).

The original parsed formula will be saved in the object's original_formula
field, and can be obtained by

	$x->{original_formula};

if needed later in the problem.

=cut

# ^function Compute
# ^uses Formula
# ^uses Value::contextSet
sub Compute {
  my $string = shift;
  my $formula = Formula($string);
  $formula = $formula->{tree}->Compute if $formula->{tree}{canCompute};
  my $context = $formula->context;
  my $flags = Value::contextSet($context,reduceConstants=>0,reduceConstantFunctions=>0);
  if (scalar(@_)) {
    $formula = $formula->substitute(@_)->with(original_formula => $formula);
    $string = $formula->string;
  }
  if ($formula->isConstant) {
    $formula = $formula->eval()->with
      (original_formula => $formula->{original_formula} || $formula);
  }
  $formula->{correct_ans} = $string;
  $formula->{correct_ans_latex_string} =
    (($formula->{original_formula} || $flags{reduceConstants} ||
      $flags{reduceConstantFunctions}) ?  Formula($string) : $formula)->TeX;
  Value::contextSet($context,$flags);
  return $formula;
}

=head2 Context

	Context();
	Context($name);
	Context($context);

Set or get the current context.  When a name is given, the context with that
name is selected as the current context.  When a context reference is provided,
that context is set as the current one.  In all three cases, the current context
(after setting) is returned.

=cut

# ^function Context
# ^uses Parser::Context::current
# ^uses %context
sub Context {Parser::Context->current(\%context,@_)}
# ^variable our %context
%context = ();  # Locally defined contexts, including 'current' context
# ^uses Context
Context();      # Initialize context (for persistent mod_perl)

###########################################################################
#
# stubs for trigonometric functions
#

# ^package Ignore
package Ignore;  ## let PGauxiliaryFunctions.pl do these

# ^#function sin
# ^#uses Parser::Function::call
#sub sin {Parser::Function->call('sin',@_)}    # Let overload handle it
# ^#function cos
# ^#uses Parser::Function::call
#sub cos {Parser::Function->call('cos',@_)}    # Let overload handle it
# ^function tan
# ^uses Parser::Function::call
sub tan {Parser::Function->call('tan',@_)}
# ^function sec
# ^uses Parser::Function::call
sub sec {Parser::Function->call('sec',@_)}
# ^function csc
# ^uses Parser::Function::call
sub csc {Parser::Function->call('csc',@_)}
# ^function cot
# ^uses Parser::Function::call
sub cot {Parser::Function->call('cot',@_)}

# ^function asin
# ^uses Parser::Function::call
sub asin {Parser::Function->call('asin',@_)}
# ^function acos
# ^uses Parser::Function::call
sub acos {Parser::Function->call('acos',@_)}
# ^function atan
# ^uses Parser::Function::call
sub atan {Parser::Function->call('atan',@_)}
# ^function asec
# ^uses Parser::Function::call
sub asec {Parser::Function->call('asec',@_)}
# ^function acsc
# ^uses Parser::Function::call
sub acsc {Parser::Function->call('acsc',@_)}
# ^function acot
# ^uses Parser::Function::call
sub acot {Parser::Function->call('acot',@_)}

# ^function arcsin
# ^uses Parser::Function::call
sub arcsin {Parser::Function->call('asin',@_)}
# ^function arccos
# ^uses Parser::Function::call
sub arccos {Parser::Function->call('acos',@_)}
# ^function arctan
# ^uses Parser::Function::call
sub arctan {Parser::Function->call('atan',@_)}
# ^function arcsec
# ^uses Parser::Function::call
sub arcsec {Parser::Function->call('asec',@_)}
# ^function arccsc
# ^uses Parser::Function::call
sub arccsc {Parser::Function->call('acsc',@_)}
# ^function arccot
# ^uses Parser::Function::call
sub arccot {Parser::Function->call('acot',@_)}

###########################################################################
#
# stubs for hyperbolic functions
#

# ^function sinh
# ^uses Parser::Function::call
sub sinh {Parser::Function->call('sinh',@_)}
# ^function cosh
# ^uses Parser::Function::call
sub cosh {Parser::Function->call('cosh',@_)}
# ^function tanh
# ^uses Parser::Function::call
sub tanh {Parser::Function->call('tanh',@_)}
# ^function sech
# ^uses Parser::Function::call
sub sech {Parser::Function->call('sech',@_)}
# ^function csch
# ^uses Parser::Function::call
sub csch {Parser::Function->call('csch',@_)}
# ^function coth
# ^uses Parser::Function::call
sub coth {Parser::Function->call('coth',@_)}

# ^function asinh
# ^uses Parser::Function::call
sub asinh {Parser::Function->call('asinh',@_)}
# ^function acosh
# ^uses Parser::Function::call
sub acosh {Parser::Function->call('acosh',@_)}
# ^function atanh
# ^uses Parser::Function::call
sub atanh {Parser::Function->call('atanh',@_)}
# ^function asech
# ^uses Parser::Function::call
sub asech {Parser::Function->call('asech',@_)}
# ^function acsch
# ^uses Parser::Function::call
sub acsch {Parser::Function->call('acsch',@_)}
# ^function acoth
# ^uses Parser::Function::call
sub acoth {Parser::Function->call('acoth',@_)}

# ^function arcsinh
# ^uses Parser::Function::call
sub arcsinh {Parser::Function->call('asinh',@_)}
# ^function arccosh
# ^uses Parser::Function::call
sub arccosh {Parser::Function->call('acosh',@_)}
# ^function arctanh
# ^uses Parser::Function::call
sub arctanh {Parser::Function->call('atanh',@_)}
# ^function arcsech
# ^uses Parser::Function::call
sub arcsech {Parser::Function->call('asech',@_)}
# ^function arccsch
# ^uses Parser::Function::call
sub arccsch {Parser::Function->call('acsch',@_)}
# ^function arccoth
# ^uses Parser::Function::call
sub arccoth {Parser::Function->call('acoth',@_)}

###########################################################################
#
# stubs for numeric functions
#

# ^#function log
# ^#uses Parser::Function::call
#sub log   {Parser::Function->call('log',@_)}    # Let overload handle it
# ^function log10
# ^uses Parser::Function::call
sub log10 {Parser::Function->call('log10',@_)}
# ^#function exp
# ^#uses Parser::Function::call
#sub exp   {Parser::Function->call('exp',@_)}    # Let overload handle it
# ^#function sqrt
# ^#uses Parser::Function::call
#sub sqrt  {Parser::Function->call('sqrt',@_)}    # Let overload handle it
# ^#function abs
# ^#uses Parser::Function::call
#sub abs   {Parser::Function->call('abs',@_)}    # Let overload handle it
# ^function int
# ^uses Parser::Function::call
sub int   {Parser::Function->call('int',@_)}
# ^function sgn
# ^uses Parser::Function::call
sub sgn   {Parser::Function->call('sgn',@_)}

# ^function ln
# ^uses Parser::Function::call
sub ln     {Parser::Function->call('log',@_)}
# ^function logten
# ^uses Parser::Function::call
sub logten {Parser::Function->call('log10',@_)}

# ^package main
package main;  ##  back to main

# ^function log10
# ^uses Parser::Function::call
sub log10 {Parser::Function->call('log10',@_)}
# ^function Factorial
# ^uses Parser::UOP::factorial::call
sub Factorial {Parser::UOP::factorial->call(@_)}

###########################################################################
#
# stubs for special functions
#

# ^#function atan2
# ^#usesParser::Function::call
#sub atan2 {Parser::Function->call('atan2',@_)}    # Let overload handle it

###########################################################################
#
# stubs for numeric functions
#

# ^function arg
# ^uses Parser::Function::call
sub arg  {Parser::Function->call('arg',@_)}
# ^function mod
# ^uses Parser::Function::call
sub mod  {Parser::Function->call('mod',@_)}
# ^function Re
# ^uses Parser::Function::call
sub Re   {Parser::Function->call('Re',@_)}
# ^function Im
# ^uses Parser::Function::call
sub Im   {Parser::Function->call('Im',@_)}
# ^function conj
# ^uses Parser::Function::call
sub conj {Parser::Function->call('conj',@_)}

###########################################################################
#
# stubs for vector functions
#

# ^function norm
# ^uses Parser::Function::call
sub norm {Parser::Function->call('norm',@_)}
# ^function unit
# ^uses Parser::Function::call
sub unit {Parser::Function->call('unit',@_)}

#
# These are defined in PG.pl (since they call eval())
#
# sub i () {Compute('i')}
# sub j () {Compute('j')}
# sub k () {Compute('k')}

###########################################################################

# ^variable our $_parser_loaded
$_parser_loaded = 1;  #  use this to tell if Parser.pl is loaded

# ^function _Parser_init
sub _Parser_init {}; # don't let loadMacros load it again

# ^uses loadMacros
loadMacros("parserCustomization.pl");

###########################################################################

1;
