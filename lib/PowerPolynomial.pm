#! /usr/local/bin/perl

package PowerPolynomial;

#@ISA = qw(Function);

	
sub givenVariableAndHash { # Give anonymous hash of coefficients
	my ($class, $variable, $hash) = @_;
	my $terms = {};
	my @exponents = keys(%{$hash});
	my $p;
	my $q;
	my $cp;
	my $cq;
	foreach my $ith (@exponents) {
		$cp = $hash -> {$ith} -> [0] -> [0];
		$cq = $hash -> {$ith} -> [0] -> [1];
		$cq = (!defined($cq)) ? 1 : $cq ;
		$terms ->{$ith} -> {'coef'} = new Fraction($cp, $cq);
		$p = $hash -> {$ith} -> [1] -> [0];
		$q = $hash -> {$ith} -> [1] -> [1];
		$q = (!defined($q)) ? 1 : $q ;
		$terms ->{$ith} -> {'exp'} = new Fraction($p, $q);
		}
	my $self = { 'variable' => $variable,
				'terms' => $terms,
				};
	bless $self, $class;
	return($self);
}

sub givenVariableAndTerms { # Give reference to hash of Fraction coefficients and exponents
	my ($class, $variable, $hash) = @_;
	my $terms = {};
	my @exponents = keys(%{$hash});
	foreach my $ith (@exponents) {
		$terms ->{$ith} -> {'coef'} = $hash -> {$ith} -> {'coef'} -> copy ;
		$terms ->{$ith} -> {'exp'} = $hash -> {$ith} -> {'exp'} -> copy ;
		}
	my $self = { 'variable' => $variable,
				'terms' => $terms,
				};
	bless $self, $class;
	return($self);
}

	


sub terms {
	my $self = shift;
	if (@_) {$self -> {'terms'} = shift;}
	return ($self -> {'terms'});
}

sub variable {
	my $self = shift;
	if (@_) {$self->{'variable'} = shift;}
	return($self ->{'variable'});
}

sub printSelf {
	my $self = shift;
	my $variable = $self->variable();
	my $terms = $self -> terms();
	my @exponents = keys(%{$terms});
	my $string = "";
	my $numTerms = scalar(@exponents);
	my $jth;
	my $coef;
	my $exp;
	my $p;
	my $q;
	foreach my $i (0..$numTerms-1) {
		$jth = $exponents[$i];
		$coef = $terms -> {$jth} -> [0];
		$p = $terms -> {$jth} -> [1] -> [0];
		$q = $terms -> {$jth} -> [1] -> [1];
		$exp = ( !defined($q) or $q==1) ? "$p" : "$p/$q";
		$string .= " + " . $coef ." x^{" . $jth ."}";
	}
	return($string);
}

sub TeXizeHighFirst {
	my $self = shift;
	my $variable = $self->variable();
	my $terms = $self->terms();
	my @exponents  =keys(%{$terms});
	my @sorted_exponents = &PGtranslator::PGsort(sub {$_[0] <=> $_[1]}, @exponents);
	my $numTerms = scalar(@sorted_exponents);
	my $string = "";
	my $found = 0;
	my $coef;
	my $jth;
	my $p;
	my $q;
	my $exp;
	my $numer;
	my $denom;
	foreach my $i (0..$numTerms-1) {
		$jth = $sorted_exponents[$numTerms -1 -$i];
		if ($jth != 0) {
		$exp = $terms -> {$jth} -> {'exp'};
		$exp -> reduce();
		$numer = $exp -> numerator;
		$numerAbs = ($numer < 0) ? -$numer : $numer;
		$denom = $exp -> denominator;
		$expStr = $exp -> TeXize;
		$vterm = ($jth == 1) ? "$variable" : 
				( $denom == 1 and $numer >0 ) ? "$variable^{$expStr}"
				: ($denom == 1 and $numer == -1) ? "\\frac{1}{$variable}"
				: ($denom == 1 and $numer < 0) ? "\\frac{1}{$variable^{$numerAbs}}"
				: ($denom == 2 and $numer == 1) ? "\\sqrt{$variable}"
				: ($denom == 2 and $numer > 0) ? "\\sqrt{$variable^{$numer}}"
				: ($denom == 2 and $numer == -1) ? "\\frac{1}{\\sqrt{$variable}}"
				: ($denom == 2 and $numer < 0) ? "\\frac{1}{\\sqrt{$variable^{$numerAbs}}}"
				: ($denom != 1 and $numer == 1) ? "\\sqrt[$denom]{$variable}"
				: ($denom != 1 and $numer > 0) ? "\\sqrt[$denom]{$variable^{$numer}}"
				: ($denom != 1 and $numer == -1) ? "\\frac{1}{\\sqrt[$denom]{$variable}}"
				: ($denom != 1 and $numer < 0) ? "\\frac{1}{\\sqrt[$denom]{$variable^{$numerAbs}}}"
				: "$variable^{$expStr}";
		if (($coef = $terms -> {$jth} -> {'coef'} ->scalar) != 0) 
			{$coefStr = $terms -> {$jth} -> {'coef'} -> TeXize;
			if ($found) {
				$string .= 
					($coef == 1) ? " + $vterm"
					:	($coef > 0) ? " + $coefStr $vterm"
						: ($coef == -1) ? " - $vterm"
							: "  $coefStr $vterm";
				}
			else {
				$found=1;
				$string .= 
					($coef == 1) ? " $vterm"
					:	($coef > 0) ? " $coefStr $vterm"
						: ($coef == -1) ? " - $vterm"
							: "  $coefStr $vterm";
				}
		}
	}			
	else {
	if (($coef = $terms -> {$jth} -> {'coef'} ->scalar) != 0) 
		{$coefStr = $terms -> {$jth} -> {'coef'} -> TeXize;
			if ($found) {
				$string .= ($coef > 0) ? " + $coefStr "
					: "  $coefStr " ;
				}
			else {
				$found=1;
				$string .= ($coef > 0) ? " $coefStr "
					: "  $coefStr " ;
				}
			}
		}
	}
	return($string);
}

sub TeXizeHighFirstAt {
	my ($self, $at, @rest) = @_;
	my $variable = $self->variable();
	if (defined($at)) {
		if (ref($at) ne '') {
			$variable = $at -> TeXizeHighFirstAt(@rest); }
		else {
			$variable = $at;
			}
		$variable = '\left(' . $variable . '\right)';
	}
	my $terms = $self->terms();
	my @exponents  =keys(%{$terms});
	my @sorted_exponents = &PGtranslator::PGsort(sub {$_[0] <=> $_[1]}, @exponents);
	my $numTerms = scalar(@sorted_exponents);
	my $string = "";
	my $found = 0;
	my $coef;
	my $jth;
	my $p;
	my $q;
	my $exp;
	my $numer;
	my $denom;
	foreach my $i (0..$numTerms-1) {
		$jth = $sorted_exponents[$numTerms -1 -$i];
		if ($jth != 0) {
		$exp = $terms -> {$jth} -> {'exp'};
		$exp -> reduce();
		$numer = $exp -> numerator;
		$numerAbs = ($numer < 0) ? -$numer : $numer;
		$denom = $exp -> denominator;
		$expStr = $exp -> TeXize;
		$vterm = ($jth == 1) ? "$variable" : 
				( $denom == 1 and $numer >0 ) ? "$variable^{$expStr}"
				: ($denom == 1 and $numer == -1) ? "\\frac{1}{$variable}"
				: ($denom == 1 and $numer < 0) ? "\\frac{1}{$variable^{$numerAbs}}"
				: ($denom == 2 and $numer == 1) ? "\\sqrt{$variable}"
				: ($denom == 2 and $numer > 0) ? "\\sqrt{$variable^{$numer}}"
				: ($denom == 2 and $numer == -1) ? "\\frac{1}{\\sqrt{$variable}}"
				: ($denom == 2 and $numer < 0) ? "\\frac{1}{\\sqrt{$variable^{$numerAbs}}}"
				: ($denom != 1 and $numer == 1) ? "\\sqrt[$denom]{$variable}"
				: ($denom != 1 and $numer > 0) ? "\\sqrt[$denom]{$variable^{$numer}}"
				: ($denom != 1 and $numer == -1) ? "\\frac{1}{\\sqrt[$denom]{$variable}}"
				: ($denom != 1 and $numer < 0) ? "\\frac{1}{\\sqrt[$denom]{$variable^{$numerAbs}}}"
				: "$variable^{$expStr}";
		if (($coef = $terms -> {$jth} -> {'coef'} ->scalar) != 0) 
			{$coefStr = $terms -> {$jth} -> {'coef'} -> TeXize;
			if ($found) {
				$string .= 
					($coef == 1) ? " + $vterm"
					:	($coef > 0) ? " + $coefStr $vterm"
						: ($coef == -1) ? " - $vterm"
							: "  $coefStr $vterm";
				}
			else {
				$found=1;
				$string .= 
					($coef == 1) ? " $vterm"
					:	($coef > 0) ? " $coefStr $vterm"
						: ($coef == -1) ? " - $vterm"
							: "  $coefStr $vterm";
				}
		}
	}			
	else {
	if (($coef = $terms -> {$jth} -> {'coef'} ->scalar) != 0) 
		{$coefStr = $terms -> {$jth} -> {'coef'} -> TeXize;
			if ($found) {
				$string .= ($coef > 0) ? " + $coefStr "
					: "  $coefStr " ;
				}
			else {
				$found=1;
				$string .= ($coef > 0) ? " $coefStr "
					: "  $coefStr " ;
				}
			}
		}
	}
	return($string);
}

sub TeXizeLowFirst {
	my $self = shift;
	my $variable = $self->variable();
	my $terms = $self->terms();
	my @exponents  =keys(%{$terms});
	my @sorted_exponents = &PGtranslator::PGsort(sub {$_[1] <=> $_[2]}, @exponents);
	my $numTerms = scalar(@sorted_exponents);
	my $string = "";
	my $found = 0;
	my $coef;
	my $jth;
	my $p;
	my $q;
	my $exp;
	foreach my $i (0..$numTerms-1) {
		$jth = $sorted_exponents[$numTerms -1 -$i];
		if ($jth != 0) {
		$exp = $terms -> {$jth} -> {'exp'};
		$expStr = $exp -> TeXize;
		$vterm = ($jth == 1) ? "$variable" : "$variable^{$expStr}";
		if (($coef = $terms -> {$jth} -> {'coef'} ->scalar) != 0) 
			{$coefStr = $terms -> {$jth} -> {'coef'} -> TeXize;
			if ($found) {
				$string .= 
					($coef == 1) ? " + $vterm"
					:	($coef > 0) ? " + $coefStr $vterm"
						: ($coef == -1) ? " - $vterm"
							: "  $coefStr $vterm";
				}
			else {
				$found=1;
				$string .= 
					($coef == 1) ? " $vterm"
					:	($coef > 0) ? " $coefStr $vterm"
						: ($coef == -1) ? " - $vterm"
							: "  $coefStr $vterm";
				}
			}
		}			
	else {
	if (($coef = $terms -> {$jth} -> {'coef'} ->scalar) != 0) 
		{$coefStr = $terms -> {$jth} -> {'coef'} -> TeXize;
			if ($found) {
				$string .= ($coef > 0) ? " + $coefStr "
					: "  $coefStr " ;
				}
			else {
				$found=1;
				$string .= ($coef > 0) ? " $coefStr "
					: "  $coefStr " ;
				}
			}
		}
	}
	return($string);
}


sub perlizeHighFirst {
	my $self = shift;
	my $variable = $self->variable();
	my $terms = $self->terms();
	my @exponents  =keys(%{$terms});
	my @sorted_exponents = &PGtranslator::PGsort(sub {$_[0] <=> $_[1]}, @exponents);
	my $numTerms = scalar(@sorted_exponents);
	my $string = "";
	my $found = 0;
	my $coef;
	my $jth;
	my $p;
	my $q;
	my $exp;
	foreach my $i (0..$numTerms-1) {
		$jth = $sorted_exponents[$numTerms -1 -$i];
		if ($jth != 0) {
		$exp = $terms -> {$jth} -> {'exp'};
		$expStr = $exp -> perlize;
		$vterm = ($jth == 1) ? "$variable" : "$variable**($expStr)";
		if (($coef = $terms -> {$jth} -> {'coef'} -> scalar) != 0) 
			{$coefStr = $terms -> {$jth} -> {'coef'} -> perlize;
			if ($found) {
				$string .= 
					($coef == 1) ? " + $vterm"
					:	($coef > 0) ? " + $coefStr * $vterm"
						: ($coef == -1) ? " - $vterm"
#							: " - $coefStr * $vterm";
							: " - " . ($terms ->{$jth} -> {'coef'} -> times(-1)) -> perlize
									. $vterm;
				}
			else {
				$found=1;
				$string .= 
					($coef == 1) ? " $vterm"
					:	($coef > 0) ? " $coefStr * $vterm"
						: ($coef == -1) ? " - $vterm"
#							: " - $coefStr * $vterm";
							: " - " . ($terms ->{$jth} -> {'coef'} -> times(-1)) -> perlize
									. $vterm;
				}
			}
		}			
	else {
	if (($coef = $terms -> {$jth} -> {'coef'}) != 0) 
		{$coefStr = $terms -> {$jth} -> {'coef'} -> perlize;
			if ($found) {
				$string .= ($coef > 0) ? " + $coefStr "
#					: " - $coefStr " ;
					: " - " . ($terms ->{$jth} -> {'coef'} -> times(-1)) -> perlize;
				}
			else {
				$found=1;
				$string .= ($coef > 0) ? " $coefStr "
#					: " - $coefStr " ;
					: " - " . ($terms ->{$jth} -> {'coef'} -> times(-1)) -> perlize;
				}
			}
		}
	}
	return($string);
}

sub perlizeHighFirstAt {
	my ($self, $at, @rest) = @_;
	my $variable = $self->variable();
	if (defined($at)) {
		if (ref($at) ne '') {
			$variable = $at -> perlizeHighFirstAt(@rest); }
		else {
			$variable = $at;
			}
		$variable = '(' . $variable . ')';
	}
	my $terms = $self->terms();
	my @exponents  =keys(%{$terms});
	my @sorted_exponents = &PGtranslator::PGsort(sub {$_[0] <=> $_[1]}, @exponents);
	my $numTerms = scalar(@sorted_exponents);
	my $string = "";
	my $found = 0;
	my $coef;
	my $jth;
	my $p;
	my $q;
	my $exp;
	foreach my $i (0..$numTerms-1) {
		$jth = $sorted_exponents[$numTerms -1 -$i];
		if ($jth != 0) {
		$exp = $terms -> {$jth} -> {'exp'};
		$expStr = $exp -> perlize;
		$vterm = ($jth == 1) ? "$variable" : "$variable**($expStr)";
		if (($coef = $terms -> {$jth} -> {'coef'} ->scalar) != 0) 
			{$coefStr = $terms -> {$jth} -> {'coef'} -> perlize;
			if ($found) {
				$string .= 
					($coef == 1) ? " + $vterm"
					:	($coef > 0) ? " + $coefStr * $vterm"
						: ($coef == -1) ? " - $vterm"
							: "  $coefStr * $vterm";
				}
			else {
				$found=1;
				$string .= 
					($coef == 1) ? " $vterm"
					:	($coef > 0) ? " $coefStr * $vterm"
						: ($coef == -1) ? " - $vterm"
							: "  $coefStr * $vterm";
				}
			}
		}			
	else {
	if (($coef = $terms -> {$jth} -> {'coef'}) != 0) 
		{$coefStr = $terms -> {$jth} -> {'coef'} -> perlize;
			if ($found) {
				$string .= ($coef > 0) ? " + $coefStr "
					: "  $coefStr " ;
				}
			else {
				$found=1;
				$string .= ($coef > 0) ? " $coefStr "
					: "  $coefStr " ;
				}
			}
		}
	}
	return($string);
}

 
sub scalarMult {
	my $self = shift;
	my $scalar = shift;
	if (!(defined($scalar))) {return(undef());}
	my $variable = $self -> variable;
	my $terms = $self -> terms;
	my @exponents = keys(%{$terms});
	foreach my $ith (@exponents) {
		$terms ->{$ith} -> {'coef'} = $terms -> {$ith} -> {'coef'} -> times($scalar);
	}
	my $scalarM = givenVariableAndTerms  PowerPolynomial($variable, $terms);
	return($scalarM);
}



sub derivative {
	my $self = shift;
	my $class = ref($self);
	my $variable = shift;
	if (!(defined($variable))) { $variable = $self -> variable;}
	my $terms = $self->terms();
	my @exponents  =keys(%{$terms});
	my $derTerms = {};
	my ($derExp, $derCoef, $derExponent);
	foreach my $exp (@exponents) {
	  if ($exp != 0) {
		$derExp = $exp - 1;
		$derCoef = $terms->{$exp}->{'coef'} -> times($terms -> {$exp} -> {'exp'});
		$derExponent = $terms -> {$exp} -> {'exp'} -> minus(1);
		$derTerms -> {$derExp} -> {'coef'} = $derCoef;
		$derTerms -> {$derExp} -> {'exp'} = $derExponent;
	  }
	}
	my $derivative = {'variable' => $variable,
					  'terms' => $derTerms,
					};
	bless $derivative, $class;
	return($derivative);
}

sub antiDerivative {
	my $self = shift;
	my $class = ref($self);
	my $variable = shift;
	if (!(defined($variable))) { $variable = $self -> variable;}
	my $terms = $self->terms();
	my @exponents  =keys(%{$terms});
	my $antiDerTerms = {};
	my ($antiDerExp, $antiDerCoef, $antiDerExponent);
	foreach my $exp (@exponents) {
	  if ($exp != -1) {
		$antiDerExp = $exp + 1;
		$antiDerCoef = $terms->{$exp}->{'coef'} -> divBy($terms->{$exp}->{'exp'}->plus(1));
		$antiDerExponent = $terms -> {$exp} -> {'exp'} -> plus(1);
		$antiDerTerms -> {$antiDerExp} -> {'coef'} = $antiDerCoef;
		$antiDerTerms -> {$antiDerExp} -> {'exp'} = $antiDerExponent;
	  }
	}
	my $antiDerivative = {'variable' => $variable,
					  'terms' => $antiDerTerms,
					};
	bless $antiDerivative, $class;
	return($antiDerivative);
}

1;

