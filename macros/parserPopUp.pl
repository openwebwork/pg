################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: webwork2/lib/WeBWorK.pm,v 1.100 2007/08/13 22:59:53 sh002i Exp $
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

loadMacros('MathObjects.pl','contextString.pl');

sub _parserPopUp_init {parserPopUp::Init()}; # don't reload this file

#
#  The package that implements pop-up menus
#
package parserPopUp;
our @ISA = qw(Value::String);

#
#  Setup the main:: namespace
#
sub Init {main::PG_restricted_eval('sub PopUp {parserPopUp->new(@_)}')}

#
#  Create a new PopUp object
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $choices = shift; my $value = shift;
  Value::Error("A PopUp's first argument should be a list of menu items")
    unless ref($choices) eq 'ARRAY';
  Value::Error("A PopUp's second argument should be the correct menu choice")
    unless defined($value) && $value ne "";
  my $context = Parser::Context->getCopy("String");
  $context->strings->add(map {$_=>{}} @{$choices});
  my $self = bless $context->Package("String")->new($context,$value)->with(choices => $choices), $class;
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

1;
