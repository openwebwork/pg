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
  showEqualErrors  => 1,
  ignoreStrings    => 1,
  studentsMustReduceUnions => 1,
  showUnionReduceWarnings => 1,
)}

sub cmp {
  my $self = shift;
  my $ans = new AnswerEvaluator;
  my $correct = protectHTML($self->{correct_ans});
  $correct = $self->correct_ans unless defined($correct);
  $ans->ans_hash(
    type => "Value (".$self->class.")",
    correct_ans => $correct,
    correct_value => $self,
    $self->cmp_defaults(@_),
    @_
  );
  $ans->install_evaluator(sub {$ans = shift; $ans->{correct_value}->cmp_parse($ans)});
  $ans->install_pre_filter('erase') if $self->{ans_name}; # don't do blank check if answer_array
  $self->{context} = $$Value::context unless defined($self->{context});
  return $ans;
}

sub correct_ans {protectHTML(shift->string)}

#
#  Parse the student answer and compute its value,
#    produce the preview strings, and then compare the
#    student and professor's answers for equality.
#
sub cmp_parse {
  my $self = shift; my $ans = shift;
  #
  #  Do some setup
  #
  my $current = $$Value::context; # save it for later
  my $context = $ans->{correct_value}{context} || $current;
  Parser::Context->current(undef,$context); # change to correct answser's context
  my $flags = contextSet($context, # save old context flags for the below
    StringifyAsTeX => 0,             # reset this, just in case.
    no_parameters => 1,              # don't let students enter parameters
    showExtraParens => 1,            # make student answer painfully unambiguous
    reduceConstants => 0,            # don't combine student constants
    reduceConstantFunctions => 0,    # don't reduce constant functions
    ($ans->{studentsMustReduceUnions} ?
      (reduceUnions => 0, reduceSets => 0,
       reduceUnionsForComparison => $ans->{showUnionReduceWarnings},
       reduceSetsForComparison => $ans->{showUnionReduceWarnings}) :
      (reduceUnions => 1, reduceSets => 1,
       reduceUnionsForComparison => 1, reduceSetsForComparison => 1)),
    ($ans->{requireParenMatch}? (): ignoreEndpointTypes => 1),  # for Intervals
    $self->cmp_contextFlags($ans),   # any additional ones from the object itself
  );
  my $inputs = $self->getPG('$inputs_ref',{action=>""});
  $ans->{isPreview} = $inputs->{previewAnswers} || ($inputs->{action} =~ m/^Preview/);
  $ans->{cmp_class} = $self->cmp_class($ans) unless $ans->{cmp_class};
  $ans->{error_message} = $ans->{ans_message} = ''; # clear any old messages
  $ans->{preview_latex_string} = $ans->{preview_text_string} = '';

  #
  #  Parse and evaluate the student answer
  #
  $ans->score(0);  # assume failure
  $ans->{student_value} = $ans->{student_formula} = Parser::Formula($ans->{student_ans});
  $ans->{student_value} = Parser::Evaluate($ans->{student_formula})
    if defined($ans->{student_formula}) && $ans->{student_formula}->isConstant;

  #
  #  If it parsed OK, save the output forms and check if it is correct
  #   otherwise report an error
  #
  if (defined $ans->{student_value}) {
    $ans->{student_value} = Value::Formula->new($ans->{student_value})
       unless Value::isValue($ans->{student_value});
    $ans->{preview_latex_string} = $ans->{student_formula}->TeX;
    $ans->{preview_text_string}  = protectHTML($ans->{student_formula}->string);
    $ans->{student_ans}          = $ans->{preview_text_string};
    if ($self->cmp_collect($ans)) {
      $self->cmp_equal($ans);
      $self->cmp_postprocess($ans) if !$ans->{error_message};
    }
  } else {
    $self->cmp_error($ans);
    $self->cmp_collect($ans);  ## FIXME: why is this here a second time?
  }
  contextSet($context,%{$flags});            # restore context values
  Parser::Context->current(undef,$current);  # put back the old context
  return $ans;
}

#
#  Check if the object has an answer array and collect the results
#  Build the combined student answer and set the preview values
#
sub cmp_collect {
  my $self = shift; my $ans = shift;
  return 1 unless $self->{ans_name};
  $ans->{preview_latex_string} = $ans->{preview_text_string} = "";
  my $OK = $self->ans_collect($ans);
  $ans->{student_ans} = $self->format_matrix($ans->{student_formula},@{$self->{format_options}},tth_delims=>1);
  return 0 unless $OK;
  my $array = $ans->{student_formula};
  if ($self->{ColumnVector}) {
    my @V = (); foreach my $x (@{$array}) {push(@V,$x->[0])}
    $array = [@V];
  } elsif (scalar(@{$array}) == 1) {$array = $array->[0]}
  my $type = $self;
  $type = "Value::".$self->{tree}->type if $self->class eq 'Formula';
  $ans->{student_formula} = eval {$type->new($array)->with(ColumnVector=>$self->{ColumnVector})};
  if (!defined($ans->{student_formula}) || $$Value::context->{error}{flag}) 
    {Parser::reportEvalError($@); return 0}
  $ans->{student_value} = $ans->{student_formula};
  $ans->{preview_text_string} = $ans->{student_ans};
  $ans->{preview_latex_string} = $ans->{student_formula}->TeX;
  if (Value::isFormula($ans->{student_formula}) && $ans->{student_formula}->isConstant) {
    $ans->{student_value} = Parser::Evaluate($ans->{student_formula});
    return 0 unless $ans->{student_value};
  }
  return 1;
}

#
#  Check if the parsed student answer equals the professor's answer
#
sub cmp_equal {
  my $self = shift; my $ans = shift;
  my $correct = $ans->{correct_value};
  my $student = $ans->{student_value};
  if ($correct->typeMatch($student,$ans)) {
    my $equal = $correct->cmp_compare($student,$ans);
    if (defined($equal) || !$ans->{showEqualErrors}) {$ans->score(1) if $equal; return}
    $self->cmp_error($ans);
  } else {
    return if $ans->{ignoreStrings} && (!Value::isValue($student) || $student->type eq 'String');
    $ans->{ans_message} = $ans->{error_message} =
      "Your answer isn't ".lc($ans->{cmp_class})."\n".
        "(it looks like ".lc($student->showClass).")"
	   if !$ans->{isPreview} && $ans->{showTypeWarnings} && !$ans->{error_message};
  }
}

#
#  Perform the comparison, either using the checker supplied
#  by the answer evaluator, or the overloaded == operator.
#

our $CMP_ERROR = 2;   # a fatal error was detected
our $CMP_WARNING = 3; # a warning was produced

sub cmp_compare {
  my $self = shift; my $other = shift; my $ans = shift; my $nth = shift || '';
  return eval {$self == $other} unless ref($ans->{checker}) eq 'CODE';
  my $equal = eval {&{$ans->{checker}}($self,$other,$ans,$nth,@_)};
  if (!defined($equal) && $@ ne '' && (!$$Value::context->{error}{flag} || $ans->{showAllErrors})) {
    $$Value::context->setError(["<I>An error occurred while checking your$nth answer:</I>\n".
      '<DIV STYLE="margin-left:1em">%s</DIV>',$@],'',undef,undef,$CMP_ERROR);
    warn "Please inform your instructor that an error occurred while checking your answer";
  }
  return $equal;
}

sub cmp_list_compare {Value::List::cmp_list_compare(@_)}

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
  my $class = $self->showClass; $class =~ s/Real //;
  return $class if $class =~ m/Formula/;
  return "an Interval, Set or Union" if $self->isSetOfReals;
  return $class; 
}

#
#  Student answer evaluation failed.
#  Report the error, with formatting, if possible.
#
sub cmp_error {
  my $self = shift; my $ans = shift;
  my $error = $$Value::context->{error};
  my $message = $error->{message};
  if ($error->{pos}) {
    my $string = $error->{string};
    my ($s,$e) = @{$error->{pos}};
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
sub cmp_contextFlags {return ()}

#
#  Check for unreduced reduced Unions and Sets
#
sub cmp_checkUnionReduce {
  my $self = shift; my $student = shift; my $ans = shift; my $nth = shift || '';
  return unless $ans->{studentsMustReduceUnions} &&
                $ans->{showUnionReduceWarnings} &&
                !$ans->{isPreview} && !Value::isFormula($student);
  if ($student->type eq 'Union' && $student->length >= 2) {
    my $reduced = $student->reduce;
    return "Your$nth union can be written in a simpler form"
      unless $reduced->type eq 'Union' && $reduced->length == $student->length;
    my @R = $reduced->sort->value;
    my @S = $student->sort->value;
    foreach my $i (0..$#R) {
      return "Your$nth union can be written in a simpler form"
	unless $R[$i] == $S[$i] && $R[$i]->length == $S[$i]->length;
    }
  } elsif ($student->type eq 'Set' && $student->length >= 2) {
    return "Your$nth set should have no repeated elements"
      unless $student->reduce->length == $student->length;
  }
  return;
}

#
#  create answer rules of various types
#
sub ans_rule {shift; pgCall('ans_rule',@_)}
sub named_ans_rule {shift; pgCall('NAMED_ANS_RULE',@_)}
sub named_ans_rule_extension {shift; pgCall('NAMED_ANS_RULE_EXTENSION',@_)}
sub ans_array {shift->ans_rule(@_)};
sub named_ans_array {shift->named_ans_rule(@_)};
sub named_ans_array_extension {shift->named_ans_rule_extension(@_)};

sub pgCall {my $call = shift; &{WeBWorK::PG::Translator::PG_restricted_eval('\&'.$call)}(@_)}
sub pgRef {WeBWorK::PG::Translator::PG_restricted_eval('\&'.shift)}

our $answerPrefix = "MaTrIx";

#
#  Lay out a matrix of answer rules
#
sub ans_matrix {
  my $self = shift;
  my ($extend,$name,$rows,$cols,$size,$open,$close,$sep) = @_;
  my $named_extension = pgRef('NAMED_ANS_RULE_EXTENSION');
  my $new_name = pgRef('RECORD_FORM_LABEL');
  my $HTML = ""; my $ename = $name;
  if ($name eq '') {
    my $n = pgCall('inc_ans_rule_count');
    $name = pgCall('NEW_ANS_NAME',$n);
    $ename = $answerPrefix.$n;
  }
  $self->{ans_name} = $ename;
  $self->{ans_rows} = $rows;
  $self->{ans_cols} = $cols;
  my @array = ();
  foreach my $i (0..$rows-1) {
    my @row = ();
    foreach my $j (0..$cols-1) {
      if ($i == 0 && $j == 0) {
	if ($extend) {push(@row,&$named_extension(&$new_name($name),$size))}
	        else {push(@row,pgCall('NAMED_ANS_RULE',$name,$size))}
      } else {
	push(@row,&$named_extension(&$new_name(ANS_NAME($ename,$i,$j)),$size));
      }
    }
    push(@array,[@row]);
  }
  $self->format_matrix([@array],open=>$open,close=>$close,sep=>$sep);
}

sub ANS_NAME {
  my ($name,$i,$j) = @_;
  $name.'_'.$i.'_'.$j;
}


#
#  Lay out an arbitrary matrix
#
sub format_matrix {
  my $self = shift;
  my $displayMode = $self->getPG('$displayMode');
  return $self->format_matrix_tex(@_) if ($displayMode eq 'TeX');
  return $self->format_matrix_HTML(@_);
}

sub format_matrix_tex {
  my $self = shift; my $array = shift;
  my %options = (open=>'.',close=>'.',sep=>'',@_);
  $self->{format_options} = [%options] unless $self->{format_options};
  my ($open,$close,$sep) = ($options{open},$options{close},$options{sep});
  my ($rows,$cols) = (scalar(@{$array}),scalar(@{$array->[0]}));
  my $tex = "";
  $open = '\\'.$open if $open =~ m/[{}]/; $close = '\\'.$close if $close =~ m/[{}]/;
  $tex .= '\(\left'.$open;
  $tex .= '\setlength{\arraycolsep}{2pt}', $sep = '\,'.$sep if $sep;
  $tex .= '\begin{array}{'.('c'x$cols).'}';
  foreach my $i (0..$rows-1) {$tex .= join($sep.'&',@{$array->[$i]}).'\cr'."\n"}
  $tex .= '\end{array}\right'.$close.'\)';
  return $tex;
}

sub format_matrix_HTML {
  my $self = shift; my $array = shift;
  my %options = (open=>'',close=>'',sep=>'',tth_delims=>0,@_);
  $self->{format_options} = [%options] unless $self->{format_options};
  my ($open,$close,$sep) = ($options{open},$options{close},$options{sep});
  my ($rows,$cols) = (scalar(@{$array}),scalar(@{$array->[0]}));
  my $HTML = "";
  if ($sep) {$sep = '</TD><TD STYLE="padding: 0px 1px">'.$sep.'</TD><TD>'}
       else {$sep = '</TD><TD WIDTH="8px"></TD><TD>'}
  foreach my $i (0..$rows-1) {
    $HTML .= '<TR><TD HEIGHT="6px"></TD></TR>' if $i;
    $HTML .= '<TR ALIGN="MIDDLE"><TD>'.join($sep,@{$array->[$i]}).'</TD></TR>'."\n";
  }
  $open = $self->format_delimiter($open,$rows,$options{tth_delims});
  $close = $self->format_delimiter($close,$rows,$options{tth_delims});
  if ($open ne '' || $close ne '') {
    $HTML = '<TR ALIGN="MIDDLE">'
          . '<TD>'.$open.'</TD>'
          . '<TD WIDTH="2"></TD>'
          . '<TD><TABLE BORDER="0" CELLSPACING="0" CELLPADDING="0" CLASS="ArrayLayout">'
          .   $HTML
          . '</TABLE></TD>'
          . '<TD WIDTH="4"></TD>'
          . '<TD>'.$close.'</TD>'
          . '</TR>'."\n";
  }
  return '<TABLE BORDER="0" CELLSPACING="0" CELLPADDING="0" CLASS="ArrayLayout"'
          . ' STYLE="display:inline;vertical-align:-'.(1.1*$rows-.6).'em">'
          . $HTML
          . '</TABLE>';
}

sub VERBATIM {
  my $string = shift;
  my $displayMode = Value->getPG('$displayMode');
  $string = '\end{verbatim}'.$string.'\begin{verbatim}' if $displayMode eq 'TeX';
  return $string;
}

#
#  Create a tall delimiter to match the line height
#
sub format_delimiter {
  my $self = shift; my $delim = shift; my $rows = shift; my $tth = shift;
  return '' if $delim eq '' || $delim eq '.';
  my $displayMode = $self->getPG('$displayMode');
  return $self->format_delimiter_tth($delim,$rows,$tth)
    if $tth || $displayMode eq 'HTML_tth' || $displayMode !~ m/^HTML_/;
  my $rule = '\vrule width 0pt height '.(.8*$rows).'em depth 0pt';
  $rule = '\rule 0pt '.(.8*$rows).'em 0pt' if $displayMode eq 'HTML_jsMath';
  $delim = '\\'.$delim if $delim eq '{' || $delim eq '}';
  return '\(\left'.$delim.$rule.'\right.\)';
}

#
#  Data for tth delimiters [top,mid,bot,rep]
#
my %tth_delim = (
  '[' => ['&#xF8EE;','','&#xF8F0;','&#xF8EF;'],
  ']' => ['&#xF8F9;','','&#xF8FB;','&#xF8FA;'],
  '(' => ['&#xF8EB;','','&#xF8ED;','&#xF8EC;'],
  ')' => ['&#xF8F6;','','&#xF8F8;','&#xF8F7;'],
  '{' => ['&#xF8F1;','&#xF8F2;','&#xF8F3;','&#xF8F4;'],
  '}' => ['&#xF8FC;','&#xF8FD;','&#xF8FE;','&#xF8F4;'],
  '|' => ['|','','|','|'],
  '<' => ['&lt;'],
  '>' => ['&gt;'],
  '\lgroup' => ['&#xF8F1;','','&#xF8F3;','&#xF8F4;'],
  '\rgroup' => ['&#xF8FC;','','&#xF8FE;','&#xF8F4;'],
);

#
#  Make delimiters as stacks of characters
#
sub format_delimiter_tth {
  my $self = shift;
  my $delim = shift; my $rows = shift; my $tth = shift;
  return '' if $delim eq '' || !defined($tth_delim{$delim});
  my $c = $delim; $delim = $tth_delim{$delim};
  $c = $delim->[0] if scalar(@{$delim}) == 1;
  my $size = ($tth? "": "font-size:175%; ");
  return '<SPAN STYLE="'.$size.'margin:0px 2px">'.$c.'</SPAN>'
    if $rows == 1 || scalar(@{$delim}) == 1;
  my $HTML = "";
  if ($delim->[1] eq '') {
    $HTML = join('<BR>',$delim->[0],($delim->[3])x(2*($rows-1)),$delim->[2]);
  } else {
    $HTML = join('<BR>',$delim->[0],($delim->[3])x($rows-1),
		        $delim->[1],($delim->[3])x($rows-1),
		        $delim->[2]);
  }
  return '<DIV STYLE="line-height:90%; margin: 0px 2px">'.$HTML.'</DIV>';
}


#
#  Look up the values of the answer array entries, and check them
#  for syntax and other errors.  Build the student answer
#  based on these, and keep track of error messages.
#

my @ans_defaults = (showCoodinateHints => 0, checker => sub {0});

sub ans_collect {
  my $self = shift; my $ans = shift;
  my $inputs = $self->getPG('$inputs_ref');
  my $blank = ($self->getPG('$displayMode') eq 'TeX') ? '\_\_' : '__';
  my ($rows,$cols) = ($self->{ans_rows},$self->{ans_cols});
  my @array = (); my $data = [$self->value]; my $errors = []; my $OK = 1;
  if ($self->{ColumnVector}) {foreach my $x (@{$data}) {$x = [$x]}}
  $data = [$data] unless ref($data->[0]) eq 'ARRAY';
  foreach my $i (0..$rows-1) {
    my @row = ();
    foreach my $j (0..$cols-1) {
      if ($i || $j) {
	my $entry = $inputs->{ANS_NAME($self->{ans_name},$i,$j)};
	my $result = $data->[$i][$j]->cmp(@ans_cmp_defaults)->evaluate($entry);
	$OK &= entryCheck($result,$blank);
	push(@row,$result->{student_formula});
	entryMessage($result->{ans_message},$errors,$i,$j,$rows);
      } else {
	$ans->{student_formula} = $ans->{student_value} = undef unless $ans->{student_ans} =~ m/\S/;
	$OK &= entryCheck($ans,$blank);
	push(@row,$ans->{student_formula});
	entryMessage($ans->{ans_message},$errors,$i,$j,$rows);
      }
    }
    push(@array,[@row]);
  }
  $ans->{student_formula} = [@array];
  $ans->{ans_message} = $ans->{error_message} = join("<BR>",@{$errors});
  return $OK && scalar(@{$errors}) == 0;
}

sub entryMessage {
  my $message = shift; return unless $message;
  my ($errors,$i,$j,$rows) = @_; $i++; $j++;
  if ($rows == 1) {$message = "Coordinate $j: $message"}
    else {$message = "Entry ($i,$j): $message"}
  push(@{$errors},$message);
}

sub entryCheck {
  my $ans = shift; my $blank = shift;
  return 1 if defined($ans->{student_value});
  if (!defined($ans->{student_formula})) {
    $ans->{student_formula} = $ans->{student_ans};
    $ans->{student_formula} = $blank unless $ans->{student_formula};
  }
  return 0
}


#
#  Get and Set values in context
#
sub contextSet {
  my $context = shift; my %set = (@_);
  my $flags = $context->{flags}; my $get = {};
  foreach my $id (keys %set) {$get->{$id} = $flags->{$id}; $flags->{$id} = $set{$id}}
  return $get;
}

#
#  Quote HTML characters
#
sub protectHTML {
    my $string = shift;
    return unless defined($string);
    return $string if eval ('$main::displayMode') eq 'TeX';
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
#  (WeBWorK::PG::Translator::PG_restricted_eval(shift))[0];
  eval ('package main; '.shift);  # faster
}

#############################################################
#############################################################

package Value::Real;

sub cmp_defaults {(
  shift->SUPER::cmp_defaults(@_),
  ignoreInfinity => 1,
)}

sub typeMatch {
  my $self = shift; my $other = shift; my $ans = shift;
  return 1 unless ref($other);
  return 0 if Value::isFormula($other);
  return 1 if $other->type eq 'Infinity' && $ans->{ignoreInfinity};
  $self->type eq $other->type;
}

#############################################################

package Value::Infinity;

sub cmp_class {'a Number'};

sub typeMatch {
  my $self = shift; my $other = shift; my $ans = shift;
  return 1 unless ref($other);
  return 0 if Value::isFormula($other);
  return 1 if $other->type eq 'Number';
  $self->type eq $other->type;
}

#############################################################

package Value::String;

sub cmp_defaults {(
  Value::Real->cmp_defaults(@_),
  typeMatch => 'Value::Real',
)}

sub cmp_class {
  my $self = shift; my $ans = shift; my $typeMatch = $ans->{typeMatch};
  return 'a Word' if !Value::isValue($typeMatch) || $typeMatch->class eq 'String';
  return $typeMatch->cmp_class;
};

sub typeMatch {
  my $self = shift; my $other = shift; my $ans = shift;
  return 0 if ref($other) && Value::isFormula($other);
  my $typeMatch = $ans->{typeMatch};
  return 1 if !Value::isValue($typeMatch) || $typeMatch->class eq 'String' ||
                 $self->type eq $other->type;
  return $typeMatch->typeMatch($other,$ans);
}

#############################################################

package Value::Point;

sub cmp_defaults {(
  shift->SUPER::cmp_defaults(@_),
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
  my $student = $ans->{student_value};
  return if $ans->{ignoreStrings} && (!Value::isValue($student) || $student->type eq 'String');
  if ($ans->{showDimensionHints} && $self->length != $student->length) {
    $self->cmp_Error($ans,"The number of coordinates is incorrect"); return;
  }
  if ($ans->{showCoordinateHints}) {
    my @errors;
    foreach my $i (1..$self->length) {
      push(@errors,"The ".$self->NameForNumber($i)." coordinate is incorrect")
	if ($self->{data}[$i-1] != $student->{data}[$i-1]);
    }
    $self->cmp_Error($ans,@errors); return;
  }
}

sub correct_ans {
  my $self = shift;
  return $self->SUPER::correct_ans unless $self->{ans_name};
  Value::VERBATIM($self->format_matrix([[@{$self->{data}}]],@{$self->{format_options}},tth_delims=>1));
}

sub ANS_MATRIX {
  my $self = shift;
  my $extend = shift; my $name = shift;
  my $size = shift || 5;
  my $def = ($self->{context} || $$Value::context)->lists->get('Point');
  my $open = $self->{open} || $def->{open}; my $close = $self->{close} || $def->{close};
  $self->ans_matrix($extend,$name,1,$self->length,$size,$open,$close,',');
}

sub ans_array {my $self = shift; $self->ANS_MATRIX(0,'',@_)}
sub named_ans_array {my $self = shift; $self->ANS_MATRIX(0,@_)}
sub named_ans_array_extension {my $self = shift; $self->ANS_MATRIX(1,@_)}

#############################################################

package Value::Vector;

sub cmp_defaults {(
  shift->SUPER::cmp_defaults(@_),
  showDimensionHints => 1,
  showCoordinateHints => 1,
  promotePoints => 0,
  parallel => 0,
  sameDirection => 0,
)}

sub typeMatch {
  my $self = shift; my $other = shift; my $ans = shift;
  return 0 unless ref($other) && $other->class ne 'Formula';
  return $other->type eq 'Vector' ||
     ($ans->{promotePoints} && $other->type eq 'Point');
}

#
#  check for dimension mismatch
#        for parallel vectors, and
#        for incorrect coordinates
#
sub cmp_postprocess {
  my $self = shift; my $ans = shift;
  return unless $ans->{score} == 0;
  my $student = $ans->{student_value};
  return if $ans->{ignoreStrings} && (!Value::isValue($student) || $student->type eq 'String');
  if (!$ans->{isPreview} && $ans->{showDimensionHints} &&
      $self->length != $student->length) {
    $self->cmp_Error($ans,"The number of coordinates is incorrect"); return;
  }
  if ($ans->{parallel} &&
      $self->isParallel($student,$ans->{sameDirection})) {
    $ans->score(1); return;
  }
  if (!$ans->{isPreview} && $ans->{showCoordinateHints} && !$ans->{parallel}) {
    my @errors;
    foreach my $i (1..$self->length) {
      push(@errors,"The ".$self->NameForNumber($i)." coordinate is incorrect")
	if ($self->{data}[$i-1] != $student->{data}[$i-1]);
    }
    $self->cmp_Error($ans,@errors); return;
  }
}

sub correct_ans {
  my $self = shift;
  return $self->SUPER::correct_ans unless $self->{ans_name};
  return Value::VERBATIM($self->format_matrix([[$self->value]],@{$self->{format_options}},tth_delims=>1))
    unless $self->{ColumnVector};
  my @array = (); foreach my $x ($self->value) {push(@array,[$x])}
  return Value::VERBATIM($self->format_matrix([@array],@{$self->{format_options}},tth_delims=>1));
}

sub ANS_MATRIX {
  my $self = shift;
  my $extend = shift; my $name = shift;
  my $size = shift || 5; my ($def,$open,$close);
  $def = ($self->{context} || $$Value::context)->lists->get('Matrix');
  $open = $self->{open} || $def->{open}; $close = $self->{close} || $def->{close};
  return $self->ans_matrix($extend,$name,$self->length,1,$size,$open,$close)
    if ($self->{ColumnVector});
  $def = ($self->{context} || $$Value::context)->lists->get('Vector');
  $open = $self->{open} || $def->{open}; $close = $self->{close} || $def->{close};
  $self->ans_matrix($extend,$name,1,$self->length,$size,$open,$close,',');
}

sub ans_array {my $self = shift; $self->ANS_MATRIX(0,'',@_)}
sub named_ans_array {my $self = shift; $self->ANS_MATRIX(0,@_)}
sub named_ans_array_extension {my $self = shift; $self->ANS_MATRIX(1,@_)}


#############################################################

package Value::Matrix;

sub cmp_defaults {(
  shift->SUPER::cmp_defaults(@_),
  showDimensionHints => 1,
  showEqualErrors => 0,
)}

sub typeMatch {
  my $self = shift; my $other = shift; my $ans = shift;
  return 0 unless ref($other) && $other->class ne 'Formula';
  return $other->type eq 'Matrix' ||
    ($other->type =~ m/^(Point|list)$/ &&
     $other->{open}.$other->{close} eq $self->{open}.$self->{close});
}

sub cmp_postprocess {
  my $self = shift; my $ans = shift;
  return unless $ans->{score} == 0 &&
    !$ans->{isPreview} && $ans->{showDimensionHints};
  my $student = $ans->{student_value};
  return if $ans->{ignoreStrings} && (!Value::isValue($student) || $student->type eq 'String');
  my @d1 = $self->dimensions; my @d2 = $student->dimensions;
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

sub correct_ans {
  my $self = shift;
  return $self->SUPER::correct_ans unless $self->{ans_name};
  my @array = $self->value; @array = ([@array]) if $self->isRow;
  Value::VERBATIM($self->format_matrix([$self->value],@{$self->{format_options}},tth_delims=>1));
}

sub ANS_MATRIX {
  my $self = shift;
  my $extend = shift; my $name = shift;
  my $size = shift || 5;
  my $def = ($self->{context} || $$Value::context)->lists->get('Matrix');
  my $open = $self->{open} || $def->{open}; my $close = $self->{close} || $def->{close};
  my @d = $self->dimensions;
  Value::Error("Can't create ans_array for %d-dimensional matrix",scalar(@d))
    if (scalar(@d) > 2);
  @d = (1,@d) if (scalar(@d) == 1);
  $self->ans_matrix($extend,$name,@d,$size,$open,$close,'');
}

sub ans_array {my $self = shift; $self->ANS_MATRIX(0,'',@_)}
sub named_ans_array {my $self = shift; $self->ANS_MATRIX(0,@_)}
sub named_ans_array_extension {my $self = shift; $self->ANS_MATRIX(1,@_)}

#############################################################

package Value::Interval;

sub cmp_defaults {(
  shift->SUPER::cmp_defaults(@_),
  showEndpointHints => 1,
  showEndTypeHints => 1,
  requireParenMatch => 1,
)}

sub typeMatch {
  my $self = shift; my $other = shift;
  return 0 if !Value::isValue($other) || $other->isFormula;
  return $other->canBeInUnion;
}

#
#  Check for unreduced sets and unions
#
sub cmp_compare {
  my $self = shift; my $student = shift; my $ans = shift;
  my $error = $self->cmp_checkUnionReduce($student,$ans,@_);
  if ($error) {$$Value::context->setError($error,'',undef,undef,$CMP_WARNING); return}
  $self->SUPER::cmp_compare($student,$ans,@_);
}

#
#  Check for wrong enpoints and wrong type of endpoints
#
sub cmp_postprocess {
  my $self = shift; my $ans = shift;
  return unless $ans->{score} == 0 && !$ans->{isPreview};
  my $other = $ans->{student_value};
  return if $ans->{ignoreStrings} && (!Value::isValue($other) || $other->type eq 'String');
  return unless $other->class eq 'Interval';
  my @errors;
  if ($ans->{showEndpointHints}) {
    push(@errors,"Your left endpoint is incorrect")
      if ($self->{data}[0] != $other->{data}[0]);
    push(@errors,"Your right endpoint is incorrect")
      if ($self->{data}[1] != $other->{data}[1]);
  }
  if (scalar(@errors) == 0 && $ans->{showEndTypeHints} && $ans->{requireParenMatch}) {
    push(@errors,"The type of interval is incorrect")
      if ($self->{open}.$self->{close} ne $other->{open}.$other->{close});
  }
  $self->cmp_Error($ans,@errors);
}

#############################################################

package Value::Set;

sub typeMatch {
  my $self = shift; my $other = shift;
  return 0 if !Value::isValue($other) || $other->isFormula;
  return $other->canBeInUnion;
}

#
#  Use the List checker for sets, in order to get
#  partial credit.  Set the various types for error
#  messages.
#
sub cmp_defaults {(
  Value::List::cmp_defaults(@_),
  typeMatch => 'Value::Real',
  list_type => 'a set',
  entry_type => 'a number',
  removeParens => 0,
  showParenHints => 1,
)}

#
#  Use the list checker if the student answer is a set
#    otherwise use the standard compare (to get better
#    error messages).
#
sub cmp_equal {
  my ($self,$ans) = @_;
  return Value::List::cmp_equal(@_) if $ans->{student_value}->type eq 'Set';
  $self->SUPER::cmp_equal($ans);
}

#
#  Check for unreduced sets and unions
#
sub cmp_compare {
  my $self = shift; my $student = shift; my $ans = shift;
  my $error = $self->cmp_checkUnionReduce($student,$ans,@_);
  if ($error) {$$Value::context->setError($error,'',undef,undef,$CMP_WARNING); return}
  $self->SUPER::cmp_compare($student,$ans,@_);
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
  $other->isSetOfReals;
}

#
#  Use the List checker for unions, in order to get
#  partial credit.  Set the various types for error
#  messages.
#
sub cmp_defaults {(
  Value::List::cmp_defaults(@_),
  typeMatch => 'Value::Interval',
  list_type => 'an interval, set or union',
  short_type => 'a union',
  entry_type => 'an interval or set',
)}

sub cmp_equal {
  my $self = shift; my $ans = shift;
  my $error = $self->cmp_checkUnionReduce($ans->{student_value},$ans);
  if ($error) {$self->cmp_Error($ans,$error); return}
  Value::List::cmp_equal($self,$ans);
}

#
#  Check for unreduced sets and unions
#
sub cmp_compare {
  my $self = shift; my $student = shift; my $ans = shift;
  my $error = $self->cmp_checkUnionReduce($student,$ans,@_);
  if ($error) {$$Value::context->setError($error,'',undef,undef,$CMP_WARNING); return}
  $self->SUPER::cmp_compare($student,$ans,@_);
}

#############################################################

package Value::List;

sub cmp_defaults {
  my $self = shift;
  my %options = (@_);
  my $element = Value::makeValue($self->{data}[0]);
  $element = Value::Formula->new($element) unless Value::isValue($element);
  return (
    Value::Real->cmp_defaults(@_),
    showHints => undef,
    showLengthHints => undef,
    showParenHints => undef,
    partialCredit => undef,
    ordered => 0,
    entry_type => undef,
    list_type => undef,
    typeMatch => $element,
    extra => $element,
    requireParenMatch => 1,
    removeParens => 1,
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
  if ($cmp->{rh_ans}{removeParens}) {
    $self->{open} = $self->{close} = '';
    $cmp->ans_hash(correct_ans => $self->stringify)
      unless defined($self->{correct_ans});
  }
  return $cmp;
}

sub cmp_equal {
  my $self = shift; my $ans = shift;
  $ans->{showPartialCorrectAnswers} = $self->getPG('$showPartialCorrectAnswers');

  #
  #  get the paramaters
  #
  my $showHints         = getOption($ans,'showHints');
  my $showLengthHints   = getOption($ans,'showLengthHints');
  my $showParenHints    = getOption($ans,'showParenHints');
  my $partialCredit     = getOption($ans,'partialCredit');
  my $requireParenMatch = $ans->{requireParenMatch};
  my $typeMatch         = $ans->{typeMatch};
  my $value             = $ans->{entry_type};
  my $ltype             = $ans->{list_type} || lc($self->type);
  my $stype             = $ans->{short_type} || $ltype;

  $value = (Value::isValue($typeMatch)? lc($typeMatch->cmp_class): 'value')
    unless defined($value);
  $value =~ s/(real|complex) //; $ans->{cmp_class} = $value;
  $value =~ s/^an? //; $value = 'formula' if $value =~ m/formula/;
  $ltype =~ s/^an? //; $stype =~ s/^an? //;
  $showHints = $showLengthHints = 0 if $ans->{isPreview};

  #
  #  Get the lists of correct and student answers
  #   (split formulas that return lists or unions)
  #
  my @correct = (); my ($cOpen,$cClose);
  if ($self->class ne 'Formula') {
    @correct = $self->value;
    $cOpen = $ans->{correct_value}{open}; $cClose = $ans->{correct_value}{close};
  } else {
    @correct = Value::List->splitFormula($self,$ans);
    $cOpen = $self->{tree}{open}; $cClose = $self->{tree}{close};
  }
  my $student = $ans->{student_value}; my @student = ($student);
  my ($sOpen,$sClose) = ('','');
  if (Value::isFormula($student) && $student->type eq $self->type) {
    @student = Value::List->splitFormula($student,$ans);
    $sOpen = $student->{tree}{open}; $sClose = $student->{tree}{close};
  } elsif ($student->class ne 'Formula' && $student->class eq $self->type) {
    @student = @{$student->{data}};
    $sOpen = $student->{open}; $sClose = $student->{close};
  }
  return if $ans->{split_error};
  #
  #  Check for parenthesis match
  #
  if ($requireParenMatch && ($sOpen ne $cOpen || $sClose ne $cClose)) {
    if ($showParenHints && !($ans->{ignoreStrings} && $student->type eq 'String')) {
      my $message = "The parentheses for your $ltype ";
      if (($cOpen || $cClose) && ($sOpen || $sClose))
                                {$message .= "are of the wrong type"}
      elsif ($sOpen || $sClose) {$message .= "should be removed"}
      else                      {$message .= "seem to be missing"}
      $self->cmp_Error($ans,$message) unless $ans->{isPreview};
    }
    return;
  }

  #
  #  Determine the maximum score
  #
  my $M = scalar(@correct);
  my $m = scalar(@student);
  my $maxscore = ($m > $M)? $m : $M;

  #
  #  Compare the two lists
  #  (Handle errors in user-supplied functions)
  #
  my ($score,@errors);
  if (ref($ans->{list_checker}) eq 'CODE') {
    eval {($score,@errors) = &{$ans->{list_checker}}([@correct],[@student],$ans,$value)};
    if (!defined($score)) {
      die $@ if $@ ne '' && $self->{context}{error}{flag} == 0;
      $self->cmp_error($ans) if $self->{context}{error}{flag};
    }
  } else {
    ($score,@errors) = $self->cmp_list_compare([@correct],[@student],$ans,$value);
  }
  return unless defined($score);

  #
  #  Give hints about extra or missing answers
  #
  if ($showLengthHints) {
    $value =~ s/( or|,) /s$1 /g; # fix "interval or union"
    push(@errors,"There should be more ${value}s in your $stype")
      if ($score < $maxscore && $score == $m);
    push(@errors,"There should be fewer ${value}s in your $stype")
      if ($score < $maxscore && $score == $M && !$showHints);
  }

  #
  #  If all the entries are in error, don't give individual messages
  #
  if ($score == 0) {
    my $i = 0;
    while ($i <= $#errors) {
      if ($errors[$i++] =~ m/^Your .* is incorrect$/)
        {splice(@errors,--$i,1)}
    }
  }

  #
  #  Finalize the score
  #
  $score = 0 if ($score != $maxscore && !$partialCredit);
  $ans->score($score/$maxscore);
  push(@errors,"Score = $ans->{score}") if $ans->{debug};
  my $error = join("\n",@errors); $error =~ s!</DIV>\n!</DIV>!g;
  $ans->{error_message} = $ans->{ans_message} = $error;
}

#
#  Compare the contents of the list to see of they are equal
#
sub cmp_list_compare {
  my $self = shift;
  my $correct = shift; my $student = shift; my $ans = shift; my $value = shift;
  my @correct = @{$correct}; my @student = @{$student}; my $m = scalar(@student);
  my $ordered = $ans->{ordered};
  my $showTypeWarnings = $ans->{showTypeWarnings} && !$ans->{isPreview};
  my $typeMatch = $ans->{typeMatch};
  my $extra = $ans->{extra};
  my $showHints = getOption($ans,'showHints') && !$ans->{isPreview};
  my $error = $$Value::context->{error};
  my $score = 0; my @errors; my $i = 0;

  #
  #  Check for empty lists
  #
  if (scalar(@correct) == 0) {$ans->score($m == 0); return}

  #
  #  Loop through student answers looking for correct ones
  #
  ENTRY: foreach my $entry (@student) {
    $i++; $$Value::context->clearError;
    $entry = Value::makeValue($entry);
    $entry = Value::Formula->new($entry) if !Value::isValue($entry);

    #
    #  Some words differ if ther eis only one entry in the student's list
    #
    my $nth = ''; my $answer = 'answer';
    my $class = $ans->{list_type} || $self->cmp_class;
    if ($m > 1) {
      $nth = ' '.$self->NameForNumber($i);
      $class = $ans->{cmp_class};
      $answer = 'value';
    }

    #
    #  See if the entry matches the correct answer
    #  and perform syntax checking if not
    #
    if ($ordered) {
      if (scalar(@correct)) {
	if (shift(@correct)->cmp_compare($entry,$ans,$nth,$value)) {$score++; next ENTRY}
      } else {
	$extra->cmp_compare($entry,$ans,$nth,$value); # do syntax check
      }
      if ($error->{flag} == $CMP_ERROR) {$self->cmp_error($ans); return}
    } else {
      foreach my $k (0..$#correct) {
	if ($correct[$k]->cmp_compare($entry,$ans,$nth,$value)) {
	  splice(@correct,$k,1);
	  $score++; next ENTRY;
	}
	if ($error->{flag} == $CMP_ERROR) {$self->cmp_error($ans); return}
      }
      $$Value::context->clearError;
      $extra->cmp_compare($entry,$ans,$nth,$value); # do syntax check
    }
    #
    #  Give messages about incorrect answers
    #
    if ($showTypeWarnings && !$typeMatch->typeMatch($entry,$ans) &&
	     !($ans->{ignoreStrings} && $entry->class eq 'String')) {
      push(@errors,"Your$nth $answer isn't ".lc($class).
	   " (it looks like ".lc($entry->showClass).")");
    } elsif ($error->{flag} && $ans->{showEqualErrors}) {
      my $message = $error->{message}; $message =~ s/\s+$//;
      if ($m > 1 && $error->{flag} != $CMP_WARNING) {
        push(@errors,"<SMALL>There is a problem with your$nth $value:</SMALL>",
	             '<DIV STYLE="margin-left:1em">'.$message.'</DIV>');
      } else {push(@errors,$message)}
    } elsif ($showHints && $m > 1) {
      push(@errors,"Your$nth $value is incorrect");
    }
  }

  #
  #  Return the score and errors
  #
  return ($score,@errors);
}

#
#  Split a formula that is a list or union into a
#    list of formulas (or Value objects).
#
sub splitFormula {
  my $self = shift; my $formula = shift; my $ans = shift;
  my @formula; my @entries;
  if ($formula->type eq 'Union') {@entries = $formula->{tree}->makeUnion}
    else {@entries = @{$formula->{tree}{coords}}}
  foreach my $entry (@entries) {
    my $v = Parser::Formula($entry);
       $v = Parser::Evaluate($v) if (defined($v) && $v->isConstant);
    push(@formula,$v);
    #
    #  There shouldn't be an error evaluating the formula,
    #    but you never know...
    #
    if (!defined($v)) {$ans->{split_error} = 1; $self->cmp_error; return}
  }
  return @formula;
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

sub cmp_defaults {
  my $self = shift;

  return (
    Value::Union::cmp_defaults($self,@_),
    typeMatch => Value::Formula->new("(1,2]"),
    showDomainErrors => 1,
  ) if $self->type eq 'Union';

  my $type = $self->type;
  $type = ($self->isComplex)? 'Complex': 'Real' if $type eq 'Number';
  $type = 'Value::'.$type.'::';

  return (
    &{$type.'cmp_defaults'}($self,@_),
    upToConstant => 0,
    showDomainErrors => 1,
  ) if defined(%$type) && $self->type ne 'List';

  return (
    Value::List::cmp_defaults($self,@_),
    removeParens => $self->{autoFormula},
    typeMatch => Value::Formula->new(($self->createRandomPoints(1))[1]->[0]{data}[0]),
    showDomainErrors => 1,
  );
}

#
#  Get the types from the values of the formulas
#     and compare those.
#
sub typeMatch {
  my $self = shift; my $other = shift; my $ans = shift;
  return 1 if $self->type eq $other->type;
  my $typeMatch = ($self->createRandomPoints(1))[1]->[0];
  $other = eval {($other->createRandomPoints(1))[1]->[0]} if Value::isFormula($other);
  return 1 unless defined($other); # can't really tell, so don't report type mismatch
  $typeMatch->typeMatch($other,$ans);
}

#
#  Handle removal of outermost parens in a list.
#
sub cmp {
  my $self = shift;
  my $cmp = $self->SUPER::cmp(@_);
  if ($cmp->{rh_ans}{removeParens} && $self->type eq 'List') {
    $self->{tree}{open} = $self->{tree}{close} = '';
    $cmp->ans_hash(correct_ans => $self->stringify)
      unless defined($self->{correct_ans});
  }
  if ($cmp->{rh_ans}{eval} && $self->isConstant) {
    $cmp->ans_hash(correct_value => $self->eval);
    return $cmp;
  }
  if ($cmp->{rh_ans}{upToConstant}) {
    my $current = Parser::Context->current();
    my $context = $self->{context} = $self->{context}->copy;
    Parser::Context->current(undef,$context);
    $context->{_variables}->{pattern} = $context->{_variables}->{namePattern} =
      'C0|' . $context->{_variables}->{pattern};
    $context->update; $context->variables->add('C0' => 'Parameter');
    my $f = Value::Formula->new('C0')+$self;
    for ('limits','test_points','test_values','num_points','granularity','resolution',
	 'checkUndefinedPoints','max_undefined')
      {$f->{$_} = $self->{$_} if defined($self->{$_})}
    $cmp->ans_hash(correct_value => $f);
    Parser::Context->current(undef,$current);
  }
  return $cmp;
}

sub cmp_equal {
  my $self = shift; my $ans = shift;
  #
  #  Get the problem's seed
  #
  $self->{context}->flags->set(
    random_seed => $self->getPG('$PG_original_problemSeed')
  );

  #
  #  Use the list checker if the formula is a list or union
  #    Otherwise use the normal checker
  #
  if ($self->type =~ m/^(List|Union|Set)$/) {
    Value::List::cmp_equal($self,$ans);
  } else {
    $self->SUPER::cmp_equal($ans);
  }
}

sub cmp_postprocess {
  my $self = shift; my $ans = shift;
  return unless $ans->{score} == 0 && !$ans->{isPreview};
  return if $ans->{ans_message};
  if ($self->{domainMismatch} && $ans->{showDomainErrors}) {
    $self->cmp_Error($ans,"The domain of your function doesn't match that of the correct answer");
    return;
  }
  return if !$ans->{showDimensionHints};
  my $other = $ans->{student_value};
  return if $ans->{ignoreStrings} && (!Value::isValue($other) || $other->type eq 'String');
  return unless $other->type =~ m/^(Point|Vector|Matrix)$/;
  return unless $self->type  =~ m/^(Point|Vector|Matrix)$/;
  return if Parser::Item::typeMatch($self->typeRef,$other->typeRef);
  $self->cmp_Error($ans,"The dimension of your result is incorrect");
}

#
#  If an answer array was used, get the data from the
#  Matrix, Vector or Point, and format the array of
#  data using the original parameter
#
sub correct_ans {
  my $self = shift;
  return $self->SUPER::correct_ans unless $self->{ans_name};
  my @array = ();
  if ($self->{tree}->type eq 'Matrix') {
    foreach my $row (@{$self->{tree}{coords}}) {
      my @row = ();
      foreach my $x (@{$row->coords}) {push(@row,$x->string)}
      push(@array,[@row]);
    }
  } else {
    foreach my $x (@{$self->{tree}{coords}}) {push(@array,$x->string)}
    if ($self->{tree}{ColumnVector}) {foreach my $x (@array) {$x = [$x]}}
      else {@array = [@array]}
  }
  Value::VERBATIM($self->format_matrix([@array],@{$self->{format_options}},tth_delims=>1));
}

#
#  Get the size of the array and create the appropriate answer array
#
sub ANS_MATRIX {
  my $self = shift;
  my $extend = shift; my $name = shift;
  my $size = shift || 5; my $type = $self->type; 
  my $cols = $self->length; my $rows = 1; my $sep = ',';
  if ($type eq 'Matrix') {
    $sep = ''; $rows = $cols; $cols = $self->{tree}->typeRef->{entryType}{length};
  }
  if ($self->{tree}{ColumnVector}) {
    $sep = ""; $type = "Matrix";
    my $tmp = $rows; $rows = $cols; $cols = $tmp;
    $self->{ColumnVector} = 1;
  }
  my $def = ($self->{context} || $$Value::context)->lists->get($type);
  my $open = $self->{open} || $self->{tree}{open} || $def->{open};
  my $close = $self->{close} || $self->{tree}{close} || $def->{close};
  $self->ans_matrix($extend,$name,$rows,$cols,$size,$open,$close,$sep);
}

sub ans_array {
  my $self = shift;
  return $self->SUPER::ans_array(@_) unless $self->array_OK;
  $self->ANS_MATRIX(0,'',@_);
}
sub named_ans_array {
  my $self = shift;
  return $self->SUPER::named_ans_array(@_) unless $self->array_OK;
  $self->ANS_MATRIX(0,@_);
}
sub named_ans_array_extension {
  my $self = shift;
  return $self->SUPER::named_ans_array_extension(@_) unless $self->array_OK;
  $self->ANS_MATRIX(1,@_);
}

sub array_OK {
  my $self = shift; my $tree = $self->{tree};
  return $tree->type =~ m/^(Point|Vector|Matrix)$/ && $tree->class eq 'List';
}

#
#  Get an array of values from a Matrix, Vector or Point
#
sub value {
  my $self = shift;
  my @array = ();
  if ($self->{tree}->type eq 'Matrix') {
    foreach my $row (@{$self->{tree}->coords}) {
      my @row = ();
      foreach my $x (@{$row->coords}) {push(@row,Value::Formula->new($x))}
      push(@array,[@row]);
    }
  } else {
    foreach my $x (@{$self->{tree}->coords}) {
      push(@array,Value::Formula->new($x));
    }
  }
  return @array;
}

#############################################################

1;
