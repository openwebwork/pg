#!/usr/bin/env perl

=head1 contextTrigDegrees

Test computations in the TrigDegrees context.

=cut

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

loadMacros('contextTrigDegrees.pl');

my $ctx = Context('TrigDegrees');

ok(Value::isContext($ctx), 'trig degrees: check context');

ok my $cos60      = Compute('cos(60)'),           'Call Compute';
ok my $eval_cos60 = $cos60->cmp->evaluate('1/2'), 'evalute an answer to cos(60)';

is $eval_cos60, hash {
	field type          => 'Value (Real)';
	field score         => 1;
	field correct_ans   => 'cos(60)';
	field student_ans   => 0.5;
	field error_flag    => U();
	field error_message => DF();
	etc();
}, q{What does the Compute('cos(60)')->cmp->evaluate('1/2') object look like?};

is(check_score($cos60,             '1/2'),     1, 'trig degrees: cos(60) = 1/2');
is(check_score(Compute('cos(60)'), 'sin(30)'), 1, 'trig degrees: cos(60) = 1/2');
is check_score(Compute('sin(0)'),  '0'),          1, 'trig degrees: sin(0) = 0';
is check_score(Compute('sin(90)'), '1'),          1, 'trig degrees: sin(90) = 1';
is check_score(Compute('cos(0)'),  '1'),          1, 'trig degrees: cos(0) = 1';
is check_score(Compute('cos(90)'), '0'),          1, 'trig degrees: cos(90) = 0';
is check_score(Compute('cos(90)'), '1.6155E-15'), 1, 'trig degrees: cos(90) ~ 0';

is check_score(Compute("cos($main::PI/3)"), "sin($main::PI/6)"), 0, 'trig degrees: cos(pi/3) != sin(pi/6)';

done_testing();
