#########################################################################
#
#  The basic context (Parser::Context is a subclass of this)
#

package Value::Context;
my $pkg = "Value::Context";
use strict;

#
#  Create a new Context object and initialize its data lists
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = bless {
    flags => {}, 
    pattern => {
      number => '(?:\d+(?:\.\d*)?|\.\d+)(?:E[-+]?\d+)?',
      signedNumber => '[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:E[-+]?\d+)?',
    },
    format => {
      number => '%g',  # default format for Reals
    },
    error => {
      string => '',
      pos => undef,
      message => '',
      flag => 0,
    },
    data => {
      hashes => ['lists'],
      arrays => ['data'],
      values => ['flags','pattern','format'],
    },
  }, $class;
  my %data = (lists=>{},flags=>{},@_);
  $context->{_lists} = new Value::Context::Lists($context,%{$data{lists}});
  $context->{_flags} = new Value::Context::Flags($context,%{$data{flags}});
  $context->{_initialized} = 1;
  $context->update;
  return $context;
}

#
#  Implemented in subclasses
#
sub update {}

#
#  Access to the data lists
#
sub lists     {(shift)->{_lists}}
sub flags     {(shift)->{_flags}}
sub flag      {(shift)->{_flags}->get(shift)}

#
#  Make a copy of a Context object
#
sub copy {
  my $self = shift;
  my $context = $self->new();
  $context->{_initialized} = 0;
  foreach my $data (@{$context->{data}{hashes}}) {
    $context->{$data} = {};
    foreach my $x (keys %{$self->{$data}}) {
      $context->{$data}{$x} = {%{$self->{$data}{$x}}};
    }
    $context->{"_$data"}->update;
  }
  foreach my $data (@{$context->{data}{arrays}}) {
    $context->{$data} = {};
    foreach my $x (keys %{$self->{$data}}) {
      $context->{$data}{$x} = [@{$self->{$data}{$x}}];
    }
  }
  foreach my $data (@{$context->{data}{values}}) {
    $context->{$data} = {%{$self->{$data}}};
  }
  $context->{_initialized} = 1;
  return $context;
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

use Value::Context::Data;

#########################################################################

1;
