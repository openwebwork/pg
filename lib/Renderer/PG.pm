################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2018 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: webwork2/lib/WeBWorK/PG.pm,v 1.76 2009/07/18 02:52:51 gage Exp $
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

# Note: this is basically the WeBWorK::PG file from the WeBWorK side.
# intention to simplify and strip out DB calls and webwork CourseEnvironment.

package Renderer::PG;

=head1 NAME

WeBWorK::PG - Invoke one of several PG rendering methods using an easy-to-use
API.

=cut

use strict;
use warnings;
# use WeBWorK::Debug;
use Renderer::Localize;
use Renderer::ImageGenerator;
use Renderer::Utils qw(runtime_use formatDateTime makeTempDirectory);
use Renderer::Utils::RestrictedClosureClass;

use constant DISPLAY_MODES => {
	# display name   # mode name
	tex       => "TeX",
	plainText => "HTML",
	images    => "HTML_dpng",
	MathJax   => "HTML_MathJax",
	PTX       => "PTX",
};

sub new {
	shift;    # throw away invocant -- we don't need it
	my ($pg_env, $user, $key, $set, $problem, $psvn, $formFields, $translationOptions) = @_;

	dd 'in PG::new';

	my $renderer = $pg_env->{renderer}->{base};

	runtime_use $renderer;

	return $renderer->new(@_);
}

sub free {
	my $self = shift;
	#
	#  If certain MathObjects (e.g. LimitedPolynomials) are left in the PG structure, then
	#  freeing them later can cause "Can't locate package ..." errors in the log during
	#  perl garbage collection.  So free them here.
	#
	$self->{pgcore}{OUTPUT_ARRAY} = [];
	$self->{answers} = {};
	undef $self->{translator};
	foreach (keys %{ $self->{pgcore}{PG_ANSWERS_HASH} }) { undef $self->{pgcore}{PG_ANSWERS_HASH}{$_} }
}

sub defineProblemEnvir {
	my ($self, $pg_env, $user, $key, $set, $problem, $psvn, $formFields, $translationOptions, $extras,) = @_;

	my %envir;

	debug("in Renderer::PG");

	# ----------------------------------------------------------------------

	# PG environment variables
	# from docs/pglanguage/pgreference/environmentvariables as of 06/25/2002
	# any changes are noted by "ADDED:" or "REMOVED:"

	# Vital state information
	# ADDED: displayModeFailover, displayHintsQ, displaySolutionsQ,
	#        refreshMath2img, texDisposition

	$envir{psvn} = $psvn;                         #'problem set version number' (associated with homework set)
	$envir{psvn} = $envir{psvn} // $set->psvn;    # use set value of psvn unless there is an explicit override.
		# update problemUUID from submitted form, and fall back to the earlier name problemIdentifierPrefix if necessary
	$envir{problemUUID} = $formFields->{problemUUID} // $formFields->{problemIdentifierPrefix} // $envir{problemUUID}
		// 0;
	$envir{psvnNumber}     = "psvnNumber-is-deprecated-Please-use-psvn-Instead";              #FIXME
	$envir{probNum}        = $problem->problem_id;
	$envir{questionNumber} = $envir{probNum};
	$envir{fileName}       = $problem->source_file;
	$envir{probFileName}   = $envir{fileName};
	$envir{problemSeed}    = $problem->problem_seed;
	$envir{displayMode}    = translateDisplayModeNames($translationOptions->{displayMode});
	#	$envir{languageMode}        = $envir{displayMode};	# don't believe this is ever used.
	$envir{outputMode}        = $envir{displayMode};
	$envir{displayHintsQ}     = $translationOptions->{showHints};
	$envir{displaySolutionsQ} = $translationOptions->{showSolutions};
	$envir{texDisposition}    = "pdf";                                  # in webwork2, we use pdflatex

	# Problem Information
	# ADDED: courseName, formatedDueDate, enable_reduced_scoring

	$envir{openDate}          = $set->open_date;
	$envir{formattedOpenDate} = formatDateTime($envir{openDate}, $pg_env->{site}->{timezone});
	$envir{OpenDateDayOfWeek} =
		formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%A", $pg_env->{site}->{locale});
	$envir{OpenDateDayOfWeekAbbrev} =
		formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%a", $pg_env->{site}->{locale});
	$envir{OpenDateDay} =
		formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%d", $pg_env->{site}->{locale});
	$envir{OpenDateMonthNumber} =
		formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%m", $pg_env->{site}->{locale});
	$envir{OpenDateMonthWord} =
		formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%B", $pg_env->{site}->{locale});
	$envir{OpenDateMonthAbbrev} =
		formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%b", $pg_env->{site}->{locale});
	$envir{OpenDateYear2Digit} =
		formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%y", $pg_env->{site}->{locale});
	$envir{OpenDateYear4Digit} =
		formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%Y", $pg_env->{site}->{locale});
	$envir{OpenDateHour12} =
		formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%I", $pg_env->{site}->{locale});
	$envir{OpenDateHour24} =
		formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%H", $pg_env->{site}->{locale});
	$envir{OpenDateMinute} =
		formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%M", $pg_env->{site}->{locale});
	$envir{OpenDateAMPM} =
		formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%P", $pg_env->{site}->{locale});
	$envir{OpenDateTimeZone} =
		formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%Z", $pg_env->{site}->{locale});
	$envir{OpenDateTime12} =
		formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%I:%M%P", $pg_env->{site}->{locale});
	$envir{OpenDateTime24} =
		formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%R", $pg_env->{site}->{locale});
	$envir{dueDate}          = $set->due_date;
	$envir{formattedDueDate} = formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone});
	$envir{formatedDueDate}  = $envir{formattedDueDate};                                     # typo in many header files
	$envir{DueDateDayOfWeek} =
		formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%A", $pg_env->{site}->{locale});
	$envir{DueDateDayOfWeekAbbrev} =
		formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%a", $pg_env->{site}->{locale});
	$envir{DueDateDay} = formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%d", $pg_env->{site}->{locale});
	$envir{DueDateMonthNumber} =
		formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%m", $pg_env->{site}->{locale});
	$envir{DueDateMonthWord} =
		formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%B", $pg_env->{site}->{locale});
	$envir{DueDateMonthAbbrev} =
		formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%b", $pg_env->{site}->{locale});
	$envir{DueDateYear2Digit} =
		formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%y", $pg_env->{site}->{locale});
	$envir{DueDateYear4Digit} =
		formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%Y", $pg_env->{site}->{locale});
	$envir{DueDateHour12} =
		formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%I", $pg_env->{site}->{locale});
	$envir{DueDateHour24} =
		formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%H", $pg_env->{site}->{locale});
	$envir{DueDateMinute} =
		formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%M", $pg_env->{site}->{locale});
	$envir{DueDateAMPM} = formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%P", $pg_env->{site}->{locale});
	$envir{DueDateTimeZone} =
		formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%Z", $pg_env->{site}->{locale});
	$envir{DueDateTime12} =
		formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%I:%M%P", $pg_env->{site}->{locale});
	$envir{DueDateTime24} =
		formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%R", $pg_env->{site}->{locale});
	$envir{answerDate}          = $set->answer_date;
	$envir{formattedAnswerDate} = formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone});
	$envir{AnsDateDayOfWeek} =
		formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%A", $pg_env->{site}->{locale});
	$envir{AnsDateDayOfWeekAbbrev} =
		formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%a", $pg_env->{site}->{locale});
	$envir{AnsDateDay} =
		formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%d", $pg_env->{site}->{locale});
	$envir{AnsDateMonthNumber} =
		formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%m", $pg_env->{site}->{locale});
	$envir{AnsDateMonthWord} =
		formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%B", $pg_env->{site}->{locale});
	$envir{AnsDateMonthAbbrev} =
		formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%b", $pg_env->{site}->{locale});
	$envir{AnsDateYear2Digit} =
		formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%y", $pg_env->{site}->{locale});
	$envir{AnsDateYear4Digit} =
		formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%Y", $pg_env->{site}->{locale});
	$envir{AnsDateHour12} =
		formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%I", $pg_env->{site}->{locale});
	$envir{AnsDateHour24} =
		formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%H", $pg_env->{site}->{locale});
	$envir{AnsDateMinute} =
		formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%M", $pg_env->{site}->{locale});
	$envir{AnsDateAMPM} =
		formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%P", $pg_env->{site}->{locale});
	$envir{AnsDateTimeZone} =
		formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%Z", $pg_env->{site}->{locale});
	$envir{AnsDateTime12} =
		formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%I:%M%P", $pg_env->{site}->{locale});
	$envir{AnsDateTime24} =
		formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%R", $pg_env->{site}->{locale});
	my $ungradedAttempts = ($formFields->{submitAnswers}) ? 1 : 0;    # is an attempt about to be graded?
	$envir{numOfAttempts}          = ($problem->num_correct || 0) + ($problem->num_incorrect || 0) + $ungradedAttempts;
	$envir{problemValue}           = $problem->value;
	$envir{sessionKey}             = $key;
	$envir{courseName}             = $pg_env->{environment}->{course_name};
	$envir{enable_reduced_scoring} = $pg_env->{ansEvalDefaults}->{enableReducedScoring} && $set->enable_reduced_scoring;

	$envir{language}                    = $pg_env->{environment}->{language};
	$envir{language_subroutine}         = Renderer::Localize::getLoc($envir{language});
	$envir{reducedScoringDate}          = $set->reduced_scoring_date;
	$envir{formattedReducedScoringDate} = formatDateTime($envir{reducedScoringDate}, $pg_env->{site}->{timezone});

	# Student Information
	# ADDED: studentID

	$envir{sectionName}      = $user->section;
	$envir{sectionNumber}    = $envir{sectionName};
	$envir{recitationName}   = $user->recitation;
	$envir{recitationNumber} = $envir{recitationName};
	$envir{setNumber}        = $set->set_id;
	$envir{studentLogin}     = $user->user_id;
	$envir{studentName}      = $user->first_name . " " . $user->last_name;
	$envir{studentID}        = $user->student_id;
	$envir{permissionLevel}  = $translationOptions->{permissionLevel};       # permission level of actual user
	$envir{effectivePermissionLevel} =
		$translationOptions->{effectivePermissionLevel};    # permission level of user assigned to this question

	# Answer Information
	# REMOVED: refSubmittedAnswers

	$envir{inputs_ref} = $formFields;

	# External Programs
	# ADDED: externalLaTeXPath, externalDvipngPath,
	#        externalGif2EpsPath, externalPng2EpsPath

	$envir{externalLaTeXPath}   = $pg_env->{environment}->{externalPrograms}->{latex};
	$envir{externalDvipngPath}  = $pg_env->{environment}->{externalPrograms}->{dvipng};
	$envir{externalGif2EpsPath} = $pg_env->{environment}->{externalPrograms}->{gif2eps};
	$envir{externalPng2EpsPath} = $pg_env->{environment}->{externalPrograms}->{png2eps};
	$envir{externalGif2PngPath} = $pg_env->{environment}->{externalPrograms}->{gif2png};
	$envir{externalCheckUrl}    = $pg_env->{environment}->{externalPrograms}->{checkurl};
	#$envir{externalCurlCommand}  = $pg_env->{environment}->{externalPrograms}->{curl};
	# Directories and URLs
	# REMOVED: courseName
	# ADDED: dvipngTempDir
	# ADDED: jsMathURL
	# ADDED: MathJaxURL
	# ADDED: asciimathURL
	# ADDED: macrosPath
	# REMOVED: macrosDirectory, courseScriptsDirectory
	# ADDED: LaTeXMathML

	$envir{cgiDirectory}   = undef;
	$envir{cgiURL}         = undef;
	$envir{classDirectory} = undef;
	$envir{macrosPath}     = $pg_env->{environment}->{macrosPath};
	$envir{appletPath}     = $pg_env->{environment}->{appletPath};
	$envir{htmlPath}       = $pg_env->{environment}->{htmlPath};
	$envir{imagesPath}     = $pg_env->{environment}->{imagesPath};
	$envir{pdfPath}        = $pg_env->{environment}->{pdfPath};
	# This is no longer needed.
	# $envir{pgDirectories}          = $ce->{pg}->{directories};

	# The following two are not used anywhere
	# $envir{webworkHtmlDirectory}   = $ce->{webworkDirs}->{htdocs}."/";
	# $envir{webworkHtmlURL}         = $ce->{webworkURLs}->{htdocs}."/";
	$envir{htmlDirectory}     = $pg_env->{directories}->{course_html} . "/";
	$envir{htmlURL}           = $pg_env->{URLs}->{course_html} . "/";
	$envir{templateDirectory} = $pg_env->{directories}->{course_templates} . "/";
	$envir{tempDirectory}     = $pg_env->{directories}->{temp_dir} . "/";
	$envir{tempURL}           = $pg_env->{URLs}->{html_temp} . "/";
	$envir{scriptDirectory}   = undef;
	$envir{webworkDocsURL}    = $pg_env->{URLs}->{webwork_docs} . "/";
	$envir{localHelpURL}      = $pg_env->{URLs}->{local_help} . "/";
	$envir{MathJaxURL}        = $pg_env->{URLs}->{mathjax};
	$envir{server_root_url}   = $pg_env->{server_root_url} || '';

	# Information for sending mail

	# Can we push this to webwork?

	# $envir{mailSmtpServer} = $ce->{mail}->{smtpServer};
	# $envir{mailSmtpSender} = $ce->{mail}->{smtpSender};
	# $envir{ALLOW_MAIL_TO}  = $ce->{mail}->{allowedRecipients};

	# Default values for evaluating answers

	my $ansEvalDefaults = $pg_env->{ansEvalDefaults};
	$envir{$_} = $ansEvalDefaults->{$_} foreach (keys %$ansEvalDefaults);

	# ----------------------------------------------------------------------

	# ADDED: ImageGenerator for images mode
	if (defined $extras->{image_generator}) {
		#$envir{imagegen} = $extras->{image_generator};
		# only allow access to the add() method
		$envir{imagegen} =
			new Renderer::Utils::RestrictedClosureClass($extras->{image_generator}, 'add', 'addToTeXPreamble',
			'refresh');
	}

	if (defined $extras->{mailer}) {
		#my $rmailer = new Renderer::Utils::RestrictedClosureClass($extras->{mailer},
		#	qw/Open SendEnc Close Cancel skipped_recipients error error_msg/);
		#my $safe_hole = new Safe::Hole {};
		#$envir{mailer} = $safe_hole->wrap($rmailer);
		# $envir{mailer} = new Renderer::Utils::RestrictedClosureClass($extras->{mailer}, "add_message");
	}
	# ADDED use_opaque_prefix and use_site_prefix

	$envir{use_site_prefix}   = $translationOptions->{use_site_prefix};
	$envir{use_opaque_prefix} = $translationOptions->{use_opaque_prefix};

	# Other things...
	$envir{QUIZ_PREFIX}           = $translationOptions->{QUIZ_PREFIX} // '';      # used by quizzes
	$envir{PROBLEM_GRADER_TO_USE} = $pg_env->{renderer}->{grader};
	$envir{PRINT_FILE_NAMES_FOR}  = $pg_env->{env_vars}->{PRINT_FILE_NAMES_FOR};
	$envir{useMathQuill}          = $translationOptions->{useMathQuill};

	#  ADDED: __files__
	#    an array for mapping (eval nnn) to filenames in error messages
	$envir{__files__} = {
		# Note: we shouldn't need the webwork information
		# root => $ce->{webworkDirs}{root},
		pg   => $pg_env->{environment}->{pg_root},             # used to shorten filenames
		tmpl => $pg_env->{directories}->{course_templates},    # ditto
	};

	# variables for interpreting capa problems and other things to be
	# seen in a pg file
	my $specialPGEnvironmentVarHash = $pg_env->{env_vars};
	for my $SPGEV (keys %{$specialPGEnvironmentVarHash}) {
		$envir{$SPGEV} = $specialPGEnvironmentVarHash->{$SPGEV};
	}

	return \%envir;
}

sub translateDisplayModeNames($) {
	my $name = shift;
	return DISPLAY_MODES()->{$name};
}

sub oldSafetyFilter {
	my $answer          = shift;     # accepts one answer and checks it
	my $submittedAnswer = $answer;
	$answer = '' unless defined $answer;
	my ($errorno);
	$answer =~ tr/\000-\037/ /;
	# Return if answer field is empty
	unless ($answer =~ /\S/) {
		#$errorno = "<BR>No answer was submitted.";
		$errorno = 0;    ## don't report blank answer as error
		return ($answer, $errorno);
	}
	# replace ^ with **    (for exponentiation)
	# $answer =~ s/\^/**/g;
	# Return if forbidden characters are found
	unless ($answer =~ /^[a-zA-Z0-9_\-\+ \t\/@%\*\.\n^\[\]\(\)\,\|]+$/) {
		$answer =~ tr/a-zA-Z0-9_\-\+ \t\/@%\*\.\n^\(\)/#/c;
		$errorno = "<BR>There are forbidden characters in your answer: $submittedAnswer<BR>";
		return ($answer, $errorno);
	}
	$errorno = 0;
	return ($answer, $errorno);
}

sub nullSafetyFilter {
	return shift, 0;    # no errors
}

1;

__END__

=head1 SYNOPSIS

 $pg = WeBWorK::PG->new(
	 $ce,         # a WeBWorK::CourseEnvironment object
	 $user,       # a WeBWorK::DB::Record::User object
	 $sessionKey,
	 $set,        # a WeBWorK::DB::Record::UserSet object
	 $problem,    # a WeBWorK::DB::Record::UserProblem object
	 $psvn,
	 $formFields  # in &WeBWorK::Form::Vars format
	 { # translation options
		 displayMode     => "images", # (plainText|formattedText|images|MathJax)
		 showHints       => 1,        # (0|1)
		 showSolutions   => 0,        # (0|1)
		 refreshMath2img => 0,        # (0|1)
		 processAnswers  => 1,        # (0|1)
	 },
 );

 $translator = $pg->{translator}; # Renderer::Translator
 $body       = $pg->{body_text};  # text string
 $header     = $pg->{head_text};  # text string
 $post_header_text = $pg->{post_header_text};  # text string
 $answerHash = $pg->{answers};    # WeBWorK::PG::AnswerHash
 $result     = $pg->{result};     # hash reference
 $state      = $pg->{state};      # hash reference
 $errors     = $pg->{errors};     # text string
 $warnings   = $pg->{warnings};   # text string
 $flags      = $pg->{flags};      # hash reference

=head1 DESCRIPTION

WeBWorK::PG is a factory for modules which use the WeBWorK::PG API. Notable
modules which use this API (and exist) are WeBWorK::PG::Local and
WeBWorK::PG::Remote. The course environment key $pg{renderer} is consulted to
determine which render to use.

=head1 THE WEBWORK::PG API

Modules which support this API must implement the following method:

=over

=item new ENVIRONMENT, USER, KEY, SET, PROBLEM, PSVN, FIELDS, OPTIONS

The C<new> method creates a translator, initializes it using the parameters
specified, translates a PG file, and processes answers. It returns a reference
to a blessed hash containing the results of the translation process.

=back

=head2 Parameters

=over

=item ENVIRONMENT

a WeBWorK::CourseEnvironment object

=item USER

a WeBWorK::User object

=item KEY

the session key of the current session

=item SET

a WeBWorK::Set object

=item PROBLEM

a WeBWorK::DB::Record::UserProblem object. The contents of the source_file
field can specify a PG file either by absolute path or path relative to the
"templates" directory. I<The caller should remove taint from this value before
passing!>

=item PSVN

the problem set version number: use variable $psvn

=item FIELDS

a reference to a hash (as returned by &WeBWorK::Form::Vars) containing form
fields submitted by a problem processor. The translator will look for fields
like "AnSwEr[0-9]" containing submitted student answers.

=item OPTIONS

a reference to a hash containing the following data:

=over

=item displayMode

one of "plainText", "formattedText", "MathJax" or "images"

=item showHints

boolean, render hints

=item showSolutions

boolean, render solutions

=item refreshMath2img

boolean, force images created by math2img (in "images" mode) to be recreated,
even if the PG source has not been updated. FIXME: remove this option.

=item processAnswers

boolean, call answer evaluators and graders

=back

=back

=head2 RETURN VALUE

The C<new> method returns a blessed hash reference containing the following
fields. More information can be found in the documentation for
Renderer::Translator.

=over

=item translator

The Renderer::Translator object used to render the problem.

=item head_text

HTML code for the E<lt>headE<gt> block of an resulting web page. Used for
JavaScript features.

=item body_text

HTML code for the E<lt>bodyE<gt> block of an resulting web page.

=item answers

An C<AnswerHash> object containing submitted answers, and results of answer
evaluation.

=item result

A hash containing the results of grading the problem.

=item state

A hash containing the new problem state.

=item errors

A string containing any errors encountered while rendering the problem.

=item warnings

A string containing any warnings encountered while rendering the problem.

=item flags

A hash containing PG_flags (see the Translator docs).

=back

=head1 METHODS PROVIDED BY THE BASE CLASS

The following methods are provided for use by subclasses of WeBWorK::PG.

=over

=item defineProblemEnvir ENVIRONMENT, USER, KEY, SET, PROBLEM, PSVN, FIELDS, OPTIONS

Generate a problem environment hash to pass to the renderer.

=item translateDisplayModeNames NAME

NAME contains

=back

=head1 AUTHOR

Written by Sam Hathaway, sh002i (at) math.rochester.edu.

=cut
