#############################################################
#
#  Implements the ->cmp method for Value objects.  This produces
#  an answer checker appropriate for the type of object.
#  Additional options can be passed to the checker to
#  modify its action.
#
#  The individual Value packages are modified below to add the
#  needed methods.
#

#############################################################

package Value;

#
#  Create an answer checker for the given type of object
#

sub cmp_defaults {(
  showTypeWarnings => 1,
  showEqualErrors => 1,
)}

sub cmp {
  my $self = shift;
  $$Value::context->flags->set(StringifyAsTeX => 0);  # reset this, just in case.
  my $ans = new AnswerEvaluator;
  $ans->ans_hash(
    type => "Value (".$self->class.")",
    correct_ans => $self->string,
    correct_value => $self,
    $self->cmp_defaults,
    @_
  );
  $ans->install_evaluator(
    sub {
      my $ans = shift;
      #  can't seem to get $inputs_ref any other way
      $ans->{isPreview} = $self->getPG('$inputs_ref->{previewAnswers}');
      my $self = $ans->{correct_value};
      my $method = $ans->{cmp_check} || 'cmp_check';
      $ans->{cmp_class} = $self->cmp_class($ans) unless $ans->{cmp_class};
      $self->$method($ans);
    }
  );
  return $ans;
}

#
#  Parse the student answer and compute its value,
#    produce the preview strings, and then compare the
#    student and professor's answers for equality.
#
sub cmp_check {
  my $self = shift; my $ans = shift;
  #
  #  Methods to call
  #
  my $cmp_equal = $ans->{cmp_equal} || 'cmp_equal';
  my $cmp_error = $ans->{cmp_error} || 'cmp_error';
  my $cmp_postprocess = $ans->{cmp_postprocess} || 'cmp_postprocess';
  #
  #  Parse and evaluate the student answer
  #
  $ans->score(0);  # assume failure
  $ans->{student_value} = $ans->{student_formula} = Parser::Formula($ans->{student_ans});
  $ans->{student_value} = Parser::Evaluate($ans->{student_formula})
    if defined($ans->{student_formula}) && $ans->{student_formula}->isConstant &&
       $ans->{correct_value}->class ne 'Formula';
  #
  #  If it parsed OK, save the output forms and check if it is correct
  #   otherwise report an error
  #
  if (defined $ans->{student_value}) {
    $ans->{student_value} = Value::Formula->new($ans->{student_value})
       unless Value::isValue($ans->{student_value});
    $ans->{preview_latex_string} = $ans->{student_formula}->TeX;
    $ans->{preview_text_string}  = $ans->{student_formula}->string;
    $ans->{student_ans}          = $ans->{student_value}->stringify;
    $self->$cmp_equal($ans);
    $self->$cmp_postprocess($ans) if !$ans->{error_message};
  } else {
    $self->$cmp_error($ans);
  }
  return $ans;
}

#
#  Check if the parsed student answer equals the professor's answer
#
sub cmp_equal {
  my $self = shift; my $ans = shift;
  if ($ans->{correct_value}->typeMatch($ans->{student_value},$ans)) {
    my $equal = eval {$ans->{correct_value} == $ans->{student_value}};
    if (defined($equal) || !$ans->{showEqualErrors}) {$ans->score(1) if $equal; return}
    my $cmp_error = $ans->{cmp_error} || 'cmp_error';
    $self->$cmp_error($ans);
  } else {
    $ans->{ans_message} = $ans->{error_message} =
      "Your answer isn't ".lc($ans->{cmp_class}).
        " (it looks like ".lc($ans->{student_value}->showClass(1)).")"
	   if !$ans->{isPreview} && $ans->{showTypeWarnings} && !$ans->{error_message};
  }
}

#
#  Check if types are compatible for equality check
#
sub typeMatch {
  my $self = shift;  my $other = shift;
  return 1 unless ref($other);
  $self->type eq $other->type && $other->class ne 'Formula';
}

#
#  Class name for cmp error messages
#
sub cmp_class {
  my $self = shift; my $ans = shift;
  my $class = $self->showClass;
  return "an Interval or Union" if $class =~ m/Interval/i;
  $class =~ s/Real //;
  return $class; 
}

#
#  Student answer evaluation failed.
#  Report the error, with formatting, if possible.
#
sub cmp_error {
  my $self = shift; my $ans = shift;
  my $context = $$Value::context;
  my $message = $context->{error}{message};
  if ($context->{error}{pos}) {
    my $string = $context->{error}{string};
    my ($s,$e) = @{$context->{error}{pos}};
    $message =~ s/; see.*//;  # remove the position from the message
    $ans->{student_ans} =
       protectHTML(substr($string,0,$s)) .
       '<SPAN CLASS="parsehilight">' . 
         protectHTML(substr($string,$s,$e-$s)) .
       '</SPAN>' .
       protectHTML(substr($string,$e));
  }
  $self->cmp_Error($ans,$message);
}

#
#  Set the error message
#
sub cmp_Error {
  my $self = shift; my $ans = shift;
  return unless scalar(@_) > 0;
  $ans->score(0);
  $ans->{ans_message} = $ans->{error_message} = join("\n",@_);
}

#
#  filled in by sub-classes
#
sub cmp_postprocess {}

#
#  Quote HTML characters
#
sub protectHTML {
    my $string = shift;
    $string =~ s/&/\&amp;/g;
    $string =~ s/</\&lt;/g;
    $string =~ s/>/\&gt;/g;
    $string;
}

#
#  names for numbers
#
sub NameForNumber {
  my $self = shift; my $n = shift;
  my $name =  ('zeroth','first','second','third','fourth','fifth',
               'sixth','seventh','eighth','ninth','tenth')[$n];
  $name = "$n-th" if ($n > 10);
  return $name;
}

#
#  Get a value from the safe compartment
#
sub getPG {
  my $self = shift;
  (WeBWorK::PG::Translator::PG_restricted_eval(shift))[0];
}

#############################################################
#############################################################

package Value::Real;

sub cmp_defaults {(
  shift->SUPER::cmp_defaults,
  ignoreStrings => 1,
  ignoreInfinity => 1,
)}

sub typeMatch {
  my $self = shift; my $other = shift; my $ans = shift;
  return 1 unless ref($other);
  return 0 if $other->class eq 'Formula';
  return 1 if $other->type eq 'Infinity' && $ans->{ignoreInfinity};
  if ($other->type eq 'String' && $ans->{ignoreStrings}) {
    $ans->{showEqualErrors} = 0;
    return 1;
  }
  $self->type eq $other->type;
}

#############################################################

package Value::Infinity;

sub cmp_class {'a Number'};

sub cmp_defaults {Value::Real->cmp_defaults};

sub typeMatch {
  my $self = shift; my $other = shift; my $ans = shift;
  return 1 unless ref($other);
  return 0 if $other->class eq 'Formula';
  return 1 if $other->type eq 'Number';
  if ($other->type eq 'String' && $ans->{ignoreStrings}) {
    $ans->{showEqualErrors} = 0;
    return 1;
  }
  $self->type eq $other->type;
}

#############################################################

package Value::String;

sub cmp_defaults {(
  Value::Real->cmp_defaults,
  typeMatch => 'Value::Real',
)}

sub cmp_class {
  my $self = shift; my $ans = shift; my $typeMatch = $ans->{typeMatch};
  return 'a Word' if !Value::isValue($typeMatch) || $typeMatch->class eq 'String';
  return $typeMatch->cmp_class;
};

sub typeMatch {
  my $self = shift; my $other = shift; my $ans = shift;
  return 0 if ref($other) && $other->class eq 'Formula';
  my $typeMatch = $ans->{typeMatch};
  return 1 if !Value::isValue($typeMatch) || $typeMatch->class eq 'String' ||
                 $self->type eq $other->type;
  return $typeMatch->typeMatch($other,$ans);
}

#############################################################

package Value::Point;

sub cmp_defaults {(
  shift->SUPER::cmp_defaults,
  showDimensionHints => 1,
  showCoordinateHints => 1,
)}

sub typeMatch {
  my $self = shift; my $other = shift; my $ans = shift;
  return ref($other) && $other->type eq 'Point' && $other->class ne 'Formula';
}

#
#  Check for dimension mismatch and incorrect coordinates
#
sub cmp_postprocess {
  my $self = shift; my $ans = shift;
  return unless $ans->{score} == 0 && !$ans->{isPreview};
  if ($ans->{showDimensionHints} &&
      $self->length != $ans->{student_value}->length) {
    $self->cmp_Error($ans,"The dimension is incorrect"); return;
  }
  if ($ans->{showCoordinateHints}) {
    my @errors;
    foreach my $i (1..$self->length) {
      push(@errors,"The ".$self->NameForNumber($i)." coordinate is incorrect")
	if ($self->{data}[$i-1] != $ans->{student_value}{data}[$i-1]);
    }
    $self->cmp_Error($ans,@errors); return;
  }
}

#############################################################

package Value::Vector;

sub cmp_defaults {(
  shift->SUPER::cmp_defaults,
  showDimensionHints => 1,
  showCoordinateHints => 1,
  promotePoints => 0,
  parallel => 0,
  sameDirection => 0,
)}

sub typeMatch {
  my $self = shift; my $other = shift; my $ans = shift;
  return 0 unless ref($other) && $other->class ne 'Formula';
  $other = $ans->{student_value} = Value::Vector::promote($other)
    if $ans->{promotePoints} && $other->type eq 'Point';
  return $other->type eq 'Vector';
}

#
#  check for dimension mismatch
#        for parallel vectors, and
#        for incorrect coordinates
#
sub cmp_postprocess {
  my $self = shift; my $ans = shift;
  return unless $ans->{score} == 0;
  if (!$ans->{isPreview} && $ans->{showDimensionHints} &&
      $self->length != $ans->{student_value}->length) {
    $self->cmp_Error($ans,"The dimension is incorrect"); return;
  }
 if ($ans->{parallel} &&
     $self->isParallel($ans->{student_value},$ans->{sameDirection})) {
   $ans->score(1); return;
 }
  if (!$ans->{isPreview} && $ans->{showCoordinateHints}) {
    my @errors;
    foreach my $i (1..$self->length) {
      push(@errors,"The ".$self->NameForNumber($i)." coordinate is incorrect")
	if ($self->{data}[$i-1] != $ans->{student_value}{data}[$i-1]);
    }
    $self->cmp_Error($ans,@errors); return;
  }
}



#############################################################

package Value::Matrix;

sub cmp_defaults {(
  shiftf->SUPER::cmp_defaults,
  showDimensionHints => 1,
  showEqualErrors => 0,
)}

sub typeMatch {
  my $self = shift; my $other = shift; my $ans = shift;
  return 0 unless ref($other) && $other->class ne 'Formula';
  $other = $ans->{student_value} = $self->make($other->{data})
    if $other->class eq 'Point';
  return $other->type eq 'Matrix';
}

sub cmp_postprocess {
  my $self = shift; my $ans = shift;
  return unless $ans->{score} == 0 &&
    !$ans->{isPreview} && $ans->{showDimensionHints};
  my @d1 = $self->dimensions; my @d2 = $ans->{student_value}->dimensions;
  if (scalar(@d1) != scalar(@d2)) {
    $self->cmp_Error($ans,"Matrix dimension is not correct");
    return;
  } else {
    foreach my $i (0..scalar(@d1)-1) {
      if ($d1[$i] != $d2[$i]) {
	$self->cmp_Error($ans,"Matrix dimension is not correct");
	return;
      }
    }
  }
}

#############################################################

package Value::Interval;

sub cmp_defaults {(
  shift->SUPER::cmp_defaults,
  showEndpointHints => 1,
  showEndTypeHints => 1,
)}

sub typeMatch {
  my $self = shift; my $other = shift;
  return 0 unless ref($other) && $other->class ne 'Formula';
  return $other->length == 2 &&
         ($other->{open} eq '(' || $other->{open} eq '[') &&
         ($other->{close} eq ')' || $other->{close} eq ']')
	   if $other->type =~ m/^(Point|List)$/;
  $other->type =~ m/^(Interval|Union)$/;
}

#
#  Check for wrong enpoints and wrong type of endpoints
#
sub cmp_postprocess {
  my $self = shift; my $ans = shift;
  return unless $ans->{score} == 0 && !$ans->{isPreview};
  my $other = $ans->{student_value};
  return unless $other->class eq 'Interval';
  my @errors;
  if ($ans->{showEndpointHints}) {
    push(@errors,"Your left endpoint is incorrect")
      if ($self->{data}[0] != $other->{data}[0]);
    push(@errors,"Your right endpoint is incorrect")
      if ($self->{data}[1] != $other->{data}[1]);
  }
  if (scalar(@errors) == 0 && $ans->{showEndTypeHints}) {
    push(@errors,"The type of interval is incorrect")
      if ($self->{open}.$self->{close} ne $other->{open}.$other->{close});
  }
  $self->cmp_Error($ans,@errors);
}

#############################################################

package Value::Union;

sub typeMatch {
  my $self = shift; my $other = shift;
  return 0 unless ref($other) && $other->class ne 'Formula';
  return $other->length == 2 &&
         ($other->{open} eq '(' || $other->{open} eq '[') &&
         ($other->{close} eq ')' || $other->{close} eq ']')
	   if $other->type =~ m/^(Point|List)$/;
  $other->type =~ m/^(Interval|Union)/;
}

#
#  Use the List checker for unions, in order to get
#  partial credit.  Set the various types for error
#  messages.
#
sub cmp_defaults {(
  Value::List::cmp_defaults(@_),
  typeMatch => 'Value::Interval',
  list_type => 'union',
  entry_type => 'an interval',
)}

sub cmp_equal {Value::List::cmp_equal(@_)}

#############################################################

package Value::List;

sub cmp_defaults {
  my $self = shift;
  return (
    Value::Real->cmp_defaults,
    showHints => undef,
    showLengthHints => undef,
#    partialCredit => undef,
    partialCredit => 0,  #  only allow this once WW can deal with partial credit
    ordered => 0,
    entry_type => undef,
    list_type => lc($self->type),
    typeMatch => Value::makeValue($self->{data}[0]),
    allowParens => 0,
    showParens => 0,
   );
}

#
#  Match anything but formulas
#
sub typeMatch {return !ref($other) || $other->class ne 'Formula'}

#
#  Handle removal of outermost parens in correct answer.
#
sub cmp {
  my $self = shift;
  my $cmp = $self->SUPER::cmp(@_);
  if (!$cmp->{rh_ans}{showParens}) {
    $self->{open} = $self->{close} = '';
    $cmp->ans_hash(correct_ans => $self->stringify);
  }
  return $cmp;
}

sub cmp_equal {
  my $self = shift; my $ans = shift;
  $ans->{showPartialCorrectAnswers} = $self->getPG('$showPartialCorrectAnswers');

  #
  #  get the paramaters
  #
  my $showTypeWarnings = $ans->{showTypeWarnings};
  my $showHints        = getOption($ans,'showHints');
  my $showLengthHints  = getOption($ans,'showLengthHints');
  my $partialCredit    = getOption($ans,'partialCredit');
  my $ordered = $ans->{ordered}; my $allowParens = $ans->{allowParens};
  my $typeMatch = $ans->{typeMatch};
  my $value     = $ans->{entry_type};
  my $ltype     = $ans->{list_type};

  $value = (Value::isValue($typeMatch)? lc($typeMatch->cmp_class): 'value')
    unless defined($value);
  $value =~ s/(real|complex) //; $ans->{cmp_class} = $value; $value =~ s/^an? //;
  $showTypeWarnings = $showHints = $showLengthHints = 0 if $ans->{isPreview};

  #
  #  Get the lists of correct and student answers
  #
  my @correct = $self->value;
  my $student = $ans->{student_value};
  my @student = ($student);
  if ($student->class eq $self->class &&
      ($allowParens || (!$student->{open} && !$student->{close}))) {
    @student = @{$student->{data}};
  } elsif ($student->class eq 'Formula' && $student->type eq 'List') {
    @student = ();
    foreach my $entry (@{$student->{tree}{coords}}) {
      my $v = Parser::Formula($entry);
         $v = Parser::Evaluate($v) if (defined($v) && $v->isConstant);
      #  FIXME:  what if there is an error?
      push(@student,$v);
    }
  }

  #
  #  Initialize the score
  #
  my $maxscore = scalar(@correct);
  my $m = scalar(@student);
  $maxscore = $m if ($m > $maxscore);
  my $score = 0; my @errors; my $i = 0;

  #
  #  Loop through student answers looking for correct ones
  #
  ENTRY: foreach my $entry (@student) {
    $i++;
    $entry = Value::makeValue($entry);
    $entry = Value::Formula->new($entry) if !Value::isValue($entry);
    if ($ordered) {
      if (eval {shift(@correct) == $entry}) {$score++; next ENTRY}
    } else {
      foreach my $k (0..$#correct) {
	if (eval {$correct[$k] == $entry}) {
	  splice(@correct,$k,1);
	  $score++; next ENTRY;
	}
      }
    }
    #
    #  Give messages about incorrect answers
    #
    my $nth = ''; $nth = ' '.$self->NameForNumber($i) if (scalar(@student) > 1);
    if ($showTypeWarnings && !$typeMatch->typeMatch($entry,$ans)) {
      next ENTRY if ($ans->{ignoreStrings} && $entry->class eq 'String');
      push(@errors,"Your$nth value isn't ".lc($ans->{cmp_class}).
	   " (it looks like ".lc($entry->showClass(1)).")");
    } elsif ($showHints && $m > 1) {
      push(@errors,"Your$nth $value is incorrect");
    }
  }

  #
  #  Give hints about extra or missing answsers
  #
  if ($showLengthHints) {
    $value =~ s/ or /s or /; # fix "interval or union"
    push(@errors,"There should be more ${value}s in your $ltype")
      if ($score == $m && scalar(@correct) > 0);
    push(@errors,"There should be fewer ${value}s in your $ltype")
      if ($score < $maxscore && $score == scalar($self->value));
  }

  #
  #  Finalize the score
  #
  $score = 0 if ($score != $maxscore && !$partialCredit);
  $ans->score($score/$maxscore);
  push(@errors,"Score = $ans->{score}") if $ans->{debug};
  $ans->{error_message} = $ans->{ans_message} = join("\n",@errors);
}

#
#  Return the value if it is defined, otherwise use a default
#
sub getOption {
  my $ans = shift; my $name = shift; 
  my $value = $ans->{$name};
  return $value if defined($value);
  return $ans->{showPartialCorrectAnswers};
}

#############################################################

package Value::Formula;

#
#  No cmp function (for now)
#
sub cmp {
  die "Answer checker for formulas is not yet defined";
}

#############################################################

1;
