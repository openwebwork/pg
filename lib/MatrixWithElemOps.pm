#!/usr/bin/env perl 

package MatrixWithElemOps;

@MatrixWithElemOps::ISA = qw(Matrix);

our $rangen = new PGrandom(0);

sub random {
	my $out;
	my $a = shift;
	if (ref($a) eq 'ARRAY') {
		$out = genrandom(@$a);
	}
	else {
		my ($b, $c ) = @_;
		$out = nonzero_random($a, $b, $c);
	}
	return($out);
}

sub nonzero_random {
	my ($a, $b, $c) = @_; 
	return($rangen->random(-1,1,2)* $rangen->random(1,$b, $c));
	}

sub genrandom { 
	my ($Low, $High, $Spacing, $ProbPos)  = @_;
	my $out=undef();
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

sub genInvertibleMatrix { #call with genInvertiblemMatrix($Size, $Determinant, $Range, $Difficulty, $randomSeed)
	my ($Size, $Determinant, $Range, $Difficulty, $randomSeed) = @_;
	$rangen -> {'seed'} = $randomSeed;
	if ($Size < 2 or $Size != int($Size))
		{warn "A nontrivial matrix cannot be of size $Size x $Size.";}
	if (ref($Range) ne 'ARRAY') {
		if ($Range < 1) {warn "There are no positive integers less than $Range.";}
		else {$Range = int($Range);}
	}
	$Difficulty = (!(defined($Difficulty))) ? 1
				: ($Difficulty < 1 ) ? 1
					: int($Difficulty);
#print "Range = $Range, Difficulty = $Difficulty\n";
	my $A = new MatrixWithElemOps($Size, $Size);
	$A -> one();
	my $B = new MatrixWithElemOps($Size, $Size);
	$B -> one();
	foreach my $k (1..$Difficulty) {
		foreach my $j  (2..$Size) {
			foreach my $i  (1..$j-1) {
				my $r = random($Range, $Range, 1);
				if ($r != 0) {
					$A -> ER3($i, $r, $j);
					$B -> EC3($j, -$r, $i);
				}
			}
		}
#print $A, "\n"; print $B, "\n";
		foreach my $J (1..$Size-1) {
			my $j = $Size - $J;
			foreach my $I ($j+1..$Size) {
				my $i = $Size - $I+ $j+1;
				my $r = random($Range, $Range, 1);
				if ($r != 0) {
					$A -> ER3($i, $r, $j);
					$B -> EC3($j, -$r, $i);
				}
			}
		}
#print $A, "\n"; print $B, "\n";
	}
	$A -> ER2($Size, $Determinant);
	$B -> EC2($Size, 1/$Determinant);
	bless $A, "MatrixWithElemOps"; 
	bless $B, "MatrixWithElemOps"; 
	bless $A, "MatrixReal1";
	bless $B, "MatrixReal1";
	return ($A, $B);
}


sub ER2 { #call with $matrix -> ER2(RowToModify, Multiplier)
	my $self = shift;
	my ($rowToModify, $multiplier) = @_;
	my ($Rows, $Cols) = $self->dim();
	if ($rowToModify < 0 or $rowToModify > $Rows or $rowToModify != int($rowToModify))
		{warn "There is no row $rowToModify to modify in this matrix.";}
	if ($multiplier == 0)
		{warn "The multiplier must be nonzero for a type 2 operation.";}
	foreach my $j (1..$Cols)
		{$self -> [0][$rowToModify-1][$j-1] *= $multiplier;}
	return(0);
}

sub ER3 { #call with $matrix -> ER3(RowToModify, Multiplier, BaseRow)
	my $self = shift;
	my ($rowToModify, $multiplier, $baseRow) = @_;
	my ($Rows, $Cols) = $self->dim();
	if ($rowToModify < 0 or $rowToModify > $Rows or $rowToModify != int($rowToModify))
		{warn "There is no row $rowToModify to modify in this matrix.";}
	if ($baseRow < 0 or $baseRow > $Rows or $baseRow != int($baseRow) )
		{warn "There is no row $baseRow to multiply in this matrix.";}
	if ($baseRow == $rowToModify)
		{warn "For Type III elementary operations, the rows must be different.";}
	if ($multiplier == 0)
		{warn "The multiplier should be nonzero.";}
	foreach my $j (1..$Cols)
		{$self -> [0][$rowToModify-1][$j-1] += ($multiplier * ($self->[0][$baseRow-1][$j-1]));}
	return(0);
}

sub EC2 { #call with $matrix -> EC2(ColToModify, Multiplier)
	my $self = shift;
	my ($colToModify, $multiplier) = @_;
	my ($Rows, $Cols) = $self->dim();
	if ($colToModify < 0 or $colToModify > $Cols or $colToModify != int($colToModify))
		{warn "There is no column $colToModify to modify in this matrix.";}
	if ($multiplier == 0)
		{warn "The multiplier must be nonzero for a type 2 operation.";}
	foreach my $i (1..$Rows)
		{$self -> [0][$i-1][$colToModify-1] *= $multiplier;}
}


sub EC3 { #call with $matrix -> EC3(ColToModify, Multiplier, BaseCol)
	my $self = shift;
	my ($colToModify, $multiplier, $baseCol) = @_;
	my ($Rows, $Cols) = $self->dim();
	if ($colToModify < 0 or $colToModify > $Cols or $colToModify != int($colToModify))
		{warn "There is no column $colToModify to modify in this matrix.";}
	if ($baseCol < 0 or $baseCol > $Cols or $baseCol != int($baseCol) )
		{warn "There is no column $baseCol to multiply in this matrix.";}
	if ($baseCol == $colToModify)
		{warn "For Type III elementary operations, the columns must be different.";}
	if ($multiplier == 0)
		{warn "The multiplier should be nonzero.";}
	foreach my $i (1..$Rows)
		{$self -> [0][$i-1][$colToModify-1] += ($multiplier * ($self->[0][$i-1][$baseCol-1]));}
}

1;
