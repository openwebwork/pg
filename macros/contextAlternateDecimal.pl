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

C<Context("AlternateDecimal")> - Provides a context that allows the
entry of decimal numbers using a comma for the decimal indicator
rather than a dot (e.g., C<3,14159> rather than C<3.14159>).


=head1 DESCRIPTION

This macro file defines contexts in which decimal numbers can be
entered using a comma rather than a period as the decimal separator.
Both forms are always recognized, but you can determine whether one or
the other form produces an error message when used.  You can also
force the display of numbers to use one or the other form.


=head1 USAGE

To use this file, first load it into your problem, then select the
context that you wish to use.  There are three pre-defined contexts,
C<AlternateDecimal>, C<AlternateDecimal-Only>, and
C<AlternateDecimal-Warning>.  The first allows both the standard and
alternate forms to be used, the second allows only the alternate form,
and the third allows only the standard form, but recognizes the
alternate form and gives an error message when it is used.

	loadMacros("contextAlternateDecimal.pl");
	
	Context("AlternateDecimal");
	
	$r1 = Compute("3.14159");
        $r2 = Compute("3,14159");    # equivalent to $r1;
	
	Context("AlternateDecimal-Only");
	
	$r1 = Compute("3.14159");
        $r2 = Compute("3,14159");    # causes an error message
	
	Context("AlternateDecimal-Warning");
	
	$I1 = Compute("3.14159");    # causes an error message
        $I2 = Compute("3,14159");

There are two context flags that control the input and output of
decimals.

=over

=item C<S<< enterDecimals => "either" (or "," or ".") >>>

This specifies what formats the student is allowed to use to enter a
decimal.  A value of C<"either"> allows either of the formats to be
accepted, while the other two options produce error messages if the
wrong form is used.

=item C<S<< displayDecimals => "either" (or "," or ".") >>>

This controls how decimals are displayed.  When set to C<"either">,
the decimal is displayed in whatever format was used to create it.
When set to C<"."> or C<",">, the display is forced to be in the given
format regardless of how it was entered.

=back

The C<AlternateDecimal> context has both flags set to C<"either">, so
the decimals remain in the format the student entered them, and either
form can be used.  The C<AlternateDecimal-Only> context has both set
to C<",">, so only the alternate format can be used, and any number
will be displayed in the alternate format.  The
C<AlternateDecimal-Warning> context has both set to C<".">, so only
standard format can be used, and all numbers will be displayed in
standard format.

It is possible to set C<enterDecimals> and C<displayDecimals> to
different values.  For example.

	Context()->flags->set(
	  enterDecimals => "either",
	  displayDecimals => ".",
	);

would allow students to enter decimals in either format, but all
numebrs would be displayed in standard form.


=head1 LISTS IN ALTERNATE FORMAT

Because the alternate format allows numbers to be entered using commas
rather than periods, this makes the formation of lists harder.  For
example, C<3,5> is the number 3-and-5-tenths, not the list consisting
of 3 followed by 5. Because of this ambiguity, the C<AlternateDecimal>
contexts also include the semi-colon as a replacement for the comma as
a separator.  So C<3;5> is the list consisting of 3 followed by 5, and
C<3,1;5.2> is the list consisting of 3.1 and 5.2.

Note that the comma is still available for use as a separator, but
this makes things like C<3,2,1> tricky, because it is not clear if
this is 3.2 followed by 1, or 3.2 times .1, or the list of 3, 2, and
1.  To help make this unambiguous, numbers that use a comma as decimal
inidcator must have a digit on both sides of the comma.  So one tenth
would have to be entered as C<0,1> not just C<,1> (but you can still
enter C<.1>.  Similarly, You must enter C<3,0> or just C<3> rather
than C<3,>, even though C<3.> is acceptable.

With this notation C<3,2,1> means the list consisting of 3.2 followed
by 1.  If you want the list consisting of 3 followed by 2.1, you could
use C<3, 2,1> since the comma in C<3,> is not part of the number, so
must be a list separator.


=head1 SETTING THE ALTERNATE FORM AS THE DEFAULT

If you want to force existing problems to allow (or force, or warn about)
the alternate format instead, then create a file named
C<parserCustomization.pl> in your course's C<templates/macros>
directory, and enter the following in it:

	loadMacros("contextAlternateDecimal.pl");
        context::AlternateDecimal->Default("either","either");
        Context("Numeric");

This will alter all the standard contexts to allow students to enter
numbers in either format, and will display them using the form that
was used to enter them.

You could also do

	loadMacros("contextAlternateDecimal.pl");
        context::AlternateDecimal->Default(".",".");
        Context("Numeric");

to cause a warning message to appear when students enter the alternate
format.

If you want to force students to enter the alternate format, use

	loadMacros("contextAlternateDecimal.pl");
        context::AlternateDecimal->Default(",",",");
        Context("Numeric");

This will force the display of all numbers into the alternate form (so
even the ones created in the problem using standard form will show
using commas), and will force students to enter their results using
commas, though professors answers will still be allowed to be entered
in either format (the C<Default()> function converts the first C<",">
to C<"either">, but arranges that the default flags for the answer
checker are set to only allow students to enter decimals with commas).
This allows you to force comma notation in problems without having to
rewrite them.

=cut


###########################################################

loadMacros("MathObjects.pl");

sub _contextAlternateDecimal_init {context::AlternateDecimal->Init}


###########################################################

package context::AlternateDecimal;

#
#  Create the AlternateDecimal contexts
#
sub Init {
  my $context = $main::context{AlternateDecimal} = Parser::Context->getCopy("Numeric");
  $context->{name} = "AlternateDecimal";
  context::AlternateDecimal->Enable($context);

  $context = $main::context{"AlternateDecimal-Warning"} = $context->copy;
  $context->{name} = "AlternateDecimal-Warning";
  $context->flags->set(
    enterDecimals => ".",
    displayDecimals => ".",
  );

  $context = $main::context{"AlternateDecimal-Only"} = $context->copy;
  $context->{name} = "AlternateDecimal-Only";
  $context->flags->set(
    enterDecimals => ",",
    displayDecimals => ",",
  );
  foreach my $list ($context->lists->names) {
    my $sep = $context->lists->get($list)->{separator};
    $context->lists->set($list,{separator => ";"}) if $sep eq ",";
    $context->lists->set($list,{separator => "; "}) if $sep eq ", ";
  }
}

#
#  Enables alternate decimals in the given context
#
sub Enable {
  my $self = shift; my $context = shift || main::Context();
  $context->flags->set(
    enterDecimals => "either",        # or "." or ","
    displayDecimals => "either",      # or "." or ","
  );
  $context->{pattern}{number} = '(?:\d+(?:\.\d*|,\d+)?|\.\d+)(?:E[-+]?\d+)?';
  $context->{pattern}{signedNumber} = '[-+]?(?:\d+(?:\.\d*|,\d+)?|\.\d+)(?:E[-+]?\d+)?';
  $context->operators->add(';' => {%{$context->operators->get(',')}, string => ";"})
    if $context->{operators}{','};
  $context->update;
  $context->{parser}{Value} = "context::AlternateDecimal::Value";
  $context->{parser}{Number} = "context::AlternateDecimal::Number";
  $context->{value}{Real} = "context::AlternateDecimal::Real";
}

#
#  Sets all the default contexts to use alternate decimals.
#  The two arguments determine the values for the
#  enterDecimals and displayDecimals flags.  If enterDecimals
#  is ",", then student answers must use commas for decimals
#  (though professors can use either).  If the display is not
#  ".", then separators for lists, points, vectors, etc, are
#  displayed as ";".
#
sub Default {
  my $self = shift; my $enter = shift || "either";  my $display = shift || "either";
  my $cmp = ($enter eq ","); $enter = "either" if $cmp;
  foreach my $name (keys %Parser::Context::Default::context) {
    my $context = $main::context{$name} = Parser::Context->getCopy($name);
    $self->Enable($context);
    $context->flags->set(enterDecimals => $enter, displayDecimals => $display);
    if ($display ne ".") {
      foreach my $list ($context->lists->names) {
	my $sep = $context->lists->get($list)->{separator};
	$context->lists->set($list,{separator => ";"}) if $sep eq ",";
	$context->lists->set($list,{separator => "; "}) if $sep eq ", ";
      }
    }
    if ($cmp) {
      foreach my $class (grep {/::/} (keys %Value::)) {
        $context->{cmpDefaults}{substr($class,0,-2)}{enterDecimals} = ",";
      }
    }
  }
  main::Context(main::Context()->{name});
}

###########################################################

package context::AlternateDecimal::Number;
our @ISA = ('Parser::Number');

#
#  Handle numbers with commas as decimal indicators, and produce an
#  error if the format is not what is allowed.  Mark the number if it
#  is in the alternate form, so we can display it correctly later.  If
#  needed, save the original string, swap the comma for a dot, save
#  THAT, and correct the number's numeric value.
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $equation = shift; my $value = shift;
  my $context = $equation->{context};
  my $format = (($context->{answerHash}||{})->{enterDecimals} || $context->flag("enterDecimals"));
  my $alternate = (Value::isHash($value) ? $value->{alternateForm} : ref($value) ? 0 : $value =~ m/,/);
  my $num = $self->SUPER::new($equation,$value,@_);
  if (!$context->flag("skipDecimalCheck")) {
    $num->Error("Decimal numbers should be entered using a comma not a period")
      if !$alternate && $value =~ m/\./ && $format eq ",";
    $num->Error("Decimal numbers should be entered using a period not a comma")
      if $alternate && $format eq ".";
  }
  if ($alternate) {
    $num->{alternateForm} = 1;
    $num->{value_original_string} = $value;
    $value =~ s/\{?,\}?/./;
    $num->{value_string} = $value;
    $num->{value} = $value + 0;
  }
  return $num;
}

#
#  If we have an alternate form, make a Real out of it so that
#  we can retain the alternateForm flag.  (I'm not sure if there
#  will be any problems from that, since it usually only returns
#  a Perl real).
#
sub eval {
  my $self = shift;
  my $n = $self->{value};
  if ($self->{alternateForm}) {$n =~ s/\./,/; $n = $self->Package("Real")->make($n)}
  return $n;
}

#
#  Fix the decimal separators depending on the display format.
#
sub swapDecimal {
  my $self = shift; my $n = shift;
  my $context = $self->{equation}{context};
  my $format = (($context->{answerHash}||{})->{displayDecimals} || $context->flag("displayDecimals"));
  $n =~ s/\./,/ if ($self->{alternateForm} || $format eq ",") && $format ne ".";
  return $n;
}
sub string {
  my $self = shift;
  $self->swapDecimal($self->SUPER::string(@_));
}
sub TeX {
  my $self = shift;
  my $n = $self->swapDecimal($self->SUPER::TeX(@_));
  $n =~ s/\{?,\}?/{,}/;
  return $n;
}

#
#  Return the proper class
#
sub class {(shift->isComplex ? "Complex" : "Number")}


###########################################################

package context::AlternateDecimal::Real;
our @ISA = ('Value::Real');

#
#  Make the number and issue a warning if the wrong format is used.
#  Save the decimal in standard notation, but mark it as alternate
#  form so that it can be displayed in its original form, if needed.
#
sub new {shift->checkDecimal("new",@_)}
sub make {shift->checkDecimal("make",@_)}

sub checkDecimal {
  my $self = shift; my $method = "SUPER::".shift;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $x = shift; my $alternate;
  if (Value::matchNumber($x) && scalar(@_) == 0 && $x =~ m/,/) {$x =~ s/,/./; $alternate = 1}
  $x = $self->$method($context,$x,@_); $x->{alternateForm} = 1 if $alternate;
  return $x;
}

sub cmp_defaults {shift->SUPER::cmp_defaults(@_)}

#
#  Display the number in the correct form depending on the displayDecimals flag.
#
sub string {
  my $self = shift; my $n = $self->SUPER::string(@_);
  my $format = $self->getFlag("displayDecimals");
  $n =~ s/\./,/ if ($self->{alternateForm} || $format eq ",") && $format ne ".";
  return $n;
}
sub TeX {
  my $self = shift; my $n = $self->SUPER::TeX(@_);
  $n =~ s/,/{,}/;  # original TeX calls string(), which already has put in the comma
  return $n;
}

###########################################################

package context::AlternateDecimal::Value;
our @ISA = ('Parser::Value');

#
#  Allow Parser::Value to create Parser::Number objects
#  from decimals without checking for commas (since these
#  are the results of computations, not values entered
#  directly by students).
#
sub new {
  my $self = shift; my $context = $self->context;
  $context->flags->set(skipDecimalCheck => 1);
  my $result = $self->SUPER::new(@_);
  $context->flags->remove("skipDecimalCheck");
  return $result;
}

###########################################################

1;
