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

answerCustom.pl - An easy method for creating answer checkers with a custom
subroutine that performs the check for correctness.

=cut

loadMacros('MathObjects.pl');

sub _answerCustom_init {}; # don't reload this file

=head1 MACROS

=head2 custom_cmp

	ANS(custom_cmp($correct_ans, $ans_checker, %options))

This answer checker provides an easy method for creating an answer
checker with a custom subroutine that performs the check for
correctness.

Pass the correct answer (either as a string or as a Parser object)
as the first argument, and a reference to the checker subroutine
as the second argument.  Additional parameters can follow.  These
include any of the parameters for the usual answer checker of the
of the type of the correct answer (e.g., showCoordinateHints), plus
the following:

=over

=item S<C<< sameClass => 0 or 1 >>>

If 1 (the default), only call the
custom checker if the student answer
is the same object class as the correct
answer (e.g., both are points).
If 0, the checker will be called
whenever the student answer passes
the typeMatch check for the correct
answer.  For example, if the correct
answer is a vector, and promotePoints
has been set to 1, then the checker
will be called when the student answer
is a vector OR a point.

=item S<C<< sameLength => 0 or 1 >>>

If 1 (the default), only call the
custom checker if the student answer
has the same number of coordinates as
the correct answer.

=back

If the correct answer is a list, the custom checker will be called
on the individual entries of the list, not on the list as a whole.
If the list is an unordered list, the routine may be called
multiple times with various combinations of student and professor's
answers in order to find a correct match.

Note: If you want a correct answer whose class is a complex variable
to check a real number entry you will have to set both sameClass and
sameLength to 0 since a complex number has length 2 and a real number
has length 1.

The checker routine will be passed the correct answer, the
student's answer, and the answer evaluator object, in that order.

For example, the following checks if a student entered
a unit vector (any unit vector in R^3 will do):

	ANS(custom_cmp("<1,0,0>",sub {
		my ($correct,$student,$ans) = @_;
		return norm($student) == 1;
	},showCoordinateHints => 0));

The checker subroutine can call Value::Error(message) to generate
an error message that will be reported in the table at the top of
the page.  If the checker generates a fatal runtime error (e.g.,
calls the "die" function), then the message is reported with the
"pink screen of death", and includes a request for the student to
inform the instructor.

=cut

sub custom_cmp {
  my $correct = shift; my $checker = shift;
  die "custom_cmp requires a correct answer" unless defined($correct);
  die "custom_cmp requires a checker subroutine" unless defined($checker);
  $correct = Value::makeValue($correct);
  $correct = Value->Package("Formula")->new($correct) unless Value::isValue($correct);
  $correct->cmp(
    checker => sub {
      my ($correct,$student,$ans) = @_;
      return 0 if $ans->{sameClass} && $correct->class ne $student->class;
      return 0 if $ans->{sameLength} && $correct->length != $student->length;
      return &{$ans->{custom_checker}}($correct,$student,$ans);
    },
    custom_checker => $checker,
    sameClass => 1,
    sameLength => 1,
    showEqualErrors => 1,  # make sure we see errors in list checker
    @custom_cmp_defaults,
    @_,
  );
}

#
#  Set this to include any default parameters you want
#  to include in the custom answer checkers
#
@custom_cmp_defaults = ();

=head2 custom_list_cmp

 ANS(custom_list_cmp($correct_ans, $ans_checker, %options))

This one installs a custom list-based answer checker (for the
List and Union classes).  Basically it is just a shell that makes
it a little easier to do, and provides an interface similar to 
custom_cmp.

You pass the correct answer (as a string or as a List or Union
object) as the first argument, and the custom list checker as
the second argument.  You can pass any additional parameters
that should be included in the answer checker following those
two required ones.

The checker will be passed a reference to the array of correct
answers, a reference to the array of student answers, and
the answer evaluator object.  Note that the correct and student
answers are array references, not List structures (this is because
a list of formulas becomes a formula returning a list, so in order
to keep the formulas separate, they are passed in an array).

The checker should return the number of list entries that were
matched by the students answers.  (I.e., a number between 0
and the length of the list.)

For example, the following checks for any list of the same length
as the instructor's list.  (A stupid checker, but just an example.)

    ANS(custom_list_cmp("1,2,3",sub {
        my ($correct,$student,$ans) = @_;
        (scalar(@{$correct}) == scalar(@{$student}) ? 3 : 0);
    }));

The checker subroutine can call Value::Error(message) to generate
an error message that will be reported in the table at the top of
the page.  If the checker generates a fatal runtime error (e.g.,
calls the "die" function), then the message is reported with the
"pink screen of death", and includes a request for the student to
inform the instructor.

=cut

sub custom_list_cmp {
  my $correct = shift; my $checker = shift;
  die "custom_list_cmp requires a correct answer" unless defined($correct);
  die "custom_list_cmp requires a checker subroutine" unless defined($checker);
  $correct = Value::makeValue($correct);
  $correct = Value->Package("Formula")->new($correct) unless Value::isValue($correct);
  $correct->cmp(
    list_checker => $checker,
    @custom_list_cmp_defaults,
    @_,
  );
}

#
#  Set this to include any default parameters you want
#  to include in the custom answer checkers
#
@custom_list_cmp_defaults = ();

