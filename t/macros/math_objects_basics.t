use Test2::V0;

use Parser;

use lib 't/lib';
use Test::PG;


=head1 MathObjects

Test MathObject properties and operations.
Try out operations with Infinity.

=cut


loadMacros("MathObjects.pl");

Context("Numeric");

my ($val1, $val2) = (10, 5);
my $obj1 = Compute($val1);
my $obj2 = Compute($val2);
my $zero = Compute("0");
ok my $one  = Compute("1"), 'Create a MathObject with Compute';

subtest 'Basic properties of MathObjects' => sub {
	is $obj1->class,  'Real',   'math objects: check class of object';
	is $obj2->type,   'Number', 'math objects: check type of object';
	is $one->isOne,   T(), 'math objects: check if a number is 1';
	is $zero->isOne,  F(), 'math objects: check if a number is not 1';
	is $zero->isZero, T(), 'math objects: check if a number is 0';
	is $one->isZero,  F(), 'math objects: check if a number is not 0';
};

subtest 'Class methods of Value to determine type' => sub {
	is Value::isValue($obj1),   T(), 'math objects: check if an object is a value';
	is Value::isNumber($obj1),  T(), 'math objects: check if an object is a number';
	is Value::isReal($obj1),    T(), 'math objects: check if a number is a real number';
	is Value::isComplex($obj1), F(), 'math objects: check if an integer is complex';

	is Value::isFormula($obj1), F(), 'math objects: check if a number is not a formula';
};

ok my $inf = Compute("inf"), 'Can create Infinity';

subtest 'Tests for infinite values' => sub {
	is $inf->value, 'infinity', 'math objects: check for infinity via a string';
	is $inf->class, 'Infinity', 'math objects: check that the class is Infinity';
	is $inf->type,  'Infinity', 'math objects: check that the type is Infinity';
	ok !Value::isNumber($inf),  'math objects: check if inf is a number';
};

subtest 'check that operations with infinity are not allowed' => sub {
	like(
		dies { Compute("$obj1+$inf") },
		qr/can't be infinities/,
		"math objects: addition with infinity"
	);
	like(
		dies { Compute("$obj1-$inf") },
		qr/can't be infinities/,
		"math objects: subtraction with infinity"
	);
	like(
		dies { Compute("$obj1*$inf") },
		qr/can't be infinities/,
		"math objects: multiplication with infinity"
	);
	like(
		dies { Compute("$obj1/$inf") },
		qr/can't be infinities/,
		"math objects: division with infinity"
	);

	# is($result1->value,'infinity','math objects: check that the sum of a finite and infinite value is infinite');
};

my $sum  = $obj1 + $obj2;
my $diff = $obj1 - $obj2;
ok my $prod = $obj1 * $obj2, 'Operate on two MathObjects';

subtest 'check object operations' => sub {
	is $sum->value,  $val1 + $val2, 'math objects: test sum';
	is $diff->value, $val1 - $val2, 'math objects: test difference';
	is $prod->value, $val1 * $val2, 'math objects: test product';
};

subtest 'check scores using the cmp method' => sub {
	is check_score($sum,  Compute($sum)),  1, 'math object: use cmp to check sum';
	is check_score($diff, Compute($diff)), 1, 'math object: use cmp to check diff';
	is check_score($prod, Compute($prod)), 1, 'math object: use cmp to check prod';
};

subtest 'check some wrong answers' => sub {
	is check_score($sum,  Compute($sum + 1)),  0, 'math object: use cmp to check sum';
	is check_score($diff, Compute($diff + 1)), 0, 'math object: use cmp to check diff';
	is check_score($prod, Compute($prod + 1)), 0, 'math object: use cmp to check prod';
};


done_testing();
