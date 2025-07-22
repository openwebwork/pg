#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
use lib "$ENV{PG_ROOT}/lib";

use Rserve::REXP::Raw;
use Rserve::REXP::List;

ok my $empty_vec = Rserve::REXP::Raw->new, 'new raw vector';
isa_ok $empty_vec, [ 'Rserve::REXP::Raw', 'Rserve::REXP::Vector', 'Rserve::REXP' ],
	'raw vector has correct class classes';

is($empty_vec, $empty_vec, 'self equality');

my $empty_vec_2 = Rserve::REXP::Raw->new;
is($empty_vec, $empty_vec_2, 'empty raw vector equality');

my $vec  = Rserve::REXP::Raw->new(elements => [ 3, 4, 11 ]);
my $vec2 = Rserve::REXP::Raw->new([ 3, 4, 11 ]);
is($vec, $vec2, 'raw vector equality');

is(Rserve::REXP::Raw->new($vec2),                                         $vec, 'copy constructor');
is(Rserve::REXP::Raw->new(Rserve::REXP::List->new([ 3.3, [ 4, '11' ] ])), $vec, 'copy constructor from a vector');

# error checking in constructor arguments
like(
	dies {
		Rserve::REXP::Raw->new(sub { 1 + 1 })
	},
	qr/Attribute 'elements' must be an array reference/,
	'error-check in single-arg constructor'
);
like(
	dies {
		Rserve::REXP::Raw->new(1, 2, 3)
	},
	qr/odd number of arguments/,
	'odd constructor arguments'
);
like(
	dies {
		Rserve::REXP::Raw->new(elements => { foo => 1, bar => 2 })
	},
	qr/Attribute 'elements' must be an array reference/,
	'bad elements argument'
);
like(
	dies {
		Rserve::REXP::Raw->new([-1])
	},
	qr/Elements of raw vectors must be 0-255/,
	'elements range'
);

my $another_vec = Rserve::REXP::Raw->new(elements => [ 3, 4, 1 ]);
isnt($vec, $another_vec, 'raw vector inequality');

my $truncated_vec = Rserve::REXP::Raw->new(elements => [ 3.3, 4.0, 11 ]);
is($truncated_vec, $vec, 'constructing from floats');

is($empty_vec->elements, [],           'empty raw vector contents');
is($vec->elements,       [ 3, 4, 11 ], 'raw vector contents');
is($vec->elements->[2],  11,           'single element access');

ok(!$empty_vec->is_null,  'is not null');
ok($empty_vec->is_vector, 'is vector');

# attributes
is($vec->attributes, undef, 'default attributes');

# cannot set attributes on Raw
like(
	dies {
		Rserve::REXP::Raw->new(attributes => { foo => 'bar', x => 42 })
	},
	qr/Raw vectors cannot have attributes/,
	'setting raw attributes'
);

# Perl representation
is($empty_vec->to_perl, [], 'empty vector Perl representation');

is($vec->to_perl, [ 3, 4, 11 ], 'Perl representation');

done_testing;
