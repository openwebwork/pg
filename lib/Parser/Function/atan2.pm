#########################################################################
#
#  Implement atan2 as special function
#
#
package Parser::Function::atan2;
use strict; use vars qw(@ISA);
@ISA = qw(Parser::Function);

#
#  Check for two real-valued arguments
#  
sub _check {
  my $self = shift;
  return if ($self->checkArgCount(2));
  if ($self->{params}->[0]->isNumber && $self->{params}->[1]->isNumber &&
      !$self->{params}->[0]->isComplex && !$self->{params}->[1]->isComplex) {
    $self->{type} = $Value::Type{number};
  } else {$self->Error("Function 'atan2' has the wrong type of inputs",$self->{ref})}
}

#
#  
sub _call {
  my $self = shift; my $name = shift;
  die "Function '$name' has too many inputs" if scalar(@_) > 2;
  die "Function '$name' has too few inputs" if scalar(@_) < 2;
  die "Function '$name' has the wrong type of inputs"
    unless Value::matchNumber($_[0]) && Value::matchNumber($_[1]);
  return $self->_eval(@_);
}

#
#  Just do core atan2() call.
#
sub _eval {shift; CORE::atan2($_[0],$_[1])}

#########################################################################

1;

