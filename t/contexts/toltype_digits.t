# this tests the tolType='digits' answer evaluator;

use warnings;
use strict;

package main;

use Data::Dump qw/dd/;
use Test::More;
use Test::Exception;

## the following needs to include at the top of any testing  down to TOP_MATERIAL

BEGIN {
	die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
	$main::pg_dir = $ENV{PG_ROOT};
}

use lib "$main::pg_dir/lib";

require("$main::pg_dir/t/build_PG_envir.pl");

## END OF TOP_MATERIAL

loadMacros("PGstandard.pl", "MathObjects.pl");

my $ctx = Context("Numeric");
$ctx->flags->set(tolType => 'digits', tolerance => 3, tolTruncation => 1);

my $pi = Real("pi");

is(check_score($pi, Compute("3.14")),  1, "toltype digits: pi is 3.14");
is(check_score($pi, Compute("3.141")), 1, "toltype digits: pi is 3.141");
is(check_score($pi, Compute("3.142")), 1, "toltype digits: pi is 3.142");
is(check_score($pi, Compute("3.143")), 0, "toltype digits: pi is not 3.143");
is(check_score($pi, Compute("3.15")),  0, "toltype digits: pi is not 3.15");

note("");
note("change tolTrunction to 0");

$ctx->flags->set(tolType => 'digits', tolerance => 3, tolTruncation => 0);
is(check_score($pi, Compute("3.14")),  1, "toltype digits: pi is 3.14");
is(check_score($pi, Compute("3.141")), 0, "toltype digits: pi is not 3.141");
is(check_score($pi, Compute("3.142")), 1, "toltype digits: pi is not 3.142");
is(check_score($pi, Compute("3.143")), 0, "toltype digits: pi is not 3.143");
is(check_score($pi, Compute("3.15")),  0, "toltype digits: pi is not 3.15");

note("");
note("set tolExtraDigits to 2");

$ctx->flags->set(
	tolType        => 'digits',
	tolerance      => 3,
	tolTruncation  => 0,
	tolExtraDigits => 2
);
is(check_score($pi, Compute("3.14")),  1, "toltype digits: pi is 3.14");
is(check_score($pi, Compute("3.141")), 0, "toltype digits: pi is not 3.141");
is(check_score($pi, Compute("3.142")), 1, "toltype digits: pi is not 3.142");
is(check_score($pi, Compute("3.143")), 0, "toltype digits: pi is not 3.143");
is(check_score($pi, Compute("3.15")),  0, "toltype digits: pi is not 3.15");

is(check_score($pi, Compute("3.1416")),    1, "toltype digits: pi is 3.1416");
is(check_score($pi, Compute("3.1415888")), 1, "toltype digits: pi is 3.1415888");
is(check_score($pi, Compute("3.1415")),    0, "toltype digits: pi is not 3.1415");

done_testing();
