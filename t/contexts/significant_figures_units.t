#!/usr/bin/env perl

=head1 SignificantFigure context

Test the SignificantFigure context defined in contextSignificantFigure.pl.

=cut

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

use lib "$ENV{PG_ROOT}/lib";

# load the Units module so that %Units::known_units is populated
use Units;
use Value;
require Parser::Legacy;
import Parser::Legacy;

loadMacros('contextSignificantFigures.pl', 'contextUnits.pl');

my $context = context::Units::extending("SignificantFigures")->withUnitsFor('length');

subtest 'Setup a basic Unit context extending SignificantFigures' => sub {
	Context($context);    # make it current without copying
	ok(defined $context && ref($context), 'Got a context object');
	is $context->{name}, 'Units-SignificantFigures', 'Context has correct name';
};

subtest 'Test a number with length units and significant figures' => sub {
	Context($context);
	ok my $a = Compute("123.0 cm"), 'Compute handles a unit.';

	is $a, '123.0 cm', 'Value stringifies with units and sig figs';
	ok $a == Compute('1.230 m'), 'Value stringifies with correct unit conversion and sig figs';
	ok $a != Compute('123 cm'),  'Value does not lose significant figure information when stringified';

	ok $a == Compute('4.035 ft'), 'Value in feet';
	ok $a == Compute('4.034 ft'), 'Value in feet (a little off, but when converted to m is correct)';
	ok $a == Compute('4.036 ft'), 'Value in feet (a little off, but when converted to m is correct)';

};

done_testing;
