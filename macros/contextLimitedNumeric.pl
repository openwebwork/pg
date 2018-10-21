################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2018 The WeBWorK Project, http://openwebwork.sf.net/
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

contextLimitedNumeric.pl - Allows numeric entry but no operations.

=head1 DESCRIPTION

Implements a context in which numbers can be entered,
but no operations are permitted between them.

There are two versions:  one for lists of numbers
and one for a single number.  Select them using
one of the following commands:

	Context("LimitedNumeric-List");
	Context("LimitedNumeric");

(Now uses Parser::Legacy::LimitedNumeric to implement
these contexts.)

=cut

loadMacros("MathObjects.pl");

sub _contextLimitedNumeric_init {

  my $context = $main::context{"LimitedNumeric-List"} = Parser::Context->getCopy("LimitedNumeric");
  $context->{name} = "LimitedNumeric-List";
  $context->operators->redefine(',');

  main::Context("LimitedNumeric");  ### FIXME:  probably should require the author to set this explicitly
}

1;
