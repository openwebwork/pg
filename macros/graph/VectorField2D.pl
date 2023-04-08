sub _VectorField2D_init { };    # don't reload this file

loadMacros('PGgraphmacros.pl');

sub VectorField2D {
	my %options = (
		graphobject     => '',
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
