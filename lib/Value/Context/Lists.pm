#########################################################################
#
#  Implement the list of known Value::List types
#
package Value::Context::Lists;
use strict;
use vars qw (@ISA);
@ISA = qw(Value::Context::Data);

sub init {
  my $self = shift;
  $self->{dataName} = 'lists';
  $self->{name} = 'list';
  $self->{Name} = 'List';
  $self->{namePattern} = '[^\s]+';
}

#########################################################################

1;
