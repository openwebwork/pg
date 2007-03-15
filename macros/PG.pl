#	This file provided the fundamental macros for the pg language
#	These macros define the interface between the problems written by
#	the professor and the processing which occurs in the script
#	processProblem.pl


BEGIN {
	be_strict();
}

sub _PG_init{

}

#package PG;


=head1 NAME

	PG.pl --- located in the courseScripts directory.
	Defines the Program Generating language at the most basic level.

=head1 SYNPOSIS

	The basic PG problem structure:

	DOCUMENT();          # should be the first statment in the problem
	loadMacros(.....);   # (optional) load other macro files if needed.
	                     # (loadMacros is defined in F<dangerousMacros.pl>)

	HEADER_TEXT(...);    # (optional) used only for inserting javaScript into problems.

	# 					 #	insert text of problems
	TEXT("Problem text to be",
	     "displayed. Enter 1 in this blank:",
	     ANS_RULE(1,30)  #	ANS_RULE() defines an answer blank 30 characters long.
	                     #  It is defined in F<PGbasicmacros.pl>
	     );


	ANS( answer_evalutors);  # see F<PGanswermacros.pl> for examples of answer evaluatiors.

	ENDDOCUMENT()        # must be the last statement in the problem



=head1 DESCRIPTION

As described in the synopsis, this file and the macros C<DOCUMENT()> and C<ENDDOCUMENT()> determine
the interface between problems written in the PG language and the rest of B<WeBWorK>, in particular
the subroutine C<createPGtext(()> in the file F<translate.pl>.

C<DOCUMENT()> must be the first statement in each problem template.
It  initializes variables,
in particular all of the contents of the
environment variable  become defined in the problem enviroment.
(See
L</webwork_system_html/docs/techdescription/pglanguage/PGenvironment.html>)

ENDDOCUMENT() must the last executable statement in any problem template.  It returns
the rendered problem, answer evaluators and other flags to the rest of B<WeBWorK>, specificially
to the routine C<createPGtext()> defined in F<translate.pl>


The C<HEADER_TEXT()>, C<TEXT()>, and C<ANS()> functions load the
header text string, the problem text string.
and the answer evaulator queue respectively.


=cut


#  Private variables for the PG.pl file.

my ($STRINGforOUTPUT, $STRINGforHEADER_TEXT, @PG_ANSWERS, @PG_UNLABELED_ANSWERS);
my %PG_ANSWERS_HASH ;
our $PG_STOP_FLAG;

# my variables are unreliable if two DOCUMENTS were to be called before an ENDDOCUMENT
# there could be conflicts.  As I understand the behavior of the Apache child
# this cannot occur -- a child finishes with one request before obtaining the next

#  	DOCUMENT must come early in every .pg file, before any answers or text are
#	defined.  It initializes the variables.
#	It can appear only once.

=head2 DOCUMENT()

C<DOCUMENT()> must be the first statement in each problem template.  It can
only be used once in each problem.

C<DOCUMENT()> initializes some empty variables and via C<INITIALIZE_PG()> unpacks the
variables in the C<%envir> variable which is implicitly passed to the problem. It must
be the first statement in any problem template. It
also unpacks any answers submitted and places them in the C<@submittedAnswer> list,
saves the problem seed in C<$PG_original_problemSeed> in case you need it later, and
initializes the pseudo random number generator object in C<$PG_random_generator>.

You can reset the standard number generator using the command:

	$PG_random_generator->srand($new_seed_value);

(See also C<SRAND> in the L<PGbasicmacros.pl> file.)

The
environment variable contents is defined in
L</webwork_system_html/docs/techdescription/pglanguage/PGenvironment.html>


=cut

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

sub inc_ans_rule_count {
	eval(q!++$main::ans_rule_count!); # evalute at runtime to get correct main::
}
#	HEADER_TEXT is for material which is destined to be placed in the header of the html problem -- such
#   as javaScript code.

=head2 HEADER_TEXT()


	HEADER_TEXT("string1", "string2", "string3");

The C<HEADER_TEXT()>
function concatenates its arguments and places them in the output
header text string.  It is used for material which is destined to be placed in
the header of the html problem -- such as javaScript code.
 It can be used more than once in a file.


=cut

sub HEADER_TEXT {
	my @in = @_;
	$STRINGforHEADER_TEXT .= join(" ",@in);
	}

#	TEXT is the function which defines text which will appear in the problem.
#	All text must be an argument to this function.  Any other statements
# 	are calculations (done in perl) which will not directly appear in the
#	output.  Think of this as the "print" function for the .pg language.
#	It can be used more than once in a file.

=head2 TEXT()

	TEXT("string1", "string2", "string3");

The C<TEXT()> function concatenates its arguments and places them in the output
text string. C<TEXT()> is the function which defines text which will appear in the problem.
All text must be an argument to this function.  Any other statements
are calculations (done in perl) which will not directly appear in the
output.  Think of this as the "print" function for the .pg language.
It can be used more than once in a file.

=cut

sub TEXT {
	return "" if $PG_STOP_FLAG;
	my @in = @_;
	$STRINGforOUTPUT .= join(" ",@in);
}

=head2 STOP_RENDERING()

	STOP_RENDERING() unless all_answers_are_correct;

No text is printed and no answer blanks or answer evaluators are stored or processed until
RESUME_RENDERING() is executed.

=cut

sub STOP_RENDERING {
	$PG_STOP_FLAG=1;
	"";
}

=head2 RESUME_RENDERING()

	RESUME_RENDERING();

Resumes processing of text,  answer blanks,  and
answer evaluators.

=cut

sub RESUME_RENDERING {
	$PG_STOP_FLAG=0;
	"";
}

=head2 ANS()

	ANS(answer_evaluator1, answer_evaluator2, answer_evaluator3,...)

Places the answer evaluators in the unlabeled answer_evaluator queue.  They will be paired
with unlabeled answer rules (answer entry blanks) in the order entered.  This is the standard
method for entering answers.

	LABELED_ANS(answer_evaluater_name1, answer_evaluator1, answer_evaluater_name2,answer_evaluator2,...)

Places the answer evaluators in the labeled answer_evaluator hash.  This allows pairing of
labeled answer evaluators and labeled answer rules which may not have been entered in the same
order.

=cut

sub ANS{             # store answer evaluators which have not been explicitly labeled
  return "" if $PG_STOP_FLAG;
  my @in = @_;
  while (@in ) {
         warn("<BR><B>Error in ANS:$in[0]</B> -- inputs must be references to
                      subroutines<BR>")
			unless ref($in[0]);
    	push(@PG_ANSWERS, shift @in );
  }
}
sub LABELED_ANS {  #a better alias for NAMED_ANS
	&NAMED_ANS;
}

sub NAMED_ANS{     # store answer evaluators which have been explicitly labeled (submitted in a hash)
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
sub RECORD_ANS_NAME {     # this maintains the order in which the answer rules are printed.
    return "" if $PG_STOP_FLAG;
	my $label = shift;
	eval(q!push(@main::PG_ANSWER_ENTRY_ORDER, $label)!);
	$label;
}

sub NEW_ANS_NAME {        # this keeps track of the answers which are entered implicitly,
                          # rather than with a specific label
        return "" if $PG_STOP_FLAG;
		my $number=shift;
		my $prefix = eval(q!$main::QUIZ_PREFIX.$main::ANSWER_PREFIX!);
		my $label = $prefix.$number;
		push(@PG_UNLABELED_ANSWERS,$label);
		$label;
}
sub ANS_NUM_TO_NAME {     # This converts a number to an answer label for use in
                          # radio button and check box answers. No new answer
                          # name is recorded.
		my $number=shift;
		my $label = eval(q!$main::QUIZ_PREFIX.$main::ANSWER_PREFIX!).$number;
		$label;
}

my $vecnum;

sub RECORD_FORM_LABEL  {             # this stores form data (such as sticky answers), but does nothing more
                                     # it's a bit of hack since we are storing these in the KEPT_EXTRA_ANSWERS queue even if they aren't answers per se.
	return "" if $PG_STOP_FLAG;
	my $label   = shift;             # the label of the input box or textarea
    eval(q!push(@main::KEPT_EXTRA_ANSWERS, $label)!); #put the labels into the hash to be caught later for recording purposes
    $label;
}
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
#	ENDDOCUMENT must come at the end of every .pg file.
#   It exports the resulting text of the problem, the text to be used in HTML header material
#   (for javaScript), the list of answer evaluators and any other flags.  It can appear only once and
#   it MUST be the last statement in the problem.

=head2 ENDDOCUMENT()

ENDDOCUMENT() must the last executable statement in any problem template.  It can
only appear once.  It returns
an array consisting of

	A reference to a string containing the rendered text of the problem.
	A reference to a string containing text to be placed in the header
	             (for javaScript)
	A reference to the array containing the answer evaluators.
	             (May be changed to a hash soon.)
	A reference to an associative array (hash) containing various flags.

	The following flags are set by ENDDOCUMENT:
	(1) showPartialCorrectAnswers  -- determines whether students are told which
	    of their answers in a problem are wrong.
	(2) recordSubmittedAnswers  -- determines whether students submitted answers
	    are saved.
	(3) refreshCachedImages  -- determines whether the cached image of the problem
	    in typeset mode is always refreshed (i.e. setting this to 1 means cached
	    images are not used).
	(4) solutionExits   -- indicates the existence of a solution.
	(5) hintExits   -- indicates the existence of a hint.
	(6) comment   -- contents of COMMENT commands if any.
	(7) showHintLimit -- determines the number of attempts after which hint(s) will be shown

	(8) PROBLEM_GRADER_TO_USE -- chooses the problem grader to be used in this order
		(a) A problem grader specified by the problem using:
		    install_problem_grader(\&grader);
		(b) One of the standard problem graders defined in PGanswermacros.pl when set to
		    'std_problem_grader' or 'avg_problem_grader' by the environment variable
		    $PG_environment{PROBLEM_GRADER_TO_USE}
		(c) A subroutine referenced by $PG_environment{PROBLEM_GRADER_TO_USE}
		(d) The default &std_problem_grader defined in PGanswermacros.pl


=cut

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



=head2 INITIALIZE_PG()

This is executed each C<DOCUMENT()> is called.  For backward compatibility
C<loadMacros> also checks whether the C<macroDirectory> has been defined
and if not, it runs C<INITIALIZE_PG()> and issues a warning.

=cut


1;
