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

contextString.pl - Allow string-valued answers.

=head1 DESCRIPTION

Implements contexts for string-valued answers.

You can add new strings to the context as needed
via the Context()->strings->add() method.  E.g.,

	Context("String")->strings->add(Foo=>{}, Bar=>{alias=>"Foo"});

Use string_cmp() to produce the answer checker(s) for your
correct values.  Eg.

	ANS(string_cmp("Foo"));

=cut

loadMacros("MathObjects.pl");

sub _contextString_init {context::String::Init()}; # don't load it again

##################################################

package context::String::Variable;

sub new {
  my $self = shift; my $equation = shift;
  my $context = $equation->{context};
  my @strings = grep {not defined($context->strings->get($_)->{alias})}
                  $context->strings->names;
  my $strings = join(', ',@strings[0..$#strings-1]).' or '.$strings[-1];
  $equation->Error(["Your answer should be one of %s",$strings]);
}

##################################################

package context::String::Formula;
our @ISA = qw(Value::Formula);

sub parse {
  my $self = shift;
  foreach my $ref (@{$self->{tokens}}) {
    $self->{ref} = $ref;
    context::String::Variable->new($self) if $ref->[0] eq 'error'; # display the error
  }
  $self->SUPER::parse(@_);
}

package context::String::BOP::mult;
our @ISA = qw(Parser::BOP);

sub _check {
  my $self = shift;
  context::String::Variable->new($self->{equation}); # report an error
}

##################################################

package context::String;

sub Init {
  my $context = $main::context{String} = Parser::Context->getCopy("Numeric");
  $context->{name} = "String";
  $context->{pattern}{number} = qr/^$/;
  $context->parens->clear();
  $context->variables->clear();
  $context->constants->clear();
  $context->operators->clear();
  $context->functions->clear();
  $context->strings->clear();
  $context->{parser}{Variable} = 'context::String::Variable';
  $context->{parser}{Formula}  = 'context::String::Formula';
  $context->operators->add(
    ' ' => {precedence => 3, associativity=>"left", type=>"bin", string => "*", class => 'context::String::BOP::mult'},
    '*' => {precedence => 3, associativity=>"left", type=>"bin", class => 'context::String::BOP::mult'}
  );

  main::PG_restricted_eval(<<'  END_EVAL');
    sub string_cmp {
      my $strings = shift;
      $strings = [$strings,@_] if (scalar(@_));
      $strings = [$strings] unless ref($strings) eq 'ARRAY';
      return map {String($_)->cmp(showHints=>0,showLengthHints=>0)} @{$strings};
    }
  END_EVAL

  main::Context("String");  ### FIXME:  probably should require author to set this explicitly
}

1;

