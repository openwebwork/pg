#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
use lib "$ENV{PG_ROOT}/lib";

use Rserve::REXP::Expression;
use Rserve::REXP::Language;
use Rserve::REXP::Character;
use Rserve::REXP::Double;
use Rserve::REXP::Integer;
use Rserve::REXP::List;
use Rserve::REXP::Symbol;

ok my $empty_expression = Rserve::REXP::Expression->new, 'new expression';
isa_ok $empty_expression,
	[ 'Rserve::REXP::Expression', 'Rserve::REXP::List', 'Rserve::REXP::Vector', 'Rserve::REXP' ],
	'expression has correct classes';

is($empty_expression, $empty_expression, 'self equality');

my $empty_expression_2 = Rserve::REXP::Expression->new;
is($empty_expression, $empty_expression_2, 'empty expression equality');

my $expression  = Rserve::REXP::Expression->new(elements => [ Rserve::REXP::Symbol->new('foo'), 4, 11.2 ]);
my $expression2 = Rserve::REXP::Expression->new([ Rserve::REXP::Symbol->new('foo'), 4, 11.2 ]);
is($expression, $expression2, 'expression equality');

is(Rserve::REXP::Expression->new($expression2), $expression, 'copy constructor');
is(Rserve::REXP::Expression->new(Rserve::REXP::List->new([ Rserve::REXP::Symbol->new('foo'), 4, 11.2 ])),
	$expression, 'copy constructor from a vector');

# error checking in constructor arguments
like(
	dies {
		Rserve::REXP::Expression->new(sub { 1 + 1 })
	},
	qr/Attribute 'elements' must be an array reference/,
	'error-check in single-arg constructor'
);
like(
	dies {
		Rserve::REXP::Expression->new(1, 2, 3)
	},
	qr/odd number of arguments/,
	'odd constructor arguments'
);
like(
	dies {
		Rserve::REXP::Expression->new(elements => { foo => 1, bar => 2 })
	},
	qr/Attribute 'elements' must be an array reference/,
	'bad elements argument'
);

my $another_expression = Rserve::REXP::Expression->new([ Rserve::REXP::Symbol->new('bla'), 4, 11.2 ]);
isnt($expression, $another_expression, 'expression inequality');

my $na_heavy_expression =
	Rserve::REXP::Expression->new(elements => [ Rserve::REXP::Symbol->new('bla'), [ '', undef ], '0' ]);
my $na_heavy_expression2 =
	Rserve::REXP::Expression->new(elements => [ Rserve::REXP::Symbol->new('bla'), [ undef, undef ], 0 ]);
is($na_heavy_expression, $na_heavy_expression, 'NA-heavy expression equality');
isnt($na_heavy_expression, $na_heavy_expression2, 'NA-heavy expression inequality');

is($expression . '', 'expression(symbol `foo`, 4, 11.2)', 'expression text representation');
is(
	Rserve::REXP::Expression->new(elements => [ Rserve::REXP::Symbol->new('foo'), undef ]) . '',
	'expression(symbol `foo`, undef)',
	'text representation of a singleton NA'
);
is(
	Rserve::REXP::Expression->new(elements => [ Rserve::REXP::Symbol->new('bar'), [ [undef] ] ]) . '',
	'expression(symbol `bar`, [[undef]])',
	'text representation of a nested singleton NA'
);
is($na_heavy_expression . '', 'expression(symbol `bla`, [, undef], 0)', 'empty string representation');

is($expression->elements,      [ Rserve::REXP::Symbol->new('foo'), 4, 11.2 ], 'expression contents');
is($expression->elements->[2], 11.2,                                          'single element access');

is(
	Rserve::REXP::Expression->new(elements => [ Rserve::REXP::Symbol->new('baz'), 4.0, '3x', 11 ])->elements,
	[ Rserve::REXP::Symbol->new('baz'), 4, '3x', 11 ],
	'constructor with non-numeric values'
);

my $nested_expression =
	Rserve::REXP::Expression->new(elements => [ Rserve::REXP::Symbol->new('qux'), 4.0, [ 'b', [ 'cc', 44.1 ] ], 11 ]);
is(
	$nested_expression->elements,
	[ Rserve::REXP::Symbol->new('qux'), 4, [ 'b', [ 'cc', 44.1 ] ], 11 ],
	'nested expression contents'
);
is($nested_expression->elements->[2]->[1], [ 'cc', 44.1 ], 'nested element');
is($nested_expression->elements->[3],      11,             'non-nested element');

is($nested_expression . '', 'expression(symbol `qux`, 4, [b, [cc, 44.1]], 11)',
	'nested expression text representation');

my $nested_rexps = Rserve::REXP::Expression->new([
	Rserve::REXP::Symbol->new('quux'),
	Rserve::REXP::Integer->new([ 1, 2, 3 ]),
	Rserve::REXP::Language->new([
		Rserve::REXP::Symbol->new('a'), Rserve::REXP::Character->new(['b']), Rserve::REXP::Double->new([11]) ]),
	Rserve::REXP::Character->new(['foo'])
]);

is(
	$nested_rexps . '',
	'expression(symbol `quux`, integer(1, 2, 3), language(symbol `a`, character(b), double(11)), character(foo))',
	'nested expression of REXPs text representation'
);

ok(!$expression->is_null,  'is not null');
ok($expression->is_vector, 'is vector');

# attributes
is($expression->attributes, undef, 'default attributes');

my $expression_attr = Rserve::REXP::Expression->new(
	elements   => [ Rserve::REXP::Symbol->new('fred'), 3.3, '4', 11 ],
	attributes => {
		foo => 'bar',
		x   => [ 40, 41, 42 ]
	}
);
is($expression_attr->attributes, { foo => 'bar', x => [ 40, 41, 42 ] }, 'constructed attributes');

my $expression_attr2 = Rserve::REXP::Expression->new(
	elements   => [ Rserve::REXP::Symbol->new('fred'), 3.3, '4', 11 ],
	attributes => {
		foo => 'bar',
		x   => [ 40, 41, 42 ]
	}
);
my $another_expression_attr = Rserve::REXP::Expression->new(
	elements   => [ Rserve::REXP::Symbol->new('fred'), 3.3, '4', 11 ],
	attributes => {
		foo => 'bar',
		x   => [ 40, 42, 42 ]
	}
);
is($expression_attr, $expression_attr2, 'equality considers attributes');
isnt($expression_attr, $expression,              'inequality considers attributes');
isnt($expression_attr, $another_expression_attr, 'inequality considers attributes deeply');

# attributes must be a hash
like(
	dies {
		Rserve::REXP::Expression->new(
			elements   => [ Rserve::REXP::Symbol->new('foo') ],
			attributes => 1
		)
	},
	qr/Attribute 'attributes' must be a hash reference/,
	'setting non-HASH attributes'
);

# Perl representation
is($expression->to_perl, [ 'foo', 4, 11.2 ], 'Perl representation');

is($na_heavy_expression->to_perl, [ 'bla', [ '', undef ], '0' ], 'expression with NAs Perl representation');

is($nested_expression->to_perl, [ 'qux', 4.0, [ 'b', [ 'cc', 44.1 ] ], 11 ], 'nested expressions Perl representation');

is(
	$nested_rexps->to_perl,
	[ 'quux', [ 1, 2, 3 ], [ 'a', ['b'], [11] ], ['foo'] ],
	'expression with nested REXPs Perl representation'
);

my $singleton = Rserve::REXP::Expression->new(elements => [ Rserve::REXP::Integer->new([42]) ]);
is($singleton->to_perl, [ [42] ], 'singleton element Perl representation');

done_testing;
