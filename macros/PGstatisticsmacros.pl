
sub _PGstatisticsmacros_init {
		foreach my $t (@Distributions::EXPORT_OK) {
				*{$t} = *{"Distributions::$t"}
		}
		foreach my $t (@Regression::EXPORT_OK) {
				*{$t} = *{"Regression::$t"}
		}
		foreach my $t (@Statistics::EXPORT_OK) {
				*{$t} = *{"Statistics::$t"}
		}
}

=head1 Statistics Macros

=head3 Normal distribution

=pod

	Usage: normal_prob(a, b, mean=>0, deviation=>1);

Computes the probability of x being in the interval (a,b) for normal distribution.
The first two arguments are required. Use '-infty' for negative infinity, and 'infty' or '+infty' for positive infinity.
The mean and deviation are optional, and are 0 and 1 respectively by default.

=cut

sub normal_prob {
	my $a = shift;
	my $b = shift;
 	my %options=@_;

	my $mean = $options{'mean'} // 0;
	my $deviation = $options{'deviation'} // 1;

	if ( $deviation <= 0 ) {
		warn 'Deviation must be a positive number.';
		return;
	}

	my $prob;
	if ( $a =~ /^-(?:inf|infty|infinity)$/i ) {
		if ( $b =~ /^[+-]?(?:inf|infty|infinity)$/i ) {
			$prob = ($b =~ /-/) ? 0 : 1; # did you really need us to tell you that?
		} else {
			my $z_score_of_b = ( $b - $mean ) / $deviation;
			$prob = 1 - uprob($z_score_of_b);
		}
	} elsif ( $a =~ /^\+?(?:inf|infty|infinity)$/i ) {
		if ( $b =~ /^\+?(?:inf|infty|infinity)$/i ) {
			$prob = 0;
		} else {
			warn 'normal_prob requires a <= b, please check your inputs.';
			return;
		}
	} else {
		my $z_score_of_a = ( $a - $mean ) / $deviation;
		if ( $b =~ /^\+?(?:inf|infty|infinity)$/i ) {
			$prob = uprob($z_score_of_a);
		} elsif ( $b =~ /^-(?:inf|infty|infinity)$/i || $a >= $b ) {
			warn 'normal_prob requires a <= b, please check your inputs.';
			return;
		} else {
            my $z_score_of_b = ( $b - $mean ) / $deviation;
			$prob = uprob($z_score_of_a) - uprob($z_score_of_b);
		}
	}

	return $prob;
}

=head3 "Inverse" of normal distribution

=pod

	Usage: normal_distr(prob, mean=>0, deviation=>1);

Computes the positive number b such that the probability of x being in the interval (0,b)
is equal to the given probability (first argument). The mean and deviation are
optional, and are 0 and 1 respectively by default.
Caution: since students may use tables, they may only be able to provide the answer correct to 2 or 3
decimal places. Use tolerance when evaluating answers.

=cut

sub normal_distr {

	my $prob = shift;
	my %options=@_;

	my $mean      = $options{'mean'}      // 0;
	my $deviation = $options{'deviation'} // 1;

	if ($deviation <= 0) {
		warn 'Deviation must be a positive number.';
		return;
	}
	if ($prob < 0 || $prob >= 0.5) {
		warn 'Probability must be non-negative and strictly less than 0.5';
		return;
	}

	$prob = 0.5 - $prob;
	my $z_score_of_b = udistr($prob);

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


	#Not using mean for computation saving.
	#Using the standard computational formula for variance ( sum(x^2) - (sum(x))^2)/(n-1)
	
	my ($sum_x,$sum_squares) = stats_SX_SXX(@data_list);
	my $n = @data_list;
	return( sqrt( ($sum_squares - $sum_x*$sum_x/$n)/($n - 1 ) ) );
	
}


=head3 Sum and Sum of Squares

=pod

	Usage: stats_SX_SXX(@data);

Computes the sum of the numbers and the sum of the numbers squared.

=cut

sub stats_SX_SXX {
		my @data_list = @_;

		# Initialize the two sums.
		my $sum_x       = 0;
		my $sum_squares = 0;
		foreach my $x (@data_list) {
				# Add the values for each number in the list.
				$sum_x       = $sum_x + $x;
				$sum_squares = $sum_squares + $x*$x;
		}
		($sum_x,$sum_squares);
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

	my $pi = 4.0*atan(1.0);
	my @numbers = ();
	while($N > 0)
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
	while($N > 0)
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
	while($N > 0)
	{
			# Generate an Poisson dist. random number.
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
			# Generate an binomially dist. random number.
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


=head3 Function to generate Bernoulli distributed random numbers

=pod

	Usage: bernoullirand(p,num,{"success"=>"1","failure"=>"0"})

Generates num Bernoulli distributed random numbers with  parameter p. The 
value for a success is given by the optional "success" parameter. The 
value for a failure is given by the optional "failure" parameter.

=cut

sub bernoullirand { # generate random, Bernoulli dist. numbers  B(p)
# bernoullirand(p,num,{"success"=>"1","failure"=>"0"})
# Generates num random numbers. The distribution is Bernoulli with parameter p.

        my $p = shift;
        my $num = shift;
        my $options = shift;

	if (($p<=0) || ($p>=1)) {
		die "Invalid parameter p: $p\n"; # must be a positive number strictly between zero and one
	}
	if ($num<=0) {
		die "Invalid number: $num\n"; # Cannot generate negative or zero numbers.
	}

        if(!defined($options))
        {
            # Define the default value for the options
            $options = {"success"=>"1","failure"=>"0"}
        }
        else
        {
            if (!defined($options->{'success'})) 
                {
                    # Define the default value for a success
                    $options->{'success'} = 1;
                }
            if (!defined($options->{'failure'}))
                {
                    # Define the default value for a failure
                    $options->{'failure'} = 0;
                }
        }

	my @numbers = ();
	while($num > 0)
	{
			# Generate a Bernoulli dist. random number.
			$num -= 1;
			if($main::PG_random_generator->random(0.0,1.0,0.0) <= $p)
			{
					# This is a success!
					push(@numbers,$options->{'success'});
			}
			else
			{
					# This is a failure. :-(
					push(@numbers,$options->{'failure'});
			}

	}
	
	return @numbers;

}


=head3 Generate random values from a discrete distribution.

=pod

	Usage: discreterand($n,@tableOfProbabilities)


  Example:

my $total = 10;
my @probabilities = ( [0.1,"A"],
                      [0.4,"B"],
                      [0.3,"C"],
                      [0.2,"D"]);

@result = discreterand($total,@probabilities);
$data = '';
foreach $lupe (@result)
{
    $data .= $lupe . ", ";
}
$data =~ s/,$//;

This routine will generate num random results. The distribution is in
the given array.  Each element in the array is itself an array.  The
first value in the array is the probability.  The second value in the
array is the value assocated with the probability.


=cut


sub discreterand { # generate random, values based on a given table
# discreterand($n,@tableOfProbabilities)
# Generates num random results. The distribution is in the given array.
# Each element in the array is itself an array. 
# The first value in the array is the probability. 
# The second value in the array is the value assocated with the probability.

    my $num = shift;  # Number of values to generate
    my @table = @_;   # Table of arrays with the probabilities and values.

    my @result = ();  # Values to return.
    my $lupe;
    while($num > 0)
    {
        # For each value generate a random variable.

        my $p = $main::PG_random_generator->random(0.0,1.0,0.0);
        my $accum = 0.0;
        foreach $lupe (@table)
        {
            # Find the cumulative dist. and stop when the prob. goes
            # over the cumulative dist.
            $accum += $$lupe[0];
            if($accum > $p)
            {
                # This one matches. Add it to the list to return.
                push(@result,$$lupe[1]);
                $p = -1.0;
                last;
            }
        }

        if($p > 0.0)
        {
            # Something bad happened. Most likely is that the table
            # that was passed was not a valid prob. dist. Just return
            # the last value in the list.
            push(@result,$table[-1][1]);
        }


        $num -= 1;
    }

    #print(@result);
    @result;
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
#	 Usage: ($t,$df,$p) = t_test(mu,@data);                       # Perform a two-sided t-test.
#  or:    ($t,$df,$p) = t_test(mu,@data,{'test'=>'right'});     # Perform a right sided t-test 
#  or:    ($t,$df,$p) = t_test(mu,@data,{'test'=>'left'});      # Perform a left sided t-test 
#  or:    ($t,$df,$p) = t_test(mu,@data,{'test'=>'two-sided'}); # Perform a left sided t-test 
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


=head3 Calc the results of a two sample t-test.

=pod

	Usage: ($t,$df,$p) = two_sample_t_test(\@data1,\@data2);                       # Perform a two-sided t-test.
  or:    ($t,$df,$p) = two_sample_t_test(\@data1,\@data2,{'test'=>'right'});     # Perform a right sided t-test 
  or:    ($t,$df,$p) = two_sample_t_test(\@data1,\@data2,{'test'=>'left'});      # Perform a left sided t-test 
  or:    ($t,$df,$p) = two_sample_t_test(\@data1,\@data2,{'test'=>'two-sided'}); # Perform a left sided t-test 

Computes the t-statistic, the number of degrees of freedom, and the
p-value after performing a two sample t-test on the given data.  The
test is whether or not the means are the same. The optional argument
can set whether or not a left, right, or two-sided test will be
conducted.

=cut

sub two_sample_t_test {
#	 Usage: ($t,$df,$p) = two_sample_t_test(\@data1,\@data2);                       # Perform a two-sided t-test using a pooled variance.
#  or:    ($t,$df,$p) = two_sample_t_test(\@data1,\@data2,{'test'=>'right','variance'=>'pooled});     # Perform a right sided t-test using a pooled variance
#  or:    ($t,$df,$p) = two_sample_t_test(\@data1,\@data2,{'test'=>'left','variance'=>'separate'});      # Perform a left sided t-test using a separate variance
#  or:    ($t,$df,$p) = two_sample_t_test(\@data1,\@data2,{'test'=>'two-sided','variance'=>'pooled}); # Perform a left sided t-test using a pooled variance
#
# example:
#
# @data1 = (1,2,3,4,5,6,7);
# @data2 = (2,3,4,5,6,7,9);
# ($t,$df,$p) = two_sample_t_test(2.5,\@data1,\@data2,{'test'=>'right','variance'=>'pooled});
#
		my @data1 = @{shift @_};
		my @data2 = @{shift @_};

		# Need to check to see if an hash of options was passed in the last argument.
		my %args;
		if(@_)
		{
				%args = %{shift @_};
				if(!defined($args{'test'}))
				{
						# The type of test was not defined.
						$args{'test'} = 'two-sided';
				}

				if(!defined($args{'variance'}))
				{
						# The type of test was not defined.
						$args{'variance'} = 'pooled';
				}

		}
		else
		{
				# Set the $args to a pointer to the default hash.
				$args{'test'} = 'two-sided';
				$args{'variance'} = 'pooled';
		}


		# Get the sums of the values and squares for both data sets.
		my ($sum_x,$sum_squares_x) = stats_SX_SXX(@data1);
		my ($sum_y,$sum_squares_y) = stats_SX_SXX(@data2);
		my $nx = 1+$#data1;
		my $ny = 1+$#data2;
		my $df = $nx+$ny-2;


		# Make a quick sanity check to see if there is any data
		if(($nx <= 0)||($ny <= 0)) {die "No data has been passed to the two_sample_t_test subroutine.";}


		# Determine the t statistic and then calculate the p value.
		my $t;
		my $p = 0.0;


		if($args{'variance'} eq "separate")
		{
				# Use the separate variance formula to calculate the t statistic
				$t = ($sum_x/$nx - $sum_y/$ny)/sqrt( ($sum_squares_x-$sum_x*$sum_x/$nx)/($nx*($nx-1.0)) + 
																						 ($sum_squares_y-$sum_y*$sum_y/$ny)/($ny*($ny-1.0)));
		}
		else
		{
				# Use the pooled variance formula to calculate the t statistic
				$t = ($sum_x/$nx - $sum_y/$ny)/sqrt( ($sum_squares_x-$sum_x*$sum_x/$nx + 
																							$sum_squares_y-$sum_y*$sum_y/$ny)/
																						 ($nx+$ny-2.0)*(1.0/$nx+1.0/$ny));
		}



		if($args{test} eq 'left')
		{
				# This is a left sided test. Find the area to the left.
				$p = 1.0 - tprob($df,$t);
		}

		elsif($args{test} eq 'right')
		{
				# This is a right sided test. Find the area to the left.
				$p = tprob($df,$t);
		}

		else
		{
				# This is a two sided test. Find the area to the left.
				$p = 2.0*tprob($df,abs($t));
		}

		($t,$df,$p);
}


=head3 Create a data file and make a link to it.

=pod

	Usage: insertDataLink($PG,linkText,@dataRefs)

Writes the given data to a file and creates a link to the data file. The string headerTitle is the label used in the anchor link. 
		$PG is a ref to an instance of a PGcore object. (Generally just use $PG in a problem)
    linkText is the text to appear in the anchor/link.
    @dataRefs is a list of references. Each reference is assumed to be ref to an array.
          All of the arrays must have the same length.
          The last entry in the array is assumed to be the label to use in the first row of the csv file.

Usage:
    # Generate random data
    @data1 = urand(10.0,2.0,10,2);
    @data2 = urand(12.0,2.0,10,2);
    @data3 = urand(14.0,4.0,10,2);
    @data4 = exprand(0.1,10,2);

    # Append the labels for each data set
    push(@data1,"w");
    push(@data2,"x");
    push(@data3,"y");
    push(@data4,"z");

    BEGIN_TEXT

    blah blah

    $BR Data: \{ insertDataLink($PG,"the data",(~~@data1,~~@data2,~~@data3,~~@data4)); \} $BR


=cut

sub insertDataLink {
		my $PG          = shift;
		my $linkText    = shift;
		my @dataRefs    = @_;
		my $stat = Statistics->new($PG);


		# Create a file name and get the url as well.
		my ($fileName,$url) = $stat->make_csv_alias(
				$main::studentLogin,$main::problemSeed,$setName,$main::probNum);

		# Now write the data
		$stat->write_array_to_CSV($fileName,@dataRefs);

		"<a href=\"$url\">$linkText</a>";
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
		my $sumX  = 0.0;
		my $sumX2 = 0.0;
		my $sumY  = 0.0;
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


=head3 Function to calculate the linear least squares estimate for the linear relationship between two data sets

=pod

	Usage:  ($slope,$intercept,$var,$SXX) = linear_regression(~~@xdata,~~@ydata);

Give the x data in @xdata and the t data in @ydata the least squares
regression line is calculated. It also returns the variance in the
residuals as well as SXX, the sum of the squares of the deviations for
the x values. This is done to make it easier to perform calculations
on the slope parameter such as the confidence interval or perform
inference procedures.

Example:
 @xdata = (-1,2,3,4,5,6,7);
 @ydata = (6,5,6,7,8,9,11);
 ($slope,$intercept,$var,$SXX) = linear_regression(~~@xdata,~~@ydata);


=cut

sub linear_regression {
		my @xdata = @{shift @_};
		my @ydata = @{shift @_};

		# Decide if there is any data
		my $N = 1+$#xdata;
		if($N <= 0) {die "No data has been passed to the linear regression subroutine.";}
		if($N != 1+$#ydata) {die "The number of x data points is not the same as the number of y data points.";}

		# Determine the correlation.
		# First figure out the basic calculations (sums) required for the data.
		my $sumX  = 0.0;
		my $sumX2 = 0.0;
		my $sumY  = 0.0;
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

		# Now calculate the required quantities based on the sums.
		my $SXX       = ($sumX2-$sumX*$sumX/$N);
		my $slope     = ($sumXY-$sumX*$sumY/$N)/$SXX;
		my $intercept = ($sumY-$slope*$sumX)/$N;
		my $var       = ($sumY2-$intercept*$sumY-$slope*$sumXY)/($N-2);
		($slope,$intercept,$var,$SXX);
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

