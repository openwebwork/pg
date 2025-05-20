#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
use lib "$ENV{PG_ROOT}/lib";

use Rserve::REXP::Unknown;

ok my $unk = Rserve::REXP::Unknown->new(sexptype => 42), 'new unknown';
isa_ok $unk, [ 'Rserve::REXP::Unknown', 'Rserve::REXP' ], 'unkown has correct class classes';

is($unk, $unk, 'self equality');

my $unk_2 = Rserve::REXP::Unknown->new(sexptype => 42);
is($unk,                               $unk_2, 'unknown equality');
is(Rserve::REXP::Unknown->new($unk_2), $unk,   'copy constructor');
is(Rserve::REXP::Unknown->new(42),     $unk,   'scalar constructor');

# error checking in constructor arguments
like(
	dies {
		Rserve::REXP::Unknown->new([ 1, 2, 3 ])
	},
	qr/Attribute 'sexptype' must be a number in range 0-255/,
	'error-check in single-arg constructor'
);
like(
	dies {
		Rserve::REXP::Unknown->new(1, 2, 3)
	},
	qr/odd number of arguments/,
	'odd constructor arguments'
);
like(
	dies {
		Rserve::REXP::Unknown->new(sexptype => [ 1, 2, 3 ])
	},
	qr/Attribute 'sexptype' must be a number in range 0-255/,
	'bad name argument'
);

my $unk_foo = Rserve::REXP::Unknown->new(sexptype => 100);
isnt($unk, $unk_foo, 'unknown inequality');

is($unk->sexptype, 42, 'unknown sexptype');

ok(!$unk->is_null,   'is not null');
ok(!$unk->is_vector, 'is not vector');

is($unk . '', 'Unknown', 'unknown text representation');

# attributes
is($unk->attributes, undef, 'default attributes');

my $unk_attr = Rserve::REXP::Unknown->new(
	sexptype   => 42,
	attributes => {
		foo => 'bar',
		x   => [ 40, 41, 42 ]
	}
);
is($unk_attr->attributes, { foo => 'bar', x => [ 40, 41, 42 ] }, 'constructed attributes');

my $unk_attr2 = Rserve::REXP::Unknown->new(
	sexptype   => 42,
	attributes => {
		foo => 'bar',
		x   => [ 40, 41, 42 ]
	}
);
my $another_unk_attr = Rserve::REXP::Unknown->new(
	sexptype   => 42,
	attributes => {
		foo => 'bar',
		x   => [ 40, 42, 42 ]
	}
);
is($unk_attr, $unk_attr2, 'equality considers attributes');
isnt($unk_attr, $unk,              'inequality considers attributes');
isnt($unk_attr, $another_unk_attr, 'inequality considers attributes deeply');

# attributes must be a hash
like(
	dies {
		Rserve::REXP::Unknown->new(
			sexptype   => 42,
			attributes => 1
		)
	},
	qr/Attribute 'attributes' must be a hash reference/,
	'setting non-HASH attributes'
);

# Perl representation
is($unk->to_perl, undef, 'Perl representation');

done_testing;
