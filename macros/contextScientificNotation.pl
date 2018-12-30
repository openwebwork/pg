################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2018 The WeBWorK Project, http://openwebwork.sf.net/
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

contextScientificNotation.pl - Allows entry of scientific notation.

=head1 DESCRIPTION

This file implements a context in which students can enter
answers in scientific notation.  It tries hard to report
useful error messages when the student's answer is not
in the proper format, and it also allows you to control
how many decimal digits they are allowed/required to
enter, and how many the system will display.

This probably should be called LimitedScientificNotation
since it does not allow any operations other than the ones
needed in Scientific notation.  In the future it may be
renamed if we produce a computational scientific notation
context.

To use this context, add

	loadMacros("contextScientificNotation.pl");

to the top of your problem file, and then use

	Context("ScientificNotation");

to select the context and make it active.  You can create
values in scientific notation in two ways:

	$n1 = Compute("1.23 x 10^3");

or

	$n2 = ScientificNotation(1.23 * 10**3);

(or even $n2 = ScientificNotation(1230), and it will be converted).

You can control how many digits are displayed by setting the
snDigits flag in the context.  For example,

	Context()->flags->set(snDigits=>2);

sets the context to display at most 2 digits.  The default is 6.
By default, trailing zeros are removed, but you can ask that
they be retained by issuing the command

	Context()->flags->set(snTrimZeros=>0);

It is also possible to specify how many decimal digits the
student must enter.  For example,

	Context()->flags->set(snMinDigits=>3);

would require the student to enter at least 3 digits past
the decimal place (for a total of 4 significant digits,
including the one to the left of the decimal).  The default
is 1 digit beyond the decimal.  A value of 0 means that
a decimal point and decimal values is optional.

Similarly,

	Context()->flags->set(snMaxDigits=>6);

sets the maximum number to 6, so the student can't enter
more than that.  Setting this to 0 means no decimal places
are allowed, effectively meaning students can only enter
the numbers 0 through 9 (times a power of 10).  Setting
this to a negative number means that there is no upper
limit on the number of digits the student may enter (this
is the default).

As an example, in order to force a fixed precision of
three digits of precision, use

	Context()->flags->set(
		snDigits => 3,
		snTrimZeros => 0,
		snMinDigits => 3,
		snMaxDigits => 3,
	);

Note that if you restrict the number of digits, you may
need to adjust the tolerance values since the student
may not be allowed to enter a more precise answer.  In
the example above, it would be appropriate to set the
tolerance to .0001 and the tolType to "relative" in
order to require the answers to be correct to the three
digits that are shown.

=cut

loadMacros("MathObjects.pl");

sub _contextScientificNotation_init {ScientificNotation::Init()}

package ScientificNotation;

#
#  Creates and initializes the ScientificNotation context
#
sub Init {
  #
  #  Create the Scientific Notation context
  #
  my $context = $main::context{ScientificNotation} = Parser::Context->getCopy("Numeric");
  $context->{name} = "ScientificNotation";

  #
  #  Make numbers include the leading + or - and not allow E notation
  #
  $context->{pattern}{number} = '[-+]?(?:\d+(?:\.\d*)?|\.\d+)';

  #
  #  Remove all the stuff we don't need
  #
  $context->variables->clear;
  $context->constants->clear;
  $context->parens->clear;
  $context->operators->clear;
  $context->functions->clear;
  $context->strings->clear;

  #
  #  Only allow  x  and  ^  operators
  #
  $context->operators->add(
     'x' => {precedence => 3, associativity => 'left', type => 'bin',
             string => 'x', TeX => '\times ', perl => '*',
             class => 'ScientificNotation::BOP::x'},

     '^' => {precedence => 7, associativity => 'right', type => 'bin',
             string => '^', perl => '**',
             class => 'ScientificNotation::BOP::power'},

     '**'=> {precedence => 7, associativity => 'right', type => 'bin',
             string => '^', perl => '**',
             class => 'ScientificNotation::BOP::power'}
  );

  #
  #  Don't reduce constant values (so 10^2 won't be replaced by 100)
  #
  $context->flags->set(reduceConstants => 0);
  #
  #  Flags controlling input and output
  #
  $context->flags->set(
    snDigits => 6,     # number of decimal digits in mantissa for output
    snTrimZeros => 1,  # 1 means remove trailing 0's, 0 means leave them
    snMinDigits => 1,  # minimum number of decimal digits to require in student input
                       #  (0 means no decimal is required)
    snMaxDigits => -1, # maximum number of decimals allowed in student input
                       #  (negative means no limit)
  );

  #
  #  Better error message for this case
  #
  $context->{error}{msg}{"Unexpected character '%s'"} = "'%s' is not allowed in scientific notation";

  #
  #  Hook into the Value package lookup mechanism
  #
  $context->{value}{ScientificNotation} = 'ScientificNotation::Real';
  $context->{value}{"Real()"} = 'ScientificNotation::Real';

  #
  #  Create the constructor function
  #
  main::PG_restricted_eval('sub ScientificNotation {Value->Package("ScientificNotation")->new(@_)}');
}


##################################################
#
#  The Scientific Notation multiplication operator
#
package ScientificNotation::BOP::x;
our @ISA = qw(Parser::BOP);

#
#  Check that the operand types are compatible, and give
#  approrpiate error messages if not.  (We have to work
#  hard to make a good message about the number of
#  decimal digits required.)
#
sub _check {
  my $self = shift;
  my ($lop,$rop) = ($self->{lop},$self->{rop});
  my ($m,$M) = ($self->context->flag("snMinDigits"),$self->context->flag("snMaxDigits"));
  $M = $m if $M >= 0 && $M < $m;
  my $repeat = ($M < 0 ? "{$m,}" : "{$m,$M}");
  my ($digits,$zeros) = ("\\.\\d$repeat","\\.0$repeat");
  my $zero = ($m == 0 ? ($M > 0 ? "0.0" : "0") : "0.".("0"x$m));
  my $decimals = ($m == $M ? ($m == 0 ? "no digits" : "exactly $m digit".($m == 1 ? "" : "s")) :
                 ($M < 0 ?   ($m == 0 ? "" : "at least $m digit".($m == 1 ? "" : "s")) :
                             ($m == 0 ? "at most $M digit".($M == 1 ? "" : "s") :
                                        "between $m and $M digits")));
  $decimals = " and ".$decimals." after it" if $decimals;
  $digits = "($digits)?", $zeros = "($zeros)?" if $m == 0;
  $self->Error("You must use a power of 10 to the right of 'x' in scientific notation") unless $rop->{isPowerOf10};
  $self->Error("You must use a number to the left of 'x' in scientific notation") unless $lop->type eq 'Number';
  $self->Error("The number to the left of 'x' must be %s, or have a single, non-zero digit before the decimal%s",
               $zero,$decimals) unless $lop->{value_string} =~ m/^[-+]?([1-9]${digits}|0${zeros})$/;
  $self->{type} = $Value::type{Number};
  $self->{isScientificNotation} = 1;  # mark it so we can tell later on
}

#
#  Perform the multiplication and return a ScientificNotation object
#
sub _eval {
  my ($self,$a,$b) = @_;
  $self->Package("ScientificNotation")->make($self->context,$a*$b);
}

#
#  Use the ScientificNotation MathObject to produce the output formats
#  (if other operators are added back into the context, these will
#   need to be modified to include parens at the appropriate times)
#
sub string {(shift)->eval->string}
sub TeX    {(shift)->eval->TeX}
sub perl   {(shift)->eval->perl}

##################################################
#
#  Scientific Notation exponentiation operator
#
package ScientificNotation::BOP::power;
our @ISA = qw(Parser::BOP::power);  # inherit from standard power (TeX method in particular)

#
#  Check that the operand types are compatible and
#  produce appropriate errors if not
#
sub _check {
  my $self = shift;
  my ($lop,$rop) = ($self->{lop},$self->{rop});
  $self->Error("The base can not have decimal places in scientific notation")
    if $lop->{value} == 10 && $lop->{value_string} =~ m/\./;
  $self->Error("You must use a power of 10 in scientific notation")
    unless $lop->{value_string} eq "10";
  $self->Error("The expondent must be an integer in scientific notation")
    unless $rop->{value_string} =~ m/^[-+]?\d+$/;
  $self->{type} = $Value::type{Number};
  $self->{isPowerOf10} = 1;  # mark it so BOP::x above can recognize it
}

#####################################
#
#  A subclass of Real that handles scientific notation
#
package ScientificNotation::Real;
our @ISA = ("Value::Real");

#
#  Override these so we can mark ourselves as scientific notation
#
sub new {
  my $self = (shift)->SUPER::new(@_);
  $self->{isValue} = $self->{isScientificNotation} = 1;
  return $self;
}

sub make {
  my $self = (shift)->SUPER::make(@_);
  $self->{isValue} = $self->{isScientificNotation} = 1;
  return $self;
}

#
#  Stringify using x notation not E,
#  using the right number of digits, and trimming
#  if requested.
#
sub string {
  my $self = shift;
  my $digits = $self->getFlag("snDigits");
  my $trim = ($self->getFlag("snTrimZeros") ? '0*' : '');
  my $r = main::spf($self->value,"%.${digits}e");
  $r =~ s/(\d)${trim}e\+?(-?)0*(\d)/$1 x 10^$2$3/i;
  return $r;
}

#
#  Convert x notation to TeX form
#
sub TeX {
  my $r = (shift)->string;
  $r =~ s/x/\\times /;
  $r =~ s/\^(.*)/^{$1}/;
  return $r;
}

#
#  What to call us in error messages
#
sub cmp_class {"Scientific Notation"}

#
#  Only match against strings and Scientific Notation
#
sub typeMatch {
  my $self = shift; my $other = shift; my $ans = shift;
  return $other->{isScientificNotation};
}

#########################################################################

1;
