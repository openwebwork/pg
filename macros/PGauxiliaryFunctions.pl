
sub _PGauxiliaryFunctions_init {

}

sub tan {
    sin($_[0])/cos($_[0]);
}
sub cot {
    cos($_[0])/sin($_[0]);
}
sub sec {
    1/cos($_[0]);
}
sub csc {
	1/sin($_[0]);
}
sub ln {
    log($_[0]);
}
sub logten {
    log($_[0])/log(10);
}
sub arcsin {
    atan2 ($_[0],sqrt(1-$_[0]*$_[0]));
}
sub asin {
    atan2 ($_[0],sqrt(1-$_[0]*$_[0]));
}
sub arccos {
    atan2 (sqrt(1-$_[0]*$_[0]),$_[0]);
}
sub acos {
    atan2 (sqrt(1-$_[0]*$_[0]),$_[0]);
}
sub arctan {
    atan2($_[0],1);
}
sub atan {
    atan2($_[0],1);
}
sub arccot {
    atan2(1,$_[0]);
}
sub acot {
    atan2(1,$_[0]);
}
sub sinh {
    (exp($_[0]) - exp(-$_[0]))/2;
}
sub cosh {
    (exp($_[0]) + exp(-$_[0]))/2;
}
sub tanh {
    (exp($_[0]) - exp(-$_[0]))/(exp($_[0]) + exp(-$_[0]));
}
sub sech {
    2/(exp($_[0]) + exp(-$_[0]));
}
sub sgn {
	my $x = shift;
	my $out;
	$out = 1 if $x > 0;
	$out = 0 if $x == 0;
	$out = -1 if $x<0;
	$out;
}
sub step {     # heavyside function (1 or x>0)
	my $x = shift;
	($x > 0 ) ? 1 : 0;
}
sub ceil {
	my $x = shift;
	- floor(-$x);
}
sub floor {
	my $input = shift;
	my $out = int $input;
	$out -- if ( $out <= 0 and ($out-$input) > 0 );  # does the right thing for negative numbers
	$out;
}

sub max {

        my $maxVal = shift;
        my @input = @_;

        foreach my $num (@input) {
                $maxVal = $num if ($maxVal < $num);
        }

        $maxVal;

}

sub min {

        my $minVal = shift;
        my @input = @_;

        foreach my $num (@input) {
                $minVal = $num if ($minVal > $num);
        }

        $minVal;

}

#round added 6/12/2000 by David Etlinger. Edited by AKP 3-6-03

sub round {
	my $input = shift;
	my $out = Round($input);
#	if( $input >= 0 ) {
#		$out = int ($input + .5);
#	}
#	else {
#		$out = ceil($input - .5);
#	}
	$out;
}

# Round contributed bt Mark Schmitt 3-6-03
sub Round {
	if (@_ == 1) { $_[0] > 0 ? int $_[0] + 0.5 : int $_[0] - 0.5}
	elsif (@_ == 2) { $_[0] > 0 ? Round($_[0]*10**$_[1])/10**$_[1] :Round($_[0]*10**$_[1])/10**$_[1]}
}

#least common multiple
#VS 6/29/2000
sub lcm {
	my $a = shift;
	my $b = shift;

	#reorder such that $a is the smaller number
	if ($a > $b) {
		my $temp = $a;
		$a = $b;
		$b = $temp;
	}

	my $lcm = 0;
	my $curr = $b;;

	while($lcm == 0) {
		$lcm = $curr if ($curr % $a == 0);
		$curr += $b;
	}

	$lcm;

}


# greatest common factor
# takes in two scalar values and uses the Euclidean Algorithm to return the gcf
#VS 6/29/2000

sub gcf {
        my $a = abs(shift);	# absolute values because this will yield the same gcd,
        my $b = abs(shift);	# but allows use of the mod operation

	# reorder such that b is the smaller number
	if ($a < $b) {
		my $temp = $a;
		$a = $b;
		$b = $temp;
	}

	return $a if $b == 0;

	my $q = int($a/$b);	# quotient
	my $r = $a % $b;	# remainder

	return $b if $r == 0;

	my $tempR = $r;

	while ($r != 0) {

		#keep track of what $r was in the last loop, as this is the value
		#we will want when $r is set to 0
		$tempR = $r;

		$a = $b;
		$b = $r;
		$q = $a/$b;
		$r = $a % $b;

	}

	$tempR;
}


#greatest common factor.
#same as gcf, but both names are sufficiently common names
sub gcd {
        return gcf($_[0], $_[1]);
}

#returns 1 for a prime number, else 0
#VS 6/30/2000
sub isPrime {
        my $num = shift;
        return 1 if ($num == 2 or $num == 3);
        return 0 if ($num == 1 or $num == 0);
        for (my $i = 2; $i <= sqrt($num); $i++) { return 0 if ($num % $i == 0); }
        return 1;
}

#reduces a fraction, returning an array containing ($numerator, $denominator)
#VS 7/10/2000
sub reduce {

	my $num = shift;
	my $denom = shift;
	my $gcd = gcd($num, $denom);

	$num = $num/$gcd;
	$denom = $denom/$gcd;

	# formats such that only the numerator will be negative
	if ($num/$denom < 0) {$num = -abs($num); $denom = abs($denom);}
	else {$num = abs($num); $denom = abs($denom);}

	my @frac = ($num, $denom);
	@frac;
}


# takes a number and fixed object, as in "$a x" and formats
# to account for when $a = 0, 1, -1
# Usage: format($scalar, "quoted string");
# Example: format(-1, "\pi") returns "-\pi"
# VS 8/1/2000  -  slight adaption of code from T. Shemanske of Dartmouth College
sub preformat {
	my $num = shift;
	my $obj = shift;
	my $out;


	if ($num == 0) { return 0; }
	elsif ($num == 1) { return $obj; }
	elsif ($num == -1) { return "-".$obj; }

	return $num.$obj;
}

# Combinations and permutations

sub C {
	my $n = shift;
	my $k = shift;
	my $ans = 1;

	if($k>($n-$k)) { $k = $n-$k; }
	for (1..$k) { $ans = ($ans*($n-$_+1))/$_; }
	return $ans;
}

sub Comb {
	C(@_);
}

sub P {
	my $n = shift;
	my $k = shift;
	my $perm = 1;

	if($n != int($n) or $n < 0) {
                warn 'Non-negative integer required.';
                return;
        }
	if($k>$n) {
		warn 'Second argument of Permutation bigger than first.';
                return;
        }
	for (($n-$k+1)..$n) { $perm *= $_;}
	return $perm;
}

sub Perm {
	P(@_);
}

#factorial

sub fact {
	P($_[0], $_[0]);
}

# return 1 so that this file can be included with require
1
