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
