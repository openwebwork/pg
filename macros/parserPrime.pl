################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2009 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/parserPrime.pl,v 1.2 2009/10/03 15:58:49 dpvc Exp $
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

parserPrime.pl - defines a prime operator (') to perform differentiation
                 (can be used in student answers as well).

=head1 DESCRIPTION

This file defines the code necessary to make the prime (') operator perform
differentiation within a Formula object.  For example, Formula("(x^2)'") would
equal Formula("2*x"), and Formula("(x^2)''") would equal Real(2).  The context
also includes reduction rules to replace the prime notaiton by the actual
derivative.

To accomplish this, put the line

	loadMacros("parserPrime.pl");

at the beginning of your problem file, then set the Context to the one you wish
to use in the problem.  Then use the command:

	parser::Prime->Enable;

(You can also pass the Enable command a context pointer if you wish to
alter a context other than the current one.)

Once this is done, you will be able to enter primes in your Formulas
to refer to differentiation.  For example:

	Formula("(3x^2+2x+1)'")

would mean the derivative of 3x^2+2x+1 and would be equivalent to

	Formula("3*2*x+2")

The variable of differentiation is taken from the variables used in
the formula being differentiated.  If there is more than one variable
used, the first one alphabetically is used.  For example

	Formula("(ln(x))' + (x^2+3y)'")

would produce the equivalent to

	Formula("(1/x) + (2*x+0)").

This can have unexpected results, however, since.

	Formula("(x^2)' + (y^2)'")

would generate

	Formula("2*x + 2*y")

which may not be what you want.  In order to specify the variable for
differentiation, you can list it in the Enable() call.  For example:

	parser::Prime->Enable("x");

would make

	Formula("(x^2)' + (y^2)'")

generate

	Formula("2*x + 0")

rather than the default 2x+2y.

The prime operator also defines a reduction rule that allows the prime
notation to be replaced by the actual derivative when the Formula is
reduced.  This is off by default, but you can set it via

	Context()->reduction->set("(f)'"=>1);

so that it will be on for all reductions, or specify it for a single
reduction as follows:

	$f = Formula("(x^2)'")->reduce("(f)'"=>1);

to obtain $f as Formula("2*x").

Note that once the prime has been added to the Context, student
answers will be allowed to include primes as well, so if you want
students to actually perform the differentiation themselves, you may
wish to disable the prime at the end of the problem (so it will not be
active while student answers are being parsed).  To do that use

	parser::Prime->Disable;

(You can pass Disable a context pointer to remove the prime operator
from a context other than the current one.)

=cut

sub _parserPrime_init {};    # don't load a second time

##########################################
#
#  Package to enable and disable the prime operator
#
package parser::Prime;

#
#  Add prime to the given or current context
#
sub Enable {
  my $self = shift; my $x = shift;
  my $context = main::Context();
  if (Value::isContext($x)) {$context = $x; $x = shift}
  $context->operators->add("'"=>{
    precedence => 8.5, associativity => "right", type => "unary", string => "'",
    class => "parser::Prime::UOP::prime", isCommand => 1
  });
  $context->reduction->set("(f)'" => 0);
  $context->flags->set(prime_variable => $x) if defined($x);
}

#
#  Remove prime from the context
#
sub Disable {
  my $self = shift; my $context = shift || main::Context();
  $context->operators->remove("'");
}

##########################################
#
#  Prime operator is a subclass of the unary operator class
#
package parser::Prime::UOP::prime;
our @ISA = ('Parser::UOP');

#
#  Do a typecheck on the operand
#
sub _check {
  my $self = shift;
  return if $self->checkInfinite || $self->checkString ||
            $self->checkList || $self->checkNumber;
  $self->{type} = {%{$self->{op}->typeRef}};
}

#
#  A hack to prevent double-primes from inserting parentheses
#   in string and TeX output (change the precedence to hide it)
#
sub string {
  my ($self,$precedence,$showparens,$position,$outerRight) = @_;
  my $uop = $self->{def}; $precedence -= .01 if $uop->{precedence} == $precedence;
  return $self->SUPER::string($precedence,$showparens,$position,$outerRight);
}
sub TeX {
  my ($self,$precedence,$showparens,$position,$outerRight) = @_;
  my $uop = $self->{def}; $precedence -= .01 if $uop->{precedence} == $precedence;
  return $self->SUPER::TeX($precedence,$showparens,$position,$outerRight);
}

#
#  Produce a perl version of the derivative
#
sub perl {
  my $self = shift;
  return $self->{op}->D($self->getVar)->perl;
}

#
#  Evaluate the derivative
#
sub eval {
  my $self = shift;
  return $self->{op}->D($self->getVar)->eval;
}

#
#  Reduce by replacing with derivative
#
sub reduce {
  my $self = shift;
  return $self unless $self->context->{reduction}{"(f)'"};
  return $self->{op}->D($self->getVar);
}

sub getVar {
  my $self = shift;
  return $self->context->flag("prime_variable") ||
         (keys(%{$self->getVariables}))[0] ||
	 (keys(%{$self->{equation}{variables}}))[0] || 'x';
}


#
#  Handle derivative by taking derivative of a prime by taking
#  derivative of the prime's value (which is itself a derivative)
#
sub D {
  my $self = shift; my $x = shift;
  return $self->{op}->D($x)->D($x);
}

1;

