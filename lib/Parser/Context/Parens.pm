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
}

sub addToken {
  my $self = shift; my $token = shift;
  my $data = $self->{context}{$self->{dataName}}{$token};
  unless ($data->{hidden}) {
    $self->{tokens}{$token} = "open";
    $self->{tokens}{$data->{close}} = "close" unless $data->{close} eq $token;
  }
}

sub removeToken {
  my $self = shift; my $token = shift;
  my $data = $self->{context}{$self->{dataName}}{$token};
  delete $self->{tokens}{$token};
  delete $self->{tokens}{$data->{close}} unless $data->{hidden} || $data->{close} eq $token;
}

#
#  Always retain 'start' since it is crucial to the parser
#
sub clear {
  my $self = shift;
  $self->SUPER::clear();
  $self->redefine('start');
}

#########################################################################

1;
