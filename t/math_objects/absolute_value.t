#!/usr/bin/env perl

=head1 MathObjects - absolute values

Test absolute values.

=cut

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

loadMacros('MathObjects.pl');

subtest 'check absolute value of number' => sub {
	my $abs_minus_three = Compute('|-3|');

	is $abs_minus_three->class, 'Real',   'absolute value of number is Real';
	is $abs_minus_three->type,  'Number', 'absolute value of number is Number';

	ok Value::isValue($abs_minus_three),    'absolute value of number is a value';
	ok Value::isNumber($abs_minus_three),   'absolute value of number is a number';
	ok Value::isReal($abs_minus_three),     'absolute value of number is a real number';
	ok !Value::isComplex($abs_minus_three), 'absolute value of number is not complex';
	ok !Value::isFormula($abs_minus_three), 'absolute value of number is not a formula';

	is $abs_minus_three->value, 3, 'absolute value of number: value is correct';
};

subtest 'check absolute value of variable' => sub {
	my $abs_x = Compute('|x|');

	is $abs_x->class, 'Formula', 'absolute value of variable: check class of object';
	is $abs_x->type,  'Number',  'absolute value of variable: check type of object';

	ok Value::isValue($abs_x),    'absolute value of variable is a value';
	ok Value::isNumber($abs_x),   'absolute value of variable is a number';
	ok !Value::isReal($abs_x),    'absolute value of variable is not a real number';
	ok !Value::isComplex($abs_x), 'absolute value of variable is not complex';
	ok Value::isFormula($abs_x),  'absolute value of variable is a formula';

	ok $abs_x == Compute('|-x|'), '|x| == |-x|';
};

done_testing();
