#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
use lib "$ENV{PG_ROOT}/lib";

use Rserve::REXP::Character;
use Rserve::REXP::List;

ok my $empty_vec = Rserve::REXP::Character->new, 'new character vector';
isa_ok $empty_vec, [ 'Rserve::REXP::Character', 'Rserve::REXP::Vector', 'Rserve::REXP' ],
	'character vector has correct classes';

is($empty_vec, $empty_vec, 'self equality');

my $empty_vec_2 = Rserve::REXP::Character->new;
is($empty_vec, $empty_vec_2, 'empty character vector equality');

my $vec  = Rserve::REXP::Character->new(elements => [ 3.3, '4.7', 'bar' ]);
my $vec2 = Rserve::REXP::Character->new([ 3.3, 4.7, 'bar' ]);
is($vec, $vec2, 'character vector equality');

is(Rserve::REXP::Character->new($vec2), $vec, 'copy constructor');
is(Rserve::REXP::Character->new(Rserve::REXP::List->new([ 3.3, [ 4.7, 'bar' ] ])),
	$vec, 'copy constructor from a vector');

# error checking in constructor arguments
like(
	dies {
		Rserve::REXP::Character->new(sub { 1 + 1 })
	},
	qr/Attribute 'elements' must be an array reference/,
	'error-check in single-arg constructor'
);
like(
	dies {
		Rserve::REXP::Character->new(1, 2, 3)
	},
	qr/odd number of arguments/,
	'odd constructor arguments'
);
like(
	dies {
		Rserve::REXP::Character->new(elements => { foo => 1, bar => 2 })
	},
	qr/Attribute 'elements' must be an array reference/,
	'bad elements argument'
);

my $another_vec = Rserve::REXP::Character->new(elements => [ 3.3, '4.7', 'bar', undef ]);
isnt($vec, $another_vec, 'character vector inequality');

my $na_heavy_vec  = Rserve::REXP::Character->new(elements => [ 'foo', '', undef, 23 ]);
my $na_heavy_vec2 = Rserve::REXP::Character->new(elements => [ 'foo', 0,  undef, 23 ]);
is($na_heavy_vec, $na_heavy_vec, 'NA-heavy vector equality');
isnt($na_heavy_vec, $na_heavy_vec2, 'NA-heavy vector inequality');

is($empty_vec . '', 'character()',              'empty character vector text representation');
is($vec . '',       'character(3.3, 4.7, bar)', 'character vector text representation');
is(Rserve::REXP::Character->new(elements => [undef]) . '', 'character(undef)', 'text representation of a singleton NA');
is($na_heavy_vec . '', 'character(foo, , undef, 23)',                          'empty characters representation');

is($empty_vec->elements, [],                  'empty character vector contents');
is($vec->elements,       [ 3.3, 4.7, 'bar' ], 'character vector contents');
is($vec->elements->[1],  4.7,                 'single element access');

is(
	Rserve::REXP::Character->new(elements => [ 3.3, 4.0, '3x', 11 ])->elements,
	[ 3.3, 4, '3x', 11 ],
	'constructor with non-numeric values'
);

is(
	Rserve::REXP::Character->new(elements => [ 3.3, 4.0, [ 7, [ 'a', 'foo' ] ], 11 ])->elements,
	[ 3.3, 4, 7, 'a', 'foo', 11 ],
	'constructor from nested arrays'
);

ok(!$empty_vec->is_null,  'is not null');
ok($empty_vec->is_vector, 'is vector');

# attributes
is($vec->attributes, undef, 'default attributes');

my $vec_attr = Rserve::REXP::Character->new(
	elements   => [ 3.3, 4.7, 'bar' ],
	attributes => {
		foo => 'bar',
		x   => [ 40, 41, 42 ]
	}
);
is($vec_attr->attributes, { foo => 'bar', x => [ 40, 41, 42 ] }, 'constructed attributes');

my $vec_attr2 = Rserve::REXP::Character->new(
	elements   => [ 3.3, 4.7, 'bar' ],
	attributes => {
		foo => 'bar',
		x   => [ 40, 41, 42 ]
	}
);
my $another_vec_attr = Rserve::REXP::Character->new(
	elements   => [ 3.3, 4.7, 'bar' ],
	attributes => {
		foo => 'bar',
		x   => [ 40, 42, 42 ]
	}
);
is($vec_attr, $vec_attr2, 'equality considers attributes');
isnt($vec_attr, $vec,              'inequality considers attributes');
isnt($vec_attr, $another_vec_attr, 'inequality considers attributes deeply');

# attributes must be a hash
like(
	dies {
		Rserve::REXP::Character->new(attributes => 1)
	},
	qr/Attribute 'attributes' must be a hash reference/,
	'setting non-HASH attributes'
);

# Perl representation
is($empty_vec->to_perl, [], 'empty vector Perl representation');

is($vec->to_perl, [ 3.3, 4.7, 'bar' ], 'Perl representation');

is($na_heavy_vec->to_perl, [ 'foo', '', undef, 23 ], 'NA-heavy vector Perl representation');

done_testing;
