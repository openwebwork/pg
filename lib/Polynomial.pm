#! /usr/local/bin/perl

package Polynomial;

#@ISA = qw(Function);

sub givenVariableScaleAndRoots {
	my ($class, $variable,$scale,@roots) = @_;
#	print @roots,"\n";
	my @coefficients;
	my $degree = scalar(@roots);
	foreach my $i (0..$degree-1) {$roots[$i] *= -1;}
	foreach my $i (0..$degree) {
		$coefficients[$i] = $scale * symmetric_function($degree-$i, \@roots);
	}
#	print @coefficients, "\n";
	my $self = {'degree' => $degree,
				'variable' => $variable,
				'scale' => $scale,
				'roots' => \@roots,
				'coefficients' => \@coefficients,
				};
	bless $self, $class;
#	print "OK\n";
	return($self);
}	
	
sub givenVariableScaleVTranslateAndRoots {
	my ($class, $variable,$scale,$vtranslate,@roots) = @_;
#	print @roots,"\n";
	my @coefficients;
	my $degree = scalar(@roots);
	foreach my $i (0..$degree) {
		$coefficients[$i] = $scale * symmetric_function($degree-$i, \@roots);
	}
	$coefficients[0] += $vtranslate;
#	print @coefficients, "\n";
	my $self = {'degree' => $degree,
				'variable' => $variable,
				'scale' => $scale,
				'roots' => \@roots,
				'coefficients' => \@coefficients,
				};
	bless $self, $class;
#	print "OK\n";
	return($self);
}	
	
sub givenVariableAndCoefficients { # Give Coefficients from a_0 to a_n 
	my ($class, $variable, @coefficients) = @_;
	my $degree = scalar(@coefficients) -1;
	while ($degree >= 0 and $coefficients[$degree] == 0)	{
		$degree--;
	}
	my $self = {'degree' => $degree,
				'variable' => $variable,
				'scale' => 1,
				'roots' => [],
				'coefficients' => \@coefficients,
				};
	bless $self, $class;
	return($self);
}

	

sub degree {
	my $self=shift;
	if (@_) {$self -> {'degree'} = shift;}
	return ($self -> {'degree'});
}

sub coefficients {
	my $self = shift;
	if (@_) {$self -> {'coefficients'} = shift;}
	return ($self -> {'coefficients'});
}

sub variable {
	my $self = shift;
	if (@_) {$self->{'variable'} = shift;}
	return($self ->{'variable'});
}

sub TeXizeHighFirst {
	my $self = shift;
	my $degree = $self->degree();
	my $variable = $self->variable();
	my $coefficients = $self->coefficients();
	my $found = 0;
	my $string = "";
	my $coef;
	my $jth;
	foreach my $i (0..$degree-1) {
		$jth = $degree - $i;
		$vterm = ($jth == 1) ? "$variable" : "$variable^{${jth}}";
		if (($coef = $coefficients -> [$jth]) != 0) 
			{if ($found) {
				$string .= 
					($coef == 1) ? " + $vterm"
					:	($coef > 0) ? " + $coef $vterm"
						: ($coef == -1) ? " - $vterm"
							: "  $coef $vterm";
				}
			else {
				$found=1;
				$string .= 
					($coef == 1) ? " $vterm"
					:	($coef > 0) ? " $coef $vterm"
						: ($coef == -1) ? " - $vterm"
							: "  $coef $vterm";
				}
		}
	}			
	$jth = 0;
	if (($coef = $coefficients -> [$jth]) != 0) 
			{if ($found) {
				$string .= ($coef > 0) ? " + $coef "
					: "  $coef " ;
				}
			else {
				$found=1;
				$string .= ($coef > 0) ? " $coef "
					: "  $coef " ;
				}
	}
	return($string);
}

sub TeXizeLowFirst {
	my $self = shift;
	my $degree = $self->degree();
	my $variable = $self->variable();
	my $coefficients = $self->coefficients();
	my $found = 0;
	my $string = "";
	my $coef;
	my $jth;
	$jth = 0;
	if (($coef = $coefficients -> [$jth]) != 0) {
			$found=1;
			$string .= $coef;
	}
	foreach my $i (1..$degree) {
		$jth = $i;
		$vterm = ($jth == 1) ? "$variable" : "$variable^{${jth}}";
		if (($coef = $coefficients -> [$jth]) != 0) 
			{if ($found) {
				$string .= 
					($coef == 1) ? " + $vterm"
					:	($coef > 0) ? " + $coef $vterm"
						: ($coef == -1) ? " - $vterm"
							: "  $coef $vterm";
				}
			else {
				$found=1;
				$string .= 
					($coef == 1) ? " $vterm"
					:	($coef > 0) ? " $coef $vterm"
						: ($coef == -1) ? " - $vterm"
							: "  $coef $vterm";
				}
		}
	}			
	return($string);
}


sub perlizeHighFirst {
	my $self = shift;
	my $degree = $self->degree();
	my $variable = $self->variable();
	my $coefficients = $self->coefficients();
	my $found = 0;
	my $string = "";
	my $coef;
	my $jth;
	foreach my $i (0..$degree-1) {
		$jth = $degree - $i;
		$vterm = ($jth == 1) ? "$variable" : "$variable**(${jth})";
		if (($coef = $coefficients -> [$jth]) != 0) 
			{if ($found) {
				$string .= 
					($coef == 1) ? " + $vterm"
					:	($coef > 0) ? " + $coef * $vterm"
						: ($coef == -1) ? " - $vterm"
							: "  $coef * $vterm";
				}
			else {
				$found=1;
				$string .= 
					($coef == 1) ? " $vterm"
					:	($coef > 0) ? " $coef* $vterm"
						: ($coef == -1) ? " - $vterm"
							: "  $coef * $vterm";
				}
		}
	}			
	$jth = 0;
	if (($coef = $coefficients -> [$jth]) != 0) 
			{if ($found) {
				$string .= ($coef > 0) ? " + $coef "
					: "  $coef " ;
				}
			else {
				$found=1;
				$string .= ($coef > 0) ? " $coef "
					: "  $coef " ;
				}
	}
	return($string);
}

sub ith_symmetric_function {
	my ($K, $i, $arrayref) = @_;
	my $N = scalar(@$arrayref);
	if ($K < 0 or $i < 0 or $K > $N or $i > $N - $K ) 
		{return(0);}
	elsif ($K == 0) 
		{return(1);}
	elsif ($K == 1)
		{return($arrayref -> [$i]);}
	else {
		my $sum = 0;
		foreach my $j ($i+1 .. $N-($K-1)) {
			$sum += ith_symmetric_function($K-1, $j, $arrayref);
		}
		return(($arrayref -> [$i]) * $sum);	
	}
}

sub symmetric_function {
	my ($K, $arrayref) = @_;
	my $N = scalar(@$arrayref);
	if ($K < 0 or $K > $N) {return(0);}
	if ($K == 0) {return(1);}
	my $sum=0;
	foreach my $i (0..$N-$K) {
		$sum += ith_symmetric_function($K, $i, $arrayref);
	}
	return($sum);
}

sub changeVar {
	my $self = shift;
	my $newVar = shift;
	if (!defined($newVar)) {return(undef());}
	my $coefficients=$self->coefficients;
	my $newP = givenVariableAndCoefficients Polynomial($newVar, @{$coefficients});
	return($newP);
}

sub scalarMult {
	my $self = shift;
	my $scalar = shift;
	if (!(defined($scalar))) {return(undef());}
	my $variable = $self -> variable;
	my $coefficients = $self -> coefficients;
	my $degree = $self -> degree;
	my @scalarMultCoeffs = ();
	foreach my $i (0..$degree) {
		$scalarMultCoeffs[$i] = $scalar * $coefficients->[$i];
	}
	my $scalarM = givenVariableAndCoefficients Polynomial($variable, @scalarMultCoeffs);
	return($scalarM);
}

sub polyAddLike {
	my $self = shift;
	my $other = shift;
	if (!(ref($other) eq "Polynomial")) { return(undef());}
	if (($self -> variable) ne ($other -> variable)) {return(undef());}
	my $variable = $self->variable;
	my $mycoefficients = $self->coefficients;
	my $othercoefficients = $other -> coefficients;
	my $myDegree = $self -> degree;
	my $otherDegree = $other -> degree;
	my $degree = ($myDegree >= $otherDegree) ? $myDegree : $otherDegree;
	my @coefficients;
	foreach my $i (0..$degree) {
		$coefficients[$i] = ( (defined($mycoefficients->[$i])) ? $mycoefficients->[$i] : 0 )
		                  + ( (defined($othercoefficients->[$i])) ? $othercoefficients->[$i] : 0 );
	}
	my $sum = givenVariableAndCoefficients Polynomial($variable, @coefficients);
	return($sum);
}


sub polyMultLike {
	my $self = shift;
	my $other = shift;
	if (!(ref($other) eq "Polynomial")) { return(undef());}
	if (($self -> variable) ne ($other -> variable)) {return(undef());}
	my $variable = $self->variable;
	my $mycoefficients = $self->coefficients;
	my $othercoefficients = $other -> coefficients;
	my $myDegree = $self -> degree;
	my $otherDegree = $other -> degree;
	my $degree = $myDegree+$otherDegree;
	my @coefficients;
	foreach my $i (0..$degree) {
		$coefficients[$i]=0;
		my $iB = ($i > $otherDegree ) ? $i-$otherDegree : 0;
		my $iT = ($i > $myDegree ) ? $myDegree : $i;
		foreach my $j ($iB .. $iT) {
			$coefficients[$i] += $mycoefficients->[$j] * $othercoefficients->[$i-$j];
		}
	}
	my $polyM = givenVariableAndCoefficients Polynomial($variable, @coefficients);
	return($polyM);
}


sub derivative {
	my $self = shift;
	my $variable = shift;
	if (!(defined($variable))) { $variable = $self -> variable;}
	my $degree = $self -> degree;
	my $coefficients = $self->coefficients;
	my @derivativeCoeffs = ();
	foreach my $i (1..$degree) {
		$derivativeCoeffs[$i-1] = $i * $coefficients->[$i];
	}
	my $deriv = givenVariableAndCoefficients Polynomial($variable, @derivativeCoeffs);
	return($deriv);
}


sub antiDerivative {
	my $self = shift;
	my $variable = shift;
	if (!(defined($variable))) { $variable = $self -> variable;}
	my $degree = $self -> degree;
	my $coefficients = $self->coefficients;
	my @antiDerivativeCoeffs = ();
	$antiDerivativeCoeffs[0] = 0;
	foreach my $i (0..$degree) {
		$antiDerivativeCoeffs[$i+1] =  ($coefficients->[$i])/($i+1);
	}
	my $antiDeriv = givenVariableAndCoefficients Polynomial($variable, @antiDerivativeCoeffs);
	return($antiDeriv);
}

1;
