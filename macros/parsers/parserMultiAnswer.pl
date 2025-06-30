# Note: documentation is at the bottom of the file

loadMacros('MathObjects.pl', 'PGbasicmacros.pl');

sub _parserMultiAnswer_init {
	main::PG_restricted_eval('sub MultiAnswer {parser::MultiAnswer->new(@_)}');
}

package parser::MultiAnswer;
our @ISA = qw(Value);

our $answerPrefix = "MuLtIaNsWeR_";    # answer rule prefix
our $separator    = ';';               # separator for singleResult previews

my @ans_defaults = (
	checker             => sub {0},
	showCoordinateHints => 0,
	showEndpointHints   => 0,
	showEndTypeHints    => 0,
);

sub new {
	my $self    = shift;
	my $class   = ref($self) || $self;
	my $context = (Value::isContext($_[0]) ? shift : $self->context);
	my @data    = @_;
	my @cmp;
	Value::Error("%s lists can't be empty", $class) if scalar(@data) == 0;
	foreach my $x (@data) {
		if (ref($x) eq 'AnswerEvaluator') {
			my $correct_value = $x->{rh_ans}{correct_value};
			Value::Error('Only MathObject answer checkers can be passed to MultiAnswer()')
				unless (defined $correct_value);
			push(@cmp, $x);
			$x = $correct_value;
		} else {
			$x = Value::makeValue($x, context => $context)
				unless Value::isValue($x);
			push(@cmp, $x->cmp(@ans_defaults));
		}
	}
	bless {
		data                => [@data],
		cmp                 => [@cmp],
		ans                 => [],
		isValue             => 1,
		part                => 0,
		singleResult        => 0,
		namedRules          => 0,
		cmpOpts             => undef,
		checkTypes          => 1,
		allowBlankAnswers   => 0,
		tex_separator       => $separator . '\,',
		separator           => $separator . ' ',
		tex_format          => undef,
		format              => undef,
		context             => $context,
		single_ans_messages => [],
		partialCredit       => $main::showPartialCorrectAnswers,
	}, $class;
}

#  Set flags to be passed to individual answer checkers

sub setCmpFlags {
	my ($self, $cmp_number, %flags) = @_;
	die "Answer $cmp_number is not defined." unless defined($self->{cmp}[ $cmp_number - 1 ]);
	$self->{cmp}[ $cmp_number - 1 ]->ans_hash(%flags);
	return $self;
}

#  Creates an answer checker (or array of same) to be passed
#  to ANS() or NAMED_ANS().  Any parameters are passed to
#  the individual answer checkers.

sub cmp {
	my ($self, %options) = @_;

	%options = (%options, %{ $self->{cmpOpts} }) if ref($self->{cmpOpts}) eq 'HASH';

	foreach my $id ('checker', 'separator') {
		if (defined($options{$id})) {
			$self->{$id} = $options{$id};
			delete $options{$id};
		}
	}

	unless (ref($self->{checker}) eq 'CODE') {
		die "Your checker must be a subroutine." if defined($self->{checker});
		$self->{checker} = sub {
			my ($correct, $student, $self, $ans) = @_;
			my @scores;

			for (0 .. $self->length - 1) {
				push(@scores, $correct->[$_] == $student->[$_] ? 1 : 0);
			}
			return \@scores if $self->{partialCredit};
			for (@scores) {
				return 0 unless $_;
			}
			return 1;
		}
	}

	if ($self->{allowBlankAnswers}) {
		foreach my $cmp (@{ $self->{cmp} }) {
			$cmp->install_pre_filter('erase');
			$cmp->install_pre_filter(sub {
				my $ans = shift;
				$ans->{student_ans} =~ s/^\s+//g;
				$ans->{student_ans} =~ s/\s+$//g;
				return $ans;
			});
		}
	}
	my @cmp = ();
	if ($self->{singleResult}) {
		push(@cmp, $self->ANS_NAME(0)) if $self->{namedRules};
		push(@cmp, $self->single_cmp(%options));
	} else {
		foreach my $i (0 .. $self->length - 1) {
			push(@cmp, $self->ANS_NAME($i)) if $self->{namedRules};
			push(@cmp, $self->entry_cmp($i, %options));
		}
	}
	return @cmp;
}

#  Get the answer checker used for when all the answers are treated
#  as a single result.

sub single_cmp {
	my $self = shift;
	my @correct;
	my @correct_tex;
	foreach my $cmp (@{ $self->{cmp} }) {
		push(@correct,     $cmp->{rh_ans}{correct_ans});
		push(@correct_tex, $cmp->{rh_ans}{correct_ans_latex_string} || $cmp->{rh_ans}{correct_value}->TeX);
	}
	my $ans = new AnswerEvaluator;
	$ans->ans_hash(
		correct_ans =>
			(defined($self->{format}) ? sprintf($self->{format}, @correct) : join($self->{separator}, @correct)),
		correct_ans_latex_string => (
			defined($self->{tex_format})
			? sprintf($self->{tex_format}, @correct_tex)
			: join($self->{tex_separator}, @correct_tex)
		),
		type => "MultiAnswer",
		@_,
	);
	$ans->install_evaluator(sub { my $ans = shift; (shift)->single_check($ans) }, $self);
	$ans->install_pre_filter('erase');    # don't do blank check
	return $ans;
}

#  Check the answers when they are treated as a single result.

#    First, call individual answer checkers to get any type-check errors
#    Then perform the user's checker routine
#    Finally collect the individual answers and errors and combine
#      them for the single result.

sub single_check {
	my $self = shift;
	my $ans  = shift;
	$ans->{_filter_name} = "MultiAnswer Single Check";
	my $inputs = $main::inputs_ref;
	$self->{ans}[0] = $self->{cmp}[0]->evaluate($ans->{student_ans});
	foreach my $i (1 .. $self->length - 1) {
		$self->{ans}[$i] = $self->{cmp}[$i]->evaluate($inputs->{ $self->ANS_NAME($i) });
	}
	my $score = 0;
	my (@errors, @student, @latex, @text);
	my $i        = 0;
	my $nonblank = 0;
	if ($self->perform_check($ans)) {
		push(
			@errors,
			main::tag(
				'tr', main::tag('td', style => 'text-align:center', colspan => '2', $self->{ans}[0]{ans_message})
			)
		);
		$self->{ans}[0]{ans_message} = "";
	}
	foreach my $result (@{ $self->{ans} }) {
		$i++;
		$nonblank |= ($result->{student_ans} =~ m/\S/);
		push(@latex,   '{' . check_string($result->{preview_latex_string}, '\_\_') . '}');
		push(@text,    check_string($result->{preview_text_string}, '__'));
		push(@student, check_string($result->{student_ans},         '__'));
		if ($result->{ans_message}) {
			push(
				@errors,
				main::tag(
					'tr',
					main::tag(
						'td',
						style => 'text-align:right;white-space:nowrap;vertical-align:top',
						main::tag('i', "In answer $i") . ':&nbsp;'
						)
						. main::tag('td', style => 'text-align:left', $result->{ans_message})
				)
			);
		}
		$score += $result->{score};
	}
	$ans->score($score / $self->length);
	$ans->{ans_message} = $ans->{error_message} = "";
	if (scalar(@errors)) {
		$ans->{ans_message} = $ans->{error_message} = main::tag(
			'table',
			class => 'ArrayLayout',
			style => 'margin-left:auto;margin-right:auto;',
			join(main::tag('tr', style => 'height: 4px', main::tag('td')), @errors)
		);
	}
	if (@{ $self->{single_ans_messages} }) {
		$ans->{ans_message} = $ans->{error_message} =
			join('', map { main::tag('div', $_) } @{ $self->{single_ans_messages} });
	}
	if ($nonblank) {
		$ans->{preview_latex_string} =
			(
				defined($self->{tex_format})
				? sprintf($self->{tex_format}, @latex)
				: join($self->{tex_separator}, @latex));
		$ans->{preview_text_string} =
			(defined($self->{format}) ? sprintf($self->{format}, @text) : join($self->{separator}, @text));
		$ans->{student_ans} =
			(defined($self->{format}) ? sprintf($self->{format}, @student) : join($self->{separator}, @student));
	}
	return $ans;
}

#  Return a given string or a default if it is empty or not defined

sub check_string {
	my $s = shift;
	$s = shift unless defined($s) && $s =~ m/\S/ && $s ne '{\rm }';
	return $s;
}

#  Answer checker to use for individual entries when singleResult
#  is not in effect.

sub entry_cmp {
	my $self = shift;
	my $i    = shift;
	my $ans  = new AnswerEvaluator;
	$ans->ans_hash(
		correct_ans => $self->{cmp}[$i]{rh_ans}{correct_ans},
		part        => $i,
		type        => "MultiAnswer($i)",
		@_,
	);
	$ans->install_evaluator(sub { my $ans = shift; (shift)->entry_check($ans) }, $self);
	$ans->install_pre_filter('erase');    # don't do blank check
	return $ans;
}

#  Call the correct answer's checker to check for syntax and type errors.
#  If this is the last one, perform the user's checker routine as well
#  Return the individual answer (our answer hash is discarded).

sub entry_check {
	my $self = shift;
	my $ans  = shift;
	$ans->{_filter_name} = "MultiAnswer Entry Check";
	my $i   = $ans->{part};
	my $ANS = $self->{cmp}[$i]->evaluate($ans->{student_ans});
	$self->{ans}[$i] = $ANS;
	$ANS->{type} = $ans->{type};
	$ANS->score(0);

	foreach my $id (keys %{$ans}) {
		$ANS->{$id} = $ans->{$id} unless defined($ANS->{$id});
	}    # copy missing original fields
	$self->perform_check($ANS) if ($i == $self->length - 1);
	return $ANS;
}

#  Collect together the correct and student answers, and call the
#  user's checker routine.

#  If any of the answers produced errors or the types don't match
#    don't call the user's routine.
#  Otherwise, call it, and if there was an error, report that.
#  Set the individual scores based on the result from the user's routine.

sub perform_check {
	my $self    = shift;
	my $rh_ans  = shift;
	my $context = $self->context;
	$context->clearError;
	my @correct;
	my @student;
	foreach my $ans (@{ $self->{ans} }) {
		push(@correct, $ans->{correct_value});
		push(@student, $ans->{student_value});
		return if $ans->{ans_message} || !defined($ans->{student_value});
		return
			if $self->{checkTypes}
			&& $ans->{student_value}->type ne $ans->{correct_value}->type
			&& !($self->{allowBlankAnswers} && $ans->{student_ans} !~ m/\S/);
	}
	my $inputs = $main::inputs_ref;
	$rh_ans->{isPreview} = $inputs->{previewAnswers}
		|| ($inputs_{action} && $inputs->{action} =~ m/^Preview/);

	Parser::Context->current(undef, $context);                                    # change to multi-answer's context
	my $flags = Value::contextSet($context, $self->cmp_contextFlags($rh_ans));    # save old context flags
	$context->{answerHash} = $rh_ans;                                             # attach the answerHash
	my @result = Value::cmp_compare([@correct], [@student], $self, $rh_ans);
	Value::contextSet($context, %{$flags});                                       # restore context values
	$context->{answerHash} = undef;                                               # remove answerHash
	if (!@result && $context->{error}{flag}) { $self->cmp_error($self->{ans}[0]); return 1 }

	my $result = (scalar(@result) > 1 ? [@result] : $result[0] || 0);
	if (ref($result) eq 'ARRAY') {
		die "Checker subroutine returned the wrong number of results"
			if (scalar(@{$result}) != $self->length);
		foreach my $i (0 .. $self->length - 1) { $self->{ans}[$i]->score($result->[$i]) }
	} elsif (Value::matchNumber($result)) {
		foreach my $ans (@{ $self->{ans} }) { $ans->score($result) }
	} else {
		die "Checker subroutine should return a number or array of numbers ($result)";
	}
	return;
}

#  The user's checker can call setMessage(n,message) to set the error message
#  for the n-th answer blank.

sub setMessage {
	my ($self, $i, $message) = @_;
	die "Answer $i is not defined." unless defined($self->{ans}[ $i - 1 ]);
	$self->{ans}[ $i - 1 ]{ans_message} = $self->{ans}[ $i - 1 ]{error_message} = $message;
}

# The user's checker can add messages to the single_ans_messages array,
# which are joined together along with any ans_messages from the
# individual answers.
sub addMessage {
	my ($self, $message) = @_;
	return unless $message;
	push(@{ $self->{single_ans_messages} }, $message);
}

#  Produce the name for a named answer blank.
#  (When the singleResult option is true, use the standard name for the first
#  one, and create the prefixed names for the rest.)

sub ANS_NAME {
	my $self = shift;
	my $i    = shift;
	return $self->{answerNames}{$i} if defined($self->{answerNames}{$i});
	if ($self->{singleResult}) {
		$self->{answerNames}{0}  = main::NEW_ANS_NAME() unless defined($self->{answerNames}{0});
		$self->{answerNames}{$i} = $answerPrefix . $self->{answerNames}{0} . "_" . $i unless $i == 0;
	} else {
		$self->{answerNames}{$i} = main::NEW_ANS_NAME();
	}
	return $self->{answerNames}{$i};
}

#  Record an answer-blank name (when using extensions)

sub NEW_NAME {
	my $self = shift;
	main::RECORD_FORM_LABEL(shift);
}

#  Produce an answer rule for the next item in the list,
#    taking care to use names or extensions as needed
#    by the settings of the MultiAnswer.

sub ans_rule {
	my $self = shift;
	my $size = shift || 20;
	my $data = $self->{data}[ $self->{part} ];
	my $name = $self->ANS_NAME($self->{part}++);
	if ($self->{singleResult} && $self->{part} == 1) {
		my $label = main::generate_aria_label($answerPrefix . $name . "_0");
		main::RECORD_IMPLICIT_ANS_NAME($name) unless $self->{namedRules};
		return $data->named_ans_rule($name, $size, @_, aria_label => $label);
	}
	if ($self->{singleResult} && $self->{part} > 1) {
		my $extension_ans_rule = $data->named_ans_rule_extension(
			$name, $size,
			answer_group_name => $self->{answerNames}{0},
			@_
		);
		# warn "extension rule created: $extension_ans_rule for ", ref($data);
		return $extension_ans_rule;
	} else {
		main::RECORD_IMPLICIT_ANS_NAME($name) unless $self->{namedRules};
		return $data->named_ans_rule($name, $size, @_);
	}
}

#  Do the same, but for answer arrays, which are generated by the
#    Value objects automatically sized to suit their data.
#    Reset the correct_ans once the array is made

sub ans_array {
	my $self = shift;
	my $size = shift || 5;
	my $HTML;
	my $data = $self->{data}[ $self->{part} ];
	my $name = $self->ANS_NAME($self->{part}++);
	if ($self->{singleResult} && $self->{part} == 1) {
		my $label = main::generate_aria_label($answerPrefix . $name . "_0");
		main::RECORD_IMPLICIT_ANS_NAME($name) unless $self->{namedRules};
		return $data->named_ans_array(
			$name, $size,
			answer_group_name => $self->{answerNames}{0},
			@_, aria_label => $label
		);
	}
	if ($self->{singleResult} && $self->{part} > 1) {
		$HTML = $data->named_ans_array_extension(
			$self->NEW_NAME($name), $size,
			answer_group_name => $self->{answerNames}{0},
			@_
		);
		# warn "array extension rule created: $HTML for ", ref($data);
	} else {
		main::RECORD_IMPLICIT_ANS_NAME($name) unless $self->{namedRules};
		$HTML = $data->named_ans_array($name, $size, @_);
	}
	$self->{cmp}[ $self->{part} - 1 ] = $data->cmp(@ans_defaults);
	return $HTML;
}

1;

=head1 NAME

parserMultiAnswer.pl - Represents mathematical objects with interrelated answers

=head1 DESCRIPTION

The C<MultiAnswer> class is designed to represent MathObjects with interrelated answers.
It provides functionality to tie several answer rules to a single answer checker, allowing one
answer to influence another. You can choose to produce either a single result in the answer table
or a separate result for each rule.

=head1 ATTRIBUTES

Create a new C<MultiAnswer> item by passing a list of answers to the constructor.

The answers may be provided as C<MathObjects>, C<AnswerEvaluators>, or as strings (which will be
converted into C<MathObjects>).

C<MultiAnswer> objects have the following attributes:

=head2 checker

A coderef to be called to check student answers.

The C<checker> routine receives four parameters: a reference to the array of correct answers,
a reference to the array of student answers, a reference to the C<MultiAnswer> object itself,
and a reference to the checker's answer hash. The routine should return either a score or a
reference to an array of scores (one for each answer).

    # this checker will give full credit for any answers
    sub always_right {
		my ($correct,$student,$multi_ans,$ans_hash) = @_;  # get the parameters
		return [ (1) x scalar(@$correct) ];                # return an array of scores
	}
	$multianswer_obj = $multianswer_obj->with(checker=>~~&always_right);

If a C<checker> is not provided, a default checker is used. The default checker checks if each
answer is equal to its correct answer (using the overloaded C<==> operator). If C<< partialCredit => 1 >>,
the checker returns an array of 0s and 1s listing which answers are correct giving partial credit.
If C<< partialCredit => 0 >>, the checker only returns 1 if all answers are correct, otherwise returns 0.

=head2 partialCredit

This is used with the default checker to determine if the default checker should reward partial
credit, based on the number of correct answers, or not. Default: C<$showPartialCorrectAnswers>.

=head2 singleResult

Indicates whether to show only one entry in the results table (C<< singleResult => 1 >>)
or one for each answer rule (C<< singleResult => 0 >>). Default: 0.

=head2 namedRules

Indicates whether to use named rules or default rule names. Use named rules (C<< namedRules => 1 >>)
if you need to intersperse other rules with the ones for the C<MultiAnswer>. In this case, you must
use C<NAMED_ANS> instead of C<ANS>. Default: 0.

=head2 cmpOpts

This is a hash of options that will be passed to the cmp method. For example,
C<< cmpOpts => { weight => 0.5 } >>. This option is provided to make it more convenient to pass
options to cmp when utilizing PGML. Default: undef (no options are sent).

=head2 checkTypes

Specifies whether the types of the student and professor's answers must match exactly
(C<< checkTypes => 1 >>) or just pass the usual type-match error checking (in which case, you should
check the types before you use the data). Default: 1.

=head2 allowBlankAnswers

Indicates whether to remove the blank-check prefilter from the answer checkers used for type checking
the student's answers. Default: 0.

=head2 format

An sprintf-style string used to format the students' answers for the results table when C<singleResult>
is true. If undefined, the C<separator> parameter (below) is used to form the string. Default: undef.

=head2 tex_format

An sprintf-style string used to format the students' answer previews when C<singleResult> mode is
in effect. If undefined, the C<tex_separator> (below) is used to form the string. Default: undef.

=head2 separator

The string to use between entries in the results table when C<singleResult> is set and C<format> is not.
Default: semicolon.

=head2 tex_separator

The string to use as a separator between entries in the preview area when C<singleResult> is set
and C<tex_format> is not. Default: semicolon followed by thinspace.

=head1 METHODS

=head2 setCmpFlags

    $multianswer_obj->setCmpFlags($which_rule, %flags)

Configure a specific comparison object within the C<MathObject> instance by setting various flags
and their corresponding values.

C<$which_rule> begins counting at 1.

If the specified C<$which_rule> does not correspond to an existing comparison object within
the C<MultiAnswer> instance, this method will throw an error with the message
"Answer $which_rule is not defined."

    $ma_obj = MultiAnswer($fraction_obj);
    $ma_obj->setCmpFlags(1, studentsMustReduceFractions => 1); # succeeds
    $ma_obj->setCmpFlags(2, studentsMustReduceFractions => 1); # fails

=head2 setMessage

    $multianswer_obj->setMessage($which_rule, $message_string)

Meant for use in C<checker>, setMessage provides feedback targeting the specified answer rule.

Note that using C<Value::Error("message")> will halt the answer checker and return early with
your message. This message will not be tied to any specific answer rule.

This method sets the provided message and does B<not> return early -- allowing an answer checker
to return a non-zero value for partial credit.

C<$which_rule> begins counting at 1.

If the specified C<$which_rule> does not correspond to an existing answer rule, this method
will throw an error with the message "Answer $which_rule is not defined."

    $ma_obj = MultiAnswer($math_obj1, $math_obj2);
    $ma_obj->setMessage(2, "It's like a jungle sometimes..."); # succeeds
    $ma_obj->setMessage(3, "It's like a jungle sometimes..."); # fails

=head2 addMessage

    $multianswer_obj->addMessage($message_string)

Meant for use in C<checker> when using C<singleResult> to add feedback messages for the
combined answer rules.  This will add the message to a message array, which will be all
joined together to create the final message. These messages are then attached to any
answer rule messages to be displayed to the user.

Note that unlike C<setMessage>, these messages are not tied to any answer rules, and
unlike C<Value::Error("message")>, this will not halt the answer checker allowing both
partial credit and other messages to also be shown.

=head1 USAGE

To create a MultiAnswer pass a list of answers to MultiAnswer() in the order they
will appear in the problem. These answers may be provides as strings, as C<MathObjects>,
or as C<AnswerEvaluators>. For example:

    $multipart_ans = MultiAnswer("x^2",-1,1);

or

    $multipart_ans = MultiAnswer(Vector(1,1,1),Vector(2,2,2));

or

    $multipart_ans = MultiAnswer($math_obj1->cmp(),$math_obj2->cmp());

In PGML, use the C<MultiAnswer> object as you would any other with the only difference
that the C<MultiAnswer> is used multiple times:

    Give the first part of the answer: [__]{$multipart_ans}{15}
    Give the second part of the answer: [__]{$multipart_ans}{15}

Properties of a C<MultiAnswer> object can be set by chaining the C<with> method to the constructor
during the initial assignment. For example, here we configure the results table to include only one
entry for our C<$multipart_ans>, and then pass in our answer checker:

    $multipart_ans = MultiAnswer("x^2",1,-1)->with(
        singleResult => 1,
        checker => sub {
            my ($correct,$student,$multi_ans,$ans_hash) = @_;  # get the parameters
            my ($f,$x1,$x2) = @{$student};                     # extract the student answers
            return $f->eval(x=>$x1) == $f->eval(x=>$x2);
        },
    );
    ANS($mp->cmp);

We can also make use of named subroutines. If using C<with> after assigning the C<MultiAnswer> to a
variable, note that the C<with> method returns a shallow copy of the C<MultiAnswer> object. If you
do not store the result when calling C<with>, your parameters will not be applied.

    sub check {
            my ($correct,$student,$multi_ans,$ans_hash) = @_;  # get the parameters
            my ($f,$x1,$x2) = @{$student};                     # extract the student answers
            if ($f->class ne 'Formula' || $f->isConstant) {
                # use setMessage so that partial credit can be given
                $multi_ans->setMessage(1,"For full-credit, find a non-trivial \(f(x)\).");
                return 0.25;
            }
			# no partial credit for this error, and a specific answer rule is not targeted
            Value::Error("It's not fair to use the same x-value twice") if ($x1 == $x2);
            return $f->eval(x=>$x1) == $f->eval(x=>$x2);
    };

    $mp = MultiAnswer("x^2",1,-1);
    $mp = $mp->with(singleResult=>1, checker=>~~&check);

=cut
