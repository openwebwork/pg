#!/usr/bin/env perl

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
use lib "$ENV{PG_ROOT}/lib";

use Test2::V0;

use WeBWorK::PG;

ok my $pg = WeBWorK::PG->new(
	sourceFilePath => "$ENV{PG_ROOT}/t/pg_test_problems/blankProblem.pg",
	inputs_ref     => { AnSwEr0001 => '3.14159' },
	processAnswers => 1,
	),
	'blankProblem.pg renders';

is($pg->{head_text}, '', 'head_text is empty');

is($pg->{post_header_text}, '', 'post_header_text is empty');

is(
	$pg->{body_text},
	qq{<div class="PGML">\n}
		. qq{Enter a value for <script type="math/tex">\\pi</script>.\n}
		. qq{<div style="margin-top:1em"></div>\n}
		. qq{<input aria-label="answer 1 " autocapitalize="off" autocomplete="off" class="codeshard" }
		. qq{dir="auto" id="AnSwEr0001" name="AnSwEr0001" size="5" spellcheck="false" type="text" value="3.14159">}
		. qq{<input id="MaThQuIlL_AnSwEr0001" name="MaThQuIlL_AnSwEr0001" type="hidden" value="">}
		. qq{<input name="previous_AnSwEr0001" type="hidden" value="3.14159">\n}
		. qq{</div>\n},
	'body_text has correct content'
);

is($pg->{result}, { errors => '', type => 'avg_problem_grader', score => 1, msg => '' }, 'result is correct');

is(
	$pg->{state},
	{ recorded_score => 1, num_of_correct_ans => 1, num_of_incorrect_ans => 0 },
	'state is properly updated'
);

is(
	$pg->{answers},
	{
		AnSwEr0001 => {
			ans_label                => 'AnSwEr0001',
			ans_name                 => 'AnSwEr0001',
			ans_message              => '',
			error_message            => '',
			isPreview                => '',
			_filter_name             => 'dereference_array_ans',
			score                    => 1,
			studentsMustReduceUnions => 1,
			showUnionReduceWarnings  => 1,
			ignoreInfinity           => 1,
			showEqualErrors          => 1,
			ignoreStrings            => 1,
			showTypeWarnings         => 1,
			type                     => 'Value (Real)',
			cmp_class                => 'a Number',
			done                     => undef,
			error_flag               => undef,
			correct_ans              => '3.14159',
			correct_ans_latex_string => '3.14159',
			correct_value            => '3.14159',
			preview_latex_string     => '3.14159',
			preview_text_string      => '3.14159',
			student_ans              => '3.14159',
			original_student_ans     => '3.14159',
			student_value            => '3.14159',
			student_formula          => '3.14159'
		}
	},
	'answers are correctly parsed'
);

is($pg->{warnings}, '', 'there are no perl warnings');

is($pg->{errors}, '', 'there are no pg errors');

is($pg->{pgcore}->get_warning_messages, [], 'there are no PG core warning messages');

is($pg->{pgcore}->get_debug_messages, [], 'there are no PG core debug messages');

is(
	$pg->{flags},
	{
		comment                   => '',
		showPartialCorrectAnswers => 1,
		recordSubmittedAnswers    => 1,
		refreshCachedImages       => 0,
		solutionExists            => 0,
		hintExists                => 0,
		ANSWER_ENTRY_ORDER        => ['AnSwEr0001'],
		KEPT_EXTRA_ANSWERS        => [ 'MaThQuIlL_AnSwEr0001', 'AnSwEr0001' ],
		PROBLEM_GRADER_TO_USE     => meta { reftype => 'CODE'; },
		extra_css_files           => [
			{ file => 'js/Problem/problem.css',                    external => undef },
			{ file => 'js/Knowls/knowl.css',                       external => undef },
			{ file => 'js/ImageView/imageview.css',                external => undef },
			{ file => 'node_modules/mathquill/dist/mathquill.css', external => undef },
			{ file => 'js/MathQuill/mqeditor.css',                 external => undef }
		],
		extra_js_files => [
			{ file => 'js/InputColor/color.js',                   external => 0, attributes => { defer => undef } },
			{ file => 'js/Base64/Base64.js',                      external => 0, attributes => { defer => undef } },
			{ file => 'js/Knowls/knowl.js',                       external => 0, attributes => { defer => undef } },
			{ file => 'js/ImageView/imageview.js',                external => 0, attributes => { defer => undef } },
			{ file => 'js/Essay/essay.js',                        external => 0, attributes => { defer => undef } },
			{ file => 'node_modules/mathquill/dist/mathquill.js', external => 0, attributes => { defer => undef } },
			{ file => 'js/MathQuill/mqeditor.js',                 external => 0, attributes => { defer => undef } }
		],
	},
	'flags are correctly set'
);

done_testing;
