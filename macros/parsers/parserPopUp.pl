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

parserPopUp.pl - Drop-down lists compatible with MathObjects,
	         specifically MultiAnswer objects.

=head1 DESCRIPTION

This file implements drop-down select objects that are compatible
with MathObjects, and in particular, with the MultiAnswer object, and
with PGML.

To create a PopUp, DropDown, or DropDownTF  object, use

    $popup     = PopUp([ choices, ... ], correct, options);
    $dropdown  = DropDown([ choices, ... ], correct, options);
    $truefalse = DropDownTF(correct, options);

where "choices" are the items in the drop-down list, "correct" is the
the correct answer for the group (or its index, with 0 being the
first one), and options are chosen from among those listed below.  If
the correct answer is a number, it is interpreted as an index, even
if the array of choices are also numbers.  (See the C<noindex> below
for more details.)

Note that drop-down menus can not contain mathematical notation, only
plain text. This is because the browser's native menus are used, and
these can contain only text, not mathematics or graphics.

The difference between C<PopUp()> and C<DropDown() >is that in HTML,
the latter will have an unselectable placeholder value.  This value
is '?' by default, but can be customized with a C<placeholder> option.

C<DropDownTF()> is like C<DropDown> with options being localized
versions of "True" and "False". 1 is understood as "True" and 0 as
"False". The initial letter of the localized word is understood as
that word if those letter are different. All of this is not case
sensitive. Also, in static output (PDF, PTX) C<showInStatic> defaults
to 0. It is assumed that text preceding the drop-down makes the menu
redundant.

The entries in the choices array can either be the actual strings to
be used in the drop-down menu (which is known as a "label" for the
option input in HTML) or C<< { label => value } >> where C<label> is
the text string to display in the drop-down list and C<value> is the
value to for the option input for this choice. The "value" is what is
actually submitted when a student submits an answer, and this is what
will appear in the past answers table, feedback messages, etc. If an
option is not set as a hash in this way, the text of the option serves
as both the label and the value.

By default, the choices are left in the order that you provide them,
but you can cause some or all of them to be ordered randomly by
enclosing those that should be randomized within a second set of
brackets.  For example

    $dropdown = DropDown(
        [
            "First Item",
            [ "Random 1", "Random 2", "Random 3" ],
            "Last Item"
        ],
        "Random 3"
    );

will make a list of options that has the first item always on top,
the next three ordered randomly, and the last item always on the
bottom.  In this example

    $dropdown = DropDown([ [ "Random 1", "Random 2", "Random 3" ] ], 2);

all the entries are randomized, and the correct answer is "Random 3"
(the one with index 2 in the flattened list).  You can have as many
randomized groups as you want, with as many static items in between.

The C<options> are taken from the following list:

=over

=item C<S<< values => array reference >>>

Values are the form of the student answer that is actually submitted
when the student submits an answer. They will be displayed in the past
answers table for this answer, appear in feedback messages, etc.  By
default these are the option text (aka the option label).  However,
that can be changed either with this option or by specifying the
choices as C<< { label => value } >> as described previously.  If this
option is used, then it must be set as a reference to an array
containing the values for the options.  For example:

    values => [ 'first choice', 'second choice', ... ]

If a choice is not represented in the hash, then the option text  will
be used for the value instead.

These values can be any descriptive string that is unique for the
choice, but care should be taken to ensure that these values do not
indicate which choice is the correct answer.

Note that values given via C<< { label => value } >> will override any
values given by the C<values> option if both are provided for a
particular choice.

=item C<S<< noindex => 0 or 1 >>>

Determines whether or not a numeric value for the correct answer is
interpreted as an index for the choice array or not.  If set to 1,
then the number is treated as the literal correct answer, not an index
to it.  Default: 0

=item C<S<< placeholder => string >>>

If nonempty, this will be the first option in the drop-down list.  It
will be unselectable and grayed out, indicating that it is not an
option the user can/should actually select and submit.  Default: ''
for C<PopUp>, '?' for C<DropDown> and C<DropDownTF>

=item C<S<< showInStatic => 0 or 1 >>>

In static output, such as PDF or PTX, this controls whether or not
the list of answer options is displayed.  (The text preceding the list
of answer options might make printing the answer option list
unnecessary in a static output format.)  Default: 1, except 0 for
DropDownTF.

=back

To insert the drop-down into the problem text when using PGML:

    BEGIN_PGML
    [_]{$dropdown}
    END_PGML

Or when not using PGML:

    BEGIN_TEXT
    \{$dropdown->menu\}
    END_TEXT

and then to get the answer checker for the drop-down:

    ANS($dropdown->cmp);


You can use the PopUp, DropDown, and DropDownTF object in MultiAnswer
objects.  This is the reason for the C<ans_rule()> method (since that
is what MultiAnswer calls to get answer rules).  Just pass the object
as one of the arguments of the MultiAnswer constructor.

When writing a custom answer checker involving a PopUp, DropDown, or
DropDownTF object (e.g. if it is part of a MultiAnswer and its answer
depends on, or affects, the answers given to other parts), note that
the actual answer strings associated to one of these objects (which
are those appearing in the "student answer" argument passed to a
custom answer checker) are not the supplied option text (aka the
labels), but rather they the option values.  These are the values
given by the C<values> option or C<< { label => value } >> choice
format if provided. Otherwise they are an internal implementation
detail whose format should not be depended on.  In any case, you can
convert these value strings to a choice string (aka label string) with
the method C<answerLabel>.

=cut

loadMacros('MathObjects.pl');

sub _parserPopUp_init { parser::PopUp::Init() };    # don't reload this file

#
#  The package that implements pop-up menus
#
package parser::PopUp;
our @ISA = ('Value::String');

#
#  Set up the main:: namespace
#
sub Init {
	main::PG_restricted_eval('sub PopUp {parser::PopUp->new(@_)}');
	main::PG_restricted_eval('sub DropDown {parser::PopUp->DropDown(@_)}');
	main::PG_restricted_eval('sub DropDownTF {parser::PopUp->DropDownTF(@_)}');
}

#
#  Create a new PopUp object
#
sub new {
	my $self  = shift;
	my $class = ref($self) || $self;
	shift if Value::isContext($_[0]);    # remove context, if given (it is not used)
	my $choices = shift;
	my $value   = shift;
	my %options = @_;
	Value::Error("A PopUp's first argument should be a list of menu items")
		unless ref($choices) eq 'ARRAY';
	Value::Error("A PopUp's second argument should be the correct menu choice")
		unless defined($value) && $value ne "";
	#
	# make a context in which arbitrary strings can be entered
	#
	my $context = Parser::Context->getCopy("Numeric");
	$context->{name} = "PopUp";
	$context->parens->clear();
	$context->variables->clear();
	$context->constants->clear();
	$context->operators->clear();
	$context->functions->clear();
	$context->strings->clear();
	$context->{pattern}{number}         = "^\$";
	$context->variables->{patterns}     = {};
	$context->strings->{patterns}{".*"} = [ -20, 'str' ];
	$context->{parser}{String}          = "parser::PopUp::String";
	$context->update;
	$self = bless {
		data         => [$value],
		context      => $context,
		choices      => $choices,
		placeholder  => $options{placeholder}  // '',
		showInStatic => $options{showInStatic} // 1,
		values       => $options{values}       // [],
		noindex      => $options{noindex}      // 0
	}, $class;
	$self->getChoiceOrder;
	$self->addLabelsValues;
	$self->getCorrectChoice($value);
	return $self;
}

#
#  Get the choices into the correct order (randomizing where requested)
#
sub getChoiceOrder {
	my $self    = shift;
	my @choices = ();
	foreach my $choice (@{ $self->{choices} }) {
		if (ref($choice) eq "ARRAY") { push(@choices, $self->randomOrder($choice)) }
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
#  Collect the labels and values
#
sub addLabelsValues {
	my $self    = shift;
	my $choices = $self->{orderedChoices};
	my $labels  = [];
	my $values  = $self->{values};
	my $n       = $self->{n};

	foreach my $i (0 .. $n - 1) {
		if (ref($choices->[$i]) eq "HASH") {
			$labels->[$i] = (keys %{ $choices->[$i] })[0];
			$values->[$i] = $choices->[$i]{ $labels->[$i] };
		} else {
			$labels->[$i] = $choices->[$i];
			$values->[$i] = $choices->[$i] unless (defined($values->[$i]) && $values->[$i] ne '');
		}

	}
	$self->{labels} = $labels;
	$self->{values} = $values;

	return;
}

#
#  Find the correct choice in the ordered array
#
sub getCorrectChoice {
	my $self  = shift;
	my $label = shift;
	if ($label =~ m/^\d+$/ && !$self->{noindex}) {
		$label = ($self->flattenChoices)[$label];
		Value::Error("The correct answer index is outside the range of choices provided")
			if !defined($label);
	}
	my @choices = @{ $self->{orderedChoices} };
	foreach my $i (0 .. $#choices) {
		if ($label eq $self->{labels}[$i]) {
			$self->{data} = [ $self->{labels}[$i] ];
			return;
		}
	}
	Value::Error("The correct choice must be one of the PopUp menu items");
}

sub flattenChoices {
	my $self    = shift;
	my @choices = map { ref($_) eq "ARRAY" ? @$_ : $_ } @{ $self->{choices} };
	foreach my $choice (@choices) {
		if (ref($choice) eq "HASH") {
			$choice = (keys %{$choice})[0];
		}
	}
	return @choices;
}

# Convert a value string into a numeric index.
sub getIndexByValue {
	my ($self, $value) = @_;
	return -1 unless defined $value;
	my ($index) = grep { $self->{values}[$_] eq $value } 0 .. $#{ $self->{values} };
	return $index // -1;
}

#
#  Use the actual choice string (aka label) rather than the value string as the output
#
sub string {
	my $self  = shift;
	my $value = $self->value;
	my $index = $self->getIndexByValue($value);
	return $self->{labels}[$index];
}

#
#  Adjust student preview and answer strings to be the actual
#  choice string rather than the value string.
#
sub cmp_preprocess {
	my $self = shift;
	my $ans  = shift;
	if (defined $ans->{student_value} && $ans->{student_value} ne '') {
		my $value = $ans->{student_value}->value;
		my $index = $self->getIndexByValue($value);
		my $label = $self->{labels}[$index];
		$ans->{preview_latex_string} = $self->quoteTeX($label);
		$ans->{student_ans}          = $self->quoteHTML($label);
		$ans->{original_student_ans} = $label;
	}
}

#  Allow users to convert the value string into a label

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

sub menu { shift->MENU(0, @_) }

sub MENU {
	my $self    = shift;
	my $extend  = shift;
	my $name    = shift;
	my $size    = shift;
	my %options = @_;
	my @list    = @{ $self->{labels} };
	my $menu    = "";
	main::RECORD_IMPLICIT_ANS_NAME($name = main::NEW_ANS_NAME()) unless $name;
	my $answer_value = (defined($main::inputs_ref->{$name}) ? $main::inputs_ref->{$name} : '');
	my $aria_label   = main::generate_aria_label($name);

	if ($main::displayMode =~ m/^HTML/) {
		$menu = main::tag(
			'span',
			class                       => 'text-nowrap',
			data_feedback_insert_elt    => $name,
			data_feedback_insert_method => 'append_content',
			main::tag(
				'select',
				class      => 'pg-select',
				name       => $name,
				id         => $name,
				aria_label => $aria_label,
				size       => 1,
				(
					$self->{placeholder}
					? main::tag(
						'option',
						disabled => undef,
						selected => undef,
						value    => '',
						class    => 'tex2jax_ignore',
						$self->{placeholder}
						)
					: ''
					)
					. join(
						'',
						map {
							main::tag(
								'option', $self->{values}[$_] eq $answer_value ? (selected => undef) : (),
								value => $self->{values}[$_],
								class => 'tex2jax_ignore',
								$self->quoteHTML($self->{labels}[$_], 1)
							)
						} (0 .. $#list)
					)
			)
		);
	} elsif ($main::displayMode eq 'PTX') {
		if ($self->{showInStatic}) {
			$menu = main::tag(
				'fillin',
				name => $name,
				join('', map { main::tag('choice', $self->quoteXML($_)) } (@list))
			);
		} else {
			$menu = qq(<fillin name="$name"/>);
		}
	} elsif ($main::displayMode eq "TeX" && $self->{showInStatic}) {
		# if the total number of characters is not more than
		# 30 and not containing / or ] then we print out
		# the select as a string: [A/B/C]
		if (length(join('', @list)) < 25
			&& !grep(/(\/|\[|\])/, @list))
		{
			$menu = '[' . join('/', map { $self->quoteTeX($_) } @list) . ']';
		} else {
			#otherwise we print a bulleted list
			$menu = '\par\vtop{\def\bitem{\hbox\bgroup\indent\strut\textbullet\ \ignorespaces}\let\eitem=\egroup';
			$menu = "\n" . $menu . "\n";
			foreach my $option (@list) {
				$menu .= '\bitem ' . $self->quoteTeX($option) . "\\eitem\n";
			}
			$menu .= '\vskip3pt}' . "\n";
		}
	}
	main::RECORD_ANS_NAME($name, $answer_value) unless $extend;    # record answer name
	main::INSERT_RESPONSE($options{answer_group_name}, $name, $answer_value) if $extend;
	return $menu;
}

#
#  Answer rule is the menu list
#
sub ans_rule                 { shift->MENU(0, '', @_) }
sub named_ans_rule           { shift->MENU(0, @_) }
sub named_ans_rule_extension { shift->MENU(1, @_) }

#
# DropDown() variant of PopUp() with placeholder
#

sub DropDown {
	my $self    = shift;
	my $choices = shift;
	my $value   = shift;
	my %options = (
		placeholder => '?',
		@_
	);
	return parser::PopUp->new($choices, $value, %options);
}

#
# TrueFalse() variant of PopUp()
#

sub DropDownTF {
	my $self    = shift;
	my $value   = lc(main::maketext(shift));
	my %options = (
		showInStatic => 0,
		@_
	);
	my $true         = main::maketext('True');
	my $false        = main::maketext('False');
	my %sanitization = (
		lc($true)  => $true,
		1          => $true,
		lc($false) => $false,
		0          => $false
	);
	if (lc(substr($true, 0, 1)) ne lc(substr($false, 0, 1))) {
		$sanitization{ lc(substr($true,  0, 1)) } = $true;
		$sanitization{ lc(substr($false, 0, 1)) } = $false;
	}
	my $sanitized_value = $sanitization{$value};
	Value->Error("The value should be one of $true or $false") unless defined $sanitized_value;
	return parser::PopUp->DropDown([ $true, $false ], $sanitized_value, %options);
}

##################################################
#
#  Replacement for Parser::String that takes the
#  complete parse string as its value
#
package parser::PopUp::String;
our @ISA = ('Parser::String');

sub new {
	my $self = shift;
	my ($equation, $value, $ref) = @_;
	$value = $equation->{string};
	$self->SUPER::new($equation, $value, $ref);
}

##################################################

1;
