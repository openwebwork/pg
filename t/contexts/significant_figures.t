#!/usr/bin/env perl

=head1 SignificantFigure context

Test the SignifcantFigure context defined in contextSignificantFigure.pl.

=cut

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

use lib "$ENV{PG_ROOT}/lib";

loadMacros('contextSignificantFigures.pl');

use Value;
require Parser::Legacy;
import Parser::Legacy;

use Data::Dumper;

Context('SignificantFigures');

sub ROUND  {&context::SignificantFigures::Real::ROUND}
sub expon  { context::SignificantFigures::Real->expFor($_[0], 0) }
sub FORMAT { context::SignificantFigures::Real->format(@_) }

subtest 'Test the helper functions.' => sub {
	is ROUND(1.335,    3), '1.34',   'Round 1.335 to 3 sig figs.';
	is ROUND(12.34567, 5), '12.346', 'Round 12.346 to 5 sig figs.';
	is ROUND(1.005,    3), '1.01',   'Check that rounding up is working with non-perfect values';
	is ROUND(0.005,    0), 0.01,     'Rounding to 0 sigfigs goes to nearest multiple of 10';
	is ROUND(0.045,    0), 0,        'Rounding to 0 sigfigs down goes to 0';

	my $a1 = Real('1');    # Needed to get a Real (SignificantFigure) MathObject.
	is $a1->expFor('12.34567',   5), '1',  'Find the exponential part of 12.3456';
	is $a1->expFor('0.00124567', 5), '-3', 'Find the exponential part of 0.00123456';

	is FORMAT('E', '123.546',   6), '1.23546E+02', 'Write 123.546 in exponential form.';
	is FORMAT('E', 0.8,         1), '8E-01',       '0.8 = 8E-01';
	is FORMAT('f', '1.23E-01',  3), '0.123',       'Write 1.23E-01 in decimal form.';
	is FORMAT('f', '1.23E-03',  3), '0.00123',     'Write 1.23E-01 in decimal form.';
	is FORMAT('f', '5.283E+02', 4), '528.3',       'Write 5.283+02 in decimal form.';
	is FORMAT('f', '1.23E+00',  3), '1.23',        'Write 1.23E+00 in decimal form.';
	is FORMAT('f', '1.23E+01',  3), '12.3',        'Write 1.23E+01 in decimal form.';
	is FORMAT('f', '1.23E+06',  3), '1.23E+06',    'Write 1.23E+01 in decimal form.';

	is expon('1000.32'),   3, 'Find the exponent of 1000.32.';
	is expon('0'),         0, 'Find the exponent of 0.';
	is expon('-0.00328'), -3, 'Find the exponent of -0.00328.';
};

subtest 'Create numbers with significant digits using Real' => sub {
	ok my $a1 = Real('0012.34'), 'Creating the number 0012.34';
	is $a1->sigfigs, 4, '0012.34 has 4 significant figures.';
	is $a1->E,       1, '0012.34 written as 1.234 * 10^1';
	ok $a1->value, 12.34, '0012.34 = 12.34';
	is $a1->format('E'), '1.234E+01', 'Correct exponential/internal form';
	is $a1->string,      '12.34',     'Correct string output.';
	is $a1->TeX,         '{12.34}',   'Correct TeX output.';

	ok my $a2 = Real('0.00314'), 'Creating the number 0.00314';
	is $a2->sigfigs,      3,          '0.00314 has 3 significant figures.';
	is $a2->E,           -3,          '0.00314 = 3.14 * 10^(-3)';
	is $a2->format('E'), '3.14E-03',  'Correct exponential/internal form';
	is $a2->string,      '0.00314',   'Correct string output.';
	is $a2->TeX,         '{0.00314}', 'Correct TeX output.';

	ok my $a3 = Real('0.0031400'), 'Creating the number 0.0031400';
	is $a3->sigfigs,      5,            '0.0031400 has 5 significant figures.';
	is $a3->E,           -3,            '0.0031400 = 3.1400 * 10^(-3)';
	is $a3->format('E'), '3.1400E-03',  'Correct exponential/internal form';
	is $a3->string,      '0.0031400',   'Correct string output.';
	is $a3->TeX,         '{0.0031400}', 'Correct TeX output.';

	ok my $a4 = Real('0.31415'), 'Creating the number 0.31415';
	is $a4->sigfigs,      5,           '0.31415 has 5 significant figures.';
	is $a4->E,           -1,           '0.31415 = 3.1415 * 10^(-1)';
	is $a4->format('E'), '3.1415E-01', 'Correct exponential/internal form';
	is $a4->string,      '0.31415',    'Correct string output.';
	is $a4->TeX,         '{0.31415}',  'Correct TeX output.';

	ok my $a5 = Real('216.100'), 'Creating the number 216.100';
	is $a5->sigfigs,     6,             '216.100 has 6 significant figures.';
	is $a5->E,           2,             '216.100 = 2.16100 * 10^(2)';
	is $a5->format('E'), '2.16100E+02', 'Correct exponential/internal form';
	is $a5->string,      '216.100',     'Correct string output.';
	is $a5->TeX,         '{216.100}',   'Correct TeX output.';

	ok my $a6 = Compute('1230000'), 'Creating the number 12300';
	is $a6->sigfigs,     3,                     '1230000 has 3 significant figures.';
	is $a6->E,           6,                     '1230000 = 1.23 * 10^6';
	is $a6->format('E'), '1.23E+06',            'Correct exponential/internal form of 1230000';
	is $a6->string,      '1.23E+06',            'Correct string output of 1230000';
	is $a6->TeX,         '{1.23\times 10^{6}}', 'Correct TeX output of 1230000';

	ok my $a7 = Compute('2'), 'Create the number 2';
	is $a7->sigfigs,     1,       '2 has 1 significant figure.';
	is $a7->E,           0,       '2 = 2 * 10^0';
	is $a7->format('E'), '2E+00', 'Correct exponential/internal form of 2';
	is $a7->string,      '2.',    'Correct string output of 2';
	is $a7->TeX,         '{2.}',  'Correct TeX output of 2';

	ok my $a8 = Compute('-1.932'), 'Creating the number -1.932';
	is $a8->sigfigs,     4,            '-1.932 has 4 significant figures.';
	is $a8->E,           0,            '-1.932 = -1.932 * 10^(0)';
	is $a8->format('E'), '-1.932E+00', 'Correct exponential/internal form of -1.932';
	is $a8->string,      '-1.932',     'Correct string output of -1.932';
	is $a8->TeX,         '{-1.932}',   'Correct TeX output of -1.932.';

	ok my $a9 = Compute('-12340000'), 'Creating the number -12340000';
	is $a9->sigfigs,     4,                       '-12340000 has 4 significant figures';
	is $a9->E,           7,                       '-12340000 = -1.234 * 10^(7)';
	is $a9->format('E'), '-1.234E+07',            'Correct exponential/internal form';
	is $a9->string,      '-1.234E+07',            'Correct string output.';
	is $a9->TeX,         '{-1.234\times 10^{7}}', 'Correct TeX output.';

	ok my $a10 = Compute('0.00000001234'), 'Creating the number 0.00000001234';
	is $a10->sigfigs,      4,                      '0.00000001234 has 4 significant figures';
	is $a10->E,           -8,                      '0.00000001234 = 1.234 * 10^(-11)';
	is $a10->format('E'), '1.234E-08',             'Correct exponential/internal form';
	is $a10->string,      '1.234E-08',             'Correct string output.';
	is $a10->TeX,         '{1.234\times 10^{-8}}', 'Correct TeX output.';

	ok my $a11 = Real('10', sigfigs => 'inf'), 'Creating the number 10 with infinite sigfigs.';
	is $a11->sigfigs,     'inf',  'This number has infinite sigfigs.';
	is $a11->E,           0,      'infinite sigfig numbers have exp = 0';
	is $a11->format('E'), '10',   'The number is stored in non-exponential form.';
	is $a11->string,      '10',   'The correct string output.';
	is $a11->TeX,         '{10}', 'The correct TeX output.';

	my $a12 = Real('0.8');
	is $a12->sigfigs,      1,      'The number of sigfigs of 0.8 is 1.';
	is $a12->E,           -1,      '0.8 = 8 * 10^(-1)';
	is $a12->format('E'), '8E-01', 'The internal form is 8E-01';
	is $a12->string,      '0.8',   'The string version is 0.8';
	is $a12->TeX,         '{0.8}', 'The TeX version is {0.8}';

	# check some forms of 0.

	my $a13 = Real('0.00');
	is $a13->sigfigs,     3,          '0.00 has 2 sig figs.';
	is $a13->E,           0,          'The exponential of 0.00 is 0.';
	is $a13->format('E'), '0.00E+00', '0.00 is written in scientific notation as 0.00E+00';
	is $a13->string,      '0.00',     '0.00 is the correct string form.';
	is $a13->TeX,         '{0.00}',   'The TeX version is {0.00}';

	my $a14 = Real('0');
	is $a14->sigfigs,     'inf', '0 has infinite sigfigs.';
	is $a14->E,           0,     'The exponential of 0 is 0';
	is $a14->format('E'), '0',   '0 written in scientific format is 0';
	is $a14->string,      '0',   'The string version is 0';
	is $a14->TeX,         '{0}', 'The TeX version is {0}';

	my $a15 = Real('+00');
	is $a15->sigfigs,     'inf', '+00 has infinite sigfigs.';
	is $a15->E,           0,     'The exponential of +00 is 0';
	is $a15->format('E'), '0',   '+00 written in scientific format is 0';
	is $a15->string,      '0',   'The string version is 0';
	is $a15->TeX,         '{0}', 'The TeX version is {0}';

	my $a16 = Real('0.');
	is $a16->format('E'), '0E+00', 'Check the format of 0.';
	is $a16->sigfigs,     1,       '0. has 1 signficant figure';
	is $a16->E,           0,       'The exponential of +00 is 0';
	is $a16->string,      '0.',    'The string version is 0.';
	is $a16->TeX,         '{0.}',  'The TeX version is {0.}';
};

subtest 'Create numbers by specifying significant figures' => sub {
	my $a1 = Real(2, sigfigs => 3);
	is $a1->format('E'), '2.00E+00', '2 with 3 sig figs is 2.00';
	is $a1->string,      '2.00',     'Correct string output.';
	is $a1->TeX,         '{2.00}',   'Correct TeX output.';

	my $a2 = Real('0.25', sigfigs => 4);
	is $a2->format('E'), '2.500E-01', '0.25 with 4 sig figs is 0.2500';
	is $a2->string,      '0.2500',    'Correct string output.';
	is $a2->TeX,         '{0.2500}',  'Correct TeX output.';

	my $a3 = Real('5', sigfigs => 'inf');
	is $a3->format('E'), '5',   "5 with infinite sig figs is stored as '5'";
	is $a3->sigfigs,     'inf', 'Ensure that the sigfigs is infinite';
	is $a3->string,      '5',   'Correct string output.';
	is $a3->TeX,         '{5}', 'Correct TeX output.';
};

subtest 'Check for out of bounds significant figures' => sub {
	my $a1 = Real('1');
	like dies { Real('5', sigfigs => 20); }, qr/The number of significant figures must be less than 16/,
		'Try to create a real with more than 16 sigfigs.';
	like dies { $a1->sigfigs(20) }, qr/The number of significant figures must be less than 16/,
		'Try to set a number with more than 16 sigfigs.';

	like dies { Real('5', sigfigs => -1); }, qr/The number of significant figures must be non-negative/,
		'Try to create a real with fewer than 1 sigfigs.';
	like dies { $a1->sigfigs(-1) }, qr/The number of significant figures must be non-negative/,
		'Try to set a number with fewer than 1 sigfigs.';

	like dies { Real('5', sigfigs => 'eight'); }, qr/The number of significant figures must be an integer or "inf"/,
		'Try to create a real with non-numerical value';
	like dies { $a1->sigfigs('eight'); }, qr/The number of significant figures must be an integer or "inf"/,
		'Try to set a number with non-numerical value';
};

subtest 'Creating numbers with significant figures using Compute' => sub {
	my $a1 = Compute('12.345');
	is $a1->format('E'), '1.2345E+01', 'Ensure that the internal storage of 12.345 is correct.';
	is $a1->string,      '12.345',     'Ensure that the string output of 12.345 is correct.';
	is $a1->TeX,         '{12.345}',   'Ensure that the TeX output of 12.345 is correct.';

	# This test currently does not pass.
	# my $a2 = Compute('1.0 * 10^2');
	# is $a2->format('E'), '1.0E+02', 'Ensure that the internal storage of 1.0 * 10^2 is correct.';

};

subtest 'Create numbers with significant digits using SigFig' => sub {
	my $a1 = SigFigNumber(10000, 3);
	is $a1->format('E'), '1.00E+04', 'Create 10000 with 3 sigfigs using SigFigNumber (check format).';
	is $a1->sigfigs,     3,          'Check that the created number has 3 sigfigs.';
	is $a1->E,           4,          'Check that the created number has the correct exponent.';

	my $a2 = SigFigNumber(12.3456, 4);
	is $a2->format('E'), '1.235E+01', 'Create 12.3456 with 4 sigfigs using SigFigNumber (check format).';
	is $a2->sigfigs,     4,           'Check that the created number has 4 sig figs.';
	is $a2->E,           1,           'Check that the created number has the correct exponent.';

	my $a3 = SigFigNumber(123.45, 6);
	is $a3->format('E'), '1.23450E+02', 'Create 123.45 with 6 sigfigs using SigFigNumber.';
	is $a3->sigfigs,     6,             'Check that the created number has 6 sigfigs.';
	is $a3->E,           2,             'Check that the created number has the correct exponent.';

	my $a4 = SigFigNumber(2, 4);
	is $a4->format('E'), '2.000E+00', '2 with 4 significant figures is 2.000 (check format)';
	is $a4->sigfigs,     4,           'Check that the created number has 4 sigfigs.';
	is $a4->E,           0,           'Check that the created number has the correct exponent.';

	my $a5 = SigFigNumber('829342', sigfigs => 4);
	is $a5->format('E'), '8.293E+05', 'Create 829342 using SigFigNumber with 4 sigfigs (check format)';
	is $a5->sigfigs,     4,           'Check that the created number has 4 sigfigs.';
	is $a5->E,           5,           'Check that the created number has the correct exponent.';
};

subtest 'Set the number of significant digits' => sub {
	my $a1 = Compute('12.34567');
	is $a1->sigfigs, 7, '12.34567 has 7 significant digits.';
	ok $a1->sigfigs(5), 'Call to the sigfigs method for n=5';
	is $a1->sigfigs,     5,            'The number has been changed to 5 sigfigs';
	is $a1->format('E'), '1.2346E+01', 'The format is now 1.2346E+01';

	my $a2 = Compute('-123.45');
	is $a2->sigfigs,     5,               '-123.45 has 5 significant digits';
	is $a2->sigfigs(7),  7,               'Change the number of signicant figures to 7';
	is $a2->format('E'), '-1.234500E+02', "The internal format is '-1.2345E+02'";

	my $a3 = Real(100, sigfigs => 3);
	is $a3->sigfigs('inf'), 'inf', "Set the sigfigs to 'inf'";
	is $a3->format("E"),    '100', 'The interval format is now 100';
};

subtest 'Multiplying two constants' => sub {
	my $a1 = Real('12.34') * Real('0.314');
	is $a1->format('E'), '3.87E+00', '12.34*0.314 = 3.87 (check format)';
	is $a1->sigfigs,     3,          '12.34*0.314 = 3.87 (check sigfigs)';
	is $a1->E,           0,          '12.34*0.314 = 3.87 (check exp)';

	my $a2 = Real('16.100') * Real('0.00043923');
	is $a2->format('E'), '7.0716E-03', '16.100*0.00043923 = 0.0070716 (check format)';
	is $a2->sigfigs,      5,           '16.100*0.00043923 = 0.0070716 (check sigfigs)';
	is $a2->E,           -3,           '16.100*0.00043923 = 0.0070716 (check exp)';

	my $a3 = Real('2.6') * Real('173.832');
	is $a3->format('E'), '4.5E+02', '2.6*173.832 = 450 (check format)';
	is $a3->sigfigs,     2,         '2.6*173.832 = 450 (check sigfigs)';
	is $a3->E,           2,         '2.6*173.832 = 450 (check exp)';

	my $a4 = Real('7', sigfigs => 'inf') * Real('82.202');
	is $a4->format('E'), '5.7541E+02', '7*82.202 = 575.41 (check format)';
	is $a4->sigfigs,     5,            '7*82.202 = 575.41 (check sigfigs)';
	is $a4->E,           2,            '7*82.202 = 575.41 (check exp)';
};

subtest 'Adding two constants' => sub {
	my $a1 = Real('12.34') + Real('0.314');
	is $a1->format('E'), '1.265E+01', '12.34+0.314 = 12.65 (check format)';
	is $a1->sigfigs,     4,           '12.34+0.314 = 12.65 (check sigfigs)';
	is $a1->E,           1,           '12.34+0.314 = 12.65 (check exp)';

	my $a2 = Real('1.234') + Real('2');
	is $a2->format('E'), '3E+00', '1.234 + 2 = 3 (check format)';
	is $a2->sigfigs,     1,       '1.234 + 2 = 3 (check sigfigs)';
	is $a2->E,           0,       '1.234 + 2 = 3 * 10^0 (check exp)';

	my $a3 = Real('1.234') + Real('2.0');
	is $a3->format('E'), '3.2E+00', '1.234 + 2.0 = 3.2E+00 (check format)';
	is $a3->sigfigs,     2,         '1.234 + 2.0 = 3.2 (check sigfigs)';
	is $a3->E,           0,         '1.234 + 2.0 = 3.2 * 10^0 (check exp)';

	my $a4 = Real('0.01234') + Real('2.0');
	is $a4->format('E'), '2.0E+00', '0.01234+2.0=2.0 (check format)';
	is $a4->sigfigs,     2,         '0.01234+2.0=2.0 (check sigfigs)';
	is $a4->E,           0,         '0.01234+2.0=2.0 * 10^0 (check exp)';

	my $a5 = Real('-12.3') + Real('14.8676');
	is $a5->format('E'), '2.6E+00', '-12.3 + 14.8678 = 2.6 = 2.6E+00 (check format)';
	is $a5->sigfigs,     2,         '-12.3 + 14.8678 = 2.6 (check sigfigs)';
	is $a5->E,           0,         '-12.3 + 14.8678 = 2.6 (check exp)';

	my $a6 = Real(-100.005) + Real(100);
	is $a6->format('E'), '0E+00', '-100.005+100 = 0 (check format)';
	is $a6->sigfigs,     1,       '-100.005+100 = 0. (1 sigfig)';

};

subtest 'Subtracting two constants' => sub {
	my $a1 = Real('12.34') - Real('0.314');
	is $a1->format('E'), '1.203E+01', '12.34-0.314=12.03 (check format)';
	is $a1->sigfigs,     4,           '12.34-0.314=12.03 (check sigfigs)';
	is $a1->E,           1,           '12.34-0.314=12.03 (check exp)';

	my $a2 = Real('20') - Real('10.645');
	is $a2->format('E'), '1E+01', '20-10.645 = 10 = 1E+01 (check format)';
	is $a2->sigfigs,     1,       '20-10.645 = 10 (check sigfigs)';
	is $a2->E,           1,       '20-10.645 = 10 (check exp)';

	my $a3 = Real('2') - Real('1.234');
	is $a3->format('E'), '1E+00', '2-1.234 = 1 = 1E+00 (check format)';
	is $a3->sigfigs,     1,       '2-1.234 = 1 (check sigfigs)';

	my $a4 = Real('2.0') - Real('1.234');
	is $a4->format('E'), '8E-01', '2.0-1.234 = 0.8 = 8E-0.1 (check format)';
	is $a4->sigfigs,      1,      '2.0 - 1.234 = 0.8 (check sigfigs)';
	is $a4->E,           -1,      '2.0 - 1.234 = 0.8 (check sigfigs)';

	my $a5 = Real('10.49827') - Real('2.37');
	is $a5->format('E'), '8.13E+00', '10.49827 - 2.37 = 8.13 = 8.13E+00 (check format)';
	is $a5->sigfigs,     3,          '10.49827 - 2.37 = 8.13 (check sigfigs)';
	is $a5->E,           0,          '10.49827 - 2.37 = 8.13 (check exp)';

	my $a6 = Real('253.32') - Real('10.2');
	is $a6->format('E'), '2.431E+02', '253.32 - 10.2 = 243.1 = 2.431E+02 (check format)';
	is $a6->sigfigs,     4,           '253.32 - 10.2 = 243.1 (check sigfigs)';
	is $a6->E,           2,           '253.32 - 10.2 = 243.1 (check exp)';

	my $a7 = Real('12.34') - Real('12.21');
	is $a7->format('E'), '1.3E-01', '12.34 - 12.21 = 0.13 = 1.3E-01 (check format)';
	is $a7->sigfigs,      2,        '12.34 - 12.21 = 0.13 = 1.3E-01 (check sigfigs)';
	is $a7->E,           -1,        '12.34 - 12.21 = 0.13 = 1.3E-01 (check exp)';

	my $a8 = Real('2.0') - Real('1.234');
	is $a8->format('E'), '8E-01', '2.0-1.234 = 0.8 = 8E-01 (check format)';
	is $a8->sigfigs,      1,      '2.0-1.234 = 1 (check sigfigs)';
	is $a8->E,           -1,      '2.0-1.234 = 8 * 10^(-1) (check exp)';

	my $a9 = Real('2.0') - Real('0.01234');
	is $a9->format('E'), '2.0E+00', '2.0-0.01234 = 2.0 = 2.0E+00 (check format)';
	is $a9->sigfigs,     2,         '2.0-0.01234 = 2.0 (check sigfigs)';
	is $a9->E,           0,         '2.0-0.01234 = 2.0 * 10^(-1) (check exp)';

	my $a10 = Real('10.35123') - Real('10.35');
	is $a10->format('E'), '0.00E+00', '10.35123 - 10.35 = 0.00 (check format)';
	is $a10->sigfigs,     3,          '10.35123 - 10.35 = 0.00 (check 3 sigfigs).';
	is $a10->E,           0,          '10.35123 - 10.35 = 0.00 (check exp).';

	my $a11 = Real('1.03') - Real('0.005');
	is $a11->format('E'), '1.02E+00', '1.03 - .005 = 1.02 (check format)';
	is $a11->sigfigs,     3,          '1.03 - .005 = 1.02 (check sigfigs)';
	is $a11->E,           0,          '1.03 - .005 = 1.02 (check exp)';

};

subtest 'Division' => sub {
	my $a1 = Compute('1.000') / Compute('4.000');
	is $a1->format('E'), '2.500E-01', '1.000/4.000 = 0.2500 (check format)';
	is $a1->sigfigs,      4,          '1.000/4.000 = 0.2500 has 4 sigfigs';
	is $a1->E,           -1,          '1.000/4.000 = 0.2500 = 2.500 * 10^(-1) (check exp)';

	my $a2 = Compute('1.0000') / Compute('4.00');
	is $a2->format('E'), '2.50E-01', '1.000/4.00 = 0.250 (check format)';
	is $a2->sigfigs,      3,         '1.0000/4.00 = 0.2500 has 3 sigfigs';
	is $a2->E,           -1,         '1.0000/4.00 = 0.2500 = 2.50 * 10^(-1) (check exp)';

};

# subtest 'Significant Figures for integers' => sub {
# 	# my $a1 = Compute('1.0 * 10^2');
# 	my $a1 = Compute('1.0E+02');
# 	is $a1->format('E'), '1.0E+02', '1.0 * 10^2 internally is 1.0E+02';
# };

done_testing();
