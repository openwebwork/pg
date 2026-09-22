#!/usr/bin/env perl

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
use lib "$ENV{PG_ROOT}/lib";

use PGrandom;

subtest 'mod' => sub {
	is PGrandom::mod( 10,       3),      1, 'positive dividend less than one multiple of the modulus';
	is PGrandom::mod( 9,        3),      0, 'an exact multiple of the modulus';
	is PGrandom::mod(-5,        3),     -2, 'a negative dividend truncates towards zero like the LCG expects';
	is PGrandom::mod(2**33 + 5, 2**32),  5, 'works for numbers too large for the % operator';
};

subtest 'new' => sub {
	my $default = PGrandom->new;
	is $default->{original_seed},   1, 'the seed defaults to 1 when none is given';
	is $default->{number_of_calls}, 1, 'constructing the generator counts as its first call';

	my $r = PGrandom->new(1234);
	is $r->{original_seed}, 1234,     'the original seed passed in is retained';
	is $r->{seed},          85231147, 'the internal seed is advanced once by the LCG on construction';
};

subtest 'random' => sub {
	my $r = PGrandom->new(1234);

	is [ map { $r->random(1, 10) } 1 .. 5 ], [ 7, 1, 3, 3, 9 ], 'reproducible sequence for a fixed seed';
	is $r->{number_of_calls},                6,                 'every call to random increments number_of_calls';

	my @out_of_range = grep { $_ < 1 || $_ > 10 } map { $r->random(1, 10) } 1 .. 500;
	is \@out_of_range, [], 'values are always within the requested inclusive range';

	my $r2      = PGrandom->new(99);
	my @stepped = map { $r2->random(0, 20, 5) } 1 .. 10;
	is \@stepped, [ 20, 15, 0, 15, 15, 0, 0, 15, 20, 0 ],
		'stepping by incr only returns multiples of incr from begin';

	for my $incr (0, -1) {
		my $r3 = PGrandom->new(99);
		is [ map { $r3->random(0, 1, $incr) } 1 .. 5 ],
			[ 0.961772898444906, 0.692322691436857, 0.035974852507934, 0.747087870724499, 0.612143070669845 ],
			"incr <= 0 (incr=$incr) gives a continuous distribution instead of stepping";
	}
};

subtest 'rand' => sub {
	my $r = PGrandom->new(99);
	is [ map { $r->rand } 1 .. 5 ],
		[ 0.961772898444906, 0.692322691436857, 0.035974852507934, 0.747087870724499, 0.612143070669845 ],
		'rand() with no argument is equivalent to a continuous random(0, 1, 0)';

	my $r2 = PGrandom->new(99);
	is [ map { $r2->rand(10) } 1 .. 5 ],
		[ 9.61772898444906, 6.92322691436857, 0.35974852507934, 7.47087870724499, 6.12143070669845 ],
		'rand($end) is equivalent to a continuous random(0, $end, 0)';
};

subtest 'srand' => sub {
	my $r = PGrandom->new(1234);
	$r->random(1, 10) for 1 .. 10;

	$r->srand(5678);
	is $r->{original_seed},   5678, 'srand updates the stored original seed';
	is $r->{number_of_calls}, 1,    'srand resets the call counter';

	my $fresh = PGrandom->new(5678);
	is $r->{seed},        $fresh->{seed},        'srand puts the generator into the same state as new() with that seed';
	is $r->random(1, 10), $fresh->random(1, 10), 'the sequence after srand matches a freshly seeded generator';
};

subtest 'seed' => sub {
	my $r = PGrandom->new(1234);
	$r->seed(5678);

	my $fresh = PGrandom->new(5678);
	is $r->{seed},        $fresh->{seed},        'seed is a synonym for srand';
	is $r->random(1, 10), $fresh->random(1, 10), 'the sequence after seed matches a freshly seeded generator';
};

done_testing;
