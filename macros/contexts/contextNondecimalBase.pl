
=head1 NAME

contextNonDecimalBase.pl - Implements a MathObject class and context for numbers
in non-decimal bases

=head1 DESCRIPTION

This context implements numbers and some operations on numbers in a non-decimal base
between 2 and 16.  The numbers will be stored internally in decimal, though parsed
and shown in the chosen base.

In addition, basic integer arithemetic (+,-,*,^) are available for these number.

The original purpose for this is simple conversion and operations in another base, however
it is not limited to this.

To use a non-decimal base MathObject, first load the contextNondecimalBase.pl file:

	loadMacros('contextNondecimalBase.pl');

and then select the appropriate context -- one of the following:

	Context('NondecimalBase');
	Context()->flags->set(base => 5);

will now interprets those in Compute and student answers in base 5.

  $a = Compute("104");
  $b = Compute("233");
	$sum = Compute("$a+$b"); # this is the base-5 number 342 (decimal 97)

For many problems, one may wish to not allow operators in the student answers.  Use
'LimitedNondecimalBase' for this.

  Context('LimitedNondecimalBase');
	Context()->flags->set(base => 5);
  $a = Compute("104");
  $b = Compute("233");
  $sum = Compute("$a+$b"); # There will be an error on this line now.

In both 'NondecmialBase' and 'LimitedNondecimalBase', another option is to use the
C<digits> flag to set the desired digits.  For example, if one wants to use base-12
and use the alternative digits 0..9,'T','E', then

  Context('NondecimalBase');
  Context()->flags->set(base => 5, digits => [0..9,'T','E']);

Then one can use the digits 'T' and 'E' in a number like:

  Compute('9T2');

=head2 Sample PG problem

A simple PG problem that asks a student to convert a number into base-5 may include:

  Context('LimitedNondecimalBase');
  Context()->flags->set(base => 5);

	# decimal number picked randomly.
	$a = random(130,500);
	$a_5 = Compute(convertBase($a, to => 5));

  BEGIN_PGML
	Convert [$a] to base-5:

	[$a] = [__]{$a_5}[`_5`]
	END_PGML
=cut

sub _contextNondecimalBase_init {
	context::NondecimalBase::Init(@_);
	sub convertBase { context::NondecimalBase::convert(@_); }
}

###########################################################################

package context::NondecimalBase;
our @ISA = ('Parser::Context');

# Note it seems like these need to be recreated each time the base is changed,
# so these are done each time in convertBase
#
# The standard digits, pre-built so it doesn't have to be done each time the conversion is called
# our $digits16 = [ '0' .. '9', 'A' .. 'F' ];
# our $digit16  = { map { ($digits16->[$_], $_) } (0 .. scalar(@$digits16) - 1) };

#  Initialize the contexts and make the creator function.
sub Init {
	my $context = $main::context{NondecimalBase} = Parser::Context->getCopy("Numeric");
	$context->{name}            = 'NondecimalBase';
	$context->{parser}{Number}  = 'context::NondecimalBase::Number';
	$context->{value}{Real}     = 'context::NondecimalBase::Real';
	$context->{pattern}{number} = '[0-9A-Z]+';
	$context->functions->disable('All');

	# don't allow division
	$context->operators->undefine('/');
	$context->constants->clear();
	$context->{precedence}{NondecimalBase} = $context->{precedence}{special};
	$context->flags->set(limits => [ -1000, 1000, 1 ]);
	$context->update;

	# define the LimitedNondecimalBase context that will not allow operations
	$context = $main::context{LimitedNondecimalBase} = $context->copy;
	$context->{name} = 'LimitedNondecimalBase';
	$context->operators->undefine('+', '-', '*', '* ', '^', '**', 'U', '.', '><', 'u+', '!', '_', ',',);
	$context->parens->undefine('|', '{', '[');
	$context->update;
}

=head2 convertBase

The function C<convertBase> is used internally but is useful for convert bases.  The format is
C<convertBase(value, opts)>

where C<value> is a positive number or string version of a positive number in some base.

=head3 options

=over

=item * C<from> the base that C<value> is in.  Defaults to 10.

=item * C<to> the base that C<value> is to be converted to.

=item * C<to> the digits to be used for the conversion.  The default is 0..9, 'A'.. 'E'
up through hexadecimal.

=back

=head3 Examples

For the following, since C<from> is not used, the base of C<value> is assumed to be 10.

  convertBase(58, to => 5);  # returns 213
  convertBase(58, to => 8); # returns 72
  convertBase(734, to => 16); # returns 2DE

For the following, since C<to> is not used, these are converted to base 10.

  convertBase(213, from => 5); # returns 58
  convertBase(72, from => 8); # returns 58
  convertBase('2DE', from => 16); # returns 734

Both C<to> and C<from> can be used together.

  convertBase(213, from => 5, to => 8); # returns 72

If one wants to use a different set of digits, say 0..9, 'T', 'E' for base-12 as an example

  convertBase(565, to => 12, digits => [0..9,'T','E']);  # returns '3E1'

=cut

sub convert {
	my $value   = shift;
	my %options = (
		from => 10,
		to   => 10,
		@_
	);
	my $from = $options{'from'};
	my $to   = $options{'to'};

	die "The digits option must be an array of characters to use for the digits"
		if $options{digits} && ref($options{digits}) ne 'ARRAY';

	# Unfortunately this needs to be called each time in case the digits were
	# set in a previous call.
	my $digits16 = $options{'digits'} // [ 0 .. 9, 'A' .. 'F' ];
	my $digit16  = { map { ($digits16->[$_], $_) } (0 .. scalar(@$digits16) - 1) };

	# The highest base the digits will support
	my $maxBase = scalar(@$digits16);

	die "The base of conversion must be between 2 and $maxBase"
		unless $to >= 2 && $to <= $maxBase && $from >= 2 && $from <= $maxBase;

	# Reverse map the digits to base 10 values
	my $baseBdigits = { map { ($digits16->[$_], $_) } (0 .. $from - 1) };

	#  Convert to base 10
	my $base10;
	if ($from == 10) {
		die "The number must consist only of digits: 0,1,2,3,4,5,6,7,8,9"
			unless $value =~ m/^\d+$/;
		$base10 = $value;
	} else {
		$base10 = 0;
		foreach my $d (split(//, $value)) {
			die "The number must consist only of digits: " . join(',', @$digits16[ 0 .. $from - 1 ])
				unless defined($baseBdigits->{$d});
			$base10 = $base10 * $from + $baseBdigits->{$d};
		}
	}
	return $base10 if $to == 10;

	#  Convert to desired base
	my @base;
	do {
		my $d = $base10 % $to;
		$base10 = ($base10 - $d) / $to;
		unshift(@base, $digits16->[$d]);
	} while $base10;

	return join('', @base);
}

# A replacement for Parser::Number that acepts numbers in a non-decimal base and
# converts them to decimal for internal use
package context::NondecimalBase::Number;
our @ISA = ('Parser::Number');

# Create a new number in the given base and convert to base 10.
sub new {
	my ($self, $equation, $value, $ref) = @_;
	my $context = $equation->{context};

	Value::Error('The base must be set for this context') unless $context->{flags}{base};
	my %opts = (from => $context->{flags}{base});
	$opts{digits} = $context->{flags}{digits} if $context->{flags}{digits};

	$value = context::NondecimalBase::convert($value, %opts);
	return $self->SUPER::new($equation, $value, $ref);
}

#  Return the value of the number in its given base.
sub eval {
	$self = shift;
	my $base = $self->{equation}{context}{flags}{base};
	return $self->Package('Real')->make($self->context, $self->{value});
}

#  A replacement for Value::Real that handles non-decimal integers
package context::NondecimalBase::Real;
our @ISA = ('Value::Real');

#  Stringify and TeXify the number in the context's base
sub string {
	my $self = shift;
	my $base = $self->{context}{flags}{base};
	return context::NondecimalBase::convert($self->value, to => $base);
}

sub TeX {
	my $self = shift;
	my $base = $self->{context}{flags}{base};
	return '\text{' . $self->string . '}';
}

1;
