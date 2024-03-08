package PGrandom;

use strict;
use warnings;

my $multiplier = 69069;

my $translate = 1;

my $modulus = 2**32;

sub new {
	my ($class, $seed) = @_;

	$seed //= 1;
	my $original_seed = $seed;
	$seed = mod($multiplier * $seed + $translate, $modulus);

	return bless {
		seed            => $seed,
		original_seed   => $original_seed,    # This and the next value are largely for debugging.
		number_of_calls => 1                  # There is always one call to set the seed.
	}, $class;
}

# Perl's % modulus operator does not work for large numbers. So use mod here instead. Although, does this ever actually
# need to handle numbers greater than 2^63 - 1 which is where the % operator fails? I think this dates back to the days
# of 32 bit integers being used.
sub mod {
	my ($m, $n) = @_;
	return $m - int($m / $n) * $n;
}

sub random {
	my ($self, $begin, $end, $incr) = @_;
	++$self->{number_of_calls};
	$incr //= 1;
	my $seed     = $self->{'seed'};
	my $new_seed = mod($multiplier * $seed + $translate, $modulus);
	$self->{seed} = $new_seed;

	unless ($incr <= 0) {
		# If $incr is less than zero, then return a "continuous" distribution.
		return $begin + $incr * int(($new_seed / ($modulus)) * (int(($end - $begin) / $incr) + 1));
	} else {
		return $begin + ($end - $begin) * $new_seed / $modulus;
	}
}

sub rand {
	my ($self, $end) = @_;
	$end //= 1;
	return $self->random(0, $end, 0);
}

sub srand {
	my ($self, $new_seed) = @_;
	$self->{original_seed}   = $new_seed;
	$new_seed                = mod($multiplier * $new_seed + $translate, $modulus);    # reset the seed
	$self->{number_of_calls} = 1;
	$self->{seed}            = $new_seed;
	return;
}

# This is a synonym for srand.
sub seed {
	my ($self, $new_seed) = @_;
	$self->srand($new_seed);
	return;
}

1;
