#########################################################################
#
#  Implement functions having two real inputs
#
package Parser::Function::numeric2;
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
  } else {
    $self->Error("Function '$self->{name}' has the wrong type of inputs");
  }
}

#
#  Check that the inputs are OK
#
sub _call {
  my $self = shift; my $name = shift;
  Value::Error("Function '$name' has too many inputs") if scalar(@_) > 2;
  Value::Error("Function '$name' has too few inputs") if scalar(@_) < 2;
  Value::Error("Function '$name' has the wrong type of inputs")
    unless Value::matchNumber($_[0]) && Value::matchNumber($_[1]);
  return $self->$name(@_);
}

#
#  Call the appropriate routine
#
sub _eval {
  my $self = shift; my $name = $self->{name};
  $self->$name(@_);
}

#
#  Do the core atan2 call
#
sub atan2 {shift; CORE::atan2($_[0],$_[1])}

#########################################################################

1;

