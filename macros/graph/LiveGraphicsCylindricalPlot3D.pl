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

LiveGraphicsCylindricalPlot3D.pl - provide an interactive plot on a rectangular
cylinder.

=head1 DESCRIPTION

This macro provides the C<CylindricalPlot3D> method for creating an interactive
plot of a function of two variables C<z = f(r, t)> (where C<r> is the radius and
C<t> is the angle) via the C<LiveGraphics3D> JavaScript applet.  The method
takes a C<MathObject> Formula of two variables defined over an annular domain
and some plot options as input and returns a string of plot data that can be
displayed using the C<Live3Ddata> routine of the L<LiveGraphics3D.pl> macro.

=head1 METHODS

=head2 CylindricalPlot3D

Usage: C<CylindricalPlot3D(%options)>

The available options are as follows.

=over

=item C<< function => $f >>

C<$f> is a MathObject Formula. For example, in the setup section define

    Context()->variables->are(r => 'Real', t => 'Real');
    $a = random(1, 3);
    $f = Formula("$a * r + t");    # Use double quotes!

before calling C<CylindricalPlot3D>.

=item C<< rvar => 'r' >>

Radial independent variable name, default 'r'. This must correspond to the
radial variable used in the C<function>.

=item C<< tvar => 't' >>

Angular independent variable name, default 't'. This must correspond to the
angular variable used in the C<function>.

=item C<< rmin => -3 >>

Lower bound for the domain of the radial variable.

=item C<< rmax => 3 >>

Upper bound for the domain of the radial variable.

=item C<< tmin => -3 >>

Lower bound for the domain of the angular variable.

=item C<< tmax => 3 >>

Upper bound for the domain of the angular variable.

=item C<< rsamples => 20 >>

The number of sample values for the radial variable in the interval from C<rmin>
to C<rmax> to use.

=item C<< tsamples => 20 >>

The number of sample values for the angular variable in the interval from
C<tmin> to C<tmax> to use.

=item C<< axesframed => 1 >>

If set to 1 then the framed axes are displayed.  If set to 0, the framed
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

sub _LiveGraphicsCylindricalPlot3D_init { }

loadMacros('MathObjects.pl', 'LiveGraphics3D.pl');

$main::beginplot = 'Graphics3D[';
$main::endplot   = ']';

sub CylindricalPlot3D {
	# Set default options.
	my %options = (
		function   => Formula('1'),
		rvar       => 'r',
		tvar       => 't',
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

	$options{function}->perlFunction('fsubroutine', [ $options{rvar}, $options{tvar} ]);

	# Generate a plotdata array, which has two indices.

	my $dr = ($options{rmax} - $options{rmin}) / $options{rsamples};
	my $dt = ($options{tmax} - $options{tmin}) / $options{tsamples};

	my (@x, @y, @z);

	for my $i (0 .. $options{tsamples}) {
		my $t = $options{tmin} + $i * $dt;
		for my $j (0 .. $options{rsamples}) {
			my $r = $options{rmin} + $j * $dr;
			$x[$i][$j] = $r * cos($t);
			$y[$i][$j] = $r * sin($t);
			$z[$i][$j] = sprintf('%.3f', fsubroutine($r, $t)->value);
			$x[$i][$j] = sprintf('%.3f', $x[$i][$j]);
			$y[$i][$j] = sprintf('%.3f', $y[$i][$j]);
		}
	}

	# Generate a plotstring from the plotdata.  This is a list of polygons that LiveGraphics3D reads as input.
	# For more information on the format of the plotstring, see
	# http://www.math.umn.edu/~rogness/lg3d/page_NoMathematica.html

	# Generate the polygons in the plotstring.
	my @polygons;
	for my $i (0 .. $options{tsamples} - 1) {
		for my $j (0 .. $options{rsamples} - 1) {
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

1;
