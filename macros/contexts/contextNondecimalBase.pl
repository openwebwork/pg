
=head1 NAME

contextNonDecimalBase.pl - Implements a MathObject class and context for numbers in non-decimal bases

=head1 DESCRIPTION

This context implements a Hex object that works like a Real, but can implement numbers
in any non-decimal base between 2 and 16.  The numbers will be stored internally in
decimal, though parsed and shown in the chosen base.

In addition, basic integer arithemetic (+,-,*,^) are available for these number.

The original purpose for this is simple conversion and operations in another base, however
it is not limited to that

To use a non-decimal base MathObject, first load the contextNondecimalBase.pl file:

	loadMacros("contextNondecimalBase.pl");

and then select the appropriate context -- one of the following:

	Context("NondecimalBase");

Once one of these contexts is selected, all the nummbers parsed by
MathObjects will be considered to be in hexadecimal, so

=cut

sub _contextNondecimalBase_init {
	context::NondecimalBase::Init(@_);
	# sub setBase     { context::NondecimalBase::setBase(@_); }
	sub convertBase { context::NondecimalBase::convert(@_); }
}

###########################################################################

package context::NondecimalBase;
our @ISA = ('Parser::Context');

use Data::Dumper;

#
#  The standard digits, pre-built so it doesn't have to be done each time the conversion is called
#
our $digits16 = [ '0' .. '9', 'A' .. 'F' ];
our $digit16  = { map { ($digits16->[$_], $_) } (0 .. scalar(@$digits16) - 1) };

#  Initialize the contexts and make the creator function.
sub Init {
	my $context = $main::context{NondecimalBase} = Parser::Context->getCopy("Numeric");
	$context->{name} = 'NondecimalBase';
	$context->{parser}{Number} = 'context::NondecimalBase::Number';
	$context->{value}{Real} = 'context::NondecimalBase::Real';
	$context->{pattern}{number} = '[0-9A-F]+';
	$context->operators->set(
		'+' => { class => 'context::NondecimalBase::BOP::add'}
	);
	$context->functions->disable('All');
	# $context->operators->remove('^');
	$context->parens->remove('|');
	$context->constants->clear();
	$context->{precedence}{NondecimalBase} = $context->{precedence}{special};
	$context->flags->set(limits => [ -1000, 1000, 1 ]);
	$context->update;

	# main::PG_restricted_eval('sub Hex {context::Hex::Hex->new(@_)}');
}

sub setBase {
	my ($name, $base) = @_;
	print Dumper 'in setBase';
	print Dumper $name;
	my $context = $main::context{$name} = Parser::Context->getCopy($name);
	print Dumper $context;
	print Dumper $base;
}

sub convert {
	my $value = shift;
	# print Dumper 'in convert';
	# print Dumper $value;
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

	# print Dumper $from;
	# print Dumper $to;
	# print Dumper $digits;

	die "The digits option must be an array of characters to use for the digits"
		unless ref($digits) eq 'ARRAY';

	# The highest base the digits will support
	my $maxBase = scalar(@$digits);

	die "The base of conversion must be between 2 and $maxBase"
		unless $to >= 2 && $to <= $maxBase && $from >= 2 && $from <= $maxBase;

	# Reverse map the digits to base 10 values
	my $baseBdigits = { map { ($digits->[$_], $_) } (0 .. $from - 1) };

	#  Convert to base 10
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

	#  Convert to desired base
	my @base;
	do {
		my $d = $base10 % $to;
		$base10 = ($base10 - $d) / $to;
		unshift(@base, $digits->[$d]);
	} while $base10;

	return join('', @base);
}

#  A replacement for Parser::Number that acepts numbers in a NonDecimal base and converts them to decimal for internal use
package context::NondecimalBase::Number;
our @ISA = ('Parser::Number');

# Create a new number in the given base and convert to base 10.
use Data::Dumper;
sub new {
	my ($self, $equation, $value, $ref) = @_;
	my $base =  $equation->{context}{flags}{base};
	$value = context::NondecimalBase::convert($value, from => $base);
	return $self->SUPER::new($equation, $value, $ref);
}

#
#  Return the value of the number in its given base.
#
sub eval {
	$self = shift;
	my $base = $self->{equation}{context}{flags}{base};
	return context::NondecimalBase::convert($self->{value}, to => $base);
	$self->Package('Real')->make($self->context, $self->{value});
}

#  A replacement for Value::Real that handles non-decimal integers
package context::NondecimalBase::Real;
our @ISA = ('Value::Real');
use Data::Dumper;
#
#  Stringify and TeXify the number in the context's base
#
sub string {
	my $self = shift;
	my $base = $self->{context}{flags}{base};
	return context::NondecimalBase::convert($self->value, to => $base);
}

sub TeX {
	my $self = shift;
	my $base = $self->{context}{flags}{base};
	return '\text{' . context::NondecimalBase::convert($self->string, to => $base) . '}';
}

sub add {
	my ($self, $l, $r, $other) = Value::checkOpOrderWithPromote(@_);
	print Dumper 'in add';
}

use Data::Dumper;
package context::NondecimalBase::BOP::add;
our @ISA = ('Parser::BOP::add');
use Data::Dumper;
sub _eval {
	my ($self, $a, $b) = @_;
	print Dumper 'in _eval';
	my $base = $self->{equation}{context}{flags}{base};
	print Dumper context::NondecimalBase::convert($a, from => $base);
	print Dumper context::NondecimalBase::convert($b, from => $base);
	return context::NondecimalBase::convert(context::NondecimalBase::convert($a, from => $base) +
		context::NondecimalBase::convert($b, from => $base), to => $base);
}

#
sub _check {
	my $self = shift;
	print Dumper 'in _check';
	# $self->{equation}{context};
	$self->SUPER::_check;
}

1;
