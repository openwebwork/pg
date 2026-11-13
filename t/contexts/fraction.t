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
use Parser;
use Parser::Legacy;

Context('Fraction');

subtest 'contextFraction: Basic computation and reduction' => sub {
	ok my $a1 = Compute('1/2'), 'compute 1/2';
	ok my $a2 = Compute('2/4'), 'compute 2/4';

	is $a1->value, $a2->value, 'comparison (1/2 = 2/4)';
};

subtest 'contextFraction: Conversion of real to fraction' => sub {
	my ($result, $direct);
	for my $num (1 .. 100) {
		for my $den (1 .. 100) {
			my $real = Real($num / $den);
			push(@$result, Fraction($real)->value);
			push(@$direct, Fraction($num, $den)->value);
		}
	}

	is $result, $direct, 'converted real gives correct fraction';
};

subtest 'contextFraction: Division of Complex numbers' => sub {
	Context(context::Fraction::extending('Complex'));

	my $z = Complex('4-3i') / Complex('2+5i');
	ok Value::isComplex($z), 'quotient is complex';
	my ($a, $b) = $z->value;
	ok Value::classMatch($a, 'Fraction'), 'real part is a fraction';
	ok Value::classMatch($b, 'Fraction'), 'imaginary part is a fraction';
	is [ $a->value ], [ -7, 29 ],                         'real part is -7/29';
	is [ $b->value ], [ -26, 29 ],                        'imaginary part is -26/29';
	is $z->string,    '-7/29-(26/29)i',                   'string output';
	is $z->TeX,       '-{\frac{7}{29}}-{\frac{26}{29}}i', 'TeX output';

	is Compute('(4-3i)/(2+5i)')->string, '-7/29-(26/29)i', 'parsed division gives fractions';
	is((Complex('4+2i') / 2)->string,               '2+i',      'whole number result');
	is((Complex('1.5+i') / Complex('2+i'))->string, '0.8+0.1i', 'decimals give a decimal result');

	is Compute('i/5')->string,     '(1/5)i',     'constant i divided by an integer';
	is Compute('3/i')->string,     '-3i',        'integer divided by constant i';
	is Compute('i/(2+i)')->string, '1/5+(2/5)i', 'constant i divided by a complex';
	is Compute('pi/2')->string,    '1.5708',     'real constants stay decimals';

	is check_score($z, '-7/29 - 26/29 i'), 1, 'fraction answer is correct';
	is check_score($z, '(-7-26i)/29'),     1, 'unsimplified answer is correct';
	is check_score($z, '-7/29 + 26/29 i'), 0, 'wrong sign is incorrect';

	like(dies { Complex('4-3i') / Complex(0, 0) }, qr/Division by zero/, 'division by zero is an error');
	like(
		dies { Compute('1/2+i') / Complex(Fraction(0, 1), Fraction(0, 1)) },
		qr/Division by zero/,
		'division by zero with fraction parts is an error'
	);

	Context('Fraction');
};

done_testing();
