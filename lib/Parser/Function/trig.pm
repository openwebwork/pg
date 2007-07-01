#########################################################################
#
#  Implements trigonometric functions
#
package Parser::Function::trig;
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
#  Should make better errors about division by zero and
#  roots of negatives here.
#
sub sin {shift; CORE::sin($_[0])}
sub cos {shift; CORE::cos($_[0])}
sub tan {shift; CORE::sin($_[0])/CORE::cos($_[0])}
sub sec {shift; 1/CORE::cos($_[0])}
sub csc {shift; 1/CORE::sin($_[0])}
sub cot {shift; CORE::cos($_[0])/CORE::sin($_[0])}

sub asin {shift; CORE::atan2($_[0],CORE::sqrt(1-$_[0]*$_[0]))}
sub acos {shift; CORE::atan2(CORE::sqrt(1-$_[0]*$_[0]),$_[0])}
sub atan {shift; CORE::atan2($_[0],1)}
sub asec {(shift)->acos(1/$_[0])}
sub acsc {(shift)->asin(1/$_[0])}
sub acot {shift; CORE::atan2(1,$_[0])}

#########################################################################

1;
