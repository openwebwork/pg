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
	# check intermediate points:
	is &$s(0.25), 0.3671875, 'check s(0.25)';
	is &$s(0.5),  0.6875,    'check s(0.5)';
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
};

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

sub roundArray {
	my ($arr, %options) = @_;
	%options = (digits => 6, %options);
	return [ map { defined($_) ? Round($_, $options{digits}) : $_ } @$arr ];
}

done_testing;
