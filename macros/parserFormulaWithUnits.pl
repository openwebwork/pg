
loadMacros('Parser.pl');

sub _parserFormulaWithUnits_init {}; # don't reload this file

=head1 DESCRIPTION

######################################################################
#
#  This is a Parser class that implements a formula with units.
#  It is a temporary version until the Parser can handle it
#  directly.
#
#  Use FormulaWithUnits("num units") or FormulaWithUnits(formula,"units")
#  to generate a FormulaWithUnits object, and then call its cmp() method
#  to get an answer checker for your formula with units.
#
#  Usage examples:
#
#      ANS(FormulaWithUnits("3x+1 ft")->cmp);
#      ANS(FormulaWithUnits("$a*x+1 ft")->cmp);
#
#      $x = Formula("x");
#      ANS(FormulaWithUnits($a*$x+1,"ft")->cmp);
#
######################################################################

#
#  Now uses the version in Parser::Legacy::NumberWithUnits
#  to avoid duplication of common code.
#

=cut

sub FormulaWithUnits {Parser::Legacy::FormulaWithUnits->new(@_)}

