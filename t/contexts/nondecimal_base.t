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

Context('NondecimalBase');

setBase(5);

# ok my $a1 = Compute('10');
ok my $a2 = Compute('240');
is convertBase($a2->value, from => 5), 70, 'Base 5 stored correctly in base 10';

subtest 'check that non-valid digits return errors' => sub {
	like dies { Compute('456'); }, qr/^The number to convert must consist/,
		'Try to build a base-5 number will illegal digits';
};

subtest 'check arithmetic in non-decimal base' => sub {
	my $a3 = Compute('240+113');
	ok $a3->value, '403', 'Base 5 addition is correct';
	my $a4 = Compute('240-113');
	ok $a4->value, '122', 'Base 5 subtraction is correct';
};


done_testing();
