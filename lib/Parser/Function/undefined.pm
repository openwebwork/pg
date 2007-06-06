#########################################################################
#
#  Use this for undefined functions in the Context function list.
#  They will still be recognized by the parser (so you don't get
#  'undefined variable' errors), but get a message that the function
#  is not defined in this context.
#

package Parser::Function::undefined;
use strict;
our @ISA = qw(Parser::Function);

sub _check {
  my $self = shift;
  $self->Error("Function '%s' is not allowed in this context",$self->{name});
}

sub _call {
  my $self = shift; my $name = shift;
  Value::Error("Function '%s' is not allowed in this context",$name);
}

#########################################################################

1;
