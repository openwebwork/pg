################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2018 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/contextLimitedPoint.pl,v 1.14 2009/06/25 23:28:44 gage Exp $
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

contextLimitedPoint.pl - Allow point entry but no point operations.

=head1 DESCRIPTION

Implements a context in which points can be entered,
but no operations are permitted between points.  So
students will be able to perform operations within the
coordinates of the points, but not between points.

	Context("LimitedPoint")

=cut

loadMacros("MathObjects.pl");

sub _contextLimitedPoint_init {LimitedPoint::Init()}; # don't load it again

##################################################
#
#  Handle common checking for BOPs
#
package LimitedPoint::BOP;

#
#  Do original check and then if the operands are numbers, its OK.
#  Otherwise report an error.
#
sub _check {
  my $self = shift;
  my $super = ref($self); $super =~ s/LimitedPoint/Parser/;
  &{$super."::_check"}($self);
  return if $self->checkNumbers;
  my $bop = $self->{def}{string} || $self->{bop};
  $self->Error("In this context, '%s' can only be used with Numbers",$bop);
}

##############################################
#
#  Now we get the individual replacements for the operators
#  that we don't want to allow.  We inherit everything from
#  the original Parser::BOP class, except the _check
#  routine, which comes from LimitedPoint::BOP above.
#

package LimitedPoint::BOP::add;
our @ISA = qw(LimitedPoint::BOP Parser::BOP::add);

##############################################

package LimitedPoint::BOP::subtract;
our @ISA = qw(LimitedPoint::BOP Parser::BOP::subtract);

##############################################

package LimitedPoint::BOP::multiply;
our @ISA = qw(LimitedPoint::BOP Parser::BOP::multiply);

##############################################

package LimitedPoint::BOP::divide;
our @ISA = qw(LimitedPoint::BOP Parser::BOP::divide);

##############################################
##############################################
#
#  Now we do the same for the unary operators
#

package LimitedPoint::UOP;

sub _check {
  my $self = shift;
  my $super = ref($self); $super =~ s/LimitedPoint/Parser/;
  &{$super."::_check"}($self);
  return if $self->checkNumber;
  my $uop = $self->{def}{string} || $self->{uop};
  $self->Error("In this context, '%s' can only be used with Numbers",$uop);
}

##############################################

package LimitedPoint::UOP::plus;
our @ISA = qw(LimitedPoint::UOP Parser::UOP::plus);

##############################################

package LimitedPoint::UOP::minus;
our @ISA = qw(LimitedPoint::UOP Parser::UOP::minus);

##############################################
##############################################
#
#  Absolute value does vector norm, so we
#  trap that as well.
#

package LimitedPoint::List::AbsoluteValue;
our @ISA = qw(Parser::List::AbsoluteValue);

sub _check {
  my $self = shift;
  $self->SUPER::_check;
  return if $self->{coords}[0]->type eq 'Number';
  $self->Error("Vector norm is not allowed in this context");
}

##############################################
##############################################

package LimitedPoint;

sub Init {
  #
  #  Build the new context that calls the
  #  above classes rather than the usual ones
  #

  my $context = $main::context{LimitedPoint} = Parser::Context->getCopy("Point");
  $context->{name} = "LimitedPoint";
  $context->operators->set(
    '+' => {class => 'LimitedPoint::BOP::add'},
    '-' => {class => 'LimitedPoint::BOP::subtract'},
    '*' => {class => 'LimitedPoint::BOP::multiply'},
   '* ' => {class => 'LimitedPoint::BOP::multiply'},
   ' *' => {class => 'LimitedPoint::BOP::multiply'},
    ' ' => {class => 'LimitedPoint::BOP::multiply'},
    '/' => {class => 'LimitedPoint::BOP::divide'},
   ' /' => {class => 'LimitedPoint::BOP::divide'},
   '/ ' => {class => 'LimitedPoint::BOP::divide'},
   'u+' => {class => 'LimitedPoint::UOP::plus'},
   'u-' => {class => 'LimitedPoint::UOP::minus'},
 );
  #
  #  Remove these operators and functions
  #
  $context->operators->undefine('_','U','><','.');
  $context->functions->undefine('norm','unit');
  $context->lists->set(
    AbsoluteValue => {class => 'LimitedPoint::List::AbsoluteValue'},
  );
  $context->parens->set(
    '(' => {formMatrix => 0},
    '[' => {formMatrix => 0},
  );
  $context->variables->are(x=>'Real');

  main::Context("LimitedPoint");  ### FIXME:  probably should require author to set this explicitly
}

1;
