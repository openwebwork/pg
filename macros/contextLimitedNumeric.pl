
loadMacros("MathObjects.pl");

=head3 Context("LimitedNumeric")

 ##########################################################
 #
 #  Implements a context in which numbers can be entered,
 #  but no operations are permitted between them.
 #
 #  There are two versions:  one for lists of numbers
 #  and one for a single number.  Select them using
 #  one of the following commands:
 #
 #      Context("LimitedNumeric-list");
 #      Context("LimiteNumeric");
 #
 #  (Now uses Parcer::Legacy::LimitedNumeric to implement
 #  these contexts.)

=cut

##################################################

sub _contextLimitedNumeric_init {

  my $context = $main::context{"LimitedNumeric-List"} = Parser::Context->getCopy("LimitedNumeric");
  $context->{name} = "LimitedNumeric-List";
  $context->operators->redefine(',');

  main::Context("LimitedNumeric");  ### FIXME:  probably should require the author to set this explicitly
}

1;
