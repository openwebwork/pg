#!/usr/bin/env perl

=head1 SignificantFigure context

Test the SignifcantFigure context defined in contextSignificantFigure.pl.

=cut

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

use lib "$ENV{PG_ROOT}/lib";

loadMacros('contextSignificantFigure.pl');

use Value;
require Parser::Legacy;
import Parser::Legacy;

use Data::Dumper;

Context('SignificantFigure');


subtest 'Create numbers with significant digits using Compute' => sub {
	ok my $a1 = Compute('0012.34'), 'Creating the number 0012.34';
	is $a1->sigfigs, 4, '0012.34 has 4 significant figures.';
	is $a1->exp, -2, '0012.34 = 1234 * 10^(-2)';

	ok my $a2 = Compute('0.00314'), 'Creating the number 0.00314';
	is $a2->sigfigs, 3, '0.00314 has 3 significant figures.';
	is $a2->exp, -5, '0.00314 = 314 * 10^(-5)';


	ok my $a3 = Compute('0.0031400'), 'Creating the number 0.0031400';
	is $a3->sigfigs, 5, '0.0031400 has 5 significant figures.';
	is $a3->exp, -7, '0.0031400 = 31400 * 10^(-7)';

	ok my $a4 = Compute('0.31415'), 'Creating the number 0.31415';
	is $a4->sigfigs, 5, '0.31415 has 5 significant figures.';
	is $a4->exp, -5, '0.31415 = 31415 * 10^(-5)';

	ok my $a5 = Compute('16.100'), 'Creating the number 16.100';
	is $a5->sigfigs, 5, '16.100 has 5 significant figures.';
	is $a5->exp, -3, '16.100 = 16100 * 10^(-3)';

	ok my $a6 = Compute('12300'), 'Creating the number 12300';
	is $a6->sigfigs, 5, '12300 has 3 significant figures.';
	is $a6->exp, 2, '12300 = 123 * 10^2';

	ok my $a7 = Compute('2'), 'Create the number 2';
	is $a7->sigfigs, 1, '2 has 1 significant figure.';
	is $a7->exp, 0, '2 = 2 * 10^0';

	ok my $a8 = Compute('2010'), 'Create the number 2010';
	is $a8->sigfigs, 4, '2010 has 3 significant figures.';
	is $a8->exp, 1, '2010 = 201 * 10^1';

	ok my $a9 = Compute('80'), 'Create the number 8';
	is $a9->sigfigs, 2, '80 has 2 significant figures.';
	is $a9->exp, 1, '80 = 8 * 10^1';

	# ok my $a10 = Compute('-1.932'), 'Creating the number -1.234';
	# is $a10->sigfigs, 4, '-1.234 has 4 significant figures.';
	# is $a10->{value_int}, -1234, '-1.234 has value int of -1234';
	# is $a10->{exp}, -3, '-1.234 = -1234 * 10^(-3)';

	ok my $a11 = Compute('2.000'), 'Creating the number 2.000';
	is $a11->sigfigs, 4, '2.000 has 4 significant figures';
	is $a11->{value_int}, 2000, '2.000 as value_int of 2000';
	is $a11->exp, -3, '2.000 = 2000 * 10^-3';

};

subtest 'Create numbers with significant digits using SigFig' => sub {
	my $a1 = SigFigNumber(10000,3);
	is $a1->{value_int}, 100, 'Test for int value for x=10000 with 3 sig figs';
	is $a1->sigfigs, 3, 'Test number of sigfigs for x=10000 with 3 sig figs';
	is $a1->exp, 2, 'Test exponential for x=10000 with 3 sig figs';

	my $a2 = SigFigNumber(12.3456,4);
	is $a2->{value_int}, 1234, 'Test for int value for x=12.3456 with 4 sig figs';
	is $a2->sigfigs, 4, 'Test for sig figs for x=12.3456 with 4 sig figs';
	is $a2->exp, -2, 'Test for exp for x=12.3456 with 4 sig figs';

	my $a3 = SigFigNumber(123.45, 6);
	is $a3->{value_int}, 123450, 'Test for int value for x=123.45 with 6 sig figs';
	is $a3->sigfigs, 6, 'Test for sig figs for x=123.45 with 6 sig figs';
	is $a3->exp, -3, 'Test for exp for x=123.45 with 6 sig figs';

	my $a4 = SigFigNumber(2,4);
	is $a4->{value_int}, 2000, '2 with 4 significant figures is 2.000';
	is $a4->sigfigs, 4, '2 with 4 significant figures is 2.000';
	is $a4->exp, -3, '2 with 4 significant figures is 2.000';
};

subtest 'Set the number of significant digits' => sub {
	my $a1 = Compute('12.34567');
	is $a1->sigfigs, 7, '12.34567 has 7 significant digits.';

	ok $a1->sigfigs(5), 'Call to the sigfigs method for n=5';
	is $a1->sigfigs, 5, 'The number has been changed to 5 sigfigs';
	is $a1->{value_int}, 12346, 'The int value is now 12346';
	is $a1->exp, -3, 'The exp is now -3';

	# my $a2 = Compute('-123.45');
	# is $a2->sigfigs, 5, '-123.45 has 5 significant digits';
	# is $a2->sigfigs(7), 7, 'Change the number of signicant figures to 7';
	# is $a2->{value_int}, -1234500, 'Check the value int for -123.4500';
	# is $a2->{exp}, -4, 'Check the value int for -123.4500';
};

subtest 'Multiplying two constants' => sub {
	my $a1 = Compute('12.34');
	my $a2 = Compute('0.314');
	my $a3 = $a1*$a2;
	is $a3->{value_int}, 387, '12.34*0.314 = 3.87 (3 sigfigs)';
	is $a3->sigfigs, 3, '12.34*0.314 = 3.87 (3 sigfigs)';
	is $a3->exp, -2, '12.34*0.314 = 3.87 (3 sigfigs)';

	my $a4 = Compute('16.100');
	my $a5 = Compute('0.00043923');
	my $a6 = $a4*$a5;
	is $a6->{value_int}, 70716, '16.100*0.00043923 = 0.0070716 (5 sigfigs)';
	is $a6->sigfigs, 5, '16.100*0.00043923 = 0.0070716 (5 sigfigs)';
	is $a6->exp, -7, '16.100*0.00043923 = 0.0070716 (5 sigfigs)';

	my $a7 = Compute('2.6');
	my $a8 = Compute('173.832');
	my $a9 = $a7*$a8;
	is $a9->{value_int}, 45, '2.6*173.832 = 450 (2 sigfigs)';
	is $a9->sigfigs, 2, '2.6*173.832 = 450 (2 sigfigs)';
	is $a9->exp, 1, '2.6*173.832 = 450 (2 sigfigs)';

};

subtest 'Adding two constants' => sub {
	my $a1 = Compute('12.34');
	my $a2 = Compute('0.314');
	my $a3 = $a1+$a2;
	is $a3->{value_int}, 1265, '12.34+0.314=12.65 (check value_int)';
	is $a3->exp, -2, '12.34+0.314=12.65 (check exp)';
	is $a3->sigfigs, 4, '12.34+0.314=12.65 (check sigfigs)';

	my $a4 = Compute('1.234');
	my $a5 = Compute('2');
	my $a6 = $a4+$a5;
	is $a6->{value_int}, 3, '1.234 + 2 = 3 (check value_int)';
	is $a6->exp, 0, '1.234 + 2 = 3 (check exp)';
	is $a6->sigfigs, 1, '1.234 + 2 = 3 (check sigfigs)';


	my $a7 = Compute('1.234');
	my $a8 = Compute('2.0');
	my $a9 = $a7+$a8;
	is $a9->{value_int}, 32, '1.234 + 2.0 = 3.2 (check value_int)';
	is $a9->exp, -1, '1.234 + 2.0 = 3.2 (check exp)';
	is $a9->sigfigs, 2, '1.234 + 2.0 = 3.2 (check sigfigs)';

	my $a10 = Compute('0.01234');
	my $a11 = Compute('2.0');
	my $a12 = $a10+$a11;
	is $a12->{value_int}, 20, '0.01234+2.0=2.0 (check value_int)';
	is $a12->exp, -1, '0.01234+2.0=2.0 (check exp)';
	is $a12->sigfigs, 2, '0.01234+2.0=2.0 (check sigfigs)';

};

subtest 'Subtracting two constants' => sub {
	my $a1 = Compute('12.34');
	my $a2 = Compute('0.314');
	my $a3 = $a1-$a2;
	is $a3->{value_int}, 1203, '12.34-0.314=12.03 (check value_int)';
	is $a3->{exp}, -2, '12.34-0.314=12.03 (check exp)';
	is $a3->{sigfigs}, 4, '12.34-0.314=12.03 (check sigfigs)';

	my $a4 = Compute('2');
	my $a5 = Compute('1.234');
	my $a6 = $a4-$a5;
	is $a6->{value_int}, 1, '2-1.234 = 1 (check value_int)';
	is $a6->{exp}, 0, '2-1.234 = 1 (check exp)';
	is $a6->{sigfigs}, 1, '2-1.234 = 1 (check sigfigs)';


	my $a7 = Compute('2.0');
	my $a8 = Compute('1.234');
	my $a9 = $a7-$a8;
	is $a9->{value_int}, 8, '2.0-1.234 = 8 (check value_int)';
	is $a9->{exp}, -1, '2.0-1.234 = 8 (check exp)';
	is $a9->{sigfigs}, 1, '2.0-1.234 = 1 (check sigfigs)';

	my $a10 = Compute('2.0');
	my $a11 = Compute('0.01234');
	my $a12 = $a10-$a11;
	is $a12->{value_int}, 20, '2.0-0.01234 = 2.0 (check value_int)';
	is $a12->{exp}, -1, '2.0-0.01234 = 2.0 (check exp)';
	is $a12->{sigfigs}, 2, '2.0-0.01234 = 2.0 (check sigfigs)';

};

subtest 'Division' => sub {
	my $a1 = Compute('1.000') / Compute('4.000');
	is $a1->{value_int}, 2500, '1.000/4.000 = 0.2500 (check value_int)';
	is $a1->{sigfigs}, 4, '1.000/4.000 = 0.2500 has 4 sigfigs';
	is $a1->{exp}, -4, '1.000/4.000 = 0.2500 (check exp)';

	my $a2 =  Compute('1.0000') / Compute('4.000');
	is $a2->{value_int}, 2500, '1.0000/4.000 = 0.2500 (check value_int)';
	is $a2->{sigfigs}, 4, '1.0000/4.000 = 0.2500 has 4 sigfigs';
	is $a2->{exp}, -4, '1.0000/4.000 = 0.2500 (check exp)';
};

done_testing();
