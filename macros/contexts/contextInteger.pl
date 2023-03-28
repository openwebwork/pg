################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2022 The WeBWorK Project, https://github.com/openwebwork
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

contextInteger.pl - adds integer related functions primeFactorization, phi, tau, isPrime, randomPrime, lcm, and gcd.

=head1 DESCRIPTION

This is a Parser context that adds integer related functions.  
This forces students to only enter integers as their answers.

=head1 USAGE

	Context("Integer")

  # generates an array of each prime factor
  @a = primeFactorization(1000);
  ANS(List(@a)->cmp);

  # get the gcd
  $b = gcd(5, 2);
  ANS($b->cmp);

  # get lcm
  $c = lcm(36, 90);
  ANS($c->cmp);

  # get phi
  $d = phi(365);
  ANS($d->cmp);
	
  # get tau
  $e = tau(365);
  ANS($e->cmp);

  # check if prime
  $f = isPrime(10); #False
  $h = isPrime(5); #True

  # get a random prime in a range
  $randomPrime = randomPrime(100, 1000);

=cut

loadMacros('MathObjects.pl');

sub _contextInteger_init { context::Integer::Init() }

###########################################################################

package context::Integer;

#
#  Initialize the contexts and make the creator function.
#
sub Init {
	my $context = $main::context{Integer} = Parser::Context->getCopy("Numeric");
	$context->{name} = "Integer";
	Parser::Number::NoDecimals($context);
	$context->{pattern}{number}       = '(?:\d+)';
	$context->{pattern}{signedNumber} = '[-+]?(?:\d+)';

	$context->{parser}{Number} = "Parser::Legacy::LimitedNumeric::Number";
	$context->operators->undefine('U', '.', '><', 'u+', '_',);

	$context->functions->add(
		primeFactorization => { class => 'context::Integer::Function::Numeric' },
		phi                => { class => 'context::Integer::Function::Numeric' },
		tau                => { class => 'context::Integer::Function::Numeric' },
		isPrime            => { class => 'context::Integer::Function::Numeric' },
		randomPrime        => { class => 'context::Integer::Function::Numeric' },
		lcm                => { class => 'context::Integer::Function::Numeric2' },
		gcd                => { class => 'context::Integer::Function::Numeric2' },
	);

	$context->{error}{msg}{"You are not allowed to type decimal numbers in this problem"} =
		"You are only allowed to enter integers, not decimal numbers";

	main::PG_restricted_eval('sub Integer {Value->Package("Integer()")->new(@_)};');
	main::PG_restricted_eval("sub primeFactorization {context::Integer::Function::Numeric::primeFactorization(\@_)}");
	main::PG_restricted_eval("sub phi {context::Integer::Function::Numeric::phi(\@_)}");
	main::PG_restricted_eval("sub tau {context::Integer::Function::Numeric::tau(\@_)}");
	main::PG_restricted_eval("sub isPrime {context::Integer::Function::Numeric::isPrime(\@_)}");
	main::PG_restricted_eval("sub randomPrime {context::Integer::Function::Numeric::randomPrime(\@_)}");
	main::PG_restricted_eval("sub lcm {context::Integer::Function::Numeric2::lcm(\@_)}");
	main::PG_restricted_eval("sub gcd {context::Integer::Function::Numeric2::gcd(\@_)}");
}

#
# divisor function
#
sub _divisor {
	my $power = abs(shift);
	my $a     = abs(shift);
	$self->Error("Cannot perform divisor function on Zero") if $a == 0;
	$result = 1;
	$sqrt_a = int(sqrt($a));
	for (my $i = 2; $i < $sqrt_a; $i++) {
		if ($a % $i == 0) {
			# add divisor to result
			$result += $i**$power;
			# if both divisors are not the same, add the other divisor
			# (ex: 12 / 2 = 6 so add 6 as well)
			if ($i != ($a / $i)) {
				$result += ($a / $i)**$power;
			}
		}
	}
	# add the final divisor, the number itself unless the number is 1
	$result += ($a**$power) if $a > 1;
	return $result;
}

sub _getPrimesInRange {
	my $index = shift;
	my $end   = shift;
	$self->Error("Start of range must be a positive number.")       if $index < 0;
	$self->Error("End of range must be greater than or equal to 2") if $end < 2;
	$self->Error("Start or range must be before end of range")      if $index > $end;
	@primes = ();

	# consider switching to set upper limit and static array of primes

	push(@primes, 2) if $index <= 2;
	# ensure index is odd
	$index++ if $index % 2 == 0;
	while ($index < $end) {
		push(@primes, $index) if context::Integer::Function::Numeric::isPrime($index);
		$index += 2;
	}

	return @primes;
}

package context::Integer::Function::Numeric;
our @ISA = qw(Parser::Function::numeric);    # checks for 2 numeric inputs

#
#  Prime Factorization
#
sub primeFactorization {
	my $a = abs(shift);
	$self->Error("Cannot factor Zero into primes.") if $a == 0;
	$self->Error("Cannot factor One into primes.")  if $a == 1;

	my %factors;
	my $n = $a;
	for (my $i = 2; ($i**2) <= $n; $i++) {
		while ($n % $i == 0) {
			$n /= $i;
			$factors{$i}++;
		}
	}
	$factors{$n}++ if $n > 1;

	# store prime factors in array for cmp
	my @results = ();
	for my $factor (main::num_sort(keys %factors)) {
		my $string = $factor;
		$string .= "**" . $factors{$factor} if $factors{$factor} > 1;
		push(@results, $string);
	}
	return @results;
}

#
# Euler's totient function phi(n)
#
sub phi {
	my $a = abs(shift);
	$self->Error("Cannot phi on Zero.") if $a == 0;
	$result = $a;
	$n      = $a;
	for (my $i = 2; ($i**2) <= $n; $i++) {
		next unless ($n % $i == 0);
		while ($n % $i == 0) {
			$n      /= $i;
		}
		$result -= $result / $i;
	}
	$result -= $result / $n if $n > 1;
	return $result;
}

#
# number of divisors function tau(n)
#
sub tau {
	my $a = shift;
	return context::Integer::_divisor(0, $a);
}

sub isPrime {
	my $a = abs(shift);
	return 1 if $a == 2;
	return 0 if $a < 2 || $a % 2 == 0;
	for (my $i = 3; $i <= sqrt($a); $i += 2) {
		return 0 if $a % $i == 0;
	}
	return 1;
}

sub randomPrime {
	my ($start, $end) = @_;
	my @primes = context::Integer::_getPrimesInRange($start, $end);
	$self->Error("Could not find any prime numbers in range.") if $#primes == 0;
	my $primeIndex = $main::PG_random_generator->random(0, ($#primes - 1), 1);
	return $primes[$primeIndex];
}

package context::Integer::Function::Numeric2;
our @ISA = qw(Parser::Function::numeric2);    # checks for 2 numeric inputs

#
#  Greatest Common Divisor
#
sub gcd {
	my $a = abs(shift);
	my $b = abs(shift);
	return $a           if $b == 0;
	return $b           if $a == 0;
	($a, $b) = ($b, $a) if $a > $b;
	while ($a) {
		($a, $b) = ($b % $a, $a);
	}
	return $b;
}

#
#  Extended Greatest Common Divisor
#
# return (g, x, y) a*x + b*y = gcd(x, y)
sub egcd {
	my $a = shift;
	my $b = shift;
	if ($a == 0) {
		return ($b, 0, 1);
	} else {
		my ($g, $x, $y) = egcd($b % $a, $a);
		my $temp = int($b / $a);
		$temp-- if $temp > $b / $a;    # act as floor() rather than int()
		return ($g, $y - $temp * $x, $x);
	}
}

#
#  Modular inverse
#
# x = mulinv(b) mod n, (x * b) % n == 1
sub mulularInverse {
	my $b = shift;
	my $n = shift;
	my ($g, $x, $y) = egcd($b, $n);
	if ($g == 1) {
		return $x % $n;
	} else {
		Value::Error("Modular inverse: gcd($a, $n) != 1");
	}
}

#
#  Least Common Multiple
#
sub lcm {
	my $a = abs(shift);
	my $b = abs(shift);
	return ($a * $b) / gcd($a, $b);
}

1;
