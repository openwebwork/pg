loadMacros("MathObjects.pl","contextString.pl");

=head3 Context("TF")

 ##########################################################
 #
 #  Implements contexts for string-valued answers especially
 #  for matching problems (where you match against T and F).
 #
 #	Context("TF");
 #
 #  You can add new strings to the context as needed (or remove old ones)
 #  via the Context()->strings->add() and Context()-strings->remove()
 #  methods.
 #
 #  Use:
 #
 #	ANS(string_cmp("T","F"));
 #
 #  when there are two answers, the first being "T" and the second being "F".
 #

=cut

sub _contextTF_init {

  my $context = $main::context{TF} = Parser::Context->getCopy("String");
  $context->{name} = "TF";
  $context->strings->are(
    "T" => {value => 1},
    "F" => {value => 0},
    "True" => {alias => "T"},
    "False" => {alias => "F"},
  );

  main::Context("TF");  ### FIXME:  probably should require author to set this explicitly
}

1;
