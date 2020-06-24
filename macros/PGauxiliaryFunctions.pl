
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

# Generate random relatively prime tuple
# (uses gcf(), so it's here, even though this isn't a "function")
# random_pairwise_coprime($ar1, $ar2, ... )
# random_coprime($ar1, $ar2, ... )


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
# should be passed a nonempty array of integers
# checks if passed an empty array, but otherwise does not validate input
# returns their least common multiple
# ^function lcm
sub lcm {
        do {warn 'Cannot take lcm of the empty set'; return;} unless (@_);
        my $a = abs(shift);
        return 0 unless $a;
        return $a unless (@_);
        my $b = abs(shift);
        return 0 unless $b;
        return lcm($a*$b/gcf($a,$b),@_);
}


# greatest common factor
# should be passed a nonempty array of integers
# checks if passed an empty array, but otherwise does not validate input
# returns their greatest common factor
# ^function gcf
sub gcf {
        # An empty argument array is either from the user or has been filtered down
        # from previous iterations where the user submitted an all-zero array
        do {warn 'Cannot take gcf of the empty set or an all-zero set'; return;} unless (@_);
        my $a = abs(shift);
        return gcf(@_) unless $a;
        return $a unless (@_);
        my $b = abs(shift);
        # Swap if needed to make sure $a is smaller
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
        return gcf(@_);
}

# Generate relatively prime integers
# Arguments should be array references to arrays of integers.
# Returns an n-tuple of relatively prime integers,
# each one coming from the corresponding array.
# Random selection is uniform among all possible tuples that are relatively prime.
# Does not consider (0,0) to be relatively prime.
# In array context, returns an array. Otherwise, an array ref.
# Use like:
# random_coprime([1..9],[1..9]) to output maybe (2,9) or (1,1) but not (6,8)
# random_coprime([-9..-1,1..9],[1..9],[1..9]) to output maybe (-3,7,4), (-1,1,1), or (-2,2,3) but not (-2,2,4)
# random_pairwise_coprime([-9..-1,1..9],[1..9],[1..9]) to output maybe (-3,7,4) or (-1,1,1) but not (-2,2,3)

# ^ function random_coprime
# ^uses gcd
sub random_coprime {
  # Expect first argument to be an array reference
  my $c = shift;
  my @candidates = @$c if $c;
  # The array may have numbers (first iteration)
  # or array references to tuples (subsequent iterations)
  # If it has numbers, convert to an array reference of references to 1-element arrays
  # and start over
  if (ref $candidates[0] eq '') {
    my @refcandidates;
    for my $i (@candidates) {push @refcandidates,[$i];}
    do {warn "Unable to find a coprime tuple from input"; return;} unless (@refcandidates);
    return random_coprime([@refcandidates],@_);
  } elsif (ref $candidates[0] eq 'ARRAY') {
    # Expect second argument to be an array reference to an array of integers, if present
    my $n = shift;
    my @newcomers = @$n if ($n);
    if (@newcomers) {
      # Cross @candidates with @newcomers to make @newcandidates
      my @newcandidates;
      for my $i (@candidates) {
        for my $j (@newcomers) {
          push @newcandidates, [@{$i}, $j];
        }
      }
      do {warn "Unable to find a coprime tuple from input"; return;} unless (@newcandidates);
      return random_coprime([@newcandidates],@_);
    } else {
      # Go through all the tuples in @candidates and keep coprime tuples
      my @coprime_tuples;
      for my $i (@candidates) {
        # next three lines are to exclude [0,0,...,0]
        my $hasnonzero = 0;
        for my $j (@{$i}) {do {$hasnonzero = 1; last;} if ($j != 0)};
        next unless ($hasnonzero);
        push @coprime_tuples, $i if (gcf(@{$i}) == 1 or @{$i} == 1);
      }
      do {warn "Unable to find a coprime tuple from input"; return;} unless (@coprime_tuples);
      my $return = list_random(@coprime_tuples);
      return wantarray ? @{$return} : $return;
    };
  }
}

# ^ function random_pairwise_coprime
# ^uses gcd
sub random_pairwise_coprime {
  # Expect first argument to be an array reference
  my $c = shift;
  my @candidates = @$c if $c;
  # The array may have numbers (first iteration)
  # or array references to tuples (subsequent iterations)
  # If it has numbers, convert to an array reference of references to 1-element arrays
  # and start over
  if (ref $candidates[0] eq '') {
    my @refcandidates;
    for my $i (@candidates) {push @refcandidates,[$i];}
    do {warn "Unable to find a coprime tuple from input"; return;} unless (@refcandidates);
    return random_pairwise_coprime([@refcandidates],@_);
  } elsif (ref $candidates[0] eq 'ARRAY') {
    # Expect second argument to be an array reference to an array of integers, if present
    my $n = shift;
    my @newcomers = @$n if ($n);
    if (@newcomers) {
      # Build @newcandidates by combining tuples from @candidates with numbers from @newcomers, only when pairwise coprime
      my @newcandidates;
      for my $i (@candidates) {
        for my $j (@newcomers) {
          my $jOK = 1;
          for my $k (@{$i}) {
            # $j=0 is not OK if @{$i} already contains a 0
            if ($j == 0 and $k == 0) {$jOK = 0; last;}
            # in general, $j are not OK if there is something in @{$i} with which they have gcf > 1
            if (gcf($j,$k) != 1) {$jOK = 0; last;}
          }
          push @newcandidates, [@{$i}, $j] if ($jOK);
        }
      }
      do {warn "Unable to find a coprime tuple from input"; return;} unless (@newcandidates);
      return random_pairwise_coprime([@newcandidates],@_);
    } else {
      # We know all candidate tuples are pairwise coprime already
      my $return = list_random(@candidates);
      return wantarray ? @{$return} : $return;
    };
  }
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
