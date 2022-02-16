################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2021 The WeBWorK Project, https://github.com/openwebwork
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

Problem.pm

=cut

# This is derived from the openwebwork/renderer branch.

package Renderer::Problem;

use PGEnvironment;
use Renderer::Translator;
use Renderer::Localize;
use Data::Dumper;

# This contains the subroutines from WeBWorK::PG and ??
# except that information like the user, set and problem info is stripped out
# and any necessary parameters (like the seed) should be directly passed in.

=head2

=head3 translationOptions

=over
=item - problem_source

The source of the pg problem.

=back

=cut

sub new {
	my $invocant = shift;
	my $class    = ref $invocant || $invocant;

	$self = {
		maketext   => sub { return @_ },
		inputs_ref => {},
		@_,
	};

	$self->{pg_env} = PGEnvironment->new() unless ($self->{pg_env});
	# check some defaults if not passed in.
	setDefaults($self);

	# The rest of this is from WeBWorK::PG::Local

	# install a local warn handler to collect warnings  FIXME -- figure out what I meant to do here.
	my $warnings = "";

	local $SIG{__WARN__} = sub { $warnings .= shift() . "<br/>\n" }
		if $self->{pg_env}->{renderer}->{catchWarnings};

	# create a Translator
	warn "PG: creating a Translator\n";
	$self->{translator} = Renderer::Translator->new;

	############################################################################
	# Here are the new instructions for preloading the macros
	############################################################################

	# STANDARD LOADING CODE: for cached script files, this merely
	# initializes the constants.
	#2010 -- in the new scheme PG.pl is the only file guaranteed
	# initialization -- it reads in everything that dangerous macros
	# and IO.pl
	# did before.  Mostly it just defines access to the PGcore object

	# 2021 -- for the standaloneRenderer, PG.pl is pre-cached in Translator.pm
	foreach (qw(PG.pl )) {    # dangerousMacros.pl IO.pl
		my $macroPath = $PG::Constants::PG_DIRECTORY . "/macros/$_";
		my $err       = $self->{translator}->unrestricted_load($macroPath);
		warn "Error while loading $macroPath: $err" if $err;
	}

	############################################################################
	# evaluate modules and "extra packages"
	############################################################################

	#warn "PG: evaluating modules and \"extra packages\"\n";

	for my $module_packages_ref (@{ $self->{pg_env}->{perl_modules} }) {
		my ($module, @extra_packages) = @$module_packages_ref;

		# the first item is the main package
		$self->{translator}->evaluate_modules($module);

		# the remaining items are "extra" packages
		$self->{translator}->load_extra_packages(@extra_packages);
	}

	############################################################################
	# prepare an imagegenerator object (if we're in "images" mode)
	############################################################################
	my $image_generator;
	my $site_prefix = ($translationOptions->{use_site_prefix}) // '';
	if ($self->{translationOptions}->{displayMode} eq "images"
		|| $self->{translationOptions}->{displayMode} eq "opaque_image")
	{
		my %imagesModeOptions = %{ $pg_env->{renderer}->{displayModeOptions}->{images} };
		$image_generator = Renderer::ImageGenerator->new(
			tempDir         => $pg_env->{directories}->{tmp_dir},         # global temp dir
			latex           => $pg_env->{externalPrograms}->{latex},
			dvipng          => $pg_env->{externalPrograms}->{dvipng},
			useCache        => 1,
			cacheDir        => $pg_env->{directories}->{equationCache},
			cacheURL        => $pg_env->{URLs}->{equation_cache},
			cacheDB         => $ce->{webworkFiles}{equationCacheDB},
			useMarkers      => ($imagesModeOptions{dvipng_align} && $imagesModeOptions{dvipng_align} eq 'mysql'),
			dvipng_align    => $imagesModeOptions{dvipng_align},
			dvipng_depth_db => $imagesModeOptions{dvipng_depth_db},
		);
	}

	bless $self, $class;
}

sub setDefaults {
	my $options = shift;

	# set defaults for the translationOptions
	my $t_opts = {};
	$t_opts->{displayMode} = $options->{translationOptions}->{displayMode}
		// $opts->{pg_env}->{renderer}->{displayMode};
	$t_opts->{problem_seed}        = $options->{translationOptions}->{problem_seed}      // 1;
	$t_opts->{showHints}           = $options->{translationOptions}->{showHints}         // 0;
	$t_opts->{showSolutions}       = $options->{translationOptions}->{showSolutions}     // 0;
	$t_opts->{refreshMath2img}     = $options->{refreshMath2img}->{showSolutions}        // 1;
	$t_opts->{processAnswers}      = $options->{translationOptions}->{processAnswers}    // 0;
	$t_opts->{QUIZ_PREFIX}         = $options->{translationOptions}->{QUIZ_PREFIX}       // 0;
	$t_opts->{use_opaque_prefix}   = $options->{translationOptions}->{use_opaque_prefix} // 0;
	$options->{translationOptions} = $t_opts;

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

sub render {
	my ($self, $psvn, $formFields) = @_;

	############################################################################
	# set the environment (from defineProblemEnvir)
	############################################################################

	my $envir = defineProblemEnvir(
		$self->{pg_env},
		$psvn,    #FIXME -- not used
		$formFields,
		$self->{translationOptions},
		{         #extras (this is kind of a hack, but not a serious one)
			image_generator => $image_generator,
			mailer          => $mailer,
			problemUUID     => 0,
		},
		x
	);
	$self->{translator}->environment($envir);
	$self->{translator}->initialize();

	############################################################################
	# set the opcode mask (using default values)
	############################################################################
	#warn "PG: setting the opcode mask (using default values)\n";
	$self->{translator}->set_mask();

	############################################################################
	# put the source into the translator object
	############################################################################

	print "adding the problem source to the translator\n";
	$self->{translator}->source_string($self->{problem_source});

	############################################################################
	# install a safety filter
	# FIXME -- I believe that since MathObjects this is no longer operational
	############################################################################
	#warn "PG: installing a safety filter\n";
	#$translator->rf_safety_filter(\&oldSafetyFilter);
	$self->{translator}->rf_safety_filter(\&nullSafetyFilter);

	############################################################################
	# translate the PG source into text
	############################################################################

	#warn "PG: translating the PG source into text\n";
	$self->{translator}->translate();

}

# This seems to be used only once.  No need to make it separate subroutine.

# sub translateDisplayModeNames($) {
# 	my $name = shift;
# 	return DISPLAY_MODES()->{$name};
# }

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

sub defineProblemEnvir {
	my (
		$pg_env,
		$psvn,          # Is it time to get rid of this?
		$formFields,
		$translationOptions,
		$extras,
	) = @_;

	my %envir;

	# ----------------------------------------------------------------------
	# PG environment variables
	# from docs/pglanguage/pgreference/environmentvariables as of 06/25/2002
	# any changes are noted by "ADDED:" or "REMOVED:"

	# Vital state information
	# ADDED: displayModeFailover, displayHintsQ, displaySolutionsQ,
	#        refreshMath2img, texDisposition

	$envir{psvn} = $psvn;    #'problem set version number' (associated with homework set)
	 # $envir{psvn}                = $envir{psvn}//$set->psvn; # use set value of psvn unless there is an explicit override.
	 # update problemUUID from submitted form, and fall back to the earlier name problemIdentifierPrefix if necessary
	$envir{problemUUID} = $formFields->{problemUUID} // $formFields->{problemIdentifierPrefix} // $envir{problemUUID}
		// 0;
	$envir{psvnNumber} = "psvnNumber-is-deprecated-Please-use-psvn-Instead";    #FIXME
		# $envir{probNum}             = $problem->problem_id;
	$envir{questionNumber} = $envir{probNum};
	# $envir{fileName}            = $problem->source_file;
	$envir{probFileName} = $envir{fileName};
	$envir{problemSeed}  = $translationOptions->{problem_seed};
	$envir{displayMode}  = $pg_env->{renderer}->{display_modes}->{ $translationOptions->{displayMode} };
	#	$envir{languageMode}        = $envir{displayMode};	# don't believe this is ever used.
	$envir{outputMode}        = $envir{displayMode};
	$envir{displayHintsQ}     = $translationOptions->{showHints};
	$envir{displaySolutionsQ} = $translationOptions->{showSolutions};
	$envir{texDisposition}    = "pdf";                                  # in webwork2, we use pdflatex

	# Problem Information
	# ADDED: courseName, formatedDueDate, enable_reduced_scoring

# $envir{openDate}            = $set->open_date;
# $envir{formattedOpenDate}   = formatDateTime($envir{openDate}, $pg_env->{site}->{timezone});
# $envir{OpenDateDayOfWeek}   = formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%A", $pg_env->{site}->{locale});
# $envir{OpenDateDayOfWeekAbbrev} = formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%a", $pg_env->{site}->{locale});
# $envir{OpenDateDay}         = formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%d", $pg_env->{site}->{locale});
# $envir{OpenDateMonthNumber} = formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%m", $pg_env->{site}->{locale});
# $envir{OpenDateMonthWord}   = formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%B", $pg_env->{site}->{locale});
# $envir{OpenDateMonthAbbrev} = formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%b", $pg_env->{site}->{locale});
# $envir{OpenDateYear2Digit}  = formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%y", $pg_env->{site}->{locale});
# $envir{OpenDateYear4Digit}  = formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%Y", $pg_env->{site}->{locale});
# $envir{OpenDateHour12}      = formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%I", $pg_env->{site}->{locale});
# $envir{OpenDateHour24}      = formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%H", $pg_env->{site}->{locale});
# $envir{OpenDateMinute}      = formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%M", $pg_env->{site}->{locale});
# $envir{OpenDateAMPM}        = formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%P", $pg_env->{site}->{locale});
# $envir{OpenDateTimeZone}    = formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%Z", $pg_env->{site}->{locale});
# $envir{OpenDateTime12}      = formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%I:%M%P", $pg_env->{site}->{locale});
# $envir{OpenDateTime24}      = formatDateTime($envir{openDate}, $pg_env->{site}->{timezone}, "%R", $pg_env->{site}->{locale});
# $envir{dueDate}             = $set->due_date;
# $envir{formattedDueDate}    = formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone});
# $envir{formatedDueDate}     = $envir{formattedDueDate}; # typo in many header files
# $envir{DueDateDayOfWeek}    = formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%A", $pg_env->{site}->{locale});
# $envir{DueDateDayOfWeekAbbrev} = formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%a", $pg_env->{site}->{locale});
# $envir{DueDateDay}          = formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%d", $pg_env->{site}->{locale});
# $envir{DueDateMonthNumber}  = formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%m", $pg_env->{site}->{locale});
# $envir{DueDateMonthWord}    = formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%B", $pg_env->{site}->{locale});
# $envir{DueDateMonthAbbrev}  = formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%b", $pg_env->{site}->{locale});
# $envir{DueDateYear2Digit}   = formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%y", $pg_env->{site}->{locale});
# $envir{DueDateYear4Digit}   = formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%Y", $pg_env->{site}->{locale});
# $envir{DueDateHour12}       = formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%I", $pg_env->{site}->{locale});
# $envir{DueDateHour24}       = formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%H", $pg_env->{site}->{locale});
# $envir{DueDateMinute}       = formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%M", $pg_env->{site}->{locale});
# $envir{DueDateAMPM}         = formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%P", $pg_env->{site}->{locale});
# $envir{DueDateTimeZone}     = formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%Z", $pg_env->{site}->{locale});
# $envir{DueDateTime12}       = formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%I:%M%P", $pg_env->{site}->{locale});
# $envir{DueDateTime24}       = formatDateTime($envir{dueDate}, $pg_env->{site}->{timezone}, "%R", $pg_env->{site}->{locale});
# $envir{answerDate}          = $set->answer_date;
# $envir{formattedAnswerDate} = formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone});
# $envir{AnsDateDayOfWeek}    = formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%A", $pg_env->{site}->{locale});
# $envir{AnsDateDayOfWeekAbbrev} = formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%a", $pg_env->{site}->{locale});
# $envir{AnsDateDay}          = formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%d", $pg_env->{site}->{locale});
# $envir{AnsDateMonthNumber}  = formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%m", $pg_env->{site}->{locale});
# $envir{AnsDateMonthWord}    = formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%B", $pg_env->{site}->{locale});
# $envir{AnsDateMonthAbbrev}  = formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%b", $pg_env->{site}->{locale});
# $envir{AnsDateYear2Digit}   = formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%y", $pg_env->{site}->{locale});
# $envir{AnsDateYear4Digit}   = formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%Y", $pg_env->{site}->{locale});
# $envir{AnsDateHour12}       = formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%I", $pg_env->{site}->{locale});
# $envir{AnsDateHour24}       = formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%H", $pg_env->{site}->{locale});
# $envir{AnsDateMinute}       = formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%M", $pg_env->{site}->{locale});
# $envir{AnsDateAMPM}         = formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%P", $pg_env->{site}->{locale});
# $envir{AnsDateTimeZone}     = formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%Z", $pg_env->{site}->{locale});
# $envir{AnsDateTime12}       = formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%I:%M%P", $pg_env->{site}->{locale});
# $envir{AnsDateTime24}       = formatDateTime($envir{answerDate}, $pg_env->{site}->{timezone}, "%R", $pg_env->{site}->{locale});
# my $ungradedAttempts        = ($formFields->{submitAnswers})?1:0; # is an attempt about to be graded?
# # $envir{numOfAttempts}       = ($problem->num_correct || 0) + ($problem->num_incorrect || 0) +$ungradedAttempts;
# $envir{problemValue}        = $problem->value;
# $envir{sessionKey}          = $key;
# $envir{courseName}          = $pg_env->{environment}->{course_name};
# $envir{enable_reduced_scoring} = $pg_env->{ansEvalDefaults}->{enableReducedScoring} && $set->enable_reduced_scoring;

	$envir{language}            = $pg_env->{environment}->{language};
	$envir{language_subroutine} = Renderer::Localize::getLoc($envir{language});
	# $envir{reducedScoringDate} = $set->reduced_scoring_date;
	# $envir{formattedReducedScoringDate} = formatDateTime($envir{reducedScoringDate}, $pg_env->{site}->{timezone});

	# Student Information
	# ADDED: studentID

	# $envir{sectionName}      = $user->section;
	# $envir{sectionNumber}    = $envir{sectionName};
	# $envir{recitationName}   = $user->recitation;
	# $envir{recitationNumber} = $envir{recitationName};
	# $envir{setNumber}        = $set->set_id;
	# $envir{studentLogin}     = $user->user_id;
	# $envir{studentName}      = $user->first_name . " " . $user->last_name;
	# $envir{studentID}        = $user->student_id;
	# $envir{permissionLevel}  = $translationOptions->{permissionLevel};  # permission level of actual user
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

	# add all the pg environment variables to the environment:
	$envir{$_} = $pg_env->{env_vars}->{$_} foreach (keys %{ $pg_env->{env_vars} });

	# ----------------------------------------------------------------------

	# ADDED: ImageGenerator for images mode
	if (defined $extras->{image_generator}) {
		#$envir{imagegen} = $extras->{image_generator};
		# only allow access to the add() method
		$envir{imagegen} =
			new Renderer::Utils::RestrictedClosureClass($extras->{image_generator}, 'add', 'addToTeXPreamble',
			'refresh');
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

1;
