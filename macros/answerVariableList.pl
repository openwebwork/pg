loadMacros('Parser.pl');

sub _answerVariableList_init {}; # don't reload this file

######################################################################
#
#  This answer checker compares the student answer to a list of
#  variable names (so, for example, you can ask for what values a
#  given function depends on).
#
#  Use addVariables() to create the list of variables that from which
#  the student can choose, and then use variable_cmp() to generate the
#  answer checker.  If the formula passed to variable_cmp contains
#  parentheses around the list, then the student's answer must as
#  well.
#
#  You can also include additional parameters to variable_cmp.  These
#  can be any of the flags appropriate for List() answer checker.
#
#  Usage examples:
#
#	addVariables('x','y','z');
#	ANS(variable_cmp("(x,y)"));
#
#	addVariables('x','y','z','s','t,);
#	ANS(variable_cmp("s,t"));
#       
#	addVariables('x','y','z');
#	ANS(variable_cmp("(x)",showHints=>0,showLengthHints=>0));
#

#
#  A new context for variable lists
#
$context{VariableList} = Parser::Context->new(
  operators => {',' => Context()->operators->get(',')},
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
  },
);
Context("VariableList");

#
#  A shell that calls Formula()->cmp with the right defaults
#
sub variable_cmp {
  Value::Formula->new(shift)->cmp(
    ordered => 1,
    entry_type =>'a variable',
    list_type => 'a list',
    @_
  );
}

#
#  Handy routine to set up variables
#
sub addVariables {
  my $context = Context();
  foreach my $v (@_) {$context->variables->add($v=>'Real')}
}

1;
