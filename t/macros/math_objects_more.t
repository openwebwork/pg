#!/usr/bin/env perl

=head1 MathObjects

Test more MathObject properties and operations.

=cut

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

loadMacros('MathObjects.pl');

my $ctx = Context('Numeric');

ok(Value::isContext($ctx), 'math objects: check context');

my $f = Compute('x^2');
my $g = Compute('sin(x)');

ok(Value::isFormula($f), 'math objects: check for formula');
is($f->class, 'Formula', 'math objects: check that the class is Formula');
is($f->type,  'Number',  'math objects: check that the type is Number');

# check answer evaluators
is(check_score($f->eval(x => 2),      '4'),   1, 'math objects: eval x^2 at x=2');
is(check_score($f->eval(x => -3),     '9'),   1, 'math objects: eval x^2 at x=-3');
is(check_score($g->eval(x => 'pi/6'), '1/2'), 1, 'math objects: eval sin(x) at x=pi/6');

# check derivatives
is(check_score($f->D('x'), '2x'),     1, 'math objects: derivative of x^2');
is(check_score($g->D('x'), 'cos(x)'), 1, 'math objects: derivative of sin(x)');

done_testing();
