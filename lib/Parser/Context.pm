#
# add/remove/get reduction flags
# make patterns into real patterns, not strings
#

#########################################################################

package Parser::Context;
my $pkg = "Parser::Context";
use strict;
use vars qw(@ISA);
@ISA = qw(Value::Context);

#
#  Create a new Context object and initialize its data lists
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = $Value::defaultContext->copy;
  bless $context, $class;
  $context->{parser} = {%{$Parser::class}};
  push(@{$context->{data}{values}},'parser');
  $context->{_initialized} = 0;
  push(@{$context->{data}{objects}},(
    'functions','variables','constants','operators','strings','parens',
  ));
  push(@{$context->{data}{values}},'reduction');
  my %data = (
    functions => {},
    variables => {},
    constants => {},
    operators => {},
    strings   => {},
    parens    => {},
    lists     => {},
    flags     => {},
    reduction => {},
    @_
  );
  $context->{_functions} = new Parser::Context::Functions($context,%{$data{functions}});
  $context->{_variables} = new Parser::Context::Variables($context,%{$data{variables}});
  $context->{_constants} = new Parser::Context::Constants($context,%{$data{constants}});
  $context->{_operators} = new Parser::Context::Operators($context,%{$data{operators}});
  $context->{_strings}   = new Parser::Context::Strings($context,%{$data{strings}});
  $context->{_parens}    = new Parser::Context::Parens($context,%{$data{parens}});
  $context->{_reduction} = new Parser::Context::Reduction($context,%{$data{reduction}});
  $context->lists->set(%{$data{lists}});
  $context->flags->set(%{$data{flags}});
  $context->{_initialized} = 1;
  $context->update;
  return $context;
}

#
#  Update the token pattern
#
sub update {
  my $self = shift; return unless $self->{_initialized};
  $self->{pattern}{token} =
   '(?:('.join(')|(',
         $self->strings->{pattern},
         $self->functions->{pattern},
         $self->constants->{pattern},
         $self->{pattern}{number},
         $self->operators->{pattern},
         $self->parens->{open},
         $self->parens->{close},
         $self->variables->{pattern},
  ).'))';
}

#
#  Access to the data lists
#
sub operators {(shift)->{_operators}}
sub functions {(shift)->{_functions}}
sub constants {(shift)->{_constants}}
sub variables {(shift)->{_variables}}
sub strings   {(shift)->{_strings}}
sub parens    {(shift)->{_parens}}
sub reduction {(shift)->{_reduction}}

sub reduce     {(shift)->{_reduction}->reduce(@_)}
sub noreduce   {(shift)->{_reduction}->noreduce(@_)}
sub reductions {(shift)->{_reduction}}

#
#  Store pointer to user's context table
#
my $userContext;

#
#  Set/Get the current Context object
#
sub current {
  my $self = shift; my $contextTable = shift; my $context = shift;
  if ($contextTable) {$userContext = $contextTable} else {$contextTable = $userContext}
  if (defined($context)) {
    if (!ref($context)) {
      my $name = $context;
      $context = Parser::Context->get($contextTable,$context);
      Value::Error("Unknown context '%s'",$name) unless defined($context);
    }
    $contextTable->{current} = $context;
    $Value::context = \$contextTable->{current};
  } elsif (!defined($contextTable->{current})) {
    $contextTable->{current} = $Parser::Context::Default::numericContext->copy;
    $Value::context = \$contextTable->{current};
  }
  return $contextTable->{current};
}

#
#  Get a copy of a named context
#   (either from the main list or from the default list)
#
sub getCopy {
  my $self = shift; my $contextTable = shift; my $name = shift;
  $contextTable = $userContext unless $contextTable;
  my $context = $contextTable->{$name};
  $context = $Parser::Context::Default::context{$name} unless $context;
  return unless $context;
  return $context->copy;
}

#
#  Obsolete:  use "getCopy" instead
#
sub get {shift->getCopy(@_)}

#
#  Update the precedences of multiplication so that they
#  are the standard or non-standard ones, depending on the
#  argument.  It should be 'Standard' or 'Non-Standard'.
#
sub usePrecedence {
  my $self = shift;
  for (shift) {

    /^Standard/i  and do {
      $self->operators->set(
        ' *' => {precedence => 3},
        '* ' => {precedence => 3},
        ' /' => {precedence => 3},
        '/ ' => {precedence => 3},
         fn  => {precedence => 7.5},
         ' ' => {precedence => 3},
      );
      last;
    };

    /^Non-Standard/i and do {
      $self->operators->set(
        ' *' => {precedence => 2.8},
        '* ' => {precedence => 2.8},
        ' /' => {precedence => 2.8},
        '/ ' => {precedence => 2.8},
         fn  => {precedence => 2.9},
         ' ' => {precedence => 3.1},
      );
      last;
    };

    Value::Error("Precedence type should be one of 'Standard' or 'Non-Standard'");
  }
}

#########################################################################
#
#  Load the subclasses.
#

use Parser::Context::Constants;
use Parser::Context::Functions;
use Parser::Context::Operators;
use Parser::Context::Parens;
use Parser::Context::Strings;
use Parser::Context::Variables;
use Parser::Context::Reduction;

#########################################################################

1;
