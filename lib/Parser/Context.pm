#
# add/remove/get reduction flags
# add/remove/get other flags
# 
# Make routine for selecting traditional multiplication parsing
# 

#########################################################################

package Parser::Context;
my $pkg = "Parser::Context";
use strict;

#
#  Crete a new Context object and initialize its data lists
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = bless {
    operators => {}, parens => {}, lists => {}, functions => {},
    variables => {}, constants => {}, strings => {},
    pattern => {
      number => '(?:\d+(?:\.\d*)?|\.\d+)(?:E[-+]?\d+)?',
      signedNumber => '[-+]?(\d+(\.\d*)?|\.\d+)(E[-+]?\d+)?',
      token => '',  # created in update() below
    },
    format => {
      number => '%g',
    },
    error => {
      string => '',
      pos => undef,
      message => '',
      flag => 0,
    },
  }, $class;
  my %data = (@_);
  $context->{_functions} = new Parser::Context::Functions($context,%{$data{functions}});
  $context->{_variables} = new Parser::Context::Variables($context,%{$data{variables}});
  $context->{_constants} = new Parser::Context::Constants($context,%{$data{constants}});
  $context->{_operators} = new Parser::Context::Operators($context,%{$data{operators}});
  $context->{_strings}   = new Parser::Context::Strings($context,%{$data{strings}});
  $context->{_parens}    = new Parser::Context::Parens($context,%{$data{parens}});
  $context->{_lists}     = new Parser::Context::Lists($context,%{$data{lists}});
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
sub lists     {(shift)->{_lists}}

#
#  Make a copy of a Context object
#
sub copy {
  my $self = shift;
  my $context = Parser::Context->new();
  $context->{_initialized} = 0;
  foreach my $data ('operators','functions','constants','variables',
                  'strings','parens','lists') {
    $context->{$data} = {};
    foreach my $x (keys %{$self->{$data}}) {
      $context->{$data}{$x} = {%{$self->{$data}{$x}}};
    }
    $context->{"_$data"}->update;
  }
  foreach my $data ('pattern','format') {
    $context->{$data} = {%{$self->{$data}}};
  }
  $context->{_initialized} = 1;
  return $context;
}

#
#  Storage for user contexts
#
our $contextTable = {};  # must be cleared each time for mod_perl

#
#  Set/Get the current Context object
#
sub current {
  my $self = shift; my $main = shift; $contextTable = $main if $main;
  my $context = $contextTable->{current};
  if (scalar(@_) > 0) {
    $context = Parser::Context->get(@_);
    Value::Error("Unknown context '@_'") unless $context;
  }
  $context = $Parser::Context::Default::fullContext->copy unless $context;
  $contextTable->{current} = $context;
  return $context;
}

#
#  Get a named context
#   (either from the main list or a copy from the default list)
#
sub get {
  my $self = shift; my $name = shift;
  my $context = $contextTable->{$name};
  return $context if $context;
  $context = $Parser::Context::Default::context{$name};
  return unless $context;
  return $context->copy;
}

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
         fn  => {precedence => 3},
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
    
    Value::Error("Precedence type should be one of 'Standard' or 'Non-standard'");
  }
}

#
#  Clear error flags
#
sub clearError {
  my $error = (shift)->{error};
  $error->{string} = '';
  $error->{pos} = undef;
  $error->{message} = '';
  $error->{flag} = 0;
}

#
#  Set the error flags
#
sub setError {
  my $error = (shift)->{error};
  $error->{message} = shift;
  $error->{string} = shift;
  $error->{pos} = shift;
  $error->{flag} = 1;
}

#########################################################################
#
#  Load the subclasses.
#

use Parser::Context::Data;
use Parser::Context::Default;

#########################################################################

1;
