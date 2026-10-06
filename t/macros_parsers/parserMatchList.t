#!/usr/bin/env perl

=head1 parserMatchList

Test the MatchList object from parserMatchList.pl.

=cut

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

loadMacros('parserMatchList.pl');

$main::PG_random_generator = PGrandom->new();

subtest 'Basic construction and accessors' => sub {
	$main::PG_random_generator->srand(1234);
	my $ml = MatchList(
		[ [ 'Question a?', 'Answer a' ], [ 'Question b?', 'Answer b' ], [ 'Question c?', 'Answer c' ] ],
		questionOrder => 'fixed',
		choiceOrder   => 'fixed'
	);

	is $ml->length,         3, 'one entry per question';
	is $ml->questions,      [ 'Question a?', 'Question b?', 'Question c?' ], 'questions in the order given';
	is $ml->choices,        [ 'Answer a',    'Answer b',    'Answer c' ],    'choices in the order given';
	is $ml->questionLabels, [ 1,             2,             3 ],             'default question labels are numbers';
	is $ml->choiceLabels,   [ 'A',           'B',           'C' ],           'default choice labels are letters';

	for (0 .. 2) {
		is $ml->originalIndex($_), $_, "originalIndex($_) is the identity when questionOrder is fixed";
		isa_ok $ml->dropDown($_), ['parser::PopUp'], "dropDown($_) is a PopUp/DropDown object";
	}

	is $ml->dropDown(0)->value, 'A', 'question a is matched with choice A';
	is $ml->dropDown(1)->value, 'B', 'question b is matched with choice B';
	is $ml->dropDown(2)->value, 'C', 'question c is matched with choice C';

	ok(Value::isValue($ml), 'a MatchList is a MathObject Value');
	is $ml->type, 'List', 'a MatchList reports its type as List';
};

subtest 'Randomization preserves the question/answer correspondence' => sub {
	my @qa = ([ 'Q0', 'A0' ], [ 'Q1', 'A1' ], [ 'Q2', 'A2' ], [ 'Q3', 'A3' ]);

	for my $seed (1 .. 10) {
		$main::PG_random_generator->srand($seed);
		my $ml = MatchList([ map { [@$_] } @qa ]);

		for my $i (0 .. $ml->length - 1) {
			my $orig          = $ml->originalIndex($i);
			my $letter        = $ml->dropDown($i)->value;
			my ($choiceIndex) = grep { $ml->choiceLabels->[$_] eq $letter } 0 .. $#{ $ml->choiceLabels };

			is $ml->questions->[$i], $qa[$orig][0], "seed $seed: question $i is the question at originalIndex($i)";
			is $ml->choices->[$choiceIndex], $qa[$orig][1],
				"seed $seed: question ${i}'s marked choice is its original answer";
		}
	}
};

subtest 'Duplicate answers share one choice' => sub {
	$main::PG_random_generator->srand(1);
	my $ml = MatchList(
		[ [ 'Q0', 'Same' ], [ 'Q1', 'Same' ], [ 'Q2', 'Different' ] ],
		questionOrder => 'fixed',
		choiceOrder   => 'fixed'
	);
	is $ml->choices,            [ 'Same', 'Different' ], 'duplicate answers collapse to a single choice';
	is $ml->dropDown(0)->value, $ml->dropDown(1)->value, 'both questions with the same answer share a choice';
};

subtest 'extra and last options' => sub {
	$main::PG_random_generator->srand(1);
	my $ml = MatchList(
		[ [ 'Q0', 'A0' ], [ 'Q1', 'A1' ] ],
		questionOrder => 'fixed',
		choiceOrder   => 'fixed',
		extra         => [ 'Extra1', 'Extra2' ],
		last          => ['None of the above'],
	);
	is $ml->choices, [ 'A0', 'A1', 'Extra1', 'Extra2', 'None of the above' ],
		'extra choices follow the answers, and last choices are forced to the end';

	for my $seed (1 .. 10) {
		$main::PG_random_generator->srand($seed);
		my $ml = MatchList([ [ 'Q0', 'A0' ], [ 'Q1', 'A1' ] ], last => ['None of the above']);
		is $ml->choices->[-1], 'None of the above', "seed $seed: the 'last' choice is always displayed last";
	}
};

subtest 'Constructor validation' => sub {
	like dies { MatchList('not an array reference') },
		qr/first argument should be a list of \[ question, answer \] pairs/,
		'the first argument must be an array reference';

	like dies { MatchList(['not a pair']) }, qr/questions and answers should be given as/,
		'each entry must be a [ question, answer ] pair or a { label => [...] } hash';

	like dies { MatchList([ ['only one element'] ]) }, qr/questions and answers should be given as/,
		'each pair must have exactly two elements';

	like dies { MatchList([ { label => 'not an array reference' } ]) },
		qr/questions and answers should be given as/,
		'a { label => ... } entry must have a [ question, answer ] pair as its value';
};

subtest 'Explicit per-question label' => sub {
	$main::PG_random_generator->srand(7);
	my $ml = MatchList([ [ 'Q0', 'A0' ], { X => [ 'Q1', 'A1' ] }, [ 'Q2', 'A2' ] ], questionOrder => 'fixed');
	is $ml->questionLabels->[0], 1,   'the first question keeps the default label';
	is $ml->questionLabels->[1], 'X', 'the explicitly labeled question uses its given label';
	is $ml->questionLabels->[2], 3,   'the third question keeps the default label';
};

subtest 'questionLabels and choiceLabels schemes' => sub {
	$main::PG_random_generator->srand(1);
	my $ml = MatchList(
		[ map { [ "Q$_", "A$_" ] } 0 .. 3 ],
		questionOrder  => 'fixed',
		choiceOrder    => 'fixed',
		questionLabels => 'roman',
		choiceLabels   => 'abc',
	);
	is $ml->questionLabels, [qw(i ii iii iv)], 'roman numeral question labels';
	is $ml->choiceLabels,   [qw(a b c d)],     'lower case choice labels';

	my $ml2 = MatchList(
		[ map { [ "Q$_", "A$_" ] } 0 .. 2 ],
		questionOrder  => 'fixed',
		questionLabels => [ '(a)', '(b)', '(c)' ],
	);
	is $ml2->questionLabels, [ '(a)', '(b)', '(c)' ], 'a custom array of question labels is used directly';
};

subtest 'values option' => sub {
	$main::PG_random_generator->srand(1);
	my $ml = MatchList(
		[ [ 'Q0', 'A0' ], [ 'Q1', 'A1' ] ],
		questionOrder => 'fixed',
		choiceOrder   => 'fixed',
		values        => [ 'val0', 'val1' ],
	);
	is $ml->dropDown(0)->value, 'val0',       'a custom value is used for the first choice';
	is $ml->dropDown(1)->value, 'val1',       'a custom value is used for the second choice';
	is $ml->choiceLabels,       [ 'A', 'B' ], 'the displayed labels are unaffected by custom values';

	my $mlPartial = MatchList(
		[ [ 'Q0', 'A0' ], [ 'Q1', 'A1' ] ],
		questionOrder => 'fixed',
		choiceOrder   => 'fixed',
		values        => ['val0'],
	);
	is $mlPartial->dropDown(0)->value, 'val0', 'the given value is used';
	is $mlPartial->dropDown(1)->value, 'B',    'a missing value falls back to the choice label';

	for my $seed (1 .. 10) {
		$main::PG_random_generator->srand($seed);
		my $ml = MatchList([ [ 'Q0', 'A0' ], [ 'Q1', 'A1' ] ], values => [ 'val-for-A0', 'val-for-A1' ],);
		for my $i (0 .. $ml->length - 1) {
			my $expected = $ml->originalIndex($i) == 0 ? 'val-for-A0' : 'val-for-A1';
			is $ml->dropDown($i)->value, $expected, "seed $seed: a value stays attached to its choice";
		}
	}
};

sub extension_name { my ($ml, $i) = @_; return Value::ANS_NAME($ml->{ans_name}, 0, $i) }

subtest 'a MatchList is graded as a single answer array, all or nothing by default' => sub {
	local $main::showPartialCorrectAnswers = 0;

	$main::PG_random_generator->srand(1);
	my $ml = MatchList(
		[ [ 'Q0', 'A0' ], [ 'Q1', 'A1' ], [ 'Q2', 'A2' ] ],
		questionOrder => 'fixed',
		choiceOrder   => 'fixed'
	);
	$ml->ans_array;
	my $ans = $ml->cmp;

	local $main::inputs_ref = {
		extension_name($ml, 1) => $ml->dropDown(1)->value,
		extension_name($ml, 2) => $ml->dropDown(2)->value,
	};
	is $ans->evaluate($ml->dropDown(0)->value)->{score}, 1, 'every question correct gives full credit';

	local $main::inputs_ref = {
		extension_name($ml, 1) => $ml->dropDown(0)->value,    # wrong
		extension_name($ml, 2) => $ml->dropDown(2)->value,
	};
	is $ans->evaluate($ml->dropDown(0)->value)->{score}, 0, 'one wrong question gives no credit by default';
};

subtest 'partialCredit passed as a cmp option' => sub {
	local $main::showPartialCorrectAnswers = 0;

	$main::PG_random_generator->srand(1);
	my $ml = MatchList(
		[ [ 'Q0', 'A0' ], [ 'Q1', 'A1' ], [ 'Q2', 'A2' ] ],
		questionOrder => 'fixed',
		choiceOrder   => 'fixed'
	);
	$ml->ans_array;
	my $ans = $ml->cmp(partialCredit => 1);

	local $main::inputs_ref = {
		extension_name($ml, 1) => $ml->dropDown(0)->value,    # wrong
		extension_name($ml, 2) => $ml->dropDown(2)->value,
	};
	my $result = $ans->evaluate($ml->dropDown(0)->value);
	is $result->{score}, 2 / 3,
		'one wrong question gives partial credit when requested, even though showPartialCorrectAnswers is off';
	is $result->{ans_message}, '2 of 3 answers correct.',
		'the message reports the count correct, without revealing which individual question was wrong';

	local $main::inputs_ref = {
		extension_name($ml, 1) => $ml->dropDown(0)->value,    # wrong
		extension_name($ml, 2) => $ml->dropDown(0)->value,    # wrong
	};
	is $ans->evaluate($ml->dropDown(0)->value)->{score}, 1 / 3, 'only one right question gives partial credit';
};

subtest 'the number of answers correct is reported only when showHints is off' => sub {
	$main::PG_random_generator->srand(1);
	my $ml = MatchList(
		[ [ 'Q0', 'A0' ], [ 'Q1', 'A1' ], [ 'Q2', 'A2' ] ],
		questionOrder => 'fixed',
		choiceOrder   => 'fixed'
	);
	$ml->ans_array;

	local $main::inputs_ref = {
		extension_name($ml, 1) => $ml->dropDown(0)->value,    # wrong
		extension_name($ml, 2) => $ml->dropDown(2)->value,
	};

	# With showHints on, the per-question hints already say specifically which question is wrong,
	# so the count would be redundant, and is not added.
	my $withHints = $ml->cmp(partialCredit => 1)->evaluate($ml->dropDown(0)->value);
	like $withHints->{ans_message}, qr/Your second answer is incorrect/,
		'a per-question hint is shown when enabled';
	unlike $withHints->{ans_message}, qr/answers correct/, 'the count is not added when hints are already shown';

	my $withoutHints = $ml->cmp(showHints => 0, partialCredit => 1)->evaluate($ml->dropDown(0)->value);
	is $withoutHints->{ans_message}, '2 of 3 answers correct.',
		'with hints disabled, the count is reported instead, without revealing which question was wrong';
};

subtest 'the number correct is never reported for a preview' => sub {
	$main::PG_random_generator->srand(1);
	my $ml = MatchList(
		[ [ 'Q0', 'A0' ], [ 'Q1', 'A1' ], [ 'Q2', 'A2' ] ],
		questionOrder => 'fixed',
		choiceOrder   => 'fixed'
	);
	$ml->ans_array;
	my $ans = $ml->cmp(showHints => 0);

	local $main::inputs_ref = {
		extension_name($ml, 1) => $ml->dropDown(0)->value,    # wrong
		extension_name($ml, 2) => $ml->dropDown(2)->value,
		previewAnswers => 1,
	};
	my $result = $ans->evaluate($ml->dropDown(0)->value);
	ok $result->{isPreview}, 'this evaluation is recognized as a preview';
	is $result->{ans_message}, '', 'a preview reveals nothing about how many questions are correct';
};

subtest 'a MatchList works as a MultiAnswer sub-answer' => sub {
	loadMacros('parserMultiAnswer.pl');

	# A previous subtest may have left the ambient context set to a MatchList's restrictive context.
	# Re-establish the base Numeric context to isolate this test.
	main::Context('Numeric');

	$main::PG_random_generator->srand(1);
	my $ml = MatchList(
		[ [ 'Q0', 'A0' ], [ 'Q1', 'A1' ] ],
		questionOrder => 'fixed',
		choiceOrder   => 'fixed'
	);
	my $multi = MultiAnswer(main::Real(3), $ml);

	$multi->ans_rule;
	$multi->ans_array;
	my @cmp = $multi->cmp;
	is scalar(@cmp), 2, 'one evaluator for the plain answer, one for the whole MatchList';

	local $main::inputs_ref = { extension_name($ml, 1) => $ml->dropDown(1)->value };
	is $cmp[0]->evaluate('3')->{score},                     1, 'the plain answer is graded normally';
	is $cmp[1]->evaluate($ml->dropDown(0)->value)->{score}, 1, 'the MatchList sub-answer is graded correctly';
};

subtest 'string and TeX show the correct answers' => sub {
	$main::PG_random_generator->srand(1);
	my $ml = MatchList(
		[ [ 'Q0', 'A0' ], [ 'Q1', 'A1' ] ],
		questionOrder => 'fixed',
		choiceOrder   => 'fixed'
	);
	is $ml->string, 'A, B', 'string is the comma separated list of correct answer letters';

	local $main::displayMode = 'TeX';
	is $ml->TeX, '\text{A}, \text{B}', 'TeX is the comma separated list of correct answer letters';
};

subtest 'ans_rule and named_ans_rule fall back to a plain (unusable) answer blank' => sub {
	$main::PG_random_generator->srand(1);
	my $ml = MatchList([ [ 'Q0', 'A0' ] ], questionOrder => 'fixed');
	unlike $ml->ans_rule, qr/<select/, 'ans_rule does not render the drop down menus';
};

subtest 'ans_array renders the two column layout and registers one combined answer' => sub {
	$main::PG_random_generator->srand(1);
	my $ml = MatchList(
		[ map { [ "Question $_?", "Answer $_" ] } 0 .. 2 ],
		questionOrder => 'fixed',
		choiceOrder   => 'fixed'
	);

	my $before = main::ans_rule_count();
	my $html   = $ml->ans_array;
	my $after  = main::ans_rule_count();

	is $after - $before, 1, 'all of the questions share a single registered answer name';
	is(scalar(() = $html =~ /<select/g), 3, 'one drop down menu per question');
	like $html, qr/match-list-container/,   'renders the two column container';
	like $html, qr/Question 0\?/,           'includes the question text';
	like $html, qr/Answer 0/,               'includes the answer choice text';
	like $html, qr/<strong>1\.<\/strong>/i, 'default question label format';
	like $html, qr/<strong>A\.<\/strong>/i, 'default choice label format';
};

subtest 'feedback is designated on the questions container' => sub {
	$main::PG_random_generator->srand(1);
	my $ml = MatchList(
		[ map { [ "Question $_?", "Answer $_" ] } 0 .. 2 ],
		questionOrder => 'fixed',
		choiceOrder   => 'fixed'
	);
	my $html = $ml->ans_array;

	my @selectNames    = $html =~ /<select[^>]*\bname="([^"]*)"/g;
	my $lastSelectName = $selectNames[-1];

	is(scalar(() = $html =~ /data-feedback-insert-element/g),
		1, 'only one element in the whole widget is marked as a feedback target');
	like $html, qr/<div
			(?=[^>]*\bclass="match-list-questions")
			(?=[^>]*\bdata-feedback-insert-element="\Q$lastSelectName\E")
			(?=[^>]*\bdata-feedback-insert-method="append(?:_|&\#95;)content")
		[^>]*>/x, 'the feedback target is the questions container, naming the last drop down, using append_content';
};

subtest 'each drop down gets a distinct aria label' => sub {
	$main::PG_random_generator->srand(1);
	my $ml = MatchList(
		[ map { [ "Question $_?", "Answer $_" ] } 0 .. 2 ],
		questionOrder => 'fixed',
		choiceOrder   => 'fixed'
	);
	my $html   = $ml->ans_array;
	my @labels = $html =~ /aria-label="([^"]*)"/g;
	is scalar(@labels), 3, 'one aria label per question';
	my %seen;
	is scalar(grep { !$seen{$_}++ } @labels), 3, 'every question has a distinct aria label';
};

subtest 'displayQuestionLabels => 0 hides the question label only' => sub {
	$main::PG_random_generator->srand(1);
	my $ml = MatchList(
		[ [ 'Question zero?', 'Answer zero' ] ],
		questionOrder         => 'fixed',
		displayQuestionLabels => 0
	);
	my $html = $ml->ans_array;
	unlike $html, qr/<strong>1\.<\/strong>/i, 'no question label is shown';
	like $html,   qr/Question zero\?/,        'the question text is still shown';
};

subtest 'questionLabelFormat and choiceLabelFormat' => sub {
	$main::PG_random_generator->srand(1);
	my $ml = MatchList(
		[ [ 'Q0', 'A0' ] ],
		questionOrder       => 'fixed',
		questionLabelFormat => '(%s)',
		choiceLabelFormat   => '[%s]',
	);
	my $html = $ml->ans_array;
	like $html, qr/\(1\)/, 'custom question label format is used';
	like $html, qr/\[A\]/, 'custom choice label format is used';
};

subtest 'dropdownPosition' => sub {
	for my $case (
		[ 'start',  qr/<select.*<\/select>.*<strong>1\.<\/strong>.*Question 0/si ],
		[ 'middle', qr/<strong>1\.<\/strong>.*<select.*<\/select>.*Question 0/si ],
		[ 'end',    qr/<strong>1\.<\/strong>.*Question 0.*<select.*<\/select>/si ],
		)
	{
		my ($position, $pattern) = @$case;
		$main::PG_random_generator->srand(1);
		my $ml = MatchList([ [ 'Question 0?', 'A0' ] ], questionOrder => 'fixed', dropdownPosition => $position);
		like $ml->ans_array, $pattern, "dropdownPosition => '$position'";
	}
};

subtest 'TeX and PTX display modes' => sub {
	$main::PG_random_generator->srand(1);
	my $ml = MatchList([ [ 'Q0', 'A0' ] ], questionOrder => 'fixed');

	{
		local $main::displayMode = 'TeX';
		like $ml->ans_array, qr/\\parbox/, 'TeX mode renders a two column parbox layout';
	}
	{
		local $main::displayMode = 'PTX';
		like $ml->ans_array, qr/<ol>/, 'PTX mode renders an ordered list';
	}
};

done_testing;
