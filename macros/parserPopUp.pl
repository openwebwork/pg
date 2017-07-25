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

This file implements a pop-up menu object that is compatible with
MathObjects, and in particular, with the MultiAnswer object, and with
PGML.

To create a PopUp object, use

	$popup = PopUp([choices,...],correct);

where "choices" are the strings for the items in the popup menu,
and "correct" is the choice that is the correct answer for the
popup (or its index, with 0 being the first one).

By default, the choices are left in the order that you provide them,
but you can cause some or all of them to be ordered randomly by
enclosing those that should be randomized within a second set of
brackets.  For example

        $radio = PopUp(
                   [
                     "First Item",
                     ["Random 1","Random 2","Random 3"],
                     "Last Item"
                   ],
                   "Random 3"
                 );

will make a pop-up menu that has the first item always on top, the
next three ordered randomly, and the last item always on the bottom.
In this example

        $radio = PopUp([["Random 1","Random 2","Random 3"]],2);

all the entries are randomized, and the correct answer is "Random 3"
(the one with index 2 in the original, unrandomized list).  You can
have as many randomized groups, with as many static items in between,
as you want.

Note that pop-up menus can not contain mathematical notation, only
plain text.  This is because the PopUp object uses the browser's
native menus, and these can contain only text, not mathematics or
graphics.

To insert the pop-up menu into the problem text, use

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
our @ISA = ('Value::String');
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
  Value->Error("A PopUp's first argument should be a list of menu items")
    unless ref($choices) eq 'ARRAY';
  Value->Error("A PopUp's second argument should be the correct menu choice")
    unless defined($value) && $value ne "";
  $self = bless {data => [$value], context => $context, choices => $choices}, $class;
  $self->getChoiceOrder;
  my %choice; map {$choice{$_} = 1} @{$self->{choices}};
  if (!$choice{$value}) {
    my @order = map {ref($_) eq "ARRAY" ? @$_ : $_} @$choices;
    if ($value =~ m/^\d+$/ && $order[$value]) {$self->{data}[0] = $order[$value]}
      else {Value->Error("The correct choice must be one of the PopUp menu items")}
  }
  return $self;
}

#
#  Get the choices into the correct order (randomizing where requested)
#
sub getChoiceOrder {
  my $self = shift;
  my @choices = ();
  foreach my $choice (@{$self->{choices}}) {
    if (ref($choice) eq "ARRAY") {push(@choices,$self->randomOrder($choice))}
      else {push(@choices,$choice)}
  }
  $self->{choices} = \@choices;
}
sub randomOrder {
  my $self = shift; my $choices = shift;
  my %index = (map {$main::PG_random_generator->rand => $_} (0..scalar(@$choices)-1));
  return (map {$choices->[$index{$_}]} main::PGsort(sub {$_[0] lt $_[1]},keys %index));
}

#
#  Create the menu list
#
sub menu {shift->MENU(0,@_)}
sub MENU {
  my $self = shift; my $extend = shift; my $name = shift;
  my @list = @{$self->{choices}}; my $menu = "";
  $name = main::NEW_ANS_NAME() unless $name;
  my $answer_value = (defined($main::inputs_ref->{$name}) ? $main::inputs_ref->{$name} : '');
  my $label = main::generate_aria_label($name);
  if ($main::displayMode =~ m/^HTML/) {
    $menu = qq!<select class="pg-select" name="$name" id="$name" aria-label="$label" size="1">\n!;
    foreach my $item (@list) {
      my $selected = ($item eq $answer_value) ? " selected" : "";
      my $option = $self->quoteHTML($item,1);
      $menu .= qq!<option$selected value="$option" class="tex2jax_ignore">$option</option>\n!;
    };
    $menu .= "</select>";
  } elsif ($main::displayMode eq "TeX") {
    # if the total number of characters is not more than
    # 30 and not containing / or ] then we print out
    # the select as a string: [A/B/C]
    if (length(join('',@list)) < 25 &&
	!grep(/(\/|\[|\])/,@list)) {
      $menu = '['.join('/',map {$self->quoteTeX($_)} @list).']';
    } else {
      #otherwise we print a bulleted list
      $menu = '\par\vtop{\def\bitem{\hbox\bgroup\indent\strut\textbullet\ \ignorespaces}\let\eitem=\egroup';
      $menu = "\n".$menu."\n";
      foreach my $option (@list) {
	$menu .= '\bitem '.$self->quoteTeX($option)."\\eitem\n";
      }
      $menu .= '\vskip3pt}'."\n";
    }
  }
  main::RECORD_ANS_NAME($name,$answer_value) unless $extend;   # record answer name
  $menu;
}

#
#  Answer rule is the menu list
#
sub ans_rule {shift->MENU(0,'',@_)}
sub named_ans_rule {shift->MENU(0,@_)}
sub named_ans_rule_extension {shift->MENU(1,@_)}

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
