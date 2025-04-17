
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

where the latter context, you or the student is not allowed to perform any operations on
any numbers.

=head2 Usage

This is primarily for decimal numbers and keep track of signficant figures.   With the context loaded,
a call to C<Real> will parse the number or string to keep track of significant figures. For example,

    $x = Real('10.45');;
    $y = Real('10.1834');

and these numbers will have 6 and 4 signficant figures respectively.  To query the number of significant
figures, use the C<sigfigs> methods.  For example, C<$x->sigfigs> will return 6.

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

=head3 Setting the number of significant figures.

The number of significant figures can be set in two ways.  The first, in creation of the number if the option
C<sigfigs> is used.  For example

    Real('100', sigfigs => 2)

will give the number C<1.0 * 10^2>.  Alternatively, if a number is already created, then the C<sigfigs>
method can set the number of significant figures.  If

    $x = Real('1000');

then C<$x> has 1 significant figure, but C<$x->sigfigs(3)> will update that to C<1.00 * 10^3>.


=cut

loadMacros('MathObjects.pl', 'PGauxiliaryFunctions.pl');

sub _contextSignificantFigures_init {
	context::SignificantFigures::Init(@_);
	sub SigFigNumber { return context::SignificantFigures::Real->new(@_); }
}

#  A replacement for Value::Real that handles Significant figures
package context::SignificantFigures::Real;
our @ISA = ('Value::Real');

sub new {
	my $self    = shift;
	my $class   = ref($self) || $self;
	my $context = (Value::isContext($_[0]) ? shift : $self->context);
	my ($value, %opts) = @_;

	# If a SignificantFigure::Number is passed in, make a copy.
	if (Value::isValue($value) && $value->{sigfigs}) {
		my $copy = $value->copy->inContext($context);
		$copy->sigfigs($n) if defined($n) && $n != $copy->N;
		return $copy;
	}
	# This handles formulas.
	if (!Value::matchNumber($value)) {
		$value = Value::makeValue($value, context => $context);
		return $value if Value::isFormula($value);
		Value::Error("Can't convert %s to %s", Value::showClass($value), Value::showClass($self));
	}
	return $value->eval if Value::isFormula($value);
	my $n = $opts{sigfigs};

	if (!defined $n) {
		my $digits = $value;
		if ($value == 0) {    # 0 is has infinite sig figs
			$n = 'inf';
		} elsif ($value !~ m/\./) {    # it is an integer
			$digits =~ s/^[+-]?0*//;    # remove signs and leading zeros;
			$digits =~ s/0+$//;         # remove trailing zeros;
		} else {
			$digits =~ s/[Ee].*$//;     # remove exponent, if any
			if ($value == 0) {
				$digits =~ s/^[+-]?0+(.(?:\.|$))/$1/;    # remove leading 0s before the decimal
				$digits =~ s/[-+.]//g;                   # remove non-digits
			} else {
				$digits =~ s/[-+.]//g;                   # remove non-digits
				$digits =~ s/^0+//;                      # remove leading zeros
			}
		}
		$n = length($digits) unless defined($n) && $n =~ /^inf$/;    # what remains are the significant digits
	}

	$context->checkSigFigs($n);
	$value = $class->format('E', $value, $n) unless $n =~ /^inf$/;
	$self  = bless $self->SUPER::new($context, $value + 0), $class;
	$self->sigfigs($n);
	$self->{data} = [$value];
	$self->{exp}  = $n == 'inf' ? 0 : (split(/E/, $value))[1] + 0;

	return $self;
}

sub make { shift->new(@_) }

# Either return the current number of sigfigs for the number or set the current number.

sub sigfigs {
	my ($self, $num_sigfigs) = @_;
	return $self->{sigfigs} unless defined($num_sigfigs);
	Value::Error('The number of significant figures must be inf or an integer >=-1')
		unless $num_sigfigs =~ m/^inf$/ || ($num_sigfigs =~ /-?\d+/ && $num_sigfigs >= 1);
	my ($v, $exp);
	if ($num_sigfigs =~ m/^inf$/) {
		$v   = $self->value;
		$exp = 0;
	} else {
		($v, $exp) = split(/E/, $self->value);
		$exp = 0 unless defined($exp);    # if $self->value is not in exponential form.
	}

	# Calculate the digit to round to.
	if ($num_sigfigs !~ /^inf$/) {
		my $N = $num_sigfigs - 1;
		$self->{data} = [ sprintf("%.${N}E", $v * 10**$exp) ];
	} else {
		$self->{data} = [$v];
	}

	$self->{sigfigs} = $num_sigfigs;
	return $self->{sigfigs};
}

# return the exponent since stored in the form d * 10^(p), where d is an integer.
sub exp { return shift->{exp}; }

# return the mantissa of the number (without sign in [1,10) )
sub mantissa { return (split(/E/, shift->value))[0] + 0; }

#  Stringify and TeXify the number in the context's base
sub string {
	my $self = shift;
	return "" . $self->value if $self->sigfigs =~ /inf/;
	my $N = -$self->{exp} + $self->sigfigs - 1;     # digit to round to.
	my $v = $self->mantissa * 10**($self->{exp});
	return abs($self->{exp}) > 5 ? $self->value : ($N > 0 ? sprintf("%.${N}f", $v) : "$v");
}

sub TeX {
	my $self = shift;
	my $tex  = $self->string;
	$tex =~ s/E(?:(-)|\+)0*([1-9]\d?)/\\times 10^{$1$2}/;
	return "{$tex}";
}

sub format {
	my ($self, $char, $value, $n) = @_;
	my $m = $n - 1;
	return sprintf("%.${m}E", $value + 0);
}

# Redefine adding two numbers.  This calculates the last significant digit and then converts each number
# to an integer with the ones being signficant.  Then add and round, finally converting to decimal using the
# last significant digit as the exponent.

# If the first addend is negative, write it as a subtraction.

sub add {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	return $r - abs($l) if $l->value < 0;
	my $value = $l->value + $r->value;
	my $exp   = int(log($value) / log(10));
	my $n     = main::min($l->{sigfigs} - $l->{exp}, $r->{sigfigs} - $r->{exp}) + $exp;
	return $n <= 0 ? $self->new(0) : $self->new($value, sigfigs => $n);
}

# For subtraction of two positive numbers, find the place of the least significant digit.
# Also, convert each number to the same exponent so the mantissa's in (0,10) before rounding to the
# correct place.

sub sub {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	my $lman = $l->mantissa;
	my $rman = $r->mantissa;
	my $exp  = 0;

	if ($l->exp > $r->exp) {
		$exp = $l->exp;
		$rman *= 10**($r->exp - $l->exp);
	} else {
		$exp = $r->exp;
		$lman *= 10**($l->exp - $r->exp);
	}

	my $place = main::min($l->{sigfigs} - $l->{exp}, $r->{sigfigs} - $r->{exp}) + $exp - 1;
	my $sf    = $place + 1;

	my $vl = sprintf("%.${place}f", $lman);
	my $vr = sprintf("%.${place}f", $rman);
	my $v  = sprintf("%.${place}f", $vl - $vr) * 10**$exp;

	# round the subtraction to the place as well since sometimes
	# floating point number introduce repeated 9s at the end.
	return $self->new("$v");
}

# Redefine multiplication.  Since the number is stored as an integer, an exponenent and
# a number of significant figures, we use this information to calculate the product.

sub mult {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	return $self->new($l->value * $r->value, sigfigs => main::min($l->{sigfigs}, $r->{sigfigs}));
}

# Redefine division.  Since the number is stored as an integer, an exponenent and
# a number of significant figures, we use this information to calculate the quotient.
#

sub div {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	return $self->new($l->value / $r->value, sigfigs => main::min($l->{sigfigs}, $r->{sigfigs}));
}

sub abs {
	my $self = shift;
	return $self->make(CORE::abs($self->value), sigfigs => $self->{sigfigs});
}

sub neg {
	my $self = shift;
	return $self->new(-$self->value, sigfigs => $self->{sigfigs});
}

sub compare {
	my ($self, $l, $r) = Value::checkOpOrderWithPromote(@_);
	return $l->value cmp $r->value;
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

	# Note: need to throw an error if the sigfigs is <1 or > 15.
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

=head2 SigFigNumber

Create a number directly (instead using Compute) either with or without the number of significant
digits.

Usage:

    SigFigNumber('1.2345');
	SigFigNumber(10000,3); # makes a sig fig number which is 1.00 * 10**4

=cut

sub SigFigNumber {
	return context::SignificantFigures::Number->new(@_x);
}

sub eval {
	$self = shift;
	return $self->SUPER::eval(@_);
}

1;
