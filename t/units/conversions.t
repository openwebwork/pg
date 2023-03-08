#!/usr/bin/perl -w

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

use lib "$ENV{PG_ROOT}/lib";
use Units;

subtest 'Check fundamental units' => sub {
	is \%Units::fundamental_units,
		{
			factor => 1,
			m      => 0,
			kg     => 0,
			s      => 0,
			rad    => 0,
			degC   => 0,
			degF   => 0,
			degK   => 0,
			mol    => 0,
			amp    => 0,
			cd     => 0,
		},
		'Fundamental units correct'; # or bail_out('Evaluating units doomed to failure if fundamental_units is borked');

	my @base_units = keys %Units::fundamental_units;
	is \%Units::known_units, hash {
		field m => { factor => 1, m => 1 };

		all_keys match qr/^(?:[a-z02]+(?:-\w+)?|%|\p{L}|\p{S}\w?)$/i;
		all_vals hash {
			field factor => !number(0);

			all_keys in_set(@base_units);
			all_vals match qr/\d/;    # all integers except for factor, which is a non-zero float
			etc();
		};

		etc();
	}, 'Known units have consistent structure';
};

subtest 'Check base units' => sub {
	is { evaluate_units('kg') },  in_base_units(kg => 1, factor => 1), 'kilogram';
	is { evaluate_units('N') },   in_base_units(kg => 1, m => 1, s => -2, factor => 1), 'Newton';
	is { evaluate_units('C') },   in_base_units(amp => 1, s => 1, factor => 1), 'Coulomb';
	is { evaluate_units('V') },   in_base_units(amp => -1, s => -3, kg => 1, m => 2, factor => 1), 'Volt';
	is { evaluate_units('J*s') }, in_base_units(kg => 1, m => 2, s => -1, factor => 1), 'Joule-seconds';

	is { evaluate_units('V/m') },
		in_base_units(kg => 1, m => 1, s => -3, amp => -1, factor => 1),
		'Volts per metre';
	is { evaluate_units('N/C') },
		in_base_units(kg => 1, m => 1, s => -3, amp => -1, factor => 1),
		'Newtons per Coulomb';
};

subtest 'Check equivalent electrical units' => sub {
	is { evaluate_units('N/C') }, { evaluate_units('V/m') },       'N/C = V/m';
	is { evaluate_units('C/N') }, { evaluate_units('m/V') },       'C/N = m/V';
	is { evaluate_units('N/C') }, { evaluate_units('J/amp*m*s') }, 'N/C = J/amp*m*s';
	is { evaluate_units('V/m') }, { evaluate_units('N/C') },       'V/m = N/C';
};

subtest 'Check electrical units' => sub {
	is multiply_by(1000, evaluate_units('mF')),  { evaluate_units('F') },    'millifarad conversion';
	is multiply_by(1E6,  evaluate_units('uF')),  { evaluate_units('F') },    'microfarad conversion';
	is multiply_by(1000, evaluate_units('ohm')), { evaluate_units('kohm') }, 'kilo-ohm conversion';
	is multiply_by(1E6,  evaluate_units('ohm')), { evaluate_units('Mohm') }, 'kilo-ohm conversion';
	is multiply_by(1000, evaluate_units('mV')),  { evaluate_units('V') },    'millivolt conversion';
	is multiply_by(1000, evaluate_units('V')),   { evaluate_units('kV') },   'kilovolt conversion';
};

subtest 'Check magnetic units' => sub {
	is multiply_by(1e4, evaluate_units('G')), { evaluate_units('T') }, 'magnetic field strength conversion';
	is { evaluate_units('V/ohm') }, { evaluate_units('V*S') },     'conductivity definition';
	is { evaluate_units('Wb') },    { evaluate_units('T*m^2') },   'Weber definition';
	is { evaluate_units('H') },     { evaluate_units('V*s/amp') }, 'Henry definition';
};

subtest 'Check biological and chemical units' => sub {
	is multiply_by(1000, evaluate_units('micromol/L')), { evaluate_units('mmol/L') }, 'concentration conversion';
	is multiply_by(10,   evaluate_units('mg/L')),       { evaluate_units('mg/dL') },  'concentration conversion';
	is multiply_by(1e9,  evaluate_units('nanomol')),    { evaluate_units('mol') },    'concentration conversion';
};

subtest 'Check radiation units' => sub {
	is multiply_by(1000, evaluate_units('mSv')), { evaluate_units('Sv') }, 'milli-Sievert conversion';
	is multiply_by(1e6,  evaluate_units('uSv')), { evaluate_units('Sv') }, 'micro-Sievert conversion';
	is { evaluate_units('kat') }, { evaluate_units('mol/s') }, 'catalitic activity';
};

subtest 'Check a collection of units' => sub {
	is multiply_by(1822.88854680448, evaluate_units('me')), { evaluate_units('amu') }, 'atomic mass conversion';

	is { evaluate_units('lx') }, { evaluate_units('lm/m^2') }, 'lux = lumen per square metre';

	is multiply_by(1e9,  evaluate_units('Pa')),  { evaluate_units('GPa') }, 'gigapascal conversion';
	is multiply_by(1000, evaluate_units('kPa')), { evaluate_units('MPa') }, 'kilopascal conversion';

	is multiply_by(2 * 1000 * $Units::PI, evaluate_units('rad/s')),
		{ evaluate_units('kHz') },
		'kilohertz conversion';

	is multiply_by(0.01, %Units::fundamental_units), { evaluate_units('%') }, 'percent conversion';

	my $todo = todo 'use within() to fudge factor in 9th decimal place';
	is multiply_by((180 / $Units::PI)**2, evaluate_units('deg^2')),
		{ evaluate_units('sr') },
		'solid angle conversion';
};

subtest 'Check astronomical units' => sub {
	my $second_arc = 0.0174532925 / 60 / 60;

	is multiply_by(299792458, evaluate_units('m/s')), { evaluate_units('c') }, 'speed of light conversion';
	is { evaluate_units('c*yr') }, { evaluate_units('light-year') }, 'light year';

	my $todo = todo 'use within() to fudge factor in 9th decimal place';
	is multiply_by(cos($second_arc) / sin($second_arc), evaluate_units('AU')),
		{ evaluate_units('parsec') },
		'parsec conversion';
};

subtest 'Additional electrical units' => sub {
	is multiply_by(1000, evaluate_units('eV')), { evaluate_units('keV') }, 'kilo-electron volt conversion';
	is multiply_by(1E6,  evaluate_units('eV')), { evaluate_units('MeV') }, 'mega-electron volt conversion';
	is multiply_by(1E9,  evaluate_units('eV')), { evaluate_units('GeV') }, 'giga-electron volt conversion';

	is multiply_by(1000, evaluate_units('mC')), { evaluate_units('C') }, 'miliCoulomb conversion';
	is multiply_by(1E6,  evaluate_units('uC')), { evaluate_units('C') }, 'microCoulomb conversion';
};

done_testing();

sub in_base_units {
	my %provided_units = @_;
	return { %Units::fundamental_units, %provided_units };
}

sub multiply_by {
	my ($conversion, %unit) = @_;
	$unit{factor} *= $conversion;
	return \%unit;
}

