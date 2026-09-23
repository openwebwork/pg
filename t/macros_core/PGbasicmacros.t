#!/usr/bin/env perl

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

use HTML::Entities;
use HTML::TagParser;

subtest 'named answer rules' => sub {
	my $name = NEW_ANS_NAME();
	my $html = HTML::TagParser->new(NAMED_ANS_RULE($name));

	my @inputs = $html->getElementsByTagName('input');
	is($inputs[0]->attributes->{id},   $name,  'test NAMED_ANS_RULE id attribute');
	is($inputs[0]->attributes->{name}, $name,  'test NAMED_ANS_RULE name attribute');
	is($inputs[0]->attributes->{type}, 'text', 'test NAMED_ANS_RULE type attribute');
	ok(!$inputs[0]->attributes->{value}, 'test NAMED_ANS_RULE value attribute');

	is($inputs[1]->attributes->{name}, "previous&#95;$name", 'test NAMED_ANS_RULE hidden name attribute');
	is($inputs[1]->attributes->{type}, 'hidden',             'test NAMED_ANS_RULE hidden type attribute');
};

subtest 'SRAND and random' => sub {
	SRAND(1234);
	is [ map { random(1, 10) } 1 .. 5 ], [ 7, 1, 3, 3, 9 ],
		'random delegates to the PG_random_generator seeded by SRAND';

	SRAND(1234);
	is random(1, 10), 7, 'SRAND reseeds the generator so the sequence repeats';
};

subtest 'non_zero_random' => sub {
	SRAND(1234);
	is non_zero_random(-2, 2, 1), 1, 'non_zero_random returns the first non-zero value random would give';

	my @results = map  { non_zero_random(-1, 1, 1) } 1 .. 200;
	my @zeros   = grep { $_ == 0 } @results;
	is \@zeros, [], 'non_zero_random never returns 0 when a non-zero value is reachable';

	my $calls_before = $main::PG_random_generator->{number_of_calls};
	is non_zero_random(0, 0), 0, 'non_zero_random gives up and returns 0 when only 0 is reachable';
	is $main::PG_random_generator->{number_of_calls} - $calls_before, 100,
		'non_zero_random makes exactly 100 attempts before giving up';
};

subtest 'list_random' => sub {
	SRAND(1234);
	is list_random(qw(a b c d e)), 'd', 'list_random picks the element chosen by random(1, scalar(@list))';

	is list_random('only'), 'only', 'list_random with a single element always returns that element';

	my %seen = map { $_ => 1 } map { list_random(1 .. 5) } 1 .. 200;
	is [ sort keys %seen ], [ 1 .. 5 ], 'list_random can return any element of the list';
};

done_testing();
