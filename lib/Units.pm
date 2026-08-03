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
	s      => 0,
	m      => 0,
	kg     => 0,
	A      => 0,
	K      => 0,
	mol    => 0,
	cd     => 0,
	rad    => 0,
	degC   => 0,
	degF   => 0,
);

# This hash defines all of the units which can be accepted, organized into
# categories (angles, time, length, and so on). Each category is a hash
# reference with the keys:
#  - default_fundamental_units: a hash reference giving the powers of the
#    fundamental units shared by the units in this category
#  - definitions: a hash reference of unit name to unit definition
#
# Each unit definition must have:
#  - a numerical factor
#  Optionally:
#  - a fundamental_units hash reference, overriding the category's
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
#  - a no_legacy boolean key if this unit should be omitted (along with all of its aliases) from
#    the legacy %known_units hash described below. New units added to %UNITS can have this key to
#    preserve the legacy %known_units. Also this is necessary for a unit whose name (in one
#    category) collides with a different unit name (in another category) to ensure which one ends
#    up in %known_units.
#
# For all of these units, for all of their approved prefixes, prefixed units will be added
# automatically. When the unit has aliases, then for each alias that is 3 characters or shorter,
# aliases will be added to the prefixed variant that use the prefix and that alias. Hence we will
# have unit `ns` with an alias `nsec` but not the alias `nsecond`.
#
# Each entry of an aliases array is normally just the alias name (a string). An entry may instead
# be a hash reference with a single key, the alias name, whose value is a hash of options for that
# alias. The only option currently supported is no_legacy, which excludes that one alias (but not
# the unit itself or its other aliases) from the legacy %known_units hash. This is how "c" is
# added below as an alias for "cup" without disturbing "c" as the legacy symbol for the speed of
# light. Once %known_units has been built, all no_legacy keys (and the hash references used to
# attach them to individual aliases) are stripped back out of %UNITS, so nothing that reads %UNITS
# directly (e.g. contextUnits.pl) ever has to know about them.
#
# For legacy tools (e.g. parserNumberWithUnits.pl, parserFormulaWithUnits.pl), all of the aliases
# will be added as units, all collected in the %known_units hash. The %unit_aliases hash will
# record the mapping from the original unit to all of its aliases. And the %unit_aliased_to
# hash is the inverse mapping.

our $PI = 4 * atan2(1, 1);

our %UNITS = (
	dimensionless => {
		default_fundamental_units => {},
		definitions               => {
			'%' => {
				factor      => 0.01,
				noSeparator => 1,
				aliases     => ['pct']
			},
			permille => {
				factor      => 0.001,
				string      => "\x{2030}",
				noSeparator => 1,
				aliases     => ["\x{2030}"],
				no_legacy   => 1
			},
			ppm => { factor => 1E-6, no_legacy => 1 },
		}
	},
	# ANGLES: fundamental unit rad (radian)
	angles => {
		default_fundamental_units => { rad => 1 },
		definitions               => {
			rad => { factor => 1, aliases => [ 'radian', 'radians' ] },
			deg => {
				factor      => $PI / 180,
				string      => "\x{00B0}",
				noSeparator => 1,
				aliases     => [ "\x{00B0}", 'degree', 'degrees' ]
			},
			grad => { factor => $PI / 200 },
			rev  => { factor => 2 * $PI },
			sr   => { factor => 1, fundamental_units => { rad => 2 } },
		}
	},
	# TIME: fundamental unit s (second)
	time => {
		default_fundamental_units => { s => 1 },
		definitions               => {
			s => {
				factor   => 1,
				prefixes => [qw(n u m)],
				aliases  => [ 'second', 'seconds', 'sec' ]
			},
			min => {
				factor  => 60,
				aliases => [ 'minute', 'minutes' ]
			},
			h => {
				factor  => 3600,
				aliases => [ 'hour', 'hours', 'hr', 'hrs' ]
			},
			d => {
				factor  => 86400,
				aliases => [ 'day', 'days' ]
			},
			wk => {
				factor    => 86400 * 7,
				aliases   => [ 'week', 'weeks' ],
				no_legacy => 1
			},
			fortnight => { factor => 1209600 },
			mo        => {
				factor  => 2592000,                # 30 day month
				aliases => [ 'month', 'months' ]
			},
			yr => {                                # 365 day year
				factor  => 31557600,
				aliases => [ 'year', 'years', { y => { no_legacy => 1 } } ]
			},
		}
	},
	# LENGTHS: fundamental unit m (meter)
	length => {
		default_fundamental_units => { m => 1 },
		definitions               => {
			m => {
				factor   => 1,
				prefixes => [qw(f p n u m c k)],
				aliases  => [ 'meter', 'meters', 'metre', 'metres' ]
			},
			micron   => { factor => 1E-6 },
			angstrom => {
				factor  => 1E-10,
				string  => "\x{00C5}",
				aliases => [ "\x{00C5}", 'angstroms', 'Angstrom', 'Angstroms' ]
			},
			in => {
				factor  => 0.0254,
				aliases => [ 'inch', 'inches' ]
			},
			ft => {
				factor  => 0.3048,
				aliases => [ 'foot', 'feet' ]
			},
			yd => {
				factor    => 0.9144,
				aliases   => [ 'yard', 'yards' ],
				no_legacy => 1
			},
			mi => {
				factor  => 1609.344,
				aliases => [ 'mile', 'miles' ]
			},
			furlong => { factor => 201.168 },
		}
	},
	# VOLUME: fundamental unit m^3 (cubic meter)
	volume => {
		default_fundamental_units => { m => 3 },
		definitions               => {
			L => {
				factor   => 0.001,
				prefixes => [qw(m d)],
				aliases  => [ 'litre', 'litres', 'liter', 'liters', 'l' ]
			},
			cc      => { factor => 1E-6 },
			tsp     => { factor => 4.92892159375E-6,  aliases => ['t'],          no_legacy => 1 },
			Tbsp    => { factor => 1.478676478125E-5, aliases => [ 'T', 'tbs' ], no_legacy => 1 },
			'fl oz' => { factor => 2.95735295625E-5,  aliases => ['floz'],       no_legacy => 1 },
			cup     => {
				factor => 0.0002365882365,
				# "c" collides with the velocity category's symbol for the speed of light, so it
				# is marked no_legacy.
				aliases => [ 'cups', { c => { no_legacy => 1 } } ]
			},
			pt => {
				factor  => 0.000473176473,
				aliases => [ 'pint', 'pints' ]
			},
			qt => {
				factor  => 0.000946352946,
				aliases => [ 'quart', 'quarts' ]
			},
			gal => {
				factor  => 0.00378541,
				aliases => [ 'gallon', 'gallons' ]
			},
		}
	},
	# VELOCITY: fundamental unit m/s (meters per second)
	velocity => {
		default_fundamental_units => { s => -1, m => 1 },
		definitions               => {
			knots => { factor => 0.5144444444, aliases => [ { kn => { no_legacy => 1 } } ] },
			c     => { factor => 299792458 },
			mph   => { factor => 0.44704 },
		}
	},
	# MASS: fundamental unit kg (kilogram)
	mass => {
		default_fundamental_units => { kg => 1 },
		definitions               => {
			kg    => { factor => 1 },
			g     => { factor => 0.001, prefixes => [qw(m)] },
			tonne => { factor => 1000,  aliases  => [ { t => { no_legacy => 1 } } ] },
			oz    => {
				factor    => 0.02834952,
				aliases   => [ 'ounce', 'ounces' ],
				no_legacy => 1
			},
			lb => {
				factor    => 0.45359237,
				aliases   => [ 'pound', 'pounds' ],
				no_legacy => 1
			},
			tn => {
				factor    => 907.18474,
				aliases   => [ 'ton', 'tons' ],
				no_legacy => 1
			},
			slug   => { factor => 14.6 },
			firkin => { factor => 40.8233133 },
		}
	},
	# TEMPERATURE: fundamental units K, degC, degF (not convertible between
	# each other here, since that would require affine, not scalar, conversion)
	temperature => {
		default_fundamental_units => { K => 1 },
		definitions               => {
			K => {
				factor  => 1,
				aliases => [ "\x{212A}", 'degK', "\x{00B0}K" ],
				string  => "\x{212A}"
			},
			degC => {
				factor            => 1,
				fundamental_units => { degC => 1 },
				string            => "\x{00B0}C",
				aliases           => [ "\x{00B0}C", "\x{2103}" ]
			},
			degF => {
				factor            => 1,
				fundamental_units => { degF => 1 },
				string            => "\x{00B0}F",
				aliases           => [ "\x{00B0}F", "\x{2109}" ]
			},
		}
	},
	# FREQUENCY: fundamental unit rad/s (radians per second)
	frequency => {
		default_fundamental_units => { s => -1, rad => 1 },
		definitions               => {
			Hz => {
				factor   => 2 * $PI,
				prefixes => [qw(k M)]
			},
			rpm => {
				factor    => 2 * $PI / 60,
				no_legacy => 1
			},
			cycles => {
				factor            => 2 * $PI,
				fundamental_units => { rad => 1 },
			},
		}
	},
	# FORCE: fundamental unit m kg / s^2
	force => {
		default_fundamental_units => { s => -2, m => 1, kg => 1 },
		definitions               => {
			N      => { factor => 1, prefixes => [qw(u k)] },
			microN => { factor => 1E-6 },
			dyne   => { factor => 1E-5, aliases => [ { dyn => { no_legacy => 1 } } ] },
			lb     => {
				factor  => 4.4482216152605,
				aliases => [ 'pound', 'pounds', 'lbs' ]
			},
			lbf => {
				factor    => 4.4482216152605,
				no_legacy => 1
			},
			ton => {
				factor  => 8900,
				aliases => ['tons']
			},
		}
	},
	# ENERGY: fundamental unit m^2 kg / s^2
	energy => {
		default_fundamental_units => { s => -2, m => 2, kg => 1 },
		definitions               => {
			J   => { factor => 1, prefixes => [qw(k)] },
			kWh => { factor => 3.6E6 },       # kW and h are valid units, but this is a common enough energy unit
			erg => { factor => 1E-7 },
			lbf => { factor => 1.35582 },     # FIXME: this is foot pound but should be pound force
			kt  => { factor => 4.184E12 },    # this is an energy unit (energy from so many tons of TNT)
			Mt  => { factor => 4.184E15 },    # this is an energy unit (energy from so many tons of TNT)
			cal => { factor => 4.19,        prefixes  => [qw(k)] },
			eV  => { factor => 1.6022E-19,  prefixes  => [qw(k M G T)] },
			BTU => { factor => 1055.055853, no_legacy => 1 }
		}
	},
	# POWER: fundamental unit m kg / s^3
	power => {
		default_fundamental_units => { s => -3, m => 2, kg => 1 },
		definitions               => {
			W  => { factor => 1, prefixes => [qw(m k M)] },
			hp => { factor => 746 },
		}
	},
	# PRESSURE: fundamental unit kg / m / s^2
	pressure => {
		default_fundamental_units => { s => -2, m => -1, kg => 1 },
		definitions               => {
			Pa    => { factor => 1, prefixes => [qw(k M G)] },
			atm   => { factor => 1.01E5 },
			bar   => { factor => 100000, prefixes => [qw(m)] },
			Torr  => { factor => 133.322 },
			mmHg  => { factor => 133.322 },
			cmH2O => { factor => 98.0638 },
			psi   => { factor => 6895 },
		}
	},
	# ELECTRICAL UNITS
	electricity => {
		default_fundamental_units => { s => 1, A => 1 },
		definitions               => {
			A => {
				factor            => 1,
				fundamental_units => { A => 1 },
				prefixes          => [qw(m)],
				string            => 'A',
				aliases           => ['amp']
			},
			C => { factor => 1, prefixes => [qw(n u m)] },
			V => {
				factor            => 1,
				fundamental_units => { s => -3, m => 2, kg => 1, A => -1 },
				prefixes          => [qw(m k M)]
			},
			F => {
				factor            => 1,
				fundamental_units => { s => 4, m => -2, kg => -1, A => 2 },
				prefixes          => [qw(u m)],
				prefix_aliases    => { u => "\x{338C}" }
			},
			ohm => {
				factor            => 1,
				fundamental_units => { s => -3, m => 2, kg => 1, A => -2 },
				prefixes          => [qw(k M)],
				string            => "\x{2126}",
				aliases           => ["\x{2126}"],
				prefix_aliases    => {
					k => "\x{33C0}",
					M => "\x{33C1}"
				}
			},
			S => { factor => 1, fundamental_units => { s => 3, m => -2, kg => -1, A => 2 } },
		}
	},
	# MAGNETIC UNITS
	magnetism => {
		default_fundamental_units => { s => -2, kg => 1, A => -1 },
		definitions               => {
			T  => { factor => 1, prefixes => [qw(m)] },
			G  => { factor => 1E-4 },
			Wb => { factor => 1, fundamental_units => { s => -2, m => 2, kg => 1, A => -1 } },
			H  => { factor => 1, fundamental_units => { s => -2, m => 2, kg => 1, A => -2 } },
		}
	},
	# LUMINOSITY
	luminosity => {
		default_fundamental_units => { cd => 1, rad => -2 },
		definitions               => {
			cd => { factor => 1, fundamental_units => { cd => 1 } },
			lm => { factor => 1 },
			lx => { factor => 1, fundamental_units => { m => -2, cd => 1, rad => -2 } },
		}
	},
	# ATOMIC UNITS
	atomics => {
		default_fundamental_units => { kg => 1 },
		definitions               => {
			amu => {
				factor  => 1.660538921E-27,
				aliases => [ 'dalton', { u => { no_legacy => 1 } } ]
			},
			me   => { factor => 9.1093826E-31 },
			barn => { factor => 1E-28,            fundamental_units => { m => 2 } },
			a0   => { factor => 0.5291772108E-10, fundamental_units => { m => 1 } },
		}
	},
	# RADIATION
	radiation => {
		default_fundamental_units => { s => -2, m => 2 },
		definitions               => {
			Sv => { factor => 1,      prefixes          => [qw(u m)] },
			Gy => { factor => 1,      no_legacy         => 1 },
			Ci => { factor => 3.7E10, fundamental_units => { s => -1 } },
			Bq => { factor => 1,      fundamental_units => { s => -1 } },
		}
	},
	# BIOLOGICAL & CHEMICAL UNITS
	biochem => {
		default_fundamental_units => { mol => 1 },
		definitions               => {
			mol      => { factor => 1, prefixes => [qw(m)] },
			micromol => { factor => 1E-6 },
			nanomol  => { factor => 1E-9 },
			kat      => { factor => 1, fundamental_units => { s => -1, mol => 1 } },
		}
	},
	# ASTRONOMICAL UNITS
	astronomy => {
		default_fundamental_units => { m => 1 },
		definitions               => {
			'light-year' => { factor => 9460730472580800, aliases => [ { ly => { no_legacy => 1 } } ] },
			AU           => { factor => 149597870700 },
			pc           => {
				factor   => 648000 / $PI * 149597870700,
				prefixes => [qw(k M)],
				aliases  => [ 'parsec', 'parsecs' ]
			},
			'solar-radii' => { factor => 6.955E8 },
			'solar-mass'  => { factor => 1.98892E30, fundamental_units => { kg => 1 } },
			'solar-lum'   => {
				factor            => 3.8939E26,
				fundamental_units => { s => -3, m => 2, kg => 1 },
				aliases           => [ { L0 => { no_legacy => 1 } } ]
			},
		}
	},
);

# The SI prefixes and their multiplicative factors.
our %PREFIXES = (
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

# Legacy units hash
our %known_units;

for my $category (values %UNITS) {
	my $default_fundamental_units = $category->{default_fundamental_units};
	for my $name (keys %{ $category->{definitions} }) {
		my $definition = $category->{definitions}{$name};
		next if $definition->{no_legacy};
		my $units = $definition->{fundamental_units} // $default_fundamental_units;

		# Exclude aliases with no_legacy => 1
		my @aliases =
			map { ref $_ eq 'HASH' ? ((values %$_)[0]{no_legacy} ? () : (keys %$_)[0]) : $_ }
			@{ $definition->{aliases} || [] };

		$known_units{$name} = { factor => $definition->{factor}, %$units };
		$known_units{$name}{aliases} = \@aliases if @aliases;

		for my $prefix (@{ $definition->{prefixes} || [] }) {
			my @short_aliases = grep { length($_) <= 3 } @aliases;
			my @prefixed_aliases =
				$prefix eq 'u' ? ("\x{00B5}$name", map {"u$_"} @short_aliases) : (map {"$prefix$_"} @short_aliases);
			push @prefixed_aliases, $definition->{prefix_aliases}{$prefix} if $definition->{prefix_aliases}{$prefix};

			$known_units{"$prefix$name"} = { factor => $PREFIXES{$prefix} * $definition->{factor}, %$units };
			$known_units{"$prefix$name"}{aliases} = \@prefixed_aliases if @prefixed_aliases;
		}
	}
}

# The no_legacy markers have now served their purpose (excluding certain units and aliases from
# %known_units above), so strip them from %UNITS
for my $category (values %UNITS) {
	for my $definition (values %{ $category->{definitions} }) {
		delete $definition->{no_legacy};
		$definition->{aliases} = [ map { ref $_ eq 'HASH' ? (keys %$_)[0] : $_ } @{ $definition->{aliases} } ]
			if $definition->{aliases};
	}
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
