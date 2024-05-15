################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2024 The WeBWorK Project, https://github.com/openwebwork
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

    HEADER_TEXT(...);       # (optional) used only for inserting javaScript into problems.

    TEXT(                   # insert text of problems
        "Problem text to be displayed. ",
        "Enter 1 in this blank:",
        ans_rule(30)        # ans_rule(30) defines an answer blank 30 characters long.
                            # It is defined in PGbasicmacros.pl.
    );

    ANS(answer_evalutors);  # see PGanswermacros.pl for examples of answer evaluatiors.

    ENDDOCUMENT()           # must be the last statement in the problem

=head1 DESCRIPTION

This file provides the fundamental macros that define the PG language. It
maintains a problem's text, header text, and answers:

=over

=item *

Problem text: The text to appear in the body of the problem. See L</TEXT>
below.

=item *

Header text: When a problem is processed in an HTML-based display mode, this
variable can contain text that the caller should place in the HEAD of the
resulting HTML page. See L</HEADER_TEXT> below.

=item *

Implicitly labeled answers: Answers that have not been explicitly assigned
names, and are associated with their answer blanks by the order in which they
appear in the problem. These types of answers are designated using the L</ANS>
macro.

=item *

Explicitly labeled answers: Answers that have been explicitly assigned names
with the L</NAMED_ANS> macro, or a macro that uses it. An explicitly labeled
answer is associated with its answer blank by name.

=item *

"Extra" answers: Names of answer blanks that do not have a 1-to-1 correspondence
to an answer evaluator. For example, in matrix problems, there will be several
input fields that correspond to the same answer evaluator.

=back

=head1 MACROS

This file is automatically loaded into the namespace of every PG problem. The
macros within can then be called to define the structure of the problem.

=cut

sub _PG_init {
	$main::VERSION = "PG-2.15";

	#
	#  Set up MathObject context for use in problems
	#  that don't load MathObjects.pl
	#
	%main::context = ();
	Parser::Context->current(\%main::context);
}

our $PG;

sub not_null { $PG->not_null(@_) }

sub pretty_print {
	my ($input, $display_mode, $print_level) = @_;
	$PG->pretty_print($input, $display_mode // $main::displayMode, $print_level // 5);
}

sub encode_pg_and_html { PGcore::encode_pg_and_html(@_) }

sub DEBUG_MESSAGE {
	my @msg = @_;
	$PG->debug_message("---- " . join(" ", caller()) . " ------", @msg, "__________________________");
}

sub WARN_MESSAGE {
	my @msg = @_;
	$PG->warning_message("---- " . join(" ", caller()) . " ------", @msg, "__________________________");
}

=head2 DOCUMENT

C<DOCUMENT()> should be the first executable statement in any problem. It
initializes variables and defines the problem environment.

=cut

sub DOCUMENT {
	# get environment
	$rh_envir = \%envir;      #KLUDGE FIXME
							  # warn "rh_envir is ",ref($rh_envir);
	$PG       = new PGcore(
		$rh_envir,            # can add key/value options to modify
	);
	$PG->clear_internal_debug_messages;
	# initialize main:: variables

	$ANSWER_PREFIX             = $PG->{ANSWER_PREFIX};
	$QUIZ_PREFIX               = $PG->{QUIZ_PREFIX};
	$showPartialCorrectAnswers = $PG->{flags}->{showPartialCorrectAnswers};
	$solutionExists            = $PG->{flags}->{solutionExists};
	$hintExists                = $PG->{flags}->{hintExists};
	$pgComment                 = '';
	%external_refs             = %{ $PG->{external_refs} };

	@KEPT_EXTRA_ANSWERS = ();    #temporary hack

	my %envir = %$rh_envir;
	# Save the file name for use in error messages

	#no strict;
	foreach my $var (keys %envir) {
		PG_restricted_eval(qq!\$main::$var = \$envir{$var}!)
			;    #whew!! makes sure $var is interpolated but $main:: is evaluated at run time.
		warn "Problem defining $var  while initializing the PG problem: $@" if $@;
	}

	$displayMode         = $PG->{displayMode};
	$problemSeed         = $PG->{problemSeed};
	$PG_random_generator = $PG->{PG_random_generator};
	#warn "{inputs_ref}->{problemSeed} =",$inputs_ref->{problemSeed} if $inputs_ref->{problemSeed};
	#warn "{inputs_ref}->{displayMode} =",$inputs_ref->{displayMode} if $inputs_ref->{displayMode};
	#warn "displayMode $displayMode";
	#warn "problemSeed $problemSeed";
	$inputs_ref->{problemSeed} = '';    #this version of the problemSeed is tainted. It can be set by a student
	$inputs_ref->{displayMode} = '';    # not sure whether this should ever by used or not.

	load_css();
	load_js();
}

$main::displayMode = $PG->{displayMode};
$main::PG          = $PG;

=head2 TEXT

C<TEXT()> concatenates its arguments and appends them to the stored problem text
string. It is used to define the text which will appear in the body of the
problem. It can be used more than once in a file. For example,

    TEXT("string1", "string2", "string3");

This macro has no effect if rendering has been stopped with the
C<STOP_RENDERING()> macro.

This macro defines text which will appear in the problem. All text must be
passed to this macro, passed to another macro that calls this macro, or included
via a BEGIN_TEXT/END_TEXT or BEGIN_PGML/END_PGML block which uses this macro
internally. No other statements in a PG file will directly appear in the output.
Think of this as the "print" function for the PG language.

Spaces are placed between the arguments during concatenation, but no spaces are
introduced between the existing content of the header text string and the new
content being appended.

=cut

sub TEXT {
	$PG->TEXT(@_);
}

=head2 HEADER_TEXT

C<HEADER_TEXT()> concatenates its arguments and appends them to the stored
header text string. It can be used more than once in a file. For example,

    HEADER_TEXT("string1", "string2", "string3");

The macro is used for material which is destined to be placed in the HEAD of
the page when in HTML mode, such as JavaScript code.

Spaces are placed between the arguments during concatenation, but no spaces are
introduced between the existing content of the header text string and the new
content being appended.

=cut

sub HEADER_TEXT {
	$PG->HEADER_TEXT(@_);
}

=head2 POST_HEADER_TEXT

DEPRECATED

Content added by this method is appended just after the page head. This method
should no longer be used. There is no valid reason to add content after the
page head, and not in the problem itself.

=cut

sub POST_HEADER_TEXT {
	$PG->POST_HEADER_TEXT(@_);
}

=head2 SET_PROBLEM_LANGUAGE

Valid HTML language codes are expected, but a region code or other settings may
be included. See L<https://www.w3.org/International/questions/qa-choosing-language-tags>.

    SET_PROBLEM_LANGUAGE($language)

Example language codes: en-US, en-UK, he-IL

Some special language codes (e.g. zh-Hans) are longer. See the following
references.

=over

=item *

L<http://www.rfc-editor.org/rfc/bcp/bcp47.txt>

=item *

L<https://www.w3.org/International/articles/language-tags/>

=item *

L<https://www.w3.org/International/questions/qa-lang-2or3.en.html>

=item *

L<http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry>

=item *

L<https://www.w3schools.com/tags/ref_language_codes.asp>

=item *

L<https://www.w3schools.com/tags/ref_country_codes.asp>

=back

There is a tester located at L<https://r12a.github.io/app-subtags/>

=cut

sub SET_PROBLEM_LANGUAGE {
	my $requested_lang = shift;

	# Clean it up for safety
	my $selected_lang = $requested_lang;
	$selected_lang =~ s/[^a-zA-Z0-9-]//g;    # Drop any characters not permitted.

	if ($selected_lang ne $requested_lang) {
		warn "PROBLEM_LANGUAGE was edited. Requested: $requested_lang which was replaced by $selected_lang";
	}
	$PG->{flags}->{"language"} = $selected_lang;
}

=head2 SET_PROBLEM_TEXTDIRECTION

Call C<SET_PROBLEM_TEXTDIRECTION> to set the HTML C<dir> attribute to be applied
to the C<div> element containing the problem.

    SET_PROBLEM_TEXTDIRECTION($dir)

Only valid settings for the HTML C<dir> attribute are permitted.

    dir="ltr|rtl|auto"

See L<https://www.w3schools.com/tags/att_global_dir.asp>.

It is likely that only problems written in RTL scripts will need to call the
following function to set the base text direction for the problem.

Note the flag may not be set, and then the default behavior will be used.

=cut

sub SET_PROBLEM_TEXTDIRECTION {
	my $requested_dir = shift;

	# Only allow valid values:

	if ($requested_dir =~ /^ltr$/i) {
		$PG->{flags}->{"textdirection"} = "ltr";
	} elsif ($requested_dir =~ /^rtl$/i) {
		$PG->{flags}->{"textdirection"} = "rtl";
	} elsif ($requested_dir =~ /^auto$/i) {
		$PG->{flags}->{"textdirection"} = "auto";    # NOT RECOMMENDED
	} else {
		warn " INVALID setting for PROBLEM_TEXTDIRECTION: $requested_dir was DROPPED.";
	}
}

=head2 ADD_CSS_FILE

Request that the problem HTML page also include additional CSS files from the
C<pg/htdocs> directory or from an external location.

	ADD_CSS_FILE($file, $external);

If external is 1, it is assumed the full URL is provided. If external is 0 or
not given, then file will be served from the C<pg/htdocs> directory (if found).

For example:

	ADD_CSS_FILE("css/rtl.css");
	ADD_CSS_FILE("https://external.domain.com/path/to/file.css", 1);

=cut

sub ADD_CSS_FILE {
	my ($file, $external) = @_;
	push(@{ $PG->{flags}{extra_css_files} }, { file => $file, external => $external });
}

# This loads the basic css needed by pg.
# It is expected that the requestor will also load the styles for Bootstrap.
# Some problems use jquery-ui still, and so the requestor should also load the css for that if those problems are used,
# although those problems should also be rewritten to not use jquery-ui.
sub load_css() {
	ADD_CSS_FILE('js/Problem/problem.css');
	ADD_CSS_FILE('js/Knowls/knowl.css');
	ADD_CSS_FILE('js/ImageView/imageview.css');

	if ($envir{useMathQuill}) {
		ADD_CSS_FILE('node_modules/mathquill/dist/mathquill.css');
		ADD_CSS_FILE('js/MathQuill/mqeditor.css');
	} elsif ($envir{useMathView}) {
		ADD_CSS_FILE('js/MathView/mathview.css');
	}
}

=head2 ADD_JS_FILE

Request that the problem HTML page also include additional JavaScript files from
the C<pg/htdocs> directory or from an external location.

	ADD_JS_FILE($file, $external);

If external is 1, it is assumed the full URL is provided. If external is 0 or
not given, then file name will be served from the C<pg/htdocs> directory (if
found).

Additional attributes can be passed as a hash reference in the optional third
argument. These attributes will be added as attributes to the script tag.

For example:

	ADD_JS_FILE("js/Base64/Base64.js");
	ADD_JS_FILE("https://cdn.geogebra.org/apps/deployggb.js", 1);
	ADD_JS_FILE("js/GraphTool/graphtool.js", 0, { id => "gt_script", defer => undef });

=cut

sub ADD_JS_FILE {
	my ($file, $external, $attributes) = @_;
	push(@{ $PG->{flags}{extra_js_files} }, { file => $file, external => $external, attributes => $attributes });
}

# This loads the basic javascript needed by pg.
# It is expected that the requestor will also load MathJax, Bootstrap, and jquery.
# Some problems use jquery-ui still, and so the requestor should also load the js for that if those problems are used,
# although those problems should also be rewritten to not use jquery-ui.
sub load_js() {

	ADD_JS_FILE('js/Feedback/feedback.js',         0, { defer => undef });
	ADD_JS_FILE('js/Base64/Base64.js',             0, { defer => undef });
	ADD_JS_FILE('js/Knowls/knowl.js',              0, { defer => undef });
	ADD_JS_FILE('js/Problem/details-accordion.js', 0, { defer => undef });
	ADD_JS_FILE('js/ImageView/imageview.js',       0, { defer => undef });
	ADD_JS_FILE('js/Essay/essay.js',               0, { defer => undef });

	if ($envir{useMathQuill}) {
		ADD_JS_FILE('node_modules/mathquill/dist/mathquill.js', 0, { defer => undef });
		ADD_JS_FILE('js/MathQuill/mqeditor.js',                 0, { defer => undef });
	} elsif ($envir{useMathView}) {
		ADD_JS_FILE("js/MathView/$envir{mathViewLocale}", 0, { defer => undef });
		ADD_JS_FILE('js/MathView/mathview.js',            0, { defer => undef });
	}
}

sub AskSage {
	my $python  = shift;
	my $options = shift;
	WARN_MESSAGE("the second argument to AskSage should be a hash of options") unless $options =~ /HASH/;
	$PG->AskSage($python, $options);
}

# sageReturnedFail checks to see if the return from Sage indicates some kind of failure
# undefined means old style return (a simple string) failed
# $obj->{success} defined but equal to zero means that the failed return and error
# messages are encoded in the $obj hash.
sub sageReturnedFail {
	my $obj = shift;
	return (not defined($obj) or (defined($obj->{success}) and $obj->{success} == 0));
}

=head2 NAMED_ANS

Associates answer names with answer evaluators.  If the given anwer name has a
response group in the PG_ANSWERS_HASH, then the evaluator is added to that
response group.  Otherwise the name and evaluator are added to the hash of
explicitly named answer evaluators.  They will be paired with exlplicitly
named answer rules by name. This allows pairing of answer evaluators and
answer rules that may not have been entered in the same order.

An example of the usage is:

    TEXT(NAMED_ANS_RULE("name1"), NAMED_ANS_RULE("name2"));
    NAMED_ANS(name1 => answer_evaluator1, name2 => answer_evaluator2);

=cut

sub NAMED_ANS {
	my @in = @_;
	$PG->NAMED_ANS(@in);
}

=head2 LABELED_ANS

Alias for NAMED_ANS

=cut

sub LABELED_ANS {
	my @in = @_;
	NAMED_ANS(@in);
}

=head2 ANS

Registers answer evaluators to be implicitly associated with answer names.  If
there is an answer name in the implicit answer name stack, then a given answer
evaluator will be paired with the first name in the stack.  Otherwise the
evaluator will be pushed onto the implicit answer evaluator stack.  This is the
standard method for entering answers.

An example of the usage is:

    TEXT(ans_rule(), ans_rule(), ans_rule());
    ANS($answer_evaluator1, $answer_evaluator2, $answer_evaluator3);

In the above example, C<answer_evaluator1> will be associated with the first
answer rule, C<answer_evaluator2> with the second, and C<answer_evaluator3> with
the third. In practice, the arguments to C<ANS()> will usually be calls to an
answer evaluator generator such as the C<cmp()> method of MathObjects or the
C<num_cmp()> macro in L<PGanswermacros.pl>.

=cut

sub ANS {
	$PG->ANS(@_);
}

=head2 RECORD_ANS_NAME

Records the name for an answer blank. Used internally by L<PGbasicmacros.pl> to
record the order of answer blanks.  All answer blanks must eventually be
recorded via this method.

    RECORD_ANS_NAME('name', 'VALUE');

=cut

sub RECORD_ANS_NAME {
	my ($name, $value) = @_;
	return $PG->record_ans_name($name, $value);
}

=head2 RECORD_IMPLICIT_ANS_NAME

Records the name for an answer blank that is implicitly named. Used
internally by L<PGbasicmacros.pl> to record the order of answer blanks that are
implicitly nameed. This must also be called by a macro for answer blanks
created by it that need to be implicitly named.

    RECORD_IMPLICIT_ANS_NAME('name');

=cut

sub RECORD_IMPLICIT_ANS_NAME {
	my ($name) = @_;
	return $PG->record_implicit_ans_name($name);
}

sub ans_rule_count {
	scalar keys %{ $PG->{PG_ANSWERS_HASH} };
}

=head2 NEW_ANS_NAME

Generates an anonymous answer name from the internal count. This method takes
no arguments.

=cut

sub NEW_ANS_NAME {
	return $PG->new_ans_name;
}

=head2 ANS_NUM_TO_NAME

Generates an answer name from the supplied answer number, but does not add it
to the list of implicitly-named answers.  This is deprecated, and most likely
will not give something useful.

    ANS_NUM_TO_NAME($num);

=cut

sub ANS_NUM_TO_NAME {
	$PG->new_label(@_);
}

sub store_persistent_data {
	my ($label, @values) = @_;
	$PG->store_persistent_data($label, @values);
}

sub update_persistent_data {
	my ($label, @values) = @_;
	$PG->update_persistent_data($label, @values);
}

sub get_persistent_data {
	my ($label) = @_;
	return $PG->get_persistent_data($label);
}

sub add_content_post_processor {
	my $handler = shift;
	$PG->add_content_post_processor($handler);
	return;
}

=head2 RECORD_FORM_LABEL

Stores the name of a form field in the "extra" answers list. This is used to
keep track of answer blanks that are not associated with an answer evaluator.

    RECORD_FORM_LABEL("name");

=cut

# This stores form data (such as sticky answers), but does nothing more.
# It's a bit of hack since we are storing these in the
# KEPT_EXTRA_ANSWERS queue even if they aren't answers per se.
sub RECORD_FORM_LABEL {
	RECORD_EXTRA_ANSWERS(@_);
}

sub RECORD_EXTRA_ANSWERS {
	my $label = shift;
	# Put the labels into the hash to be caught later for recording purposes.
	eval(q!push(@main::KEPT_EXTRA_ANSWERS, $label)!);
	return $label;
}

=head2 NEW_ANS_ARRAY_NAME_EXTENSION

Generate an additional answer name for an existing array (vector) element and
add it to the list of "extra" answers.

    NEW_ANS_ARRAY_NAME_EXTENSION($row, $col);

=cut

# Creates a new array element answer name and records it.
sub NEW_ANS_ARRAY_NAME_EXTENSION {
	my $row_num = shift;
	my $col_num = shift;
	if ($row_num == 0 && $col_num == 0) {
		$main::vecnum += 1;
	}
	my $ans_label         = $PG->new_ans_name();
	my $element_ans_label = $PG->new_array_element_label($ans_label, $row_num, $col_num, vec_num => $vecnum);
	my $response          = new PGresponsegroup($ans_label, $element_ans_label, undef);
	$PG->extend_ans_group($ans_label, $response);
	return $element_ans_label;
}

sub CLEAR_RESPONSES {
	my $ans_label = shift;
	if (defined $PG->{PG_ANSWERS_HASH}{$ans_label}) {
		my $responsegroup = $PG->{PG_ANSWERS_HASH}{$ans_label}{response};
		if (ref($responsegroup)) {
			$responsegroup->clear;
		} else {
			$responsegroup = $PG->{PG_ANSWERS_HASH}{$ans_label}{response} = new PGresponsegroup($label);
		}
	}
	return;
}

#FIXME -- examine the difference between insert_response and extend_response
sub INSERT_RESPONSE {
	my ($ans_label, $response_label, $ans_value, $selected) = @_;
	if (defined($PG->{PG_ANSWERS_HASH}{$ans_label})) {
		my $responsegroup = $PG->{PG_ANSWERS_HASH}{$ans_label}{response};
		$responsegroup->append_response($response_label, $ans_value, $selected);
	}
	return;
}

# For radio buttons and checkboxes.
sub EXTEND_RESPONSE {
	my ($ans_label, $response_label, $ans_value, $selected) = @_;
	if (defined($PG->{PG_ANSWERS_HASH}->{$ans_label})) {
		my $responsegroup = $PG->{PG_ANSWERS_HASH}->{$ans_label}->{response};
		$responsegroup->extend_response($response_label, $ans_value, $selected);
	}
	return;
}

=head2 ENDDOCUMENT

When PG problems are evaluated, the result of evaluating the entire problem is
interpreted as the return value of C<ENDDOCUMENT()>. Furthermore, a post
processing hook is added that injects feedback into the problem text.
Therefore, C<ENDDOCUMENT()> must be the last executable statement of every
problem. It can only appear once. It returns a list consisting of:

=over

=item *

A reference to a string containing the rendered text of the problem.

=item *

A reference to a string containing text to be placed in the HEAD block
when in and HTML-based mode (e.g. for JavaScript).

=item *

A reference to a string containing text to be placed immediately after the HEAD
block when in and HTML-based mode.

=item *

A reference to the hash mapping answer names to answer evaluators.

=item *

A reference to a hash containing various flags.  This includes the following
flags:

=over

=item *

C<showPartialCorrectAnswers>: determines whether students are told which of
their answers in a problem are wrong.

=item *

C<recordSubmittedAnswers>: determines whether students submitted answers are
saved.

=item *

C<refreshCachedImages>: determines whether the cached image of the problem in
typeset mode is always refreshed (i.e. setting this to 1 means cached images are
not used).

=item *

C<solutionExits>: indicates the existence of a solution.

=item *

C<hintExits>: indicates the existence of a hint.

=item *

C<comment>: contents of COMMENT commands if any.

=item *

C<PROBLEM_GRADER_TO_USE>: a reference to the chosen problem grader.
C<ENDDOCUMENT> chooses the problem grader as follows:

=over

=item *

If a problem grader has been chosen in the problem by calling
C<install_problem_grader(\&grader)>, it is used.

=item *

Otherwise, if the C<PROBLEM_GRADER_TO_USE> PG environment variable contains a
reference to a subroutine, it is used.

=item *

Otherwise, if the C<PROBLEM_GRADER_TO_USE> PG environment variable contains the
string C<std_problem_grader> or the string C<avg_problem_grader>,
C<&std_problem_grader> or C<&avg_problem_grader> are used. These graders are
defined in L<PGanswermacros.pl>.

=item *

Otherwise, the C<PROBLEM_GRADER_TO_USE> flag will contain an empty value and the
PG translator should select C<&std_problem_grader>.

=back

=back

=item *

A reference to the C<PGcore> object for this problem.

=back

The post processing hook added in this method adds a feedback button for each
answer response group that when clicked opens a popover containing feedback for
the answer. A result class is also added to each C<feedbackElement> (see this
option below) for coloring answer rules via CSS. In addition visually hidden
spans are added that provide feedback for screen reader users. Each
C<feedbackElement> will be C<aria-describedby> these spans.

When and what feedback is shown is determined by translator options described in
L<WeBWorK::PG/OPTIONS> as well as options described below. The hook handles
standard answer types effectively, but macros that add special answer types and
in some case problems (particularly those that use C<MultiAnswer> questions with
C<singleResult> true) may need to help the method for proper placement of the
feedback button and other aspects of feedback.

There are several options that can be modified, and a few different ways to make
these modifications. Unfortunately, this is perhaps a little bit complicated to
understand, and that really can not be helped. The reason for this is the
extremely loose connection between answer rules, answer labels, and answer
evaluators in PG.

How these options are set can be controlled in three ways.

First, an answer hash can have the C<feedback_options> key set to a CODE
reference. If this is the case, then the subroutine referenced by this key will
be called and passed the answer hash itself, a reference to the hash of options
described below (any of which can be modified by this subroutine), and a
Mojo::DOM object containing the problem text. Note that if this method sets the
C<insertElement> option, then the other ways of controlling how these options
are set will not be used.

Second, an element can be added to the DOM that contains an answer rule that has
the class C<ww-feedback-container>, and if that answer rule is initially chosen
to be the C<insertElement> and that is not set by the C<feedback_options>
method, then this added element will replace it as the C<insertElement>.

Third, data attributes may be added to elements in the DOM will affect where the
feedback button will be placed. The following data attributes are honored.

=over

=item *

C<data-feedback-insert-element>: If an element in the DOM has this data
attribute and the value of this attribute is the answer name (or label), then
the element that has this data attribute will be used for the C<insertElement>
option described below.

=item *

C<data-feedback-insert-method>: If the C<insertElement> is not set by the
C<feedback_options> method of the answer hash, and the C<insertElement> also has
this attribute, then the value of this attribute will be used for the
C<insertMethod> option described below.

=item *

C<data-feedback-btn-add-class>: If the C<insertElement> is not set by the
C<feedback_options> method of the answer hash, and the C<insertElement> also has
this attribute, then the value of this attribute will be used for the
C<btnAddClass> option described below.

=back

The options that can be modified are as follows.

=over

=item *

C<resultTitle>: This is the title that is displayed in the feedback popover for
the answers in the response group. By default this is "Answer Preview",
"Correct", "Incorrect", or "n% correct", depending on the status of the answer
and the type of submission. Those strings are translated via C<maketext>.
Usually this should not be changed, but in some cases the default status titles
are not appropriate for certain types of answers. For example, the
L<PGessaymacros.pl> macros changes this to "Ungraded" for essay answers.

=item *

C<resultClass>: This is the CSS class that is added to each answer input in the
response group. By default it is set to the empty string, "correct",
"incorrect", or "partially-correct" depending on the status of the answer and
the type of submission.

=item *

C<btnClass>: This is the bootstrap button class added to the feedback button.
By default it is "btn-info", "btn-success", "btn-danger", or "btn-warning"
depending on the status of the answer and the type of submission.

=item *

C<btnAddClass>: This is a string containing additional space separated CSS
classes to add to the feedback button. This is "ms-2" by default. Macros can
change this to affect positioning of the button. This generally should not be
used to change the appearance of the button.

=item *

C<feedbackElements>: This is a Mojo::Collection of elements in the DOM to which
the feedback C<resultClass> and C<aria-describedby> attribute will be added. By
default this is all elements in the DOM that have a name in the list of response
labels for the response group. Note that for radio buttons and checkboxes, only
the checked elements will be in this collection by default.

=item *

C<insertElement>: This is the element in the DOM to insert the feedback button
in or around. How the element is inserted is determined by the C<insertMethod>
option.  How this option is set is slightly complicated. First, if this option
is set by the answer hash C<feedback_options> method, then that is used. If the
C<feedback_options> method does not exist or does not set this option, then
initially the last C<feedbackElement> is used for this. However, if that last
C<feedbackElement> is contained in another DOM element that has the
C<ww-feedback-container> class, then that is used for this instead. If such a
container is not found and there is an element in the DOM that has the
C<data-feedback-insert-element> attribute set whose value is equal to the name
of this last C<feedbackElement>, then that element is used for the
C<insertElement> instead. Finally, if the C<insertElement> determined as just
described happens to be a radio button or checkbox, then the C<insertElement>
will instead be the parent of the radio button or checkbox (which will hopefully
be the label for that input).

=item *

C<insertMethod>: The Mojo::DOM method to use to insert the feedback button
relative to the C<insertElement>. It can be C<append> (insert after the
C<insertElement>), C<append_content> (insert as the last child of
C<insertElement>), C<prepend> (insert before C<insertElement>), or
C<prepend_content> (insert as the first child of C<insertElement>).

=item *

C<wrapPreviewInTex>: This is a boolean value that is 1 by default. If true and
the display mode is HTML_MathJax, then the answer previews are wrapped in a
math/tex type script tag.

=item *

C<showEntered>: This is a boolean value that is 1 by default. If true and the
translator option C<showAttemptAnswers> is also true, then the student's
evaluated (or "Entered") answer is shown in the feedback popover if the student
has entered an answer.

=item *

C<showPreview>: This is a boolean value that is 1 by default. If true and the
translator option C<showAttemptPreviews> is also true, then a preview of the
student's answer is shown in the feedback popover. Most likely this should
always be true, and most likely this option (and the translator option)
shouldn't even exist!

=item *

C<showCorrect>: This is a boolean value that is 1 by default. If this is true
and the translator option C<showCorrectAnswers> is nonzero, then a preview of
the correct answer is shown in the feedback popover. In other words, this option
prevents showing correct answers even if the frontend requests that correct
answers be shown.

=item *

C<answerGiven>: This is a boolean value. This should be true if a student has
answered a question, and false otherwise. By default this is set to 1 if the
responses for all answers in the response group are non-empty, and 0 otherwise.
For radio buttons and checkboxes this is if one of the inputs are checked or
not. However, for some answers a non-empty response can occur even if a student
has not answered a question (for example, this occurs for answers to questions
created with the L<draggableProof.pl> macro) . So macros that create answers
with responses like that should override this.

=item *

C<manuallyGraded>: This is a boolean value. This should be true if the answer is
not graded by the PG problem grader, but is graded manually at a later time, and
should be false if the PG problem grader sets the grade for this answer. For
example, essay answers created by the PGessaymacros.pl macro set this to true.

=item *

C<needsGrading>: This is a boolean value. This should be true if the answer is
not graded by the PG problem grader, but is graded manually at a later time, and
the answer has changed.

=back

=cut

sub ENDDOCUMENT {
	# Insert MathQuill responses if MathQuill is enabled.  Add responses to each answer's response group that store the
	# latex form of the students' answers and add corresponding hidden input boxes to the page.
	if ($envir{useMathQuill} && $main::displayMode =~ /HTML/i) {
		for my $answerLabel (keys %{ $PG->{PG_ANSWERS_HASH} }) {
			my $answerGroup = $PG->{PG_ANSWERS_HASH}{$answerLabel};
			my $mq_opts     = $answerGroup->{ans_eval}{rh_ans}{mathQuillOpts} // {};

			# This is a special case for multi answers.  This is used to obtain mathQuillOpts set
			# specifically for individual parts.
			my $multiAns;
			my $part;
			if ($answerGroup->{ans_eval}{rh_ans}{type} =~ /MultiAnswer(?:\((\d*)\))?/) {
				# This will only be set if singleResult is not enabled.
				$part = $1;
				# The MultiAnswer object passes itself as the first optional argument to the evaluator it creates.
				# Loop through the evaluators to find it.
				for (@{ $answerGroup->{ans_eval}{evaluators} }) {
					$multiAns = $_->[1] if (ref($_->[1]) && ref($_->[1]) eq "parser::MultiAnswer");
				}
				# Pass the mathQuillOpts of the main MultiAnswer object on to each part
				# (unless the part already has the option set).
				if (defined $multiAns) {
					for (@{ $multiAns->{cmp} }) {
						$_->rh_ans(mathQuillOpts => $mq_opts) unless defined $_->{rh_ans}{mathQuillOpts};
					}
				}
			}

			next if $mq_opts =~ /^\s*disabled\s*$/i;

			my $response_obj  = $answerGroup->response_obj;
			my $responseCount = -1;
			for my $response ($response_obj->response_labels) {
				++$responseCount;
				next if ref($response_obj->{responses}{$response});

				my $ansHash =
					defined $multiAns
					? $multiAns->{cmp}[ $part // $responseCount ]{rh_ans}
					: $answerGroup->{ans_eval}{rh_ans};
				my $mq_part_opts = $ansHash->{mathQuillOpts} // $mq_opts;
				next if $mq_part_opts =~ /^\s*disabled\s*$/i;

				my $context = $ansHash->{correct_value}->context if $ansHash->{correct_value};
				$mq_part_opts->{rootsAreExponents} = 0
					if $context && $context->functions->get('root') && !defined $mq_part_opts->{rootsAreExponents};

				my $name = "MaThQuIlL_$response";
				RECORD_EXTRA_ANSWERS($name);

				add_content_post_processor(sub {
					my $problemContents = shift;
					my $input           = $problemContents->at(qq{input[name="$response"]})
						|| $problemContents->at(qq{textarea[name="$response"]});
					return unless $input;
					$input->append(
						Mojo::DOM->new_tag(
							'input',
							type  => 'hidden',
							name  => $name,
							id    => $name,
							value => $inputs_ref->{$name} // '',
							scalar(keys %$mq_part_opts)
							? (data => { mq_opts => JSON->new->encode($mq_part_opts) })
							: ''
						)->to_string
					);
				});
			}
		}
	}

	# Gather flags
	$PG->{flags}{showPartialCorrectAnswers} = $showPartialCorrectAnswers // 1;
	$PG->{flags}{recordSubmittedAnswers}    = $recordSubmittedAnswers    // 1;
	$PG->{flags}{refreshCachedImages}       = $refreshCachedImages       // 0;
	$PG->{flags}{hintExists}                = $hintExists                // 0;
	$PG->{flags}{solutionExists}            = $solutionExists            // 0;
	$PG->{flags}{comment}                   = $pgComment                 // '';

	if ($main::displayMode =~ /HTML/i && ($rh_envir->{showFeedback} || $rh_envir->{forceShowAttemptResults})) {
		add_content_post_processor(sub {
			my $problemContents = shift;

			my $numCorrect        = 0;
			my $numBlank          = 0;
			my $numManuallyGraded = 0;
			my $needsGrading      = $rh_envir->{needs_grading};

			my @answerNames = keys %{ $PG->{PG_ANSWERS_HASH} };

			for my $answerLabel (@answerNames) {
				my $response_obj = $PG->{PG_ANSWERS_HASH}{$answerLabel}->response_obj;
				my $ansHash      = $PG->{PG_ANSWERS_HASH}{$answerLabel}{ans_eval}{rh_ans};

				my $answerScore = $ansHash->{score} // 0;

				my %options = (
					resultTitle      => maketext('Answer Preview'),
					resultClass      => '',
					btnClass         => 'btn-info',
					btnAddClass      => 'ms-2',
					feedbackElements => Mojo::Collection->new,
					insertElement    => undef,
					insertMethod     => 'append',    # Can be append, append_content, prepend, or prepend_content.
					wrapPreviewInTex => defined $ansHash->{non_tex_preview} ? !$ansHash->{non_tex_preview} : 1,
					showEntered      => 1,
					showPreview      => 1,
					showCorrect      => 1,
					answerGiven      => 0,
					manuallyGraded   => 0,
					needsGrading     => 0
				);

				# Determine if the student gave an answer to any of the questions in this response group and find the
				# inputs associated to this response group that the correct/incorrect/partially-correct feedback classes
				# will be added to.
				for my $responseLabel ($response_obj->response_labels) {
					my $response = $response_obj->get_response($responseLabel);
					my $elements = $problemContents->find(qq{[name="$responseLabel"]});

					if (ref($response) eq 'ARRAY') {
						# This is the case of checkboxes or radios.
						# Feedback classes are added only to those that are checked.
						for (@$response) { $options{answerGiven} = 1 if $_->[1] =~ /^checked$/i; }
						my $checked = $elements->grep(sub {
							my $element = $_;
							grep { $_->[0] eq $element->attr('value') && $_->[1] =~ /^checked$/i } @$response;
						});
						$elements = $checked if @$checked;
					} else {
						$options{answerGiven} = 1 if defined $response && $response =~ /\S/;
					}
					push(@{ $options{feedbackElements} }, @$elements);
				}

				my $showResults = ($rh_envir->{showAttemptResults} && $PG->{flags}{showPartialCorrectAnswers})
					|| $rh_envir->{forceShowAttemptResults};

				if ($showResults) {
					if ($answerScore >= 1) {
						$options{resultTitle} = maketext('Correct');
						$options{resultClass} = 'correct';
						$options{btnClass}    = 'btn-success';
					} elsif ($answerScore == 0) {
						$options{resultTitle} = maketext('Incorrect');
						$options{resultClass} = 'incorrect';
						$options{btnClass}    = 'btn-danger';
					} else {
						$options{resultTitle} = maketext('[_1]% correct', round($answerScore * 100));
						$options{resultClass} = 'partially-correct';
						$options{btnClass}    = 'btn-warning';
					}
				}

				# If a feedback_options method is provided, it can override anything set above.
				$ansHash->{feedback_options}->($ansHash, \%options, $problemContents)
					if ref($ansHash->{feedback_options}) eq 'CODE';

				# Update the counts.  This should be after the custom feedback_options call as that method can change
				# some of the options.  (The draggableProof.pl macro changes the answerGiven option, and the
				# PGessaymacros.pl macro changes the manuallyGraded and needsGrading options.)
				++$numCorrect        if $answerScore >= 1;
				++$numManuallyGraded if $options{manuallyGraded};
				$needsGrading = 1    if $options{needsGrading};
				++$numBlank unless $options{manuallyGraded} || $options{answerGiven} || $answerScore >= 1;

				# Don't show the results popover if there is nothing to show.
				next
					unless @{ $options{feedbackElements} }
					&& ($answerScore > 0
						|| $options{answerGiven}
						|| $ansHash->{ans_message}
						|| $rh_envir->{showCorrectAnswers});

				# Find an element to insert the button in or around if one has not been provided.
				unless ($options{insertElement}) {
					# Use the last feedback element by default.
					$options{insertElement} = $options{feedbackElements}->last;

					# Check to see if the last feedback element is contained in a feedback container. If so use that.
					# Note that this class should not be used by PG or macros directly.  It is provided for authors to
					# use as an override.
					my $ancestorContainer = $options{insertElement}->ancestors('.ww-feedback-container')->first;
					if ($ancestorContainer) {
						$options{insertElement} = $ancestorContainer;
						$options{insertMethod}  = 'append_content';
					} else {
						# Otherwise check to see if the last feedback element has a special element to attach the
						# button to defined in its data attributes, and if so use that instead.
						$options{insertElement} = $problemContents->at(
							'[data-feedback-insert-element="' . $options{insertElement}->attr('name') . '"]')
							|| $options{insertElement};
					}

					# For radio or checkbox answers place the feedback button after the label by default.
					if (lc($options{insertElement}->attr('type')) =~ /^(radio|checkbox)$/) {
						$options{btnAddClass}   = 'ms-3';
						$options{insertElement} = $options{insertElement}->parent;
					}

					# Check to see if this element has details for placement defined in its data attributes.
					$options{btnAddClass} = $options{insertElement}->attr->{'data-feedback-btn-add-class'}
						if $options{insertElement} && $options{insertElement}->attr->{'data-feedback-btn-add-class'};
					$options{insertMethod} = $options{insertElement}->attr->{'data-feedback-insert-method'}
						if $options{insertElement} && $options{insertElement}->attr->{'data-feedback-insert-method'};
				}

				# Add the correct/incorrect/partially-correct class and
				# aria-described by attribute to the feedback elements.
				for (@{ $options{feedbackElements} }) {
					$_->attr(class => join(' ', $options{resultClass}, $_->attr->{class} || ()))
						if $options{resultClass};
				}

				my $previewAnswer = sub {
					my ($preview, $wrapPreviewInTex, $fallback) = @_;

					return $fallback unless defined $preview && $preview =~ /\S/;

					if ($main::displayMode eq 'HTML' || !$wrapPreviewInTex) {
						return $preview;
					} elsif ($main::displayMode eq 'HTML_dpng') {
						return $rh_envir->{imagegen}->add($preview);
					} elsif ($main::displayMode eq 'HTML_MathJax') {
						return Mojo::DOM->new_tag('script', type => 'math/tex; mode=display', sub {$preview})
							->to_string;
					}
				};

				my $feedbackLine = sub {
					my ($title, $line, $class) = @_;
					$class //= '';
					return '' unless defined $line && $line =~ /\S/;
					return (
						$title
						? Mojo::DOM->new_tag(
							'div',
							class => 'card-header text-center p-1',
							sub { Mojo::DOM->new_tag('h4', class => 'card-title fs-6 m-0', $title); }
							)
						: ''
					) . Mojo::DOM->new_tag('div', class => "card-body text-center $class", sub {$line});
				};

				my $answerPreview = $previewAnswer->($ansHash->{preview_latex_string}, $options{wrapPreviewInTex});

				# Create the screen reader only span holding the aria description, create the feedback button and
				# popover, and insert the button at the requested location.
				my $feedback = Mojo::DOM->new_tag(
					'button',
					type  => 'button',
					class => "ww-feedback-btn btn btn-sm $options{btnClass} $options{btnAddClass}"
						. ($rh_envir->{showMessages} && $ansHash->{ans_message} ? ' with-message' : ''),
					'aria-label' => (
						$rh_envir->{showMessages} && $ansHash->{ans_message}
						? maketext('[_1] with message', $options{resultTitle})
						: $options{resultTitle}
					),
					data => {
						bs_title => Mojo::DOM->new_tag(
							'div',
							class           => 'd-flex align-items-center justify-content-between',
							'data-bs-theme' => 'dark',
							sub {
								Mojo::DOM->new_tag('span', style => 'width:20.4px')
									. Mojo::DOM->new_tag('span', class => 'mx-3', $options{resultTitle})
									. Mojo::DOM->new_tag(
										'button',
										type         => 'button',
										class        => 'btn-close',
										'aria-label' => maketext('Close')
									);
							}
						)->to_string,
						answer_label           => $answerLabel,
						bs_toggle              => 'popover',
						bs_trigger             => 'click',
						bs_placement           => 'bottom',
						bs_html                => 'true',
						bs_custom_class        => join(' ', 'ww-feedback-popover', $options{resultClass} || ()),
						bs_fallback_placements => '[]',
						bs_content             => Mojo::DOM->new_tag(
							'div',
							id => "$answerLabel-feedback",
							sub {
								Mojo::DOM->new_tag(
									'div',
									class => 'card',
									sub {
										(
											$rh_envir->{showMessages} && $ansHash->{ans_message}
											? $feedbackLine->(
												'', $ansHash->{ans_message} =~ s/\n/<br>/gr,
												'feedback-message'
												)
											: ''
											)
											. ($rh_envir->{showAttemptAnswers} && $options{showEntered}
												? $feedbackLine->(maketext('You Entered'), $ansHash->{student_ans})
												: '')
											. (
												$rh_envir->{showAttemptPreviews} && $options{showPreview}
												? $feedbackLine->(
													maketext('Preview of Your Answer'),
													(
														(defined $answerPreview && $answerPreview =~ /\S/)
														|| $rh_envir->{showAttemptAnswers}
														? $answerPreview
														: $ansHash->{student_ans}
													)
												)
												: ''
											)
											. (
												$rh_envir->{showCorrectAnswers} && $options{showCorrect}
												? do {
													my $correctAnswer = $previewAnswer->(
														$ansHash->{correct_ans_latex_string},
														$options{wrapPreviewInTex},
														$ansHash->{correct_ans}
													);
													$feedbackLine->(
														maketext('Correct Answer'),
														$rh_envir->{showCorrectAnswers} > 1
														? $correctAnswer
														: Mojo::DOM->new_tag(
															'button',
															type  => 'button',
															class => 'reveal-correct-btn btn btn-secondary btn-sm',
															maketext('Reveal')
														)
														. Mojo::DOM->new_tag(
															'div',
															class => 'd-none',
															sub {$correctAnswer}
														)
													);
												}
												: ''
											);
									}
								);
							}
						)->to_string,
					},
					sub { Mojo::DOM->new_tag('i', class => $options{resultClass}) }
				)->to_string;

				if ($options{insertElement} && $options{insertElement}->can($options{insertMethod})) {
					my $insertMethod = $options{insertMethod};
					$options{insertElement}->$insertMethod($feedback);
				}
			}

			# Generate the result summary if results are being shown.
			# FIXME: This is set up to occur when it did previously.  That is it ignores the value of
			# $PG->{flags}{showPartialCorrectAnswers}. It seems that is incorrect, as it makes that setting rather
			# pointless.  The summary still reveals if the answer is correct or not.
			if ($rh_envir->{showAttemptResults} || $rh_envir->{forceShowAttemptResults}) {
				my @summary;

				if (@answerNames == 1) {
					if ($numCorrect == 1) {
						push(
							@summary,
							Mojo::DOM->new_tag(
								'div',
								class => 'alert alert-success mb-2 p-1',
								maketext('The answer is correct.')
							)
						);
					} elsif ($numManuallyGraded) {
						push(
							@summary,
							Mojo::DOM->new_tag(
								'div',
								class => 'alert alert-info mb-2 p-1',
								$needsGrading
								? maketext('The answer will be graded later.')
								: maketext('The answer has been graded.')
							)
						);
					} elsif ($numBlank) {
						push(
							@summary,
							Mojo::DOM->new_tag(
								'div',
								class => 'alert alert-warning mb-2 p-1',
								maketext('The question has not been answered.')
							)
						);
					} else {
						push(
							@summary,
							Mojo::DOM->new_tag(
								'div',
								class => 'alert alert-danger mb-2 p-1',
								maketext('The answer is NOT correct.')
							)
						);
					}
				} else {
					if ($numCorrect + $numManuallyGraded == @answerNames) {
						if ($numManuallyGraded) {
							push(
								@summary,
								Mojo::DOM->new_tag(
									'div',
									class => 'alert alert-success mb-2 p-1',
									maketext('All of the computer gradable answers are correct.')
								)
							);
						} else {
							push(
								@summary,
								Mojo::DOM->new_tag(
									'div',
									class => 'alert alert-success mb-2 p-1',
									maketext('All of the answers are correct.')
								)
							);
						}
					} elsif ($numBlank + $numManuallyGraded + $numCorrect != @answerNames) {
						push(
							@summary,
							Mojo::DOM->new_tag(
								'div',
								class => 'alert alert-danger mb-2 p-1',
								maketext(
									'[_1] of the answers [plural,_1,is,are] NOT correct.',
									@answerNames - $numBlank - $numCorrect - $numManuallyGraded
								)
							)
						);
					}
					if ($numBlank) {
						push(
							@summary,
							Mojo::DOM->new_tag(
								'div',
								class => 'alert alert-warning mb-2 p-1',
								maketext(
									'[quant,_1,of the questions remains,of the questions remain] unanswered.',
									$numBlank
								)
							)
						);
					}
					if ($numManuallyGraded) {
						push(
							@summary,
							Mojo::DOM->new_tag(
								'div',
								class => 'alert alert-info mb-2 p-1',
								$needsGrading
								? maketext('[_1] of the answers will be graded later.', $numManuallyGraded)
								: maketext(
									'[_1] of the answers [plural,_1,has,have] been graded.',
									$numManuallyGraded
								)
							)
						);
					}
				}
				$PG->{result_summary} = join('', @summary);
			}
		});
	}

	# Install problem grader.
	# WeBWorK::PG::Translator will install its default problem grader if none of the conditions below are true.
	if (defined($PG->{flags}{PROBLEM_GRADER_TO_USE})) {
		# Problem grader defined within problem.  No further action needed.
	} elsif (defined($rh_envir->{PROBLEM_GRADER_TO_USE})) {
		if (ref($rh_envir->{PROBLEM_GRADER_TO_USE}) eq 'CODE') {
			# User defined grader.
			$PG->{flags}{PROBLEM_GRADER_TO_USE} = $rh_envir->{PROBLEM_GRADER_TO_USE};
		} elsif ($rh_envir->{PROBLEM_GRADER_TO_USE} eq 'std_problem_grader') {
			$PG->{flags}{PROBLEM_GRADER_TO_USE} = \&std_problem_grader if (defined(&std_problem_grader));
		} elsif ($rh_envir->{PROBLEM_GRADER_TO_USE} eq 'avg_problem_grader') {
			$PG->{flags}{PROBLEM_GRADER_TO_USE} = \&avg_problem_grader if (defined(&avg_problem_grader));
		} else {
			warn "Error: $PG->{flags}{PROBLEM_GRADER_TO_USE} is not a known problem grader.";
		}
	} elsif (defined(&std_problem_grader)) {
		$PG->{flags}{PROBLEM_GRADER_TO_USE} = \&std_problem_grader;
	}

	TEXT(MODES(%{ $rh_envir->{problemPostamble} }));

	if ($inputs_ref->{showResourceInfo} && $rh_envir->{show_resource_info}) {
		if (keys %{ $PG->{PG_alias}{resource_list} }) {
			$PG->debug_message(
				'<p>Resources</p><ul>' . join(
					'',
					map {
						'<li>' . knowlLink($_, value => pretty_print($PG->{PG_alias}{resource_list}{$_})) . '</li>'
					}
						sort keys %{ $PG->{PG_alias}{resource_list} }
					)
					. '</ul>'
			);
		} else {
			$PG->debug_message('No auxiliary resources.');
		}
	}

	if ($inputs_ref->{showPGInfo} && $rh_envir->{show_pg_info}) {
		my $context = $$Value::context->{flags};
		$PG->debug_message(
			"$HR<p>Form variables</p><div>" . pretty_print($inputs_ref) . '</div>',
			"$HR<p>Environment variables</p><div>" . pretty_print(\%envir) . '</div>',
			"$HR<p>Context flags</p><div>" . pretty_print($context) . '</div>'
		);
	}

	my (%PG_ANSWERS_HASH, @PG_ANSWER_ENTRY_ORDER);
	for my $key (keys %{ $PG->{PG_ANSWERS_HASH} }) {
		my $answergroup = $PG->{PG_ANSWERS_HASH}{$key};

		# EXTRA ANSWERS KLUDGE
		# The first response label in each answer group is placed in the @PG_ANSWER_ENTRY_ORDER array, and the first
		# response evaluator is placed in %PG_ANSWERS_HASH identified by its label.  The remainder of the response
		# labels are placed in the @KEPT_EXTRA_ANSWERS array.
		if (defined $answergroup) {
			if ($inputs_ref->{showAnsGroupInfo} && $rh_envir->{show_answer_group_info}) {
				$PG->debug_message(pretty_print($answergroup));
				$PG->debug_message(pretty_print($answergroup->{response}));
			}

			$PG_ANSWERS_HASH{ $answergroup->{ans_label} } = $answergroup->{ans_eval};
			push @PG_ANSWER_ENTRY_ORDER, $answergroup->{ans_label};

			push @KEPT_EXTRA_ANSWERS, $answergroup->{response}->response_labels;
		} else {
			warn "$key does not have a valid answer group.";
		}
	}

	$PG->{flags}{KEPT_EXTRA_ANSWERS} = \@KEPT_EXTRA_ANSWERS;
	$PG->{flags}{ANSWER_ENTRY_ORDER} = \@PG_ANSWER_ENTRY_ORDER;

	my $STRINGforOUTPUT          = join('', @{ $PG->{OUTPUT_ARRAY} });
	my $STRINGforHEADER_TEXT     = join('', @{ $PG->{HEADER_ARRAY} });
	my $STRINGforPOSTHEADER_TEXT = join('', @{ $PG->{POST_HEADER_ARRAY} });

	(\$STRINGforOUTPUT, \$STRINGforHEADER_TEXT, \$STRINGforPOSTHEADER_TEXT, \%PG_ANSWERS_HASH, $PG->{flags}, $PG);
}

sub alias {
	my $aux_file_id = shift;
	return $PG->{PG_alias}->make_alias($aux_file_id);
}

sub get_resource {
	my $aux_file_id = shift;
	return $PG->{PG_alias}->get_resource($aux_file_id);
}

sub maketext {
	$PG->maketext(@_);
}

sub insertGraph {
	$PG->insertGraph(@_);
}

sub findMacroFile {
	$PG->{PG_loadMacros}->findMacroFile(@_);
}

sub loadMacros {
	$PG->{PG_loadMacros}->loadMacros(@_);
}

# This is a stub for deprecated problems that call this method.  Some of the GeoGebra
# problems that do so actually work even though this method does nothing.
sub findAppletCodebase { return ''; }

## Problem Grader Subroutines

#####################################
# This is a model for plug-in problem graders
#####################################
# ^function install_problem_grader
# ^uses PG_restricted_eval
# ^uses %PG_FLAGS{PROBLEM_GRADER_TO_USE}
sub install_problem_grader {
	my $rf_problem_grader = shift;
	my $rh_flags          = $PG->{flags};
	$rh_flags->{PROBLEM_GRADER_TO_USE} = $rf_problem_grader if not_null($rf_problem_grader);
	$rh_flags->{PROBLEM_GRADER_TO_USE};
}

sub current_problem_grader {
	install_problem_grader(@_);
}

#  FIXME? The following functions were taken from the former
#  dangerousMacros.pl file and might have issues when placed here.
#
#  Some constants that can be used in perl expressions
#

# ^function i
# ^uses $_parser_loaded
# ^uses &Complex::i
# ^uses &Value::Package
sub i () {
	#  check if Parser.pl is loaded, otherwise use Complex package
	if (!eval(q!$main::_parser_loaded!)) { return Complex::i }
	return Value->Package("Formula")->new('i')->eval;
}

# ^function j
# ^uses $_parser_loaded
# ^uses &Value::Package
sub j () {
	if (!eval(q!$main::_parser_loaded!)) { return 'j' }
	Value->Package("Formula")->new('j')->eval;
}

# ^function k
# ^uses $_parser_loaded
# ^uses &Value::Package
sub k () {
	if (!eval(q!$main::_parser_loaded!)) { return 'k' }
	Value->Package("Formula")->new('k')->eval;
}

# ^function pi
# ^uses $_parser_loaded
# ^uses &Value::Package
sub pi () {
	if (!eval(q!$main::_parser_loaded!)) { return 4 * atan2(1, 1) }
	Value->Package("Formula")->new('pi')->eval;
}

# ^function Infinity
# ^uses $_parser_loaded
# ^uses &Value::Package
sub Infinity () {
	if (!eval(q!$main::_parser_loaded!)) { return 'Infinity' }
	Value->Package("Infinity")->new();
}

# ^function abs
# ^function sqrt
# ^function exp
# ^function log
# ^function sin
# ^function cos
# ^function atan2
#
#  Allow these functions to be overridden without complaint.
#  (needed for log() to implement $useBaseTenLog)
#
use subs 'abs', 'sqrt', 'exp', 'log', 'sin', 'cos', 'atan2', 'ParserDefineLog';
sub abs  { return CORE::abs($_[0]) }
sub sqrt { return CORE::sqrt($_[0]) }
sub exp  { return CORE::exp($_[0]) }
#sub log  {return CORE::log($_[0])};
sub sin   { return CORE::sin($_[0]) }
sub cos   { return CORE::cos($_[0]) }
sub atan2 { return CORE::atan2($_[0], $_[1]) }

# used to be Parser::defineLog -- but that generated redefined notices
sub ParserDefineLog {
	eval {
		sub log { CommonFunction->Call("log", @_) }
	}
}

=head2 includePGproblem

Essentially runs the pg problem specified by C<$filePath>, which is a path
relative to the top of the templates directory. The output of that problem
appears in the given problem.

    includePGproblem($filePath);

=cut

sub includePGproblem {
	my $filePath     = shift;
	my %save_envir   = %main::envir;
	my $fullfilePath = $PG->envir("templateDirectory") . $filePath;
	my $r_string     = $PG->read_whole_problem_file($fullfilePath);
	if (ref($r_string) eq 'SCALAR') {
		$r_string = $$r_string;
	}

	# The problem calling this should provide DOCUMENT and ENDDOCUMENT,
	# so we remove them from the included file.
	$r_string =~ s/^\s*(END)?DOCUMENT(\(\s*\));?//gm;

	# Reset the problem path so that static images can be found via
	# their relative paths.
	eval('$main::envir{probFileName} = $filePath');
	# now update the PGalias object
	my $save_PGalias = $PG->{PG_alias};
	my $temp_PGalias = PGalias->new(
		\%main::envir,
		WARNING_messages => $PG->{WARNING_messages},
		DEBUG_messages   => $PG->{DEBUG_messages},
	);
	$PG->{PG_alias} = $temp_PGalias;
	$PG->includePGtext($r_string);
	# Reset the environment to what it was before.
	%main::envir = %save_envir;
	$PG->{PG_alias} = $save_PGalias;
}

sub beginproblem;    # announce that beginproblem is a macro

=head1 FILTER UTILITIES

These two subroutines can be used in filters to set default options. They help
make filters perform in uniform, predictable ways, and also make it easy to
recognize from the code which options a given filter expects.

=head2 assign_option_aliases

Use this to assign aliases for the standard options. It must come before
set_default_options within the subroutine.

    assign_option_aliases(\%options,
        alias1 => 'option5'
        alias2 => 'option7'
    );

If the subroutine is called with an option C<< alias1 => 23 >> it will behave as
if it had been called with the option C<< option5 => 23 >>.

=cut

sub assign_option_aliases {
	my $rh_options = shift;
	warn "The first entry to set_default_options must be a reference to the option hash"
		unless ref($rh_options) eq 'HASH';
	my @option_aliases = @_;
	while (@option_aliases) {
		my $alias      = shift @option_aliases;
		my $option_key = shift @option_aliases;

		if (defined($rh_options->{$alias})) {    # if the alias appears in the option list
			if (not defined($rh_options->{$option_key})) {    # and the option itself is not defined,
				$rh_options->{$option_key} =
					$rh_options->{$alias};    # insert the value defined by the alias into the option value
											  # the FIRST alias for a given option takes precedence
											  # (after the option itself)
			} else {
				warn "option $option_key is already defined as", $rh_options->{$option_key}, "<br>\n",
					"The attempt to override this option with the alias $alias with value ", $rh_options->{$alias},
					" was ignored.";
			}
		}
		delete($rh_options->{$alias});    # remove the alias from the initial list
	}

}

=head2 set_default_options

    set_default_options(\%options,
        _filter_name          => 'filter',
        option5               => .0001,
        option7               => 'ascii',
        allow_unknown_options => 0,
    }

Note that the first entry is a reference to the options with which the filter
was called.

The C<option5> is set to .0001 unless the option is explicitly set when the
subroutine is called.

The C<_filter_name> option should always be set, although there is no error if
it is missing. It is used mainly for debugging answer evaluators and allows you
to keep track of which filter is currently processing the answer.

If C<allow_unknown_options> is set to 0 then if the filter is called with
options which do NOT appear in the set_default_options list an error will be
signaled and a warning message will be printed out. This provides error checking
against misspelling an option and is generally what is desired for most filters.

Occasionally one wants to write a filter which accepts a long list of options,
not all of which are known in advance, but only uses a subset of the options
provided. In this case, setting C<allow_unkown_options> to 1 prevents the error
from being signaled.

=cut

sub set_default_options {
	my $rh_options = shift;
	warn "The first entry to set_default_options must be a reference to the option hash"
		unless ref($rh_options) eq 'HASH';
	my %default_options = @_;
	unless (defined($default_options{allow_unknown_options}) and $default_options{allow_unknown_options} == 1) {
		foreach my $key1 (keys %$rh_options) {
			warn "This option |$key1| is not recognized in this subroutine<br> ", pretty_print($rh_options)
				unless exists($default_options{$key1});
		}
	}
	foreach my $key (keys %default_options) {
		if (not defined($rh_options->{$key}) and defined($default_options{$key})) {
			$rh_options->{$key} =
				$default_options{$key};    #this allows     tol   => undef to allow the tol option, but doesn't define
										   # this key unless tol is explicitly defined.
		}
	}
}

=head1 SEE ALSO

L<PGbasicmacros.pl>, L<PGanswermacros.pl>.

=cut

1;
