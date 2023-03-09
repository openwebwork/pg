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

=head1 NAME

parserCheckboxList.pl - Multiple choice checkbox answers compatible with
                        MathObjects, MultiAnswer objects, and PGML.

=head1 DESCRIPTION

This file implements a multiple choice checkbox object that is compatible with
MathObjects, and in particular, with the MultiAnswer object, and with PGML.

To create a CheckboxList object, use

    $checks = CheckboxList([choices, ...], [correct_choices, ...], options);

where "S<choices>" are the label value strings for the checkboxes,
"S<correct_choices>" are the choices that are the correct answers (or their
indices, with 0 being the first one), and options are chosen from among those
listed below.  If the correct answer is a number, it is interpreted as an index,
even if the array of choices are also numbers.  (See the C<noindex> below for
more details.)

The entries in the choices array can either be strings that are the text to use
for the choice buttons, or C<< { label => text } >> where C<label> is a label to
use for the choice when showing the student or correct answers and C<text> is
the text to use for the choice, or C<< { label => [ text, value ] } >> where
C<label> and C<text> are as described above and C<value> is the value to for the
checkbox input for this choice.

See below for options controlling how the labels will be used.  If a choice
includes mathematics, you should use labels as above or through the C<labels>
option below in order to have the student and correct answers display properly
in the results table when an answer is submitted.  Use the C<displayLabels>
option to make the labels be part of the choice as it is displayed following the
checkbox.

The values set as described above are the answers that will be displayed in the
past answers table.  See the C<values> option below for more information.
Problem authors are encourages to set these values either as described above, or
via the C<values> option.  This is useful for instructors viewing past answers.

By default, the choices are left in the order that you provide them, but you can
cause some or all of them to be ordered randomly by enclosing those that should
be randomized within a second set of brackets.  For example

    $checks = CheckboxList(
        [
            "First Item",
            [ "Random 1", "Random 2", "Random 3" ],
            "Last Item"
        ],
        ["First Item", "Random 3"]
    );

will make a list of checkboxes that has the first item always on top, the next
three ordered randomly, and the last item always on the bottom.  In this example

    $checks = CheckboxList([[ "Random 1", "Random 2", "Random 3" ]], 2);

all the entries are randomized, and the correct answer is "Random 3" (the one
with index 2 in the original, unrandomized list).  You can have as many
randomized groups, with as many static items in between, as you want.

The C<options> are taken from the following list:

=over

=item C<S<< labels => "123", "ABC", "text", or [label1, ...] >>>

Labels are used to replace the text of the choice in the student and correct
answers, and can also be shown just before the choice text (if C<displayLabels>
is set).  If the value is C<"123"> then the choices will be labeled with numbers
(the choices will be numbered sequentially after they have been randomized).  If
the value is C<"ABC"> then the choices will be labeled with capital letters
after they have been randomized.  If the value is C<"text"> then the button text
is used (note, however, that if the text contains things like math or formatting
or special characters, these may not display well in the student and correct
answer columns of the results table).

If any choices have explicit labels (via C<< { label => text } >>), those labels
will be used instead of the automatic number or letter (and the number or letter
will be skipped).  The third form allows you to specify labels for each of the
choices in their original order (though the C<< { label => text } >> form is
preferred).

Default: labels are the text of the choice when they don't include any special
characters, and "Button 1", "Button 2", etc., otherwise.

=item C<S<< values => array reference >>>

Values are the form of the student answer that will be displayed in the past
answers table for this answer.  By default these are B0, B1, etc.  However, that
can be changed either with this option or by specifying the choices with
C<< { label => [ text, value ] } >> as described previously.  If this option is
used, then the value of the option should be a reference to an array containing
the values for the choices.  For example:

    values => [ 'first choice', 'second choice', ... ]

If a choice is not represented in the hash, then C<Bn> will be used for the
value instead where C<n> is the 0 based index of the choice.

These values can be any descriptive string that is unique for the choice, but
care should be taken to ensure that these values do not indicate which choice is
the correct answer.

Note that values given via C<< { label => [ text, value ] } >> will override any
values given by this option if both are provided for a particular choice.

Also note that due to the way that checkbox values are passed in HTML forms, all
checked values will be concatenated into a single string for the original
student answer with no separator.  So it is advisable to end each value with a
comma or semicolon to provide a separator for the parts of the answer that were
checked.

=item C<S<< displayLabels => 0 or 1 >>>

Specifies whether labels should be displayed after the checkbox and before its
text.  This makes the association between the choices and the label used as an
answer more explicit.  Default: 1

=item C<S<< labelFormat => string >>>

Specifies a format string to use when displaying labels before the choice text.
It is an C<sprintf> string that contains C<%s> where the label should go.  By
default, it is C<${BBOLD}%s. ${EBOLD}>, which produces the label in bold
followed by a period and a space.

=item C<S<< forceLabelFormat => 0 or 1 >>>

When C<displayLabels> is set, this controls how blank labels are handled.  When
set to C<0>, no label is inserted before the choice text for blank labels, and
when C<1>, the C<labelFormat> is applied to the empty string and the result is
inserted before the choice text.  Default: 0.

=item C<S<< separator => string >>>

Specifies the text to put between the checkboxes.  Default: $BR

=item C<S<< checked => choice >>>

A list of texts or indices (starting at zero) of the checkboxes to be checked
initially.  Default: [] (none checked)

=item C<S<< maxLabelSize => n >>>

The approximate largest size that should be used for the answer strings to be
generated by the checkboxes (if the choice strings are too long, they will be
trimmed and "..." inserted) Default: 25

=item C<S<< noindex => 0 or 1 >>>

Determines whether a numeric value for the correct answer is interpreted as an
index into the choice array or not.  If set to 1, then the number is treated as
the literal correct answer, not an index to it.  Default: 0

=back

To insert the checkboxes into the problem text use

    BEGIN_PGML
    [_]{$checks}
    END_PGML

with PGML, or

    BEGIN_TEXT
    \{$checks->checks\}
    END_TEXT

    ANS($checks->cmp);

with basic PG.

You can use the CheckboxList object in MultiAnswer objects.  This is the reason
for the CheckboxList's C<ans_rule> method (since that is what MultiAnswer calls
to get answer rules).  Just pass a CheckboxList object as one of the arguments
of the MultiAnswer constructor.

When writing a custom answer checker involving a CheckboxList object (e.g. if it
is part of a MultiAnswer and its answer depends on, or affects, the answers
given to other parts), note that the actual answer strings associated to a
CheckboxList object (which are those appearing in the "student answer" argument
passed to a custom answer checker) are neither the supplied choice strings nor
the supplied labels, but are the checkbox input values.  These are the values
given by the C<values> option or C<< { label => [ text, value ] } >> choice
format if provided. Otherwise they are an internal implementation detail whose
format should not be depended on.  In any case, you can convert these value
strings to a choice string or a label with the methods answerChoice or
answerLabel.

=cut

loadMacros('MathObjects.pl');

sub _parserCheckboxList_init {
	main::PG_restricted_eval('sub CheckboxList { parser::CheckboxList->new(@_) }');
	return;
}

package parser::CheckboxList;
our @ISA = qw(Value::List);

sub new {
	my ($invocant, @inputs) = @_;

	shift @inputs if Value::isContext($inputs[0]);

	my $choices = shift @inputs;
	my $correct = shift @inputs;

	Value::Error(q{A CheckboxLists's first argument should be a list of checkbox label values.})
		unless ref($choices) eq 'ARRAY';
	Value::Error(q{A CheckboxList's second argument should be a list of correct choices.})
		unless ref($correct) eq 'ARRAY';

	my %options;
	main::set_default_options(
		\%options,
		labels           => 'auto',
		displayLabels    => 'auto',
		labelFormat      => "${main::BBOLD}%s${main::EBOLD}. ",
		forceLabelFormat => 0,
		values           => [],
		separator        => $main::BR,
		checked          => [],
		maxLabelSize     => 25,
		noindex          => 0,
		checkedI         => [],
		@inputs
	);

	my $context = Parser::Context->getCopy('Numeric');

	my $self = $invocant->SUPER::new($context, 0 .. $#$correct);
	$self->{$_} = $options{$_} for keys %options;
	$self->{choices} = $choices;

	$self->getChoiceOrder;
	$self->addLabels;
	$self->getCorrectChoices($correct);
	$self->getCheckedChoices($self->{checked});

	$context->strings->add(map { ($self->{values}[$_] => {}) } (0 .. ($self->{n} - 1)));
	$_ = Value::makeValue($_, context => $context) for @{ $self->data };

	return $self;
}

sub type { return 'List'; }

# Order the choices (randomizing where requested).
sub getChoiceOrder {
	my $self = shift;

	my @choices;
	for my $choice (@{ $self->{choices} }) {
		if (ref($choice) eq 'ARRAY') { push(@choices, $self->randomOrder($choice)) }
		else { push(@choices, $choice); push(@{ $self->{order} }, scalar(@{ $self->{order} })); }
	}
	$self->{orderedChoices} = \@choices;
	$self->{n}              = scalar(@choices);

	return;
}

sub randomOrder {
	my ($self, $choices) = @_;
	my @indices = 0 .. $#$choices;
	my @order   = map { splice(@indices, $main::PG_random_generator->random(0, $#indices), 1) } @indices;
	push(@{ $self->{order} }, map { $_ + scalar(@{ $self->{order} }) } @order);
	return map { $choices->[$_] } @order;
}

# Collect the labels from those that have them, and add ones to those that don't (if requested).
sub addLabels {
	my $self = shift;

	my $choices = $self->{orderedChoices};
	my $labels  = $self->{labels};
	$labels = [ 1 .. $self->{n} ]                        if $labels eq '123';
	$labels = [ @main::ALPHABET[ 0 .. $self->{n} - 1 ] ] if uc($labels) eq 'ABC';
	$labels = []                                         if $labels eq 'text';

	if (ref($labels) ne 'ARRAY') {
		my $replace = $labels ne 'auto';
		if (!$replace) {
			for (@$choices) { $replace = 1 if $_ =~ m/[^-+.,;:()!\[\]a-z0-9 ]/i }
		}
		$labels                = [ map {"Choice $_"} (1 .. $self->{n}) ] if $replace;
		$self->{displayLabels} = 0                                       if $self->{displayLabels} eq 'auto';
	}

	$labels = [] unless ref($labels) eq 'ARRAY';

	my @values = (undef) x $self->{n};

	for (0 .. $self->{n} - 1) {
		if (ref($choices->[$_]) eq 'HASH') {
			my $key = (keys %{ $choices->[$_] })[0];
			$labels->[$_] = $key;
			if (ref($choices->[$_]{$key}) eq 'ARRAY') {
				$values[$_] = $choices->[$_]{$key}[1];
				$choices->[$_] = $choices->[$_]{$key}[0];
			} else {
				$choices->[$_] = $choices->[$_]{$key};
			}
		}
	}

	$self->{labels}        = $labels;
	$self->{displayLabels} = 1 if $self->{displayLabels} eq 'auto';
	$self->{values}        = [ map { $values[$_] // $self->{values}[ $self->{order}[$_] ] // "B$_" } 0 .. $#values ];

	return;
}

# Find the correct choices in the ordered array
sub getCorrectChoices {
	my ($self, $values) = @_;

	$self->{data} = [];

	for my $value (@$values) {
		if ($value =~ m/^\d+$/ && !$self->{noindex}) {
			$value = ($self->flattenChoices)[$value];
			if (!defined($value)) {
				Value::Error('The correct answer index is outside the range of choices provided');
				return;
			}
		}

		for (0 .. $#{ $self->{orderedChoices} }) {
			if ($value eq $self->{orderedChoices}[$_] || $value eq ($self->{labels}[$_] || '')) {
				push(@{ $self->{data} }, $self->{values}[$_]);
				last;
			}
		}
	}

	# Sort the correct choices into display order.
	$self->{data} =
		[ main::PGsort(sub { $self->getIndexByValue($_[0]) < $self->getIndexByValue($_[1]) }, @{ $self->{data} }) ];

	Value::Error('The correct choices must be among the label values') unless @{ $self->{data} };

	return;
}

sub getCheckedChoices {
	my ($self, $values) = @_;
	return unless @$values;

	for my $value (@$values) {
		$value = ($self->flattenChoices)[$value] if $value =~ m/^\d+$/;

		if (!defined($value)) {
			Value::Error('The correct answer index is outside the range of choices provided');
			return;
		}

		for (0 .. $#{ $self->{orderedChoices} }) {
			if ($value eq $self->{orderedChoices}[$_] || $value eq $self->{labels}[$_]) {
				push(@{ $self->{checkedI} }, $_);
				last;
			}
		}
	}

	Value::Error('The checked choices must be among the label values') unless @{ $self->{checkedI} };
	return;
}

sub flattenChoices {
	my $self    = shift;
	my @choices = map { ref($_) eq 'ARRAY' ? @$_ : $_ } @{ $self->{choices} };
	for my $choice (@choices) {
		if (ref($choice) eq 'HASH') {
			my $key = (keys %$choice)[0];
			$choice = ref($choice->{$key}) eq 'ARRAY' ? $choice->{$key}[0] : $choice->{$key};
		}
	}
	return @choices;
}

# Format a label using the user-provided format string
sub labelFormat {
	my ($self, $label) = @_;
	return ''   unless $label || $self->{forceLabelFormat};
	$label = '' unless defined $label;
	return sprintf($self->{labelFormat}, $self->protect($label));
}

# Convert a value string into a numeric index.
sub getIndexByValue {
	my ($self, $value) = @_;
	return -1 unless defined $value;
	my ($index) = grep { $self->{values}[$_] eq $value } 0 .. $#{ $self->{values} };
	return $index // -1;
}

# Trim the selected choice or label so that it is not too long to be displayed in the results table.
sub labelText {
	my ($self, $value) = @_;
	$index = $self->getIndexByValue($value);
	my $choice = $self->{labels}[$index];
	$choice = $self->{orderedChoices}[$index] unless defined $choice;
	return $choice if length($choice) < $self->{maxLabelSize};
	my @words = split(/( |\b)/, $choice);
	my ($s, $e) = ('', '');
	return $choice if scalar(@words) < 3;
	do { $s .= shift(@words); $e = pop(@words) . $e if @words }
		while length($s) + length($e) + 10 < $self->{maxLabelSize} && scalar(@words);
	return $s . " ... " . $e;
}

# Use the actual choice strings in the output rather than the value string.
sub TeX {
	my $self = shift;
	return $self->quoteTeX(join(', ', map { $self->labelText($_) } $self->value));
}

sub string {
	my $self = shift;
	return $self->quoteHTML(join(', ', map { $self->labelText($_) } $self->value));
}

sub cmp_defaults {
	my ($self, %options) = @_;
	return (
		$self->SUPER::cmp_defaults(%options),
		entry_type        => 'choice',
		list_type         => 'selection',
		requireParenMatch => 0,
		implicitList      => 0,
		correct_choices   => $self->data
	);
}

# Adjust student preview and answer strings to be the actual choice strings rather than the value strings.
sub cmp_preprocess {
	my ($self, $ans) = @_;
	if (defined $ans->{student_value} && @{ $ans->{student_value}->data }) {
		$ans->{original_student_ans} = join(', ', map { $self->labelText($_) } @{ $ans->{student_value}->data });
		$ans->{preview_latex_string} = $self->quoteTeX($ans->{original_student_ans});
		$ans->{student_ans}          = $self->quoteHTML($ans->{original_student_ans});
	}
	return;
}

sub verb {
	my ($self, $s) = @_;
	$s =~ s/\r/ /g;
	my $d = main::MODES(HTML => chr(0x1F), TeX => chr(0xD), PTX => chr(0xD));
	return "{\\verb$d$s$d}";
}

# Put normal strings into \text{} and others into \verb
sub quoteTeX {
	my ($self, $s) = @_;
	return $self->verb($s) unless $s =~ m/^[-a-z0-9 ,.;:+=?()\[\]]*$/i;
	return "\\text{$s}";
}

# Quote HTML special characters
sub quoteHTML {
	my ($self, $s, $nospan) = @_;
	return unless defined $s;
	return $s if $main::displayMode eq 'TeX';

	$s =~ s/&/\&amp;/g;
	$s =~ s/</\&lt;/g;
	$s =~ s/>/\&gt;/g;
	$s =~ s/"/\&quot;/g;

	return $s if $nospan || $s !~ m/(\$|\\\(|\\\[)/;
	return qq{<span class="tex2jax_ignore">$s</span>};
}

sub answerChoice {
	my ($self, $value) = @_;
	return $self->{orderedChoices}[ $self->getIndexByValue($value) ];
}

sub answerLabel {
	my ($self, $value) = @_;
	return $self->{labels}[ $self->getIndexByValue($value) ];
}

# Given a choice, a label, or an index into the choices array, return the choice.
sub findChoice {
	my ($self, $value) = @_;
	my $index = $self->Index($value);
	return $self->{choices}[$index] unless $index == -1;
	for (0 .. ($self->{n} - 1)) {
		my $label  = $self->{labels}[$_] // '';
		my $choice = $self->{choices}[$_];
		return $choice if $label eq $value || $choice eq $value;
	}
	return;
}

# Get a numeric index (-1 if not defined or not a number).
sub Index {
	my ($self, $index) = @_;
	return -1 unless defined $index && $index =~ m/^\d$/;
	return $index;
}

# Create the checkbox text
sub CHECKS {
	my ($self, $extend, $name, $size, %options) = @_;

	my @checks;
	$name = main::NEW_ANS_NAME() unless $name;
	my $label = main::generate_aria_label($name);

	for my $i (0 .. $#{ $self->{orderedChoices} }) {
		my $value = $self->{values}[$i];
		my $tag   = $self->{orderedChoices}[$i];
		$value = '%' . $value                                   if (grep { $i == $_ } @{ $self->{checkedI} });
		$tag   = $self->labelFormat($self->{labels}[$i]) . $tag if $self->{displayLabels};
		if ($i > 0) {
			push(
				@checks,
				main::NAMED_ANS_CHECKBOX_OPTION(
					$name, $value, " $tag",
					id         => "${name}_$i",
					aria_label => $label . 'option ' . ($i + 1) . ' ',
					%options
				)
			);
		} else {
			push(@checks, main::NAMED_ANS_CHECKBOX($name, $value, " $tag", $extend, %options));
		}
	}

	if ($main::displayMode eq 'TeX') {
		$checks[0] = "\n\\begin{itemize}\n" . $checks[0];
		$checks[-1] .= "\n\\end{itemize}\n";
	}

	# FIXME: Alex, what is needed here?
	if ($main::displayMode eq 'PTX') {
		$checks[0] = qq{<var form="buttons" name="$name">\n$checks[0]};
		$checks[-1] .= '</var>';
		# Change math delimiters
		@checks = map { $_ =~ s/\\\(/<m>/gr } @checks;
		@checks = map { $_ =~ s/\\\)/<\/m>/gr } @checks;
	}

	return wantarray ? @checks : join($main::displayMode eq 'PTX' ? '' : $self->{separator}, @checks);
}

sub protect {
	my ($self, $s) = @_;
	return '' if !defined $s || $s eq '';
	return main::MODES(TeX => $self->quoteTeX($s), HTML => $self->quoteHTML($s));
}

sub checks { my ($self, $size, %options) = @_; return $self->CHECKS(0, undef, $size, %options); }
sub named_checks { my ($self, $name, $size, %options) = @_; return $self->CHECKS(0, $name, $size, %options); }

sub ans_rule { my ($self, $size, %options) = @_; return $self->CHECKS(0, undef, $size, %options); }
sub named_ans_rule { my ($self, $name, $size, %options) = @_; return $self->CHECKS(0, $name, $size, %options); }

sub named_ans_rule_extension {
	my ($self, $name, $size, %options) = @_;
	return $self->CHECKS(1, $name, $size, %options);
}

1;
