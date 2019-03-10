################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 20014 The WeBWorK Project, http://openwebwork.sf.net/
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

scaffold.pl - Provides support for multi-part problems where
              later parts are not visible until earlier parts
              are completed correctly.

=head1 DESCRIPTION

Scaffolding macros provide the ability to make a single problem file
contain multiple parts, where the later parts aren't visible to the
student until the earlier ones are completed.  The author has control
over which parts are allowed to be opened, and which are showing, but
does not have to keep track of what answer blanks go with which
sections (as was the case in the earlier compoundProblem macros). It
is even possible to have nested scaffolds within a single problem.

To use the scaffolding macros, include the macros into your problem

    loadMacros("scaffold.pl");

and then use C<Scaffold::Begin()> to start a scaffold problem and
C<Scaffold::End()> to end it.  In between, use
C<Section::Begin(title)> and C<Section::End()> around the sections of
your problem.  Within a section, use C<BEGIN_TEXT/END_TEXT> or
C<BEGIN_PGML/END_PGML> to create the text of the section as usual, and
C<ANS()> to assign answer checkers to the blanks that appear within
the section.  For example:

    Scaffold::Begin();
    
    Section::Begin("Part 1: The first part");
    BEGIN_TEXT
    This is the text for part 1.  \(1+1\) = \{ans_rule\}
    END_TEXT
    ANS(Real(2)->cmp);
    Section::End();
    
    Section::Begin("Part 2: The second part");
    BEGIN_TEXT
    This is text for the second part.  \(2*2\) = \{ans_rule\}
    END_TEXT
    ANS(Real(4)->cmp);
    Section::End();
    
    Scaffold::End();

You can include whatever code you need to between the
C<Section::Begin()> and C<Section::End()> calls, so you can create
variables, set the Context, perform computations, generate text
sections, and so on.  Whatever answer checkers are assigned within a
section are the ones that are used to decide when that section can be
opened by the student.  Any solutions created within a section become
part of that section, and will be made available from within that
section, when applicable.

A section is considered to be "correct" when all the answers contained
in it are correct.  Note that essay answers are treated specially, and
are always considered correct (when non-empty) for purposes of
determining when a section is correct.  You can also force a non-empty
answer blank to be considered correct by using the C<scaffold_force>
option on the answer checker.  For example:

    ANS(Real(123)->cmp(scaffold_force => 1));

would mean that this answer would not have to be correct for the
section to be considered correct.

Note that you can also create text (or even answer blanks and
checkers) between the sections, or before the first one, or after the
last one, if you wish.  That material would always be showing,
regardless of which sections are open. So, for example, you could put
a data table in the area before the first section, so that it would be
visible throughtout the problem, no matter which section the student
is working on.

The C<Scaffold::Begin()> function accepts optional parameters that
control the functioning of the scaffold as a whole.  The primary use
it to control when the sections can be opened by the student, and
which is currently open.  The following options are provided:

=over

=item C<S<< can_open => condition >>> 

This specifies when a section can be opened by the student.  The
C<condition> is either one of the strings C<"always">,
C<"when_previous_correct">, C<"first_incorrect">, C<"incorrect"> or
C<"never">, or is a reference to a subroutine that returns 0 or 1
depending on whether the section can be opened or not (the subroutine
is passed a reference to the section object).  The default value is
C<"when_previous_correct">, which means that all the correct sections
and the first section incorrect or empty blanks would be able to be
opened by the student.  The value C<"first_incorrect"> would mean that
correct sections can not be reopened, and only the first one that is
not fully correct can be, while C<"incorrect"> means that only
incorrect sections can be opened (so once a section is correct, it
can't be reopened).  The value C<"always"> means the student can
always open the section, and C<"never"> means that the section can
never be opened.

If answers are available (i.e., it is after the answer date), then the
C<after_AnswerDate_can_open> option (described below) is used instead
of this option.  If not and the user is a professor, then the
C<instructor_can_open> option (described below) is used instead.

=item C<S<< is_open => condition >>>

This is similar to the C<can_open> option above, but determines
whether the section will be open when the problem is displayed.  The
possible values are C<"always">, C<"incorrect">, C<"first_incorrect">,
C<"correct_or_first_incorrect">, C<"never">, or a reference to a
subroutine that returns 0 or 1 depending on whether the section should
be open or not (the subroutine is passed a reference to the section
object).  Note that a section will only open if the C<can_open>
condition is also met, so you do need to coordinate these two values.
The default is C<"first_incorrect">, which means that only the first
section with incorrect answers will be open when the problem is
displayed after answers are submitted (though the student may be abe
to open other sections afterward, depending on the value if C<can_open>.
The value C<"incorrect"> would mean that all incorrect or incomplete
sections are open (the student can see all future work that he or she
must complete) but correct sections are closed, while
C<"correct_or_first_incorrect"> would be the opposite: all correct
sections and the first incorrect one are opened while the later
sections are closed (the student can see the completed work, but not
the future sections).  As expected, C<"always"> would mean every
section that can be opened will be open, and C<"never"> means no
section is opened.

Hardcopy versions of the problem use the C<hardcopy_is_open> option
(described below).

=item C<S<< instructor_can_open => condition >>>

This provides the condition for when an instructor (as opposed to a
student) can open a section.  By default, this is set to C<"always">,
so that instructors can look at any section of the problem, but you
can set it to any value for C<can_open> above.  If you are an
instructor and want to test how a problem looks for a student, you can
set

    $Scaffold::isInstructor = 0;

temporarily while testing the problem.  Remember to remove that when
you are done, however.

=item C<S<< after_AnswerDate_can_open => condition >>>

This is similar to the C<can_open> option (described above), and is
used in place of it when the answers are available.  The default is
C<"always">.  That means that after the answer date, the student will
be able to open all the sections regardless of whether the answers are
correct or not.

=item C<S<< hardcopy_is_open => condition >>>

This is similar to the C<is_open> option (described above), and is
used in place of it when the problem appears in hardcopy output.  The
default is C<"always">, which means that any sections that can be open
will be open in hardcopy output.  This allows the student to see the
parts of the problem that are already complete, even if they don't
open when viewed on line.

=item C<S<< open_first_section => 0 or 1 >>>

This determines whether the initial section is open (when it can be).
With the default C<can_open> and C<is_open> settings, the first
section will be open automatically when the problem is first viewed,
but if you have material to read (or even answers to give) prior to
the first section, you might want the first section to be closed, and
have the student open it by hand before anwering the questions.  In
this case, set this value to 0 (it is 1 by default).

=back

Some useful configurations are:

    #
    #  The defaults:
    #    only the active section is open, but students can open
    #    previous correct sections if they want.
    #
    Scaffold::Begin(
      can_open => "when_previous_correct",
      is_open  => "first_incorrect"
    );
    
    #
    #  Sections stay open as the student works through
    #  the problem.
    #
    Scaffold::Begin(
      can_open => "when_previous_correct",
      is_open  => "correct_or_first_incorrect"
    );
    
    #
    #  Students work through the problem seeing only
    #  one section at a time, and can't go back to
    #  previous sections.
    #
    Scaffold::Begin(
      can_open => "first_incorrect",
      is_open  => "first_incorrect"
    );
    
    #
    #  Students can view and work on any section,
    #  but only the first incorrect one is shown initially.
    #
    Scaffold::Begin(
      can_open => "always",
      is_open  => "first_incorrect"
    );
    
    #
    #  Students see all the parts initially, but the
    #  sections close as the student gets them correct.
    #
    Scaffold::Begin(
      can_open => "always",
      is_open  => "incorrect"
    );
    
    #
    #  Students see all the parts initially, but the
    #  sections close as the student gets them correct,
    #  and can't be reopened.
    #
    Scaffold::Begin(
      can_open => "incorrect",
      is_open  => "incorrect"
    );

The C<Section::Begin()> macro also accepts the options C<can_open>,
C<is_open>, and C<instructor_can_open> described above.  This allows
you to override the defaults for a particular section.  In particular,
you can provide a subroutine that determines when the section can or
should be open.

Note that values like C<$showPartialCorrectAnswers> and the isntalled
grader are global to the whole problem, so can't be set individually
on a per section basis.  Also note that the answers aren't checked
until the end of the problem, so any changes you make to the
C<Context()> after a section is ended will still affect the context
within that section.

=cut

sub _scaffold_init {};   # don't reload this file

#
#  The Scaffoling package
#
package Scaffold;

our $isLibrary = ($main::envir{effectivePermissionLevel} eq "");  # Library and problem set detail pages don't set this
our $isInstructor = (
  $isLibrary || $main::envir{effectivePermissionLevel} >= $main::envir{ALWAYS_SHOW_SOLUTION_PERMISSION_LEVEL}
);
our $isHardcopy = ($main::displayMode eq "TeX");
our $isPTX = ($main::displayMode eq "PTX");
our $afterAnswerDate = (time() > $main::envir{answerDate});

our $scaffold;           # the active scaffold (set by Begin() below)
my  @scaffolds = ();     # array of nested scaffolds
my  $scaffold_no = 0;    # each scaffold gets a unique number

our $PG_ANSWERS_HASH = $main::PG->{PG_ANSWERS_HASH};  # where PG stores answer evaluators
our $PG_OUTPUT = $main::PG->{OUTPUT_ARRAY};           # where PG stores the TEXT() output

our $PREFIX = "$main::envir{QUIZ_PREFIX}Prob-$main::envir{questionNumber}";

#
#  Scaffold::Begin() is used to start a new scaffold section, passing
#  it any options that need to be overriden (e.g. is_open, can_open,
#  open_first_section, etc).
#
#  Problems can include more than one scaffold, if desired,
#  and they can be nested.
#
#    We save the current PG_OUTPUT, which will be put back durring
#    the Scaffold::End() call.  The sections use PG_OUTPUT to create
#    their own text, which is added to the $scaffold->{output}
#    during the Section::End() call.
#
sub Begin {
  my $self = Scaffold->new(@_);
  unshift(@scaffolds,$self); $scaffold = $self;
  $self->{previous_output} = [splice(@{$PG_OUTPUT},0)];  # get output and clear it without changing the array pointer
  $self->{output} = [];                                  # the contents of the scaffold
  return $self;
}

#
#  Scaffold::End() is used to end the scaffold.
#
#    This puts the scaffold into the page output
#    and opens the sections that should be open.
#    Then the next nested scaffold (if any) is poped off
#    the stack and returned.
#
sub End {
  Scaffold->Error("Scaffold::End() without a corresponding Scaffold::Begin") unless @scaffolds;
  Scaffold->Error("Scaffold ended with section was still open") if $self->{current_section};
  my $self = $scaffold;
  push(@{$self->{output}},splice(@$PG_OUTPUT,0));                      # collect any final non-section output
  $self->open_sections(@{$self->{open}});                              # make the open sections be displayed
  push(@$PG_OUTPUT,@{$self->{previous_output}},@{$self->{output}});    # put back original output and scaffold output
  delete $self->{previous_output}; delete $self->{output};             # don't need these any more
  shift(@scaffolds); $scaffold = $scaffolds[0];
  return $scaffold;
}

#
#  Report an error and die
#
sub Error {
  my $self = shift; my $error = shift;
  die $error;
}

#
#  Create a new Scaffold object.
#
#    Set the defaults for can_open, is_open, etc., but allow
#    the author to override them.
#
sub new {
  my $class = shift; $class = ref($class) if ref($class);
  my $self = bless {
    can_open => "when_previous_correct",
    instructor_can_open => "always",
    after_AnswerDate_can_open => "always",        # all sections can be opened after answer date
    is_open => "first_incorrect",
    hardcopy_is_open => "always",                 # open all possible sections in hardcopy
    open_first_section => 1,                      # 0 means don't open any sections initially
    @_,
    number => ++$scaffold_no,                     # the number for this section
    sections => {},                               # the sections within this scaffold
    section_no => 0,                              # the current section number
    ans_names => [],                              # the names of all answer blanks in this scaffold
    scores => {},                                 # the scores for the answers entered by the student
    open => [],                                   # the sections to open
  }, $class;
  return $self;
}

#
#  Add a section to the scaffold and give it a unique number (within
#  the scaffold).  Determine its label and save it as current_section
#  so that we know which section is active.
#
sub start_section {
  my $self = shift; my $section = shift;
  push(@{$self->{output}},splice(@{$PG_OUTPUT},0));        # get any non-section output that may have been added
  $self->{sections}{++$self->{section_no}} = $section;
  $self->{current_section} = $section;
  $section->{number} = $self->{section_no};
  $section->{label} = "${PREFIX}_SC-$self->{number}_SECT-$section->{number}";
  return $section;
}

#
#  Add the content from the current section into the scaffold's output
#  and remove the current_section (so we can tell that no sectionis open).
#
sub end_section {
  my $self = shift;
  push(@{$self->{output}},splice(@{$PG_OUTPUT},0));        # save the section output
  delete $self->{current_section};
}

#
#  Record the answers for a section, and evaluate them, if non-empty,
#  keeping the scores for future reference.
#
sub section_answers {
  my $self = shift;
  my %answers;
  #
  #  MultiAnswer objects can set the answer hash score when the last answer is evaluated,
  #    so save the hashes and look up the scores after they have all been called.
  #  Essay answers never return as correct, so special case them, and provide a
  #    "scaffold_force" option in the AnswerHash that can be used to force Scaffold
  #    to consider the score to be 1 (bug in PGessaymacros.pl prevents us from using
  #    it for essay_cmp(), though).
  #
  push(@{$self->{ans_names}},@_);
  foreach my $name (@_) {
    my $input = $main::inputs_ref->{$name};
    my $evaluator = $PG_ANSWERS_HASH->{$name}->ans_eval;
    Parser::Eval(sub {$answers{$name} = $evaluator->evaluate($input)}) if defined($input) && $input ne "";
    $answers{$name}{score} = 1
      if $answers{$name} && (($answers{$name}{type}||"") eq "essay" || $answers{$name}{"scaffold_force"});
    $evaluator->{rh_ans}{ans_message} = ""; delete $evaluator->{rh_ans}{error_message};
  }
  foreach my $name (@_) {$self->{scores}{$name} = $answers{$name}{score} if $answers{$name}}
}

#
#  Add the given sections to the list of sections to be openned
#  for this scaffold
#
sub is_open {
  my $self = shift;
  push(@{$self->{open}},map {$_->{number}} @_) if @_;
  return $self->{open};
}

#
#  Add the javascript to open the given sections
#  and hide the rows of the results table for other sections.
#
sub open_sections {
  my $self = shift;
  my @script = map {'$("#'.$self->{sections}{$_}{label}.'").opensection();'} @_;
  push(@{$self->{output}},main::MODES(TeX=>'', HTML=>"<script>\n".join("\n",@script)."\n</script>",PTX=>''));
  $self->hide_other_results(@_);
}

#
#  Add CSS to dim the rows of the table that are not in the open
#  section.  (When a section is marked correct, the next section will
#  be opened, so the correct answers will be dimmed, and the new
#  section's blank rows will be active.  That may be a downside to the
#  dimming.)
#
sub hide_other_results {
  my $self = shift;
  #
  #  Record the row for each answer evaluator, and
  #  mark which sections to show
  #
  my %row; my $i = 2;
  foreach my $name (keys %{$PG_ANSWERS_HASH}) {$row{$name} = $i; $i++}; # record the rows for all answers
  my %show; map {$show{$_} = 1} @_;
  #
  #  Get the row numbers for the answers from OTHER sections
  #
  my @hide = ();
  foreach $i (keys %{$self->{sections}}) {
    push(@hide,map {$row{$_}} @{$self->{sections}{$i}{ans_names}}) if !$show{$i};
  }
  #
  #  Add styles that dim the hidden rows
  #  (the other possibility would be to use display:none)
  #
  if (@hide) {
    my @styles = (map {".attemptResults > tbody > tr:nth-child($_) {opacity:.5}"} @hide);
    main::HEADER_TEXT("<style type=\"text/css\">\n".join("\n",@styles)."\n</style>\n");
  }
}

#
#  Check if a scaffold is completely correct.
#  (Must be called after the last section is ended.)
#
sub is_correct {
  my $self = shift; my $scores = $self->{scores};
  foreach my $name (@{$self->{ans_names}}) {return 0 unless ($scores->{$name}||0) >= 1}
  return 1;
}


package Section;

#
#  Shortcuts for Scaffold data
#
$PG_ANSWERS_HASH = $Scaffold::PG_ANSWERS_HASH;
$PG_OUTPUT = $Scaffold::PG_OUTPUT;


#
#  Section::Begin() is used to start a section in the scaffolding,
#  passing it the name of the section and any options (e.g., can_open,
#  is_open, etc.).
#
#    The section is added to the scaffold, and the names of the answer
#    blanks for previous sections are recorded, along with information
#    about the answer blanks that have evaluators assigned (so we can
#    see which answers belong to this section when it closes).
#
sub Begin {
  my $scaffold = $Scaffold::scaffold;
  Scaffold->Error("Sections must appear within a Scaffold") unless $scaffold;
  Scaffold->Error("Section::Begin() while a section is already open") if $scaffold->{current_section};
  my $self = $scaffold->start_section(Section->new(@_));
  $self->{name} = "Part $self->{number}:" unless $self->{name};
  $self->{previous_ans} = [@{$scaffold->{ans_names}}],      # copy of current list of answers in the scaffold
  $self->{assigned_ans} = [$self->assigned_ans],            # array indicating which answers have evaluators
  return $self;
}

#
#  Section::End() is used to end the active section.
#
#    We get the names of the answer blanks that are in this section,
#    then add the HTML around the section that is used by jQuery
#    for showing/hiding the section, and finally tell the scaffold
#    that the section is complete (it adds the content to its output).
#
sub End {
  my $scaffold = $Scaffold::scaffold;
  Scaffold->Error("Sections must appear within a Scaffold") unless $scaffold;
  Scaffold->Error("Section::End() without Section::Begin()") unless $scaffold->{current_section};
  my $self = $scaffold->{current_section};
  $self->{ans_names} = [$self->new_answers];
  $scaffold->section_answers(@{$self->{ans_names}});
  $self->add_container();
  $scaffold->end_section();
}

#
#  Create a new Section object.
#
#    It takes default values for can_open, is_open, etc.
#    from the active scaffold.  These can be overridden
#    by the author.
#
sub new {
  my $class = shift; $class = ref($class) if ref($class);
  my $name = shift; my $scaffold = $Scaffold::scaffold;
  my $self = bless {
    name => $name,
    can_open => $scaffold->{can_open},
    instructor_can_open => $scaffold->{instructor_can_open},
    after_AnswerDate_can_open => $scaffold->{after_AnswerDate_can_open},
    is_open => $scaffold->{is_open},
    hardcopy_is_open => $scaffold->{hardcopy_is_open},
    @_,
  }, $class;
  return $self;
}

#
#  Adds the necessary HTML around the content of the section.
#
#    First, determine the is_correct and can_open status and save them.
#    Then check if the section is to be openned, and if so, add it
#    to the open list of the scaffold.
#
#    The $PG_OUTPUT variable holds just the contents of this section,
#    so we unshift the openning tags onto the front, and push
#    the closing tags onto the back.  (This is added to the scaffold
#    output when $scaffold->end_section() is called.)
#
sub add_container {
  my $self = shift; my $scaffold = $Scaffold::scaffold;
  my $label = $self->{label};
  my ($iscorrect,$canopen,$isopen);

  $iscorrect = $self->{is_correct} = $self->is_correct;
  $canopen   = $self->{can_open}   = $self->can_open;
  $isopen    = $self->is_open;

  $scaffold->is_open($self) if $isopen;
  splice(@$PG_OUTPUT,0,scalar(@$PG_OUTPUT)) if !($canopen || $iscorrect || $Scaffold::isPTX) || (!$isopen && $Scaffold::isHardcopy);
  unshift(@$PG_OUTPUT,@{main::MODES(
    HTML => [
      '<div class="section-div">',
      '<h3 tabindex=0 id="'.$label.'" class="'.($iscorrect?"iscorrect":"iswrong").'">'.$self->{name}.'</h3>',
      '<div><p>',
      '<script>$("#'.$label.'").can'.($canopen?"":"not").'open()</script>',
    ],
    TeX => ["\\par{\\bf $self->{name}}\\par "],
    PTX => ["<stage>\n"],
  )});
  push(@$PG_OUTPUT,main::MODES(
    HTML => '</p></div></div>',
    TeX  => "\\par ",
    PTX => "<\/stage>\n",
  ));
}

#
#  Check if all the answers for this section are correct
#
sub is_correct {
  my $self = shift; my $scores = $Scaffold::scaffold->{scores};
  foreach my $name (@{$self->{ans_names}}) {return 0 unless ($scores->{$name}||0) >= 1}
  return 1;
}

#
#  Perform the can_open check for this section:
#    If the author supplied code, use it, otherwise use the routine from Section::can_open.
#
sub can_open {
  my $self = shift;
  return 1 if $Scaffold::isLibrary;          # always open in library browser and problem set details
  my $method = ($Scaffold::isInstructor ? $self->{instructor_can_open} : $self->{can_open});
  $method = $self->{after_AnswerDate_can_open} if $Scaffold::afterAnswerDate;
  $method = "Section::can_open::".$method unless ref($method) eq 'CODE';
  return &{$method}($self);
}

#
#  Peform the is_open check for this section:
#    If the author supplied code, use it, otherwise use the routine from Section::is_open.
#
sub is_open {
  my $self = shift;
  return 1 if $Scaffold::isLibrary;          # always open in library browser and problem set details
  return 0 unless $self->{can_open};         # only open ones that are allowed to be open
  my $method = $self->{is_open};
  $method = $self->{hardcopy_is_open} if $Scaffold::isHardcopy;
  $method = "Section::is_open::".$method unless ref($method) eq 'CODE';
  return &{$method}($self);
}

#
#  Return a boolean array where a 1 means that answer blank has
#  an answer evaluator assigned to it and 0 means not.
#
sub assigned_ans {
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
  my @assigned = @{$self->{assigned_ans}};     # 0 if previously unassigned, 1 if assigned
  my @answers = (); my $i = 0;
  foreach my $name (keys %{$PG_ANSWERS_HASH}) {
    push(@answers,$name) if $PG_ANSWERS_HASH->{$name}->ans_eval && !$assigned[$i];
    $i++;
  }
  delete $self->{assigned_ans};                # don't need these any more
  return @answers;
}


########################################################################
#
#  Implements the possible values for the can_open option for scaffolds
#  and sections
#
package Section::can_open;

#
#  Always can be openned
#
sub always {return 1}
#
#  Can be openned when all the answers from previous sections are correct
#
sub when_previous_correct {
  my $section = shift; my $scores = $Scaffold::scaffold->{scores};
  foreach my $name (@{$section->{previous_ans}}) {return 0 unless ($scores->{$name}||0) >= 1}
  return 1;
}
#
#  Can open when previous are correct but this one is not
#
sub first_incorrect {
  my $section = shift;
  return when_previous_correct($section) && !$section->{is_correct};
}
#
#  Can open when incorrect
#
sub incorrect {
  my $section = shift;
  return !$section->{is_correct}
}
#
#  Never can be openned
#
sub never {return 0}


########################################################################
#
#  Implements the possible values for the is_open option for scaffolds
#  and sections
#
package Section::is_open;

#
#  Every section is open that can be
#
sub always {return 1}
#
#  Every incorrect section is open that can be
#  (unless it is the first one, and everything is blank, and
#   the scaffold doesn't have open_first_section set)
#
sub incorrect {
  my $section = shift; my $scaffold = $Scaffold::scaffold;
  return 0 if $section->{is_correct};
  if (!$scaffold->{open_first_section}) {
    my $scores = $scaffold->{scores}; my $blank = 1;
    foreach my $name (@{$section->{ans_names}}) {$blank = 0 if defined $scores->{$name}}
    return 0 if $blank;
  }
  return 1;
}
#
#  The first incorrect section is open that can be
#
sub first_incorrect {
  my $section = shift;
  return Section::is_open::incorrect($section) && Section::can_open::when_previous_correct($section);
}
#
#  All correct sections and the first incorrect section
#  are open (that are allowed to be open)
#
sub correct_or_first_incorrect {
  my $section = shift;
  return 1 if $section->{is_correct} || Section::is_open::first_incorrect($section);
}
#
#  No sections are open
#
sub never {return 0}



package main;

#
#  Set up some styles and the jQuery calls for opening and closing the scaffolds.
#
TEXT(<<'END_HEADER_TEXT') if !($Scaffold::isHardcopy or $Scaffold::isPTX);  # should be HEADER_TEXT, but that gets lost in library browser

<style type="text/css">
.section-div > div {padding:0 .5em;}    /* move the contents away from the edges */
.section-div > h3 > .ui-icon {
  display: inline-block;                /* make the triangle be on the same line as the title */
  margin: 3px 1px;                      /* adjust its position slightly */
  vertical-align: -5px;
}
.section-div > h3 {
  color: #212121!important;
  border-color: #AAAAAA!important;
  font-weight: normal!important;
  font-style: normal!important;
}

.section-div > h3:focus {
    outline-style:solid;
    outline-color:#aaaa00;
    outline-width:2px;
}

.section-div > h3.ui-state-default {
  color: #555555!important;
}
.section-div > div.ui-accordion-content {
  background: #FAFAFA!important;
}
.canopen    {background:yellow!important;}
.iscorrect  {background:lightgreen!important;}
.cannotopen {
  background:#EEEEEE!important;
  padding: 3px 0px 3px 16px;        /* leave space that would have been triangle */
}
</style>

<script type="text/javascript">
$.fn.canopen = function() {
   $(this).addClass("canopen ui-accordion-header ui-helper-reset ui-state-default ui-corner-top ui-corner-bottom")
   .hover(function() { $(this).toggleClass("ui-state-hover"); })
   .prepend('<span class="ui-icon ui-icon-triangle-1-e"></span>')
   .on('keypress click', function(e) {
     if (e.type != 'click' && e.which != 13) {
       return true;
     }
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
$.fn.cannotopen = function() {
   $(this).addClass("cannotopen ui-accordion-header ui-helper-reset ui-state-default ui-corner-top ui-corner-bottom")
   .hover(function() { $(this).toggleClass("ui-state-hover"); })
   .next()
     .addClass("ui-accordion-content ui-helper-reset ui-widget-content ui-corner-bottom")
     .hide();
};
$.fn.opensection = function() {
   $(this)
     .toggleClass("ui-accordion-header-active ui-state-active ui-state-default ui-corner-bottom")
     .find("> .ui-icon").toggleClass("ui-icon-triangle-1-e ui-icon-triangle-1-s").end()
     .next().slideToggle();
   return false;
}
</script>
END_HEADER_TEXT


1;

