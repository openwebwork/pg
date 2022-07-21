use Test2::V0;

use HTML::Entities;
use HTML::TagParser;

use lib 't/lib';
use Test::PG;


=head1 MathObjects

=cut


loadMacros("PGbasicmacros.pl");

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
