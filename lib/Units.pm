# Methods for evaluating units in answers
package Units;
use parent Exporter;

use strict;
use warnings;
use utf8;

our @EXPORT_OK = qw(evaluate_units);

# compound units are entered such as m/sec^2 or kg*m/sec^2
# the format is unit[^power]*unit^[*power].../  unit^power*unit^power....
# there can be only one / in a unit.
# powers can be negative integers as well as positive integers.

# Unfortunately there will be no automatic conversion between the different
# temperature scales since we haven't allowed for affine conversions.

our %fundamental_units = (
	factor => 1,
	m      => 0,
	kg     => 0,
	s      => 0,
	rad    => 0,
	degC   => 0,
	degF   => 0,
	K      => 0,
	mol    => 0,    # moles, treated as a fundamental unit
	amp    => 0,
	cd     => 0,    # candela, SI unit of luminous intensity
);

# This hash contains all of the units which will be accepted.  These must
# be defined in terms of the fundamental units given above.  If the power
# of the fundamental unit is not included it is assumed to be zero.

our $PI = 4 * atan2(1, 1);

# 9.80665 m/s^2  -- standard acceleration of gravity

our %known_units = (
	m => {
		factor  => 1,
		m       => 1,
		aliases => [ 'meter', 'meters', 'metre', 'metres' ]
	},
	kg => {
		factor => 1,
		kg     => 1
	},
	s => {
		factor  => 1,
		s       => 1,
		aliases => [ 'second', 'seconds', 'sec' ]
	},
	rad => {
		factor  => 1,
		rad     => 1,
		aliases => [ 'radian', 'radians' ]
	},
	degC => {
		factor  => 1,
		degC    => 1,
		aliases => [ "\x{00B0}C", "\x{2103}" ]
	},
	degF => {
		factor  => 1,
		degF    => 1,
		aliases => [ "\x{00B0}F", "\x{2109}" ]
	},
	K => {
		factor  => 1,
		K       => 1,
		aliases => [ "\x{212A}", 'degK', "\x{00B0}K" ]    # Should the degree forms be deleted? Probably.
	},
	mol => {
		factor => 1,
		mol    => 1
	},
	amp => {                                              # ampere
		factor  => 1,
		amp     => 1,
		aliases => ['A']
	},
	cd => {
		factor => 1,
		cd     => 1,
	},
	'%' => {
		factor => 0.01,
	},

	# ANGLES: fundamental unit rad (radian)
	deg => {    # degree
		factor  => 0.0174532925,
		rad     => 1,
		aliases => [ "\x{00B0}", 'degree', 'degrees' ]
	},
	sr => {     # steradian, a mesure of solid angle
		factor => 1,
		rad    => 2
	},

	# TIME: fundamental unit s (second)
	ms => {     # millisecond
		factor => 0.001,
		s      => 1
	},
	us => {     # microsecond
		factor  => 1E-6,
		s       => 1,
		aliases => ["\x{00B5}s"]
	},
	ns => {     # nanosecond
		factor => 1E-9,
		s      => 1
	},
	minute => {
		factor  => 60,
		s       => 1,
		aliases => [ 'minutes', 'min' ]
	},
	hour => {
		factor  => 3600,
		s       => 1,
		aliases => [ 'hours', 'hrs', 'hr', 'h' ]
	},
	day => {
		factor  => 86400,
		s       => 1,
		aliases => ['days']
	},
	month => {    # 60 * 60 * 24 * 30
		factor  => 2592000,
		s       => 1,
		aliases => [ 'months', 'mo' ]
	},
	year => {     # 365 days in a year
		factor  => 31557600,
		s       => 1,
		aliases => [ 'years', 'yr' ]
	},
	fortnight => {    # (FFF system) 2 weeks
		factor => 1209600,
		s      => 1
	},

	# LENGTHS: fundamental unit m (meter)

	# METRIC LENGTHS
	km => {    # kilometer
		factor => 1000,
		m      => 1
	},
	cm => {    # centimeter
		factor => 0.01,
		m      => 1
	},
	mm => {    # millimeter
		factor => 0.001,
		m      => 1
	},
	um => {    # micrometer
		factor  => 1E-6,
		m       => 1,
		aliases => [ 'micron', "\x{00B5}m" ]
	},
	nm => {    # nanometer
		factor => 1E-9,
		m      => 1
	},
	angstrom => {
		factor  => 1E-10,
		m       => 1,
		aliases => [ 'angstroms', 'Angstrom', 'Angstroms', "\x{00C5}" ]
	},
	pm => {    # picometer
		factor => 1E-12,
		m      => 1
	},
	fm => {    # femtometer
		factor => 1E-15,
		m      => 1
	},
	meter => {
		factor  => 1,
		m       => 1,
		aliases => ['meters']
	},

	# ENGLISH LENGTHS
	inch => {
		factor  => 0.0254,
		m       => 1,
		aliases => [ 'inches', 'in' ]
	},
	foot => {
		factor  => 0.3048,
		m       => 1,
		aliases => [ 'feet', 'ft' ]
	},
	mile => {
		factor  => 1609.344,
		m       => 1,
		aliases => [ 'miles', 'mi' ]
	},
	furlong => {    # (FFF system) 0.125 mile
		factor => 201.168,
		m      => 1
	},
	'light-year' => {    # 9.46E15,
		factor => 9460730472580800,
		m      => 1
	},
	AU => {              # Astronomical Unit
		factor => 149597870700,
		m      => 1
	},
	parsec => {          # 30.857E15,
		factor => 3.08567758149137E16,
		m      => 1
	},

	# VOLUME: fundamental unit m^3 (cubic meter)
	L => {               # liter
		factor => 0.001,
		m      => 3
	},
	ml => {              # milliliter (cubic centimeter)
		factor  => 1E-6,
		m       => 3,
		aliases => ['cc']
	},
	dL => {              # deciliter
		factor => 0.0001,
		m      => 3
	},
	# U.S./English volume units
	cup => {
		factor  => 0.000236588,
		m       => 3,
		aliases => ['cups']
	},
	pint => {
		factor  => 0.000473176473,
		m       => 3,
		aliases => [ 'pt', 'pints' ]
	},
	quart => {
		factor  => 0.000946352946,
		m       => 3,
		aliases => [ 'qt', 'quarts' ]
	},
	gallon => {
		factor  => 0.00378541,
		m       => 3,
		aliases => [ 'gallons', 'gal' ]
	},

	# VELOCITY: fundamental unit m/s (meters per second)
	knots => {    # nautical miles per hour
		factor => 0.5144444444,
		m      => 1,
		s      => -1
	},
	c => {        # exact speed of light
		factor => 299792458,
		m      => 1,
		s      => -1
	},
	mph => {
		factor => 0.44704,
		m      => 1,
		s      => -1
	},

	# MASS: fundamental unit kg (kilogram)

	# METRIC MASS
	mg => {    # milligrams
		factor => 0.000001,
		kg     => 1
	},
	g => {     # gram
		factor => 0.001,
		kg     => 1
	},
	tonne => {    # metric ton
		factor => 1000,
		kg     => 1
	},

	# ENGLISH MASS
	slug => {
		factor => 14.6,
		kg     => 1
	},
	firkin => {    # (FFF system) 90 lb, mass of a firkin of water
		factor => 40.8233133,
		kg     => 1
	},

	# FREQUENCY: fundamental unit rad/s (radians per second)
	Hz => {        # hertz
		factor => 2 * $PI,
		s      => -1,
		rad    => 1
	},
	kHz => {       # kilohertz
		factor => 2000 * $PI,
		s      => -1,
		rad    => 1
	},
	MHz => {       # megahertz (10^6 * 2pi)
		factor => (2E6) * $PI,
		s      => -1,
		rad    => 1
	},
	cycles => {    # or revolutions
		factor  => 2 * $PI,
		rad     => 1,
		aliases => ['rev']
	},

	# COMPOUND UNITS

	# FORCE: fundamental unit m kg / s^2
	N => {    # newton
		factor => 1,
		m      => 1,
		kg     => 1,
		s      => -2
	},
	uN => {    # micronewton
		factor  => 1E-6,
		m       => 1,
		kg      => 1,
		s       => -2,
		aliases => [ 'microN', "\x{00B5}N" ]
	},
	kN => {    # kilonewton
		factor => 1000,
		m      => 1,
		kg     => 1,
		s      => -2
	},
	dyne => {
		factor => 1E-5,
		m      => 1,
		kg     => 1,
		s      => -2
	},
	lb => {    # pound
		factor  => 4.4482216152605,
		m       => 1,
		kg      => 1,
		s       => -2,
		aliases => [ 'pound', 'pounds', 'lbs' ]
	},
	ton => {
		factor  => 8900,
		m       => 1,
		kg      => 1,
		s       => -2,
		aliases => ['tons']
	},

	# ENERGY: fundamental unit m^2 kg / s^2
	J => {    # joule
		factor => 1,
		m      => 2,
		kg     => 1,
		s      => -2
	},
	kJ => {    # kilojoule
		factor => 1000,
		m      => 2,
		kg     => 1,
		s      => -2
	},
	erg => {
		factor => 1E-7,
		m      => 2,
		kg     => 1,
		s      => -2
	},
	lbf => {    # foot pound
		factor => 1.35582,
		m      => 2,
		kg     => 1,
		s      => -2
	},
	kt => {     # kiloton
		factor => 4.184E12,
		m      => 2,
		kg     => 1,
		s      => -2
	},
	Mt => {     # megaton
		factor => 4.184E15,
		m      => 2,
		kg     => 1,
		s      => -2
	},
	cal => {    # calorie
		factor => 4.19,
		m      => 2,
		kg     => 1,
		s      => -2
	},
	kcal => {    # kilocalorie
		factor => 4190,
		m      => 2,
		kg     => 1,
		s      => -2
	},
	eV => {      # electron volt
		factor => 1.6022E-19,
		m      => 2,
		kg     => 1,
		s      => -2
	},
	keV => {     # kilo electron volt
		factor => 1.6022E-16,
		m      => 2,
		kg     => 1,
		s      => -2
	},
	MeV => {     # mega electron volt
		factor => 1.6022E-13,
		m      => 2,
		kg     => 1,
		s      => -2
	},
	GeV => {     # giga electron volt
		factor => 1.6022E-10,
		m      => 2,
		kg     => 1,
		s      => -2
	},
	TeV => {     # tera electron volt
		factor => 1.6022E-7,
		m      => 2,
		kg     => 1,
		s      => -2
	},
	kWh => {     # kilo Watt hour
		factor => 3.6E6,
		m      => 2,
		kg     => 1,
		s      => -2
	},

	# POWER: fundamental unit m kg / s^3
	W => {       # watt
		factor => 1,
		m      => 2,
		kg     => 1,
		s      => -3
	},
	kW => {      # kilowatt
		factor => 1000,
		m      => 2,
		kg     => 1,
		s      => -3
	},
	MW => {      # megawatt
		factor => 1E6,
		m      => 2,
		kg     => 1,
		s      => -3
	},
	mW => {      # milliwatt
		factor => 0.001,
		m      => 2,
		kg     => 1,
		s      => -3
	},
	hp => {      # horse power
		factor => 746,
		m      => 2,
		kg     => 1,
		s      => -3
	},

	# PRESSURE
	Pa => {      # pascal
		factor => 1,
		m      => -1,
		kg     => 1,
		s      => -2
	},
	kPa => {     # kilopascal
		factor => 1000,
		m      => -1,
		kg     => 1,
		s      => -2
	},
	MPa => {     # megapascal
		factor => 1E6,
		m      => -1,
		kg     => 1,
		s      => -2
	},
	GPa => {     # gigapascal
		factor => 1E9,
		m      => -1,
		kg     => 1,
		s      => -2
	},
	atm => {     # atmosphere
		factor => 1.01E5,
		m      => -1,
		kg     => 1,
		s      => -2
	},
	bar => {
		factor => 100000,
		m      => -1,
		kg     => 1,
		s      => -2
	},
	mbar => {    # millibar
		factor => 100,
		m      => -1,
		kg     => 1,
		s      => -2
	},
	Torr => {
		factor => 133.322,
		m      => -1,
		kg     => 1,
		s      => -2
	},
	mmHg => {
		factor => 133.322,
		m      => -1,
		kg     => 1,
		s      => -2
	},
	cmH2O => {    # centimeters of water
		factor => 98.0638,
		m      => -1,
		kg     => 1,
		s      => -2
	},
	psi => {      # pounds per square inch
		factor => 6895,
		m      => -1,
		kg     => 1,
		s      => -2
	},

	# ELECTRICAL UNITS
	C => {        # coulomb
		factor => 1,
		amp    => 1,
		s      => 1,
	},
	mC => {       # millicoulomb
		factor => 0.001,
		amp    => 1,
		s      => 1,
	},
	uC => {       # microcoulomb
		factor  => 1e-6,
		amp     => 1,
		s       => 1,
		aliases => ["\x{00B5}C"]
	},
	nC => {       # nanocoulomb
		factor => 1e-9,
		amp    => 1,
		s      => 1,
	},
	V => {        # volt (also J/C)
		factor => 1,
		kg     => 1,
		m      => 2,
		amp    => -1,
		s      => -3,
	},
	mV => {       # millivolt
		factor => 0.001,
		kg     => 1,
		m      => 2,
		amp    => -1,
		s      => -3,
	},
	kV => {       # killivolt
		factor => 1000,
		kg     => 1,
		m      => 2,
		amp    => -1,
		s      => -3,
	},
	MV => {       # megavolt
		factor => 1E6,
		kg     => 1,
		m      => 2,
		amp    => -1,
		s      => -3,
	},
	F => {        # farad (also C/V)
		factor => 1,
		amp    => 2,
		s      => 4,
		kg     => -1,
		m      => -2,
	},
	mF => {       # millifarad
		factor => 0.001,
		amp    => 2,
		s      => 4,
		kg     => -1,
		m      => -2,
	},
	uF => {       # microfarad
		factor  => 1E-6,
		amp     => 2,
		s       => 4,
		kg      => -1,
		m       => -2,
		aliases => [ "\x{00B5}F", "\x{338C}" ]
	},
	ohm => {      # V/amp
		factor  => 1,
		kg      => 1,
		m       => 2,
		amp     => -2,
		s       => -3,
		aliases => ["\x{2126}"]
	},
	kohm => {     # kiloohm
		factor  => 1000,
		kg      => 1,
		m       => 2,
		amp     => -2,
		s       => -3,
		aliases => [ "k\x{2126}", "\x{33C0}" ]
	},
	Mohm => {     # megaohm
		factor  => 1E6,
		kg      => 1,
		m       => 2,
		amp     => -2,
		s       => -3,
		aliases => [ "M\x{2126}", "\x{33C1}" ]
	},
	S => {        # siemens (1/ohm)
		factor => 1,
		kg     => -1,
		m      => -2,
		amp    => 2,
		s      => 3,
	},
	mA => {       # milliampere
		factor => 0.001,
		amp    => 1,
	},

	# MAGNETIC UNITS
	T => {        # tesla (also kg / A s^2 or N s / C m)
		factor => 1,
		kg     => 1,
		amp    => -1,
		s      => -2,
	},
	mT => {       # millitesla
		factor => 0.001,
		kg     => 1,
		amp    => -1,
		s      => -2,
	},
	G => {        # gauss
		factor => 1E-4,
		kg     => 1,
		amp    => -1,
		s      => -2,
	},
	Wb => {       # weber (also T m^2)
		factor => 1,
		kg     => 1,
		m      => 2,
		amp    => -1,
		s      => -2,
	},
	H => {        # henry (also V s/amp)
		factor => 1,
		kg     => 1,
		m      => 2,
		amp    => -2,
		s      => -2,
	},

	# LUMINOSITY
	lm => {       # lumen (luminous flux)
		factor => 1,
		cd     => 1,
		rad    => -2,
	},
	lx => {       # lux (illuminance)
		factor => 1,
		cd     => 1,
		rad    => -2,
		m      => -2,
	},

	# ATOMIC UNITS
	amu => {      # atomic mass units
		factor  => 1.660538921E-27,
		kg      => 1,
		aliases => ['dalton']
	},
	me => {       # electron rest mass
		factor => 9.1093826E-31,
		kg     => 1,
	},
	barn => {     # cross-sectional area
		factor => 1E-28,
		m      => 2,
	},
	a0 => {       # Bohr radius
		factor => 0.5291772108E-10,
		m      => 1,
	},

	# RADIATION
	Sv => {       # sievert, dose equivalent radiation (http://xkcd.com/radiation)
		factor => 1,
		m      => 2,
		s      => -2,
	},
	mSv => {      # millisievert (http://blog.xkcd.com/2011/03/19/radiation-chart)
		factor => 0.001,
		m      => 2,
		s      => -2,
	},
	uSv => {      # microsievert (http://blog.xkcd.com/2011/04/26/radiation-chart-update)
		factor  => 0.000001,
		m       => 2,
		s       => -2,
		aliases => ["\x{00B5}Sv"]
	},
	Bq => {       # becquerel, radioactivity (https://en.wikipedia.org/wiki/Becquerel)
		factor => 1,
		s      => -1,
	},

	# BIOLOGICAL & CHEMICAL UNITS
	mmol => {     # millimole
		factor => 0.001,
		mol    => 1,
	},
	micromol => {    # micromole
		factor => 1E-6,
		mol    => 1,
	},
	nanomol => {     # nanomole
		factor => 1E-9,
		mol    => 1,
	},
	kat => {         # katal (catalytic activity)
		factor => 1,
		mol    => 1,
		s      => -1,
	},

	# ASTRONOMICAL UNITS
	kpc => {         # kiloparsec
		factor => 30.857E18,
		m      => 1
	},
	Mpc => {         # megaparsec
		factor => 30.857E21,
		m      => 1
	},
	'solar-mass' => {    # solar mass
		factor => 1.98892E30,
		kg     => 1,
	},
	'solar-radii' => {    # solar radius
		factor => 6.955E8,
		m      => 1,
	},
	'solar-lum' => {      # solar luminosity
		factor => 3.8939E26,
		m      => 2,
		kg     => 1,
		s      => -3
	},
);

# Process aliases.
for my $unit (keys %known_units) {
	if (ref $known_units{$unit}{aliases} eq 'ARRAY') {
		my $aliases = delete $known_units{$unit}{aliases};
		$known_units{$_} = $known_units{$unit} for @$aliases;
	}
}

sub process_unit {

	my $string = shift;

	my $options = shift;

	my $fundamental_units = \%fundamental_units;
	my $known_units       = \%known_units;

	if (defined($options->{fundamental_units})) {
		$fundamental_units = $options->{fundamental_units};
	}

	if (defined($options->{known_units})) {
		$known_units = $options->{known_units};
	}

	die("UNIT ERROR: No units were defined.") unless defined($string);

	#split the string into numerator and denominator --- the separator is /
	my ($numerator, $denominator) = split(m{/}, $string);

	$denominator = "" unless defined($denominator);
	my %numerator_hash =
		process_term($numerator, { fundamental_units => $fundamental_units, known_units => $known_units });
	my %denominator_hash =
		process_term($denominator, { fundamental_units => $fundamental_units, known_units => $known_units });

	my %unit_hash = %$fundamental_units;
	for my $u (keys %unit_hash) {
		if ($u eq 'factor') {
			# calculate the correction factor for the unit
			$unit_hash{$u} = $numerator_hash{$u} / $denominator_hash{$u};
		} else {
			# calculate the power of the fundamental unit in the unit
			$unit_hash{$u} = $numerator_hash{$u} - $denominator_hash{$u};
		}
	}

	return (%unit_hash);
}

sub process_term {
	my $string  = shift;
	my $options = shift;

	my $fundamental_units = \%fundamental_units;
	my $known_units       = \%known_units;

	if (defined($options->{fundamental_units})) {
		$fundamental_units = $options->{fundamental_units};
	}

	if (defined($options->{known_units})) {
		$known_units = $options->{known_units};
	}

	my %unit_hash = %$fundamental_units;
	if ($string) {

		#split the numerator or denominator into factors -- the separators are *
		my @factors = split(/\*/, $string);

		for my $f (@factors) {
			my %factor_hash =
				process_factor($f, { fundamental_units => $fundamental_units, known_units => $known_units });

			for my $u (keys %unit_hash) {
				if ($u eq 'factor') {
					# calculate the correction factor for the unit
					$unit_hash{$u} = $unit_hash{$u} * $factor_hash{$u};
				} else {
					# calculate the power of the fundamental unit in the unit
					$unit_hash{$u} = $unit_hash{$u} + $factor_hash{$u};
				}
			}
		}
	}

	return (%unit_hash);
}

sub process_factor {
	my $string = shift;
	#split the factor into unit and powers

	my $options = shift;

	my $fundamental_units = \%fundamental_units;
	my $known_units       = \%known_units;

	if (defined($options->{fundamental_units})) {
		$fundamental_units = $options->{fundamental_units};
	}

	if (defined($options->{known_units})) {
		$known_units = $options->{known_units};
	}

	my ($unit_name, $power) = split(/\^/, $string);
	$power = 1 unless defined($power);
	my %unit_hash = %$fundamental_units;
	if (defined($known_units->{$unit_name})) {
		my %unit_name_hash = %{ $known_units->{$unit_name} };    # $reference_units contains all of the known units.
		for my $u (keys %unit_hash) {
			if ($u eq 'factor') {
				$unit_hash{$u} = $unit_name_hash{$u}**$power;    # calculate the correction factor for the unit
			} else {
				my $fundamental_unit = $unit_name_hash{$u};
				# a fundamental unit which doesn't appear in the unit need not be defined explicitly
				$fundamental_unit = 0 unless defined($fundamental_unit);
				# calculate the power of the fundamental unit in the unit
				$unit_hash{$u} = $fundamental_unit * $power;
			}
		}
	} else {
		die "UNIT ERROR Unrecognizable unit: |$unit_name|";
	}

	return %unit_hash;
}

# This is the "exported" subroutine.  Use this to evaluate the units given in an answer.
sub evaluate_units {
	my $unit    = shift;
	my $options = shift;

	my $fundamental_units = \%fundamental_units;
	my $known_units       = \%known_units;

	if (defined($options->{fundamental_units}) && $options->{fundamental_units}) {
		$fundamental_units = $options->{fundamental_units};
	}

	if (defined($options->{known_units}) && $options->{fundamental_units}) {
		$known_units = $options->{known_units};
	}

	my %output = eval { process_unit($unit, { fundamental_units => $fundamental_units, known_units => $known_units }) };
	if ($@) {
		%output = %$fundamental_units;
		$output{'ERROR'} = $@;
	}

	return %output;
}

1;
