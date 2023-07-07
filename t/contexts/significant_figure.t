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

subtest 'Test for number of significant digits' => sub {
	ok my $a1 = Compute('0012.34'), 'Creating the number 0012.34';
	is $a1->sigfigs, 4, '0012.34 has 4 significant figures.';
	ok my $a2 = Compute('0.00314'), 'Creating the number 0.00314';
	is $a2->sigfigs, 3, '0.00314 has 3 significant figures.';
	ok my $a3 = Compute('0.0031400'), 'Creating the number 0.0031400';
	is $a3->sigfigs, 5, '0.0031400 has 5 significant figures.';
	ok my $a4 = Compute('0.31415'), 'Creating the number 0.31415';
	is $a4->sigfigs, 5, '0.31415 has 5 significant figures.';

	ok my $a5 = Compute('16.100'), 'Creating the number 16.100';
	is $a5->sigfigs, 5, '16.100 has 5 significant figures.';
	ok my $a6 = Compute('12300'), 'Creating the number 12300';
	is $a6->sigfigs, 3, '12300 has 3 significant figures.';
	ok my $a7 = Compute('2'), 'Create the number 2';
	is $a7->sigfigs, 1, '2 has 1 significant figure.';
	ok my $a8 = Compute('2010'), 'Create the number 2010';
	is $a8->sigfigs, 3, '2010 has 3 significant figures.';

	# ok my $a6 = Compute('-1.234'), 'Creating the number -1.234';
	# is $a6->sigfigs, 4, '-1.234 has 4 significant figures.';
};

subtest 'Multiplying two constants' => sub {
	my $a1 = Compute('12.34');
	my $a2 = Compute('0.314');
	my $a3 = $a1*$a2;
	is $a3->{value}, 3.87, '12.34*0.314 = 3.87 (3 sigfigs)';

	my $a4 = Compute('16.100');
	my $a5 = Compute('0.00043923');
	my $a6 = $a4*$a5;
	is $a6->{value}, 0.0070716, '16.100*0.00043923 = 0.0070716 (5 sigfigs)';


	my $a7 = Compute('2.6');
	my $a8 = Compute('173.832');
	my $a9 = $a7*$a8;
	is $a9->{value}, 450, '2.6*173.832 = 450 (2 sigfigs)';

};

subtest 'Adding two constants' => sub {
	my $a1 = Compute('12.34');
	my $a2 = Compute('0.314');
	my $a3 = $a1+$a2;
	is $a3->{value}, 12.65, '12.34+0.314=12.65';

	my $a4 = Compute('1.234');
	my $a5 = Compute('2');
	my $a6 = $a4+$a5;
	is $a6->{value}, 3, '1.234+2=3';

	my $a7 = Compute('1.234');
	my $a8 = Compute('2.0');
	my $a9 = $a7+$a8;
	is $a9->{value}, 3.2, '1.234+2.0=3.2';

	my $a10 = Compute('0.01234');
	my $a11 = Compute('2.0');
	my $a12 = $a10+$a11;
	is $a12->{value}, 2.0, '0.01234+2.0=2.0';

};

done_testing();
