#########################################################################
#
#  The basic context (Parser::Context is a subclass of this)
#

package Value::Context;
my $pkg = "Value::Context";
use strict; no strict "refs";
use UNIVERSAL;

#
#  Create a new Context object and initialize its data lists
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = bless {
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
      hashes => ['cmpDefaults'],
      arrays => ['data'],
      values => ['pattern','format','value'],
      objects => [],
    },
    value => {
      Formula => "Value::Formula"
    },
  }, $class;
  my %data = (lists=>{},flags=>{},diagnostics=>{},@_);
  $context->{_lists} = new Value::Context::Lists($context,%{$data{lists}});
  $context->{_flags} = new Value::Context::Flags($context,%{$data{flags}});
  $context->{_diagnostics} = new Value::Context::Diagnostics($context,%{$data{diagnostics}});
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
sub lists         {(shift)->{_lists}}
sub flags         {(shift)->{_flags}}
sub flag          {(shift)->{_flags}->get(shift)}
sub diagnostics   {(shift)->{_diagnostics}}

#
#  Make a copy of a Context object
#
sub copy {
  my $self = shift;
  my $context = $self->new();
  $context->{_initialized} = 0;
  foreach my $data (@{$context->{data}{objects}}) {
    $context->{$data}->copy($self->{$data});
  }
  foreach my $data (@{$context->{data}{hashes}}) {
    $context->{$data} = {};
    foreach my $x (keys %{$self->{$data}}) {
      $context->{$data}{$x} = {%{$self->{$data}{$x}}};
    }
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
  $context->{error}{msg} = {%{$self->{error}{msg}}};
  $context->{error}{convert} = $self->{error}{convert}
    if defined $self->{error}{convert};
  $context->{name} = $self->{name};
  $context->{_initialized} = 1;
  return $context;
}

#
#  Returns the package name for the specificied Value object class
#  (as specified by the context's {value} hash, or "Value::name").
#
sub Package {
  my $context = shift; my $class = shift;
  return $context->{value}{$class} if defined $context->{value}{$class};
  $class =~ s/\(\)$//;
  return $context->{value}{$class} if defined $context->{value}{$class};
  return "Value::$class" if @{"Value::${class}::ISA"};
  Value::Error("No such package 'Value::%s'",$class) unless $_[0];
}

#
#  Make these available to Contexts
#
sub isa {UNIVERSAL::isa(@_)}
sub can {UNIVERSAL::can(@_)}

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
  while ($message && $error->{msg}{$message}) {$message = $error->{msg}{$message}}
  $message .= sprintf($more,$pos->[0]+1) if $more;
  $message = &{$error->{convert}}($message) if defined $error->{convert};
  $error->{message} = $message;
  $error->{string} = $string;
  $error->{pos} = $pos;
  $error->{flag} = $flag || 1;
}

#########################################################################
#
#  Load the subclasses.
#

END {
  use Value::Context::Data;
}

#########################################################################

1;
