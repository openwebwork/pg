################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2018 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/parserMultiAnswer.pl,v 1.11 2009/06/25 23:28:44 gage Exp $
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

parserMultiAnswer.pl - Tie several blanks to a single answer checker.

=head1 DESCRIPTION

MultiAnswer objects let you tie several answer blanks to a single
answer checker, so you can have the answer in one blank influence
the answer in another.  The MultiAnswer can produce either a single
result in the answer results area, or a separate result for each
blank.

To create a MultiAnswer pass a list of answers to MultiAnswer() in the
order they will appear in the problem.  For example:

	$mp = MultiAnswer("x^2",-1,1);

or

	$mp = MultiAnswer(Vector(1,1,1),Vector(2,2,2))->with(singleResult=>1);

Then, use $mp->ans_rule to create answer blanks for the various parts
just as you would ans_rule.  You can pass the width of the blank, which
defaults to 20 otherwise.  For example:

	BEGIN_TEXT
	\(f(x)\) = \{$mp->ans_rule(20)\} produces the same value
	at \(x\) = \{$mp->ans_rule(10)\} as it does at \(x\) = \{$mp->ans_rule(10)\}.
	END_TEXT

Finally, call $mp->cmp to produce the answer checker(s) used in the MultiAnswer.
You need to provide a checker routine that will be called to determine if the
answers are correct or not.  The checker will only be called if the student
answers have no syntax errors and their types match the types of the professor's
answers, so you don't have to worry about handling bad data from the student
(at least as far as typechecking goes).

The checker routine should accept four parameters:  a reference to the array
of correct answers, a reference to the array of student answers, a reference
to the MultiAnswer itself, and a reference to the answer hash.  It should do
whatever checking it needs to do and then return a score for the MultiAnswer
as a whole (every answer blank will be given the same score), or a reference
to an array of scores, one for each blank.  The routine can set error messages
via the MultiAnswer's setMessage() method (e.g.,

	$mp->setMessage(1,"The function can't be the identity");

would set the message for the first answer blank of the MultiAnswer), or can
call Value::Error() to generate an error and die.

The checker routine can be supplied either when the MultiAnswer is created, or
when the cmp() method is called.  For example:

	$mp = MultiAnswer("x^2",1,-1)->with(
		singleResult => 1,
		checker => sub {
			my ($correct,$student,$self) = @_;  # get the parameters
			my ($f,$x1,$x2) = @{$student};      # extract the student answers
			Value::Error("Function can't be the identity") if ($f == 'x');
			Value::Error("Function can't be constant") if ($f->isConstant);
			return $f->eval(x=>$x1) == $f->eval(x=>$x2);
		},
	);
	ANS($mp->cmp);

or

	$mp = MultiAnswer("x^2",1,-1)->with(singleResult=>1);
	sub check {
		my ($correct,$student,$self) = @_;  # get the parameters
		my ($f,$x1,$x2) = @{$student};      # extract the student answers
		Value::Error("Function can't be the identity") if ($f == 'x');
		Value::Error("Function can't be constant") if ($f->isConstant);
		return $f->eval(x=>$x1) == $f->eval(x=>$x2);
	};
	ANS($mp->cmp(checker=>~~&check));

=cut

loadMacros("MathObjects.pl");

sub _parserMultiAnswer_init {
  main::PG_restricted_eval('sub MultiAnswer {parser::MultiAnswer->new(@_)}');
}

##################################################

package parser::MultiAnswer;
our @ISA = qw(Value);

our $answerPrefix = "MuLtIaNsWeR_";  # answer rule prefix
our $separator = ';';                # separator for singleResult previews

=head1 CONSTRUCTOR

	MultiAnswer($answer1, $answer2, ...);
	MultiAnswer($answer1, $answer2, ...)->with(...);

Create a new MultiAnswer item from a list of items. The items are converted if
Value items, if they aren't already. You can set the following fields of the
resulting item:

    checker => code            a subroutine to be called to check the
                               student answers.  The routine is passed
                               four parameters: a reference to the array
                               or correct answers, a reference to the
                               array of student answers, a reference to the
                               MultiAnswer object itself, and a reference to
                               the checker's answer hash.  The routine
                               should return either a score or a reference
                               to an array of scores (one for each answer).

    singleResult => 0 or 1     whether to show only one entry in the
                               results area at the top of the page,
                               or one for each answer rule.
                               (Default: 0)

    namedRules => 0 or 1       whether to use named rules or default
                               rule names.  Use named rules if you need
                               to intersperse other rules with the
                               ones for the MultiAnswer, in which case
                               you must use NAMED_ANS not ANS.
                               (Default: 0)

    checkTypes => 0 or 1       whether the types of the student and
                               professor's answers must match exactly
                               or just pass the usual type-match error
                               checking (in which case, you should check
                               the types before you use the data).
                               (Default: 1)

    allowBlankAnswers=>0 or 1  whether to remove the blank-check prefilter
                               from the answer checkers used for type
                               checking the student's answers.
                               (Default: 0)

    separator => string        the string to use between entries in the
                               results area when singleResult is set.
                               (Default: semicolon)

    tex_separator => string    same, but for the preview area.
                               (Default: semicolon followed by thinspace)

    format => string           an sprintf-style string used to format the
                               students answers for the results area
                               when singleResults is true.  If undefined,
                               the separator parameter (above) is used to
                               form the string.
                               (Default: undef)

    tex_format => string       an sprintf-style string used to format the
                               students answer previews when singleResults
                               mode is in effect.  If undefined, the
                               tex_separator (above) is used to form the
                               string.
                               (Default: undef)

=cut

my @ans_defaults = (
  checker => sub {0},
  showCoordinateHints => 0,
  showEndpointHints => 0,
  showEndTypeHints => 0,
);

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my @data = @_; my @cmp;
  Value::Error("%s lists can't be empty",$class) if scalar(@data) == 0;
  foreach my $x (@data) {
    $x = Value::makeValue($x,context=>$context) unless Value::isValue($x);
    push(@cmp,$x->cmp(@ans_defaults));
  }
  bless {
    data => [@data], cmp => [@cmp], ans => [], isValue => 1,
    part => 0, singleResult => 0, namedRules => 0,
    checkTypes => 1, allowBlankAnswers => 0,
    tex_separator => $separator.'\,', separator => $separator.' ',
    tex_format => undef, format => undef,
    context => $context,
  }, $class;
}

#
#  Creates an answer checker (or array of same) to be passed
#  to ANS() or NAMED_ANS().  Any parameters are passed to
#  the individual answer checkers.
#
sub cmp {
  my $self = shift; my %options = @_;
  foreach my $id ('checker','separator') {
    if (defined($options{$id})) {
      $self->{$id} = $options{$id};
      delete $options{$id};
    }
  }
  die "You must supply a checker subroutine" unless ref($self->{checker}) eq 'CODE';
  if ($self->{allowBlankAnswers}) {
    foreach my $cmp (@{$self->{cmp}}) {
      $cmp->install_pre_filter('erase');
      $cmp->install_pre_filter(sub {
	my $ans = shift;
	$ans->{student_ans} =~ s/^\s+//g;
	$ans->{student_ans} =~ s/\s+$//g;
	return $ans;
      });
    }
  }
  my @cmp = ();
  if ($self->{singleResult}) {
    push(@cmp,$self->ANS_NAME(0)) if $self->{namedRules};
    push(@cmp,$self->single_cmp(%options));
  } else {
    foreach my $i (0..$self->length-1) {
      push(@cmp,$self->ANS_NAME($i)) if $self->{namedRules};
      push(@cmp,$self->entry_cmp($i,%options));
    }
  }
  return @cmp;
}

######################################################################

#
#  Get the answer checker used for when all the answers are treated
#  as a single result.
#
sub single_cmp {
  my $self = shift; my @correct; my @correct_tex;
  foreach my $cmp (@{$self->{cmp}}) {
    push(@correct,$cmp->{rh_ans}{correct_ans});
    push(@correct_tex,$cmp->{rh_ans}{correct_ans_latex_string}||$cmp->{rh_ans}{correct_value}->TeX);
  }
  my $ans = new AnswerEvaluator;
  $ans->ans_hash(
    correct_ans => (defined($self->{format}) ? sprintf($self->{format},@correct) : join($self->{separator},@correct)),
    correct_ans_latex_string => (defined($self->{tex_format}) ?
        sprintf($self->{tex_format},@correct_tex) : join($self->{tex_separator},@correct_tex)),
    type        => "MultiAnswer",
    @_,
  );
  $ans->install_evaluator(sub {my $ans = shift; (shift)->single_check($ans)},$self);
  $ans->install_pre_filter('erase'); # don't do blank check
  return $ans;
}

#
#  Check the answers when they are treated as a single result.
#
#    First, call individual answer checkers to get any type-check errors
#    Then perform the user's checker routine
#    Finally collect the individual answers and errors and combine
#      them for the single result.
#
sub single_check {
  my $self = shift; my $ans = shift; $ans->{_filter_name} = "MultiAnswer Single Check";
  my $inputs = $main::inputs_ref;
  $self->{ans}[0] = $self->{cmp}[0]->evaluate($ans->{student_ans});
  foreach my $i (1..$self->length-1)
    {$self->{ans}[$i] = $self->{cmp}[$i]->evaluate($inputs->{$self->ANS_NAME($i)})}
  my $score = 0; my (@errors,@student,@latex,@text);
  my $i = 0; my $nonblank = 0;
  if ($self->perform_check($ans)) {
    push(@errors,'<TR><TD STYLE="text-align:left" COLSPAN="2">'.$self->{ans}[0]{ans_message}.'</TD></TR>');
    $self->{ans}[0]{ans_message} = "";
  }
  foreach my $result (@{$self->{ans}}) {
    $i++; $nonblank |= ($result->{student_ans} =~ m/\S/);
    push(@latex,'{'.check_string($result->{preview_latex_string},'\_\_').'}');
    push(@text,check_string($result->{preview_text_string},'__'));
    push(@student,check_string($result->{student_ans},'__'));
    if ($result->{ans_message}) {
      push(@errors,'<TR VALIGN="TOP"><TD STYLE="text-align:right; border:0px" NOWRAP>' .
                   "<I>In answer $i</I>:&nbsp;</TD>".
                   '<TD STYLE="text-align:left; border:0px">'.$result->{ans_message}.'</TD></TR>');
    }
    $score += $result->{score};
  }
  $ans->score($score/$self->length);
  $ans->{ans_message} = $ans->{error_message} = "";
  if (scalar(@errors)) {
    $ans->{ans_message} = $ans->{error_message} =
      '<TABLE BORDER="0" CELLSPACING="0" CELLPADDING="0" CLASS="ArrayLayout">' .
       join('<TR><TD HEIGHT="4"></TD></TR>',@errors).
      '</TABLE>';
  }
  if ($nonblank) {
    $ans->{preview_latex_string} =
      (defined($self->{tex_format}) ? sprintf($self->{tex_format},@latex) : join($self->{tex_separator},@latex));
    $ans->{preview_text_string} =
      (defined($self->{format}) ? sprintf($self->{format},@text) : join($self->{separator},@text));
    $ans->{student_ans} =
      (defined($self->{format}) ? sprintf($self->{format},@student) : join($self->{separator},@student));
  }
  return $ans;
}

#
#  Return a given string or a default if it is empty or not defined
#
sub check_string {
  my $s = shift;
  $s = shift unless defined($s) && $s =~ m/\S/ && $s ne '{\rm }';
  return $s;
}

######################################################################

#
#  Answer checker to use for individual entries when singleResult
#  is not in effect.
#
sub entry_cmp {
  my $self = shift; my $i = shift;
  my $ans = new AnswerEvaluator;
  $ans->ans_hash(
    correct_ans => $self->{cmp}[$i]{rh_ans}{correct_ans},
    part        => $i,
    type        => "MultiAnswer($i)",
    @_,
  );
  $ans->install_evaluator(sub {my $ans = shift; (shift)->entry_check($ans)},$self);
  $ans->install_pre_filter('erase'); # don't do blank check
  return $ans;
}

#
#  Call the correct answser's checker to check for syntax and type errors.
#  If this is the last one, perform the user's checker routine as well
#  Return the individual answer (our answer hash is discarded).
#
sub entry_check {
  my $self = shift; my $ans = shift; $ans->{_filter_name} = "MultiAnswer Entry Check";
  my $i = $ans->{part};
  my $ANS = $self->{cmp}[$i]->evaluate($ans->{student_ans});
  $self->{ans}[$i] = $ANS; $ANS->{type} = $ans->{type}; $ANS->score(0);
  foreach my $id (keys %{$ans}) {$ANS->{$id} = $ans->{$id} unless defined($ANS->{$id})} # copy missing original fields
  $self->perform_check($ANS) if ($i == $self->length - 1);
  return $ANS;
}

######################################################################

#
#  Collect together the correct and student answers, and call the
#  user's checker routine.
#
#  If any of the answers produced errors or the types don't match
#    don't call the user's routine.
#  Otherwise, call it, and if there was an error, report that.
#  Set the individual scores based on the result from the user's routine.
#
sub perform_check {
  my $self = shift; my $rh_ans = shift;
  $self->context->clearError;
  my @correct; my @student;
  foreach my $ans (@{$self->{ans}}) {
    push(@correct,$ans->{correct_value});
    push(@student,$ans->{student_value});
    return if $ans->{ans_message} ne "" || !defined($ans->{student_value});
    return if $self->{checkTypes} && $ans->{student_value}->type ne $ans->{correct_value}->type &&
              !($self->{allowBlankAnswers} && $ans->{student_ans} !~ m/\S/) ;
  }
  my $inputs = $main::inputs_ref;
  $rh_ans->{isPreview} = $inputs->{previewAnswers} ||
                         ($inputs_{action} && $inputs->{action} =~ m/^Preview/);
  my @result = Value::cmp_compare([@correct],[@student],$self,$rh_ans);
  if (!@result && $self->context->{error}{flag}) {$self->cmp_error($self->{ans}[0]); return 1}
  my $result = (scalar(@result) > 1 ? [@result] : $result[0] || 0);
  if (ref($result) eq 'ARRAY') {
    die "Checker subroutine returned the wrong number of results"
      if (scalar(@{$result}) != $self->length);
    foreach my $i (0..$self->length-1) {$self->{ans}[$i]->score($result->[$i])}
  } elsif (Value::matchNumber($result)) {
    foreach my $ans (@{$self->{ans}}) {$ans->score($result)}
  } else {
    die "Checker subroutine should return a number or array of numbers ($result)";
  }
  return;
}

######################################################################

#
#  The user's checker can call setMessage(n,message) to set the error message
#  for the n-th answer blank.
#
sub setMessage {
  my $self = shift; my $i = (shift)-1; my $message = shift;
  $self->{ans}[$i]->{ans_message} = $self->{ans}[$i]->{error_message} = $message;
}


######################################################################

#
#  Produce the name for a named answer blank.
#  (When the singleResult option is true, use the standard name for the first
#  one, and create the prefixed names for the rest.)
#
sub ANS_NAME {
  my $self = shift; my $i = shift;
  return $self->{answerNames}{$i} if defined($self->{answerNames}{$i});
  if ($self->{singleResult}) {
    $self->{answerNames}{0} = main::NEW_ANS_NAME() unless defined($self->{answerNames}{0});
    $self->{answerNames}{$i} = $answerPrefix.$self->{answerNames}{0}."_".$i unless $i == 0;
  } else {
    $self->{answerNames}{$i} = main::NEW_ANS_NAME();
  }
  return $self->{answerNames}{$i};
}

#
#  Record an answer-blank name (when using extensions)
#
sub NEW_NAME {
  my $self = shift;
  main::RECORD_FORM_LABEL(shift);
}

#
#  Produce an answer rule for the next item in the list,
#    taking care to use names or extensions as needed
#    by the settings of the MultiAnswer.
#
sub ans_rule {
  my $self = shift; my $size = shift || 20;
  my $data = $self->{data}[$self->{part}];
  my $name = $self->ANS_NAME($self->{part}++);
  if ($self->{singleResult} && $self->{part} == 1) {      
      my $label = main::generate_aria_label($answerPrefix.$name."_0");
      return $data->named_ans_rule($name,$size,@_,aria_label=>$label);
  }
  if ($self->{singleResult} && $self->{part} > 1) {
  	 my $extension_ans_rule = 
  	 	$data->named_ans_rule_extension(
  	 	$name,$size, answer_group_name => $self->{answerNames}{0},
  	 	@_);
  	 # warn "extension rule created: $extension_ans_rule for ", ref($data);
  	 return $extension_ans_rule; 
  } else {
  	 return $data->named_ans_rule($name,$size,@_);
  }
}

#
#  Do the same, but for answer arrays, which are generated by the
#    Value objects automatically sized to suit their data.
#    Reset the correct_ans once the array is made
#
sub ans_array {
  my $self = shift; my $size = shift || 5; my $HTML;
  my $data = $self->{data}[$self->{part}];
  my $name = $self->ANS_NAME($self->{part}++);
  if ($self->{singleResult} && $self->{part} == 1) {
      my $label = main::generate_aria_label($answerPrefix.$name."_0");
      return $data->named_ans_array($name,$size,
             answer_group_name => $self->{answerNames}{0},
             @_,aria_label=>$label);
  }
  if ($self->{singleResult} && $self->{part} > 1) {
    $HTML = $data->named_ans_array_extension($self->NEW_NAME($name),$size,
      answer_group_name => $self->{answerNames}{0}, @_);
    # warn "array extension rule created: $HTML for ", ref($data);
  } else {
    $HTML = $data->named_ans_array($name,$size,@_);
  }
  $self->{cmp}[$self->{part}-1] = $data->cmp(@ans_defaults);
  return $HTML;
}

######################################################################

1;
