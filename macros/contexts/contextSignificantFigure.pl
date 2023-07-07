
loadMacros('MathObjects.pl','PGauxiliaryFunctions.pl');

sub _contextSignificantFigure_init {
	context::SignificantFigure::Init(@_);
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

sub new {
	my ($self, $equation, $value, $ref) = @_;
	$value = $value =~ s/^[0]+//r;

	my $num = $self->SUPER::new($equation, $value, $ref);
	# store the number as an integer.
	my ($value_int, $exp, $sigfigs);
	if ($value =~ /\./) {
		my @s = split(/\./,$value);
		$exp = -1*length($s[1]);
		# If it is in the form .XXX, then $s[0] is ''
		$value_int = ($s[0] || 0)*10**(-$exp)+$s[1];
		$sigfigs = $value_int < 0 ? length($value_int)-1 : length($value_int);
	} else {
		if ($value =~/^-?([1-9](\d*[1-9])?)(0*)$/) {
			$value_int = $1;
			$exp = length($2);
			$sigfigs = length($value_int);
		}
	}

	$num->{value_int} = $value_int;
	$num->{exp} = $exp;
	$num->{sigfigs} = $sigfigs;

	return $num;
}

sub eval {
	$self = shift;
	return $self->SUPER::eval(@_);
}


#  A replacement for Value::Real that handles Significant figures
package context::SignificantFigure::Real;
our @ISA = ('Value::Real');

sub new {
	return shift->SUPER::new(@_);
}

sub sigfigs {
	my $self = shift;
	return $self->{equation}{tree}{sigfigs};
}

#  Stringify and TeXify the number in the context's base
sub string {
	my $self = shift;
	return $self->value;
}

sub TeX {
	my $self = shift;
	return '\text{' . $self->string . '}';
}

# Redefine multiplication.  Since the number is stored as an integer, an exponenent and
# a number of significant figures, we use this information to calculate the product.
#
# The integer product is made and then the number of digits kept is the length of the
# number - min(left, right). Lastly, the decimal is then shifted using the sum of
# the exponents.
sub mult {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	my $vl = $l->{original_formula}{stack}[0]{value};
	my $vr = $r->{original_formula}{stack}[0]{value};
	my $prod = $vr->{value_int}*$vl->{value_int};
	my $digs = length($prod)-main::min($vr->{sigfigs},$vl->{sigfigs});
	my $value = main::Round($prod,-$digs)*10**($vl->{exp}+$vr->{exp});
	return context::SignificantFigure::Number->new($l->{equation},"$value");
}

# Redefine adding two numbers.  This calculates the last significant digit and then converts each number
# to an integer with the ones being signficant.  Then add and round, finally converting to decimal using the
# last significant digit as the exponent.

sub add {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	my $vl = $l->{original_formula}{stack}[0]{value};
	my $vr = $r->{original_formula}{stack}[0]{value};

	# Determine the last significant digit (0 = ones, -1 = tenths, ...)
	my $last_dig_l = length($vl->{value_int}) - $vl->{sigfigs} + $vl->{exp};
	my $last_dig_r = length($vr->{value_int}) - $vr->{sigfigs} + $vr->{exp};
	my $last_dig = main::max($last_dig_l, $last_dig_r);

	my $sum_int = main::Round($vl->{value_int}*10**($vl->{exp}-$last_dig))
		+ main::Round($vr->{value_int}*10**($vr->{exp}-$last_dig));
	my $value = $sum_int*10**$last_dig;
	return context::SignificantFigure::Number->new($l->{equation},"$value");
}

1;