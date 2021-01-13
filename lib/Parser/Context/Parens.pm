#########################################################################
#
#  Implement the list of allowed parentheses.
#
package Parser::Context::Parens;
use strict;
our @ISA = qw(Value::Context::Data);

sub init {
  my $self = shift;
  $self->{dataName} = 'parens';
  $self->{name} = 'parenthesis';
  $self->{Name} = 'Parenthesis';
  $self->{namePattern} = qr/\S+/;
  $self->{tokenType} = 'open';
  $self->{closes} = {};
}

#
#  Determine if a close token matches with an open one.
#
sub match {
  my $self = shift; my ($open,$close) = @_;
  ($open) = $self->resolve($open);
  return $self->{closes}{$open}{$close} || 0;
}

#
#  Do the usual add, and then add the close tokens
#
sub addToken {
  my $self = shift; my $token = shift;
  $self->SUPER::addToken($token);
  my $data = $self->{context}{$self->{dataName}}{$token};
  unless ($data->{hidden}) {
    my $close = $data->{close};
    $self->{tokens}{$close} = 'close' if defined($close) && $close ne $token;
    $self->addAlternativeClose($token);
  }
}

#
#  Add alternative close tokens
#
sub addAlternativeClose {
  my $self = shift; my $token = shift;
  my $data = $self->{context}{$self->{dataName}}{$token};
  foreach my $alt (@{$data->{alternativeClose} || []}) {
    Value::Error("Illegal %s name '%s'",$self->{name},$alt) unless $alt =~ m/^$self->{namePattern}$/;
    $self->{tokens}{$alt} = ['close', $data->{close}];
  }
}

#
#  Do the usual remove, and then remove close tokens
#
sub removeToken {
  my $self = shift; my $token = shift;
  $self->SUPER::removeToken($token);
  my $data = $self->{context}{$self->{dataName}}{$token};
  unless ($data->{hidden}) {
    my $close = $data->{close};
    delete $self->{tokens}{$close} if defined($close) && $close ne $token;
    $self->removeAlternativeClose($token);
  }
}

#
#  Remove the alternative close tokens
#
sub removeAlternativeClose {
  my $self = shift; my $token = shift;
  my $data = $self->{context}{$self->{dataName}}{$token};
  foreach my $alt (@{$data->{alternativeClose} || []}) {
    delete $self->{tokens}{$alt};
  }
}

#
#  Create the {closes} hash
#
sub update {
  my $self = shift;
  $self->SUPER::update(@_);
  $self->{closes} = {};
  my $data = $self->{context}{$self->{dataName}};
  foreach my $open (keys %{$data}) {
    my $def = $data->{$open};
    my ($base) = $self->resolve($open);
    $self->{closes}{$base}{$def->{close}} = 1 if $def->{close};
  }
}

#
#  Always retain 'start' since it is crucial to the parser
#
sub clear {
  my $self = shift;
  $self->SUPER::clear();
  $self->redefine('start');
}

#
#  Copy the {closes} hash
#
sub copy {
  my $self = shift; my $orig = shift;
  $self->SUPER::copy($orig);
  $self->{closes} = {};
  foreach my $open (keys %{$orig->{closes}}) {
    $self->{closes}{$open} = {%{$orig->{closes}{$open}}};
  }
}

sub set {
  my $self = shift;
  $self->SUPER::set(@_);
  my %D = (@_);
  my $data = $self->{context}{$self->{dataName}};
  my $update = 0;
  foreach my $x (keys(%D)) {
    foreach my $id (keys %{$D{$x}}) {
      if ($id eq 'alternativeClose' && !$D{$x}{hidden}) {
        $self->addAlternativeClose($x);
        $update = 1;
      }
    }
  };
  $self->update if $update;
}

#########################################################################

1;
