use warnings;
use strict;
package main;

use Data::Dump qw/dd/;
use Test::More;


## the following needs to include at the top of any testing  down to TOP_MATERIAL

BEGIN {
	die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
	die "WEBWORK_ROOT not found in environment.\n" unless $ENV{WEBWORK_ROOT};

	$main::pg_dir = $ENV{PG_ROOT};
	$main::webwork_dir = $ENV{WEBWORK_ROOT};

}


use lib "$main::webwork_dir/lib";
use lib "$main::pg_dir/lib";

require("$main::pg_dir/t/build_PG_envir.pl");

## END OF TOP_MATERIAL


loadMacros("PGauxiliaryFunctions.pl");

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

## random_coprime

my $sum = 0;
for my $i (1..1000) {
	my @coprimes = random_coprime([1..20],[1..20]);
	$sum += gcd($coprimes[0],$coprimes[1]);
}
is($sum,1000,"random_coprime: 1000 tests in 1..20,1..20");

$sum = 0;

for my $i (1..1000) {
	my @coprimes = random_coprime([-9..-1,1..9],[1..9],[1..9]);
	$sum += gcd(@coprimes);
}
is($sum,1000,"random_coprime: 1000 tests in [-9..-1,1..9],[1..9],[1..9]");

my ($sum1, $sum2, $sum3,$sum4) = (0,0,0);
for my $i (1..1000) {
	my @coprimes = random_pairwise_coprime([-9..-1,1..9],[1..9],[1..9]);
	$sum1 += gcd(@coprimes);
	$sum2 += gcd($coprimes[0],$coprimes[1]);
	$sum3 += gcd($coprimes[0],$coprimes[2]);
	$sum4 += gcd($coprimes[1],$coprimes[2]);
}
is($sum1+$sum2+$sum3+$sum4,4000,"random_pairwise_coprime: 1000 tests of [-9..-1,1..9],[1..9],[1..9]");

## reduce
## it would be nicer to directly compare the arrays
my @my_arr = (3,4);
my @res = reduce(15,20);
is ($my_arr[0], $res[0] , "reduce: correct numerator");
is ($my_arr[1], $res[1] , "reduce: correct denominator");



done_testing;
