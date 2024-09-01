
=head1 NAME

contextFraction.pl - Implements a MathObject class for Fractions.

=head1 DESCRIPTION

This context implements a Fraction object that works like a Real, but
keeps the numerator and denominator separate.  It provides methods for
reducing the fractions, and for allowing fractions with a whole-number
preceding it, as in C<4 1/2> for "four and one half".  The answer
checker can require that students reduce their results, and there are
contexts that don't allow entery of decimal values (only fractions),
and that don't allow any operators or functions (other than division
and negation).

To use these contexts, first load the contextFraction.pl file:

    loadMacros("contextFraction.pl");

and then select the appropriate context -- one of the following:

    Context("Fraction");
    Context("Fraction-NoDecimals");
    Context("LimitedFraction");
    Context("LimitedProperFraction");

The first is the most general, and allows fractions to be intermixed
with real numbers, so C<1/2 + .5> would be allowed.  Also, C<1/2.5> is
allowed, though it produces a real number, not a fraction, since this
fraction class only implements fractions of integers.  All operators
and functions are defined, so there are no restrictions on what is
allowed by the student.

The second does not allow decimal numbers to be entered, but they can
still be produced as the result of function calls, or by named
constants such as "pi".  For example, C<1/sqrt(2)> is allowed (and
produces a real number result).  All functions and operations are
defined, and the only real difference between this and the previous
context is that decimal numbers can't be typed in explicitly.

The third context limits the operations that can be performed: in
addition to not being able to type decimal numbers, no operations
other than division and negation are allowed, and no function calls at
all.  Thus C<1/sqrt(2)> would be illegal, as would C<1/2 + 2>.  The student
must enter a whole number or a fraction in this context.  It is also
permissible to enter a whole number WITH a fraction, as in C<2 1/2> for
"two and one half", or C<5/2>.

The fourth is the same as LimiteFraction, but students must enter proper
fractions, and results are shown as proper fractions.

It is also possible to add fractions to an existing context using
C<context::Fraction::extending()> and passing it either the name of
the context, or the Context object itself.  E.g.:

    Context(context::Fraction::extending("Matrix"));

would produce a context where fractions can be used in Matrix entries.

You can also pass any of the Fraction contact flags to
C<context::Fraction::extending()> to set those flags in the new
context.  For example:

    Context(context::Fraction::extending("Matrix", allowMixedNumbers => 1));

would get a Matrix context where fractions can be entered as mixed numbers.

You can use the C<Compute()> function to generate fraction objects, or
the C<Fraction()> constructor to make one explicitly.  For example:

    Context("Fraction");
    $a = Compute("1/2");
    $b = Compute("4 - 1/6");
    $c = Compute("(4/9)^(1/2)");

    Context("LimitedFraction");
    $d = Compute("4 2/3");
    $e = Compute("-1 1/2");

    $f = Fraction(-2,5);

Note that C<$c> will be C<2/3>, $d will be C<14/3>, $e will be C<-3/2>, and C<$f>
will be C<-2/5>.

Once you have created a fraction object, you can use it as you would
any real number.  For example:

    Context("Fraction");
    $a = Compute("1/2");
    $b = Compute("1/3");
    $c = $a - $b;
    $d = asin($a);
    $e = $b**2;

Here C<$c> will be the equivalent of C<Compute("1/6")>, C<$d> will be
equivalent to C<Compute("pi/6")>, and C<$e> will be the same as C<Compute("1/9");>

You can produce an answer checker for a fraction in the same way as
you do for ALL C<MathObjects> -- via its C<cmp()> method:

    ANS(Compute("1/2")->cmp);

or

    $b = Compute("1/2");
    ANS($b->cmp);

There are several options to the C<cmp()> method that control how the
answer checker will work.  The first controls whether unreduced
fractions are accepted as correct.  Unreduced fractions are allowed in
the C<Fraction> and C<Fraction-NoDecimals> contexts, but not in the
C<LimitedFraction> and C<LimitedProperFraction> contexts.  You can
control this using the C<studentsMustReduceFractions> option:

    Context("Fraction");
    ANS(Compute("1/2")->cmp(studentsMustReduceFractions=>1));

or

    Context("LimitedFraction");
    ANS(Compute("1/2")->cmp(studentsMustReduceFractions=>0));

A second option controls whether warnings are issued when students don't
reduce their answers, or to mark the answer incorrect silently.  This
is specified by the C<showFractionReductionWarnings> option.  The default
is to report the warnings, but this option has an effect only when
C<studentsMustReduceFractions> is 1, and so only in the C<LimitedFraction>
context.  For example,

    Context("LimitedFraction");
    ANS(Compute("1/2")->cmp(showFractionReductionWarnings=>0));

turns off these warnings.

A final option, C<requireFraction>, specifies whether a fraction MUST
be entered (e.g. one would have to enter C<2/1> for a whole number).  The
default is 0.

In addition to these options for C<cmp()>, there are Context flags that
control how fractions are handled.  These include the following.

=over

=item S<C<< reduceFractions >>>

This determines whether fractions are reduced automatically when they
are created.  The default is to reduce fractions (except when
C<studentsMustReduceFractions> is set), so C<Compute("4/6")> would
produce the fraction C<2/3>.  To leave fractions unreduced, set C<S<<
reduceFractions => 0 >>>.  The C<LimitedFraction> and
C<LimiteProperFraction> contexts have C<studentsMustReduceFractions>
set, so C<reduceFractions> is unset automatically for students, but
not for correct answers, so C<Fraction(2,4)> would still produce
C<1/2>, even though C<2/4> would not be allowed in a student answer.

=item S<C<< strictFractions >>>

This determines whether division is allowed only between integers or
not.  If you want to prevent division from accepting non-integers,
then set C<S<< strictFractions => 1 >>>.  These are all three 0 by default in the
C<Fraction> and C<Fraction-NoDecimals> contexts, but 1 in C<LimitedFraction>.

=item S<C<< allowMixedNumbers >>>

This determines whether a space between a whole number and a fraction
is interpretted as implicit multiplication (as it usually would be in
WeBWorK), or as addition, allowing "4 1/2" to mean "4 and 1/2".  By
default, it acts as multiplication in the C<Fraction> and
C<Fraction-NoDecimals> contexts, and as addition in C<LimitedFraction>
and C<LimitedProperFraction>.  If you set C<S<< allowMixedNumbers => 1
>>> you should also set C<S<< reduceConstants => 0 >>>.  This
parameter used to be named C<allowProperFractions>, which is
deprecated, but you can still use it for backward-compatibility.

=item S<C<< showMixedNumbers >>>

This controls whether fractions are displayed as proper fractions or
not.  When set, C<5/2> will be displayed as C<2 1/2> in the answer
preview area, otherwise it will be displayed as C<5/2>.  This flag is
0 by default in the C<Fraction> and C<Fraction-NoDecimals> contexts,
and 1 in C<LimitedFraction> and C<LimitedProperFraction>.  This
parameter used to be named C<showProperFractions>, which is
deprecated, but you can still use it for backward-compatibility.

=item S<C<< requireProperFractions >>>

This determines whether fractions MUST be entered as proper fractions.
It is 0 by default, meaning improper fractions are allowed.  When set,
you will not be able to enter 5/2 as a fraction, but must use "2 1/2".
This flag is allowed only when C<strictFractions> is in effect.  Set it
to 1 only when you also set C<allowMixedNumbers>, or you will not be able
to specify fractions bigger than one.  It is off by default in all
four contexts.  You should not set both C<requireProperFractions> and
C<requirePureFractions> to 1.

=item S<C<< requirePureFractions >>>

This determines whether fractions MUST be entered as pure fractions
rather than mixed numbers.  If C<allowMixedNumbers> is also set, then
mixed numbers will be properly interpretted, but will produce a
warning message and be marked incorrect; that is, C<2 3/4> would be
recognized as C<2+3/4> rather than C<2*3/4>, but would generate a message
indicating that mixed numbers are not allowed.  This flag is off by
default in all four contexts.  You should not set both
C<requirePureFractions> and C<requireProperFractions> to 1.

=back

Fraction objects have two methods that can be useful when
C<reduceFractions> is set to 0.  The C<reduce()> method will reduce a
fraction to lowest terms, and the C<isReduced()> method returns true when
the fraction is reduced and false otherwise.

Fraction objects also have the C<num> and C<den> methods to return the
numerator and denominator. Note that these will be the unreduced numerator
and denominator when the C<reduceFractions> is set to 0.

If you wish to convert a fraction to its numeric (real number) form,
use the C<Real()> constructor to coerce it to a real.  E.g.,

    $a = Compute("1/2");
    $r = Real($a);

would set $r to the value 0.5.  Similarly, use C<Fraction()> to convert a
real number to (an approximating) fraction.  E.g.,

    $r = Real(.5);
    $a = Fraction($r);

would set C<$a> to be C<1/2>.  The fraction produced is good to about 6
decimal places, so it can't be used for numbers that are too small.

A side-effect of using the C<Fraction> context is that fractions can be
used to take powers of negative numbers when the reduced form of the
fraction has an odd denominator.  Thus C<(-8)^(1/3)> will produce -2 as a
result, while in the standard C<Numeric> context it would produce an
error.

=cut

loadMacros('contextExtensions.pl');

sub _contextFraction_init { context::Fraction::Init() }

#################################################################################################
#################################################################################################

package context::Fraction;
our @ISA = ('Parser::Context');

our $INTEGER  = Value::Type("Number", undef, undef, fracData => { class => "INTEGER" });
our $MINUS    = Value::Type("Number", undef, undef, fracData => { class => "MINUS" });
our $FRACTION = Value::Type("Number", undef, undef, fracData => { class => "FRACTION" });
our $MIXED    = Value::Type("Number", undef, undef, fracData => { class => "MIXED" });

#
#  Extend a given context (by name or actual Context object) to include fractions
#  The options are the default values for the Fraction context flags
#
sub extending {
	my ($from, %options) = @_;

	#
	#  Get a copy of the original context
	#
	my $context = context::Extensions::create("Fraction", $from);

	#
	#  Add fractions into the number pattern
	#
	$context->{pattern}{signedNumber} = '(?:' . $context->{pattern}{signedNumber} . '|-?\d+\s*/\s*-?\d+)';

	#
	#  Define fractions as being above Infinity
	#
	$context->{value}{Fraction}      = "context::Fraction::Value::Fraction";
	$context->{precedence}{Fraction} = $context->{precedence}{Infinity} + .5;

	#
	#  Set the mixedNum class to be the original multiplication
	#
	my $operators = $context->operators;
	my $mult      = $operators->get('*');
	$context->{'context::Fraction'}{mixedNum} = $mult->{class};

	#
	#  Extend the context with the needed classes and properties
	#
	return context::Extensions::extend(
		$context,
		opClasses => {
			'/'  => 'BOP::divide',
			'//' => 'BOP::divide',
			'/ ' => 'BOP::divide',
			' /' => 'BOP::divide',
			'u-' => 'UOP::minus',
			' '  => 'BOP::space',
		},
		ops => {
			'  ' => {
				%$mult,
				hidden     => 1,
				string     => ' ',
				TeX        => '\,',
				class      => 'context::Fraction::BOP::and',
				precedence => $mult->{precedence} - .1,
			},
			mixedNum => {
				%$mult,
				hidden => 1,
				class  => "context::Fraction::BOP::space",
			},
			' '  => { string     => 'mixedNum' },
			'/'  => { precedence => $operators->get('/')->{precedence} + .1 },
			'//' => { precedence => $operators->get('//')->{precedence} + .1 },
			'/ ' => { precedence => $operators->get('/ ')->{precedence} + .1 },
			' /' => { precedence => $operators->get(' /')->{precedence} + .1 },
		},
		value  => ['Real'],
		parser => [ 'Value', 'Number' ],
		flags  => {
			reduceFractions        => $options{reduceFractions} // 1,
			strictFractions        => $options{strictFractions}        || 0,
			allowMixedNumbers      => $options{allowMixedNumbers}      || 0,
			requireProperFractions => $options{requireProperFractions} || 0,
			requirePureFractions   => $options{requirePureFractions}   || 0,
			showMixedNumbers       => $options{showMixedNumbers}       || 0,
			contFracMaxDen         => $options{contFracMaxDen} // 10**8,
		},
		reductions => { 'a/b' => 1, 'a b/c' => 1, '0 a/b' => 1 },
		context    => "Context"
	);
}

#
#  Initialize the contexts and make the creator function.
#
sub Init {
	my $context = $main::context{Fraction} = context::Fraction::extending('Numeric');

	$context = $main::context{'Fraction-NoDecimals'} = $context->copy;
	$context->{name} = "Fraction-NoDecimals";
	Parser::Number::NoDecimals($context);
	$context->{error}{msg}{"You are not allowed to type decimal numbers in this problem"} =
		"You are only allowed to enter fractions, not decimal numbers";

	$context = $main::context{LimitedFraction} = context::Fraction::extending('LimitedNumeric');
	$context->{name} = "LimitedFraction";
	$context->flags->set(
		strictFractions   => 1,
		allowMixedNumbers => 1,
		reduceConstants   => 0,
		showMixedNumbers  => 1,
	);
	$context->{cmpDefaults}{Fraction} = { studentsMustReduceFractions => 1 };

	$context = $main::context{LimitedProperFraction} = $context->copy;
	$context->flags->set(requireProperFractions => 1);

	main::PG_restricted_eval('sub Fraction { Value->Package("Fraction()")->new(@_)} ;');
}

#
#  Backward compatibility
#
sub contFrac   { context::Fraction::Context->continuedFraction(@_) }
sub toFraction { context::Fraction::Context->toFraction(@_) }

#
#  Greatest Common Divisor
#
sub gcd {
	my ($a, $b) = (abs(shift), abs(shift));
	($a, $b) = ($b, $a) if $a < $b;
	return $a if $b == 0;
	my $r = $a % $b;
	while ($r != 0) {
		($a, $b) = ($b, $r);
		$r = $a % $b;
	}
	return $b;
}

#
#  Least Common Multiple
#
sub lcm {
	my ($a, $b) = @_;
	return ($a / gcd($a, $b)) * $b;
}

#
#  Reduced fraction
#
sub reduce {
	my ($a, $b) = @_;
	($a, $b) = (-$a, -$b) if $b < 0;
	my $gcd = gcd($a, $b);
	return ($a / $gcd, $b / $gcd);
}

#################################################################################################
#################################################################################################

package context::Fraction::Context;
our @ISA = ('Parser::Context');

sub class {'Context'}

#
# Takes a positive real input and outputs an array (a,b) where a/b
# is a very good fraction approximation with b no larger than
# maxdenominator.
#
sub continuedFraction {
	my ($self, $x) = @_;
	my $step = $x;
	my $n    = int($step);
	my ($h0, $h1, $k0, $k1) = (1, $n, 0, 1);
	my $maxdenominator = $_[2] || $self->flag('contFracMaxDen', 10**8);
	#
	# End when $step is an integer.
	#
	while ($step != $n) {
		$step = 1 / ($step - $n);
		#
		# Compute the next integer from the continued fraction sequence.
		#
		$n = int($step);
		#
		# Compute the next numerator and denominator according to the continued fraction formulas.
		#
		my ($newh, $newk) = ($n * $h1 + $h0, $n * $k1 + $k0);
		#
		# Machine rounding error may begin to make denominators skyrocket out of control
		#
		last if $newk > $maxdenominator;
		($h0, $h1, $k0, $k1) = ($h1, $newh, $k1, $newk);
	}
	return ($h1, $k1);
}

#
# Convert a real to a reduced fraction approximation.
#
# Uses $context->continuedFracation() to convert .333333... into 1/3
# rather than 333333/1000000, etc.
#
sub toFraction {
	my ($self, $x, $max) = @_;
	my ($a, $b);
	if ($x == 0) {
		($a, $b) = (0, 1);
	} else {
		my $sign = $x / abs($x);
		($a, $b) = $self->continuedFraction(abs($x), $max);
		$a = $sign * $a;
	}
	my $Real = $self->Package("Real");
	return [ $Real->make($a), $Real->make($b) ];
}

#################################################################################################
#################################################################################################

#
#  A common class for getting the super-class of an extension class
#
package context::Fraction::Super;
our @ISA = ('context::Extensions::Super');

sub extensionContext {'context::Fraction'}

#################################################################################################
#################################################################################################

#
#  A common class for handling the fraction class data in an object's typeRef
#
package context::Fraction::Class;
our @ISA = ('context::Fraction::Super', 'context::Extensions::Data');

sub extensionID {'fracData'}

sub extensionClassMatch { (shift)->extensionDataMatch(shift, "class", @_) }
sub setExtensionClass   { (shift)->setExtensionType(@_) }

#################################################################################################
#################################################################################################

package context::Fraction::BOP::divide;
our @ISA = ('context::Fraction::Class', 'Parser::BOP');

#
#  When strictFraction is in effect, only allow division
#  with integers and negative integers
#
sub _check {
	my $self = shift;
	my $lInt = $self->extensionClassMatch($self->{lop}, 'INTEGER', 'MINUS');
	my $rInt = $self->extensionClassMatch($self->{rop}, 'INTEGER', 'MINUS');
	if ($self->context->flag("strictFractions")) {
		$self->Error("The numerator of a fraction must be an integer") unless $lInt;
		my $rInt = $self->extensionClassMatch($self->{rop}, 'INTEGER');
		$self->Error("The denominator of a fraction must be a (non-negative) integer") unless $rInt;
		$self->Error("The numerator must be less than the denominator in a proper fraction")
			if $self->context->flag("requireProperFractions")
			&& CORE::abs($self->{lop}->eval) >= CORE::abs($self->{rop}->eval);
	}
	#
	#  This is not a fraction, so convert to original class and
	#  do its _check
	#
	return $self->mutate->_check unless $lInt && $rInt;
	$self->setExtensionClass('FRACTION');
}

#
#  Create a Fraction from the given data
#
sub _eval {
	my $self    = shift;
	my $context = $self->context;
	my $n       = $context->Package("Fraction")->make($context, @_);
	$n->{isHorizontal} = 1 if $self->{def}{noFrac};
	return $n;
}

#
#  Reduce the fraction
#
sub reduce {
	my $self   = shift;
	my $reduce = $self->{equation}{context}{reduction};
	return $self->{lop} if $self->{rop}{isOne} && $reduce->{'x/1'};
	$self->Error("Division by zero"), return $self if $self->{rop}{isZero};
	return $self->{lop} if $self->{lop}{isZero} && $reduce->{'0/x'};
	if ($reduce->{'a/b'}) {
		my ($a, $b) = context::Fraction::reduce($self->{lop}->eval, $self->{rop}->eval);
		if ($self->extensionClassMatch($self->{lop}, 'INTEGER')) {
			$self->{lop}{value} = $a;
		} else {
			$self->{lop}{op}{value} = -$a;
		}
		$self->{rop}{value} = $b;
	}
	return $self;
}

#
#  Display minus signs outside the fraction
#
sub TeX {
	my $self = shift;
	my $bop  = $self->{def};
	my ($precedence, $showparens, $position, $outerRight) = @_;
	$showparens = '' unless defined($showparens);
	my $addparens = defined($precedence)
		&& ($showparens eq 'all'
			|| ($precedence > $bop->{precedence}  && $showparens ne 'nofractions')
			|| ($precedence == $bop->{precedence} && ($bop->{associativity} eq 'right' || $showparens eq 'same')));
	my $TeX = $self->eval->TeX;
	$TeX = '\left(' . $TeX . '\right)' if $addparens;
	return $TeX;
}

#################################################################################################
#################################################################################################

package context::Fraction::BOP::space;
our @ISA = ('context::Fraction::Class', 'Parser::BOP');

#
#  If the implied multiplication represents a proper fraction with a
#  preceeding integer, then switch to the proper fraction operator
#  (for proper handling of string() and TeX() calls), otherwise,
#  convert the object to a standard multiplication.
#
sub _check {
	my $self              = shift;
	my $context           = $self->context;
	my $allowMixedNumbers = $context->flag("allowProperFractions") || $context->flag("allowMixedNumbers");
	#
	#  This is not a mixed number, so convert to original class and do
	#  its _check
	#
	unless ($allowMixedNumbers
		&& $self->extensionClassMatch($self->{lop}, 'INTEGER', 'MINUS')
		&& !$self->{lop}{hadParens}
		&& $self->extensionClassMatch($self->{rop}, 'FRACTION')
		&& !$self->{rop}{hadParens}
		&& $self->{rop}->eval >= 0)
	{
		$self->{bop} = $self->{def}{string};
		$self->{def} = $context->{operators}{ $self->{bop} };
		return $self->mutate->_check;
	}
	$self->{type} = $context::Fraction::MIXED;
	$self->Error("Mixed numbers are not allowed; you must use a pure fraction")
		if $context->flag("requirePureFractions");
	$self->{bop} = '  ';
	$self->{def} = $context->{operators}{ $self->{bop} };
	if ($self->extensionClassMatch($self->{lop}, 'MINUS')) {
		my $copy = bless {%$self}, $self->{def}{class};
		$copy->{lop} = $copy->{lop}{op};
		$self->mutate($self->Item("UOP")->new($self->{equation}, "u-", $copy));
	} else {
		bless $self, $self->{def}{class};
	}
}

#
#  For when the space operator's space property sends to an
#  operator we didn't otherwise subclass.
#
package context::Fraction::BOP::Space;
our @ISA = ('context::Fraction::BOP::space');

#################################################################################################
#################################################################################################

#
# Implements the space between mixed numbers
#
package context::Fraction::BOP::and;
our @ISA = ('Parser::BOP');

#
#  For proper fractions, add the integer to the fraction
#
sub _eval {
	my ($self, $a, $b) = @_;
	return ($a >= 0 ? $a + $b : $a - $b)->with(showMixedNumbers => 1);
}

#
#  Reduce the fraction
#
sub reduce {
	my $self   = shift;
	my $reduce = $self->{equation}{context}{reduction};
	my ($a, ($b, $c)) = (CORE::abs($self->{lop}->eval), $self->{rop}->eval->value);
	if ($reduce->{'a b/c'}) {
		($b, $c) = context::Fraction::reduce($b, $c) if $reduce->{'a/b'};
		$a += int($b / $c);
		$b                       = $b % $c;
		$self->{lop}{value}      = $a;
		$self->{rop}{lop}{value} = $b;
		$self->{rop}{rop}{value} = $c;
		return $self->{lop} if $b == 0 || $c == 1;
	}
	return $self->{rop} if $a == 0 && $reduce->{'0 a/b'};
	return $self;
}

#################################################################################################
#################################################################################################

package context::Fraction::UOP::minus;
our @ISA = ('context::Fraction::Class', 'Parser::UOP');

#
#  For strict fractions, only allow minus on certain operands
#
sub _check {
	my $self = shift;
	$self->{hadParens} = 1 if $self->{op}{hadParens};
	&{ $self->super('_check') }($self);
	$self->setExtensionClass('MINUS') if $self->{op}->class eq 'Number';
	$self->mutate;
}

#################################################################################################
#################################################################################################

package context::Fraction::Parser::Value;
our @ISA = ('context::Fraction::Class', 'Parser::Value');

sub check {
	my $self  = shift;
	my $value = &{ $self->super("check") }($self, @_);
	$self->mutate unless $self->{value}->classMatch('Fraction');
}

#
#  Handle reductions of negative fractions
#
sub reduce {
	my $self   = shift;
	my $reduce = $self->context->{reduction};
	$self->{value} = $self->{value}->reduce;
	return $self unless $reduce->{'-n'} && $self->{value}{data}[0] < 0;
	$self->{value}{data}[0] = -$self->{value}{data}[0];
	return Parser::UOP::Neg($self);
}

#
#  Add parentheses if they were there originally, or are needed by precedence
#
sub string {
	my $self       = shift;
	my $string     = &{ $self->super('string') }($self, @_);
	my $precedence = shift;
	my $frac       = $self->context->operators->get('/')->{precedence};
	$string = '(' . $string . ')' if $self->{hadParens} || (defined $precedence && $precedence > $frac);
	return $string;
}

#
#  Add parentheses if they were there originally, or
#  are needed by precedence and we asked for exxxtra parens
#
sub TeX {
	my $self   = shift;
	my $string = &{ $self->super('TeX') }($self, @_);
	my ($precedence, $noparens) = @_;
	my $frac = $self->context->operators->get('/')->{precedence};
	$string = '\left(' . $string . '\right)'
		if $self->{hadParens}
		|| (defined $precedence && $precedence > $frac && !$noparens);
	return $string;
}

#
#  Just return the fraction
#
sub makeMatrix { (shift)->{value} }

#################################################################################################
#################################################################################################

#
#  Distinguish integers from decimals
#
package context::Fraction::Parser::Number;
our @ISA = ('context::Fraction::Class', 'Parser::Number');

sub new {
	my $self = shift;
	my $num  = &{ $self->super('new') }($self, @_);
	$num->setExtensionClass('INTEGER') if $num->{value_string} =~ m/^[-+]?[0-9]+$/;
	return $num->mutate;
}

#################################################################################################
#################################################################################################

package context::Fraction::Value::Real;
our @ISA = ('context::Fraction::Super', 'Value::Real');

#
#  Allow Real to convert Fractions to Reals
#
sub new {
	my $self    = shift;
	my $context = (Value::isContext($_[0]) ? shift : $self->context);
	my $x       = shift;
	$x = $context->Package("Formula")->new($context, $x)->eval if !ref($x) && $x =~ m!/!;
	$x = $x->eval                                              if @_ == 0  && Value::classMatch($x, 'Fraction');
	return &{ $self->super("new") }($self, $context, $x, @_);
}

#
#  Since the signed number pattern now include fractions, we need to make sure
#  we handle them when a real is made and it looks like a fraction
#
sub make {
	my $self    = shift;
	my $context = (Value::isContext($_[0]) ? shift : $self->context);
	my $x       = shift;
	$x = $context->Package("Formula")->new($context, $x)->eval if !ref($x) && $x =~ m!/!;
	$x = $x->eval                                              if @_ == 0  && Value::classMatch($x, 'Fraction');
	return &{ $self->super("make") }($self, $context, $x, @_);
}

#
#  Since this is called directly, pass it up to the parent
#
sub cmp_defaults { (shift)->SUPER::cmp_defaults(@_) }

##################################################

package context::Fraction::Value::Real_Parens;
our @ISA = ('context::Fraction::Value::Real');

#################################################################################################
#################################################################################################
#
#  Implements the MathObject for fractions
#

package context::Fraction::Value::Fraction;
our @ISA = ('Value');

sub new {
	my $self    = shift;
	my $class   = ref($self) || $self;
	my $context = (Value::isContext($_[0]) ? shift : $self->context);
	my $x       = shift;
	$x = [ $x, @_ ] if @_ > 0;
	return $x->inContext($context) if Value::classMatch($x, 'Fraction');
	$x = [$x] unless ref($x) eq 'ARRAY';
	$x->[1] = 1 if @$x == 1;
	Value::Error("Can't convert ARRAY of length %d to %s", scalar(@$x), Value::showClass($self))
		unless @$x == 2;
	$x->[0] = Value::makeValue($x->[0], context => $context);
	$x->[1] = Value::makeValue($x->[1], context => $context);
	return $x->[0]                            if Value::classMatch($x->[0], 'Fraction') && @_ == 0;
	$x = $context->toFraction($x->[0]->value) if Value::isReal($x->[0]) && @_ == 0;
	return $self->formula($x)                 if Value::isFormula($x->[0]) || Value::isFormula($x->[1]);
	Value::Error("Fraction numerators must be integers")   unless isInteger($x->[0]);
	Value::Error("Fraction denominators must be integers") unless isInteger($x->[1]);
	my ($a, $b) = ($x->[0]->value, $x->[1]->value);
	($a, $b) = (-$a, -$b) if $b < 0;
	Value::Error("Denominator can't be zero") if $b == 0;
	($a, $b) = context::Fraction::reduce($a, $b) if $context->flag("reduceFractions");
	bless { data => [ $a, $b ], context => $context }, $class;
}

#
#  Produce a real if one of the terms is not an integer
#  otherwise produce a fraction.
#
sub make {
	my $self    = shift;
	my $class   = ref($self) || $self;
	my $context = (Value::isContext($_[0]) ? shift : $self->context);
	push(@_, 0) if @_ == 0;
	push(@_, 1) if @_ == 1;
	my ($a, $b) = @_;
	($a, $b) = (-$a, -$b) if $b < 0;
	return $context->Package("Real")->make($context, $a / $b) unless isInteger($a) && isInteger($b);
	($a, $b) = context::Fraction::reduce($a, $b) if $context->flag("reduceFractions");
	bless { data => [ $a, $b ], context => $context }, $class;
}

#
#  Promote to a fraction, allowing reals to be $x/1 even when
#  not an integer (later $self->make() will produce a Real in
#  that case)
#
sub promote {
	my $self    = shift;
	my $class   = ref($self) || $self;
	my $context = (Value::isContext($_[0]) ? shift : $self->context);
	my $x       = (@_                      ? shift : $self);
	if (@_ == 0) {
		return $x->inContext($context) if ref($x) eq $class;
		return (bless { data => [ $x->value, 1 ], context => $context }, $class) if Value::isReal($x);
		return (bless { data => [ $x, 1 ], context => $context }, $class) if Value::matchNumber($x);
	}
	return $x if Value::classMatch($x, "Infinity");
	return $self->new($context, $x, @_);
}

#
#  Create a new formula from the number
#
sub formula {
	my $self    = shift;
	my $value   = shift;
	my $formula = $self->Package("Formula")->blank($self->context);
	my ($l, $r) = Value::toFormula($formula, @$value);
	$formula->{tree} = $formula->Item("BOP")->new($formula, '/', $l, $r);
	return $formula;
}

#
#  Return the real number type
#
sub typeRef {$context::Fraction::FRACTION}
sub length  {2}

sub isZero { (shift)->{data}[0] == 0 }
sub isOne  { (shift)->eval == 1 }

#
#  Return the real value
#
sub eval {
	my $self = shift;
	my ($a, $b) = $self->value;
	return $a / $b;
}

#
#  Parts are not Value objects, so don't transfer
#
sub transferFlags { }

#
#  Check if a value is an integer
#
sub isInteger {
	my $n = shift;
	$n = $n->value if Value::isReal($n);
	return $n =~ m/^-?\d+$/;
}

#
#  Get a flag that has been renamed
#
sub getFlagWithAlias {
	my $self  = shift;
	my $flag  = shift;
	my $alias = shift;
	return $self->getFlag($alias, $self->getFlag($flag));
}

##################################################
#
#  Binary operations
#

sub add {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	my (($a, $b), ($c, $d)) = ($l->value, $r->value);
	my $M = context::Fraction::lcm($b, $d);
	return $self->inherit($other)->make($a * ($M / $b) + $c * ($M / $d), $M);
}

sub sub {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	my (($a, $b), ($c, $d)) = ($l->value, $r->value);
	my $M = context::Fraction::lcm($b, $d);
	return $self->inherit($other)->make($a * ($M / $b) - $c * ($M / $d), $M);
}

sub mult {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	my (($a, $b), ($c, $d)) = ($l->value, $r->value);
	return $self->inherit($other)->make($a * $c, $b * $d);
}

sub div {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	my (($a, $b), ($c, $d)) = ($l->value, $r->value);
	Value::Error("Division by zero") if $c == 0;
	return $self->inherit($other)->make($a * $d, $b * $c);
}

sub power {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	my (($a, $b), ($c, $d)) = ($l->value, $r->reduce->value);
	($a, $b, $c) = ($b, $a, -$c) if $c < 0;
	my ($x, $y) = ($c == 1 ? ($a, $b) : ($a**$c, $b**$c));
	if ($d != 1) {
		if ($x < 0 && $d % 2 == 1) {
			$x = -(-$x)**(1 / $d);
		} else {
			$x = $x**(1 / $d);
		}
		if ($y < 0 && $d % 2 == 1) {
			$y = -(-$y)**(1 / $d);
		} else {
			$y = $y**(1 / $d);
		}
	}
	return $self->inherit($other)->make($x, $y) unless $x eq 'nan' || $y eq 'nan';
	Value::Error("Can't raise a negative number to a non-integer power") if $a * $b < 0;
	Value::Error("Result of exponention is not a number");
}

sub compare {
	my ($self, $l, $r) = Value::checkOpOrderWithPromote(@_);
	return $l->eval <=> $r->eval;
}

##################################################
#
#   Numeric functions
#

sub abs  { my $self = shift; $self->make(CORE::abs($self->{data}[0]), CORE::abs($self->{data}[1])) }
sub neg  { my $self = shift; $self->make(-($self->{data}[0]),         $self->{data}[1]) }
sub exp  { my $self = shift; $self->make(CORE::exp($self->eval)) }
sub log  { my $self = shift; $self->make(CORE::log($self->eval)) }
sub sqrt { my $self = shift; $self->make(CORE::sqrt($self->{data}[0]), CORE::sqrt($self->{data}[1])) }

##################################################
#
#   Trig functions
#

sub sin { my $self = shift; $self->make(CORE::sin($self->eval)) }
sub cos { my $self = shift; $self->make(CORE::cos($self->eval)) }

sub atan2 {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	return $self->inherit($other)->make(CORE::atan2($l->eval, $r->eval));
}

##################################################
#
#  Differentiation
#

sub D {
	my $self = shift;
	return $self->make(0, 1);
}

##################################################
#
#  Utility
#

sub reduce {
	my $self = shift;
	my ($a, $b) = context::Fraction::reduce($self->value);
	return $self->make($a, $b);
}

sub isReduced {
	my $self = shift;
	my (($a, $b), ($c, $d)) = ($self->value, $self->reduce->value);
	return $a == $c && $b == $d;
}

sub num { (shift->value)[0] }
sub den { (shift->value)[1] }

##################################################
#
#  Formatting
#

sub string {
	my ($self, $equation, $skip1, $skip2, $prec) = @_;
	my ($a, $b) = @{ $self->{data} };
	my $n = "";
	return "$a" if $b == 1;
	if ($self->getFlagWithAlias("showMixedNumbers", "showProperFractions") && CORE::abs($a) > $b) {
		$n = int($a / $b);
		$a = CORE::abs($a) % $b;
		$n .= ' ' unless $a == 0;
	}
	$n .= "$a/$b" unless $a == 0 && $n ne '';
	return $n;
}

sub TeX {
	my ($self, $equation, $skip1, $skip2, $prec) = @_;
	my ($a, $b) = @{ $self->{data} };
	my $n     = "";
	my $style = '';
	return "$a" if $b == 1;
	if ($self->getFlagWithAlias("showMixedNumbers", "showProperFractions") && CORE::abs($a) > $b) {
		$n     = int($a / $b);
		$a     = CORE::abs($a) % $b;
		$style = '\\textstyle';
	}
	my $s = "";
	($a, $s) = (-$a, "-") if $a < 0;
	$n .= ($self->{isHorizontal} ? "$s$a/$b" : "${s}{$style\\frac{$a}{$b}}")
		unless $a == 0 && $n ne '';
	return $n;
}

sub pdot {
	my $self = shift;
	my $n    = $self->string;
	$n = '(' . $n . ')' if $n =~ m![^0-9]!;    #  add parens if not just a number
	return $n;
}

###########################################################################
#
#  Answer Checker
#

sub cmp_defaults { (
	shift->SUPER::cmp_defaults(@_),
	ignoreInfinity              => 1,
	studentsMustReduceFractions => 0,
	showFractionReduceWarnings  => 1,
	requireFraction             => 0,
) }

sub cmp_contextFlags {
	my ($self, $ans) = @_;
	return ($self->SUPER::cmp_contextFlags($ans), reduceFractions => !$ans->{studentsMustReduceFractions});
}

sub cmp_class {"a fraction of integers"}

sub typeMatch {
	my ($self, $other, $ans) = @_;
	return 1 unless ref($other);
	return 0 if Value::isFormula($other);
	return 1 if $other->type eq 'Infinity' && $ans->{ignoreInfinity};
	return 0 if $ans->{requireFraction}    && !$other->classMatch("Fraction");
	$self->type eq $other->type;
}

sub cmp_postprocess {
	my ($self, $ans) = @_;
	my $student = $ans->{student_value};
	return
		if $ans->{isPreview}
		|| !$ans->{studentsMustReduceFractions}
		|| !Value::classMatch($student, 'Fraction')
		|| $student->isReduced;
	$ans->score(0);
	$self->cmp_Error($ans, "Your fraction is not reduced") if $ans->{showFractionReduceWarnings};
}

#################################################################################################
#################################################################################################

1;
