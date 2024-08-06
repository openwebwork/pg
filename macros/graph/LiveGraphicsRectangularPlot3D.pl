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

LiveGraphicsRectangularPlot3D.pl - provide an interactive 3D rectangular plot.

=head1 DESCRIPTION

This macro provides two methods for creating an interactive plot of a function
of two variables C<z = f(x, y)> in rectangular (Cartesian) coordinates via the
C<LiveGraphics3D> JavaScript applet.  The routine
L</RectangularPlot3DRectangularDomain> takes a C<MathObject> Formula of two
variables defined over a rectangular domain and some plot options as input and
returns a string of plot data that can be displayed using the C<Live3Ddata>
routine of the L<LiveGraphics3D.pl> macro.  The routine
L</RectangularPlot3DAnnularDomain> works similarly for a function C<z = f(x, y)>
over an annular domain specified in polar coordinates by C<< rmin < r < rmax >>
and C<< tmin < theta < tmax >> (polar coordinates are converted to rectangular
for evaluation of the function).

=head1 METHODS

=head2 RectangularPlot3DRectangularDomain

Usage: C<RectangularPlot3DRectangularDomain(%options)>

The available options are as follows.

=over

=item C<< function => $f >>

C<$f> is a MathObject Formula. For example, in the setup section define

    Context()->variables->are(x => 'Real', y => 'Real');
    $a = random(1, 3);
    $f = Formula("$a * x^2 - 2 * y");    # Use double quotes!

before calling C<RectangularPlot3DRectangularDomain>.

=item C<< xvar => 'x' >>

First independent variable name, default 'x'. This must correspond to the first
variable used in the C<function>.

=item C<< yvar => 'y' >>

Second independent variable name, default 'y'. This must correspond to the
second variable used in the C<function>.

=item C<< xmin => -3 >>

Lower bound for the domain of the first independent variable.

=item C<< xmax => 3 >>

Upper bound for the domain of the first independent variable.

=item C<< ymin => -3 >>

Lower bound for the domain of the second independent variable.

=item C<< ymax => 3 >>

Upper bound for the domain of the second independent variable.

=item C<< xsamples => 20 >>

The number of sample values for the first independent variable in the interval
from C<xmin> to C<xmax> to use.

=item C<< ysamples => 20 >>

The number of sample values for the second independent variable in the interval
from C<ymin> to C<ymax> to use.

=item C<< axesframed => 1 >>

If set to 1 then the framed axes are displayed.  If set to 0, the the framed
axes are not shown. This is 1 by default.

=item C<< xaxislabel => 'x' >>

Label for the axis corresponding to the first independent variable.

=item C<< yaxislabel => 'y' >>

Label for the axis corresponding to the second independent variable.

=item C<< zaxislabel => 'z' >>

Label for the axis corresponding to the dependent variable.

=item C<< outputtype => 1 >>

This determines what is contained in the string that the method returns. The
values of 1 through 4 are accepted, and have the following meaning.

=over

=item 1.

Return a string of only polygons (or edge mesh).

=item 2.

Return a string of only plot options.

=item 3.

Return a string of polygons (or edge mesh) and plot options.

=item 4.

Return the complete plot to be passed directly to the C<Live3DData> method.

=back

=back

=head2 RectangularPlot3DAnnularDomain

Usage: C<RectangularPlot3DAnnularDomain(%options)>

The available options are as follows.

=over

=item C<< function => $f >>

C<$f> is a MathObject Formula. For example, in the setup section define

    Context()->variables->are(x => 'Real', y => 'Real');
    $a = random(1, 3);
    $f = Formula("$a * e^(-x^2 - y^2)");    # Use double quotes!

before calling C<RectangularPlot3DRectangularDomain>.

=item C<< xvar => 'x' >>

First independent variable name, default 'x'. This must correspond to the first
variable used in the C<function>.

=item C<< yvar => 'y' >>

Second independent variable name, default 'y'. This must correspond to the
second variable used in the C<function>.

=item C<< rmin => -3 >>

Lower bound for the domain of radial coordinate.

=item C<< rmax => 3 >>

Upper bound for the domain of radial coordinate.

=item C<< tmin => -3 >>

Lower bound for the domain of angular coordinate.

=item C<< tmax => 3 >>

Upper bound for the domain of angular coordinate.

=item C<< rsamples => 20 >>

The number of radial values in the interval from C<rmin> to C<rmax> to use.

=item C<< tsamples => 20 >>

The number of angular values in the interval from C<tmin> to C<tmax> to use.

=item C<< axesframed => 1 >>

If set to 1 then the frames axes are displayed.  If set to 0, the the framed
axes are not shown. This is 1 by default.

=item C<< xaxislabel => 'x' >>

Label for the axis corresponding to the first independent variable.

=item C<< yaxislabel => 'y' >>

Label for the axis corresponding to the second independent variable.

=item C<< zaxislabel => 'z' >>

Label for the axis corresponding to the dependent variable.

=item C<< outputtype => 1 >>

This determines what is contained in the string that the method returns. The
values of 1 through 4 are accepted, and have the following meaning.

=over

=item 1.

Return a string of only polygons (or edge mesh).

=item 2.

Return a string of only plot options.

=item 3.

Return a string of polygons (or edge mesh) and plot options.

=item 4.

Return the complete plot to be passed directly to the C<Live3DData> method.

=back

=back

=cut

sub _LiveGraphicsRectangularPlot3D_init { };    # don't reload this file

loadMacros('MathObjects.pl', 'LiveGraphics3D.pl');

$main::beginplot = 'Graphics3D[';
$main::endplot   = ']';

sub RectangularPlot3DRectangularDomain {
	# Set default options
	my %options = (
		function   => Formula('1'),
		xvar       => 'x',
		yvar       => 'y',
		xmin       => -3,
		xmax       => 3,
		ymin       => -3,
		ymax       => 3,
		xsamples   => 20,
		ysamples   => 20,
		axesframed => 1,
		xaxislabel => 'x',
		yaxislabel => 'y',
		zaxislabel => 'z',
		outputtype => 4,
		@_
	);

	$options{function}->perlFunction('fsubroutine', [ $options{xvar}, $options{yvar} ]);

	# Generate a plotdata array, which has two indices.

	my $dx = ($options{xmax} - $options{xmin}) / $options{xsamples};
	my $dy = ($options{ymax} - $options{ymin}) / $options{ysamples};

	my (@x, @y, @z);

	for my $i (0 .. $options{xsamples}) {
		$x[$i] = $options{xmin} + $i * $dx;
		for my $j (0 .. $options{ysamples}) {
			$y[$j]     = $options{ymin} + $j * $dy;
			$z[$i][$j] = sprintf('%.3f', fsubroutine($x[$i], $y[$j])->value);
			$y[$j]     = sprintf('%.3f', $y[$j]);
		}
		$x[$i] = sprintf('%.3f', $x[$i]);
	}

	# Generate a plotstring from the plotdata. This is a list of polygons LiveGraphics3D reads as input.
	# For more information on the format of the plotstring, see
	# http://www.math.umn.edu/~rogness/lg3d/page_NoMathematica.html.

	# Generate the polygons in the plotstring.
	my @polygons;
	for my $i (0 .. $options{xsamples} - 1) {
		for my $j (0 .. $options{ysamples} - 1) {
			push(@polygons,
				'Polygon[{'
					. "{$x[$i],$y[$j],$z[$i][$j]},"
					. "{$x[$i+1],$y[$j],$z[$i+1][$j]},"
					. "{$x[$i+1],$y[$j+1],$z[$i+1][$j+1]},"
					. "{$x[$i],$y[$j+1],$z[$i][$j+1]}"
					. '}]');
		}
	}
	my $plotstructure = '{' . join(',', @polygons) . '}';

	my $plotoptions =
		$options{outputtype} > 1 && $options{axesframed} == 1
		? "Axes->True,AxesLabel->{$options{xaxislabel},$options{yaxislabel},$options{zaxislabel}}"
		: '';

	if ($options{outputtype} == 1) {
		return $plotstructure;
	} elsif ($options{outputtype} == 2) {
		return $plotoptions;
	} elsif ($options{outputtype} == 3) {
		return "{$plotstructure,$plotoptions}";
	} elsif ($options{outputtype} == 4) {
		return "${main::beginplot}${plotstructure},${plotoptions}${main::endplot}";
	} else {
		return 'Invalid outputtype (outputtype should be a number 1 through 4).';
	}

}

sub RectangularPlot3DAnnularDomain {
	# Set default options.
	my %options = (
		function   => Formula('1'),
		xvar       => 'x',
		yvar       => 'y',
		rmin       => 0.001,
		rmax       => 3,
		tmin       => 0,
		tmax       => 6.28,
		rsamples   => 20,
		tsamples   => 20,
		axesframed => 1,
		xaxislabel => 'x',
		yaxislabel => 'y',
		zaxislabel => 'z',
		outputtype => 4,
		@_
	);

	$options{function}->perlFunction('fsubroutine', [ $options{xvar}, $options{yvar} ]);

	# Generate a plotdata array which has two indices.

	my ($rsamples1, $tsamples1) = ($options{rsamples} - 1, $options{tsamples} - 1);

	my $dr = ($options{rmax} - $options{rmin}) / $options{rsamples};
	my $dt = ($options{tmax} - $options{tmin}) / $options{tsamples};

	my (@x, @y, @z);

	for my $i (0 .. $options{tsamples}) {
		my $t = $options{tmin} + $i * $dt;
		for my $j (0 .. $options{rsamples}) {
			my $r = $options{rmin} + $j * $dr;
			$x[$i][$j] = $r * cos($t);
			$y[$i][$j] = $r * sin($t);
			$z[$i][$j] = sprintf('%.3f', fsubroutine($x[$i][$j], $y[$i][$j])->value);
			$x[$i][$j] = sprintf('%.3f', $x[$i][$j]);
			$y[$i][$j] = sprintf('%.3f', $y[$i][$j]);
		}
	}

	# Generate a plotstring from the plotdata.  This is a list of polygons that LiveGraphics3D reads as input.
	# For more information on the format of the plotstring, see
	# http://www.math.umn.edu/~rogness/lg3d/page_NoMathematica.html.

	# Generate the polygons in the plotstring.
	my @polygons;
	for my $i (0 .. $tsamples1) {
		for my $j (0 .. $rsamples1) {
			push(@polygons,
				'Polygon[{'
					. "{$x[$i][$j],$y[$i][$j],$z[$i][$j]},"
					. "{$x[$i+1][$j],$y[$i+1][$j],$z[$i+1][$j]},"
					. "{$x[$i+1][$j+1],$y[$i+1][$j+1],$z[$i+1][$j+1]},"
					. "{$x[$i][$j+1],$y[$i][$j+1],$z[$i][$j+1]}"
					. '}]');
		}
	}
	my $plotstructure = '{' . join(',', @polygons) . '}';

	my $plotoptions =
		$options{outputtype} > 1 || $options{axesframed} == 1
		? "Axes->True,AxesLabel->{$options{xaxislabel},$options{yaxislabel},$options{zaxislabel}}"
		: '';

	if ($options{outputtype} == 1) {
		return $plotstructure;
	} elsif ($options{outputtype} == 2) {
		return $plotoptions;
	} elsif ($options{outputtype} == 3) {
		return "{$plotstructure,$plotoptions}";
	} elsif ($options{outputtype} == 4) {
		return "${main::beginplot}${plotstructure},${plotoptions}${main::endplot}";
	} else {
		return 'Invalid outputtype (outputtype should be a number 1 through 4).';
	}
}

1;
