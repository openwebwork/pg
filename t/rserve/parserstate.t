#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
use lib "$ENV{PG_ROOT}/lib";

use Rserve::ParserState;

use Scalar::Util qw(refaddr);

my $state = Rserve::ParserState->new(data => 'foobar');

# basic state sanity
is($state->data,     [ 'f', 'o', 'o', 'b', 'a', 'r' ], 'split data');
is($state->at,       'f',                              'starting at');
is($state->position, 0,                                'starting position');
ok(!$state->eof, 'starting eof');

# state next
my $next_state = $state->next;
is($next_state,           Rserve::ParserState->new(data => 'foobar', position => 1), 'next');
is($next_state->at,       'o',                                                       'next value');
is($next_state->position, 1,                                                         'next position');
is($state,                Rserve::ParserState->new(data => 'foobar', position => 0), q{next doesn't mutate in place});

done_testing;
