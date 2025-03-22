#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
use lib "$ENV{PG_ROOT}/lib";

use Rserve::REXP::List;
use Rserve::REXP::Character;
use Rserve::REXP::Double;
use Rserve::REXP::Integer;

ok my $empty_list = Rserve::REXP::List->new, 'new list vector';
isa_ok $empty_list, [ 'Rserve::REXP::List', 'Rserve::REXP::Vector', 'Rserve::REXP' ], 'list vector has correct classes';

is($empty_list, $empty_list, 'self equality');

my $empty_list_2 = Rserve::REXP::List->new;
is($empty_list, $empty_list_2, 'empty generic vector equality');

my $list  = Rserve::REXP::List->new(elements => [ 3.3, '4', 11 ]);
my $list2 = Rserve::REXP::List->new([ 3.3, 4, 11 ]);
is($list, $list2, 'generic vector equality');

is(Rserve::REXP::List->new($list2),                                    $list, 'copy constructor');
is(Rserve::REXP::List->new(Rserve::REXP::Double->new([ 3.3, 4, 11 ])), $list, 'copy constructor from a vector');

# error checking in constructor arguments
like(
	dies {
		Rserve::REXP::List->new(sub { 1 + 1 })
	},
	qr/Attribute 'elements' must be an array reference/,
	'error-check in single-arg constructor'
);
like(
	dies {
		Rserve::REXP::List->new(1, 2, 3)
	},
	qr/odd number of arguments/,
	'odd constructor arguments'
);
like(
	dies {
		Rserve::REXP::List->new(elements => { foo => 1, bar => 2 })
	},
	qr/Attribute 'elements' must be an array reference/,
	'bad elements argument'
);

my $another_list = Rserve::REXP::List->new(elements => [ 3.3, 4, 10.9 ]);
isnt($list, $another_list, 'generic vector inequality');

my $na_heavy_list  = Rserve::REXP::List->new(elements => [ 11.3, [ '',    undef ], '0' ]);
my $na_heavy_list2 = Rserve::REXP::List->new(elements => [ 11.3, [ undef, undef ], 0 ]);
is($na_heavy_list, $na_heavy_list, 'NA-heavy generic vector equality');
isnt($na_heavy_list, $na_heavy_list2, 'NA-heavy generic vector inequality');

is($empty_list . '',                                  'list()',           'empty generic vector text representation');
is($list . '',                                        'list(3.3, 4, 11)', 'generic vector text representation');
is(Rserve::REXP::List->new(elements => [undef]) . '', 'list(undef)',      'text representation of a singleton NA');
is(
	Rserve::REXP::List->new(elements => [ [ [undef] ] ]) . '',
	'list([[undef]])',
	'text representation of a nested singleton NA'
);
is($na_heavy_list . '', 'list(11.3, [, undef], 0)', 'empty string representation');

is($empty_list->elements, [],             'empty generic vector contents');
is($list->elements,       [ 3.3, 4, 11 ], 'generic vector contents');
is($list->elements->[2],  11,             'single element access');

is(
	Rserve::REXP::List->new(elements => [ 3.3, 4.0, '3x', 11 ])->elements,
	[ 3.3, 4, '3x', 11 ],
	'constructor with non-numeric values'
);

my $nested_list = Rserve::REXP::List->new(elements => [ 3.3, 4.0, [ 'b', [ 'cc', 44.1 ] ], 11 ]);
is($nested_list->elements,           [ 3.3, 4, [ 'b', [ 'cc', 44.1 ] ], 11 ], 'nested list contents');
is($nested_list->elements->[2]->[1], [ 'cc', 44.1 ],                          'nested element');
is($nested_list->elements->[3],      11,                                      'non-nested element');

is($nested_list . '', 'list(3.3, 4, [b, [cc, 44.1]], 11)', 'nested generic vector text representation');

my $nested_rexps = Rserve::REXP::List->new([
	Rserve::REXP::Integer->new([ 1, 2, 3 ]),
	Rserve::REXP::List->new([ Rserve::REXP::Character->new(['a']), Rserve::REXP::Character->new(['b']),
		Rserve::REXP::Double->new([11]) ]),
	Rserve::REXP::Character->new(['foo'])
]);

is(
	$nested_rexps . '',
	'list(integer(1, 2, 3), list(character(a), character(b), double(11)), character(foo))',
	'nested generic vector of REXPs text representation'
);

ok(!$empty_list->is_null,  'is not null');
ok($empty_list->is_vector, 'is vector');

# attributes
is($list->attributes, undef, 'default attributes');

my $list_attr = Rserve::REXP::List->new(
	elements   => [ 3.3, '4', 11 ],
	attributes => {
		foo => 'bar',
		x   => [ 40, 41, 42 ]
	}
);
is($list_attr->attributes, { foo => 'bar', x => [ 40, 41, 42 ] }, 'constructed attributes');

my $list_attr2 = Rserve::REXP::List->new(
	elements   => [ 3.3, '4', 11 ],
	attributes => {
		foo => 'bar',
		x   => [ 40, 41, 42 ]
	}
);
my $another_list_attr = Rserve::REXP::List->new(
	elements   => [ 3.3, '4', 11 ],
	attributes => {
		foo => 'bar',
		x   => [ 40, 42, 42 ]
	}
);
is($list_attr, $list_attr2, 'equality considers attributes');
isnt($list_attr, $list,              'inequality considers attributes');
isnt($list_attr, $another_list_attr, 'inequality considers attributes deeply');

# attributes must be a hash
like(
	dies {
		Rserve::REXP::List->new(attributes => 1)
	},
	qr/Attribute 'attributes' must be a hash reference/,
	'setting non-HASH attributes'
);

# Perl representation
is($empty_list->to_perl, [], 'empty list Perl representation');

is($list->to_perl, [ 3.3, '4', 11 ], 'Perl representation');

is($na_heavy_list->to_perl, [ 11.3, [ '', undef ], '0' ], 'list with NAs Perl representation');

is($nested_list->to_perl, [ 3.3, 4.0, [ 'b', [ 'cc', 44.1 ] ], 11 ], 'nested lists Perl representation');

is($nested_rexps->to_perl, [ [ 1, 2, 3 ], [ 'a', 'b', 11 ], 'foo' ], 'list with nested REXPs Perl representation');

done_testing;
