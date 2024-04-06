################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2023 The WeBWorK Project, https://github.com/openwebwork
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

package WeBWorK::PG::Translator;

=head1 NAME

WeBWorK::PG::Translator - Evaluate PG code and evaluate answers safely

=head1 SYNPOSIS

    my $pt = WeBWorK::PG::Translator->new;   # create a translator
    $pt->environment(\%envir);               # provide the environment variable for the problem
    $pt->initialize;                         # initialize the translator
    $pt->set_mask;                           # set the operation mask for the translator safe compartment

    $pt->source_string($source);             # provide the source string for the problem
                                             # or
    $pt->source_file($sourceFilePath);       # provide the proble file containing the source

    # Load the unprotected macro files.
    # These files are evaluated with the Safe compartment wide open.
    # Other macros are loaded from within the problem using loadMacros.
    # This should not be done if the safe cache is used which is only the case if $ENV{MOJO_MODE} exists.
    $pt->unrestricted_load("${pgMacrosDirectory}PG.pl");

    $pt->translate;    # translate the problem (the following pieces of information are created)

    $PG_PROBLEM_TEXT_REF = $pt->r_text;               # reference to output text for the body of problem
    $PG_HEADER_TEXT_REF = $pt->r_header;              # reference to text for the header in HTML output
    $PG_POST_HEADER_TEXT_REF = $pt->r_post_header;
    $PG_ANSWER_HASH_REF = $pt->rh_correct_answers;    # a hash of answer evaluators
    $PG_FLAGS_REF = $pt->rh_flags;                    # misc. status flags.

    $pt->process_answers;                                 # evaluates all of the answers
    my $rh_answer_results = $pt->rh_evaluated_answers;    # provides a hash of the results of evaluating the answers.
    my $rh_problem_result = $pt->grade_problem(%options); # grades the problem.

    $pt->post_process_content;   # Execute macro or problem hooks that further modify the problem content.
    $pt->stringify_answers;      # Convert objects to strings in the answer hash

=head1 DESCRIPTION

This module defines an object which will translate a problem written in the Problem Generating (PG) language

=cut

use strict;
use warnings;

use utf8;
use v5.12;
binmode(STDOUT, ":encoding(UTF-8)");

use Opcode;
use Carp;
use Mojo::DOM;

use WWSafe;
use PGUtil qw(pretty_print);
use WeBWorK::PG::IO qw(fileFromPath);

=head1 NAME

WeBWorK::PG::Translator - Evaluate PG code and evaluate answers safely

=head1 SYNPOSIS

    my $pt = new WeBWorK::PG::Translator;    # create a translator
    $pt->environment(\%envir);               # provide the environment variable for the problem
    $pt->initialize();                       # initialize the translator
    $pt-> set_mask();                        # set the operation mask for the translator safe compartment
    $pt->source_string($source);             # provide the source string for the problem

    # Load the unprotected macro files.
    # These files are evaluated with the Safe compartment wide open.
    # Other macros are loaded from within the problem using loadMacros.
    $pt->unrestricted_load("${courseScriptsDirectory}PG.pl");

    $pt->translate();    # translate the problem (the following pieces of information are created)

    $PG_PROBLEM_TEXT_ARRAY_REF = $pt->ra_text();      # output text for the body of the HTML file (in array form)
    $PG_PROBLEM_TEXT_REF = $pt->r_text();             # output text for the body of the HTML file
    $PG_HEADER_TEXT_REF = $pt->r_header;              # text for the header of the HTML file
    $PG_POST_HEADER_TEXT_REF = $pt->r_post_header
    $PG_ANSWER_HASH_REF = $pt->rh_correct_answers;    # a hash of answer evaluators
    $PG_FLAGS_REF = $pt->rh_flags;                    # misc. status flags.

    $pt->process_answers;    # evaluates all of the answers

    my $rh_answer_results = $pt->rh_evaluated_answers;  # provides a hash of the results of evaluating the answers.
    my $rh_problem_result = $pt->grade_problem;         # grades the problem using the default problem grading method.

=head1 DESCRIPTION

This module defines an object which will translate a problem written in the Problem Generating (PG) language

=cut

BEGIN {
	# Setup the safe compartment for the standalone renderer.
	if (exists $ENV{MOJO_MODE}) {
		my $pg_envir = WeBWorK::PG::Environment->new;

		# Each instance of the translator is run in a new process in the standalone renderer.  So the safe compartment
		# can be cached and reused for each instance without the possibility of memory leaks from one instance to the
		# next.
		my $safeCache = WWSafe->new;

		# Load the modules into the safe cache. This saves approximately 200ms per render.
		my @modules             = @{ $pg_envir->{modules} };
		my $ra_included_modules = [];

		for my $module_packages_ref (@modules) {
			my ($module, @extra_packages) = @$module_packages_ref;

			# The first item is the main package.
			$module =~ s/\.pm$//;
			eval "package main; require $module; import $module;";
			warn "Failed to evaluate module $module: $@" if $@;
			push @$ra_included_modules, "\%${module}::";

			# The remaining items are "extra" packages.
			for (@extra_packages) {
				s/\.pm$//;
				import $_;
				warn "Failed to evaluate module $_: $@" if $@;
				push @$ra_included_modules, "\%${_}::";
			}
		}

		$safeCache->share_from('main', $ra_included_modules);

		my $store_mask = $safeCache->mask();
		$safeCache->mask(Opcode::empty_opset());
		my $safe_cmpt_package_name = $safeCache->root();

		# The only unrestricted load is PG.pl.  Load that into the cache as well.
		my $filePath             = $pg_envir->{directories}{root} . '/macros/PG.pl';
		my $init_subroutine_name = "${safe_cmpt_package_name}::_PG_init";

		my $errors = '';
		if (-r $filePath) {
			my $rdoResult = $safeCache->rdo($filePath);
			$errors .= "\nThere were problems compiling the file:\n $filePath\n $@\n" if $@;
		} else {
			$errors .= "Can't open file $filePath for reading\n";
		}
		$safeCache->mask($store_mask);

		my $init_subroutine   = eval { \&{$init_subroutine_name} };
		my $macro_file_loaded = ref($init_subroutine) =~ /CODE/;
		if ($macro_file_loaded) {
			&$init_subroutine();
		}
		$errors .= "\nUnknown error.  Unable to load $filePath\n" if ($errors eq '' and not $macro_file_loaded);
		die "Translator.pm [BEGIN errors]: $errors\n"             if $errors;

		# Stash the safe cache in a package variable.
		$WeBWorK::Translator::safeCache = $safeCache;
	}
}

=head2 evaluate_modules

Adds modules to the list of modules which can be used by the PG problems.

For example,

    $obj->evaluate_modules('LaTeXImage', 'DragNDrop');

adds modules to the C<LaTeXImage> and C<DragNDrop> modules.

=cut

sub evaluate_modules {
	my ($self, @modules) = @_;

	local $SIG{__DIE__} = 'DEFAULT';

	for (@modules) {
		# Ensure that the name is in fact a base name.
		s/\.pm$//;

		eval "package main; require $_; import $_";
		warn "Failed to evaluate module $_: $@" if $@;

		# Record this in the appropriate place.
		push @{ $self->{ra_included_modules} }, "\%${_}::";
	}

	return;
}

=head2 load_extra_packages

Loads extra packages for modules that contain more than one package.  Works in
conjunction with evaluate_modules.  It is assumed that the file containing the
extra packages (along with the base package name which is the same as the name
of the file minus the .pm extension) has already been loaded using
evaluate_modules.

    Usage:  $obj->load_extra_packages('AlgParserWithImplicitExpand', 'ExprWithImplicitExpand');

=cut

sub load_extra_packages {
	my ($self, @package_list) = @_;

	for (@package_list) {
		# Ensure that the name is in fact a base name.
		s/\.pm$//;

		# Import symbols from the extra package
		import $_;
		warn "Failed to evaluate module $_: $@" if $@;

		# Record this in the appropriate place
		push @{ $self->{ra_included_modules} }, "\%${_}::";
	}

	return;
}

=head2 new

Creates the translator object.

=cut

sub new {
	my $class = shift;

	# Use the cached safe for the standalone renderer.
	my $safe_cmpt = exists($ENV{MOJO_MODE}) ? $WeBWorK::Translator::safeCache : WWSafe->new;

	my $self = {
		preprocess_code         => \&default_preprocess_code,
		postprocess_code        => \&default_postprocess_code,
		envir                   => undef,
		PG_PROBLEM_TEXT_REF     => 0,
		PG_HEADER_TEXT_REF      => 0,
		PG_POST_HEADER_TEXT_REF => 0,
		PG_ANSWER_HASH_REF      => {},
		PG_FLAGS_REF            => {},
		rh_pgcore               => undef,
		safe                    => $safe_cmpt,
		safe_compartment_name   => $safe_cmpt->root,
		errors                  => '',
		source                  => '',
		rh_correct_answers      => {},
		rh_student_answers      => {},
		rh_evaluated_answers    => {},
		rh_problem_result       => {},
		rh_problem_state        => {
			recorded_score       => 0,
			num_of_correct_ans   => 0,
			num_of_incorrect_ans => 0,
		},
		rf_problem_grader   => \&std_problem_grader,
		ra_included_modules => []
	};
	return bless $self, $class;
}

=head2 initialize

The following translator methods are shared to the safe compartment:

	&PG_answer_eval
	&PG_restricted_eval
	&PG_macro_file_eval

Also all methods that are exported by WeBWorK::PG::IO are shared.

In addition the environment hash C<%envir> is shared.  This variable is unpacked
when PG.pl is run.

=cut

# Share variables and routines with the safe compartment.
# Some symbols are defined here and some in the WeBWorK::PG::IO module.

# Functions shared from WeBWorK::PG::Translator
my @Translator_shared_subroutine_array = qw(
	&PG_answer_eval
	&PG_restricted_eval
	&PG_macro_file_eval
);

sub initialize {
	my $self      = shift;
	my $safe_cmpt = $self->{safe};

	$safe_cmpt->share_from('WeBWorK::PG::Translator', \@Translator_shared_subroutine_array);
	$safe_cmpt->share_from('WeBWorK::PG::IO',         \@WeBWorK::PG::IO::EXPORT_OK);

	no strict;
	local (%envir) = %{ $self->{envir} };
	$safe_cmpt->share('%envir');
	local ($PREPROCESS_CODE) = sub { &{ $self->{preprocess_code} }(@_) };
	$safe_cmpt->share('$PREPROCESS_CODE');    # Used by WeBWorK::PG::IO::includePGtext
	use strict;

	# The standalone renderer does this when the module is compiled.
	unless (exists($ENV{MOJO_MODE})) {
		$safe_cmpt->share_from('main', $self->{ra_included_modules});
	}

	return;
}

sub environment {
	my $self     = shift;
	my $envirref = shift;
	if (defined($envirref)) {
		if (ref($envirref) eq 'HASH') {
			%{ $self->{envir} } = %$envirref;
		} else {
			$self->{errors} .= 'ERROR: The environment method for PG_translate objects requires a reference to a hash';
		}
	}
	return $self->{envir};
}

=head2 Safe compartment pass through macros

=cut

sub mask {
	my $self             = shift;
	my $mask             = shift;
	my $safe_compartment = $self->{safe};
	return $safe_compartment->mask($mask);
}

sub permit {
	my $self             = shift;
	my @array            = shift;
	my $safe_compartment = $self->{safe};
	return $safe_compartment->permit(@array);
}

sub deny {
	my $self             = shift;
	my @array            = shift;
	my $safe_compartment = $self->{safe};
	return $safe_compartment->deny(@array);
}

sub share_from {
	my $self             = shift;
	my $pckg_name        = shift;
	my $array_ref        = shift;
	my $safe_compartment = $self->{safe};
	return $safe_compartment->share_from($pckg_name, $array_ref);
}

# End safe compartment pass through macros.

sub source_string {
	my $self = shift;
	my $temp = shift;
	if (ref($temp) eq 'SCALAR') {
		$self->{source} = $$temp;
	} elsif ($temp) {
		$self->{source} = $temp;
	}
	return $self->{source};
}

sub source_file {
	my $self     = shift;
	my $filePath = shift;
	local $/ = undef;
	if (open(my $SOURCEFILE, "<:encoding(UTF-8)", $filePath)) {
		$self->{source} = <$SOURCEFILE>;
		close($SOURCEFILE);
	} else {
		$self->{errors} .= "Can't open file: $filePath";
		croak("Can't open file: $filePath\n");
	}
	return;
}

sub unrestricted_load {
	my $self     = shift;
	my $filePath = shift;

	my $safe_cmpt  = $self->{safe};
	my $store_mask = $safe_cmpt->mask();
	$safe_cmpt->mask(Opcode::empty_opset());
	my $safe_cmpt_package_name = $safe_cmpt->root();

	my $macro_file_name = fileFromPath($filePath) =~ s/\.pl//r;    # Trim off the extension

	my $init_subroutine_name = "${safe_cmpt_package_name}::_${macro_file_name}_init";

	my $local_errors = '';

	my $init_subroutine = eval { \&{$init_subroutine_name} };

	my $macro_file_loaded = ref($init_subroutine) =~ /CODE/ && defined(&$init_subroutine);

	unless ($macro_file_loaded) {
		# Load the $filePath file
		# Using rdo insures that the $filePath file is loaded for every problem, allowing initializations to occur.
		# Ordinary mortals should not be fooling with the fundamental macros in these files.
		if (-r $filePath) {
			my $rdoResult = $safe_cmpt->rdo($filePath);
			$local_errors = "\nThere were problems compiling the file:\n $filePath\n $@\n" if $@;
			$self->{errors} .= $local_errors if $local_errors;
		} else {
			$local_errors = "Can't open file $filePath for reading\n";
			$self->{errors} .= $local_errors if $local_errors;
		}
	}

	$safe_cmpt->mask($store_mask);

	unless ($macro_file_loaded) {
		# Try again to define the initialization subroutine.
		$init_subroutine   = eval { \&{"$init_subroutine_name"} };
		$macro_file_loaded = ref($init_subroutine) =~ /CODE/;
		if ($macro_file_loaded) {
			&$init_subroutine();
		}
	}

	$local_errors .= "\nUnknown error.  Unable to load $filePath\n" if $local_errors eq '' && !$macro_file_loaded;
	return $local_errors;
}

sub nameSpace {
	my $self = shift;
	return $self->{safe}->root;
}

sub header {
	my $self = shift;
	return ${ $self->{PG_HEADER_TEXT_REF} };
}

sub post_header {
	my $self = shift;
	return ${ $self->{PG_POST_HEADER_TEXT_REF} };
}

sub h_flags {
	my $self = shift;
	return %{ $self->{PG_FLAGS_REF} };
}

sub rh_flags {
	my $self = shift;
	return $self->{PG_FLAGS_REF};
}

sub h_answers {
	my $self = shift;
	return %{ $self->{PG_ANSWER_HASH_REF} };
}

sub r_text {
	my $self = shift;
	return $self->{PG_PROBLEM_TEXT_REF};
}

sub r_header {
	my $self = shift;
	return $self->{PG_HEADER_TEXT_REF};
}

sub r_post_header {
	my $self = shift;
	return $self->{PG_POST_HEADER_TEXT_REF};
}

sub rh_correct_answers {
	my ($self, @in) = @_;
	return $self->{rh_correct_answers} if @in == 0;

	if (ref($in[0]) eq 'HASH') {
		$self->{rh_correct_answers} = { %{ $in[0] } };
	} else {
		$self->{rh_correct_answers} = {@in};
	}
	return $self->{rh_correct_answers};
}

sub rf_problem_grader {
	my $self = shift;
	my $in   = shift;
	return $self->{rf_problem_grader} unless defined($in);
	if (ref($in) =~ /CODE/) {
		$self->{rf_problem_grader} = $in;
	} else {
		die "ERROR: Attempted to install a problem grader which was not a reference to a subroutine.";
	}
	return $self->{rf_problem_grader};
}

sub errors {
	my $self = shift;
	return $self->{errors};
}

=head2 set_mask

Limit allowed operations in the safe compartment.  Only the certain operations
can be used within PG problems and the PG macro files.  These include the
subroutines shared with the safe compartment as defined above and most Perl
commands which do not involve file access, access to the system or evaluation.

Specifically the following are allowed:

    time
        - Gives the current Unix time.
    atan, sin, cos, exp, log, sqrt
        - Arithemetic commands.  More are defined in PGauxiliaryFunctions.pl

The following are specifically not allowed:

	eval, unlink, symlink, system, exec, print, require

=cut

# Restrict the operations allowed within the safe compartment
sub set_mask {
	my $self      = shift;
	my $safe_cmpt = $self->{safe};
	$safe_cmpt->mask(Opcode::full_opset());    # Allow no operations
	$safe_cmpt->permit(qw(:default));
	$safe_cmpt->permit(qw(time));
	$safe_cmpt->permit(qw(atan2 sin cos exp log sqrt));

	# Just to make sure, deny some things specifically.
	$safe_cmpt->deny(qw(entereval));
	$safe_cmpt->deny(qw(unlink symlink system exec));
	$safe_cmpt->deny(qw(print require));
	return;
}

############################################################################

=head2 PG_errorMessage

This routine processes error messages by fixing file names and adding
traceback information.  It loops through the function calls via
caller() in order to give more information about where the error
occurred.  Since the loadMacros() files and the .pg file itself are
handled via various kinds of eval calls, the caller() information does
not contain the file names.  So we have saved them in the
$main::__files__ hash, which we look up here and use to replace the
(eval nnn) file names that are in the caller stack.  We shorten the
filenames by removing the templates or root directories when possible,
so they are easier to read.

We skip any nested calls to Parser:: or Value:: so that these act more like
perl built-in functions.

We stop when we find a routine in the WeBWorK:: package, or an __ANON__
routine, in order to avoid reporting the PG translator calls that
surround the pg file.  Finally, there is usually one more eval before
that, so we remove it as well.

File names are shortened, when possible, by replacing the templates
directory with [TMPL], the WeBWorK root directory by [WW] and
the PG root directory by [PG].

=cut

sub PG_errorMessage {
	my ($return, @messages) = @_;    # $return can be 'message' or 'traceback'

	my $message = join("\n", @messages) =~ s/\s+$//r;

	my $files = $main::__files__ // {};
	my $tmpl  = $files->{tmpl} || '$';
	my $root  = $files->{root} || '$';
	my $pg    = $files->{pg}   || '$';

	# Fix initial message file names
	$message =~ s! $tmpl! [TMPL]!g;
	$message =~ s! $root! [WW]!g;
	$message =~ s! $pg! [PG]!g;
	$message =~ s/(\(eval \d+\)) (line (\d+))/$2 of $1/g;
	my @eval_ids = $message =~ m/of (?:file )?(\(eval \d+\))/g;
	for (@eval_ids) {
		my $name = $files->{$_};
		next unless defined $name;
		$name    =~ s!^$tmpl![TMPL]!;
		$name    =~ s!^$root![WW]!;
		$name    =~ s!^$pg![PG]!;
		$message =~ s/\($_\)/$name/g;
	}

	# Return the message if that is what was requested, or if the message already includes a stack trace.
	return $message . "\n" if $return eq 'message' || $message =~ m/\n   Died within/;

	$message =~ s/\.$//;

	# Look through caller stack for traceback information
	my @trace      = ($message);
	my $skipParser = (caller(3))[3] =~ m/^(Parser|Value)::/;

	my $frame = 2;
	while (my ($pkg, $file, $line, $subname) = caller($frame++)) {
		last if ($subname =~ m/^(Safe::reval|main::__ANON__)/);
		next if $skipParser && $subname =~ m/^(Parser|Value)::/;              # Skip Parser and Value calls.
		next if $subname                =~ m/^WeBWorK::PG::Translator/;       # Skip Translator calls.
		next if $subname =~ m/^main::(safe_ev|old_safe_ev|ev_substring)$/;    # Skip PGbasicmacros.pl ev calls.
		next if $subname =~ m/__ANON__/;
		$file = $files->{$file} || $file;
		$file =~ s!^$tmpl![TMPL]!;
		$file =~ s!^$root![WW]!;
		$file =~ s!^$pg![PG]!;
		$message = "   from within $subname called at line $line of $file";
		next if $message =~ m/within \(eval\)/;
		push @trace, $message;
		$skipParser = 0;
	}

	# Report the full traceback.
	return join("\n", @trace, '');
}

=head2 Translate

B<Preprocess the problem text>

The input text is subjected to some global replacements.

First every incidence of

    BEGIN_TEXT
    problem text
    END_TEXT

is replaced by

    TEXT(EV3(<<'END_TEXT'));
    problem text
    END_TEXT

The first construction is syntactic sugar for the second. This is explained
in C<PGbasicmacros.pl>.

Second every incidence of \ (backslash) is replaced by \\ (double backslash).

Third each incidence of ~~ is replaced by a single backslash.

This is done to alleviate a basic incompatibility between TeX and Perl. TeX uses
backslashes to denote a command word (as opposed to text which is to be entered
literally).  Perl uses backslashes to escape the following symbol.  This escape
mechanism takes place immediately when a Perl script is compiled and takes place
throughout the code and within every quoted string (both double and single
quoted strings) with the single exception of single quoted "here" documents.
That is backlashes which appear in

    TEXT(<<'EOF');
    ... text including \{   \} for example
    EOF

are the only ones not immediately evaluated.  This behavior makes it very difficult
to use TeX notation for defining mathematics within text.

The initial global replacement, before compiling a PG problem, allows one to use
backslashes within text without doubling them. (The anomalous behavior inside
single quoted "here" documents is compensated for by the behavior of the
evaluation macro EV3.) This makes typing TeX easy, but introduces one difficulty
in entering normal Perl code.

The second global replacement provides a work around for this.  That is to use
~~ when you would ordinarily use a backslash in Perl code.  In order to define a
carriage return use ~~n rather than \n; in order to define a reference to a
variable you must use ~~@array rather than \@array. This is annoying and a
source of simple compiler errors, but must be lived with.

The problems are not evaluated in strict mode, so global variables can be used
without warnings.

Note that there are several other replacements that are now done that are not
documented here.  See the C<default_preprocess_code> method for all
replacements that are done.

B<Evaluate the problem text>

Evaluate the text within the safe compartment.  Save the errors. The safe
compartment is a new one unless the $safeCompartment was set to zero in which
case the previously defined safe compartment is used. (See item 1.)

B<Process errors>

The error provided by Perl is truncated slightly and returned. In the text
string which would normally contain the rendered problem.

The original text string is given line numbers and concatenated to the errors.

B<Prepare return values>

Sets the following hash keys of the translator object:
    PG_PROBLEM_TEXT_REF: Reference to a string containing the rendered text.
    PG_HEADER_TEXT_REF:  Reference to a string containing material to be placed
        in the header.
    PG_POST_HEADER_TEXT_REF:  Reference to a string containing material to
        be placed in body above form.
    rh_correct_answers:  Reference to an array containing the answer evaluators.
        Constructed from keys of $PGcore->{PG_ANSWERS_HASH}.
    PG_FLAGS_REF:  Reference to a hash containing flags and other references:
        'error_flag' is set to 1 if there were errors in rendering.
    rh_pgcore:  The PGcore object.

=cut

# Characters that should be escaped in XML
my %XML = ('&' => '&amp;', '<' => '&lt;', '>' => '&gt;', '"' => '&quot;', '\'' => '&#39;');

sub translate {
	my $self       = shift;
	my $safe_cmpt  = $self->{safe};
	my $evalString = $self->{source};
	$self->{errors} .= qq{ERROR:  This problem file was empty!\n} unless ($evalString);
	$self->{errors} .= qq{ERROR:  You must define the environment before translating.}
		unless defined($self->{envir});

	# Create a global reference to the __files__ hash in the envir so that
	# it can be accessed in the $PG_errorMessage method.
	$main::__files__ = $self->{envir}{__files__};

	# Install handlers for warn and die that call PG_errorMessage.
	# If the existing signal handler is not a coderef, the built-in warn or
	# die function is called. This does not account for the case where the
	# handler is set to "IGNORE" or to the name of a function. In these cases
	# the built-in function will be called.

	my $outer_sig_warn = $SIG{__WARN__};
	my (@frontend_warnings, @backend_warnings);
	local $SIG{__WARN__} = sub { $_[1] ? push(@backend_warnings, $_[0]) : push(@frontend_warnings, $_[0]); };

	my $outer_sig_die = $SIG{__DIE__};
	local $SIG{__DIE__} = sub {
		ref $outer_sig_die eq "CODE"
			? &$outer_sig_die(PG_errorMessage('traceback', $_[0]))
			: die PG_errorMessage('traceback', $_[0]);
	};

	# PG preprocessing code
	$evalString =
		'BEGIN { my $eval = __FILE__; $main::envir{__files__}{$eval} = "'
		. $self->{envir}{probFileName} . '" };'
		. &{ $self->{preprocess_code} }($evalString);

	my ($PG_PROBLEM_TEXT_REF, $PG_HEADER_TEXT_REF, $PG_POST_HEADER_TEXT_REF, $PG_ANSWER_HASH_REF, $PG_FLAGS_REF,
		$PGcore)
		= $safe_cmpt->reval($evalString);

	# This section could use some more error messages.  In particular if a problem doesn't produce the right output,
	# the user needs information about which problem was at fault.

	# FIXME The various warning message tracks are still being sorted out
	# WARNING and DEBUG tracks are being handled elsewhere (in Problem.pm?)
	$self->{errors} .= "ERRORS from evaluating PG file:\n$@\n" if $@;

	my @PROBLEM_TEXT_OUTPUT;
	push(@PROBLEM_TEXT_OUTPUT, split(/^/, $$PG_PROBLEM_TEXT_REF)) if ref($PG_PROBLEM_TEXT_REF) eq 'SCALAR';
	# This is better than using defined($$PG_PROBLEM_TEXT_REF)
	# Because more pleasant feedback is given when the problem doesn't render.
	# Try to get the \n to appear at the end of the line.

	if (@frontend_warnings) {
		ref $outer_sig_warn eq "CODE"
			? &$outer_sig_warn(PG_errorMessage('message', @frontend_warnings))
			: warn PG_errorMessage('message', @frontend_warnings);
	}
	if (@backend_warnings) {
		if (ref $outer_sig_warn eq "CODE" && $self->{envir}{view_problem_debugging_info}) {
			&$outer_sig_warn(PG_errorMessage(
				'message',
				'Non fatal warnings. '
					. 'These are only displayed for users with permission to view problem debugging info.',
				@backend_warnings
			));
		} else {
			local $SIG{__WARN__} = 'DEFAULT';
			warn PG_errorMessage('message', @backend_warnings);
		}
	}

	# PG postprocessing code
	$PG_PROBLEM_TEXT_REF = &{ $self->{postprocess_code} }($PG_PROBLEM_TEXT_REF);

	# PG error processing code
	if ($self->{errors}) {
		chomp($self->{errors});
		if ($self->{envir}{view_problem_debugging_info}) {
			push(
				@PROBLEM_TEXT_OUTPUT,
				"<p>ERROR caught by Translator while processing problem file: $self->{envir}{probFileName}</p><hr>",
				"<pre>$self->{errors}</pre><hr>"
			);

			push(@PROBLEM_TEXT_OUTPUT, '<p>Input Read:</p><hr><pre style="tab-size:4">');
			$self->{source} =~ s/([&<>"'])/$XML{$1}/ge;
			my @input      = split("\n", $self->{source});
			my $lineNumber = 1;
			for my $line (@input) {
				chomp($line);
				push(@PROBLEM_TEXT_OUTPUT, "$lineNumber:\t$line\n");
				$lineNumber++;
			}
			push(@PROBLEM_TEXT_OUTPUT, '</pre>');
		} else {
			warn "ERRORS in rendering problem: $self->{envir}{probFileName}\n$self->{errors}";
			push(@PROBLEM_TEXT_OUTPUT, '<p>ERROR caught by Translator while processing this problem</p>');
		}
	}

	$PG_FLAGS_REF->{error_flag} = 1 if $self->{errors};
	my $PG_PROBLEM_TEXT = join("", @PROBLEM_TEXT_OUTPUT);

	$self->{PG_PROBLEM_TEXT_REF} = \$PG_PROBLEM_TEXT;

	# Make sure that these variables are defined.  If the eval failed with
	# errors, one or more of these variables won't be defined.
	$self->{PG_HEADER_TEXT_REF}      = $PG_HEADER_TEXT_REF      // \('');
	$self->{PG_POST_HEADER_TEXT_REF} = $PG_POST_HEADER_TEXT_REF // \('');
	$self->{rh_correct_answers}      = $PG_ANSWER_HASH_REF      // {};
	$self->{PG_FLAGS_REF}            = $PG_FLAGS_REF            // {};

	$self->{rh_pgcore} = $PGcore;

	return;
}

=head2 Answer evaluation methods

=cut

=head3 access methods

    $obj->rh_student_answers

=cut

sub rh_evaluated_answers {
	my ($self, @in) = @_;
	return $self->{rh_evaluated_answers} if @in == 0;

	if (ref($in[0]) eq 'HASH') {
		$self->{rh_evaluated_answers} = { %{ $in[0] } };
	} else {
		$self->{rh_evaluated_answers} = {@in};
	}
	return $self->{rh_evaluated_answers};
}

sub rh_problem_result {
	my ($self, @in) = @_;
	return $self->{rh_problem_result} if @in == 0;

	if (ref($in[0]) eq 'HASH') {
		$self->{rh_problem_result} = { %{ $in[0] } };
	} else {
		$self->{rh_problem_result} = {@in};
	}
	return $self->{rh_problem_result};
}

sub rh_problem_state {
	my ($self, @in) = @_;
	return $self->{rh_problem_state} if @in == 0;

	if (ref($in[0]) eq 'HASH') {
		$self->{rh_problem_state} = { %{ $in[0] } };
	} else {
		$self->{rh_problem_state} = {@in};
	}
	return $self->{rh_problem_state};
}

=head3 process_answers

    $obj->process_answers()

=cut

sub process_answers {
	my ($self) = @_;

	my $rh_correct_answers = $self->rh_correct_answers();
	my @answer_entry_order =
		(defined($self->{PG_FLAGS_REF}->{ANSWER_ENTRY_ORDER}))
		? @{ $self->{PG_FLAGS_REF}->{ANSWER_ENTRY_ORDER} }
		: keys %{$rh_correct_answers};

	# Define custom warn/die handlers for answer evaluation.
	my $outer_sig_warn = $SIG{__WARN__};
	local $SIG{__WARN__} = sub {
		ref $outer_sig_warn eq 'CODE'
			? &$outer_sig_warn(PG_errorMessage('message', $_[0]))
			: warn PG_errorMessage('message', $_[0]);
	};

	my $fullerror;
	my $outer_sig_die = $SIG{__DIE__};
	local $SIG{__DIE__} = sub {
		$fullerror = PG_errorMessage('traceback', @_);
		my ($error) = split /\n/, $fullerror, 2;
		$error .= "\n";
		ref $outer_sig_die eq 'CODE' ? &$outer_sig_die($error) : die $error;
	};
	my $PG = $self->{rh_pgcore};

	our ($new_rf_fun, $new_temp_ans);
	for my $ans_name (keys %{ $PG->{PG_ANSWERS_HASH} }) {
		my $local_debug = 0;    # Enables reporting of each $ans_name evaluator and responses.
		$PG->debug_message("Executing answer evaluator $ans_name ") if $local_debug;

		# gather answers and answer evaluator
		local ($new_rf_fun, $new_temp_ans);
		# This has all answer evaluators AND answer blanks (just to be sure).
		my $answergrp   = $PG->{PG_ANSWERS_HASH}->{$ans_name};
		my $responsegrp = $answergrp->response_obj;

		# Refactor to answer group?
		$new_rf_fun = $answergrp->ans_eval;
		my $ans = $responsegrp->get_response($ans_name);
		$new_temp_ans = $ans;    # Avoid undefined errors in translator
		my $skip_evaluation = 0;
		if (not defined($new_rf_fun)) {
			$PG->warning_message("No answer evaluator for the question labeled: $ans_name ");
			$skip_evaluation = 1;
		} elsif (not ref($new_rf_fun) =~ /AnswerEvaluator/) {
			$PG->warning_message(
				"Error in Translator.pm::process_answers: Answer $ans_name:
				                    Unrecognized evaluator type |" . ref($new_rf_fun) . "|"
			);
			$skip_evaluation = 1;
		}
		if (not defined($new_temp_ans)) {
			$PG->warning_message("No answer blank provided for answer evaluator $ans_name ");
			$skip_evaluation = 1;
		}
		$PG->debug_message("Answers associated with $ans_name are $new_temp_ans ref=" . ref($new_temp_ans))
			if defined $new_temp_ans and $local_debug;

		# Handle check boxes and radio buttons.
		if (ref($new_temp_ans) eq 'ARRAY') {
			$new_temp_ans = [ map { $_->[0] } grep { $_->[1] eq 'CHECKED' } @$new_temp_ans ];
			$new_temp_ans = $new_temp_ans->[0] // '' if @$new_temp_ans < 2;
		}

		$self->{safe}->share('$new_rf_fun', '$new_temp_ans');

		my ($rh_ans_evaluation_result, $new_rh_ans_evaluation_result);

		if (ref($new_rf_fun) eq 'CODE') {
			$PG->warning_message('CODE objects cannot be used directly as answer evaluators.  Use AnswerEvaluator');
		} elsif (!$skip_evaluation) {
			$new_rh_ans_evaluation_result =
				$self->{safe}->reval('$new_rf_fun->evaluate($new_temp_ans, ans_label => \'' . $ans_name . '\')');

			if ($@) {
				$PG->warning_message($@);
				$PG->debug_message(split /\n/, $fullerror) if $fullerror && $self->{envir}{view_problem_debugging_info};
			} elsif (ref($new_rh_ans_evaluation_result) =~ /AnswerHash/i) {
				$PG->warning_message(
					"Evaluation error in new process: Answer $ans_name:<br/>\n",
					$new_rh_ans_evaluation_result->error_flag(),
					' :: ', $new_rh_ans_evaluation_result->error_message(), "<br/>\n"
					)
					if defined $new_rh_ans_evaluation_result
					&& ref $new_rh_ans_evaluation_result
					&& defined $new_rh_ans_evaluation_result->error_flag();
			} else {
				$PG->warning_message('The evaluated answer is not an answer hash '
						. ($new_rh_ans_evaluation_result // '') . ': |'
						. ref($new_rh_ans_evaluation_result)
						. '|.');
			}
		} else {
			$PG->warning_message("Answer evaluator $ans_name was not executed due to errors. ", '========');
		}
		# End refactor to answer group?

		$PG->debug_message(
			"new $ans_name: $new_rf_fun -- ans:
  	          	$new_temp_ans", pretty_print($new_rh_ans_evaluation_result)
		) if $PG->{envir}{inputs_ref}{showAnsHashInfo} && $PG->{envir}{show_answer_hash_info};

		# Decide whether to return the new or old answer evaluator hash
		$rh_ans_evaluation_result = $new_rh_ans_evaluation_result;

		$rh_ans_evaluation_result->{ans_name} = $ans_name;
		$self->{rh_evaluated_answers}->{$ans_name} = $rh_ans_evaluation_result;
	}
	return $self->rh_evaluated_answers;
}

sub stringify_answers {
	my $self = shift;
	no strict;
	local $rh_answers = $self->{rh_evaluated_answers};
	$self->{safe}->share('$rh_answers');
	$self->{safe}->reval(<<'END_EVAL;');
(sub {
	for my $label (keys %$rh_answers) {
		$rh_answers->{$label}->stringify_hash if ref($rh_answers->{$label}) =~ m/AnswerHash/;
	}
})->();
END_EVAL;
	die $@ if $@;
	use strict;

	return;
}

=head3 grade_problem

    $obj->rh_problem_state(%problem_state);  # sets the current problem state
    $obj->grade_problem(%form_options);

=cut

sub grade_problem {
	my ($self, %options) = @_;

	no strict;

	local %rf_options = %options;
	local $rf_grader  = $self->{rf_problem_grader};
	local $rh_answers = $self->{rh_evaluated_answers};
	local $rh_state   = $self->{rh_problem_state};
	$self->{safe}->share('$rf_grader', '$rh_answers', '$rh_state', '%rf_options');

	# FIXME: Warning messages are not being transmitted from this evaluation.
	($self->{rh_problem_result}, $self->{rh_problem_state}) =
		$self->{safe}->reval('&{$rf_grader}($rh_answers, $rh_state, %rf_options)');

	use strict;

	die $@ if $@;
	return ($self->{rh_problem_result}, $self->{rh_problem_state});
}

# These are models for plug-in problem graders.

sub rf_std_problem_grader {
	my $self = shift;
	return \&std_problem_grader;
}

sub std_problem_grader {
	my ($rh_evaluated_answers, $rh_problem_state, %form_options) = @_;

	my %evaluated_answers = %{$rh_evaluated_answers};

	# By default the old problem state is simply passed back out again.
	my %problem_state = %$rh_problem_state;

	# Initial setup of the answer.
	my %problem_result = (
		score  => 0,
		errors => '',
		type   => 'std_problem_grader',
		msg    => '',
	);

	my $ansCount = keys %evaluated_answers;
	unless ($ansCount > 0) {
		$problem_result{msg} = 'This problem did not ask any questions.';
		return (\%problem_result, \%problem_state);
	}

	$problem_result{msg} = 'In order to get credit for this problem all answers must be correct.'
		if $ansCount > 1;

	return (\%problem_result, \%problem_state)
		unless defined $form_options{answers_submitted} && $form_options{answers_submitted} == 1;

	my $allAnswersCorrectQ = 1;
	for my $ans_name (keys %evaluated_answers) {
		if (ref $evaluated_answers{$ans_name} eq 'HASH' or ref $evaluated_answers{$ans_name} eq 'AnswerHash') {
			$allAnswersCorrectQ = 0 unless $evaluated_answers{$ans_name}->{score} == 1;
		} else {
			warn "Error: Answer $ans_name is not a hash";
			warn "$evaluated_answers{$ans_name}";
			warn 'This probably means that the answer evaluator for this answer is not working correctly.';
			$problem_result{error} = "Error: Answer $ans_name is not a hash: $evaluated_answers{$ans_name}";
		}
	}

	# Report the results.
	$problem_result{score} = $allAnswersCorrectQ;
	$problem_state{recorded_score} //= 0;

	if ($allAnswersCorrectQ == 1 || $problem_state{recorded_score} == 1) {
		$problem_state{recorded_score} = 1;
	} else {
		$problem_state{recorded_score} = 0;
	}

	++$problem_state{num_of_correct_ans}   if $allAnswersCorrectQ == 1;
	++$problem_state{num_of_incorrect_ans} if $allAnswersCorrectQ == 0;

	return (\%problem_result, \%problem_state);
}

sub rf_avg_problem_grader {
	my $self = shift;
	return \&avg_problem_grader;
}

sub avg_problem_grader {
	my ($rh_evaluated_answers, $rh_problem_state, %form_options) = @_;

	my %evaluated_answers = %{$rh_evaluated_answers};

	# By default the old problem state is simply passed back out again.
	my %problem_state = %$rh_problem_state;

	# Initial setup of the answer
	my $total          = 0;
	my %problem_result = (
		score  => 0,
		errors => '',
		type   => 'avg_problem_grader',
		msg    => '',
	);

	my $count = keys %evaluated_answers;
	$problem_result{msg} = 'You can earn partial credit on this problem.' if $count > 1;

	return (\%problem_result, \%problem_state) unless $form_options{answers_submitted} == 1;

	# Answers have been submitted -- process them.
	for my $ans_name (keys %evaluated_answers) {
		$total += $evaluated_answers{$ans_name}{score};
	}

	# Calculate score rounded to three places to avoid roundoff problems
	$problem_result{score} = $count ? $total / $count : 0;
	$problem_state{recorded_score} //= 0;

	# Increase recorded score if the current score is greater.
	$problem_state{recorded_score} = $problem_result{score}
		if $problem_result{score} > $problem_state{recorded_score};

	++$problem_state{num_of_correct_ans}   if $total == $count;
	++$problem_state{num_of_incorrect_ans} if $total < $count;

	warn "Error in grading this problem the total $total is larger than $count" if $total > $count;

	return (\%problem_result, \%problem_state);
}

=head2 post_process_content

Call hooks added via macros or the problem via C<add_content_post_processor> to
post process content.  Hooks are called in the order they were added.

This method should be called in the rendering process after answer processing
has occurred.

If the display mode is TeX, then each hook subroutine is passed a reference to
the problem text string generated in the C<translate> method.

For all other display modes each hook subroutine is passed two Mojo::DOM
objects.  The first containing the parsed problem text string, and the second
contains the parsed header text string, both of which were generated in the
C<translate> method.  After all hooks are called and modifications are made to
the Mojo::DOM contents by the hooks, the Mojo::DOM objects are converted back to
strings and the translator problem text and header references are updated with
the contents of those strings.

=cut

sub post_process_content {
	my $self = shift;

	my $outer_sig_warn = $SIG{__WARN__};
	my @warnings;
	local $SIG{__WARN__} = sub { push(@warnings, $_[0]) };

	my $outer_sig_die = $SIG{__DIE__};
	local $SIG{__DIE__} = sub {
		ref $outer_sig_die eq "CODE"
			? $outer_sig_die->(PG_errorMessage('traceback', $_[0]))
			: die PG_errorMessage('traceback', $_[0]);
	};

	if ($self->{rh_pgcore}{displayMode} eq 'TeX') {
		our $PG_PROBLEM_TEXT_REF = $self->{PG_PROBLEM_TEXT_REF};
		$self->{safe}->share('$PG_PROBLEM_TEXT_REF');
		$self->{safe}->reval('for (@{ $main::PG->{content_post_processors} }) { $_->($PG_PROBLEM_TEXT_REF); }', 1);
		warn "ERRORS from post processing PG text:\n$@\n" if $@;
	} else {
		$self->{safe}->share_from('main', [qw(%Mojo::Base:: %Mojo::Collection:: %Mojo::DOM::)]);
		our $problemDOM =
			Mojo::DOM->new->xml($self->{rh_pgcore}{displayMode} eq 'PTX')->parse(${ $self->{PG_PROBLEM_TEXT_REF} });
		our $pageHeader = Mojo::DOM->new(${ $self->{PG_HEADER_TEXT_REF} });
		$self->{safe}->share('$problemDOM', '$pageHeader');
		$self->{safe}->reval('for (@{ $main::PG->{content_post_processors} }) { $_->($problemDOM, $pageHeader); }', 1);
		warn "ERRORS from post processing PG text:\n$@\n" if $@;

		$self->{PG_PROBLEM_TEXT_REF} = \($problemDOM->to_string);
		$self->{PG_HEADER_TEXT_REF}  = \($pageHeader->to_string);
	}

	if (@warnings) {
		ref $outer_sig_warn eq "CODE"
			? $outer_sig_warn->(PG_errorMessage('message', @warnings))
			: warn PG_errorMessage('message', @warnings);
	}

	return;
}

=head2 PG_restricted_eval

    PG_restricted_eval($string)

Evaluated in package 'main'. Result of last statement is returned.
When called from within a safe compartment the safe compartment package
is 'main'.

=cut

# Remember, eval STRING evaluates code in the current lexical context, so any
# lexicals available here will also be available in the evaluated code. So we
# move the actual eval into a helper function called PG_restricted_eval_helper,
# which doesn't need to have any lexicals.
sub PG_restricted_eval {
	my $string = shift;

	my $outer_sig_warn = $SIG{__WARN__};
	local $SIG{__WARN__} = sub {
		# Note that the second argument to outer_sig_warn is 1 so that these warnings will not be shown to students.
		ref $outer_sig_warn eq 'CODE'
			? &$outer_sig_warn(PG_errorMessage('traceback', $_[0]), 1)
			: warn PG_errorMessage('traceback', $_[0]);
	};
	local $SIG{__DIE__} = 'DEFAULT';

	my $out        = PG_restricted_eval_helper($string);
	my $err        = $@;
	my $err_report = $err =~ /\S/ ? $err : undef;
	return wantarray ? ($out, $err, $err_report) : $out;
}

# This is a helper that doesn't use any lexicals. See above.
sub PG_restricted_eval_helper {
	my $code = shift;

	no strict;

	# Many macros redefine methods using PG_restricted_eval.  This hides those warnings.
	no warnings 'redefine';

	return eval("package main; $code");
}

sub PG_macro_file_eval {
	my ($string, $filePath) = @_;

	my $outer_sig_warn = $SIG{__WARN__};
	my $warnings       = '';
	local $SIG{__WARN__} = sub { $warnings .= $_[0]; };

	local $SIG{__DIE__} = 'DEFAULT';

	if ($string =~ /^=/) {
		$string = "\n$string";
		warn "The first line of a macro must not contain a POD directive at $filePath line 1.\n"
			. "A new line will be added, but this will result in errors and warnings from "
			. "this file being reported on the incorrect line number.\n";
	}

	my ($out, $errors) =
		PG_macro_file_eval_helper('package main; strict->import;'
			. 'BEGIN { my $eval = __FILE__; $main::envir{__files__}{$eval} = "'
			. $filePath . '" };'
			. $string);

	if ($warnings) {
		# Send these files to the outer warning signal handler so the (eval nnn) will be replaced with the filename.
		# Note that the second argument t outer_sig_warn is 1 so that these warnings will not be shown to students.
		ref $outer_sig_warn eq 'CODE' ? &$outer_sig_warn($warnings, 1) : warn $warnings;
	}

	my ($pck, $file, $line) = caller;
	my $full_error_report = '';
	$full_error_report =
		"PG_macro_file_eval detected error at line $line of file $file\n${errors}\nThe calling package is $pck\n"
		if defined $errors && $errors =~ /\S/;

	return (wantarray) ? ($out, $errors, $full_error_report) : $out;
}

# This is another helper that doesn't use any lexicals.
# It would nice to be able to remove the "no strict" call so "use strict" applies to the files that it evaluates.
sub PG_macro_file_eval_helper {
	my $string = shift;

	no strict;
	# Many subroutines are redefined in macros.  In addition if multiple WeBWorK::PG::Translator instances are created
	# in the same process, the safe compartment is not entirely isolated between instances, and this causes redefine
	# warnings if a macro is loaded in both instances.  So those warnings are disabled.
	no warnings 'redefine';
	my $out    = eval($string);
	my $errors = $@;
	use strict;

	return ($out, $errors);
}

=head2 PG_answer_eval

    PG_answer_eval($string)

Evaluated in package defined by the current safe compartment.
Result of last statement is returned.
When called from within a safe compartment the safe compartment package
is 'main'.

There is still some confusion about how these two evaluation subroutines work
and how best to define them.  It is useful to have two evaluation procedures
since at some point one might like to make the answer evaluations more stringent.

=cut

sub PG_answer_eval {
	my $string = shift;

	my $errors            = '';
	my $full_error_report = '';
	my ($pck, $file, $line) = caller;

	# Because of the global variable $PG::compartment_name and $PG::safe_cmpt only one problem safe compartment can be
	# active at a time.  This might cause problems at some point.  In that case a cleverer way of insuring that the
	# package stays in scope until the answer is evaluated will be required.

	local $SIG{__WARN__} = sub { die(@_) };    # make warn die, so all errors are reported.
	local $SIG{__DIE__}  = 'DEFAULT';

	no strict;
	my $out = eval('package main;' . $string);
	$out = '' unless defined($out);
	$errors .= $@;
	$full_error_report = "ERROR: at line $line of file $file
                $errors
                The calling package is $pck\n" if defined($errors) && $errors =~ /\S/;
	use strict;

	return (wantarray) ? ($out, $errors, $full_error_report) : $out;
}

sub default_preprocess_code {
	my $evalString = shift // '';

	$evalString =~ s/\r\n/\n/g;

	# BEGIN_TEXT, END_TEXT, and the others that follow must occur on a line by themselves.
	$evalString =~ s/\n\h*END_TEXT[\h;]*\n/\nEND_TEXT\n/g;
	$evalString =~ s/\n\h*END_PGML[\h;]*\n/\nEND_PGML\n/g;
	$evalString =~ s/\n\h*END_PGML_SOLUTION[\h;]*\n/\nEND_PGML_SOLUTION\n/g;
	$evalString =~ s/\n\h*END_PGML_HINT[\h;]*\n/\nEND_PGML_HINT\n/g;
	$evalString =~ s/\n\h*END_SOLUTION[\h;]*\n/\nEND_SOLUTION\n/g;
	$evalString =~ s/\n\h*END_HINT[\h;]*\n/\nEND_HINT\n/g;
	$evalString =~ s/\n\h*BEGIN_TEXT[\h;]*\n/\nSTATEMENT\(EV3P\(<<'END_TEXT'\)\);\n/g;
	$evalString =~ s/\n\h*BEGIN_PGML[\h;]*\n/\nSTATEMENT\(PGML::Format2\(<<'END_PGML'\)\);\n/g;
	$evalString =~ s/\n\h*BEGIN_PGML_SOLUTION[\h;]*\n/\nSOLUTION\(PGML::Format2\(<<'END_PGML_SOLUTION'\)\);\n/g;
	$evalString =~ s/\n\h*BEGIN_PGML_HINT[\h;]*\n/\nHINT\(PGML::Format2\(<<'END_PGML_HINT'\)\);\n/g;
	$evalString =~ s/\n\h*BEGIN_SOLUTION[\h;]*\n/\nSOLUTION\(EV3P\(<<'END_SOLUTION'\)\);\n/g;
	$evalString =~ s/\n\h*BEGIN_HINT[\h;]*\n/\nHINT\(EV3P\(<<'END_HINT'\)\);\n/g;
	$evalString =~ s/\n\h*(.*)\h*->\h*BEGIN_TIKZ[\h;]*\n/\n$1->tex\(<<END_TIKZ\);\n/g;
	$evalString =~ s/\n\h*END_TIKZ[\h;]*\n/\nEND_TIKZ\n/g;
	$evalString =~ s/\n\h*(.*)\h*->\h*BEGIN_LATEX_IMAGE[\h;]*\n/\n$1->tex\(<<END_LATEX_IMAGE\);\n/g;
	$evalString =~ s/\n\h*END_LATEX_IMAGE[\h;]*\n/\nEND_LATEX_IMAGE\n/g;

	# Remove text after ENDDOCUMENT
	$evalString =~ s/ENDDOCUMENT.*/ENDDOCUMENT();/s;

	$evalString =~ s/\\/\\\\/g;    # \ can't be used for escapes because of TeX conflict
	$evalString =~ s/~~/\\/g;      # use ~~ as escape instead, use # for comments

	return $evalString;
}

sub default_postprocess_code {
	my $evalString_ref = shift;
	return $evalString_ref;
}

1;
