#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
use lib "$ENV{PG_ROOT}/lib";

use Rserve::REXP::Complex;
use Rserve::REXP::List;

use Math::Complex qw(cplx);

ok my $empty_vec = Rserve::REXP::Complex->new, 'new complex vector';
isa_ok $empty_vec, [ 'Rserve::REXP::Complex', 'Rserve::REXP::Vector', 'Rserve::REXP' ],
	'complex vectro has correct classes';

is($empty_vec, $empty_vec, 'self equality');

my $empty_vec_2 = Rserve::REXP::Complex->new;
is($empty_vec, $empty_vec_2, 'empty complex vector equality');

my $vec  = Rserve::REXP::Complex->new(elements => [ cplx(3.3), cplx(4.7), cplx(11) ]);
my $vec2 = Rserve::REXP::Complex->new([ 3.3, 4.7, 11 ]);
is($vec, $vec2, 'complex vector equality');

is(Rserve::REXP::Complex->new($vec2),                                         $vec, 'copy constructor');
is(Rserve::REXP::Complex->new(Rserve::REXP::List->new([ 3.3, [ 4.7, 11 ] ])), $vec, 'copy constructor from a vector');

# error checking in constructor arguments
like(
	dies {
		Rserve::REXP::Complex->new(sub { 1 + 1 })
	},
	qr/Attribute 'elements' must be an array reference/,
	'error-check in single-arg constructor'
);
like(
	dies {
		Rserve::REXP::Complex->new(1, 2, 3)
	},
	qr/odd number of arguments/,
	'odd constructor arguments'
);
like(
	dies {
		Rserve::REXP::Complex->new(elements => { foo => 1, bar => 2 })
	},
	qr/Attribute 'elements' must be an array reference/,
	'bad elements argument'
);

my $another_vec = Rserve::REXP::Complex->new(elements => [ cplx(3.3), cplx(4.7, 1), 11 ]);
isnt($vec, $another_vec, 'complex vector inequality');

my $na_heavy_vec  = Rserve::REXP::Complex->new(elements => [ cplx(11.3, 3), '', undef, 0.0 ]);
my $na_heavy_vec2 = Rserve::REXP::Complex->new(elements => [ cplx(11.3, 3), 0,  undef, 0 ]);
is($na_heavy_vec, $na_heavy_vec, 'NA-heavy vector equality');
isnt($na_heavy_vec, $na_heavy_vec2, 'NA-heavy vector inequality');

is($empty_vec . '', 'complex()',                                           'empty complex vector text representation');
is($vec . '',       'complex(3.3, 4.7, 11)',                               'complex vector text representation');
is(Rserve::REXP::Complex->new(elements => [undef]) . '', 'complex(undef)', 'text representation of a singleton NA');
is($na_heavy_vec . '', 'complex(11.3+3i, undef, undef, 0)',                'empty numbers representation');

is($empty_vec->elements, [],               'empty complex vector contents');
is($vec->elements,       [ 3.3, 4.7, 11 ], 'complex vector contents');
cmp_ok($vec->elements->[1], '==', 4.7, 'single element access');

is(
	Rserve::REXP::Complex->new(elements => [ 3.3, 4.0, '3x', 11 ])->elements,
	[ 3.3, 4, undef, 11 ],
	'constructor with non-numeric values'
);

is(
	Rserve::REXP::Complex->new(elements => [ 3.3, 4.0, [ 7, [ 20.9, 44.1 ] ], 11 ])->elements,
	[ 3.3, 4, 7, 20.9, 44.1, 11 ],
	'constructor from nested arrays'
);

ok(!$empty_vec->is_null,  'is not null');
ok($empty_vec->is_vector, 'is vector');

# attributes
is($vec->attributes, undef, 'default attributes');

my $vec_attr = Rserve::REXP::Complex->new(
	elements   => [ 3.3, 4.7, 11 ],
	attributes => {
		foo => 'bar',
		x   => [ 40, 41, 42 ]
	}
);
is($vec_attr->attributes, { foo => 'bar', x => [ 40, 41, 42 ] }, 'constructed attributes');

my $vec_attr2 = Rserve::REXP::Complex->new(
	elements   => [ 3.3, 4.7, 11 ],
	attributes => {
		foo => 'bar',
		x   => [ 40, 41, 42 ]
	}
);
my $another_vec_attr = Rserve::REXP::Complex->new(
	elements   => [ 3.3, 4.7, 11 ],
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
		Rserve::REXP::Complex->new(attributes => 1)
	},
	qr/Attribute 'attributes' must be a hash reference/,
	'setting non-HASH attributes'
);

# Perl representation
is($empty_vec->to_perl, [], 'empty vector Perl representation');

is($vec->to_perl, [ 3.3, 4.7, 11 ], 'Perl representation');

is($na_heavy_vec->to_perl, [ cplx(11.3, 3), undef, undef, 0 ], 'NA-heavy vector Perl representation');

done_testing;
