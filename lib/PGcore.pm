package PGcore;
use strict;

BEGIN {
	use File::Basename qw(dirname);
	my $dir = dirname(__FILE__);
	do "${dir}/../VERSION";
	warn "Error loading PG VERSION file: $!"    if $!;
	warn "Error processing PG VERSION file: $@" if $@;
	$ENV{PG_VERSION} = $PGcore::PG_VERSION || 'unknown';
}

our $internal_debug_messages = [];

use PGanswergroup;
use PGresponsegroup;
use PGrandom;
use PGalias;
use PGloadfiles;
use AnswerHash;
require WeBWorK::PG::IO;
use Tie::IxHash;
use MIME::Base64();
use PGUtil();
use Encode qw(encode_utf8 decode_utf8);
use utf8;
binmode(STDOUT, ":utf8");
##################################
# PGcore object
##################################

sub not_null {
	my $self = shift;
	PGUtil::not_null(@_);
}

sub pretty_print {
	my $self        = shift;
	my $input       = shift;
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
	my $envir = shift;    #pointer to environment hash
	warn "PGcore must be called with an environment" unless ref($envir) eq 'HASH';
	#warn "creating a new PGcore object";
	my %options = @_;
	my $self    = {
		OUTPUT_ARRAY      => [],    # holds output body text
		HEADER_ARRAY      => [],    # holds output for the header text
		POST_HEADER_ARRAY => [],
		PG_ANSWERS_HASH   => {},    # holds label=>answer pairs

		# Holds other data, besides answers, which persists during a session and beyond.
		PERSISTENCE_HASH            => $envir->{PERSISTENCE_HASH} // {},    # Main data, received from DB
		answer_name_count           => 0,
		implicit_named_answer_stack => [],
		implicit_answer_eval_stack  => [],
		explicit_answer_name_evals  => {},
		KEPT_EXTRA_ANSWERS          => [],
		ANSWER_PREFIX               => 'AnSwEr',
		ARRAY_PREFIX                => 'ArRaY',
		vec_num                     => 0,                                   # for distinguishing matrices
		QUIZ_PREFIX                 => $envir->{QUIZ_PREFIX},
		PG_VERSION                  => $ENV{PG_VERSION},
		PG_ACTIVE                   => 1,                                   # toggle to zero to stop processing
		submittedAnswers            => 0,        # have any answers been submitted? is this the first time this session?
		PG_session_persistence_hash => {},       # stores data from one invoction of the session to the next.
		PG_original_problem_seed    => 0,
		PG_random_generator         => undef,
		PG_alias                    => undef,
		PG_problem_grader           => undef,
		displayMode                 => undef,
		content_post_processors     => [],
		envir                       => $envir,
		WARNING_messages            => [],
		DEBUG_messages              => [],
		names_created               => 0,
		%options,                                # allows overrides and initialization
	};
	bless $self, $class;
	tie %{ $self->{PG_ANSWERS_HASH} }, "Tie::IxHash";    # creates a Hash with order
	$self->initialize;
	return $self;
}

sub initialize {
	my $self = shift;
	warn "environment is not defined in PGcore" unless ref($self->{envir}) eq 'HASH';

	$self->{displayMode}              = $self->{envir}->{displayMode};
	$self->{PG_original_problem_seed} = $self->{envir}->{problemSeed};
	$self->{PG_random_generator}      = new PGrandom($self->{PG_original_problem_seed});
	$self->{problemSeed}              = $self->{PG_original_problem_seed};
	$self->{PG_problem_grader}        = $self->{envir}->{PROBLEM_GRADER_TO_USE};
	$self->{PG_alias}                 = PGalias->new(
		$self->{envir},
		WARNING_messages => $self->{WARNING_messages},
		DEBUG_messages   => $self->{DEBUG_messages},
	);
	$self->{maketext}      = $self->{envir}{language_subroutine};
	$self->{PG_loadMacros} = new PGloadfiles($self->{envir});
	$self->{flags}         = {
		showPartialCorrectAnswers => 1,
		hintExists                => 0,
		solutionExists            => 0,
		recordSubmittedAnswers    => 1,
		refreshCachedImages       => 0,
		comment                   => '',    # implement as array?
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

Implicitly-named answers: Answers that have not been explicitly
assigned names, and are associated with their answer blanks by the order in
which they appear in the problem. These types of answers are designated using
the C<ANS> method.

=item *

Explicitly-named answers: Answers that have been explicitly assigned
names with the C<NAMED_ANS> method, or a macro that uses it. An explicitly-
named answer is associated with its answer blank by name.

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

=head1 METHODS

=head2 HEADER_TEXT

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
	push @{ $self->{HEADER_ARRAY} }, map { (defined($_)) ? $_ : '' } @_;
	$self->{HEADER_ARRAY};
}

=head2 POST_HEADER_TEXT

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
	push @{ $self->{POST_HEADER_ARRAY} }, map { (defined($_)) ? $_ : '' } @_;
	$self->{POST_HEADER_ARRAY};
}

=head2 TEXT

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
# ^uses $STRINGforOUTPUT

sub TEXT {
	my $self = shift;    #FIXME  filter for undefined entries replace by "";
	push @{ $self->{OUTPUT_ARRAY} }, map { (defined($_)) ? $_ : '' } @_;
	$self->{OUTPUT_ARRAY};
}

sub envir {
	my $self   = shift;
	my $in_key = shift;
	if ($self->not_null($in_key)) {
		if (defined($self->{envir}->{$in_key})) {
			$self->{envir}->{$in_key};
		} else {
			warn "\$envir{$in_key} is not defined\n";
			return '';
		}
	} else {
		warn "<h3> Environment</h3>" . $self->pretty_print($self->{envir});
		return '';
	}

}

=head2 NAMED_ANS

Associates answer names with answer evaluators.  If the given answer name has a
response group in the PG_ANSWERS_HASH, then the evaluator is added to that
response group.  Otherwise the name and evaluator are added to the hash of
explicitly named answer evaluators.  They will be paired with explicitly named
answer rules by name. This allows pairing of answer evaluators and answer rules
that may not have been entered in the same order.

An example of the usage is:

    TEXT(NAMED_ANS_RULE("name1"), NAMED_ANS_RULE("name2"));
    NAMED_ANS(name1 => answer_evaluator1, name2 => answer_evaluator2);

Note that internally implicitly named evaluators are also associated with
their names via this method.

=cut

sub NAMED_ANS {
	my ($self, @in) = @_;

	while (@in) {
		my ($label, $ans_eval) = (shift @in, shift @in);
		$self->warning_message(
			"Error in NAMED_ANS: |$label| -- inputs must be references to AnswerEvaluator objects or subroutines.")
			unless ref($ans_eval) =~ /CODE/ || ref($ans_eval) =~ /AnswerEvaluator/;
		if (ref($ans_eval) =~ /CODE/) {
			# Create an AnswerEvaluator that calls the given CODE reference and use that for $ans_eval.
			# So we always have an AnswerEvaluator from here on.
			my $cmp = new AnswerEvaluator;
			$cmp->install_evaluator(
				sub {
					my $ans     = shift;
					my $checker = shift;
					my @args    = ($ans->{student_ans});
					push(@args, ans_label => $ans->{ans_label}) if defined($ans->{ans_label});
					# Call the original checker with the arguments that PG::Translator would have used
					$checker->(@args);
				},
				$ans_eval
			);
			$ans_eval = $cmp;
		}
		if (ref($self->{PG_ANSWERS_HASH}{$label}) eq 'PGanswergroup') {
			$self->{PG_ANSWERS_HASH}{$label}
				->insert(ans_label => $label, ans_eval => $ans_eval, active => $self->{PG_ACTIVE});
		} else {
			$self->{explicit_answer_name_evals}{$label} = $ans_eval;
		}
	}

	return;
}

=head2 ANS

Registers answer evaluators to be implicitly associated with answer names.  If
there is an answer name in the implicit answer name stack, then a given answer
evaluator will be paired with the first name in the stack.  Otherwise the
evaluator will be pushed onto the implicit answer evaluator stack.  This is the
standard method for entering answers.

    TEXT(ans_rule(), ans_rule(), ans_rule());
    ANS($answer_evaluator1, $answer_evaluator2, $answer_evaluator3);

In the above example, C<$answer_evaluator1> will be associated with the first
answer rule, C<$answer_evaluator2> with the second, and C<$answer_evaluator3>
with the third.  In practice, the arguments to C<ANS> will usually be calls to
an answer evaluator generator such as the C<cmp> method of MathObjects or the
C<num_cmp> macro in L<PGanswermacros.pl>. Note that if the C<ANS> call is made
before the C<ans_rule> calls, the same pairing would occur.

=cut

sub ANS {
	my ($self, @in) = @_;
	while (@in) {
		if (my $label = shift @{ $self->{implicit_named_answer_stack} }) {
			$self->NAMED_ANS($label, shift @in);
		} else {
			# In this case ANS is called before the answer rule method for this answer.
			# Defer calling NAMED_ANS until the answer rule method is called and the answer is recorded.
			push(@{ $self->{implicit_answer_eval_stack} }, shift @in);
		}
	}
	return;
}

=head2 STOP_RENDERING

 STOP_RENDERING() unless all_answers_are_correct();

Temporarily suspends accumulation of problem text and storing of answer blanks
and answer evaluators until RESUME_RENDERING() is called.

=cut

# ^function STOP_RENDERING
sub STOP_RENDERING {
	my $self = shift;
	$self->{PG_ACTIVE} = 0;
	"";
}

=head2 RESUME_RENDERING

 RESUME_RENDERING();

Resumes accumulating problem text and storing answer blanks and answer
evaluators. Reverses the effect of STOP_RENDERING().

=cut

# ^function RESUME_RENDERING
sub RESUME_RENDERING {
	my $self = shift;
	$self->{PG_ACTIVE} = 1;
	"";
}

# Internal methods

# Creates a new name for an answer rule.
sub new_label {
	my ($self, $number) = @_;
	return $self->{QUIZ_PREFIX} . $self->{ANSWER_PREFIX} . sprintf("%04u", $number);
}

# Creates a new name for an element in an array answer rule group.
# $ans_label is the name of the PGanswer group holding this array.
sub new_array_element_label {
	my ($self, $ans_label, $row_num, $col_num, %options) = @_;
	my $vec_num = $options{vec_num} // 0;
	return $self->{QUIZ_PREFIX} . $ans_label . '__' . $vec_num . '-' . $row_num . '-' . $col_num . '__';
}

sub new_ans_name {
	my $self = shift;
	return $self->new_label(++$self->{answer_name_count});
}

sub record_ans_name {
	my ($self, $label, $value) = @_;

	my $response_group = new PGresponsegroup($label, $label, $value);

	if (ref($self->{PG_ANSWERS_HASH}{$label}) eq 'PGanswergroup') {
		# This should really never happen.  Should this warn if it does?
		$self->{PG_ANSWERS_HASH}{$label}
			->replace(ans_label => $label, response => $response_group, active => $self->{PG_ACTIVE});
	} elsif ($self->{explicit_answer_name_evals}{$label}) {
		$self->{PG_ANSWERS_HASH}{$label} =
			PGanswergroup->new($label, response => $response_group, active => $self->{PG_ACTIVE});
		$self->NAMED_ANS($label, delete $self->{explicit_answer_name_evals}{$label});
	} elsif (my $evaluator = shift @{ $self->{implicit_answer_eval_stack} }) {
		$self->{PG_ANSWERS_HASH}{$label} =
			PGanswergroup->new($label, response => $response_group, active => $self->{PG_ACTIVE});
		$self->NAMED_ANS($label, $evaluator);
	} else {
		$self->{PG_ANSWERS_HASH}{$label} =
			PGanswergroup->new($label, response => $response_group, active => $self->{PG_ACTIVE});
	}

	return $label;
}

sub record_implicit_ans_name {
	my ($self, $label) = @_;
	# Do not add to the name stack if there is something in the evaluator stack. Note that if there is something in the
	# evaluator stack then it will be removed when record_ans_name is called which is done when the named answer rule
	# method is called.
	push(@{ $self->{implicit_named_answer_stack} }, $label) unless @{ $self->{implicit_answer_eval_stack} };
	return $label;
}

sub extend_ans_group {    # modifies the group type
	my $self          = shift;
	my $label         = shift;
	my @response_list = @_;
	my $answer_group  = $self->{PG_ANSWERS_HASH}->{$label};
	if (ref($answer_group) eq 'PGanswergroup') {
		$answer_group->append_responses(@response_list);
	}
	return $label;
}

# Save to or retrieve data from the persistence hash.  The $label parameter is the key in the persistence hash.  If the
# $value parameter is not given then the value of the $label key in the hash will be returned.  If the $value parameter
# is given then the value of the $label key in the hash will be saved or updated.  Note that if the $value parameter is
# given but is undefined then the $label key will be deleted from the hash.  Anything that can be JSON encoded can be
# stored.
sub persistent_data {
	my ($self, $label, $value) = @_;
	if (@_ > 2) {
		if (defined $value) {
			$self->{PERSISTENCE_HASH}{$label} = $value;
		} else {
			delete $self->{PERSISTENCE_HASH}{$label};
		}
	}
	return $self->{PERSISTENCE_HASH}{$label};
}

sub add_content_post_processor {
	my ($self, $handler) = @_;
	push(@{ $self->{content_post_processors} }, $handler) if ref($handler) eq 'CODE';
	return;
}

sub check_answer_hash {
	my $self = shift;
	foreach my $key (keys %{ $self->{PG_ANSWERS_HASH} }) {
		my $ans_eval = $self->{PG_ANSWERS_HASH}->{$key}->{ans_eval};
		unless (ref($ans_eval) eq 'CODE' or ref($ans_eval) eq 'AnswerEvaluator') {
			warn "The answer group labeled $key is missing an answer evaluator";
		}
		unless (ref($self->{PG_ANSWERS_HASH}->{$key}->{response}) eq 'PGresponsegroup') {
			warn "The answer group labeled $key is missing answer blanks ";
		}
	}
}

sub PG_restricted_eval {
	my $self = shift;
	WeBWorK::PG::Translator::PG_restricted_eval(@_);
}

=head2 base64 encoding and decoding

	$str       = decode_base64($coded_str);
	$coded_str = encode_base64($str);

=cut

sub decode_base64 ($) {
	my $self = shift;
	my $str  = shift;
	$str = MIME::Base64::decode_base64($str);
	decode_utf8($str);
}

sub encode_base64 ($;$) {
	my $self   = shift;
	my $str    = shift;
	my $option = shift;
	$str = encode_utf8($str);
	MIME::Base64::encode_base64($str);
}

#####
#  This macro encodes HTML, EV3, and PGML special caracters using html codes
#  This should be done for any variable which contains student input and is
#  printed to a screen or interpreted by EV3.

sub encode_pg_and_html {
	my $input = shift;
	$input = HTML::Entities::encode_entities($input, '<>"&\'\$\@\\\\`\\[*_\x00-\x1F\x7F');
	return $input;
}

=head2 insertGraph

	# returns a path to the file containing the graph image.
	$filePath = insertGraph($graphObject);

insertGraph writes an image file to the images subdirectory of the
current course's HTML temp directory. The file name is obtained from the graph
object. Warnings are issued if errors occur while writing to the file.

Returns a string containing the full path to the temporary file containing the
image. This is most often used in the construct

	TEXT(alias(insertGraph($graph)));

where alias converts the directory address to a URL when serving HTML pages and
insures that an EPS file is generated when creating TeX code for downloading.

Note that a file is only actually written in the temporary directory if the file
does not already exist, or the last modified time of the problem file is sooner
than the last modified time of existing temporary file, or the set is an
undefined set (for instance, the problem is loaded from the library browser), or
C<$refreshCachedImages> is true.

=cut

sub insertGraph {
	my ($self, $graph) = @_;

	my $fileName = $graph->imageName . '.' . $graph->ext;
	my $filePath = $self->surePathToTmpFile("images/$fileName");

	# Check to see if we already have this graph, or if we have to make it.
	if (!-e $filePath
		|| (stat "$self->{envir}{templateDirectory}$self->{envir}{probFileName}")[9] > (stat $filePath)[9]
		|| $self->{envir}{setNumber} =~ /Undefined_Set/
		|| $self->PG_restricted_eval(q!$refreshCachedImages!))
	{
		my $graphData = $graph->draw;
		if ($graphData) {
			WeBWorK::PG::IO::saveDataToFile($graphData, $filePath);
		} else {
			warn "Error generating graph for $filePath";
		}
	}
	return $filePath;
}

=head2 getUniqueName

	# Returns a unique file name for use in the problem
	$name = getUniqueName('png');

getUniqueName generates a unique file name for use in a problem.  Its single
argument is the file type.  This is used internally by PGgraphmacros.pl and
PGtikz.pl.

=cut

# Generate a unique file name in a problem based on the user, seed, set
# number, and problem number.
sub getUniqueName {
	my $self     = shift;
	my $ext      = shift;
	my $num      = ++$self->{names_created};
	my $resource = $self->{PG_alias}->make_resource_object("name$num", $ext);
	$resource->path("__");
	return $resource->create_unique_id;
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

sub surePathToTmpFile {
	# constructs intermediate directories if needed beginning at ${Global::htmlDirectory}tmp/
	# the input path must be either the full path, or the path relative to this tmp sub directory

	my $self         = shift;
	my $path         = shift;
	my $delim        = "/";
	my $tmpDirectory = $self->tempDirectory();
	unless (-e $tmpDirectory) {    # if by some unlucky chance the tmpDirectory hasn't been created, create it.
		my $parentDirectory = $tmpDirectory;
		$parentDirectory =~ s|/$||;    # remove a trailing /
		$parentDirectory = $self->directoryFromPath($parentDirectory);
		my ($perms, $groupID) = (stat $parentDirectory)[ 2, 5 ];
		#warn "Creating tmp directory at $tmpDirectory, perms $perms groupID $groupID";
		WeBWorK::PG::IO::createDirectory($tmpDirectory, $perms, $groupID)
			or warn "Failed to create parent tmp directory at $path";

	}
	# use the permissions/group on the temp directory itself as a template
	my ($perms, $groupID) = (stat $tmpDirectory)[ 2, 5 ];
	#warn "surePathToTmpFile: directory=$tmpDirectory, perms=$perms, groupID=$groupID\n";

	# if the path starts with $tmpDirectory (which is permitted but optional) remove this initial segment
	$path =~ s|^$tmpDirectory|| if $path =~ m|^$tmpDirectory|;

	# Find the nodes on the given path. Any ".." elements in the path are remove to prevent
	# someone from trying to write to a file outside the temporary directory.
	my @nodes = grep { $_ ne '..' } split("$delim", $path);

	# create new path
	$path = $tmpDirectory;

	while (@nodes > 1) {
		$path = $path . shift(@nodes) . "/";

		unless (-e $path) {
			WeBWorK::PG::IO::createDirectory($path, $perms, $groupID)
				or $self->warning_message(
					"Failed to create directory at $path with permissions $perms and groupID $groupID");
		}

	}

	$path = $path . shift(@nodes);
	return $path;
}

=head1 Macros from IO.pm

		includePGtext
		read_whole_problem_file
		fileFromPath
		directoryFromPath

=cut

sub maketext {
	my $self = shift;
	# uncomment this to check to see if strings are run through
	# maketext.
	# return 'xXx'.  &{ $self->{maketext}}(@_).'xXx';
	&{ $self->{maketext} }(@_);
}

sub includePGtext {
	my $self = shift;
	WeBWorK::PG::IO::includePGtext(@_);
}

sub read_whole_problem_file {
	my $self = shift;
	WeBWorK::PG::IO::read_whole_problem_file(@_);
}

sub fileFromPath {
	my $self = shift;
	WeBWorK::PG::IO::fileFromPath(@_);
}

sub directoryFromPath {
	my $self = shift;
	WeBWorK::PG::IO::directoryFromPath(@_);
}

sub AskSage {
	my $self    = shift;
	my $python  = shift;
	my $options = shift;
	$options->{curlCommand} = WeBWorK::PG::IO::externalCommand('curl');
	WeBWorK::PG::IO::AskSage($python, $options);
}

sub tempDirectory {
	my $self = shift;
	return "$WeBWorK::PG::IO::pg_envir->{directories}{html_temp}/";
}

=head1 Message channels

There are two message channels
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
	my ($self, @str) = @_;
	push @{ $self->{DEBUG_messages} }, @str;
}

sub get_debug_messages {
	my $self = shift;
	$self->{DEBUG_messages};
}

sub warning_message {
	my ($self, @str) = @_;
	push @{ $self->{WARNING_messages} }, @str;
}

sub get_warning_messages {
	my $self = shift;
	$self->{WARNING_messages};
}

sub internal_debug_message {
	my ($self, @str) = @_;
	push @$internal_debug_messages, @str;
}

sub get_internal_debug_messages {
	my $self = shift;
	$internal_debug_messages;
}

sub clear_internal_debug_messages {
	my $self = shift;
	$internal_debug_messages = [];
}

sub DESTROY {
	# doing nothing about destruction, hope that isn't dangerous
}

1;
