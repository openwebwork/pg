################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
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

=head1 AnswerHints()

This is an answer-checker post-filter that allows you to produce
additional error messages for incorrect answers.  You can trigger
a message for a single answer, a collection of answers, or via a
subroutine that determines the condition for the message.

Note that this filter only works for MathObjects answer checkers.

The answer hints are given as a pair using => with the right-hand
side being the answer message and the left-hand side being one of
three possibilities:  1) the value that triggers the message,
2) a reference to an array of values that trigger the message, or
3) a code reference to a subtroutine that accepts the correct
answer, the student's answer, and the answer hash, and returns
1 or 0 depending on whether the message should or should not be
displayed.  (See the examples below.)

The right-hand side can be either the message string itself, or
a referrence to an array where the first element is the message
string, and the remaining elements are name-value pairs that
set options for the message.  These can include:

=over

=item C<S<< checkCorrect => 0 or 1 >>>

1 means check for messages even
if the answer is correct.
Default: 0

=item C<S<< replaceMessage => 0 or 1 >>>

1 means it's OK to repalce any
message that is already in place
in the answer hash.
Default: 0

=item C<S<< checkTypes => 0 or 1 >>>

1 means only perform the test
if the student answer is the
same type as the correct one.
Default: 1

=item C<S<< score => number >>>

Specifies the score to use if
the message is triggered (so that
partial credit can be given).
Default: keep original score

=item C<S<< cmp_options => [...] >>>

provides options for the cmp routine
used to check if the student answer
matches these answers.
Default: []

=back

If more than one message matches the student's answer, the first
one in the list is used.

Example:

	ANS(Vector(1,2,3)->cmp(showCoordinateHints=>0)->withPostFilter(AnswerHints(
		Vector(0,0,0) => "The zero vector is not a valid solution",
		"-<1,2,3>" => "Try the opposite direction",
		"<1,2,3>" => "Well done!",
		["<1,1,1>","<2,2,2>","<3,3,3>"] => "Don't just guess!",
		sub {
			my ($correct,$student,$ans) = @_;
			return $correct . $student == 0;
		} => "Your answer is perpendicular to the correct one",
		Vector(1,2,3) => [
			"You have the right direction, but not length",
			cmp_options => [parallel=>1],
		],
		0 => ["Careful, your answer should be a vector!", checkTypes => 0, replaceMessage => 1],
		sub {
			my ($correct,$student,$ans) = @_;
			return norm($correct-$student) < .1;
		} => ["Close!  Keep trying.", score => .25],
	)));

=cut

sub _answerHints_init {}

sub AnswerHints {
  return (sub {
    my $ans = shift; $ans->{_filter_name} = "Answer Hints Post Filter";
    my $correct = $ans->{correct_value};
    my $student = $ans->{student_value};
    Value::Error("AnswerHints can only be used with MathObjects answer checkers") unless ref($correct);
    return $ans unless ref($student);

    while (@_) {
      my $wrongList = shift; my $message = shift; my @options;
      ($message,@options) = @{$message} if ref($message) eq 'ARRAY';
      my %options = (
        checkCorrect => 0,
        replaceMessage => 0,
	checkTypes => 1,
        score => undef,
        cmp_options => [],
        @options,
      );
      next if $options{checkType} && $correct->type ne $student->type;
      $wrongList = [$wrongList] unless ref($wrongList) eq 'ARRAY';
      foreach my $wrong (@{$wrongList}) {
	if (ref($wrong) eq 'CODE') {
	  if (($ans->{score} < 1 || $options{checkCorrect}) &&
	      ($ans->{ans_message} eq "" || $options{replaceMessage}) &&
	      &$wrong($correct,$student,$ans)) {
	    $ans->{ans_message} = $ans->{error_message} = $message;
	    $ans->{score} = $options{score} if defined $options{score};
	    last;
	  }
	} else {
	  $wrong = Value::makeValue($wrong);
	  if (($ans->{score} < 1 || $options{checkCorrect} || AnswerHints::Compare($correct,$wrong,$ans)) &&
	      ($ans->{ans_message} eq "" || $options{replaceMessage}) &&
	      AnswerHints::Compare($wrong,$student,$ans,@{$options{cmp_options}})) {
	    $ans->{ans_message} = $ans->{error_message} = $message;
	    $ans->{score} = $options{score} if defined $options{score};
	    last;
	  }
	}
      }
    }
    return $ans;
  },@_);
}

package AnswerHints;

#
#  Calls the answer checker on two values with a copy of the answer hash
#  and returns true if the two values match and false otherwise.
#
sub Compare {
  my $self = shift; my $other = shift; my $ans = shift;
  $ans = bless {%{$ans},@_}, ref($ans);  # make a copy
  $ans->{typeError} = 0; $ans->{ans_message} = $ans->{error_message} = ""; $ans->{score} = 0;
  if (sprintf("%p",$self) ne sprintf("%p",$ans->{correct_value})) {
    $ans->{correct_ans} = $self->string;
    $ans->{correct_value} = $self;
    $ans->{correct_formula} = Value->Package("Formula")->new($self);
  }
  if (sprintf("%p",$other) ne sprintf("%p",$ans->{student_value})) {
    $ans->{student_ans} = $other->string;
    $ans->{student_value} = $other;
    $ans->{student_formula} = Value->Package("Formula")->new($other);
  }
  $self->cmp_preprocess($ans);
  $self->cmp_equal($ans);
  $self->cmp_postprocess($ans) if !$ans->{error_message} && !$ans->{typeError};
  return $ans->{score} >= 1;
}

1;
