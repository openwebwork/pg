
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

=head2 Usage

This is primarily for decimal numbers and keep track of signficant figures.   With the context loaded,
a call to C<Real> will parse the number or string to keep track of significant figures. For example,

    $x = Real('10.45');;
    $y = Real('37.1834');

and these numbers will have 6 and 4 signficant figures respectively.  To query the number of significant
figures, use the C<sigfigs> methods.  For example, C<$x->sigfigs> will return 4.

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
	my $value   = shift;
	my %opts    = @_;
	my $n       = $opts{sigfigs};

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
		if ($value !~ m/[.Ee]/) {
			$digits =~ s/0+$//;
		} else {
			$digits =~ s/[Ee].*$//;    # remove exponent, if any
			if ($value == 0) {
				$digits =~ s/^[+-]?0+(.(?:\.|$))/$1/;    # remove leading 0s before the decimal
				$digits =~ s/[-+.]//g;                   # remove non-digits
			} else {
				$digits =~ s/[-+.]//g;                   # remove non-digits
				$digits =~ s/^0+//;                      # remove leading zeros
			}
		}
		$n = length($digits);                            # what remains are the significant digits
	}
	my $N = $context->checkSigFigs($n);

	$self            = bless $self->SUPER::new($context, ROUND($value, $n)), $class;
	$value           = $class->format('E', $self->value, $n) unless $n == 'inf';
	$self->{data}    = [$value];
	$self->{exp}     = $n == 'inf' ? 0 : (split(/E/, $self->value))[1] + 0;
	$self->{sigfigs} = $N;

	return $self;
}

sub make { shift->new(@_) }

# Either return the current number of sigfigs for the number or set the current number.

sub sigfigs {
	my ($self, $n) = @_;
	return $self->{sigfigs} if !defined($n) || $self->{sigfigs} == $n;
	$self->{sigfigs} = $self->context->checkSigFigs($n);
	$self->{data}[0] = $n == 'inf' ? $self->value : $self->format('E', ROUND($self->value, $n), $n);
	return $self->{sigfigs};
}

# Shortcut for returning the number of significant figures.
sub N { shift->{sigfigs} }

# Return the exponent.
sub E { shift->{exp} }

# Return the exponential for the given $value with max(3,14-$exp) sigfigs.  This is
# helpful for addition and subtraction.
sub expFor {
	my ($self, $value, $exp) = @_;
	$exp = main::max(3, 14 - $exp);
	return (split(/E/, $self->format('E', $value, $exp)))[1] + 0;
}

#  Stringify and TeXify the number in the context's base
sub string { shift->format('f') }

sub TeX {
	my $self = shift;
	my $tex  = $self->string;
	$tex =~ s/E(?:(-)|\+)0*([1-9]\d?)/\\times 10^{$1$2}/;
	return "{$tex}";
}

# Format the number in $value in either 'E' (exponential form) or 'f' decimal form using
# $n signficant figures.

# Example: format('E', '123.456', 6) returns 1.23456E+02
# format('f', 1.23E-01, 3) returns '0.123'.

sub format {
	my ($self, $f, $value, $n) = @_;
	$value = $self->value        unless defined $value;
	$n     = $self->N - $self->E unless defined $n;
	return "$value" if $n == 'inf';
	$f = 'E', $n = $self->N if $f eq 'f' && ($n < 1 || $self->E >= 14 || -5 >= $self->E);
	$n = main::max(0, $n - 1);
	return sprintf("%.${n}${f}" . ($n == 0 && $f eq 'f' ? '.' : ''), $value);
}

# Redefine adding two numbers.  This calculates the last significant digit and then converts each number
# to an integer with the ones being signficant.  Then add and round, finally converting to decimal using the
# last significant digit as the exponent.

sub add {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	my $exp   = main::min($l->N - $l->E, $r->N - $r->E);
	my $value = $l->round($exp) + $r->round($exp);
	return $self->new($value, sigfigs => $exp + $self->expFor($value, $exp));
}

# For subtraction of two positive numbers, find the place of the least significant digit.
# Also, convert each number to the same exponent so the mantissa's in (0,10) before rounding to the
# correct place.

sub sub {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	my $exp   = main::min($l->N - $l->E, $r->N - $r->E);
	my $value = $l->round($exp) - $r->round($exp);
	return $self->new($value, sigfigs => $exp + $self->expFor($value, $exp));
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

# The compare method performs a comparsion on the value which is the exponential version of the number
# as in '1.23E+02'.  The comparison only is true if the string version of the two numbers are exactly the same.

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
	return $x if $n == 'inf';                          # keep the same if infinite digits
	return 0  if $n < 0 || $x == 0;                    # 0 if less than 0 digits wanted or there are no digits
	my $N = main::max(0, $n - 1);                      # Number of decimals to use in E notation
	my $r = sprintf("%.${N}E", $x);                    # preliminary rounding of $x
	my $e = (split(/E/, $r))[1] + 0;                   # exponent for $r
	my $s = ($x < 0 ? -1 : 1);                         # sign of $x
	my $m = main::max($n, 14 - $n);                    # position to use for adjustment for repeated 9s
	$x += $s * 10**($e - $m);                          # adjust for repeated 9s
	return sprintf("%.${N}E", $x) + 0 unless $n == 0;  # if we want digits, re-round the adjusted value
													   #
													   # For zero digits, we add a digit just above the first one in $x,
													   # round that, then remove the added digit, getting 0 if $x didn't
													   # round up, or 1 in the proper place if it did.  This means that
													   # 0.005 rounds to .01, for example, if we ask for no digits,
													   # so something like 1.23 - .005 will yield 1.22 properly.
													   #
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
	return $n if $n == 'inf';
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

sub eval { shift->SUPER::eval(@_) }

1;
