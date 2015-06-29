################################################################################
# WeBWorK Online Homework Delivery System
# Copyright � 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
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

contextTrigDegrees.pl - for trigonometric functions evaluated in degrees.

=head1 DESCRIPTION

This is a Parser context that redefines existing trigonometric functions
from radians to degrees. The trigonometric functions can be used by the
problem author and also by students if the answer checking is done by
Parser.  The latter is the main purpose of this file.

B<Note:> By default, webwork problems evaluate trigonometric functions
in radians.  Problems which evaluate trigonometric functions in degrees
should alert the student in their text.

=head1 USAGE

	Context("TrigDegrees")
	
	$a = 60;
        $b = Compute("cos($a)");
	ANS($b->cmp);

=head1 AUTHORS

Davide Cervone (Union College, Schenectady, New York, USA)

Paul Pearson (Hope College, Holland, Michigan, USA)

=cut

loadMacros('MathObjects.pl');

sub _contextTrigDegrees_init {context::TrigDegrees::Init()}; # don't reload this file

#######################################

package context::TrigDegrees::common;

my $deg = $main::PI / 180;

#
#  Check the number of arguments, and call the proper method with the
#  the proper factor involved.
#
sub _call {
  my $self = shift; my $name = shift;
  Value::Error("Function '%s' has too many inputs",$name) if scalar(@_) > 1;
  Value::Error("Function '%s' has too few inputs",$name) if scalar(@_) == 0;
  my $n = $_[0];
  if (!Value::matchNumber($n)) {
    my $context = (Value::isValue($n) ? $n : $self)->context;
    return $self->Package("Complex")->promote($context,$n)->$name;
  }
  if ($self->context->{functions}{$name}{isInverse}) {
    return $self->$name($n) / $deg;
  } else {
    return $self->$name($n * $deg);
  }
}

#
#  Call the proper method with the correct factor
#
sub _eval {
  my $self = shift; my $name = $self->{name};
  return $_[0]->$name if Value::isComplex($_[0]);
  if ($self->{def}{isInverse}) {
    return $self->$name(@_) / $deg;
  } else {
    return $self->$name($_[0] * $deg);
  }
}

#
#  Do chain rule derivative, taking the $deg factor into account
#
sub D {
  my $self = shift; my $x = $self->{params}[0];
  my $name = "D_" . $self->{name};
  my $equation = $self->{equation};
  my $BOP = $self->Item("BOP"), $NUMBER = $self->Item("Number"), $CONSTANT = $self->Item("Constant");
  my $num = $CONSTANT->new($equation,"pi"), $den = $NUMBER->new($equation,180);
  ($num,$den) = ($den,$num) if $self->{def}{isInverse};
  $self = $BOP->new($equation,"*",
    $BOP->new($equation,"/",$num,$den),
    $BOP->new($equation,'*',$self->$name($x->copy),$x->D(shift))
  );
  return $self->reduce;
}

#######################################

#
#  Hook the common functions into these classes
#

package context::TrigDegrees::trig;
our @ISA = ('context::TrigDegrees::common','Parser::Function::trig');

package context::TrigDegrees::hyperbolic;
our @ISA = ('context::TrigDegrees::common','Parser::Function::hyperbolic');

#######################################

package context::TrigDegrees::numeric2;
our @ISA = ('Parser::Function::numeric2');

my $deg = $main::PI / 180;

sub atan2 {CORE::atan2($_[1],$_[2]) / $deg}

#######################################

package context::TrigDegrees;

#
#  Change the classes for the trig functions to be our classes above,
#  and mark the inverses so that the degrees can be applied in the
#  proper location.
#
#  Define the sin, cos, and atan2 functions so that they will call our
#  methods even if their arguments are Perl reals.
#
sub Init {
  my $context = $main::context{TrigDegrees} = Parser::Context->getCopy("Numeric");
  $context->{name} = "TrigDegrees";
  $context->functions->set(
    cos => {class => 'context::TrigDegrees::trig'},
    sin => {class => 'context::TrigDegrees::trig'},
    tan => {class => 'context::TrigDegrees::trig'},
    sec => {class => 'context::TrigDegrees::trig'},
    csc => {class => 'context::TrigDegrees::trig'},
    cot => {class => 'context::TrigDegrees::trig'},
    acos => {class => 'context::TrigDegrees::trig', isInverse => 1},
    asin => {class => 'context::TrigDegrees::trig', isInverse => 1},
    atan => {class => 'context::TrigDegrees::trig', isInverse => 1},
    asec => {class => 'context::TrigDegrees::trig', isInverse => 1},
    acsc => {class => 'context::TrigDegrees::trig', isInverse => 1},
    acot => {class => 'context::TrigDegrees::trig', isInverse => 1},
    atan2 => {class => 'context::TrigDegrees::numeric2', isInverse => 1},
    cosh => {class => 'context::TrigDegrees::hyperbolic'},
    sinh => {class => 'context::TrigDegrees::hyperbolic'},
    tanh => {class => 'context::TrigDegrees::hyperbolic'},
    sech => {class => 'context::TrigDegrees::hyperbolic'},
    csch => {class => 'context::TrigDegrees::hyperbolic'},
    coth => {class => 'context::TrigDegrees::hyperbolic'},
    acosh => {class => 'context::TrigDegrees::hyperbolic', isInverse => 1},
    asinh => {class => 'context::TrigDegrees::hyperbolic', isInverse => 1},
    atanh => {class => 'context::TrigDegrees::hyperbolic', isInverse => 1},
    asech => {class => 'context::TrigDegrees::hyperbolic', isInverse => 1},
    acsch => {class => 'context::TrigDegrees::hyperbolic', isInverse => 1},
    acoth => {class => 'context::TrigDegrees::hyperbolic', isInverse => 1},
  );

  main::PG_restricted_eval('sub sin {CommonFunction->Call("sin",@_)}');
  main::PG_restricted_eval('sub cos {CommonFunction->Call("cos",@_)}');
  main::PG_restricted_eval('sub atan2 {CommonFunction->Call("atan2",@_)}');
}

1;
