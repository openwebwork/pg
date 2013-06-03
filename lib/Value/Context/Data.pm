#########################################################################
#
#  Implements base class for data list in Context objects.
#
package Value::Context::Data;
use strict;
use Scalar::Util;

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $parent = shift;
  my $data = bless {
    context => $parent,     # parent context
    dataName => {},         # name of data storage in context hash
    tokens => {},           # hash of id => type specifications that will be made into a pattern
    patterns => {},         # hash of pattern => [precedence,type] specification for extra patterns
    tokenType => {},        # type of Parser token for these pattern
    namePattern => '',      # pattern for allowed names for new items
    name => '', Name => '', # lower- and upper-case names for the class of items
  }, $class;
  $data->weaken;
  $data->init();
  $parent->{$data->{dataName}} = {};
  push @{$parent->{data}{objects}},"_$data->{dataName}";
  $data->add(@_);
  return $data;
}

#
#  Implemented in sub-classes
#
sub init {}
sub create {shift; shift}
sub uncreate {shift; shift}

#
#  Copy the context data
#
sub copy {
  my $self = shift; my $orig = shift;
  my $data = $orig->{context}->{$orig->{dataName}};
  my $copy = $self->{context}->{$self->{dataName}};
  foreach my $name (keys %{$data}) {
    if (ref($data->{$name}) eq 'ARRAY') {
      $copy->{$name} = [@{$data->{$name}}];
    } elsif (ref($data->{$name}) eq 'HASH') {
      $copy->{$name} = {%{$data->{$name}}};
    } else {
      $copy->{$name} = $data->{$name};
    }
  }
  $self->{tokens} = {%{$orig->{tokens}}};
  foreach my $p (keys %{$orig->{patterns}}) {
    $self->{patterns}{$p} =
      (ref($orig->{patterns}{$p}) ? [@{$orig->{patterns}{$p}}] : $orig->{patterns}{$p});
  }
}

#
#  Make context pointer a weak pointer (avoids reference loops)
#
sub weaken {Scalar::Util::weaken((shift)->{context})}

#
#  Update the context patterns
#
sub update {(shift)->{context}->update}

sub addToken {
  my $self = shift; my $token = shift;
  $self->{tokens}{$token} = $self->{tokenType}
    unless $self->{context}{$self->{dataName}}{$token}{hidden};
}

sub removeToken {
  my $self = shift; my $token = shift;
  delete $self->{tokens}{$token};
}


#
#  Add one or more new items to the list
#
sub add {
  my $self = shift; my %D = (@_); return if scalar(@_) == 0;
  my $data = $self->{context}{$self->{dataName}};
  foreach my $x (keys %D) {
    Value::Error("Illegal %s name '%s'",$self->{name},$x) unless $x =~ m/^$self->{namePattern}$/;
    warn "$self->{Name} '$x' already exists" if defined($data->{$x});
    $data->{$x} = $self->create($D{$x});
    $self->addToken($x);
  }
  $self->update;
}

#
#  Remove one or more items
#
sub remove {
  my $self = shift;
  my $data = $self->{context}{$self->{dataName}};
  foreach my $x (@_) {
    warn "$self->{Name} '$x' doesn't exist" unless defined($data->{$x});
    $self->removeToken($x);
    delete $data->{$x};
  }
  $self->update;
}

#
#  Replace an item with a new definition
#
sub replace {
  my $self = shift; my %list = (@_);
  $self->remove(keys %list);
  $self->add(@_);
}

#
#  Clear all items
#
sub clear {
  my $self = shift;
  $self->{context}{$self->{dataName}} = {};
  $self->{tokens} = {};
  $self->update;
}

#
#  Make the data be only these items
#
sub are {
  my $self = shift;
  $self->clear;
  $self->add(@_);
}

#
#  Make one or more items become undefined, but still recognized.
#  (Implemented in the sub-classes.)
#
sub undefine {my $self = shift; $self->remove(@_)}

#
#  Redefine items from the default context, or a given one
#
sub redefine {
  my $self = shift; my $X = shift;
  my %options = (using => undef, from => "Full", @_);
  my $Y = $options{using}; my $from = $options{from};
  $from = $Parser::Context::Default::context{$from} unless ref($from);
  $Y = $X if !defined($Y) && !ref($X);
  $X = [$X] unless ref($X) eq 'ARRAY';
  my @data = (); my @remove = ();
  foreach my $x (@{$X}) {
    my $y = defined($Y)? $Y: $x;
    Value::Error("No definition for %s '%s' in the given context",$self->{name},$y)
      unless $from->{$self->{dataName}}{$y};
    push(@remove,$x) if $self->get($x);
    push(@data,$x => $self->uncreate($from->{$self->{dataName}}{$y}));
  }
  $self->remove(@remove);
  $self->add(@data);
}


#
#  Get hash for an item
#
sub get {
  my $self = shift; my $x = shift;
  return $self->{context}{$self->{dataName}}{$x};
}

#
#  Set flags for one or more items
#
sub set {
  my $self = shift; my %D = (@_);
  my $data = $self->{context}{$self->{dataName}};
  foreach my $x (keys(%D)) {
    my $xref = $data->{$x};
    if (defined($xref) && ref($xref) eq 'HASH') {
      foreach my $id (keys %{$D{$x}}) {$xref->{$id} = $D{$x}{$id}}
    } else {
      $data->{$x} = $self->create($D{$x});
      $self->addToken($x);
    }
  };
}

#
#  Get the names of all items
#
sub names {
  my $self = shift;
  return sort(keys %{$self->{context}{$self->{dataName}}});
}

#
#  Get the complete data hash
#
sub all {
  my $self = shift;
  $self->{context}{$self->{dataName}};
}

#########################################################################
#
#  Load the subclasses.
#

END {
  use Value::Context::Flags;
  use Value::Context::Lists;
  use Value::Context::Diagnostics;
}

#########################################################################

1;
