use warnings;
use strict;
package main;

use Data::Dump qw/dd/;
use Test::More;
use Test::Exception;
## the following needs to include at the top of any testing  down to TOP_MATERIAL

BEGIN {
	die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
	# die "WEBWORK_ROOT not found in environment.\n" unless $ENV{WEBWORK_ROOT};

	$main::pg_dir = $ENV{PG_ROOT};
	# $main::webwork_dir = $ENV{WEBWORK_ROOT};

}

# use lib "$main::webwork_dir/lib";
use lib "$main::pg_dir/lib";

require("$main::pg_dir/t/build_PG_envir.pl");

## END OF TOP_MATERIAL

use Parser;

loadMacros("MathObjects.pl");

Context("Numeric");

my ($val1,$val2) = (10,5);
my $obj1 = Compute($val1);
my $obj2 = Compute($val2);
my $one = Compute("1");
my $zero = Compute("0");


is($obj1->class,"Real","math objects: check class of object");
is($obj2->type,"Number","math objects: check type of object");
ok($one->isOne,"math objects: check if a number is 1");
ok(! $zero->isOne,"math objects: check if a number is not 1");
ok($zero->isZero,"math objects: check if a number is 0");
ok(! $one->isZero,"math objects: check if a number is not 0");

ok(Value::isValue($obj1),"math objects: check if an object is a value");
ok(Value::isNumber($obj1),"math objects: check if an object is a number");
ok(Value::isReal($obj1),"math objects: check if a number is a real number");
ok(! Value::isComplex($obj1),"math objects: check if an integer is complex");

ok(! Value::isFormula($obj1),"math objects: check if a number is not a formula");


# check infinite values
note("Tests for infinite values");

my $inf = Compute("inf");
is($inf->value,"infinity","math objects: check for infinity via a string");
is($inf->class,"Infinity","math objects: check that the class is Infinity");
is($inf->type,"Infinity","math objects: check that the type is Infinity");
ok(! Value::isNumber($inf),"math objects: check if inf is a number");

# check that operations with infinity are not allowed

throws_ok {
	Compute("$obj1+$inf");
} qr/can't be infinities/, "math objects: addition with infinity";
throws_ok {
	Compute("$obj1-$inf");
} qr/can't be infinities/, "math objects: subtraction with infinity";
throws_ok {
	Compute("$obj1*$inf");
} qr/can't be infinities/, "math objects: multiplication with infinity";
throws_ok {
	Compute("$obj1/$inf");
} qr/can't be infinities/, "math objects: division with infinity";





# is($result1->value,"infinity","math objects: check that the sum of a finite and infinite value is infinite");

my $sum = $obj1+$obj2;
my $diff = $obj1-$obj2;
my $prod = $obj1*$obj2;


is($sum->value,$val1+$val2,"math objects: test sum");
is($diff->value,$val1-$val2,"math objects: test difference");
is($prod->value,$val1*$val2,"math objects: test product");


## check scores using the cmp method

is (check_score($sum,Compute($sum)),1,"math object: use cmp to check sum");
is (check_score($diff,Compute($diff)),1,"math object: use cmp to check diff");
is (check_score($prod,Compute($prod)),1,"math object: use cmp to check prod");

## check some wrong answers;

is (check_score($sum,Compute($sum+1)),0,"math object: use cmp to check sum");
is (check_score($diff,Compute($diff+1)),0,"math object: use cmp to check diff");
is (check_score($prod,Compute($prod+1)),0,"math object: use cmp to check prod");



done_testing();