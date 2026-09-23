#!/usr/bin/env perl

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

use HTML::Entities;
use HTML::TagParser;

my $name = NEW_ANS_NAME();

my $html = HTML::TagParser->new(NAMED_ANS_RULE($name));

my @inputs = $html->getElementsByTagName('input');
is($inputs[0]->attributes->{id},   $name,  'basicmacros: test NAMED_ANS_RULE id attribute');
is($inputs[0]->attributes->{name}, $name,  'basicmacros: test NAMED_ANS_RULE name attribute');
is($inputs[0]->attributes->{type}, 'text', 'basicmacros: test NAMED_ANS_RULE type attribute');
ok(!$inputs[0]->attributes->{value}, 'basicmacros: test NAMED_ANS_RULE value attribute');

is($inputs[1]->attributes->{name}, "previous&#95;$name", 'basicmacros: test NAMED_ANS_RULE hidden name attribute');
is($inputs[1]->attributes->{type}, 'hidden',             'basicmacros: test NAMED_ANS_RULE hidden type attribute');

done_testing();
