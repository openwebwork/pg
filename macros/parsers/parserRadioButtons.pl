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

=head1 NAME

parserRadioButtons.pl - Radio buttons compatible with MathObjects,
                        specifically MultiAnswer objects.

=head1 DESCRIPTION

This file implements a radio button group object that is compatible
with MathObjects, and in particular, with the MultiAnswer object, and
with PGML.

To create a RadioButtons object, use

    $radio = RadioButtons([choices,...],correct,options);

where "choices" are the strings for the items in the radio buttons,
"correct" is the choice that is the correct answer for the group (or
its index, with 0 being the first one), and options are chosen from
among those listed below.  If the correct answer is a number, it is
interpreted as an index, even if the array of choices are also
numbers.  (See the C<noindex> below for more details.)

The entries in the choices array can either be strings that are the
text to use for the choice buttons, or C<< { label => text } >> where
C<label> is a label to use for the choice when showing the student or
correct answers and C<text> is the text to use for the choice, or
C<< { label => [ text, value ] } >> where C<label> and C<text> are as
described above and C<value> is the value to for the radio input for
this choice.

See below for options controlling how the labels will be used.  If a
choice includes mathematics, you should use labels as above or through
the C<labels> option below in order to have the student and correct
answers display properly in the results table when an answer is
submitted.  Use the C<displayLabels> option to make the labels be part
of the choice as it is displayed following the radio button.

The values set as described above are the answers that will be
displayed in the past answers table.  See the C<values> option below
for more information.  Problem authors are encourages to set these
values either as described above, or via the C<values> option.  This
is useful for instructors viewing past answers.

By default, the choices are left in the order that you provide them,
but you can cause some or all of them to be ordered randomly by
enclosing those that should be randomized within a second set of
brackets.  For example

    $radio = RadioButtons(
                          [
                            "First Item",
                            ["Random 1","Random 2","Random 3"],
                            "Last Item"
                          ],
                          "Random 3"
                        );

will make a list of radio buttons that has the first item always on
top, the next three ordered randomly, and the last item always on the
bottom.  In this example

        $radio = RadioButtons([["Random 1","Random 2","Random 3"]],2);

all the entries are randomized, and the correct answer is "Random 3"
(the one with index 2 in the original, unrandomized list).  You can
have as many randomized groups, with as many static items in between,
as you want.

The C<options> are taken from the following list:

=over

=item C<S<< labels => "123", "ABC", "text", or [label1,...] >>>

Labels are used to replace the text of the choice in the student and
correct answers, and can also be shown just before the choice text (if
C<displayLabels> is set).  If the value is C<"123"> then the choices
will be labeled with numbers (the choices will be numbered
sequentially after they have been randomized).  If the value is
C<"ABC"> then the choices will be labeled with capital letters after
they have been randomized.  If the value is C<"text"> then the button
text is used (note, however, that if the text contains things like
math or formatting or special characters, these may not display well
in the student and correct answer columns of the results table).

If any choices have explicit labels (via C<< { label => text } >>),
those labels will be used instead of the automatic number of letter
(and the number of letter will be skipped).  The third form allows you
to specify labels for each of the choices in their random order.  If
you want to specify the labels for the choices in their original order
the C<< { label => text } >> form must be used.

Default: labels are the text of the choice when they don't include any
special characters, and "Button 1", "Button 2", etc. otherwise.

=item C<S<< values => array reference >>>

Values are the form of the student answer that will be displayed in
the past answers table for this answer.  By default these are B0, B1,
etc.  However, that can be changed either with this option or by
specifying the choices with C<< { label => [ text, value ] } >> as
described previously.  If this option is used, then the value of the
option should be a reference to an array containing the values for the
choices.  For example:

    values => [ 'first choice', 'second choice', ... ]

If a choice is not represented in the hash, then C<Bn> will be used
for the value instead where C<n> is the 0 based index of the choice.

These values can be any descriptive string that is unique for the
choice, but care should be taken to ensure that these values do not
indicate which choice is the correct answer.

Note that values given via C<< { label => [ text, value ] } >> will
override any values given by this option if both are provided for a
particular choice.

=item C<S<< displayLabels => 0 or 1 >>>

Specifies whether labels should be displayed after the radio button
and before its text.  This makes the association between the choices
and the label used as an answer more explicit.  Default: 1

=item C<S<< labelFormat => string >>>

Specifies a format string to use when displaying labels before the
choice text.  It is an C<sprintf()> string that contains C<%s> where
the label should go.  By default, it is C<${BBOLD}%s. ${EBOLD}>, which
produces the label in bold followed by a period and a space.

=item C<S<< forceLabelFormat => 0 or 1 >>>

When C<displayLabels> is set, this controls how blank labels are
handled.  When set to C<0>, no label is inserted before the choice
text for blank labels, and when C<1>, the C<labelFormat> is applied to
the empty string and the result is inserted before the choice text.
Default: 0.

=item C<S<< separator => string >>>

Specifies the text to put between the radio buttons.  Default: $BR

=item C<S<< checked => choice >>>

The text or index (starting at zero) of the button to be checked
initially.  Default: none checked

=item C<S<< maxLabelSize => n >>>

The approximate largest size that should be used for the answer
strings to be generated by the radio buttons (if the choice strings
are too long, they will be trimmed and "..." inserted) Default: 25

=item C<S<< uncheckable => 0 or 1 or "shift" >>>

Determines whether the radio buttons can be unchecked (requires
JavaScript).  To uncheck, click a second time; when set to "shift",
unchecking requires the shift key to be pressed.  Default: 0

=item C<S<< noindex => 0 or 1 >>>

Determines whether a numeric value for the correct answer is
interpreted as an index into the choice array or not.  If set to 1,
then the number is treated as the literal correct answer, not an index
to it.  Default: 0

=back

The following options are deprecated, but are available for backward
compatibility.  This functionality can now be accomplished though
grouping the items in the choice list.

=over

=item C<S<< randomize => 0 or 1 >>>

Specifies whether the order of the choices should be randomized or
not.  By default, the order is exactly as they appear in the choices
array.  If you select random order, you can use the C<first> and
C<last> arrays to help organize the choices.

=item C<S<< order => [choice,...] >>>

Specifies the order in which choices should be presented. All choices
must be listed. If this option is specified, the C<first> and C<last>
options are ignored.  The order can be given in terms of the indices
of the choices (0 is the first one), or as the strings themselves.

=item C<S<< first => [choice,...] >>>

Specifies choices which should appear first, in the order specified,
in the list of choices. Ignored if the C<order> option is specified.
The entries in this list are either indices of the choices (0 is the
first one), or the strings themselves.

=item C<S<< last => [choice,...] >>>

Specifies choices which should appear last, in the order specified, in
the list of choices. Ignored if the C<order> option is specified.  The
entries in this list are either the indices of the choices (0 is the
first one), or the strings themselves.

=back

To insert the radio buttons into the problem text, use

    BEGIN_TEXT
    \{$radio->buttons\}
    END_TEXT

and then

    ANS($radio->cmp);

to get the answer checker for the radion buttons.

You can use the RadioButtons object in MultiAnswer objects.  This is
the reason for the RadioButton's C<ans_rule()> method (since that is
what MultiAnswer calls to get answer rules).  Just pass a RadioButtons
object as one of the arguments of the MultiAnswer constructor.

When writing a custom answer checker involving a RadioButtons object
(e.g. if it is part of a MultiAnswer and its answer depends on, or
affects, the answers given to other parts), note that the actual
answer strings associated to a RadioButtons object (which are those
appearing in the "student answer" argument passed to a custom answer
checker) are neither the supplied choice strings nor the supplied
labels, but are the radio button values.  These are the values given
by the C<values> option or C<< { label => [ text, value ] } >> choice
format if provided. Otherwise they are an internal implementation
detail whose format should not be depended on.  In any case, you can
convert these value strings to a choice string or a label with the
methods answerChoice or answerLabel.

=cut

loadMacros('MathObjects.pl');

sub _parserRadioButtons_init { parserRadioButtons::Init() };    # don't reload this file

##################################################################
#
#  The package that implements RadioButtons
#
package parserRadioButtons;
our @ISA = qw(Value::String);

#
#  Set up the main:: namespace
#
sub Init {
	main::PG_restricted_eval('sub RadioButtons {parserRadioButtons->new(@_)}');
}

#
#  Create a new RadioButtons object
#
sub new {
	my $self    = shift;
	my $class   = ref($self) || $self;
	my $context = (Value::isContext($_[0]) ? shift : $self->context);
	my $choices = shift;
	my $value   = shift;
	my %options;
	main::set_default_options(
		\%options,
		labels           => "auto",
		displayLabels    => "auto",
		labelFormat      => "${main::BBOLD}%s${main::EBOLD}. ",
		forceLabelFormat => 0,
		values           => [],
		separator        => $main::BR,
		checked          => undef,
		maxLabelSize     => 25,
		uncheckable      => 0,
		randomize        => 0,
		first            => undef,
		last             => undef,
		order            => undef,
		noindex          => 0,
		@_,
		checkedI => -1,
	);
	Value::Error("A RadioButton's first argument should be a list of button values")
		unless ref($choices) eq 'ARRAY';
	Value::Error("A RadioButton's second argument should be the correct button choice")
		unless defined($value) && $value ne "";
	$context = Parser::Context->getCopy('Numeric');
	$self    = bless { %options, choices => $choices, context => $context }, $class;
	$self->compatibility if $self->{order} || $self->{last} || $self->{first} || $self->{randomize};
	$self->{order} = [];    # Reset the order to ensure old style arguments don't conflict with later usage.
	$self->getChoiceOrder;
	$self->addLabels;
	$self->getCorrectChoice($value);
	$self->getCheckedChoice($self->{checked});
	main::ADD_JS_FILE('js/RadioButtons/RadioButtons.js', 0, { defer => undef }) if $self->{uncheckable};
	$context->strings->are(map { $self->{values}[$_] => {} } (0 .. ($self->{n} - 1)));
	return $self;
}

#
#  Get the choices into the correct order (randomizing where requested)
#
sub getChoiceOrder {
	my $self    = shift;
	my @choices = ();
	foreach my $choice (@{ $self->{choices} }) {
		if (ref($choice) eq 'ARRAY') { push(@choices, $self->randomOrder($choice)) }
		else { push(@choices, $choice); push(@{ $self->{order} }, scalar(@{ $self->{order} })); }
	}
	$self->{orderedChoices} = \@choices;
	$self->{n}              = scalar(@choices);
}

sub randomOrder {
	my ($self, $choices) = @_;
	my @indices = 0 .. $#$choices;
	my @order   = map { splice(@indices, $main::PG_random_generator->random(0, $#indices), 1) } @indices;
	push(@{ $self->{order} }, map { $_ + scalar(@{ $self->{order} }) } @order);
	return map { $choices->[$_] } @order;
}

#
#  Collect the labels from those that have them, and add ones
#  to those that don't (if requested)
#
sub addLabels {
	my $self    = shift;
	my $choices = $self->{orderedChoices};
	my $labels  = $self->{labels};
	my $n       = $self->{n};

	$labels = [ 1 .. $n ]                        if $labels eq "123";
	$labels = [ @main::ALPHABET[ 0 .. $n - 1 ] ] if uc($labels) eq "ABC";
	$labels = []                                 if $labels eq "text";
	if (ref($labels) ne "ARRAY") {
		my $replace = ($labels ne "auto");
		if (!$replace) {
			foreach (@$choices) { $replace = 1 if $_ =~ m/[^-+.,;:()!\[\]a-z0-9 ]/i }
		}
		$labels                = [ map {"Choice $_"} (1 .. $n) ] if $replace;
		$self->{displayLabels} = 0                               if $self->{displayLabels} eq "auto";
	}
	$labels = [] unless ref($labels) eq "ARRAY";

	my @values = (undef) x $n;

	foreach my $i (0 .. $n - 1) {
		if (ref($choices->[$i]) eq "HASH") {
			my $key = (keys %{ $choices->[$i] })[0];
			$labels->[$i] = $key;
			if (ref($choices->[$i]{$key}) eq 'ARRAY') {
				$values[$i] = $choices->[$i]{$key}[1];
				$choices->[$i] = $choices->[$i]{$key}[0];
			} else {
				$choices->[$i] = $choices->[$i]{$key};
			}
		}
	}
	$self->{labels}        = $labels;
	$self->{displayLabels} = 1 if $self->{displayLabels} eq "auto";
	$self->{values}        = [ map { $values[$_] // $self->{values}[ $self->{order}[$_] ] // "B$_" } 0 .. $#values ];

	return;
}

#
#  Find the correct choice in the ordered array
#
sub getCorrectChoice {
	my $self  = shift;
	my $value = shift;
	if ($value =~ m/^\d+$/ && !$self->{noindex}) {
		$value = ($self->flattenChoices)[$value];
		Value::Error("The correct answer index is outside the range of choices provided")
			if !defined($value);
	}
	my @choices = @{ $self->{orderedChoices} };
	foreach my $i (0 .. $#choices) {
		if ($value eq $choices[$i] || $value eq ($self->{labels}[$i] || "")) {
			$self->{data} = [ $self->{values}[$i] ];
			return;
		}
	}
	Value::Error("The correct choice must be one of the button values");
}

sub getCheckedChoice {
	my $self  = shift;
	my $value = shift;
	return unless defined $value;
	$value = ($self->flattenChoices)[$value] if $value =~ m/^\d+$/;
	my @choices = @{ $self->{orderedChoices} };
	foreach my $i (0 .. $#choices) {
		if ($value eq $choices[$i] || $value eq ($self->{labels}[$i] || "")) {
			$self->{checkedI} = $i;
			return;
		}
	}
	Value::Error("The checked choice must be one of the button values");
}

sub flattenChoices {
	my $self    = shift;
	my @choices = map { ref($_) eq "ARRAY" ? @$_ : $_ } @{ $self->{choices} };
	foreach my $choice (@choices) {
		if (ref($choice) eq "HASH") {
			my $key = (keys %{$choice})[0];
			$choice = ref($choice->{$key}) eq 'ARRAY' ? $choice->{$key}[0] : $choice->{$key};
		}
	}
	return @choices;
}

#
#  Format a label using the user-provided format string
#
sub labelFormat {
	my $self  = shift;
	my $label = shift;
	return ""   unless $label || $self->{forceLabelFormat};
	$label = "" unless defined $label;
	sprintf($self->{labelFormat}, $self->protect($label));
}

# Convert a value string into a numeric index.
sub getIndexByValue {
	my ($self, $value) = @_;
	return -1 unless defined $value;
	my ($index) = grep { $self->{values}[$_] eq $value } 0 .. $#{ $self->{values} };
	return $index // -1;
}

#
#  Trim the selected choice or label so that it is not too long
#  to be displayed in the results table.
#
sub labelText {
	my ($self, $value) = @_;
	my $index  = $self->getIndexByValue($value);
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

#
#  Use the actual choice string rather than the value string as the output
#
sub string {
	my $self = shift;
	$self->labelText($self->value);
}

#
#  Adjust student preview and answer strings to be the actual
#  choice string rather than the value string.
#
sub cmp_preprocess {
	my $self = shift;
	my $ans  = shift;
	if (defined $ans->{student_value} && $ans->{student_value} ne '') {
		my $label = $self->labelText($ans->{student_value}->value);
		$ans->{preview_latex_string} = $self->quoteTeX($label);
		$ans->{student_ans}          = $self->quoteHTML($label);
		$ans->{original_student_ans} = $label;
	}
}

#  Allow users to convert the value string into a choice or label
sub answerChoice {
	my ($self, $value) = @_;
	my $index = $self->getIndexByValue($value);
	return $self->{orderedChoices}[$index];
}

sub answerLabel {
	my ($self, $value) = @_;
	my $index = $self->getIndexByValue($value);
	return $self->{labels}[$index];
}

#  Include the value string for the correct choice in the answer hash
sub cmp {
	my $self = shift;
	my $cmp  = $self->SUPER::cmp(
		correct_choice => $self->value,
		@_
	);
	return $cmp;
}

##################################################################
#
#  Handle old-style options (order, first, last, randomize)
#

sub compatibility {
	my $self = shift;
	foreach my $choice (@{ $self->{choices} }) {
		Value::Error("Old-style options (order, first, last, randomize) can't be used with new-style choice array")
			if ref($choice) eq "ARRAY" || ref($choice) eq "HASH";
	}
	$self->{n} = scalar(@{ $self->{choices} });
	my @choices;
	my %remaining = map { $_ => 1 } @{ $self->{choices} };

	if ($self->{order}) {

		Value::Error("You can't use 'first' or 'last' with 'order'") if $self->{first} || $self->{last};
		my @order = @{ $self->{order} };
		foreach my $i (0 .. $#order) {
			my $choice = $self->findChoice($order[$i]);
			Value::Error("Item $i of the 'order' option is not a choice.")       if !defined($choice);
			Value::Error("Item $i of the 'order' option was already specified.") if !$remaining{$choice};
			push(@choices, $choice);
			delete $remaining{$choice};
		}
		Value::Error("You must specify all choices in the 'order' option") if scalar(keys %remaining);
		$self->{choices} = \@choices;

	} elsif ($self->{first} || $self->{last}) {
		my @first = @{ $self->{first} || [] };
		my @last  = @{ $self->{last}  || [] };

		foreach my $i (0 .. $#first) {
			my $choice = $self->findChoice($first[$i]);
			Value::Error("Item $i of the 'first' option is not a choice.")       if !defined($choice);
			Value::Error("Item $i of the 'first' option was already specified.") if !$remaining{$choice};
			push(@choices, $choice);
			delete $remaining{$choice};
		}

		foreach my $i (0 .. $#last) {
			my $choice = $self->findChoice($last[$i]);
			Value::Error("Item $i of the 'last' option is not a choice.")       if !defined($choice);
			Value::Error("Item $i of the 'last' option was already specified.") if !$remaining{$choice};
			$last[$i] = $choice;
			delete $remaining{$choice};
		}

		my @remaining;
		foreach my $choice (@{ $self->{choices} }) { push(@remaining, $choice) if $remaining{$choice} }
		if (@remaining) {
			@remaining = ([@remaining]) if $self->{randomize};
			push(@choices, @remaining);
		}

		push(@choices, @last) if @last;

		$self->{choices} = \@choices;

	} elsif ($self->{randomize}) {
		$self->{choices} = [ $self->{choices} ];
	}
}

#
#  Given a choice, a label, or an index into the choices array,
#  return the choice.
#
sub findChoice {
	my $self  = shift;
	my $value = shift;
	my $index = $self->Index($value);
	return $self->{choices}[$index] unless $index == -1;
	foreach my $i (0 .. ($self->{n} - 1)) {
		my $label  = $self->{labels}[$i];
		my $choice = $self->{choices}[$i];
		$label = "" unless defined $label;
		return $choice if $label eq $value || $choice eq $value;
	}
	return undef;
}

#
#  Get a numeric index (-1 if not defined or not a number)
#
sub Index {
	my $self  = shift;
	my $index = shift;
	return -1 unless defined $index && $index =~ m/^\d$/;
	return $index;
}

#
#  Create the radio-buttons text
#
sub BUTTONS {
	my $self    = shift;
	my $extend  = shift;
	my $name    = shift;
	my $size    = shift;
	my @choices = @{ $self->{orderedChoices} };
	my @radio   = ();
	main::RECORD_IMPLICIT_ANS_NAME($name = main::NEW_ANS_NAME()) unless $name;
	my $label = main::generate_aria_label($name);

	foreach my $i (0 .. $#choices) {
		my $value = $self->{values}[$i];
		my $tag   = $choices[$i];
		$value = "%" . $value                                   if $i == $self->{checkedI};
		$tag   = $self->labelFormat($self->{labels}[$i]) . $tag if $self->{displayLabels};
		if ($i > 0) {
			push(
				@radio,
				main::NAMED_ANS_RADIO_EXTENSION(
					$name, $value, $tag,
					aria_label => $label . "option " . ($i + 1) . " ",
					id         => "${name}_$i",
					$self->{uncheckable}
					? (
						attributes => {
							data_uncheckable_radio_button => 1,
							$self->{uncheckable} =~ m/shift/i ? (data_shift => 1) : ()
						}
						)
					: (),
					@_
				)
			);
		} else {
			push(
				@radio,
				main::NAMED_ANS_RADIO(
					$name, $value, $tag, $extend,
					$self->{uncheckable}
					? (
						attributes => {
							data_uncheckable_radio_button => 1,
							$self->{uncheckable} =~ m/shift/i ? (data_shift => 1) : ()
						}
						)
					: (),
					@_
				)
			);
		}
	}

	# Taken from PGbasicmacros.pl
	# It is wrong to have \item in the radio buttons and to add itemize here,
	# but that is the way PGbasicmacros.pl does it.
	if ($main::displayMode eq 'TeX') {
		$radio[0] = "\n\\begin{itemize}\n" . $radio[0];
		$radio[-1] .= "\n\\end{itemize}\n";
	} elsif ($main::displayMode eq 'PTX') {
		$radio[0] = qq(<ul name="$name">) . "\n" . $radio[0];
		$radio[-1] .= '</ul>';
		#turn any math delimiters
		@radio = map { $_ =~ s/\\\(/<m>/g;   $_ } (@radio);
		@radio = map { $_ =~ s/\\\)/<\/m>/g; $_ } (@radio);
	} else {
		$radio[0] =
			qq{<div class="radio-buttons-container" }
			. qq{data-feedback-insert-element="$name" data-feedback-insert-method="append_content" }
			. qq{data-feedback-btn-add-class="ms-3">$radio[0]};
		$radio[-1] .= "</div>";
	}
	(wantarray) ? @radio : join(($main::displayMode eq 'PTX') ? '' : $self->{separator}, @radio);
}

sub protect {
	my $self = shift;
	my $s    = shift;
	return $s if !defined($s) || $s eq "";
	main::MODES(TeX => $self->quoteTeX($s), HTML => $self->quoteHTML($s));
}

sub buttons { shift->BUTTONS(0, '', @_) }
sub named_buttons { shift->BUTTONS(0, @_) }

sub ans_rule                 { shift->BUTTONS(0, '', @_) }
sub named_ans_rule           { shift->BUTTONS(0, @_) }
sub named_ans_rule_extension { shift->BUTTONS(1, @_) }

##################################################################

1;
