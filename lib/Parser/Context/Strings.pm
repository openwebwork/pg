#########################################################################
#
#  Implement the list of known strings
#
package Parser::Context::Strings;
use strict;
use vars qw (@ISA);
@ISA = qw(Parser::Context::Data);

sub init {
  my $self = shift;
  $self->{dataName} = 'strings';
  $self->{name} = 'string';
  $self->{Name} = 'String';
  $self->{namePattern} = '[^\s]+';
}

#########################################################################

1;
