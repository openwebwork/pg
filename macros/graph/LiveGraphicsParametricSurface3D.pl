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

LiveGraphicsParametricSurface3D.pl - provide an interactive plot of a parametric
surface.

=head1 DESCRIPTION

This macro provides the C<ParametricSurface3D> method for creating an
interactive plot of a parametric surface via the C<LiveGraphics3D> JavaScript
applet.  The method takes three C<MathObject> Formulas in two variables as input
and returns a string of plot data that can be displayed using the C<Live3Ddata>
routine of the L<LiveGraphics3D.pl> macro.

=head1 Methods

=head2 ParametricSurface3D

Usage: C<ParametricSurface3D(%options)>

The available options are as follows.

=over

=item C<< Fx => Formula('cos(u) * cos(v)') >>

Parametric function for the C<x>-coordinate.

=item C<< Fy => Formula('sin(u) * cos(v)') >>

Parametric function for the C<y>-coordinate.

=item C<< Fz => Formula('sin(v)') >>

Parametric function for the C<z>-coordinate.

=item C<< uvar => 'u' >>

The first parameter, default 'u'. This must correspond to the first parameter
used in C<Fx>, C<Fy>, and C<Fz>.

=item C<< vvar => 'v' >>

The second parameter, default 'v'. This must correspond to the second parameter
used in C<Fx>, C<Fy>, and C<Fz>.

=item C<< umin => -3 >>

Lower bound for the domain of the first parameter.

=item C<< umax => 3 >>

Upper bound for the domain of the first parameter.

=item C<< vmin => -3 >>

Lower bound for the domain of the second parameter.

=item C<< vmax => 3 >>

Upper bound for the domain of the second parameter.

=item C<< usamples => 3 >>

The number of sample values for the first parameter in the interval from C<umin>
to C<umax> to use.

=item C<< vsamples => 3 >>

The number of sample values for the second parameter in the interval from
C<vmin> to C<vmax> to use.

=item C<< axesframed => 1 >>

If set to 1 then the framed axes are displayed.  If set to 0, the framed
axes are not shown. This is 1 by default.

=item C<< xaxislabel => 'x' >>

Label for the axis corresponding to the first independent variable.

=item C<< yaxislabel => 'y' >>

Label for the axis corresponding to the second independent variable.

=item C<< zaxislabel => 'z' >>

Label for the axis corresponding to the dependent variable.

=item C<< edges => 1 >>

If set to 1, then the edges of the polygons are shown. If set to 0, then the
edges are not shown. This is 1 by default.

=item C<< edgecolor => 'RGBColor[0.2, 0.2, 0.2]' >>

The color of the edges if C<edges> is 1.

=item C<< edgethickness => 'Thickness[0.001]' >>

The thickness of the edges if C<edges> is 1.

=item C<< mesh => 0 >>

If set to 1, then the edge mesh is shown and the polygons for the surface
are not filled.  If set to 0, then the polygons for the surface are filled.  The
edge mesh can also be shown in this case by setting C<edges> to 1. This is 0 by
default.

=item C<< meshcolor => 'RGBColor[0.7, 0.7, 0.7]' >>

The red, green, and blue colors each from 0 to 1 to be combined to form the
color of the mesh.  If this is set and C<mesh> is 1, then this will be the color
of the mesh edges.

=item C<< meshthickness => 0.001 >>

The thickness of the mesh edges if C<mesh> is 1.

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

sub _LiveGraphicsParametricSurface3D_init { }

loadMacros('MathObjects.pl', 'LiveGraphics3D.pl');

$main::beginplot = 'Graphics3D[';
$main::endplot   = ']';

sub ParametricSurface3D {
	# Set default options.
	my %options = (
		Fx            => Formula('1'),
		Fy            => Formula('1'),
		Fz            => Formula('1'),
		uvar          => 'u',
		vvar          => 'v',
		umin          => -3,
		umax          => 3,
		vmin          => -3,
		vmax          => 3,
		usamples      => 20,
		vsamples      => 20,
		axesframed    => 1,
		xaxislabel    => 'x',
		yaxislabel    => 'y',
		zaxislabel    => 'z',
		edges         => 1,
		edgecolor     => 'RGBColor[0.2,0.2,0.2]',
		edgethickness => 'Thickness[0.001]',
		mesh          => 0,
		meshcolor     => 'RGBColor[0.7,0.7,0.7]',
		meshthickness => 0.001,
		outputtype    => 4,
		@_
	);

	$options{Fx}->perlFunction('Fxsubroutine', [ $options{uvar}, $options{vvar} ]);
	$options{Fy}->perlFunction('Fysubroutine', [ $options{uvar}, $options{vvar} ]);
	$options{Fz}->perlFunction('Fzsubroutine', [ $options{uvar}, $options{vvar} ]);

	# Generate plot data.

	my $du = ($options{umax} - $options{umin}) / $options{usamples};
	my $dv = ($options{vmax} - $options{vmin}) / $options{vsamples};

	my (@Fx, @Fy, @Fz);

	for my $i (0 .. $options{usamples}) {
		my $u = $options{umin} + $i * $du;
		for my $j (0 .. $options{vsamples}) {
			my $v = $options{vmin} + $j * $dv;
			$Fx[$i][$j] = sprintf('%.3f', Fxsubroutine($u, $v)->value);
			$Fy[$i][$j] = sprintf('%.3f', Fysubroutine($u, $v)->value);
			$Fz[$i][$j] = sprintf('%.3f', Fzsubroutine($u, $v)->value);
		}
	}

	# Generate plotstructure from the plotdata.  This is a list of arrows (made of lines) that LiveGraphics3D reads as
	# input.  For more information on the format of the plotstructure, see
	# http://www.math.umn.edu/~rogness/lg3d/page_NoMathematica.html

	my $plotstructure = '{';

	if ($options{edges} == 0 && $options{mesh} == 0) {
		$plotstructure .= 'EdgeForm[],';
	} elsif ($options{edges} == 1 && $options{mesh} == 0) {
		$plotstructure .= "EdgeForm[{$options{edgecolor},$options{edgethickness}}],";
	}

	if ($options{mesh} == 1) {
		$plotstructure .= "$options{meshcolor},Thickness[$options{meshthickness}],";
	}

	# Generate the polygons or lines in the plotstructure.
	my @objects;
	if ($options{mesh} == 0) {
		for my $i (0 .. $options{usamples} - 1) {
			for my $j (0 .. $options{vsamples} - 1) {
				push(@objects,
					'Polygon[{'
						. "{$Fx[$i][$j],$Fy[$i][$j],$Fz[$i][$j]},"
						. "{$Fx[$i+1][$j],$Fy[$i+1][$j],$Fz[$i+1][$j]},"
						. "{$Fx[$i+1][$j+1],$Fy[$i+1][$j+1],$Fz[$i+1][$j+1]},"
						. "{$Fx[$i][$j+1],$Fy[$i][$j+1],$Fz[$i][$j+1]}"
						. '}]');
			}
		}
	} else {
		for my $i (0 .. $options{usamples} - 1) {
			for my $j (0 .. $options{vsamples} - 1) {
				push(@objects,
					'Line[{'
						. "{$Fx[$i][$j],$Fy[$i][$j],$Fz[$i][$j]},"
						. "{$Fx[$i+1][$j],$Fy[$i+1][$j],$Fz[$i+1][$j]},"
						. "{$Fx[$i+1][$j+1],$Fy[$i+1][$j+1],$Fz[$i+1][$j+1]},"
						. "{$Fx[$i][$j+1],$Fy[$i][$j+1],$Fz[$i][$j+1]},"
						. "{$Fx[$i][$j],$Fy[$i][$j],$Fz[$i][$j]}"
						. '}]');
			}
		}
	}

	$plotstructure .= join(',', @objects) . '}';

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
