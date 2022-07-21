use Test2::V0;

use lib 't/lib';
use Test::PG;

# remove warnings about redefining trig functions
delete $main::{sin};
delete $main::{cos};
delete $main::{atan2};


=head2 Errors to be fixed

There is something wrong with either contextTrigDegrees.pl or how this test
sets up the context.  It looks like it still calculates in radians.
Maybe the problem is how it imports symbols?

When you fix it, the test output will report the test numbers after C<TODO passed:>

These are the same results as the original Test::More version with build_PG_env.pl

=cut


loadMacros("contextTrigDegrees.pl");

my $ctx = Context("TrigDegrees");

ok(Value::isContext($ctx), "trig degrees: check context");

ok my $cos60 = Compute("cos(60)"), 'Call Compute';
ok my $eval_cos60 = $cos60->cmp->evaluate("1/2"), 'evalute an answer to cos(60)';

is $eval_cos60,
    hash {
        field type          => 'Value (Real)';
        field score         => 0;
        field correct_ans   => "cos(60)";
        field student_ans   => 0.5;
        field error_flag    => U();
        field error_message => DF();
        etc();
    }, 'What does the Compute("cos(60)") object look like?';


# dd Compute("1/2")->value;
# is (check_score($cos60,"1/2"),1,"trig degrees: cos(60) = 1/2");

# dd $cos60->cmp->evaluate("1/2")->{type};
# dd $cos60->cmp->evaluate("1/2")->{score};
# dd $cos60->cmp->evaluate("1/2")->{correct_ans};
# dd $cos60->cmp->evaluate("1/2")->{student_ans};

# is (check_score(Compute("cos(60)"),"sin(30)"),1,"trig degrees: cos(60) = 1/2");

# simple sanity checking
is check_score( Compute('sin(0)'), '0'), 1, 'trig degrees: sin(0) = 0';
is check_score( Compute('sin(90)'), '1'), 1, 'trig degrees: sin(90) = 1';
is check_score( Compute('cos(0)'), '1'), 1, 'trig degrees: cos(0) = 1';

todo 'why is cos(90) not equal to 0' => sub {
	# are we still computing in radians?
	is check_score( Compute('cos(90)'), '0'), 1, 'trig degrees: cos(90) = 0';
	is check_score( Compute('cos(90)'), '1.6155E-15'), 1, 'trig degrees: cos(90) ~ 0';

	my $pi = 4 * atan2(1,1);
	is check_score( Compute("cos($pi/3)"), "sin($pi/6)"), 1, 'trig degrees: cos(60) = sin(30)';
};


done_testing();
