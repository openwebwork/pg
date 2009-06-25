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

contextTF.pl - Imlements contexts for true/false problems.

=head1 DESCRIPTION

Implements contexts for string-valued answers especially
for matching problems (where you match against T and F).

	Context("TF");

You can add new strings to the context as needed (or remove old ones)
via the Context()->strings->add() and Context()-strings->remove()
methods.

Use:

	ANS(string_cmp("T","F"));

when there are two answers, the first being "T" and the second being "F".

=cut

loadMacros("MathObjects.pl","contextString.pl");

sub _contextTF_init {

  my $context = $main::context{TF} = Parser::Context->getCopy("String");
  $context->{name} = "TF";
  $context->strings->are(
    "T" => {value => 1},
    "F" => {value => 0},
    "True" => {alias => "T"},
    "False" => {alias => "F"},
  );

  main::Context("TF");  ### FIXME:  probably should require author to set this explicitly
}

1;
