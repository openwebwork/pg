################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2014 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader:$
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

C<contextComplexJ.pl> - Alters the Complex context to allow the
use of j-notation in addition to (or in place of) i-notation for
complex numbers.


=head1 DESCRIPTION

This macro file adds features to the Complex context that allow both
i and j notation for complex numbers.  There are flags that control
which notation a student must use (a warning is given for the other
type), and how complex numbers should be displayed (you can force
either form to be used regardless of how they were entered).


=head1 USAGE

To use this file, first load it into your problem, then use the
Complex context as usual.  Both i and j notation will be allowed,
and numbers will display in whichever format they were originally
entered.

	loadMacros("contextComplexJ.pl");
	
	Context("Complex");
	
	$z1 = Compute("1+3i");
        $z2 = Compute("1+3j");    # equivalent to $z1;
	
        $z1 == $z2;               # true

There are two context flags that control the input and output of
complex numbers.

=over

=item C<S<< enterComplex => "either" (or "i" or "j") >>>

This specifies what formats the student is allowed to use to enter a
complex number.  A value of C<"either"> allows either of the formats to be
accepted, while the other two options produce error messages if the
wrong form is used.

=item C<S<< displayComplex => "either" (or "i" or "j") >>>

This controls how complex numbers are displayed.  When set to C<"either">,
the complex is displayed in whatever format was used to create it.
When set to C<"i"> or C<"j">, the display is forced to be in the given
format regardless of how it was entered.

=back

By default, the C<Complex> context has both flags set to C<"either">,
so the complex numbers remain in the format the student entered them,
and either form can be used.

It is possible to set C<enterComplex> and C<displayComplex> to
different values.  For example.

	Context()->flags->set(
	  enterComplex => "either",
	  displayComplex => "i",
	);

would allow students to enter complex numbers in either format, but
all numebrs would be displayed in standard form.


=head1 SETTING THE ALTERNATE FORM AS THE DEFAULT

If you want to force existing problems to allow (or force, or warn
about) the j notation, then create a file named
C<parserCustomization.pl> in your course's C<templates/macros>
directory, and enter the following in it:

	loadMacros("contextComplexJ.pl");
        context::ComplexJ->Default("either","either");

This will alter all the standard Complex contexts to allow students to
enter complex numbers in either format, and will display them using
the form that was used to enter them.

You could also do

	loadMacros("contextComplexJ.pl");
        context::ComplexJ->Default("i","i");

to cause a warning message to appear when students enter the j format.

If you want to force students to enter the alternate format, use

	loadMacros("contextComplexJ.pl");
        context::ComplexJ->Default("j","j");

This will force the display of all complex numbers to use j notation
(so even the ones created in the problem using standard form will show
using j's), and will force students to enter their results using j's,
though professors answers will still be allowed to be entered in
either format (the C<Default()> function converts the first C<"j"> to
C<"either">, but arranges that the default flags for the answer
checker are set to only allow students to enter complex numbers with
j's).  This allows you to force j notation in problems without having
to rewrite them.

=cut


##########################################################################

loadMacros("MathObjects.pl");

sub _contextComplexJ_init {
  my $context = $main::context{Complex} = Parser::Context->getCopy("Complex");
  context::ComplexJ->Enable($context);
}

###############################################################

package context::ComplexJ;

#
#  Enables complex j notation in the given context
#
sub Enable {
  my $self = shift; my $context = shift || main::Context();
  $context->flags->set(
     enterComplex => "either",
     displayComplex => "either",
  );
  $context->{value}{Complex} = "context::ComplexJ::Value::Complex";
  $context->{parser}{Value} = "context::ComplexJ::Parser::Value";
  $context->{parser}{Complex} = "context::ComplexJ::Parser::Complex";
  $context->{parser}{Constant} = "context::ComplexJ::Parser::Constant";
  $context->constants->set(
    j => {value => $context->Package("Complex")->new($context,0,1)->with(isJ=>1), isConstant => 1, perl => "j"},
    i => {value => $context->Package("Complex")->new($context,0,1), isConstant => 1, perl => "i"},
  );
  $context->update;
}

#
#  Sets all the complex-based default contexts to use ComplexJ
#  notation.  The two arguments determine the values for the
#  enterComplex and displayComplex flags.  If enterComplex is "j",
#  then student answers must use the j notation (though
#  professors can use either).
#
sub Default {
  my $self = shift; my $enter = shift || "either";  my $display = shift || "either";
  my $cmp = ($enter eq "j"); $enter = "either" if $cmp;
  foreach my $name (keys %Parser::Context::Default::context) {
    next unless $name =~ m/Complex/;
    my $context = $main::context{$name} = Parser::Context->getCopy($name);
    $self->Enable($context);
    $context->flags->set(enterComplex => $enter, displayComplex => $display);
    if ($cmp) {
      foreach my $class (grep {/::/} (keys %Value::)) {
        $context->{cmpDefaults}{substr($class,0,-2)}{enterComplex} = "j";
      }
    }
  }
  main::Context(main::Context()->{name});
}

###############################################################
#
#  Handle Complex numbers so that they are displayed
#  with the proper i or j value.
#

package context::ComplexJ::Value::Complex;
our @ISA = ('Value::Complex');

sub string {
  my $self = shift; my $display = $self->getFlag("displayComplex");
  my $z = Value::Complex::format($self->{format},$self->value,'string',@_);
  $z =~ s/i/j/ if ($self->{isJ} || $display eq 'j') && $display ne 'i';
  return $z;
}
sub TeX {
  my $self = shift; my $display = $self->getFlag("displayComplex");
  my $z = Value::Complex::format($self->{format},$self->value,'TeX',@_);
  $z =~ s/i/j/ if ($self->{isJ} || $display eq 'j') && $display ne 'i';
  return $z;
}

###############################################################
#
#  Make Parser Value object maintain the indicator for
#  which notation was used for a complex number.
#

package context::ComplexJ::Parser::Value;
our @ISA = ('Parser::Value');

sub new {
  my $self = shift;
  my ($equation,$value,@ref) = @_;
  my $z = $self->SUPER::new(@_);
  if ($z->class eq "Complex") {
    $value = $value->[0] if ref($value) eq 'ARRAY' && scalar(@$value) == 1;
    $z->{isJ} = 1 if Value::isHash($value) && $value->{isJ};
  }
  return $z;
}

sub class {'Value'};

###############################################################
#
#  Make sure complex numbers maintain their flag for
#  which format was used to create them.
#

package context::ComplexJ::Parser::Complex;
our @ISA = ('Parser::Complex');

sub eval {
  my $self = shift;
  my $z = $self->SUPER::eval(@_);
  $z->{isJ} = 1 if $self->{isJ};
  return $z;
}

sub class {'Complex'}

###############################################################
#
#  Produce error messages when the wrong notation
#  is used for complex numbers.
#
#  Swap i and j when required by the displayComplex flag
#  in the output of constants.
#

package context::ComplexJ::Parser::Constant;
our @ISA = ('Parser::Constant');

sub new {
  my $self = shift;
  my $z = $self->SUPER::new(@_);
  if ($z->isComplex) {
    my $context = $z->{equation}{context};
    my $enter = ($context->{answerHash}||{})->{enterComplex} || $context->flag("enterComplex");
    $self->Error("Complex numbers must be entered using 'j'")
      if $enter eq 'j' && !$z->{def}{value}{isJ};
    $self->Error("Complex numbers must be entered using 'i'")
      if $enter eq 'i' && $z->{def}{value}{isJ};
  }
  return $z;
}

sub swapIJ {
  my $self = shift; my $z = shift;
  if ($self->isComplex) {
    my $display = $self->{equation}{context}->flag("displayComplex");
    $z =~ s/i/j/ if ($self->{def}{value}{isJ} || $display eq "j") && $display ne "i";
    $z =~ s/j/i/ if ($self->{def}{value}{isJ} && $display eq "i");
  }
  return $z;
}
sub string {
  my $self = shift;
  $self->swapIJ($self->SUPER::string(@_));
}
sub TeX {
  my $self = shift;
  $self->swapIJ($self->SUPER::TeX(@_));
}

sub class {'Constant'}

###############################################################

1;
