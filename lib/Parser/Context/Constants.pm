#########################################################################
#
#  Implements the list of named constants.
#
package Parser::Context::Constants;
use strict;
use vars qw (@ISA);
@ISA = qw(Value::Context::Data);

sub init {
  my $self = shift;
  $self->{dataName} = 'constants';
  $self->{name} = 'constant';
  $self->{Name} = 'Constant';
  $self->{namePattern} = '[a-zA-Z][a-zA-Z0-9]*';
}

#
#  Create data for constants
#
sub create {
  my $self = shift; my $value = shift;
  return {value => $value, keepName => 1};
}

#
#  Return a constant's value
#
sub value {
  my $self = shift; my $x = shift;
  return $self->{context}{constants}{$x}{value};
}

#########################################################################

1;

