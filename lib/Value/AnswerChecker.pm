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
      $ans->{isPreview} = (WeBWorK::PG::Translator::PG_restricted_eval('$inputs_ref->{previewAnswers}'))[0];
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
  my $cmp_equal = $ans->{cmp_equal} || 'cmp_equal';
  my $cmp_error = $ans->{cmp_error} || 'cmp_error';
  my $cmp_postprocess = $ans->{cmp_postprocess};
  $ans->score(0);  # assume failure
  my $vars = $$Value::context->{variables};
  $$Value::context->{variables} = {}; #  pretend there are no variables
  $ans->{student_formula} = Parser::Formula($ans->{student_ans});
  $ans->{student_value}   = Parser::Evaluate($ans->{student_formula});
  $$Value::context->{variables} = $vars;
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
      "Your answer isn't ".$ans->{correct_value}->showClass.
        " (it looks like ".$ans->{student_value}->showClass.")"
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

#############################################################
#############################################################

package Value::Real;

our $cmp_defaults = {
  %{$Value::cmp_defaults},
  ignoreStrings => 1,
};

sub typeMatch {
  my $self = shift; my $other = shift; my $ans = shift;
  if ($other->type eq 'String' && $ans->{ignoreStrings}) {
    $ans->{showEqualErrors} = 0;
    return 1;
  }
  $self->type eq $other->type;
}

#############################################################

package Value::List;

#
#  Lists can be compared to anything
#
sub typeMatch {1}

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

package Value::Formula;

#
#  No cmp function (for now)
#
sub cmp {
  die "Answer checker for formulas is not yet defined";
}

#############################################################

1;
