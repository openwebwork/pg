#!/usr/bin/perl -w
#
# tests Units.pm module

#use Test::More tests => 5;
use Test::More qw( no_plan );

BEGIN { 
	use_ok('Units'); 
}

my $error_message = '';

#### Let's check that all the units are unique and defined in base units ####
ok( check_fundamental_units(), "checking fundamental units: $error_message");

SKIP: {
	skip 'Evaluating units doomed to failure', 9 if $error_message;

is_deeply( {evaluate_units('kg')}, in_base_units(kg => 1, factor => 1), 'kilogram' );
is_deeply( {evaluate_units('N')}, in_base_units(kg => 1, m => 1, s => -2, factor => 1), 'Newton' );
is_deeply( {evaluate_units('C')}, in_base_units(amp => 1, s => 1, factor => 1), 'Coulomb' );
is_deeply( {evaluate_units('V')}, in_base_units(amp => -1, s => -3, kg => 1, m => 2, factor => 1), 'Volt' );
is_deeply( {evaluate_units('J*s')}, in_base_units(kg => 1, m => 2, s => -1, factor => 1), 'Joule-seconds' );

is_deeply( {evaluate_units('N/C')}, {evaluate_units('V/m')}, 'N/C = V/m' );
is_deeply( {evaluate_units('C/N')}, {evaluate_units('m/V')}, 'C/N = m/V' );
is_deeply( {evaluate_units('V/m')}, in_base_units(kg => 1, m => 1, s => -3, amp => -1, factor => 1), 'Volts per metre' );
is_deeply( {evaluate_units('N/C')}, in_base_units(kg => 1, m => 1, s => -3, amp => -1, factor => 1), 'Newtons per Coulomb' );
is_deeply( {evaluate_units('N/C')}, {evaluate_units('J/amp*m*s')}, 'N/C = J/amp*m*s' );
is_deeply( {evaluate_units('V/m')}, {evaluate_units('N/C')}, 'V/m = N/C' );

is_deeply( multiply_by(1000, evaluate_units('mF')), {evaluate_units('F')}, 'millifarad conversion');
is_deeply( multiply_by(1E6, evaluate_units('uF')), {evaluate_units('F')}, 'microfarad conversion');
is_deeply( multiply_by(1000, evaluate_units('ohm')), {evaluate_units('kohm')}, 'kilo-ohm conversion');
is_deeply( multiply_by(1E6, evaluate_units('ohm')), {evaluate_units('Mohm')}, 'kilo-ohm conversion');
is_deeply( multiply_by(1000, evaluate_units('mV')), {evaluate_units('V')}, 'millivolt conversion');
is_deeply( multiply_by(1000, evaluate_units('V')), {evaluate_units('kV')}, 'kilovolt conversion');

is_deeply( multiply_by(1e5, evaluate_units('G')), {evaluate_units('T')}, 'magnetic field strength conversion');
is_deeply( {evaluate_units('V/ohm')}, {evaluate_units('V*S')}, 'conductivity definition');
is_deeply( {evaluate_units('Wb')}, {evaluate_units('T*m^2')}, 'Weber definition');
is_deeply( {evaluate_units('H')}, {evaluate_units('V*s/amp')}, 'Henry definition');

is_deeply( multiply_by(1000, evaluate_units('micromol/L')), {evaluate_units('mmol/L')}, 'concentration conversion');
is_deeply( multiply_by(10, evaluate_units('mg/L')), {evaluate_units('mg/dL')}, 'concentration conversion');
is_deeply( multiply_by(1e9, evaluate_units('nanomol')), {evaluate_units('mol')}, 'concentration conversion');

is_deeply( multiply_by(1000, evaluate_units('mSv')), {evaluate_units('Sv')}, 'milli-Sievert conversion');
is_deeply( multiply_by(1e6, evaluate_units('uSv')), {evaluate_units('Sv')}, 'micro-Sievert conversion');
is_deeply( {evaluate_units('kat')}, {evaluate_units('mol/s')}, 'catalitic activity' );

is_deeply( multiply_by(1822.88854680448, evaluate_units('me')), {evaluate_units('amu')}, 'atomic mass conversion');

is_deeply( {evaluate_units('lx')}, {evaluate_units('lm/m^2')}, 'lux = lumen per square metre' );

is_deeply( multiply_by(1e9, evaluate_units('Pa')), {evaluate_units('GPa')}, 'gigapascal conversion');
is_deeply( multiply_by(1000, evaluate_units('kPa')), {evaluate_units('MPa')}, 'kilopascal conversion');

is_deeply( multiply_by(2*1000*$Units::PI, evaluate_units('rad/s')), {evaluate_units('kHz')}, 'kilohertz conversion');

$second_arc = 0.0174532925/60/60;
is_deeply( multiply_by(cos($second_arc)/sin($second_arc), evaluate_units('AU')), {evaluate_units('parsec')}, 'parsec conversion');
is_deeply( multiply_by(299792458, evaluate_units('m/s')), {evaluate_units('c')}, 'speed of light conversion');
is_deeply( {evaluate_units('c*yr')}, {evaluate_units('light-year')}, 'light year' );

is_deeply( multiply_by((180/$Units::PI)**2, evaluate_units('deg^2')), {evaluate_units('sr')}, 'solid angle conversion');


}
ok( units_well_defined(), "checking unit definitions: $error_message");

exit;

sub in_base_units {
	my %u = @_;
	my %base_units = %Units::fundamental_units;
	foreach my $key (keys %u) {
		$base_units{$key} = $u{$key};
	}
	return \%base_units;
}

sub multiply_by {
	my ($conversion, %unit) = @_;
	$unit{factor} *= $conversion;
	return \%unit;
}

sub check_fundamental_units {
	my @base_units = qw( factor mol degF degC kg m amp s degK rad cd );
	
	if ( @base_units != keys %Units::fundamental_units ) {
		if ( @base_units < keys %Units::fundamental_units ) {
			$error_message = 'New fundamental units added - update test';
			return undef;
		}
		else {
			$error_message = 'Missing fundamental units';
			return undef;
		}
	}
	foreach my $unit ( @base_units ) {
		unless ( exists $Units::fundamental_units{$unit} 
				&& ($Units::fundamental_units{$unit} == 0 || $Units::fundamental_units{$unit} == 1) ) {
			$error_message = "Problem with $unit";
			return undef;
		}
	}
	return 'ok';
}


sub units_well_defined {
	foreach my $unit ( keys %Units::known_units ) {
		for my $factor ( keys %{$Units::known_units{$unit}} ) {
			unless ( exists $Units::fundamental_units{$factor} ) {
				$error_message = "non-base unit in definition: $unit";
				return undef;
			}
		}
	}
	return 'ok';
}

