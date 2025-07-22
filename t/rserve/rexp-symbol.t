#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
use lib "$ENV{PG_ROOT}/lib";

use Rserve::REXP::Symbol;

ok my $sym = Rserve::REXP::Symbol->new(name => 'sym'), 'new symbol';
isa_ok $sym, [ 'Rserve::REXP::Symbol', 'Rserve::REXP' ], 'symbol has correct class classes';

is($sym, $sym, 'self equality');

my $sym_2 = Rserve::REXP::Symbol->new(name => $sym);
is($sym,                              $sym_2, 'symbol equality with copy');
is(Rserve::REXP::Symbol->new($sym_2), $sym,   'copy constructor');
is(Rserve::REXP::Symbol->new('sym'),  $sym,   'string constructor');

# error checking in constructor arguments
like(
	dies {
		Rserve::REXP::Symbol->new([ 1, 2, 3 ])
	},
	qr/Attribute 'name' must be a scalar value/,
	'error-check in single-arg constructor'
);
like(
	dies {
		Rserve::REXP::Symbol->new(1, 2, 3)
	},
	qr/odd number of arguments/,
	'odd constructor arguments'
);
like(
	dies {
		Rserve::REXP::Symbol->new(name => [ 1, 2, 3 ])
	},
	qr/Attribute 'name' must be a scalar value/,
	'bad name argument'
);

my $sym_foo = Rserve::REXP::Symbol->new(name => 'foo');
isnt($sym, $sym_foo, 'symbol inequality');

is($sym->name, 'sym', 'symbol name');

ok(!$sym->is_null,   'is not null');
ok(!$sym->is_vector, 'is not vector');

is($sym . '', 'symbol `sym`', 'symbol text representation');

# attributes
is($sym->attributes, undef, 'default attributes');

my $sym_attr = Rserve::REXP::Symbol->new(
	name       => 'sym',
	attributes => {
		foo => 'bar',
		x   => [ 40, 41, 42 ]
	}
);
is($sym_attr->attributes, { foo => 'bar', x => [ 40, 41, 42 ] }, 'constructed attributes');

my $sym_attr2 = Rserve::REXP::Symbol->new(
	name       => 'sym',
	attributes => {
		foo => 'bar',
		x   => [ 40, 41, 42 ]
	}
);
my $another_sym_attr = Rserve::REXP::Symbol->new(
	name       => 'sym',
	attributes => {
		foo => 'bar',
		x   => [ 40, 42, 42 ]
	}
);
is($sym_attr, $sym_attr2, 'equality considers attributes');
isnt($sym_attr, $sym,              'inequality considers attributes');
isnt($sym_attr, $another_sym_attr, 'inequality considers attributes deeply');

# attributes must be a hash
like(
	dies {
		Rserve::REXP::Symbol->new(attributes => 1)
	},
	qr/Attribute 'attributes' must be a hash reference/,
	'setting non-HASH attributes'
);

# Perl representation
is($sym->to_perl, 'sym', 'Perl representation');

done_testing;
