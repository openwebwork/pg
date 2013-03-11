################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2013 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/parserParametricLine.pl,v 1.17 2009/06/25 23:28:44 gage Exp $
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

parserParametricPlane.pl - Implements Formulas that represent parametric planes
                           in three-space.

=head1 DESCRIPTION

This is a Parser class that implements parametric planes in 3D as a
subclass of the Formula class.  To use it, load this macro file, and
set the context to the ParametricPlane context:

	loadMacros("parserParametricPlane.pl");
	Context("ParametricPlane");

Use ParametricPlane(point,vector1,vector2) or ParametricPlane(formula)
to create a ParametricPlane object.  You can pass two optional
additional parameters that indicated the variables to use for the
parameter for the line (these are s and t by default).

Usage examples:

	$P = ParametricPlane(Point(3,-1,2),Vector(1,1,3),Vector(-1,2,0));
	$P = ParametricPlane([3,-1,2],[1,1,3],[-1,2,0]);
	$P = ParametricPlane("<3+t-s,t+2s-1,2+2t>");

	$p = Point(3,-1,2); $v1 = Vector(1,1,3); $v2 = Vector(-1,2,0)
	$P = ParametricPlane($p,$v1,$v2);

	$s = Formula('s'); $t = Formula('t');
        $p = Point(3,-1,2); $v1 = Vector(1,1,3); $v2 = Vector(-1,2,0);
	$P = ParametricPlane($p+$s*$v1+$t*$v2);

	Context()->constants->are(a=>1+pi^2); # won't guess this value
	$P = ParametricPlane("(a,2a,-1) + t <1,a,a^2> + s <2a,0,1-a>");

Then use

   ANS($P->cmp);

to get the answer checker for $P.

=cut

loadMacros('MathObjects.pl');

sub _parserParametricPlane_init {ParametricPlane::Init()}; # don't reload this file

#
#  Define the subclass of Formula
#
package ParametricPlane;
our @ISA = qw(Value::Formula);

sub Init {
  my $context = $main::context{ParametricPlane} = Parser::Context->getCopy("Vector");
  $context->{name} = "ParametricPlane";
  $context->variables->are(s=>'Real',t=>'Real');
  $context->{precedence}{ParametricPlane} = $context->{precedence}{special};
  $context->reduction->set('(-x)-y'=>0);

  main::PG_restricted_eval('sub ParametricPlane {ParametricPlane->new(@_)}');
}

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my ($p,$v1,$v2,$plane,$s,$t);
  return shift if scalar(@_) == 1 && ref($_[0]) eq $class;
  $_[0] = $context->Package("Point")->new($context,$_[0]) if ref($_[0]) eq 'ARRAY';
  $_[1] = $context->Package("Vector")->new($context,$_[1]) if ref($_[1]) eq 'ARRAY';
  $_[2] = $context->Package("Vector")->new($context,$_[2]) if ref($_[2]) eq 'ARRAY';
  if (scalar(@_) >= 3 && Value::classMatch($_[0],'Point') &&
                         Value::classMatch($_[1],'Vector') &&
                         Value::classMatch($_[2],'Vector')) {
    $p = shift; $v1 = shift; $v2 = shift;
    $s = shift || 's'; $s = $context->Package("Formula")->new($context,$s) unless Value::isFormula($s);
    $t = shift || 't'; $t = $context->Package("Formula")->new($context,$t) unless Value::isFormula($t);
    $plane = $p + $s*$v1 + $t*$v2;
  } else {
    $plane = $context->Package("Formula")->new($context,shift);
    Value::Error("Your formula doesn't look like a parametric plane")
      unless $plane->type eq 'Vector' || $plane->type eq "Point";
    $s = shift || (keys %{$plane->{variables}})[0];
    $t = shift || (keys %{$plane->{variables}})[1];
    Value::Error("A plane must have two variables") unless $t && $s;
    $p = $context->Package("Point")->new($context,$plane->eval($s=>0,$t=>0));
    $v1 = $context->Package("Vector")->new($context,$plane->eval($s=>1,$t=>0) - $p);
    $v2 = $context->Package("Vector")->new($context,$plane->eval($s=>0,$t=>1) - $p);
    Value::Error("Your formula isn't linear in at least one of its variables (%s and %s)",$s,$t)
      unless $plane == $p + $context->Package("Formula")->new($context,$s) * $v1
                          + $context->Package("Formula")->new($context,$t) * $v2;
  }
  Value::Error("Parametric Planes must be in three-space") unless $plane->length == 3;
  Value::Error("The direction vectors for a parametric plane can't be zero vectors")
    if $v1->norm == 0 || $v2->norm == 0;
  Value::Error("The direction vectors for a parametric plane can't be parallel")
    if $v1->isParallel($v2);
  $plane->{p} = $p; $plane->{v1} = $v1; $plane->{v2} = $v2;
  $plane->{isValue} = $plane->{isFormula} = 1;
  return bless $plane, $class;
}

=head2 $lhs == $rhs

 #
 #  Two parametric planes are equal if their implicit forms are equal
 #

=cut

sub compare {
  my ($self,$l,$r) = Value::checkOpOrderWithPromote(@_);
  my ($lp,$lv1,$lv2) = ($l->{p},$l->{v1},$l->{v2});
  my ($rp,$rv1,$rv2) = ($r->{p},$r->{v1},$r->{v2});
  my ($lN,$rN) = ($lv1 x $lv2, $rv1 x $rv2);
  my ($ld,$rd) = ($lN . $lp, $rN . $rp);
  if ($rd == 0 || $ld == 0) {
    return $rd <=> $ld unless $ld == $rd;
    return $lN <=> $rN unless (areParallel $lN $rN);
    return 0;
  }
  return $rd*$lN <=> $ld*$rN;
}

sub cmp_class {'a Parametric Plane'};
sub showClass {shift->cmp_class};

sub cmp_defaults {(
  shift->SUPER::cmp_defaults,
  showEqualErrors => 0,  # don't show problems evaluating student answer
  ignoreInfinity => 0,   # report infinity as an error
)}

#
#  Report some errors that were stopped by the showEqualErrors=>0 above.
#
sub cmp_postprocess {
  my $self = shift; my $ans = shift;
  my $error = $self->context->{error}{message};
  $self->cmp_error($ans)
    if $error =~ m/^(Your formula (isn't linear|doesn't look)|A plane must|The direction vectors)/;
}

1;
