use warnings;
use strict;

package main;

use Test::More;
use Test::Exception;

# The following needs to include at the top of any testing down to END OF TOP_MATERIAL.

BEGIN {
	die 'PG_ROOT not found in environment.\n' unless $ENV{PG_ROOT};
	$main::pg_dir = $ENV{PG_ROOT};
}

use lib "$main::pg_dir/lib";

require("$main::pg_dir/t/build_PG_envir.pl");

## END OF TOP_MATERIAL

use Parser;

loadMacros('MathObjects.pl');

Context('Numeric');
Context()->variables->add(y => "Real");
Context()->variables->add(n => "Real");

my $five_fact = Compute('5!');

use Data::Dumper;
print Dumper $five_fact->class;

is($five_fact->class, 'Real',   'factorial: check class of object');
is($five_fact->type,  'Number', 'factorial: check type of object');

ok(Value::isValue($five_fact),    'factorial: check if an object is a value');
ok(Value::isNumber($five_fact),   'factorial: check if an object is a number');
ok(Value::isReal($five_fact),     'factorial: check if a number is a real number');
ok(!Value::isComplex($five_fact), 'factorial: check if an integer is complex');
ok(!Value::isFormula($five_fact), 'factorial: check if a number is not a formula');

is($five_fact->value,120, 'factorial: 5! is 120');
is(Compute("0!")->value, 1, 'factorial: 0! is 1');

note('The double factorial is not defined here.');
my $four_double_fact = Compute("4!!")->value;
ok(6.2e+23 < $four_double_fact && $four_double_fact < 6.3e+23, 'factorial: 4!! is defined as (4!)!=24!' );

ok(Compute("170!") > 1e+306, 'factorial: 170! is large but not infinite.');

note('Tests for throwing exceptions.');

throws_ok {
	Compute("(-1)!");
}
qr/Factorial can only be taken of \(non-negative\) integers/, 'factorial: can\'t take factorial of negative integers.';

throws_ok {
	Compute("1.5!");
}
qr/Factorial can only be taken of \(non-negative\) integers/, 'factorial: can\'t take factorial of non-integer reals.';

note('Try taking factorials of variables');
my $n_fact = Compute("n!");
is($n_fact->class, "Formula", "factorial: n! is a Formula");
is($n_fact->type,  "Number",  "factorial: n! has type is Number");
is($n_fact->eval(n=>5), 120, 'factorial: n! evaluated at n=5 is correct.');

# check infinite values
note('Tests for infinite values');

my $large_fact = Compute('171!');
my $inf = Compute('inf');
is($large_fact->value, $inf, '171! is infinite.');

done_testing();
