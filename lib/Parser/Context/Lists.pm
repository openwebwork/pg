#########################################################################
#
#  Implement the list of known Parser::List types
#
package Parser::Context::Lists;
use strict;
use vars qw (@ISA);
@ISA = qw(Parser::Context::Data);

sub init {
  my $self = shift;
  $self->{dataName} = 'lists';
  $self->{name} = 'list';
  $self->{Name} = 'List';
  $self->{namePattern} = '[^\s]+';
}

sub update {} # no pattern needed

#########################################################################

1;
