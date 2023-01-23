#!/usr/bin/env perl

=head1 nondecimal_base

Tests conversion of integers to non-decimal bases.

=cut

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

loadMacros('nondecimal_base.pl');

subtest 'conversion from a non-decimal base to base 10' => sub {
	is convertBase('101010', from => 2),  42,   'convert from base 2';
	is convertBase('44011',  from => 5),  3006, 'convert from base 5';
	is convertBase('5073',   from => 8),  2619, 'convert from base 8';
	is convertBase('98A',    from => 12), 1402, 'convert from base 12';
	is convertBase('98T',    from => 12, digits => [ '0' .. '9', 'T', 'E' ]), 1402,
		'convert from base 12 with non-standard digits';
	is convertBase('9FE8', from => 16), 40936, 'convert from base 16';
};

subtest 'Convert from decimal to non-decimal bases' => sub {
	is convertBase(12, to => 2), '1100',   'convert to base 2';
	is convertBase(47, to => 2), '101111', 'convert to base 2';

	is convertBase(98,  to => 5), '343',   'convert to base 5';
	is convertBase(761, to => 5), '11021', 'convert to base 5';

	is convertBase(519,  to => 8), '1007', 'convert to base 8';
	is convertBase(2023, to => 8), '3747', 'convert to base 8';

	is convertBase(853,  to => 12), '5B1',  'convert to base 12';
	is convertBase(2023, to => 12), '1207', 'convert to base 12';
	is convertBase(1678, to => 12, digits => [ '0' .. '9', 'T', 'E' ]), 'E7T',
		'convert to base 12 using non-standard digits';

	is convertBase(5752,  to => 16), '1678', 'convert to base 16';
	is convertBase(41446, to => 16), 'A1E6', 'convert to base 16';
};

subtest 'Check that errors are returned for illegal arguments' => sub {
	like(
		dies { convertBase('10E3', to => 16) },
		qr/The input number must consist only of the digits/,
		'The input number (base 10) doesn\'t consist of the given digits'
	);
	like(
		dies { convertBase('10201', from => 2) },
		qr/The input number must consist only of the digits/,
		'The input number (base 2) doesn\'t consist of the given digits'
	);
	like(
		dies { convertBase('807', from => 8) },
		qr/The input number must consist only of the digits/,
		'The input number (base 8) doesn\'t consist of the given digits'
	);
	like(
		dies { convertBase('930C', from => 12) },
		qr/The input number must consist only of the digits/,
		'The input number (base 12) doesn\'t consist of the given digits'
	);
	like(
		dies { convertBase('930A', from => 12, digits => [ 0 .. 9, 'T', 'E' ]) },
		qr/The input number must consist only of the digits/,
		'The input number (base 12) doesn\'t consist of the given digits (provided)'
	);
};

subtest 'Check that errors are returned for illegal options' => sub {

	like(
		dies { convertBase(87, to => 14, digits => [ 0 .. 9, 'T' ]) },
		qr/The option digits must be an array ref/,
		'The digits option must have enough digits.'
	);
	like(
		dies { convertBase(87, from => 12, digits => [ 0 .. 9, 'T' ]) },
		qr/The option digits must be an array ref/,
		'The digits option must have enough digits.'
	);
	like(
		dies { convertBase(87, to => 8, digits => (0 .. 7)) },
		qr/The option digits must be an array ref/,
		'The digits option must be an array ref.'
	);
	like(
		dies { convertBase(87, to => 1) },
		qr/The base of conversion must be between 2 and 16/,
		'The to option must be between 2 and 16.'
	);
	like(
		dies { convertBase(87, to => 24) },
		qr/The base of conversion must be between 2 and 16/,
		'The to option must be between 2 and 16.'
	);

	like(
		dies { convertBase('0110101', from => 1) },
		qr/The base of conversion must be between 2 and 16/,
		'The from option must be between 2 and 16.'
	);
	like(
		dies { convertBase(87, from => 24) },
		qr/The base of conversion must be between 2 and 16/,
		'The from option must be between 2 and 16.'
	);

};

done_testing;
