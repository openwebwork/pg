#########################################################################
#
#  Implements functions that require complex inputs
#
package Parser::Function::complex;
use strict; use vars qw(@ISA);
@ISA = qw(Parser::Function);

#
#  Check that the argument is complex, and
#    mark the result as real or complex, as appropriate.
#
sub _check {
  my $self = shift;
  return $self->checkComplex(@_) if $self->{def}{complex};
  return $self->checkReal(@_);
}

#
#  Evaluate by calling the appropriate routine from Value.pm.
#
sub _eval {
  my $self = shift; my $name = $self->{name};
  my $c = Value::Complex::promote($_[0]);
  $c->$name;
}

#
#  Check for the right number of arguments.
#  Convert argument to a complex (does error checking)
#    and then call the appropriate routine from Value.pm.
#
sub _call {
  my $self = shift; my $name = shift;
  Value::Error("Function '$name' has too many inputs") if scalar(@_) > 1;
  Value::Error("Function '$name' has too few inputs") if scalar(@_) == 0;
  my $c = Value::Complex::promote($_[0]);
  $c->$name;
}

#########################################################################

1;

