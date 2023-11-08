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

LiveGraphicsCylindricalPlot3D.pl - provide an interactive plot on a rectangular cylinder.

=head1 DESCRIPTION

C<LiveGraphicsCylindricalPlot3D.pl> provides a macros for creating an
interactive plot of a function of two variables C<z = f(r,t)>
(where C<r> is the radius and C<t=theta >is the angle) via the C<LiveGraphics3D>
javascript applet.  The routine CC<ylindricalPlot3D()> takes a C<MathObject> Formula
of two variables defined over an annular domain and some plot options
as input and returns a string of plot data that can be displayed
using the C<Live3Ddata()> routine of the C<LiveGraphics3D.pl> macro.

=head1 USAGE

    CylindricalPlot3D(options)

Options are:

    function => $f,        $f is a MathObjects Formula
                           For example, in the setup section define

                           Context("Numeric");
                           Context()->variables->add(r=>"Real",t=>"Real");
                           $a = random(1,3,1);
                           $f = Formula("$a*r + t"); # use double quotes!

                           before calling CylindricalPlot3D()

    rvar => "r",           independent variable name, default "r"
    tvar => "t",           independent variable name, default "t"

    rmin =>  0,            domain for rvar
    rmax =>  3,

    tmin => -3,            domain for tvar
    tmax =>  3,

    rsamples => 20,        deltar = (rmax - rmin) / rsamples
    tsamples => 20,        deltat = (tmax - tmin) / tsamples

    axesframed => 1,       1 displays framed axes, 0 hides framed axes

    xaxislabel => "X",     Capital letters may be easier to read
    yaxislabel => "Y",
    zaxislabel => "Z",

    outputtype => 1,       return string of only polygons (or mesh)
                  2,       return string of only plotoptions
                  3,       return string of polygons (or mesh) and plotoptions
                  4,       return complete plot


=cut

sub _LiveGraphicsCylindricalPlot3D_init { };    # don't reload this file

loadMacros("MathObjects.pl", "LiveGraphics3D.pl");

$beginplot = "Graphics3D[";
$endplot   = "]";

#############################################
#  Begin CylindricalPlot3D

sub CylindricalPlot3D {

#############################################
	#
	#  Set default options
	#

	my %options = (
		function   => Formula("1"),
		rvar       => "r",
		tvar       => "t",
		rmin       => 0.001,
		rmax       => 3,
		tmin       => 0,
		tmax       => 6.28,
		rsamples   => 20,
		tsamples   => 20,
		axesframed => 1,
		xaxislabel => "X",
		yaxislabel => "Y",
		zaxislabel => "Z",
		outputtype => 4,
		@_
	);

	my $fsubroutine;
	$options{function}->perlFunction('fsubroutine', [ "$options{rvar}", "$options{tvar}" ]);

######################################################
	#
	#  Generate a plotdata array, which has two indices
	#

	my $rsamples1 = $options{rsamples} - 1;
	my $tsamples1 = $options{tsamples} - 1;

	my $dr = ($options{rmax} - $options{rmin}) / $options{rsamples};
	my $dt = ($options{tmax} - $options{tmin}) / $options{tsamples};

	my $r;
	my $t;

	my $x;
	my $y;
	my $z;

	foreach my $i (0 .. $options{tsamples}) {
		$t[$i] = $options{tmin} + $i * $dt;
		foreach my $j (0 .. $options{rsamples}) {
			$r[$j]     = $options{rmin} + $j * $dr;
			$x[$i][$j] = $r[$j] * cos($t[$i]);
			$y[$i][$j] = $r[$j] * sin($t[$i]);
			$z[$i][$j] = sprintf("%.3f", fsubroutine($r[$j], $t[$i])->value);
			$x[$i][$j] = sprintf("%.3f", $x[$i][$j]);
			$y[$i][$j] = sprintf("%.3f", $y[$i][$j]);
		}
	}

###########################################################################
	#
	#  Generate a plotstring from the plotdata.
	#
	#  The plotstring is a list of polygons that
	#  LiveGraphics3D reads as input.
	#
	#  For more information on the format of the plotstring, see
	#  http://www.math.umn.edu/~rogness/lg3d/page_NoMathematica.html
	#  http://www.vis.uni-stuttgart.de/~kraus/LiveGraphics3D/documentation.html
	#
###########################################
	#
	#  Generate the polygons in the plotstring
	#

	my $plotstructure = "{";

	foreach my $i (0 .. $tsamples1) {
		foreach my $j (0 .. $rsamples1) {

			$plotstructure =
				$plotstructure
				. "Polygon[{"
				. "{$x[$i][$j],$y[$i][$j],$z[$i][$j]},"
				. "{$x[$i+1][$j],$y[$i+1][$j],$z[$i+1][$j]},"
				. "{$x[$i+1][$j+1],$y[$i+1][$j+1],$z[$i+1][$j+1]},"
				. "{$x[$i][$j+1],$y[$i][$j+1],$z[$i][$j+1]}" . "}]";

			if (($i < $tsamples1) || ($j < $rsamples1)) {
				$plotstructure = $plotstructure . ",";
			}

		}
	}

	$plotstructure = $plotstructure . "}";

##############################################
	#
	#  Add plot options to the plotoptions string
	#

	my $plotoptions = "";

	if ($options{outputtype} > 1 && $options{axesframed} == 1) {
		$plotoptions =
			$plotoptions
			. "Axes->True,AxesLabel->"
			. "{$options{xaxislabel},$options{yaxislabel},$options{zaxislabel}}";
	}

####################################################
	#
	#  Return only the plotstring    (if outputtype=>1),
	#  or only plotoptions           (if outputtype=>2),
	#  or plotstring, plotoptions    (if outputtype=>2),
	#  or the entire plot (default)  (if outputtype=>4)

	if ($options{outputtype} == 1) {
		return $plotstructure;
	} elsif ($options{outputtype} == 2) {
		return $plotoptions;
	} elsif ($options{outputtype} == 3) {
		return "{" . $plotstructure . "," . $plotoptions . "}";
	} elsif ($options{outputtype} == 4) {
		return $beginplot . $plotstructure . "," . $plotoptions . $endplot;
	} else {
		return "Invalid outputtype (outputtype should be a number 1 through 4).";
	}

}    #  End CylindricalPlot3D
#####################################################
#####################################################

1;
