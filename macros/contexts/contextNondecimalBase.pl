
=head1 NAME

contextNonDecimalBase.pl - Implements a MathObject class and context for numbers
in non-decimal bases

=head1 DESCRIPTION

This context implements positive integers and some operations on integers in a non-decimal base
greater than or equal to 2.  The numbers will be stored internally in decimal, though parsed
and shown in the chosen base.

In addition, basic integer arithemetic (+,-,*,/^) are available for these numbers.
Division is defined in an integer sense.

The original purpose for this is simple conversion and operations in another base, however
it is not limited to this.

To use a non-decimal base MathObject, first load the contextNondecimalBase.pl file:

    loadMacros('contextNondecimalBase.pl');

There are two contexts: C<NondecimalBase> and C<LimiitedNondecimalBase>, where the former
allows operations between numbers and the latter only allows numbers. To use either
first, one must set the base.  For example:

    Context('NondecimalBase')->setBase(5);

will now interprets those in Compute and student answers in base 5.

    $a = Compute('104');
    $b = Compute('233');
    $sum = $a+$b # this is the base-5 number 342 (decimal 97)

or a shorter way:

    $sum = Compute('104+233');

For many problems, one may wish to not allow operators in the student answers.  Use
'LimitedNondecimalBase' for this.

    Context('LimitedNondecimalBase')->setBase(5);
    $sum = Compute("104+233"); # There will be an error on this line now.

In both 'NondecimalBase' and 'LimitedNondecimalBase', another option is to pass the
digits used for the number to the C<setBase> method.  For example, if one wants to use base-12
and use the alternative digits 0..9,'T','E', then

    Context('NondecimalBase')->setBase([0..9,'T','E']);

Then one can use the digits 'T' and 'E' in a number like:

    Compute('9TE');

=head2 Sample PG problem

A simple PG problem that asks a student to convert a number into base-5 may include:

    Context('LimitedNondecimalBase')->setBase(5);

    # decimal number picked randomly.
    $a = random(130,500);
    $a_5 = Real($a); # converts $a to base-5

    BEGIN_PGML
    Convert [$a] to base-5:

    [$a] = [__]{$a_5}[`_5`]
    END_PGML

=cut

sub _contextNondecimalBase_init {
	context::NondecimalBase::Init(@_);
	sub convertBase { context::NondecimalBase::convert(@_); }
}

package context::NondecimalBase;

# Define the contexts 'NondecimalBase' and 'LimitedNondecimalBase'
sub Init {
	my $context = $main::context{NondecimalBase} = context::NondecimalBase::Context->new();
	$context         = $main::context{LimitedNondecimalBase} = $context->copy;
	$context->{name} = 'LimitedNondecimalBase';
	$context->operators->undefine($context->operators->names);
	$context->parens->undefine('|', '{', '[');
}

=head2 convertBase

The function C<convertBase(value, opts)> converts the value from or to other bases depending on the options
in C<opts>.  The input C<value> is a positive number or string version of a positive number in some base.

=head3 options

=over

=item * C<from> the base that C<value> is in.  Defaults to 10.

=item * C<to> the base that C<value> is to be converted to.

=item * C<digits> the digits to be used for the conversion.  The default is 0..9, 'A'.. 'E'
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

    convertBase(565, to => [0..9,'T','E']);  # returns '3E1'

=cut

my $convertContext;

sub convert {
	my ($value, %options) = @_;
	my $from = $options{'from'} // 10;
	my $to   = $options{'to'}   // 10;

	$convertContext = $main::context{NondecimalBase}->copy unless $convertContext;
	if ($from != 10) {
		$convertContext->setBase($from);
		$value = $convertContext->fromBase($value);
	}
	if ($to != 10) {
		$convertContext->setBase($to);
		$value = $convertContext->toBase($value);
	}
	return $value;
}

package context::NondecimalBase::Context;
our @ISA = ('Parser::Context');

# Create a Context based on Numeric (Real) that allows +, -, *, / and ^ on nondecimal numbers.

sub new {
	my $self    = shift;
	my $class   = ref($self) || $self;
	my $context = bless Parser::Context->getCopy('Numeric'), $class;
	$context->{name}           = 'NondecimalBase';
	$context->{parser}{Number} = 'context::NondecimalBase::Number';
	$context->{value}{Real}    = 'context::NondecimalBase::Real';
	$context->functions->disable('All');
	$context->constants->clear();
	$context->{pattern}{number}            = '[' . join('', 0 .. 9, 'A' .. 'Z') . ']+';
	$context->{precedence}{NondecimalBase} = $context->{precedence}{special};
	$context->flags->set(limits => [ -1000, 1000, 1 ]);
	return $context;
}

# set the base of the context.  Either base a number >=2 or an arrayref of digits.
sub setBase {
	my ($self, $base) = @_;
	my $digits;

	if (ref($base) eq 'ARRAY') {
		$digits = $base;
		$base   = scalar(@$digits);
		die 'Base must be at least 2' unless $base >= 2;
	} else {
		die 'Base must be an integer' unless $base == int($base);
		die 'Base must be at least 2' unless $base >= 2;
		die 'You must provide a digit list for bases bigger than 36' if $base > 36;
		$digits = [ ('0' .. '9', 'A' .. 'Z')[ 0 .. $base - 1 ] ];
	}

	$self->{base}            = $base;
	$self->{digits}          = $digits;
	$self->{digitMap}        = { map { ($digits->[$_], $_) } (0 .. $base - 1) };
	$self->{pattern}{number} = '[' . join('', @$digits) . ']+';
	my $msg = 'Numbers should consist only of the digits: ' . join(',', @$digits);
	$self->{error}{msg}{"Variable '%s' is not defined in this context"} = $msg;
	$self->{error}{msg}{"'%s' is not defined in this context"}          = $msg;
	$self->update;
}

sub copy {
	my $self = shift;
	my $copy = $self->SUPER::copy;
	$copy->{base}     = $self->{base};
	$copy->{digits}   = $self->{digits};
	$copy->{digitMap} = $self->{digitMap};
	return $copy;
}

# Convert a number in base10 to the given base.
sub toBase {
	my ($self, $base10) = @_;
	my $b      = $self->{base};
	my $digits = $self->{digits};

	my @baseB;
	do {
		my $d = $base10 % $b;
		$base10 = ($base10 - $d) / $b;
		unshift(@baseB, $digits->[$d]);
	} while $base10;

	return join('', @baseB);
}

# Convert a number in a given base to base 10.
sub fromBase {
	my ($self, $baseB) = @_;
	my $b      = $self->{base};
	my $digits = $self->{digits};
	my $digit  = $self->{digitMap};

	my $base10 = 0;
	for my $d (split('', $baseB)) {
		die 'The number should only consist of the digits: ' . join(',', @$digits) unless defined($digit->{$d});
		$base10 = $base10 * $b + $digit->{$d};
	}

	return $base10;
}

# A replacement for Parser::Number that accepts numbers in a non-decimal base and
# converts them to decimal for internal use
package context::NondecimalBase::Number;
our @ISA = ('Parser::Number');

# Create a new number in the given base and convert to base 10.
sub new {
	my ($self, $equation, $value, $ref) = @_;
	my $context = $equation->{context};

	Value::Error('The base must be set for this context') unless $context->{base};

	$value = $context->fromBase($value);
	return $self->SUPER::new($equation, $value, $ref);
}

sub eval {
	$self = shift;
	return $self->Package('Real')->make($self->context, $self->{value});
}

#  A replacement for Value::Real that handles non-decimal integers
package context::NondecimalBase::Real;
our @ISA = ('Value::Real');

#  Stringify and TeXify the number in the context's base
sub string {
	my $self = shift;
	return $self->context->toBase($self->value);
}

sub TeX {
	my $self = shift;
	return '\text{' . $self->string . '}';
}

# Define division as integer division.
sub div {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	Value::Error("Division by zero") if $r->{data}[0] == 0;
	return $self->inherit($other)->make(int($l->{data}[0] / $r->{data}[0]));
}

1;
