################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2024 The WeBWorK Project, https://github.com/openwebwork
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

BEGIN { strict->import; }

sub _PGnumericalmacros_init { }

=head2 Interpolation methods

=head3 plot_list

Usage:

    plot_list([x0,y0,x1,y1,...]);
    plot_list([(x0,y0),(x1,y1),...]);
    plot_list(\x_y_array);

    plot_list([x0,x1,x2...], [y0,y1,y2,...]);
    plot_list(\@xarray,\@yarray);

It is important that the x values in any form are unique or this method fails.  There is no
check for this however.
=cut

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
		die "ERROR in plot_list -- single array of input has odd number of elements" if (@$xref % 2 == 1);

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
		my ($y, $x0, $x1, $y0, $y1);
		my @x_values = @$xref;
		my @y_values = @$yref;
		while ((@x_values and $x > $x_values[0]) || (@x_values > 0 and $x >= $x_values[0])) {
			$x0 = shift(@x_values);
			$y0 = shift(@y_values);
		}
		# Now that we have the left hand of the input, check first that x isn't out of range to the left or right
		if (@x_values && defined($x0)) {
			$x1 = shift(@x_values);
			$y1 = shift(@y_values);
			$y  = $y0 + ($y1 - $y0) * ($x - $x0) / ($x1 - $x0);
		}
		return $y;
	};
}

=head3 horner

Usage:

    $fn = horner([x0,x1,x2, ...],[q0,q1,q2, ...]);

Produces the newton polynomial

    &$fn(x) = q0 + q1*(x-x0) +q2*(x-x1)*(x-x0) + ...;

Generates a subroutine which evaluates a polynomial passing through the points
C<(x0,q0), (x1,q1), (x2, q2)>, ... using Horner's method.

The array refs for C<x> and C<q> can be any length but must be the same length.

Example

    $h = horner([0,1,2],[1,-1,2]);

Then C<&$h(num)> returns the polynomial at the value C<num>.  For example,
C<&$h(1.5)=1>.

=cut

sub horner {
	my ($xref, $qref) = @_;    # get the coefficients
	die 'The x inputs and q inputs must be the same length' unless scalar(@$xref) == scalar(@$qref);
	return sub {
		my $x     = shift;
		my @xvals = @$xref;
		my @qvals = @$qref;
		my $y     = pop(@qvals);
		pop(@xvals);
		while (@qvals) {
			$y = $y * ($x - pop(@xvals)) + pop(@qvals);
		}
		return $y;
	};
}

=head3 hermite

Usage:

    $poly = hermite([x0,x1...],[y0,y1...],[yp0,yp1,...]);

Produces a reference to polynomial function with the specified values and first derivatives
at (x0,x1,...). C<&$poly(34)> gives a number

Generates a subroutine which evaluates a polynomial passing through the specified points
with the specified derivatives: (x0,y0,yp0) ...
The polynomial will be of high degree and may wobble unexpectedly.  Use the Hermite splines
described below and in Hermite.pm for  most graphing purposes.

Example

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

=head3 hermite_spline

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

		# Handle left most endpoint
		return $y = &{ $fns[0] }($x) if $x == $xvals[0];

		# Find the function for this range of x
		while (@xvals && $x > $xvals[0]) {
			shift(@xvals);
			$fun = shift(@fns);
		}

		# Now that we have the left hand of the input, check first that x isn't out of range to the left or right.
		if (@xvals && defined($fun)) {
			$y = &$fun($x);
		}
		return $y;
	};
}

=head3 cubic_spline

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
	} else {
		# The input value is not in the range defined by the function.
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
	my ($x_ref, $y_ref, %options) = @_;
	assign_option_aliases(
		\%options,

	);
	set_default_options(
		\%options,
		name   => 'func',
		llimit => $x_ref->[0],
		rlimit => $x_ref->[-1],
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

	return $output_str;
}

=head2 Numerical Integration methods

=head3 lefthandsum

Left Hand Riemann Sum

Usage:

    lefthandsum(function_reference, start, end, steps=>30 );

Implements the Left Hand sum using 30 intervals between 'start' and 'end'.
The first three arguments are required.  The final argument (number of steps) is
optional and defaults to 30.

=cut

sub lefthandsum {
	my ($fn_ref, $x0, $x1, %options) = @_;
	assign_option_aliases(\%options, intervals => 'steps');
	set_default_options(\%options, steps => 30);
	my $steps = $options{steps};
	my $delta = ($x1 - $x0) / $steps;
	my $sum   = 0;

	for my $i (0 .. ($steps - 1)) {
		$sum += &$fn_ref($x0 + $i * $delta);
	}
	return $sum * $delta;
}

=head3 righthandsum

Right Hand Riemann Sum

Usage:

    righthandsum(function_reference, start, end, steps=>30 );

Implements the right hand sum using 30 intervals between 'start' and 'end'.
The first three arguments are required.  The final argument (number of steps)
is optional and defaults to 30.

=cut

sub righthandsum {
	my ($fn_ref, $x0, $x1, %options) = @_;
	assign_option_aliases(\%options, intervals => 'steps');
	set_default_options(\%options, steps => 30);
	my $steps = $options{steps};
	my $delta = ($x1 - $x0) / $steps;
	my $sum   = 0;

	for my $i (1 .. $steps) {
		$sum += &$fn_ref($x0 + $i * $delta);
	}
	return $sum * $delta;
}

=head3 midpoint

Usage:

    midpoint(function_reference, start, end, steps=>30);

Implements the Midpoint rule between 'start' and 'end'.
The first three arguments are required.  The final argument (number of steps)
is optional and defaults to 30.

=cut

sub midpoint {
	my ($fn_ref, $x0, $x1, %options) = @_;
	assign_option_aliases(\%options, intervals => 'steps');
	set_default_options(\%options, steps => 30);
	my $steps = $options{steps};
	my $delta = ($x1 - $x0) / $steps;
	my $sum   = 0;

	for my $i (0 .. ($steps - 1)) {
		$sum += &$fn_ref($x0 + ($i + 1 / 2) * $delta);
	}
	return $sum * $delta;
}

=head3 simpson

Usage:

    simpson(function_reference, start, end, steps=>30 );

Implements Simpson's rule between 'start' and 'end'.
The first three arguments are required.  The final argument (number of steps) is
optional and defaults to 30, but must be even.

=cut

sub simpson {
	my ($fn_ref, $x0, $x1, %options) = @_;
	assign_option_aliases(\%options, intervals => 'steps');
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

=head3 trapezoid

Usage:

    trapezoid(function_reference, start, end, steps=>30);

Implements the trapezoid rule using 30 intervals between 'start' and 'end'.
The first three arguments are required.  The final argument (number of steps)
is optional and defaults to 30.

=cut

sub trapezoid {
	my ($fn_ref, $x0, $x1, %options) = @_;
	assign_option_aliases(\%options, intervals => 'steps');
	set_default_options(\%options, steps => 30);
	my $steps = $options{steps};
	my $delta = ($x1 - $x0) / $steps;
	my $sum   = 0;

	for my $i (1 .. ($steps - 1)) {
		$sum += &$fn_ref($x0 + $i * $delta);
	}
	$sum += 0.5 * (&$fn_ref($x0) + &$fn_ref($x1));
	return $sum * $delta;
}

=head3 romberg

Usage:

    romberg(function_reference, x0, x1, level);

Implements the Romberg integration routine through 'level' recursive steps.  Level defaults to 6.

=cut

sub romberg {
	my ($fn_ref, $x0, $x1, %options) = @_;
	set_default_options(\%options, level => 6);
	return romberg_iter($fn_ref, $x0, $x1, $options{level}, $options{level});
}

sub romberg_iter {
	my ($fn_ref, $x0, $x1, $j, $k) = @_;
	return $k == 1
		? trapezoid($fn_ref, $x0, $x1, steps => 2**($j - 1))
		: (4**($k - 1) * romberg_iter($fn_ref, $x0, $x1, $j, $k - 1) - romberg_iter($fn_ref, $x0, $x1, $j - 1, $k - 1))
		/ (4**($k - 1) - 1);
}

=head3 inv_romberg

Inverse Romberg

Usage:

    inv_romberg(function_reference, a, value);

Finds b such that the integral of the function from a to b is equal to value.
Assumes that the function is continuous and doesn't take on the zero value.
Uses Newton's method of approximating roots of equations, and Romberg to evaluate definite integrals.

Example

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

=head2 Differential Equation Methods

=head3 rungeKutta4

Finds integral curve of a vector field using the 4th order Runge Kutta method by
providing the function C<rungeKutta4>

Usage:

    rungeKutta4( &vectorField(t,x),%options);

Returns:  array ref of points [t,y]

    Default %options:
        'initial_t'       => 1,
        'initial_y'       => 1,
        'dt'              => 0.01,
        'num_of_points'   => 10,     # number of reported points
        'interior_points' => 5,      # number of 'interior' steps between reported points
        'debug'

=cut

sub rungeKutta4 {
	my ($rf_fun, %options) = @_;
	set_default_options(
		\%options,
		'initial_t'       => 1,
		'initial_y'       => 1,
		'dt'              => .01,
		'num_of_points'   => 10,    # number of reported points
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
		$errors .= " $err at ( " . join(" , ", @in) . " )<br>\n" if defined($err);
		$out = 'NaN'                                             if defined($err) and not is_a_number($out);
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

1;
