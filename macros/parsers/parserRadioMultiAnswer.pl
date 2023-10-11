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

parserRadioMultiAnswer.pl - Radio answer questions with dependent answers.

=head1 DESCRIPTION

RadioMultiAnswer objects let you tie a radio answer together with several answer blanks that are
dependent on the radio choice.  The RadioMultiAnswer produces a single result in the answer
results area.  This macro requires javascript to function properly.

To create a RadioMultiAnswer pass a list of lists each with an sprintf-style string and answers,
followed by the index of the correct part to RadioMultiAnswer() in the order they will appear in
the problem.  For example:

    $rma = RadioMultiAnswer([
               ['The unique solution is \(x=\) %s and \(y=\) %s.', 5, 6],
               ['There are an infinite number of solutions parameterized by '
                    . '\(x=\) %s and \(y=\) %s.', '23-3t', 't']
               ['There are no solutions.']
           ], 0);

The sprintf C<'%s'> format specifiers are where the answer rules for the answers listed in the
part will be placed.  If C<'%s*'> is used instead of the C<'%s'> format specifier, then an
answer array will be used instead of a single answer rule for that answer.  In each part there
should be one of these format specifiers for each answer in that part.

Then, use $rma->ans_rule to create the radio parts and answer blanks inside.  Note that you only
call ans_rule once for each RadioMultiAnswer object.  You can pass the width of all of the
blanks, which defaults to 20 otherwise.  For example:

    BEGIN_TEXT
    Solve the system of linear equations \(x+3y = 23\) and \(2x+y=16\).

    \{$rma->ans_rule(10)\}
    END_TEXT

Then, call $rma->cmp to produce the answer evaluator for the RadioMultiAnswer.

For PGML:

    BEGIN_PGML
    Solve the system of linear equations [`x+3y=23`] and [`2x+y=16`].

    [__________]{$rma}
    END_PGML

You may provide a checker routine that will be called to determine if the answers are correct or
not.  If one is not provided a default checker will be used.  The default checker returns 1 if
the student selects the correct radio answer, and all answers in that part are equal to correct
answers in that part.  The checker will only be called if the student answers have no syntax
errors and their types match the types of the correct answers, so you don't have to worry about
handling bad data from the student (at least as far as type checking goes).

The checker routine should accept four parameters:  a reference to the array of correct answers,
a reference to the array of student answers, a reference to the RadioMultiAnswer itself, and a
reference to the answer hash.  It should do whatever checking it needs to do and then return a
score for the RadioMultiAnswer as a whole (every answer blank will be given the same score).
You can add error messages in the checker routine by calling the RadioMultiAnswer's
appendMessage() method.  For example:

    $rma->appendMessage('The function can't be the identity');

You can also call Value::Error() in the checker routine to generate an error and die.

The checker routine can be supplied either when the RadioMultiAnswer is created, or when the
cmp() method is called.  For example:

    $rma = RadioMultiAnswer(...,
        checker => sub {
            my ($correct, $student, $self, $ans) = @_; # get the parameters
            my ($radio_cor, $a_cor, $b_cor) = @$correct; # extract the correct answers
            my ($radio_stu, $a_stu, $b_stu) = @$student; # extract the student answers
            return ($radio_cor == $radio_stu
                && $a_cor->[0] == $a_stu->[0]
                && $a_cor->[1] == $a_stu->[1]);
        }
    );
    ANS($rma->cmp);

or

    $rma = RadioMultiAnswer(...);
    sub check {
        my ($correct, $student, $self, $ans) = @_; # get the parameters
        my ($radio_cor, $a_cor, $b_cor) = @$correct; # extract the correct answers
        my ($radio_stu, $a_stu, $b_stu) = @$student; # extract the student answers
        return ($radio_cor == $radio_stu
            && $a_cor->[0] == $a_stu->[0]
            && $a_cor->[1] == $a_stu->[1]);
    };
    ANS($rma->cmp(checker => ~~&check));

See the checker option below for more details.

=head1 CONSTRUCTOR

    RadioMultiAnswer([['First part %s, %s', $answer1, $answer2],
                      ['Second part %s, %s', $answer3, $answer4],
                      ['Third part']], 0);
    RadioMultiAnswer(...)->with(...);

Create a new RadioMultiAnswer item from a list of lists each of which has a first element that
is a sprintf style string and the remaining elements of each list are items. The items are
converted to Value items, if they aren't already.

=head1 OPTIONS

There are a number of options that you can set.  These can be passed directly to the constructor
or set as parameters to the with() method called on the RadioMultiAnswer object.

=over

=item checker (Default: undef)

A subroutine to be called to check the student answers.  The routine is passed four parameters:
a reference to the array of correct answers, a reference to the array of student answers, a
reference to the RadioMultiAnswer object itself, and a reference to the checker's answer hash.
The routine should return a score from 0 to 1.  If this is not defined, then this will be set to
a default checker that returns 1 if the student selects the correct radio answer, and all
answers in that part are equal to correct answers in that part, and 0 otherwise.

The structures of the array of student answers and the array of correct answers are the same.
The first entry of each will be a number from 1 up to the number of radio answers in the
problem.  The remaining entries will be array references to the answers for each part.  So the
first entry can be used to access the index of the array containing the answers for the correct
part.  For example, $correct->[$correct->[0]] and $student->[$correct->[0]].  Note that the
student answers in the parts that are not selected will always be blank.  This is enforced by
javascript.

So, for the CONSTRUCTOR example shown above the correct answer array will be

    [ 1, [ $answer1, $answer2 ], [ $answer3, $answer4 ], [] ]

and if the student selects the incorrect second part, then the student answer array will be:

    [ 2, [ '', '' ], [ '5t+2', 't' ], [] ]

where the entries in the latter arrays are not actually strings but are MathObjects.

=item namedRules (Default: namedRules => 0)

Whether to use named rules or default rule names.  Use named rules if you need to intersperse
other rules with the one for the RadioMultiAnswer, in which case you must use NAMED_ANS not ANS.

=item cmpOpts (Default: cmpOpts => undef)

This is a hash of options that will be passed to the cmp method.  For example,
C<< cmpOpts => { weight => 0.5 } >>.  This option is provided to make it more convenient to pass
options to cmp when utilizing PGML.

=item checkTypes (Default: checkTypes => 1)

Whether the types of the student and correct answers must match exactly or just pass the usual
type-match error checking (in which case, you should check the types before you use the data).

=item allowBlankAnswers (Default: allowBlankAnswers => 0)

Whether to remove the blank-check pre-filter from the answer checkers that is used for type
checking the student's answers.

=item separator (Default: separator => "; ")

The string to use between entries in the results area.

=item tex_separator (Default: tex_separator => ";\,"

The string to use between entries in the preview area.

=item formats (Default: formats => undef)

A reference to a list of sprintf-style strings used to format the students answers for the
results area.  If undefined, the separator parameter (above) is used to form the string.

=item tex_formats (Default: tex_formats => undef)

A reference to a list of sprintf-style string used to format the students answer previews when
singleResults mode is in effect.  If undefined, the tex_separator (above) is used to form the
string.

=item size (Default: size => undef)

A number or a nested list that gives the sizes of the answer blanks.  If this is a number then
all answer rules will use that for the size.  If this is a nested list, then it should contain a
list of sizes for each rule in each part.  If there are not enough sizes in each sub list, then
a default of 20 will be used.  If this is not defined, then WeBWorK defaults will be used.  The
sizes of the answer blanks can also be set via the argument to ans_rule.  The same types of
arguments are accepted there.

=item labels (Default: labels => "ABC")

This determines what label to show for each choice.  The default is "S<< ABC >>", which results in
upper case alphabetic labels, starting with S<< A >>.  If the value is "S<< 123 >>" then the
choices will be labeled with numbers.  The value of labels may also be a list of labels for each
choice (e.g. C<[label1,label2,...]>).  Note that if you give a list of labels and do not supply
enough labels for the number of radio choices in your problem, expect inconsistent labelling.

=item values (Default: values => [])

Values are the form of the student answer that will be displayed in the past answers table for the
radio button choices part of the answer.  By default these are B0, B1, etc.  However, that can be
changed with this option.  The value of the option should be a reference to an array containing the
values for the choices.  For example:

    values => [ 'first choice', 'second choice', ... ]

If a choice is not represented in the hash, then C<Bn> will be used for the value instead where C<n>
is the 0 based index of the choice.

These values can be any descriptive string that is unique for the choice, but care should be taken
to ensure that these values do not indicate which choice is the correct answer.

=item labelFormat (Default: labelFormat => C<${BBOLD}%s.${EBOLD}>)

Specifies a format string to use when displaying labels before the choice text.  It is an
sprintf string that contains C<'%s'> where the label should go.  The default value produces the
label followed by a period in bold.

=item displayLabels (Default: displayLabels => 1)

Specifies whether labels should be displayed after the radio button and before its text.  This
makes the association between the choices and the label used as an answer more explicit.

=item checked (Default: checked => undef)

The index (starting at zero) of the radio button to be checked initially.  By default this is
undefined, which means that none of the radio buttons are initially checked.

=item uncheckable (Default: uncheckable => 0)

If this is set to 1 or "shift" then it is possible to uncheck a radio button by clicking it when it
is checked.  If this is set to "shift", unchecking requires the shift key to be pressed.

=back

=cut

BEGIN { strict->import }

loadMacros('MathObjects.pl', 'PGbasicmacros.pl');

sub _parserRadioMultiAnswer_init {
	ADD_CSS_FILE('js/RadioMultiAnswer/RadioMultiAnswer.css', 0);
	ADD_JS_FILE('js/RadioMultiAnswer/RadioMultiAnswer.js', 0, { defer => undef });
	main::PG_restricted_eval('sub RadioMultiAnswer { parser::RadioMultiAnswer->new(@_) }');
	return;
}

package parser::RadioMultiAnswer;
our @ISA = qw(Value Value::String);

our $answerPrefix = 'RaDiOMuLtIaNsWeR_';    # answer rule prefix

my @ans_defaults = (
	checker             => sub {0},
	showCoordinateHints => 0,
	showEndpointHints   => 0,
	showEndTypeHints    => 0
);

sub new {
	my ($self, @inputs) = @_;
	my $class   = ref($self) || $self;
	my $context = Value::isContext($inputs[0]) ? shift @inputs : $self->context;
	my $data    = shift @inputs;
	my $correct = shift @inputs;

	Value::Error(q{A RadioMultiAnswer's first argument should be a list of lists of radio formats and answers.})
		unless ref($data) eq 'ARRAY';
	Value::Error(q{A RadioMultiAnswer's second argument should be the correct choice.})
		unless defined $correct && $correct ne '';

	my %options;
	main::set_default_options(
		\%options,
		labels            => 'ABC',
		displayLabels     => 1,
		labelFormat       => "${main::BBOLD}%s.${main::EBOLD}",
		values            => [],
		namedRules        => 0,
		cmpOpts           => undef,
		checkTypes        => 1,
		allowBlankAnswers => 0,
		tex_separator     => ';\,',
		separator         => '; ',
		tex_formats       => undef,
		formats           => undef,
		size              => undef,
		checked           => undef,
		uncheckable       => 0,
		@inputs
	);

	my (@cmp, @values);
	for (@$data) {
		Value::Error("Each part of a RadioMultiAnswer should be a list with at least one element,\n"
				. 'which must be an sprintf style string.')
			unless ref($_) eq 'ARRAY' && @$_;
		my @itemCmps;
		for my $x (@$_[ 1 .. $#$_ ]) {
			$x = Value::makeValue($x, context => $context) unless Value::isValue($x);
			push(@itemCmps, $x->cmp(@ans_defaults));
		}
		push(@cmp,    [@itemCmps]);
		push(@values, $options{values}[ scalar(@values) ] // ('B' . scalar(@values)));
	}

	return bless {
		%options,
		data          => $data,
		cmp           => \@cmp,
		values        => \@values,
		correct       => $correct,
		ans           => [],
		isValue       => 1,
		context       => $context,
		errorMessages => []
	}, $class;
}

# Convert a value string into a numeric index.
sub getIndexByValue {
	my ($self, $value) = @_;
	return -1 unless defined $value;
	my ($index) = grep { $self->{values}[$_] eq $value } 0 .. $#{ $self->{values} };
	return $index // -1;
}

# Creates an answer evaluator to be passed to ANS() or an array with a label and answer
# evaluator to be passed to LABELED_ANS().  Any parameters are passed to the individual answer
# evaluators.  A default checker is supplied if one is not supplied by the problem author.  This
# checker returns 1 if the student selects the correct radio answer, and all answers in that
# part are equal to correct answers in that part.
sub cmp {
	my ($self, %options) = @_;

	%options = (%options, %{ $self->{cmpOpts} }) if ref($self->{cmpOpts}) eq 'HASH';

	for my $id ('checker', 'separator') {
		$self->{$id} = delete $options{$id} if defined $options{$id};
	}

	unless (ref($self->{checker}) eq 'CODE') {
		$self->{checker} = sub {
			my ($correct, $student, $self, $ans) = @_;
			return 0 if ($correct->[0] != $student->[0]);

			for (0 .. $#{ $correct->[ $correct->[0] ] }) {
				return 0 if $correct->[ $correct->[0] ][$_] != $student->[ $correct->[0] ][$_];
			}

			return 1;
		};
	}

	if ($self->{allowBlankAnswers}) {
		for (@{ $self->{cmp} }) {
			for my $cmp (@$_) {
				$cmp->install_pre_filter('erase');
				$cmp->install_pre_filter(sub {
					my $ans = shift;
					$ans->{student_ans} =~ s/^\s+//g;
					$ans->{student_ans} =~ s/\s+$//g;
					return $ans;
				});
			}
		}
	}

	my @correct;
	my @correct_tex;
	# Only the radio answer and the answers in the correct part are needed.
	push(@correct,     $self->quoteHTML($self->label($self->{correct}))) if $self->{displayLabels};
	push(@correct_tex, $self->quoteTeX($self->label($self->{correct})))  if $self->{displayLabels};
	for (@{ $self->{cmp}[ $self->{correct} ] }) {
		push(@correct,     $_->{rh_ans}{correct_ans});
		push(@correct_tex, $_->{rh_ans}{correct_ans_latex_string} || $_->{rh_ans}{correct_value}->TeX);
	}
	my $ans = AnswerEvaluator->new;
	$ans->ans_hash(
		correct_ans => (
			(ref($self->{formats}) eq 'ARRAY' && $#{ $self->{formats} } >= $self->{correct})
			? sprintf($self->{formats}[ $self->{correct} ], @correct)
			: join($self->{separator}, @correct)
		),
		correct_ans_latex_string => (
			ref($self->{tex_formats}) eq 'ARRAY' && $#{ $self->{tex_formats} } >= $self->{correct}
			? sprintf($self->{tex_formats}[ $self->{correct} ], @correct_tex)
			: join($self->{tex_separator}, @correct_tex)
		),
		type             => 'RadioMultiAnswer',
		correct_choice   => $self->{values}[ $self->{correct} ],
		feedback_options => sub {
			my ($ansHash, $options) = @_;

			# Find the radio buttons (not including and checks or radios in sub parts).
			my $radios = $options->{feedbackElements}->grep(sub { $_->attr('name') eq $self->ANS_NAME(0) });

			return unless @$radios;    # Sanity check. This shouldn't happen.

			$options->{insertMethod} = 'append_content';
			$options->{btnAddClass}  = 'ms-3';

			# Find the checked radios, and if there is one, the answers in that part.
			# Those will be the elements that the feedback classes are added to.
			my $selected = $radios->grep(sub { exists $_->attr->{checked} });
			if (@$selected == 1) {
				$options->{insertElement} = $selected->first->parent;
				my $contents = $selected->first->parent->at('div.radio-content[data-radio]');
				if ($contents) {
					my $partNames = JSON->new->decode($contents->attr('data-part-names'));
					push(@$selected, $contents->at(qq{[name="$_"]})) for (@$partNames);
					$options->{feedbackElements} = $selected;
				}
			} else {
				$options->{insertElement} = $radios->first->parent->parent;
			}
		},
		%options
	);
	$ans->install_evaluator(sub { my $ans = shift; (shift)->answer_evaluator($ans) }, $self);
	$ans->install_pre_filter('erase');    # Don't do blank check.

	return ($self->ANS_NAME(0), $ans) if $self->{namedRules};
	return $ans;
}

# Check the answers.  First, call individual answer checkers to get any type-check errors.  Then
# perform the user's checker routine.  Finally collect the individual answers and errors and
# combine them for the single result.
sub answer_evaluator {
	my ($self, $ans) = @_;
	$ans->{_filter_name} = 'RadioMultiAnswer Evaluator';

	my $part = 1;
	for (0 .. $#{ $self->{cmp} }) {
		for my $j (0 .. $#{ $self->{cmp}[$_] }) {
			$self->{ans}[$_][$j] = $self->{cmp}[$_][$j]->evaluate($main::inputs_ref->{ $self->ANS_NAME($part++) });
		}
	}
	$ans->{original_student_ans} = $main::inputs_ref->{ $self->ANS_NAME(0) };
	return $ans if !defined $ans->{original_student_ans} || $ans->{original_student_ans} eq '';
	my (@errors, @student, @latex, @text);
	$self->perform_check($ans);
	my $stu_index = $self->getIndexByValue($ans->{original_student_ans});
	# Only the radio answer and the answers in the selected part are needed.
	push(@latex,   $self->quoteTeX($self->label($stu_index)))  if $self->{displayLabels};
	push(@text,    $self->quoteHTML($self->label($stu_index))) if $self->{displayLabels};
	push(@student, $self->quoteHTML($self->label($stu_index))) if $self->{displayLabels};
	for my $result (@{ $self->{ans}[$stu_index] }) {
		push(@latex,   '{' . check_string($result->{preview_latex_string}, '\_\_') . '}');
		push(@text,    check_string($result->{preview_text_string}, '__'));
		push(@student, check_string($result->{student_ans},         '__'));
		if ($result->{ans_message}) {
			push(
				@errors,
				main::tag(
					'tr',
					style => 'vertical-align:top',
					main::tag('td', style => 'text-align:left', $result->{ans_message})
				)
			);
		}
	}
	for (@{ $self->{errorMessages} }) {
		push(@errors, main::tag('tr', style => 'vertical-align:top', main::tag('td', style => 'text-align:left', $_)));
	}
	$ans->{ans_message} = $ans->{error_message} = '';
	if (@errors) {
		$ans->{ans_message} = $ans->{error_message} = main::tag(
			'table',
			style => 'border-collapse:collapse',
			class => 'ArrayLayout',
			join(main::tag('tr', main::tag('td', style => 'height:4px')), @errors)
		);
	}

	$ans->{preview_latex_string} =
		(ref($self->{tex_formats}) eq 'ARRAY' && $#{ $self->{tex_formats} } >= $stu_index
			? sprintf($self->{tex_formats}[$stu_index], @latex)
			: join($self->{tex_separator}, @latex));
	$ans->{preview_text_string} =
		(ref($self->{formats}) eq 'ARRAY' && $#{ $self->{formats} } >= $stu_index
			? sprintf($self->{formats}[$stu_index], @text)
			: join($self->{separator}, @text));
	$ans->{student_ans} =
		(ref($self->{formats}) eq 'ARRAY' && $#{ $self->{formats} } >= $stu_index
			? sprintf($self->{formats}[$stu_index], @student)
			: join($self->{separator}, @student));

	return $ans;
}

# Return a given string or a default if it is empty or not defined
sub check_string {
	my $s = shift;
	$s = shift unless defined $s && $s =~ m/\S/ && $s ne '{\rm }' && $s ne '\text{}';
	return $s;
}

# Collect the correct and student answers, and call the user's checker routine.  If any of the
# answers in the selected part produced errors or the types don't match, don't call the user's
# routine.  Otherwise, call it, and if there was an error, report that.  Set the score from the
# supplied checker.
sub perform_check {
	my ($self, $rh_ans) = @_;
	$self->context->clearError;
	my @correct;
	my @student;
	# The answers for all parts are sent to the grader.  The answers in the incorrect parts from
	# the correct answer may be used in the grader.  The answers for each part are in a separate
	# list.  The radio answer is sent as the numerical index of the choice.  The count starts at
	# one, so that it is the location in the list sent to the grader of the answers for the
	# selected part (the radio answer is in position 0).
	push(@correct, $self->{correct} + 1);
	push(@student, $self->getIndexByValue($main::inputs_ref->{ $self->ANS_NAME(0) }) + 1);
	my $part_index = 1;
	for my $part (@{ $self->{ans} }) {
		my @part_correct;
		my @part_student;
		for my $ans (@$part) {
			push(@part_correct, $ans->{correct_value});
			push(@part_student, $ans->{student_value});
			# Only check types for the student's selected part.
			next   if $student[0] != $part_index;
			return if $ans->{ans_message} ne '' || !defined $ans->{student_value};
			return
				if ($self->{checkTypes}
					&& $ans->{student_value}->type ne $ans->{correct_value}->type
					&& !($self->{allowBlankAnswers} && $ans->{student_ans} !~ m/\S/));
		}
		push(@correct, [@part_correct]);
		push(@student, [@part_student]);
		++$part_index;
	}
	$rh_ans->{isPreview} = $main::inputs_ref->{previewAnswers}
		|| ($main::inputs_ref->{action} && $main::inputs_ref->{action} =~ m/^Preview/);
	$self->{errorMessages} = [];
	my $result = Value::cmp_compare([@correct], [@student], $self, $rh_ans);
	if (!defined $result && $self->context->{error}{flag}) { $self->cmp_error($self->{ans}[0]); return 1; }
	if (Value::matchNumber($result)) {
		$rh_ans->score($result);
	} else {
		die "Checker subroutine should return a number ($result)";
	}
	return;
}

# The user's checker can call appendMessage(message) to add an error message.
sub appendMessage {
	my ($self, @messages) = @_;
	for (@messages) { push(@{ $self->{errorMessages} }, $_) if $_ ne ''; }
	return;
}

# Produce the name for an answer blank.  (Use the standard name for the first one, and create
# the prefixed names for the rest.)
sub ANS_NAME {
	my ($self, $i) = @_;
	return $self->{answerNames}{$i} if defined $self->{answerNames}{$i};
	main::RECORD_IMPLICIT_ANS_NAME($self->{answerNames}{0} = main::NEW_ANS_NAME())
		unless defined $self->{answerNames}{0};
	$self->{answerNames}{$i} = $answerPrefix . $self->{answerNames}{0} . '_' . $i unless $i == 0;
	return $self->{answerNames}{$i};
}

# Produce the label for a part of the radio answer.
sub label {
	my ($self, $i) = @_;
	return $self->{labels}[$i] if ref($self->{labels}) eq 'ARRAY' && $#{ $self->{labels} } >= $i;

	$self->{labels} = [ @main::ALPHABET[ 0 .. $#{ $self->{data} } ] ] if uc($self->{labels}) eq 'ABC';
	$self->{labels} = [ 1 .. @{ $self->{data} } ]                     if $self->{labels} eq '123';

	# Fill with additional alphabetic labels as needed.
	# This is a fallback and if used indicates a failure of the problem author to use this macro correctly.
	$self->{labels} = [] unless ref($self->{labels}) eq 'ARRAY';
	for (0 .. $#{ $self->{data} }) {
		$self->{labels}[$_] = $main::ALPHABET[$_] unless defined $self->{labels}[$_];
	}
	return $self->{labels}[$i];
}

# Produce the answer rule.
sub ans_rule {
	my ($self, $size, @options) = @_;
	$size ||= 20;
	my @data = @{ $self->{data} };
	my @rules;
	my $radio_name = $self->ANS_NAME(0);

	$size = $self->{size} if defined $self->{size};

	my ($part, $num_responses) = (1, 1);
	for my $i (0 .. $#data) {
		my $rule = $self->begin_radio($i, $i != 0);
		my @part_rules;
		my @part_names;
		my @positions = $data[$i][0] =~ /(%s\*?)/g;
		for (1 .. $#{ $data[$i] }) {
			my $name = $self->ANS_NAME($part++);
			if ($positions[ $_ - 1 ] eq '%s*') {
				push(
					@part_rules,
					scalar(
						$data[$i][$_]->named_ans_array_extension(
							$self->new_name($name),
							ref($size) eq 'ARRAY'
							? (defined $size->[$i][ $_ - 1 ] ? $size->[$i][ $_ - 1 ] : 20)
							: $size,
							answer_group_name => $radio_name,
							@options
						)
					)
				);
				$self->{cmp}[$i][ $_ - 1 ] = $data[$i][$_]->cmp(@ans_defaults);
			} else {
				push(
					@part_rules,
					scalar(
						$data[$i][$_]->named_ans_rule_extension(
							$name,
							ref($size) eq 'ARRAY'
							? (defined $size->[$i][ $_ - 1 ] ? $size->[$i][ $_ - 1 ] : 20)
							: $size,
							answer_group_name => $radio_name,
							@options
						)
					)
				);
			}
			push(@part_names, $main::PG->{PG_ANSWERS_HASH}{$radio_name}{response}{response_order}[$_])
				for ($num_responses .. $#{ $main::PG->{PG_ANSWERS_HASH}{$radio_name}{response}{response_order} });
			$num_responses = @{ $main::PG->{PG_ANSWERS_HASH}{$radio_name}{response}{response_order} };
		}
		$rule .= main::MODES(
			TeX  => sprintf($data[$i][0] =~ s/%s\*/%s/gr, @part_rules),
			HTML => main::tag(
				'div',
				class           => 'radio-content',
				data_radio      => $radio_name,
				data_index      => $self->{values}[$i],
				data_part_names => JSON->new->encode(\@part_names),
				sprintf($data[$i][0] =~ s/%s\*/%s/gr, @part_rules)
			),
			PTX => sprintf($data[$i][0] =~ s/%s\*/%s/gr, @part_rules)
		);
		$rule .= $self->end_radio();
		push(@rules, $rule);
	}

	return main::MODES(
		TeX  => '\\begin{itemize}',
		HTML => '<div class="radio-multianswer-container">'
		)
		. join(main::MODES(TeX => '\vskip\baselineskip', HTML => main::tag('div', style => 'margin-top:1rem')), @rules)
		. main::MODES(TeX => '\\end{itemize}', HTML => '</div>');
}

# Format a label.
sub label_format {
	my ($self, $label) = @_;
	return '' unless $self->{displayLabels} && defined $label && $label ne '';
	return sprintf($self->{labelFormat}, main::MODES(TeX => $self->quoteTeX($label), HTML => $self->quoteHTML($label)));
}

# Start a radio button container.
sub begin_radio {
	my ($self, $i, $extend) = @_;

	my $name  = $self->ANS_NAME(0);
	my $value = $self->{values}[$i];
	my $tag   = $self->label_format($self->label($i));

	my $checked = $i == ($self->{checked} // -1) ? 'checked' : '';
	$checked = $main::inputs_ref->{$name} eq $value ? 'checked' : '' if (defined $main::inputs_ref->{$name});

	if ($extend) { main::EXTEND_RESPONSE($name, $name, $value, $checked) }
	else         { $name = main::RECORD_ANS_NAME($name, { $value => $checked }) }

	my $idSuffix = $extend ? "_$value" : '';

	return main::MODES(
		TeX  => qq!\\item{$tag}\n!,
		HTML => qq{<div class="radio-container">}
			. main::tag(
				'input',
				type       => 'radio',
				name       => $name,
				id         => "$name$idSuffix",
				aria_label => main::generate_aria_label("$answerPrefix${name}_0") . ' option ' . ($i + 1),
				value      => $value,
				$self->{uncheckable}
				? (
					data_uncheckable_radio => 1,
					(!$extend && $self->{uncheckable}) =~ m/shift/i ? (data_shift => 1) : ()
				)
				: (),
				$checked ? (checked => undef) : ()
			)
			. main::tag('label', for => "$name$idSuffix", $tag),
		PTX => "<li>$tag",
	);
}

# End a radio button container.
sub end_radio {
	return main::MODES(TeX => '', HTML => '</div>', PTX => '</li>');
}

# Record an answer-blank name (when using extensions)
sub new_name {
	my ($self, $label) = @_;
	return main::RECORD_FORM_LABEL($label);
}

1;
