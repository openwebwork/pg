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

LiveGraphicsParametricCurve3D.pl - provide an interactive 3D parametric curve.

=head1 DESCRIPTION

This macro provides the C<ParametricCurve3D> method for creating an interactive
plot of a vector field via the C<LiveGraphics3D> JavaScript applet.  The method
takes three C<MathObject> Formulas in one variable as input and returns a string
of plot data that can be displayed using the C<Live3Ddata> routine of the
L<LiveGraphics3D.pl> macro.

=head1 METHODS

=head2 ParametricCurve3D

Usage: C<ParametricCurve3D(%options)>

The available options are as follows.

=over

=item C<< Fx => Formula('t * cos(t)') >>

Parametric function for the C<x>-coordinate.

=item C<< Fy => Formula('t * sin(t)') >>

Parametric function for the C<y>-coordinate.

=item C<< Fz => Formula('t') >>

Parametric function for the C<z>-coordinate.

=item C<< tvar => 't' >>

Parameter name, default 't'. This must correspond to the parameter used in
C<Fx>, C<Fy>, and C<Fz>.

=item C<< tmin => -3 >>

Lower bound for the domain of the parameter.

=item C<< tmax => 3 >>

Upper bound for the domain of the parameter.

=item C<< tsamples => 3 >>

The number of sample values for the parameter in the interval from C<tmin> to
C<tmax> to use.

=item C<< axesframed => 1 >>

If set to 1 then the framed axes are displayed.  If set to 0, the the framed
axes are not shown. This is 1 by default.

=item C<< xaxislabel => 'x' >>

Label for the axis corresponding to the first independent variable.

=item C<< yaxislabel => 'y' >>

Label for the axis corresponding to the second independent variable.

=item C<< zaxislabel => 'z' >>

Label for the axis corresponding to the dependent variable.

=item C<< curvecolor => 'RGBColor[1.0, 0.0, 0.0]' >>

The color of the curve.

=item C<< curvethickness => 0.001 >>

The curve thickness.

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

sub _LiveGraphicsParametricCurve3D_init { }

loadMacros('MathObjects.pl', 'LiveGraphics3D.pl');

$main::beginplot = 'Graphics3D[';
$main::endplot   = ']';

sub ParametricCurve3D {
	# Set default options.
	my %options = (
		Fx             => Formula('1'),
		Fy             => Formula('1'),
		Fz             => Formula('1'),
		tvar           => 't',
		tmin           => -3,
		tmax           => 3,
		tsamples       => 20,
		orientation    => 0,
		axesframed     => 1,
		xaxislabel     => 'x',
		yaxislabel     => 'y',
		zaxislabel     => 'z',
		curvecolor     => 'RGBColor[1.0,0.0,0.0]',
		curvethickness => 0.001,
		outputtype     => 4,
		@_
	);

	$options{Fx}->perlFunction('Fxsubroutine', [ $options{tvar} ]);
	$options{Fy}->perlFunction('Fysubroutine', [ $options{tvar} ]);
	$options{Fz}->perlFunction('Fzsubroutine', [ $options{tvar} ]);

	# Generate plot data.

	my $dt = ($options{tmax} - $options{tmin}) / $options{tsamples};

	my (@Fx, @Fy, @Fz);

	#  The curve data
	for my $i (0 .. $options{tsamples}) {
		my $t = $options{tmin} + $i * $dt;
		$Fx[$i] = sprintf('%.3f', Fxsubroutine($t)->value);
		$Fy[$i] = sprintf('%.3f', Fysubroutine($t)->value);
		$Fz[$i] = sprintf('%.3f', Fzsubroutine($t)->value);
	}

	# Generate plotstructure from the plotdata.  This is a list of lines that LiveGraphics3D reads as input.  For more
	# information on the format of the plotstructure, see http://www.math.umn.edu/~rogness/lg3d/page_NoMathematica.html.

	# Generate the line segments in the plotstructure.
	my @lines;
	for my $i (0 .. $options{tsamples} - 1) {
		push(@lines, "Line[{{$Fx[$i],$Fy[$i],$Fz[$i]},{$Fx[$i+1],$Fy[$i+1],$Fz[$i+1]}}]");
	}

	my $plotstructure = "{$options{curvecolor},Thickness[$options{curvethickness}]," . join(',', @lines) . '}';

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
