#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0 '!string';

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
use lib "$ENV{PG_ROOT}/lib";

use Rserve::Parser qw(:all);
use Rserve::ParserState;

my $state = Rserve::ParserState->new(data => 'foobar');

subtest 'characters' => sub {
	# any_char parser
	is(any_char($state), [ 'f', Rserve::ParserState->new(data => 'foobar', position => 1) ], 'any_char');
	is(any_char($state->next->next->next->next->next->next), undef,                          'any_char at eof');

	# char parser
	my $f_char = char('f');

	is($f_char->($state), [ 'f', Rserve::ParserState->new(data => 'foobar', position => 1) ], 'char');
	is($f_char->($state->next),                               undef,                          'char doesn\'t match');
	is($f_char->($state->next->next->next->next->next->next), undef,                          'char at eof');
	like(dies { char('foo') }, qr/Must be a single-char argument/, "bad 'char' argument");

	# string parser
	my $foo_string = string('foo');

	is($foo_string->($state), [ 'foo', Rserve::ParserState->new(data => 'foobar', position => 3) ], 'string');
	is($foo_string->($state->next),                               undef, 'string doesn\'t match');
	is($foo_string->($state->next->next->next->next->next->next), undef, 'string at eof');
	like(dies { string(['foo']) }, qr/Must be a scalar argument/, "bad 'string' argument");
};

subtest 'int parsers' => sub {
	# any_uint
	my $num_state = Rserve::ParserState->new(data => pack('N', 0x12345678));
	is(any_uint8($num_state)->[0],                 0x12, 'any_uint8');
	is(any_uint8(any_uint8($num_state)->[1])->[0], 0x34, 'second any_uint8');

	is(any_uint16($num_state)->[0],                  0x1234, 'any_uint16');
	is(any_uint16(any_uint16($num_state)->[1])->[0], 0x5678, 'second any_uint16');

	is(any_uint24($num_state)->[0],             0x123456, 'any_uint24');
	is(any_uint24(any_uint24($num_state)->[1]), undef,    'second any_uint24');

	is(any_uint32($num_state)->[0],             0x12345678, 'any_uint32');
	is(any_uint32(any_uint32($num_state)->[1]), undef,      'second any_uint32');

	# uint
	is(uint8(0x12)->($num_state)->[0],                     0x12,  'uint8');
	is(uint8(0x34)->(uint8(0x12)->($num_state)->[1])->[0], 0x34,  'second uint8');
	is(uint8(0x10)->($num_state),                          undef, 'uint8 fails');

	is(uint16(0x1234)->($num_state)->[0],                        0x1234, 'uint16');
	is(uint16(0x5678)->(uint16(0x1234)->($num_state)->[1])->[0], 0x5678, 'second uint16');
	is(uint16(0x1010)->($num_state),                             undef,  'uint16 fails');

	is(uint24(0x123456)->($num_state)->[0],                 0x123456, 'uint24');
	is(uint24(0x78)->(uint24(0x123456)->($num_state)->[1]), undef,    'second uint24');
	is(uint24(0x1010)->($num_state),                        undef,    'uint24 fails');

	is(uint32(0x12345678)->($num_state)->[0],              0x12345678, 'uint32');
	is(uint32(0)->(uint32(0x12345678)->($num_state)->[1]), undef,      'second uint32');
	is(uint32(0x1010)->($num_state),                       undef,      'uint32 fails');
};

subtest 'signed int parsers' => sub {
	my $signed_num_state = Rserve::ParserState->new(data => pack('N', 0x12bacafe));

	# any_int
	is(any_int8($signed_num_state)->[0],             0x12, 'any_int8');
	is(any_int8($signed_num_state->next->next)->[0], -54,  'negative any_int8');

	is(any_int16($signed_num_state)->[0],             0x12ba, 'any_int16');
	is(any_int16($signed_num_state->next->next)->[0], -13570, 'negative any_int16');

	is(any_int24($signed_num_state)->[0],       0x12baca, 'any_int24');
	is(any_int24($signed_num_state->next)->[0], -4535554, 'negative any_int24');

	is(any_int32($signed_num_state)->[0],                                        0x12bacafe, 'any_int32');
	is(any_int32(Rserve::ParserState->new(data => pack('N', 0xbabecafe)))->[0], -1161901314, 'negative any_int32');
	is(any_int32(any_int32($signed_num_state)->[1]),                            undef,       'failed any_int32');

	# int
	is(int8(0x12)->($signed_num_state)->[0],                           0x12, 'int8');
	is(int8(unpack c => "\xca")->($signed_num_state->next->next)->[0], -54,  'negative int8');

	is(int16(0x12ba)->($signed_num_state)->[0],                                0x12ba, 'int16');
	is(int16(unpack 's>' => "\xca\xfe")->($signed_num_state->next->next)->[0], -13570, 'negative any_int16');

	is(int24(0x12baca)->($signed_num_state)->[0],                                0x12baca, 'int24');
	is(int24(unpack 'l>' => "\xff\xba\xca\xfe")->($signed_num_state->next)->[0], -4535554, 'negative int24');

	is(int32(0x12bacafe)->($signed_num_state)->[0], 0x12bacafe, 'int32');
	is(int32(unpack 'l>' => "\xba\xbe\xca\xfe")->(Rserve::ParserState->new(data => pack('N', 0xbabecafe)))->[0],
		-1161901314, 'negative int32');
	is(int32(0x00bacafe)->($signed_num_state->next), undef, 'failed int32');
};

subtest 'floating point parsers' => sub {
	is(any_real32(Rserve::ParserState->new(data => "\x45\xcc\x79\0"))->[0], 6543.125, 'any_real32');

	is(any_real64(Rserve::ParserState->new(data => "\x40\x93\x4a\x45\x6d\x5c\xfa\xad"))->[0],
		unpack('d', pack('d', 1234.5678)), 'any_real64');
};

subtest 'NAs' => sub {
	my $signed_num_state = Rserve::ParserState->new(data => pack('N', 0x12bacafe));

	is(any_int32_na->($signed_num_state)->[0], 0x12bacafe, 'any_int32_na');

	my $int_na = Rserve::ParserState->new(data => "\x80\0\0\0");
	is(any_int32_na->($int_na)->[0], undef, 'int NA');

	is(
		any_real64_na->(Rserve::ParserState->new(data => "\x40\x93\x4a\x45\x6d\x5c\xfa\xad"))->[0],
		unpack('d', pack('d', 1234.5678)),
		'any_real64_na'
	);

	my $real_na = Rserve::ParserState->new(data => "\x7f\xf0\0\0\0\0\7\xa2");
	is(any_real64_na->($real_na)->[0], undef, 'real NA');
};

subtest 'endianness' => sub {
	is(endianness,        '>', 'get endianness');
	is(endianness('<'),   '<', 'set endianness');
	is(endianness('bla'), '<', 'ignore bad endianness value');

	my $num_state = Rserve::ParserState->new(data => pack('N', 0x12345678));

	is(any_uint16($num_state)->[0],                  0x3412, 'any_uint16 little endian');
	is(any_uint16(any_uint16($num_state)->[1])->[0], 0x7856, 'second any_uint16 little endian');

	is(any_uint24($num_state)->[0],             0x563412, 'any_uint24 little endian');
	is(any_uint24(any_uint24($num_state)->[1]), undef,    'second any_uint24 little endian');

	is(any_uint32($num_state)->[0],             0x78563412, 'any_uint32 little endian');
	is(any_uint32(any_uint32($num_state)->[1]), undef,      'second any_uint32 little endian');

	# little-endian uint's
	is(uint8(0x12)->($num_state)->[0],                     0x12,  'little-endian uint8');
	is(uint8(0x34)->(uint8(0x12)->($num_state)->[1])->[0], 0x34,  'second little-endian uint8');
	is(uint8(0x10)->($num_state),                          undef, 'little-endian uint8 fails');

	is(uint16(0x3412)->($num_state)->[0],                        0x3412, 'little-endian uint16');
	is(uint16(0x7856)->(uint16(0x3412)->($num_state)->[1])->[0], 0x7856, 'second little-endian uint16');
	is(uint16(0x1010)->($num_state),                             undef,  'little-endian uint16 fails');

	is(uint24(0x563412)->($num_state)->[0],                 0x563412, 'little-endian uint24');
	is(uint24(0x78)->(uint24(0x563412)->($num_state)->[1]), undef,    'second little-endian uint24');
	is(uint24(0x1010)->($num_state),                        undef,    'little-endian uint24 fails');

	is(uint32(0x78563412)->($num_state)->[0],              0x78563412, 'little-endian uint32');
	is(uint32(0)->(uint32(0x78563412)->($num_state)->[1]), undef,      'second little-endian uint32');
	is(uint32(0x1010)->($num_state),                       undef,      'little-endian uint32 fails');

	is(any_real32(Rserve::ParserState->new(data => "\0\x79\xcc\x45"))->[0], 6543.125, 'any_real32 little endian');

	is(
		any_real64(Rserve::ParserState->new(data => "\xad\xfa\x5c\x6d\x45\x4a\x93\x40"))->[0],
		unpack('d', pack('d', 1234.5678)),
		'any_real64 little endian'
	);
};

subtest 'monad' => sub {
	# mreturn
	is(mreturn('foobar')->($state), [ 'foobar', $state ], 'mreturn');

	# bind
	my $len_chars_bind = bind(\&any_uint8, sub { my $n = shift or return; count($n, \&any_uint8); });
	is($len_chars_bind->(Rserve::ParserState->new(data => "\3\x2a\7\0"))->[0], [ 42, 7, 0 ], 'bind');
	is($len_chars_bind->(Rserve::ParserState->new(data => "\3\x2a\7")),        undef,        'bind fails');

	# error
	like(dies { error('foobar-ed')->($state->next) }, qr/foobar-ed \(at 1\)/, 'error');
};

subtest 'combinators' => sub {
	# seq
	my $f_oob_seq = seq(char('f'), string('oob'));
	is($f_oob_seq->($state), [ [ 'f', 'oob' ], Rserve::ParserState->new(data => 'foobar', position => 4) ], 'seq');
	is($f_oob_seq->($state->next), undef, 'seq fails');

	# many_till
	my $many_o_till_b = many_till(char('o'), char('b'));
	is($many_o_till_b->($state->next),
		[ [ 'o', 'o' ], Rserve::ParserState->new(data => 'foobar', position => 3) ], 'many_till');
	is($many_o_till_b->($state), undef, 'many_till fails');

	# choose
	my $f_oob_choose = choose(char('f'), string('oob'), char('o'));
	is($f_oob_choose->($state), [ 'f', Rserve::ParserState->new(data => 'foobar', position => 1) ], 'seq first');
	is(
		$f_oob_choose->($state->next),
		[ 'oob', Rserve::ParserState->new(data => 'foobar', position => 4) ],
		'seq second'
	);
	is($f_oob_choose->($state->next->next->next), undef, 'choose fails');

	# count
	is(
		count(3, \&any_char)->($state),
		[ [ 'f', 'o', 'o' ], Rserve::ParserState->new(data => 'foobar', position => 3) ],
		'count 3 any_char'
	);

	is(
		count(0, \&any_char)->($state),
		[ [], Rserve::ParserState->new(data => 'foobar', position => 0) ],
		'count 0 any_char'
	);

	is(count(7, \&any_char)->($state), undef, 'count fails');

	# with_count
	endianness('>');
	is(with_count(\&any_uint8, \&any_uint8)->(Rserve::ParserState->new(data => "\3\x2a\7\0"))->[0],
		[ 42, 7, 0 ], 'with_count');

	is(
		with_count(\&any_real64)->(Rserve::ParserState->new(data => "\0\0\0\1\x40\x93\x4a\x3d\x70\xa3\xd7\x0a"))
			->[0],
		[ unpack('d', pack('d', 1234.56)) ],
		'with_count default counter'
	);

	is(with_count(\&any_uint)->(Rserve::ParserState->new(data => "\0\0\0\0"))->[0], [], 'with_count zero counter');

	is(with_count(\&any_uint8, \&any_uint8)->(Rserve::ParserState->new(data => "\3\x2a\7")),
		undef, 'with_count fails');
};

done_testing;
