################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/PG.pl,v 1.37 2008/05/08 00:37:31 sh002i Exp $
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

PG.pl - Provides core Program Generation Language functionality.

=head1 SYNPOSIS

In a PG problem:

	DOCUMENT();             # should be the first statment in the problem
	
	loadMacros(.....);      # (optional) load other macro files if needed.
                        	# (loadMacros is defined in F<dangerousMacros.pl>)
	
	HEADER_TEXT(...);       # (optional) used only for inserting javaScript into problems.
	
	TEXT(                   # insert text of problems
		"Problem text to be displayed. ",
		"Enter 1 in this blank:",
		ANS_RULE(1,30)      # ANS_RULE() defines an answer blank 30 characters long.
 		                	# It is defined in F<PGbasicmacros.pl>
	);
	
	ANS(answer_evalutors);  # see F<PGanswermacros.pl> for examples of answer evaluatiors.
	
	ENDDOCUMENT()           # must be the last statement in the problem

=head1 DESCRIPTION

This file provides the fundamental macros that define the PG language. It
maintains a problem's text, header text, and answers:

=over

=item *

Problem text: The text to appear in the body of the problem. See TEXT()
below.

=item *

Header text: When a problem is processed in an HTML-based display mode,
this variable can contain text that the caller should place in the HEAD of the
resulting HTML page. See HEADER_TEXT() below.

=item *

Implicitly-labeled answers: Answers that have not been explicitly
assigned names, and are associated with their answer blanks by the order in
which they appear in the problem. These types of answers are designated using
the ANS() macro.

=item *

Explicitly-labeled answers: Answers that have been explicitly assigned
names with the LABELED_ANS() macro, or a macro that uses it. An explicitly-
labeled answer is associated with its answer blank by name.

=item *

"Extra" answers: Names of answer blanks that do not have a 1-to-1
correspondance to an answer evaluator. For example, in matrix problems, there
will be several input fields that correspond to the same answer evaluator.

=back

=head1 USAGE

This file is automatically loaded into the namespace of every PG problem. The
macros within can then be called to define the structure of the problem.

DOCUMENT() should be the first executable statement in any problem. It
initializes vriables and defines the problem environment.

ENDDOCUMENT() must be the last executable statement in any problem. It packs
up the results of problem processing for delivery back to WeBWorK.

The HEADER_TEXT(), TEXT(), and ANS() macros add to the header text string,
body text string, and answer evaluator queue, respectively.

=cut

BEGIN {
	be_strict();
}

sub _PG_init{

}

#package PG;

#  Private variables for the PG.pl file.

# ^variable my $STRINGforOUTPUT
my $STRINGforOUTPUT;
# ^variable my $STRINGforHEADER_TEXT
my $STRINGforHEADER_TEXT;
# ^variable my @PG_ANSWERS
my @PG_ANSWERS;
# ^variable my @PG_UNLABELED_ANSWERS
my @PG_UNLABELED_ANSWERS;
# ^variable my %PG_ANSWERS_HASH
my %PG_ANSWERS_HASH;

# ^variable our $PG_STOP_FLAG
our $PG_STOP_FLAG;

# my variables are unreliable if two DOCUMENTS were to be called before an ENDDOCUMENT
# there could be conflicts.  As I understand the behavior of the Apache child
# this cannot occur -- a child finishes with one request before obtaining the next

################################################################################

=head1 MACROS

These macros may be used from PG problem files.

=over

=item DOCUMENT()

DOCUMENT() should be the first statement in each problem template.  It can
only be used once in each problem.

DOCUMENT() initializes some empty variables and unpacks the variables in the
%envir hash which is implicitly passed from WeBWorK to the problem. It must be 
the first statement in any problem. It also unpacks any answers submitted and
places them in the @submittedAnswer list, saves the problem seed in
$PG_original_problemSeed in case you need it later, and initializes the pseudo
random number generator object in $PG_random_generator.

You can reset the standard number generator using the command:

 $PG_random_generator->srand($new_seed_value);

See also SRAND() in the L<PGbasicmacros.pl> file.

=cut

# ^function DOCUMENT
# ^uses $STRINGforOUTPUT
# ^uses $STRINGforHEADER_TEXT
# ^uses @PG_ANSWERS
# ^uses $PG_STOP_FLAG
# ^uses @PG_UNLABELED_ANSWERS
# ^uses %PG_ANSWERS_HASH
# ^uses @PG_ANSWER_ENTRY_ORDER
# ^uses $ANSWER_PREFIX
# ^uses %PG_FLAGS
# ^uses $showPartialCorrectAnswers
# ^uses $showHints
# ^uses $solutionExists
# ^uses $hintExists
# ^uses $pgComment
# ^uses %gifs_created
# ^uses %envir
# ^uses $refSubmittedAnswers
# ^uses @submittedAnswers
# ^uses $PG_original_problemSeed
# ^uses $problemSeed
# ^uses $PG_random_generator
# ^uses $ans_rule_count
# ^uses $QUIZ_PREFIX
# (Also creates a package scalar named after each key in %envir containing a copy of the corresponding value.)
# ^uses &PGrandom::new
sub DOCUMENT {

	$STRINGforOUTPUT ="";
    $STRINGforHEADER_TEXT ="";
	@PG_ANSWERS=();
	$PG_STOP_FLAG=0;
	@PG_UNLABELED_ANSWERS = ();
	%PG_ANSWERS_HASH = ();
	# FIXME:  We are initializing these variables into both Safe::Root1 (the cached safe compartment) 
	# and Safe::Root2 (the current one)
	# There is a good chance they won't be properly updated in one or the other of these compartments.
	

# 	@main::PG_ANSWER_ENTRY_ORDER = ();
# 	$main::ANSWER_PREFIX = 'AnSwEr';
# 	%main::PG_FLAGS=();  #global flags
# 	$main::showPartialCorrectAnswers = 0 unless defined($main::showPartialCorrectAnswers );
# 	$main::showHint = 1 unless defined($main::showHint);
# 	$main::solutionExists =0;
# 	$main::hintExists =0;
# 	%main::gifs_created = ();
	eval(q!
	# set perl to use capital E for scientific notation:  e.g.  5.4E-05 instead of 5.4e-05
	$#="%G";  #FIXME  -- check that this works
	
	@main::PG_ANSWER_ENTRY_ORDER = ();
	$main::ANSWER_PREFIX = 'AnSwEr';
	%main::PG_FLAGS=();  #global flags
	$main::showPartialCorrectAnswers = 0 unless defined($main::showPartialCorrectAnswers );
	$main::showHint = 1 unless defined($main::showHint);
	$main::solutionExists =0;
	$main::hintExists =0;
	$main::pgComment = '';
	%main::gifs_created = ();
	
    !);
#    warn eval(q! "PG.pl:  The envir variable $main::{envir} is".join(" ",%main::envir)!);
    my $rh_envir = eval(q!\%main::envir!);
    my %envir    = %$rh_envir;

    # Save the file name for use in error messages
    my ($callpkg,$callfile) = caller(0);
    $envir{__files__}{$callfile} = $envir{templateDirectory}.$envir{fileName};

    #no strict;
    foreach  my  $var (keys %envir) {
   		eval(q!$main::!.$var.q! = $main::envir{!.$var.q!}! );  #whew!! makes sure $var is interpolated but $main:: is evaluated at run time.
    #    warn eval(q! "var $var is defined ". $main::!.$var);
        warn "Problem defining ", q{\$main::}.$var, " while initializing the PG problem: $@" if $@;
    }
    #use strict;
    #FIXME these strict pragmas don't seem to be needed and they cause trouble in perl 5.6.0

    

    eval(q!
	@main::submittedAnswers = @{$main::refSubmittedAnswers} if defined($main::refSubmittedAnswers);
	$main::PG_original_problemSeed = $main::problemSeed;
	$main::PG_random_generator = new PGrandom($main::problemSeed) || die "Can't create random number generator.";
	$main::ans_rule_count = 0;  # counts questions

  	# end unpacking of environment variables.
  	$main::QUIZ_PREFIX = '' unless defined($main::QUIZ_PREFIX)
  
	!);
# 	@main::submittedAnswers = @{$main::refSubmittedAnswers} if defined($main::refSubmittedAnswers);
# 	$main::PG_original_problemSeed = $main::problemSeed;
# 	$main::PG_random_generator = new PGrandom($main::problemSeed) || die "Can't create random number generator.";
# 	$main::ans_rule_count = 0;  # counts questions

  	# end unpacking of environment variables.
#  	$main::QUIZ_PREFIX = '' unless defined($main::QUIZ_PREFIX)

	if ($main::envir{displayMode} eq 'HTML_jsMath') {
		my $prefix = "";
		if (!$main::envir{jsMath}{reportMissingFonts}) {
			$prefix .= '<SCRIPT>noFontMessage = 1</SCRIPT>'."\n";
		} elsif ($main::envir{jsMath}{missingFontMessage}) {
			$prefix .= '<SCRIPT>missingFontMessage = "'.$main::envir{jsMath}{missingFontMessage}.'"</SCRIPT>'."\n";
		}
		$prefix .= '<SCRIPT>processDoubleClicks = '.($main::envir{jsMath}{processDoubleClicks}?'1':'0')."</SCRIPT>\n";
		$STRINGforOUTPUT =
		  $prefix . 
		  '<SCRIPT SRC="'.$main::envir{jsMathURL}.'"></SCRIPT>' . "\n" .
		  '<NOSCRIPT><CENTER><FONT COLOR="#CC0000">' .
		  '<B>Warning: the mathematics on this page requires JavaScript.<BR>' .
		  'If your browser supports it, be sure it is enabled.</B>'.
		  '</FONT></CENTER><p></NOSCRIPT>' .
		  $STRINGforOUTPUT;
		$STRINGforOUTPUT .= 
		  '<SCRIPT>jsMath.Setup.Script("plugins/noImageFonts.js")</SCRIPT>'
		    if ($main::envir{jsMath}{noImageFonts});
	}
	
	$STRINGforOUTPUT = '<SCRIPT SRC="'.$main::envir{asciimathURL}.'"></SCRIPT>' . "\n" .
                           '<SCRIPT>mathcolor = "black"</SCRIPT>' . $STRINGforOUTPUT
	  if ($main::envir{displayMode} eq 'HTML_asciimath');

	$STRINGforOUTPUT = '<SCRIPT SRC="'.$main::envir{LaTeXMathMLURL}.'"></SCRIPT>'."\n" . $STRINGforOUTPUT
	  if ($main::envir{displayMode} eq 'HTML_LaTeXMathML');

}

=item HEADER_TEXT()

 HEADER_TEXT("string1", "string2", "string3");

HEADER_TEXT() concatenates its arguments and appends them to the stored header
text string. It can be used more than once in a file.

The macro is used for material which is destined to be placed in the HEAD of
the page when in HTML mode, such as JavaScript code.

Spaces are placed between the arguments during concatenation, but no spaces are
introduced between the existing content of the header text string and the new
content being appended.

=cut

# ^function HEADER_TEXT
# ^uses $STRINGforHEADER_TEXT
sub HEADER_TEXT {
	my @in = @_;
	$STRINGforHEADER_TEXT .= join(" ",@in);
	}

=item TEXT()

 TEXT("string1", "string2", "string3");

TEXT() concatenates its arguments and appends them to the stored problem text
string. It is used to define the text which will appear in the body of the
problem. It can be used more than once in a file.

This macro has no effect if rendering has been stopped with the STOP_RENDERING()
macro.

This macro defines text which will appear in the problem. All text must be
passed to this macro, passed to another macro that calls this macro, or included
in a BEGIN_TEXT/END_TEXT block, which uses this macro internally. No other
statements in a PG file will directly appear in the output. Think of this as the
"print" function for the PG language.

Spaces are placed between the arguments during concatenation, but no spaces are
introduced between the existing content of the header text string and the new
content being appended.

=cut

# ^function TEXT
# ^uses $PG_STOP_FLAG
# ^uses $STRINGforOUTPUT
sub TEXT {
	return "" if $PG_STOP_FLAG;
	my @in = @_;
	$STRINGforOUTPUT .= join(" ",@in);
}

=item ANS()

 TEXT(ans_rule(), ans_rule(), ans_rule());
 ANS($answer_evaluator1, $answer_evaluator2, $answer_evaluator3);

Adds the answer evaluators listed to the list of unlabeled answer evaluators.
They will be paired with unlabeled answer rules (a.k.a. answer blanks) in the
order entered. This is the standard method for entering answers.

In the above example, answer_evaluator1 will be associated with the first
answer rule, answer_evaluator2 with the second, and answer_evaluator3 with the
third. In practice, the arguments to ANS() will usually be calls to an answer
evaluator generator such as the cmp() method of MathObjects or the num_cmp()
macro in L<PGanswermacros.pl>.

=cut

# ^function ANS
# ^uses $PG_STOP_FLAG
# ^uses @PG_ANSWERS
sub ANS{
  return "" if $PG_STOP_FLAG;
  my @in = @_;
  while (@in ) {
         warn("<BR><B>Error in ANS:$in[0]</B> -- inputs must be references to
                      subroutines<BR>")
			unless ref($in[0]);
    	push(@PG_ANSWERS, shift @in );
  }
}

=item LABELED_ANS()

 TEXT(labeled_ans_rule("name1"), labeled_ans_rule("name2"));
 LABELED_ANS(name1 => answer_evaluator1, name2 => answer_evaluator2);

Adds the answer evaluators listed to the list of labeled answer evaluators.
They will be paired with labeled answer rules (a.k.a. answer blanks) in the
order entered. This allows pairing of answer evaluators and answer rules that
may not have been entered in the same order.

=cut

# ^function LABELED_ANS
# ^uses &NAMED_ANS
sub LABELED_ANS {
	&NAMED_ANS;
}

=item NAMED_ANS()

Old name for LABELED_ANS(). DEPRECATED.

=cut

# ^function NAMED_ANS
# ^uses $PG_STOP_FLAG
sub NAMED_ANS{
  return "" if $PG_STOP_FLAG;
  my @in = @_;
  while (@in ) {
  	my $label = shift @in;
  	$label = eval(q!$main::QUIZ_PREFIX.$label!);
  	my $ans_eval = shift @in;
  	TEXT("<BR><B>Error in NAMED_ANS:$in[0]</B>
  	      -- inputs must be references to subroutines<BR>")
			unless ref($ans_eval);
  	$PG_ANSWERS_HASH{$label}= $ans_eval;
  }
}

=item STOP_RENDERING()

 STOP_RENDERING() unless all_answers_are_correct();

Temporarily suspends accumulation of problem text and storing of answer blanks
and answer evaluators until RESUME_RENDERING() is called.

=cut

# ^function STOP_RENDERING
# ^uses $PG_STOP_FLAG
sub STOP_RENDERING {
	$PG_STOP_FLAG=1;
	"";
}

=item RESUME_RENDERING()

 RESUME_RENDERING();

Resumes accumulating problem text and storing answer blanks and answer
evaluators. Reverses the effect of STOP_RENDERING().

=cut

# ^function RESUME_RENDERING
# ^uses $PG_STOP_FLAG
sub RESUME_RENDERING {
	$PG_STOP_FLAG=0;
	"";
}

=item ENDDOCUMENT()

 ENDDOCUMENT();

When PG problems are evaluated, the result of evaluating the entire problem is
interpreted as the return value of ENDDOCUMENT(). Therefore, ENDDOCUMENT() must
be the last executable statement of every problem. It can only appear once. It
returns a list consisting of:

=over

=item *

A reference to a string containing the rendered text of the problem.

=item *

A reference to a string containing text to be placed in the HEAD block
when in and HTML-based mode (e.g. for JavaScript).

=item *

A reference to the hash mapping answer labels to answer evaluators.

=item *

A reference to a hash containing various flags:

=over

=item *

C<showPartialCorrectAnswers>: determines whether students are told which of their answers in a problem are wrong.

=item *

C<recordSubmittedAnswers>: determines whether students submitted answers are saved.

=item *

C<refreshCachedImages>: determines whether the cached image of the problem in typeset mode is always refreshed
(i.e. setting this to 1 means cached images are not used).

=item *

C<solutionExits>: indicates the existence of a solution.

=item *

C<hintExits>: indicates the existence of a hint.

=item *

C<comment>: contents of COMMENT commands if any.

=item *

C<showHintLimit>: determines the number of attempts after which hint(s) will be shown

=item *

C<PROBLEM_GRADER_TO_USE>: a reference to the chosen problem grader.
ENDDOCUMENT chooses the problem grader as follows:

=over

=item *

If a problem grader has been chosen in the problem by calling
C<install_problem_grader(\&grader)>, it is used.

=item *

Otherwise, if the C<PROBLEM_GRADER_TO_USE> PG environment variable
contains a reference to a subroutine, it is used.

=item *

Otherwise, if the C<PROBLEM_GRADER_TO_USE> PG environment variable
contains the string C<std_problem_grader> or the string C<avg_problem_grader>,
C<&std_problem_grader> or C<&avg_problem_grader> are used. These graders are defined
in L<PGanswermacros.pl>.

=item *

Otherwise, the PROBLEM_GRADER_TO_USE flag will contain an empty value
and the PG translator should select C<&std_problem_grader>.

=back

=back

=back

=cut

# ^function ENDDOCUMENT
# ^uses @PG_UNLABELED_ANSWERS
# ^uses %PG_ANSWERS_HASH
# ^uses @PG_ANSWERS
sub ENDDOCUMENT {

    my $index=0;
    foreach my $label (@PG_UNLABELED_ANSWERS) {
        if ( defined($PG_ANSWERS[$index]) ) {
    		$PG_ANSWERS_HASH{"$label"}= $PG_ANSWERS[$index];
 			#warn "recording answer label = $label";
    	} else {
    		warn "No answer provided by instructor for answer $label";
    	}
    	$index++;
    }

    $STRINGforOUTPUT .="\n";
   eval q{  #make sure that "main" points to the current safe compartment by evaluating these lines.
		$main::PG_FLAGS{'showPartialCorrectAnswers'} = $main::showPartialCorrectAnswers;
		$main::PG_FLAGS{'recordSubmittedAnswers'} = $main::recordSubmittedAnswers;
		$main::PG_FLAGS{'refreshCachedImages'} = $main::refreshCachedImages;
		$main::PG_FLAGS{'comment'} = $main::pgComment;
		$main::PG_FLAGS{'hintExists'} = $main::hintExists;
		$main::PG_FLAGS{'showHintLimit'} = $main::showHint;
		$main::PG_FLAGS{'solutionExists'} = $main::solutionExists;
		$main::PG_FLAGS{ANSWER_ENTRY_ORDER} = \@main::PG_ANSWER_ENTRY_ORDER;
		$main::PG_FLAGS{KEPT_EXTRA_ANSWERS} = \@main::KEPT_EXTRA_ANSWERS;##need to keep array labels that don't call "RECORD_ANS_NAME"
		$main::PG_FLAGS{ANSWER_PREFIX} = $main::ANSWER_PREFIX;
		# install problem grader
		if (defined($main::PG_FLAGS{PROBLEM_GRADER_TO_USE}) ) {
			# problem grader defined within problem -- no further action needed
		} elsif ( defined( $main::envir{PROBLEM_GRADER_TO_USE} ) ) {
			if (ref($main::envir{PROBLEM_GRADER_TO_USE}) eq 'CODE' ) {         # user defined grader
				$main::PG_FLAGS{PROBLEM_GRADER_TO_USE} = $main::envir{PROBLEM_GRADER_TO_USE};
			} elsif ($main::envir{PROBLEM_GRADER_TO_USE} eq 'std_problem_grader' ) {
				if (defined(&std_problem_grader) ){
					$main::PG_FLAGS{PROBLEM_GRADER_TO_USE} = \&std_problem_grader; # defined in PGanswermacros.pl
				} # std_problem_grader is the default in any case so don't give a warning.
			} elsif ($main::envir{PROBLEM_GRADER_TO_USE} eq 'avg_problem_grader' ) {
				if (defined(&avg_problem_grader) ){
					$main::PG_FLAGS{PROBLEM_GRADER_TO_USE} = \&avg_problem_grader; # defined in PGanswermacros.pl
				}
				#else { # avg_problem_grader will be installed by PGtranslator so there is no need for a warning.
				#	warn "The problem grader 'avg_problem_grader' has not been defined.  Has PGanswermacros.pl been loaded?";
				#}
			} else {
				warn "Error:  $main::PG_FLAGS{PROBLEM_GRADER_TO_USE} is not a known program grader.";
			}
		} elsif (defined(&std_problem_grader)) {
			$main::PG_FLAGS{PROBLEM_GRADER_TO_USE} = \&std_problem_grader; # defined in PGanswermacros.pl
		} else {
			# PGtranslator will install its default problem grader
		}
	
    warn "ERROR: The problem grader is not a subroutine" unless ref( $main::PG_FLAGS{PROBLEM_GRADER_TO_USE}) eq 'CODE'
										 or $main::PG_FLAGS{PROBLEM_GRADER_TO_USE} = 'std_problem_grader'
										 or $main::PG_FLAGS{PROBLEM_GRADER_TO_USE} = 'avg_problem_grader';
     # return results
    };

    $STRINGforOUTPUT .= '<SCRIPT> jsMath.wwProcess() </SCRIPT>'
      if ($main::envir{displayMode} eq 'HTML_jsMath');

    if ($main::envir{displayMode} eq 'HTML_asciimath') {
      $STRINGforOUTPUT .= '<SCRIPT> translate() </SCRIPT>';
      $STRINGforHEADER_TEXT .=
        '<object id="mathplayer" classid="clsid:32F66A20-7614-11D4-BD11-00104BD3F987">' . "\n" .
        '</object><?import namespace="mml" implementation="#mathplayer"?>'
	unless ($STRINGforHEADER_TEXT =~ m/mathplayer/);
    }	
	$STRINGforOUTPUT .= MODES(%{PG_restricted_eval('$main::problemPostamble')});
    
	(\$STRINGforOUTPUT, \$STRINGforHEADER_TEXT,\%PG_ANSWERS_HASH,eval(q!\%main::PG_FLAGS!));
}


################################################################################

=head1 PRIVATE MACROS

These macros should only be used by other macro files. In practice, they are
used exclusively by L<PGbasicmacros.pl>.

=over

=item inc_ans_rule_count()

 NEW_ANS_NAME(inc_ans_rule_count());

Increments the internal count of the number of answer blanks that have been
defined ($ans_rule_count) and returns the new count. This should only be used
when one is about to define a new answer blank, for example with NEW_ANS_NAME().

=cut

# ^function inc_ans_rule_count
# ^uses $ans_rule_count
sub inc_ans_rule_count {
	eval(q!++$main::ans_rule_count!); # evalute at runtime to get correct main::
}

=item RECORD_ANS_NAME()

 RECORD_ANS_NAME("label");

Records the label for an answer blank. Used internally by L<PGbasicmacros.pl>
to record the order of explicitly-labelled answer blanks.

=cut

# ^function RECORD_ANS_NAME
# ^uses $PG_STOP_FLAG
# ^uses @PG_ANSWER_ENTRY_ORDER
sub RECORD_ANS_NAME {
    return "" if $PG_STOP_FLAG;
	my $label = shift;
	eval(q!push(@main::PG_ANSWER_ENTRY_ORDER, $label)!);
	$label;
}

=item NEW_ANS_NAME()

 NEW_ANS_NAME($num);

Generates an answer label from the supplied answer number. The label is
added to the list of implicity-labeled answers. Used internally by
L<PGbasicmacros.pl> to generate labels for unlabeled answer blanks.

=cut

# ^function NEW_ANS_NAME
# ^uses $PG_STOP_FLAG
# ^uses $QUIZ_PREFIX
# ^uses $ANSWER_PREFIX
# ^uses @PG_UNLABELED_ANSWERS
sub NEW_ANS_NAME {
        return "" if $PG_STOP_FLAG;
		my $number=shift;
		my $prefix = eval(q!$main::QUIZ_PREFIX.$main::ANSWER_PREFIX!);
		my $label = $prefix.$number;
		push(@PG_UNLABELED_ANSWERS,$label);
		$label;
}

=item ANS_NUM_TO_NAME()

 ANS_NUM_TO_NAME($num);

Generates an answer label from the supplied answer number, but does not add it
to the list of inplicitly-labeled answers. Used internally by
L<PGbasicmacros.pl> in generating answers blanks that use radio buttons or
check boxes. (This type of answer blank uses multiple HTML INPUT elements with
the same label, but the label should only be added to the list of implicitly-
labeled answers once.)

=cut

# ^function ANS_NUM_TO_NAME
# ^uses $QUIZ_PREFIX
# ^uses $ANSWER_PREFIX
sub ANS_NUM_TO_NAME {
		my $number=shift;
		my $label = eval(q!$main::QUIZ_PREFIX.$main::ANSWER_PREFIX!).$number;
		$label;
}

my $vecnum;

=item RECORD_FROM_LABEL()

 RECORD_FORM_LABEL("label");

Stores the label of a form field in the "extra" answers list. This is used to
keep track of answer blanks that are not associated with an answer evaluator.

=cut

# ^function RECORD_FORM_LABEL
# ^uses $PG_STOP_FLAG
# ^uses @KEPT_EXTRA_ANSWERS
sub RECORD_FORM_LABEL  {             # this stores form data (such as sticky answers), but does nothing more
                                     # it's a bit of hack since we are storing these in the KEPT_EXTRA_ANSWERS queue even if they aren't answers per se.
	return "" if $PG_STOP_FLAG;
	my $label   = shift;             # the label of the input box or textarea
    eval(q!push(@main::KEPT_EXTRA_ANSWERS, $label)!); #put the labels into the hash to be caught later for recording purposes
    $label;
}

=item NEW_ANS_ARRAY_NAME()

 NEW_ANS_ARRAY_NAME($num, $row, $col);

Generates a new answer label for an array (vector) element and adds it to the
list of implicitly-labeled answers.

=cut

# ^function NEW_ANS_ARRAY_NAME
# ^uses $PG_STOP_FLAG
# ^uses $QUIZ_PREFIX
# ^uses @PG_UNLABELED_ANSWERS
sub NEW_ANS_ARRAY_NAME {        # this keeps track of the answers which are entered implicitly,
                          # rather than with a specific label
        return "" if $PG_STOP_FLAG;
		my $number=shift;
		$vecnum = 0;
		my $row = shift;
		my $col = shift;
#		my $label = "ArRaY"."$number"."["."$vecnum".","."$row".","."$col"."]";
		my $label = eval(q!$main::QUIZ_PREFIX."ArRaY"."$number"."__"."$vecnum".":"."$row".":"."$col"."__"!);
		push(@PG_UNLABELED_ANSWERS,$label);
		$label;
}

=item NEW_ANS_ARRAY_NAME_EXTENSION()

 NEW_ANS_ARRAY_NAME_EXTENSION($num, $row, $col);

Generate an additional answer label for an existing array (vector) element and
add it to the list of "extra" answers.

=cut

# ^function NEW_ANS_ARRAY_NAME_EXTENSION
# ^uses $PG_STOP_FLAG
sub NEW_ANS_ARRAY_NAME_EXTENSION {        # this keeps track of the answers which are entered implicitly,
                                          # rather than with a specific label
        return "" if $PG_STOP_FLAG;
		my $number=shift;
		my $row = shift;
		my $col = shift;
		if( $row == 0 && $col == 0 ){
			$vecnum += 1;		
		}
		#FIXME   change made to conform to HTML 4.01 standards.  "Name" attributes can only contain
		# alphanumeric characters,   _ : and .   
		# Also need to make corresponding changes in PGmorematrixmacros.  grep for ArRaY.
		#my $label = "ArRaY"."$number"."["."$vecnum".","."$row".","."$col"."]";
		my $label = eval(q!$main::QUIZ_PREFIX."ArRaY"."$number"."__"."$vecnum".":"."$row".":"."$col"."__"!);
		eval(q!push(@main::KEPT_EXTRA_ANSWERS, $label)!);#put the labels into the hash to be caught later for recording purposes
		$label;
}

=item get_PG_ANSWERS_HASH()

 get_PG_ANSWERS_HASH();
 get_PG_ANSWERS_HASH($key);



=cut

# ^function get_PG_ANSWERS_HASH
# ^uses %PG_ANSWERS_HASH
# ^uses @PG_UNLABELED_ANSWERS
# ^uses @PG_ANSWERS
sub get_PG_ANSWERS_HASH {
	# update the PG_ANSWWERS_HASH, then report the result.  
	# This is used in writing sequential problems
	# if there is an input, use that as a key into the answer hash
	my $key = shift;
	my (%pg_answers_hash, @pg_unlabeled_answers);
	%pg_answers_hash= %PG_ANSWERS_HASH;
	#warn "order ", eval(q!@main::PG_ANSWER_ENTRY_ORDER!);
	#warn "pg answers", %PG_ANSWERS_HASH;
	#warn "unlabeled", @PG_UNLABELED_ANSWERS;
    my $index=0;
    foreach my $label (@PG_UNLABELED_ANSWERS) {
        if ( defined($PG_ANSWERS[$index]) ) {
    		$pg_answers_hash{"$label"}= $PG_ANSWERS[$index];
 			#warn "recording answer label = $label";
    	} else {
    		warn "No answer provided by instructor for answer $label";
    	}
    	$index++;
    }
    if ($key) {
    	return $pg_answers_hash{$key};
    } else {
    	return %pg_answers_hash;
    }
}

=item includePGproblem($filePath)

 includePGproblem($filePath);

 Essentially runs the pg problem specified by $filePath, which is
 a path relative to the top of the templates directory.  The output
 of that problem appears in the given problem.

=cut

# ^function includePGproblem
# ^uses %envir
# ^uses &read_whole_problem_file
# ^uses &includePGtext
sub includePGproblem {
    my $filePath = shift;
    my %save_envir = %main::envir;
    my $fullfilePath = $main::envir{templateDirectory}.$filePath;
    my $r_string =  read_whole_problem_file($fullfilePath);
    if (ref($r_string) eq 'SCALAR') {
        $r_string = $$r_string;      
    }

	# The problem calling this should provide DOCUMENT and ENDDOCUMENT,
	# so we remove them from the included file.
    $r_string=~ s/^\s*(END)?DOCUMENT(\(\s*\));?//gm;

	# Reset the problem path so that static images can be found via
	# their relative paths.
    eval('$main::envir{probFileName} = $filePath');
    eval('$main::envir{fileName} = $filePath');
    includePGtext($r_string);
    # Reset the environment to what it is before.
    %main::envir = %save_envir;
}


=back

=head1 SEE ALSO

L<PGbasicmacros.pl>, L<PGanswermacros.pl>.

=cut

1;
