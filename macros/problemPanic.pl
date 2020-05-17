################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2009 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/problemPanic.pl,v 1.6 2010/04/27 02:00:37 dpvc Exp $
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

problemPanic.pl - Allow for a PANIC button that gives additional
                  hints, possibly costing some points.

=head1 DESCRIPTION

This file implements a mechanism for you to provide one or more "panic
button" that your students can use to get additional hints, at the
cost of a portion of their score.

To include the button, use the command Panic::Button command within a
BEGIN_TEXT/END_TEXT block.  E.g.,

    BEGIN_TEXT
    \{Panic::Button(label => "Request a Hint", penalty => .25)\}
    (you will lose 25% of your points if you do)
    END_TEXT

When the student presses the hint button, the button will not longer
be available, and the "panic level" will be increased.  This sets the
variable $panicked, which you can use to determine whether to include the
hints or not.  For example

    if ($panicked) {
      BEGIN_TEXT
        Hint:  You should factor the numerator and cancel
        one of the factors with the denominator.
      END_TEXT
    }

Note that you can create a "cascade" of hints by including a second
panic button in the hint received from the first button.  This will
set $panic to 2 (panic level 2) and you can use that to include the
second hint.

    if ($panicked) {
      BEGIN_TEXT
        Hint:  You should factor the numerator and cancel
        one of the factors with the denominator.
        $PAR
        \{Panic::Button(label => "Another Hint", penalty => .25)\}
        (costing an additional 25%)
      END_TEXT
      
      if ($panicked > 1) {
        BEGIN_TEXT
        Additional Hint: one of the factors is \(x+$a)\).
        END_TEXT
      }
    }

You can add more buttons in a similar way.  You can not have separate
buttons for separate hints that are NOT cascaded, however.  (That may
be possible in future versions.)

The Panic::Button command takes two optional parameters:

=over

=item S<C<< label => "text" >>>

Sets the text to use for the button.  The default is "Request a Hint".

=item S<C<< penalty => percent >>>

Specifies the number points to lose (as a number from 0 to 1) if this
hint is displayed.  When more than one panic button is used, the
penalties are cumulative.  That is, two penalties of .25 would produce
a total penalty of .5, so the student would lose half his points if
both hints were given.

=back

Once a hint is displayed, the panic button for that hint will no
longer be shown, and the hint will continue to be displayed as the
student submits new answers.

A professor will be given a "Reset problem hints" checkbox at the
bottom of the problem, and can use that to request that the panic
level be reset back to 0.  This also sets the score and the number of
attempts back to 0 as well, so this effectively resets the problem to
its original state.  This is intended for use primarily during problem
development, but can be used to allow a student to get full credit for
a problem even after he or she has asked for a hint.

To allow the grading penalties to work, you must include the command

    Panic::GradeWithPenalty();

in order to install the panic-button grader.  You should do this afer
setting the grader that you want to use for the problem itself, as the
panic grader will use the one that is installed at the time the
Panic::GradWithPenalty command is issued.

=cut

sub _problemPanic_init {Panic::Init()}

#
#  The packge to contain the routines and data for the Panic buttons
#
package Panic;

my $isTeX = 0;         # true in hardcopy mode
my $allowReset = 0;    # true if a professor is viewing the problem
my $buttonCount = 0;   # number of panic buttons displayed so far
my @penalty = (0);     # accummulated penalty values
my $grader;            # problem's original grader

#
#  Allow resets if permission level is high enough.
#  Look up the panic level and reset it if needed.
#  Save the panic level for the next time through.
#
sub Init {
  $main::permissionLevel = 0 unless defined $main::permissionLevel;
  $allowReset = $main::permissionLevel > $main::PRINT_FILE_NAMES_PERMISSION_LEVEL;
  $isTeX = ($main::displayMode eq 'TeX');
  unless ($isTeX) {
    $main::panicked = $main::inputs_ref->{_panicked} || 0;
    $main::panicked = 0 if $main::inputs_ref->{_panic_reset} && $allowReset;
    main::TEXT(qq!<input type="hidden" name="_panicked" id="_panicked" value="$main::panicked" />!);
    main::RECORD_FORM_LABEL("_panicked");
  }
}

#
#  Place a panic button on the page, if it's not hardcopy mode and its not at the wrong level.
#  You can set the label, the penalty for taking this hint, and the panic level for this button.
#  Use submitAnswers if it is before the due date, and checkAnswers otherwise.
#
sub Button {
  $buttonCount++;
  my %options = (
    label => "Request a Hint",
    level => $buttonCount,
    penalty => 0,
    @_
  );
  my $label = $options{label};
  my $level = $options{level};
  $penalty[$buttonCount] = $penalty[$buttonCount-1] + $options{penalty};
  $penalty[$buttonCount] = 1 if $penalty[$buttonCount] > 1;
  return if $isTeX || $main::panicked >= $level;
  my $time = time();
  my $name = ($main::openDate <= $time && $time <= $main::dueDate ? "submitAnswers" : "checkAnswers");
  $value = quoteHTML($value);
  return qq!<input type="submit" name="$name" value="$label" onclick="document.getElementById('_panicked').value++">!;
}

#
#  The reset button
#
sub ResetButton {
  main::RECORD_FORM_LABEL("_panic_reset");
  return qq!<input type="checkbox" name="_panic_reset"> Reset problem hints!;
}

#
#  Handle HTML in the value
#
sub quoteHTML {
  my $string = shift;
  return main::encode_pg_and_html($string);
}

#
#  Install the panic grader, saving the original one
#
sub GradeWithPenalty {
  $grader = $main::PG->{flags}->{PROBLEM_GRADER_TO_USE} || \&main::avg_problem_grader;
  main::install_problem_grader(\&Panic::grader);
}

#
#  The grader for the panic levels.
#
sub grader {
  #
  #  Save the old score and call the original grader.
  #  Compute the penalized score, and save it, if it is better than the old score.
  #  Reset the values if we are resetting scores.
  #
  my $oldScore = $_[1]->{recorded_score} || 0;
  my ($result,$state) = &{$grader}(@_);
  $result->{score} *= 1-$penalty[$main::panicked];
  $state->{recorded_score} = ($result->{score} > $oldScore ? $result->{score} : $oldScore);
  $state->{recorded_score} = $state->{num_of_incorrect_ans} = $state->{num_of_correct_ans} = 0
    if $main::inputs_ref->{_panic_reset} && $allowReset;

  #
  #  Add the problemPanic message and data
  #
  $result->{type} = "problemPanic ($result->{type})";
  if ($main::panicked) {
    $result->{msg} .= '</i><p><b>Note:</b> <i>' if $result->{msg};
    $result->{msg} .= 'Your score was reduced by '.(int($penalty[$main::panicked]*100)).'%'
                   .  ' because you accepted '.($main::panicked == 1 ? 'a hint.' : $main::panicked.' hints.');
    #
    #  Add the reset checkbox, if needed
    #
    $result->{msg} .= '<p>'.ResetButton() if $allowReset;
  }

  return ($result,$state);
}
