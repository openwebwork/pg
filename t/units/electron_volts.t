#!/usr/bin/env perl

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
use lib "$ENV{PG_ROOT}/lib";

use Units qw(evaluate_units);

my %joule        = evaluate_units('J');
my %newton_metre = evaluate_units('N*m');
my %base_units   = evaluate_units('kg*m^2/s^2');

my %electron_volt = evaluate_units('eV');
my %kev           = evaluate_units('keV');
my %mev           = evaluate_units('MeV');
my %gev           = evaluate_units('GeV');
my %tev           = evaluate_units('TeV');

is \%electron_volt, by_factor(1.6022E-19, \%joule),         'eV and joules differ by a factor of 1.6022 x 10^19';
is \%kev,           by_factor(1000,       \%electron_volt), 'kilo is factor 1000';
is \%mev,           by_factor(10**6,      \%electron_volt), 'mega is factor 10^6';
is \%gev,           by_factor(10**9,      \%electron_volt), 'giga is factor 10^9';
is \%tev,           by_factor(10**12,     \%electron_volt), 'tera is factor 10^12';

done_testing();

# this sub is useful when reusing units for testing
# NumberWithUnits is mutable and test order dependant
sub by_factor {
	my ($value, $unit) = @_;
	my $new_unit = {%$unit};    # shallow copy hash values

	$new_unit->{factor} *= $value;

	return $new_unit;
}
