
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
#  lcm(@listNumbers)
#  gcf(@listNumbers)
#  gcd(@listNumbers)
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
# ^function lcm
sub lcm {
        do {warn 'Cannot take lcm of the empty set'; return;} unless (@_);
        my $a = abs(shift);
        if ($a == 0) {return 0;}
        return $a unless (@_);
        my $b = abs(shift);
        if ($b == 0) {return 0;}
        else {return lcm($a*$b/gcf($a,$b),@_);};
}


# greatest common factor
# takes in scalar values and uses the Euclidean Algorithm to return the gcf
# ^function gcf
sub gcf {
        do {warn 'Cannot take gcf of the empty set or an all-zero set'; return;} unless (@_);
        my $a = abs(shift);
        if ($a == 0) {return gcf(@_);}
        return $a unless (@_);
        my $b = abs(shift);
        if ($b == 0) {return gcf($a,@_);}
        ($a,$b) = ($b,$a) if $a > $b;
        while ($a) {
          ($a, $b) = ($b % $a, $a);
        }
        return gcf($b,@_);
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
