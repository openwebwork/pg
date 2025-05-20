#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
use lib "$ENV{PG_ROOT}/lib";

use Rserve::REXP::Null;

ok my $null = Rserve::REXP::Null->new, 'new null';
isa_ok $null, [ 'Rserve::REXP::Null', 'Rserve::REXP' ], 'null has correct classes';

is($null, $null, 'self equality');

my $null_2 = Rserve::REXP::Null->new;
is($null, $null_2, 'null equality');
isnt($null, 'null', 'null inequality');

ok($null->is_null,    'is null');
ok(!$null->is_vector, 'is not vector');

is($null . '', 'NULL', 'null text representation');

# attributes
is($null->attributes, undef, 'default attributes');

# cannot set attributes on Null
like(
	dies { Rserve::REXP::Null->new(attributes => { foo => 'bar', x => 42 }) },
	qr/Null cannot have attributes/,
	'setting null attributes'
);

# Perl representation
is($null->to_perl, undef, 'Perl representation');

done_testing;
