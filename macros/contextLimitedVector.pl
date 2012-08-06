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

contextLimitedVector.pl - Allow vector entry but no vector operations.

=head1 DESCRIPTION

Implements a context in which vectors can be entered,
but no vector operations are permitted.  So students will
be able to perform operations within the coordinates
of the vectors, but not between vectors.

Vectors can still be entered either in < , , > or ijk format.
Most of the complication here is to handle ijk format
properly.  Each coordinate vector is allowed to appear
only once, so we have to keep track of that, and allow
SOME vector operations, but only when one term is
one of the coordinate constants, or one of the formulas
we've already OKed.

You control which format to use by setting the context
to one of the following:

	 Context("LimitedVector-coordinate");
	 Context("LimitedVector-ijk");
	 Context("LimitedVector");      # either one

=cut

loadMacros("MathObjects.pl");

sub _contextLimitedVector_init {LimitedVector::Init()}; # don't load it again

##################################################
#
#  Handle common checking for BOPs
#
package LimitedVector::BOP;

#
#  Do original check and then if the operands are numbers, its OK.
#  Otherwise, check if there is a duplicate constant from either term
#  Otherwise, do an operator-specific check for if vectors are OK.
#  Otherwise report an error.
#
sub _check {
  my $self = shift;
  my $super = ref($self); $super =~ s/LimitedVector/Parser/;
  &{$super."::_check"}($self);
  return if $self->checkNumbers;
  if ($self->context->{flags}{vector_format} ne 'coordinate') {
    $self->checkConstants($self->{lop});
    $self->checkConstants($self->{rop});
    return if $self->checkVectors;
  }
  my $bop = $self->{def}{string} || $self->{bop};
  $self->Error("In this context, '%s' can only be used with Numbers",$bop)
    if $self->{equation}{context}{flags}{vector_format} eq 'coordinate';
  $self->Error("In this context, '%s' can only be used with Numbers or i,j and k",$bop);
}

#
#  filled in by subclasses
#
sub checkVectors {return 0}

#
#  Check if a constant has been repeated
#  (we maintain a hash that lists if one is below us in the parse tree)
#
sub checkConstants {
  my $self = shift; my $op = shift;
  my $duplicate = '';
  if ($op->class eq 'Constant') {
    return unless $op->{name} =~ m/^[ijk]$/;
    $duplicate = $op->{name} if $self->{ijk}{$op->{name}};
    $self->{ijk}{$op->{name}} = 1;
  } else {
    foreach my $x ('i','j','k') {
      $duplicate = $x if $self->{ijk}{$x} && $op->{ijk}{$x};
      $self->{ijk}{$x} = $self->{ijk}{$x} || $op->{ijk}{$x};
    }
  }
  Value::Error("The constant '%s' may appear only once in your formula",$duplicate)
    if $duplicate;
}

##############################################
#
#  Now we get the individual replacements for the operators
#  that we don't want to allow.  We inherit everything from
#  the original Parser::BOP class, and just add the
#  vector checks here.
#

package LimitedVector::BOP::add;
our @ISA = qw(LimitedVector::BOP Parser::BOP::add);

sub checkVectors {
  my $self = shift;
  return (($self->{lop}->class eq 'Constant' || $self->{lop}->class =~ m/[BU]OP/) &&
          ($self->{rop}->class eq 'Constant' || $self->{rop}->class =~ m/[BU]OP/));
}

##############################################

package LimitedVector::BOP::subtract;
our @ISA = qw(LimitedVector::BOP Parser::BOP::subtract);

sub checkVectors {
  my $self = shift;
  return (($self->{lop}->class eq 'Constant' || $self->{lop}->class =~ m/[BU]OP/) &&
          ($self->{rop}->class eq 'Constant' || $self->{rop}->class =~ m/[BU]OP/));
}

##############################################

package LimitedVector::BOP::multiply;
our @ISA = qw(LimitedVector::BOP Parser::BOP::multiply);

sub checkVectors {
  my $self = shift;
  return (($self->{lop}->class eq 'Constant' || $self->{lop}->type eq 'Number') &&
	  ($self->{rop}->class eq 'Constant' || $self->{rop}->type eq 'Number'));
}

##############################################

package LimitedVector::BOP::divide;
our @ISA = qw(LimitedVector::BOP Parser::BOP::divide);

sub checkVectors {
  my $self = shift;
  my $bop = $self->{def}{string} || $self->{bop};
  $self->Error("In this context, '%s' can only be used with Numbers",$bop);
}

##############################################
##############################################
#
#  Now we do the same for the unary operators
#

package LimitedVector::UOP;

sub _check {
  my $self = shift;
  my $super = ref($self); $super =~ s/LimitedVector/Parser/;
  &{$super."::_check"}($self);
  return if $self->checkNumber;
  if ($self->context->{flags}{vector_format} ne 'coordinate') {
    LimitedVector::BOP::checkConstants($self,$self->{op});
    return if $self->checkVector;
  }
  my $uop = $self->{def}{string} || $self->{uop};
  $self->Error("In this context, '%s' can only be used with Numbers",$uop)
    if $self->{equation}{context}{flags}{vector_format} eq 'coordinate';
  $self->Error("In this context, '%s' can only be used with Numbers or i,j and k",$uop);
}

sub checkVector {return 0}

##############################################

package LimitedVector::UOP::plus;
our @ISA = qw(LimitedVector::UOP Parser::UOP::plus);

sub checkVector {return shift->{op}->class eq 'Constant'}

##############################################

package LimitedVector::UOP::minus;
our @ISA = qw(LimitedVector::UOP Parser::UOP::minus);

sub checkVector {return shift->{op}->class eq 'Constant'}

##############################################
##############################################
#
#  Absolute value does vector norm, so we
#  trap that as well.
#

package LimitedVector::List::AbsoluteValue;
our @ISA = qw(Parser::List::AbsoluteValue);

sub _check {
  my $self = shift;
  $self->SUPER::_check;
  return if $self->{coords}[0]->type eq 'Number';
  $self->Error("Vector norm is not allowed in this context");
}

##############################################

package LimitedVector::List::Vector;
our @ISA = qw(Parser::List::Vector);

sub _check {
  my $self = shift;
  $self->SUPER::_check;
  return if $self->context->{flags}{vector_format} ne 'ijk';
  $self->Error("Vectors must be given in the form 'ai+bj+ck' in this context");
}

##############################################
##############################################

package LimitedVector;

sub Init {
  #
  #  Build the new context that calls the
  #  above classes rather than the usual ones
  #

  my $context = $main::context{LimitedVector} = Parser::Context->getCopy("Vector");
  $context->{name} = "LimitedVector";
  $context->operators->set(
     '+' => {class => 'LimitedVector::BOP::add'},
     '-' => {class => 'LimitedVector::BOP::subtract'},
     '*' => {class => 'LimitedVector::BOP::multiply'},
    '* ' => {class => 'LimitedVector::BOP::multiply'},
    ' *' => {class => 'LimitedVector::BOP::multiply'},
     ' ' => {class => 'LimitedVector::BOP::multiply'},
     '/' => {class => 'LimitedVector::BOP::divide'},
    ' /' => {class => 'LimitedVector::BOP::divide'},
    '/ ' => {class => 'LimitedVector::BOP::divide'},
    'u+' => {class => 'LimitedVector::UOP::plus'},
    'u-' => {class => 'LimitedVector::UOP::minus'},
  );
  #
  #  Remove these operators and functions
  #
  $context->operators->undefine('_','U','><','.');
  $context->functions->undefine('norm','unit');
  $context->lists->set(
    AbsoluteValue => {class => 'LimitedVector::List::AbsoluteValue'},
    Vector        => {class => 'LimitedVector::List::Vector'},
  );
  #
  #  Format can be 'coordinate', 'ijk', or 'either'
  #
  $context->flags->set(vector_format => 'either');

  #########################

  $context = $main::context{'LimitedVector-ijk'} = $main::context{LimitedVector}->copy;
  $context->flags->set(vector_format => 'ijk');

  #########################

  $context = $main::context{'LimitedVector-coordinate'} = $main::context{LimitedVector}->copy;
  $context->flags->set(vector_format => 'coordinate');
  $context->constants->undefine('i','j','k');

  #########################

  main::Context("LimitedVector");  ### FIXME:  probably should require author to set this explicitly
}

1;
