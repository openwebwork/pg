
=head1 NAME

contextSignificantFigures.pl - Implements a context to handle numbers where significant figures is important.

=head1 DESCRIPTION

This file implements a MathObject SignificantFigures class that provides the ability to create
numbers for given significant figures as well as the operations +, -, *, /, **

To load this context, use

    loadMacros('contextSignificantFigures.pl');

and then set this context with

    Context('SignificantFigures');

or

    Context('LimitedSignificantFigures');  # TO BE DONE

where the latter context, you or the student are not allowed to perform any operations on
any numbers.

This is primarily for decimal numbers and keep track of signficant figures.   With the context loaded,
a call to C<Real> will parse the number or string to keep track of significant figures. For example,

    $x = Real('10.45');
    $y = Real('37.1834');

and these numbers will have 6 and 4 signficant figures respectively.  To query the number of significant
figures, use the C<sigfigs> method.  For example, C<< $x->sigfigs >> will return 4.

The standard arithmetic operations +, -, *, / are defined for these and the result will have the correct
number of significant figures. For example

    $x + $y;

returns the value C<20.63>, where the first number is rounded to the hundredths place before adding.

   $x * $y;

returns C<106.4> (with only 4 signficant figures, since one of them only has four).

Finally, we can also perform subtraction as in

   $x - $y;

however, subtraction can lose significant figures.  The answer to this is C<0.23>, so only 2 significant
figures.

=head2 Significant Figure Rules

A reminder about signficant figures is that all non-zero digits are significant.  The rule about a zero's
significance depends on where it is in a number.

=over

=item * Zeros between any significant digits are signficant.  The zeros in 12.0034 are significant. There are 6
significant figures in this number.

=item * Zeros to the left of a non-zero digit are not significant.  The zeros in 0.00123 are not signficant.
There are 3 significant figures in this number.

=item * Zeros to right of the decimal point and to the right a non-zero digit are significant.  The zeros in 12.3400 are
significant. There are 6 significant figures in this number.

=item * Zeros to the left of the decimal point and to the right of a non zero digit are not significant.  The
zeros in 12300 are not significant. There are 3 significant figures in this number.  However, the presesence of
a significant zero changes the rule.  The zeros in 12300.0  are all significant because the rightmost 0 is
significant and therefore the other zeros are significant.


=back

Note: If a number only consists of zeros has some different rules generally as a result of other operations.

=over

=item * The number 0 has infinite significant figures.

=item * The number 0. has 1 significant figure.

=item * The number 0.00 has 3 significant figures.

=back

=head3 Setting the number of significant figures.

The number of significant figures can be set in two ways.  The first, in creation of the number if the option
C<sigfigs> is used.  For example

    Real('100', sigfigs => 2)

will give the number C<1.0 * 10^2>.  Alternatively, if a number is already created, then the C<sigfigs>
method can set the number of significant figures.  If

    $x = Real('1000');

then C<$x> has 1 significant figure, but C<< $x->sigfigs(3) >> will update that to C<1.00 * 10^3>.

One can set a number with infinite significant figures with C<< sigfigs => 'inf' >>.   This is often done
with known constants.  A simple example would be that in the perimeter of a square with side C<x>, or C<4x>,
the 4 would have infinite significant figures, meaning that the result would have the same significant figures
as the number x.  Example:

    $x = Real(17.05);
    $p = Real(4, sigfigs => 'inf') * $x;

One can set the number of significant figures after a number has been created with the C<sigfigs> method.  For
example,

    $x = Real(12.3456);

which has 6 significant figures.  If C<< $x->sigfigs(4) >>, then the result is the number '12.35', where
rounding has been performed.

=head2 SigFigNumber

The function C<SigFigNumber> will also create a SigFigNumber with the second argument the number of
significant figures.  For example,

    $a = SigFigNumber(12.345);
    $b = SigFigNumber(10000,3);

will create a number with 5 and 3 significant figures respectively.

=cut

loadMacros('MathObjects.pl', 'PGauxiliaryFunctions.pl');

sub _contextSignificantFigures_init {
	context::SignificantFigures::Init(@_);

	sub SigFigNumber {
		my ($x, @opts) = @_;
		@opts = (sigfigs => $opts[0]) if @opts == 1;
		return Value->Package('Real')->new($x, @opts);
	}
}

#  A replacement for Value::Real that handles Significant figures
package context::SignificantFigures::Real;
our @ISA = ('Value::Real');

sub new {
	my $self    = shift;
	my $class   = ref($self) || $self;
	my $context = (Value::isContext($_[0]) ? shift : $self->context);
	my ($value, %opts) = @_;
	my $n = $opts{sigfigs};

	if (!Value::isValue($value) && !Value::matchNumber($value)) {
		$value = Value::makeValue($value, context => $context);
		return $value if Value::isFormula($value);
		Value::Error("Can't convert %s to %s", Value::showClass($value), Value::showClass($self))
			unless Value::isNumber($value);
	}
	return $value->eval if Value::isFormula($value);
	if (Value::isValue($value) && $value->{sigfigs}) {
		my $copy = $value->copy->inContext($context);
		$copy->sigfigs($n) if defined($n) && $n != $copy->N;
		return $copy;
	}

	if (!defined $n) {
		my $digits = $value;
		$digits =~ s/^[-+]//;        # Remove any leading sign.
		if ($value !~ m/[.Ee]/) {    # The number is an integer.
			$digits =~ s/0+$//;      # Remove trailing 0s.
		} else {
			$digits =~ s/[Ee].*$//;    # remove exponent, if any
			if ($value == 0) {
				$digits =~ s/^0*\.?/0/;    # remove leading 0s, leaving only one
			} else {
				$digits =~ s/\.//;         # remove non-digits
				$digits =~ s/^0+//;        # remove leading zeros
			}
		}
		$n = length($digits) || 'inf';     # what remains are the significant digits
	}
	my $N = $context->checkSigFigs($n);
	$self            = bless $self->SUPER::new($context, ROUND($value, $n)), $class;
	$value           = $self->format('E', $self->value, $N) unless $N eq 'inf';
	$self->{exp}     = $N eq 'inf' ? 0 : (split(/E/, $value))[1] + 0;
	$self->{sigfigs} = $N;
	$self->{pure}    = 1 unless $opts{computed} || $self->{value}{hadParens};

	return $self;
}

sub make { shift->new(@_) }

# Either return the current number of sigfigs for the number or set the current number.
sub sigfigs {
	my ($self, $n) = @_;
	return $self->{sigfigs} if !defined($n);
	my $sigfigs = $self->context->checkSigFigs($n);
	return $self->{sigfigs} if $self->{sigfigs} == $n;
	$self->{sigfigs} = $sigfigs;
	$self->{data}[0] = ROUND($self->value, $n);
	return $self->{sigfigs};
}

# Shortcut for returning the number of significant figures.
sub N { shift->{sigfigs} }

# Return the exponent.
sub E { shift->{exp} }

# Return the exponential for the given $value with max($n,14-$n) sigfigs.
# This basically is log10 except handles 0 and negative numbers.
sub expFor {
	my ($self, $value, $n) = @_;
	$n = main::max(0, $n - 1, 14 - $n);
	return (split(/E/, sprintf("%.${n}E", $value)))[1] + 0;
}

#  Stringify and TeXify the number in the context's base

sub string {
	my ($self, $equation, $precedence) = @_;
	my $string = $self->format($self->{expForm} || $self->getFlag('alwaysExponentialForm') ? 'E' : 'f');
	$string        =~ s/E(?:(-)|\+)0*(\d+)/x10^$1$2/;
	$string        =~ s/\^-(.*)/^(-$1)/;
	return $string =~ m/x/ && $precedence ? "($string)" : $string;
}

sub TeX {
	my ($self, $equation, $precedence) = @_;
	my $tex = $self->format($self->{expForm} || $self->getFlag('alwaysExponentialForm') ? 'E' : 'f');
	$tex =~ s/E(?:(-)|\+)0*(\d+)/\\times 10^{$1$2}/;
	return $tex =~ m/\\times/ && $precedence ? "\\left($tex\\right)" : "{$tex}";
}

# Format the number in $value in either 'E' (exponential form) or 'f' decimal form using
# $n signficant figures.

# Example: format('E', '123.456', 6) returns 1.23456E+02
# format('f', 1.23E-01, 3) returns '0.123'.

sub format {
	my ($self, $f, $value, $n) = @_;
	$value = $self->value unless defined $value;
	$n     = $self->N     unless defined $n;
	return "$value" if $n == 'inf';
	$value = ROUND($value, 0) if $n == 0;
	my $exp = $self->E // $self->expFor($value, 0);
	$f = 'E' if $f eq 'f' && ($n - $exp < 1 || $exp >= 5 || -5 >= $exp);
	$n -= $exp if $f eq 'f';
	$n     = main::max(0, $n - 1);
	$value = sprintf("%.${n}${f}", $value);
	$value .= '.' if $n == 0 && $f eq 'f' && $value =~ m/0$/;
	return $value;
}

# Redefine addition.  The leftmost signifcant place in the result is needed to get the
# correct value.

sub add {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	my $exp   = main::min($l->N - $l->E, $r->N - $r->E);
	my $value = $l->round($exp) + $r->round($exp);
	return $self->new($value, sigfigs => main::max(0, $exp + $self->expFor($value, $exp)), computed => 1);
}

# Redefine subtraction.  The leftmost signifcant place in the result is needed to get the
# correct value.

sub sub {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	my $exp   = main::min($l->N - $l->E, $r->N - $r->E);
	my $value = $l->round($exp) - $r->round($exp);
	return $self->new($value, sigfigs => main::max(0, $exp + $self->expFor($value, $exp)), computed => 1);
}

# Redefine multiplication.  Use the product of the two numbers and set the number of significant
# figures to the minimum of the two numbers.

sub mult {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	return $self->new($l->value * $r->value, sigfigs => main::min($l->{sigfigs}, $r->{sigfigs}), computed => 1);
}

# Redefine multiplication.  Use the quotient of the two numbers and set the number of significant
# figures to the minimum of the two numbers.

sub div {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	return $self->new($l->value / $r->value, sigfigs => main::min($l->{sigfigs}, $r->{sigfigs}), computed => 1);
}

# Redefine powers.  Record whether this is an integer power of 10 for use with exponetial form.

sub power {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	my ($L, $R) = ($l->value, $r->value);
	$self->Error("Can't raise a negative number to a non-integer power") if $L < 0  && CORE::int($R) != $R;
	$self->Error("Zero to the zero power is undefined")                  if $L == 0 && $R == 0;
	return $l->copy                                                      if $L == 0;
	my $intPower = CORE::int($R) == $R;
	my $n        = $intPower ? $l->{sigfigs} : main::min($l->{sigfigs}, $r->{sigfigs});
	my $result   = $self->make($L**$R, sigfigs => $n, computed => 1);
	$result->{tenPower} = 1 if $intPower && $L == 10 && $l->{pure} && $r->{pure};
	return $result;
}

# Redefine abs to return the absolute value of the number with the same number of sigfigs.

sub abs {
	my $self = shift;
	return $self->make(CORE::abs($self->value), sigfigs => $self->{sigfigs}, computed => 1);
}

# Redefined neg to handle the parsing of negative numbers with sigfigs.

sub neg {
	my $self = shift;
	return $self->new(-$self->value, sigfigs => $self->{sigfigs});
}

# This promotes non-Sig fig numbers that are used in expressions to a sig fig
# with infinite precision.

sub promote {
	my $self    = shift;
	my $context = (Value::isContext($_[0]) ? shift : $self->context);
	my $value   = (scalar(@_)              ? shift : $self);
	return $value->inContext($context) if Value::isValue($value) && $value->{sigfigs};
	return $self->new($context, $value, sigfigs => 'inf');
}

# The compare method determines that the values are equal with the same number of significant figures.
# This also handles inequalities as in other Reals.

sub compare {
	my ($self, $l, $r) = Value::checkOpOrderWithPromote(@_);
	return $l->value <=> $r->value if $l->N == $r->N || $l->value != $r->value;
	return $l->N     <=> $r->N;
}

sub round {
	my ($self, $exp) = @_;
	return ROUND($self->value, $self->E + $exp);
}

# Rounds the number $x to $n significant digits.

sub ROUND {
	my ($x, $n) = @_;
	return $x + 0 if $n == 'inf';                        # keep the same if infinite digits
	return 0      if $n < 0 || $x == 0;                  # 0 if less than 0 digits wanted or there are no digits
	my $N = main::max(0, $n - 1);                        # Number of decimals to use in E notation
	my $r = sprintf("%.${N}E", $x);                      # preliminary rounding of $x
	my $e = (split(/E/, $r))[1] + 0;                     # exponent for $r
	my $s = ($x < 0 ? -1 : 1);                           # sign of $x
	my $m = main::max($n, 14 - $n);                      # position to use for adjustment for repeated 9s
	$x += $s * 10**($e - $m);                            # adjust for repeated 9s
	return sprintf("%.${N}E", $x) + 0 unless $n == 0;    # if we want digits, re-round the adjusted value

	# For zero digits, we add a digit just above the first one in $x,
	# round that, then remove the added digit, getting 0 if $x didn't
	# round up, or 1 in the proper place if it did.  This means that
	# 0.005 rounds to .01, for example, if we ask for no digits,
	# so something like 1.23 - .005 will yield 1.22 properly.

	my $d = $s * 10**($e + 1);
	return sprintf("%.0E", $x + $d) - $d;
}

package context::SignificantFigures;

sub Init {
	my $context = $main::context{SignificantFigures} = context::SignificantFigures::Context->new();
	$context         = $main::context{LimitedSignificantFigures} = $context->copy;
	$context->{name} = 'LimitedSignificantFigures';
	$context->parens->undefine('|', '{', '[');
	$context->variables->remove('x');
	$context->operators->undefine('-', '+', '/', '//', ' /', '/ ', '!', '_', '.', 'U', '><');
	$context->flags->set(limitedSigFigs => 1);
}

package context::SignificantFigures::Context;
our @ISA = ('Parser::Context');

sub new {
	my $self    = shift;
	my $class   = ref($self) || $self;
	my $context = bless Parser::Context->getCopy('Numeric'), $class;
	$context->{name}             = 'SignificantFigures';
	$context->{parser}{Number}   = 'context::SignificantFigures::Number';
	$context->{parser}{Value}    = 'context::SignificantFigures::Value';
	$context->{parser}{Variable} = 'context::SignificantFigures::Variable';
	$context->{value}{Real}      = 'context::SignificantFigures::Real';
	$context->functions->disable('All');
	$context->constants->clear();
	$context->{precedence}{SignificantFigures} = $context->{precedence}{special};
	$context->flags->set(alwaysExponentialForm => 0);    # controls whether all reals are given in exponential form
	$context->operators->set(
		'*'  => { class => 'context::SignificantFigures::BOP::multiply' },
		'* ' => { class => 'context::SignificantFigures::BOP::multiply' },
		' *' => { class => 'context::SignificantFigures::BOP::multiply' },
		'^'  => { class => 'context::SignificantFigures::BOP::power' },
		'**' => { class => 'context::SignificantFigures::BOP::power' },
		' '  => { class => 'context::SignificantFigures::BOP::space', space => '  ', string => '  ' },
		'  ' =>
			{ %{ $context->operators->get('*') }, class => 'context::SignificantFigures::BOP::space', hidden => 1 },
		'u-' => { class => 'context::SignificantFigures::UOP::minus' },
		'u+' => { class => 'context::SignificantFigures::UOP::plus' },
	);
	#
	# Arrange for variables to be higher priority than operators so variable 'x' is used rather
	# than operator 'x', unless the variable is removed.
	#
	my $variables = '_' . $context->variables->{dataName};
	$context->{data}{objects} = [ (grep { $_ ne $variables } @{ $context->{data}{objects} }), $variables ];
	#
	# Add the 'x' operator as a fallback when 'x' is not a variable.
	#
	$context->operators->set(
		'x' => {
			%{ $context->operators->get('*') },
			class  => 'context::SignificantFigures::BOP::multiply',
			string => 'x',
			TeX    => '\\times'
		},
	);
	return $context;
}

sub checkSigFigs {
	my ($self, $n) = @_;
	return $n if $n eq 'inf';
	Value::Error('The number of significant figures must be an integer or "inf"') unless $n =~ m/^[+-]?\d+$/;
	Value::Error('The number of significant figures must be non-negative') if $n < 0;
	Value::Error('The number of significant figures must be less than 16') if $n > 15;
	return main::max(1, $n);
}

# Some common function for the Parser object overrides

package context::SignificantFigures::common;

# True when this is a pure real, not a computed one

sub isPure {
	my ($self, $value) = @_;
	return $value->{pure} && !$value->{hadParens};
}

# Check for limited use of UOPs

sub checkLimitedUOP {
	my $self = shift;
	Value::Error("You can only use '%s' on an unsigned constant", shift)
		if $self->context->flag('limitedSigFigs') && !$self->{pure};
}

# Check whether multiplication is for exponential form

sub checkExponentialForm {
	my $self = shift;
	my ($l, $r) = ($self->{lop}, $self->{rop});
	if ($r->{tenPower} && !$r->{hadParens} && $self->isPure($l)) {
		$r                   = $r->{lop} if $r->class eq 'BOP';
		$r->{value}{sigfigs} = 'inf';
		$self->{expForm}     = 1;
		$self->{def}         = { %{ $self->{def} }, string => 'x', TeX => '\times' };
	} else {
		Value::Error("The '%s' operator can ony appear between a simple constant and an integer power of ten",
			$self->{bop})
			if $self->context->flag('limitedSigFigs') || $self->{bop} eq 'x';
	}
}

# Copy the special properites used for exponential notation processing

sub COPY {
	my ($self, $from, $to) = @_;
	for my $name ('pure', 'hadParens', 'hadPlus', 'tenPower', 'expForm') {
		delete $to->{name} if $to->{$name};
		$to->{$name} = 1   if $from->{$name};
	}
	delete $to->{pure} if $to->{hadParens};
	return $to;
}

# Properly handle constants in exponential form, and add parenthese if needed

sub STRING {
	my ($self, $fn, $precedence) = @_;
	my $flags  = Value::contextSet($self->context, alwaysExponentialForm => 0);
	my $string = $self->{expForm} && $precedence ? $self->addParens(&$fn) : &$fn;
	Value::contextSet($self->context, %$flags);
	return $string;
}

# Properly handle constants in exponential form, and add parenthese if needed

sub TEX {
	my ($self, $fn, $precedence) = @_;
	my $flags = Value::contextSet($self->context, alwaysExponentialForm => 0);
	my $tex   = $self->{expForm} && $precedence ? '\left(' . &$fn . '\right)' : &$fn;
	Value::contextSet($self->context, %$flags);
	return $tex;
}

# Override Parser::Number to handle SignificantFigures Reals and copy the properties
# needed for processing exponential form.

package context::SignificantFigures::Number;
our @ISA = ('Parser::Number', 'context::SignificantFigures::common');

sub new {
	my $self  = shift;
	my $class = ref($self) || $self;
	my ($equation, $x, $ref) = @_;
	my $context = $equation->{context};

	$self = bless $self->SUPER::new($equation, $x, $ref), $class;
	$self->{value} = Value::isValue($x)
		&& $x->{sigfigs} ? $x->copy->inContext($context) : $self->Package('Real')->new($context, $self->{value_string});
	return $self->COPY($self->{value}, $self);
}

sub class {'Number'}

sub value { shift->{value}->value }

sub eval {
	my $self = shift;
	return $self->COPY($self, $self->SUPER::eval(@_));
}

sub perl {
	my $self  = shift;
	my $value = $self->{value};
	return $self->SUPER::perl unless $value->{sigfigs};
	return $self->context->Package('Real') . '->new(' . $value->value . ', sigfigs => {' . $value->N . '})';
}

# Override the Parser::Value class to avoid using CORE::abs that would otherwise
# mark the result as computed when it may be pure

package context::SignificantFigures::Value;
our @ISA = ('Parser::Value');

sub new {
	my $self     = shift;
	my $class    = ref($self) || $self;
	my $equation = shift;
	my $context  = $equation->{context};
	my ($value, $ref) = @_;
	$value = $value->[0] if ref($value) eq 'ARRAY' && scalar(@{$value}) == 1;
	return $self->SUPER::new($equation, @_) unless Value::isValue($value) && $value->{sigfigs};
	return $self->Item("Number")->new($equation, $value);
}

# Override the Parser::Variable class to count the number of times a variable is used
# (so we can remove it from the equation's variables if 'x' is used for exponential form)

package context::SignificantFigures::Variable;
our @ISA = ('Parser::Variable');

sub new {
	my $self = shift;
	my $v    = $self->SUPER::new(@_);
	my ($equation, $name) = ($v->{equation}, $v->{name});
	$equation->{vCount}{$name} = 0 unless defined $equation->{vCount}{$name};
	$equation->{vCount}{$name}++;
	return $v;
}

sub class {'Variable'}

# Override Parser::UOP::minus to allow negation of a constant, but mark
# any other usage as computed rather than pure

package context::SignificantFigures::UOP::minus;
our @ISA = ('Parser::UOP::minus', 'context::SignificantFigures::common');

sub _check {
	my $self = shift;
	$self->SUPER::_check(@_);
	my $op = $self->{op};
	$self->{pure} = 1 if $op->class eq 'Number' && $self->isPure($op) && !$op->{hadPlus};
	$self->checkLimitedUOP('-');
}

sub _eval {
	my $self = shift;
	return $self->COPY($self, $self->SUPER::_eval(@_));
}

# Override the Parser::UOP::plus to allow it to be used on a constant, but
# mark any other usage as computed rather than pure

package context::SignificantFigures::UOP::plus;
our @ISA = ('Parser::UOP::plus', 'context::SignificantFigures::common');

sub _check {
	my $self = shift;
	$self->SUPER::_check(@_);
	my $op = $self->{op};
	$self->{pure}    = 1 if $op->class eq 'Number' && $self->isPure($op) && !$op->{hadPlus};
	$self->{hadPlus} = 1;
	$self->checkLimitedUOP('+');
}

sub _eval {
	my $self = shift;
	return $self->COPY($self, $self->SUPER::_eval(@_)->with(hadPlus => 1));
}

# Override Parser::BOP::mulitoply to handle the formation of an exponential form

package context::SignificantFigures::BOP::multiply;
our @ISA = ('Parser::BOP::multiply', 'context::SignificantFigures::common');

sub _check {
	my $self = shift;
	$self->SUPER::_check(@_);
	$self->checkExponentialForm;
}

sub _eval {
	my $self = shift;
	return $self->COPY($self, $self->SUPER::_eval(@_));
}

sub string {
	my $self = shift;
	return $self->STRING(sub { $self->SUPER::string }, @_);
}

sub TeX {
	my $self = shift;
	return $self->TEX(sub { $self->SUPER::TeX }, @_);
}

# Override implicit multiplication to form exponential form when we have
# a number (implicitly) times the 'x' (implicitly) times a power of 10.

package context::SignificantFigures::BOP::space;
our @ISA = ('Parser::BOP::multiply', 'context::SignificantFigures::common');

sub _check {
	my $self = shift;
	$self->SUPER::_check(@_);
	Value::Error("Can't use implied multiplication in this context") if $self->context->flag('limitedSigFigs');
	my ($l, $r) = ($self->{lop}, $self->{rop});
	return unless $r->{tenPower} && !$r->{hadParens} && $l->class eq 'BOP' && $l->{bop} eq '  ';
	my ($L, $R) = ($l->{lop}, $l->{rop});
	if ($R->class eq 'Variable' && $R->{name} eq 'x' && $self->isPure($L)) {
		#
		# Mark the 10 as infinite precision and remove the 'x' and its multiplication,
		# leaving only the number and the power of ten being multiplied.
		#
		$r                   = $r->{lop} if $r->class eq 'BOP';
		$r->{value}{sigfigs} = 'inf';
		$self->{lop}         = $l->{lop};
		$self->{isConstant}  = 1;
		$self->{expForm}     = 1;
		#
		# Set the string and TeX values for exponential form.
		#
		$self->{def} = { %{ $self->{def} }, string => 'x', TeX => '\times' };
		#
		# Remove the variable from the expression if this was the only occurrance of 'x'.
		#
		my $equation = $self->{equation};
		$equation->{vCount}{x}--;
		delete $equation->{variables}{x} if $equation->{vCount}{x} == 0;
	}
}

sub eval {
	my $self = shift;
	return $self->COPY($self, $self->SUPER::eval(@_));
}

sub string {
	my $self = shift;
	return $self->STRING(sub { $self->SUPER::string }, @_);
}

sub TeX {
	my $self = shift;
	return $self->TEX(sub { $self->SUPER::TeX }, @_);
}

# Override Parser::BOP::power to mark occurances of ten-to-a-power so we can
# recognize them when checking for exponential form

package context::SignificantFigures::BOP::power;
our @ISA = ('Parser::BOP::power', 'context::SignificantFigures::common');

sub _check {
	my $self = shift;
	$self->SUPER::_check(@_);
	my ($l, $r) = ($self->{lop}, $self->{rop});
	delete $r->{hadParens} if $self->isPureParen($r);
	if ($l->class eq 'Number' && $self->isPure($r)) {
		my ($L, $R) = ($l->value, $r->eval->value);
		$self->{tenPower} = 1 if $L == 10 && $self->isPure($l) && CORE::int($R) == $R;
	}
	$self->checkLimited();
}

sub isPureParen {
	my ($self, $r) = @_;
	return $r->{hadParens} && $r->{pure} && $r->class eq 'UOP';
}

sub checkLimited {
	my $self = shift;
	return                                                            unless $self->context->flag('limitedSigFigs');
	Value::Error("Exponents can only be used with a base of 10 here") unless $self->{lop}->value == 10;
	Value::Error("Exponents can only be integers")                    unless $self->{tenPower};
}

1;
