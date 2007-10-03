=head1 NAME

parserNumberWithUnits.pl - Implements a number with units.

=head1 DESCRIPTION

This is a Parser class that implements a number with units.
It is a temporary version until the Parser can handle it
directly.

Use NumberWithUnits("num units") or NumberWithUnits(formula,"units")
to generate a NumberWithUnits object, and then call its cmp method
to get an answer checker for your number with units.

Usage examples:

    ANS(NumberWithUnits("3 ft")->cmp);
    ANS(NumberWithUnits("$a*$b ft")->cmp);
    ANS(NumberWithUnits($a*$b,"ft")->cmp);

We now call on the Legacy version, which is used by
num_cmp to handle numbers with units.

=cut

loadMacros('MathObjects.pl');

sub _parserNumberWithUnits_init {
  main::PG_restricted_eval('sub NumberWithUnits {Parser::Legacy::NumberWithUnits->new(@_)}');
}

1;
