use Test2::V0;

# should I "use" Parser Value Parser::Legacy here instead?

use lib 't/lib';
use Test::PG;

=head2 Integer context

To test for greatest common denomenators and such like.

=cut

loadMacros("MathObjects.pl", "contextInteger.pl");

for my $module (qw/Parser Value Parser::Legacy/) {
	eval "package Main; require $module; import $module;";
}

Context("Integer");

my $b = Compute(gcd(5, 2));
ANS($b->cmp);

ok(1, "integer test: dummy test");

done_testing();
