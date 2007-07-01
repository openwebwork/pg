#########################################################################
#
#  Implements hyperbolic functions
#
package Parser::Function::hyperbolic;
use strict;
our @ISA = qw(Parser::Function);

#
#  Check that the argument is numeric (complex or real)
#
sub _check {(shift)->checkNumeric(@_)}

#
#  For complex arguments, call the complex version,
#  Otherwise call the version below.
#
sub _eval {
  my $self = shift; my $name = $self->{name};
  return $_[0]->$name if Value::isComplex($_[0]);
  $self->$name(@_);
}

#
#  Check the arguments and return the (real or complex) result.
#
sub _call {
  my $self = shift; my $name = shift;
  Value::Error("Function '%s' has too many inputs",$name) if scalar(@_) > 1;
  Value::Error("Function '%s' has too few inputs",$name) if scalar(@_) == 0;
  my $n = $_[0];
  return $self->$name($n) if Value::matchNumber($n);
  my $context = (Value::isValue($n) ? $n : $self)->context;
  $self->Package("Complex")->promote($context,$n)->$name;
}

#
#  Should make better errors about division by zero,
#  roots of negatives here, and undefined logs.
#
sub sinh {shift; (CORE::exp($_[0]) - CORE::exp(-$_[0]))/2}
sub cosh {shift; (CORE::exp($_[0]) + CORE::exp(-$_[0]))/2}
sub tanh {shift; (CORE::exp($_[0]) - CORE::exp(-$_[0]))/(CORE::exp($_[0]) + CORE::exp(-$_[0]))}
sub sech {shift; 2/(CORE::exp($_[0]) + CORE::exp(-$_[0]))}
sub csch {shift; 2/(CORE::exp($_[0]) - CORE::exp(-$_[0]))}
sub coth {shift; (CORE::exp($_[0]) + CORE::exp(-$_[0]))/(CORE::exp($_[0]) - CORE::exp(-$_[0]))}

sub asinh {shift; CORE::log($_[0]+CORE::sqrt($_[0]*$_[0]+1))}
sub acosh {shift; CORE::log($_[0]+CORE::sqrt($_[0]*$_[0]-1))}
sub atanh {shift; CORE::log((1+$_[0])/(1-$_[0]))/2}
sub asech {shift; CORE::log((1+CORE::sqrt(1-$_[0]*$_[0]))/$_[0])}
sub acsch {shift; CORE::log((1+CORE::sqrt(1+$_[0]*$_[0]))/$_[0])}
sub acoth {shift; CORE::log(($_[0]+1)/($_[0]-1))/2}

#########################################################################

1;
