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

LiveGraphicsVectorField2D.pl - provide an interactive plot of a 2D vector field.

=head1 DESCRIPTION

This macro provides a method for creating an interactive plot of a vector field
via the C<LiveGraphics3D> JavaScript applet.  The method takes two C<MathObject>
Formulas of two variables as input and returns a string of plot data that can be
displayed using the C<Live3Ddata> routine of the L<LiveGraphics3D.pl> macro.

=head1 METHODS

=head2 VectorField2D

Usage: C<VectorField2D(%options)>

The available options are as follows.

=over

=item C<< Fx => Formula('y') >>

Function for the C<x>-coordinate.

=item C<< Fy => Formula('-x') >>

Function for the C<y>-coordinate.

=item C<< xvar => 'x' >>

First independent variable name, default 'x'. This must correspond to the first
variable used in the C<Fx> and C<Fy>.

=item C<< yvar => 'y' >>

Second independent variable name, default 'y'. This must correspond to the
second variable used in the C<Fx> and C<Fz>.

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

=item C<< vectorcolor => 'RGBColor[0.0, 0.0, 1.0]' >>

Color of vectors shown in the slope field.

=item C<< vectorscale => 0.2 >>

Multiplier that determines the lentgh of vectors shown in the slope field.

=item C<< vectorthickness => 0.001 >>

Thickness (or width) of the line segments used to construct the vectors shown in
the slope field.

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

sub _LiveGraphicsVectorField2D_init { }

loadMacros('MathObjects.pl', 'LiveGraphics3D.pl');

$main::beginplot = 'Graphics3D[';
$main::endplot   = ']';

sub VectorField2D {
	# Set default options
	my %options = (
		Fx              => Formula('1'),
		Fy              => Formula('1'),
		xvar            => 'x',
		yvar            => 'y',
		xmin            => -3,
		xmax            => 3,
		ymin            => -3,
		ymax            => 3,
		xsamples        => 20,
		ysamples        => 20,
		axesframed      => 1,
		xaxislabel      => 'x',
		yaxislabel      => 'y',
		vectorcolor     => 'RGBColor[0.0,0.0,1.0]',
		vectorscale     => 0.2,
		vectorthickness => 0.001,
		outputtype      => 4,
		@_
	);

	$options{Fx}->perlFunction('Fxsubroutine', [ $options{xvar}, $options{yvar} ]);
	$options{Fy}->perlFunction('Fysubroutine', [ $options{xvar}, $options{yvar} ]);

	# Generate plot data

	my $dx = ($options{xmax} - $options{xmin}) / $options{xsamples};
	my $dy = ($options{ymax} - $options{ymin}) / $options{ysamples};

	my (@xtail, @ytail, @xtip, @ytip, @xleftbarb, @xrightbarb, @yleftbarb, @yrightbarb);

	for my $i (0 .. $options{xsamples}) {
		$xtail[$i] = $options{xmin} + $i * $dx;
		for my $j (0 .. $options{ysamples}) {
			$ytail[$j] = $options{ymin} + $j * $dy;

			my $Fx = sprintf('%.3f', $options{vectorscale} * Fxsubroutine($xtail[$i], $ytail[$j])->value);
			my $Fy = sprintf('%.3f', $options{vectorscale} * Fysubroutine($xtail[$i], $ytail[$j])->value);

			$xtail[$i] = sprintf('%.3f', $xtail[$i]);
			$ytail[$j] = sprintf('%.3f', $ytail[$j]);

			$xtip[$i][$j] = $xtail[$i] + sprintf('%.3f', $Fx);
			$ytip[$i][$j] = $ytail[$j] + sprintf('%.3f', $Fy);

			$xleftbarb[$i][$j] = sprintf('%.3f', $xtail[$i] + 0.8 * $Fx - 0.2 * $Fy);
			$yleftbarb[$i][$j] = sprintf('%.3f', $ytail[$j] + 0.8 * $Fy + 0.2 * $Fx);

			$xrightbarb[$i][$j] = sprintf('%.3f', $xtail[$i] + 0.8 * $Fx + 0.2 * $Fy);
			$yrightbarb[$i][$j] = sprintf('%.3f', $ytail[$j] + 0.8 * $Fy - 0.2 * $Fx);
		}
	}

	# Generate plotstructure from the plotdata.  This is a list of arrows (made of lines) that LiveGraphics3D reads as
	# input.  For more information on the format of the plotstructure, see
	# http://www.math.umn.edu/~rogness/lg3d/page_NoMathematica.html.

	# Generate the lines in the plotstructure.
	my @lines;

	for my $i (0 .. $options{xsamples}) {
		for my $j (0 .. $options{ysamples}) {
			push(@lines,
				'Line[{'
					. "{$xtail[$i],$ytail[$j],0},"
					. "{$xtip[$i][$j],$ytip[$i][$j],0}"
					. '}],Line[{'
					. "{$xleftbarb[$i][$j],$yleftbarb[$i][$j],0},"
					. "{$xtip[$i][$j],$ytip[$i][$j],0},"
					. "{$xrightbarb[$i][$j],$yrightbarb[$i][$j],0}"
					. '}]');
		}
	}

	my $plotstructure = "{{{{$options{vectorcolor},Thickness[$options{vectorthickness}]," . join(',', @lines) . '}}}}';

	my $plotoptions = '';
	if ($options{outputtype} > 1) {
		$plotoptions =
			$plotoptions
			. "PlotRange->{{$options{xmin},$options{xmax}},{$options{ymin},$options{ymax}},{-0.1,0.1}},"
			. 'ViewPoint->{0,0,2},ViewVertical->{0,1,0},Lighting->False,'
			. ($options{axesframed} == 1
				? "AxesLabel->{$options{xaxislabel},$options{yaxislabel},Z},Axes->{True,True,False}"
				: '');
	}

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
