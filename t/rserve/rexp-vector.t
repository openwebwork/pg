#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
use lib "$ENV{PG_ROOT}/lib";

use Rserve::REXP::Vector;

# not instantiable
like(dies { Rserve::REXP::Vector->new }, qr/method required/, 'creating a Vector instance');

ok(Rserve::REXP::Vector->is_vector, 'is vector');
ok(!Rserve::REXP::Vector->is_null,  'is not null');

done_testing;
