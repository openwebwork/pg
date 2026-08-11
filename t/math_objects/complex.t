#!/usr/bin/env perl

=head1 MathObjects - Complex numbers

Test creation and manipulation of Complex number math objects.

=cut

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

loadMacros('MathObjects.pl');

Context('Complex');

subtest 'Creating a Complex number' => sub {
	my $z1 = Complex(3, 4);
	my $z2 = Complex([ 3, 4 ]);
	my $z3 = Compute('3+4i');
	my $z4 = Compute('3+4*i');

	for my $z ($z1, $z2, $z3, $z4) {
		is $z->class, 'Complex', 'a Complex number has class Complex';
		is $z->type,  'Number',  'a Complex number has type Number';

		ok Value::isValue($z),   'a Complex number is a value';
		ok Value::isNumber($z),  'a Complex number is a number';
		ok Value::isComplex($z), 'a Complex number is complex';
		ok !Value::isReal($z),   'a Complex number is not real';

		is $z->Re->value, 3, 'real part is correct';
		is $z->Im->value, 4, 'imaginary part is correct';
	}
};

subtest 'Real numbers promote to Complex' => sub {
	my $z = Complex(5, 0) + Complex(0, 0);
	is $z->class,     'Complex', 'result of Complex arithmetic is still Complex';
	is $z->Re->value, 5,         'real part is correct';
	is $z->Im->value, 0,         'imaginary part is correct';
};

subtest 'Arithmetic with Complex numbers' => sub {
	my $z1 = Complex(1,  2);
	my $z2 = Complex(3, -1);

	is check_score($z1 + $z2, '4+i'),       1, 'addition of complex numbers';
	is check_score($z1 - $z2, '-2+3i'),     1, 'subtraction of complex numbers';
	is check_score($z1 * $z2, '5+5i'),      1, 'multiplication of complex numbers';
	is check_score($z1 / $z2, '(1+7i)/10'), 1, 'division of complex numbers';

	ok $z1 == Complex(1, 2), 'equality of complex numbers';
	ok $z1 != $z2,           'inequality of complex numbers';

	like(dies { $z1 / Complex(0, 0) }, qr/Division by zero/, 'division by zero is an error');
};

subtest 'Complex conjugate and modulus' => sub {
	my $z = Complex(3, 4);

	is check_score($z->conj, '3-4i'), 1, 'conjugate of a complex number';
	is $z->abs->value,                5, 'absolute value (modulus) of a complex number';
	is $z->norm->value,               5, 'norm of a complex number is the same as abs';

	is Compute('i')->arg->value, Compute('pi/2')->value, 'argument of i is pi/2';
};

subtest 'Negation of Complex numbers' => sub {
	my $z = Complex(3, -4);
	is check_score(-$z, '-3+4i'), 1, 'negation of a complex number';
};

subtest 'Powers of Complex numbers' => sub {
	my $z = Complex(0, 1);
	is check_score($z**2, '-1'), 1, 'i^2 is -1';
	is check_score($z**4, '1'),  1, 'i^4 is 1';
};

subtest 'sqrt and log of negative and complex numbers' => sub {
	is check_score(Compute('sqrt(-4)'), '2i'), 1, 'square root of a negative number is imaginary';
	is check_score(Compute('sqrt(-1)'), 'i'),  1, 'square root of -1 is i';
	is check_score(Compute('e^(i pi)'), '-1'), 1, "Euler's identity: e^(i pi) = -1";

	like(dies { Compute('log(0)') }, qr/Can't take log of 0/, 'log of zero is an error');
};

subtest 'Trigonometric and hyperbolic functions of Complex numbers' => sub {
	my $f = Compute('sin(z)^2 + cos(z)^2');

	is check_score($f->eval(z => Complex(1, 1)), '1'), 1, 'Pythagorean identity holds for complex arguments';

	ok Value::isComplex(Compute('sinh(i)')), 'sinh of a complex number is complex';
};

subtest 'Comparing to a Real number' => sub {
	my $z = Complex(5, 0);
	ok $z == 5,            'a Complex number with zero imaginary part equals the corresponding Real number';
	ok Complex(5, 1) != 5, 'a Complex number with nonzero imaginary part does not equal a Real number';
};

subtest 'Errors constructing invalid Complex numbers' => sub {
	like(
		dies { Complex(1, 2, 3) },
		qr/Can't convert ARRAY of length 3 to a Complex Number/,
		'a Complex number needs exactly two coordinates'
	);
};

Context('Numeric');

done_testing();
