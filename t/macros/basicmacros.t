use warnings;
use strict;

package main;

use Test::More;
use Test::Exception;

# The following needs to include at the top of any testing down to END OF TOP_MATERIAL.

BEGIN {
	die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
	$main::pg_dir = $ENV{PG_ROOT};
}

use lib "$main::pg_dir/lib";

require("$main::pg_dir/t/build_PG_envir.pl");

## END OF TOP_MATERIAL

loadMacros("PGbasicmacros.pl");

use HTML::Entities;
use HTML::TagParser;

my $name      = "myansrule";
my $named_box = NAMED_ANS_RULE($name);

my $html = HTML::TagParser->new($named_box);

my @inputs = $html->getElementsByTagName("input");
is($inputs[0]->attributes->{id},   $name,  "basicmacros: test NAMED_ANS_RULE id attribute");
is($inputs[0]->attributes->{name}, $name,  "basicmacros: test NAMED_ANS_RULE name attribute");
is($inputs[0]->attributes->{type}, "text", "basicmacros: test NAMED_ANS_RULE type attribute");
ok(!$inputs[0]->attributes->{value}, "basicmacros: test NAMED_ANS_RULE value attribute");

is($inputs[1]->attributes->{name}, "previous_$name", "basicmacros: test NAMED_ANS_RULE hidden name attribute");
is($inputs[1]->attributes->{type}, "hidden",         "basicmacros: test NAMED_ANS_RULE hidden type attribute");

done_testing();
