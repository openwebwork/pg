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

C<Context("AlternateIntervals")> - Provides a context that allows the
entry of intervals using reversed bracket notation for open endpoints
(e.g., C<]a,b[> rather than C<(a,b)> for an open interval).


=head1 DESCRIPTION

This macro file defines contexts in which open intervals can be
specified using reversed brackets rather than parentheses.  Both forms
are always recognized, but you can determine whether one or the other
form produces an error message when used.  You can also force the
display of intervals to use one or the other form.


=head1 USAGE

To use this file, first load it into your problem, then select the
context that you wish to use.  There are three pre-defined contexts,
C<AlternateIntervals>, C<AlternateIntervals-Only>, and
C<AlternateIntervals-Warning>.  The first allows both the standard and
alternate forms to be used, the second allows only the alternate form,
and the third allows only the standard form, but recognizes the
alternate form and gives an error message when it is used.

	loadMacros("contextAlternateIntervals.pl");
	
	Context("AlternateIntervals");
	
	$I1 = Compute("]2,5[");
        $I2 = Compute("(2,5)");    # equivalent to $I1;
	
	Context("AlternateIntervals-Only");
	
	$I1 = Compute("]2,5[");
        $I2 = Compute("(2,5)");    # causes an error message
	
	Context("AlternateIntervals-Warning");
	
	$I1 = Compute("]2,5[");    # causes an error message
        $I2 = Compute("(2,5)");

There are two context flags that control the input and output of
intervals.

=over

=item C<S<< enterIntervals => "either" (or "alternate" or "stanard") >>>

This specifies what formats the student is allowed to use to enter an
interval.  A value of C<"either"> allows either of the formats to be
accepted, while the other two options produce error messages if the
wrong form is used.

=item C<S<< displayIntervals => "either" (or "alternate" or "standard") >>>

This controls how intervals are displayed.  When set to C<"either">, the
interval is displayed in whatever format was used to create it.  When
set to C<"standard"> or C<"alternate">, the display is forced to be in the
given format regardless of how it was entered.

=back

The C<AlternateIntervals> context has both flags set to C<"either">, so the
intervals remain in the format the student entered them, and either
form can be used.  The C<AlternateIntervals-Only> context has both set to
C<"alternate">, so only the alternate format can be used, and any
Interval will be displayed in alternate format.  The
C<AlternateIntervals-Warning> context has both set to C<"standard">, so only
standard format can be used, and all intervals will be displayed in
standard format.

It is possible to set C<enterIntervals> and C<displayIntervals> to
different values.  For example.

	Context()->flags->set(
	  enterIntervals => "either",
	  displayIntervals => "standard",
	);

would allow students to enter intervals in either format, but all
intervals would be displayed in standard form.

=head1 SETTING THE ALTERNATE FORM AS THE DEFAULT

If you want to force existing problems that use the Interval context
to use one of the alternate contexts instead, then create a file named
C<parserCustomization.pl> in your course's C<templates/macros>
directory, and enter the following in it:

	loadMacros("contextAlternateIntervals.pl");
	context::AlternateIntervals->Default("either","either");

This will alter the C<Interval> context so that students can
enter intervals in either format (and they will be shown in whatever
format that was used to enter them).

You could also do

	loadMacros("contextAlternateIntervals.pl");
	context::AlternateIntervals->Default("standard","standard");

to cause a warning message to appear when students enter the alternate
format.

If you want to force students to enter the alternate format, use

	loadMacros("contextAlternateIntervals.pl");
	context::AlternateIntervals->Default("alternate","alternate");

This will force the display of all intervals into the alternate form
(so even the ones created in the problem using standard form will show
using the alternate format), and will force students to enter their
results using the alternate format, though professor's answers will
still be allowed to be entered in either format (the C<Default()>
function converts the first C<"alternate"> to C<"either">, but
arranges that the default flags for the answer checker are set to only
allow students to enter the alternative format).  This allows you to
force alternate notation in problems without having to rewrite them.

=cut

##########################################################################

loadMacros("MathObjects.pl");

sub _contextAlternateIntervals_init {context::AlternateIntervals->Init}


##########################################################################

package context::AlternateIntervals;

#
#  Create the AlternateIntervals contexts
#
sub Init {
  my $self = shift;
  my $context = $main::context{AlternateIntervals} = Parser::Context->getCopy("Interval");
  $context->{name} = "AlternateIntervals";
  $self->Enable($context);

  $context = $main::context{"AlternateIntervals-Only"} = $context->copy;
  $context->{name} = "AlternativeIntervals-Only";
  $context->flags->set(
    enterIntervals   => "alternate",
    displayIntervals => "alternate",
  );

  $context = $main::context{"AlternateIntervals-Warning"} = $context->copy;
  $context->{name} = "AlternativeIntervals-Warning";
  $context->flags->set(
    enterIntervals   => "standard",
    displayIntervals => "standard",
  );
}

#
#  Enables alternate intervals in the given context
#
sub Enable {
  my $self = shift; my $context = shift || main::Context();
  $context->flags->set(
    enterIntervals   => "either",    # or "standard" or "alternate"
    displayIntervals => "either",    # or "standard" or "alternate"
  );
  $context->parens->set(
    "[" => {close => "[", type => "Interval", formInterval => ["]",")"], removable => 0},
    "]" => {close => "]", type => "Interval", formInterval => "["},
  );
  $context->update;
  $context->{value}{Interval} = "context::AlternateIntervals::Interval";
  $context->{value}{Formula}  = "context::AlternateIntervals::Formula";
  $context->{parser}{Formula} = "context::AlternateIntervals::Formula";
  $context->{parser}{List} = "context::AlternateIntervals::Parser::List";
  $context->lists->set("Interval" => {class=>"context::AlternateIntervals::Parser::Interval"});
}

#
#  Sets the default Interval context to use alternate decimals.  The
#  two arguments determine the values for the enterIntervals and
#  displayIntervals flags.  If enterIntervals is "alternate", then
#  student answers must use the alternate format for entering
#  intervals (though professors can use either).
#
sub Default {
  my $self = shift; my $enter = shift || "either";  my $display = shift || "either";
  my $cmp = ($enter eq "alternate"); $enter = "either" if $cmp;
  #
  #  This adds the names from InequalitySetBuilder, but we need a better way to
  #  link into contexts as they are created and copied.
  #
  my @InequalitySetBuilder = (
    "SetBuilder::",
    "InequalitySetBuilder::",
    "InequalitySetBuilderInterval::",
    "InequalitySetBuilderUnion::",
    "InequalitySetBuilderSet::",
  );
  foreach my $name ("Interval","Full") {
    my $context = $main::context{$name} = Parser::Context->getCopy($name);
    $self->Enable($context);
    $context->flags->set(enterIntervals => $enter, displayIntervals => $display);
    if ($cmp) {
      foreach my $class ((grep {/::/} (keys %Value::)),@InequalitySetBuilder) {
        $context->{cmpDefaults}{substr($class,0,-2)}{enterIntervals} = "alternate";
      }
    }
  }
  main::Context(main::Context()->{name});
}

##########################################################################

package context::AlternateIntervals::Formula;
our @ISA = ('Value::Formula');

#
#  Replace the standard Open with one that handles formInterval better.
#  We need to handle several possible close delimiters.
#
sub Open {
  my $self = shift; my $type = shift;
  my $paren = $self->{context}{parens}{$type};
  if ($self->state eq 'operand') {
    if ($type eq $paren->{close}) {
      my $stack = $self->{stack}; my $i = scalar(@{$stack})-1;
      while ($i >= 0 && $stack->[$i]{type} ne "open") {$i--}
      if ($i >= 0 && $stack->[$i]{close}{$type}) {
	$self->Close($type,$self->{ref});
	return;
      }
    }
    $self->ImplicitMult();
  }
  my $item = {type => 'open', value => $type, ref => $self->{ref}, close => {}};
  if ($paren->{formInterval}) {
    my $close = $paren->{formInterval}; $close = [$close] unless ref($close) eq 'ARRAY';
    $item->{close} = {map {$_ => 1} @$close};
  }
  $item->{close}{$type} = 1;
  $self->push($item);
}

#
#  We need to modify the test for formInterval to NOT check the number
#  of entries so that better error messages are produced, and to handle
#  multiple close delimiters.  These are both in teh "operand" branch,
#  so do the original for all the choices, and copy that branch here,
#  with our modifications.
#
sub Close {
  my $self = shift; my $type = shift;
  my $ref = $self->{ref} = shift;
  my $parens = $self->{context}{parens};

  return $self->SUPER::Close($type,$ref,@_) if $self->state ne "operand";

  $self->Precedence(-1); return if ($self->{error});
  if ($self->state ne 'operand') {$self->Close($type,$ref); return}
  my $paren = $parens->{$self->prev->{value}};
  if ($paren->{close} eq $type) {
    my $top = $self->pop;
    if (!$paren->{removable} || ($top->{value}->type eq "Comma")) {
      $top = $top->{value};
      $top = {type => 'operand', value =>
	      $self->Item("List")->new($self,[$top->makeList],$top->{isConstant},$paren,
				       ($top->type eq 'Comma') ? $top->entryType : $top->typeRef,
				       ($type ne 'start') ? ($self->top->{value},$type) : () )};
    } else {$top->{value}{hadParens} = 1}
    $self->pop; $self->push($top);
    $self->CloseFn() if ($paren->{function} && $self->prev->{type} eq 'fn');
  } else {
    my $close = $paren->{formInterval}||[]; $close = [$close] unless ref($close) eq 'ARRAY';
    $close = {map {$_ => 1} @$close};
    if ($close->{$type}) {
      my $top = $self->pop->{value}; my $open = $self->pop->{value};
      $self->pushOperand(
         $self->Item("List")->new($self,[$top->makeList],$top->{isConstant},
				  $paren,$top->entryType,$open,$type));
    } else {
      my $prev = $self->prev;
      if ($type eq "start") {$self->Error(["Missing close parenthesis for '%s'",$prev->{value}],$prev->{ref})}
      elsif ($prev->{value} eq "start") {$self->Error(["Extra close parenthesis '%s'",$type],$ref)}
      else {$self->Error(["Mismatched parentheses: '%s' and '%s'",$prev->{value},$type],$ref)}
    }
  }
}

sub class {'Formula'}

##########################################################################

package context::AlternateIntervals::Interval;
our @ISA = ('Value::Interval');

#
#  Convert alternative form to regular form, but mark it as alternative.
#  Give error messages about forms that aren't allowed by the context flags.
#
sub new {
  my $self = shift;
  return $self->SUPER::new(@_) unless scalar(@_) == 5;
  my @args = @_; my $alternate; my $format = $self->getFlag("enterIntervals");
  if ($args[1] eq "]") {$alternate = 1; $args[1] = "("}
  if ($args[4] eq "[") {$alternate = 1; $args[4] = ")"}
  Value->Error("You must use parentheses to form open intervals")
    if $alternate && $format eq "standard";
  Value->Error("You must use reversed brackets to form open intervals")
    if ($_[1] eq "(" || $_[4] eq ")") && $format eq "alternate";
  $self->SUPER::new(@args)->with(alternateForm => $alternate);
}

#
#  For alternative form, switch back to the alternative brackets for printing,
#  or force standard or alternative form based on the context flags.
#
sub formatOutput {
  my $self = shift; my $method = shift; my @args = @_;
  my $format = $self->getFlag("displayIntervals");
  my $alternate = ($self->{alternateForm} || $format eq "alternate") && $format ne "standard";
  $args[1] = "]" if $alternate && ($args[1]||$self->{open}) eq "(";
  $args[2] = "[" if $alternate && ($args[2]||$self->{close}) eq ")";
  $method = "SUPER::$method";
  $self->$method(@args);
}

sub string {
  my $self = shift;
  $self->formatOutput("string",@_);
}

sub TeX {
  my $self = shift;
  $self->formatOutput("TeX",@_);
}

#
#  This gets called directly, so pass it up the line
#
sub cmp_defaults {shift->SUPER::cmp_defaults(@_)}

##########################################################################

package context::AlternateIntervals::Parser::List;
our @ISA = ('Parser::List');

#
#  Make sure that the standard open and close delimiters are
#  used so that comparisons and so on will work properly.
#
sub new {
  my $self = shift;
  my $alternate = ($_[5] eq "]" || $_[6] eq "[");
  my $list = $self->SUPER::new(@_);
  return $list unless $alternate && $list->type eq "Interval";
  my $L = ($list->class eq "Value" ? $list->{value} : $list);
  $L->{open} = "(" if $L->{open} eq "]";
  $L->{close} = ")" if $L->{close} eq "[";
  $L->{alternateForm} = 1;
  return $list
}

sub class {"List"}

##########################################################################

package context::AlternateIntervals::Parser::Interval;
our @ISA = ('Parser::List::Interval');

#
#  Report errors when invalid form is specified
#
sub _check {
  my $self = shift; my $context = $self->context;
  my $format = (($context->{answerHash}||{})->{enterIntervals} || $context->flag("enterIntervals"));
  $self->Error("You must use parentheses to form open intervals")
    if $format eq "standard"  && ($self->{open} eq "]" || $self->{close} eq "[");
  $self->Error("You must use reversed brackets to form open intervals")
    if $format eq "alternate" && ($self->{open} eq "(" || $self->{close} eq ")");
  $self->SUPER::_check(@_);
}

#
#  Make a copy with the alternate delimiters, if needed.
#
sub fixDelimiters {
  my $self = shift; my $alternate = shift;
  if ($alternate) {
    $self = $self->copy;
    $self->{open} = "]" if $self->{open} eq "(";
    $self->{close} = "[" if $self->{close} eq ")";
  }
  $self;
}

#
#  Override the output methods to replace the alternate delimiters,
#  when needed.
#

sub _eval {
  my $self = shift;
  return $self->fixDelimiters($self->{alternateForm})->SUPER::_eval(@_);
}

sub string {
  my $self = shift;
  my $format = $self->{equation}{context}->flag("displayIntervals");
  my $alternate = $self->type eq "Interval" &&
       ($self->{alternateForm} || $format eq "alternate") && $format ne "standard";
  $self->fixDelimiters($alternate)->SUPER::string(@_);
}

sub TeX {
  my $self = shift;
  my $format = $self->{equation}{context}->flag("displayIntervals");
  my $alternate = $self->type eq "Interval" &&
       ($self->{alternateForm} || $format eq "alternate") && $format ne "standard";
  $self->fixDelimiters($alternate)->SUPER::TeX(@_);
}

sub class {"Interval"}

##########################################################################

1;
