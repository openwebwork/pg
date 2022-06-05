use Test2::V0;

use Units;

my %joule = evaluate_units('J');
my %newton_metre = evaluate_units('N*m');
my %base_units = evaluate_units('kg*m^2/s^2');

my %electron_volt = evaluate_units('eV');
my %kev = evaluate_units('keV');
my %mev = evaluate_units('MeV');
my %gev = evaluate_units('GeV');

SKIP: {
	skip('New eV units not available until PG-2.17')
		if $kev{ERROR} =~ /^UNIT ERROR Unrecognizable unit/;

	is \%electron_volt, by_factor( 1.6022E-19, \%joule ),
		'eV and joules differ by a factor of 1.6022 x 10^19';

	is \%kev, by_factor( 1000, \%electron_volt ),  'kilo is factor 1000';
	is \%mev, by_factor( 10**6, \%electron_volt ), 'mega is factor 10^6';
	is \%gev, by_factor( 10**9, \%electron_volt ), 'giga is factor 10^9';
}

subtest 'electron volt has units of energy' => sub {
	my ($ev, $J) = ( { %electron_volt }, { %joule } );
	delete $ev->{factor};
	delete $J->{factor};

	is $ev, $J, 'electron volt has units of energy';
};


done_testing;

sub by_factor {
    my ($value, $unit) = @_;
    my $new_unit = { %$unit }; # shallow copy hash values

    $new_unit->{factor} *= $value;

    return $new_unit;
}
