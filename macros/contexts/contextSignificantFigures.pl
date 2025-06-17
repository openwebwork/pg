
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

	if (Value::isValue($value) && $value->{sigfigs}) {
		my $copy = $value->copy->inContext($context);
		$copy->sigfigs($n) if defined($n) && $n != $copy->N;
		return $copy;
	}
	if (!Value::matchNumber($value)) {
		$value = Value::makeValue($value, context => $context);
		return $value if Value::isFormula($value);
		Value::Error("Can't convert %s to %s", Value::showClass($value), Value::showClass($self));
	}
	return $value->eval if Value::isFormula($value);

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
sub string { shift->format('f') }

sub TeX {
	my $tex = shift->string;
	$tex =~ s/E(?:(-)|\+)0*([1-9]\d?)/\\times 10^{$1$2}/;
	return "{$tex}";
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
	$f = 'E' if $f eq 'f' && ($n < 1 || $exp >= 5 || -5 >= $exp);
	$n -= $exp if $f eq 'f';
	$n = main::max(0, $n - 1);
	return sprintf("%.${n}${f}" . ($n == 0 && $f eq 'f' ? '.' : ''), $value);
}

# Redefine addition.  The leftmost signifcant place in the result is needed to get the
# correct value.

sub add {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	my $exp   = main::min($l->N - $l->E, $r->N - $r->E);
	my $value = $l->round($exp) + $r->round($exp);
	return $self->new($value, sigfigs => main::max(0, $exp + $self->expFor($value, $exp)));
}

# Redefine subtraction.  The leftmost signifcant place in the result is needed to get the
# correct value.

sub sub {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	my $exp   = main::min($l->N - $l->E, $r->N - $r->E);
	my $value = $l->round($exp) - $r->round($exp);
	return $self->new($value, sigfigs => main::max(0, $exp + $self->expFor($value, $exp)));
}

# Redefine multiplication.  Use the product of the two numbers and set the number of significant
# figures to the minimum of the two numbers.

sub mult {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	return $self->new($l->value * $r->value, sigfigs => main::min($l->{sigfigs}, $r->{sigfigs}));
}

# Redefine multiplication.  Use the quotient of the two numbers and set the number of significant
# figures to the minimum of the two numbers.

sub div {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	return $self->new($l->value / $r->value, sigfigs => main::min($l->{sigfigs}, $r->{sigfigs}));
}

# Redefine abs to return the absolute value of the number with the same number of sigfigs.

sub abs {
	my $self = shift;
	return $self->make(CORE::abs($self->value), sigfigs => $self->{sigfigs});
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
}

package context::SignificantFigures::Context;
our @ISA = ('Parser::Context');

sub new {
	my $self    = shift;
	my $class   = ref($self) || $self;
	my $context = bless Parser::Context->getCopy('Numeric'), $class;
	$context->{name}           = 'SignificantFigures';
	$context->{parser}{Number} = 'context::SignificantFigures::Number';
	$context->{value}{Real}    = 'context::SignificantFigures::Real';
	$context->functions->disable('All');
	$context->constants->clear();
	$context->{precedence}{SignifcantFigures} = $context->{precedence}{special};
	$context->flags->set(limits => [ -1000, 1000, 1 ]);

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

package context::SignificantFigures::Number;
our @ISA = ('Parser::Number');

sub new {
	my $self  = shift;
	my $class = ref($self) || $self;
	my ($equation, $x, $ref) = @_;
	my $context = $equation->{context};

	$self = bless $self->SUPER::new($equation, $x, $ref), $class;
	$self->{value} = Value::isValue($x)
		&& $x->{sigfigs} ? $x->copy->inContext($context) : $self->Package('Real')->new($context, $self->{value_string});
	return $self;
}

sub perl {
	my $self  = shift;
	my $value = $self->{value};
	return $self->SUPER::perl unless $value->{sigfigs};
	return $self->context->Package('Real') . '->new(' . $value->value . ',' . $value->N . ')';
}

1;
