

sub _PGstatisticsmacros_init {
	foreach my $t (@Distributions::EXPORT_OK) {
        	*{$t} = *{"Distributions::$t"}
        	}
        foreach my $t (@Regression::EXPORT_OK) {
                *{$t} = *{"Regression::$t"}
                }
}

=head1 Statistics Macros

=head3 Normal distribution

=pod

	Usage: normal_prob(a, b, mean=>0, deviation=>1);

Computes the probability of x being in the interval (a,b) for normal distribution.
The first two arguments are required. Use '-infty' for negative infinity, and 'infty' or '+infty' for positive infinity.
The mean and deviation are optional, and are 0 and 1 respectively by default.
Load PGnumericalmacros.pl in your problem if you use this method.

=cut

sub normal_prob {
        warn 'You must also load PGnumericalmacros to use PGstatisticsmacros' unless defined(&_PGnumericalmacros_init);

	my $a = shift;
        my $b = shift;
 	my %options=@_;

	my $mean = $options{'mean'} if defined ($options{'mean'});
        $mean = 0 unless defined $mean;

	my $deviation = $options{'deviation'} if defined ($options{'deviation'});
        $deviation = 1 unless defined $deviation;

	if ($deviation <= 0) {
		warn 'Deviation must be a positive number.';
		return;
		}

        my $z_score_of_a;
	my $z_score_of_b;

	if ( $a eq '-infty' ) {
		$z_score_of_a = -6;
	} else {
		$z_score_of_a = ($a - $mean)/$deviation;
	}

        if (($b eq 'infty') or ($b eq '+infty')) {
		$z_score_of_b = 6;
	} else {
		$z_score_of_b = ($b - $mean)/$deviation;
	}

        my $function = sub { my $x=shift;
                             $E**(-$x**2/2)/sqrt(2*$PI);
                             };

        my $prob = romberg($function, $z_score_of_a, $z_score_of_b, level => 8);
        $prob;
}

=head3 "Inverse" of normal distribution

=pod

	Usage: normal_distr(prob, mean=>0, deviation=>1);

Computes the positive number b such that the probability of x being in the interval (0,b)
is equal to the given probability (first argument). The mean and deviation are
optional, and are 0 and 1 respectively by default.
Caution: since students may use tables, they may only be able to provide the answer correct to 2 or 3
decimal places. Use tolerance when evaluating answers.
Load PGnumericalmacros.pl if you use this method.

=cut

sub normal_distr {
	warn 'You must also load PGnumericalmacros to use PGstatisticsmacros' unless defined(&_PGnumericalmacros_init);

        my $prob = shift;
        my %options=@_;

        my $mean = $options{'mean'} if defined ($options{'mean'});
        $mean = 0 unless defined $mean;

        my $deviation = $options{'deviation'} if defined ($options{'deviation'});
        $deviation = 1 unless defined $deviation;

        if ($deviation <= 0) {
                warn 'Deviation must be a positive number.';
                return;
                }

        my $function = sub { my $x=shift;
                             $E**(-$x**2/2)/sqrt(2*$PI);
                             };

        my $z_score_of_b = inv_romberg($function, 0, $prob);

        my $b = $z_score_of_b * $deviation + $mean;
        $b;
}


=head3 Mean function

=pod

	Usage: stats_mean(@data);

Computes the artihmetic mean of a list of numbers, data. You may also pass the numbers individually.

=cut

sub stats_mean {
	my @data_list = @_;
	
	my $total = 0;
	
	foreach ( @data_list  )  {
		$total=$total + $_;
	}
	
	my $n = @data_list;
	return( $total/$n );
	
}

=head3 Standard Deviation function

=pod

	Usage: stats_sd(@data);

Computes the sample standard deviation of a list of numbers, data. You may also pass the numbers individually.

=cut

sub stats_sd {
	my @data_list = @_;
	
	my $sum_x = 0;
	#Not using mean for computation saving.
	my $sum_squares = 0;
	#Using the standard computational formula for variance ( sum(x^2) - (sum(x))^2)/(n-1)
	foreach (@data_list) {
		$sum_x=$sum_x + $_;
		$sum_squares = $sum_squares + ($_)*($_);
	}
	
	my $n = @data_list;
	return( sqrt( ($sum_squares - $sum_x*$sum_x/$n)/($n - 1 ) ) );
	
}


=head3 Function to trim the decimal numbers in a floating point number.

=pod

	Usage: significant_decimals(x,n)

Trims the number x to have n decimal digit. ex: significant_decimals(0.12345678,4) = 0.1235

=cut

sub significant_decimals {
# significant_decimals(x,n)
# Return the value of x but with the decimal digits rounded
# to n places.
#
# ex: significant_decimals(0.12345678,4) = 0.1235
		my ($x,$n) = @_;
		if($n < 0)
		{
				die "Invalid digits: $n\n"; # number of decimal places
		}
		elsif ($n > 10)
		{
				# Too many decimal digits to worry about.
				return($x);
		}
		my $power = 10**$n;
		return(int($x*$power + 0.5)/$power);
}




=head3 Function to generate normally distributed random numbers

=pod

	Usage: urand(mean,sd,N,digits)

Generates N normally distributed random numbers with the given mean and standard deviation. The digits is the number of decimal digits to use.

=cut

sub urand { # generate normally dist. random numbers 
# urand(mean,sd,N,digits)
# Generates N random numbers. The distribution is set by 
# mean equal to "mean" and the standard deviation given by 
# "sd." The value of 'digits' gives the number of decimal 
# places to return.
	my ($mean, $sd, $N, $digits) = @_;
	if ($N<=0) {
		die "Invalid N: $N\n"; # Cannot generate negative or zero numbers.
	}

	$random = new PGrandom;
	$pi = 4.0*atan(1.0);
	my @numbers = ();
	while($N > 0)
	{
			# Generate a new set of normally dist. random numbers.
			# Use the Box–Muller transform which gives two normally dist. numbers.
			my $radius = sqrt(-2.0*log($main::PG_random_generator->random(0.0,1.0,0.0))); #sqrt(-2.0*log(rand(1.0)));
			my $angle  = 2.0*$pi*$main::PG_random_generator->random(0.0,1.0,0.0); #2.0*PI*rand(1.0);
			my @r = (significant_decimals($mean+$sd*$radius*CORE::sin($angle),$digits),
							 significant_decimals($mean+$sd*$radius*CORE::cos($angle),$digits));

			if($N > 1)
			{
					# Add both numbers to the list.
					$N -= 2;
					push(@numbers,@r);
			}
			else
			{
					# Only add one of the numbers to the list.
					$N -= 1;
					push(@numbers,$r[0]);
			}
	}
	
	return @numbers;
}


=head3 Function to generate exponentially distributed random numbers

=pod

	Usage: exprand(lambda,N,digits)

Generates N normally exponentially distributed random numbers with the given parameter, lambda. The digits is the number of decimal digits to use.

=cut

sub exprand { # generate exponentially dist. numbers  Exp(x,lambda)
# exprand(lambda,N,digits)
# Generates N random numbers. The distribution is exponetially
# distributed with parameter lambda.  The value of 'digits' gives the
# number of decimal places to return.
	my ($lambda,$N,$digits) = @_;
	if ($lambda<=0) {
		die "Invalid parameter lambda: $lambda\n"; # must be a positive number
	}
	if ($N<=0) {
		die "Invalid N: $N\n"; # Cannot generate negative or zero numbers.
	}

	my @numbers = ();
	while($N > 0)
	{
			# Generate an exponentially dist. random number.
			$N -= 1;
			push(@numbers,significant_decimals(-log($main::PG_random_generator->random(0.0,1.0,0.0))/$lambda,$digits));
	}
	
	return @numbers;

}



=head3 Five Point Summary function

=pod

	Usage: five_point_summary(@data);
  or:    five_point_summary(@data,{method=>'includeMedian'});
  or:    five_point_summary(@data,{method=>'proper'});

Computes the five point summary of a list of numbers, data. You may
also pass the numbers individually.  The optional parameter can be
used to specify that the median be included in the calculation of the
quartiles if it is in the data set or whether proper proportions
should be used to calculate the quartiles.

=cut

sub five_point_summary {
	# Get the data that is passed to me and put it all in one array.
	my (@data_list) = @_;

  # Need to check to see if an hash of options was passed in the last argument.
	my $args = $data_list[$#data_list];
	if(ref($args) eq HASH)
	{
			# An hash was passed that presumably has some options. Remove it from the array.
			pop(@data_list);
	}
	else
	{
			# Set the $args to a pointer to the default hash.
			$args = {'method' => 'simple'};
	}


	# Sort the data and get the number of data points.
	@data_list = num_sort(@data_list);
	my $number = 1+$#data_list;
	if($number == 0)
	{
			die "Cannot find five point summary of empty data set.";
	}

	# Allocate the variables and set the min and the max values
	my $min = $data_list[0];
	my $q1;
	my $med;
	my $q3;
	my $max = $data_list[$number-1];

	if($args->{method} eq 'proper')
	{
			# Find the five point summary using more strict rules.
			# The calculation for the quartiles depends on the number of items in the list.
			if($number%2 == 0)
			{
					# There is an even number of points. Take the sample mean of the
					# two central points for the median.
					$med = 0.5*($data_list[$number/2-1]+$data_list[$number/2]);
					if($number%4 == 0)
					{
							# The lower and upper halves have an even number of points in them.
							$q1 = 0.25*$data_list[$number/4-1]  +0.75*$data_list[$number/4];
							$q3 = 0.75*$data_list[3*$number/4-1]+0.25*$data_list[3*$number/4];
					}
					else
					{
							# The lower and upper halves have an off number of points in them.
							$q1 = 0.75*$data_list[$number/4]  +0.25*$data_list[$number/4+1];
							$q3 = 0.25*$data_list[3*$number/4-1]+0.75*$data_list[3*$number/4];
					}
			}
			else
			{
					# There is an odd number of points. Just use the middle number
					# for the median.
					$med = $data_list[$number/2];
					if(($number-1)%4 == 0)
					{
							# The lower and upper halves have an even number of points in them.
							$q1 = $data_list[($number-1)/4];
							$q3 = $data_list[3*($number-1)/4];
					}
					else
					{
              # The lower and upper halves have an off number of points in them.
							$q1 = 0.5*$data_list[($number-1)/4]  +0.5*$data_list[($number-1)/4+1];
							$q3 = 0.5*$data_list[3*($number-1)/4]+0.5*$data_list[3*($number-1)/4+1];
					}

			}
	} # if($args->{method} eq 'proper')


	elsif ($args->{method} eq 'includeMedian') 
	{
			# Find the five point summary using the simplest rules. Here we
			# do use the median when calculating the quartiles.

			# The calculation for the quartiles depends on the number of items in the list.
			if($number%2 == 0)
			{
					# There is an even number of points. Take the sample mean of the
					#two central points for the median.
					$med = 0.5*($data_list[$number/2-1]+$data_list[$number/2]);
					if($number%4 == 0)
					{
							# The lower and upper halves have an even number of points in them.
							$q1 = 0.5*$data_list[$number/4-1]   + 0.5*$data_list[$number/4];
							$q3 = 0.5*$data_list[3*$number/4-1] + 0.5*$data_list[3*$number/4];
					}
					else
					{
							# The lower and upper halves have an off number of points in them.
							$q1 = $data_list[$number/4];
							$q3 = $data_list[3*$number/4];
					}
			}
			else
			{
					#There is an odd number of points. Just use the middle number
					#for the median.
					$med = $data_list[$number/2];
					if(($number-1)%4 == 0)
					{
              # The lower and upper halves have an even number of points in them.
							$q1 = $data_list[($number-1)/4];
							$q3 = $data_list[3*($number-1)/4];
					}
					else
					{
							# The lower and upper halves have an off number of points in them.
							$q1 = 0.5*$data_list[($number-1)/4]  +0.5*$data_list[($number-1)/4+1];
							$q3 = 0.5*$data_list[3*($number-1)/4]+0.5*$data_list[3*($number-1)/4+1];
					}
			}

	} # 


	else 
	{
			# Find the five point summary using the simplest rules. Here we
			# do not use the median when calculating the quartiles.

			# The calculation for the quartiles depends on the number of items in the list.
			if($number%2 == 0)
			{
					# There is an even number of points. Take the sample mean of the
					#two central points for the median.
					$med = 0.5*($data_list[$number/2-1]+$data_list[$number/2]);
					if($number%4 == 0)
					{
							# The lower and upper halves have an even number of points in them.
							$q1 = 0.5*$data_list[$number/4-1]   + 0.5*$data_list[$number/4];
							$q3 = 0.5*$data_list[3*$number/4-1] + 0.5*$data_list[3*$number/4];
					}
					else
					{
							# The lower and upper halves have an off number of points in them.
							$q1 = $data_list[$number/4];
							$q3 = $data_list[3*$number/4];
					}
			}
			else
			{
					#There is an odd number of points. Just use the middle number
					#for the median.
					$med = $data_list[$number/2];
					if(($number-1)%4 == 0)
					{
              # The lower and upper halves have an even number of points in them.
							$q1 = 0.5*$data_list[($number-1)/4-1]+0.5*$data_list[($number-1)/4];
							$q3 = 0.5*$data_list[3*($number-1)/4]+0.5*$data_list[3*($number-1)/4+1];
					}
					else
					{
							# The lower and upper halves have an off number of points in them.
							$q1 = $data_list[($number-1)/4];
							$q3 = $data_list[3*($number-1)/4+1];
					}
			}

	} # else

	return(($min,$q1,$med,$q3,$max));
	
}


##########################################

1;

