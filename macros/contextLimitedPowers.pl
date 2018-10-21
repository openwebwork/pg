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

contextLimitedPowers.pl - Restrict the base or power allowed in exponentials.

=head1 DESCRIPTION

Implements subclasses of the "^" operator that restrict
the base or power that is allowed.  There are four
available restrictions:

	No raising e to a power
	Only allowing integer powers (positive or negative)
	Only allowing positive integer powers
	Only allowing positive integer powers (and 0)

You install these via one of the commands:

	LimitedPowers::NoBaseE();
	LimitedPowers::OnlyIntegers();
	LimitedPowers::OnlyPositiveIntegers();
	LimitedPowers::OnlyNonNegativeIntegers();

Only one of the three can be in effect at a time; setting
a second one overrides the first.

These function affect the current context, or you can pass
a context reference, as in

	$context = Context("Numeric")->copy;
	LimitedPowers::OnlyIntegers($context);

For the integer power functions, you can pass additional
parameters that control the range of values that are allowed
for the powers.  The oprtions include:

=over

=item S<C<< minPower => m >>>

only integer powers bigger than or equal
to m are allowed.  (If m is undef, then
there is no minimum power.)

=item S<C<< maxPower => M >>>

only integer powers less than or equal
to M are allowed.  (If M is undef, then
there is no maximum power.)

=item S<C<< message => "text" >>>

a description of the type of power
allowed (e.g., "positive integer constants");

=item S<C<< checker => code >>>

a reference to a subroutine that will be
used to check if the powers are acceptable.
It should accept a reference to the BOP::power
structure and return 1 or 0 depending on
whether the power is OK or not.

=back

For example:

    LimitedPowers::OnlyIntegers(
        minPower => -5, maxPower => 5,
        message => "integer constants between -5 and 5",
    );

would accept only powers between -5 and 5, while

    LimitedPowers::OnlyIntegers(
        checker => sub {
            return 0 unless LimitedPowers::isInteger(@_);
            my $self = shift; my $p = shift; # the power as a constant
            return $p != 0 && $p != 1;
        },
        message => "integer constants other than 0 or 1",
    );

would accept any integer power other than 0 and 1.

=cut

loadMacros("MathObjects.pl");

sub _contextLimitedPowers_init {}; # don't load it again

package LimitedPowers;

sub NoBaseE {
  my $context = (Value::isContext($_[0]) ? shift : Value->context);
  $context->operators->set(
    '^'  => {class => 'LimitedPowers::NoBaseE', isCommand=>1, perl=>'LimitedPowers::NoBaseE->_eval', @_},
    '**' => {class => 'LimitedPowers::NoBaseE', isCommand=>1, perl=>'LimitedPowers::NoBaseE->_eval', @_},
  );
}

sub OnlyIntegers {
  my $context = (Value::isContext($_[0]) ? shift : Value->context);
  $context->operators->set(
    '^'  => {class => 'LimitedPowers::OnlyIntegers', message => "integer constants", @_},
    '**' => {class => 'LimitedPowers::OnlyIntegers', message => "integer constants",@_},
  );
}

sub OnlyNonNegativeIntegers {
  my $context = (Value::isContext($_[0]) ? shift : Value->context);
  OnlyIntegers($context, minPower=>0, message=>"non-negative integer constants", @_);
}

sub OnlyPositiveIntegers {
  my $context = (Value::isContext($_[0]) ? shift : Value->context);
  OnlyIntegers($context, minPower => 1, message => "positive integer constants", @_);
}

sub OnlyNonTrivialPositiveIntegers {
  my $context = (Value::isContext($_[0]) ? shift : Value->context);
  OnlyIntegers($context, minPower=>2, message=>"integer constants bigger than 1", @_);
}

#
#  Test for whether the power is an integer in the specified range
#
sub isInteger {
  my $self = shift; my $n = shift;
  my $def = $self->{def};
  return 0 if defined($def->{minPower}) && $n < $def->{minPower};
  return 0 if defined($def->{maxPower}) && $n > $def->{maxPower};
  return Value::Real->make($n - int($n)) == 0;
}

#
#  Legacy code to accommodate older approach to setting the operators
#
our @NoBaseE = (
  '^'  => {class => 'LimitedPowers::NoBaseE', isCommand=>1, perl=>'LimitedPowers::NoBaseE->_eval'},
  '**' => {class => 'LimitedPowers::NoBaseE', isCommand=>1, perl=>'LimitedPowers::NoBaseE->_eval'},
);
our @OnlyIntegers = (
  '^'  => {class => 'LimitedPowers::OnlyIntegers', message => "integer constants"},
  '**' => {class => 'LimitedPowers::OnlyIntegers', message => "integer constants"},
);
our @OnlyNonNegativeIntegers = (
  '^'  => {class => 'LimitedPowers::OnlyIntegers', minPower => 0, message => "non-negative integer constants"},
  '**' => {class => 'LimitedPowers::OnlyIntegers', minPower => 0, message => "non-negative integer constants"},
);
our @OnlyPositiveIntegers = (
  '^'  => {class => 'LimitedPowers::OnlyIntegers', minPower => 1, message => "positive integer constants"},
  '**' => {class => 'LimitedPowers::OnlyIntegers', minPower => 1, message => "positive integer constants"},
);
our @OnlyNonTrivialPositiveIntegers = (
  '^'  => {class => 'LimitedPowers::OnlyIntegers', minPower => 2, message => "integer constants bigger than 1"},
  '**' => {class => 'LimitedPowers::OnlyIntegers', minPower => 2, message => "integer constants bigger than 1"},
);


##################################################

package LimitedPowers::NoBaseE;
@ISA = qw(Parser::BOP::power);

my $e = CORE::exp(1);

sub _check {
  my $self = shift;
  $self->SUPER::_check(@_);
  $self->Error("Can't raise e to a power") if $self->{lop}->string eq 'e';
}

sub _eval {
  my $self = shift;
  Value::cmp_Message("Can't raise e to a power") if $_[0] - $e == 0;
  $self->SUPER::_eval(@_);
}

##################################################

package LimitedPowers::OnlyIntegers;
@ISA = qw(Parser::BOP::power);

sub _check {
  my $self = shift; my $p = $self->{rop}; my $def = $self->{def};
  my $checker = (defined($def->{checker}) ? $def->{checker} :  \&LimitedPowers::isInteger);
  $self->SUPER::_check(@_);
  $self->Error("Powers must be $def->{message}")
    if $p->type ne 'Number' || !$p->{isConstant} || !&{$checker}($self,$p->eval);
}

##################################################

1;
