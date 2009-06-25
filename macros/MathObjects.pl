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

MathObjects.pl - Macro-based fronted to the MathObjects system.

=head1 DESCRIPTION

This file loads Parser.pl which in turn loads Value.pl The purpose of this file
is to encourage the use of the name MathObjects instead of Parser (which is not
as intuitive for those who don't know the history).

It may later be used for other purposes as well.

=head1 SEE ALSO

L<Parser.pl>.

=cut

# ^uses loadMacros
loadMacros("Parser.pl");

1;
