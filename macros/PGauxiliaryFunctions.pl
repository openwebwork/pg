################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2021 The WeBWorK Project, http://openwebwork.sf.net/
# 
# This program is free software; you can redistribute it and/or modify it under
# the terms of either: (a) the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version, or (b) the "Artistic License" which comes with this package.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
# Artistic License for more details.
################################################################################




=head1 NAME

A set of auxilliary functions that are often used in PG problems.  


=head1 DESCRIPTION

This macro creates the following functions that are available for PG: 

	step($number)
	ceil($number)
	floor($number)
	max(@listNumbers)
	min(@listNumbers)
	round($number)
	lcm(@listNumbers)
	gcf(@listNumbers)
	gcd(@listNumbers)
	isPrime($number)
	reduce($numerator,$denominator)
	preformat($scalar, "QuotedString")
	random_pairwise_coprime($ar1, $ar2, ... )
	random_coprime($ar1, $ar2, ... )
=cut

# ^uses loadMacros
loadMacros("PGcommonFunctions.pl");


sub _PGauxiliaryFunctions_init {

}

=head3 step function

=pod

	Usage: step(x);

returns the step function (or Heaviside function) with jump at x=0.  That is when x<0, it returns 0, when x>=0 the function returns 1. 

Example:

	step(3.14159) returns 1

=cut

sub step {     # Heaviside function (1 or x>0)
	my $x = shift;
	($x > 0 ) ? 1 : 0;
}

=head3 ceil Function

=pod

	Usage: ceil(x);

returns the ceiling function of x.  This rounds up to the nearest integer.  

Examples: 

	ceil(3.14159) returns 4
	ceil(-9.75) return -9

=cut

sub ceil {
	my $x = shift;
	- floor(-$x);
}

=head3 floor Function

=pod

	Usage: floor(x);

returns the floor function of x.  This rounds down to the nearest integer.  

Examples: 

	floor(3.14159) returns 3
	floor(-9.75) return -10

=cut

sub floor {
	my $input = shift;
	my $out = int $input;
	$out -- if ( $out <= 0 and ($out-$input) > 0 );  # does the right thing for negative numbers
	$out;
}

=head3 max function 

=pod

	Usage: max(@arr);

returns the maximum of the values in the array @arr. 

Example

	max(1,2,3,4,5,6,7) returns 7

=cut

sub max {

	my $maxVal = shift;
	my @input = @_;

	foreach my $num (@input) {
		$maxVal = $num if ($maxVal < $num);
	}

	$maxVal;

}


=head3 min function 

=pod

	Usage: min(@arr);

returns the minimum of the values in the array @arr. 

Example

	min(1,2,3,4,5,6,7) returns 1

=cut

sub min {

	my $minVal = shift;
	my @input = @_;

	foreach my $num (@input) {
		$minVal = $num if ($minVal > $num);
	}

	$minVal;

}

# round added 6/12/2000 by David Etlinger. Edited by AKP 3-6-03


=head3 round function 

=pod

	Usage: round(x);

returns integer nearest x. 

Example:

	round(3.14159) returns 3

=cut

# ^uses Round
sub round {
	my $input = shift;
	my $out = Round($input);
	$out;
}

=head3 Round function 

=pod

	Usage: Round(x);

returns integer nearest x.  

	Usage: Round(x,n);

returns the number rounded to n digits.  

Example:

	Round(1.789,2) returns 1.79

=cut


# Round contributed bt Mark Schmitt 3-6-03
sub Round {
	if (@_ == 1) { $_[0] > 0 ? int $_[0] + 0.5 : int $_[0] - 0.5}
	elsif (@_ == 2) { $_[0] > 0 ? Round($_[0]*10**$_[1])/10**$_[1] :Round($_[0]*10**$_[1])/10**$_[1]}
}

=head3 lcm function 

=pod

	Usage: lcm(@arr);

returns the lowest common multiple of the array @arr of integers.  

Example:

	 lcm(3,4,5,6) returns 60.

Note: it checks for an empty array, however doesn't check if the inputs are integers. 

=cut

sub lcm {
	do {warn 'Cannot take lcm of the empty set'; return;} unless (@_);
	my $a = abs(shift);
	return 0 unless $a;
	return $a unless (@_);
	my $b = abs(shift);
	return 0 unless $b;
	return lcm($a*$b/gcf($a,$b),@_);
}

=head3 gcf function 

=pod

	Usage: gcf(@arr);

returns the greatest common factor of the array @arr of integers.  

Example:
 
 	gcf(20,30,45) returns 5.

Note: it checks for an empty array, however doesn't check if the inputs are integers. 

=cut

sub gcf {
	# An empty argument array is either from the user or has been filtered down
	# from previous iterations where the user submitted an all-zero array
	do {warn 'Cannot take gcf of the empty set or an all-zero set'; return;} unless (@_);
	my $a = abs(shift);
	return gcf(@_) unless $a;
	return $a unless (@_);
	return 1 unless ($a > 1);
	my $b = abs(shift);
	# Swap if needed to make sure $a is smaller
	($a,$b) = ($b,$a) if $a > $b;
	while ($a) {
		($a, $b) = ($b % $a, $a);
	}
	return gcf($b,@_);
}

=head3 gcd function 

=pod

	Usage: gcd(@arr);

returns the greatest common divisor of the array @arr of integers.  

Example:
	gcd(20,30,45) returns 5.

Note: this is just an alias for gcf. 

=cut

sub gcd {
	return gcf(@_);
}

=head3 random_coprime function 

=pod

	Usage: random_coprime(array of array_refs);

returns relatively prime integers. The arguments should be references to arrays of integers.  This returns an n-tuple of relatively prime integers, 
each one coming from the corresponding array. Random selection is uniform among all possible tuples that are relatively prime.
This does not consider (0,0) to be relatively prime.

This function may return an n-tuple where pairs are not coprime.  This returns n-tuples where the largest (in absolute) common factor is 1. 

In array context, returns an array. Otherwise, an array ref.

Examples: 

	random_coprime([1..9],[1..9]) may return (2,9) or (1,1) but not (6,8)
	random_coprime([-9..-1,1..9],[1..9],[1..9]) may return (-3,7,4), (-1,1,1), or (-2,2,3) but not (-2,2,4)

Note: in the example above (-2,2,3) is valid because not all three share a factor greater than 1.  If you don't want to 
allow pairs of numbers to be coprime, see random_pairwise_coprime. 

	random_pairwise_coprime([-9..-1,1..9],[1..9],[1..9]) may return (-3,7,4) or (-1,1,1) but not (-2,2,3)

WARNING: random_coprime() will use a lot of memory and CPU resources if used with too many/too large arguments.
For example, random_coprime([-20..20],[-20..20],[-20..20],[-20..20],[-20..20]) involves processing 41^5 arrays.	
Consider using random_pairwise_coprime() instead. Or breaking things up like:
random_coprime([-20..20],[-20..20]),random_coprime([-20..20],[-20..20],[-20..20])

Note for Problem Authors: one reason for developing this function is to be able to create polynomials that don't have a constant factor.  
For example, if random_coprime([-9..-1,1..9],[1..9],[1..9]) returns (-5,5,3)
then building the quadratic 3x^2+5x-5 doesn't lead to a constant multiple to be factored.  

=cut

# ^uses gcd
sub random_coprime {
	# Expect first argument to be an array reference
	my $c = shift;
	my @candidates = @$c if $c;
	# @candidates has numbers on the first iteration
	# On subsequent iterations it has two array references
	# The first of these is full of array references to tuples where we already know the gcf is 1
	# The second is full of array references to tuples where the gcf is not 1, but these may become usable on later iterations
	# If it has numbers, initialize the two array refs
	if (ref $candidates[0] eq '') {
		do {warn "Unable to find a coprime tuple from input"; return;} unless (@candidates);
		my @refcandidates = ([],[]);
		for my $i (@candidates) {
			if (abs($i) == 1) {
				push @{$refcandidates[0]},[$i];
			} else {
				push @{$refcandidates[1]},[$i];
			}
		}
		return random_coprime([@refcandidates],@_);
	} elsif (ref $candidates[0] eq 'ARRAY') {
		# Expect second argument to be an array reference to an array of integers, if present
		my $n = shift;
		my @newcomers = @$n if ($n);
		if (@newcomers) {
			# Cross @candidates with @newcomers to make @newcandidates
			my @newcandidates = ([],[]);
			for my $i (@{$candidates[0]}) {
				for my $j (@newcomers) {
					push @{$newcandidates[0]}, [@{$i}, $j];
				}
			}
			for my $i (@{$candidates[1]}) {
				for my $j (@newcomers) {
					# next three lines are to avoid asking for gcf of all-zero set
					my $hasnonzero = 0;
					for my $k (@{$i}) {do {$hasnonzero = 1; last;} if ($k != 0)};
					do {push @{$newcandidates[1]}, [@{$i}, $j]; next} unless ($hasnonzero or $j != 0);
					if (gcf($j,@{$i}) == 1) {
						push @{$newcandidates[0]}, [@{$i}, $j];
					} else {
						push @{$newcandidates[1]}, [@{$i}, $j];
					}
				}
			}
			do {warn "Unable to find a coprime tuple from input"; return;} unless (@{$newcandidates[0]} || @{$newcandidates[1]});
			return random_coprime([@newcandidates],@_);
		} else {
			my @coprime_tuples = @{$candidates[0]};
			do {warn "Unable to find a coprime tuple from input"; return;} unless (@coprime_tuples);
			my $return = list_random(@coprime_tuples);
			return wantarray ? @{$return} : $return;
		};
	}
}

=head3 random_pairwise_coprime function 

=pod

	Usage: random_pairwise_coprime($arr);

This is similar to the random_coprime function with the additional constraint that all pairs of numbers are also coprime.  

Examples: 

	random_coprime([-9..-1,1..9],[1..9],[1..9]) may return (-3,7,4), (-1,1,1), or (-2,2,3) but not (-2,2,4)
	random_pairwise_coprime([-9..-1,1..9],[1..9],[1..9]) may return (-3,7,4) or (-1,1,1) but not (-2,2,3) or (3,5,6)

=cut

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

=head3 isPrime function 

=pod

	Usage: isPrime(n);

returns 1 if n is prime and 0 otherwise. 

Example: 
	
	isPrime(7) returns 1.
	isPrime(8) returns 0

Note: this doesn't check if n is negative. 

=cut

# VS 6/30/2000

sub isPrime {
	my $num = shift;
	return 1 if ($num == 2 or $num == 3);
	return 0 if ($num == 1 or $num == 0);
	for (my $i = 2; $i <= sqrt($num); $i++) { return 0 if ($num % $i == 0); }
	return 1;
}

=head3 reduce function 

=pod

	Usage: reduce(num,den);

returns the fraction num/den as an array with first entry as the numerator and second as the denominator.  

Example:  
	
	reduce(15,20) returns (3,4)

=cut

# VS 7/10/2000
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

=head3 preFormat function 

=pod

	Usage: preFormat($scalar,"quoted string");

returns the string preformatted with the $scalar as 0,1, or -1  takes a number and fixed object, as in "$a x" and formats

Example:  

	preformat(-1, "\pi") returns "-\pi"

=cut

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

# factorial
# ^function fact
# ^uses P
sub fact {
	P($_[0], $_[0]);
}

# return 1 so that this file can be included with require
1
