package Rserve::Parser;

use strict;
use warnings;

use feature 'state';

use Exporter 'import';

our @EXPORT_OK = qw(
	endianness
	any_char
	char
	string
	any_uint8
	any_uint16
	any_uint24
	any_uint32
	any_real32
	any_real64
	any_real64_na
	uint8
	uint16
	uint24
	uint32
	any_int8
	any_int16
	any_int24
	any_int32
	any_int32_na
	int8
	int16
	int24
	int32
	count
	with_count
	many_till
	seq
	choose
	mreturn
	error
	bind
);

our %EXPORT_TAGS = (
	all  => [@EXPORT_OK],
	char => [qw(any_char char string)],
	num  => [ qw(
		any_uint8
		any_uint16
		any_uint24
		any_uint32
		any_real32
		any_real64
		any_real64_na
		uint8
		uint16
		uint24
		uint32
		any_int8
		any_int16
		any_int24
		any_int32
		any_int32_na
		int8
		int16
		int24
		int32
	) ],
	combinator => [qw(count with_count many_till seq choose mreturn bind)]
);

use Scalar::Util qw(looks_like_number);
use Carp         qw(croak);

sub endianness {
	my $new_value = shift;
	state $endianness = '>';
	return $endianness unless defined $new_value;
	return $endianness = $new_value =~ /^[<>]$/ && $new_value || $endianness;
}

sub any_char {
	my $state = shift;
	return if !$state || $state->eof;
	return [ $state->at, $state->next ];
}

sub char {
	my $arg = shift;
	die 'Must be a single-char argument: ' . $arg unless length($arg) == 1;

	return sub {
		my $state = shift or return;
		return if $state->eof || $arg ne $state->at;
		return [ $arg, $state->next ];
	}
}

sub string {
	my $arg = shift;
	die 'Must be a scalar argument: ' . $arg unless $arg && !ref($arg);
	my $chars = count(length($arg), \&any_char);

	return sub {
		my ($char_values, $state) = @{ $chars->(@_) or return };
		return unless join('', @$char_values) eq $arg;
		return [ $arg, $state ];
	}
}

sub any_uint8 {
	my $state = shift;
	(my $value, $state) = @{ any_char($state) or return };
	return [ unpack('C', $value), $state ];
}

sub any_uint16 {
	my $state = shift;
	(my $value, $state) = @{ count(2, \&any_uint8)->($state) or return };
	return [ unpack('S' . endianness, pack 'C2' => @$value), $state ];
}

sub any_uint24 {
	my $state = shift;
	(my $value, $state) = @{ count(3, \&any_uint8)->($state) or return };
	return [ unpack('L' . endianness, pack(endianness eq '>' ? 'xC3' : 'C3x', @$value)), $state ];
}

sub any_uint32 {
	my $state = shift;
	(my $value, $state) = @{ count(4, \&any_uint8)->($state) or return };
	return [ unpack('L' . endianness, pack 'C4' => @$value), $state ];
}

sub uint8 {
	my $arg = shift;
	die 'Argument must be a number 0-255: ' . $arg
		unless looks_like_number($arg) && $arg <= 0x000000FF && $arg >= 0;

	return sub {
		my ($value, $state) = @{ any_uint8 @_ or return };
		return unless $arg == $value;
		return [ $arg, $state ];
	}
}

sub uint16 {
	my $arg = shift;
	die 'Argument must be a number 0-65535: ' . $arg
		unless looks_like_number($arg) && $arg <= 0x0000FFFF && $arg >= 0;

	return sub {
		my ($value, $state) = @{ any_uint16 @_ or return };
		return unless $arg == $value;
		return [ $arg, $state ];
	}
}

sub uint24 {
	my $arg = shift;
	die 'Argument must be a number 0-16777215: ' . $arg
		unless looks_like_number($arg) && $arg <= 0x00FFFFFF && $arg >= 0;

	return sub {
		my ($value, $state) = @{ any_uint24 @_ or return };
		return unless $arg == $value;
		return [ $arg, $state ];
	}
}

sub uint32 {
	my $arg = shift;
	die 'Argument must be a number 0-4294967295: ' . $arg
		unless looks_like_number($arg) && $arg <= 0xFFFFFFFF && $arg >= 0;

	return sub {
		my ($value, $state) = @{ any_uint32 @_ or return };
		return unless $arg == $value;
		return [ $arg, $state ];
	}
}

sub any_int8 {
	my $state = shift;
	(my $value, $state) = @{ any_char($state) or return };
	return [ unpack('c', $value), $state ];
}

sub any_int16 {
	my $state = shift;
	(my $value, $state) = @{ any_uint16($state) or return };
	$value |= 0x8000 if ($value >= 1 << 15);
	return [ unpack('s', pack 's' => $value), $state ];
}

sub any_int24 {
	my $state = shift;
	(my $value, $state) = @{ any_uint24($state) or return };
	$value |= 0xff800000 if ($value >= 1 << 23);
	return [ unpack('l', pack 'l' => $value), $state ];
}

sub any_int32 {
	my $state = shift;
	(my $value, $state) = @{ any_uint32($state) or return };
	$value |= 0x80000000 if ($value >= 1 << 31);
	return [ unpack('l', pack 'l' => $value), $state ];
}

sub int8 {
	my $arg = shift;
	die 'Argument must be a number -128-127: ' . $arg
		unless looks_like_number($arg) && $arg < 1 << 7 && $arg >= -(1 << 7);

	return sub {
		my ($value, $state) = @{ any_int8 @_ or return };
		return unless $arg == $value;
		return [ $arg, $state ];
	}
}

sub int16 {
	my $arg = shift;
	die 'Argument must be a number -32768-32767: ' . $arg
		unless looks_like_number($arg) && $arg < 1 << 15 && $arg >= -(1 << 15);

	return sub {
		my ($value, $state) = @{ any_int16 @_ or return };
		return unless $arg == $value;
		return [ $arg, $state ];
	}
}

sub int24 {
	my $arg = shift;
	die 'Argument must be a number 0-16777215: ' . $arg
		unless looks_like_number($arg) && $arg < 1 << 23 && $arg >= -(1 << 23);

	return sub {
		my ($value, $state) = @{ any_int24 @_ or return };
		return unless $arg == $value;
		return [ $arg, $state ];
	}
}

sub int32 {
	my $arg = shift;
	die 'Argument must be a number -2147483648-2147483647: ' . $arg
		unless looks_like_number($arg) && $arg < 1 << 31 && $arg >= -(1 << 31);

	return sub {
		my ($value, $state) = @{ any_int32 @_ or return };
		return unless $arg == $value;
		return [ $arg, $state ];
	}
}

sub any_int32_na {
	return choose(Rserve::Parser::bind(int32(-2147483648), sub { mreturn(undef); }), \&any_int32);
}

my %na_real = (
	'>' => [ uint32(0x7ff00000), uint32(0x7a2) ],
	'<' => [ uint32(0x7a2),      uint32(0x7ff00000) ]
);

sub any_real64_na {
	return choose(Rserve::Parser::bind(seq(@{ $na_real{ endianness() } }), sub { mreturn(undef); }), \&any_real64);
}

sub any_real32 {
	my $state = shift;
	(my $value, $state) = @{ count(4, \&any_uint8)->($state) or return };
	return [ unpack('f' . endianness, pack 'C4' => @$value), $state ];
}

sub any_real64 {
	my $state = shift;
	(my $value, $state) = @{ count(8, \&any_uint8)->($state) or return };
	return [ unpack('d' . endianness, pack 'C8' => @$value), $state ];
}

sub count {
	my ($n, $parser) = @_;
	return sub {
		my $state = shift;
		my @value;

		for (1 .. $n) {
			my $result = $parser->($state) or return;

			push @value, shift @$result;
			$state = shift @$result;
		}

		return [ [@value], $state ];
	}
}

sub seq {
	my @parsers = @_;

	return sub {
		my $state = shift;
		my @value;

		for my $parser (@parsers) {
			my $result = $parser->($state) or return;

			push @value, shift @$result;
			$state = shift @$result;
		}

		return [ [@value], $state ];
	}
}

sub many_till {
	my ($p, $end) = @_;
	die q{'bind' expects two arguments} unless $p && $end;

	return sub {
		my $state = shift or return;
		my @value;

		until ($end->($state)) {
			my $result = $p->($state) or return;

			push @value, shift @$result;
			$state = shift @$result;
		}

		return [ [@value], $state ];
	}
}

sub choose {
	my @parsers = @_;

	return sub {
		my $state = shift or return;

		for my $parser (@parsers) {
			my $result = $parser->($state);
			return $result if $result;
		}

		return;
	}
}

sub mreturn {
	my $arg = shift;
	return sub { return [ $arg, shift ] }
}

sub error {
	my $message = shift;
	return sub { my $state = shift; croak $message . ' (at ' . $state->position . ')'; }
}

sub bind {
	my ($p1, $fp2) = @_;
	die q{'bind' expects two arguments} unless $p1 && $fp2;

	return sub {
		my $v1 = $p1->(shift or return);
		my ($value, $state) = @{ $v1 or return };
		return $fp2->($value)->($state);
	}
}

sub with_count {
	my @args = @_;
	die q{'bind' expects one or two arguments} unless @args && @args <= 2;
	unshift(@args, \&any_uint32) if @args == 1;
	my ($counter, $content) = @args;

	return Rserve::Parser::bind($counter, sub { my $n = shift; count($n, $content); });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Rserve::Parser - Functions for parsing R data files

=head1 SYNOPSIS

    use Rserve::ParserState;
    use Rserve::Parser;

    my $state = Rserve::ParserState->new(
        data => 'file.rds'
    );
    say $state->at
    say $state->next->at;

=head1 DESCRIPTION

You shouldn't create instances of this class, it exists mainly to handle
deserialization of R data files.

=head1 FUNCTIONS

This library is inspired by monadic parser frameworks from the Haskell world,
like L<Packrat|http://bford.info/packrat/> or
L<Parsec|http://hackage.haskell.org/package/parsec>. What this means is that
I<parsers> are constructed by combining simpler parsers.

The library offers a selection of basic parsers and combinators.  Each of these
is a function (think of it as a factory) that returns another function (the
actual parser) which receives the current parsing state (L<Rserve::ParserState>)
as the argument and returns a two-element array reference (called for brevity "a
pair" in the following text) with the result of the parser in the first element
and the new parser state in the second element. If the I<parser> fails, say if
the current state is "a" where a number is expected, it returns C<undef> to
signal failure.

The descriptions of individual functions below use a shorthand because the above
mechanism is implied. Thus, when C<any_char> is described as "parses any
character", it really means that calling C<any_char> will return a function that
when called with the current state will return "a pair of the character...",
etc.

=head2 CHARACTER PARSERS

=head3 any_char

Parses any character, returning a pair of the character at the current State's
position and the new state, advanced by one from the starting state. If the
state is at the end (C<$state->eof> is true), returns undef to signal failure.

=head3 char

    char($c)

Parses the given character C<$c>, returning a pair of the character at the
current State's position if it is equal to C<$c> and the new state, advanced by
one from the starting state. If the state is at the end (C<$state->eof> is true)
or the character at the current position is not C<$c>, returns undef to signal
failure.

=head3 string

    string($s)

Parses the given string C<$s>, returning a pair of the sequence of characters
starting at the current State's position if it is equal to C<$s> and the new
state, advanced by C<length($s)> from the starting state. If the state is at the
end (C<$state->eof> is true) or the string starting at the current position is
not C<$s>, returns undef to signal failure.

=head2 NUMBER PARSERS

=head3 endianness

    endianness($end)

The C<$end> argument is optional and if given, this function sets the byte order
used by parsers in the module to be little-endian if C<$end> is "E<lt>" or
big-endian if C<$end> is "E<gt>". This function changes the module's state
and remains in effect until the next change.

When called with no arguments, C<endianness> returns the current byte order in
effect. The starting byte order is big-endian.

=head3 any_uint8

=head3 any_uint16

=head3 any_uint24

=head3 any_uint32

Parses an 8-, 16-, 24-, or 32-bit I<unsigned> integer, returning a pair of the
integer starting at the current State's position and the new state, advanced by
1, 2, 3, or 4 bytes from the starting state, depending on the parser. The
integer value is determined by the current value of C<endianness>. If there are
not enough elements left in the data from the current position, returns undef to
signal failure.

=head3 uint8

=head3 uint16

=head3 uint24

=head3 uint32

    uint8($n)
    uint16($n)
    uint24($n)
    uint32($n)

Parses the specified 8-, 16-, 24-, and 32-bit I<unsigned> integer C<$n>,
returning a pair of the integer at the current State's position if it is equal
C<$n> and the new state. The new state is advanced by 1, 2, 3, or 4 bytes from
the starting state, depending on the parser. The integer value is determined by
the current value of C<endianness>. If there are not enough elements left in the
data from the current position or the current position is not C<$n>, returns
undef to signal failure.

=head3 any_int8

=head3 any_int16

=head3 any_int24

=head3 any_int32

Parses an 8-, 16-, 24-, and 32-bit I<signed> integer, returning a pair of the
integer starting at the current State's position and the new state, advanced by
1, 2, 3, or 4 bytes from the starting state, depending on the parser. The
integer value is determined by the current value of C<endianness>. If there are
not enough elements left in the data from the current position, returns undef to
signal failure.

=head3 int8

=head3 int16

=head3 int24

=head3 int32

    int8($n)
    int16($n)
    int24($n)
    int32($n)

Parses the specified 8-, 16-, 24-, and 32-bit I<signed> integer C<$n>, returning
a pair of the integer at the current State's position if it is equal C<$n> and
the new state. The new state is advanced by 1, 2, 3, or 4 bytes from the
starting state, depending on the parser. The integer value is determined by the
current value of C<endianness>. If there are not enough elements left in the
data from the current position or the current position is not C<$n>, returns
undef to signal failure.

=head3 any_real32

=head3 any_real64

Parses an 32- or 64-bit real number, returning a pair of the number starting at
the current State's position and the new state, advanced by 4 or 8 bytes from
the starting state, depending on the parser. The real value is determined by the
current value of C<endianness>. If there are not enough elements left in the
data from the current position, returns undef to signal failure.

=head3 any_int32_na

=head3 any_real64_na

Parses a 32-bit I<signed> integer or 64-bit real number, respectively, but
recognizing R-style missing values (NAs): INT_MIN for integers and a special NaN
bit pattern for reals. Returns a pair of the number value (C<undef> if a NA) and
the new state, advanced by 4 or 8 bytes from the starting state, depending on
the parser. If there are not enough elements left in the data from the current
position, returns undef to signal failure.

=head2 SEQUENCING

=head3 seq

    seq($p1, $p2, ...)

This combinator applies parsers C<$p1>, C<$p2>, ... in sequence, using the
returned parse state of C<$p1> as the input parse state to C<$p2>, etc.  Returns
a pair of the concatenation of all the parsers' results and the parsing state
returned by the final parser. If any of the parsers returns undef, C<seq> will
return it immediately without attempting to apply any further parsers.

=head3 many_till

    many_till($p, $end)

This combinator applies a parser C<$p> until parser C<$end> succeeds.  It does
this by alternating applications of C<$end> and C<$p>; once C<$end> succeeds,
the function returns the concatenation of results of preceding applications of
C<$p>. (Thus, if C<$end> succeeds immediately, the 'result' is an empty list.)
Otherwise, C<$p> is applied and must succeed, and the procedure repeats. Returns
a pair of the concatenation of all the C<$p>'s results and the parsing state
returned by the final parser. If any applications of C<$p> returns undef,
C<many_till> will return it immediately.

=head3 count

    count($n, $p)

This combinator applies the parser C<$p> exactly C<$n> times in sequence,
threading the parse state through each call.  Returns a pair of the
concatenation of all the parsers' results and the parsing state returned by the
final application. If any application of C<$p> returns undef, C<count> will
return it immediately without attempting any more applications.

=head3 with_count

    with_count($num_p, $p)
    with_count($p)

This combinator first applies parser C<$num_p> to get the number of times that
C<$p> should be applied in sequence. If only one argument is given,
C<any_uint32> is used as the default value of C<$num_p>.  (So C<with_count>
works by getting a number I<$n> by applying C<$num_p> and then calling C<count
$n, $p>.) Returns a pair of the concatenation of all the parsers' results and
the parsing state returned by the final application. If the initial application
of C<$num_p> or any application of C<$p> returns undef, C<with_count> will
return it immediately without attempting any more applications.

=head3 choose

    choose($p1, $p2, ...)

This combinator applies parsers C<$p1>, C<$p2>, ... in sequence, until one of
them succeeds, when it immediately returns the parser's result.  If all of the
parsers fail, C<choose> fails and returns undef.

=head2 COMBINATORS

=head3 bind

    bind($p1, $f)

This combinator applies parser C<$p1> and, if it succeeds, calls function C<$f>
using the first element of C<$p1>'s result as the argument. The call to C<$f>
needs to return a parser, which C<bind> applies to the parsing state after
C<$p1>'s application.

The C<bind> combinator is an essential building block for most combinators
described so far. For instance, C<with_count> can be written as:

    bind($num_p,
         sub {
             my $n = shift;
             count $n, $p;
         })

=head3 mreturn

    mreturn($value)

Returns a parser that when applied returns C<$value> without changing the
parsing state.

=head3 error

    error($message)

Returns a parser that when applied croaks with the C<$message> and the current
parsing state.

=cut
