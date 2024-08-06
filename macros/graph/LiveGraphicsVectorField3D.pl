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

LiveGraphicsVectorField3D.pl - provide an interactive plot of a 3D vector field.

=head1 DESCRIPTION

This macro provides a method for creating an interactive plot of a vector field
via the C<LiveGraphics3D> JavaScript applet.  The method takes three
C<MathObject> Formulas of three variables as input and returns a string of plot
data that can be displayed using the C<Live3Ddata> routine of the
L<LiveGraphics3D.pl> macro.

=head1 METHODS

=head2 VectorField3D

Usage: C<VectorField3D(%options)>

The available options are as follows.

=over

=item C<< Fx => Formula('y') >>

Function for the C<x>-coordinate.

=item C<< Fy => Formula('-x') >>

Function for the C<y>-coordinate.

=item C<< Fz => Formula('x + y + z') >>

Function for the C<z>-coordinate.

=item C<< xvar => 'x' >>

First independent variable name, default 'x'. This must correspond to the first
variable used in the C<Fx>, C<Fy>, and C<Fz>.

=item C<< yvar => 'y' >>

Second independent variable name, default 'y'. This must correspond to the
second variable used in the C<Fx>, C<Fy>, and C<Fz>.

=item C<< zvar => 'z' >>

Third independent variable name, default 'z'. This must correspond to the
third variable used in the C<Fx>, C<Fy>, and C<Fz>.

=item C<< xmin => -3 >>

Lower bound for the domain of the first independent variable.

=item C<< xmax => 3 >>

Upper bound for the domain of the first independent variable.

=item C<< ymin => -3 >>

Lower bound for the domain of the second independent variable.

=item C<< ymax => 3 >>

Upper bound for the domain of the second independent variable.

=item C<< zmin => -3 >>

Lower bound for the domain of the third independent variable.

=item C<< zmax => 3 >>

Upper bound for the domain of the third independent variable.

=item C<< xsamples => 20 >>

The number of sample values for the first independent variable in the interval
from C<xmin> to C<xmax> to use.

=item C<< ysamples => 20 >>

The number of sample values for the second independent variable in the interval
from C<ymin> to C<ymax> to use.

=item C<< zsamples => 20 >>

The number of sample values for the third independent variable in the interval
from C<zmin> to C<zmax> to use.

=item C<< axesframed => 1 >>

If set to 1 then the framed axes are displayed.  If set to 0, the the framed
axes are not shown. This is 1 by default.

=item C<< xaxislabel => 'x' >>

Label for the axis corresponding to the first independent variable.

=item C<< yaxislabel => 'y' >>

Label for the axis corresponding to the second independent variable.

=item C<< zaxislabel => 'z' >>

Label for the axis corresponding to the third independent variable.

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

sub _LiveGraphicsVectorField3D_init { }

loadMacros('MathObjects.pl', 'LiveGraphics3D.pl');

$main::beginplot = 'Graphics3D[';
$main::endplot   = ']';

sub VectorField3D {
	# Set default options.
	my %options = (
		Fx              => Formula('1'),
		Fy              => Formula('1'),
		Fz              => Formula('1'),
		xvar            => 'x',
		yvar            => 'y',
		zvar            => 'z',
		xmin            => -3,
		xmax            => 3,
		ymin            => -3,
		ymax            => 3,
		zmin            => -3,
		zmax            => 3,
		xsamples        => 20,
		ysamples        => 20,
		zsamples        => 20,
		axesframed      => 1,
		xaxislabel      => 'x',
		yaxislabel      => 'y',
		zaxislabel      => 'z',
		vectorcolor     => 'RGBColor[0.0,0.0,1.0]',
		vectorscale     => 0.2,
		vectorthickness => 0.001,
		xavoid          => 1000000,
		yavoid          => 1000000,
		zavoid          => 1000000,
		outputtype      => 4,
		@_
	);

	$options{Fx}->perlFunction('Fxsubroutine', [ $options{xvar}, $options{yvar}, $options{zvar} ]);
	$options{Fy}->perlFunction('Fysubroutine', [ $options{xvar}, $options{yvar}, $options{zvar} ]);
	$options{Fz}->perlFunction('Fzsubroutine', [ $options{xvar}, $options{yvar}, $options{zvar} ]);

	# Generate plot data.

	my $dx = ($options{xmax} - $options{xmin}) / $options{xsamples};
	my $dy = ($options{ymax} - $options{ymin}) / $options{ysamples};
	my $dz = ($options{zmax} - $options{zmin}) / $options{zsamples};

	my (@xtail, @ytail, @ztail, @xtip, @ytip, @ztip, @xleftbarb, @xrightbarb, @yleftbarb, @yrightbarb, @zbarb);

	for my $i (0 .. $options{xsamples}) {
		$xtail[$i] = $options{xmin} + $i * $dx;
		for my $j (0 .. $options{ysamples}) {
			$ytail[$j] = $options{ymin} + $j * $dy;
			for my $k (0 .. $options{zsamples}) {
				$ztail[$k] = $options{zmin} + $k * $dz;

				my ($Fx, $Fy, $Fz) = (0, 0, 0);

				if ($xtail[$i] != $options{xavoid} || $ytail[$j] != $options{yavoid} || $ztail[$k] != $options{zavoid})
				{
					$Fx = sprintf('%.3f',
						$options{vectorscale} * Fxsubroutine($xtail[$i], $ytail[$j], $ztail[$k])->value);
					$Fy = sprintf('%.3f',
						$options{vectorscale} * Fysubroutine($xtail[$i], $ytail[$j], $ztail[$k])->value);
					$Fz = sprintf('%.3f',
						$options{vectorscale} * Fzsubroutine($xtail[$i], $ytail[$j], $ztail[$k])->value);
				}

				$xtail[$i] = sprintf('%.3f', $xtail[$i]);
				$ytail[$j] = sprintf('%.3f', $ytail[$j]);
				$ztail[$k] = sprintf('%.3f', $ztail[$k]);

				$xtip[$i][$j][$k] = $xtail[$i] + sprintf('%.3f', $Fx);
				$ytip[$i][$j][$k] = $ytail[$j] + sprintf('%.3f', $Fy);
				$ztip[$i][$j][$k] = $ztail[$k] + sprintf('%.3f', $Fz);

				$xleftbarb[$i][$j][$k] = sprintf('%.3f', $xtail[$i] + 0.8 * $Fx - 0.2 * $Fy);
				$yleftbarb[$i][$j][$k] = sprintf('%.3f', $ytail[$j] + 0.8 * $Fy + 0.2 * $Fx);

				$xrightbarb[$i][$j][$k] = sprintf('%.3f', $xtail[$i] + 0.8 * $Fx + 0.2 * $Fy);
				$yrightbarb[$i][$j][$k] = sprintf('%.3f', $ytail[$j] + 0.8 * $Fy - 0.2 * $Fx);

				$zbarb[$i][$j][$k] = sprintf("%.3f", $ztail[$k] + 0.8 * $Fz);
			}
		}
	}

	# Generate plotstructure from the plotdata.  This is a list of arrows (made of lines) that LiveGraphics3D reads as
	# input.  For more information on the format of the plotstructure, see
	# http://www.math.umn.edu/~rogness/lg3d/page_NoMathematica.html.

	# Generate the lines in the plotstructure.
	my @lines;
	for my $i (0 .. $options{xsamples}) {
		for my $j (0 .. $options{ysamples}) {
			for my $k (0 .. $options{zsamples}) {
				push(@lines,
					'Line[{'
						. "{$xtail[$i],$ytail[$j],$ztail[$k]},"
						. "{$xtip[$i][$j][$k],$ytip[$i][$j][$k],$ztip[$i][$j][$k]}"
						. '}],Line[{'
						. "{$xleftbarb[$i][$j][$k],$yleftbarb[$i][$j][$k],$zbarb[$i][$j][$k]},"
						. "{$xtip[$i][$j][$k],$ytip[$i][$j][$k],$ztip[$i][$j][$k]},"
						. "{$xrightbarb[$i][$j][$k],$yrightbarb[$i][$j][$k],$zbarb[$i][$j][$k]}"
						. '}]');
			}
		}
	}

	my $plotstructure = "{{{{$options{vectorcolor},Thickness[$options{vectorthickness}]," . join(',', @lines) . '}}}}';

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
