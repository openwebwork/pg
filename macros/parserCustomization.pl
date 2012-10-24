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

parserCustomization.pl - Placeholder for site/course-local customization file.

=head1 DESCRIPTION

Copy this file to your course templates directory and put any
customization for the Parser that you want for your course
here.  For example, you can make vectors display using
ijk notation (and force students to use it for entering
vectors) by using:

	$context{Vector} = Parser::Context->getCopy("Vector");
	$context{Vector}->flags->set(ijk=>1);
	$context{Vector}->parens->remove('<');

To allow vectors to be entered with parens (and displayed with
parens) rather than angle-brakets, use

	$context{Vector} = Parser::Context->getCopy("Vector");
	$context{Vector}->{cmpDefaults}{Vector} = {promotePoints => 1};
	$context{Vector}->lists->set(Vector=>{open=>'(', close=>')'});

(This actually just turns points into vectors in the answer checker
for vectors, and displays vectors using parens rather than angle
brackets.  The student is really still entering what MathObjects
thinks is a point, but since points get promoted automatically, that
should work.  But if a problem checks if a student's value is actually
a Vector, that will not be true.)

=cut

sub _parserCustomization_init {}

1;
