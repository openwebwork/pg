use warnings;
use strict;

package main;

use Test::More;
use Test::Exception;

# The following needs to include at the top of any testing down to END OF TOP_MATERIAL.

BEGIN {
	die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
	$main::pg_dir = $ENV{PG_ROOT};
}

use lib "$main::pg_dir/lib";

require("$main::pg_dir/t/build_PG_envir.pl");

## END OF TOP_MATERIAL

loadMacros("MathObjects.pl", "contextInteger.pl");

for my $module (qw/Parser Value Parser::Legacy/) {
	eval "package Main; require $module; import $module;";
}

Context("Integer");

my $b = Compute(gcd(5, 2));
ANS($b->cmp);

ok(1, "integer test: dummy test");

done_testing();

