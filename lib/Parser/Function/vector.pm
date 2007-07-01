#########################################################################
#
#  Implement functions on vectors
#
package Parser::Function::vector;
use strict;
our @ISA = qw(Parser::Function);

#
#  Check for a single vector-valued input
#
sub _check {(shift)->checkVector(@_)}

#
#  Evaluate by promoting to a vector
#    and then calling the routine from Value.pm
#
sub _eval {
  my $self = shift; my $name = $self->{name};
  my $v = $self->Package("Vector")->promote($self->context,$_[0]);
  $v->$name;
}

#
#  Check for a single vector-valued argument
#  Then promote it to a vector (does error checking)
#    and call the routine from Value.pm
#
sub _call {
  my $self = shift; my $name = shift;
  Value::Error("Function '%s' has too many inputs",$name) if scalar(@_) > 1;
  Value::Error("Function '%s' has too few inputs",$name) if scalar(@_) == 0;
  my $v = shift; my $context = (Value::isValue($v) ? $v : $self)->context;
  $self->Package("Vector")->promote($context,$v)->$name;
}

#########################################################################

1;
