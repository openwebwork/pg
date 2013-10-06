################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2012 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/contextComplexExtras.pl,v 1.0 2012/08/01 11:33:50 dpvc Exp $
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

F<contextCopmlesExtras.pl> - Add conjugation to Complex contexts, and
transpose, conjugate transpose, trace, and determinant to Complex-Matrix context.

=head1 DESCRIPTION

The F<contextComplexExtras.pl> file adds the ability to include matrix
transpose, conjugate transpose, trace, and determinants in student
answers in the Complex-Matrix context, and adds conjugation to all
Complex contexts.

Conjugation is represented by C<~>, as in C<~z> or C<~M> to conjugate
a complex number or complex matrix.  This can be used in both PG code
as well as student answers.  The transpose is represented by C<^T>, as
in C<M^T>, in student answers or parsed strings.  The conjugate
transpose is C<^*>, as in C<M^*>, and is equivalent to C<~M^T>.  The
trace is given as C<tr(M)>, and the determinant by C<det(M)>.  Thus
you can do things like:

    loadMacros("contextComplexExtras.pl");
    
    Context("Complex-Matrix");
    Context()->constants->add(
      A => Matrix([[pi+i,i/pi**2],[1+sqrt[2]*i,ln(pi)-2*i]]),  # an arbitrary matrix with no special properties
    );
    
    $F = Formula("det(~A) + tr(A^*)");
    
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
    $Mc = ~$M;
    $Ms = ~($M->transpose);

Note that the F<contextComplexExtras.pl> file modifies the Complex,
Complex-Point, Complex-Vector, and Complex-Matrix contexts, so be sure
to load it before you set the Context.

=cut


loadMacros("MathObjects.pl");

sub _contextComplexExtras_init {
  my $context;
  foreach $name ("Complex","Complex-Point","Complex-Vector","Complex-Matrix") {
    $context = $main::context{$name} = Parser::Context->getCopy($name);
    $context->operators->add(
      '~' => {precedence => 6, associativity => 'left', type => 'unary', string => '~', perl => '~',
               class => 'context::ComplexExtras::UOP::conjugate'},
    );
  }
  $context->operators->add(
    '^T' => {precedence => 7, associativity => 'right', type => 'unary', string => '^T',
             class => 'context::ComplexExtras::UOP::transpose'},
    '^*' => {precedence => 7, associativity => 'right', type => 'unary', string => '^*',
             class => 'context::ComplexExtras::UOP::conjtrans'},
  );
  $context->functions->add(
    'tr'  => {class => "context::ComplexExtras::Function::matrix", method => "trace"},
    'det' => {class => "context::ComplexExtras::Function::matrix"},
  );
};

####################################################
#
#  Base UOP class that checks for matrix arguments
#
package context::ComplexExtras::UOP;
our @ISA = ("Parser::UOP");

#
#  Check that the operand is a Matrix
#
sub _check {
  my $self = shift;
  $self->Error("'%s' is only defined for Matrices",$self->{def}{string})
    unless $self->{op}->type eq "Matrix";
}


####################################################
#
#  Implements the ~ operation on matrices and complex numbers
#    (as a left-associative unary operator)
#
package context::ComplexExtras::UOP::conjugate;
our @ISA = ("context::ComplexExtras::UOP");

sub _check {
  my $self = shift;
  $self->Error("Conjugate is only defined for Complex Numbers and Matrices")
    unless $self->{op}->type =~ m/Number|Matrix/;
}

sub _eval {shift; $_[0]->conj}

####################################################
#
#  Implements the ^T operation on matrices and complex numbers
#    (as a right-associative unary operator)
#
package context::ComplexExtras::UOP::transpose;
our @ISA = ("context::ComplexExtras::UOP");

sub _eval {shift; $_[0]->transpose}

sub perl {
  my $self = shift;
  return '('.$self->{op}->perl.'->transpose)';
}


####################################################
#
#  Implements the ^* operation on matrices and complex numbers
#    (as a right-associative unary operator)
#
package context::ComplexExtras::UOP::conjtrans;
our @ISA = ("context::ComplexExtras::UOP");

sub _eval {shift; $_[0]->transpose->conj}

sub perl {
  my $self = shift;
  return '('.$self->{op}->perl.'->transpose->conj)';
}

####################################################
#
#  Implement functions with one matrix input and complex output
#
package context::ComplexExtras::Function::matrix;
our @ISA = ("Parser::Function");

#
#  Check for a single Matrix-valued input
#
sub _check {(shift)->checkMatrix("complex")}

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
