################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2018 The WeBWorK Project, http://openwebwork.sf.net/
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

answerVariableList.pl - Creates answer checkers that compare the student's
answer to a list of variable names.

=head1 MACROS

=head2 variable_cmp

 ANS(variable_cmp($var_string, %options))

This answer checker compares the student answer to a list of
variable names (so, for example, you can ask for what values a
given function depends on).

Use addVariables() to create the list of variables that from which
the student can choose, and then use variable_cmp() to generate the
answer checker.  If the formula passed to variable_cmp contains
parentheses around the list, then the student's answer must as
well.

You can also include additional parameters to variable_cmp.  These
can be any of the flags appropriate for List() answer checker.

Usage examples:

	addVariables('x','y','z');
	ANS(variable_cmp("(x,y)"));

	addVariables('x','y','z','s','t,);
	ANS(variable_cmp("s,t"));

	addVariables('x','y','z');
	ANS(variable_cmp("(x)",showHints=>0,showLengthHints=>0));

=cut

loadMacros('MathObjects.pl');

sub _answerVariableList_init {
  #
  #  A new context for variable lists
  #
  $main::context{VariableList} = Parser::Context->new(
    operators => {',' => $Parser::Context::Default::context{Full}->operators->get(',')},
    lists => {'List'  => {class =>'Parser::List::List'}},
    parens => {
     '(' => {close => ')', type => 'List', formList => 1},
     'start' => {close => 'start', type => 'List', formList => 1,
                 removable => 1, emptyOK => 1, hidden => 1},
     'list'  => {type => 'List', hidden => 1},
    },
    flags => {
      NumberCheck => 
        sub {shift->Error("Entries in your list must be variable names")},
      formatStudentAnswer => 'evaluated',  # or 'parsed' or 'reduced'
    },
  );

  main::Context("VariableList");  ### FIXME:  probably should require author to set this explicitly.
}

sub variable_cmp {
  Value->Package("Formula")->new(shift)->cmp(
    ordered => 1,
    entry_type =>'a variable',
    list_type => 'a list',
    implicitList => 0,
    @_
  );
}

=head2 addVariables

 addVariables(@vars)

Adds each string in @vars as a varible to the current context.

=cut

sub addVariables {
  my $context = Context();
  foreach my $v (@_) {$context->variables->add($v=>'Real')}
}

1;

