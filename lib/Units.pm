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

our %FUNDAMENTAL_UNITS = (
	s => {
		factor   => 1,
		units    => { s => 1 },
		prefixes => [qw(n u m)],
		aliases  => [ 'second', 'seconds', 'sec' ]
	},
	m => {
		factor   => 1,
		units    => { m => 1 },
		prefixes => [qw(f p n u m c k)],
		aliases  => [ 'meter', 'meters', 'metre', 'metres' ]
	},
	kg => {
		factor => 1,
		units  => { kg => 1 }
	},
	A => {
		factor   => 1,
		units    => { A => 1 },
		prefixes => [qw(m)],
		string   => 'A',
		aliases  => ['amp']
	},
	K => {
		factor  => 1,
		units   => { K => 1 },
		aliases => [ "\x{212A}", 'degK', "\x{00B0}K" ],
		string  => "\x{212A}"
	},
	mol => {
		factor   => 1,
		units    => { mol => 1 },
		prefixes => [qw(m)]
	},
	cd => {
		factor => 1,
		units  => { cd => 1 }
	},
	rad => {
		factor  => 1,
		units   => { rad => 1 },
		aliases => [ 'radian', 'radians' ]
	},
	degC => {
		factor  => 1,
		units   => { degC => 1 },
		string  => "\x{00B0}C",
		aliases => [ "\x{00B0}C", "\x{2103}" ]
	},
	degF => {
		factor  => 1,
		units   => { degF => 1 },
		string  => "\x{00B0}F",
		aliases => [ "\x{00B0}F", "\x{2109}" ]
	}

);

# legacy hash
our %fundamental_units = (factor => 1, map { $_ => 0 } keys %FUNDAMENTAL_UNITS);

# This hash defines all of the units which can be accepted.  These must have:
#  - a numerical factor
#  - a units hash reference, possibly empty, and the keys must be keys from %FUNDAMENTAL_UNITS
#  Optionally:
#  - a string key with a string to use for text output. Characters used in this string may be
#    unicode characters but it should be checked that fonts in various output forms (HTML, TeX)
#    support those characters. If this is not provided, the actual name of the unit is used.
#  - a TeX key with a string to use for tex output. The same consideration for unicode characters
#    should be given. This will be wrapped in \text{...} for output, so don't include something
#    like that here, and also be aware of possible issues once your string is wrapped in \text{..}.
#    If this is not provided, the string option will be used instead. Or if that too is not
#    provided, the actual name of the unit is used.
#  - a noSeparator boolean key if there should be no space between a magnitude and that unit
#  - an aliases key pointing to an array reference of aliases
#  - a prefixes key pointing to an array reference of SI prefixes that are approved for use
#    with this unit
#  - a prefix_aliases key pointing to a hash reference where keys are SI prefix abbreviations,
#    and values are special unicode characters like "\x{338C}" which is a single chacter for
#    microFarad
#
# For all of these units, for all of their approved prefixes, prefixed units will be added
# automatically. When the unit has aliases, then for each alias that is 3 characters or shorter,
# aliases will be added to the prefixed variant that use the prefix and that alias. Hence we will
# have unit `ns` with an alias `nsec` but not the alias `nsecond`.
#
# For legacy tools (e.g. parserNumberWithUnits.pl, parserFormulaWithUnits.pl), all of the aliases
# will be added as units, all collected in the %known_units hash. The %unit_aliases hash will
# record the mapping from the original unit to all of its aliases. And the %unit_aliased_to
# hash is the inverse mapping.

our $PI = 4 * atan2(1, 1);

our %UNITS = (
	%FUNDAMENTAL_UNITS,
	'%' => {
		factor      => 0.01,
		units       => {},
		noSeparator => 1,
		aliases     => ['pct']
	},
	# ANGLES: fundamental unit rad (radian)
	deg => {
		factor      => $PI / 180,
		units       => { rad => 1 },
		string      => "\x{00B0}",
		noSeparator => 1,
		aliases     => [ "\x{00B0}", 'degree', 'degrees' ]
	},
	sr => {
		factor => 1,
		units  => { rad => 2 }
	},
	# TIME: fundamental unit s (second)
	min => {
		factor  => 60,
		units   => { s => 1 },
		aliases => [ 'minute', 'minutes' ]
	},
	h => {
		factor  => 3600,
		units   => { s => 1 },
		aliases => [ 'hour', 'hours', 'hr', 'hrs' ]
	},
	d => {
		factor  => 86400,
		units   => { s => 1 },
		aliases => [ 'day', 'days' ]
	},
	mo => {
		factor  => 2592000,                # 30 day month
		units   => { s => 1 },
		aliases => [ 'month', 'months' ]
	},
	yr => {                                # 365 day year
		factor  => 31557600,
		units   => { s => 1 },
		aliases => [ 'year', 'years' ]
	},
	fortnight => {
		factor => 1209600,
		units  => { s => 1 }
	},
	# LENGTHS: fundamental unit m (meter)
	micron => {
		factor => 1E-6,
		units  => { m => 1 }
	},
	angstrom => {
		factor  => 1E-10,
		units   => { m => 1 },
		string  => "\x{00C5}",
		aliases => [ "\x{00C5}", 'angstroms', 'Angstrom', 'Angstroms' ]
	},
	in => {
		factor  => 0.0254,
		units   => { m => 1 },
		aliases => [ 'inch', 'inches' ]
	},
	ft => {
		factor  => 0.3048,
		units   => { m => 1 },
		aliases => [ 'foot', 'feet' ]
	},
	mi => {
		factor  => 1609.344,
		units   => { m => 1 },
		aliases => [ 'mile', 'miles' ]
	},
	furlong => {
		factor => 201.168,
		units  => { m => 1 }
	},
	'light-year' => {
		factor => 9460730472580800,
		units  => { m => 1 }
	},
	AU => {
		factor => 149597870700,
		units  => { m => 1 }
	},
	pc => {
		factor   => 648000 / $PI * 149597870700,
		units    => { m => 1 },
		prefixes => [qw(k M)],
		aliases  => [ 'parsec', 'parsecs' ]
	},
	# VOLUME: fundamental unit m^3 (cubic meter)
	L => {
		factor   => 0.001,
		units    => { m => 3 },
		prefixes => [qw(m d)],
		aliases  => [ 'litre', 'litres', 'liter', 'liters', 'l' ]
	},
	cc => {
		factor => 1E-6,
		units  => { m => 3 }
	},
	cup => {
		factor  => 0.000236588,
		units   => { m => 3 },
		aliases => ['cups']
	},
	pt => {
		factor  => 0.000473176473,
		units   => { m => 3 },
		aliases => [ 'pint', 'pints' ]
	},
	qt => {
		factor  => 0.000946352946,
		units   => { m => 3 },
		aliases => [ 'quart', 'quarts' ]
	},
	gal => {
		factor  => 0.00378541,
		units   => { m => 3 },
		aliases => [ 'gallon', 'gallons' ]
	},
	# VELOCITY: fundamental unit m/s (meters per second)
	knots => {
		factor => 0.5144444444,
		units  => {
			s => -1,
			m => 1
		}
	},
	c => {
		factor => 299792458,
		units  => {
			s => -1,
			m => 1
		}
	},
	mph => {
		factor => 0.44704,
		units  => {
			s => -1,
			m => 1
		}
	},
	# MASS: fundamental unit kg (kilogram)
	g => {
		factor   => 0.001,
		units    => { kg => 1 },
		prefixes => [qw(m)]
	},
	tonne => {
		factor => 1000,
		units  => { kg => 1 }
	},
	slug => {
		factor => 14.6,
		units  => { kg => 1 }
	},
	firkin => {
		factor => 40.8233133,
		units  => { kg => 1 }
	},
	# FREQUENCY: fundamental unit rad/s (radians per second)
	Hz => {
		factor => 2 * $PI,
		units  => {
			s   => -1,
			rad => 1
		},
		prefixes => [qw(k M)]
	},
	cycles => {
		factor  => 2 * $PI,
		units   => { rad => 1 },
		aliases => ['rev']
	},
	# FORCE: fundamental unit m kg / s^2
	N => {
		factor => 1,
		units  => {
			s  => -2,
			m  =>  1,
			kg => 1
		},
		prefixes => [qw(u k)]
	},
	microN => {
		factor => 1E-6,
		units  => {
			s  => -2,
			m  =>  1,
			kg => 1
		}
	},
	dyne => {
		factor => 1E-5,
		units  => {
			s  => -2,
			m  =>  1,
			kg => 1
		}
	},
	lb => {
		factor => 4.4482216152605,
		units  => {
			s  => -2,
			m  =>  1,
			kg => 1
		},
		aliases => [ 'pound', 'pounds', 'lbs' ]
	},
	ton => {
		factor => 8900,
		units  => {
			s  => -2,
			m  =>  1,
			kg => 1
		},
		aliases => ['tons']
	},
	# ENERGY: fundamental unit m^2 kg / s^2
	J => {
		factor => 1,
		units  => {
			s  => -2,
			m  =>  2,
			kg => 1
		},
		prefixes => [qw(k)]
	},
	erg => {
		factor => 1E-7,
		units  => {
			s  => -2,
			m  =>  2,
			kg => 1
		}
	},
	lbf => {    #FIXME: this is foot pound but should be pound force
		factor => 1.35582,
		units  => {
			s  => -2,
			m  =>  2,
			kg => 1
		}
	},
	kt => {     # this is an energy unit (energy from so many tons of TNT)
		factor => 4.184E12,
		units  => {
			s  => -2,
			m  =>  2,
			kg => 1
		}
	},
	Mt => {     # this is an energy unit (energy from so many tons of TNT)
		factor => 4.184E15,
		units  => {
			s  => -2,
			m  =>  2,
			kg => 1
		}
	},
	cal => {
		factor => 4.19,
		units  => {
			s  => -2,
			m  =>  2,
			kg => 1
		},
		prefixes => [qw(k)]
	},
	eV => {
		factor => 1.6022E-19,
		units  => {
			s  => -2,
			m  =>  2,
			kg => 1
		},
		prefixes => [qw(k M G T)]
	},
	# POWER: fundamental unit m kg / s^3
	W => {
		factor => 1,
		units  => {
			s  => -3,
			m  =>  2,
			kg => 1
		},
		prefixes => [qw(m k M)]
	},
	hp => {
		factor => 746,
		units  => {
			s  => -3,
			m  =>  2,
			kg => 1
		}
	},
	# PRESSURE: fundamental unit kg / m / s^2
	Pa => {
		factor => 1,
		units  => {
			s  => -2,
			m  => -1,
			kg => 1
		},
		prefixes => [qw(k M G)]
	},
	atm => {
		factor => 1.01E5,
		units  => {
			s  => -2,
			m  => -1,
			kg => 1
		}
	},
	bar => {
		factor => 100000,
		units  => {
			s  => -2,
			m  => -1,
			kg => 1
		},
		prefixes => [qw(m)]
	},
	Torr => {
		factor => 133.322,
		units  => {
			s  => -2,
			m  => -1,
			kg => 1
		}
	},
	mmHg => {
		factor => 133.322,
		units  => {
			s  => -2,
			m  => -1,
			kg => 1
		}
	},
	cmH2O => {
		factor => 98.0638,
		units  => {
			s  => -2,
			m  => -1,
			kg => 1
		}
	},
	psi => {
		factor => 6895,
		units  => {
			s  => -2,
			m  => -1,
			kg => 1
		}
	},
	# ELECTRICAL UNITS
	C => {
		factor => 1,
		units  => {
			s => 1,
			A => 1
		},
		prefixes => [qw(n u m)]
	},
	V => {
		factor => 1,
		units  => {
			s  => -3,
			m  =>  2,
			kg =>  1,
			A  => -1
		},
		prefixes => [qw(m k M)]
	},
	F => {
		factor => 1,
		units  => {
			s  =>  4,
			m  => -2,
			kg => -1,
			A  => 2
		},
		prefixes       => [qw(u m)],
		prefix_aliases => { u => "\x{338C}" }
	},
	ohm => {
		factor => 1,
		units  => {
			s  => -3,
			m  =>  2,
			kg =>  1,
			A  => -2
		},
		prefixes       => [qw(k M)],
		string         => "\x{2126}",
		aliases        => ["\x{2126}"],
		prefix_aliases => {
			k => "\x{33C0}",
			M => "\x{33C1}"
		}
	},
	S => {
		factor => 1,
		units  => {
			s  =>  3,
			m  => -2,
			kg => -1,
			A  => 2
		}
	},
	# MAGNETIC UNITS
	T => {
		factor => 1,
		units  => {
			s  => -2,
			kg =>  1,
			A  => -1
		},
		prefixes => [qw(m)]
	},
	G => {
		factor => 1E-4,
		units  => {
			s  => -2,
			kg =>  1,
			A  => -1
		}
	},
	Wb => {
		factor => 1,
		units  => {
			s  => -2,
			m  =>  2,
			kg =>  1,
			A  => -1
		}
	},
	H => {
		factor => 1,
		units  => {
			s  => -2,
			m  =>  2,
			kg =>  1,
			A  => -2
		}
	},
	# LUMINOSITY
	lm => {
		factor => 1,
		units  => {
			cd  => 1,
			rad => -2
		}
	},
	lx => {
		factor => 1,
		units  => {
			m   => -2,
			cd  =>  1,
			rad => -2
		}
	},
	# ATOMIC UNITS
	amu => {
		factor  => 1.660538921E-27,
		units   => { kg => 1 },
		aliases => ['dalton']
	},
	me => {
		factor => 9.1093826E-31,
		units  => { kg => 1 }
	},
	barn => {
		factor => 1E-28,
		units  => { m => 2 }
	},
	a0 => {
		factor => 0.5291772108E-10,
		units  => { m => 1 }
	},
	# RADIATION
	Sv => {
		factor => 1,
		units  => {
			s => -2,
			m => 2
		},
		prefixes => [qw(u m)]
	},
	Bq => {
		factor => 1,
		units  => { s => -1 }
	},
	# BIOLOGICAL & CHEMICAL UNITS
	micromol => {
		factor => 1E-6,
		units  => { mol => 1 }
	},
	nanomol => {
		factor => 1E-9,
		units  => { mol => 1 }
	},
	kat => {
		factor => 1,
		units  => {
			s   => -1,
			mol => 1
		}
	},
	# ASTRONOMICAL UNITS
	'solar-mass' => {
		factor => 1.98892E30,
		units  => { kg => 1 }
	},
	'solar-radii' => {
		factor => 6.955E8,
		units  => { m => 1 }
	},
	'solar-lum' => {
		factor => 3.8939E26,
		units  => {
			s  => -3,
			m  =>  2,
			kg => 1
		}
	},
);

# Expand to include prefixes
my %prefixes = (
	f => 1E-15,
	p => 1E-12,
	n => 1E-9,
	u => 1E-6,
	m => 1E-3,
	c => 1E-2,
	d => 1E-1,
	k => 1E3,
	M => 1E6,
	G => 1E9,
	T => 1E12
);

for my $name (keys %UNITS) {
	for my $prefix (@{ $UNITS{$name}{prefixes} }) {
		if ($prefix ne 'u') {
			$UNITS{"$prefix$name"} = {
				factor => $prefixes{$prefix} * $UNITS{$name}{factor},
				units  => { %{ $UNITS{$name}{units} } },
				$UNITS{$name}{string} ? (string => "$prefix$UNITS{$name}{string}") : (),
				$UNITS{$name}{TeX}    ? (TeX    => "$prefix$UNITS{$name}{TeX}")    : (),
			};
			# if $name had short aliases, apply prefixes to those short aliases
			my @short_aliases = grep { length($_) <= 3 } @{ $UNITS{$name}{aliases} };
			$UNITS{"$prefix$name"}{aliases} = [ map {"$prefix$_"} @short_aliases ] if @short_aliases;
		} else {
			$UNITS{"u$name"} = {
				factor => $prefixes{u} * $UNITS{$name}{factor},
				units  => { %{ $UNITS{$name}{units} } },
				string => $UNITS{$name}{string} ? "\x{00B5}$UNITS{$name}{string}" : "\x{00B5}$name",
				TeX    => $UNITS{$name}{TeX}    ? "\x{00B5}$UNITS{$name}{TeX}"    : "\x{00B5}$name",
			};
			my @short_aliases = grep { length($_) <= 3 } @{ $UNITS{$name}{aliases} };
			$UNITS{"$prefix$name"}{aliases} = [ "\x{00B5}$name", map {"$prefix$_"} @short_aliases ];
		}
		push @{ $UNITS{"$prefix$name"}{aliases} }, $UNITS{$name}{prefix_aliases}{$prefix}
			if $UNITS{$name}{prefix_aliases}{$prefix};
	}
	delete $UNITS{$name}{prefixes};
	delete $UNITS{$name}{prefix_aliases};
}

# Legacy map of unit names to units-with-factors
our %known_units;

for my $name (keys %UNITS) {
	my $unit = $UNITS{$name};
	$known_units{$name} = { factor => $unit->{factor}, %{ $unit->{units} } };
	$known_units{$name}{aliases} = $unit->{aliases} if $unit->{aliases};
}

# A map from unit name to its aliases
our %unit_aliases;

# A map from units name to what it is an alias for
our %unit_aliased_to;

# Process aliases.

for my $unit (keys %known_units) {
	if (ref $known_units{$unit}{aliases} eq 'ARRAY') {
		my $aliases = delete $known_units{$unit}{aliases};
		$known_units{$_}     = $known_units{$unit} for @$aliases;
		$unit_aliased_to{$_} = $unit               for @$aliases;
		$unit_aliases{$unit} = $aliases;
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
