#!/usr/bin/env perl

=head1 MathObjects

Test MathObject properties and operations.
Try out operations with Infinity.

=cut

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

loadMacros('MathObjects.pl');

my ($val1, $val2) = (10, 5);
my $obj1 = Compute($val1);
my $obj2 = Compute($val2);
my $zero = Compute('0');
ok my $one = Compute('1'), 'Create a MathObject with Compute';

subtest 'Basic properties of MathObjects' => sub {
	is $obj1->class,  'Real',   'check class of object';
	is $obj2->type,   'Number', 'check type of object';
	is $one->isOne,   T(),      'check if a number is 1';
	is $zero->isOne,  F(),      'check if a number is not 1';
	is $zero->isZero, T(),      'check if a number is 0';
	is $one->isZero,  F(),      'check if a number is not 0';
};

subtest 'Class methods of Value to determine type' => sub {
	is Value::isValue($obj1),   T(), 'check if an object is a value';
	is Value::isNumber($obj1),  T(), 'check if an object is a number';
	is Value::isReal($obj1),    T(), 'check if a number is a real number';
	is Value::isComplex($obj1), F(), 'check if an integer is complex';

	is Value::isFormula($obj1), F(), 'check if a number is not a formula';
};

ok my $inf = Compute("inf"), 'Can create Infinity';

subtest 'Tests for infinite values' => sub {
	is $inf->value, 'infinity', 'check for infinity via a string';
	is $inf->class, 'Infinity', 'check that the class is Infinity';
	is $inf->type,  'Infinity', 'check that the type is Infinity';
	ok !Value::isNumber($inf), 'check if inf is a number';
};

subtest 'check that operations with infinity are not allowed' => sub {
	like(dies { Compute("$obj1 + $inf") }, qr/can't be infinities/, 'addition with infinity');
	like(dies { Compute("$obj1 - $inf") }, qr/can't be infinities/, 'subtraction with infinity');
	like(dies { Compute("$obj1 * $inf") }, qr/can't be infinities/, 'multiplication with infinity');
	like(dies { Compute("$obj1 / $inf") }, qr/can't be infinities/, 'division with infinity');
};

my $sum  = $obj1 + $obj2;
my $diff = $obj1 - $obj2;
ok my $prod = $obj1 * $obj2, 'Operate on two MathObjects';

subtest 'check object operations' => sub {
	is $sum->value,  $val1 + $val2, 'test sum';
	is $diff->value, $val1 - $val2, 'test difference';
	is $prod->value, $val1 * $val2, 'test product';
};

subtest 'check scores using the cmp method' => sub {
	is check_score($sum,  Compute($sum)),  1, 'use cmp to check sum';
	is check_score($diff, Compute($diff)), 1, 'use cmp to check diff';
	is check_score($prod, Compute($prod)), 1, 'use cmp to check prod';
};

subtest 'check some wrong answers' => sub {
	is check_score($sum,  Compute($sum + 1)),  0, 'use cmp to check sum';
	is check_score($diff, Compute($diff + 1)), 0, 'use cmp to check diff';
	is check_score($prod, Compute($prod + 1)), 0, 'use cmp to check prod';
};

subtest 'numeric context' => sub {
	my $ctx = Context('Numeric');
	ok(Value::isContext($ctx), 'numeric context is a context');
};

subtest 'formulas' => sub {
	my $f = Compute('x^2');
	my $g = Compute('sin(x)');

	ok(Value::isFormula($f), 'check that a formula is a formula');
	is($f->class, 'Formula', 'check that the class is Formula');
	is($f->type,  'Number',  'check that the type is Number');

	is(check_score($f->eval(x =>  2),     '4'),   1, 'eval x^2 at x=2');
	is(check_score($f->eval(x => -3),     '9'),   1, 'eval x^2 at x=-3');
	is(check_score($g->eval(x => 'pi/6'), '1/2'), 1, 'eval sin(x) at x=pi/6');

	is(check_score($f->D('x'), '2x'),     1, 'derivative of x^2');
	is(check_score($g->D('x'), 'cos(x)'), 1, 'derivative of sin(x)');
};

done_testing();
