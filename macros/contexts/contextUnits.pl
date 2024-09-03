
=head1 NAME

contextUnits.pl - Implements a MathObject class for numbers with units

=head1 DESCRIPTION

This file implements a MathObject Unit class that provides the ability
to use units within computations, within lists, and so on.  There are
two pre-defined units contexts, but you can add units to other
existing contexts, if they are compatible with units.

To load, use

    loadMacros('contextUnits.pl');

and then select the Units or LimitedUnits context and enable the units
that you want to use.  E.g.,

    Context("Units")->withUnitsFor("length");

or

    Context("LimitedUnits")->withUnitsFor("angles");

For the C<LimitedUnits> context, you are not allowed to perform any
operations, like addition or multiplication, or any function calls, so
can only enter a single number, unit, or number with unit.

You can include as many categories as you want, as in

    Context("Units")->withUnitsFor("length", "volume");

The categories of units are the following:

    angles           (fundamental units "rad")
    time             (fundamental units "s")
    length           (fundamental units "m", except for those in "atomics" and "astronomy" below)
    metric-length    (same as length except no imperial lengths)
    imperial-length  (in, ft, mi, furlong, and their aliases)
    volume           (fundamental units "m^3")
    velocity         (fundamental units "m/s")
    mass             (fundamental units "kg", except for those in "astronomy" below)
    temperature      (fundamental units "defC", "defF", "K")
    frequency        (fundamental units "rad/s")
    force            (fundamental units "(kg m)/(s^2)")
    energy           (fundamental units "(kg m^2)/(s^2)")
    power            (fundamental units "(kg m^2)/(s^3)" except for those in "astronomy" below)
    pressure         (fundamental units "kg/(m s^2)")
    electricity      (fundamental units "amp", "amp/s", "(kg m)/(amp s^-3)", "(amp s^-3)/(kg m)",
                                        "(amp^2 s^4)/(kg m^2)", "(kg m^2)/(amp^2 s^3)", and "(amp^2 s^3)/(kg m^2)")
    magnatism        (fundamental units "kg/(amp s^2)" and "(kg m)/(amp s^2)")
    luminosity       (fundamental units "cd/(rad^2)" and "cd/(rad m)^2")
    atomics          (amu, me, barn, a0, dalton)
    radiation        (fundamental units "(m^2)/(s^2)" and "s^-1")
    biochem          (fundamental units "mol" or "mol/s")
    astronomy        (kpc, Mpc, solar-mass, solar-radii, solar-lum, light-year, AU, parsec)
    fundamental      (m, kg, s, rad, degC, degF, K, mol, amp, cd)

You can add specific named units via the C<addUnits()> method of the
context, as in

    Context("Units")->withUnitsFor("volume")->addUnits("m", "cm");

or

    $context = Context("Units");
    $context->addCategories("volume");
    $context->addUnits("m", "cm");

to get a units context with units for volume as well as C<m> and C<cm>
and any aliases for these units (e.g., C<meter>, C<meters>, etc.).
Use C<addUnitsNotAliases()> in place of C<addUnits()> to add just the
named units without adding any aliases for them.

=head2 Custom units

You can define your own units in terms of the fundamental units.
E.g., to define the unit C<acres>, you could use

    Context("Units")->withUnitsFor("length")->addUnits(acres => {factor => 4046.86, m => 2});

which indicates that 1 acre is equal to 4046.86 square meters.

You can even make up your own fundamental units.  For example, to
define C<apples> and C<oranges> as units, you could do

    Context("Units")->addUnits(
      apples => { apples => 1, aliases => ["apple"] },
      oranges => { oranges => 1, aliases => ["orange"] }
    );

    BEGIN_PGML
    If you have 5 apples and give your friend 2 of them,
    what do you have left? [___________]{"3 apples"}
    END_PGML

and the student can answer C<3 oranges> but will be marked incorrect
(with a message about the units being incorrect).  Note that C<apples>
and C<apple> are synonymous in this context, and that C<1 apple> is
accepted, but is displayed as C<1 apples>, as no attempt is made to
handle plurals.

On the other hand, you could also do

    Context("Units")->addUnits(
      apples => { fruit => 1, aliases => ["apple"] },
      oranges => { fruit => 1, aliases => ["orange"] }
    );

    Compute("3 apples") == Compute("3 oranges"); # returns 1

will consider apple and oranges as the same unit (both are the
fundamental unit of C<fruit>).

Finally,

    Context("Units")->addUnits(
      apples => { fruit => 1, aliases => ["apple"] },
      oranges => { fruit => 1, aliases => ["orange"], factor => 2 }
    );

    Compute("1 apple") == Compute("2 oranges"); # returns 1

will make an apple equivalent to two oranges by making both C<apples>
and C<oranges> be examples of the fundamental unit C<fruit>.

You can remove individual units from the context using the
C<removeUnits()> method of the context.  For example

    Context("Units")->withUnitsFor("length")->removeUnits("ft", "inch", "mile", "furlong");

removes the English units and their aliases, leaving only the metric
units.  To remove a unit without removing its aliases, use C<removeUnitsNotAliases()>
instead.

Note that the units are stored in the context as constants, so to list
all the units, together with other constants, use

    Context()->constants->names;

The constants that are units have the C<isUnit> property set.  So

    grep {Context()->constants->get($_)->{isUnit}} (Context()->constants->names);

will get the list of units.


=head2 Adding units to other contexts

The C<Units> and C<LimitedUnits> contexts are based on the C<Numeric>
and C<LimitedNumeric> contexts.  You can add units to other contexts
using the C<context::Units::extends()> function.  For example,

    Context(context::Units::extending("Fraction")->withUnitsFor("length"));

would allow you to use fractions with units.

In addition to the name of the context to extend, you can pass options
to C<context::Units::extending()>, as in

    $context = Context(context::Units::extending("LimitedFraction", limited => 1));
    $context->addUnitsFor("length");

In this case, the C<limited => 1> option indicates that no operations
are allowed between numbers with units, and since the
C<LimitedFraction> context doesn't allow operations otherwise, you
will only be able to enter fractions or whole numbers, with or without
units, or a unit without a number.

The available options and their defaults are

    keepNegativePowers => 1,     Preserve use of negative powers so C<m s^-1> will
                                 not be shown as C<m/s> (but will still match it).
    useNegativePowers => 0       Always use negative powers instead of fractions?
    limited => 0                 Don't allow operations on numbers with units.
    exactUnits => 0              Require student units to exactly match correct ones
                                   in both order and use of negative powers
    sameUnits => 0               Require student units to match correct ones
                                   not scaled versions
    partialCredit => .5          Partial credit if answer is right but units
    factorUnits => 1             Factor the units out of sums and differences of
                                   formulas with the same units

The first two and last three can also be set as context flags after
the context is created.  There is a C<limitedOperators> flag that is
set by the C<limited> option that controls whether operations are
allowed on numbers with units, but if you set it, you might also need
to do

    Context()->parens->set( '(' => { close => ')', type => 'Units' } );

to allow parentheses around units if the parentheses have been removed
from the original context (as they are in the C<LimitedNumeric>
context, for instance). This makes it possible to enter units of the
form C<kg/(m s)> in such contexts.


=head2 Creating unit and number-with-unit objects

In the units contexts, units are first-class citizens, and unit and
number-with-unit objects can be created just like any other
MathObject.  So you can use

    $n = Compute("3 m/s");

to get a numer-with-units object for 3 meters per second.  You can also use
the word C<per> in place of C</>, as in

    $n = Compute("3 meters per second");

You can use the words C<squared> and C<cubed> with units in place of
C<^2> and C<^3>, so that

    $n = Compute("3 meters per second squared");

will produce an equivalent result to

    $n = Compute("3 m/s^2");

There are also C<square> and C<cubic> that can be used to precede a unit,
such as

    $n = Compute("3 square meters");

as an alternative to C<Compute("3 m^2")>.

Note that the space between the number and units is not strictly
necessary, and neither is the space between units, unless the combined
unit names have a different meaning.  For example

    $n = Compute("3m");     # instead of "3 m"
    $n = Compute("3 kgm");  # instead of "3 kg m"

are both fine, but

    $n = Compute("3 ms");

would treat C<ms> as the single unit for milliseconds, rather than
meter-seconds, in a context that includes both length and time units.

In order to have more than one unit in the denominator, you can either
use multiple division signs (or C<per> operations), or enclose the
denominator in parentheses, as in

    $n = Compute("3 kg/m/s");
    $n = Compute("3 kg/(m s)");
    $n = Compute("3 kg per meter per second");

Units can be preceded by formulas as well as numbers.  For example

    $f = Compute("2x meters");

makes C<$f> be a Formula returning a Number-with-Unit.  Note, however,
that since the space before the unit has the same precedence as
multiplication (just as it does within a formula), if the expression
before the unit includes addition, you need to enclose it in parentheses:

    $n = Compute("(1+4) meters");
    $f = Compute("(1+2x) meters");

Using C<Compute()> is not the only way to produce a number or formula
with units; there are also constructor functions that are sometimes
useful when writing a problem involving units.

    $n = NumberWithUnits(3, "m/s");
    $f = FormulaWithUnits("1+2x", "meters");

These are most useful when the numeric part is the result of a
computation or a value held in a variable:

    $n = NumberWithUnits(random(1,5), "m");

Since units are themselves MathObjects, you can work with units
without a preceding number.  These can be created through C<Compute()>
just as with other MathObject, or you can use the C<Unit()> constructor.

    $u = Compute("meters per second per second");
    $u = Unit("m/s^2");

This allows you to ask a student to say what units should be used for
a particular setting, without the need for a quntity.


=head2 Working with numbers with units

Because units and numbers with units are full-fledged MathObjects, you
can do computations with them, just as with other MathObejcts.  For
example, you can do

    $n = Compute("3 m + 10 cm");

to get the equivalent of C<3.1 m>.  Similarly, you can do

    $velocity = Compute("100 miles / (2 hours)");  # equals "50 mi/h"
    $area = Compute("(5 m) * (3 m)");              # equals "15 m^2"

to get numbers with compound units.

As with other MathObjects, units and numbers with units can be
combined using perl operations:

    $distance = Compute("100 miles");
    $time = Compute("2 hours");
    $velocity = $distance / $time;  # equivalent to "50 miles/hour"

    $m = Compute("m");
    $s = Compute("s");
    $a = 9.8 * $m / $s**2;

    $x = Compute("x");
    $f = (3 * $x**2 - 2) * $m;  # equivalent to Compute("(3x^2 - 2) m");

The units objects provide functions for converting from one set of
units to another (compatible) set via the C<toUnits()> and
C<toBaseUnits()> methods.  For example:

    $m = Compute("5 m");
    $ft = $m->toUnits("ft");                 # returns "16.4042 ft"

    $cm = Compute("5.21 m")->toUnits("cm");  # returns "521 cm"

    $a = Compute("32 ft/s^2")->toBaseUnits;  # returns "9.7536 m/s^2"

For a given number with units, you may wish to obtain the numeric
portion or the units portion separatly.  This can be done using the
C<number> and C<unit> methods:

    $n = Compute("5 m");
    $r = $m->number;         # returns 5 as a Real MathObject
    $u = $m->unit;           # returns "m" as a Unit MathObject

You can also use the C<Real()> and C<Unit()> constructors to do the
same thing:

    $n = Compute("5 m");
    $r = Real($m);           # returns 5 as a Real MathObject
    $u = Unit($m);           # returns "m" as a Unit MathObject

You can get the numeric portion of the number-with-units
object relative to the base units using the C<quantity> method:

    $q = Compute("3 ft")->quantity;    # returns .9144

Using C<< $m->quantity >> is equivalent to calling C<< $m->toBaseUnits->number >>.

Finally, you can get the factor by which the given units must be
multiplied to obtain the quantity in the fundamental base uses using
the C<factor> method:

    $f = Compute("3 ft")->factor;    # returns 0.3048

Similarly, you can use the C<factor> method of a unit object to get
the factor for that unit.

Most functions, such as C<sqrt()> and C<ln()>, will report an error if
hey are passed a number with units (or a bare unit).  Important
exceptions are the trigonometric and hyperbolic functions, which
accept a number with units provided the units are angular units.  For
example,

    $v = Compute("sin(30 deg)");

will return 0.5, and so will

    $a = Compute("60 deg");
    $sin_a = sin($a);

as the perl functions have been overloaded to handle numbers with
units when the units are anglular units.

The other exception is C<abs()>, which can be applied to numbers with
units, and returns a number with units hacing the same units, but the
quantity is the absolute value of the original quantity.


=head2 Answer checking for units and numbers with units

You can use units and numbers with units within PGML or C<ANS()> calls
in the same way that you use any other MathObject.  For example

    BEGIN_PGML
    What are the units for acceleration? [_______]{"m/sec^2"}
    END_PGML

Here, the student can answer any equivalent units, such as C<ft/s^2>
or even C<mi/h^2>, and get full credit.  If you wish to require the
units to being the same as the correct answer, you can use the
C<sameUnits> option on the answer checker (ot set the C<sameUnits>
flag in the units context):

    $u = Compute("m/s^2");
    BEGIN_PGML
    What are the metric units for acceleration? [_______]{$u->cmp(sameUnits => 1)}
    END_PGML

If the student entered C<ft/sec^2>, they would get partial credit, and
a message indicating that their units are correct but are not the same
as the expected units.  The amount of partial credit is determined by
the C<partialCredit> answer-checkeroption (or context flag), whose
default value is .5 for half credit.  So you can use

    $u->cmp(sameUnits => 1, partialCredit => .75)

to increase the credit to 75%, or

    $u->cmp(sameUnits => 1, partialCredit => 0)

to give no partial credit.

Similarly, if the correct answer is given with units of C<m>, then
when C<< sameUnits => 1 >> is set, an answer using C<cm> instead will be
given only partical credit.

In the case where the units include products of units, like C<m s>,
the C<sameUnits> option requires both be present, but they can be in
either order.  So a student can enter C<s m> and still get full
credit.  If you want to require the order to be the same as in the
correct anser, then use the C<exactUnits> option.  Again, partial
credit is given for answers that have the right units but not in the
right order.

If the correct answer is C<m/s^2>, a student usually can enter C<m
s^-2> and their answer will be counted as correct.  Similarly, if the
correct answer is given as C<m s^-2>, then C<m/s^2> is also marked as
correct.  When C<< exactUnits => 1 >> is set, however, in addition to
using the units in the same order, the student's answer must use the
same form (either fraction or negative power) for units in the
denominator, and will only get the C<particalCredit> value for using
the other form.

Answers that are numbers with units are treated in a similar manner,
and can use the C<sameUnits>, C<exactUnits>, and C<partialCredit>
flags to control what answers are given full credit.

Note that in the C<Units> context, students can perform operations on
numbers with units, as described in the previous section.  For
example, if the correct answer is C<3.02 m>, then a student can enter
C<3 m + 2 cm> and be marked correct.  Similarly, for the answer C<50
mi/h> a student could enter C<(100 miles) / (2 hours)>.

If you want to prevent students from performing such computations,
then set the C<limitedOperations> flag in the context or in the
C<cmp()> call.  So

    $ans = Compute("50 mi/h")->cmp(limitedOperations => 1);
    BEGIN_PGML
    If you travel 100 miles in 2 hours, then your
    average velocity is [_______]{$ans}
    END_PGML

will prevent the student from dividing two numbers with units, though
they can still enter C<(100/2) mi/h>.  To prevent any operations at
all, use the C<LimitedUnits> context instead of the C<Units> context.

Note that you can add the C<limitedOperations> and other flags to the
MathObject itself, rather than the context or answer checker, as in

    $av = Compute("50 mi/h")->with(limitedOperations => 1, sameUnits => 1);
    BEGIN_PGML
    If you travel 100 miles in 2 hours, then your
    average velocity is [_______]{$av}
    END_PGML

and still be able to use the result in computations in the perl code.
Note that the flags will be passed on to any results involving the
original that had the flags set.

=cut

loadMacros("contextExtensions.pl");

sub _contextUnits_init { context::Units::Init() }

#################################################################################################
#################################################################################################

package context::Units;

#
#  The class name for the number-with-unit class
#
our $NUNIT = 'Number-with-Unit';

#
#  Value types for units and numbers with units
#
our $UNIT             = Value::Type('Unit', 1, $Value::Type{unknown});
our $NUMBER_WITH_UNIT = Value::Type($NUNIT, 1, $Value::Type{unknown});

#
#  Common error message for functions when they get arguments with units
#
sub fnError { Value->Error("The input for '%s' must be a number", shift) }

sub extending {
	my ($from, %options) = @_;

	#
	#  Get a copy of the original context
	#
	my $context = context::Extensions::create("Units", $from);

	#
	#  Hook in the unit and number-with-unit classes
	#
	$context->{value}{Unit}           = 'context::Units::Unit';
	$context->{value}{NumberWithUnit} = 'context::Units::NumberWithUnit';
	$context->{value}{$NUNIT}         = 'context::Units::NumberWithUnit';
	#
	#  Make the precedences for units and numbers-with-units be just
	#  below a Formula (so formulas will be created automatically for
	#  them when needed, but these will have precedence over Real and
	#  other types).
	#
	$context->{precedence}{Unit} = $context->{precedence}{Formula} - .6;
	$context->{precedence}{$NUNIT} = $context->{precedence}{Formula} - .3;

	#
	#  Get the data for "per" from "/" and get the power precedence
	#
	my $operators = $context->operators;
	my $per       = { %{ $operators->get('/') } };
	delete $per->{space};
	$per->{precedence} -= .1;
	my $precedence = $operators->get('^')->{precedence};

	#
	#  We make a Units list type for use in LimitedNumeric classes
	#
	$context->lists->set(Units => { class => 'context::Units::UnitList' });
	$context->parens->set('(' => { close => ')', type => 'Units' })
		if $options{limited} && !$context->parens->get('(');

	return context::Extensions::extend(
		$context,
		opClasses => {
			'+'  => 'BOP::add',
			'-'  => 'BOP::subtract',
			'*'  => 'BOP::multiply',
			' '  => 'BOP::multiply',
			'/'  => 'BOP::divide',
			'//' => 'BOP::divide',
			'**' => 'BOP::power',
			'^'  => 'BOP::power',
			'* ' => 'BOP::multiply',
			' *' => 'BOP::multiply',
			'/ ' => 'BOP::divide',
			' /' => 'BOP::divide',
		},
		ops => {
			per     => $per,
			squared => {
				class         => 'context::Units::UOP::NamedPower',
				precedence    => $precedence,
				associativity => 'right',
				type          => 'unary',
				string        => '^2',
				TeX           => '^2',
				power         => 2,
				isCommand     => 1
			},
			cubed => {
				class         => 'context::Units::UOP::NamedPower',
				precedence    => $precedence,
				associativity => 'right',
				type          => 'unary',
				string        => '^3',
				TeX           => '^3',
				power         => 3,
				isCommand     => 1
			},
			square => {
				class         => 'context::Units::UOP::NamedPower',
				precedence    => $precedence,
				associativity => 'left',
				type          => 'unary',
				power         => 2,
				isCommand     => 1
			},
			cubic => {
				class         => 'context::Units::UOP::NamedPower',
				precedence    => $precedence,
				associativity => 'left',
				type          => 'unary',
				power         => 3,
				isCommand     => 1
			}
		},
		functions => 'trig|hyperbolic|numeric',
		value     => [ 'Real()', 'Formula' ],
		parser    => ['Formula'],
		flags     => {
			useNegativePowers  => $options{useNegativePowers}  // 0,
			keepNegativePowers => $options{keepNegativePowers} // 1,
			limitedOperators   => $options{limited}            // 0,
			exactUnits         => $options{exactUnits}         // 0,
			sameUnits          => $options{sameUnits}          // 0,
			partialCredit      => $options{partialCredit}      // .5,
			factorUnits        => $options{factorUnits}        // 1,
		},
		context => 'Context'
	);
}

#
#  Create the Units and LimitedUnits contexts, and the
#  Unit(), NumberWithUnit(), and FormulaWithUnit() functions.
#
sub Init {
	$main::context{Units}        = context::Units::extending("Numeric");
	$main::context{LimitedUnits} = context::Units::extending("LimitedNumeric", limited => 1);
	sub main::Unit            { Value->Package("Unit()")->new(@_) }
	sub main::NumberWithUnits { Value->Package("NumberWithUnit()")->new(@_) }

	sub main::FormulaWithUnits {
		return Value->Package("Formula()")->new(Value->Package("NumberWithUnit()")->new(@_));
	}
}

#################################################################################################
#################################################################################################

#
#  The context subclass that adds unit-handling functions
#
package context::Units::Context;
our @ISA = ('Parser::Context');

#
#  The units from the original Units package
#
our %UNITS = (%Units::known_units);
$UNITS{$_} = $UNITS{L} for ('litre', 'litres', 'litre', 'litres');    # add these extras

#
#  The categories of units that can be selected.
#
#  These give the fundamental units of the unit names to be added to
#  the context, or a list of such, or a list of names of known units.
#  If a name begins with a dash, then REMOVE the category or named
#  unit.  For example, the "length" category excludes the lengths that
#  are part of the "atomics" and "astronomy" categories.  If a name
#  ends in an asterisk, then add or remove all the aliases for that
#  unit as well.
#
our %categories = (
	angles            => { rad => 1 },
	time              => { s   => 1 },
	length            => [ { m => 1 }, '-atomics', '-astronomy' ],
	"metric-length"   => [ { m => 1 }, '-atomics', '-astronomy', '-imperial-length' ],
	"imperial-length" => [ 'in*', 'ft*', 'mi*', 'furlong*' ],
	volume            => { m => 3 },
	velocity          => { m => 1, s => -1 },
	mass              => [ { kg => 1 }, '-astronomy' ],
	temperature       => [ { degC => 1 }, { defF => 1 }, { K => 1 } ],
	frequency         => { rad => 1, s => -1 },
	force             => { m => 1, kg => 1, s => -2 },
	energy            => { m => 2, kg => 1, s => -2 },
	power             => [ { m => 2, kg => 1, s => -3 }, '-astronomy' ],
	pressure          => { m => -1, kg => 1, s => -2 },
	electricity       => [
		{ amp => 1 },
		{ amp => 1,  s => 1 },
		{ kg  => 1,  m => 2,  amp => -1, s => -3 },
		{ kg  => -1, m => -2, amp => 1,  s => 3 },
		{ amp => 2,  s => 4,  kg  => -1, m => -2 },
		{ kg  => 1,  m => 2,  amp => -2, s => -3 },
		{ kg  => -1, m => -2, amp => 2,  s => 3 },
	],
	magnatism   => [ { kg => 1, amp => -1, s => -2 }, { kg => 1, m => 2, amp => -1, s => -2 }, ],
	luminosity  => [ { cd => 1, rad => -2 }, { cd => 1, rad => -2, m => -2 }, ],
	atomics     => [ 'amu', 'me', 'barn', 'a0', 'dalton' ],
	radiation   => [ { m => 2, s => -2 }, { s => -1 } ],
	biochem     => [ { mol => 1 }, { mol => 1, s => -1 } ],
	astronomy   => [ 'kpc', 'Mpc', 'solar-mass', 'solar-radii', 'solar-lum', 'light-year', 'AU', 'parsec' ],
	fundamental => [ keys %Units::fundamental_units ],
);

#
#  Add new units, either by name, as name => unit_def, or as unit_def
#  (where unit_def is like one of the known units).  Also add other
#  units that are aliases for the given one in the known_units list.
#
sub addUnits {
	my $self = shift;
	while (@_) {
		if (ref($_[0]) eq 'HASH') {
			$self->addUnit('' => shift);
		} else {
			$self->addUnit(shift => ref($_[0]) eq 'HASH' ? shift : undef);
		}
	}
	return $self;
}

#
#  Add new units, either by name or name => unit_def (where unit_def
#  is like one of the known units).  Don't add any aliases for these
#  units.
#
sub addUnitsNotAliases {
	my $self = shift;
	while (@_) {
		my ($name, $unit) = (shift, ref($_[0]) eq 'HASH' ? shift : undef);
		$self->addUnit($name => $unit, noaliases => 1);
	}
	return $self;
}

#
#  Add a single unit by name or name => unit_def
#
sub addUnit {
	my ($self, $name, $unit, %options) = @_;
	my $constants = $self->constants;
	$unit = $UNITS{$name} unless $unit;
	Value->Error("Can't add unknown unit '%s'", $name) unless $unit;
	my $aliases = $unit->{aliases};
	$units = {%$unit}, delete $units->{aliases} if $aliases;
	$constants->{namePattern} = qr/.+/;
	if ($name) {
		$constants->add(
			$name => {
				value      => context::Units::Unit->new($name => $unit),
				isUnit     => 1,
				isConstant => 1
			}
		);
		$constants->add(map { $_ => { alias => $name } } @$aliases) if $aliases;
		$self->addUnitAliases($name) unless $options{noaliases};
	} else {
		$self->addUnitAliases($unit);
	}
	return $self;
}

#
#  Adds all the aliases for a given named unit or unit definition
#
sub addUnitAliases {
	my ($self, $name) = @_;
	my $unit = ref($name) eq 'HASH' ? $name : $UNITS{$name};
	return unless $unit;
	my $def = join(',', map {"$_=$unit->{$_}"} (main::lex_sort(keys %$unit)));
	for my $alias (keys %UNITS) {
		my $UNIT = { %{ $UNITS{$alias} } };
		delete $UNIT->{factor} unless defined($unit->{factor});
		if (join(',', map {"$_=$UNIT->{$_}"} (main::lex_sort(keys %$UNIT))) eq $def && $name ne $alias) {
			$self->addUnit($alias => $UNITS{$alias}, noaliases => 1);
		}
	}
	return $self;
}

#
#  Add the units for the given named categories
#
sub addUnitsFor {
	my $self = shift;
	$self->addUnitCategory($_) for (@_);
	return $self;
}

#
#  Add the units for a single category
#
sub addUnitCategory {
	my ($self, $name) = @_;
	my $category = $categories{$name};
	Value->Error("Unknown unit category '%s'", $name) unless $category;
	$category = [$category]                           unless ref($category) eq 'ARRAY';
	#
	#  Collect the units to add and remove
	#
	my @units;
	my @unitsNoAliases;
	my @remove;
	my @removeNoAliases;
	for my $def (@$category) {
		if (ref($def) eq 'HASH') {
			#
			#  Add a category by unit_def
			#
			push(@units, $def);
		} elsif ($def =~ m/^-/) {
			my $cat = $categories{ substr($def, 1) };
			if (defined($cat)) {
				#
				#  Remove a named category (it must consist only of named units)
				#
				for my $u (@$cat) {
					if ($u =~ m/\*$/) {
						push(@remove, substr($u, 0, -1));
					} else {
						push(@removeNoAliases, $u);
					}
				}
			} else {
				#
				#  Remove a named unit with or without aliases
				#
				if ($def =~ m/\*$/) {
					push(@remove, substr($def, 1, -1));
				} else {
					push(@removeNoAliases, substr($def, 1));
				}
			}
		} elsif ($def =~ m/\*$/) {
			#
			#  Add a named unit with aliases
			#
			push(@units, substr($def, 0, -1));
		} else {
			#
			#  Add a single named unit
			#
			push(@unitsNoAliases, $def);
		}
	}
	$self->addUnits(@units);
	$self->removeUnits(@remove);
	$self->removeUnitsNotAliases(@removeNoAliases);
	$self->addUnitsNotAliases(@unitsNoAliases);
	return $self;
}

#
#  Alias for addUnitsFor
#
sub withUnitsFor { (shift)->addUnitsFor(@_) }

#
#  Remove the named units and thier aliases
#
sub removeUnits {
	my $self      = shift;
	my $constants = $self->constants;
	my @units     = grep { defined($constants->get($_)) } @_;
	$self->removeUnitAndAliases($_) for (@units);
}

#
#  Remove a named unit and its aliases
#
sub removeUnitAndAliases {
	my ($self, $name) = @_;
	my $unit = $UNITS{$name};
	return unless $unit;
	my $def = join(',', map {"$_=$unit->{$_}"} (main::lex_sort(keys %$unit)));
	my @units;
	for my $alias (keys %UNITS) {
		my $UNIT = $UNITS{$alias};
		if (join(',', map {"$_=$UNIT->{$_}"} (main::lex_sort(keys %$UNIT))) eq $def) {
			push(@units, $alias);
		}
	}
	$self->constants->remove(@units);
	return $self;
}

#
#  Removes the named units nit not their aliases
#
sub removeUnitsNotAliases {
	my $self      = shift;
	my $constants = $self->constants;
	my @units     = grep { defined($constants->get($_)) } @_;
	$self->constants->remove(@units);
}

#################################################################################################
#################################################################################################

#
#  The MathObject class for units (single or compound)
#
package context::Units::Unit;
our @ISA = ('Value');

#
#  Create a new Unit object, either by parsing a string version of
#  the units, or by giving the name of a known unit, or as name => unit_def,
#  where unit_def is an object like the known units.  You can also use this
#  to objectin the Unit from a Number-with-Unit, or to make a copy of an
#  existing Unit.
#
sub new {
	my $self    = shift;
	my $class   = ref($self) || $self;
	my $context = (Value::isContext($_[0]) ? shift : $self->context);
	my ($name, $unit) = @_;
	#
	#  Look up a known unit, if none given.
	#
	$unit = $context::Units::Context::UNITS{$name} unless defined($unit);
	#
	#  If not given or not a known unit,
	#    If the argument is not a Value object
	#      Parse it as a formula and give an error if it is not constant (all Units are constants)
	#      Otherwise use the parsed value as the potential unit
	#    Return the unit, if it is one
	#    Return the unit from a numer-with-unit
	#    Otherwise error that we can't get a unit
	#
	if (!defined($unit)) {
		my $value = $name;
		$value = $self->Package("Formula")->new($context, $value) unless Value::isValue($value);
		if (Value::isFormula($value)) {
			if ($value->isConstant) {
				$value = $value->eval;
			} else {
				$value = $value->getTypicalValue($value)->unit;
			}
		}
		return $value       if $value->type eq 'Unit';
		return $value->unit if $value->type eq $context::Units::NUNIT && $value->{isConstant};
		$self->Error("Can't convert %s to a Unit", $value->showClass);
	}
	#
	#  Given a unit HASH, set the numerator and denominator power counts
	#  from the fundamental units in the unit definition, and set the
	#  factor
	#
	my $nfunds = {};
	my $dfunds = {};
	my $factor = 1;
	for my $name (keys %$unit) {
		if ($name eq 'factor') {
			$factor = $unit->{$name};
		} else {
			if ($unit->{$name} > 0) {
				$nfunds->{$name} = $unit->{$name};
			} else {
				$dfunds->{$name} = -$unit->{$name};
			}
		}
	}
	#
	#  Return the Unit object
	#
	return (
		bless {
			factor         => $factor,
			order          => [$name],
			negativePowers => {},
			nunits         => { $name => 1 },
			dunits         => {},
			nfunds         => $nfunds,
			dfunds         => $dfunds,
			isConsant      => 1,
		},
		$class
	);
}

#
#  Copy a Unit by duplicating the internal hashs and arrays.
#
sub copy {
	my $self = shift;
	my $copy = $self->SUPER::copy;
	$copy->{order}          = [ @{ $self->{order} } ];
	$copy->{nunits}         = { %{ $self->{nunits} } };
	$copy->{dunits}         = { %{ $self->{dunits} } };
	$copy->{nfunds}         = { %{ $self->{nfunds} } };
	$copy->{dfunds}         = { %{ $self->{dfunds} } };
	$copy->{negativePowers} = { %{ $self->{negativePowers} } };
	return $copy;
}

#
#  Get the factor by which the unit must be multiplied to obtain
#  a quantity in the corresponding fundamental units.
#
sub factor { (shift)->{factor} }

#############################################################

#
#  Multiply the Unit by another Unit
#
sub appendUnit {
	my ($self, $unit) = @_;
	my $copy = $self->copy;
	push(@{ $copy->{order} }, @{ $unit->{order} });
	$copy->{factor} *= $unit->{factor};
	$copy->addUnits($unit->{nunits}, 'nunits', 'dunits');
	$copy->addUnits($unit->{dunits}, 'dunits', 'nunits');
	$copy->addUnits($unit->{nfunds}, 'nfunds', 'dfunds');
	$copy->addUnits($unit->{dfunds}, 'dfunds', 'nfunds');
	$copy->{negativePowers}{$_} = 1 for (keys %{ $unit->{negativePowers} });
	return $copy;
}

#
#  Divide the Unit by another Unit
#
sub perUnit {
	my ($self, $unit) = @_;
	my $copy = $self->copy;
	push(@{ $copy->{order} }, @{ $unit->{order} });
	$copy->{factor} /= $unit->{factor};
	$copy->addUnits($unit->{nunits}, 'dunits', 'nunits');
	$copy->addUnits($unit->{dunits}, 'nunits', 'dunits');
	$copy->addUnits($unit->{nfunds}, 'dfunds', 'nfunds');
	$copy->addUnits($unit->{dfunds}, 'nfunds', 'dfunds');
	$copy->{negativePowers}{$_} = 1 for (keys %{ $unit->{negativePowers} });
	return $copy;
}

#
#  Raise the Unit to a power
sub raiseUnit {
	my ($self, $n) = @_;
	my $copy = $self->copy;
	#
	#  If the unit is not compound, record the negative unit so it can
	#  be reproduced in output later.
	#
	if ($n < 0) {
		my @nunits = keys %{ $copy->{nunits} };
		my @dunits = keys %{ $copy->{dunits} };
		$copy->{negativePowers}{ $nunits[0] } = 1
			if @nunits == 1
			&& @dunits == 0
			&& $copy->{nunits}{ $nunits[0] } == 1
			&& $self->getFlag('keepNegativePowers');
	}
	$copy->{factor} = $copy->{factor}**$n;
	$copy->{nunits}{$_} *= $n for (keys %{ $copy->{nunits} });
	$copy->{dunits}{$_} *= $n for (keys %{ $copy->{dunits} });
	$copy->checkUnits('nunits', 'dunits');
	$copy->checkUnits('dunits', 'nunits');
	$copy->{nfunds}{$_} *= $n for (keys %{ $copy->{nfunds} });
	$copy->{dfunds}{$_} *= $n for (keys %{ $copy->{dfunds} });
	$copy->checkUnits('nfunds', 'dfunds');
	$copy->checkUnits('dfunds', 'nfunds');
	return $copy;
}

#
#  Add the powers of units in the $units hash into the Unit's $key1
#  list, and cancel powers between the $key1 and $key2 lists, moving
#  any negative powers into the $key2 list.
#
sub addUnits {
	my ($self, $units, $key1, $key2) = @_;
	for my $u (keys %$units) {
		$self->addUnitPower($self->{$key1}, $self->{$key2}, $u, $units->{$u});
	}
}

#
#  Add $n to the unit $u in the $units hash, and move it to
#  the $other hash if the power ends up being negative.
#
sub addUnitPower {
	my ($self, $units, $other, $u, $n) = @_;
	$units->{$u} = ($units->{$u} // 0) + $n;
	$self->checkUnitPower($units, $other, $u);
}

#
#  Check if there is cancelation between the $key1 and $key2 lists,
#  and move any negative powers from the $key1 list to the $key2 list
#
sub checkUnits {
	my ($self, $key1, $key2) = @_;
	for my $u (keys %{ $self->{$key1} }) {
		$self->checkUnitPower($self->{$key1}, $self->{$key2}, $u);
	}
}

#
#  Handle cancelation of powers in the $units and $other lists.
#
sub checkUnitPower {
	my ($self, $units, $other, $u) = @_;
	if ($units->{$u} == 0) {
		#
		#  Remove the unit if its power is 0
		#
		delete $units->{$u};
		return;
	} elsif ($units->{$u} < 0) {
		#
		#  If the power is negative, add it intto the
		#  $other list.
		#
		$other->{$u} = ($other->{$u} // 0) - $units->{$u};
		delete $units->{$u};
		return;
	}
	return if !$other->{$u};
	#
	#  The unit is in both lists, so we cancel.
	#
	if ($other->{$u} > $units->{$u}) {
		#
		#  There are more in the $other list, so remove
		#  the ones from $units and delete from there.
		#
		$other->{$u} -= $units->{$u};
		delete $units->{$u};
	} else {
		#
		#  There are more in the $units list, so remove
		#  the ones from $other and delete from there.
		#  If they were equal, remove from $units as well.
		#
		$units->{$u} -= $other->{$u};
		delete $other->{$u};
		delete $units->{$u} if $units->{$u} == 0;
	}
}

#############################################################

#
#  Multiply a Unit by a Number or another Unit
#
sub mult {
	my ($self, $l, $r, $other) = Value::checkOpOrder(@_);
	($l, $r) = (Value::makeValue($l), Value::makeValue($r));
	my ($ltype, $rtype) = ($l->type, $r->type);
	return $l->appendUnit($r) if $ltype eq 'Unit' && $rtype eq 'Unit';
	$self->Error("A Unit can't be multiplied by %s", Value::showClass($r)) if $ltype eq 'Unit';
	$self->Error("Can't multiply %s by a Unit", Value::showClass($l))
		unless $ltype eq 'Number' || $ltype eq $context::Units::NUNIT;
	return $self->Package($context::Units::NUNIT)->new($l->copy, $r->copy);
}

#
#  Divide a Unit by a Number or another Unit
#
sub div {
	my ($self, $l, $r, $other) = Value::checkOpOrder(@_);
	($l, $r) = (Value::makeValue($l), Value::makeValue($r));
	my ($ltype, $rtype) = ($l->type, $r->type);
	return $l->perUnit($r) if $ltype eq 'Unit' && $rtype eq 'Unit';
	$self->Error("A Unit can't be divided by %s", Value::showClass($r)) if $ltype eq 'Unit';
	$self->Error("Can't divide %s by a Unit", Value::showClass($l));
}

#
#  Raise a Unit to a numeric power
#
sub power {
	my ($self, $l, $r, $other) = Value::checkOpOrder(@_);
	($l, $r) = (Value::makeValue($l), Value::makeValue($r));
	$self->Error("A Unit can't be raised to %s", Value::showClass($r))
		unless $l->type eq 'Unit' && $r->type eq 'Number';
	my $n = $r->value;
	$self->Error("A Unit can only be raised to a non-zero integer value") if $n == 0 || CORE::int($n) != $n;
	return $l->raiseUnit($n);
}

#
#  Compare two Units (0 means equal)
#
sub compare {
	my ($self, $l, $r, $other) = Value::checkOpOrder(@_);
	($l, $r) = (Value::makeValue($l), Value::makeValue($r));
	return $l->type eq 'Unit' ? -1 : 1 unless $l->type eq $r->type;
	my ($ls, $rs) = ($l->fString, $r->fString);
	return $ls cmp $rs unless $ls eq $rs;
	return $l->{factor} <=> $r->{factor};
}

#############################################################

#
#  The default flags for answer checking (take them from the context instead)
#
sub cmp_defaults { () }

#
#  Check for sameUnits and exactUnits, and give the needed messages and partial credit
#
sub cmp_postprocess {
	my ($self, $ans) = @_;
	my $student = $ans->{student_value};
	return unless defined($student) && $student->type eq 'Unit';
	return                                              if $ans->{ans_message};
	$self->cmp_Error($ans, "Your units aren't correct") if $self->fString ne $student->fString;
	return                                              if $ans->{score} != 1 || !$self->getFlag('exactUnits');
	if ($self->uString(1) ne $student->uString(1)) {
		$self->cmp_Error($ans,
			"Your answer is correct, but the units aren't in the right order or misuse negative powers");
		$ans->{score} = $self->getFlag('partialCredit');
	}
}

#############################################################

#
#  Get the string version using the original units and powers
#
sub string {
	my ($self, $equation, $open, $close, $precedence) = @_;
	my $string = $self->stringFor('nunits', 'dunits', $self->{order});
	$string = '(' . $string . ')' if $string =~ m![ /]! && defined($precedence) && $precedence > 2.9;
	return $string;
}

#
#  Get the string version using the fundamental units
#
sub fString {
	my $self = shift;
	return $self->stringFor('nfunds', 'dfunds', undef, 1);
}

#
#  Get the string version using original units using:
#    The original order and powers if $exact is set, or
#    Alphabetic order and fractions otherwise.
#
sub uString {
	my ($self, $exact) = @_;
	return $self->stringFor('nunits', 'dunits', $exact ? $self->{order} : undef, !$exact);
}

#
#  Creates the string version using the given order and power settings
#
sub stringFor {
	my ($self, $key1, $key2, $order, $noNegativePowers) = @_;
	my ($nunits, $dunits) = ({ %{ $self->{$key1} } }, { %{ $self->{$key2} } });
	$order = [ main::lex_sort(keys %$nunits, keys %$dunits) ] unless $order;
	my ($ns, $ds) = ([], []);
	my $constants = $self->context->constants;
	for my $u (@$order) {
		$self->pushUnitString($ns, $ds, $u, $nunits->{$u}, $noNegativePowers);
		$self->pushUnitString($ds, $ns, $u, $dunits->{$u}, $noNegativePowers);
		$nunits->{$u} = $dunits->{$u} = 0;    # don't include them again
	}
	my ($num, $den) = (join(' ', @$ns), join(' ', @$ds));
	return $self->with(useNegativePowers => 1)->string if !$num && $den;
	return ($den && @$ns > 1 ? "($num)" : $num) . ($den ? '/' . (@$ds > 1 ? "($den)" : $den) : '');
}

#
#  Create the string for a given unit and power and push it
#  into the $units or $invert array depending on whether it has
#  a negative power or not
#
sub pushUnitString {
	my ($self, $units, $invert, $u, $n, $noNegativePowers) = @_;
	return unless $n;
	my $def  = $self->context->constants->get($u);
	my $unit = ($def->{string} || $u);
	if (!$noNegativePowers && ($self->{negativePowers}{$u} || $self->getFlag('useNegativePowers'))) {
		push(@$invert, $unit . "^-$n");
	} else {
		push(@$units, $unit . ($n > 1 ? "^$n" : ''));
	}
}

#
#  Create the TeX string for the Units
#
sub TeX {
	my $self = shift;
	my ($nunits, $dunits) = ({ %{ $self->{nunits} } }, { %{ $self->{dunits} } });
	my ($ns, $ds)         = ([], []);
	my $constants = $self->context->constants;
	for my $u (@{ $self->{order} }) {
		$self->pushUnitTeX($ns, $u, $nunits->{$u}, $ds);
		$self->pushUnitTeX($ds, $u, $dunits->{$u}, $ns);
		$nunits->{$u} = $dunits->{$u} = 0;    # don't include them again
	}
	my ($num, $den) = (join('\,', @$ns) || "1", join('\,', @$ds));
	return $den ? "\\frac{$num}{$den}" : $num;
}

#
#  Create the TeX string for a given unit and power and
#  push it into the $units array.
#
sub pushUnitTeX {
	my ($self, $units, $u, $n, $invert) = @_;
	return unless $n;
	my $def  = $self->context->constants->get($u);
	my $unit = ($def->{TeX} || "\\text{$u}");
	if ($self->{negativePowers}{$u} || $self->getFlag('useNegativePowers')) {
		push(@$invert, $unit . "^{-$n}");
	} else {
		push(@$units, $unit . ($n > 1 ? "^{$n}" : ''));
	}
}

#
#  Create the Perl code to recreate the Units.
#
sub perl {
	my $self = shift;
	return ref($self) . '->new("' . $self->string . '")';
}

#############################################################

#
#  Override the functions to produce errors on Unit inputs
#
sub log  { context::Units::fnError('log') }
sub exp  { context::Units::fnError('exp') }
sub sqrt { context::Units::fnError('sqrt') }

sub cos { context::Units::fnError('cos') }
sub sin { context::Units::fnError('sin') }

sub atan2 { Value->Error("Function 'atan2' has the wrong type of arguments") }

#################################################################################################
#################################################################################################

#
#  The MathObject class for numbers with units
#
package context::Units::NumberWithUnit;
our @ISA = ('Value');

#
#  Create a new Number-with-Unit object, either by giving the number
#  and units separately.  The number can be any MathObject that is of
#  type Number (including a Formula returing a number), or a string to
#  be parsed to copmute the number.  The unit can be a Unit object or
#  a string that can be parsed to a Unit.
#
sub new {
	my $self    = shift;
	my $class   = ref($self) || $self;
	my $context = (Value::isContext($_[0]) ? shift : $self->context);
	my $unit    = pop;
	my $n       = Value::isValue($_[0]) && $_[0]->type eq 'Number' ? $_[0] : $self->Package('Real')->new($context, @_);
	$unit = $self->Package('Unit')->new($context, $unit) unless Value::isValue($unit);
	return $n * $unit if Value::isFormula($n) && $n->type eq 'Number';
	$self->Error('Can\'t append a Unit to %s',  Value::showClass($n))    unless $n->type eq 'Number';
	$self->Error('Can\'t convert %s to a Unit', Value::showClass($unit)) unless $unit->classMatch('Unit');
	return $n if $unit->string eq '';
	return bless { data => [ $n, $unit ], context => $context, isConstant => 1 }, $class;
}

#
#  Return the proper type and class data
#
sub typeRef {$context::Units::NUMBER_WITH_UNIT}
sub class   {$context::Units::NUNIT}
sub length  {1}

#############################################################

#
#  Functions for obtaining the various parts of the Number-with-Units
#
sub number { (shift)->{data}[0] }
sub unit   { (shift)->{data}[1] }
sub factor { (shift)->{data}[1]{factor} }

sub quantity {
	my $self = shift;
	return $self->number * $self->factor;
}

#############################################################

#
#  Get the string version using the fundamental units
#
sub fString { (shift)->unit->fString }

#
#  Get the string version using original units using:
#    The original order and powers if the argument is true, or
#    Alphabetic order and fractions if not.
#
sub uString { (shift)->unit->uString(shift) }

#
#  Get the string version of the Number with Units
#
sub string {
	my ($self, $equation, $open, $close, $precedence) = @_;
	my $string = $self->number->string . ' ' . $self->unit->string;
	$string = '(' . $string . ')' if defined($precedence) && $precedence > 1;
	return $string;
}

#
#  Get the TeX version of the Number with Units
#
sub TeX {
	my ($self, $equation, $open, $close, $precedence) = @_;
	my $tex = $self->number->TeX . '\,' . $self->unit->TeX;
	$tex = '(' . $tex . ')' if defined($precedence) && $precedence > 1;
	return $tex;
}

#
#  Get the Perl code to re-create the Number with Units
#
sub perl {
	my $self = shift;
	return ref($self) . '->new(' . $self->number . ', "' . $self->unit->string . '")';
}

#
#  Since the string version contains a space, we add parentheses when stringifying
#  into another string
#
sub pdot { '(' . (shift)->stringify(@_) . ')' }

#############################################################

#
#  The default flags for answer checking (take them from the context instead)
#
sub cmp_defaults { () }

#
#  Give a message about incorrect units, and check for sameUnits and
#  exactUnits, and give the needed messages and partial credit.
#
sub cmp_postprocess {
	my ($self, $ans) = @_;
	my $student = $ans->{student_value};
	return unless defined($student) && $student->type eq $context::Units::NUNIT;
	return                                              if $ans->{ans_message};
	$self->cmp_Error($ans, "Your units aren't correct") if $self->fString ne $student->fString;
	return                                              if $ans->{score} != 1;
	my ($same, $exact) = ($self->getFlag('sameUnits'), $self->getFlag('exactUnits'));
	return unless $same || $exact;

	if ($self->uString ne $student->uString) {
		$self->cmp_Error($ans, "Your answer is correct, but the units don't match the correct answer exactly");
		$ans->{score} = $self->getFlag('partialCredit');
	}
	if ($exact && $self->uString(1) ne $student->uString(1)) {
		$self->cmp_Error($ans,
			"Your answer is correct, but the units aren't in the right order or misuse negative powers");
		$ans->{score} = $self->getFlag('partialCredit');
	}
}

#############################################################

#
#  Negate by negating the numeric part
#
sub neg {
	my $self = shift;
	return $self->new(-$self->number, $self->unit->copy);
}

#
#  Take absolute value on the numeric part
#
sub abs {
	my $self = shift;
	return $self->new(CORE::abs($self->number), $self->unit->copy);
}

#
#  Add a Number with Units to another one
#
sub add {
	my ($self, $l, $r, $other) = Value::checkOpOrder(@_);
	shift;
	($l, $r) = (Value::makeValue($l), Value::makeValue($r));
	$self->Error('You can\'t add %s to %s', $l->showClass, $r->showClass)
		unless $other->classMatch('NumberWithUnit');
	$self->Error('You can only add quantities with the same units') unless $l->fString eq $r->fString;
	return $self->new($l->number + $r->quantity / $l->factor, $l->unit->copy);
}

#
#  Subtract a Number with Units from another one
#
sub sub {
	my ($self, $l, $r, $other) = Value::checkOpOrder(@_);
	shift;
	($l, $r) = (Value::makeValue($l), Value::makeValue($r));
	$self->Error('You can\'t subtract %s from %s', $r->showClass, $l->showClass)
		unless $other->classMatch('NumberWithUnit');
	$self->Error('You can only subtract quantities with the same units') unless $l->fString eq $r->fString;
	return $self->new($l->number - $r->quantity / $l->factor, $l->unit->copy);
}

#
#  Multiply a Number with Units by another Number with Units, or a Unit, or a Number
#
sub mult {
	my ($self, $l, $r, $other) = Value::checkOpOrder(@_);
	($l, $r) = (Value::makeValue($l), Value::makeValue($r));
	my ($lUnit, $rUnit)   = ($l->classMatch('Unit'), $r->classMatch('Unit'));
	my ($lUnitN, $rUnitN) = ($l->classMatch('NumberWithUnit'), $r->classMatch('NumberWithUnit'));
	return $self->new($l->number->copy,        $l->unit->appendUnit($r))       if $lUnitN && $rUnit;
	return $self->new($l->number * $r->number, $l->unit->appendUnit($r->unit)) if $lUnitN && $rUnitN;
	return $self->new($l * $r->number,         $r->unit->copy)                 if $l->type eq 'Number';
	return $self->new($l->number * $r,         $l->unit->copy)                 if $$r->type eq 'Number';
	$self->Error("A Unit can't be multiplied by %s", Value::showClass($r)) if $lUnit;
	$self->Error("Can't multiply %s by a Unit", Value::showClass($l));
}

#
#  Divide a Number with Units by another Number with Units, or a Unit, or a Number,
#  or divide a Number, Unit, or Number with Units byt a Number with Units
#
sub div {
	my ($self, $l, $r, $other) = Value::checkOpOrder(@_);
	($l, $r) = (Value::makeValue($l), Value::makeValue($r));
	my ($lUnit, $rUnit)   = ($l->classMatch('Unit'), $r->classMatch('Unit'));
	my ($lUnitN, $rUnitN) = ($l->classMatch('NumberWithUnit'), $r->classMatch('NumberWithUnit'));
	return $self->new($l->number->copy,        $l->unit->perUnit($r))       if $lUnitN && $rUnit;
	return $self->new($l->number / $r->number, $l->unit->perUnit($r->unit)) if $lUnitN && $rUnitN;
	return $self->new($l / $r->number,         $r->unit->raiseUnit(-1))     if $l->type eq 'Number';
	return $self->new($l->number / $r,         $l->unit->copy)              if $r->type eq 'Number';
	$self->Error("A Unit can't be divided by %s", Value::showClass($r)) if $lUnit;
	$self->Error("Can't divide %s by a Unit", Value::showClass($l));
}

#
#  Raise a Number with Units to an integer
#
sub power {
	my ($self, $l, $r, $other) = Value::checkOpOrder(@_);
	($l, $r) = (Value::makeValue($l), Value::makeValue($r));
	$self->Error("A $context::Units::NUNIT can't be raised to %s", $r->showClass)
		unless $l->classMatch('NumberWithUnit') && $r->type eq 'Number';
	my $n = $r->value;
	$self->Error("A $context::Units::NUNIT can only be raised to a non-zero integer value")
		if $n == 0 || CORE::int($n) != $n;
	return $self->new($l->number**$n, $l->unit->raiseUnit($n));
}

#
#  Compare two Numbers with Units (0 means equal)
#
sub compare {
	my ($self, $l, $r, $other) = Value::checkOpOrder(@_);
	($l, $r) = (Value::makeValue($l), Value::makeValue($r));
	return $l->type eq 'Unit' || $r->classMatch('NumberWithUnit') ? -1 : 1 unless $l->type eq $r->type;
	my ($ls, $rs) = ($l->fString, $r->fString);
	return $ls cmp $rs unless $ls eq $rs;
	return $l->quantity <=> $r->quantity;
}

#############################################################

#
#  Functions that can't have Numbers with Units as arguments
#
sub log  { context::Units::fnError('log') }
sub exp  { context::Units::fnError('exp') }
sub sqrt { context::Units::fnError('sqrt') }

sub atan2 { Value->Error("Function 'atan2' has the wrong type of arguments") }

#
#  sin() and cos() can take arguments that are angles
#
sub cos {
	my $self = shift;
	return CORE::cos($self->quantity) if $self->fString eq 'rad';
	context::Units::fnError('cos');
}

sub sin {
	my ($self, $x) = @_;
	return CORE::sin($self->quantity) if $self->fString eq 'rad';
	context::Units::fnError('sin');
}

#############################################################

#
#  Convert a Number with Units to one using the base units (in
#  alphabetial order)
#
sub toBaseUnits {
	my $self = shift;
	my $unit = $self->unit->copy;
	$unit->{nunits}         = { %{ $unit->{nfunds} } };
	$unit->{dunits}         = { %{ $unit->{dfunds} } };
	$unit->{factor}         = 1;
	$unit->{order}          = [ main::lex_sort(%{ $unit->{nunits} }, %{ $unit->{dunits} }) ];
	$unit->{negativePowers} = {};
	return $self->new($self->quantity, $unit);
}

#
#  Convert a Number with Units to one using the given units
#
sub toUnits {
	my ($self, $units) = @_;
	$units = Value::makeValue($units) unless Value::isValue($units);
	$self->Error("'%s' is not a Unit", $units) unless $units->type eq 'Unit';
	$self->Error("Units '%s' and '%s' are not compatible", $self->unit, $units)
		unless $self->fString eq $units->fString;
	return $self->new($self->quantity / $units->{factor}, $units);
}

#################################################################################################
#################################################################################################

#
#  A common class for getting the super-class of an extension class
#
package context::Units::Super;
our @ISA = ('context::Extensions::Super');

sub extensionContext {'context::Units'}

#################################################################################################
#################################################################################################

#
#  A common base class for unit-based binary operators.  It is used as
#  part of a dynamically created class that includes a units class and
#  original class from the context that the units context extends.
#
package context::Units::BOP;
our @ISA = ('context::Units::Super', 'Parser::BOP');

#
#  True if one of the operands is a Unit or Number with Unit
#
sub hasUnitOperand {
	my ($self, $ltype, $rtype) = @_;
	return
		$ltype eq 'Unit'
		|| $ltype eq $context::Units::NUNIT
		|| $rtype eq 'Unit'
		|| $rtype eq $context::Units::NUNIT;
}

#
#  True if both operands are Units or Numbers with Units
#
sub bothUnitOperands {
	my ($self, $ltype, $rtype) = @_;
	return ($ltype eq 'Unit' || $ltype eq $context::Units::NUNIT)
		&& ($rtype eq 'Unit' || $rtype eq $context::Units::NUNIT);
}

#
#  True if one of the operands is a Number with Units and the other is
#  a Number with Unit or a Number
#
sub hasNumberUnitOperand {
	my ($self, $ltype, $rtype) = @_;
	my $NUNIT = $context::Units::NUNIT;
	return ($ltype eq $NUNIT && ($rtype eq 'Number' || $rtype eq $NUNIT))
		|| ($rtype eq $NUNIT && ($ltype eq 'Number' || $ltype eq $NUNIT));
}

#
#  True if both of the operands are a Numbers with Units
#
sub hasNumberUnitOperands {
	my ($self, $ltype, $rtype) = @_;
	return $ltype eq $context::Units::NUNIT && $rtype eq $context::Units::NUNIT;
}

#
#  Call the _check from the original class unless one of the operands
#  is a Number with Units, in which case, we check that operations are
#  allowed, and set the type if they are.
#
sub checkNumberUnits {
	my $self = shift;
	my ($ltype, $rtype) = ($self->{lop}->type, $self->{rop}->type);
	return $self->mutate->_check unless $self->hasNumberUnitOperand($ltype, $rtype);
	$self->Error("Both operands of '%s' must have units if one does", $self->{bop})
		unless $self->hasNumberUnitOperands($ltype, $rtype);
	my $lunit = $self->Package('Formula')->new($self->{lop})->unit;
	my $runit = $self->Package('Formula')->new($self->{rop})->unit;
	$self->Error("Units '%s' and '%s' are not compatible", $lunit->string, $runit->string)
		unless $lunit->fString eq $runit->fString;
	$self->Error("Can't use '%s' with Numbers with Units in this context", $self->{bop})
		if $self->context->flag('limitedOperators');
	$self->{type} = $context::Units::NUMBER_WITH_UNIT;
	$self->factorUnits if !$self->{isConstant} && $self->context->flag('factorUnits');
}

#
#  Call the _check from the original class unless one of the operands
#  is a Unit or Number with Units.  Otherwise, check the operands
#  and report any messages, and set the type accordingly.
#  For multiplication, use space or \, for string and TeX versions, not '*'.
#
sub checkMultDiv {
	my ($self, $op1, $op2, $action) = @_;
	my $mult = $op1 eq 'multiply';
	my ($ltype, $rtype) = ($self->{lop}->type, $self->{rop}->type);
	$self->{type} = $context::Units::NUMBER_WITH_UNIT;
	return if $ltype eq $context::Units::NUNIT && $rtype eq 'Unit' && $self->adjustFormulaUnits($mult);
	$self->Error("You can only use '%s' with Units", $self->{bop})
		if $self->{bop} eq 'per' && !$self->bothUnitOperands($ltype, $rtype);
	return $self->mutate->_check unless $self->hasUnitOperand($ltype, $rtype);
	$self->Error("Can't $op1 two Numbers with Units in this context")
		if $self->context->flag('limitedOperators') && $ltype eq $context::Units::NUNIT && $ltype eq $rtype;
	$self->{def} = {
		%{ $self->{def} },
		$mult ? (string => ' ', TeX => '\,', perl => '*') : (),
		precedence => $self->{def}{precedence} - ($self->{def}{isUnit} ? 0 : .1),
		isUnit     => 1
		}
		if $rtype eq 'Unit' && $ltype eq 'Number';

	if ($ltype eq $rtype) {
		$self->{type} = $context::Units::UNIT if $ltype eq 'Unit';
		return;
	}
	return if $ltype eq $context::Units::NUNIT && ($rtype eq 'Unit' || $rtype eq 'Number');
	return
		if ($ltype eq 'Number' && $rtype eq $context::Units::NUNIT)
		|| ($rtype eq 'Number' && $ltype eq $context::Units::NUNIT && $mult);
	$self->Error('A %s can only be $op2 by a Unit', $ltype) if $lHasUnit;
	$self->Error('A Unit can only $action another Unit') unless $ltype eq 'Number' || $mult;
}

#
#  When we have "(x unit) unit" or "(x unit) / unit", adjust these to be
#  "x (unit unit) or "x (unit / unit)" so that the output is better
#  (i.e., doesn't include extra parentheses).
#
sub adjustFormulaUnits {
	my ($self, $mult) = @_;
	return 0 unless $self->hasExplicitUnit($self->{lop});
	my ($lunit, $runit) = ($self->{lop}{rop}->eval, $self->{rop}->eval);
	my $unit = $mult ? $lunit->appendUnit($runit) : $lunit->perUnit($runit);
	$self->{rop} = $self->Item("Value")->new($self->{equation}, $unit);
	$self->{lop} = $self->{lop}{lop};
	$self->makeMult;
	return 1;
}

#
#  Hack to replace BOP with a division BOP.
#  (When check() is changed to accept a return value,
#  this will not be necessary.)
#
sub makeMult {
	my $self = shift;
	my $mult = $self->Item("BOP")->new($self->{equation}, '*', $self->{lop}, $self->{rop});
	$self->mutate($self->context, $mult);
}

#
#  Check if the units have cancelled, and set the type accordingly
#
sub checkCancelledUnits {
	my $self = shift;
	return unless $self->type eq $context::Units::NUNIT;
	return if $self->{rop}->type ne 'Unit' || $self->{rop}->eval->string ne '';
	$self->{type} = $Value::Type{number};
}

sub hasExplicitUnit {
	my ($self, $x) = @_;
	return $x->class eq 'BOP' && $x->{bop} eq '*' && $x->{rop}->type eq 'Unit';
}

sub splitNumberUnit {
	my ($self, $x) = @_;
	return () unless $x->type eq $context::Units::NUNIT;
	return ($x->{lop}, $x->{rop}) if $self->hasExplicitUnit($x);
	return () unless $x->{isConstant};
	$x = $x->eval;
	return (
		$self->Item('Number')->new($self->{equation}, $x->number),
		$self->Item('Value')->new($self->{equation}, $x->unit)
	);
}

sub factorUnits {
	my $self = shift;
	return if $self->{isConstant};
	my ($lnum, $lunit) = $self->splitNumberUnit($self->{lop});
	return unless $lunit;
	my ($rnum, $runit) = $self->splitNumberUnit($self->{rop});
	return unless $runit && $lunit->string eq $runit->string;
	$self->{lop} = $self->Item("BOP")->new($self->{equation}, $self->{bop}, $lnum, $rnum);
	$self->{rop} = $lunit;
	$self->makeMult;
}

#
#  For string output, add parenthese if the precedence is the same
#
sub string {
	my $self = shift;
	$_[1] = 'same' if $self->{def}{isUnit} && @_;
	return &{ $self->super("string") }($self, @_);
}

#############################################################

package context::Units::BOP::add;
our @ISA = ('context::Units::BOP');

sub _check { (shift)->checkNumberUnits }
sub _eval  { $_[1] + $_[2] }

#############################################################

package context::Units::BOP::subtract;
our @ISA = ('context::Units::BOP');

sub _check { (shift)->checkNumberUnits }
sub _eval  { $_[1] - $_[2] }

#############################################################

package context::Units::BOP::multiply;
our @ISA = ('context::Units::BOP');

sub _check {
	my $self  = shift;
	my $class = ref($self);
	$self->checkMultDiv('multiply', 'multiplied', 'follow a Number or');
	$self->checkCancelledUnits() if ref($self) eq $class;
}
sub _eval { $_[1] * $_[2] }

#############################################################

package context::Units::BOP::Space;
our @ISA = ('context::Units::BOP::multiply');

#############################################################

package context::Units::BOP::divide;
our @ISA = ('context::Units::BOP');

sub _check {
	my $self  = shift;
	my $class = ref($self);
	$self->checkMultDiv('divide', 'divided', 'divide');
	$self->checkCancelledUnits() if ref($self) eq $class;
}
sub _eval { $_[1] / $_[2] }

#############################################################

package context::Units::BOP::power;
our @ISA = ('context::Units::BOP');

sub _check {
	my $self = shift;
	my ($ltype, $rtype) = ($self->{lop}->type, $self->{rop}->type);
	return $self->mutate->_check
		unless ($ltype eq 'Unit' || $ltype eq $context::Units::NUNIT) && $rtype eq 'Number';
	if ($self->context->flag('limitedOperators')) {
		$self->Error("Can't raise a %s to a power in this context", $ltype) if $ltype ne 'Unit';
		my $unit   = $self->{lop}->eval;
		my @nunits = keys %{ $unit->{nunits} };
		my @dunits = keys %{ $unit->{dunits} };
		$self->Error("Can't raise a Compound Unit to a power in this context") unless @nunits == 1 && @dunits == 0;
	}
	$self->{type} = $self->{lop}->{type};
}

sub _eval { $_[1]**$_[2] }

#############################################################

#
#  Implements "squared", "cubed", "square", and "cubic" operators.
#
package context::Units::UOP::NamedPower;
our @ISA = ('Parser::UOP');

sub _check {
	my $self = shift;
	$self->Error("You can only use '%s' with a (single) Unit", $self->{uop})
		unless $self->{op}->type eq 'Unit' && $self->{op}->eval->string !~ m/[ ^]/;
	$self->{type} = $context::Units::UNIT;
}

sub _eval { $_[1]->raiseUnit($_[0]->{def}{power}) }

sub string { (shift)->eval->string(@_) }
sub TeX    { (shift)->eval->TeX(@_) }
sub perl   { (shift)->eval->perl(@_) }

#################################################################################################
#################################################################################################

#
#  A common base class for the unit function classes to allow trig and hyperbolic functions
#  to have arguments that are Numbers with Units when the units are angles or other units.
#
package context::Units::Function::common;
our @ISA = ('context::Units::Super', 'Parser::Function');

sub allowDegrees {1}    # allow angle arguments by default
sub allowUnits   {0}    # don't allow other units by default

#
#  True when $x is a Number with Units where the units are degrees.
#
sub isAngle {
	my ($self, $x) = @_;
	return 0 unless $x->type eq $context::Units::NUNIT;
	$x = $x->eval->unit if $x->{isConstant};
	$x = $x->{rop}      if $x->class eq 'BOP' && $x->{lop}->type eq 'Number';
	return $x->type eq 'Unit' && $x->eval->fString eq 'rad';
}

#
#  Check whether degrees or other units are allowed, and do the usual
#  check (for error reporting) if not.
#
sub _check {
	my $self = shift;
	return if &{ $self->super('checkArgCount') }($self, 1);
	my $arg = $self->{params}->[0];
	if (($self->allowDegrees && $self->isAngle($arg)) || ($self->allowUnits && $arg->type eq $context::Units::NUNIT)) {
		$self->{type} = $Value::Type{number};
	} else {
		$self->mutate->_check;
	}
}

#
#  Convert an angle to radians if the argument is an angle (and conversion is allowed)
#
sub _eval {
	my ($self, $arg) = @_;
	my $name = $self->{name};
	$arg = $arg->quantity
		if $self->allowDegrees
		&& Value::isValue($arg)
		&& $arg->type eq $context::Units::NUNIT
		&& $arg->fString eq 'rad';
	return &{ $self->super($name) }($self, $arg);
}

#
#  Convert an angle to radians if the argument is an angle (and conversion is allowed)
#  before calling the function.
#
sub _call {
	my $self = shift;
	my $name = shift;
	my $n    = $_[0];
	return $self->mutate->_call($name, @_) unless Value::isValue($n) && $n->type eq $context::Units::NUNIT;
	Value::Error("Function '%s' has too many inputs", $name) if scalar(@_) > 1;
	Value::Error("Function '%s' has too few inputs",  $name) if scalar(@_) == 0;
	$n = $n->quantity if $self->allowDegrees && $n->fString eq 'rad';
	Value::Error("The input to '%s' must be a number", $name) unless $n->isNumber || $self->allowUnits;
	return &{ $self->super($name) }($self, $n);
}

#############################################################

package context::Units::Function::trig;
our @ISA = ('context::Units::Function::common');

#############################################################

package context::Units::Function::hyperbolic;
our @ISA = ('context::Units::Function::common');

#############################################################

package context::Units::Function::numeric;
our @ISA = ('context::Units::Function::common');

sub allowDegrees {0}
sub allowUnits   { (shift)->{name} eq 'abs' }

#################################################################################################
#################################################################################################

#
#  Allow Real() to return the numeric part of a Number with Units,
#  otherwise, do the original Real() call.
#
package context::Units::Value::Real_Parens;
our @ISA = ('context::Units::Super', 'Value::Real');

sub new {
	my $self    = shift;
	my $context = (Value::isContext($_[0]) ? shift : $self->context);
	my $x       = $_[0];
	return $x->number if @_ == 1 && Value::isValue($x) && $x->type eq $context::Units::NUNIT;
	return $self->mutate($context)->new($context, @_);
}

#################################################################################################
#################################################################################################

#
#  Allow Formulas to have "unit" and "number" methods
#
package context::Units::Value::Formula;
our @ISA = ('context::Units::Super', 'Value::Formula');

sub checkNumberWithUnits {
	my ($self, $method) = @_;
	$self->Error("Can't use '->$method' with " . $self->showClass)
		unless $self->type eq $context::Units::NUNIT;
}

sub unit {
	my $self = shift;
	$self->checkNumberWithUnits('unit');
	return $self->getTypicalValue($self)->unit;
}

sub number {
	my $self = shift;
	$self->checkNumberWithUnits('number');
	return $self->Package('Formula()')->new($self->{tree}{lop})
		if ($self->{tree}->class eq 'BOP'
			&& $self->{tree}{bop} eq '*'
			&& $self->{tree}{lop}->type eq 'Number'
			&& $self->{tree}{rop}->type eq 'Unit');
	return $self / $self->getTypicalValue($self)->unit;
}

package context::Units::Parser::Formula;
our @ISA = ('context::Units::Value::Formula');

#################################################################################################
#################################################################################################

#
#  Allow parentheses to be used around units in contexts (like
#  LimitedNumeric) where they have been removed.  This allows
#  you to enter "kg/(m s)" in such contexts.
#
package context::Units::UnitList;
our @ISA = qw(Parser::List);

sub _check {
	my $self = shift;
	$self->{type}{list} = 0;
	$self->Error("Lists of units are not allowed") if ($self->{type}{length} != 1);
	my $arg = $self->{coords}[0];
	$self->Error("Parentheses should only be used around units in this context")
		unless $arg->type eq 'Unit' || $self->context->flag("allowBadOperands");
	$self->{type} = $context::Units::UNIT;
}

sub _eval { $_[1][0] }

#################################################################################################
#################################################################################################

1;
