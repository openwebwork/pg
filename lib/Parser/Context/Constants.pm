#########################################################################
#
#  Implements the list of named constants.
#
package Parser::Context::Constants;
use strict;
our @ISA = qw(Value::Context::Data);

sub init {
  my $self = shift;
  $self->{dataName} = 'constants';
  $self->{name} = 'constant';
  $self->{Name} = 'Constant';
  $self->{namePattern} = qr/[a-zA-Z][a-zA-Z0-9]*|_blank_/;
  $self->{tokenType} = 'const';
}

#
#  Create/Uncreate data for constants
#
sub create {
  my $self = shift; my $value = shift;
  return $value if ref($value) eq 'HASH';
  return {value => $value, keepName => 1};
}
sub uncreate {shift; (shift)->{value}}

#
#  Return a constant's value
#
sub value {
  my $self = shift; my $x = shift;
  return $self->{context}{constants}{$x}{value};
}

#########################################################################

1;
