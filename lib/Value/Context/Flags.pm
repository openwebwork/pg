#########################################################################
#
#  Implement the list of Value::Flags types
#
package Value::Context::Flags;
use strict;
use vars qw (@ISA);
@ISA = qw(Value::Context::Data);

sub init {
  my $self = shift;
  $self->{dataName} = 'flags';
  $self->{name} = 'flag';
  $self->{Name} = 'Flag';
  $self->{namePattern} = '[-\w_.]+';
}

sub update {} # no pattern needed

#########################################################################

1;
