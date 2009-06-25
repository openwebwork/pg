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

parserFunction.pl - An easy way of adding new functions to the current context.

=head1 DESCRIPTION

This file implements an easy way of creating new functions that
are added to the current Parser context.  (This avoids having to
do the complicated procedure outlined in the docs/parser/extensions
samples.)

To create a function that can be used in Formula() calls (and by
students in their answers), use the parserFunction() routine, as
in the following examples:

	parserFunction(f => "sqrt(x+1)-2");

	$x = Formula('x');
	parserFunction(f => sqrt($x+1)-2);

	parserFunction("f(x)" => "sqrt(x+1)-2");

	parserFunction("f(x,y)" => "sqrt(x*y)");

The first parameter to parserFunction is the name of the function
or the name with its argument list.  In the first case, the
names of the variables are taken from the formula for the
function, and are listed in alphabetical order.

The second argument is the formula used to compute the value
of the function.  It can be either a string or a Parser Formula
object.

=cut

loadMacros('MathObjects.pl');

sub _parserFunction_init {parserFunction::Init()}; # don't reload this file
#
#  The package that will manage user-defined functions
#
package parserFunction;
our @ISA = qw(Parser::Function);

sub Init {
  main::PG_restricted_eval('sub parserFunction {parserFunction->Create(@_)}');
}

sub Create {
  my $self = shift; my $name = shift; my $formula = shift;
  my $context = (Value::isContext($_[0]) ? shift : Value->context);
  my @argNames; my @argTypes; my @newVars;
  #
  #  Look for argument names for the function
  #   (check that the arguments are ok, and temporarily
  #    add in any variables that are not already there)
  #
  if ($name =~ m/^([a-z0-9]+)\(\s*(.*?)\s*\)$/i) {
    $name = $1; my $args = $2;
    @argNames = split(/\s*,\s*/,$args);
    foreach my $x (@argNames) {
      Value::Error("Illegal variable name '%s'",$x) if $x =~ m/[^a-z]/i;
      unless ($context->{variables}{$x}) {
	$context->variables->add($x=>'Real');
	push(@newVars,$x);
      }
    }
  } else {
    Value::Error("Illegal function name '%s'",$name)
      if $name =~ m/[^a-z0-9]/i;
  }
  #
  #  Create the formula and get its arguments and types
  #
  $formula = $context->Package("Formula")->new($context,$formula) unless Value::isFormula($formula);
  @argNames = main::lex_sort(keys(%{$formula->{variables}})) unless scalar(@argNames);
  foreach my $x (@argNames) {push(@argTypes,$context->{variables}{$x}{type})}
  #
  #  Add the function to the context and create the perl function
  #
  $context->functions->add(
    $name => {
      (length($name) == 1? (TeX=>$name): ()),
      @_, class => 'parserFunction', argCount => scalar(@argNames),
      argNames => [@argNames], argTypes => [@argTypes],
      function => $formula->perlFunction(undef,[@argNames]),
      formula => $formula, type => $formula->typeRef,
    }
  );
  main::PG_restricted_eval("sub main::$name {Parser::Function->call('$name',\@_)}");
  $context->variables->remove(@newVars) if scalar(@newVars);
}

#
#  Check that there are the right number of arguments
#  and they are of the right type.
#
sub _check {
  my $self = shift; my $name = $self->{name};
  return if $self->checkArgCount($self->{def}{argCount});
  my @argTypes = @{$self->{def}{argTypes}}; my $n = 0;
  foreach my $x (@{$self->{params}}) {
    my $atype = shift(@argTypes); $n++;
    $self->Error("The %s argument for '%s' should be of type %s",
		 NameForNumber($n),$name,$atype->{name})
      unless (Parser::Item::typeMatch($atype,$x->{type}));
  }
  $self->{type} = $self->{def}{type};
}

#
#  Call the function stored in the definition
#
sub _eval {
  my $self = shift; my $name = $self->{name};
  &{$self->{def}{function}}(@_);
}

#
#  Check the arguments and compute the result.
#
sub _call {
  my $self = shift; my $name = shift;
  my $def = Value->context->{functions}{$name};
  &{$def->{function}}(@_);
}

=head2 ($Function)->D

 #
 #  Compute the derivative of (single-variable) functions
 #    using the chain rule.
 #

=cut

sub D {
  my $self = shift; my $def = $self->{def};
  $self->Error("Can't differentiate function '%s'",$self->{name})
    unless $def->{argCount} == 1;
  my $x = $def->{argNames}[0];
  my $Df = $def->{formula}->D($x);
  my $g = $self->{params}[0];
  return (($Df->substitute($x=>$g))*($g->D(@_)))->{tree}->reduce;
}

=head3 NameForNumber($number)

#
#  Get the name for a number
#

=cut

sub NameForNumber {
  my $n = shift;
  my $name =  ('zeroth','first','second','third','fourth','fifth',
               'sixth','seventh','eighth','ninth','tenth')[$n];
  $name = "$n-th" if ($n > 10);
  return $name;
}

1;
