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

problemPreserveAnswers.pl - Allow sticky answers to preserve special characters.

=head1 DESCRIPTION

This file implements a fragile hack to overcome a problem with
PGbasicmacros.pl, which removes special characters from student
answers (in order to prevent EV3 from mishandling them).

NOTE: This file has been depreciated and doesn't do anything any more.  
Encoding of special characters is now handled by PGbasicmacros.pl

=cut

sub _problemPreserveAnswers_init {PreserveAnswers::Init()}

package PreserveAnswers;

sub Init {

}


our $ENDDOCUMENT; # holds pointer to original ENDDOCUMENT

######################################################################

1;
