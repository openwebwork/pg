#########################################################################
#
#  Implement the list of known Value::List types
#
package Value::Context::Lists;
use strict;
our @ISA = ("Value::Context::Data");

sub init {
  my $self = shift;
  $self->{dataName} = 'lists';
  $self->{name} = 'list';
  $self->{Name} = 'List';
  $self->{namePattern} = qr/[^\s]+/;
}

sub update {} # no pattern or tokens needed
sub addToken {}
sub removeToken {}

#########################################################################

1;
