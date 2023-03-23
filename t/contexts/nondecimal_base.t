#!/usr/bin/env perl

=head1 NondecimalBase context

Test the functionality for the NondecimalBase context.

=cut

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

use lib "$ENV{PG_ROOT}/lib";

loadMacros('PGstandard.pl', 'MathObjects.pl', 'contextNondecimalBase.pl');

use Value;
require Parser::Legacy;
import Parser::Legacy;

use Data::Dumper;

Context('NondecimalBase');

# test that convert is working

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

subtest 'Convert between two non-decimal bases' => sub {
	is convertBase('1234', from => 5, to => 16), 'C2', 'convert from base 5 to 16';
};

# Now test the Context.

Context()->flags->set(base => 5);
# # context::NondecimalBase->setBase(5);

subtest 'Check that the Context parses number correct' => sub {
	is Context()->{flags}->{base}, 5, 'Check that the base is stored.';

	ok my $a1 = Compute('10'),  "The string '10' is created";
	is $a1->value, 5, "The base-5 string '10' is 5 in base 10";
	ok my $a2 = Compute('242'), "The string '242' is created.";
	is $a2->value, 72, "The base-5 string '242' is 72 in base 10";
};

subtest 'check that non-valid digits return errors' => sub {
	like dies { Compute('456'); }, qr/^The number must consist/,
		'Try to build a base-5 number will illegal digits';
};

subtest 'check arithmetic in base-5' => sub {
	ok my $a1 = Compute('4021'), "Base-5 number '4021' parsed.";
	is $a1->value, 511, "Base-5 number '4021' is 511 in base-10";

	ok my $a2 = Compute('2334'), "Base-5 number '2334' parsed.";
	is $a2->value, 344, "Base-5 number '2334' is 344 in base-10";

	my $a3 = Compute("$a2+$a1");
	is $a3->string, '11410', '4021+2334=11410 in base-5';

	my $a4 = Compute("$a1-$a2");
	is $a4->string, '1132', '4021-2334=1132 in base-5';

	my $a5 = Compute("$a1*$a2");
	is $a5->string, '21111114', '4021*2334=21111114 in base-5';

	my $a6 = Compute("$a1^2");
	is $a6->string, '31323441', '4021^2 = 31323441 in base-5';

	like dies { Compute("$a1/$a2"); }, qr/^Can't use '\/'/, 'Check that / is not allowed.';

};

subtest 'check arithmetic in base-16' => sub {
	Context()->flags->set(base => 16);
	ok my $a1 = Compute('AE'), "Base-16 number 'AE' parsed.";
	is $a1->value, 174, "Base-16 number 'AE' is 175 in base-10";

	ok my $a2 = Compute('D8'), "Base-16 number 'D8' parsed.";
	is $a2->value, 216, "Base-16 number 'D8' is 216 in base-10";

	my $a3 = Compute("$a2+$a1");
	is $a3->string, '186', 'AE+D8=186 in base-16';

	my $a4 = Compute("$a2-$a1");
	is $a4->string, '2A', 'D8-AE=2A in base-16';

	my $a5 = Compute("$a2*$a1");
	is $a5->string, '92D0', 'AE*D8=92D0 in base-16';

	my $a6 = Compute("$a2^2");
	is $a6->string, 'B640', 'D8^2=B640 in base-16';

	like dies { Compute("$a1/$a2"); }, qr/^Can't use '\/'/, 'Check that / is not allowed.';
};




done_testing();
