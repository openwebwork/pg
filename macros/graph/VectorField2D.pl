
=head1 NAME

VectorField2D.pl - Adds a vector field graph to a WWPlot (from PGgraphmacros.pl) graphobject.

=head1 DESCRIPTION

This is a single macro which creates a vector field and adds it to a graphobject created using
C<init_graph> from PGgraphmacros.pl. Create a vector field by first creating a graphobject.

    loadMacros('PGML.pl', 'PGgraphmacros.pl', 'VectorField2D.pl');
    $gr = init_graph($xmin, $ymin, $xmax, $ymax, axes => [0, 0], pixels => [500, 500]);

Then use the C<VectorField2D(options)> macro to add the vector field C<F = Fx i + Fy j> to the graph,
where C<Fx> and C<Fy> are MathObject formulas in two variables (you may need to add the variables to the Context):

    Context()->variables->add(x => 'Real', y => 'Real');
    VectorField2D(
        graphobject     => $gr,
        Fx              => Formula('2xy'),
        Fy              => Formula('y^2 - x^2'),
        xvar            => 'x',
        yvar            => 'y',
        xmin            => -5,
        xmax            => 5,
        ymin            => -5,
        ymax            => 5,
        xsamples        => 10,
        ysamples        => 10,
        vectorcolor     => 'blue',
        vectorscale     => 0.25,
        vectorthickness => 2,
        vectortiplength => 0.65,
        vectortipwidth  => 0.08,
        xavoid          => 0,
        yavoid          => 0,
    );

Add the following PGML to insert the image into the problem:

    [@ image(insertGraph($gr)) @]*

=head1 OPTIONS

The options control the domain, vector density, and arrow style of the vector field.

=over 5

=item graphobject

A reference to the graphobject to add the vector field to.

=item Fx / Fy

The x and y coordinate functions for vector field. These can either be a MathObject Formula
using two variables, or a perl subroutine, such as C<sub { my ($x, $y) = @_; return $x - $y; }>.

=item xvar / yvar

The name of the two variables used in the MathObjects Fx and Fy. Has no effect on perl functions.

=item xmin / xmax / ymin / ymax

The rectangular domain to plot the vector field inside of.

=item xsamples / ysamples

Defines the number of subrectangles to divide the domain into, which results in
C<xsamples + 1> by C<ysamples + 1> vectors graphed at the grid intersections.

=item vectorcolor / vectorscale / vectorthickness / vectortipwidth / vectortiplength

These define the color and multiple scale factors which are used to compute the length
of the vector arrow and size of the vector tip.

=item xavoid / yavoid

Defines a single point to skip when creating the vector field.

=back

=cut

sub _VectorField2D_init { };    # don't reload this file

loadMacros('MathObjects.pl', 'PGgraphmacros.pl');

sub VectorField2D {
	my %options = (
		graphobject     => undef,
		Fx              => sub { return 1; },
		Fy              => sub { return 1; },
		xvar            => 'x',
		yvar            => 'y',
		xmin            => -5,
		xmax            => 5,
		ymin            => -5,
		ymax            => 5,
		xsamples        => 10,
		ysamples        => 10,
		vectorcolor     => 'blue',
		vectorscale     => 0.25,
		vectorthickness => 2,
		vectortipwidth  => 0.08,
		vectortiplength => 0.65,
		xavoid          => 1000000,
		yavoid          => 1000000,
		@_
	);

	my $gr = $options{graphobject};
	unless (ref($gr) eq 'WWPlot') {
		warn 'VectorField2D: Invalid graphobject provided.';
		return;
	}

	my $Fx = $options{Fx};
	my $Fy = $options{Fy};
	if (Value::isFormula($Fx)) {
		$Fx = $Fx->perlFunction('', [ "$options{xvar}", "$options{yvar}" ]);
	} elsif (ref($Fx) ne 'CODE') {
		warn 'VectorField2D: Invalid function Fx provided.';
		return;
	}
	if (Value::isFormula($Fy)) {
		$Fy = $Fy->perlFunction('', [ "$options{xvar}", "$options{yvar}" ]);
	} elsif (ref($Fy) ne 'CODE') {
		warn 'VectorField2D: Invalid function Fy provided.';
		return;
	}

	# Generate plot data
	my $dx    = ($options{xmax} - $options{xmin}) / $options{xsamples};
	my $dy    = ($options{ymax} - $options{ymin}) / $options{ysamples};
	my $xtail = $options{xmin} - $dx;
	for (0 .. $options{xsamples}) {
		$xtail += $dx;
		my $ytail = $options{ymin} - $dy;
		for (0 .. $options{ysamples}) {
			$ytail += $dy;
			next if ($options{xavoid} == $xtail && $options{yavoid} == $ytail);

			my $Deltax     = $options{vectorscale} * &$Fx($xtail, $ytail);
			my $Deltay     = $options{vectorscale} * &$Fy($xtail, $ytail);
			my $xtip       = $xtail + $Deltax;
			my $ytip       = $ytail + $Deltay;
			my $xstem      = $xtail + $options{vectortiplength} * $Deltax;
			my $ystem      = $ytail + $options{vectortiplength} * $Deltay;
			my $xleftbarb  = $xstem - $options{vectortipwidth} * $Deltay;
			my $yleftbarb  = $ystem + $options{vectortipwidth} * $Deltax;
			my $xrightbarb = $xstem + $options{vectortipwidth} * $Deltay;
			my $yrightbarb = $ystem - $options{vectortipwidth} * $Deltax;

			$gr->moveTo($xtail, $ytail);
			$gr->lineTo($xtip, $ytip, $options{vectorcolor}, $options{vectorthickness});
			$gr->moveTo($xleftbarb, $yleftbarb);
			$gr->lineTo($xtip,       $ytip,       $options{vectorcolor}, $options{vectorthickness});
			$gr->lineTo($xrightbarb, $yrightbarb, $options{vectorcolor}, $options{vectorthickness});
		}
	}
}

1;
