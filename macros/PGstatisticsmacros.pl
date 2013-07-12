

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

	$pi = 4.0*atan(1.0);
	my @numbers = ();
	while($N >= 0)
	{
			# Generate a new set of normally dist. random numbers.
			# Use the Box–Muller transform which gives two normally dist. numbers.
			my $radius = sqrt(-2.0*log($main::PG_random_generator->random(0.0,1.0,0.0)));
			my $angle  = 2.0*$pi*$main::PG_random_generator->random(0.0,1.0,0.0);
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

Generates N  exponentially distributed random numbers with the given parameter, lambda. The digits is the number of decimal digits to use.

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
	while($N >= 0)
	{
			# Generate an exponentially dist. random number.
			$N -= 1;
			push(@numbers,significant_decimals(-log($main::PG_random_generator->random(0.0,1.0,0.0))/$lambda,$digits));
	}
	
	return @numbers;

}


=head3 Function to generate Poisson distributed random numbers

=pod

	Usage: poissonrand(lambda,N)

Generates N Poisson distributed random numbers with the given parameter, lambda. 

=cut

sub poissonrand { # generate random, Poisson dist. numbers  Pois(lambda)
# poissonrand(lambda,N)
# Generates N random numbers. The distribution is Poisson with  parameter lambda.  

	my ($lambda,$N) = @_;
	if ($lambda<=0) {
		die "Invalid parameter lambda: $lambda\n"; # must be a positive number
	}
	if ($N<=0) {
		die "Invalid N: $N\n"; # Cannot generate negative or zero numbers.
	}

	#Initialize the array of numbers to return.
	my @numbers = ();
	my $poisFactor = exp(-$lambda);
	while($N >= 0)
	{
			# Generate an exponentially dist. random number.
			$N -= 1;
			my $cumProb = $main::PG_random_generator->random(0.0,1.0,0.0)/$poisFactor;  # The cumulative prob. 
			                                                                            # Need to find k to match this.
			my $k = 0;                         # The new, random number.
			my $currentProb = 1.0;             # P(x=k|lambda)
			my $trialCumProb = 1.0;            # The cumulative prob, P(x<=k|lambda)
			while($trialCumProb < $cumProb)
			{
					# Find the prob and update the cumulative prob. for the next value of k.
					# Stop when we exceed the target cumulative prob.
					$k++;
					$currentProb *= $lambda/$k;
					$trialCumProb += $currentProb;
			}
			push(@numbers,$k); # Add this number to the list!
	}
	
	return @numbers;

}



=head3 Function to generate Binomial distributed random numbers

=pod

	Usage: binomrand(p,N,num)

Generates num binomial distributed random numbers with  parameters p and N.

=cut

sub binomrand { # generate random, binomial dist. numbers  Bin(n,p)
# binomrand(p,N,num)
# Generates num random numbers. The distribution is binomial with parameters p and N.

	my ($p,$N,$num) = @_;
	if (($p<=0) || ($p>=1)) {
		die "Invalid parameter p: $p\n"; # must be a positive number strictly between zero and one
	}
	if ($N<=0) {
		die "Invalid N: $N\n"; # Cannot have zero or negative trials
	}
	if ($num<=0) {
		die "Invalid number: $num\n"; # Cannot generate negative or zero numbers.
	}


	my @numbers = ();
	while($num > 0)
	{
			# Generate an exponentially dist. random number.
			$num -= 1;
			my $cumProb = $main::PG_random_generator->random(0.0,1.0,0.0);  # The cumulative prob. 
			                                                                # Need to find k to match this.
			my $k;  # The new, random number.

			# Determine the prob. that X=0.
			my $currentProb = 1.0;
			for($k=0;$k<$N;++$k)
			{
					$currentProb *= (1.0-$p);
			}

			$k = 0;
			my $trialCumProb = $currentProb;
			while(($trialCumProb < $cumProb) && ($k <= $N))
			{
					# Find the prob and update the cumulative prob. for the next value of k.
					# Stop when we exceed the target cumulative prob.
					$currentProb *= ($N-$k)*$p/(($k+1)*(1.0-$p));
					$trialCumProb += $currentProb;
					$k++;
			}
			push(@numbers,$k);
	}
	
	return @numbers;

}



=head3 Chi Squared statistic for a two way table

=pod

	Usage: chisqrTable(@frequencies)

  Example:
		@row1 = (1,2,2,2);
    @row2 = (3,1,2,4);
    @row3 = (1,4,2,1);
    @row4 = (3,1,4,3);
    @row5 = (5,2,2,4);
    push(@table,~~@row1);
    push(@table,~~@row2);
    push(@table,~~@row3);
    push(@table,~~@row4);
    push(@table,~~@row5);
    ($chiSquared,$df) = chisqrTable(@table);

Computes the Chi Squared test statistic for a two way frequency table. Returns the test statistic and the number of degrees of freedom. The array used in the argument is a list of references to arrays that have the frequencies for each row. If one of the rows has a different number of entries than the others the routine will throw an error.

=cut

sub chisqrTable { # Given a two-way frequency table calculates the chi-squared test statistic
# chisqrTable(@frequencies)
# @frequencies is an array of pointers to arrays. Each array must have the same dimension.
#
# Returns an array: (chi square test statistic , number degrees of freedom)
#
# Example:
# my @row1 = (1,2,2,2);
# my @row2 = (3,1,2,4);
# my @row3 = (1,4,2,1);
# my @row4 = (3,1,4,3);
# my @row5 = (5,2,2,4);
# push(@table,~~@row1);
# push(@table,~~@row2);
# push(@table,~~@row3);
# push(@table,~~@row4);
# push(@table,~~@row5);


	my @table = @_;

	# Get the row and column totals
	my $columns = 'nd';
	my $rows;
	my @rowTotals = ();
	my @columnTotals = ();
	my $innerLupe;
	my $lupe;
	my $totalSum = 0;
	foreach $lupe (@table)
	{
			++$rows;
			my @row = @{$lupe};
			if($columns eq 'nd') 
			{ 
					# This is the first time through. Set the number of columns
					# and initialize the column totals with zeros.
					$columns = 1+$#row;
					for($innerLupe=0;$innerLupe<$columns;++$innerLupe)
					{
							push(@columnTotals,0);
					}
			}
			elsif ($columns != (1+$#row))
			{
					# This is not a rectangular array. Cannot proceed with this.
					die "The number of columns in row $rows is different from the previous rows.";
			}

			# Add up the totals for this row and each column.
			my $sum = 0;
			for($innerLupe=0;$innerLupe<$columns;++$innerLupe)
			{ 
					$sum += $row[$innerLupe];
					$columnTotals[$innerLupe] += $row[$innerLupe];
					$totalSum += $row[$innerLupe];
			}
			push(@rowTotals,$sum);
	}

	# calculate the idealized frequency table assuming independence.
	my $chiSquared = 0.0;   # The Chi Squared test statistic
	for($lupe=0;$lupe<$rows;++$lupe)
	{
			# Get the ideal row.
			my @currentRow = @{$table[$lupe]};
			for($innerLupe=0;$innerLupe<$columns;++$innerLupe)
			{
					my $expected = $columnTotals[$innerLupe]*$rowTotals[$lupe]/$totalSum;
					$chiSquared += ($currentRow[$innerLupe]-$expected)*(($currentRow[$innerLupe]-$expected))/$expected;
			}
	}

	($chiSquared,($rows-1)*($columns-1));
}


=head3 Calc the results of a t-test.

=pod

	Usage: ($t,$df,$p) = t_test(t_test(mu,@data);                       # Perform a two-sided t-test.
  or:    ($t,$df,$p) = t_test(t_test(mu,@data,{'test'=>'right'});     # Perform a right sided t-test 
  or:    ($t,$df,$p) = t_test(t_test(mu,@data,{'test'=>'left'});      # Perform a left sided t-test 
  or:    ($t,$df,$p) = t_test(t_test(mu,@data,{'test'=>'two-sided'}); # Perform a left sided t-test 

Computes the t-statistic, the number of degrees of freedom, and the
p-value after performing a t-test on the given data. the value of mu
is the assumed mean for the null hypothesis. The optional argument can
set whether or not a left, right, or two-sided test will be conducted.

=cut

sub t_test {
#	 Usage: ($t,$df,$p) = t_test(t_test(mu,@data);                       # Perform a two-sided t-test.
#  or:    ($t,$df,$p) = t_test(t_test(mu,@data,{'test'=>'right'});     # Perform a right sided t-test 
#  or:    ($t,$df,$p) = t_test(t_test(mu,@data,{'test'=>'left'});      # Perform a left sided t-test 
#  or:    ($t,$df,$p) = t_test(t_test(mu,@data,{'test'=>'two-sided'}); # Perform a left sided t-test 
#
# example:
#
# @data = (1,2,3,4,5,6,7);
# ($t,$df,$p) = t_test(2.5,@data,{'test'=>'right'});
#
		my $assumedMean = shift;
		my @data = @_;

		# Need to check to see if an hash of options was passed in the last argument.
		my $args = $data[$#data];
		if(ref($args) eq "HASH")
		{
				# An hash was passed that presumably has some options. Remove it from the array.
				pop(@data);
				if(!defined($args->{'test'}))
				{
						# The type of test was not defined.
						$args->{'test'} = 'two-sided';
				}

		}
		else
		{
				# Set the $args to a pointer to the default hash.
				$args = {'test' => 'two-sided'};
		}


		# Decide if there is any data
		my $N = 1+$#data;
		if($N <= 0) {die "No data has been passed to the t_test subroutine.";}

		# Determine the t-statistic.
		# First figure out the basic calcs required for the data.
		my $sumX = 0.0;
		my $sumX2 = 0.0;
		foreach my $x (@data)
		{
				$sumX  += $x;
				$sumX2 += $x*$x;
		}

		# Determine the t statistic and then calculate the p value.
		my $t = ($sumX-$assumedMean*$N)/sqrt(($sumX2*$N-$sumX*$sumX)/($N-1));
		my $p = 0.0;

		if($args->{test} eq 'left')
		{
				# This is a left sided test. Find the area to the left.
				$p = 1.0 - tprob($N-1,$t);
		}

		elsif($args->{test} eq 'right')
		{
				# This is a right sided test. Find the area to the left.
				$p = tprob($N-1,$t);
		}

		else
		{
				# This is a two sided test. Find the area to the left.
				$p = 2.0*tprob($N-1,abs($t));
		}

		($t,$N-1,$p);
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
	if(ref($args) eq "HASH")
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

	} # if ($args->{method} eq 'includeMedian') 


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



=head3 Function to calculate the Pearson's sample correlation

=pod

	Usage:  $cor = sample_correlation(~~@xData,~~@yData);

Calculates the Pearson's sample correlation for the given data. The
arguments are references to two arrays where each array contains the
associated data.

=cut

sub sample_correlation {
		my @xdata = @{shift @_};
		my @ydata = @{shift @_};

		# Decide if there is any data
		my $N = 1+$#xdata;
		if($N <= 0) {die "No data has been passed to the sample_correlation subroutine.";}
		if($N != 1+$#ydata) {die "The number of x data points is not the same as the number of y data points.";}

		# Determine the correlation.
		# First figure out the basic calculations (sums) required for the data.
		my $sumX = 0.0;
		my $sumX2 = 0.0;
		my $sumY = 0.0;
		my $sumY2 = 0.0;
		my $sumXY = 0.0;
		my $lupe;
		for($lupe=0;$lupe<$N;++$lupe)
		{
				$sumX  += $xdata[$lupe];
				$sumX2 += $xdata[$lupe]*$xdata[$lupe];
				$sumY  += $ydata[$lupe];
				$sumY2 += $ydata[$lupe]*$ydata[$lupe];
				$sumXY += $xdata[$lupe]*$ydata[$lupe];
		}
		# Pass back the Pearson's sample data
		(($N*$sumXY-$sumX*$sumY)/sqrt(($N*$sumX2-$sumX*$sumX)*($N*$sumY2-$sumY*$sumY)));
}


=head3 Function to calculate the frequencies for the factors in a given data set.

=pod

	Usage:  %freq = frequencies(@theData)

Finds the factors in the data set and calculates the frequency of occurance for each factor. Returns a hash whose keys ar the factors and the associated values are the frequencies.

=cut

sub frequencies {
#   %freq = frequencies(@theData)
#   returns a hash whos keys are the factors and the associated values are the frequencies.

	# Get the data that is passed to me and put it all in one array.
	my (@data_list) = @_;
	my %frequency;

	foreach my $value (@data_list)
	{
			if(defined($frequency{$value}))
			{
					$frequency{$value} += 1;
			}
			else
			{
					$frequency{$value} = 1;
			}
	}

	%frequency;
}


##########################################

1;

