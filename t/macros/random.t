use warnings;
use strict;
package main;

use Data::Dump qw/dd/;
use Test::More;


our %envir;

require("./build_PG_envir.pl");



isa_ok \%envir, 'HASH', "check that \%envir is defined as a hash";
isa_ok \%main::envir, 'HASH', "check that \%main::envir is defined as a hash";

loadMacros("PGauxiliaryFunctions.pl");


# set the seed relative to the time running to do more random testing.
SRAND(time % 100000);


## random_coprime

my @coprimes = random_pairwise_coprime([-9..-1,1..9],[1..9],[1..9]);
dd gcd(@coprimes);
dd gcd($coprimes[0],$coprimes[1]);
dd gcd($coprimes[0],$coprimes[2]);
dd gcd($coprimes[1],$coprimes[2]);


done_testing();