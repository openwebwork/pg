loadMacros("Parser.pl","contextString.pl");

sub _contextABCD_init {}; # don't load it again

##########################################################
#
#  Implements contexts for string-valued answers especially
#  for matching problems (where you match against A, B, C, D,
#  and so on).
#
#  There are two contexts defined here,
#
#	Context("ABCD");
#	Context("ABCD-List");
#
#  The second allows the students to enter lists of strings,
#  while the first does not.
#
#  You can add new strings to the context as needed (or remove old ones)
#  via the Context()->strings->add() and Context()-strings->remove()
#  methods, eg.
#
#	Context("ABCD-List")->strings->add(E=>{},e=>{alias=>"E"});
#
#  Use string_cmp() to produce the answer checker(s) for your
#  correct values.  Eg.
#
#	ANS(string_cmp("A","B"));
#
#  when there are two answers, the first being "A" and the second being "B".
#

$context{ABCD} = Context("String")->copy;
$context{ABCD}->strings->are(
 "A" => {}, "a" => {alias => "A"},
 "B" => {}, "b" => {alias => "B"},
 "C" => {}, "c" => {alias => "C"},
 "D" => {}, "d" => {alias => "D"},
);

$context{'ABCD-List'} = $context{ABCD}->copy;
$context{'ABCD-List'}->operators->add(
  ',' => $Parser::Context::Default::fullContext->operators->get(','),
);
$context{'ABCD-List'}->strings->add("NONE"=>{});

Context("ABCD");
