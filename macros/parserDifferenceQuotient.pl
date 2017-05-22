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

parserDifferenceQuotient.pl - An answer checker for difference quotients.

=head1 DESCRIPTION

This is a Parser class that implements an answer checker for
difference quotients as a subclass of the Formula class.  The
standard ->cmp routine will work for this.  The difference quotient
is just a special type of formula with a special variable
for 'dx'.  The checker will give an error message if the
student's result contains a dx in the denominator, meaning it
is not fully reduced.

Use DifferenceQuotient(formula) to create a difference equation
object.  If the context has more than one variable, the last one
alphabetically is used to form the dx.  Otherwise, you can specify
the variable used for dx as the second argument to
DifferenceQuotient().  You could use a variable like h instead of
dx if you prefer.  This is specified in the second argument.
If you want to identify division by zero when a value other than
zero is substituted in for dx (or h), then the third argument is a 
number to be substituted into the variable named in the second 
argument.  The third argument is optional and the default value
0 is used when the third argument is omitted.

=head1 USAGE

        # simplify (f(x+dx)-f(x)) / dx for f(x)=x^2
	$df = DifferenceQuotient("2x+dx");
	ANS($df->cmp);

        # simplify (f(x+h)-f(x)) / h for f(x) = x^2
	$df = DifferenceQuotient("2x+h","h");
	ANS($df->cmp);
	
        # simplify (f(t+dt)-f(t)) / dt for f(t)=a/t
	Context()->variables->are(t=>'Real',a=>'Real');
	ANS(DifferenceQuotient("-a/[t(t+dt)]","dt")->cmp);

        # simplify (f(x)-f(c)) / (x-c) for f(x)=x^2 at c=3
	$df = DifferenceQuotient("x+3","x",3);

        # simplify (x^2 - 4) / (x-2)
        $df = DifferenceQuotient("x+2","x",2);
	ANS($df->cmp);

=cut

loadMacros('MathObjects.pl');

sub _parserDifferenceQuotient_init {DifferenceQuotient::Init()}; # don't reload this file

package DifferenceQuotient;
our @ISA = qw(Value::Formula);

sub Init {
  main::Context("Numeric");  ### FIXME:  probably should require author to set this explicitly
  main::PG_restricted_eval('sub DifferenceQuotient {new DifferenceQuotient(@_)}');
}

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $current = (Value::isContext($_[0]) ? shift : $self->context);
  my $formula = shift;
  my $dx = shift || $current->flag('diffQuotientVar') || 'd'.($current->variables->names)[-1];
  my $zp = shift || 0; # division by zero point
  #
  #  Make a copy of the context to which we add a variable for 'dx'
  #
  my $context = $current->copy;
  $context->variables->add($dx=>'Real') unless ($context->variables->get($dx));
  $q = bless $context->Package("Formula")->new($context,$formula), $class;
  $q->{'dx'} = $dx;
  $q->{'zp'} = $zp; # the division by zero point
  return $q;
}

sub cmp_class {'a Difference Quotient'}

sub cmp_defaults{(
  shift->SUPER::cmp_defaults,
  ignoreInfinity => 0,
)}

sub cmp_postprocess {
  my $self = shift; my $ans = shift; my $dx = $self->{'dx'}; my $zp = $self->{'zp'};
  return if $ans->{score} == 0 || $ans->{isPreview};
  $main::__student_value__ = $ans->{student_value};
  my ($value,$err) = main::PG_restricted_eval('$__student_value__->substitute(\''.$dx.'\'=>\''.$zp.'\')->reduce');
  $self->cmp_Error($ans,"It looks like you didn't finish simplifying your answer")
    if $err && $err =~ m/division by zero/i;
}

1;
