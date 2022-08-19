#!/usr/bin/env perl

=head1 TolType context

Test MathObjects tolerances.

=cut

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

loadMacros('PGstandard.pl', 'MathObjects.pl');

my $ctx = Context('Numeric');
my $pi  = Real('pi');

subtest 'set tolTrunction to 1' => sub {
	$ctx->flags->set(tolType => 'digits', tolerance => 3, tolTruncation => 1);

	is check_score($pi, Compute('3.14')),  1, 'toltype digits: pi is 3.14';
	is check_score($pi, Compute('3.141')), 1, 'toltype digits: pi is 3.141';
	is check_score($pi, Compute('3.142')), 1, 'toltype digits: pi is 3.142';
	is check_score($pi, Compute('3.143')), 0, 'toltype digits: pi is not 3.143';
	is check_score($pi, Compute('3.15')),  0, 'toltype digits: pi is not 3.15';
};

subtest 'set tolTrunction to 0' => sub {
	$ctx->flags->set(tolType => 'digits', tolerance => 3, tolTruncation => 0);

	is check_score($pi, Compute('3.14')),  1, 'toltype digits: pi is 3.14';
	is check_score($pi, Compute('3.141')), 0, 'toltype digits: pi is not 3.141';
	is check_score($pi, Compute('3.142')), 1, 'toltype digits: pi is not 3.142';
	is check_score($pi, Compute('3.143')), 0, 'toltype digits: pi is not 3.143';
	is check_score($pi, Compute('3.15')),  0, 'toltype digits: pi is not 3.15';
};

subtest 'set tolExtraDigits to 2' => sub {
	$ctx->flags->set(
		tolType        => 'digits',
		tolerance      => 3,
		tolTruncation  => 0,
		tolExtraDigits => 2
	);

	is check_score($pi, Compute('3.14')),  1, 'toltype digits: pi is 3.14';
	is check_score($pi, Compute('3.141')), 0, 'toltype digits: pi is not 3.141';
	is check_score($pi, Compute('3.142')), 1, 'toltype digits: pi is not 3.142';
	is check_score($pi, Compute('3.143')), 0, 'toltype digits: pi is not 3.143';
	is check_score($pi, Compute('3.15')),  0, 'toltype digits: pi is not 3.15';

	is check_score($pi, Compute('3.1416')),    1, 'toltype digits: pi is 3.1416';
	is check_score($pi, Compute('3.1415888')), 1, 'toltype digits: pi is 3.1415888';
	is check_score($pi, Compute('3.1415')),    0, 'toltype digits: pi is not 3.1415';
};

done_testing();
