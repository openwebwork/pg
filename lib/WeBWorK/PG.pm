################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2022 The WeBWorK Project, https://github.com/openwebwork
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

package WeBWorK::PG;

use strict;
use warnings;
use feature 'signatures';
no warnings qw(experimental::signatures);

use WeBWorK::PG::Environment;
use WeBWorK::PG::Translator;
use WeBWorK::PG::RestrictedClosureClass;
use WeBWorK::PG::Constants;

use constant DISPLAY_MODES => {
	# display name   # mode name
	tex       => 'TeX',
	plainText => 'HTML',
	images    => 'HTML_dpng',
	MathJax   => 'HTML_MathJax',
	PTX       => 'PTX',
};

sub new ($invocant, %options) {
	local $SIG{ALRM} = sub ($) {
		my $msg =
			"Timeout after processing this problem for $WeBWorK::PG::TIMEOUT seconds. "
			. "Check for infinite loops in problem source.\n";
		warn $msg;
		die $msg;
	};
	alarm $WeBWorK::PG::TIMEOUT;
	my $pg = eval { $invocant->new_helper(%options) };
	alarm 0;
	die $@ if $@;
	return $pg;
}

sub new_helper ($invocant, %options) {
	my $class = ref($invocant) || $invocant;

	my $pg_envir = WeBWorK::PG::Environment->new($options{courseName});

	# Make sure these are defined.
	$options{sourceFilePath}    //= '';
	$options{templateDirectory} //= '';
	$options{inputs_ref}        //= {};

	# Set up the warning handler.
	my $warning_messages = '';

	local $SIG{__WARN__} = sub ($warning) { $warning_messages .= $warning; return; }
		if $pg_envir->{options}{catchWarnings};

	my $translator = WeBWorK::PG::Translator->new;

	# Modules have already been loaded at compile time for the standalone renderer.
	if (!exists $ENV{MOJO_MODE}) {
		for (@{ $pg_envir->{modules} }) {
			my ($module, @extra_packages) = @$_;

			# The first item is the main package
			$translator->evaluate_modules($module);

			# The remaining items are extra packages
			$translator->load_extra_packages(@extra_packages);
		}
	}

	# Prepare an imagegenerator object if "images" mode was selected.
	my $image_generator = ($options{displayMode} // '') eq 'images'
		? WeBWorK::PG::ImageGenerator->new(
			tempDir         => $pg_envir->{directories}{tmp},
			latex           => $pg_envir->{externalPrograms}{latex},
			dvipng          => $pg_envir->{externalPrograms}{dvipng},
			useCache        => 1,
			cacheDir        => $pg_envir->{directories}{equationCache},
			cacheURL        => ($options{use_site_prefix} // '') . $pg_envir->{URLs}{equationCache},
			cacheDB         => $pg_envir->{equationCacheDB},
			useMarkers      => 1,
			dvipng_align    => $pg_envir->{displayModeOptions}{images}{dvipng_align},
			dvipng_depth_db => $pg_envir->{displayModeOptions}{images}{dvipng_depth_db},
		)
		: undef;

	$translator->environment(defineProblemEnvironment($pg_envir, \%options, $image_generator));

	$translator->initialize;

	# PG.pl has already been loaded at compile time for the standalone renderer.
	if (!exists $ENV{MOJO_MODE}) {
		my $err = $translator->unrestricted_load($pg_envir->{directories}{root} . '/macros/PG.pl');
		warn "Error while loading macros/PG.pl: $err" if $err;
	}

	# Set the opcode mask to use default values
	$translator->set_mask;

	if (ref $options{r_source}) {
		# The source for the problem was given as a reference to a string.
		$translator->source_string(${ $options{r_source} });
	} elsif ($options{sourceFilePath}) {
		# A file path was given, so read the source from the file.
		my $sourceFilePath =
			$options{sourceFilePath} =~ /^\//
			? $options{sourceFilePath}
			: "$options{templateDirectory}$options{sourceFilePath}";

		eval { $translator->source_file($sourceFilePath) };

		if ($@) {
			# The problem source file could not be read.
			return bless {
				translator       => $translator,
				head_text        => '',
				post_header_text => '',
				body_text        => "Unabled to read problem source file:\n$@\n",
				answers          => {},
				result           => {},
				state            => {},
				errors           => 'Failed to read the problem source file.',
				warnings         => $warning_messages,
				flags            => { error_flag => 1 },
				pgcore           => $translator->{rh_pgcore},
			}, $class;
		}
	}

	$translator->rf_safety_filter(sub { return shift, 0; });

	$translator->translate();

	# IMPORTANT: The translator environment should not be trusted after the problem code runs.

	my ($result, $state);
	if ($options{processAnswers}) {
		$translator->process_answers($options{inputs_ref});

		$translator->rh_problem_state({
			recorded_score       => $options{recorded_score}       // 0,
			num_of_correct_ans   => $options{num_of_correct_ans}   // 0,
			num_of_incorrect_ans => $options{num_of_incorrect_ans} // 0
		});

		my @answerOrder =
			$translator->rh_flags->{ANSWER_ENTRY_ORDER}
			? @{ $translator->rh_flags->{ANSWER_ENTRY_ORDER} }
			: keys %{ $translator->rh_evaluated_answers };

		# Install a grader.  Use the one specified in the problem, or fall back to the average problem grader.
		my $grader = $translator->rh_flags->{PROBLEM_GRADER_TO_USE} || 'avg_problem_grader';
		$grader = $translator->rf_std_problem_grader if $grader eq 'std_problem_grader';
		$grader = $translator->rf_avg_problem_grader if $grader eq 'avg_problem_grader';
		die "Problem grader $grader is not a CODE reference." unless ref $grader eq 'CODE';
		$translator->rf_problem_grader($grader);

		($result, $state) = $translator->grade_problem(
			answers_submitted  => 1,
			ANSWER_ENTRY_ORDER => \@answerOrder,
			%{ $options{inputs_ref} }
		);
	}

	# HTML_dpng uses an ImageGenerator. We have to render the queued equations.
	if ($image_generator) {
		my $sourceFile = "$options{templateDirectory}$options{sourceFilePath}";
		$image_generator->render(
			refresh   => $options{refreshMath2img} // 0,
			body_text => $translator->r_text,
		);
	}

	return bless {
		translator       => $translator,
		head_text        => ${ $translator->r_header },
		post_header_text => ${ $translator->r_post_header },
		body_text        => ${ $translator->r_text },
		answers          => $translator->rh_evaluated_answers,
		result           => $result,
		state            => $state,
		errors           => $translator->errors,
		warnings         => $warning_messages,
		flags            => $translator->rh_flags,
		pgcore           => $translator->{rh_pgcore}
	}, $class;
}

sub free ($pg) {
	# If certain MathObjects (e.g. LimitedPolynomials) are left in the PG structure, then freeing them later can cause
	# "Can't locate package ..." errors in the log during perl garbage collection.  So free them here.
	$pg->{pgcore}{OUTPUT_ARRAY} = [];
	$pg->{answers} = {};
	undef $pg->{translator};
	undef $pg->{pgcore}{PG_ANSWERS_HASH}{$_} for (keys %{ $pg->{pgcore}{PG_ANSWERS_HASH} });
	return;
}

sub defineProblemEnvironment ($pg_envir, $options = {}, $image_generator = undef) {
	my $now = time;

	# Take the values for the following from the pg environment, and override with any that are defined in the
	# corresponding key in the options.

	my $ansEvalDefaults = $pg_envir->{ansEvalDefaults};
	$ansEvalDefaults->{$_} = $options->{ansEvalDefaults}{$_} for keys %{ $options->{ansEvalDefaults} };

	my $specialPGEnvironmentVars = $pg_envir->{specialPGEnvironmentVars};
	$specialPGEnvironmentVars->{$_} = $options->{specialPGEnvironmentVars}{$_}
		for keys %{ $options->{specialPGEnvironmentVars} };

	return {
		# This copies everything from the provided options that are not explicitly dealt with below.
		# With this the caller can add any desired key value pairs to the translator environment.
		# webwork2 uses this to add formatted dates and other things used for set headers.
		%$options,

		# All of the following values are taken from the provided options if defined.  Fall back to the pg environment
		# value, or just hard coded defaults.

		# Problem information
		probFileName       => $options->{sourceFilePath}                                // '',
		displayMode        => DISPLAY_MODES()->{ $options->{displayMode} || 'MathJax' } // 'HTML_MathJax',
		problemSeed        => $options->{problemSeed} || 1234,
		psvn               => $options->{psvn}               // 1,
		problemUUID        => $options->{problemUUID}        // 0,
		probNum            => $options->{probNum}            // 1,
		showHints          => $options->{showHints}          // 1,
		showSolutions      => $options->{showSolutions}      // 0,
		forceScaffoldsOpen => $options->{forceScaffoldsOpen} // 0,
		setOpen            => $options->{setOpen}            // 1,
		pastDue            => $options->{pastDue}            // 0,
		answersAvailable   => $options->{answersAvailable}   // 0,
		isInstructor       => $options->{isInstructor}       // 0,

		inputs_ref => $options->{inputs_ref},

		(map { $_ => $ansEvalDefaults->{$_} } keys %$ansEvalDefaults),

		QUIZ_PREFIX           => $options->{answerPrefix} // '',
		PROBLEM_GRADER_TO_USE => $options->{grader}       // $pg_envir->{options}{grader},

		useMathQuill   => $options->{useMathQuill}   // $pg_envir->{options}{useMathQuill},
		useMathView    => $options->{useMathView}    // $pg_envir->{options}{useMathView},
		mathViewLocale => $options->{mathViewLocale} // $pg_envir->{options}{mathViewLocale},
		useWirisEditor => $options->{useWirisEditor} // $pg_envir->{options}{useWirisEditor},

		# Internationalization
		language            => $options->{language}            // 'en',
		language_subroutine => $options->{language_subroutine} // sub (@args) { return $args[0]; },

		# Directories and URLs
		pgMacrosDir       => "$pg_envir->{directories}{root}/macros",
		macrosPath        => $options->{macrosPath}        // $pg_envir->{directories}{macrosPath},
		htmlPath          => $options->{htmlPath}          // $pg_envir->{URLs}{htmlPath},
		imagesPath        => $options->{imagesPath}        // $pg_envir->{URLs}{imagesPath},
		htmlDirectory     => $options->{htmlDirectory}     // "$pg_envir->{directories}{html}/",
		htmlURL           => $options->{htmlURL}           // "$pg_envir->{URLs}{html}/",
		templateDirectory => $options->{templateDirectory} // '',
		tempDirectory     => $options->{tempDirectory}     // "$pg_envir->{directories}{html_temp}/",
		tempURL           => $options->{tempURL}           // "$pg_envir->{URLs}{tempURL}/",
		localHelpURL      => $options->{localHelpURL}      // "$pg_envir->{URLs}{localHelpURL}/",
		server_root_url   => $options->{server_root_url} || '',

		# Other things ...

		imagegen => $image_generator
		? WeBWorK::PG::RestrictedClosureClass->new($image_generator, 'add', 'addToTeXPreamble', 'refresh')
		: undef,

		use_site_prefix   => $options->{use_site_prefix}   // '',
		use_opaque_prefix => $options->{use_opaque_prefix} // 0,

		__files__ => $options->{__files__} // {
			root => $pg_envir->{directories}{root},
			pg   => $pg_envir->{directories}{root},
			tmpl => $pg_envir->{directories}{root}
		},

		(map { $_ => $specialPGEnvironmentVars->{$_} } keys %$specialPGEnvironmentVars),

		(map { $_ => $options->{debuggingOptions}{$_} } keys %{ $options->{debuggingOptions} // {} }),

		# FIXME:  These are used by PG, but should not be.
		courseName   => $options->{courseName}   // 'pg_local',
		setNumber    => $options->{setNumber}    // 1,
		studentLogin => $options->{studentLogin} // 'pg_local',
		studentName  => $options->{studentName}  // 'pg_local',
		studentID    => $options->{studentID}    // 'pg_local',
	};
}

1;

__END__

=head1 SYNOPSIS

    $pg = WeBWorK::PG->new(
        displayMode        => 'MathJax',            # (images|MathJax)
        showHints          => 1,
        showSolutions      => 0,
        processAnswers     => 1,
        isInstructor       => 1,
        useMathQuill       => 1,
        templateDirectory  => '/opt/webwork/pg/',
        problemSeed        => 1234,
        inputs_ref         => $formFields,
        sourceFilePath     =>
            '/opt/webwork/libraries/webwork-open-problem-library/OpenProblemLibrary/Michigan/Chap8Sec4/Q21.pg'

    );

    $translator       = $pg->{translator};          # WeBWorK::PG::Translator
    $body             = $pg->{body_text};           # text string
    $header           = $pg->{head_text};           # text string
    $post_header_text = $pg->{post_header_text};    # text string
    $answerHash       = $pg->{answers};             # WeBWorK::PG::AnswerHash
    $result           = $pg->{result};              # hash reference
    $state            = $pg->{state};               # hash reference
    $errors           = $pg->{errors};              # text string
    $warnings         = $pg->{warnings};            # text string
    $flags            = $pg->{flags};               # hash reference
    $pgcore           = $pg->{pgcore}               # PGcore

=head1 DESCRIPTION

WeBWorK::PG is a module that provides a convenient API for rendering a PG problem.

=head1 OPTIONS

The constructor can be passed the following options.  One of the r_source or
sourceFilePath options described below must be provided.  In addition, any of
the translator environment variables may be passed as options in this argument.
Furthermore, any keys in the passed hash not documented below will be copied
into the translator environment.

=over

=item r_source (reference to string)

The source of the pg problem to render provided as a reference to a string.  If
this is given it will be used for the problem source instead of the
sourceFilePath

=item sourceFilePath (string)

Location of the pg problem file to render.  It must either be provided with an
absoute path, or a path relative to the given templateDirectory.

=item templateDirectory (string, default: '')

Either a readable location containing the problem file and all static assets for
the problem, or the empty string.  WARNING:  If this is the empty string then
any static assets for the problem may not be found.

=item problemSeed (number, default: 1234)

Seed to use for the problem.

=item displayMode (string, default: 'MathJax')

The PG display mode to use, e.g., 'tex', 'plainText', 'images', 'MathJax', or
'PTX'.

=item showHints (boolean, default: 1)

This determines if hints that may be encoded in the problem will be rendered.

=item showSolutions (boolean, default: 0)

This determines if solutionas that may be encoded in the problem will be
rendered.

=item forceScaffoldsOpen (boolean, default: 0)

If set to 1, then all scaffolds will be allowed to be opened.

=item setOpen (boolean, default: 1)

Determines if the set containing the problem is open for the user to work.
(This is only used by problemPanic.pl)

=item pastDue (boolean, default: 0)

Determines if the problem is past due.
(This is only used by answerDiscussion.pl, problemPanic.pl, and problemRandomize.pl)

=item answersAvailable (boolean, default: 0)

Determines if the problem answers are available.
(This is only used by scaffold.pl)

=item problemUUID (scalar, default: 0)

This is used to generate unique identifiers for resources.  The caller should
ensure that this is sufficiently unique for the purposes of the system.
Generally that means it should be unique for each course, user, set, and problem
number.

=item psvn (number, default: 1)

Problem set version number.  This is also incorporated into the unique
identifiers used for resources.

=item probNum (number, default: 1, deprecated)

Problem number.  This will eventually be removed from pg.

=item refreshMath2img (boolean, default: 0)

If 1, force images created by math2img (in "images" mode) to be recreated.

=item processAnswers (boolean, default: 0)

If 1, call answer evaluators and graders.

=item isInstructor (boolean, default: 0)

Determines if the user is an instructor (certain restrictions are removed for
these users).

=item inputs_ref (hash, default: {})

Hash containing all input values in the form containing the problem.
Most importantly this contains answers.

=item ansEvalDefaults (hash, default: taken from WeBWorK::PG::Environment)

This may contain the following keys (example values are shown)

    functAbsTolDefault: 0.001
    functLLimitDefault: 0.0000001
    functMaxConstantOfIntegration: 1E8
    functNumOfPoints: 3
    functRelPercentTolDefault: 0.1
    functULimitDefault: 0.9999999
    functVarDefault: x
    functZeroLevelDefault: 1E-14
    functZeroLevelTolDefault: 1E-12
    numAbsTolDefault: 0.001
    numFormatDefault: ''
    numRelPercentTolDefault: 0.1
    numZeroLevelDefault: 1E-14
    numZeroLevelTolDefault: 1E-12
    useBaseTenLog: 0
    defaultDisplayMatrixStyle: '[s]' # left delimiter, middle line delimiters, right delimiter

=item answerPrefix (string, default: '')

A prefix to prepend to all answer labels.  Note that other prefixes may be
prepended in front of this one, so it is not safe to assume that it is at the
beginning of all answer labels.  For example, the parserMultiAnswer.pl macro
does this.  Also note that in the actual PGcore environment this is QUIZ_PREFIX.

=item grader (string or CODE, default taken from WeBWorK::PG::Environment)

The default grader to use.  This can be overridden by the problem.

=item useMathQuill, useMathView, useWirisEditor
    (boolean, defaults taken from WeBWorK::PG::Environment)

Determines which entry assist method to use.  If useMathQuill is 1, then
MathQuill will be used.  Otherwise, if useMathView is 1, then MathView will be
used.  Otherwise, if useWirisEditor is 1, then Wiris will be used.  If all are
0, then basic html inputs will be used.

=item language (string, default: 'en')

The language for the problem.

=item language_subroutine (CODE, default: sub (@args) { return $args[0]; })

Language subroutine that will be used for translations (the maketext method).

=item macrosPath (array, default taken from WeBWorK::PG::Environment)

An array of paths to search for macros that may be loaded by the problem.

=item htmlPath (array, default taken from WeBWorK::PG::Environment)

Paths to search for auxiliary html files.  Note that this array may contain the
special value of '.' which means the directory the problem file is contained in.

=item imagesPath (array, default taken from WeBWorK::PG::Environment)

Paths to search for auxiliarly image files.  Note that this array may contain the
special value of '.' which means the directory the problem file is contained in.

=item htmlDirectory (string, default taken from WeBWorK::PG::Environment)

Html directory that may contain additional static resources that may be used in
problems.  Usually the course's html directory.

=item htmlURL (string, default taken from WeBWorK::PG::Environment)

Public html address of the htmlDirectory above.

=item tempDirectory (string, default taken from WeBWorK::PG::Environment)

Location to place generated resources.  This directory must be writable.

=item tempURL (string, default taken from WeBWorK::PG::Environment)

Public html address of the tempDirectory above.

=item localHelpURL (string, default taken from WeBWorK::PG::Environment)

Public html address for the PG help files.

=item server_root_url (string, default: '')

Server root url.  This is used by check_url when verifying that static resources
are available.  It is prepended to relative urls in this check.

=item use_site_prefix (string, default: '')

Site prefix prepended to image and video url's inserted into problems by the
PGbasicmacros.pl methods "image" and "video".

=item use_opaque_prefix (boolean, default: 0)

If set to 1, then "%%IDPREFIX%%" will be prepended to answer labels.

=item __files__ (hash default: default taken from WeBWorK::PG::Environment)

A hash that should contain key value pairs for the keys 'root', 'pg', and
'tmpl'.  These are used to shorten filenames in error messages.

=item specialPGEnvironmentVars (hash, default taken from WeBWorK::PG::Environment)

A hash that can contain any of the keys described int conf/pg_config.dist.yml.

=item debuggingOptions (hash, default: {})

A hash that may contain key value pairs for the keys show_resource_info,
view_problem_debugging_info, show_pg_info, show_answer_hash_info,
show_answer_group_info.  The keys enable the things describe in the key name.

=item courseName (string, default: 'pg_local', deprecated)

=item setNumber (number, default: 1, deprecated)

=item studentLogin (string, default: 'pg_local', deprecated)

=item studentName (string, default: 'pg_local', deprecated)

=item studentID (string, default: 'pg_local', deprecated)

These options are still used in some places in PG (mostly by macros that will
eventually be deprecated and removed), but eventually that will all be fixed and
these will no longer be needed.  Note that webwork2 still needs to pass the
courseName so the relevant course values (course html directories and urls) can
be optained from the WeBWorK::CourseEnvironment.

=back

=head1 RETURN VALUE

The C<new> method returns a blessed hash reference containing the following
fields. More information can be found in the documentation for
WeBWorK::PG::Translator.

=over

=item translator

The WeBWorK::PG::Translator object used to render the problem.

=item head_text

HTML code to be injected into the E<lt>headE<gt> tag of the web page containing
the problem.

=item post_header_text

HTML code to be injected into the E<lt>bodyE<gt> tag before the form containing
the problem.

=item body_text

HTML code to be inserted into the E<lt>bodyE<gt> tag of the web page to show the
problem.

=item answers

An C<AnswerHash> object containing submitted answers, and results of answer
evaluation.

=item result

A hash containing the results of grading the problem.

=item state

A hash containing the problem state.

=item errors

A string containing any errors encountered while rendering the problem.

=item warnings

A string containing any warnings encountered while rendering the problem.

=item flags

A hash containing PG_flags (see the Translator docs).

=item pgcore

The PGcore object for the problem.

=back

=cut
