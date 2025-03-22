#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
use lib "$ENV{PG_ROOT}/lib";

use Rserve::REXP::Logical;
use Rserve::REXP::List;

ok my $empty_vec = Rserve::REXP::Logical->new, 'new logical vector';
isa_ok $empty_vec, [ 'Rserve::REXP::Logical', 'Rserve::REXP::Vector', 'Rserve::REXP' ],
	'logical vector has correct classes';

is($empty_vec, $empty_vec, 'self equality');

my $empty_vec_2 = Rserve::REXP::Logical->new;
is($empty_vec, $empty_vec_2, 'empty logical vector equality');

my $vec  = Rserve::REXP::Logical->new(elements => [ 1, 0, 1, 0 ]);
my $vec2 = Rserve::REXP::Logical->new([ 3.3, '', 'bla', '0' ]);
is($vec, $vec2, 'logical vector equality');

is(Rserve::REXP::Logical->new($vec2), $vec, 'copy constructor');
is(Rserve::REXP::Logical->new(Rserve::REXP::List->new([ 3.3, '', [ 'bla', 0 ] ])),
	$vec, 'copy constructor from a vector');

# error checking in constructor arguments
like(
	dies {
		Rserve::REXP::Logical->new(sub { 1 + 1 })
	},
	qr/Attribute 'elements' must be an array reference/,
	'error-check in single-arg constructor'
);
like(
	dies {
		Rserve::REXP::Logical->new(1, 2, 3)
	},
	qr/odd number of arguments/,
	'odd constructor arguments'
);
like(
	dies {
		Rserve::REXP::Logical->new(elements => { foo => 1, bar => 2 })
	},
	qr/Attribute 'elements' must be an array reference/,
	'bad elements argument'
);

my $another_vec = Rserve::REXP::Logical->new(elements => [ 1, 0, 1, undef ]);
isnt($vec, $another_vec, 'logical vector inequality');

is($empty_vec . '',   'logical()',                                         'empty logical vector text representation');
is($vec . '',         'logical(1, 0, 1, 0)',                               'logical vector text representation');
is($another_vec . '', 'logical(1, 0, 1, undef)',                           'text representation with logical NAs');
is(Rserve::REXP::Logical->new(elements => [undef]) . '', 'logical(undef)', 'text representation of a singleton NA');

is($empty_vec->elements, [],             'empty logical vector contents');
is($vec->elements,       [ 1, 0, 1, 0 ], 'logical vector contents');
is($vec->elements->[2],  1,              'single element access');

is(
	Rserve::REXP::Logical->new(elements => [ 3.3, '', undef, 'foo' ])->elements,
	[ 1, 0, undef, 1 ],
	'constructor with undefined values'
);

is(
	Rserve::REXP::Logical->new(elements => [ 3.3, '', [ 0, [ '00', undef ] ], 1 ])->elements,
	[ 1, 0, 0, 1, undef, 1 ],
	'constructor from nested arrays'
);

ok(!$empty_vec->is_null,  'is not null');
ok($empty_vec->is_vector, 'is vector');

# attributes
is($vec->attributes, undef, 'default attributes');

my $vec_attr = Rserve::REXP::Logical->new(
	elements   => [ 1, 0, 1, 0 ],
	attributes => {
		foo => 'bar',
		x   => [ 40, 41, 42 ]
	}
);
is($vec_attr->attributes, { foo => 'bar', x => [ 40, 41, 42 ] }, 'constructed attributes');

my $vec_attr2 = Rserve::REXP::Logical->new(
	elements   => [ 1, 0, 1, 0 ],
	attributes => {
		foo => 'bar',
		x   => [ 40, 41, 42 ]
	}
);
my $another_vec_attr = Rserve::REXP::Logical->new(
	elements   => [ 1, 0, 1, 0 ],
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
		Rserve::REXP::Logical->new(attributes => 1)
	},
	qr/Attribute 'attributes' must be a hash reference/,
	'setting non-HASH attributes'
);

# Perl representation
is($empty_vec->to_perl, [], 'empty vector Perl representation');

is($vec->to_perl, [ 1, 0, 1, 0 ], 'Perl representation');

is($another_vec->to_perl, [ 1, 0, 1, undef ], 'NA-heavy vector Perl representation');

done_testing;
