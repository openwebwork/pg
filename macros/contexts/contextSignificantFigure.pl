
=head1 NAME

contextSignificantFigure.pl - Implements a context to handle numbers where significant figures is important.

=head1 DESCRIPTION

This file implements a MathObject SignificantFigure class that provides the ability to create
numbers for given significant figures as well as the operations +, -, *, /, **

To load this context, use

    loadMacros('contextSignificantFigure.pl');

and then set this context with

    Context('SignificantFigure');

or

    Context('LimitedSignificantFigure');

where the latter context, you or the student is not allowed to perform any operations on
any numbers.

=cut

loadMacros('MathObjects.pl', 'PGauxiliaryFunctions.pl');

sub _contextSignificantFigure_init {
	context::SignificantFigure::Init(@_);
	sub SigFigNumber { return SignificantFigure->new(@_); }
}

package SignificantFigure;
our @ISA = ('Value::Real');

use Data::Dumper;

sub new {
	print Dumper 'in SignificantFigure::new';
	my $self    = shift;
	my $class   = ref($self) || $self;
	my $context = (Value::isContext($_[0]) ? shift : $self->context);
	my $value   = shift;
	my $n       = shift;                                                # number of significant digits
	print Dumper $value;
	$self = bless $self->SUPER::new($context, $value), $class;

	# remove all leading zeros
	$value =~ s/^0+//r;

	my $s;                                                              # Used to store the sigfigs if $n is passed in.
	if ($value =~ /\./) {
		my @s = split(/\./, $value);
		$self->{exp} = -1 * length($s[1]);
		# If the number is in the form .XXX, then $s[0] is ''
		$self->{value_int} = ($s[0] || 0) * 10**(-$self->{exp}) + $s[1];
		$self->{sigfigs}   = $self->{value_int} < 0 ? length($self->{value_int}) - 1 : length($self->{value_int});
		$s                 = $self->{sigfigs};    # needs to be saved for later.

	} elsif ($value =~ /^-?([1-9](\d*[1-9])?)(0*)$/) {
		$self->{value_int} = defined($n) ? substr($1, 0, $n) : $1;
		$self->{exp}       = defined($n) ? length($3)        : length($3);
		$self->{sigfigs}   = defined($n) ? $n                : length($value);
		$s                 = length($self->{value_int});
	} else {
		die 'oops';
	}
	# If the number of sig figs is passed in, need to adjust all of the values:
	if (defined($n)) {
		Value::Error('The number of significant digits needs to be an integer at least 1')
			unless $n =~ /^\d*$/ && $n > 0;

		# print Dumper ['n', $n, 'sigfigs', $self->{sigfigs}, 's', $s];
		$self->{exp}       = $self->exp + (length($self->{value_int}) - $n);
		$self->{sigfigs}   = $n;
		$self->{value_int} = $n < $s ? substr($self->{value_int}, 0, $n) : $self->{value_int} * 10**($n - $s);
	}

	$self->{data} = [ $self->{value_int} * 10**$self->{exp} ];
	return $self;
}

# Either return the current number of sigfigs for the number or set the current number.

sub sigfigs {
	my ($self, $num_sigfigs) = @_;
	return $self->{sigfigs} unless defined($num_sigfigs);
	Value::Error('The number of significant figures must be an integer >=-1')
		unless $num_sigfigs =~ /-?\d+/ && $num_sigfigs >= -1;

	my $curr_sigfigs = $self->{sigfigs};
	my $curr_exp     = $self->{exp};

	return $curr_sigfigs if $curr_sigfigs == $num_sigfigs;
	# print Dumper [$self->{value_int}, $num_sigfigs, $curr_sigfigs];
	$self->{sigfigs}   = $num_sigfigs;
	$self->{value_int} = main::Round($self->{value_int} * 10**($num_sigfigs - $curr_sigfigs))
		if ($num_sigfigs < $curr_sigfigs);
	$self->{exp} += $curr_sigfigs - $num_sigfigs;
	return $self->{sigfigs};
}

# return the exponent since stored in the form d * 10^(p), where d is an integer.
sub exp { return shift->{exp}; }

#  Stringify and TeXify the number in the context's base
sub string { return shift->value; }
sub TeX    { return '\text{' . shift->string . '}'; }

# Redefine adding two numbers.  This calculates the last significant digit and then converts each number
# to an integer with the ones being signficant.  Then add and round, finally converting to decimal using the
# last significant digit as the exponent.

use Data::Dumper;

sub add {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	# Determine the last significant digit (0 = ones, -1 = tenths, ...)
	my $last_dig_l = length($l->{value_int}) - $l->{sigfigs} + $l->{exp};
	my $last_dig_r = length($r->{value_int}) - $r->{sigfigs} + $r->{exp};
	my $last_dig   = main::max($last_dig_l, $last_dig_r);
	my $sum_int    = main::Round($l->{value_int} * 10**($l->{exp} - $last_dig)) +
		main::Round($r->{value_int} * 10**($r->{exp} - $last_dig));
	return $self->new($sum_int * 10**$last_dig, length($sum_int));
}

# Redefine subtraction.  This calculates the last significant digit and then converts each number
# to an integer with the ones being signficant.  Then subtract and round, finally converting to decimal using the
# last significant digit as the exponent.

sub sub {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	# Determine the last significant digit (0 = ones, -1 = tenths, ...)
	my $last_dig_l = length($l->{value_int}) - $l->{sigfigs} + $l->{exp};
	my $last_dig_r = length($r->{value_int}) - $r->{sigfigs} + $r->{exp};
	my $last_dig   = main::max($last_dig_l, $last_dig_r);

	my $diff_int = main::Round($l->{value_int} * 10**($l->{exp} - $last_dig)) -
		main::Round($r->{value_int} * 10**($r->{exp} - $last_dig));
	return $self->new($diff_int * 10**$last_dig, length($diff_int));
}

# Redefine multiplication.  Since the number is stored as an integer, an exponenent and
# a number of significant figures, we use this information to calculate the product.
#
# The integer product is made and then the number of digits kept is the length of the
# number - min(left, right). Lastly, the decimal is then shifted using the sum of
# the exponents.
sub mult {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	my $prod = $l->{value_int} * $r->{value_int};
	return $self->new($prod * 10**($l->{exp} + $r->exp), main::min($l->sigfigs, $r->sigfigs));
}

# Redefine division.  Since the number is stored as an integer, an exponenent and
# a number of significant figures, we use this information to calculate the quotient.
#
# The integer product is made and then the number of digits kept is the length of the
# number - min(left, right). Lastly, the decimal is then shifted using the difference of
# the exponents.

sub div {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	my $quo = $l->{value_int} / $r->{value_int};
	return $self->new($quo * 10**($l->{exp} - $r->exp), main::min($r->{sigfigs}, $l->{sigfigs}));
}

package context::SignificantFigure;

sub Init {
	my $context = $main::context{SignificantFigure} = context::SignificantFigure::Context->new();
}

package context::SignificantFigure::Context;
our @ISA = ('Parser::Context');

sub new {
	my $self    = shift;
	my $class   = ref($self) || $self;
	my $context = bless Parser::Context->getCopy('Numeric'), $class;
	$context->{name}           = 'SignificantFigure';
	$context->{parser}{Number} = 'context::SignificantFigure::Number';
	$context->{value}{Real}    = 'context::SignificantFigure::Real';
	$context->functions->disable('All');
	$context->constants->clear();
	$context->{precedence}{SignifcantFigure} = $context->{precedence}{special};
	$context->flags->set(limits => [ -1000, 1000, 1 ]);
	return $context;
}

package context::SignificantFigure::Number;
our @ISA = ('Parser::Number');
use Data::Dumper;

sub new {
	my $self     = shift;
	my $class    = ref($self) || $self;
	my $equation = shift;
	my $context  = $equation->{context};
	$self = bless $self->SUPER::new($equation, @_), $class;
	$self->{value} = SignificantFigure->new($self->{value_string});
	return $self;
}

=head2 SigFigNumber

Create a number directly (instead using Compute) either with or without the number of significant
digits.

Usage:

    SigFigNumber('1.2345');
	SigFigNumber(10000,3); # makes a sig fig number which is 1.00 * 10**4

=cut

sub SigFigNumber {
	return context::SignificantFigure::Number->new(@_x);
}

sub eval {
	$self = shift;
	return $self->SUPER::eval(@_);
}

#  A replacement for Value::Real that handles Significant figures
package context::SignificantFigure::Real;
our @ISA = ('Value::Real');

sub new {
	print Dumper 'in context::SignificantFigure::Real::new';
	print Dumper \@_;
	return shift->SUPER::new(@_);
}

1;
