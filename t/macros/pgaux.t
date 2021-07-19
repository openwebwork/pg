use warnings;
use strict;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
        $main::test_dir = abs_path( dirname(__FILE__) );
	$main::macros_dir  = dirname( dirname($main::test_dir) ) . '/macros';
}

use Data::Dump qw/dd/;
use Test::More;

sub loadMacros {
	for my $file (@_) {
	require("$main::macros_dir/$file");
	}
}

sub ParserDefineLog {

}

require("$main::macros_dir/PGauxiliaryFunctions.pl");

# test step functions

is(step(8),1,"step: positive number");
is(step(-8),0,"step: negative number");
is(step(0),0,"step: step(0)=0");

# test floor function

is(floor(0.5),0,"floor: positive non-integer");
is(floor(-0.5),-1,"floor: negative non-integer");
is(floor(1),1,"floor: positive integer");
is(floor(0),0,"floor: floor(0)=0");
is(floor(-1),-1,"floor: negative integer");

# test ceiling function

is(ceil(0.5),1,"ceil: positive non-integer");
is(ceil(-0.5),0,"ceil: negative non-integer");
is(ceil(1),1,"ceil: positive integer");
is(ceil(0),0,"ceil: floor(0)=0");
is(ceil(-1),-1,"ceil: negative integer");

# max/min functions

is(max(1,2,3,9,4,5,6,8),9,"max: set of integers");
is(max(0.1,-2.3,1.345,2.71712,-1000.1),2.71712,"max: set of decimals");
is(min(1,2,3,9,4,5,6,8),1,"min: set of integers");
is(min(0.1,-2.3,1.345,2.71712,-1000.1),-1000.1,"min: set of decimals");

# round function

is(round(0.95),1,"round: fractional part > 0.5");
is(round(0.45),0,"round: fractional part < 0.5");
is(round(0.5),1,"round: fractional part = 0.5");
is(round(-0.95),-1,"round: fractional part > 0.5 and negative");
is(round(-0.45),0,"round: fractional part < 0.5 and negative");
is(round(-0.5),-1,"round: fractional part = 0.5 and negative");

## Round function which takes a second number, the number of digits to round to

is(Round(1.793,2),1.79,"Round to 2 digits: test 1");
is(Round(1.797,2),1.80,"Round to 2 digits: test 2");
is(Round(1.795,2),1.80,"Round to 2 digits: test 3");
is(Round(-1.793,2),-1.79,"Round to 2 digits: test 1");
is(Round(-1.797,2),-1.80,"Round to 2 digits: test 2");
is(Round(-1.795,2),-1.80,"Round to 2 digits: test 3");

is(Round(15.793,-1),20,"Round to -1 digits (nearest 10)");

## lcm

is(lcm(20,30),60,"lcm: non relatively prime numbers");
is(lcm(5,6),30,"lcm: relatively prime numbers");
is(lcm(2,3,4),12,"lcm: 3 numbers");
is(lcm(2,3,4,5,6,7,8),840,"lcm: 7 numbers");


## gcd
is(gcd(16,8),8,"gcd: 2 powers of 2");
is(gcd(10,9),1,"gcd: 2 relatively prime");

is(gcd(10,20,30,40),10,"gcd: 4 multiples of 10");

## isPrime
is (isPrime(7),1,"isPrime: 7 is prime");
is (isPrime(2),1,"isPrime: 2 is prime");
is (isPrime(15),0,"isPrime: 15 is not prime");

## reduce
## it would be nicer to directly compare the arrays
my @my_arr = (3,4);
my @res = reduce(15,20);
ok ($my_arr[0] eq $res[0] , "reduce: correct numerator");
ok ($my_arr[1] eq $res[1] , "reduce: correct denominator");



done_testing;
