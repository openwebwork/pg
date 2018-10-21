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

contextABCD.pl - Contexts for matching problems.

=head1 DESCRIPTION

Implements contexts for string-valued answers especially
for matching problems (where you match against A, B, C, D,
and so on).

There are two contexts defined here,

	Context("ABCD");
	Context("ABCD-List");

The second allows the students to enter lists of strings,
while the first does not.

You can add new strings to the context as needed (or remove old ones)
via the Context()->strings->add() and Context()-strings->remove()
methods, eg.

	Context("ABCD-List")->strings->add(E=>{},e=>{alias=>"E"});

Use string_cmp() to produce the answer checker(s) for your
correct values.  Eg.

	ANS(string_cmp("A","B"));

when there are two answers, the first being "A" and the second being "B".

=cut

loadMacros("MathObjects.pl","contextString.pl");

sub _contextABCD_init {
  my $context = $main::context{ABCD} = Parser::Context->getCopy("String");
  $context->{name} = "ABCD";
  $context->strings->are(
    "A" => {},
    "B" => {},
    "C" => {},
    "D" => {},
   );

  $context = $main::context{'ABCD-List'} = $context->copy;
  $context->operators->redefine(',', from => "Full");
  $context->strings->add("NONE"=>{});

  main::Context("ABCD");  ### FIXME:  probably should make author select context explicitly
}

1;
