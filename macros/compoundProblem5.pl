################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2014 The WeBWorK Project, http://openwebwork.sf.net/
# $$
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

compoundProblem5.pl - Provides support for multi-part problems where
                      later parts are not visible until earlier parts
                      are completed correctly.

=head1 DESCRIPTION

This file defines a C<Scaffold()> macro that creates the structure
needed to manage scaffolded problems.  The sections are then defined
using C<DISPLAY_SECTION()> or C<DISPLAY_PGML_SECTION()> calls
surrounding the text of the sections.  These keep track of the answers
in each section so that the system knows when one section is complete
and the next is to be made available.  To make that work, use
C<SECTION_ANS()> and C<SECTION_NAMED_ANS()> rather than C<ANS()> and
C<NAMED_ANS()> to assign answer checkers to answer blanks.  Solutions
can be provided for each section using the C<SECTION_SOLUTION()> or
C<SECTION_PGML_SOLUTION()> macros.  At the end of the problem, use
C<PROCESS_SECTIONS()> to finalize all the sections.

Here is a sample:

	loadMacros("compoundProblem5.pl");
	
	$scaffold = Scaffold();   # create the scaffold
	Context("Numeric");
	
	##########################################
	#  Section 1
	##########################################
	
	$f = Compute("x^2-1");
	
	Context()->texStrings;
	DISPLAY_SECTION("Section 1: The equation",<<'END_SECTION');
	  Enter the function \($f\): \{ SECTION_ANS($f->cmp); $f->ans_rule(10) \}
	END_SECTION
	Context()->normalStrings;
	
	##########################################
	#  Section 2
	##########################################
	
	$x = Compute("sqrt(3)/2");
	
	DISPLAY_SECTION("Section 2: The number",<<'END_SECTION');
	  What is \(\sin(\pi/3)\)? \{ SECTION_ANS($x->cmp); $x->ans_rule \}
	END_SECTION
	
	##########################################
	
	PROCESS_SCAFFOLD();

The C<DISPLAY_SECTION()> and C<DISPLAY_PGML_SECTION()> macros can
accept optional arguments by replacing the title with an array
reference that consists of the title followed by the options.  For
example, to force a section to always be displayed, you could use

    DISPLAY_SECTION(["Part 2: Always Open", canshow => "1"],<<'END_SECTION');
    ...
    END_SECTION

It is also possible to pass a HASH reference as the first argument:

    DISPLAY_SECTION({name => "Part 2: Always Open", canshow => "1"},<<'END_SECTION');
    ...
    END_SECTION

Here you must specify the C<name> option in order to give the section
its title.

The possible options are the following:

=over

=item C<S<< iscorrect => condition >>>

This gives the condition to use to tell if the section is fully
correct.  It is a string that is evaluated and should return 0 or 1
(or true or false) to indicate if the section is correct or not.  It
can also be a reference to a subroutine that is called with a pointer
to the section object whose return value should be 0 or 1.

In the past, the problem author had to supply this option in order to
tell which answers belong to this section, but this version of the
scaffolding macros handles that automatically, so you only need to
provide it if you want to override the default.

The C<Scaffold->requireCorrect()> function is provided to allow you
to check if the given answers are checked.  You pass it a list of
integers representing the answer blanks that you want to be correct.
Here, 1 represents the first answer blank, 2 the next one, and so on.

=item C<S<< canshow => condition >>>

This gives the condition to use to tell if the student is allowed to
open this section.  It is a string that is evaluated and should return 0 or 1
(or true or false) to indicate if the section can ope or not.  It
can also be a reference to a subroutine that is called with a pointer
to the section object whose return value should be 0 or 1.

In the past, the problem author had to supply this option in order to
tell which answers need to be correct in order for this section to be
openable, but this version of the scaffolding macros handles that
automatically, so you only need to provide it if you want to override
the default.

The C<Scaffold->requireCorrect()> function is provided to allow you to
check if the given answers are checked.  You pass it a list of
integers representing the answer blanks that you want to be correct.
Here, 1 represents the first answer blank, 2 the next one, and so on.

=item C<S<< name => "title" >>>

This is the title of the section as it should appear in the colored
title area of the section.

=item C<S<< PGML => 0 or 1 >>>

This indicates whether the text of the section is PGML text, or text
suitable for use in C<BEGIN_TEXT/END_TEXT>.  It is set automatically
by the C<DISPLAY_PGML_SECTION()> macro.

=back

Within the text of the section, you can use C<ANS()> as you would
normally to obtain answer checkers.  E.g.,

    $r = Real(2);
    DISPLAY_SECTION("Part 1",<<'END_SECTION');
    \(1 + 1\) = \{ANS($r->cmp); $r->ans_rule(5)\}
    END_SECTION

If you want to assign answer checkers after the section is created,
you must use C<SECTION_ANS()> or C<SECTION_NAMED_ANS()> to do so.  E.g.,

    $r = Real(2);
    DISPLAY_SECTION("Part 1",<<'END_SECTION');
    \(1 + 1\) = \{$r->ans_rule(5)\}
    END_SECTION
    SECTION_ANS($r->cmp);

If you want a solution for a section, use C<SECTION_SOLUTION()> or
C<SECTION_PGML_SOLUTION()> to create it.  E.g.,

    $r = Real(2);
    DISPLAY_SECTION("Part 1",<<'END_SECTION');
    \(1 + 1\) = \{ANS($r->cmp); $r->ans_rule(5)\}
    END_SECTION
    
    SECTION_SOLUTION(<<'END_SOLUTION');
    When you add 1 to 1 you get 2.
    END_SOLUTION

Normally, a solution will be tied to the section that preceeded it,
but if you want to put all your solutions at the end, for example, you
can pass options the solution macros that tell it the section to
attach to:

    $r1 = Real(2);
    DISPLAY_SECTION("Part 1",<<'END_SECTION');
    \(1 + 1\) = \{ANS($r1->cmp); $r1->ans_rule(5)\}
    END_SECTION
    
    $r2 = Real(4);
    DISPLAY_SECTION("Part 1",<<'END_SECTION');
    \(2\times 2\) = \{ANS($r2->cmp); $r2->ans_rule(5)\}
    END_SECTION
    
    SECTION_SOLUTION({section => 1},<<'END_SOLUTION')
    When you add 1 to 1 you get 2.
    END_SOLUTION
    
    SECTION_SOLUTION({section => 2},<<'END_SOLUTION')
    When you multiply 2 by 2 you get 4.
    END_SOLUTION

At the bottom of your problem file you should use the command

    PROCESS_SCAFFOLD();

so that the contents of the scaffold will be properly displayed.

=cut

sub _compoundProblem5_init {};   # don't reload this file

#
#  Set up some styles and the jQuery calls for opening and closing the scaffolds.
#
HEADER_TEXT(<<'END_HEADER_TEXT');

<style type="text/css">

.section-li {list-style: none}          /* don't show bullets */
.section-li > div {padding:0 .5em;}     /* move the contents away from the edges */
.section-li > h3 > .ui-icon {
  display: inline-block;                /* make the triangle be on the same line as the title */
  margin: 3px 1px;                      /* adjust its position slightly */
  vertical-align: -5px;
}

.canshow   {background:yellow;}
.iscorrect {background:lightgreen;}

/*.cannotshow {background:#e66; }*/
/*.iswrong {background-color:red;}*/
/*.notanswered {}*/
/*.isclosed{ {background-color: #000; display:none;}*/

</style>


<script language="javascript">

$.fn.canshow = function() {
   $(this).addClass("canshow ui-accordion-header ui-helper-reset ui-state-default ui-corner-top ui-corner-bottom")
   .hover(function() { $(this).toggleClass("ui-state-hover"); })
   .prepend('<span class="ui-icon ui-icon-triangle-1-e"></span>')
   .click(function() {
     if ($(this).hasClass("ui-accordion-header-active")) {
       var THIS = this;
       $(this)
         .toggleClass("ui-accordion-header-active ui-state-active ui-state-default")
         .find("> .ui-icon").toggleClass("ui-icon-triangle-1-e ui-icon-triangle-1-s").end()
         .next().slideToggle(400,function () {$(THIS).toggleClass("ui-corner-bottom")});
     } else {
       $(this)
         .toggleClass("ui-accordion-header-active ui-state-active ui-state-default ui-corner-bottom")
         .find("> .ui-icon").toggleClass("ui-icon-triangle-1-e ui-icon-triangle-1-s").end()
         .next().slideToggle();
     }
     return false;
   })
   .next()
     .addClass("ui-accordion-content ui-helper-reset ui-widget-content ui-corner-bottom")
     .hide();
};
$.fn.cannotshow = function() {
   $(this).addClass("cannotshow ui-accordion-header ui-helper-reset ui-state-default ui-corner-top ui-corner-bottom")
   .hover(function() { $(this).toggleClass("ui-state-hover"); })
   .next()
     .addClass("ui-accordion-content ui-helper-reset ui-widget-content ui-corner-bottom")
     .hide();
};
$.fn.openSection = function() {
   $(this)
     .toggleClass("ui-accordion-header-active ui-state-active ui-state-default ui-corner-bottom")
     .find("> .ui-icon").toggleClass("ui-icon-triangle-1-e ui-icon-triangle-1-s").end()
     .next().slideToggle();
   return false;
}

</script>
END_HEADER_TEXT

#
#  The Scaffoling package
#
package Scaffold;
our @ISA = qw(PGcore);

our $scaffold;  # the active scaffold (set by Scaffold() below)
our $isInstructor = ($envir{effectivePermissionLevel} >= $envir{ALWAYS_SHOW_SOLUTION_PERMISSION_LEVEL});

my $PG_ANSWERS_HASH = $main::PG->{PG_ANSWERS_HASH};  # where PG stores answer evaluators

#
#  Create a new Scaffold object
#
sub new {
    my $class = shift;
    my $self = bless {
	sections => {},
        current_section => 0,
	ans_names => [],
	scores => [],
    }, $class;
    return $self;
}

#
#  Access scores (grades).  These are set using
#  the PROCESS_ANSWERS method below.
#
sub scores {
    my $self = shift;
    $self->{scores};
}

#
#  Add answer evaluators to a section
#   If the section is already displayed ($section->{section_answers} exists), 
#      Get the answer labels and add them to the scaffold and section
#   Otherwise we pick them up in the new_answers() call.
#
sub ans_evaluators {
    my $self = shift;
    my $section = $self->{sections}{$self->{current_section}};
    if ($section->{section_answers}) {
        my $count = $main::PG->{unlabeled_answer_eval_count};      # Pitty that we have to grab this by hand
	foreach my $evaluator (@_) {
	    my $name = main::ANS_NUM_TO_NAME(++$count);
	    push(@{$self->{ans_names}},$name);
	    push(@{$section->{section_answers}},$name);
	}
    }
}
sub named_ans_evaluators {
    my $self = shift;
    my $section = $self->{sections}{$self->{current_section}};
    if ($section->{section_answers}) {
        while (@_) {
	    my $name = shift; my $evaluator = shift;
	    push(@{$self->{ans_names}},$name);
	    push(@{$section->{section_answers}},$name);
	}
    }
}


###########################################
#
#  Create a displayed section.
#    Pass it the name of the section and the contents,
#    or use [$name,options] or {name => ..., options}
#    as the first argument.
#
#  The "section" option defaults to the next section number.
#  The "iscorrect" option defaults to checking the answers
#    given in this section.
#  The "canshow" option defaults to checking if the user
#    is an instructor or if the answers in all
#    previous sections are correct.
#
#  The data for a section includes the section number and options,
#  plus the names of the answer checkers from the previous sections,
#  the names of the checkers for this section, and answer checker
#  count from before and after this section (used for highlighting
#  the results table), and the rendered text for the section.
#
sub DISPLAY_SECTION {
     my $self= shift;
     my $options = shift;
     $options = {name => shift(@$options), @$options} if ref($options) eq 'ARRAY';
     $options = {name => $options} unless ref($options) eq 'HASH';
     $options->{iscorrect} = sub {$self->iscorrect(shift)} unless $options->{iscorrect};
     $options->{canshow}   = sub {$self->canshow(shift)}   unless $options->{canshow};
     my $text_string = shift;
     my $sectionNo = $options->{section} || ($self->{current_section}+1);
     $self->{current_section} = $sectionNo;
     my $sectionID = "DiSpLaY_SeCtIoN_$sectionNo";
     my $section = $self->{sections}{$sectionNo} = {};
     $section->{number} = $sectionNo;
     $section->{options} = $options;
     my @assigned = $self->assigned_answers;                         # the answer blanks with no evaluators
     $section->{previous_answers} = [@{$self->{ans_names}}];         # copy of current list of answers
     $section->{renderedtext} = ($options->{PGML} ? PGML::Format2($text_string) : main::EV3P($text_string));
     $section->{section_answers} = [$self->new_answers(@assigned)];  # new answers in this section
     push(@{$self->{ans_names}},@{$section->{section_answers}});     # add them to the answers in this scaffold
     main::TEXT("$sectionID"); # place holder, on a line by itself that will be replaced in process_section
     return "";
}

#
#  Display a section using PGML rather than BEGIN_TEXT/END_TEXT notation
#
sub DISPLAY_PGML_SECTION {
  my $self = shift;
  my $options = shift;
  $options = {name => shift(@$options), @$options} if ref($options) eq 'ARRAY';
  $options = {name => $options} unless ref($options) eq 'HASH';
  $options->{PGML} = 1;
  $self->DISPLAY_SECTION($options,@_);
}

#
#  Return a boolean array where a 1 means that answer blank has
#  an answer evaluator assigned to it and 0 means not.
#
sub assigned_answers {
    my $self = shift;
    my @answers = ();
    foreach my $name (keys %{$PG_ANSWERS_HASH}) {
      push(@answers,$PG_ANSWERS_HASH->{$name}->ans_eval ? 1 : 0);
    }
    return @answers;
}
#
#  Get the names of any of the original answer blanks that now have
#  evaluators attached.
#
sub new_answers {
    my $self = shift;
    my @assigned = @_;                  # 0 if previously unassigned, 1 if assigned
    my @answers = (); my $i = 0;
    foreach my $name (keys %{$PG_ANSWERS_HASH}) {
      push(@answers,$name) if $PG_ANSWERS_HASH->{$name}->ans_eval && !$assigned[$i];
      $i++;
    }
    return @answers;
}

#
#  When all the sections have been created and the answers checked,
#  the sections are processed to tell if they should be opened or not
#  and what color they should be.
#
sub process_section {
    my $self = shift;
    my $section = shift;
    my $sectionNo = $section->{number};
    my $options = $section->{options};
    my $name = $options->{name};

    #
    #  Process the iscorrect and canshow values and set the class
    #
    my $iscorrect = $self->process_check($section,$options->{iscorrect});
    my $canshow   = $self->process_check($section,$options->{canshow});
    my $iscorrect_class = 'notanswered';
    $iscorrect_class = ($iscorrect ? 'iscorrect' : 'iswrong') if defined($iscorrect);

    #
    #  Get the script to open or prevent the section from opening
    #
    my $action = $canshow ? "canshow()" : "cannotshow()";
    my $scriptpreamble = main::MODES(TeX=>'', HTML=>qq!<script>\$("#section$sectionNo").$action</script>!);
    my $renderedtext = $canshow ? $section->{renderedtext} : '' ;
    $renderedtext = $scriptpreamble . "\n" . $renderedtext;
    $renderedtext .= $section->{solution} if main::not_null($section->{solution});

    #
    #  Make the final version of the section's text
    #
    $section->{finalversion} = main::MODES(
      HTML=> qq!<li class="section-li">
         <h3 id="section$sectionNo" class="$iscorrect_class">Section: $name:</h3>
         <div><p>$renderedtext</p></div></li>
      !, TeX=>"\\par{\\bf Section: $name}\\par $renderedtext\\par"
    );
    ($iscorrect,$canshow);
}
#
#  Process an answer check.
#   If the check is code, call it on the given section,
#   Otherwise (a string), evaluate it and die if there are errors.
#   return the result.
#
sub process_check {
    my $self = shift; my $section = shift; my $check = shift;
    my ($result,$error);
    if (ref($check) eq "CODE") {
        $result = &$check($section);
    } else {
        ($result,$error) = main::PG_restricted_eval($check);
	die $error if $error;
    }
    return $result;
}

#
#  Call the answer evaluator on all answers, and record the scores
#  so that we can use them in iscorrect and canshow checks.
#
sub PROCESS_ANSWERS {
    my $self = shift;
    my %answers;
    my @debug_messages = ();
    my %options = @_;   # allow debug options for example.
    my $DEBUG_ON = 1 if defined $options{debug} and $options{debug} == 1;

    #
    #  MultiAnswer objects can set the answer hash score when the last answer is evaluated,
    #    so save the hashes and look up the scores after they have all been called.
    #  Essay answers never return as correct, so special case them, and provide a
    #    "scaffold_force" option in the AnswerHash that can be used to force Scaffold
    #    to consider the score to be 1 (bug in PGessaymacros.pl prevents us from using
    #    it for essay_cmp(), though).
    #
    foreach my $name (@{$self->{ans_names}}) {
        my $input = $main::inputs_ref->{$name};
	my $evaluator = $PG_ANSWERS_HASH->{$name}->ans_eval;
	Parser::Eval(sub {$answers{$name} = $evaluator->evaluate($input)}) if defined($input) && $input ne "";
	$answers{$name}{score} = 1
	    if $answers{$name} && (($answers{$name}{type}||"") eq "essay" || $answers{$name}{scaffold_force});
	$evaluator->{rh_ans}{ans_message} = ""; delete $evaluator->{rh_ans}{error_message};
    }
    $self->{scores} = {};
    foreach my $name (@{$self->{ans_names}}) {
        $self->{scores}{$name} = $answers{$name}{score} if $answers{$name};
	push(@debug_messages, "Scaffold:  scores $name = $self->{scores}{$name}") if $DEBUG_ON && $answers{$name};
    }
    main::DEBUG_MESSAGE(join("<br/>",@debug_messages)) if $DEBUG_ON;
}

#
#  Run through the output looking for sections, processing each as it
#  is found, replacing the temporary identification line with the
#  final result of processing the section.  Keep track of the first
#  incorrect section so that it can be opened when the page is displayed.
#
sub PROCESS_SECTIONS {
    my $self = shift;
    my $number; my $section; my @open = (); my $last_correct = 0;
    foreach my $line (@{$main::PG->{OUTPUT_ARRAY}}) {
        if ($line =~/^\s*DiSpLaY_SeCtIoN_(\d+)\s*$/) {
	    $number = $1; $section = $self->{sections}{$number};
	    main::WARN_MESSAGE("Can't find object for section $number") unless $section;
	    my ($iscorrect,$canshow) = $self->process_section($section);
	    push(@open,$number) unless scalar(@open) || $iscorrect; # first section that isn't correct;
	    $last_correct = $number if $iscorrect; # backward compatibility;
	    $line = $section->{finalversion};
	}
    }
    return $last_correct if $self->{oldstyle};
    push(@open,$number) unless scalar(@open);
    return @open;
}

#
#  Standard way of processing answers and sections,
#  leaving the usual one open.
#
sub PROCESS_SCAFFOLD {
    my $self = shift;
    $self->PROCESS_ANSWERS(@_);
    $self->openSections($self->PROCESS_SECTIONS());
}

#
#  Add CSS to dim the rows of the table that are not
#  in the open section.  (When a section is marked correct,
#  the next section will be opened, so the correct answers
#  will be dimmed, and the new section's blank rows will be
#  active.  That may be a downside to the dimming.)
#
sub HIDE_OTHER_RESULTS {
    my $self = shift;
    #
    #  Record the row for each answer evaluator
    #
    my %row; my $i = 2;
    foreach my $name (keys %{$PG_ANSWERS_HASH}) {$row{$name} = $i; $i++}; # record the rows for all answers
    #
    #  Mark which sections to show
    #
    my %show; map {$show{$_} = 1} @_;
    #
    #  Get the row numbers for the answers from OTHER sections
    #
    my @hide = ();
    foreach $i (keys %{$self->{sections}}) {
        push(@hide,map {$row{$_}} @{$self->{sections}{$i}{section_answers}}) if !$show{$i};
    }
    #
    #  Add styles that dim the hidden rows
    #
    my @styles = (map {".attemptResults > tbody > tr:nth-child($_) {opacity:.5}"} @hide);
    main::HEADER_TEXT("<style type=\"text/css\">\n".join("\n",@styles)."\n</style>\n");
}

#
#  Add a solution to a section.  The default section is the previously
#  defined one, but you can also specify a section to add to in the
#  options.
#
sub SECTION_SOLUTION {
    my $self = shift;
    my $options = (ref($_[0]) eq 'HASH' ? shift : {});
    my $sectionNo = $options->{section} || $self->{current_section};
    my $section = $self->{sections}{$sectionNo}; main::WARN_MESSAGE("Can't find section '$sectionNo'") unless $section;
    my $output = '';
    my $formatted_solution = main::solution($options->{PGML} ? PGML::Format2(join("",@_)) : main::EV3P(@_));
    if ($main::displayMode =~ /^HTML/ and $main::envir{use_knowls_for_solutions}) {
        $output = join($main::PAR, main::knowlLink(main::SOLUTION_HEADING(),
    	               value => main::escapeSolutionHTML($main::BR.$formatted_solution.$main::PAR),
    	               base64 => 1)) if $formatted_solution;
    } elsif ($main::displayMode =~ /TeX/) {
    	$output = join($main::PAR,main::SOLUTION_HEADING(),$formatted_solution,$main::PAR) if $formatted_solution;
    } else {
        $output = ("$main::PAR SOLUTION: ".$main::BR.$formatted_solution.$main::PAR) if $formatted_solution;
    }
    $section->{solution} = $output;
}
sub SECTION_PGML_SOLUTION {
    my $self = shift;
    my $options = (ref($_[0]) eq 'HASH' ? shift : {});
    $options->{PGML} = 1;
    $self->SECTION_SOLUTION($options,@_);
}

#
#  Add answers in the current section.
#
sub ANS {
    my $self = shift;
    $self->ans_evaluators(@_);
    main::ANS(@_);
}
sub NAMED_ANS {
    my $self = shift;
    $self->named_ans_evaluators(@_);
    main::NAMED_ANS(@_);
}

#
#  Service routine to check for whether all the answers in a section
#  are correct.  (Used as the default for the iscorrect option of a
#  section.)
#
sub iscorrect {
    my $self = shift; my $section = shift;
    $self->needsCorrect(@{$section->{section_answers}});
}
#
#  Service routine to check for whether all the previous answers in a
#  section are correct, or whether the user is an instructor.  (Used
#  as the default for the canshow option of a section.)
#
sub canshow {
    my $self = shift; my $section = shift;
    $isInstructor || $self->needsCorrect(@{$section->{previous_answers}});
}
#
#  Checks the scores to see if they are all correct (returns 1),
#  all are answered but at least one is wrong (returns 0), or
#  some are blank (returns undef).
#
sub needsCorrect {
    my $self = shift; my $result = 1;
    foreach my $name (@_) {
	return undef unless defined($self->{scores}{$name});  # indicates some answers are blank
	$result = 0 unless $self->{scores}{$name};
    }
    return $result;
}

#
#  Checks whether all the given answers are correct or not.
#  The arguments are either names of named answers blanks, or
#  numbers indicating the n-th unnamed answer blank.
#
#  This can be used in the iscorrect or canshow options for a
#  section in order to customize when it will be considered
#  correct or can be opened.
#
sub requireCorrect {
    my $self = shift;
    '$Scaffold::scaffold->needsCorrect('.
       join(",",map {$_ =~ /^\d+$/ ? main::ANS_NUM_TO_NAME($_) : $_} @_).
    ')';
}

#
#  Opens the given sections so they are open when the page loads.
#
sub openSections {
    my $self = shift; my $script = '';
    $self->HIDE_OTHER_RESULTS(@_);
    foreach my $s (@_) {$script .= qq!\$("#section$s").openSection()\n!;}
    main::TEXT(main::MODES(TeX=>'', HTML=>qq!<script>\n$script</script>!));
}


package main;

#
#  Syntactic sugar to make it easier to call these routines.  Note
#  that you can't use these if you want to have nested scaffolds, as
#  they rely on a global variable to store the active scaffold.
#
sub Scaffold              {$Scaffold::scaffold = Scaffold->new()}
sub DISPLAY_SECTION       {$Scaffold::scaffold->DISPLAY_SECTION(@_)}
sub DISPLAY_PGML_SECTION  {$Scaffold::scaffold->DISPLAY_PGML_SECTION(@_)}
sub SECTION_SOLUTION      {$Scaffold::scaffold->SECTION_SOLUTION(@_)}
sub SECTION_PGML_SOLUTION {$Scaffold::scaffold->SECTION_PGML_SOLUTION(@_)}
sub SECTION_ANS           {$Scaffold::scaffold->ANS(@_)}
sub SECTION_NAMED_ANS     {$Scaffold::scaffold->NAMED_ANS(@_)}
sub PROCESS_ANSWERS       {$Scaffold::scaffold->PROCESS_ANSWERS(@_)}
sub PROCESS_SECTIONS      {$Scaffold::scaffold->PROCESS_SECTIONS(@_)}
sub PROCESS_SCAFFOLD      {$Scaffold::scaffold->PROCESS_SCAFFOLD(@_)}

sub INITIALIZE_SCAFFOLD {$Scaffold::scaffold->{oldstyle} = 1}  # backward compatibility

1;

