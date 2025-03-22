#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
use lib "$ENV{PG_ROOT}/lib";

use Rserve::REXP;

# not instantiable
like(dies { Rserve::REXP->new }, qr/an abstract class/, 'creating a REXP instance');

done_testing;
