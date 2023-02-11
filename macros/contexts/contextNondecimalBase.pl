
=head1 NAME

contextHex.pl - Implements a MathObject class and context for integers
                in hexadecimal notation.

=head1 DESCRIPTION

This context implements a Hex object that works like a Real, but
where you enter numbers in hexadecimal, and they display in hexadecimal.
You can perform the usual numeric operations (addition, subtraction,
etc.), but division is integer division (so 7/3 = 2).  The context defines
the bitwise operators &, |, ^, >>, <<, and ~ (for bitwise and, or,
exclusive or, shift-right, shift-left, and one's complement not).  You can
apply these operations within your PG code to variables that store Hex
objects.  Remember that you can also obtain Perl reals via hex notation,
for example, 0x1A.

To use hexadecimal MathObjects, first load the contextHex.pl file:

	loadMacros("contextHex.pl");

and then select the appropriate context -- one of the following:

	Context("Hex");
	Context("LimitedHex");

The latter only allows the student to enter hexadecimal literals (not
expressions), or lists of hexadecimal numbers.  The former allows
expression involving numeric operations and bitwise operations.

Once one of these contexts is selected, all the nummbers parsed by
MathObjects will be considered to be in hexadecimal, so

        $n = Compute('10');

produces the hexadecimal number 10 (decimal 16).  You could also obtain
a hex MathObject using

        $n = Hex(0x10);

Once you have such a value, use

        ANS($n->cmp)

to get an answer checker for the number.  You can also perform numeric or
bitwise operations on the value, as in

        $m = $n + 0xE3;
        $N = $n << 2;     # shifts n to the left 2 (binary) places,
                          #   $N = Hex(0x40) when $n = Hex(0x10)

=cut

sub _contextNondecimalBase_init {
	context::NondecimalBase::Init();
	sub setBase     { context::NondecimalBase::setBase(@_); }
	sub convertBase { context::NondecimalBase::convert(@_); }
}

###########################################################################

package context::NondecimalBase;

# defines the base for the context.
our $base = 10;
#
#  The standard digits, pre-built so it doesn't have to be done each time the conversion is called
#
our $digits16 = [ '0' .. '9', 'A' .. 'F' ];
our $digit16  = { map { ($digits16->[$_], $_) } (0 .. scalar(@$digits16) - 1) };

use Data::Dumper;
#
#  Initialize the contexts and make the creator function.
#
sub Init {
	my $context = $main::context{NondecimalBase} = Parser::Context->getCopy("Numeric");
	$context->{name} = 'NondecimalBase';
	$context->{parser}{Number} = 'context::NondecimalBase::Number';
	# $context->{value}{Real} = 'context::Hex::Hex';
	$context->{pattern}{number} = '[0-9A-F]+';
	$context->functions->disable('All');
	$context->operators->remove('^');
	$context->parens->remove('|');
	$context->constants->clear();
	# $context->operators->add(
	#   '&'  => {precedence => .6, associativity => 'left', type => 'bin', string => ' & ',
	#            class => 'context::Hex::BOP::hex', eval => sub {$_[0] & $_[1]}},
	#   '|'  => {precedence => .5, associativity => 'left', type => 'bin', string => ' | ',
	#            class => 'context::Hex::BOP::hex', eval => sub {$_[0] | $_[1]}},
	#   '^'  => {precedence => .5, associativity => 'left', type => 'bin', string => ' ^ ',
	#            class => 'context::Hex::BOP::hex', eval => sub {$_[0] ^ $_[1]}},
	#   '>>' => {precedence => .4, associativity => 'left', type => 'bin', string => ' >> ',
	#            class => 'context::Hex::BOP::hex', eval => sub {$_[0] >> $_[1]}},
	#   '<<' => {precedence => .4, associativity => 'left', type => 'bin', string => ' << ',
	#            class => 'context::Hex::BOP::hex', eval => sub {$_[0] << $_[1]}},
	#   '~'  => {precedence => 6, associativity => 'left', type => 'unary', string => '~',
	#            class => 'context::Hex::UOP::not'},
	# );
	# $context->{precedence}{Hex} = $context->{precedence}{special};
	$context->flags->set(limits => [ -1000, 1000, 1 ]);
	$context->update;

	# main::PG_restricted_eval('sub Hex {context::Hex::Hex->new(@_)}');
}
use Data::Dumper;

sub convert {
	my $value = shift;
	print Dumper "convert: $value";
	# Set default options and get passed in options.
	my %options = (
		from   => 10,
		to     => 10,
		digits => $digits16,
		@_
	);
	my $from   = $options{'from'};
	my $to     = $options{'to'};
	my $digits = $options{'digits'};
	print Dumper "from: $from; to: $to";

	die "The digits option must be an array of characters to use for the digits"
		unless ref($digits) eq 'ARRAY';

	#
	# The highest base the digits will support
	#
	my $maxBase = scalar(@$digits16);

	die "The base of conversion must be between 2 and $maxBase"
		unless $to >= 2 && $to <= $maxBase && $from >= 2 && $from <= $maxBase;

	#
	# Reverse map the digits to base 10 values
	#
	my $baseBdigits = { map { ($digits->[$_], $_) } (0 .. $from - 1) };

	#
	#  Convert to base 10
	#
	my $base10;
	if ($from == 10) {
		die "The number to convert must consist only of digits: 0,1,2,3,4,5,6,7,8,9"
			unless $value =~ m/^\d+$/;
		$base10 = $value;
	} else {
		$base10 = 0;
		foreach my $d (split(//, $value)) {
			die "The number to convert must consist only of digits: " . join(',', @$digits[ 0 .. $from - 1 ])
				unless defined($baseBdigits->{$d});
			$base10 = $base10 * $from + $baseBdigits->{$d};
		}
	}
	return $base10 if $to == 10;

	#
	#  Convert to desired base
	#
	my @base;
	do {
		my $d = $base10 % $to;
		$base10 = ($base10 - $d) / $to;
		unshift(@base, $digits->[$d]);
	} while $base10;

	return join('', @base);
}

# set the base for the context.

use Data::Dumper;

sub setBase {
	my $b = shift;
	return Value::Error('The base must be greater than 1 and less than or equal to $max_base')
		unless $b >= 2 && $b <= scalar(@$digits16);
	$base = $b;
	# $digits16 = [map { $digits16->[$_] } (0..($base-1))];
	# $digit16 = { map { ($digits16->[$_], $_) } (0 .. scalar(@$digits16) - 1) };
	# $context->{pattern}{number} = '[' . join('',@$digits16) . ']+';
}

###########################################################################
#
#  A replacement for Parser::Number that acepts numbers in
#  hexadecimal and converts them to decimal for internal use
#
package context::NondecimalBase::Number;
our @ISA = ('Parser::Number');

use Data::Dumper;

# Create a new number in the given base and convert to base 10.

sub new {
	my $self = shift;
	my ($equation, $value, $ref) = @_;
	$value = context::NondecimalBase::convert($value, from => $base);
	return $self->SUPER::new($equation, $value, $ref);
}

#
#  Return the value of the number in its given base.
#
sub eval {
	$self = shift;
	return context::NondecimalBase::convert($self->{value}, to => $base);
	$self->Package('Real')->make($self->context, $self->{value});
}

###########################################################################
#
#  A replacement for Value::Real that handles hexadecimal integers
#
package context::Hex::Hex;
our @ISA = ('Value::Real');

#
#  Stringify and TeXify in hex notation
#
sub string {
	my $self = shift;
	return main::spf($self->value);
}

sub TeX {
	my $self = shift;
	return '\text{' . $self->string . '}';
}

###########################################################################
#
#  This is a Parser::BOP that handles the bitwise operations (all of
#  them call the same class, and the operators list gives the code to
#  perform the operation)
#
package context::Hex::BOP::hex;
our @ISA = ('Parser::BOP');

sub _check {
	my $self = shift;
	return if $self->checkNumbers;
	$self->Error("Arguments to '%s' must be Numbers", $self->{bop});
}

sub _eval {
	my ($self, $a, $b) = @_;
	$a->inherit($b)->make(&{ $self->{def}{eval} }($a->value, $b->value));
}

###########################################################################
#
#  The Parser::UOP subclass for one's complement not.
#
package context::Hex::UOP::not;
our @ISA = ('Parser::UOP');

sub _check {
	my $self = shift;
	return if $self->checkNumber;
	$self->Error("Argument to '%s' must be a Number", $self->{uop});
}

sub _eval {
	my ($self, $a) = @_;
	$a->make(~($a->value));
}

###########################################################################

1;
