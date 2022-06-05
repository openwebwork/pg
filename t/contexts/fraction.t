use Test2::V0;

# should I "use" Parser Value Parser::Legacy here instead?

use lib 't/lib';
use Test::PG;

=head2 Fraction context

To test the reduction of fractions

=cut

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

ok my $a1 = Compute("1/2");
ok my $a2 = Compute("2/4");

is $a1->value, $a2->value, 'contextFraction: reduce fractions';

done_testing();
