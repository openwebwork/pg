
=head1 NAME

contextBaseN.pl - Implements a MathObject class and context for numbers
in non-decimal bases

=head1 DESCRIPTION

This context implements positive integers and some operations on integers in a non-decimal base
greater than or equal to 2.  The numbers will be stored internally in decimal, though parsed
and shown in the chosen base.

The original purpose for this is simple conversion and operations in another base, however
it is not limited to this. In addition, basic integer arithemetic (+,-,*,/,%,^) are available for these numbers.
Division is defined in an integer sense.

To use a non-decimal base MathObject, first load the contextBaseN.pl file:

    loadMacros('contextBaseN.pl');

There are two contexts: C<BaseN> and C<LimitedBaseN>, where the former
allows operations between numbers and the latter only allows numbers. To use either,
one must set the base.  For example:

    Context('BaseN')->setBase(5);

Now most numerical strings in Compute, Formula, and student answers will be read in base five.

    $a = Compute('104');
    $b = Compute('233');
    $sum = $a+$b # this is the base-5 number 342 (decimal 97)

or a shorter way:

    $sum = Compute('104+233');

Also, when a string is the argument to some other Math Object and that string needs to
be parsed, numerical substrings will be read in base 5:

    $point = Point('(104, 233)');  # this is (29, 68) in base ten

For Math Object constructors that directly accept a number or numbers as arguments,
the numbers will be read in base ten. All of the following should be read in base ten:

    $r = Real(29);
    $r = Real('68');
    $p = Point(29, 68);

For many problems, one may wish to not allow operators in the student answers.  Use
'LimitedBaseN' for this.

    Context('LimitedBaseN')->setBase(5);
    $sum = Compute("104+233"); # There will be an error on this line now.

In both contexts, rather than pass the base as a number, another option is to pass the
digits used for the number to the C<setBase> method.  For example, if one wants to use base-12
and use the alternative digits 0..9,'T','E', then

    Context('BaseN')->setBase([0 .. 9, 'T', 'E']);

Then one can use the digits 'T' and 'E' in a number like:

    Compute('9TE');

A few strings can be passed to the C<setBase> method with preset meanings:

    C<binary> for [0,1]
    C<octal> for [0 .. 7]
    C<decimal> for [0 .. 9]
    C<duodecimal> for [0 .. 9, 'A', 'B']
    C<hexadecimal> for [0 .. 9, 'A' .. 'F']
    C<base64> for ['A' .. 'Z', 'a' .. 'z', 0 .. 9, '_', '?']

The last two digits for C<base64> are nonstandard. We want to avoid '+' and '/' here as they have arithmetic meaning.

=head1 Sample PG problem

A simple PG problem that asks a student to convert a number into base-5:

    DOCUMENT();
    loadMacros(qw(PGstandard.pl PGML.pl contextBaseN.pl));

    Context('LimitedBaseN')->setBase(5);

    # decimal number picked randomly.
    $a = random(130,500);
    $a_5 = Real($a); # converts $a to base-5

    BEGIN_PGML
    Convert [$a] to base-5:

    [$a] = [__]*{$a_5}
    END_PGML
    ENDDOCUMENT();

The star variant answer blank will print the base in subscript after the answer blank.
=cut

sub _contextBaseN_init {
	context::BaseN::Init(@_);
	sub convertBase { context::BaseN::convert(@_); }
}

package context::BaseN;

# Define the contexts 'BaseN' and 'LimitedBaseN'
sub Init {
	my $context = $main::context{BaseN} = context::BaseN::Context->new();
	$context         = $main::context{LimitedBaseN} = $context->copy;
	$context->{name} = 'LimitedBaseN';
	$context->operators->undefine($context->operators->names);
	$context->parens->undefine('|', '{', '[');
}

=head1 FUNCTIONS

=head2 convertBase

The function C<convertBase(value, opts)> converts the value from or to other bases depending on the options
in C<opts>.  The input C<value> is a positive number or string version of a positive number in some base.

=head3 options

=over

=item * C<from> the base that C<value> is in.  Default is 10.  Can take the same values as C<setBase>.

=item * C<to> the base that C<value> will be converted to.  Default is 10.  Can take the same values as C<setBase>.

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

    convertBase(565, to => [0 .. 9, 'T', 'E']);  # returns '3E1'

=cut

my $convertContext;

sub convert {
	my ($value, %options) = @_;
	my $from = $options{'from'} // 10;
	my $to   = $options{'to'}   // 10;

	$convertContext = $main::context{BaseN}->copy unless $convertContext;
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

package context::BaseN::Context;
our @ISA = ('Parser::Context');

# Create a Context based on Numeric that allows +, -, *, /, %, and ^ on BaseN integers.

sub new {
	my $self    = shift;
	my $class   = ref($self) || $self;
	my $context = bless Parser::Context->getCopy('Numeric'), $class;
	$context->{name}           = 'BaseN';
	$context->{parser}{Number} = 'context::BaseN::Number';
	$context->{value}{Real}    = 'context::BaseN::Real';
	$context->functions->disable('All');
	$context->constants->clear();
	$context->{pattern}{number}   = '[' . join('', 0 .. 9, 'A' .. 'Z') . ']+';
	$context->{precedence}{BaseN} = $context->{precedence}{special};
	$context->flags->set(limits => [ -1000, 1000, 1 ]);
	$context->operators->add(
		'%' => {
			class         => 'context::BaseN::BOP::modulo',
			precedence    => 3,
			associativity => 'left',
			type          => 'bin',
			string        => ' % ',
			TeX           => '\mathbin{\%}',
		}
	);
	return $context;
}

# set the base of the context.  Either an integer that is at least 2, an arrayref of digits,
# or a preset: 'binary', 'octal', 'decimal', 'duodecimal', 'hexadecimal', or 'base64'.
sub setBase {
	my ($self, $base) = @_;
	my $digits;

	$base = [ 0, 1 ]                                     if ($base eq 'binary');
	$base = [ 0 .. 7 ]                                   if ($base eq 'octal');
	$base = [ 0 .. 9 ]                                   if ($base eq 'decimal');
	$base = [ 0 .. 9, 'A', 'B' ]                         if ($base eq 'duodecimal');
	$base = [ 0 .. 9, 'A' .. 'F' ]                       if ($base eq 'hexadecimal');
	$base = [ 'A' .. 'Z', 'a' .. 'z', 0 .. 9, '_', '?' ] if ($base eq 'base64');

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
package context::BaseN::Number;
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

# Modulo operator
package context::BaseN::BOP::modulo;
our @ISA = ('Parser::BOP::divide');

#  Do the division.

sub _eval { $_[1] % $_[2] }

#  A replacement for Value::Real that handles non-decimal integers
package context::BaseN::Real;
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

sub ans_array {
	my $self = shift;
	return $self->ans_rule(@_) . main::math_ev3('_{' . $self->context->{base} . '}');
}

# Define division as integer division.
sub div {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	Value::Error("Division by zero") if $r->{data}[0] == 0;
	return $self->inherit($other)->make(int($l->{data}[0] / $r->{data}[0]));
}

1;
