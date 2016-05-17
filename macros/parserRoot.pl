################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2013 The WeBWorK Project, http://openwebwork.sf.net/
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

parserRoot.pl - defines a C<root(n,x)> function for n-th root of x.

=head1 DESCRIPTION

This file defines the code necessary to add to any context a
C<root(n,x)> function that performs the n-th root of x.  For example,
C<Compute("root(3,27)")> would return the equivalent of C<Real(3)>.

To accomplish this, put the line

	loadMacros("parserRoot.pl");

at the beginning of your problem file, then set the Context to the one
you wish to use in the problem.  Then use the command:

	parser::Root->Enable;

(You can also pass the Enable command a pointer to a context if you
wish to alter a context other than the current one.)

Once that is done, you (and students) can enter roots by using the
C<root()> function.  You can use C<root()> both within C<Formula()> and
C<Compute()> calls, and in Perl expressions, such as

        $n = root(3,27);

to obtain n-th roots.  Note that C<root()> will properly handle odd
roots of negative numbers, so

        $n = root(3,-8);

will produce the equivalent of C<$n = Real(-2)>, but even roots of
negative numbers will produce an error message.

If you enable C<root()> in a context that allows complex numbers, you
may want to allow even roots of negative numbers.  To do this, use

        parser::Root->EnableComplex;

(again, you can pass a context to be altered, if you wish).  This will
force negative values to be promoted to complex numbers before an even
root is taken.  So

        parser::Root->EnableComplex;
        $z = root(2,-9);

would produce the equivalent of C<$z = 3*i;>

=cut

########################################################################

sub _parserRoot_init {
  main::PG_restricted_eval('sub root {Parser::Function->call("root",@_)}');
}

########################################################################

package parser::Root;

sub Enable {
  my $self = shift; my $context = shift; my $complex = shift;
  $context = main::Context() unless Value::isContext($context);
  $context->functions->add(
    root => {class => 'parser::Root::Function::numeric2'},
  );
  $context->functions->set(root => {negativeIsComplex=>1}) if $complex;
}

sub EnableComplex {
  my $self = shift; my $context = shift;
  $self->Enable($context,1);
}

########################################################################

package parser::Root::Function::numeric2;
our @ISA = qw(Parser::Function);

#
#  Check for arguments that are an integer and a number
#
sub _check {
  my $self = shift; my $context = $self->context;
  return if ($self->checkArgCount(2));
  $self->{type} = $Value::Type{number};
  return if $context->flag("allowBadFunctionInputs");
  my ($n,$x) = @{$self->{params}};
  $self->Error("Function '%s' must have numeric inputs",$self->{name})
    unless $n->isNumber && $x->isNumber;
  $self->{type} = $Value::Type{complex} if $x->isComplex;
}

#
#  Check that the inputs are OK and call the named routine
#
sub _call {
  my $self = shift; my $name = shift;
  $self->Error("Function '%s' has too many inputs",$name) if scalar(@_) > 2;
  $self->Error("Function '%s' has too few inputs",$name) if scalar(@_) < 2;
  return $self->$name($self->checkArguments($name,@_));
}

#
#  Call the appropriate routine
#
sub _eval {
  my $self = shift; my $name = $self->{name};
  $self->$name($self->checkArguments($name,@_));
}

#
#  Check that the parameters are OK
#
sub checkArguments {
  my $self = shift; my $name = shift; my $context = $self->context;
  my ($n,$x) = (map {Value::makeValue($_,$context)} @_);
  $self->Error("Function '%s' must have numeric inputs",$name)
      unless $n->isNumber && $x->isNumber;
  return ($n,$x);
}


#
#  Compute root using x**(1/n)
#  If x < 0 and n is even, either promote x to a complex
#   or throw an error.
#  If x < 0 and n is odd, use -(abs(x))**(1/n)
#
sub root {
  my $self = shift; my ($n,$x) = @_;
  if ($x->isReal && $x->value < 0 && CORE::int($n->value) == $n->value) {
    if ($n->value % 2 == 0) {
      my $context = $x->context;
      $self->Error("Can't take even root of %s",$x)
	unless $context->functions->get("root")->{negativeIsComplex};
      $x = $self->Package("Complex")->promote($context,$x);
    } else {
      return -((-$x)**(1/$n));
    }
  }
  return $x**(1/$n);
}

#
#  Implement differentiation: (u^(1/n))' -> (1/n)(u^(1/n))^(1-n) * u' - u^(1/n)ln(u)/n^2 * n'
#  (We use (u^(1/n))^(1-n) rather than u^(1/n-1) so that we have the
#  same domain as u^(1/n) does originally).
#
sub D {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $BOP = $self->Item("BOP");
  my $NUM = $self->Item("Number");
  my ($n,$u) = @{$self->{params}};
  my $D = $BOP->new($equation,'*',
            $BOP->new($equation,'*',
              $BOP->new($equation,'/',$NUM->new($equation,1),$n->copy($equation)),
              $BOP->new($equation,'^',
                $self->copy($equation),
	        $BOP->new($equation,'-',$NUM->new($equation,1),$n->copy($equation))
              )
            ),
            $u->D($x)
          );
  $D = $BOP->new($equation,'-',
    $D,
    $BOP->new($equation,"*",
      $self->copy($equation),
      $BOP->new($equation,"*",
        $BOP->new($equation,"/",
          $self->Item("Function")->new($equation,"ln",[$u->copy($equation)],$u->{isConstant}),
          $BOP->new($equation,"^",$n->copy($equation),$NUM->new($equation,2))
        ),
        $n->D($x)
      )
    )
  ) if $n->getVariables->{$x};
  return $D->reduce;
}

#
#  Output TeX using \sqrt[n]{x}
#
sub TeX {
  my ($self,$precedence,$showparens,$position,$outerRight,$power) = @_;
  $showparens = '' unless defined $showparens;
  my $fn = $self->{equation}{context}{operators}{'fn'};
  my $fn_precedence = $fn->{parenPrecedence} || $fn->{precedence};
  my ($n,$x) = @{$self->{params}};
  my $TeX = '\sqrt['.$n->TeX."]{".$x->TeX."}";
  $TeX = '\left('.$TeX.'\right)'
    if $showparens eq 'all' or $showparens eq 'extra' or
       (defined($precedence) and $precedence > $fn_precedence) or
       (defined($precedence) and $precedence == $fn_precedence and $showparens eq 'same');
  return $TeX;
}

########################################################################

1;
