################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/parserPopUp.pl,v 1.10 2009/06/25 23:28:44 gage Exp $
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

parserPopUp.pl - Pop-up menus compatible with Value objects.

=head1 DESCRIPTION

This file implements a pop-up menu object that is compatible
with Value objects, and in particular, with the MultiAnswer object.

To create a PopUp object, use

	$popup = PopUp([choices,...],correct);

where "choices" are the strings for the items in the popup menu,
and "correct" is the choice that is the correct answer for the
popup.

To insert the popup menu into the problem text, use

	BEGIN_TEXT
	\{$popup->menu\}
	END_TEXT

and then

	ANS($popup->cmp);

to get the answer checker for the popup.

You can use the PopUp menu object in MultiAnswer objects.  This is
the reason for the pop-up menu's ans_rule method (since that is what
MultiAnswer calls to get answer rules).

=cut

loadMacros('MathObjects.pl');

sub _parserPopUp_init {parser::PopUp::Init()}; # don't reload this file

#
#  The package that implements pop-up menus
#
package parser::PopUp;
our @ISA = qw(Value::String);
my $context;

#
#  Setup the context and the PopUp() command
#
sub Init {
  #
  # make a context in which arbitrary strings can be entered
  #
  $context = Parser::Context->getCopy("Numeric");
  $context->{name} = "PopUp";
  $context->parens->clear();
  $context->variables->clear();
  $context->constants->clear();
  $context->operators->clear();
  $context->functions->clear();
  $context->strings->clear();
  $context->{pattern}{number} = "^\$";
  $context->variables->{patterns} = {};
  $context->strings->{patterns}{".*"} = [-20,'str'];
  $context->{parser}{String} = "parser::PopUp::String";
  $context->update;
  main::PG_restricted_eval('sub PopUp {parser::PopUp->new(@_)}');
}

#
#  Create a new PopUp object
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  shift if Value::isContext($_[0]); # remove context, if given (it is not used)
  my $choices = shift; my $value = shift;
  Value::Error("A PopUp's first argument should be a list of menu items")
    unless ref($choices) eq 'ARRAY';
  Value::Error("A PopUp's second argument should be the correct menu choice")
    unless defined($value) && $value ne "";
  my %choice; map {$choice{$_} = 1} @$choices;
  Value::Error("The correct choice must be one of the PopUp menu items")
    unless $choice{$value};
  $self = bless {data => [$value], context => $context, choices => $choices}, $class;
  return $self;
}

#
#  Create the menu list
#
sub menu {
  my $self = shift;
  main::pop_up_list($self->{choices});
}

#
#  Answer rule is the menu list
#
sub ans_rule {shift->menu(@_)}

##################################################
#
#  Replacement for Parser::String that takes the
#  complete parse string as its value
#
package parser::PopUp::String;
our @ISA = ('Parser::String');

sub new {
  my $self = shift;
  my ($equation,$value,$ref) = @_;
  $value = $equation->{string};
  $self->SUPER::new($equation,$value,$ref);
}

##################################################

1;
