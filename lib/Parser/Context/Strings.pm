#########################################################################
#
#  Implement the list of known strings
#
package Parser::Context::Strings;
use strict;
use vars qw (@ISA);
@ISA = qw(Value::Context::Data);

sub init {
  my $self = shift;
  $self->{dataName} = 'strings';
  $self->{name} = 'string';
  $self->{Name} = 'String';
  $self->{namePattern} = '[\S ]+';
}

#########################################################################

1;
