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

We now call on the Legacy version, which is used by
num_cmp to handle numbers with units.

New units can be added at run time by using the newUnit option

       $a = FormulaWithUnits("3x apples",{newUnit=>'apples'});

A new unit can either be a string, in which case the string is added as a
new unit with no relation to other units, or as a hashreference

       $newUnit = {name => 'bear',
                   conversion => {factor =>3, m=>1}};
       $a = FormulaWithUnits("3x bear", {newUnit=>$newUnit});

You can also define your own conversion hash.  In the above example one bear
is three meters.  (See Units.pm for examples). 

Finally, the newUnit option can also be an array ref containing any number of
new units to add.  A common reason for doing this would be to add the plural
version of the unit as an equilvalent unit.  E.G.

      $newUnits = ['apple',{name=>'apples',conversion=>{factor=>1,apple=>1}}];
      $a = FormulaWithUnits("3x apples",{newUnit=>$newUnits});

In this case both 3x apple and 3x apples would be accepted as answers. 

Note:  English pluralization is suprisingly hard, so WeBWorK will make no 
attempt to display a grammerically correct result.  

=cut

loadMacros('MathObjects.pl');

 #
 #  Now uses the version in Parser::Legacy::NumberWithUnits
 #  to avoid duplication of common code.
 #
our %fundamental_units = %Units::fundamental_units;
our %known_units = %Units::known_units;

sub _parserFormulaWithUnits_init {
    # We make copies of these hashes here because these copies will be unique to  # the problem.  The hashes in Units are shared between problems.  We pass
  # the hashes for these local copies to the NumberWithUnits package to use
  # for all of its stuff.  

  
  Parser::Legacy::ObjectWithUnits::initializeUnits(\%fundamental_units,\%known_units);
  
  main::PG_restricted_eval('sub FormulaWithUnits {Parser::Legacy::FormulaWithUnits->new(@_)}');
}

sub parserFormulaWithUnits::fundamental_units {
	return \%fundamental_units;
}
sub parserFormulaWithUnits::known_units {
	return \%known_units;
}
1;
