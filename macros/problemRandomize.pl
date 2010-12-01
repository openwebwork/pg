################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/problemRandomize.pl,v 1.12 2009/06/25 23:28:44 gage Exp $
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

problemRandomize.pl - Reseed a problem so that students can do additional versions for
more practice.

=head1 DESCRIPTION

This file implements a mechanism for allowing a problem file to be
"reseeded" so that the student can do additional versions of the
problem.  You can control when the reseed message is available,
and what style to use for it.

To use the problemRandimize library, use

	loadMacros("problemRandomize.pl");

at the top of your problem file, and then create a problemRandomize
object with

	$pr = ProblemRandomize(options);

where '$pr' is the name of the variable you will use to refer
to the randomized problem (if needed), and 'options' can include:

=over

=item C<S<< when => type >>>

Specifies the condition on which
reseeding the problem is allowed.
The choices include:

=over

=item *

C<Correct> - only when the problem has been answered correctly.

=item *

C<Always> - reseeding is always allowed.

=back

Default: "Correct"

=item C<S<< onlyAfterDue => 0 or 1 >>>

Specifies if the reseed option is only
allowed after the due date has passed.
Default:  1

=item C<S<< style => type >>>

Determines the type of interaction needed
to reseed the problem.  Types include:

=over

=item *

C<Button> - a button.

=item *

C<Checkbox> - a checkbox plus pressing submit.

=item *

C<Input> - an input box where the seed can be set explicitly.

=item *

C<HTML> - the HTML is given explicitly via the "label" option below.

=back

Default:  "Button"

=item C<S<< label => "text" >>>

Specifies the text used for the button name,
checkbox label, input box label, or raw HTML
used for the reseed mechanism.

=back

The problemRandomize library installs a special grader that handles determining
when the reseed option will be available.  It also redefines install_problem_grader
so that it will not overwrite the one installed by the library (it is stored so
that it can be called internally by the problemRandomize library's grader).

Note that the problem will store the new problem seed only if the student can
submit saved answers (i.e., only before the due date).  After the due date,
the student can get new versions, but the problem will revert to the original
version when they come back to the problem later.  Since the default is only
to allow reseeding afer the due date, the reseeding will not be sticky by default.
Hardcopy ALWAYS produces the original version of the problem, regardless of
the seed saved by the student.

Examples:

	ProblemRandomize();                               # use all defaults
	ProblemRandomize(when=>"Always");                 # always can reseed (after due date)
	ProblemRandomize(onlyAfterDue=>0);                # can reseed whenever correct
	ProblemRandomize(when=>"always",onlyAfterDue=>0); # always can reseed
	ProblemRandomize(style=>"Input");                 # use an input box to set the seed

For problems that include "PGcourse.pl" in their loadMacros() calls, you can
use that file to provide reseed buttons for ALL problems simply by including

	loadMacros("problemRandomize.pl");
	ProblemRandomize();

in PGcourse.pl.  You can make the ProblemRandomize() be dependent on the set
number or the set or the login ID or whatever.  For example

	loadMacros("problemRandomize.pl");
	ProblemRandomize(when=>"always",onlyAfterDue=>0,style=>"Input")
		if $studentLogin eq "dpvc";

would enable reseeding at any time for the user called "dpvc" (presumably a
professor).  You can test $probNum and $setNumber to make reseeding available
only for specific sets or problems within a set.

=cut

sub _problemRandomize_init {
  sub ProblemRandomize {new problemRandomize(@_)}
  PG_restricted_eval(<<'  end_eval');
    sub install_problem_grader {
      return $main::PG->{flags}->{problemRandomize}->useGrader(@_) if $main::PG->{flags}->{problemRandomize};
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
    when => "correct",
    onlyAfterDue => 1,
    style => "Button",
    styleName => ($main::inputs_ref->{effectiveUser} ne $main::inputs_ref->{user} ? "checkAnswers" : "submitAnswers"),
    label => undef,
    buttonLabel => "Get a new version of this problem",
    checkboxLabel => "Get a new version of this problem",
    inputLabel => "Set random seed to:",
    grader => $main::PG->{flags}->{PROBLEM_GRADER_TO_USE}  || \&main::avg_problem_grader,  #$main::PG_FLAGS{PROBLEM_GRADER_TO_USE}
    random => $main::PG_random_generator,
    status => {},
    @_
  }, $class;
  $pr->{style} = uc(substr($pr->{style},0,1)) . lc(substr($pr->{style},1));
  $pr->{when} = lc($pr->{when});
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
  main::RECORD_FORM_LABEL("_reseed");
  main::RECORD_FORM_LABEL("_status");
  my $label = $self->{label} || $self->{lc($self->{style})."Label"};
  $self->{status} = $self->decode;
  $self->{submit} = $main::inputs_ref->{submitAnswers};
  $self->{isReset} = $main::inputs_ref->{_reseed} || ($self->{submit} && $self->{submit} eq $label);
  $self->{isReset} = 0 unless !$self->{onlyAfterDue} || time >= $main::dueDate;
}

#
#  Initialize the current problem
#
sub initProblem {
  my $self = shift;
  $main::PG->{flags}->{PROBLEM_GRADER_TO_USE} = \&problemRandomize::grader;
  $main::PG->{flags}->{problemRandomize} = $self;
  $self->reset if $self->{isReset};
  $main::problemSeed = $self->{status}{seed};
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
    {delete $main::inputs_ref->{main::ANS_NUM_TO_NAME($id)}}
  $main::inputs_ref->{_status} = $self->encode(\%defaultStatus);
  $status->{seed} = ($main::inputs_ref->{_reseed} || seed());
}

sub seed {substr(time,5,5)}

##################################################

#
#  Return the HTML for the "re-randomize" checkbox.
#
sub randomizeCheckbox {
  my $self = shift;
  my $label = shift || $self->{checkboxLabel};
  $label = "<b>$label</b> (when you submit your answers).";
  my $par = shift; $par = ($par ? $main::PAR : '');
  $self->{reseedInserted} = 1;
  $par . '<input type="checkbox" name="_reseed" value="'.seed().'" />' . $label;
}

#
#  Return the HTML for the "next part" button.
#
sub randomizeButton {
  my $self = shift;
  my $label = quoteHTML(shift || $self->{buttonLabel});
  my $par = shift; $par = ($par ? $main::PAR : '');
  $par . qq!<input type="submit" name="$self->{styleName}" value="$label" !
       .  q!onclick="document.getElementById('_reseed').value=!.seed().'" />';
}

#
#  Return the HTML for the "problem seed" input box
#
sub randomizeInput {
  my $self = shift;
  my $label = quoteHTML(shift || $self->{inputLabel});
  my $par = shift; $par = ($par ? main::PAR : '');
  $par . qq!<input type="submit" name="$self->{styleName}" value="$label" !
       .  q!onclick="document.getElementById('_reseed').value=document.getElementById('_seed').value" />!
       . qq!<input name="_seed" id="_seed" value="$self->{status}{seed}" size="10">!;
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
  foreach my $id (main::lex_sort(keys(%defaultStatus))) {push(@data, ($status->{$id}) )}
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
  my $self = $main::PG->{flags}->{problemRandomize};

  #
  #  Call the original grader
  #
  $self->{grader} = \&problemRandomize::resetGrader if $self->{isReset};
  my ($result,$state) = &{$self->{grader}}(@_);
  shift; shift; my %options = @_;

  #
  #  Update that state information and encode it.
  #
  my $status = $self->{status};
  $status->{ans_rule_count} = main::ans_rule_count();
  $status->{answers} = join(';',grep(!/${main::QUIZ_PREFIX}${main::ANSWER_PREFIX}/o,keys(%{$_[0]})));
  my $data = quoteHTML($self->encode);
  $result->{type} = "problemRandomize ($result->{type})";

  #
  #  Conditions for when to show the reseed message
  #
  my $inputs = $main::inputs_ref;
  my $isSubmit = $inputs->{submitAnswers} || $inputs->{previewAnswers} || $inputs->{checkAnswers};
  my $score = ($isSubmit || $self->{isReset} ? $result->{score} : $state->{recorded_score});
  my $isWhen = ($self->{when} eq 'always' ||
     ($self->{when} eq 'correct' && $score >= 1 && !$main::inputs_ref->{previewAnswers}));
  my $okDate = (!$self->{onlyAfterDue} || time >= $main::dueDate);

  #
  #  Add the problemRandomize message and data
  #
  if ($isWhen && !$okDate) {
    $result->{msg} .= "</i><br /><b>Note:</b> <i>" if $result->{msg};
    $result->{msg} .= "You can get a new version of this problem after the due date.";
  }
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
  if ($isWhen && $okDate) {
    my $method = "randomize".$self->{style};
    $result->{msg} .= $self->$method($self->{label},1).'<br/>';
  }

  #
  #  Don't show the summary section if the problem is being reset.
  #
  if ($self->{isReset} && $isSubmit) {
    $result->{msg} .= "<style>.problemHeader {display:none}</style>";
    $state->{state_summary_msg} =
       "<b>Note:</b> This is a new (re-randomized) version of the problem.".$main::BR.
       "If you come back to it later, it may revert to its original version.".$main::BR.
       "Hardcopy will always print the original version of the problem.";
  }

  #
  #  Make sure we don't go on unless the next button really is checked
  #
  $result->{msg} .= '<input type="hidden" name="_reseed" id="_reseed" value="0" />'
    unless $self->{reseedInserted};

  return ($result,$state);
}

#
#  Fake grader for when the problem is reset
#
sub resetGrader {
  my $answers = shift;
  my $state = shift;
  my %options = @_;
  my $result = {
    score => 0,
    msg => '',
    errors => '',
    type => 'problemRandomize (reset)',
  };
  return ($result,$state);
}

1;
