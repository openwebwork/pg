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

loadMacros("PGstandard.pl", "MathObjects.pl", "contextFraction.pl");

# dd @INC;

for my $module (qw/Parser Value Parser::Legacy/) {
	eval "package Main; require $module; import $module;";
}

# use Value;
# use Value::Complex;
# # use Value::Type;
# use Parser::Context::Default;
# use Parser::Legacy;
# use Parser::Context;

Context("Fraction");

# require("Parser::Legacy::LimitedNumeric::Number");
# require("Parser::Legacy");

my $a1 = Compute("1/2");
my $a2 = Compute("2/4");

is($a1->value, $a2->value, "contextFraction: reduce fractions");

done_testing();
