################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2012 The WeBWorK Project, http://openwebwork.sf.net/
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

parserFormulaAnyVar.pl - implements formulas that can be entered
                         using any variable (not necessarily the
                         same one used by the author).

=head1 DESCRIPTION

This file implements the FormulaAnyVar object, which lets you declare
a formula that uses any letter as its variable, and allows the student
to type the formula using any variable, not necessarily the same as
the one used in the professor's answer.  That way, if the correct
answer is 2x+1, the student could type 2k+1 or 2z+1, etc., and still
have it marked correct.  Note that the formula can only include a
single variable (since it would be difficult to decide how to match up
the variables between the student and professor's answers) if there
were more than one.

To use FormulaAnyVar objects, load this macro file at the
top of your problem:

	loadMacros("parserFormulaAnyVar.pl");

then create a formula as follows:

	$f = FormulaAnyVar("x sin(x) + 3x^2");

The FormulaAnyVar should work like any normal Formula, and in
particular, you use $f->cmp to get its answer checker.

	ANS($f->cmp);

Note that the FormulaAnyVar object creates its own private copy of the
current Context (so that it can add variables without affecting the
rest of the problem).  You should not notice this in general, but if
you need to access that context, use $f->{context}.  E.g.

	Context($f->{context});

would make the current context the one being used by the
FormulaAnyVar, while

	$f->{context}->variables->names

would return a list of the variables in the private context.

The name of the variable used in the FormulaAnyVar object is available
as

        $f->{x}

in case you want to use it in error messages, for example.

=cut

loadMacros("MathObjects.pl");

sub _parserFormulaAnyVar_init {FormulaAnyVar::Init()}

package FormulaAnyVar;
@ISA = ('Value::Formula');

sub Init {
  main::PG_restricted_eval('sub FormulaAnyVar {FormulaAnyVar->new(@_)}');
}

#
#  Create an instance of a FormulaAnyVar.
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  #
  #  Copy the context (so we can modify it) and
  #  replace the usual Variable object with our own.
  #  Remove the variables from it, and let them be
  #  created automatically as needed.
  #
  my $context = (Value::isContext($_[0]) ? shift : $self->context)->copy;
  $context->{parser}{Variable} = 'FormulaAnyVar::Variable';
  $context->variables->clear();
  #
  #  Create a formula from the user's input.
  #
  my $f = main::Formula($context,@_);
  return bless $f, $class;
}

##################################################
#
#  Implement comparison that first replaces the student
#  variable by the professor's (if they differ).
#
sub compare {
  my ($l,$r) = @_; my $self = $l; my $context = $self->context;
  $r = Value::makeValue($r,context=>$context) unless Value::isValue($r);
  #
  #  If constants aren't the same, substitute the professor's in the student answer.
  #
  $r = $r->substitute($r->{x}=>$l->{x}) unless $r->{x} eq $l->{x};
  $r = main::Formula($context,$r);
  return $l->SUPER::compare($r);
}

######################################################################
#
#  This class replaces the Parser::Variable class, and its job
#  is to look for new variables that aren't in the context,
#  and add them in.  This allows students to use ANY variable
#  they want, even a different one from the professor.  We check
#  that the student only used ONE variable, however.
#
package FormulaAnyVar::Variable;
our @ISA = ('Parser::Variable');

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $equation = shift; my $variables = $equation->{context}{variables};
  my ($name,$ref) = @_; my $def = $variables->{$name};
  #
  #  If the variable is not already in the context, add it
  #  Save the variable for future reference
  #
  if (!defined($def) && length($name) eq 1) {
    Value->Error("Your formula should include only one variable") if $equation->{x};
    $equation->{context}->variables->add($name => 'Real');
    $def = $variables->{$name};
  }
  $equation->{x} = $name;
  #
  #  Do the usual Variable stuff.
  #
  $self->SUPER::new($equation,$name,$ref);
}

1;
