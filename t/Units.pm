

# This is the "exported" subroutine.  Use this to evaluate the units given in an answer.

sub evaluate_units {
	&Units::evaluate_units;
}

# Methods for evaluating units in answers
package Units;

#require Exporter;
#@ISA = qw(Exporter);
#@EXPORT = qw(evaluate_units);


# compound units are entered such as m/sec^2 or kg*m/sec^2
# the format is unit[^power]*unit^[*power].../  unit^power*unit^power....
# there can be only one / in a unit.
# powers can be negative integers as well as positive integers.

    # These subroutines return a unit hash.
    # A unit hash has the entries
    #      factor => number   number can be any real number
    #      m      => power    power is a signed integer
    #      kg     => power
    #      s      => power
    #      rad    => power
    #      degC   => power
    #      degF   => power
    #      degK   => power
    #      mol	  => power
	#	   amp	  => power
	#	   cd	  => power

# Unfortunately there will be no automatic conversion between the different
# temperature scales since we haven't allowed for affine conversions.

our %fundamental_units = ('factor' => 1,
                     'm'      => 0,
                     'kg'     => 0,
                     's'      => 0,
                     'rad'    => 0,
                     'degC'   => 0,
                     'degF'   => 0,
                     'degK'   => 0,
                     'mol'    => 0,  # moles, treated as a fundamental unit
                     'amp'    => 0,
                     'cd'     => 0,  # candela, SI unit of luminous intensity
);


# This hash contains all of the units which will be accepted.  These must
# be defined in terms of the fundamental units given above.  If the power
# of the fundamental unit is not included it is assumed to be zero.

our $PI = 4*atan2(1,1);
#         9.80665 m/s^2  -- standard acceleration of gravity

our %known_units = ('m'  => {
                           'factor'    => 1,
                           'm'         => 1
                          },
                 'kg'  => {
                           'factor'    => 1,
                           'kg'        => 1
                          },
                 's'  => {
                           'factor'    => 1,
                           's'         => 1
                          },
                'rad' => {
                           'factor'    => 1,
                           'rad'       => 1
                          },
               'degC' => {
                           'factor'    => 1,
                           'degC'      => 1
                          },
               'degF' => {
                           'factor'    => 1,
                           'degF'      => 1
                          },
               'degK' => {
                           'factor'    => 1,
                           'degK'      => 1
                          },
               'mol'  => {
                           'factor'    =>1,
                           'mol'       =>1
                         },
                'amp' => {
                           'factor'    => 1,
                           'amp'       => 1,
                         },
                'cd'  => {
                           'factor'    => 1,
                           'cd'        => 1,
                         },
# ANGLES
# deg  -- degrees
# sr   -- steradian, a mesure of solid angle
#
                'deg'  => {
                           'factor'    => 0.0174532925,
                           'rad'       => 1
                          },
                'sr'  => {
                           'factor'    => 1,
                           'rad'       => 2
                          },
# TIME
# s     -- seconds
# ms    -- miliseconds
# min   -- minutes
# hr    -- hours
# day   -- days
# yr    -- years  -- 365 days in a year
# fortnight	-- (FFF system) 2 weeks
#
                  'ms'  => {
                           'factor'    => 0.001,
                           's'         => 1
                          },
                  'min'  => {
                           'factor'    => 60,
                           's'         => 1
                          },
                  'hr'  => {
                           'factor'    => 3600,
                           's'         => 1
                          },
                  'day'  => {
                           'factor'    => 86400,
                           's'         => 1
                          },
                  'yr'  => {
                           #'factor'    => 31557600,
                           'factor'    => 31557600,
                           's'         => 1
                          },
                  'fortnight'  => {
                           'factor'    => 1209600,
                           's'         => 1
                          },

# LENGTHS
# m    -- meters
# cm   -- centimeters
# km   -- kilometers
# mm   -- millimeters
# micron -- micrometer
# um   -- micrometer
# nm   -- nanometer
# A    -- Angstrom
#
                 'km'  => {
                           'factor'    => 1000,
                           'm'         => 1
                          },
                 'cm'  => {
                           'factor'    => 0.01,
                           'm'         => 1
                          },
                 'mm'  => {
                           'factor'    => 0.001,
                           'm'         => 1
                          },
             'micron'  => {
                           'factor'    => 1E-6,
                           'm'         => 1
                          },
                 'um'  => {
                           'factor'    => 1E-6,
                           'm'         => 1
                          },
                 'nm'  => {
                           'factor'    => 1E-9,
                           'm'         => 1
                          },
                  'A'  => {
                           'factor'    => 1E-10,
                           'm'         => 1
                          },
# ENGLISH LENGTHS
# in    -- inch
# ft    -- feet
# mi    -- mile
# furlong -- (FFF system) 0.125 mile
# light-year
# AU	-- Astronomical Unit
# parsec
#
                 'in'  => {
                           'factor'    => 0.0254,
                           'm'         => 1
                          },
                 'ft'  => {
                           'factor'    => 0.3048,
                           'm'         => 1
                          },
                 'mi'  => {
                           'factor'    => 1609.344,
                           'm'         => 1
                          },
                 'furlong'  => {
                           'factor'    => 201.168,
                           'm'         => 1
                          },
         'light-year'  => {
                           #'factor'    => 9.46E15,
                           'factor'    => 9460730472580800,
                           'm'         => 1
                          },
         'AU'  		   => {
                           'factor'    => 149597870700,
                           'm'         => 1
                          },
         'parsec'  => {
                           'factor'    => 30.857E15,
                           'm'         => 1
                          },
# VOLUME
# L   -- liter
# ml -- milliliters
# cc -- cubic centermeters
# dL  -- deci-liter
#
                  'L'  => {
                           'factor'    => 0.001,
                           'm'         => 3
                          },
                 'cc'  => {
                           'factor'    => 1E-6,
                           'm'         => 3,
                          },
                 'ml'  => {
                           'factor'    => 1E-6,
                           'm'         => 3,
                          },
                  'dL'  => {
                           'factor'    => 0.0001,
                           'm'         => 3
                          },
# VELOCITY
# knots -- nautical miles per hour
# c		-- speed of light
#
              'knots'  => {
                           'factor'    =>  0.5144444444,
                           'm'         => 1,
                           's'         => -1
                          },
              'c'  => {
                           'factor'    =>  299792458,	# exact
                           'm'         => 1,
                           's'         => -1
                          },
# MASS
# mg   -- miligrams
# g    -- grams
# kg   -- kilograms
# tonne -- metric ton
#
                  'mg'  => {
                           'factor'    => 0.000001,
                           'kg'        => 1
                          },
                  'g'  => {
                           'factor'    => 0.001,
                           'kg'        => 1
                          },
                  'tonne'  => {
                           'factor'    => 1000,
                           'kg'        => 1
                          },
# ENGLISH MASS
# slug -- slug
# firkin	-- (FFF system) 90 lb, mass of a firkin of water
#
               'slug'  => {
                           'factor'    => 14.6,
                           'kg'         => 1
                          },
                  'firkin'  => {
                           'factor'    => 40.8233133,
                           'kg'        => 1
                          },
# FREQUENCY
# Hz    -- Hertz
# kHz   -- kilo Hertz
# MHz   -- mega Hertz
#
                 'Hz'  => {
                           'factor'    => 2*$PI,  #2pi
                           's'         => -1,
                           'rad'       => 1
                          },
                'kHz'  => {
                           'factor'    => 2000*$PI,  #1000*2pi,
                           's'         => -1,
                           'rad'       => 1
                          },
                'MHz'  => {
                           'factor'    => (2E6)*$PI,  #10^6 * 2pi,
                           's'         => -1,
                           'rad'       => 1
                          },
                'rev'  => {
                			'factor'   => 2*$PI,
                			'rad'      => 1
                		  },
                'cycles'  => {
                			'factor'   => 2*$PI,
                			'rad'      => 1
                		  },

# COMPOUND UNITS
#
# FORCE
# N      -- Newton
# microN -- micro Newton
# uN     -- micro Newton
# kN	 -- kilo Newton
# dyne   -- dyne
# lb     -- pound
# ton    -- ton
#
                 'N'  => {
                           'factor'    => 1,
                           'm'         => 1,
                           'kg'        => 1,
                           's'         => -2
                          },
            'microN'  => {
                           'factor'    => 1E-6,
                           'm'         => 1,
                           'kg'        => 1,
                           's'         => -2
                          },
                 'uN'  => {
                           'factor'    => 1E-6,
                           'm'         => 1,
                           'kg'        => 1,
                           's'         => -2
                          },
                 'kN'  => {
                           'factor'    => 1000,
                           'm'         => 1,
                           'kg'        => 1,
                           's'         => -2
                          },
               'dyne'  => {
                           'factor'    => 1E-5,
                           'm'         => 1,
                           'kg'        => 1,
                           's'         => -2
                          },
                 'lb'  => {
                           'factor'    => 4.4482216152605,
                           'm'         => 1,
                           'kg'        => 1,
                           's'         => -2
                          },
                'ton'  => {
                           'factor'    => 8900,
                           'm'         => 1,
                           'kg'        => 1,
                           's'         => -2
                          },
# ENERGY
# J      -- Joule
# kJ     -- kilo Joule
# erg    -- erg
# lbf    -- foot pound
# kt	 -- kiloton (of TNT)
# Mt	 -- megaton (of TNT)
# cal    -- calorie
# kcal   -- kilocalorie
# eV     -- electron volt
# kWh    -- kilo Watt hour
#
                    'J'  => {
                           'factor'    => 1,
                           'm'         => 2,
                           'kg'        => 1,
                           's'         => -2
                          },
                 'kJ'  => {
                           'factor'    => 1000,
                           'm'         => 2,
                           'kg'        => 1,
                           's'         => -2
                          },
                'erg'  => {
                           'factor'    => 1E-7,
                           'm'         => 2,
                           'kg'        => 1,
                           's'         => -2
                          },
                'lbf'  => {
                           'factor'    => 1.35582,
                           'm'         => 2,
                           'kg'        => 1,
                           's'         => -2
                          },
                'kt'  => {
                           'factor'    => 4.184E12,
                           'm'         => 2,
                           'kg'        => 1,
                           's'         => -2
                          },
                'Mt'  => {
                           'factor'    => 4.184E15,
                           'm'         => 2,
                           'kg'        => 1,
                           's'         => -2
                          },
                'cal'  => {
                           'factor'    => 4.19,
                           'm'         => 2,
                           'kg'        => 1,
                           's'         => -2
                          },
               'kcal'  => {
                           'factor'    => 4190,
                           'm'         => 2,
                           'kg'        => 1,
                           's'         => -2
                          },
                'eV'  => {
                           'factor'    => 1.60E-9,
                           'm'         => 2,
                           'kg'        => 1,
                           's'         => -2
                          },
                'kWh'  => {
                           'factor'    => 3.6E6,
                           'm'         => 2,
                           'kg'        => 1,
                           's'         => -2
                          },
# POWER
# W      -- Watt
# kW     -- kilo Watt
# hp     -- horse power  746 W
#
                 'W'  => {
                           'factor'    => 1,
                           'm'         => 2,
                           'kg'        => 1,
                           's'         => -3
                          },
                 'kW'  => {
                           'factor'    => 1000,
                           'm'         => 2,
                           'kg'        => 1,
                           's'         => -3
                          },
                'hp'   => {
                           'factor'    => 746,
                           'm'         => 2,
                           'kg'        => 1,
                           's'         => -3
                          },
# PRESSURE
# Pa     -- Pascal
# kPa    -- kilo Pascal
# MPa    -- mega Pascal
# GPa    -- giga Pascal
# atm    -- atmosphere
# bar	 -- 100 kilopascals
# cmH2O	 -- centimetres of water
#
                 'Pa'  => {
                           'factor'    => 1,
                           'm'         => -1,
                           'kg'        => 1,
                           's'         => -2
                          },
                'kPa'  => {
                           'factor'    => 1000,
                           'm'         => -1,
                           'kg'        => 1,
                           's'         => -2
                          },
                'MPa'  => {
                           'factor'    => 1E6,
                           'm'         => -1,
                           'kg'        => 1,
                           's'         => -2
                          },
                'GPa'  => {
                           'factor'    => 1E9,
                           'm'         => -1,
                           'kg'        => 1,
                           's'         => -2
                          },
                'atm'  => {
                           'factor'    => 1.01E5,
                           'm'         => -1,
                           'kg'        => 1,
                           's'         => -2
                          },
                'bar'  => {
                           'factor'    => 100000,
                           'm'         => -1,
                           'kg'        => 1,
                           's'         => -2
                          },
                'mbar'  => {
                           'factor'    => 100,
                           'm'         => -1,
                           'kg'        => 1,
                           's'         => -2
                          },
                'Torr'  => {
                           'factor'    => 133.322,
                           'm'         => -1,
                           'kg'        => 1,
                           's'         => -2
                          },
                'mmHg'  => {
                           'factor'    => 133.322,
                           'm'         => -1,
                           'kg'        => 1,
                           's'         => -2
                          },
                'cmH2O'  => {
                           'factor'    => 98.0638,
                           'm'         => -1,
                           'kg'        => 1,
                           's'         => -2
                          },
                'psi'  => {
                           'factor'    => 6895,
                           'm'         => -1,
                           'kg'        => 1,
                           's'         => -2
                          },
# ELECTRICAL UNITS
# C      -- Coulomb
# V      -- volt
# mV     -- milivolt
# kV     -- kilovolt
# MV     -- megavolt
# F      -- Farad
# mF     -- miliFarad
# uF     -- microFarad
# ohm    -- ohm
# kohm   -- kilo-ohm
# Mohm	 -- mega-ohm
# S		 -- siemens
#
                'C'    => {
                           'factor'    => 1,
                           'amp'       => 1,
                           's'         => 1,
                         },
                'V'    => {			# also J/C
                           'factor'    => 1,
                           'kg'        => 1,
                           'm'         => 2,
                           'amp'       => -1,
                           's'         => -3,
                         },
                'mV'   => {
                           'factor'    => 0.001,
                           'kg'        => 1,
                           'm'         => 2,
                           'amp'       => -1,
                           's'         => -3,
                         },
                'kV'   => {
                           'factor'    => 1000,
                           'kg'        => 1,
                           'm'         => 2,
                           'amp'       => -1,
                           's'         => -3,
                         },
                'MV'   => {
                           'factor'    => 1E6,
                           'kg'        => 1,
                           'm'         => 2,
                           'amp'       => -1,
                           's'         => -3,
                         },
                'F'    => {			# also C/V
                           'factor'    => 1,
                           'amp'       => 2,
                           's'         => 4,
                           'kg'        => -1,
                           'm'         => -2,
                         },
                'mF'   => {
                           'factor'    => 0.001,
                           'amp'       => 2,
                           's'         => 4,
                           'kg'        => -1,
                           'm'         => -2,
                         },
                'uF'   => {
                           'factor'    => 1E-6,
                           'amp'       => 2,
                           's'         => 4,
                           'kg'        => -1,
                           'm'         => -2,
                         },
                'ohm'  => {			# V/amp
                           'factor'    => 1,
                           'kg'        => 1,
                           'm'         => 2,
                           'amp'       => -2,
                           's'         => -3,
                         },
                'kohm' => {
                           'factor'    => 1000,
                           'kg'        => 1,
                           'm'         => 2,
                           'amp'       => -2,
                           's'         => -3,
                         },
                'Mohm' => {
                           'factor'    => 1E6,
                           'kg'        => 1,
                           'm'         => 2,
                           'amp'       => -2,
                           's'         => -3,
                         },
                'S'  => {			# 1/ohm
                           'factor'    => 1,
                           'kg'        => -1,
                           'm'         => -2,
                           'amp'       => 2,
                           's'         => 3,
                         },
# MAGNETIC UNITS
# T	 	 -- tesla
# G	 	 -- gauss
# Wb	 -- weber
# H	 	 -- henry
#
                'T'    => {			# also kg/A s^2		N s/C m
                           'factor'    => 1,
                           'kg'        => 1,
                           'amp'       => -1,
                           's'         => -2,
                         },
                'G' => {
                           'factor'    => 1E-5,
                           'kg'        => 1,
                           'amp'       => -1,
                           's'         => -2,
                         },
                'Wb'    => {			# also T m^2
                           'factor'    => 1,
                           'kg'        => 1,
                           'm'         => 2,
                           'amp'       => -1,
                           's'         => -2,
                         },
                'H'    => {			# also V s/amp
                           'factor'    => 1,
                           'kg'        => 1,
                           'm'         => 2,
                           'amp'       => -2,
                           's'         => -2,
                         },
# LUMINOSITY
# lm	-- lumen, luminous flux
# lx	-- lux, illuminance
#
                'lm' => {
                           'factor'    => 1,
                           'cd'        => 1,
                           'rad'       => -2,
                         },
                'lx' => {
                           'factor'    => 1,
                           'cd'        => 1,
                           'rad'       => -2,
                           'm'         => -2,
                         },

# ATOMIC UNITS
# amu	-- atomic mass units
# dalton	-- 1 amu
# me	-- electron rest mass
# barn	-- cross-sectional area
# a0	-- Bohr radius
#
                'amu' => {
                           'factor'    => 1.660538921E-27,
                           'kg'        => 1,
                         },
                'dalton' => {
                           'factor'    => 1.660538921E-27,
                           'kg'        => 1,
                         },
                'me' => {
                           'factor'    => 9.1093826E-31,
                           'kg'        => 1,
                         },
                'barn' => {
                           'factor'    => 1E-28,
                           'm'         => 2,
                         },
                'a0' => {
                           'factor'    => 0.5291772108E-10,
                           'm'         => 1,
                         },
# RADIATION
# Sv	-- sievert, dose equivalent radiation	http://xkcd.com/radiation
# mSv	-- millisievert				http://blog.xkcd.com/2011/03/19/radiation-chart
# uSv	-- microsievert				http://blog.xkcd.com/2011/04/26/radiation-chart-update
#
                'Sv' => {
                           'factor'    => 1,
                           'm'         => 2,
                           's'         => -2,
                         },
                'mSv' => {
                           'factor'    => 0.001,
                           'm'         => 2,
                           's'         => -2,
                         },
                'uSv' => {
                           'factor'    => 0.000001,
                           'm'         => 2,
                           's'         => -2,
                         },
# BIOLOGICAL & CHEMICAL UNITS
# mmol	-- milli mole
# micromol	-- micro mole
# nanomol	-- nano mole
# kat	-- katal, catalytic activity
#
                'mmol' => {
                           'factor'    => 0.001,
                           'mol'       => 1,
                         },
                'micromol' => {
                           'factor'    => 1E-6,
                           'mol'       => 1,
                         },
                'nanomol' => {
                           'factor'    => 1E-9,
                           'mol'       => 1,
                         },
                'kat' => {
                           'factor'    => 1,
                           'mol'       => 1,
                           's'         => -1,
                         },

# ASTRONOMICAL UNITS
# kpc	-- kilo parsec
# Mpc	-- mega parsec
# solar-mass	-- solar mass
# solar-radii	-- solar radius
# solar-lum	-- solar luminosity
         'kpc'  => {
                           'factor'    => 30.857E18,
                           'm'         => 1
                          },
         'Mpc'  => {
                           'factor'    => 30.857E21,
                           'm'         => 1
                          },
                'solar-mass' => {
                           'factor'    => 1.98892E30,
                           'kg'        => 1,
                         },
                'solar-radii' => {
                           'factor'    => 6.955E8,
                           'm'         => 1,
                         },
                'solar-lum' => {
                           'factor'    => 3.8939E26,
                           'm'         => 2,
                           'kg'        => 1,
                           's'         => -3
                         },

);



sub process_unit {

	my $string = shift;
    die ("UNIT ERROR: No units were defined.") unless defined($string);  #
	#split the string into numerator and denominator --- the separator is /
    my ($numerator,$denominator) = split( m{/}, $string );



	$denominator = "" unless defined($denominator);
	my %numerator_hash = process_term($numerator);
	my %denominator_hash =  process_term($denominator);


    my %unit_hash = %fundamental_units;
	my $u;
	foreach $u (keys %unit_hash) {
		if ( $u eq 'factor' ) {
			$unit_hash{$u} = $numerator_hash{$u}/$denominator_hash{$u};  # calculate the correction factor for the unit
		} else {

			$unit_hash{$u} = $numerator_hash{$u} - $denominator_hash{$u}; # calculate the power of the fundamental unit in the unit
		}
	}
	# return a unit hash.
	return(%unit_hash);
}

sub process_term {
	my $string = shift;
	my %unit_hash = %fundamental_units;
	if ($string) {

		#split the numerator or denominator into factors -- the separators are *

	    my @factors = split(/\*/, $string);

		my $f;
		foreach $f (@factors) {
			my %factor_hash = process_factor($f);

			my $u;
			foreach $u (keys %unit_hash) {
				if ( $u eq 'factor' ) {
					$unit_hash{$u} = $unit_hash{$u} * $factor_hash{$u};  # calculate the correction factor for the unit
				} else {

					$unit_hash{$u} = $unit_hash{$u} + $factor_hash{$u}; # calculate the power of the fundamental unit in the unit
				}
			}
		}
	}
	#returns a unit hash.
	#print "process_term returns", %unit_hash, "\n";
	return(%unit_hash);
}


sub process_factor {
	my $string = shift;
	#split the factor into unit and powers

    my ($unit_name,$power) = split(/\^/, $string);
	$power = 1 unless defined($power);
	my %unit_hash = %fundamental_units;

	if ( defined( $known_units{$unit_name} )  ) {
		my %unit_name_hash = %{$known_units{$unit_name}};   # $reference_units contains all of the known units.
		my $u;
		foreach $u (keys %unit_hash) {
			if ( $u eq 'factor' ) {
				$unit_hash{$u} = $unit_name_hash{$u}**$power;  # calculate the correction factor for the unit
			} else {
				my $fundamental_unit = $unit_name_hash{$u};
				$fundamental_unit = 0 unless defined($fundamental_unit); # a fundamental unit which doesn't appear in the unit need not be defined explicitly
				$unit_hash{$u} = $fundamental_unit*$power; # calculate the power of the fundamental unit in the unit
			}
		}
	} else {
		die "UNIT ERROR Unrecognizable unit: |$unit_name|";
	}
	%unit_hash;
}

# This is the "exported" subroutine.  Use this to evaluate the units given in an answer.
sub evaluate_units {
	my $unit = shift;
	my %output =  eval(q{process_unit( $unit)});
	%output = %fundamental_units if $@;  # this is what you get if there is an error.
	$output{'ERROR'}=$@ if $@;
	%output;
}
#################

1;
