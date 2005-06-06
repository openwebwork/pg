sub _parserMultiPart_init {}

#
#  MultiPart objects let you tie several answer blanks to a single
#  answer checker, so you can have the answer in one blank influence
#  the answer in another.  The MultiPart can produce either a single
#  result in the answer results area, or a separate result for each
#  blank.
#
#  To create a MultiPart pass a list of answers to MultiPart() in the
#  order they will appear in the problem.  For example:
#
#    $mp = MultiPart("x^2",-1,1);
#
#  or
#
#    $mp = MultiPart(Vector(1,1,1),Vector(2,2,2))->with(singleResult=>1);
#
#  Then, use $mp->ans_rule to create answer blanks for the various parts
#  just as you would ans_rule.  You can pass the width of the blank, which
#  defaults to 20 otherwise.  For example:
#
#    BEGIN_TEXT
#      \(f(x)\) = \{$mp->ans_rule(20)\} produces the same value
#      at \(x\) = \{$mp->ans_rule(10)\} as it does at \(x\) = \{$mp->ans_rule(10)\}.
#    END_TEXT
#
#  Finally, call $mp->cmp to produce the answer checker(s) used in the MultiPart.
#  You need to provide a checker routine that will be called to determine if the
#  answers are correct or not.  The checker will only be called if the student
#  answers have no syntax errors and their types match the types of the professor's
#  answers, so you don't ahve to worry about handling bad data from the student
#  (at least as far as typechecking goes).
#
#  The checker routine should accept three parameters:  a reference to the array
#  of correct answers, a reference to the array of student answers, and a reference
#  to the MultiPart itself.  It should do whatever checking it needs to do and
#  then return a score for the MultiPart as a whole (every answer blank will be
#  given the same score), or a reference to an array of scores, one for each
#  blank.  The routine can set error messages via the MultiPart's setMessage()
#  method (e.g., $mp->setMessage(1,"The function can't be the identity") would
#  set the message for the first answer blank of the MultiPart), or can call
#  Value::Error() to generate an error and die.
#
#  The checker routine can be supplied either when the MultiPart is created, or
#  when the cmp() method is called.  For example:
#
#      $mp = MultiPart("x^2",1,-1)->with(
#        singleResult => 1,
#        checker => sub {
#          my ($correct,$student,$self) = @_;  # get the parameters
#          my ($f,$x1,$x2) = @{$student};      # extract the student answers
#          Value::Error("Function can't be the identity") if ($f == 'x');
#          Value::Error("Function can't be constant") if ($f->isConstant);
#          return $f->eval(x=>$x1) == $f->eval(x=>$x2);
#        },
#      );
#           .
#           .
#           .
#      ANS($mp->cmp);
#
#  or
#
#      $mp = MultiPart("x^2",1,-1)->with(singleResult=>1);
#      sub check {
#        my ($correct,$student,$self) = @_;  # get the parameters
#        my ($f,$x1,$x2) = @{$student};      # extract the student answers
#        Value::Error("Function can't be the identity") if ($f == 'x');
#        Value::Error("Function can't be constant") if ($f->isConstant);
#        return $f->eval(x=>$x1) == $f->eval(x=>$x2);
#      };
#           .
#           .
#           .
#      ANS($mp->cmp(checker=>~~&check));
# 
######################################################################

package MultiPart;
our @ISA = qw(Value);

our $count = 0;                      # counter for unique identifier for multi-parts
our $answerPrefix = "MuLtIpArT";     # answer rule prefix
our $separator = ';';                # separator for singleResult previews

#
#  Create a new MultiPart item from a list of items.
#  The items are converted if Value items, if they aren't already.
#  You can set the following fields of the resulting item:
#
#      checker => code            a subroutine to be called to check the
#                                 student answers.  The routine is passed
#                                 three parameters: a reference to the array
#                                 or correct answers, a reference to the
#                                 array of student answers, and a reference
#                                 to the MultiPart object itself.  The routine
#                                 should return either a score or an array of
#                                 scores (one for each student answer).
#
#      singleResult => 0 or 1     whether to show only one entry in the
#                                 results area at the top of the page,
#                                 or one for each answer rule.
#                                 (Default: 0)
#
#      namedRules => 0 or 1       wether to use named rules or default
#                                 rule names.  Use named rules if you need
#                                 to intersperse other rules with the
#                                 ones for the MultiPart, in which case
#                                 you must use NAMED_ANS not ANS.
#                                 (Default: 0)
#
#      checkTypes => 0 or 1       whether the types of the student and
#                                 professor's answers must match exactly
#                                 or just pass the usual type-match error
#                                 checking (in which case, you should check
#                                 the types before you use the data).
#	                          (Default: 1)
#
#      separator => string        the string to use between entries in the
#                                 results area when singleResult is set.
#
#      tex_separator => string    same, but for the preview area.
#
my @ans_defaults = (
  checker => sub {0},
  showCoordinateHints => 0,
  showEndpointHints => 0,
  showEndTypeHints => 0,
);

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my @data = @_; my @cmp;
  Value::Error($class." lists can't be empty") if scalar(@data) == 0;
  foreach my $x (@data) {
    $x = Value::makeValue($x) unless Value::isValue($x);
    push(@cmp,$x->cmp(@ans_defaults));
  }
  bless {
    data => [@data], cmp => [@cmp], ans => [],
    part => 0, singleResult => 0, namedRules => 0, checkTypes => 1,
    tex_separator => $separator.'\,', separator => $separator.' ',
    context => $$Value::context, id => $answerPrefix.($count++),
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
  my $self = shift; my @correct;
  foreach my $cmp (@{$self->{cmp}}) {push(@correct,$cmp->{rh_ans}{correct_ans})}
  my $ans = new AnswerEvaluator;
  $ans->ans_hash(
    correct_ans => join($self->{separator},@correct),
    type        => "MultiPart",
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
  my $self = shift; my $ans = shift;
  my $inputs = $main::inputs_ref;
  $self->{ans}[0] = $self->{cmp}[0]->evaluate($ans->{student_ans});
  foreach my $i (1..$self->length-1) 
    {$self->{ans}[$i] = $self->{cmp}[$i]->evaluate($inputs->{$self->ANS_NAME($i)})}
  my $score = 0; my (@errors,@student,@latex,@text);
  my $i = 0; my $nonblank = 0;
  if ($self->perform_check) {
    push(@errors,$self->{ans}[0]{ans_message});
    $self->{ans}[0]{ans_message} = "";
  }
  foreach my $result (@{$self->{ans}}) {
    $i++; $nonblank |= ($result->{student_ans} =~ m/\S/);
    push(@latex,check_string($result->{preview_latex_string},'\_\_'));
    push(@text,check_string($result->{preview_text_string},'__'));
    push(@student,check_string($result->{student_ans},'__'));
    if ($result->{ans_message}) {
      push(@errors,"Answer $i: ".$result->{ans_message});
    } else {$score += $result->{score}}
  }
  $ans->score($score/$self->length);
  $ans->{ans_message} = $ans->{error_message} = join("<BR>",@errors);
  if ($nonblank) {
    $ans->{preview_latex_string} = '{'.join('}'.$self->{tex_separator}.'{',@latex).'}';
    $ans->{preview_text_string}  = join($self->{separator},@text);
    $ans->{student_ans} = join($self->{separator},@student);
  }
  return $ans;
}

#
#  Return a given string or a default if it is empty or not defined
#
sub check_string {
  my $s = shift;
  $s = shift unless defined($s) && $s =~ m/\S/;
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
    type        => "MultiPart($i)",
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
  my $self = shift; my $ans = shift;
  my $i = $ans->{part};
  $self->{ans}[$i] = $self->{cmp}[$i]->evaluate($ans->{student_ans});
  $self->{ans}[$i]->score(0);
  $self->perform_check if ($i == $self->length - 1);
  return $self->{ans}[$i];
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
  my $self = shift; $self->{context}->clearError;
  my @correct; my @student;
  foreach my $ans (@{$self->{ans}}) {
    push(@correct,$ans->{correct_value});
    push(@student,$ans->{student_value});
    return if $ans->{ans_message} ne "" || !defined($ans->{student_value});
    return if $self->{checkTypes} && $ans->{student_value}->type ne $ans->{correct_value}->type;
  }
  my $result = Value::cmp_compare([@correct],[@student],$self);
  if (!defined($result) && $self->{context}{error}{flag}) {$self->cmp_error($self->{ans}[0]); return 1}
  $result = 0 if (!defined($result) || $result eq '');
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
#  Produce the name for a named answer blank
#
sub ANS_NAME {
  my $self = shift; my $i = shift;
  $self->{id}.'_'.$i;
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
#    by the settings of the MultiPart.
#
sub ans_rule {
  my $self = shift; my $size = shift || 20;
  my $data = $self->{data}[$self->{part}];
  my $name = $self->ANS_NAME($self->{part}++);
  return $data->named_ans_rule_extension($self->NEW_NAME($name),$size,@_)
    if ($self->{singleResult} && $self->{part} > 1);
  return $data->ans_rule($size,@_) unless $self->{namedRules};
  return $data->named_ans_rule($name,$size,@_);
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
  if ($self->{singleResult} && $self->{part} > 1) {
    $HTML = $data->named_ans_array_extension($self->NEW_NAME($name),$size,@_);
  } elsif (!$self->{namedRules}) {
    $HTML = $data->ans_array($size,@_);
  } else {
    $HTML = $data->named_ans_array($name,$size,@_);
  }
  $self->{cmp}[$self->{part}-1] = $data->cmp(@ans_defaults);
  return $HTML;
}

######################################################################

package main;

#
#  Main routine to create MultiPart items.
#
sub MultiPart {MultiPart->new(@_)};

1;
