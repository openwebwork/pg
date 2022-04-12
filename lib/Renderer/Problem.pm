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

use feature 'say';

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

	# set defaults for the translationOptions
	my $translationOptions = {
		displayMode     => $self->{translationOptions}->{displayMode}    // $self->{pg_env}->{renderer}->{displayMode},
		problem_seed    => $self->{translationOptions}->{problem_seed}   // 1,
		showHints       => $self->{translationOptions}->{showHints}      // 0,
		showSolutions   => $self->{translationOptions}->{showSolutions}  // 0,
		refreshMath2img => $self->{refreshMath2img}->{showSolutions}     // 1,
		processAnswers  => $self->{translationOptions}->{processAnswers} // 0,
		QUIZ_PREFIX     => $self->{translationOptions}->{QUIZ_PREFIX}    // '',
		use_opaque_prefix => $self->{translationOptions}->{use_opaque_prefix} // 0
	};

	$self->{translationOptions} = $translationOptions;

	# The rest of this is from WeBWorK::PG::Local

	# install a local warn handler to collect warnings  FIXME -- figure out what I meant to do here.
	my $warnings = "";

	local $SIG{__WARN__} = sub { $warnings .= shift() . "<br/>\n" }
		if $self->{pg_env}->{renderer}->{catchWarnings};

	# create a Translator
	warn "PG: creating a Translator\n";
	$self->{translator} = Renderer::Translator->new;

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
	if ($translationOptions->{displayMode} eq "images"
		|| $translationOptions->{displayMode} eq "opaque_image")
	{
		my %imagesModeOptions = %{ $self->{pg_env}->{renderer}->{displayModeOptions}->{images} };
		$image_generator = WeBWorK::PG::ImageGenerator->new(
			tempDir         => $self->{pg_env}->{directories}->{renderer_dirs}->{temp_dir},
			latex           => $self->{pg_evn}->{environment}->{externalPrograms}->{latex},
			dvipng          => $self->{pg_evn}->{environment}->{externalPrograms}->{dvipng},
			useCache        => 1,
			cacheDir        => $self->{pg_env}->{directories}->{renderer_dirs}->{equation_cache},
			cacheURL        => $self->{pg_env}->{URLs}->{equation_cache},
			cacheDB         => $self->{pg_env}->{environment}->{equation_cache_db},
			useMarkers      => ($imagesModeOptions{dvipng_align} && $imagesModeOptions{dvipng_align} eq 'mysql'),
			dvipng_align    => $imagesModeOptions{dvipng_align},
			dvipng_depth_db => $imagesModeOptions{dvipng_depth_db},
		);
	}

############################################################################
	# set the environment (from defineProblemEnvir)
	############################################################################

	print Dumper 'transOpts';
	print Dumper $translationOptions;

	warn "Problem: setting the environment (from defineProblemEnvir)\n";
	my $envir = defineProblemEnvir(
		$self->{pg_env},
		$psvn,    #FIXME -- not used
		$formFields,
		$translationOptions,
		{         #extras (this is kind of a hack, but not a serious one)
			image_generator => $image_generator,
			mailer          => $mailer,
			problemUUID     => 0,
		}
	);
	$self->{translator}->environment($envir);

	$self->{translator}->initialize;

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

	bless $self, $class;
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
	say "in Problem::render";
	my ($self, $psvn, $formFields) = @_;

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

=head2 defineProblemEnvir

This creates the problem environment, which are a set of variables that can
be used within a problem

=cut

use Data::Dump;

sub defineProblemEnvir {
	my (
		$pg_env,
		$psvn,    # Is it time to get rid of this?
		$formFields,
		$translationOptions,
		$extras,
	) = @_;

	print Dumper 'in Renderer::Problem::defineProblemEnvir';

	my %envir;

	# This is an old problem set version number, but is used for other things currently.
	$envir{psvn} = $psvn;

	# update problemUUID from submitted form, and fall back to the earlier name problemIdentifierPrefix if necessary
	$envir{problemUUID} = $formFields->{problemUUID} // $formFields->{problemIdentifierPrefix} // $envir{problemUUID}
		// 0;
	$envir{psvnNumber} = "psvnNumber-is-deprecated-Please-use-psvn-Instead";    #FIXME

	$envir{questionNumber}    = $envir{probNum};
	$envir{probFileName}      = $envir{fileName};
	$envir{problemSeed}       = $translationOptions->{problem_seed};
	$envir{displayMode}       = $pg_env->{renderer}->{display_modes}->{ $translationOptions->{displayMode} };
	$envir{outputMode}        = $envir{displayMode};
	$envir{displayHintsQ}     = $translationOptions->{showHints};
	$envir{displaySolutionsQ} = $translationOptions->{showSolutions};
	$envir{texDisposition}    = "pdf";                                          # in webwork2, we use pdflatex

	# Note: information related to dates removed.  Problems should be renderered
	# independent of any date. Also, all student information including course is
	# removed for security reasons.

	$envir{language} = $pg_env->{environment}->{language};
	# $envir{language_handle} = $pg_env->get_language_handle;
	print Dumper 'defining maketext';
	$envir{language_subroutine} = Renderer::Localize::getLoc($envir{language});
	# $envir{language_subroutine} = $pg_env->{environment}->{maketext};
	# $envir{language_subroutine} = $pg_env->maketext();
	# $envir{language_subroutine} = sub {
	# 	warn 'in Problem.pm';
	# 	# dd $pg_env;
	# 	dd $pg_env->{environment};
	# 	my $lh = $pg_env->{environment}->{language_handle};
	# 	dd $lh;
	# 	return $lh->maketext(@_);
	# };

	# Are these needed?  Or should permission level be handled at a level above?
	$envir{permissionLevel} = $translationOptions->{permissionLevel};    # permission level of actual user
	$envir{effectivePermissionLevel} =
		$translationOptions->{effectivePermissionLevel};    # permission level of user assigned to this question

	$envir{inputs_ref} = $formFields;

	# External Programs
	# ADDED: externalLaTeXPath, externalDvipngPath,
	#        externalGif2EpsPath, externalPng2EpsPath

	# Question: why are these needed for within a problem?

	$envir{externalLaTeXPath}   = $pg_env->{environment}->{externalPrograms}->{latex};
	$envir{externalDvipngPath}  = $pg_env->{environment}->{externalPrograms}->{dvipng};
	$envir{externalGif2EpsPath} = $pg_env->{environment}->{externalPrograms}->{gif2eps};
	$envir{externalPng2EpsPath} = $pg_env->{environment}->{externalPrograms}->{png2eps};
	$envir{externalGif2PngPath} = $pg_env->{environment}->{externalPrograms}->{gif2png};
	$envir{externalCheckUrl}    = $pg_env->{environment}->{externalPrograms}->{checkurl};
	#$envir{externalCurlCommand}  = $pg_env->{environment}->{externalPrograms}->{curl};

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

	# Mail information is not needed here.

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
