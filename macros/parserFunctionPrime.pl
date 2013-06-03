################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2012 The WeBWorK Project, http://openwebwork.sf.net/
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

parserFunctionPrime.pl - Allow f' notation for parserFunction objects.

=head1 DESCRIPTION

This file implements prime notation for derivatives for functions added
to the Context via a parserFunction() call.  For example, if you have
done

    parserFunction("f(x)" => "3x^2+x-2");

then you can use

    $f = Formula("f'(x)");

to get the equivalent of Formula("6x+1"), and

    $f = Formula("f''(x)");

for the equivalent of Formula("6").  Students can also type primes in
their answers, so if you define parserFunction's for f and g, you can
ask "What is the derivative of f(g(x))" and expect them to answer
"f'(g(x))g'(x)" (and you can also type the same thing as the correct
answer for the problem).

To enable prime notation, first load the parserFunctionPrime.pl file,
and then call parser::FunctionPrime->Enable() command after having
selected the Context that you want to use.  For example:

    loadMacros(
      "PGstandard.pl",
      "parserFunctionPrime.pl",
      "PGcourse.pl",
    );
    
    Context("Numeric");
    parser::FunctionPrime->Enable();

Note that parserFunctionPrime.pl loads parserFunction.pl automatically, so
you don't have to load both.

=cut

loadMacros(
  'MathObjects.pl',
  'parserFunction.pl',
);

sub _parserFunctionPrime_init {}; # don't reload this file

#
#  The package that will manage function primes
#
package parser::FunctionPrime;
our @ISA = qw(Parser::Function);


=head2 parser::FunctionPrime->Enable($context)

This enables prime notation for parserFunction objects in the given
context (or if no context is given, in the current context).

=cut

sub Enable {
  my $self = shift;
  my $context = shift || main::Context();
  #
  #  Add a special pattern that will allow function names followed by
  #  any number of primes, and override the Parser::Function class
  #  to handle these.
  #
  $context->{_functions}{patterns} = {qr/[a-z][a-z0-9]*'+/i => [-1,'fn']};
  $context->{_functions}->update;
  $context->{parser}{Function} = "parser::FunctionPrime";
}

=head2 parser::FunctionPrime->Disable($context)

This disables prime notation for parserFunction objects in the given
context (or if no context is given, in the current context).

=cut

sub Disable {
  my $self = shift;
  my $context = shift || main::Context();
  delete $context->{_functions}{patterns}{qr/[a-z][a-z0-9]*'+/i};
  $context->{_functions}->update;
  $context->{parser}{Function} = "Parser::Function";
}

#
#  Override the Parser::Function new() method to handle names with primes.
#  When such a name appears, define a new (hidden) parserFunction that
#  has the proper function and formula for the number of derivatives
#  requested.
#
sub new {
  my $self = shift; my $equation = shift;
  my $name = shift; my $ref = $_[2];
  my $context = $equation->{context};
  #
  #  If the name has primes and we haven't already created
  #  the associated function definition, then do so now.
  #
  if ($name =~ m/'/ && !$context->{functions}{$name}) {
    my $shortname = $name; $shortname =~ s/'//g;
    my $def = $context->{functions}{$shortname};
    #
    #  Check that the function is a single-variable parserFunction
    #
    $equation->Error(["Function '%s' is not defined",$shortname],$ref) unless $def;
    $equation->Error(["Can't use primes with '%s'",$shortname],$ref) unless $def->{class} eq 'parserFunction';
    $equation->Error(["Prime can only be used on single-variable functions"],$ref) unless $def->{argCount} == 1;
    #
    #  Make a (hidden) copy of the original parserFunction data
    #  and replace the function and formula by the appropriate
    #  derivative of the  original.
    #
    my $fn = {%{$def}, hidden => 1};
    my $n = length($name) - length($shortname);
    my $f = $def->{formula}, $x = $def->{argNames}[0];
    while ($n) {$f = $f->D($x); $n--}
    $fn->{function} = $f->perlFunction(undef,[$x]);
    $fn->{formula} = $f;
    $fn->{TeX} = (length($shortname) == 1 ? $name : "{\\rm ".$shortname."}".substr($name,length($shortname)));
    $context->{functions}{$name} = $fn;
  }
  #
  #  Make the function node as usual, now that the data is
  #  in place for the derivative.
  #
  $self->SUPER::new($equation,$name,@_);
}

1;
