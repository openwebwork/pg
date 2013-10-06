
=head1 DESCRIPTION

 #############################################################
 #
 #  Implements the ->cmp method for Value objects.
 #  Otherwise known as MathObjects.  This produces
 #  an answer checker appropriate for the type of object.
 #  Additional options can be passed to the cmp method to
 #  modify its action.
 #
 #   Usage:  $num = Real(3.45); # Real can be replaced by any other MathObject
 #			 ANS($num->cmp(compareOptionName => compareOptionValue, ... ))
 #
 #  The individual Value packages are modified below to add the
 #  needed methods.
 #
 #############################################################

=cut

package Value;
use PGcore;

#
#  Context can add default values to the answer checkers by class;
#
$Value::defaultContext->{cmpDefaults} = {};

=head5 $mathObject->cmp_defaults()

#  Internal use.
#  Set default flags for the answer checker in this object
#       showTypeWarnings         => 1
#       showEqualErrors          => 1
#       ignoreStrings            => 1
#       studentsMustReduceUnions => 1
#       showUnionReduceWarnings  => 1
#

=cut

sub cmp_defaults {(
  showTypeWarnings => 1,
  showEqualErrors  => 1,
  ignoreStrings    => 1,
  studentsMustReduceUnions => 1,
  showUnionReduceWarnings => 1,
)}


#
#  Special Context flags to be set for the student answer
#

sub cmp_contextFlags {
  my $self = shift; my $ans = shift;
  return (
    StringifyAsTeX => 0,                 # reset this, just in case.
    no_parameters => 1,                  # don't let students enter parameters
    showExtraParens => 2,                # make student answer painfully unambiguous
    reduceConstants => 0,                # don't combine student constants
    reduceConstantFunctions => 0,        # don't reduce constant functions
    ($ans->{studentsMustReduceUnions} ?
      (reduceUnions => 0, reduceSets => 0,
       reduceUnionsForComparison => $ans->{showUnionReduceWarnings},
       reduceSetsForComparison => $ans->{showUnionReduceWarnings}) :
      (reduceUnions => 1, reduceSets => 1,
       reduceUnionsForComparison => 1, reduceSetsForComparison => 1)),
    ($ans->{requireParenMatch}? (): ignoreEndpointTypes => 1),  # for Intervals
  );
}


#
#  Create an answer checker for the given type of object
#

sub cmp {
  my $self = shift;
  my $ans = new AnswerEvaluator;
  my $correct = preformat($self->{correct_ans});
  $correct = $self->correct_ans unless defined($correct);
  my $correct_latex = $self->{correct_ans_latex_string};
  $correct_latex = $self->correct_ans_latex unless defined($correct_latex);
  $self->{context} = Value->context unless defined($self->{context});
  $ans->ans_hash(
    type => "Value (".$self->class.")",
    correct_ans => $correct,
    correct_ans_latex_string => $correct_latex,
    correct_value => $self,
    $self->cmp_defaults(@_),
    %{$self->{context}{cmpDefaults}{$self->class} || {}},  # context-specified defaults
    @_,
  );
  $ans->{debug} = $ans->{rh_ans}{debug};
  $ans->install_evaluator(sub {
     my $ans = shift;
     $ans->{_filter_name} = "MathObjects answer checker";
     $ans->{correct_value}->cmp_parse($ans);
  });
  $ans->install_pre_filter('erase') if $self->{ans_name}; # don't do blank check if answer_array
  $self->cmp_diagnostics($ans);
  return $ans;
}

sub correct_ans {preformat(shift->string)}
sub correct_ans_latex {shift->TeX}
sub cmp_diagnostics {}

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
  my $current = Value->context; # save it for later
  my $context = $ans->{correct_value}{context} || $current;
  Parser::Context->current(undef,$context); # change to correct answser's context
  my $flags = contextSet($context,$self->cmp_contextFlags($ans)); # save old context flags
  my $inputs = $self->getPG('$inputs_ref');
  $ans->{isPreview} = $inputs->{previewAnswers} || ($inputs->{action} =~ m/^Preview/);
  $ans->{cmp_class} = $self->cmp_class($ans) unless $ans->{cmp_class};
  $ans->{error_message} = $ans->{ans_message} = ''; # clear any old messages
  $ans->{preview_latex_string} = $ans->{preview_text_string} = '';
  $context->clearError();
  $context->{answerHash} = $ans; # values here can override context flags

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
    $ans->{student_value} = $self->Package("Formula")->new($ans->{student_value})
       unless Value::isValue($ans->{student_value});
    $ans->{student_value}{isStudent} = 1;
    $ans->{preview_latex_string} = $ans->{student_formula}->TeX;
    $ans->{preview_text_string}  = preformat($ans->{student_formula}->string);
    #
    #  Get the string for the student answer
    #
    for ($self->getFlag('formatStudentAnswer')) {
      /evaluated/i  and do {$ans->{student_ans} = preformat($ans->{student_value}->string); last};
      /parsed/i     and do {$ans->{student_ans} = $ans->{preview_text_string}; last};
      /reduced/i    and do {
	my $oldFlags = contextSet($context,reduceConstants=>1,reduceConstantFunctions=>0);
	$ans->{student_ans} = preformat($ans->{student_formula}->substitute()->string);
	contextSet($context,%{$oldFags}); last;
      };
      warn "Unkown student answer format |$ans->{formatStudentAnswer}|";
    }
    if ($self->cmp_collect($ans)) {
      $self->cmp_preprocess($ans);
      $self->cmp_equal($ans);
      $self->cmp_postprocess($ans) if !$ans->{error_message} && !$ans->{typeError};
      $self->cmp_diagnostics($ans);
    }
  } else {
    $self->cmp_collect($ans);
    $self->cmp_error($ans);
  }
  $context->{answerHash} = undef;
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
  } elsif (scalar(@{$array}) == 1) {
    my @d = ($self->classMatch("Matrix") ? $self->dimensions : (1));
    $array = $array->[0] if scalar(@d) == 1;
  }
  my $type = $self;
  $type = $self->Package($self->{tree}->type) if $self->isFormula;
  $ans->{student_formula} = eval {$type->new($array)->with(ColumnVector=>$self->{ColumnVector})};
  if (!defined($ans->{student_formula}) || $self->context->{error}{flag})
    {Parser::reportEvalError($@); $self->cmp_error($ans); return 0}
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
    $self->context->clearError();
    my $equal = $correct->cmp_compare($student,$ans);
    if ($self->context->{error}{flag} != $CMP_MESSAGE &&
        (defined($equal) || !$ans->{showEqualErrors})) {$ans->score(1) if $equal; return}
    $self->cmp_error($ans);
  } else {
    return if $ans->{ignoreStrings} && (!Value::isValue($student) || $student->type eq 'String');
    $ans->{typeError} = 1;
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
our $CMP_MESSAGE = 4; # a message should be reported for this check

sub cmp_compare {
  my $self = shift; my $other = shift; my $ans = shift; my $nth = shift || '';
  my $context = (Value::isValue($self) ? $self->context : Value->context);
  return eval {$self == $other} unless ref($ans->{checker}) eq 'CODE';
  my @equal = eval {&{$ans->{checker}}($self,$other,$ans,$nth,@_)};
  if (!defined($equal) && $@ ne '' && (!$context->{error}{flag} || $ans->{showAllErrors})) {
    $nth = "" if ref($nth) eq 'AnswerHash';
    $context->setError(["<I>An error occurred while checking your$nth answer:</I>\n".
      '<DIV STYLE="margin-left:1em">%s</DIV>',$@],'',undef,undef,$CMP_ERROR);
    warn "Please inform your instructor that an error occurred while checking your answer";
  }
  return (wantarray ? @equal : $equal[0]);
}

sub cmp_list_compare {Value::List::cmp_list_compare(@_)}

#
#  Check if types are compatible for equality check
#
sub typeMatch {
  my $self = shift;  my $other = shift;
  return 1 unless ref($other);
  $self->type eq $other->type && !$other->isFormula;
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
  my $error = $self->context->{error};
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
#  Force a message into the results message column and die
#  (To be used when overriding Parser classes that need
#  to report errors to the student but can't do it in
#  the overridden == since errors are trapped.)
#
sub cmp_Message {
  my $message = shift; my $context = Value->context;
  $message = [$message,@_] if scalar(@_) > 0;
  $context->setError($message,'',undef,undef,$CMP_MESSAGE);
  $message = $context->{error}{message};
  die $message . traceback() if $context->flags('showTraceback');
  die $message . getCaller();
}

#
#  filled in by sub-classes
#
sub cmp_preprocess {}
sub cmp_postprocess {}

#
#  Used to call an object's method as a pre- or post-filter.
#  E.g.,
#     $cmp->install_pre_filter(\&Value::cmp_call_filter,"cmp_prefilter");
#
sub cmp_call_filter {
  my $ans = shift; my $method = shift;
  return $ans->{correct_value}->$method($ans,@_);
}

#
#  Check for unreduced reduced Unions and Sets
#
sub cmp_checkUnionReduce {
  my $self = shift; my $student = shift; my $ans = shift; my $nth = shift || '';
  return unless $ans->{studentsMustReduceUnions} &&
                $ans->{showUnionReduceWarnings} &&
                !$ans->{isPreview} && !Value::isFormula($student);
  return unless $student->isSetOfReals;
  my ($result,$error) = $student->isReduced;
  return unless $error;
  return {
    "overlaps" => "Your$nth union contains overlapping intervals",
    "overlaps in sets" => "Your$nth union contains sets and intervals that overlap",
    "uncombined intervals" => "Your$nth union can be simplified by combining intervals",
    "uncombined sets" => "Your$nth union can be simplified by combining some sets",
    "repeated elements in set" => "Your$nth union contains sets with repeated elements",
    "repeated elements" => "Your$nth set should have no repeated elements",
  }->{$error};
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
  #my $named_extension = pgRef('NAMED_ANS_RULE_EXTENSION');
  my $named_extension = pgRef('NAMED_ANS_ARRAY_EXTENSION');
  my $new_name = sub {@_}; # pgRef('RECORD_EXTRA_ANSWERS');
  my $HTML = ""; my $ename = $name;
  if ($name eq '') {
    #my $n = pgCall('inc_ans_rule_count');
    $name = pgCall('NEW_ANS_NAME',$n);
    #$name = pgCall('NEW_ARRAY_NAME',$n);
    $ename = "${answerPrefix}_${name}_";
  }
  $self->{ans_name} = $ename;
  $self->{ans_rows} = $rows;
  $self->{ans_cols} = $cols;
  my @array = ();
  foreach my $i (0..$rows-1) {
    my @row = ();
    foreach my $j (0..$cols-1) {
      if ($i == 0 && $j == 0) {
	     if ($extend) {
	     	push(@row,&$named_extension(&$new_name($name),$size,ans_label=>$name));
	     	#push(@row,&$named_extension(&$new_name($name),$size))
	     }else {
	     	push(@row,pgCall('NAMED_ANS_RULE',$name,$size))
	     }
      } else {
		push(@row,&$named_extension(&$new_name(ANS_NAME($ename,$i,$j)),$size,ans_label=>$name));
		#push(@row,&$named_extension(&$new_name(ANS_NAME($ename,$i,$j)),$size,ans_label=>$name));
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
  my $self = shift; my $array = shift;
  my $displayMode = $self->getPG('$displayMode');
  $array = [$array] unless ref($array->[0]) eq 'ARRAY';
  return $self->format_matrix_tex($array,@_) if ($displayMode eq 'TeX');
  return $self->format_matrix_HTML($array,@_);
}

sub format_matrix_tex {
  my $self = shift; my $array = shift;
  my %options = (open=>'.',close=>'.',sep=>'',@_);
  $self->{format_options} = [%options] unless $self->{format_options};
  my ($open,$close,$sep) = ($options{open},$options{close},$options{sep});
  my ($rows,$cols) = (scalar(@{$array}),scalar(@{$array->[0]}));
  my $tex = ""; my @rows = ();
  $open = '\\'.$open if $open =~ m/[{}]/; $close = '\\'.$close if $close =~ m/[{}]/;
  $tex .= '\(\left'.$open;
  $tex .= '\setlength{\arraycolsep}{2pt}', $sep = '\,'.$sep if $sep;
  $tex .= '\begin{array}{'.('c'x$cols).'}';
  foreach my $i (0..$rows-1) {push(@rows,join($sep.'&',@{$array->[$i]}))}
  $tex .= join('\cr'."\n",@rows);
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
    $HTML .= '<TR ALIGN="MIDDLE"><TD>'.join($sep,EVALUATE(@{$array->[$i]})).'</TD></TR>'."\n";
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
          . ' STYLE="display:inline;margin:0;vertical-align:-'.(1.1*$rows-.6).'em">'
          . $HTML
          . '</TABLE>';
}

sub EVALUATE {map {(Value::isFormula($_) && $_->isConstant? $_->eval: $_)} @_}

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
  $rule = '\Rule{0pt}{'.(.8*$rows).'em}{0pt}' if $displayMode eq 'HTML_MathJax';
  $rule = '\rule 0pt '.(.8*$rows).'em 0pt' if $displayMode eq 'HTML_jsMath';
  $delim = '\\'.$delim if $delim eq '{' || $delim eq '}';
  return '\(\left'.$delim.$rule.'\right.\)';
}

#
#  Data for tth delimiters [top,mid,bot,rep]
#
$tth_family = "symbol";
my %tth_delim = (
  '[' => ['&#x23A1;','','&#x23A3;','&#x23A2;'],
  ']' => ['&#x23A4;','','&#x23A6;','&#x23A5;'],
  '(' => ['&#x239B;','','&#x239D;','&#x239C;'],
  ')' => ['&#x239E;','','&#x23A0;','&#x239F;'],
  '{' => ['&#x23A7;','&#x23A8;','&#x23A9;','&#x23AA;'],
  '}' => ['&#x23AB;','&#x23AC;','&#x23AD;','&#x23AA;'],
  '|' => ['|','','|','|'],
  '<' => ['&#x27E8;'],
  '>' => ['&#x27E9;'],
  '\lgroup' => ['&#x23A7;','','&#x23A9;','&#x23AA;'],
  '\rgroup' => ['&#x23AB;','','&#x23AD;','&#x23AA;'],
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
  return '<SPAN STYLE="font-family: '.$tth_family.'; '.$size.'margin:0px 2px">'.$c.'</SPAN>'
    if $rows == 1 || scalar(@{$delim}) == 1;
  my $HTML = "";
  if ($delim->[1] eq '') {
    $HTML = join('<BR>',$delim->[0],($delim->[3])x(2*($rows-1)),$delim->[2]);
  } else {
    $HTML = join('<BR>',$delim->[0],($delim->[3])x($rows-1),
		        $delim->[1],($delim->[3])x($rows-1),
		        $delim->[2]);
  }
  return '<DIV STYLE="font-family: '.$tth_family.'; line-height:90%; margin: 0px 2px">'.$HTML.'</DIV>';
}


#
#  Look up the values of the answer array entries, and check them
#  for syntax and other errors.  Build the student answer
#  based on these, and keep track of error messages.
#

my @ans_cmp_defaults = (showCoodinateHints => 0, checker => sub {0});

sub ans_collect {
  my $self = shift; my $ans = shift;
  my $inputs = $self->getPG('$inputs_ref');
  my $blank = ($self->getPG('$displayMode') eq 'TeX') ? '\_\_' : '__';
  my ($rows,$cols) = ($self->{ans_rows},$self->{ans_cols});
  my @array = (); my $data = [$self->value]; my $errors = []; my $OK = 1;
  if ($self->{ColumnVector}) {foreach my $x (@{$data}) {$x = [$x]}}
  $data = [$data] unless ref($data->[0]) eq 'ARRAY';
  foreach my $i (0..$rows-1) {
    my @row = (); my $entry;
    foreach my $j (0..$cols-1) {
      if ($i || $j) {
	$entry = $inputs->{ANS_NAME($self->{ans_name},$i,$j)};
      } else {
	$entry = $ans->{original_student_ans};
	$ans->{student_formula} = $ans->{student_value} = undef unless $entry =~ m/\S/;
      }
      my $result = $data->[$i][$j]->cmp(@ans_cmp_defaults)->evaluate($entry);
      $OK &= entryCheck($result,$blank);
      push(@row,$result->{student_formula});
      entryMessage($result->{ans_message},$errors,$i,$j,$rows,$cols);
    }
    push(@array,[@row]);
  }
  $ans->{student_formula} = [@array];
  $ans->{ans_message} = $ans->{error_message} = "";
  if (scalar(@{$errors})) {
    $ans->{ans_message} = $ans->{error_message} = 
      '<TABLE BORDER="0" CELLSPACING="0" CELLPADDING="0" CLASS="ArrayLayout">'.
      join('<TR><TD HEIGHT="4"></TD></TR>',@{$errors}).
      '</TABLE>';
    $OK = 0;
  }
  return $OK;
}

sub entryMessage {
  my $message = shift; return unless $message;
  my ($errors,$i,$j,$rows,$cols) = @_; $i++; $j++;
  my $title;
  if ($rows == 1) {$title = "In entry $j"}
  elsif ($cols == 1) {$title = "In entry $i"}
  else {$title = "In entry ($i,$j)"}
  push(@{$errors},"<TR VALIGN=\"TOP\"><TD NOWRAP STYLE=\"text-align:right; border:0px\"><I>$title</I>:&nbsp;</TD>".
                  "<TD STYLE=\"text-align:left; border:0px\">$message</TD></TR>");
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
#  Convert newlines to <BR>
#
sub preformat {
  my $string = protectHTML(shift);
  $string =~ s!\n!<br />!g unless eval('$main::displayMode') eq 'TeX';
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

=head3 Value::Real

	Usage ANS( Real(3.56)->cmp() )
		Compares response to a real value using 'fuzzy' comparison
		compareOptions and default values:
			  showTypeWarnings => 1,
			  showEqualErrors  => 1,
			  ignoreStrings    => 1,

=cut


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

=head3 Value::String

	Usage:  $s = String("pole");
		ANS($s->cmp(typeMatch => Complex("4+i")));
		    # compare to response 'pole', don't complain about complex number responses.

		compareOptions and default values:
		  showTypeWarnings => 1,
		  showEqualErrors  => 1,
		  ignoreStrings    => 1,  # don't complain about string-valued responses
		  typeMatch        => 'Value::Real'

	Initial and final spaces are ignored when comparing strings.

=cut

package Value::String;

sub cmp_defaults {(
  Value::Real->cmp_defaults(@_),
  typeMatch => 'Value::Real',
)}

sub cmp_class {
  my $self = shift; my $ans = shift; my $typeMatch = $ans->{typeMatch};
  return 'a Word' if !Value::isValue($typeMatch) || $typeMatch->classMatch('String');
  return $typeMatch->cmp_class;
};

sub typeMatch {
  my $self = shift; my $other = shift; my $ans = shift;
  my $typeMatch = $ans->{typeMatch};
  return &$typeMatch($other,$ans) if ref($typeMatch) eq 'CODE';
  return 1 if !Value::isValue($typeMatch) || $typeMatch->classMatch('String') ||
                 $self->type eq $other->type;
  return $typeMatch->typeMatch($other,$ans);
}

#
#  Remove the blank-check prefilter when the string is empty,
#  and add a filter that removes leading and trailing whitespace.
#
sub cmp {
  my $self = shift;
  my $cmp = $self->SUPER::cmp(@_);
  if ($self->value =~ m/^\s*$/) {
    $cmp->install_pre_filter('erase');
    $cmp->install_pre_filter(sub {
      my $ans = shift;
      $ans->{student_ans} =~ s/^\s+//g;
      $ans->{student_ans} =~ s/\s+$//g;
      return $ans;
    });
  }
  return $cmp;
}

#############################################################

=head3 Value::Point

	Usage: $pt = Point("(3,6)"); # preferred
	       or $pt = Point(3,6);
	       or $pt = Point([3,6]);
	       ANS($pt->cmp());

		compareOptions:
		  showTypeWarnings => 1,   # warns if student response is of incorrect type
		  showEqualErrors  => 1,
		  ignoreStrings    => 1,
		  showDimensionHints => 1, # reports incorrect number of coordinates
		  showCoordinateHints =>1, # flags individual coordinates that are incorrect

=cut

package Value::Point;

sub cmp_defaults {(
  shift->SUPER::cmp_defaults(@_),
  showDimensionHints => 1,
  showCoordinateHints => 1,
)}

sub typeMatch {
  my $self = shift; my $other = shift; my $ans = shift;
  return ref($other) && $other->type eq 'Point' && !$other->isFormula;
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
  my $def = $self->context->lists->get('Point');
  my $open = $self->{open} || $def->{open}; my $close = $self->{close} || $def->{close};
  $self->ans_matrix($extend,$name,1,$self->length,$size,$open,$close,',');
}

sub ans_array {my $self = shift; $self->ANS_MATRIX(0,'',@_)}
sub named_ans_array {my $self = shift; $self->ANS_MATRIX(0,@_)}
sub named_ans_array_extension {my $self = shift; $self->ANS_MATRIX(1,@_)}

#############################################################

=head3 Value::Vector

	Usage:  $vec = Vector("<3,6,7>");
	        or $vec = Vector(3,6,7);
	        or $vec = Vector([3,6,7]);
	        ANS($vec->cmp());

		compareOptions:
		  showTypeWarnings    => 1,   # warns if student response is of incorrect type
		  showEqualErrors     => 1,
		  ignoreStrings       => 1,
		  showDimensionHints  => 1, # reports incorrect number of coordinates
		  showCoordinateHints => 1, # flags individual coordinates which are incorrect
		  promotePoints       => 0, # allow students to enter vectors as points (3,5,6)
		  parallel            => 1, # response is correct if it is parallel to correct answer
		  sameDirection       => 1, # response is correct if it has same orientation as correct answer
		                            #  (only has an effect when parallel => 1 is specified)


=cut

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
  return 0 unless ref($other) && !$other->isFormula;
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
  return unless $ans->{score} == 0 && !$ans->{isPreview};
  my $student = $ans->{student_value};
  return if $ans->{ignoreStrings} && (!Value::isValue($student) || $student->type eq 'String');
  if ($self->length != $student->length) {
    ($self,$student) = $self->cmp_pad($student);
    if ($ans->{showDimensionHints} && $self->length != $student->length) {
      $self->cmp_Error($ans,"The number of coordinates is incorrect"); return;
    }
  }
  if ($ans->{parallel} && !$student->isFormula && !$student->classMatch('String') &&
      $self->isParallel($student,$ans->{sameDirection})) {
    $ans->score(1); return;
  }
  if ($ans->{showCoordinateHints} && !$ans->{parallel}) {
    my @errors;
    foreach my $i (1..$self->length) {
      push(@errors,"The ".$self->NameForNumber($i)." coordinate is incorrect")
	if ($self->{data}[$i-1] != $student->{data}[$i-1]);
    }
    $self->cmp_Error($ans,@errors); return;
  }
}

#
#  Pad the student or correct answer if either is in ijk notation
#  and they are not the same dimension.  Only add zeros when the other one
#  also has zeros in those places.
#
sub cmp_pad {
  my $self = shift; my $student = shift;
  if (($self->getFlag("ijk") || $student->getFlag("ijk")) && $self->getFlag("ijkAnyDimension")) {
    $self = $self->copy; $student = $student->copy;
    while ($self->length > $student->length && $self->{data}[$student->length] == 0)
      {push(@{$student->{data}},Value::Real->new(0))}
    while ($self->length < $student->length && $student->{data}[$self->length] == 0)
      {push(@{$self->{data}},Value::Real->new(0))}
  }
  return ($self,$student);
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
  $def = $self->context->lists->get('Matrix');
  $open = $self->{open} || $def->{open}; $close = $self->{close} || $def->{close};
  return $self->ans_matrix($extend,$name,$self->length,1,$size,$open,$close)
    if ($self->{ColumnVector});
  $def = $self->context->lists->get('Vector');
  $open = $self->{open} || $def->{open}; $close = $self->{close} || $def->{close};
  $self->ans_matrix($extend,$name,1,$self->length,$size,$open,$close,',');
}

sub ans_array {my $self = shift; $self->ANS_MATRIX(0,'',@_)}
sub named_ans_array {my $self = shift; $self->ANS_MATRIX(0,@_)}
sub named_ans_array_extension {my $self = shift; $self->ANS_MATRIX(1,@_)}


#############################################################

=head3 Value::Matrix

	Usage   $ma = Matrix([[3,6],[2,5]]) or $ma =Matrix([3,6],[2,5])
	        ANS($ma->cmp());

		compareOptions:

		  showTypeWarnings    => 1, # warns if student response is of incorrect type
		  showEqualErrors     => 1, # reports messages that occur during element comparisons
		  ignoreStrings       => 1,
		  showDimensionHints  => 1, # reports incorrect number of coordinates
		  showCoordinateHints => 1, # flags individual coordinates which are incorrect


=cut

package Value::Matrix;

sub cmp_defaults {(
  shift->SUPER::cmp_defaults(@_),
  showDimensionHints => 1,
  showEqualErrors => 0,
)}

sub typeMatch {
  my $self = shift; my $other = shift; my $ans = shift;
  return 0 unless ref($other) && !$other->isFormula;
  return $other->type eq 'Matrix' ||
    ($other->type =~ m/^(Point|list)$/ &&
     $other->{open}.$other->{close} eq $self->{open}.$self->{close});
}

sub cmp_preprocess {
  my $self = shift; my $ans = shift;
  my $student = $ans->{student_value};
  return if $student->type ne 'Matrix';
  my @d1 = $self->dimensions; my @d2 = $student->dimensions;
  $ans->{student_value} = $student->make([$student->value])
    if (scalar(@d2) == 1 && scalar(@d1) == 2);
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
  my $def = $self->context->lists->get('Matrix');
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

=head3   Value::Interval

	Usage:    $interval = Interval("(1,2]");
	          or $interval = Interval('(',1,2,']');
	          ANS($inteval->cmp);

		  compareOptions and defaults:
			showTypeWarnings  => 1,
			showEqualErrors   => 1,
			ignoreStrings     => 1,
			showEndpointHints => 1, # show hints about which end point values are correct
			showEndTypeHints  => 1, # show hints about endpoint types
			requireParenMatch => 1,


=cut

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
  if ($error) {$self->context->setError($error,'',undef,undef,$CMP_WARNING); return}
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
  return unless $other->classMatch('Interval');
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

=head3 Value::Set

	Usage:   $set = Set(5,6,'a', 'b')
	      or $set = Set("{5, 6, a, b}")

	      The object is a finite set of real numbers. It can be used with Union and
	      Interval.

	Examples:  Interval("(-inf,inf)") - Set(0)
	           Compute("R-{0}")   # in Interval context: Context("Interval");

=cut

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
  implicitList => 0,
)}

#
#  Use the list checker if the student answer is a set
#    otherwise use the standard compare (to get better
#    error messages).
#
sub cmp_equal {
  my ($self,$ans) = @_;
  return $self->SUPER::cmp_equal($ans) unless $ans->{student_value}->type eq 'Set';
  my $error = $self->cmp_checkUnionReduce($ans->{student_value},$ans);
  if ($error) {$self->cmp_Error($ans,$error); return}
  return Value::List::cmp_equal(@_);
}

#
#  Check for unreduced sets and unions
#
sub cmp_compare {
  my $self = shift; my $student = shift; my $ans = shift;
  my $error = $self->cmp_checkUnionReduce($student,$ans,@_);
  if ($error) {$self->context->setError($error,'',undef,undef,$CMP_WARNING); return}
  $self->SUPER::cmp_compare($student,$ans,@_);
}

#############################################################

=head3 Value::Union

	Usage: $union = Union("[4,5] U [6,7]");
	       or $union = Union(Interval("[4,5]",Interval("[6,7]"));
	       ANS($union->cmp());


=cut

package Value::Union;

sub typeMatch {
  my $self = shift; my $other = shift;
  return 0 unless ref($other) && !$other->isFormula;
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
my $typeMatchInterval = Value::Interval->make(0,1);
sub cmp_defaults {(
  Value::List::cmp_defaults(@_),
  typeMatch => $typeMatchInterval,
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
  if ($error) {$self->context->setError($error,'',undef,undef,$CMP_WARNING); return}
  $self->SUPER::cmp_compare($student,$ans,@_);
}

#############################################################

=head3 Value::List

	Usage:  $lst = List("1, x, <4,5,6>"); # list of a real, a formula and a vector.
	        or $lst = List(Real(1), Formula("x"), Vector(4,5,6));
	        ANS($lst->cmp(showHints=>1));

		compareOptions and defaults:
			showTypeWarnings => 1,
			showEqualErrors  => 1,         # show errors produced when checking equality of entries
			ignoreStrings    => 1,         # don't show type warnings for strings
			studentsMustReduceUnions => 1,
			showUnionReduceWarnings => 1,
			showHints => undef,            # automatically set to 1 if $showPartialCorrectAnswers == 1
			showLengthHints => undef,      # automatically set to 1 if $showPartialCorrectAnswers == 1
			showParenHints => undef,       # automatically set to 1 if $showPartialCorrectAnswers == 1
			partialCredit => undef,        # automatically set to 1 if $showPartialCorrectAnswers == 1
			ordered => 0,                  # 1 = must be in same order as correct answer
			entry_type => undef,           # determined from first entry
			list_type => undef,            # determined automatically
			typeMatch => $element,         # used for type checking the entries
			firstElement => $element,
			extra => undef,                # used to check syntax of incorrect answers
			requireParenMatch => 1,        # student parens must match correct parens
			removeParens => 1,             # remove outermost parens, if any
			implicitList => 1,             # force single answers to be lists (even if they ARE lists)


=cut

package Value::List;

sub cmp_defaults {
  my $self = shift;
  my %options = (@_);
  my $element = Value::makeValue($self->{data}[0],context=>$self->context);
  $element = $self->Package("Formula")->new($element) unless Value::isValue($element);
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
    firstElement => $element,
    extra => undef,
    requireParenMatch => 1,
    removeParens => 1,
    implicitList => 1,
  );
}

#
#  Match anything but formulas
#
sub typeMatch {return !ref($other) || !$other->isFormula}

#
#  Handle removal of outermost parens in correct answer.
#
sub cmp {
  my $self = shift;
  my %params = @_;
  my $cmp = $self->SUPER::cmp(@_);
  if ($cmp->{rh_ans}{removeParens}) {
    $self->{open} = $self->{close} = '';
    $cmp->ans_hash(correct_ans => $self->stringify)
      unless defined($self->{correct_ans}) || defined($params{correct_ans});
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
  my $implicitList      = $ans->{implicitList};
  my $typeMatch         = $ans->{typeMatch};
  my $value             = $ans->{entry_type};
  my $ltype             = $ans->{list_type} || lc($self->type);
  my $stype             = $ans->{short_type} || $ltype;

  $value = (Value::isValue($typeMatch)? lc($typeMatch->cmp_class): 'a value')
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
  if (!$self->isFormula) {
    @correct = $self->value;
    $cOpen = $ans->{correct_value}{open}; $cClose = $ans->{correct_value}{close};
  } else {
    @correct = Value::List->splitFormula($self,$ans);
    $cOpen = $self->{tree}{open}; $cClose = $self->{tree}{close};
  }
  my $student = $ans->{student_value}; my @student = ($student);
  my ($sOpen,$sClose) = ('','');
  if (Value::isFormula($student) && $student->type eq $self->type) {
    if ($implicitList && $student->{tree}{open} ne '') {
      @student = ($student);
    } else {
      @student = Value::List->splitFormula($student,$ans);
      $sOpen = $student->{tree}{open}; $sClose = $student->{tree}{close};
    }
  } elsif (!$student->isFormula && $student->classMatch($self->type)) {
    if ($implicitList && $student->{open} ne '') {
      @student = ($student);
    } else {
      @student = @{$student->{data}};
      $sOpen = $student->{open}; $sClose = $student->{close};
    }
  }
  return if $ans->{split_error};
  foreach my $x (@correct) {$x->{equation} = $self};
  foreach my $x (@student) {$x->{equation} = $self};
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
  my $self = shift; my $context = $self->context;
  my $correct = shift; my $student = shift; my $ans = shift; my $value = shift;
  my @correct = @{$correct}; my @student = @{$student}; my $m = scalar(@student);
  my $ordered = $ans->{ordered};
  my $showTypeWarnings = $ans->{showTypeWarnings} && !$ans->{isPreview};
  my $typeMatch = $ans->{typeMatch};
  my $extra = defined($ans->{extra}) ? $ans->{extra} :
              (Value::isValue($typeMatch) ? $typeMatch: $ans->{firstElement});
  $extra = $self->Package("List")->new() unless defined($extra);
  my $showHints = getOption($ans,'showHints') && !$ans->{isPreview};
  my $error = $context->{error};
  my $score = 0; my @errors; my $i = 0;

  #
  #  Check for empty lists
  #
  if (scalar(@correct) == 0) {$ans->score($m == 0); return}

  #
  #  Loop through student answers looking for correct ones
  #
  ENTRY: foreach my $entry (@student) {
    $i++; $context->clearError;
    $entry = Value::makeValue($entry,$context);
    $entry = $self->Package("Formula")->new($entry) if !Value::isValue($entry);

    #
    #  Some words differ if there is only one entry in the student's list
    #
    my $nth = ''; my $answer = 'answer';
    my $class = $ans->{list_type} || $ans->{cmp_class};
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
	# do syntax check
	if (ref($extra) eq 'CODE') {&$extra($entry,$ans,$nth,$value)}
	  else {$extra->cmp_compare($entry,$ans,$nth,$value)}
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
      $context->clearError;
      # do syntax check
      if (ref($extra) eq 'CODE') {&$extra($entry,$ans,$nth,$value)}
        else {$extra->cmp_compare($entry,$ans,$nth,$value)}
    }
    #
    #  Give messages about incorrect answers
    #
    my $match = (ref($typeMatch) eq 'CODE')? &$typeMatch($entry,$ans) :
                                             $typeMatch->typeMatch($entry,$ans);
    if ($showTypeWarnings && !$match &&
	!($ans->{ignoreStrings} && $entry->classMatch('String'))) {
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
    if (!defined($v)) {$ans->{split_error} = 1; $self->cmp_error($ans); return}
    $v->{equation} = $self;
    push(@formula,$v);
  }
  return @formula;
}

#
#  Override for List ?
#  Return the value if it is defined, otherwise use a default
#
sub getOption {
  my $ans = shift; my $name = shift;
  my $value = $ans->{$name};
  return $value if defined($value);
  return $ans->{showPartialCorrectAnswers};
}

#############################################################

=head3  Value::Formula

	Usage: $fun = Formula("x^2-x+1");
	       $set = Formula("[-1, x) U (x, 2]");

	A formula can have any of the other math object types as its range.
		Union, List, Number (Complex or Real),


=cut

package Value::Formula;

sub cmp_defaults {
  my $self = shift;

  return (
    Value::Union::cmp_defaults($self,@_),
    typeMatch => $self->Package("Formula")->new("(1,2]"),
    showDomainErrors => 1,
  ) if $self->type eq 'Union';

  my $type = $self->type;
  $type = ($self->isComplex? 'Complex': 'Real') if $type eq 'Number';
  $type = $self->Package($type).'::';

  return (
    &{$type.'cmp_defaults'}($self,@_),
    upToConstant => 0,
    showDomainErrors => 1,
  ) if %$type && $self->type ne 'List';
  my $element;
  if ($self->{tree}->class eq 'List') {$element = $self->Package("Formula")->new($self->{tree}{coords}[0])}
    else {$element = $self->Package("Formula")->new(($self->createRandomPoints(1))[1]->[0]{data}[0])}
  return (
    Value::List::cmp_defaults($self,@_),
    removeParens => $self->{autoFormula},
    typeMatch => $element,
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
  my $typeMatch = $self->getTypicalValue($self);
  $other = $self->getTypicalValue($other,1) if Value::isFormula($other);
  return 1 unless defined($other); # can't really tell, so don't report type mismatch
  return 1 if $typeMatch->classMatch('String') && Value::isFormula($ans->{typeMatch});  # avoid infinite loop
  $typeMatch->typeMatch($other,$ans);
}

#
#  Create a value from the formula (so we know the output type)
#
sub getTypicalValue {
  my $self = shift; my $f = shift; my $noError = shift;
  return $f->{test_values}[0] if $f->{test_values};
  my $points = $f->{test_points} || $self->{test_points};
  return ($f->createPointValues($points)||[])->[0] if $points;
  return ((($f->createRandomPoints(1,undef,$noError))[1])||[])->[0];
}

#
#  Handle removal of outermost parens in a list.
#  Evaluate answer, if the eval option is used.
#  Handle the UpToConstant option.
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
    $context->variables->add('C0' => 'Parameter');
    my $f = $self->Package("Formula")->new('C0')+$self;
    for ('limits','test_points','test_values','num_points','granularity','resolution',
	 'checkUndefinedPoints','max_undefined')
      {$f->{$_} = $self->{$_} if defined($self->{$_})}
    $cmp->ans_hash(correct_value => $f);
    Parser::Context->current(undef,$current);
  }
  $cmp->install_pre_filter(\&Value::cmp_call_filter,"cmp_prefilter");
  $cmp->install_post_filter(\&Value::cmp_call_filter,"cmp_postfilter");
  return $cmp;
}

sub cmp_prefilter {
  my $self = shift; my $ans = shift;
  $ans->{_filter_name} = "fetch_previous_answer";
  $ans->{prev_ans} = undef;
  if (defined($ans->{ans_label})) {
    my $label = "previous_".$ans->{ans_label};
    my $inputs = $self->getPG('$inputs_ref');
    if (defined $inputs->{$label} and $inputs->{$label} =~ /\S/) {
      $ans->{prev_ans} = $inputs->{$label};
      #FIXME -- previous answer item is not always being updated in inputs_ref (which comes from formField)
    }
  }
  return $ans;
}

sub cmp_postfilter {
  my $self = shift; my $ans = shift;
  $ans->{_filter_name} = "produce_equivalence_message";
  return $ans if $ans->{ans_message}; # don't overwrite other messages
  return $ans unless defined($ans->{prev_ans}); # if prefilters are erased, don't do this check
  my $context = $self->context;
  $ans->{prev_formula} = Parser::Formula($context,$ans->{prev_ans});
  if (defined($ans->{prev_formula}) && defined($ans->{student_formula})) {
    my $prev = eval {$self->promote($ans->{prev_formula})->inherit($self)}; # inherit limits, etc.
    next unless defined($prev);
    $context->{answerHash} = $ans; # values here can override context flags
    $ans->{prev_equals_current} = Value::cmp_compare($prev,$ans->{student_formula},$ans);
    $context->{answerHash} = undef;
    if (   !$ans->{isPreview}                                 # not preview mode
	and $ans->{prev_equals_current}                       # equivalent
	and $ans->{prev_ans} ne $ans->{original_student_ans}) # but not identical
      {$ans->{ans_message} = "This answer is equivalent to the one you just submitted."}
  }
  return $ans;
}


sub cmp_equal {
  my $self = shift; my $ans = shift;
  #
  #  Get the problem's seed
  #
  $self->{context}->flags->set(
    random_seed => $self->getPG('$problemSeed')
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
  return unless $ans->{score} == 0;
  $self->{context}->clearError;
  eval {$ans->{student_formula}->reduce} if defined($ans->{student_formula}); # check for bad function calls
  $self->cmp_error($ans) if $self->{context}{error}{flag};                    #  and report the error
  return if $ans->{ans_message} || $ans->{isPreview};
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
#  Diagnostics for Formulas
#
sub cmp_diagnostics {
  my $self = shift;  my $ans = shift;
  my $isEvaluator = (ref($ans) =~ /Evaluator/)? 1: 0;
  my $hash = $isEvaluator? $ans->rh_ans : $ans;
  my $diagnostics = $self->{context}->diagnostics->merge("formulas",$self,$hash);
  my $formulas = $diagnostics->{formulas};
  return unless $formulas->{show};

  my $output = "";
  if ($isEvaluator) {
    #
    #  The tests to be performed when the answer checker is created
    #
    $self->getPG('loadMacros("PGgraphmacros.pl")');
    my ($inputs) = $self->getPG('$inputs_ref');
    my $process = $inputs->{checkAnswers} || $inputs->{previewAnswers} || $inputs->{submitAnswers};
    if ($formulas->{checkNumericStability} && !$process) {
      ### still needs to be written
    }
  } else {
    #
    #  The checks to be performed when an answer is submitted
    #
    my $student = $ans->{student_formula};
    #
    #  Get the test points
    #
    my @names = $self->{context}->variables->names;
    my $vx = (keys(%{$self->{variables}}))[0];
    my $vi = 0; while ($names[$vi] ne $vx) {$vi++}
    my $points = [map {$_->[$vi]} @{$self->{test_points}}];
    my @params = $self->{context}->variables->parameters;
       @names = $self->{context}->variables->variables;

    #
    #  The graphs of the functions and errors
    #
    if ($formulas->{showGraphs}) {
      my @G = ();
      if ($formulas->{combineGraphs}) {
	push(@G,$self->cmp_graph($diagnostics,[$student,$self],
				 title=>'Student Answer (red)<BR>Correct Answer (green)<BR>',
				 points=>$points,showDomain=>1));
      } else {
	push(@G,$self->cmp_graph($diagnostics,$self,title=>'Correct Answer'));
	push(@G,$self->cmp_graph($diagnostics,$student,title=>'Student Answer'));
      }
      my $cutoff = $self->Package("Formula")->new($self->getFlag('tolerance'));
      if ($formulas->{graphAbsoluteErrors}) {
	push(@G,$self->cmp_graph($diagnostics,[CORE::abs($self-$student),$cutoff],
				 clip=>$formulas->{clipAbsoluteError},
				 title=>'Absolute Error',points=>$points));
      }
      if ($formulas->{graphRelativeErrors}) {
	push(@G,$self->cmp_graph($diagnostics,[CORE::abs(($self-$student)/$self),$cutoff],
				 clip=>$formulas->{clipRelativeError},
				 title=>'Relative Error',points=>$points));
      }
      $output .= '<TABLE BORDER="0" CELLSPACING="0" CELLPADDING="0">'
	. '<TR VALIGN="TOP">'.join('<TD WIDTH="20"></TD>',@G).'</TR></TABLE>';
    }

    #
    #  The adaptive parameters
    #
    if ($formulas->{showParameters} && scalar(@params) > 0) {
      $output .= '<HR><TABLE BORDER="0" CELLSPACING="0" CELLPADDING="0"><TR><TD>Adaptive Parameters:<BR>';
      $output .= join("<BR>",map {"&nbsp;&nbsp;$params[$_]: ".$self->{parameters}[$_]} (0..$#params));
      $output .= '</TD></TR></TABLE>';
    }

    #
    #  The test points and values
    #
    my @rows = (); my $colsep = '</TD><TD WIDTH="20"></TD><TD ALIGN="RIGHT">';
    my @P = (map {(scalar(@{$_}) == 1)? $_->[0]: $self->Package("Point")->make(@{$_})} @{$self->{test_points}});
    my @i = sort {$P[$a] <=> $P[$b]} (0..$#P);
    foreach $p (@P) {if (Value::isValue($p) && $p->length > 2) {$p = $p->string; $p =~ s|,|,<br />|g}}
    my $zeroLevelTol = $self->{context}{flags}{zeroLevelTol};
    $self->{context}{flags}{zeroLevelTol} = 0; # always show full resolution in the tables below
    my $names = join(',',@names); $names = '('.$names.')' if scalar(@names) > 1;

    $student->createPointValues($self->{test_points},0,1,1) unless $student->{test_values};

    my $cv = $self->{test_values};
    my $sv = $student->{test_values};
    my $av = $self->{test_adapt} || $cv;

    if ($formulas->{showTestPoints}) {
      my @p = ("$names:", (map {$P[$i[$_]]} (0..$#P)));
      push(@rows,'<TR><TD ALIGN="RIGHT">'.join($colsep,@p).'</TD></TR>');
      push(@rows,'<TR><TD ALIGN="RIGHT">'.join($colsep,("<HR>")x scalar(@p)).'</TD></TR>');
      push(@rows,'<TR><TD ALIGN="RIGHT">'
	   .join($colsep,($av == $cv)? "Correct Answer:" : "Adapted Answer:",
		 map {Value::isNumber($av->[$i[$_]])? $av->[$i[$_]]: "undefined"} (0..$#P))
	   .'</TD></TR>');
      push(@rows,'<TR><TD ALIGN="RIGHT">'
	   .join($colsep,"Student Answer:",
		 map {Value::isNumber($sv->[$i[$_]])? $sv->[$i[$_]]: "undefined"} (0..$#P))
	   .'</TD></TR>');
    }
    #
    #  The absolute errors (colored by whether they are ok or too big)
    #
    if ($formulas->{showAbsoluteErrors}) {
      my @p = ("Absolute Error:");
      my $tolerance = $self->getFlag('tolerance');
      my $tolType = $self->getFlag('tolType'); my $error;
      foreach my $j (0..$#P) {
	if (Value::isNumber($sv->[$i[$j]])) {
	  $error = CORE::abs($av->[$i[$j]] - $sv->[$i[$j]]);
	  $error = '<SPAN STYLE="color:#'.($error->value<$tolerance ? '00AA00': 'AA0000').'">'.$error.'</SPAN>'
	    if $tolType eq 'absolute';
	} else {$error = "---"}
	push(@p,$error);
      }
      push(@rows,'<TR><TD ALIGN="RIGHT">'.join($colsep,@p).'</TD></TR>');
    }
    #
    #  The relative errors (colored by whether they are OK or too big)
    #
    if ($formulas->{showRelativeErrors}) {
      my @p = ("Relative Error:");
      my $tolerance = $self->getFlag('tolerance'); my $tol;
      my $tolType = $self->getFlag('tolType'); my $error;
      my $zeroLevel = $self->getFlag('zeroLevel');
      foreach my $j (0..$#P) {
	if (Value::isNumber($sv->[$i[$j]])) {
	  my $c = $av->[$i[$j]]; my $s = $sv->[$i[$j]];
	  if (CORE::abs($cv->[$i[$j]]->value) < $zeroLevel || CORE::abs($s->value) < $zeroLevel)
            {$error = CORE::abs($c-$s); $tol = $zeroLevelTol} else
            {$error = CORE::abs(($c-$s)/($c||1E-10)); $tol = $tolerance}
	  $error = '<SPAN STYLE="color:#'.($error < $tol ? '00AA00': 'AA0000').'">'.$error.'</SPAN>'
	    if $tolType eq 'relative';
	} else {$error = "---"}
	push(@p,$error);
      }
      push(@rows,'<TR><TD ALIGN="RIGHT">'.join($colsep,@p).'</TD></TR>');
    }
    $self->{context}{flags}{zeroLevelTol} = $zeroLevelTol;
    #
    #  Put the data into a table
    #
    if (scalar(@rows)) {
      $output .= '<p><HR><p><TABLE BORDER="0" CELLSPACING="0" CELLPADDING="0">'
	. join('<TR><TD HEIGHT="3"></TD>',@rows)
	. '</TABLE>';
    }
  }
  #
  #  Put all the diagnostic output into a frame
  #
  return unless $output;
  $output 
    = '<TABLE BORDER="1" CELLSPACING="2" CELLPADDING="20" BGCOLOR="#F0F0F0">'
    . '<TR><TD ALIGN="LEFT"><B>Diagnostics for '.$self->string .':</B>'
    . '<P><CENTER>' . $output . '</CENTER></TD></TR></TABLE><P>';
  warn $output;
}

#
#  Draw a graph from a given Formula object
#
sub cmp_graph {
  my $self = shift; my $diagnostics = shift;
  my $F1 = shift; my $F2; ($F1,$F2) = @{$F1} if (ref($F1) eq 'ARRAY');
  #
  #  Get the various options
  #
  my %options = (title=>'',points=>[],@_);
  my $graphs = $diagnostics->{graphs};
  my $limits = $graphs->{limits};
  my $size = $graphs->{size}; $size = [$size,$size] unless ref($size) eq 'ARRAY';
  my $steps = $graphs->{divisions};
  my $points = $options{points}; my $clip = $options{clip};
  my ($my,$My) = (0,0); my ($mx,$Mx); my $dx; my $f; my $y;

  my @pnames = $self->{context}->variables->parameters;
  my @pvalues = ($self->{parameters} ? @{$self->{parameters}} : (0) x scalar(@pnames));
  my $x = "";

  #
  #  Find the max and min values of the function
  #
  foreach $f ($F1,$F2) {
    next unless defined($f);
    foreach my $v (keys(%{$f->{variables}})) {
      if ($v ne $x && !$f->{context}->variables->get($v)->{parameter}) {
	if ($x) {
	  warn "Only formulas with one variable can be graphed" unless $self->{graphWarning};
	  $self->{graphWarning} = 1;
	  return "";
	}
	$x = $v;
      }
    }
    unless ($f->typeRef->{length} == 1) {
      warn "Only real-valued functions can be graphed" unless $self->{graphWarning};
      $self->{graphWarning} = 1;
      return "";
    }

    $x = ($f->{context}->variables->names)[0] unless $x;
    $limits = [$self->getVariableLimits($x)] unless $limits;
    $limits = $limits->[0] while ref($limits) eq 'ARRAY' && ref($limits->[0]) eq 'ARRAY';
    ($mx,$Mx) = @{$limits};
    $dx = ($Mx-$mx)/$steps;

    if ($f->isConstant) {
      $y = $f->eval;
      $my = $y if $y < $my; $My = $y if $y > $My;
    } else {
      my $F = $f->perlFunction(undef,[$x,@pnames]);
      foreach my $i (0..$steps-1) {
        $y = eval {&{$F}($mx+$i*$dx,@pvalues)};
	next unless defined($y) && Value::isNumber($y);
        $my = $y if $y < $my; $My = $y if $y > $My;
      }
    }
  }
  $My = 1 if CORE::abs($My - $my) < 1E-5;
  $my *= 1.1; $My *= 1.1;
  if ($clip) {
    $my = -$clip if $my < -$clip;
    $My = $clip if $My > $clip;
  }
  $my = -$My/10 if $my > -$My/10; $My = -$my/10 if $My < -$my/10;
  my $a = $self->Package("Real")->new(($My-$my)/($Mx-$mx));

  #
  #  Create the graph itself, with suitable title
  #
  my $grf = $self->getPG('$_grf_ = {n => 0}');
  $grf->{Goptions} = [
     $mx,$my,$Mx,$My,
     axes => $graphs->{axes},
     grid => $graphs->{grid},
     size => $size,
  ];
  $grf->{params} = {
    names => [$x,@pnames],
    values => {map {$pnames[$_] => $pvalues[$_]} (0..scalar(@pnames)-1)},
  };
  $grf->{G} = $self->getPG('init_graph(@{$_grf_->{Goptions}})');
  $grf->{G}->imageName($grf->{G}->imageName.'-'.time()); # avoid browser cache
  $self->cmp_graph_function($grf,$F2,"green",$steps,$points) if defined($F2);
  $self->cmp_graph_function($grf,$F1,"red",$steps,$points);
  my $image = $self->getPG('alias(insertGraph($_grf_->{G}))');
  $image = '<IMG SRC="'.$image.'" WIDTH="'.$size->[0].'" HEIGHT="'.$size->[1].'" BORDER="0" STYLE="margin-bottom:5px">';
  my $title = $options{title}; $title .= '<DIV STYLE="margin-top:5px"></DIV>' if $title;
  $title .= "<SMALL>Domain: [$mx,$Mx]</SMALL><BR>" if $options{showDomain};
  $title .= "<SMALL>Range: [$my,$My]<BR>Aspect ratio: $a:1</SMALL>";
  return '<TD ALIGN="CENTER" VALIGN="TOP" NOWRAP>'.$image.'<BR>'.$title.'</TD>';
}

#
#  Add a function to a graph object, and plot the points
#  that are used to test the function
#
sub cmp_graph_function {
  my $self = shift; my $grf = shift; my $F = shift;
  my $color = shift; my $steps = shift; my $points = shift;
  $grf->{n}++; my $Fn = "F".$grf->{n}; $grf->{$Fn} = $F; my $f;
  if ($F->isConstant) {
    my $y = $F->eval;
    $f = $self->getPG('new Fun(sub {'.$y.'},$_grf_->{G})');
  } else {
    my $X = $grf->{params}{names}[0];
    $f = $self->getPG('new Fun(sub {Parser::Evaluate($_grf_->{'.$Fn.'},'
           .$X.'=>shift,%{$_grf_->{params}{values}})},$_grf_->{G})');
    foreach my $x (@{$points}) {
      my $y = Parser::Evaluate($F,($X)=>$x,%{$grf->{params}{values}});
      next unless defined($y) && Value::isNumber($y);
      $grf->{x} = $x; $grf->{'y'} = $y;
      my $C = $self->getPG('new Circle($_grf_->{x},$_grf_->{y},4,"'.$color.'","'.$color.'")');
      $grf->{G}->stamps($C);
    }
  }
  $f->color($color); $f->weight(2); $f->steps($steps);
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
  my $def = $self->context->lists->get($type);
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
#  (this needs to be made more general)
#
sub value {
  my $self = shift;
  return $self unless defined $self->{tree}{coords};
  my $context = $self->context;
  my @array = ();
  if ($self->{tree}->type eq 'Matrix') {
    foreach my $row (@{$self->{tree}->coords}) {
      my @row = ();
      foreach my $x (@{$row->coords}) {push(@row,$context->Package("Formula")->new($context,$x))}
      push(@array,[@row]);
    }
  } else {
    foreach my $x (@{$self->{tree}->coords}) {
      push(@array,$context->Package("Formula")->new($context,$x));
    }
  }
  return @array;
}

#############################################################

1;
