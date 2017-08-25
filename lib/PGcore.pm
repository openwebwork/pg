################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/lib/PGcore.pm,v 1.6 2010/05/25 22:47:52 gage Exp $
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
package PGcore;

use strict;
our $internal_debug_messages = [];

use PGanswergroup;
use PGresponsegroup;
use PGrandom;
use PGalias;
use PGloadfiles;
use AnswerHash;
use WeBWorK::PG::IO(); # don't important any command directly
use Tie::IxHash;
use WeBWorK::Debug;
use MIME::Base64();
use PGUtil();

##################################
# PGcore object
##################################

sub not_null {
    my $self = shift;
    PGUtil::not_null(@_);  
}

sub pretty_print {
    my $self = shift;
    my $input = shift;
    my $displayMode = shift;
    my $level       = shift;

    if (!PGUtil::not_null($displayMode) && ref($self) eq 'PGcore') {
		$displayMode = $self->{displayMode};
    }
    warn "displayMode not defined" unless $displayMode;
    PGUtil::pretty_print($input, $displayMode, $level);  
}

sub new {
	my $class = shift;	
	my $envir = shift;  #pointer to environment hash
	warn "PGcore must be called with an environment" unless ref($envir) eq 'HASH';
	#warn "creating a new PGcore object";
	my %options = @_;
	my $self = {
		OUTPUT_ARRAY              => [],          # holds output body text
		HEADER_ARRAY              => [],         # holds output for the header text
		POST_HEADER_ARRAY         => [],
#		PG_ANSWERS                => [],  # holds answers with labels # deprecated
#		PG_UNLABELED_ANSWERS      => [],  # holds unlabeled ans. #deprecated -replaced by PG_ANSWERS_HASH
		PG_ANSWERS_HASH           => {},  # holds label=>answer pairs
		PERSISTENCE_HASH          => {}, # holds other data, besides answers, which persists during a session and beyond
		answer_eval_count         => 0,
		answer_blank_count        => 0,
		unlabeled_answer_blank_count =>0,
		unlabeled_answer_eval_count  => 0,
		KEPT_EXTRA_ANSWERS        => [],
		ANSWER_PREFIX             => 'AnSwEr',
		ARRAY_PREFIX              => 'ArRaY',
		vec_num                   => 0,     # for distinguishing matrices
		QUIZ_PREFIX               => $envir->{QUIZ_PREFIX},
		SECTION_PREFIX            => '',  # might be used for sequential (compound) questions?
		
		PG_ACTIVE                 => 1,   # toggle to zero to stop processing
		submittedAnswers          => 0,   # have any answers been submitted? is this the first time this session?
		PG_session_persistence_hash =>{}, # stores data from one invoction of the session to the next.
		PG_original_problem_seed  => 0,
		PG_random_generator		  => undef,
		PG_alias                  => undef,
		PG_problem_grader         => undef,
		displayMode               => undef,
		envir                     => $envir,
		WARNING_messages		  => [],
		DEBUG_messages            => [],
		gifs_created              => {},
		external_refs             => {},      # record of external references 
		%options,                                   # allows overrides and initialization	
	};
	bless $self, $class;
	tie %{$self->{PG_ANSWERS_HASH}}, "Tie::IxHash";  # creates a Hash with order
	$self->initialize;
	return $self;
}

sub initialize {
	my $self = shift;
	warn "environment is not defined in PGcore" unless ref($self->{envir}) eq 'HASH';

	$self->{displayMode}                = $self->{envir}->{displayMode};
	$self->{PG_original_problem_seed}   = $self->{envir}->{problemSeed};
	$self->{PG_random_generator}        = new PGrandom( $self->{PG_original_problem_seed});
	$self->{problemSeed}                = $self->{PG_original_problem_seed};
    $self->{tempDirectory}        		= $self->{envir}->{tempDirectory};
	$self->{PG_problem_grader}    		= $self->{envir}->{PROBLEM_GRADER_TO_USE};
    $self->{PG_alias}             		= PGalias->new($self->{envir},
												WARNING_messages => $self->{WARNING_messages},
												DEBUG_messages   => $self->{DEBUG_messages},                                           
										);
	#$self->{maketext} =  WeBWorK::Localize::getLoc($self->{envir}->{language});
	$self->{maketext} = $self->{envir}->{language_subroutine};
	#$self->debug_message("PG alias created", $self->{PG_alias} );
    $self->{PG_loadMacros}        = new PGloadfiles($self->{envir});
	$self->{flags} = {
		showpartialCorrectAnswers => 1,
		showHint                  => 1,
		hintExists 				  => 0,
		showHintLimit             => 0,
		solutionExists            => 0,
		recordSubmittedAnswers    => 1,
		refreshCachedImages       => 0,
#		ANSWER_ENTRY_ORDER        => [],  # may not be needed if we ue Tie:IxHash
		comment                   => '',  # implement as array?

	
	
	};

}


####################################################################

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
	my $self = shift;
	push @{$self->{HEADER_ARRAY}}, map { (defined($_) )?$_:'' } @_;
	$self->{HEADER_ARRAY}  ;
}

=item POST_HEADER_TEXT()

 POST_HEADER_TEXT("string1", "string2", "string3");

POST_HEADER_TEXT() concatenates its arguments and appends them to the stored post_header
text string. It can be used more than once in a file.

The macro is used for material which is destined to be placed iimmediately after the HEAD of
the page as the first item in the body, before the main problem form
when in HTML mode, such as JavaScript code.

Spaces are placed between the arguments during concatenation, but no spaces are
introduced between the existing content of the header text string and the new
content being appended.

=cut

# ^function POST_HEADER_TEXT
# ^uses $STRINGforHEADER_TEXT
sub POST_HEADER_TEXT {
	my $self = shift;
	push @{$self->{POST_HEADER_ARRAY}}, map { (defined($_) )?$_:'' } @_;
	$self->{POST_HEADER_ARRAY}  ;
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
	my $self = shift;    #FIXME  filter for undefined entries replace by "";
	push @{$self->{OUTPUT_ARRAY}}, map { (defined($_) )?$_:'' } @_ ;
	$self->{OUTPUT_ARRAY};
}

sub envir {
	my $self = shift;
	my $in_key = shift;
	if ( $self->not_null($in_key) ) {
  		if (defined  ($self->{envir}->{$in_key} ) ) {
  			$self->{envir}->{$in_key};
  		} else {
  			 warn "\$envir{$in_key} is not defined\n";
  			return '';
  		}
	} else {
 		warn "<h3> Environment</h3>".$self->pretty_print($self->{envir});
 		return '';
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

# ^function NAMED_ANS
# ^uses &LABELED_ANS
sub NAMED_ANS {
	&LABELED_ANS;
}

=item NAMED_ANS()

Old name for LABELED_ANS(). DEPRECATED.

=cut

# ^function NAMED_ANS
# ^uses $PG_STOP_FLAG
sub LABELED_ANS{ 
  my $self = shift;
  my @in = @_;
  while (@in ) {
  	my $label    = shift @in;
  	#$label       = join("", $self->{QUIZ_PREFIX}, $self->{SECTION_PREFIX}, $label);
  	my $ans_eval = shift @in;
  	$self->warning_message("<BR><B>Error in LABELED_ANS:|$label|</B>
  	      -- inputs must be references to AnswerEvaluator objects or subroutines<BR>")
			unless ref($ans_eval) =~ /CODE/ or ref($ans_eval) =~ /AnswerEvaluator/  ;
	if (ref($ans_eval) =~ /CODE/) {
	  #
	  #  Create an AnswerEvaluator that calls the given CODE reference and use that for $ans_eval.
	  #  So we always have an AnswerEvaluator from here on.
	  #
	  my $cmp = new AnswerEvaluator;
	  $cmp->install_evaluator(sub {
	    my $ans = shift; my $checker = shift;
	    my @args = ($ans->{student_ans});
	    push(@args,ans_label=>$ans->{ans_label}) if defined($ans->{ans_label});
	    $checker->(@args); # Call the original checker with the arguments that PG::Translator would have used
	  },$ans_eval);
	  $ans_eval = $cmp;
	}
	if (defined($self->{PG_ANSWERS_HASH}->{$label})  ){
		$self->{PG_ANSWERS_HASH}->{$label}->insert(ans_label => $label, ans_eval => $ans_eval, active=>$self->{PG_ACTIVE});
	} else {
  		$self->{PG_ANSWERS_HASH}->{$label} = PGanswergroup->new($label, ans_eval => $ans_eval, active=>$self->{PG_ACTIVE});
  	}
  	$self->{answer_eval_count}++;
  }
  $self->{PG_ANSWERS_HASH};
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
  my $self = shift;
  my @in = @_;
  while (@in ) {
         # create new label
         $self->{unlabeled_answer_eval_count}++;
         my $label = $self->new_label($self->{unlabeled_answer_eval_count});
         my $evaluator = shift @in;
		 $self->LABELED_ANS($label, $evaluator);
  }
  $self->{PG_ANSWERS_HASH};
}




=item STOP_RENDERING()

 STOP_RENDERING() unless all_answers_are_correct();

Temporarily suspends accumulation of problem text and storing of answer blanks
and answer evaluators until RESUME_RENDERING() is called.

=cut

# ^function STOP_RENDERING
# ^uses $PG_STOP_FLAG
sub STOP_RENDERING {
	my $self = shift;
	$self->{PG_ACTIVE}=0;
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
	my $self = shift;
	$self->{PG_ACTIVE}=1;
	"";
}
########
# Internal methods
#########
sub new_label {     #creates a new label for unlabeled submissions ASNWER_PREFIX.$number
	my $self         = shift;
	my $number       = shift;
	$self->{QUIZ_PREFIX}.$self->{ANSWER_PREFIX}.sprintf("%04u", $number);
}
sub new_array_label {     #creates a new label for unlabeled submissions ASNWER_PREFIX.$number
	my $self         = shift;
	my $number       = shift;
	$self->{QUIZ_PREFIX}.$self->{ARRAY_PREFIX}.sprintf("%04u", $number);
}
sub new_array_element_label {     #creates a new label for unlabeled submissions ARRAY_PREFIX.$number
	my $self              = shift;
	my $ans_label         = shift;  # name of the PGanswer group holding this array
	my $row_num           = shift;
	my $col_num           = shift;
	my %options           = @_;
	my $vec_num           = (defined $options{vec_num})?$options{vec_num}: 0 ;
	$self->{QUIZ_PREFIX}.$ans_label.'__'.$vec_num.'-'.$row_num.'-'.$col_num.'__';
}
sub new_answer_name  {     # bit of a legacy item
	&new_label;
}


sub record_ans_name {      # the labels in the PGanswer group and response group should match in this case
	my $self = shift;
	my $label = shift;
	my $value = shift;
	#$self->internal_debug_message("PGcore::record_ans_name: $label $value");
	my $response_group = new PGresponsegroup($label,$label,$value);
	#$self->debug_message("adding a response group $response_group");
	if (ref($self->{PG_ANSWERS_HASH}->{$label})=~/PGanswergroup/ ) {
		$self->{PG_ANSWERS_HASH}->{$label}->replace(ans_label => $label, 
		                                           response  => $response_group, 
		                                           active    => $self->{PG_ACTIVE});
	} else {
  		$self->{PG_ANSWERS_HASH}->{$label} = PGanswergroup->new($label, 
  		                                           response  => $response_group, 
  		                                           active    => $self->{PG_ACTIVE});
  	}
  	$self->{answer_blank_count}++;
	$label;
}

sub record_array_name {  # currently the same as record ans name
	my $self = shift;
	my $label = shift;
	my $value = shift;
	my $response_group = new PGresponsegroup($label,$label,$value); 
	#$self->debug_message("adding a response group $response_group");
	if (ref($self->{PG_ANSWERS_HASH}->{$label})=~/PGanswergroup/ ) {
		$self->{PG_ANSWERS_HASH}->{$label}->replace(ans_label => $label, 
		                                           response   => $response_group, 
		                                           active     => $self->{PG_ACTIVE});
	} else {
  		$self->{PG_ANSWERS_HASH}->{$label} = PGanswergroup->new($label, 
  		                                           response   => $response_group, 
  		                                           active     => $self->{PG_ACTIVE});
  	}
  	$self->{answer_blank_count}++;
  	#$self->{PG_ANSWERS_HASH}->{$label}->{response}->clear;  #why is this ?
	$label;

}


sub extend_ans_group {         # modifies the group type
	my $self = shift;
	my $label = shift;
	my @response_list = @_;
	my $answer_group  = $self->{PG_ANSWERS_HASH}->{$label};
	if (ref($answer_group) =~/PGanswergroup/) {
    	$answer_group->append_responses(@response_list);
    } else {
    	#$self->warning_message("The answer |$label| has not yet been defined, you cannot extend it.",caller() );
    	# this error message is correct but misleading for the original way 
    	# in which matrix blanks and their response evaluators are matched up
    	# we should restore the warning message once the new matrix evaluation method is in place
    
    }
    $label;
}

sub record_unlabeled_ans_name {
	my $self = shift;
    $self->{unlabeled_answer_blank_count}++;
    my $label = $self->new_label($self->{unlabeled_answer_blank_count});
    $self->record_ans_name($label);
    $label;
}
sub record_unlabeled_array_name {
	my $self = shift;
    $self->{unlabeled_answer_blank_count}++;
    my $ans_label = $self->new_array_label($self->{unlabeled_answer_blank_count});
    $self->record_array_name($ans_label);                          
}
sub store_persistent_data {  # will store strings only (so far)
	my $self = shift;
	my $label = shift;
	my @content = @_;
	# $self->internal_debug_message("PGcore::store_persistent_data: storing $label in PERSISTENCE_HASH");
	if (defined($self->{PERSISTENCE_HASH}->{$label}) ) {
		warn "can' overwrite $label in persistent data";
	} else {
  		$self->{PERSISTENCE_HASH}->{$label} = join("",@content);  #need base64 encoding?
  	}
	$label;
}
sub check_answer_hash {
	my $self = shift;
	foreach my $key (keys %{ $self->{PG_ANSWERS_HASH} }) {
	    my $ans_eval = $self->{PG_ANSWERS_HASH}->{$key}->{ans_eval};
		unless (ref($ans_eval) =~ /CODE/ or ref($ans_eval) =~ /AnswerEvaluator/ ) {
			warn "The answer group labeled $key is missing an answer evaluator";
		}
		unless (ref( $self->{PG_ANSWERS_HASH}->{$key}->{response} ) =~ /PGresponsegroup/ ) {
			warn "The answer group labeled $key is missing answer blanks ";
		}
	}
}

sub PG_restricted_eval {
	my $self = shift;
	WeBWorK::PG::Translator::PG_restricted_eval(@_);
}		


# =head2 base64 coding
# 
# 	$str       = decode_base64($coded_str);
# 	$coded_str = encode_base64($str);
# 
# # Sometimes a question author needs to code or decode base64 directly
# 
# =cut
# 
sub decode_base64 ($) {
	my $self = shift;
	my $str = shift;
	MIME::Base64::decode_base64($str);
}

sub encode_base64 ($;$) {
	my $self = shift;
	my $str  = shift;
	my $option = shift;
	MIME::Base64::encode_base64($str);
}

#####
#  This macro encodes HTML, EV3, and PGML special caracters using html codes
#  This should be done for any variable which contains student input and is
#  printed to a screen or interpreted by EV3.  

sub encode_pg_and_html {
    my $input = shift;
    $input = HTML::Entities::encode_entities($input,
		   '<>"&\'\$\@\\\\`\\[*_\x00-\x1F\x7F');
    return $input;
}

=head2   Message channels

There are three message channels
	$PG->debug_message()   or in PG:  DEBUG_MESSAGE() 
	$PG->warning_message() or in PG:  WARN_MESSAGE()
	
They behave the same way, it is simply convention as to how they are used.
	
To report the messages use:

	$PG->get_debug_messages
	$PG->get_warning_messages

These are used in Problem.pm for example to report any errors.

There is also
    	
    $PG->internal_debug_message()
	$PG->get_internal_debug_message
	$PG->clear_internal_debug_messages();
	
There were times when things were buggy enough that only the internal_debug_message which are not saved
inside the PGcore object would report.

=cut


sub debug_message {
    my $self = shift;
	my @str = @_;
	push @{$self->{DEBUG_messages}}, "<br/>\n", @str;
}
sub get_debug_messages {
	my $self = shift;
	$self->{DEBUG_messages};
}
sub warning_message {
    my $self = shift;
	my @str = @_;
	unshift @str, "<br/>------"; # mark start of each message
	push @{$self->{WARNING_messages}}, @str;
}
sub get_warning_messages {
	my $self = shift;
	$self->{WARNING_messages};
}

sub internal_debug_message {
    my $self = shift;
	my @str = @_;
	push @{$internal_debug_messages}, @str;
}
sub get_internal_debug_messages {
	my $self = shift;
	$internal_debug_messages;
}
sub clear_internal_debug_messages {
	my $self = shift;
	$internal_debug_messages=[];
}

sub DESTROY {
	# doing nothing about destruction, hope that isn't dangerous
}

# sub WARN {
# 	warn(@_);
# }


# This creates on the fly graphs

=head2 insertGraph

	# returns a path to the file containing the graph image.
	$filePath = insertGraph($graphObject);

insertGraph writes a GIF or PNG image file to the gif subdirectory of the
current course's HTML temp directory. The file name is obtained from the graph
object. Warnings are issued if errors occur while writing to the file.

Returns a string containing the full path to the temporary file containing the
image. This is most often used in the construct

	TEXT(alias(insertGraph($graph)));

where alias converts the directory address to a URL when serving HTML pages and
insures that an EPS file is generated when creating TeX code for downloading.

=cut

# ^function insertGraph
# ^uses $WWPlot::use_png
# ^uses convertPath
# ^uses surePathToTmpFile
# ^uses PG_restricted_eval
# ^uses $refreshCachedImages
# ^uses $templateDirectory
# ^uses %envir
sub insertGraph {
	# Convert the image to GIF and print it on standard output
	my $self     = shift;
	my $graph    = shift;
	my $extension = ($WWPlot::use_png) ? '.png' : '.gif';
	my $fileName = $graph->imageName  . $extension;
	my $filePath = $self->convertPath("gif/$fileName");
	my $templateDirectory = $self->{envir}{templateDirectory};
	$filePath = $self->surePathToTmpFile( $filePath );
	my $refreshCachedImages = $self->PG_restricted_eval(q!$refreshCachedImages!);
	# Check to see if we already have this graph, or if we have to make it
	if( not -e $filePath # does it exist?
	  or ((stat "$templateDirectory".$self->{envir}{probFileName})[9] > (stat $filePath)[9]) # source has changed
	  or $self->{envir}{setNumber} =~ /Undefined_Set/ # problems from SetMaker and its ilk should always be redone
	  or $refreshCachedImages
	) {
		local(*OUTPUT);  # create local file handle so it won't overwrite other open files.
 		open(OUTPUT, ">$filePath")||warn ("$0","Can't open $filePath<BR>","");
 		chmod( 0777, $filePath);
 		print OUTPUT $graph->draw|| warn("$0","Can't print graph to $filePath<BR>","");
 		close(OUTPUT)||warn("$0","Can't close $filePath<BR>","");
	}
	$filePath;
}

=head1 Macros from IO.pm

		includePGtext
		read_whole_problem_file
		convertPath
		getDirDelim
		fileFromPath
		directoryFromPath
		createDirectory

=cut
sub maketext {
  my $self = shift;
  # uncomment this to check to see if strings are run through
  # maketext.  
  # return 'xXx'.  &{ $self->{maketext}}(@_).'xXx';
  &{ $self->{maketext}}(@_);
}
sub includePGtext { 
	my $self = shift;
	WeBWorK::PG::IO::includePGtext(@_); 
 };
sub read_whole_problem_file { 
	my $self = shift;
	WeBWorK::PG::IO::read_whole_problem_file(@_); 
 };
sub convertPath { 
	my $self = shift;
	WeBWorK::PG::IO::convertPath(@_); 
 };
sub getDirDelim { 
	my $self = shift;
	WeBWorK::PG::IO::getDirDelim(@_); 
 };
sub fileFromPath { 
	my $self = shift;
	WeBWorK::PG::IO::fileFromPath(@_); 
 };
sub directoryFromPath { 
	my $self = shift;
	WeBWorK::PG::IO::directoryFromPath(@_); 
 };
sub createDirectory { 
	my $self = shift;
	WeBWorK::PG::IO::createDirectory(@_); 
 };
sub AskSage {
	my $self = shift;
	my $python = shift;
	my $options = shift;
	$options->{curlCommand} = $self->{envir}->{externalCurlCommand};
	WeBWorK::PG::IO::AskSage($python, $options);
}
 
sub tempDirectory {
	my $self = shift;
	return $self->{tempDirectory};
}


=head2 surePathToTmpFile

	$path = surePathToTmpFile($path);

Creates all of the intermediate directories between the tempDirectory 

If $path begins with the tempDirectory path, then the
path is treated as absolute. Otherwise, the path is treated as relative the the
course temp directory.

=cut

# A very useful macro for making sure that all of the directories to a file have been constructed.

# ^function surePathToTmpFile
# ^uses getCourseTempDirectory
# ^uses createDirectory


sub surePathToTmpFile {
	# constructs intermediate directories if needed beginning at ${Global::htmlDirectory}tmp/
	# the input path must be either the full path, or the path relative to this tmp sub directory
	
	my $self = shift;
	my $path = shift;
	my $delim = "/"; 
	my $tmpDirectory = $self->tempDirectory();
	unless ( -e $tmpDirectory) {   # if by some unlucky chance the tmpDirectory hasn't been created, create it.
	    my $parentDirectory =  $tmpDirectory;
	    $parentDirectory =~s|/$||;  # remove a trailing /
		$parentDirectory = $self->directoryFromPath($parentDirectory);
	    my ($perms, $groupID) = (stat $parentDirectory)[2,5];
        #warn "Creating tmp directory at $tmpDirectory, perms $perms groupID $groupID";
		$self->createDirectory($tmpDirectory, $perms, $groupID)
				or warn "Failed to create parent tmp directory at $path";
	
	}
	# use the permissions/group on the temp directory itself as a template
	my ($perms, $groupID) = (stat $tmpDirectory)[2,5];
    #warn "surePathToTmpFile: directory=$tmpDirectory, perms=$perms, groupID=$groupID\n";
	
	# if the path starts with $tmpDirectory (which is permitted but optional) remove this initial segment
	$path =~ s|^$tmpDirectory|| if $path =~ m|^$tmpDirectory|;
	
	# find the nodes on the given path
        my @nodes = split("$delim",$path);
	
	# create new path
	$path = $tmpDirectory; 
	
	while (@nodes>1) {
		$path = $path . shift (@nodes) . "/"; #convertPath($path . shift (@nodes) . "/");

		unless (-e $path) {
			$self->createDirectory($path, $perms, $groupID)
				or $self->warning_message( "Failed to create directory at $path with permissions $perms and groupID $groupID");
		}

	}
	
	$path = $path . shift(@nodes); #convertPath($path . shift(@nodes));
	return $path;
}


1;
