
sub _PGauxiliaryFunctions_init {

}

=head1 DESCRIPTION

#
#  Get the functions that are in common with Parser.pm
#

=cut

# ^uses loadMacros
loadMacros("PGcommonFunctions.pl");

=head3

#
#  Do the additional functions such as:
#
#  step($number)
#  ceil($number)
#  floor($number)
#  max(@listNumbers)
#  min(@listNumbers)
#  round($number)
#  lcm($number1,$number2)
#  gfc($number1,$number2)
#  gcd($number1,$number2)  
#  isPrime($number)
#  reduce($numerator,$denominator)
#  preformat($scalar, "QuotedString")
#

=cut

# ^function step
sub step {     # heavyside function (1 or x>0)
	my $x = shift;
	($x > 0 ) ? 1 : 0;
}
# ^function ceil
sub ceil {
	my $x = shift;
	- floor(-$x);
}
# ^function floor
sub floor {
	my $input = shift;
	my $out = int $input;
	$out -- if ( $out <= 0 and ($out-$input) > 0 );  # does the right thing for negative numbers
	$out;
}

# ^function max
sub max {

        my $maxVal = shift;
        my @input = @_;

        foreach my $num (@input) {
                $maxVal = $num if ($maxVal < $num);
        }

        $maxVal;

}

# ^function min
sub min {

        my $minVal = shift;
        my @input = @_;

        foreach my $num (@input) {
                $minVal = $num if ($minVal > $num);
        }

        $minVal;

}

#round added 6/12/2000 by David Etlinger. Edited by AKP 3-6-03

# ^function round
# ^uses Round
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
# ^function Round
# ^uses Round
sub Round {
	if (@_ == 1) { $_[0] > 0 ? int $_[0] + 0.5 : int $_[0] - 0.5}
	elsif (@_ == 2) { $_[0] > 0 ? Round($_[0]*10**$_[1])/10**$_[1] :Round($_[0]*10**$_[1])/10**$_[1]}
}

#least common multiple
#VS 6/29/2000
# ^function lcm
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
# ^function gcf
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
# ^function gcd
# ^uses gcf
sub gcd {
        return gcf($_[0], $_[1]);
}

#returns 1 for a prime number, else 0
#VS 6/30/2000
# ^function isPrime
sub isPrime {
        my $num = shift;
        return 1 if ($num == 2 or $num == 3);
        return 0 if ($num == 1 or $num == 0);
        for (my $i = 2; $i <= sqrt($num); $i++) { return 0 if ($num % $i == 0); }
        return 1;
}

#reduces a fraction, returning an array containing ($numerator, $denominator)
#VS 7/10/2000
# ^function reduce
# ^uses gcd
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
# Usage: preformat($scalar, "quoted string");
# Example: preformat(-1, "\pi") returns "-\pi"
# VS 8/1/2000  -  slight adaption of code from T. Shemanske of Dartmouth College
# ^function preformat
sub preformat {
	my $num = shift;
	my $obj = shift;
	my $out;


	if ($num == 0) { return 0; }
	elsif ($num == 1) { return $obj; }
	elsif ($num == -1) { return "-".$obj; }

	return $num.$obj;
}

#factorial
# ^function fact
# ^uses P
sub fact {
	P($_[0], $_[0]);
}

# return 1 so that this file can be included with require
1
