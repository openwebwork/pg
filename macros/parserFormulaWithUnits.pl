################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader$
# 
# This program is free software; you can redistribute it and/or modify it under
# the terms of either: (a) the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version, or (b) the "Artistic License" which comes with this package.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
# Artistic License for more details.
################################################################################

=head1 NAME

parserFormulaWithUnits.pl - Implements a formula with units.

=head1 DESCRIPTION

This is a Parser class that implements a formula with units.
It is a temporary version until the Parser can handle it
directly.

Use FormulaWithUnits("num units") or FormulaWithUnits(formula,"units")
to generate a FormulaWithUnits object, and then call its cmp() method
to get an answer checker for your formula with units.

=head1 USAGE

	ANS(FormulaWithUnits("3x+1 ft")->cmp);
	ANS(FormulaWithUnits("$a*x+1 ft")->cmp);

	$x = Formula("x");
	ANS(FormulaWithUnits($a*$x+1,"ft")->cmp);

=cut

loadMacros('MathObjects.pl');

 #
 #  Now uses the version in Parser::Legacy::NumberWithUnits
 #  to avoid duplication of common code.
 #

sub _parserFormulaWithUnits_init {
  main::PG_restricted_eval('sub FormulaWithUnits {Parser::Legacy::FormulaWithUnits->new(@_)}');
}

1;
