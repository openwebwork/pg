
=head1 NAME

parserMatchList.pl - Matching list questions compatible with MathObjects,
MultiAnswer objects, and PGML.

=head1 DESCRIPTION

This file implements a matching list object that is compatible with MathObjects,
MultiAnswer objects, and with PGML. It builds a list of questions, each paired
with a drop-down menu (via L<parserPopUp.pl>) of labelled choices, and takes
care of collecting the distinct answer choices, adding any extra (incorrect)
choices, randomizing the order in which the questions and choices are displayed,
and laying out the questions and answer choices in a two column table.

To create a MatchList object, use

    $ml = MatchList(
        [
            [ question1, answer1 ],
            [ question2, answer2 ],
            ...
        ],
        options
    );

where each C<[ question, answer ]> pair gives the text of a question and the
text of its correct answer. Answers that are repeated across questions are only
listed once among the answer choices, and questions can share the same answer.

A question may instead be given as C<< { label => [ question, answer ] } >>, to
explicitly set the label used for that question (see C<questionLabels> below),
overriding whatever label it would otherwise get from its position among the
displayed questions. For example:

    $ml = MatchList(
        [
            [ question1, answer1 ],
            { label2 => [ question2, answer2 ] },
            [ question3, answer3 ],
        ]
    );

always labels the second question C<label2>, wherever it ends up being displayed
among the possible randomly ordered questions.

The C<options> are taken from the following list:

=over

=item C<S<< extra => [ choice, ... ] >>>

Extra answer choices to add to the list of answer choices that are not the
correct answer to any of the questions. Default: C<[]>

=item C<S<< last => [ choice, ... ] >>>

Answer choices (either among the questions' answers, the C<extra> choices, or
new choices) that should always be forced to appear at the end of the list of
answer choices, in the order given, and excluded from the randomization of the
other choices. This is typically used for a choice like "None of the above".
Default: C<[]>

=item C<S<< questionOrder => 'random' or 'fixed' >>>

Whether the questions are displayed in a random order or in the order given.
Default: C<random>

=item C<S<< choiceOrder => 'random' or 'fixed' >>>

Whether the answer choices (other than those in C<last>) are displayed in a
random order or in the order given (correct answers in the order of their
questions, followed by the C<extra> choices). Default: C<random>

=item C<S<< questionLabels => "123", "abc", "ABC", "roman", "Roman", or [label1, ...] >>>

Determines the labels used for the questions (e.g. the "1" in "1. question
text"), assigned after the questions have been put in the order they will be
displayed. If the value is C<"123"> the questions are labeled with numbers (the
default), C<"abc"> or C<"ABC"> label them with lower or upper case letters, and
C<"roman"> or C<"Roman"> label them with lower or upper case Roman numerals. The
C<[label1, ...]> form gives the labels directly, one for each question, in the
order the questions are displayed.

Any question given as C<< { label => [ question, answer ] } >> uses that label
instead, regardless of this option.

=item C<S<< displayQuestionLabels => 0 or 1 >>>

Whether the question labels are shown at all. Default: 1

=item C<S<< questionLabelFormat => string >>>

A format string used when displaying a question's label. It is an C<sprintf>
string that contains C<%s> where the label should go. Default:
C<"${BBOLD}%s.${EBOLD}">, which produces the label in bold followed by a period.

=item C<S<< choiceLabels => "123", "abc", "ABC", "roman", "Roman", or [label1, ...] >>>

Determines the labels used for the answer choices (e.g. the "A" in "A. answer
text"), assigned after the choices have been put in the order they will be
displayed. Accepts the same values as C<questionLabels> above, and defaults to
C<"ABC">.

=item C<S<< choiceLabelFormat => string >>>

A format string used when displaying an answer choice's label. Accepts the same
kind of C<sprintf> string as C<questionLabelFormat> above, and has the same
default.

=item C<S<< values => [ value1, ... ] >>>

The values submitted as the student's answer for each choice (as opposed to the
label or the choice text itself). The same values will be used for every
question's drop down menu (since every question offers the same choices). This
is passed on to the C<DropDown> created for each question (see the C<values>
option of C<parserPopUp.pl>). The values are given in the same order that the
choices are given to the C<MatchList> constructor (the question answers,
followed by any C<extra> answers, followed by any new choices in C<last>). If a
value isn't given for a particular choice (or if not enough values are given for
this option), then the choice's label is used as its value. Default: C<[]>

=item C<S<< dropDownOptions => { option => value, ... } >>>

Options to pass along to the C<DropDown> object (see C<parserPopUp.pl>) that is
created for each question, e.g. C<< { placeholder => '?' } >>. Default: C<{}>

=item C<S<< dropdownPosition => 'start', 'middle', or 'end' >>>

Where the drop down menu is placed within a question's row, relative to the
question label and the question text. C<start> places it before the question
label (e.g. "[menu] 1. question text"), C<middle> places it between the question
label and the question text (e.g. "1. [menu] question text"), and C<end> places
it after the question text (e.g. "1. question text [menu]"). Default: C<start>

=item C<S<< verticalAlign => 'top', 'middle', or 'bottom' >>>

The vertical alignment of the questions and choices. Note that this does not
affect alignment when the window width is narrow and the choices are below the
questions. Default: C<middle>

=item C<S<< questionVerticalAlign => 'top', 'middle', or 'bottom' >>>

The vertical alignment of the contents of the C<div> that contains a question.
Default: C<middle>

=item C<S<< choiceVerticalAlign => 'top', 'middle', or 'bottom' >>>

The vertical alignment of the contents of the C<div> that contains a choice.
Default: C<middle>

=back

To insert the match list (a two column table of questions with their drop down
menus, and answer choices) into the problem text, use

    BEGIN_PGML
    Match each question with its answer.

    [_]*{$ml}
    END_PGML

Note that a C<MatchList> is an answer array, and so the starred PGML answer rule
version must be used.  Furthermore, that means that the questions are graded
together, and so one feedback button will be shown for the C<MatchList> when
answers are processed.

When C<showHints> is 0 and C<partialCredit> is 1, the number of questions
answered correctly is reported in the answer's message, e.g.  "4 of 6 questions
correct.", without revealing which ones. Note that C<showHints> and
C<partialCredit> are set to the value of C<$showPartialCorrectAnswers> by
default, and that is 1 by default.  So the default behavior is to show
per-question hints which state specifically which questions are wrong (e.g.
"Your second answer is incorrect, Your fourth answer is incorrect"). Pass
C<< showHints => 0 >> via C<cmp_options> to get the count instead:

    [_]*{$ml}{ cmp_options => { showHints => 0 } }

Once a C<MatchList> object is created, the following methods are also available:

=over

=item C<< $ml->questions >>

A reference to the array of question strings, in the order they are displayed.

=item C<< $ml->choices >>

A reference to the array of answer choice strings, in the order they are
displayed.

=item C<< $ml->questionLabels >>

A reference to the array of labels for the questions, in display order.

=item C<< $ml->choiceLabels >>

A reference to the array of labels corresponding for the answer choices, in
display order.

=item C<< $ml->dropDown($i) >>

The C<DropDown> object (see C<parserPopUp.pl>) for the C<i>-th question (with 0
being the first question).

=item C<< $ml->answer($i) >>

The textual answer for the C<$i>-th question (with 0 being the first question).

=item C<< $ml->originalIndex($i) >>

The index, in the list of C<[ question, answer ]> pairs originally passed to
C<MatchList>, of the question displayed at position C<$i> (with 0 being the
first question displayed).

=back

A MatchList object is a C<Value::List> whose value is the list of the correct
answer letters for its questions (in question order), and C<< $ml->length >>
gives the number of questions. So, for example, to show the correct answers in
a solution, simply insert the MatchList itself:

    BEGIN_PGML_SOLUTION
    The correct answers are [$ml].
    END_PGML_SOLUTION

=cut

loadMacros('parserPopUp.pl');

sub _parserMatchList_init {
	main::PG_restricted_eval('sub MatchList { parser::MatchList->new(@_) }');
	return;
}

package parser::MatchList;
our @ISA = ('Value::List');

sub new {
	my ($invocant, @options) = @_;
	my $class = ref($invocant) || $invocant;
	shift @options if Value::isContext($options[0]);   # remove context, if given (a MatchList builds its context below)
	my $qa = shift @options;
	Value::Error(q{A MatchList's first argument should be a list of [ question, answer ] pairs})
		unless ref($qa) eq 'ARRAY';

	my @rows;
	for my $entry (@$qa) {
		if (ref($entry) eq 'HASH') {
			my ($label) = keys %$entry;
			Value::Error(q{A MatchList's questions and answers should be given as [ question, answer ] }
					. q{pairs, or { label => [ question, answer ] }})
				unless defined($label) && ref($entry->{$label}) eq 'ARRAY' && @{ $entry->{$label} } == 2;
			push(@rows, [ $label, @{ $entry->{$label} } ]);
		} else {
			Value::Error(q{A MatchList's questions and answers should be given as [ question, answer ] }
					. q{pairs, or { label => [ question, answer ] }})
				unless ref($entry) eq 'ARRAY' && @$entry == 2;
			push(@rows, [ undef, @$entry ]);
		}
	}

	my %options;
	main::set_default_options(
		\%options,
		extra                 => [],
		last                  => [],
		questionOrder         => 'random',
		choiceOrder           => 'random',
		questionLabels        => '123',
		displayQuestionLabels => 1,
		questionLabelFormat   => "${main::BBOLD}%s.${main::EBOLD}",
		choiceLabels          => 'ABC',
		choiceLabelFormat     => "${main::BBOLD}%s.${main::EBOLD}",
		values                => [],
		dropDownOptions       => {},
		dropdownPosition      => 'start',
		verticalAlign         => 'middle',
		questionVerticalAlign => 'middle',
		choiceVerticalAlign   => 'middle',
		@options
	);

	# Make a context in which arbitrary strings can be entered.
	my $context = Parser::Context->getCopy('Numeric');
	$context->{name} = 'MatchList';
	$context->parens->clear;
	$context->variables->clear;
	$context->constants->clear;
	$context->operators->clear;
	$context->functions->clear;
	$context->strings->clear;
	$context->{pattern}{number}         = '^$';
	$context->variables->{patterns}     = {};
	$context->strings->{patterns}{'.*'} = [ -20, 'str' ];
	$context->{parser}{String}          = 'parser::PopUp::String';
	$context->update;

	my $self = bless { %options, qa => \@rows }, $class;

	$self->orderChoices;
	$self->orderQuestions;
	$self->buildQuestionLabels;
	$self->buildDropDowns;

	my $matchList = $class->SUPER::new($context, map { $_->value } @{ $self->{dropDowns} });
	$matchList->{$_} = $self->{$_} for keys %$self;
	$matchList->{format_options} = [ open => '', close => '', sep => ', ' ];

	return $matchList;
}

# Convert a label type into a reference to an array of $n labels.
sub buildLabelArray {
	my ($self, $type, $n) = @_;
	my @roman =
		qw(i ii iii iv v vi vii viii ix x xi xii xiii xiv xv xvi xvii xviii xix xx xxi xxii xxiii xxiv xxv xxvi);
	return [ map { lc($_) } @main::ALPHABET[ 0 .. $n - 1 ] ] if $type eq 'abc';
	return [ @main::ALPHABET[ 0 .. $n - 1 ] ]                if uc($type) eq 'ABC';
	return [ @roman[ 0 .. $n - 1 ] ]                         if $type eq 'roman';
	return [ map { uc($_) } @roman[ 0 .. $n - 1 ] ]          if uc($type) eq 'ROMAN';
	return [@$type]                                          if ref($type) eq 'ARRAY';
	return [ 1 .. $n ];
}

sub type { return 'List'; }

sub string {
	my ($self, @rest) = @_;
	return join(', ', map { $_->string(@rest) } @{ $self->data });
}

sub TeX {
	my ($self, @rest) = @_;
	return join(', ', map { $_->TeX(@rest) } @{ $self->data });
}

# Put the questions (and their answers) into the order they will be displayed, and record
# the indices in the original list passed to MatchList.
sub orderQuestions {
	my $self = shift;
	my @qa   = map { [ $_, $self->{qa}[$_] ] } 0 .. $#{ $self->{qa} };
	@qa = map { splice(@qa, $main::PG_random_generator->random(0, $#qa), 1) } 0 .. $#qa
		if $self->{questionOrder} eq 'random';
	$self->{originalIndices} = [ map { $_->[0] } @qa ];
	$self->{qa}              = [ map { $_->[1] } @qa ];
	return;
}

# Compute the question labels, overridden by any explicit per-question label
# from a { label => [ question, answer ] } entry, in question display order.
sub buildQuestionLabels {
	my $self   = shift;
	my $n      = @{ $self->{qa} };
	my $labels = $self->buildLabelArray($self->{questionLabels}, $n);
	for my $i (0 .. $n - 1) {
		$labels->[$i] = $self->{qa}[$i][0] if defined $self->{qa}[$i][0];
	}
	$self->{questionLabels} = $labels;
	return;
}

# Collect the distinct answer choices, move the "last" choices to the end, and randomize the rest. Also record the
# original index of each choice.
sub orderChoices {
	my $self = shift;

	my (@choices, %seen);
	for my $row (@{ $self->{qa} }) {
		push(@choices, $row->[2]) unless $seen{ $row->[2] }++;
	}
	for my $choice (@{ $self->{extra} }) {
		push(@choices, $choice) unless $seen{$choice}++;
	}
	my %originalIndex = map { $choices[$_] => $_ } 0 .. $#choices;

	my @last;
	for my $choice (@{ $self->{last} }) {
		next if grep { $_ eq $choice } @last;
		push(@last, $choice);
		$originalIndex{$choice} //= scalar(keys %originalIndex);
	}
	my %isLast = map { $_ => 1 } @last;
	@choices = grep { !$isLast{$_} } @choices;

	@choices = map { splice(@choices, $main::PG_random_generator->random(0, $#choices), 1) } 0 .. $#choices
		if $self->{choiceOrder} eq 'random' && @choices;

	push(@choices, @last);

	$self->{choices}               = \@choices;
	$self->{choiceOriginalIndices} = [ map { $originalIndex{$_} } @choices ];
	$self->{choiceLabels}          = $self->buildLabelArray($self->{choiceLabels}, scalar(@choices));

	return;
}

# Build a DropDown menu (of the answer choices) for each question.
sub buildDropDowns {
	my $self = shift;

	my %index;
	for (0 .. $#{ $self->{choices} }) { $index{ $self->{choices}[$_] } //= $_ }

	# Remap the `values` option into the displayed choice order, for use by every DropDown.
	my @values = map { $self->{values}[$_] } @{ $self->{choiceOriginalIndices} };

	my (@questions, @dropDowns);
	for my $row (@{ $self->{qa} }) {
		my (undef, $question, $answer) = @$row;
		Value::Error(qq{The answer "$answer" is not among the MatchList's answer choices})
			unless defined $index{$answer};
		push(@questions, $question);
		push(
			@dropDowns,
			main::DropDown(
				$self->{choiceLabels}, $index{$answer},
				values => \@values,
				%{ $self->{dropDownOptions} }
			)
		);
	}

	$self->{questions} = \@questions;
	$self->{dropDowns} = \@dropDowns;

	return;
}

sub questions      { my $self = shift; return $self->{questions} }
sub choices        { my $self = shift; return $self->{choices} }
sub questionLabels { my $self = shift; return $self->{questionLabels} }
sub choiceLabels   { my $self = shift; return $self->{choiceLabels} }
sub answer         { my ($self, $i) = @_; return $self->{qa}[$i][2]; }

sub dropDown {
	my ($self, $i) = @_;
	return $self->{dropDowns}[$i];
}

# The 0-based index, in the list of [ question, answer ] pairs originally passed to MatchList,
# of the question displayed at the 0-based position $i.
sub originalIndex {
	my ($self, $i) = @_;
	return $self->{originalIndices}[$i];
}

sub cmp_defaults {
	my $self = shift;
	return ($self->SUPER::cmp_defaults(@_), ordered => 1, entry_type => 'answer');
}

sub cmp_collect {
	my ($self, $ans) = @_;
	$ans->{preview_latex_string} = $ans->{preview_text_string} = '';
	my $OK = $self->ans_collect($ans);
	$ans->{student_ans} = $self->format_matrix($ans->{student_array}, @{ $self->{format_options} }, tth_delims => 1);
	return 0 unless $OK;

	$ans->{student_value} = $ans->{student_formula} = eval {
		$self->Package('List')
			->new($self->context,
				map { Value::isFormula($_) ? Parser::Evaluate($_) // $_ : $_ } @{ $ans->{student_array}[0] });
	};

	if (!defined($ans->{student_value}) || $self->context->{error}{flag}) {
		Parser::reportEvalError($@);
		$self->cmp_error($ans);
		return 0;
	}
	$ans->{preview_text_string}  = $ans->{student_ans};
	$ans->{preview_latex_string} = $ans->{student_value}->TeX;
	return 1;
}

# Report how many questions were answered correctly when this is not an answer preview, showHints is off, partial credit
# is on, and not all answers are correct.  Note that when showHints is on messages stating exactly which answers are
# incorrect are reported.
sub cmp_equal {
	my ($self, $ans) = @_;
	$self->SUPER::cmp_equal($ans);
	return
		if $ans->{isPreview}
		|| Value::List::getOption($ans,  'showHints')
		|| !Value::List::getOption($ans, 'partialCredit');
	my $numCorrect = int($ans->{score} * $self->length + 0.5);
	return if $numCorrect >= $self->length;
	my $message = main::maketext('[_1] of [_2] answers correct.', $numCorrect, $self->length);
	$ans->{ans_message} = $ans->{ans_message} ? "$ans->{ans_message}\n$message" : $message;
	return;
}

our $answerPrefix = 'MaTcHlIsT';

sub ans_array                 { my ($self, @options) = @_; return $self->MATCHLIST(0, '', @options); }
sub named_ans_array           { my ($self, @options) = @_; return $self->MATCHLIST(0, @options); }
sub named_ans_array_extension { my ($self, @options) = @_; return $self->MATCHLIST(1, @options); }

sub MATCHLIST {
	my ($self, $extend, $name, $size, %options) = @_;

	main::ADD_CSS_FILE('js/MatchList/matchlist.css', 0);

	main::RECORD_IMPLICIT_ANS_NAME($name = main::NEW_ANS_NAME()) unless $name;
	my $ename = "${answerPrefix}_${name}";
	$self->{ans_name} = $ename;
	$self->{ans_rows} = 1;
	$self->{ans_cols} = $self->length;

	my $answer_group_name = delete($options{answer_group_name}) // $name;

	my $aria_label_prefix = delete($options{aria_label}) // main::generate_aria_label($name);

	my $lastCellName = $self->length > 1 ? Value::ANS_NAME($ename, 0, $self->length - 1) : $name;

	my @questionRows;
	for (0 .. $self->length - 1) {
		my $aria_label = $aria_label_prefix . main::maketext('question [_1] ', $_ + 1);
		my $ansRule    = $_ == 0
			? (
				$extend
				? $self->dropDown(0)->named_ans_rule_extension(
					$name, $size,
					answer_group_name => $answer_group_name,
					aria_label        => $aria_label,
					%options
				)
				: $self->dropDown(0)->named_ans_rule($name, $size, aria_label => $aria_label, %options)
			)
			: $self->dropDown($_)->named_ans_rule_extension(
				Value::ANS_NAME($ename, 0, $_), $size,
				answer_group_name => $answer_group_name,
				aria_label        => $aria_label,
				%options
			);

		# Remove the data-feedback attributes added by DropDown to take back control of feedback placement.
		$ansRule =~ s/\s*data-feedback-insert-(?:element|method)="[^"]*"//g;

		my $question = $self->{questions}[$_];
		my $label =
			$self->{displayQuestionLabels} ? sprintf($self->{questionLabelFormat}, $self->{questionLabels}[$_]) : '';
		push(
			@questionRows,
			join(
				' ',
				grep {length} (
					$self->{dropdownPosition} eq 'end'      ? ($label, $question, $ansRule)
					: $self->{dropdownPosition} eq 'middle' ? ($label, $ansRule, $question)
					:                                         ($ansRule, $label, $question)
				)
			)
		);
	}

	my @choiceRows;
	for (0 .. $#{ $self->{choices} }) {
		push(@choiceRows, sprintf($self->{choiceLabelFormat}, $self->{choiceLabels}[$_]) . ' ' . $self->{choices}[$_]);
	}

	return main::MODES(
		TeX => '\parbox{0.55\linewidth}{'
			. join('\vskip\baselineskip ', @questionRows)
			. '}\hfill\parbox{0.25\linewidth}{'
			. join('\vskip\baselineskip ', @choiceRows) . '}',
		HTML => main::tag(
			'div',
			class => "match-list-container match-list-align-$self->{verticalAlign}",
			main::tag(
				'div',
				class                        => 'match-list-questions',
				data_feedback_insert_element => $lastCellName,
				data_feedback_insert_method  => 'append_content',
				data_feedback_btn_add_class  => 'ms-3',
				join(
					'',
					map {
						main::tag(
							'div',
							class => "match-list-question match-list-align-$self->{questionVerticalAlign}",
							$_
						)
					} @questionRows
				)
				)
				. main::tag(
					'div',
					class => 'match-list-choices',
					join(
						'',
						map {
							main::tag(
								'div',
								class => "match-list-choice match-list-align-$self->{choiceVerticalAlign}",
								$_
							)
						} @choiceRows
					)
				)
		),
		PTX => main::tag('ol', join('', map { main::tag('li', $_) } @questionRows))
			. main::tag('ol', join('', map { main::tag('li', $_) } @choiceRows)),
	);
}

1;
