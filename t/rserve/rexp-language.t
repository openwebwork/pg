#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
use lib "$ENV{PG_ROOT}/lib";

use Rserve::REXP::Language;
use Rserve::REXP::Character;
use Rserve::REXP::Double;
use Rserve::REXP::Integer;
use Rserve::REXP::List;
use Rserve::REXP::Symbol;

ok my $language = Rserve::REXP::Language->new(elements => [ Rserve::REXP::Symbol->new('foo'), 4, 11.2 ]),
	'new language';
isa_ok $language, [ 'Rserve::REXP::Language', 'Rserve::REXP::List', 'Rserve::REXP::Vector', 'Rserve::REXP' ],
	'language has correct classes';

my $language2 = Rserve::REXP::Language->new([ Rserve::REXP::Symbol->new('foo'), 4, 11.2 ]);
is($language, $language2, 'language equality');

is(Rserve::REXP::Language->new($language2), $language, 'copy constructor');
is(Rserve::REXP::Language->new(Rserve::REXP::List->new([ Rserve::REXP::Symbol->new('foo'), 4, 11.2 ])),
	$language, 'copy constructor from a vector');

# error checking in constructor arguments
like(
	dies {
		Rserve::REXP::Language->new
	},
	qr/The first element must be a Symbol or Language/,
	'error-check in no-arg constructor'
);
like(
	dies {
		Rserve::REXP::Language->new(elements => [])
	},
	qr/The first element must be a Symbol or Language/,
	'error-check in empty vec constructor'
);
like(
	dies {
		Rserve::REXP::Language->new(sub { 1 + 1 })
	},
	qr/Attribute 'elements' must be an array reference/,
	'error-check in single-arg constructor'
);
like(
	dies {
		Rserve::REXP::Language->new(1, 2, 3)
	},
	qr/odd number of arguments/,
	'odd constructor arguments'
);
like(
	dies {
		Rserve::REXP::Language->new([ { foo => 1, bar => 2 } ])
	},
	qr/The first element must be a Symbol or Language/,
	'bad call argument'
);
like(
	dies {
		Rserve::REXP::Language->new(elements => { foo => 1, bar => 2 })
	},
	qr/Attribute 'elements' must be an array reference/,
	'bad elements argument'
);

my $another_language = Rserve::REXP::Language->new([ Rserve::REXP::Symbol->new('bla'), 4, 11.2 ]);
isnt($language, $another_language, 'language inequality');

my $na_heavy_language =
	Rserve::REXP::Language->new(elements => [ Rserve::REXP::Symbol->new('bla'), [ '', undef ], '0' ]);
my $na_heavy_language2 =
	Rserve::REXP::Language->new(elements => [ Rserve::REXP::Symbol->new('bla'), [ undef, undef ], 0 ]);
is($na_heavy_language, $na_heavy_language, 'NA-heavy language equality');
isnt($na_heavy_language, $na_heavy_language2, 'NA-heavy language inequality');

is($language . '', 'language(symbol `foo`, 4, 11.2)', 'language text representation');
is(
	Rserve::REXP::Language->new(elements => [ Rserve::REXP::Symbol->new('foo'), undef ]) . '',
	'language(symbol `foo`, undef)',
	'text representation of a singleton NA'
);
is(
	Rserve::REXP::Language->new(elements => [ Rserve::REXP::Symbol->new('bar'), [ [undef] ] ]) . '',
	'language(symbol `bar`, [[undef]])',
	'text representation of a nested singleton NA'
);
is($na_heavy_language . '', 'language(symbol `bla`, [, undef], 0)', 'empty string representation');

is($language->elements,      [ Rserve::REXP::Symbol->new('foo'), 4, 11.2 ], 'language contents');
is($language->elements->[2], 11.2,                                          'single element access');

is(
	Rserve::REXP::Language->new(elements => [ Rserve::REXP::Symbol->new('baz'), 4.0, '3x', 11 ])->elements,
	[ Rserve::REXP::Symbol->new('baz'), 4, '3x', 11 ],
	'constructor with non-numeric values'
);

my $nested_language =
	Rserve::REXP::Language->new(elements => [ Rserve::REXP::Symbol->new('qux'), 4.0, [ 'b', [ 'cc', 44.1 ] ], 11 ]);
is(
	$nested_language->elements,
	[ Rserve::REXP::Symbol->new('qux'), 4, [ 'b', [ 'cc', 44.1 ] ], 11 ],
	'nested language contents'
);
is($nested_language->elements->[2]->[1], [ 'cc', 44.1 ], 'nested element');
is($nested_language->elements->[3],      11,             'non-nested element');

is($nested_language . '', 'language(symbol `qux`, 4, [b, [cc, 44.1]], 11)', 'nested language text representation');

my $nested_rexps = Rserve::REXP::Language->new([
	Rserve::REXP::Symbol->new('quux'),
	Rserve::REXP::Integer->new([ 1, 2, 3 ]),
	Rserve::REXP::Language->new([
		Rserve::REXP::Symbol->new('a'), Rserve::REXP::Character->new(['b']), Rserve::REXP::Double->new([11]) ]),
	Rserve::REXP::Character->new(['foo'])
]);

is(
	$nested_rexps . '',
	'language(symbol `quux`, integer(1, 2, 3), language(symbol `a`, character(b), double(11)), character(foo))',
	'nested language of REXPs text representation'
);

ok(!$language->is_null,  'is not null');
ok($language->is_vector, 'is vector');

# attributes
is($language->attributes, undef, 'default attributes');

my $language_attr = Rserve::REXP::Language->new(
	elements   => [ Rserve::REXP::Symbol->new('fred'), 3.3, '4', 11 ],
	attributes => {
		foo => 'bar',
		x   => [ 40, 41, 42 ]
	}
);
is($language_attr->attributes, { foo => 'bar', x => [ 40, 41, 42 ] }, 'constructed attributes');

my $language_attr2 = Rserve::REXP::Language->new(
	elements   => [ Rserve::REXP::Symbol->new('fred'), 3.3, '4', 11 ],
	attributes => {
		foo => 'bar',
		x   => [ 40, 41, 42 ]
	}
);
my $another_language_attr = Rserve::REXP::Language->new(
	elements   => [ Rserve::REXP::Symbol->new('fred'), 3.3, '4', 11 ],
	attributes => {
		foo => 'bar',
		x   => [ 40, 42, 42 ]
	}
);
is($language_attr, $language_attr2, 'equality considers attributes');
isnt($language_attr, $language,              'inequality considers attributes');
isnt($language_attr, $another_language_attr, 'inequality considers attributes deeply');

# attributes must be a hash
like(
	dies {
		Rserve::REXP::Language->new(
			elements   => [ Rserve::REXP::Symbol->new('foo') ],
			attributes => 1
		)
	},
	qr/Attribute 'attributes' must be a hash reference/,
	'setting non-HASH attributes'
);

# Perl representation
is($language->to_perl, [ 'foo', 4, 11.2 ], 'Perl representation');

is($na_heavy_language->to_perl, [ 'bla', [ '', undef ], '0' ], 'language with NAs Perl representation');

is($nested_language->to_perl, [ 'qux', 4.0, [ 'b', [ 'cc', 44.1 ] ], 11 ], 'nested languages Perl representation');

is(
	$nested_rexps->to_perl,
	[ 'quux', [ 1, 2, 3 ], [ 'a', ['b'], [11] ], ['foo'] ],
	'language with nested REXPs Perl representation'
);

done_testing;
