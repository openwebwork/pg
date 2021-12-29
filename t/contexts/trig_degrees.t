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

loadMacros("contextTrigDegrees.pl");

my $ctx = Context("TrigDegrees");

ok(Value::isContext($ctx), "trig degrees: check context");

my $cos60 = Compute("cos(60)");

Compute("cos(60)")->cmp->evaluate("1/2");
# dd Compute("1/2")->value;
# is (check_score($cos60,"1/2"),1,"trig degrees: cos(60) = 1/2");

# dd $cos60->cmp->evaluate("1/2")->{type};
# dd $cos60->cmp->evaluate("1/2")->{score};
# dd $cos60->cmp->evaluate("1/2")->{correct_ans};
# dd $cos60->cmp->evaluate("1/2")->{student_ans};

# is (check_score(Compute("cos(60)"),"sin(30)"),1,"trig degrees: cos(60) = 1/2");

done_testing();
