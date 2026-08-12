#!/usr/bin/env perl

=head1 MathObjects - absolute values

Test absolute values.

=cut

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

use lib "$ENV{PG_ROOT}/lib";

use Units;
use Value;
use Parser;
use Parser::Legacy;

loadMacros('PGstandard.pl', 'MathObjects.pl', 'contextUnits.pl');

subtest 'basic differentiation' => sub {
	my $f = Compute('(5x^2 + 3x - 4) / 7')->D;

	is $f->class, 'Formula', 'derivative is formula';
	is $f->type,  'Number',  'derivative is Number';

	ok Value::isValue($f),    'derivative is a value';
	ok Value::isNumber($f),   'derivative is a number';
	ok !Value::isReal($f),    'derivative is not real';
	ok !Value::isComplex($f), 'derivative is not complex';
	ok Value::isFormula($f),  'derivative is a formula';

	is check_score($f,              '(10x + 3) / 7'), 1, 'derivative of (5x^2 + 3x - 4) / 7 is (10x + 3) / 7';
	is check_score(Compute('5')->D, '0'),             1, 'derivative of number is zero';

	my $g = Compute('5x^2 + 3x - 4');
	my $h = Compute('e^x + ln(x)');

	is check_score(($g * $h)->D, '(10x + 3)(e^x + ln(x)) + (5x^2 + 3x - 4)(e^x + 1 / x)'), 1, 'product rule';
	is check_score(($g / $h)->D, '((10x + 3)(e^x + ln(x)) - (5x^2 + 3x - 4)(e^x + 1 / x)) / (e^x + ln(x))^2'), 1,
		'quotient rule';
};

subtest 'numeric function differentiation' => sub {
	is check_score(Compute('sqrt(x)')->D, '1 / (2 sqrt(x))'), 1, 'derivative of sqrt(x) is 1 / (2 sqrt(x))';
	is check_score(Compute('ln(x)')->D,   '1 / x'),           1, 'derivative of ln(x) is 1 / x';
	is check_score(Compute('log(x)')->D,  '1 / x'),           1, 'derivative of log(x) is 1 / x';
	is check_score(Compute('exp(x)')->D,  'exp(x)'),          1, 'derivative of exp(x) is exp(x)';
	is check_score(Compute('abs(x)')->D,  'abs(x) / x'),      1, 'derivative of abs(x) is abs(x) / x';

	Context()->flags->set(useBaseTenLog => 1);
	is check_score(Compute('log(x)')->D, '1 / (ln(10)x)'), 1,
		'derivative of log(x) with useBaseTenLog flag set is 1 / (ln(10) x)';
	Context()->flags->set(useBaseTenLog => 0);

};

subtest 'trig differentiation' => sub {
	is check_score(Compute('sin(x)')->D, 'cos(x)'),        1, 'derivative of sin(x) is cos(x)';
	is check_score(Compute('cos(x)')->D, '-sin(x)'),       1, 'derivative of cos(x) is -sin(x)';
	is check_score(Compute('tan(x)')->D, 'sec^2(x)'),      1, 'derivative of tan(x) is sec^2(x)';
	is check_score(Compute('cot(x)')->D, '-csc^2(x)'),     1, 'derivative of cot(x) is -csc^2(x)';
	is check_score(Compute('sec(x)')->D, 'sec(x)tan(x)'),  1, 'derivative of sec(x) is sec(x)tan(x)';
	is check_score(Compute('csc(x)')->D, '-csc(x)cot(x)'), 1, 'derivative of csc(x) is -csc(x)cot(x)';
};

subtest 'list differentiation' => sub {
	is check_score(Compute('|x|')->D,      '|x| / x'),  1, 'derivative of |x| is |x| / x';
	is check_score(Compute('x^2, x^3')->D, '2x, 3x^2'), 1, 'derivative of the list "x^2, x^3" is "2x, 3x^2"';
};

subtest 'differentiation with units' => sub {
	Context('Units')->withUnitsFor('length', 'time')->assignUnits(t => 's');
	is check_score(Compute('(3t^2 - 2t) m')->D, '(6t - 2) m/s'), 1, 'derivative of (3t^2 - 2t) m';
	Context('Numeric');
};

subtest 'invalid differentiation' => sub {
	like(
		dies { Compute('x!')->D },
		qr/Differentiation for 'factorial' is not implemented/,
		'derivative of factorial is not implemented'
	);

	like(dies { Compute('{5, 8}')->D }, qr/Can't differentiate sets/, 'Sets can not be differentiated');

	Context('Interval');
	like(dies { Compute('[5, 8)')->D }, qr/Can't differentiate intervals/, 'Intervals can not be differentiated');
	like(
		dies { Compute('(-5, 0) U (0, 5)')->D },
		qr/Can't differentiate unions/,
		'Unions can not be differentiated'
	);
};

done_testing();
