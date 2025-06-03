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

sub ROUND {&context::SignificantFigures::Real::ROUND}

subtest 'Test the helper functions.' => sub {
	is ROUND(1.335,    3), '1.34',   'Round 1.335 to 3 sig figs.';
	is ROUND(12.34567, 5), '12.346', 'Round 12.346 to 5 sig figs.';

	my $a1 = Real('1');    # Needed to get a Real (SignificantFigure) MathObject.
	is $a1->expFor('12.34567',   5), '1',  'Find the exponential part of 12.3456';
	is $a1->expFor('0.00124567', 5), '-3', 'Find the exponential part of 0.00123456';

	is $a1->format('E', '123.456',  6), '1.23456E+02', 'Write 123.456 in exponential form.';
	is $a1->format('f', '1.23E-01', 4), '0.123',       'Write 1.23E-01 in decimal form.';
};

subtest 'Create numbers with significant digits using Real' => sub {
	ok my $a1 = Real('0012.34'), 'Creating the number 0012.34';
	is $a1->sigfigs, 4, '0012.34 has 4 significant figures.';
	is $a1->E,       1, '0012.34 written as 1.234 * 10^1';
	ok $a1->value, 12.34, '0012.34 = 12.34';
	is $a1->expFormat, '1.234E+01', 'Correct exponential/internal form';
	is $a1->string,    '12.34',     'Correct string output.';
	is $a1->TeX,       '{12.34}',   'Correct TeX output.';

	ok my $a2 = Real('0.00314'), 'Creating the number 0.00314';
	is $a2->sigfigs,    3,          '0.00314 has 3 significant figures.';
	is $a2->E,         -3,          '0.00314 = 3.14 * 10^(-3)';
	is $a2->expFormat, '3.14E-03',  'Correct exponential/internal form';
	is $a2->string,    '0.00314',   'Correct string output.';
	is $a2->TeX,       '{0.00314}', 'Correct TeX output.';

	ok my $a3 = Real('0.0031400'), 'Creating the number 0.0031400';
	is $a3->sigfigs,    5,            '0.0031400 has 5 significant figures.';
	is $a3->E,         -3,            '0.0031400 = 3.1400 * 10^(-3)';
	is $a3->expFormat, '3.1400E-03',  'Correct exponential/internal form';
	is $a3->string,    '0.0031400',   'Correct string output.';
	is $a3->TeX,       '{0.0031400}', 'Correct TeX output.';

	ok my $a4 = Real('0.31415'), 'Creating the number 0.31415';
	is $a4->sigfigs,    5,           '0.31415 has 5 significant figures.';
	is $a4->E,         -1,           '0.31415 = 3.1415 * 10^(-1)';
	is $a4->expFormat, '3.1415E-01', 'Correct exponential/internal form';
	is $a4->string,    '0.31415',    'Correct string output.';
	is $a4->TeX,       '{0.31415}',  'Correct TeX output.';

	ok my $a5 = Real('216.100'), 'Creating the number 216.100';
	is $a5->sigfigs,   6,             '216.100 has 6 significant figures.';
	is $a5->E,         2,             '216.100 = 2.16100 * 10^(2)';
	is $a5->expFormat, '2.16100E+02', 'Correct exponential/internal form';
	is $a5->string,    '216.100',     'Correct string output.';
	is $a5->TeX,       '{216.100}',   'Correct TeX output.';

	ok my $a6 = Compute('1230000'), 'Creating the number 12300';
	is $a6->sigfigs,   3,                     '1230000 has 3 significant figures.';
	is $a6->E,         6,                     '1230000 = 1.23 * 10^6';
	is $a6->expFormat, '1.23E+06',            'Correct exponential/internal form';
	is $a6->string,    '1.23E+06',            'Correct string output.';
	is $a6->TeX,       '{1.23\times 10^{6}}', 'Correct TeX output.';

	ok my $a7 = Compute('2'), 'Create the number 2';
	is $a7->sigfigs,   1,       '2 has 1 significant figure.';
	is $a7->E,         0,       '2 = 2 * 10^0';
	is $a7->expFormat, '2E+00', 'Correct exponential/internal form';
	is $a7->string,    '2.',    'Correct string output.';
	is $a7->TeX,       '{2.}',  'Correct TeX output.';

	ok my $a8 = Compute('-1.932'), 'Creating the number -1.932';
	is $a8->sigfigs,   4,            '-1.932 has 4 significant figures.';
	is $a8->E,         0,            '-1.932 = -1.932 * 10^(0)';
	is $a8->expFormat, '-1.932E+00', 'Correct exponential/internal form';
	is $a8->string,    '-1.932',     'Correct string output.';
	is $a8->TeX,       '{-1.932}',   'Correct TeX output.';

	ok my $a9 = Compute('-12340000'), 'Creating the number -12340000';
	is $a9->sigfigs,   4,                       '-12340000 has 4 significant figures';
	is $a9->E,         7,                       '-12340000 = -1.234 * 10^(7)';
	is $a9->expFormat, '-1.234E+07',            'Correct exponential/internal form';
	is $a9->string,    '-1.234E+07',            'Correct string output.';
	is $a9->TeX,       '{-1.234\times 10^{7}}', 'Correct TeX output.';

	ok my $a10 = Compute('0.00000001234'), 'Creating the number 0.00000001234';
	is $a10->sigfigs,    4,                      '0.00000001234 has 4 significant figures';
	is $a10->E,         -8,                      '0.00000001234 = 1.234 * 10^(-11)';
	is $a10->expFormat, '1.234E-08',             'Correct exponential/internal form';
	is $a10->string,    '1.234E-08',             'Correct string output.';
	is $a10->TeX,       '{1.234\times 10^{-8}}', 'Correct TeX output.';

	ok my $a11 = Real('10', sigfigs => 'inf'), 'Creating the number 10 with infinite sigfigs.';
	is $a11->sigfigs,   'inf',  'This number has infinite sigfigs.';
	is $a11->E,         0,      'infinite sigfig numbers have exp = 0';
	is $a11->expFormat, '10',   'The number is stored in non-exponential form.';
	is $a11->string,    '10',   'The correct string output.';
	is $a11->TeX,       '{10}', 'The correct TeX output.';

	my $a12 = Real('0.8');
	is $a12->sigfigs,    1,      'The number of sigfigs of 0.8 is 1.';
	is $a12->E,         -1,      '0.8 = 8 * 10^(-1)';
	is $a12->expFormat, '8E-01', 'The internal form is 8E-01';
	is $a12->string,    '0.8',   'The string version is 0.8';
	is $a12->TeX,       '{0.8}', 'The TeX version is {0.8}';

	# check some forms of 0.

	my $a13 = Real('0.00');
	is $a13->sigfigs,   2,          '0.00 has 2 sig figs.';
	is $a13->E,         0,          'The exponential of 0.00 is 0.';
	is $a13->expFormat, '0.00E+00', '0.00 is written in scientific notation as 0.00E+00';
	is $a13->string,    '0.00',     '0.00 is the correct string form.';
	is $a13->TeX,       '{0.00}',   'The TeX version is {0.00}';

	my $a14 = Real('0');
	is $a14->sigfigs,   'inf', '0 has infinite sigfigs.';
	is $a14->E,         0,     'The exponential of 0 is 0';
	is $a14->expFormat, '0',   '0 written in scientific format is 0';
	is $a14->string,    '0',   'The string version is 0';
	is $a14->TeX,       '{0}', 'The TeX version is {0}';

	my $a15 = Real('+00');
	is $a15->sigfigs,   'inf', '+00 has infinite sigfigs.';
	is $a15->E,         0,     'The exponential of +00 is 0';
	is $a15->expFormat, '0',   '+00 written in scientific format is 0';
	is $a15->string,    '0',   'The string version is 0';
	is $a15->TeX,       '{0}', 'The TeX version is {0}';
};

subtest 'Create numbers by specifying significant figures' => sub {
	my $a1 = Real(2, sigfigs => 3);
	is $a1->expFormat, '2.00E+00', '2 with 3 sig figs is 2.00';
	is $a1->string,    '2.00',     'Correct string output.';
	is $a1->TeX,       '{2.00}',   'Correct TeX output.';

	my $a2 = Real('0.25', sigfigs => 4);
	is $a2->expFormat, '2.500E-01', '0.25 with 4 sig figs is 0.2500';
	is $a2->string,    '0.2500',    'Correct string output.';
	is $a2->TeX,       '{0.2500}',  'Correct TeX output.';

	my $a3 = Real('5', sigfigs => 'inf');
	is $a3->expFormat, '5',   "5 with infinite sig figs is stored as '5'";
	is $a3->sigfigs,   'inf', 'Ensure that the sigfigs is infinite';
	is $a3->string,    '5',   'Correct string output.';
	is $a3->TeX,       '{5}', 'Correct TeX output.';
};

subtest 'Creating numbers with significant figures using Compute' => sub {
	my $a1 = Compute('12.345');
	is $a1->expFormat, '1.2345E+01', 'Ensure that the internal storage of 12.345 is correct.';
	is $a1->string,    '12.345',     'Ensure that the string output of 12.345 is correct.';
	is $a1->TeX,       '{12.345}',   'Ensure that the TeX output of 12.345 is correct.';

	# This test currently does not pass.
	# my $a2 = Compute('1.0 * 10^2');
	# is $a2->expFormat, '1.0E+02', 'Ensure that the internal storage of 1.0 * 10^2 is correct.';

};

# # subtest 'Create numbers with significant digits using SigFig' => sub {
# # 	my $a1 = SigFigNumber(10000,3);
# # 	is $a1->expFormat, 100, 'Test for int expFormat for x=10000 with 3 sig figs';
# # 	is $a1->sigfigs, 3, 'Test number of sigfigs for x=10000 with 3 sig figs';
# # 	is $a1->exp, 2, 'Test exponential for x=10000 with 3 sig figs';

# # 	my $a2 = SigFigNumber(12.3456,4);
# # 	is $a2->expFormat, 1234, 'Test for int expFormat for x=12.3456 with 4 sig figs';
# # 	is $a2->sigfigs, 4, 'Test for sig figs for x=12.3456 with 4 sig figs';
# # 	is $a2->exp, -2, 'Test for exp for x=12.3456 with 4 sig figs';

# # 	my $a3 = SigFigNumber(123.45, 6);
# # 	is $a3->expFormat, 123450, 'Test for int expFormat for x=123.45 with 6 sig figs';
# # 	is $a3->sigfigs, 6, 'Test for sig figs for x=123.45 with 6 sig figs';
# # 	is $a3->exp, -3, 'Test for exp for x=123.45 with 6 sig figs';

# # 	my $a4 = SigFigNumber(2,4);
# # 	is $a4->expFormat, 2000, '2 with 4 significant figures is 2.000';
# # 	is $a4->sigfigs, 4, '2 with 4 significant figures is 2.000';
# # 	is $a4->exp, -3, '2 with 4 significant figures is 2.000';
# # };

subtest 'Set the number of significant digits' => sub {
	my $a1 = Compute('12.34567');
	is $a1->sigfigs, 7, '12.34567 has 7 significant digits.';
	ok $a1->sigfigs(5), 'Call to the sigfigs method for n=5';
	is $a1->sigfigs,   5,            'The number has been changed to 5 sigfigs';
	is $a1->expFormat, '1.2346E+01', 'The expFormat is now 1.2346E+01';

	my $a2 = Compute('-123.45');
	is $a2->sigfigs,    5,               '-123.45 has 5 significant digits';
	is $a2->sigfigs(7), 7,               'Change the number of signicant figures to 7';
	is $a2->expFormat,  '-1.234500E+02', "The internal expFormat is '-1.2345E+02'";
};

subtest 'Multiplying two constants' => sub {
	my $a1 = Real('12.34') * Real('0.314');
	is $a1->expFormat, '3.87E+00', '12.34*0.314 = 3.87 (3 sigfigs)';
	is $a1->sigfigs,   3,          '12.34*0.314 = 3.87 (3 sigfigs)';
	is $a1->E,         0,          '12.34*0.314 = 3.87 (3 sigfigs)';

	my $a2 = Real('16.100') * Real('0.00043923');
	is $a2->expFormat, '7.0716E-03', '16.100*0.00043923 = 0.0070716 (5 sigfigs)';
	is $a2->sigfigs,    5,           '16.100*0.00043923 = 0.0070716 (5 sigfigs)';
	is $a2->E,         -3,           '16.100*0.00043923 = 7.0716 * 10^(-3)';

	my $a3 = Real('2.6') * Real('173.832');
	is $a3->expFormat, '4.5E+02', '2.6*173.832 = 450 (2 sigfigs)';
	is $a3->sigfigs,   2,         '2.6*173.832 = 450 (2 sigfigs)';
	is $a3->E,         2,         '2.6*173.832 = 4.50 * 10^(2)';

	my $a4 = Real('7', sigfigs => 'inf') * Real('82.202');
	is $a4->expFormat, '5.7541E+02', "The expFormat of 7*82.202 is '5.7541E+02'.";
	is $a4->sigfigs,   5,            '7*82.202 = 575.41 has 5 sig figs.';
	is $a4->E,         2,            '7*82.202 = 575.41 = 5.7541 * 10^2';
};

subtest 'Adding two constants' => sub {
	my $a1 = Real('12.34') + Real('0.314');
	is $a1->expFormat, '1.265E+01', '12.34+0.314=12.65';
	is $a1->sigfigs,   4,           '12.34+0.314=12.65 (check sigfigs)';
	is $a1->E,         1,           '12.34+0.314 = 1.265 * 10^1';

	my $a2 = Real('1.234') + Real('2');
	is $a2->expFormat, '3E+00', '1.234 + 2 = 3';
	is $a2->sigfigs,   1,       '1.234 + 2 = 3 (check sigfigs)';
	is $a2->E,         0,       '1.234 + 2 = 3 * 10^0 (check exp)';

	my $a3 = Real('1.234') + Real('2.0');
	is $a3->expFormat, '3.2E+00', '1.234 + 2.0 = 3.2E+00';
	is $a3->sigfigs,   2,         '1.234 + 2.0 = 3.2 (check sigfigs)';
	is $a3->E,         0,         '1.234 + 2.0 = 3.2 * 10^0 (check exp)';

	my $a4 = Real('0.01234') + Real('2.0');
	is $a4->expFormat, '2.0E+00', '0.01234+2.0=2.0';
	is $a4->sigfigs,   2,         '0.01234+2.0=2.0 (check sigfigs)';
	is $a4->E,         0,         '0.01234+2.0=2.0 * 10^0 (check exp)';

	my $a5 = Real('-12.3') + Real('14.8676');
	is $a5->expFormat, '2.6E+00', '-12.3 + 14.8678 = 2.6 = 2.6E+00 (check expFormat)';

};

subtest 'Subtracting two constants' => sub {
	my $a1 = Real('12.34') - Real('0.314');
	is $a1->expFormat, '1.203E+01', '12.34-0.314=12.03 (check expFormat)';
	is $a1->sigfigs,   4,           '12.34-0.314=12.03 (check sigfigs)';

	my $a2 = Real('20') - Real('10.645');
	is $a2->expFormat, '1E+01', '20-10.645 = 10 = 1E+01 (check expFormat)';
	is $a2->sigfigs,   1,       '20-10.645 = 10 (1 sig fig)';

	my $a3 = Real('2') - Real('1.234');
	is $a3->expFormat, '1E+00', '2-1.234 = 1 = 1E+00 (check expFormat)';
	is $a3->sigfigs,   1,       '2-1.234 = 1 (check sigfigs)';

	my $a4 = Real('2.0') - Real('1.234');
	is $a4->expFormat, '8E-01', '2.0-1.234 = 0.8 = 8E-0.1';
	is $a4->sigfigs,   1,       '2.0 - 1.234 = 0.8 (1 sig fig)';

	my $a5 = Real('10.49827') - Real('2.37');
	is $a5->expFormat, '8.13E+00', '10.49827 - 2.37 = 8.13 = 8.13E+00';
	is $a5->sigfigs,   3,          '10.49827 - 2.37 = 8.13 (3 sigfigs)';

	my $a6 = Real('253.32') - Real('10.2');
	is $a6->expFormat, '2.431E+02', '253.32 - 10.2 = 243.1 = 2.431E+02';
	is $a6->sigfigs,   4,           '253.32 - 10.2 = 243.1 (4 sigfigs)';

	my $a7 = Real('12.34') - Real('12.21');
	is $a7->expFormat, '1.3E-01', '12.34 - 12.21 = 0.13 = 1.3E-01';

	my $a8 = Real('2.0') - Real('1.234');
	is $a8->expFormat, '8E-01', '2.0-1.234 = 0.8 = 8E-01 (check expFormat)';
	is $a8->sigfigs,    1,      '2.0-1.234 = 1 (check sigfigs)';
	is $a8->E,         -1,      '2.0-1.234 = 8 * 10^(-1) (check exp)';

	my $a9 = Real('2.0') - Real('0.01234');
	is $a9->expFormat, '2.0E+00', '2.0-0.01234 = 2.0 = 2.0E+00 (check expFormat)';
	is $a9->sigfigs,   2,         '2.0-0.01234 = 2.0 (check sigfigs)';
	is $a9->E,         0,         '2.0-0.01234 = 2.0 * 10^(-1) (check exp)';

};

subtest 'Division' => sub {
	my $a1 = Compute('1.000') / Compute('4.000');
	is $a1->expFormat, '2.500E-01', '1.000/4.000 = 0.2500 (check expFormat)';
	is $a1->sigfigs,    4,          '1.000/4.000 = 0.2500 has 4 sigfigs';
	is $a1->E,         -1,          '1.000/4.000 = 0.2500 = 2.500 * 10^(-1) (check exp)';

	my $a2 = Compute('1.0000') / Compute('4.00');
	is $a2->expFormat, '2.50E-01', '1.000/4.00 = 0.250 (check expFormat)';
	is $a2->sigfigs,    3,         '1.0000/4.00 = 0.2500 has 3 sigfigs';
	is $a2->E,         -1,         '1.0000/4.00 = 0.2500 = 2.50 * 10^(-1) (check exp)';

};

# subtest 'Significant Figures for integers' => sub {
# 	# my $a1 = Compute('1.0 * 10^2');
# 	my $a1 = Compute('1.0E+02');
# 	is $a1->expFormat, '1.0E+02', '1.0 * 10^2 internally is 1.0E+02';
# };

done_testing();
