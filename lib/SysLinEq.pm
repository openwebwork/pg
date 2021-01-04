#!/usr/bin/env perl 

########################################################################  
## William H. Wheeler, July, 2002
## Calling programs must have loaded MatrixReal1.pm and Matrix.pm
########################################################################


package SysLinEq;

our $rangen = new PGrandom(0);

sub genrandom { 
	my ($Low, $High, $Spacing, $ProbPos)  = @_;
	my $out=0;
	if ($Low < 0 and $High > 0 and defined($ProbPos) and $ProbPos > 0) {
		my $p = $rangen -> random(0,1, 0.01);
		$out = ($p <= $ProbPos) ? $rangen -> random($Spacing, $High, $Spacing) 
								: $rangen -> random($Low, 0, $Spacing);
	}
	else {
		$out = $rangen -> random($Low, $High, $Spacing);
	}
	return($out);
}


sub new { #call with   new SysLinEq(num_eqs, num_vars, \$@Variables (optional), Matrix $Coef, Matrix $Constants)
	my $class = shift;
	my ($numEqs, $numVars, $Variables, $Coef, $Constants) =@_;
	my $self = {};
	bless $self, $class;
	$self -> numEqs($numEqs);
	$self -> numVars($numVars);
	$self -> variables($Variables);
	$self -> coeffs($Coef);
	$self -> constants($Constants);
	$self -> variablesVector($self -> genVariablesVector);
	return($self);
}


sub numEqs {
    my $self = shift;
    if (@_) { $self ->{'numEqs'} = shift };
    return $self->{'numEqs'};
}

sub numVars {
    my $self = shift;
    if (@_) { $self ->{'numVars'} = shift };
    return $self->{'numVars'};
}

sub variables {
    my $self = shift;
	my $reference = shift;
    if (ref($reference) eq 'ARRAY') { 
		$self -> {'variables'} = $reference;
		$self -> numVars($#$reference + 1);
	}
    return $self->{'variables'};
}

sub variable_i {# call with $self->variable_i($i) with 1 <= $i <= $numVars.
	my $self = shift;
	my $i = shift;
	if (defined ($i) and  0 <= $i and $i <= $self -> numVars )
		{return(($self -> variables) -> [$i-1]);}
	else
		{return(undef);}
}

sub coeffs {
    my $self = shift;
	my $reference = shift;
    if (ref($reference) eq 'Matrix' or ref($reference) eq 'MatrixReal1') { $self ->{'coeffs'} = $reference };
    return $self->{'coeffs'};
}

sub constants {
    my $self = shift;
	my $reference = shift;
    if (ref($reference) eq 'Matrix' or ref($reference) eq 'MatrixReal1') { $self ->{'constants'} = $reference };
    return $self->{'constants'};
}

sub variablesVector {
    my $self = shift;
	my $reference = shift;
    if (ref($reference) eq 'Matrix' or ref($reference) eq 'MatrixReal1') { $self ->{'variablesVector'} = $reference };
    return $self->{'variablesVector'};
}

sub rrefMatrix {
	my $self = shift;
	my $reference = shift;
    if (ref($reference) eq 'Matrix' or ref($reference) eq 'MatrixReal1') { $self ->{'rrefMatrix'} = $reference };
    return $self->{'rrefMatrix'};
}
	
sub depVariables { # The dependent variables are specified by an ordered array of indicies i_1 < i_2 < ...
    my $self = shift;
	my $reference = shift;
    if (defined($reference) ) {
		if (ref($reference) eq 'ARRAY') { 
#			$self -> {'depVariables'} = \@{&PGsort::PGsort(sub {$a <=> $b}, @{$reference})};
			$self -> {'depVariables'} = $reference;
		}
	}
    return $self->{'depVariables'};
}

sub indVariables { # The dependent variables are specified by an ordered array of indicies i_1 < i_2 < ...
    my $self = shift;
	my $reference = shift;
    if (defined($reference) ) {
		if (ref($reference) eq 'ARRAY') { 
#			$self -> {'indVariables'} = \@{&PGsort::PGsort(sub {$a <=> $b}, @{$reference})};
			$self -> {'indVariables'} = $reference;
		}
	}
    return $self->{'indVariables'};
}

sub genRrefMatrix { # The nonzero entries will be chosen in [$Low, $High] with spacing $Spacing;
					# If $Low < 0, $High > 0, and $ProbPos > 0, then the probability that a
					# nonzero entry is > 0 will be approximately $ProbPos.
	my $self = shift;
	my ($RandomSeed, $Low, $High, $Spacing, $ProbPos) = @_;
	$rangen -> {'seed'} = $RandomSeed;
	my $numEqs = $self->numEqs;
	my $numVars = $self->numVars;
	my $depVariables = (defined($self->depVariables) ) ? $self->depVariables : [];
	my $rank = $#$depVariables + 1;
	my $rref = new Matrix($numEqs, $numVars+1);
	$rref -> zero;
	foreach my $k (1..$rank) {
		my $depVarIndex = $depVariables->[$k-1];
		$rref -> assign ($k, $depVarIndex, 1);
		$q = ($k < $rank) ? $depVariables->[$k] - 1 : $numVars+1;
		foreach my $j ($depVarIndex+1 .. $q) {
			foreach my $i (1 .. $k) {
				$rref -> assign($i, $j, genrandom($Low, $High, $Spacing, $ProbPos));
			}
		}
	}
	bless $rref, "Matrix";
	$self->rrefMatrix($rref);
}

sub transformMatrices {
	my $self = shift;
	my ($A, $Ainverse)= @_;
	if ((ref($A) eq 'Matrix' or ref($A) eq "MatrixReal1") and
		(ref($Ainverse) eq 'Matrix' or ref($Ainverse) eq "MatrixReal1") ) {
		$self -> {'transformMatrices'} = {'A' => $A, 'Ainverse' => $Ainverse};
	}
	return $self->{'transformMatrices'};
}
	
sub genTransformMatrices {
	my $self = shift;
	my ($Determinant, $Difficulty, $RandomSeed, $RandomSpecs) = @_;
	my $numEqs = $self-> numEqs;
	$self -> transformMatrices(
		MatrixWithElemOps::genInvertibleMatrix($numEqs, $Determinant, $RandomSpecs, $Difficulty, $RandomSeed));
}
	
	
sub augmentedMatrix {
	my $self = shift;
	my $reference = shift;
    if (ref($reference) eq 'Matrix' or ref($reference) eq 'MatrixReal1') { $self ->{'augmentedMatrix'} = $reference };
    return $self->{'augmentedMatrix'};
}
	
sub genAugmentedMatrixFromRref {
	my $self = shift;
	my $rref = $self -> rrefMatrix;
	my $A = $self -> transformMatrices -> {'A'};
	if (defined($rref) and defined($A)) {
		my $aug = new Matrix ($self->numEqs, $self->numVars+1);
		$aug = $A * $rref;
		bless $aug, "Matrix";
		$self-> augmentedMatrix($aug);
	}
}

sub genCoeffAndConstantsFromAugmentedMatrix {
	my $self = shift;
	my $aug = $self -> augmentedMatrix;
	if (defined($aug)) {
		$numEqs = $self->numEqs;
		$numVars = $self -> numVars;
		my $coeffs = new Matrix($numEqs, $numVars);
		foreach my $i (1..$numEqs) {
			foreach my $j (1..$numVars) {
				$coeffs -> assign($i, $j, $aug -> element($i, $j));
			}
		}
		my $constants = new Matrix($numEqs,1);
		$constants = $aug -> column($numVars+1);
		$self -> coeffs($coeffs);
		$self -> constants($constants);
	}
}

sub genVariablesVector {
	my $self = shift;
	my $numVars = $self ->numVars();
	my $variablesVector = new Matrix ($numVars,1);
	foreach my $i (1..$numVars) {
		$variablesVector -> assign($i,1, $self->variable_i($i));
	}
	return($variablesVector);
}

sub affineBasis {
	my $self = shift;
	my $reference = shift;
    if (ref($reference) eq 'Matrix' or ref($reference) eq 'MatrixReal1') { $self ->{'affineBasis'} = $reference };
    return $self->{'affineBasis'};
}

sub genAffineBasisFromRrefMatrix {
	my $self = shift;
	my $rref = $self -> rrefMatrix;
	my $numEqs = $self -> numEqs;
	my $numVars = $self -> numVars;
	my (@depVars, @indVars, %Index);
	##############################  Analyze which variables are independent and which are dependent
	my $row = 1;
	foreach my $j (1..$numVars) {
		if ($row <= $numEqs) {
			if ($rref -> element($row, $j) == 1.0) {
				push @depVars, $j;
				$Index{$j} = scalar(@depVars);
				$row++;
			}
			else {
				push @indVars, $j;
				$Index{$j} = -scalar(@indVars);
			}
		}
		else {
			push @indVars, $j;
			$Index{$j} = -scalar(@indVars);
		}
	}
	############################  Construct the Affine Basis Matrix with Particular Solution in First Column
	my $affineBasis = new Matrix ($numVars, scalar(@indVars) + 1);
	$affineBasis -> zero;
	my $j = 1;
	foreach my $i (1..$numVars) {
		if ($Index{$i} > 0) {
			$affineBasis -> assign($i, $j, $rref->element($Index{$i},$numVars+1)); 
		}
		else {
			$affineBasis -> assign($i, $j, 0);
		}
	}
	foreach my $k (1..scalar(@indVars)) {
		$j = $k+1;
		foreach my $i (1..$indVars[$k-1]-1) {
			if ($Index{$i} > 0) {
				$affineBasis -> assign($i, $j, - $rref->element($Index{$i}, $indVars[$k-1]));
			}
			else {
				$affineBasis -> assign($i, $j, 0);
			}
			$affineBasis -> assign($indVars[$k-1], $j, 1);
		}
	}
	bless $affineBasis, "Matrix";
	$self ->indVariables(\@indVars);
	$self -> affineBasis($affineBasis);
}
			
sub ithVariableSolutionEquation {
	my $self = shift;
	my $ith = shift;
	my $affineBasis = $self->affineBasis;
	my $indVars = $self->indVariables;
	my $variables = $self->variables;
	my $numInd = scalar(@$indVars);
	my $value = $affineBasis -> element($ith, 1);
	my $equation = "$value";
	my ($j, $variable);
	foreach my $k (1..$numInd) {
		$j = $k+1;
		$value = $affineBasis -> element($ith,$j);
		if ($value != 0) {
			$variable = $variables -> [$indVars -> [$k-1]-1];
			$equation .= "+ $value * $variable"; 
		}
	}
	return($equation);
}
	

sub render {
	my $self=shift;
	my $numEqs = $self->numEqs;
	my $numVars = $self->numVars;
	my $coeffs = $self -> coeffs;
	my $constants = $self -> constants;
	my $alignment = "r";
	foreach my $i (2..$numVars) {$alignment .= "cr";}
	$alignment .= "cr";
	my $out = "\\begin{array} {${alignment}}\n";
	my ($coef, $coefString, $sign, $absCoef);
	foreach my $i (1..$numEqs) {
		my $leftside = '';
		my $leading = 0;
		foreach my $j (1..$numVars) {
			$coef = $coeffs -> element($i, $j);
#			if ($coef != 0 ) {
			if ($coef =~ /[A-Za-z]/ or $coef != 0) {
#			if (($coef = $coeffs -> element($i, $j)) != 0 or 1*$coef ne $coef ) {
				if ($coef =~ /[A-Za-z]/) {
					if ($leading) {
						$sign = " & + & ";
					}
					else {
						$sign = '';
						$leading = 1;
					}
					$coefString = $sign . "$coef";
				}
				else {
					$absCoef = abs($coef);
					if ($leading) {
						$sign = ($coef > 0) ? '+' : '-';
						$sign = " & " . $sign . " & ";
						$coefString = ($coef == +1 or $coef == -1) ?
							 $sign : $sign . " $absCoef";
					}		
					else {
						$sign = ($coef > 0) ? '' : '-';
						$coefString = ($coef == +1 or $coef == -1) ?
							 $sign : $sign . " $absCoef";
						$leading = 1;
					}
				}
			$leftside .= $coefString . " " . $self->variable_i($j) . " ";
			}
			else {
				$leftside = " & & " . $leftside ;
			}
		}
		if ($leading == 0) {$leftside .= '0';}
		my $constant = $constants -> element($i, 1);
#		$out .= $leftside . " & = & " . "$constant" . "\\\\\n"; 
		$out .= $leftside . " & = & " . "$constant" . '\\\\' . "\n"; 
	}	
 	$out .= "\\end{array} \n";
	return($out);
}


1;
