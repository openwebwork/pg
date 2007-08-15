
=pod

######################################################################
#
#  This file implements a mechanism for allowing a problem file to be
#  "reseeded" so that the student can do additional versions of the
#  problem.  You can control when the reseed message is available,
#  and what style to use for it.
#
#  To use the problemRandimize library, use
#
#      loadMacros("problemRandomize.pl");
#
#  at the top of your problem file, and then create a problemRandomize
#  object with
#
#      $pr = ProblemRandomize(options);
#
#  where '$pr' is the name of the variable you will use to refer
#  to the randomized problem (if needed), and 'options' can include:
#
#    when => type               Specifies the condition on which
#                               reseeding the problem is allowed.
#                               The choices include:
#
#                                 "Correct"   (only when the problem has
#                                              been answered correctly.)
#
#                                 "Always"    (reseeding is always allowed.)
#
#                                 Default:  "Correct"
#
#    onlyAfterDue => 0 or 1     Specifies if the reseed option is only
#                               allowed after the due date has passed.
#                                 Default:  1
#
#    style => type              Determines the type of interaction needed
#                               to reseed the problem.  Types include:
#
#                                 "Button"    (a button)
#
#                                 "Checkbox"  (a checkbox plus pressing submit)
#
#                                 "Input"     (an input box where the seed
#                                              can be set explicitly)
#
#                                 "HTML"      (the HTML is given explicitly
#                                              via the "label" option below)
#
#                                 Default:  "Button"
#
#    label => "text"            Specifies the text used for the button name,
#                               checkbox label, input box label, or raw HTML
#                               used for the reseed mechanism.
#
#  The problemRandomize library installs a special grader that handles determining
#  when the reseed option will be available.  It also redefines install_problem_grader
#  so that it will not overwrite the one installed by the library (it is stored so
#  that it can be called internally by the problemRandomize library's grader).
#
#  Note that the problem will store the new problem seed only if the student can
#  submit saved answers (i.e., only before the due date).  After the due date,
#  the student can get new versions, but the problem will revert to the original
#  version when they come back to the problem later.  Since the default is only
#  to allow reseeding afer the due date, the reseeding will not be sticky by default.
#  Hardcopy ALWAYS produces the original version of the problem, regardless of
#  the seed saved by the student.
#
#  Examples:
#
#    ProblemRandomize();                    # use all defaults
#    ProblemRandomize(when=>"Always");      # always can reseed (after due date)
#    ProblemRandomize(onlyAfterDue=>0);     # can reseed whenever correct
#    ProblemRandomize(when=>"always",onlyAfterDue=>0);    # always can reseed
#
#    ProblemRandomize(style=>"Input");      # use an input box to set the seed
#
#  For problems that include "PGcourse.pl" in their loadMacros() calls, you can
#  use that file to provide reseed buttons for ALL problems simply by including
#
#    loadMacros("problemRandomize.pl");
#    ProblemRandomize();
#
#  in PGcourse.pl.  You can make the ProblemRandomize() be dependent on the set
#  number or the set or the login ID or whatever.  For example
#
#    loadMacros("problemRandomize.pl");
#    ProblemRandomize(when=>"always",onlyAfterDue=>0,style=>"Input")
#      if $studentLogin eq "dpvc";
#
#  would enable reseeding at any time for the user called "dpvc" (presumably a
#  professor).  You can test $probNum and $setNumber to make reseeding available
#  only for specific sets or problems within a set.
#


=cut

sub _problemRandomize_init {
  sub ProblemRandomize {new problemRandomize(@_)}
  PG_restricted_eval(<<'  end_eval');
    sub install_problem_grader {
      return $PG_FLAGS{problemRandomize}->useGrader(@_) if $PG_FLAGS{problemRandomize};
      &{$problemRandomize::installGrader}(@_); # call cached version
    }
  end_eval
}

######################################################################

package problemRandomize;

#
#  The state data that is stored between invocations of
#  the problem.
#
our %defaultStatus = (
  seed => $main::problemSeed,  # original seed
  answers => "",               # list of answer names
  ans_rule_count => 0,         # number of unnamed answers
);

#
#  Cache original grader installer (so we can override it).
#
our $installGrader = \&main::install_problem_grader;

#
#  Create new problemRandomize object from user's data
#  and initialize it.
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $pr = bless {
    when => "Correct",
    onlyAfterDue => 1,
    style => "Button",
    label => undef,
    buttonLabel => "Get a new version of this problem",
    checkboxLabel => "Get a new version of this problem",
    inputLabel => "Set random seed to:",
    grader => $main::PG_FLAGS{PROBLEM_GRADER_TO_USE} || \&main::avg_problem_grader,
    random => $main::PG_random_generator,
    status => {},
    @_
  }, $class;
  $pr->{style} = uc(substr($pr->{style},0,1)) . lc(substr($pr->{style},1));
  $pr->getStatus;
  $pr->initProblem;
  return $pr;
}

#
#  Look up the status from the previous invocation
#  and check to see if a rerandomization is requested
#
sub getStatus {
  my $self = shift;
  main::RECORD_FORM_LABEL("_randomize");
  main::RECORD_FORM_LABEL("_status");
  my $label = $self->{label} || $self->{lc($self->{style})."Label"};
  $self->{status} = $self->decode;
  $self->{submit} = $main::inputs_ref->{submitAnswers};
  $self->{isReset} = $main::inputs_ref->{_randomize} || ($self->{submit} && $self->{submit} eq $label);
  $self->{isReset} = 0 unless !$self->{onlyAfterDue} || time >= $main::dueDate;
}

#
#  Initialize the current problem
#
sub initProblem {
  my $self = shift;
  $main::PG_FLAGS{PROBLEM_GRADER_TO_USE} = \&problemRandomize::grader;
  $main::PG_FLAGS{problemRandomize} = $self;
  $self->reset if $self->{isReset};
  $self->{random}->srand($self->{status}{seed});
}

#
#  Clear the answers and re-randomize the seed
#
sub reset {
  my $self = shift;
  my $status = $self->{status};
  foreach my $id (split(/;/,$status->{answers})) {delete $main::inputs_ref->{$id}}
  foreach my $id (1..$status->{ans_rule_count})
    {delete $main::inputs_ref->{"${main::QUIZ_PREFIX}${main::ANSWER_PREFIX}$id"}}
  $main::inputs_ref->{_status} = $self->encode(\%defaultStatus);
  $main::inputs_ref->{_randomize} = 1;
  $status->{seed} = ($main::inputs_ref->{_seed} || substr(time,5,5));
}

##################################################

#
#  Return the HTML for the "re-randomize" checkbox.
#
sub randomizeCheckbox {
  my $self = shift;
  my $label = shift || $self->{checkboxLabel};
  $label = "<b>$label</b> (when you submit your answers).";
  my $par = shift; $par = ($par ? $main::PAR : '');
  $self->{randomizeInserted} = 1;
  $par . '<input type="checkbox" name="_randomize" value="1" />' . $label;
}

#
#  Return the HTML for the "next part" button.
#
sub randomizeButton {
  my $self = shift;
  my $label = quoteHTML(shift || $self->{buttonLabel});
  my $par = shift; $par = ($par ? $main::PAR : '');
  $par . qq!<input type="submit" name="submitAnswers" value="$label" !
       .      q!onclick="document.getElementById('_randomize').value=1" />!;
}

#
#  Return the HTML for the "problem seed" input box
#
sub randomizeInput {
  my $self = shift;
  my $label = quoteHTML(shift || $self->{inputLabel});
  my $par = shift; $par = ($par ? main::PAR : '');
  $par . qq!<input type="submit" name="submitAnswers" value="$label">!
       . qq!<input name="_seed" value="$self->{status}{seed}" size="10">!;
}

#
#  Return the raw HTML provided
#
sub randomizeHTML {shift; shift}

##################################################

#
#  Encode all the status information so that it can be
#  maintained as the student submits answers.  Since this
#  state information includes things like the score from
#  the previous parts, it is "encrypted" using a dumb
#  hex encoding (making it harder for a student to recognize
#  it as valuable data if they view the page source).
#
sub encode {
  my $self = shift; my $status = shift || $self->{status};
  my @data = (); my $data = "";
  foreach my $id (main::lex_sort(keys(%defaultStatus))) {push(@data,$status->{$id})}
  foreach my $c (split(//,join('|',@data))) {$data .= toHex($c)}
  return $data;
}

#
#  Decode the data and break it into the status hash.
#
sub decode {
  my $self = shift; my $status = shift || $main::inputs_ref->{_status};
  return {%defaultStatus} unless $status;
  my @data = (); foreach my $hex (split(/(..)/,$status)) {push(@data,fromHex($hex)) if $hex ne ''}
  @data = split('\\|',join('',@data)); $status = {%defaultStatus};
  foreach my $id (main::lex_sort(keys(%defaultStatus))) {$status->{$id} = shift(@data)}
  return $status;
}


#
#  Hex encoding is shifted by 10 to obfuscate it further.
#  (shouldn't be a problem since the status will be made of
#  printable characters, so they are all above ASCII 32)
#
sub toHex {main::spf(ord(shift)-10,"%X")}
sub fromHex {main::spf(hex(shift)+10,"%c")}


#
#  Make sure the data can be properly preserved within
#  an HTML <INPUT TYPE="HIDDEN"> tag.
#
sub quoteHTML {
  my $string = shift;
  $string =~ s/&/\&amp;/g; $string =~ s/"/\&quot;/g;
  $string =~ s/>/\&gt;/g;  $string =~ s/</\&lt;/g;
  return $string;
}

##################################################

#
#  Set the grader for this part to the specified one.
#
sub useGrader {
  my $self = shift;
  $self->{grader} = shift;
}

#
#  The custom grader that does the work of computing the scores
#  and saving the data.
#
sub grader {
  my $self = $main::PG_FLAGS{problemRandomize};

  #
  #  Call the original grader
  #
  my ($result,$state) = &{$self->{grader}}(@_);

  #
  #  Update that state information and encode it.
  #
  my $status = $self->{status};
  $status->{ans_rule_count} = $main::ans_rule_count;
  $status->{answers} = join(';',grep(!/${main::QUIZ_PREFIX}${main::ANSWER_PREFIX}/o,keys(%{$_[0]})));
  my $data = quoteHTML($self->encode);

  #
  #  Add the problemRandomize message and data
  #
  $result->{type} = "problemRandomize ($result->{type})";
  if (!$result->{msg}) {
    # hack to remove unwanted "<b>Note: </b>" from the problem
    #  (it is inserted automatically by Problem.pm when {msg} is non-emtpy).
    $result->{msg} .= '<script>var bb = document.getElementsByTagName("b");'
                   .  'bb[bb.length-1].style.display="none"</script>';
  }
  $result->{msg} .= qq!<input type="hidden" name="_status" value="$data" />!;

  #
  #  Include the "randomize" checkbox, button, or whatever.
  #
  if (lc($self->{when}) eq 'always' ||
     (lc($self->{when}) eq 'correct' && $result->{score} >= 1 &&
         !$main::inputs_ref->{previewAnswers})) {
    if (!$self->{onlyAfterDue} || time >= $main::dueDate) {
      my $method = "randomize".$self->{style};
      $result->{msg} .= $self->$method($self->{label},1).'<br/>';
    }
  }

  #
  #  Don't show the summary section if the problem is being reset.
  #
  if ($self->{isReset}) {
    $result->{msg} .= "<style>.problemHeader {display:none}</style>";
    $state->{state_summary_msg} =
       "<b>Note:</b> This is a new (re-randomized) version of the problem.".$main::BR.
       "If you come back to it later, it may revert to its original version.".$main::BR.
       "Hardcopy will always print the original version of the problem.";
  }

  #
  #  Make sure we don't go on unless the next button really is checked
  #
  $result->{msg} .= '<input type="hidden" name="_randomize" value="0" />'
    unless $self->{randomizeInserted};

  return ($result,$state);
}

1;
