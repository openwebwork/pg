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
      msg => {},  # for localization
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
#  Make a copy with additional initialization
#  (defined in subclasses)
#
sub initCopy {shift->copy(@_)}

#
#  Make stringify produce TeX or regular strings
#
sub texStrings {shift->flags->set(StringifyAsTeX=>1)}
sub normalStrings {shift->flags->set(StringifyAsTeX=>0)}

#
#  Clear error flags
#
sub clearError {
  my $error = (shift)->{error};
  $error->{string} = '';
  $error->{pos} = undef;
  $error->{message} = '';
  $error->{original} = '';
  $error->{flag} = 0;
}

#
#  Set the error flags
#
sub setError {
  my $error = (shift)->{error};
  my ($message,$string,$pos,$more,$flag) = @_;
  my @args = ();
  ($message,@args) = @{$message} if ref($message) eq 'ARRAY';
  $error->{original} = $message;
  while ($message && $error->{msg}{$message}) {$message = $error->{msg}{$message}}
  while ($more && $error->{msg}{$more}) {$more = $error->{msg}{$more}}
  $message = sprintf($message,@args) if scalar(@args) > 0;
  $message .= sprintf($more,$pos->[0]+1) if $more;
  $error->{message} = $message;
  $error->{string} = $string;
  $error->{pos} = $pos;
  $error->{flag} = $flag || 1;
}

#########################################################################
#
#  Load the subclasses.
#

use Value::Context::Data;

#########################################################################

1;
