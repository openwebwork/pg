#!/usr/bin/env perl

=head1 Fraction context

Test the fraction context defined in contextFraction.pl.

=cut

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

use lib "$ENV{PG_ROOT}/lib";

loadMacros('PGstandard.pl', 'MathObjects.pl', 'contextFraction.pl');

use Value;
require Parser::Legacy;
import Parser::Legacy;

Context('Fraction');

ok my $a1 = Compute('1/2');
ok my $a2 = Compute('2/4');

is $a1->value, $a2->value, 'contextFraction: reduce fractions';

done_testing();
