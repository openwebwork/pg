#!/usr/bin/env perl

# Tests subroutines in the PGnumericamacros.pl macro.

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

loadMacros('PGnumericalmacros.pl', 'MathObjects.pl', 'PGauxiliaryFunctions.pl');

subtest 'plot_list' => sub {
	ok my $p1 = plot_list([ 0, 0, 1, 2 ]);
	is &$p1(0.75), 1.5, 'linear interpolation at $x=0.75';
	is &$p1(0.25), 0.5, 'linear interpolation at $x=0.25';

	ok my $p2 = plot_list([ (0, 0), (1, 2) ]);
	is &$p2(0.75), 1.5, 'linear interpolation at $x=0.75';
	is &$p2(0.25), 0.5, 'linear interpolation at $x=0.25';

	ok my $p3 = plot_list([ 0, 3 ], [ 4, 0 ]);
	is &$p3(1.5), 2,     'linear interpolation at $x=0.75';
	is &$p3(2),   4 / 3, 'linear interpolation at $x=0.25';

	like dies { plot_list([ 0, 1, 3, 4, 5 ]) },
		qr/single array of input has odd number/,
		'Input of odd number of values';
	like dies { plot_list(0, 1, 3, 4, 5) },
		qr/Error in plot_list:X values must be given as an array reference./,
		'Values are not given as an array reference';
};

subtest 'horner' => sub {
	ok my $h1 = horner([ 0, 1, 2 ], [ 1, -1, 2 ]);    # 1-1*(x-0)+2(x-0)*(x-1)
	is &$h1(0.5), 0, 'h1(0.5)=0';                     #1-1*0.5+2*(0.5)*(-0.5) = 0
	is &$h1(1.5), 1, 'h1(1.5)=1';                     # 1-1*(1.5)+2*(1.5)*(0.5)= 1

	ok my $h2 = horner([ -1, 1, 2, 5 ], [ 2, 0, -2, 1 ]);    # 2+0(x+1)-2(x+1)(x-1)+(x+1)(x-1)(x-2)
	is &$h2(0), 6,  'h2(0)=6';                               # 2-2(1)(-1)+(1)(-1)(-2) = 6
	is &$h2(3), -6, 'h2(3)=-6';                              # 2-2(4)(2)+(4)(2)(1) = -6

	like dies { horner([ 0, 1, 2 ], [ -1, 0, 2, 3 ]); },
		qr/The x inputs and q inputs must be the same length/,
		'Input array refs are different lengths.';
};

subtest 'hermite' => sub {
	ok my $h1 = hermite([ 0, 1 ], [ 0, 0 ], [ 1, -1 ]);      # x-x^2
	is &$h1(0),    0,      'h1(0)=0';
	is &$h1(1),    0,      'h1(1)=0';
	is &$h1(0.5),  0.25,   'h1(0.5)=0.25';
	is &$h1(0.25), 0.1875, 'h1(0.25)=0.1875';

	ok my $h2 = hermite([ 0, 1, 3 ], [ 2, 0, 1 ], [ 1, 0, -1 ]);
	is &$h2(0),              2,                      'h2(0)=2';
	is &$h2(1),              0,                      'h2(1)=0';
	is Round(&$h2(3), 10),   1,                      'h2(3)=1';
	is Round(&$h2(0.5), 10), Round(1573 / 1728, 10), 'h2(1/2)=1573/1728';
	is Round(&$h2(2), 10),   Round(55 / 27, 10),     'h2(2)=55/27';

	like dies { hermite([ 0, 1, 2 ], [ 1, 1, 1 ], [ 0, 2 ]) },
		qr/The input array refs all must be the same length/,
		'Input array refs are different lengths.';
};

subtest 'hermite spline' => sub {
	ok my $h = hermite_spline([ 0, 1, 3 ], [ 3, 1, -5 ], [ 1, -2, 0 ]);
	is &$h(0),   3,      'h(0)=3';
	is &$h(1),   1,      'h(1)=1';
	is &$h(3),   -5,     'h(3)=-5';
	is &$h(0.5), 19 / 8, 'h(1/2)=19/8';
	is &$h(2),   -2.5,   'h(2)=-2.5';
	is &$h(1.3), 0.202,  'h(1.3)=0.202';
};

subtest 'cubic spline' => sub {
	ok my $s = cubic_spline([ 0, 1, 2 ], [ 0, 1, 0 ]);
	is &$s(0), 0, 's(0)=0';
	is &$s(1), 1, 's(1)=1';
	is &$s(2), 0, 's(2)=0';
	# not sure how the spline is constructed to find intermediate points.
	# is &$s(0.25), 0.4375;
	# is &$s(0.5), 0.75;
};

subtest 'Newton Divided difference' => sub {
	my @x = (0, 1, 3, 6);
	my @y = (0, 1, 2, 5);
	my $a =
		[ [ 0, 1, 2, 5 ], [ 1, 1 / 2, 1 ], [ -1 / 6, 1 / 10 ], [ 2 / 45 ] ];

	is newtonDividedDifference(\@x, \@y), $a, 'Newton Divided difference, test 1';

	@x = (5,  6,  9,  11);
	@y = (12, 13, 14, 16);
	$a =
		[ [ 12, 13, 14, 16 ], [ 1, 1 / 3, 1 ], [ -1 / 6, 4 / 30 ], [ 1 / 20 ] ];
	is newtonDividedDifference(\@x, \@y), $a, 'Newton Divided difference, test 2';
};

subtest 'Riemann Sums' => sub {
	my $f = sub { my $x = shift; return $x * $x; };
	is lefthandsum($f, 0, 2, steps => 4),  1.75,  'left hand sum of x^2 on [0,2]';
	is righthandsum($f, 0, 2, steps => 4), 3.75,  'right hand sum of x^2 on [0,2]';
	is midpoint($f, 0, 2, steps => 4),     2.625, 'midpoint rule of x^2 on [0,2]';
};

subtest 'Quadrature' => sub {
	my $f = sub { my $x = shift; return $x * $x; };
	my $g = sub { my $x = shift; return exp($x); };
	is simpson($f, 0, 2, steps => 4), 8 / 3,                "Simpson's rule of x^2 on [0,2]";
	is Round(simpson($g, 0, 1), 7),   Round(exp(1) - 1, 7), "Simpson's rule of e^x on [0,1]";
	like dies { simpson($f, 0, 2, steps => 5); },
		qr /Error: Simpson's rule requires an even number of steps./,
		'Check for odd number of steps';

	is trapezoid($f, 0, 2, steps => 4), 2.75, 'Trapezoid rule of x^2 on [0,2]';

	is romberg($f, 0, 2), 8 / 3,      'Romberg interation for x^2 on [0,2]';
	is romberg($g, 0, 1), exp(1) - 1, 'Romberg interation on e^x on [0,1]';

	is inv_romberg($g, 0, exp(1) - 1), 1.0, 'Inverse Romberg to find b with int of e^x on [0,b] returns 1';

	is newtonCotes($f, 0, 2, n => 4, method => 'trapezoid'),     2.75,  'Newton-Cotes (trapezoid) of x^2 on [0,2]';
	is newtonCotes($f, 0, 2, n => 4, method => 'simpson'),       8 / 3, 'Newton-Cotes (simpson) of x^2 on [0,2]';
	is newtonCotes($f, 0, 2, n => 4, method => 'three-eighths'), 8 / 3, 'Newton-Cotes (3/8) of x^2 on [0,2]';
	is newtonCotes($f, 0, 2, n => 4, method => 'boole'),         8 / 3, 'Newton-Cotes (boole) of x^2 on [0,2]';

	is newtonCotes($g, -1, 1, n => 1, method => 'trapezoid'), 3.0861612696304874,
		'Newton-Cotes (trapezoid) of e^x on [-1,1]';
	is newtonCotes($g, -1, 1, n => 1, method => 'simpson'), 2.362053756543496,
		'Newton-Cotes (simpsons) of e^x on [-1,1]';
	is newtonCotes($g, -1, 1, n => 1, method => 'three-eighths'), 2.355648119152531,
		'Newton-Cotes (3/8) of e^x on [-1,1]';
	is newtonCotes($g, -1, 1, n => 1, method => 'boole'), 2.350470903569373,
		'Newton-Cotes (boole) of e^x on [-1,1]';

	is newtonCotes($g, -1, 1, n => 4, method => 'trapezoid'), 2.3991662826140026,
		'Newton-Cotes (composite trapezoid, n=4) of e^x on [-1,1]';
	is newtonCotes($g, -1, 1, n => 4, method => 'simpson'), 2.3504530172422795,
		'Newton-Cotes (composite simpson, n=4) of e^x on [-1,1]';
	is newtonCotes($g, -1, 1, n => 4, method => 'three-eighths'), 2.350424908072871,
		'Newton-Cotes (composite 3/8, n=4) of e^x on [-1,1]';
	is newtonCotes($g, -1, 1, n => 4, method => 'boole'), 2.3504024061087962,
		'Newton-Cotes (composite boole, n=4) of e^x on [-1,1]';
};

subtest 'Quadrature - Open Newton-Cotes' => sub {
	my $f = sub { my $x = shift; return $x * $x; };
	my $g = sub { my $x = shift; return exp($x); };
	is newtonCotes($f, 0, 2, n => 1, method => 'open1'), 2,      'Newton-Cotes (open, k=1) of x^2 on [0,2]';
	is newtonCotes($f, 0, 2, n => 1, method => 'open2'), 20 / 9, 'Newton-Cotes (open, k=2) of x^2 on [0,2]';
	is newtonCotes($f, 0, 2, n => 1, method => 'open3'), 8 / 3,  'Newton-Cotes (open, k=3) of x^2 on [0,2]';
	is newtonCotes($f, 0, 2, n => 1, method => 'open4'), 8 / 3,  'Newton-Cotes (open, k=4) of x^2 on [0,2]';
};

sub roundArray {
	my ($arr, %options) = @_;
	%options = (digits => 6, %options);
	return [ map { defined($_) ? Round($_, $options{digits}) : $_ } @$arr ];
}

subtest 'Runge Kutta 4th order' => sub {
	my $f = sub {
		my ($t, $y) = @_;
		return $t * $t + $y * $y;
	};
	my $rk4 = rungeKutta4(
		$f,
		initial_t       => 0,
		initial_y       => 1,
		dt              => 0.2,
		num_of_points   => 5,
		interior_points => 1
	);
	is [ map { $_->[0] } @$rk4 ], [ 0, 0.2, 0.4, 0.6, 0.8, 1.0 ], 'returns correct x values';
	is roundArray([ map { $_->[1] } @$rk4 ]),
		roundArray([ 1, 1.25299088, 1.6959198, 2.6421097, 5.7854627, 99.9653469 ]),
		'returns correct y values';
};

subtest 'Options for solveDiffEqn' => sub {
	my $g = sub {
		my ($x, $y) = @_;
		return $x**2 + $y**2;
	};

	like dies {
		Context()->variables->add(y => 'Real');
		my $f = Formula('x^2+y^2');
		solveDiffEqn($f, 1);
	}, qr/The first argument must be a subroutine reference/, 'The first argument must be a sub.';
	like dies { solveDiffEqn($g, 1, n => -3) }, qr/The option n must be a positive integer/,
		'The option n is a positive integer';
	like dies { solveDiffEqn($g, 1, h => -0.25) }, qr/The option h must be a positive number/,
		'The option h is a positive number';
	like dies { solveDiffEqn($g, 1, method => 'error') },
		qr/The option method must be one of euler\/improved_euler\/heun\/rk4/, 'Checking for a value method';
};

subtest "Solve an ODE using Euler's method" => sub {
	my $g = sub {
		my ($x, $y) = @_;
		return $x**2 + $y**2;
	};

	my $soln = solveDiffEqn(
		$g, 1,
		method => 'euler',
		h      => 0.2,
		n      => 5
	);
	is $soln->{x}, [ 0, 0.2, 0.4, 0.6, 0.8, 1.0 ], 'returns correct x';
	is roundArray($soln->{y}),
		roundArray([ 1, 1.2, 1.496, 1.9756032, 2.8282048008, 4.5559532799 ]),
		'returns correct y';
};

subtest 'Solve an ODE using improved Euler\'s method ' => sub {
	my $g = sub {
		my ($x, $y) = @_;
		return $x**2 + $y**2;
	};

	my $soln = solveDiffEqn(
		$g, 1,
		x0     => 0,
		method => 'improved_euler',
		h      => 0.2,
		n      => 5
	);
	is $soln->{x}, [ 0, 0.2, 0.4, 0.6, 0.8, 1.0 ], 'returns correct x';
	# check the following to 6 digits.
	is roundArray($soln->{k1}),
		roundArray([ undef, 1, 1.597504, 2.947084257, 6.662185892, 22.89372811 ]),
		'returns correct k1';
	is roundArray($soln->{k2}),
		roundArray([ undef, 1.48, 2.617058758, 5.462507804, 15.40751657, 87.41805808 ]),
		'returns correct k2';
	is roundArray($soln->{y}),
		roundArray([ 1, 1.248, 1.669456276, 2.510415482, 4.717385728, 15.74856435 ]),
		'returns correct y';
};

subtest "Solve an ODE using Heun's method" => sub {
	my $g = sub {
		my ($x, $y) = @_;
		return $x**2 + $y**2;
	};

	my $soln = solveDiffEqn(
		$g, 1,
		x0     => 0,
		method => 'heun',
		h      => 0.2,
		n      => 5
	);
	is $soln->{x}, [ 0, 0.2, 0.4, 0.6, 0.8, 1.0 ], 'returns correct x';
	# check the following to 6 digits.
	is roundArray($soln->{k1}),
		roundArray([ undef, 1.0, 1.5908551111111113, 2.9161500566582608, 6.502422880077087, 21.460193376361623 ]),
		'returns correct k1';
	is roundArray($soln->{k2}),
		roundArray([
			undef, 1.302222222222222, 2.235263883735181, 4.482786757206292, 11.72935117869894, 55.9909574019759 ]),
		'returns correct k2';
	is roundArray($soln->{y}),
		roundArray([
			1, 1.2453333333333334, 1.6601656714491662, 2.478391187863023, 4.562915008671718, 14.034568287786184 ]),
		'returns correct y';
};

subtest 'Solve an ODE using 4th order Runge-Kutta ' => sub {
	my $g = sub {
		my ($x, $y) = @_;
		return $x**2 + $y**2;
	};

	my $soln = solveDiffEqn($g, 1, method => 'rk4', h => 0.2, n => 5);
	is $soln->{x}, [ 0, 0.2, 0.4, 0.6, 0.8, 1.0 ], 'returns correct x';
	# check the following to 6 digits.
	is roundArray($soln->{k1}),
		roundArray([ undef, 1, 1.6099859, 3.0361440, 7.3407438, 34.1115788 ]),
		'returns correct k1';
	is roundArray($soln->{k2}),
		roundArray([ undef, 1.22000, 2.0893660, 4.2481371, 11.8886191, 85.3878304 ]),
		'returns correct k2';
	is roundArray($soln->{k3}),
		roundArray([ undef, 1.2688840, 2.2272318, 4.7475107, 15.1663436, 205.9940166 ]),
		'returns correct k3';
	is roundArray($soln->{k4}),
		roundArray([ undef, 1.6119563, 3.0446888, 7.3582574, 32.8499206, 2208.5212543 ]),
		'returns correct k4';
	is roundArray($soln->{y}),
		roundArray([ 1, 1.25299088, 1.6959198, 2.6421097, 5.7854627, 99.9653469 ]),
		'returns correct y';
};

subtest 'Test that errors of the bisection method are returned correctly' => sub {
	my $bisect = bisection(Formula('x^2+2'), [ 0, 1 ]);
	like $bisect->{error}, qr/The function must be a code reference/, 'The function is not a code reference';

	my $g = sub { return (shift)**2 - 2; };

	$bisect = bisection($g, [ 0, 1 ]);
	like $bisect->{error}, qr/The function may not have a root/, 'The function may not have a root';

	$bisect = bisection($g, [ 0, 1, 2 ]);
	is $bisect->{error}, 'The interval must be an array ref of length 2', 'The interval must be an array ref';

	$bisect = bisection($g, [ 1, 0 ]);
	is $bisect->{error}, 'The initial interval [a, b] must satisfy a < b', 'Check the initial interval for a < b';

	$bisect = bisection($g, [ 0, 2 ], eps => -1);
	is $bisect->{error}, 'The option eps must be a positive number', 'The option eps must be a positive number';

	$bisect = bisection($g, [ 0, 2 ], max_iter => -1);
	is $bisect->{error}, 'The option max_iter must be a positive integer',
		'The option max_iter must be a positive integer';

	$bisect = bisection($g, [ 0, 2 ], max_iter => 1.5);
	is $bisect->{error}, 'The option max_iter must be a positive integer',
		'The option max_iter must be a positive integer';

	$bisect = bisection(sub { (shift)**2 - 19 }, [ 0, 100 ], max_iter => 20);
	like $bisect->{error}, qr/You have reached the maximum/, 'Reached the maximum number of iterations.';
};

subtest 'Find a root via bisection' => sub {
	my $g = sub { return (shift)**2 - 2; };

	my $bisect = bisection($g, [ 0, 2 ]);
	is roundArray([ map { $_->[0] } @{ $bisect->{intervals} }[ 0 .. 10 ] ]),
		roundArray([ 0.0, 1.0, 1.0, 1.25, 1.375, 1.375, 1.40625, 1.40625, 1.4140625, 1.4140625, 1.4140625 ]),
		'left endpoints of the bisection method';
	is roundArray([ map { $_->[1] } @{ $bisect->{intervals} }[ 0 .. 10 ] ]),
		roundArray([ 2.0, 2.0, 1.5, 1.5, 1.5, 1.4375, 1.4375, 1.421875, 1.421875, 1.41796875, 1.416015625 ]),
		'right endpoints of the bisection method';
	is sqrt(2), float($bisect->{root}, precision => 6), 'The root was found successfully.';
};

subtest "Test that the errors from Newton's method" => sub {
	my $newton = newton(Formula('x^2+2'), 1);
	like $newton->{error}, qr/The function must be a code reference/, 'The function is not a code reference';

	my $g  = sub { return (shift)**2 - 2; };
	my $dg = sub { return 2 * (shift); };

	$newton = newton($g, $dg, 1, eps => -1e-8);
	like $newton->{error}, qr/The option eps must be a positive number/, 'The option eps must be a positive number';

	$newton = newton($g, $dg, 1, feps => -1e-8);
	like $newton->{error}, qr/The option feps must be a positive number/,
		'The option feps must be a positive number';

	$newton = newton($g, $dg, 1, max_iter => -10);
	like $newton->{error}, qr/The option max_iter must be a positive integer/,
		'The option max_iter must be a positive number';

	$newton = newton(sub { my $x = shift; ($x)**2 + 2 }, sub { my $x = shift; 2 * $x; }, 1);
	like $newton->{error}, qr/Newton's method did not converge in \d+ steps/, "Newton's method did not converge.";
};

subtest "Find a root using Newton's method" => sub {
	my $g  = sub { return (shift)**2 - 2; };
	my $dg = sub { return 2 * (shift); };

	my $newton = newton($g, $dg, 10);
	is sqrt(2), float($newton->{root}), 'The root was found successfully.';

	is roundArray([ @{ $newton->{iterations} }[ 0 .. 5 ] ]),
		roundArray([ 10.0, 5.1, 2.7460784313725486, 1.7371948743795982, 1.444238094866232, 1.4145256551487377 ]),
		"iterations of newton's method";

};

subtest 'Test that the errors from the Secant method' => sub {

	my $secant = secant(Formula('x^2+2'), 1, 2);
	like $secant->{error}, qr/The function must be a code reference/, 'The function is not a code reference';

	my $g = sub { return (shift)**2 - 2; };

	$secant = secant($g, 1, 2, eps => -1e-8);
	like $secant->{error}, qr/The option eps must be a positive number/, 'The option eps must be a positive number';

	$secant = secant($g, 1, 2, feps => -1e-8);
	like $secant->{error}, qr/The option feps must be a positive number/,
		'The option feps must be a positive number';

	$secant = secant($g, 1, 2, max_iter => -10);
	like $secant->{error}, qr/The option max_iter must be a positive integer/,
		'The option max_iter must be a positive number';

	$secant = secant(sub { return (shift)**2 + 2; }, 1, 2);
	like $secant->{error}, qr/The secant method did not converge in \d+ steps/,
		'The secant method did not converge.';
};

subtest 'Find a root using the Secant method' => sub {
	my $g      = sub { return (shift)**2 - 2; };
	my $secant = secant($g, 1, 2);
	is sqrt(2), float($secant->{root}), 'The root was found successfully.';

	is roundArray([ @{ $secant->{iterations} }[ 0 .. 6 ] ]),
		roundArray([ 1.0, 2.0, 1.3333333333333335, 1.4, 1.4146341463414633, 1.41421143847487, 1.4142135620573204 ]),
		'iterations of the secant method';

};

done_testing;
