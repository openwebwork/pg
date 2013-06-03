################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2012 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/contextMatrixExtras.pl,v 1.0 2012/08/01 11:21:45 dpvc Exp $
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

F<contextMatrixExtras.pl> - Add transpose, trace, and determinant to Matrix context

=head1 DESCRIPTION

The F<contextMatrixExtras.pl> file adds the ability to include matrix
transpose, trace, and determinants in student answers.  The transpose
is represented by C<^T>, as in C<M^T>, in student answers or parsed
strings.  The trace is given as C<tr(M)>, and the determinant by
C<det(M)>.  Thus you can do things like:

    loadMacros("contextMatrixExtras.pl");
    
    Context("Matrix");
    Context()->constants->add(
      A => Matrix([[pi,1/pi**2],[sqrt[2],ln(pi)]]),  # an arbitrary matrix with no special properties
    );
    
    $F = Formula("det(A) + tr(A^T)");
    
    Context()->texStrings;
    BEGIN_TEXT
    \($F\) = \{ans_rule(20)\}
    END_TEXT
    Context()->normalStrings;
    
    ANS($F->cmp);

You can also use the C<trace>, C<det>, and C<transpose> methods of a
Matrix object to compute these in PG code.

    loadMacros("contextMatrixExtras.pl");
    
    Context("Matrix");
    $M = Matrix([[1,2],[3,4]]);
    
    $Mt = $M->transpose;
    $d  = $M->det;
    $tr = $M->trace;

Note that the F<contextMatrixExtras.pl> file modifies the Matrix context, so be sure to load it before you set the Context.

=cut


loadMacros("MathObjects.pl");

sub _contextMatrixExtras_init {
  my $context = $main::context{Matrix} = Parser::Context->getCopy("Matrix");
  $context->operators->add(
    '^T' => {precedence => 7, associativity => 'right', type => 'unary', string => '^T',
             class => 'context::MatrixExtras::UOP::transpose'},
  );
  $context->functions->add(
    'tr'  => {class => "context::MatrixExtras::Function::matrix", method => "trace"},
    'det' => {class => "context::MatrixExtras::Function::matrix"},
  );
};

####################################################
#
#  Implements the ^T operation on matrices
#    (as a right-associative unary operator)
#
package context::MatrixExtras::UOP::transpose;
@ISA = ("Parser::UOP");

sub _check {
  my $self = shift;
  $self->Error("Transpose is only defined for Matrices") unless $self->{op}->type eq "Matrix";
}

sub _eval {shift; $_[0]->transpose}

sub perl {
  my $self = shift;
  return '('.$self->{op}->perl.'->transpose)';
}


####################################################
#
#  Implement functions with one matrix input and real output
#
package context::MatrixExtras::Function::matrix;
our @ISA = ("Parser::Function");

#
#  Check for a single Matrix-valued input
#
sub _check {(shift)->checkMatrix(@_)}

#
#  Evaluate by promoting to a Matrix
#    and then calling the routine from the Value package
#
sub _eval {
  my $self = shift; my $name = $self->{def}{method} || $self->{name};
  $self->Package("Matrix")->promote($self->context,$_[0])->$name;
}

#
#  Check for a single Matrix-valued argument
#  Then promote it to a Matrix (does error checking)
#    and call the routine from Value package (after
#    converting "tr" to "trace")
#
sub _call {
  my $self = shift; my $name = shift;
  Value->Error("Function '%s' has too many inputs",$name) if scalar(@_) > 1;
  Value->Error("Function '%s' has too few inputs",$name) if scalar(@_) == 0;
  my $M = shift; my $context = (Value::isValue($M) ? $M : $self)->context;
  $name = "trace" if $name eq "tr";  # method of Matrix is trace not tr
  $self->Package("Matrix")->promote($context,$M)->$name;
}
