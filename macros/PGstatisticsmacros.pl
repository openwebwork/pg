

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

##########################################

1;

