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

our $cmp_defaults = {
  showTypeWarnings => 1,
  showEqualErrors => 1,
};

sub cmp {
  my $self = shift;
  my $ans = new AnswerEvaluator;
  my $defaults = ref($self)."::cmp_defaults";
  $ans->ans_hash(
    type => "Value (".$self->class.")",
    correct_ans => $self->string,
    correct_value => $self,
    %{$$defaults || $cmp_defaults},
    @_
  );
  $ans->install_evaluator(
    sub {
      my $ans = shift;
      #  can't seem to get $inputs_ref any other way
      $ans->{isPreview} = $self->getPG('$inputs_ref->{previewAnswers}');
      my $self = $ans->{correct_value};
      my $method = $ans->{cmp_check} || 'cmp_check';
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
  my $cmp_postprocess = $ans->{cmp_postprocess};
  #
  #  Parse and evaluate the student answer
  #
  $ans->score(0);  # assume failure
  my $vars = $$Value::context->{variables};
  $$Value::context->{variables} = {}; #  pretend there are no variables
  $ans->{student_formula} = Parser::Formula($ans->{student_ans});
  $ans->{student_value}   = Parser::Evaluate($ans->{student_formula});
  $$Value::context->{variables} = $vars;
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
    $self->$cmp_postprocess($ans) if $cmp_postprocess && !$ans->{error_message};
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
      "Your answer isn't ".lc($ans->{correct_value}->showClass).
        " (it looks like ".lc($ans->{student_value}->showClass).")"
	   if !$ans->{isPreview} && $ans->{showTypeWarnings} && !$ans->{error_message};
  }
}

#
#  Check if types are compatible for equality check
#
sub typeMatch {
  my $self = shift;
  my $other = shift;
  $self->type eq $other->type;
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
  $ans->score(0);
  $ans->{ans_message} = $ans->{error_message} = $message;
}

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
#  Get a value from the safe compartment
#
sub getPG {
  my $self = shift;
  (WeBWorK::PG::Translator::PG_restricted_eval(shift))[0];
}

#############################################################
#############################################################

package Value::Real;

our $cmp_defaults = {
  %{$Value::cmp_defaults},
  ignoreStrings => 1,
};

sub typeMatch {
  my $self = shift; my $other = shift; my $ans = shift;
  return 1 if !ref($other);
  if ($other->type eq 'String' && $ans->{ignoreStrings}) {
    $ans->{showEqualErrors} = 0;
    return 1;
  }
  $self->type eq $other->type;
}

#############################################################

package Value::Point;

our $cmp_defaults = {
  %{$Value::cmp_defaults},
  showDimensionWarnings => 1,
};

sub typeMatch {
  my $self = shift; my $other = shift; my $ans = shift;
  return 0 unless $other->type eq 'Point';
  if (!$ans->{isPreview} && $ans->{showDimensionWarnings} &&
      $self->length != $other->length) {
    $ans->{ans_message} = $ans->{error_message} = "The dimension is incorrect";
    return 0;
  }
  return 1;
}

#############################################################

package Value::Vector;

our $cmp_defaults = {
  %{$Value::cmp_defaults},
  showDimensionWarnings => 1,
  promotePoints => 0,
  parallel => 0,
  sameDirection => 0,
  cmp_postprocess => 'cmp_postprocess',
};

sub typeMatch {
  my $self = shift; my $other = shift; my $ans = shift;
  return 0 unless $other->type eq 'Vector' ||
                  ($ans->{promotePoints} && $other->type eq 'Point');
  if (!$ans->{isPreview} && $ans->{showDimensionWarnings} &&
      $self->length != $other->length) {
    $ans->{ans_message} = $ans->{error_message} = "The dimension is incorrect";
    return 0;
  }
  return 1;
}

#
#  Handle check for parallel vectors
#
sub cmp_postprocess {
  my $self = shift; my $ans = shift;
  return unless $ans->{parallel} && $ans->{score} == 0;
  $ans->score(1) if $self->isParallel($ans->{student_value},$ans->{sameDirection});
}



#############################################################

package Value::Matrix;

our $cmp_defaults = {
  %{$Value::cmp_defaults},
  showDimensionWarnings => 1,
};

sub typeMatch {
  my $self = shift; my $other = shift; my $ans = shift;
  $other = $self->make($other->{data}) if $other->class eq 'Point';
  return 0 unless $other->type eq 'Matrix';
  return 1 unless $ans->{showDimensionWarnings};
  my @d1 = $self->dimensions; my @d2 = $other->dimensions;
  if (scalar(@d1) != scalar(@d2)) {
    $ans->{ans_message} = $ans->{error_message} =
      "Matrix dimension is not correct";
    return 0;
  } else {
    foreach my $i (0..scalar(@d1)-1) {
      if ($d1[$i] != $d2[$i]) {
	$ans->{ans_message} = $ans->{error_message} =
	  "Matrix dimension is not correct";
	return 0;
      }
    }
  }
  return 1;
}

#############################################################

package Value::Interval;

## @@@ report interval-type mismatch? @@@

sub typeMatch {
  my $self = shift; my $other = shift;
  return $other->length == 2 &&
         ($other->{open} eq '(' || $other->{open} eq '[') &&
         ($other->{close} eq ')' || $other->{close} eq ']')
	   if $other->type =~ m/^(Point|List)$/;
  $other->type =~ m/^(Interval|Union)$/;
}

#############################################################

package Value::Union;

sub typeMatch {
  my $self = shift; my $other = shift;
  return $other->length == 2 &&
         ($other->{open} eq '(' || $other->{open} eq '[') &&
         ($other->{close} eq ')' || $other->{close} eq ']')
	   if $other->type =~ m/^(Point|List)$/;
  $other->type =~ m/^(Interval|Union)/;
}

#############################################################

package Value::List;

our $cmp_defaults = {
  %{$Value::cmp_defaults},
  showHints => undef,
  showLengthHints => undef,
#  partialCredit => undef,
  partialCredit => 0,  #  only allow this once WW can deal with partial credit
  ordered => 0,
  entry_type => undef,
  list_type => undef,
  typeMatch => undef,
  allowParens => 0,
};

sub typeMatch {1}

sub cmp_equal {
  my $self = shift; my $ans = shift;
  my $showPartialCorrectAnswers = $self->getPG('$showPartialCorrectAnswers');
  my $showTypeWarnings = $ans->{showTypeWarnings};
  my $showHints = getOption($ans->{showHints},$showPartialCorrectAnswers);
  my $showLengthHints = getOption($ans->{showLengthHints},$showPartialCorrectAnswers);
  my $partialCredit = getOption($ans->{partialCredit},$showPartialCorrectAnswers);
  my $ordered = $ans->{ordered}; my $allowParens = $ans->{allowParens};
  my $typeMatch = $ans->{typeMatch} || $self->{data}[0];
  $typeMatch = Value::Real->make($typeMatch)
    if !ref($typeMatch) && Value::matchNumber($typeMatch);
  my $value = getOption($ans->{entry_type},
      Value::isValue($typeMatch)? lc($typeMatch->showClass): 'value');
  $value =~ s/^an? //; $value =~ s/(real|complex) //;
  my $ltype = getOption($ans->{list_type},lc($self->type));
  $showTypeWarnings = $showHints = $showLengthHints = 0 if $ans->{isPreview};

  my $student = $ans->{student_value};
  my @correct = $self->value;
  my @student =
    $student->class eq 'List' &&
      ($allowParens || (!$student->{open} && !$student->{close})) ?
    @{$student->{data}} : ($student);

  my $maxscore = scalar(@correct);
  my $m = scalar(@student);
  $maxscore = $m if ($m > $maxscore);
  my $score = 0; my @errors; my $i = 0;

  ENTRY: foreach my $entry (@student) {
    $i++;
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
    if ($showTypeWarnings && defined($typeMatch) &&
        !$typeMatch->typeMatch($entry,$ans)) {
      push(@errors,
        "Your ".NameForNumber($i)." value isn't ".lc($typeMatch->showClass).
	   " (it looks like ".lc(Value::showClass($entry)).")");
      next ENTRY;
    }
    push(@errors,"Your ".NameForNumber($i)." $value is incorrect")
      if $showHints && $m > 1;
  }

  if ($showLengthHints) {
    $value =~ s/ or /s or /; # fix "interval or union"
    push(@errors,"There should be more ${value}s in your $ltype")
      if ($score == $m && scalar(@correct) > 0);
    push(@errors,"There should be fewer ${value}s in your $ltype")
      if ($score < $maxscore && $score == scalar($self->value));
  }

  $score = 0 if ($score != $maxscore && !$partialCredit);
  $ans->score($score/$maxscore);
  push(@errors,"Score = $ans->{score}") if $ans->{debug};
  $ans->{error_message} = $ans->{ans_message} = join("\n",@errors);
}

#
#  Return the value if it is defined, otherwise a default
#
sub getOption {
  my $value = shift; my $default = shift;
  return $value if defined($value);
  return $default;
}

#
#  names for numbers
#
sub NameForNumber {
  my $n = shift;
  my $name =  ('zeroth','first','second','third','fourth','fifth',
               'sixth','seventh','eighth','ninth','tenth')[$n];
  $name = "$n-th" if ($n > 10);
  return $name;
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
