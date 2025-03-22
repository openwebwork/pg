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

ok my $empty_list = Rserve::REXP::List->new, 'new generic vector';

ok(!($empty_list->attributes && $empty_list->attributes->{'class'}), 'no class');
ok(!$empty_list->inherits('foo'),                                    'no inheritance');

my $obj = Rserve::REXP::List->new(
	elements   => [ 3.3, '4', 11 ],
	attributes => {
		class => Rserve::REXP::Character->new([ 'foo', 'data.frame' ]),
		names => Rserve::REXP::Character->new([ 'a',   'b', 'g' ]),
	}
);
ok($obj->inherits('foo'));
ok($obj->inherits('data.frame'));
ok(!$obj->inherits('bar'));

done_testing;
