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

parserSolutionFor.pl - An answer checker that checks if a student's answer
satisifies an implicit equation.

=head1 DESCRIPTION

This is a Parser class that implements an answer checker that
checks if a student's answer satisfies an implicit equation.
We define a SolutionFor object class that lets you specify an
equality that the student answer must satisfy, and a point that
DOES satify the equation.  The overloaded == operator will
check if a given point satisfies the given equality.

Use SolutionFor(equality,point[,options]) to create a SolutionFor object.
The equality is a Formula object containing an equality, or a string
representing such a formula, and the point is a Point object or string
containing a point that satisfies the equation (to be used as the
correct answer when the student asks to see the answers).

The variables to use are declared in the Context in the usual way,
and the coordinates of the student point will be considered to be in
alphabetical order.  You can override this by supplying the vars=>[...]
option, where you specify the variable names in the order you want the
student to give them.  E.g., vars=>['y','x'] will make the student answer
represent the point (y,x) rather than the default (x,y).

Usage examples:

	Context("Vector")->variables->are(x=>'Real',y=>'Real');
	$f = SolutionFor("x^2 = cos(y)","(1,0)");
	$f = SolutionFor("x^2 - y = 0",[2,4]);
	$f = SolutionFor("x^2 - y = 0",Point(4,2),vars=>['y','x']);

Then use

	ANS($f->cmp);

to get the answer checker for $f.

You can use $f->{f} to get the Formula object for the equality used
in the object, and $f->f(point) to determine if the given point is
a solution to the equality or not.  For example, if you want to include
the TeX version of a formula within the text of a problem, you can use:

	Context()->texStrings;
	BEGIN_TEXT
	A solution to \($f->{f}\) is \((x,y)\) = \{ans_rule(30)\}.
	END_TEXT
	Context()->normalStrings;
	ANS($f->cmp);

=cut

loadMacros("MathObjects.pl");

sub _parserSolutionFor_init {}; # don't reload this file

#
#  Create a SolutionFor object of the correct type
#
sub SolutionFor {
  #
  #  Get the professor's equation
  #
  my $context = SolutionFor::getContext();     # use a context in which equality is defined
  my $f = main::Formula($context,shift);       # get equation as a formula

  #
  #  Get the professor's correct point
  #
  my $p = shift; $p = main::Point($p) if ref($p) eq "ARRAY";
  $p = main::Compute($p) unless Value::isValue($p);

  #
  #  Get any user options (e.g., vars => ['x','y'])
  #
  my %options = (vars=>undef,@_);

  #
  #  Do some error checking
  #
  Value::Error("Your formula doesn't look like an implicit equation")
     unless $f->type eq 'Equality';
  Value::Error("Professor's answer should be a point or a number")
     unless Value::isNumber($p) || $p->type eq 'Point';

  #
  #  Save the formula for future reference, and make a callable
  #  perl function out of it.
  #
  $p->{f} = $f;
  $p->{F} = $f->perlFunction(undef,$options{vars});

  #
  #  Save some data about the original object
  #  and make the Value package think we are one of its objects
  #
  $p->{originalClass} = $p->cmp_class;
  $p->{isValue} = 1;

  #
  #  Make the object into the correct SolutionFor subclass
  #
  $p = bless $p, "SolutionFor::".$p->class;

  #
  #  Make sure professor's answer actually works
  #
  Value::Error("Professor's answer of %s does not satisfy the given equation",$p->string)
    unless $p->f($p);

  #
  #  Return the SolutionFor object
  #
  return $p;
}

######################################################################
#
#  Define the new class (we make subclasses below)
#  (we need subclasses in order to make things work
#  properly with single-variable complex or real-valued
#  equations)
#
package SolutionFor;

#
#  Evaluate the formula on the given point
#
sub f {
  my $self = shift;
  &{$self->{F}}(shift->value);
}

#
#  The name of this object for error messages
#
sub cmp_class {shift->{originalClass}}

#
#  Do a comparison by testing if the formula's equality
#  operation returns true or false.
#  (Since we are implementing <=> here, we need
#  to return 0 when true and 1 when false.)
#
sub compare {
  my ($l,$r) = @_;
  $r = Value::makeValue($r,context=>$l->context);
  return ($l->f($r)) ? 0 : 1;
}

#
#  Set up a new context that is a copy of the current one, but
#  has the equality operator defined, and the SolutionFor object
#  prededence set so that comparisons with points or numbers will
#  be promoted to comparisons with the SolutionFor
#
sub getContext {
  my $oldContext = main::Context();
  $oldContext->{precedence}{SolutionFor} = $oldContext->{precedence}{special};
  my $context = $oldContext->copy;
  Parser::BOP::equality->Allow($context);
  return $context
}

######################################################################
#
#  A separate class for Reals, to get Value::Real in the ISA list
#
package SolutionFor::Real;
our @ISA = qw(SolutionFor Value::Real Value);

#
#  Pass the real number directly
#
sub f {
  my $self = shift;
  &{$self->{F}}(shift);
}


######################################################################
#
#  A separate class for Complexes
#
package SolutionFor::Complex;
our @ISA = qw(SolutionFor Value::Complex Value);

#
#  Pass the complex number directly
#
sub f {
  my $self = shift;
  &{$self->{F}}(shift);
}

######################################################################
#
#  A separate class for Points
#
package SolutionFor::Point;
our @ISA = qw(SolutionFor Value::Point Value);

#
#  Use the Point's defaults, but turn off coordinate hints
#  (since a wrong coordinate isn't detectable)
#
sub cmp_defaults {(
  shift->SUPER::cmp_defaults,
  showCoordinateHints => 0,
)}

1; # make Perl happy
