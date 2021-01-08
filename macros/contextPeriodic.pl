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

contextPeriodic.pl - [DEPRECATED] Features added to Real and Complex 
MathObjects classes.

=head1 DESCRIPTION

This file is no longer needed, as these features have been added to the
Real and Complex MathObject classes.

=head1 USAGE

	Context("Numeric");
	$a = Real("pi/2")->with(period=>pi);
	$a->cmp         # will match pi/2, 3pi/2 etc.

	Context("Complex");
	$z0 = Real("i^i")->with(period=>2pi, logPeriodic=>1);
	$z0->cmp        # will match exp(i*(ln(1) + Arg(pi/2) + 2k pi))

=cut

1;

