#########################################################################
#
#  Implements functions that require complex inputs
#
package Parser::Function::complex;
use strict;
our @ISA = qw(Parser::Function);

#
#  Check that the argument is complex, and
#    mark the result as real or complex, as appropriate.
#
sub _check {
  my $self = shift;
  return $self->checkComplexOrMatrix(@_) if $self->{def}{matrix};
  return $self->checkComplex(@_) if $self->{def}{complex};
  return $self->checkReal(@_);
}

#
#  Evaluate by calling the appropriate routine from Value.pm.
#
sub _eval {
  my $self = shift; my $name = $self->{name};
  my $c = shift; my $context = (Value::isValue($c) ? $c : $self)->context;
  my $type = ($self->type eq "Matrix" ? "Matrix" : "Complex");
  $self->Package($type)->promote($context,$c)->$name;
}

#
#  Check for the right number of arguments.
#  Convert argument to a complex (does error checking)
#    and then call the appropriate routine from Value.pm.
#
sub _call {
  my $self = shift; my $name = shift;
  Value::Error("Function '%s' has too many inputs",$name) if scalar(@_) > 1;
  Value::Error("Function '%s' has too few inputs",$name) if scalar(@_) == 0;
  my $c = shift; my $context = (Value::isValue($c) ? $c : $self)->context;
  my $type = ($c->type eq "Matrix" ? "Matrix" : "Complex");
  $self->Package($type)->promote($context,$c)->$name;
}

##################################################
#
#  Special versions of sqrt, log and ^ that are used
#  in the Complex context.
#

#
#  Subclass of numeric functions that promote negative reals
#  to complex before performing the function (so that sqrt(-2)
#  is defined, for example).
#
package Parser::Function::complex_numeric;
use strict;
our @ISA = qw(Parser::Function::numeric);

sub sqrt {
  my $self = shift; my $context = $self->context;
  my $x = Value::makeValue(shift,context=>$context);
  $x = $self->Package("Complex")->promote($context,$x)
    if $x->value < 0 && $self->{def}{negativeIsComplex};
  $x->sqrt;
}

sub log {
  my $self = shift; my $context = $self->context;
  my $x = Value::makeValue(shift,$context);
  $x = $self->Package("Complex")->promote($context,$x)
    if $x->value < 0 && $self->{def}{negativeIsComplex};
  $x->log;
}

#
#  Special power operator that promotes negative real
#  bases to complex numbers before taking power (so that
#  (-3)^(1/2) is defined, for example).
#
package Parser::Function::complex_power;
use strict;
our @ISA = qw(Parser::BOP::power Parser::BOP);

sub _eval {
  my $self = shift; my $context = $self->context;
  my $a = Value::makeValue(shift,context=>$context); my $b = shift;
  $a = $self->Package("Complex")->promote($context,$a)
    if Value::isReal($a) && $a->value < 0 && $self->{def}{negativeIsComplex};
  return $a ** $b;
}


#########################################################################

1;
