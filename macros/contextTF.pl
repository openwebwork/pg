loadMacros("Parser.pl","contextString.pl");

sub _contextTF_init {}; # don't load it again

##########################################################
#
#  Implements contexts for string-valued answers especially
#  for matching problems (where you match against T and F).
#
#	Context("TF");
#
#  You can add new strings to the context as needed (or remove old ones)
#  via the Context()->strings->add() and Context()-strings->remove()
#  methods
#
#	ANS(string_cmp("T","F"));
#
#  when there are two answers, the first being "T" and the second being "F".
#

$context{TF} = Context("String")->copy;
$context{TF}->strings->are(
 "T" => {value => 1}, "t" => {alias => "T"},
 "F" => {value => 0}, "f" => {alias => "F"},
 "True" => {alias => "T"}, "False" => {alias => "F"},
 "TRUE" => {alias => "T"}, "FALSE" => {alias => "F"},
 "true" => {alias => "T"}, "false" => {alias => "F"},
);

Context("TF");


