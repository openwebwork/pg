################################################################################
# WeBWorK Online Homework Delivery System
# Copyright � 2000-2015 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/parserWordCompletion.pl,v 1.0 2015/11/25 23:28:44 paultpearson Exp $
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

parserWordCompletion.pl

=head1 DESCRIPTION

Provides free response, fill in the blank questions with interactive help.  
As a student types their answer into the answer blank, jQuery's 
autocomplete feature generates a drop-down list of allowable answers 
that match what has already been typed.  When the student presses
the "Check Answers" or "Submit Answers" button, jQuery generates a
warning message if the student answer is not one of the allowable 
answers.  Choices in the drop-down list and the correct answer are 
specified by the problem author.  WordCompletion objects are compatible 
with Value objects, and in particular, can be used with MultiAnswer 
objects.

To create a WordCompletion object, use

	$w = WordCompletion([choices,...],correct);

where "choices" are the strings for the allowable answers in the 
drop-down list and "correct" is the correct answer from the list.

To insert the WordCompletion into the problem text, use

	BEGIN_TEXT
	\{ $w->ans_rule(40) \}
	END_TEXT

You can explicitly list all of the choices using 

	\{ $w->choices_text \}

for a comma separated list of the choices (inline, text style) and

	\{ $w->choices_list \}

for an unordered list (display style).  Use 

	ANS( $wb->cmp );

to get the answer checker for the WordCompletion object.  Note: the way
to construct and use WordCompletion objects is exactly the same as 
PopUp objects (see parserPopUp.pl), and you can use C<menu> instead of
C<ans_rule>.

You can use the WordCompletion object in MultiAnswer objects.  This is
the reason for the WordCompletion's ans_rule method (since that is what
MultiAnswer calls to get answer rules).

=head1 AUTHOR

Paul Pearson (Hope College Mathematics Department)

(Davide Cervone wrote parserPopUp.pl, which served as a template
for parserWordCompletion.pl.)

=cut

loadMacros("MathObjects.pl");

sub _parserWordCompletion_init { parser::WordCompletion::Init(); }

package parser::WordCompletion;
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
  $context->{name} = "WordCompletion";
  $context->parens->clear();
  $context->variables->clear();
  $context->constants->clear();
  $context->operators->clear();
  $context->functions->clear();
  $context->strings->clear();
  $context->{pattern}{number} = "^\$";
  $context->variables->{patterns} = {};
  $context->strings->{patterns}{".*"} = [-20,'str'];
  $context->{parser}{String} = "parser::WordCompletion::String";
  $context->update;
  main::PG_restricted_eval('sub WordCompletion {parser::WordCompletion->new(@_)}');
}

#
#  Create a new WordCompletion object
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  shift if Value::isContext($_[0]); # remove context, if given (it is not used)
  my $choices = shift; my $value = shift;
  Value::Error("A WordCompletion's first argument should be a list of menu items")
    unless ref($choices) eq 'ARRAY';
  Value::Error("A WordCompletion's second argument should be the correct menu choice")
    unless defined($value) && $value ne "";
  my %choice; map {$choice{$_} = 1} @$choices;
  Value::Error("The correct choice must be one of the WordCompletion menu items")
    unless $choice{$value};
  #warn join ', ' , @$choices;
  $self = bless {data => [$value], context => $context, choices => $choices }, $class;
  return $self;
}

sub menu {
    my $self = shift;
    my $size = shift || 20;
    my $name = shift;

    my $list = $self->{choices};
    my $list_string = join ',', map { qq/"$_"/ } @{$list};
    my $invalid_input_msg = qq(" is not a valid answer.\\n\\nPlease choose a valid answer from the list of allowable matching answers that appears when you type your answer into the answer blank.  Type slowly and pause between keystrokes to ensure that the drop-down list appears.\\n\\nNote: this special feature is enabled for this WeBWorK problem, but it is not available in all WeBWorK problems.");

    # generate new answer blank name used both by jQuery and creating the ans_rule
    #
    $name = main::NEW_ANS_NAME() unless $name;

    # insert jQuery
    #
    main::POST_HEADER_TEXT(main::MODES(TeX=>"", HTML=>qq(
    <!-- jQuery script to enable autocompletion drop-down menu -->  
    <script>
    \$(function() {
        var allowed = [ $list_string ]; // create a JavaScript array of allowed choices.
        \$( "#$name" ).autocomplete({ source: allowed }); // apply jQuery autocomplete to the answer blank using the allowed choices.

        var itemFound = false; // boolean to record whether the student answer is among the allowed choices
        var student = \$( "#$name" ).val(); // get the student answer from the answer blank using jQuery.
        for (i = 0, len = allowed.length; i < len; i++) { // Loop through the allowed choices and see if the student answer agrees with any of them
            if (allowed[i].toLowerCase() === student.toLowerCase()) {
                itemFound = true; // If the student answer agrees with an allowed answer, set this boolean to true.
            }
        }
        if (itemFound == false && student.length > 0) { // Warn the student when their answer is not allowed.
            alert( '"' + student + '"' + $invalid_input_msg); // JavaScript alert that tells the student which answer was not allowed.
        }
    });
    </script>
    )));

    # create the answer rule
    #
    main::NAMED_ANS_RULE($name,$size);

} # end menu

sub choices_text {
    my $self = shift;
    my $list = $self->{choices};
    my $output = join ', ', map { qq/$_/ } @{$list};
    return $output;
}

sub choices_list {
    my $self = shift;
    my $list = $self->{choices};
    my $output = '';

    if ($main::displayMode eq "TeX") {
        $output = join "\n", map { qq/\\item $_/ } @{$list};
        return "\\begin{itemize}\n" . $output . "\\end{itemize}\n";
    } else { # HTML mode
        $output = join " ", map { qq/<li>$_<\/li>/ } @{$list};
        return "<ul> " . $output . " </ul>";
    }
    return $output;

} # end choices_list

##################################################
#
#  Answer rule is the menu list (for compatibility with parserMultiAnswer)
# Use alternates given below with older parserMultiAnswer.pl versions

sub ans_rule {shift->menu(0,'',@_)}  # sub ans_rule {shift->menu(@_)} 
sub named_ans_rule {shift->menu(0,@_)} # sub named_ans_rule {shift->menu(@_)}
sub named_ans_rule_extension {shift->menu(1,@_)} # sub named_ans_rule_extension {shift->menu(@_)}


##################################################
#
#  Replacement for Parser::String that takes the
#  complete parse string as its value.  (To make ->cmp work.)
#
package parser::WordCompletion::String;
our @ISA = ('Parser::String');

sub new {
  my $self = shift;
  my ($equation,$value,$ref) = @_;
  $value = $equation->{string};
  $self->SUPER::new($equation,$value,$ref);
}

##################################################


1;
