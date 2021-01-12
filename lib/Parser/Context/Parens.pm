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

sub addToken {
  my $self = shift; my $token = shift;
  my $data = $self->{context}{$self->{dataName}}{$token};
  unless ($data->{hidden}) {
    $self->{tokens}{$token} = "open";
    my $close = $data->{close};
    $self->{tokens}{$close} = "close" if defined($close) && $close ne $token;
  }
}

sub removeToken {
  my $self = shift; my $token = shift;
  my $data = $self->{context}{$self->{dataName}}{$token};
  unless ($data->{hidden}) {
    delete $self->{tokens}{$token};
    my $close = $data->{close};
    delete $self->{tokens}{$close} if defined($close) && $close ne $token;
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

#########################################################################

1;
