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

parserAutoStrings.pl - Force String() to accept any string.

=head1 DESCRIPTION

This file allows you to force String() to accept ANY string as a
legal value.  (It will add the string to the context if it isn't
already defined.)

To accomplish this, put the lines

	loadMacros("parserAutoStrings.pl");
	AutoStrings();

at the beginning of your problem file.  (You can also pass AutoStrings
a context pointer if you wish to alter context other than the current
one.)

There is also a routine to help make strings easier to predefine.
For example:

	loadMacros("parserAutoStrings.pl");
	DefineStrings("string1","string2");

would define two new strings (string1 and string2).  You can pass
a context reference as the first argument to add strings to that
context rather than the active one.

=cut

sub _parserAutoStrings_init {}

######################################################################

sub AutoStrings {(shift || Value->context)->{value}{"String()"} = "parser::AutoStrings"};

sub DefineStrings {
  my $context = (Value::isContext($_[0]) ? shift : Value->context);
  foreach my $x (@_)
    {$context->strings->add($x=>{}) unless defined $context->{strings}{$x}}
}

######################################################################

package parser::AutoStrings;
our @ISA = ("Value::String");

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $x = join('',@_);
  $context->strings->add($x=>{}) unless defined $context->{strings}{$x};
  $self->SUPER::new($x);
}

######################################################################

1;
