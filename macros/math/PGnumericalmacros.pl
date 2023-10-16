################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2023 The WeBWorK Project, https://github.com/openwebwork
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of either: (a) the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version, or (b) the "Artistic License" which comes with this package.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
# Artistic License for more details.
################################################################################

=head1 NAME

Numerical methods for the PG language

=cut

BEGIN {
	be_strict();
}

sub _PGnumericalmacros_init { }

=head2 Interpolation  methods

=head3 Plotting a list of points (piecewise linear interpolation)

Usage:

    plot_list([x0,y0,x1,y1,...]);
    plot_list([(x0,y0),(x1,y1),...]);
    plot_list(\x_y_array);

    plot_list([x0,x1,x2...], [y0,y1,y2,...]);
    plot_list(\@xarray,\@yarray);


=cut

BEGIN { strict->import; }
# TODO: this fails if the $xref are not unique and ordered.  Should check for
# these and document.

sub plot_list {
	my ($xref, $yref) = @_;
	unless (defined($xref) && ref($xref) =~ /ARRAY/) {
		die "Error in plot_list:X values must be given as an array reference.
         Remember to use ~~\@array to reference an array in the PG language.";
	}
	if (defined($yref) && !(ref($yref) =~ /ARRAY/)) {
		die "Error in plot_list:Y values must be given as an array reference.
         Remember to use ~~\@array to reference an array in the PG language.";
	}
	my (@x_vals, @y_vals);
	unless (defined($yref)) {    #with only one entry we assume (x0,y0,x1,y1..);
		if (@$xref % 2 == 1) {
			die "ERROR in plot_list -- single array of input has odd number of elements";
		}

		my @in = @$xref;
		while (@in) {
			push(@x_vals, shift(@in));
			push(@y_vals, shift(@in));
		}
		$xref = \@x_vals;
		$yref = \@y_vals;
	}

	return sub {
		my $x = shift;
		my $y;
		my ($x0, $x1, $y0, $y1);
		my @x_values = @$xref;
		my @y_values = @$yref;
		while ((@x_values and $x > $x_values[0])
			or (@x_values > 0 and $x >= $x_values[0]))
		{
			$x0 = shift(@x_values);
			$y0 = shift(@y_values);
		}
		# now that we have the left hand of the input
		#check first that x isn't out of range to the left or right
		if (@x_values && defined($x0)) {
			$x1 = shift(@x_values);
			$y1 = shift(@y_values);
			$y  = $y0 + ($y1 - $y0) * ($x - $x0) / ($x1 - $x0);
		}
		$y;
	};
}

=head3 Horner polynomial/ Newton polynomial

Usage:

    $fn = horner([x0,x1,x2, ...],[q0,q1,q2, ...]);

Produces the newton polynomial

    &$fn(x) = q0 + q1*(x-x0) +q2*(x-x1)*(x-x0) + ...;

Generates a subroutine which evaluates a polynomial passing through the points
C<(x0,q0), (x1,q1), (x2, q2)>, ... using Horner's method.

The array refs for C<x> and C<q> can be any length but must be the same length.

=head4 Example

    $h = horner([0,1,2],[1,-1,2]);

Then C<&$h(num)> returns the polynomial at the value C<num>.  For example,
C<&$h(1.5)=1>.

=cut

sub horner {
	my ($xref, $qref) = @_;    # get the coefficients
	die 'The x inputs and q inputs must be the same length'
		unless scalar(@$xref) == scalar(@$qref);
	return sub {
		my $x     = shift;
		my @xvals = @$xref;
		my @qvals = @$qref;
		my $y     = pop(@qvals);
		pop(@xvals);
		while (@qvals) {
			$y = $y * ($x - pop(@xvals)) + pop(@qvals);
		}
		$y;
	};
}

=head3 Hermite polynomials

Usage:

    $poly = hermite([x0,x1...],[y0,y1...],[yp0,yp1,...]);

Produces a reference to polynomial function with the specified values and first derivatives
at (x0,x1,...). C<&$poly(34)> gives a number

Generates a subroutine which evaluates a polynomial passing through the specified points
with the specified derivatives: (x0,y0,yp0) ...
The polynomial will be of high degree and may wobble unexpectedly.  Use the Hermite splines
described below and in Hermite.pm for  most graphing purposes.

=head4 Example

    $h = hermite([0,1],[0,0],[1,-1]);

C<&$h(num)> will evaluate the hermite polynomial at C<num>.  For example, C<&$h(0.5)>
returns C<0.25>.

=cut

sub hermite {
	my ($x_ref, $y_ref, $yp_ref) = @_;
	die 'The input array refs all must be the same length'
		unless scalar(@$x_ref) == scalar(@$y_ref) && scalar(@$y_ref) == scalar(@$yp_ref);
	my (@zvals, @qvals);
	my $n = $#{$x_ref};

	for my $i (0 .. $n) {
		$zvals[ 2 * $i ]        = $$x_ref[$i];
		$zvals[ 2 * $i + 1 ]    = $$x_ref[$i];
		$qvals[ 2 * $i ][0]     = $$y_ref[$i];
		$qvals[ 2 * $i + 1 ][0] = $$y_ref[$i];
		$qvals[ 2 * $i + 1 ][1] = $$yp_ref[$i];
		$qvals[ 2 * $i ][1] =
			($qvals[ 2 * $i ][0] - $qvals[ 2 * $i - 1 ][0]) / ($zvals[ 2 * $i ] - $zvals[ 2 * $i - 1 ])
			unless $i == 0;
	}

	for my $i (2 .. (2 * $n + 1)) {
		for my $j (2 .. $i) {
			$qvals[$i][$j] = ($qvals[$i][ $j - 1 ] - $qvals[ $i - 1 ][ $j - 1 ]) / ($zvals[$i] - $zvals[ $i - $j ]);
		}
	}

	my @output;
	for my $i (0 .. 2 * $n + 1) {
		push(@output, $qvals[$i][$i]);
	}
	return horner(\@zvals, \@output);
}

=head3 Hermite splines

Usage

    $spline = hermit_spline([x0,x1...],[y0,y1...],[yp0,yp1,...]);

Produces a reference to a piecewise cubic hermit spline with the specified values
and first derivatives at (x0,x1,...).

C<&$spline(45)> evaluates to a number.

Generates a subroutine which evaluates a piecewise cubic polynomial
passing through the specified points with the specified derivatives: (x0,y0,yp0) ...

An object oriented version of this is defined in Hermite.pm

=cut

sub hermite_spline {
	my ($xref, $yref, $ypref) = @_;
	my @xvals  = @$xref;
	my @yvals  = @$yref;
	my @ypvals = @$ypref;
	my $x0     = shift @xvals;
	my $y0     = shift @yvals;
	my $yp0    = shift @ypvals;
	my ($x1, $y1, $yp1);
	my @polys;    #calculate a hermite polynomial evaluator for each region

	while (@xvals) {
		$x1  = shift @xvals;
		$y1  = shift @yvals;
		$yp1 = shift @ypvals;
		push @polys, hermite([ $x0, $x1 ], [ $y0, $y1 ], [ $yp0, $yp1 ]);
		$x0  = $x1;
		$y0  = $y1;
		$yp0 = $yp1;
	}

	return sub {
		my $x = shift;
		my $y;
		my $fun;
		my @xvals = @$xref;
		my @fns   = @polys;

		#handle left most endpoint
		return $y = &{ $fns[0] }($x) if $x == $xvals[0];

		# find the function for this range of x
		while (@xvals && $x > $xvals[0]) {
			shift(@xvals);
			$fun = shift(@fns);
		}

		# now that we have the left hand of the input
		#check first that x isn't out of range to the left or right
		if (@xvals && defined($fun)) {
			$y = &$fun($x);
		}
		return $y;
	};
}

=head3 Cubic spline approximation

Usage:

    $fun_ref = cubic_spline(~~@x_values, ~~@y_values);

Where the x and y value arrays come from the function to be approximated.
The function reference will take a single value x and produce value y.

    $y = &$fun_ref($x);

You can also generate javaScript which defines a cubic spline:

    $function_string = javaScript_cubic_spline(~~@_x_values, ~~@y_values,
        name =>  'myfunction1',
        llimit => -3,
        rlimit => 3,
    );

This will return

    <SCRIPT LANGUAGE="JavaScript">
    <!-- Begin
    function myfunction1(x) {
    ...etc...
    }
    </SCRIPT>

and can be placed in the header of the HTML output using

    HEADER_TEXT($function_string);

=cut

sub cubic_spline {
	my ($t_ref, $y_ref) = @_;
	my @spline_coeff = create_cubic_spline($t_ref, $y_ref);
	return sub {
		my $x = shift;
		eval_cubic_spline($x, @spline_coeff);
	}
}

sub eval_cubic_spline {
	my ($x, $t_ref, $a_ref, $b_ref, $c_ref, $d_ref) = @_;
	#	The knot points given by $t_ref should be in order.
	my $i   = 0;
	my $out = 0;
	$i++ while (defined($t_ref->[ $i + 1 ]) && $x > $t_ref->[ $i + 1 ]);
	unless (defined($t_ref->[$i]) && ($t_ref->[$i] <= $x) && ($x <= $t_ref->[ $i + 1 ])) {
		$out = undef;
		# input value is not in the range defined by the function.
	} else {
		$out =
			($t_ref->[ $i + 1 ] - $x) * (($d_ref->[$i]) + ($a_ref->[$i]) * ($t_ref->[ $i + 1 ] - $x)**2) +
			($x - $t_ref->[$i]) * (($b_ref->[$i]) * ($x - $t_ref->[$i])**2 + ($c_ref->[$i]));
	}
	return $out;
}

# Cubic spline algorithm adapted from p319 of Kincaid and Cheney's Numerical Analysis.
sub create_cubic_spline {
	my ($t_ref, $y_ref) = @_;
	#	The knot points are given by $t_ref (in order) and the function values by $y_ref
	my $num = $#{$t_ref};    # number of knots

	my (@h, @b, @u, @v, @z);
	for my $i (0 .. $num - 1) {
		$h[$i] = $t_ref->[ $i + 1 ] - $t_ref->[$i];
		$b[$i] = 6 * ($y_ref->[ $i + 1 ] - $y_ref->[$i]) / $h[$i];
	}
	$u[1] = 2 * ($h[0] + $h[1]);
	$v[1] = $b[1] - $b[0];
	for my $i (2 .. $num - 1) {
		$u[$i] = 2 * ($h[$i] + $h[ $i - 1 ]) - ($h[ $i - 1 ])**2 / $u[ $i - 1 ];
		$v[$i] =
			$b[$i] - $b[ $i - 1 ] - $h[ $i - 1 ] * $v[ $i - 1 ] / $u[ $i - 1 ];
	}
	$z[$num] = 0;
	for (my $i = $num - 1; $i > 0; $i--) {
		$z[$i] = ($v[$i] - $h[$i] * $z[ $i + 1 ]) / $u[$i];
	}
	$z[0] = 0;
	my ($a_ref, $b_ref, $c_ref, $d_ref);
	for my $i (0 .. $num - 1) {
		$a_ref->[$i] = $z[$i] / (6 * $h[$i]);
		$b_ref->[$i] = $z[ $i + 1 ] / (6 * $h[$i]);
		$c_ref->[$i] = (($y_ref->[ $i + 1 ]) / $h[$i] - $z[ $i + 1 ] * $h[$i] / 6);
		$d_ref->[$i] = (($y_ref->[$i]) / $h[$i] - $z[$i] * $h[$i] / 6);
	}
	return ($t_ref, $a_ref, $b_ref, $c_ref, $d_ref);
}

sub javaScript_cubic_spline {
	my $x_ref   = shift;
	my $y_ref   = shift;
	my %options = @_;
	assign_option_aliases(
		\%options,

	);
	set_default_options(
		\%options,
		name   => 'func',
		llimit => $x_ref->[0],
		rlimit => $x_ref->[$#$x_ref],
	);

	my ($t_ref, $a_ref, $b_ref, $c_ref, $d_ref) = create_cubic_spline($x_ref, $y_ref);

	my $str_t_array = "t = new Array(" . join(",", @$t_ref) . ");";
	my $str_a_array = "a = new Array(" . join(",", @$a_ref) . ");";
	my $str_b_array = "b = new Array(" . join(",", @$b_ref) . ");";
	my $str_c_array = "c = new Array(" . join(",", @$c_ref) . ");";
	my $str_d_array = "d = new Array(" . join(",", @$d_ref) . ");";

	my $output_str = <<END_OF_JAVA_TEXT;
<SCRIPT LANGUAGE="JavaScript">
<!-- Begin



function $options{name}(x) {
	$str_t_array
	$str_a_array
	$str_b_array
	$str_c_array
	$str_d_array

	// Evaluate a cubic spline defined by the vectors above
	i = 0;
	while (x > t[i+1] ) {
		i++
	}

	if ( t[i] <= x && x <= t[i+1]  && $options{llimit} <= x && x <= $options{rlimit} ) {
		return (   ( t[i+1] - x )*( d[i] +a[i]*( t[i+1] - x )*( t[i+1] - x ) )
		         + ( x -   t[i] )*( b[i]*( x - t[i])*( x - t[i] ) +c[i] )
		       );

	} else {
		return( "undefined" ) ;
	}

}
// End
 -->
</SCRIPT>
<NOSCRIPT>
This problem requires a browser capable of processing javaScript
</NOSCRIPT>
END_OF_JAVA_TEXT

	$output_str;
}

=head3 Newton Divided Difference

Computes the newton divided difference table with the function C<newtonDividedDifference>.

=head4 Arguments

=over

=item * C<x> an array reference for x values.

=item * C<y> an array reference for y values.  This is the first row/column in the divided
difference table.

=back

=head4 Ouput

An arrayref of arrayrefs of Divided Differences.

=head4 Examples

  $x=[0,1,3,6];
  $y=[0,1,2,5];

  $c=newtonDividedDifference($x,$y)

The result of C<$c> is

  [ [0,1,2,5],
    [1,0.5,1],
    [-0.1667,0.1],
    [0.0444]
  ]

This is generally laid out in the following way:

  0  0
        1
  1  1      -0.1667
        0.5         0.04444
  3  2      0.1
        1
  6  5

where the first column is C<$x>, the second column is C<$y> and the rest of the table
is

   f[x_i,x_j] = (f[x_j]-f[x_i])/(x_j - x_i)

=cut

sub newtonDividedDifference {
	my ($x, $y) = @_;
	my $a = [ [@$y] ];
	for my $j (0 .. (scalar(@$x) - 2)) {
		for my $i (0 .. (scalar(@$x) - ($j + 2))) {
			$a->[ $j + 1 ][$i] = ($a->[$j][ $i + 1 ] - $a->[$j][$i]) / ($x->[ $i + $j + 1 ] - $x->[$i]);
		}
	}
	return $a;
}

=head2 Numerical Integration methods

=head3 Left Hand Riemann Sum

Usage:

    lefthandsum(function_reference, start, end, steps=>30 );

Implements the Left Hand sum using 30 intervals between 'start' and 'end'.
The first three arguments are required.  The final argument (number of steps) is
optional and defaults to 30.

=cut

sub lefthandsum {
	my ($fn_ref, $x0, $x1, %options) = @_;
	assign_option_aliases(\%options, intervals => 'steps',);
	set_default_options(\%options, steps => 30);
	my $steps = $options{steps};
	my $delta = ($x1 - $x0) / $steps;
	my $sum   = 0;

	for my $i (0 .. ($steps - 1)) {
		$sum += &$fn_ref($x0 + $i * $delta);
	}
	return $sum * $delta;
}

=head3 Right Hand Riemann Sum

Usage:

    righthandsum(function_reference, start, end, steps=>30 );

Implements the right hand sum using 30 intervals between 'start' and 'end'.
The first three arguments are required.  The final argument (number of steps)
is optional and defaults to 30.

=cut

sub righthandsum {
	my ($fn_ref, $x0, $x1, %options) = @_;
	assign_option_aliases(\%options, intervals => 'steps',);
	set_default_options(\%options, steps => 30);
	my $steps = $options{steps};
	my $delta = ($x1 - $x0) / $steps;
	my $sum   = 0;

	for my $i (1 .. $steps) {
		$sum += &$fn_ref($x0 + $i * $delta);
	}
	return $sum * $delta;
}

=head3 Midpoint rule

Usage:

    midpoint(function_reference, start, end, steps=>30 );

Implements the Midpoint rule between 'start' and 'end'.
The first three arguments are required.  The final argument (number of steps)
is optional and defaults to 30.

=cut

sub midpoint {
	my ($fn_ref, $x0, $x1, %options) = @_;
	assign_option_aliases(\%options, intervals => 'steps',);
	set_default_options(\%options, steps => 30,);
	my $steps = $options{steps};
	my $delta = ($x1 - $x0) / $steps;
	my $sum   = 0;

	for my $i (0 .. ($steps - 1)) {
		$sum += &$fn_ref($x0 + ($i + 1 / 2) * $delta);
	}
	return $sum * $delta;
}

=head3 Simpson's rule

    Usage:  simpson(function_reference, start, end, steps=>30 );

Implements Simpson's rule between 'start' and 'end'.
The first three arguments are required.  The final argument (number of steps) is
optional and defaults to 30, but must be even.

=cut

sub simpson {
	my ($fn_ref, $x0, $x1, %options) = @_;
	assign_option_aliases(\%options, intervals => 'steps',);
	set_default_options(\%options, steps => 30);
	my $steps = $options{steps};
	die "Error: Simpson's rule requires an even number of steps." unless $steps % 2 == 0;

	my $delta = ($x1 - $x0) / $steps;
	my $sum   = 0;
	for (my $i = 1; $i < $steps; $i = $i + 2) {    # look this up - loop by two.
		$sum += 4 * &$fn_ref($x0 + $i * $delta);
	}
	for (my $i = 2; $i < $steps - 1; $i = $i + 2) {    # ditto
		$sum += 2 * &$fn_ref($x0 + $i * $delta);
	}
	$sum += &$fn_ref($x0) + &$fn_ref($x1);
	return $sum * $delta / 3;
}

=head3 trapezoid rule

Usage:

    trapezoid(function_reference, start, end, steps=>30 );

Implements the trapezoid rule using 30 intervals between 'start' and 'end'.
The first three arguments are required.  The final argument (number of steps)
is optional and defaults to 30.

=cut

sub trapezoid {
	my ($fn_ref, $x0, $x1, %options) = @_;
	assign_option_aliases(\%options, intervals => 'steps',);
	set_default_options(\%options, steps => 30);
	my $steps = $options{steps};
	my $delta = ($x1 - $x0) / $steps;
	my $sum   = 0;

	for my $i (1 .. ($steps - 1)) {
		$sum += &$fn_ref($x0 + $i * $delta);
	}
	$sum += 0.5 * (&$fn_ref($x0) + &$fn_ref($x1));
	$sum * $delta;
}

=head3  Romberg method of integration

Usage:

    romberg(function_reference, x0, x1, level);

Implements the Romberg integration routine through 'level' recursive steps.  Level defaults to 6.

=cut

sub romberg {
	my ($fn_ref, $x0, $x1, %options) = @_;
	set_default_options(\%options, level => 6);
	my $level = $options{level};
	romberg_iter($fn_ref, $x0, $x1, $level, $level);
}

sub romberg_iter {
	my ($fn_ref, $x0, $x1, $j, $k) = @_;
	return $k == 1
		? trapezoid($fn_ref, $x0, $x1, steps => 2**($j - 1))
		: (4**($k - 1) * romberg_iter($fn_ref, $x0, $x1, $j, $k - 1) - romberg_iter($fn_ref, $x0, $x1, $j - 1, $k - 1))
		/ (4**($k - 1) - 1);
}

=head3 Inverse Romberg

Usage:

    inv_romberg(function_reference, a, value);

Finds b such that the integral of the function from a to b is equal to value.
Assumes that the function is continuous and doesn't take on the zero value.
Uses Newton's method of approximating roots of equations, and Romberg to evaluate definite integrals.

=head4 Example

Find the value of b such that the integral of e^(-x^2/2)/sqrt(2*pi) from 0 to b is 0.25.

    $f = sub { my $x = shift; return exp(-$x*$x/2)/sqrt(4*acos(0));};
    $b = inv_romberg($f,0,0.45);

this returns C<1.64485362695934>.   This is the standard normal curve and this
value is the z value for the 90th percentile.

=cut

sub inv_romberg {
	my ($fn_ref, $a, $value) = @_;
	my ($b, $delta, $i, $funct, $deriv) = ($a, 1, 0);

	while (abs($delta) > 0.000001 && $i++ < 5000) {
		$funct = romberg($fn_ref, $a, $b) - $value;
		$deriv = &$fn_ref($b);
		if ($deriv == 0) {
			warn 'Values of the function are too close to 0.';
			return;
		}
		$delta = $funct / $deriv;
		$b -= $delta;
	}
	if ($i == 5000) {
		warn 'Newtons method does not converge.';
		return;
	}
	return $b;
}

=head3 Newton Cotes functions.

Perform quadrature (numerical integration) using a newtonCotes composite formula (trapezoid,
Simpson's, the 3/8 rule or Boole's).

Usage:

    newtonCotes($f,$a,$b, n=> 4, method => 'simpson')

where C<$f> is a subroutine reference (function that takes a single numerical value and
returns a single value), C<$a> and C<$b> is the interval C<[$a,$b]>.

=head4 options

=over

=item method

The method options are either open or closed methods. The closed newton-cotes formula methods
are trapezoid, simpson, three-eighths, boole.  The open newton-cotes formula methods are
open1, open2, open3, open4, the number indicates the number of used nodes for the formula.

=item n

This number is the number of subintervals to use for a composite version of the formula.
If n is set to 1, then this uses the non-composite version of the method.

=back

=cut

sub newtonCotes {
	my ($f, $a, $b, @args) = @_;
	my %opts = (n => 10, method => 'simpson', @args);
	my $h    = ($b - $a) / $opts{n};
	my @weights;
	my @innernodes;

	if ($opts{method} eq 'trapezoid') {
		@weights    = (1 / 2, 1 / 2);
		@innernodes = (0, 1);
	} elsif ($opts{method} eq 'simpson') {
		@weights    = (1 / 6, 4 / 6, 1 / 6);
		@innernodes = (0, 0.5, 1);
	} elsif ($opts{method} eq 'three-eighths') {
		@weights    = (1 / 8, 3 / 8, 3 / 8, 1 / 8);
		@innernodes = (0, 1 / 3, 2 / 3, 1);
	} elsif ($opts{method} eq 'boole') {
		@weights    = (7 / 90, 32 / 90, 12 / 90, 32 / 90, 7 / 90);
		@innernodes = (0, 1 / 4, 1 / 2, 3 / 4, 1);
	} elsif ($opts{method} eq 'open1') {
		@weights    = (undef, 1);
		@innernodes = (undef, 0.5);
	} elsif ($opts{method} eq 'open2') {
		@weights    = (undef, 1 / 2, 1 / 2);
		@innernodes = (undef, 1 / 3, 2 / 3);
	} elsif ($opts{method} eq 'open3' || $opts{method} eq 'milne') {
		@weights    = (undef, 2 / 3, -1 / 3, 2 / 3);
		@innernodes = (undef, 1 / 4, 1 / 2,  3 / 4);
	} elsif ($opts{method} eq 'open4') {
		@weights    = (undef, 11 / 24, 1 / 24, 1 / 24, 11 / 24);
		@innernodes = (undef, 1 / 5,   2 / 5,  3 / 5,  4 / 5);
	}

	my $quad = 0;
	for my $i (0 .. $opts{n} - 1) {
		for my $k (0 .. $#innernodes) {
			$quad += &$f($a + ($i + $innernodes[$k]) * $h) * $weights[$k] if $weights[$k];
		}
	}
	return $h * $quad;
}

=head3 Legendre Polynomials

Returns a code reference to the Legendre Polynomial of degree C<n>.

Usage:

    $poly = legendreP($n)

And then evaluations can be found with C<&$poly(0.5)> for example to evaluate the polynomial at
C<x=5>. Even though this is a polynomial, the standard domain of these are [-1,1], although this
subroutine does not check for that.

=cut

# This uses the recurrence formula (n+1)P_{n+1}(x) = (2n+1)P_n(x) - n P_{n-1}(x), with  P_0 (x)=1 and P_1(x)=x.
# After testing, this is found to have less round off error than other formula.
sub legendreP {
	my ($n) = @_;
	return sub {
		my ($x) = @_;
		return 1  if $n == 0;
		return $x if $n == 1;
		my $P1 = legendreP($n - 1);
		my $P2 = legendreP($n - 2);
		return ((2 * $n - 1) * $x * &$P1($x) - ($n - 1) * &$P2($x)) / $n;
	};
}

=head3 derivative of Legendre Polynomials

Returns a code reference to the derivative of the Legendre polynomial of degree C<n>.

Usage:

    $dp = diffLegendreP($n)

If C<$dp = diffLegendreP(5)>, then C<&$dp(0.5)> will find the value of the derivative of the 5th degree
legendre polynomial at C<x=0.5>.

=cut

# This uses the recurrence relation P'_{n+1}(x) = (n+1)P_n(x)  + x P'_n(x). Like the subroutine
# legendreP, it was found that round off error is smaller for this method than others.
sub diffLegendreP {
	my ($n) = @_;
	return sub {
		my ($x) = @_;
		return 0 if $n == 0;
		my $P  = legendreP($n - 1);
		my $dP = diffLegendreP($n - 1);
		return $n * &$P($x) + $x * &$dP($x);
	};
}

=head3 Nodes and Weights of Legendre Polynomial

Finds the nodes (roots) and weights of the Legendre Polynomials of degree C<n>. These are used in
Gaussian Quadrature.

Usage:

    ($nodes, $weights) = legendreP_nodes_weights($n)

=cut

# this calculates the roots and weights of the Legendre polynomial of degree n.  The roots
# can be determined exactly for n<=9, due to symmetry, however, this uses newton's method
# to solve them based on an approximate value
# (see https://math.stackexchange.com/questions/12160/roots-of-legendre-polynomial )
#
# the weights can then be calculated based on a formula shown in
# https://en.wikipedia.org/wiki/Gaussian_quadrature
sub legendreP_nodes_weights {
	my ($n) = @_;

	my $leg  = legendreP($n);
	my $dleg = diffLegendreP($n);
	my $pi   = 4 * atan(1.0);

	my @nodes;
	my @weights;
	my $m;
	# If $n is odd, then there is a node at x=0.
	if ($n % 2 == 1) {
		push(@nodes,   0);
		push(@weights, 2 / &$dleg(0)**2);
		$m = ($n + 1) / 2 + 1;
	} else {
		$m = $n / 2 + 1;
	}
	# Compute only nodes for half of the nodes and use symmetry to fill in the rest.
	for my $k ($m .. $n) {
		my $node = newton(
			$leg, $dleg,
			(1 - 1 / (8 * $n**2) + 1 / (8 * $n**3)) * cos($pi * (4 * $k - 1) / (4 * $n + 2)),
			feps => 1e-14
		)->{root};
		my $w = 2 / ((1 - $node**2) * &$dleg($node)**2);
		unshift(@nodes, $node);
		push(@nodes, -$node);

		unshift(@weights, $w);
		push(@weights, $w);
	}
	return (\@nodes, \@weights);
}

=head3 Gaussian Quadrature

Compute the integral of a function C<$f> on an interval C<[a,b]> using Gassian
Quadrature.

Usage:

     gauss_quad($f,n=>5, a => -1, b => 1, weights => $w, nodes => $nodes)

where C<$f> is a code reference to a function from R => R, C<a> and C<b> are the endpoints of the
interval, C<n> is the number of nodes to use.  The weights and nodes will depend on the value of
C<n>.

If C<weights> or C<nodes> are included, they must both be used and will override the C<n> option.
These will not be checked and assumed to be correct.  These should be used for performance
in that calculating the weights and nodes have some computational time.

=cut

sub gauss_quad {
	my ($f, %opts) = @_;
	# defines default values.
	%opts = (n => 5, a => -1, b => 1, %opts);
	die 'The optional value n must be an integer >=2' unless $opts{n} =~ /\d+/ && $opts{n} >= 2;
	die 'The optional value a must be a number'       unless $opts{a} =~ /[+-]?\d*\.?\d+/;
	die 'The optional value b must be a number'       unless $opts{b} =~ /[+-]?\d*\.?\d+/;
	die 'The optional value b must be greater than a' unless $opts{b} > $opts{a};
	die 'The argument f must be a code ref'           unless ref($f) eq 'CODE';

	my ($x, $w) = ($opts{nodes}, $opts{weights});
	if ((!defined($w) && !defined($x))) {
		($x, $w) = legendreP_nodes_weights($opts{n});
	} elsif (!defined($w) || !defined($w)) {
		die 'If either option "weights" or "nodes" is used, both must be used.';
	}
	die 'The options weights and nodes must be array refs of the same length'
		unless ref $w eq 'ARRAY' && ref $x eq 'ARRAY' && scalar($x) == scalar($x);

	my $sum = 0;
	$sum += $w->[$_] * &$f(0.5 * ($opts{b} + $opts{a}) + 0.5 * ($opts{b} - $opts{a}) * $x->[$_])
		for (0 .. scalar(@$w) - 1);
	return 0.5 * ($opts{b} - $opts{a}) * $sum;
}

=head2 Differential Equation Methods

=head3 4th-order Runge-Kutta

Finds integral curve of a vector field using the 4th order Runge Kutta method by
providing the function C<rungeKutta4>

Usage:

    rungeKutta4( &vectorField(t,x),%options);

    Returns:  \@array of points [t,y]

    Default %options:
        'initial_t'       =>1,
        'initial_y'       => 1,
        'dt'              =>  .01,
        'num_of_points'   =>  10,     #number of reported points
        'interior_points' =>  5,      # number of 'interior' steps between reported points
        'debug'

=cut

sub rungeKutta4 {
	my $rf_fun  = shift;
	my %options = @_;
	set_default_options(
		\%options,
		'initial_t'       => 1,
		'initial_y'       => 1,
		'dt'              => .01,
		'num_of_points'   => 10,    #number of reported points
		'interior_points' => 5,     # number of 'interior' steps between reported points
		'debug'           => 1,     # remind programmers to always pass the debug parameter
	);
	my $t = $options{initial_t};
	my $y = $options{initial_y};

	my $num    = $options{'num_of_points'};      # number of points
	my $num2   = $options{'interior_points'};    # number of steps between points.
	my $dt     = $options{'dt'};
	my $errors = undef;
	my $rf_rhs = sub {
		my @in = @_;
		my ($out, $err) = &$rf_fun(@in);
		$errors .= " $err at ( " . join(" , ", @in) . " )<br>\n"
			if defined($err);
		$out = 'NaN' if defined($err) and not is_a_number($out);
		$out;
	};

	my @output = ([ $t, $y ]);
	for my $j (0 .. $num - 1) {
		for my $i (0 .. $num2 - 1) {
			my $K1 = $dt * &$rf_rhs($t,           $y);
			my $K2 = $dt * &$rf_rhs($t + $dt / 2, $y + $K1 / 2);
			my $K3 = $dt * &$rf_rhs($t + $dt / 2, $y + $K2 / 2);
			my $K4 = $dt * &$rf_rhs($t + $dt,     $y + $K3);
			$y += ($K1 + 2 * $K2 + 2 * $K3 + $K4) / 6;
			$t += $dt;
		}
		push(@output, [ $t, $y ]);
	}
	if (defined $errors) {
		return $errors;
	} else {
		return \@output;
	}
}

=head3 Robust Differential Equation Solver

Produces a numerical solution to the differential equation y'=f(x,y) with the
function C<solveDiffEqn>.

=head4 Arguments

=over

=item * C<f> an subroutine reference that take two inputs (x,y) and returns
a single number. Note: if you use a Formula to generate a function, create a perl
function with the C<<$f->perlFunction>> method.

=item * C<y0> a real-values number for the initial point

=back

=head4 Options

=over

=item * C<x0> the initial x value (defaults to 0)

=item * C<h> the stepsize of the numerical method (defaults to 0.25)

=item * C<n> the number of steps to perform (defaults to 4)

=item * C<method> one of 'euler', 'improved_euler', 'heun' or 'rk4' (defaults to euler)

=back

=head4 Output

An hash with the following fields:

=over

=item *  C<x> an array ref of the x values which are C<x0 + i*h for i=0..n>

=item *  C<y> an array ref of the y values (depending on the method used)

=item *  C<k1, k2, k3, k4> the intermediate function values used (depending on the method).

=back

=head4 Examples

The following performs Euler's method on C<y'=xy, y(0) = 1> using C<h=0.5> for C<n=10> points, so
the last x value is 5.

    $f = sub { my ($x, $y) = @_; return $x*$y; }
    $sol1 = solveDiffEqn($f,1,x0=>0,h=>0.5,n=>10, method => 'euler');

The output C<$sol> is a hash ref with fields x and y, where each have 11 points.

The following uses the improved Euler method on C<y'=x^2+y^2, y(0)=1> using C<h=0.2> for C<n=5> points
(the last x value is 1.0).  Note, this shows how to pass the perl function to the method.

    Context()->variables->add(y => 'Real');
    $G = Formula("x^2+y^2");
    $g = $G->perlFunction;
    $sol2 = solveDiffEqn($g, 1, method => 'improved_euler', x0=>0, h=>0.2,n=>5);

In this case, C<$sol2> returns both x and y, but also, the values of C<k1> and C<k2>.

=cut

sub solveDiffEqn {
	my ($f, $y0, @args) = @_;
	my %opts = (x0 => 0, h => 0.25, n => 4, method => 'euler', @args);

	die 'The first argument must be a subroutine reference' unless ref($f) eq 'CODE';
	die 'The option n must be a positive integer'           unless $opts{n} =~ /^\d+$/;
	die 'The option h must be a positive number'            unless $opts{h} > 0;
	die 'The option method must be one of euler/improved_euler/heun/rk4'
		unless grep { $opts{method} eq $_ } qw/euler improved_euler heun rk4/;

	my $x0 = $opts{x0};
	my $h  = $opts{h};
	my @y  = ($y0);
	my @k1;
	my @k2;
	my @k3;
	my @k4;
	my @x = map { $x0 + $_ * $h } (0 .. $opts{n});

	for my $j (1 .. $opts{n}) {
		if ($opts{method} eq 'euler') {
			$y[$j] = $y[ $j - 1 ] + $h * &$f($x[ $j - 1 ], $y[ $j - 1 ]);
		} elsif ($opts{method} eq 'improved_euler') {
			$k1[$j] = &$f($x[ $j - 1 ], $y[ $j - 1 ]);
			$k2[$j] = &$f($x[$j],       $y[ $j - 1 ] + $h * $k1[$j]);
			$y[$j]  = $y[ $j - 1 ] + 0.5 * $h * ($k1[$j] + $k2[$j]);
		} elsif ($opts{method} eq 'heun') {
			$k1[$j] = &$f($x[ $j - 1 ],              $y[ $j - 1 ]);
			$k2[$j] = &$f($x[ $j - 1 ] + 2 * $h / 3, $y[ $j - 1 ] + 2 * $h / 3 * $k1[$j]);
			$y[$j]  = $y[ $j - 1 ] + 0.25 * $h * ($k1[$j] + 3 * $k2[$j]);
		} elsif ($opts{method} eq 'rk4') {
			$k1[$j] = &$f($x[ $j - 1 ],            $y[ $j - 1 ]);
			$k2[$j] = &$f($x[ $j - 1 ] + 0.5 * $h, $y[ $j - 1 ] + $h * 0.5 * $k1[$j]);
			$k3[$j] = &$f($x[ $j - 1 ] + 0.5 * $h, $y[ $j - 1 ] + $h * 0.5 * $k2[$j]);
			$k4[$j] = &$f($x[$j],                  $y[ $j - 1 ] + $h * $k3[$j]);
			$y[$j]  = $y[ $j - 1 ] + $h / 6 * ($k1[$j] + 2 * $k2[$j] + 2 * $k3[$j] + $k4[$j]);
		}
	}
	if ($opts{method} eq 'euler') {
		return { y => \@y, x => \@x };
	} elsif ($opts{method} eq 'improved_euler' || $opts{method} eq 'heun') {
		return { k1 => \@k1, k2 => \@k2, y => \@y, x => \@x };
	} elsif ($opts{method} eq 'rk4') {
		return {
			k1 => \@k1,
			k2 => \@k2,
			k3 => \@k3,
			k4 => \@k4,
			y  => \@y,
			x  => \@x
		};
	}
}

=head2 Rootfinding

=head3 bisection

Performs the bisection method for the function C<$f> and initial interval C<$int> (arrayref).
An example is

  $f = sub { $x = shift; $x**2-2;}
  $bisect = bisection($f, [1, 2]);

The result is a hash with fields root (the estimated root), intervals (an array ref or
intervals for each step of bisection) or a hash with field C<error> if there is an
error with either the inputs or from the method.

=head4 Arguments

=over

=item * C<f>, a reference to a subroutine with a single input number and single output
value.

=item * C<int>, an array ref of the interval C<[a,b]> where a < b.

=back

=head4 Options

=over

=item * C<eps>, the maximum error of the root or stopping condition.  Default is C<1e-6>

=item * C<max_iter>, the maximum number of iterations to run the bisection method. Default is C<40>.

=back

=head4 Output

A hash with the following fields

=over

=item * C<root>, the approximate root using bisection.

=item * C<interval>, an arrayref of the intervals (each interval also an array ref)

=item * C<error>, a string specifying the error (either argument argument error or too many steps)

=back

=cut

sub bisection {
	my ($f, $int, @args) = @_;
	my %opts = (eps => 1e-6, max_iter => 40, @args);

	# Check that the arguments/options are valid.
	return { error => 'The function must be a code reference' } unless ref($f) eq 'CODE';

	return { error => 'The interval must be an array ref of length 2' }
		unless ref($int) eq 'ARRAY' && scalar(@$int) == 2;

	return { error => 'The initial interval [a, b] must satisfy a < b' } unless $int->[0] < $int->[1];

	return { error => 'The function may not have a root on the given interval' }
		unless &$f($int->[0]) * &$f($int->[1]) < 0;

	return { error => 'The option eps must be a positive number' } unless $opts{eps} > 0;

	return { error => 'The option max_iter must be a positive integer' }
		unless $opts{max_iter} > 0 && int($opts{max_iter}) == $opts{max_iter};

	# stores the intervals for each step
	my $ints = [$int];
	my $i    = 0;
	do {
		my $mid  = 0.5 * ($ints->[$i][0] + $ints->[$i][1]);
		my $fmid = &$f($mid);
		push(@$ints, $fmid * &$f($ints->[$i][0]) < 0 ? [ $ints->[$i][0], $mid ] : [ $mid, $ints->[$i][1] ]);
		$i++;
	} while ($i < $opts{max_iter}
			&& ($ints->[$i][1] - $ints->[$i][0]) > $opts{eps});

	if ($i == $opts{max_iter}) {
		return { error => "You have reached the maximum number of iterations: $opts{max_iter} without "
				. 'reaching a root.' };
	}

	return {
		root      => 0.5 * ($ints->[$i][0] + $ints->[$i][1]),
		intervals => $ints
	};
}

=head3 newton

Performs newton's method for the function C<$f> and initial point C<$x0>.
An example is

  $f = sub { my $x = shift; return $x**2-2; }
	$df = sub { my $x = shift; return 2*$x; }
  $newton = newton($f, $df, 1);

The result is a hash with fields C<root> (the estimated root) and C<intervals> (an arrayref
of the iterations with the first being C<$x0>. The result hash will contain the field C<error>
if there is an error.

=head4 Arguments

=over

=item * C<f>, a reference to a subroutine with a single input number and single output
value.

=item * C<df>, a subroutine reference that is the derivative of f.

=item * C<x0>, a perl number or math object number.

=back

=head4 Options

=over

=item * C<max_iter>, the maximum number of iterations to run Newton's method. Default is C<15>.

=item * C<eps>, the cutoff value in the C<x> direction or stopping condition.
The default is C<1e-8>

=item * C<feps>, the allowed functional value for the stopping condition.  The default
value is C<1e-10>.

=back

=head4 Output

A hash with the following fields

=over

=item * C<root>, the approximate root.

=item * C<iterations>, an arrayref of the iterations.

=item * C<error>, a string specifying the error (either argument argument error or too many steps)

=back


=cut

sub newton {
	my ($f, $df, $x0, @args) = @_;
	my %opts = (eps => 1e-8, feps => 1e-10, max_iter => 15, @args);

	# Check that the arguments/options are valid.
	return { error => 'The function must be a code reference' } unless ref($f) eq 'CODE';

	return { error => 'The option eps must be a positive number' }
		unless $opts{eps} > 0;

	return { error => 'The option feps must be a positive number' }
		unless $opts{feps} > 0;

	return { error => 'The option max_iter must be a positive integer' }
		unless $opts{max_iter} > 0;

	my @iter = ($x0);
	my $i    = 0;
	do {
		$iter[ $i + 1 ] = $iter[$i] - &$f($iter[$i]) / &$df($iter[$i]);
		$i++;
		return { error => "Newton's method did not converge in $opts{max_iter} steps" }
			if $i > $opts{max_iter};
	} while abs($iter[$i] - $iter[ $i - 1 ]) > $opts{eps} || &$f($iter[$i]) > $opts{feps};

	return { root => $iter[$i], iterations => \@iter };
}

=head3 secant

Performs the secant method for finding a root of the function C<$f> with initial points C<$x0> and C<$x1>
An example is

  $f = sub { my $x = shift; return $x**2-2; }
  $secant = secant($f,1,2);

The result is a hash with fields C<root> (the estimated root) and C<intervals> (an arrayref
of the iterations with the first two being C<$x0> and C<$x1>. The result hash will contain
the field C<error> if there is an error.

=head4 Arguments

=over

=item * C<f>, a reference to a subroutine with a single input number and single output
value.

=item * C<x0>, a number.

=item * C<x1>, a number.

=back

=head4 Options

=over

=item * C<max_iter>, the maximum number of iterations to run the Secant method. Default is C<20>.

=item * C<eps>, the cutoff value in the C<x> direction or stopping condition.
The default is C<1e-8>

=item * C<feps>, the allowed functional value for the stopping condition.  The default
value is C<1e-10>.

=back

=head4 Output

A hash with the following fields

=over

=item * C<root>, the approximate root.

=item * C<iterations>, an arrayref of the iterations.

=item * C<error>, a string specifying the error (either argument argument error or too many steps)

=back


=cut

sub secant {
	my ($f, $x0, $x1, @args) = @_;
	my %opts = (eps => 1e-8, feps => 1e-10, max_iter => 20, @args);

	# Check that the arguments/options are valid.
	return { error => 'The function must be a code reference' } unless ref($f) eq 'CODE';

	return { error => 'The option eps must be a positive number' }
		unless $opts{eps} > 0;

	return { error => 'The option feps must be a positive number' }
		unless $opts{feps} > 0;

	return { error => 'The option max_iter must be a positive integer' }
		unless $opts{max_iter} > 0;

	my @iter = ($x0, $x1);
	my $i    = 1;
	do {
		my $m = (&$f($iter[$i]) - &$f($iter[ $i - 1 ])) / ($iter[$i] - $iter[ $i - 1 ]);
		$iter[ $i + 1 ] = $iter[$i] - &$f($iter[$i]) / $m;
		$i++;
		return { error => "The secant method did not converge in $opts{max_iter} steps" }
			if $i > $opts{max_iter};

	} while abs($iter[$i] - $iter[ $i - 1 ]) > $opts{eps};

	return { root => $iter[$i], iterations => \@iter };
}

1;

