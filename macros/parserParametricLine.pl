################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2018 The WeBWorK Project, http://openwebwork.sf.net/
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

parserParametricLine.pl - Implements Formulas that represent parametric lines.

=head1 DESCRIPTION

This is a Parser class that implements parametric lines as
a subclass of the Formula class.  The standard ->cmp routine
will work for this, provided we define the compare() function
needed by the overloaded ==.  We assign the special precedence
so that overloaded operations will be promoted to the ones below.

Use ParametricLine(point,vector) or ParametricLine(formula)
to create a ParametricLine object.  You can pass an optional
additional parameter that indicated the variable to use for the
parameter for the line.

Usage examples:

	$L = ParametricLine(Point(3,-1,2),Vector(1,1,3));
	$L = ParametricLine([3,-1,2],[1,1,3]);
	$L = ParametricLine("<t,1-t,2t-3>");

	$p = Point(3,-1,2); $v = Vector(1,1,3);
	$L = ParametricLine($p,$v);

	$t = Formula('t'); $p = Point(3,-1,2); $v = Vector(1,1,3);
	$L = ParametricLine($p+$t*$v);

	Context()->constants->are(a=>1+pi^2); # won't guess this value
	$L = ParametricLine("(a,2a,-1) + t <1,a,a^2>");

Then use

   ANS($L->cmp);

to get the answer checker for $L.

=cut

loadMacros('MathObjects.pl');

sub _parserParametricLine_init {ParametricLine::Init()}; # don't reload this file

#
#  Define the subclass of Formula
#
package ParametricLine;
our @ISA = qw(Value::Formula);

sub Init {
  my $context = $main::context{ParametricLine} = Parser::Context->getCopy("Vector");
  $context->{name} = "ParametricLine";
  $context->variables->are(t=>'Real');
  $context->{precedence}{ParametricLine} = $context->{precedence}{special};
  $context->reduction->set('(-x)-y'=>0);

  main::Context("ParametricLine");  ### FIXME:  probably should require author to set this explicitly

  main::PG_restricted_eval('sub ParametricLine {ParametricLine->new(@_)}');
}

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my ($p,$v,$line,$t);
  return shift if scalar(@_) == 1 && ref($_[0]) eq $class;
  $_[0] = $context->Package("Point")->new($context,$_[0]) if ref($_[0]) eq 'ARRAY';
  $_[1] = $context->Package("Vector")->new($context,$_[1]) if ref($_[1]) eq 'ARRAY';
  if (scalar(@_) >= 2 && Value::classMatch($_[0],'Point') &&
                         Value::classMatch($_[1],'Vector')) {
    $p = shift; $v = shift;
    $t = shift || $context->Package("Formula")->new($context,'t');
    $line = $p + $t*$v;
  } else {
    $line = $context->Package("Formula")->new($context,shift);
    Value::Error("Your formula doesn't look like a parametric line")
      unless $line->type eq 'Vector' || $line->type eq "Point";
    $t = shift || (keys %{$line->{variables}})[0];
    Value::Error("A line can't be just a constant vector") unless $t;
    $p = $context->Package("Point")->new($context,$line->eval($t=>0));
    $v = $context->Package("Vector")->new($context,$line->eval($t=>1) - $p);
    Value::Error("Your formula isn't linear in the variable %s",$t)
      unless $line == $p + $context->Package("Formula")->new($context,$t) * $v;
  }
  Value::Error("The direction vector for a parametric line can't be the zero vector")
    if ($v->norm == 0);
  $line->{p} = $p; $line->{v} = $v;
  $line->{isValue} = $line->{isFormula} = 1;
  return bless $line, $class;
}

=head2 $lhs == $rhs

 #
 #  Two parametric lines are equal if they have
 #  parallel direction vectors and either the same
 #  points or the vector between the points is
 #  parallel to the (common) direction vector.
 #

=cut

sub compare {
  my ($self,$l,$r) = Value::checkOpOrderWithPromote(@_);
  my ($lp,$lv) = ($l->{p},$l->{v});
  my ($rp,$rv) = ($r->{p},$r->{v});
  return $lv <=> $rv unless ($lv->isParallel($rv));
  return 0 if $lp == $rp || $lv->isParallel($rp-$lp);
  return $lp <=> $rp;
}

sub cmp_class {'a Parametric Line'};
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
    if $error =~ m/^(Your formula (isn't linear|doesn't look)|A line can't|The direction vector)/;
}

1;
