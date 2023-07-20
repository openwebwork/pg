#!/usr/bin/env perl

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
use lib "$ENV{PG_ROOT}/lib";

use Test2::V0;

use WeBWorK::PG;

my $source = << 'END_SOURCE';
DOCUMENT();

loadMacros('PGstandard.pl', 'MathObjects.pl', 'PGML.pl', 'PGcourse.pl');

$pi = Real('pi');

BEGIN_PGML
Enter a value for [`\pi`].

[_____]{$pi}
END_PGML

ENDDOCUMENT();
END_SOURCE

ok my $pg = WeBWorK::PG->new(r_source => \$source, problemSeed => 1234, processAnswers => 1), 'source string renders';

my $correct_answers =
	{ map { $_ => $pg->{answers}{$_}{correct_ans} } @{ $pg->{translator}{PG_FLAGS_REF}{ANSWER_ENTRY_ORDER} } };

ok my $pg2 = WeBWorK::PG->new(
	r_source       => \$source,
	processAnswers => 1,
	inputs_ref     => $correct_answers
	),
	'source string renders with answers passed';

is($pg2->{result}{score}, 1, 'correct answer is correct');

done_testing;
