#########################################################################
#
#  Implement functions having two real inputs
#
package Parser::Function::numeric2;
use strict;
our @ISA = qw(Parser::Function);

#
#  Check for two real-valued arguments
#
sub _check {
  my $self = shift;
  return if ($self->checkArgCount(2));
  if (($self->{params}->[0]->isNumber && $self->{params}->[1]->isNumber &&
      !$self->{params}->[0]->isComplex && !$self->{params}->[1]->isComplex) ||
      $self->context->flag("allowBadFunctionInputs")) {
    $self->{type} = $Value::Type{number};
  } else {
    $self->Error("Function '%s' has the wrong type of inputs",$self->{name});
  }
}

#
#  Check that the inputs are OK
#
sub _call {
  my $self = shift; my $name = shift;
  Value::Error("Function '%s' has too many inputs",$name) if scalar(@_) > 2;
  Value::Error("Function '%s' has too few inputs",$name) if scalar(@_) < 2;
  Value::Error("Function '%s' has the wrong type of inputs",$name)
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
