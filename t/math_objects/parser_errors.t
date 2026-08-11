#!/usr/bin/env perl

=head1 Parser - malformed expression errors

Test that C<Parser.pm> reports sensible, specific errors for malformed input, such as
mismatched parentheses, missing operands, unknown functions/variables, and incorrect
numbers of function arguments.

=cut

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

loadMacros('MathObjects.pl');

Context('Numeric');

subtest 'Mismatched parentheses' => sub {
	like(
		dies { Compute('(1+2') },
		qr/Missing close parenthesis for '\('/,
		'a missing close parenthesis is an error'
	);
	like(dies { Compute('1+2)') }, qr/Extra close parenthesis '\)'/, 'an extra close parenthesis is an error');
};

subtest 'Missing operands' => sub {
	like(dies { Compute('1 +') }, qr/Missing operand after '\+'/,
		'a missing operand after an operator is an error');
	like(
		dies { Compute('*2') },
		qr/Missing operand before '\*'/,
		'a missing operand before an operator is an error'
	);
	like(
		dies { Compute('2^') },
		qr/Missing operand after '\^'/,
		'a missing operand after the power operator is an error'
	);
};

subtest 'Unexpected characters' => sub {
	like(dies { Compute('@') },     qr/Unexpected character '\@'/, 'an unrecognized character is an error');
	like(dies { Compute('1 & 2') }, qr/Unexpected character '&'/,  'an unrecognized operator character is an error');
};

subtest 'Function argument count' => sub {
	like(
		dies { Compute('sin()') },
		qr/Function 'sin' has too few inputs/,
		'calling a function with too few arguments is an error'
	);
	like(
		dies { Compute('sin(1,2)') },
		qr/Function 'sin' has too many inputs/,
		'calling a function with too many arguments is an error'
	);
	like(
		dies { Compute('atan2(1)') },
		qr/Function 'atan2' has too few inputs/,
		'a two-argument function called with one argument is an error'
	);
};

subtest 'Undeclared variables and unknown functions' => sub {
	like(
		dies { Compute('q') },
		qr/Variable 'q' is not defined in this context/,
		'an undeclared variable is an error'
	);
	like(
		dies { Compute('foo(1)') },
		qr/'foo' is not defined in this context/,
		'an unknown function name is an error'
	);
};

subtest 'Division by zero is caught at parse/evaluation time for constants' => sub {
	like(dies { Compute('1/0') }, qr/Division by zero/, 'dividing a constant by zero is an error');
};

done_testing();
