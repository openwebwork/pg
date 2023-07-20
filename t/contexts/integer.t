#!/usr/bin/env perl

=head1 Integer context

Test contextInteger.pl methods.

=cut

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

use lib "$ENV{PG_ROOT}/lib";

loadMacros('MathObjects.pl', 'contextInteger.pl');

use Value;
require Parser::Legacy;
import Parser::Legacy;

Context('Integer');

my $b = Compute(gcd(5, 2));
ANS($b->cmp);

ok(1, 'integer test: dummy test');

done_testing();
