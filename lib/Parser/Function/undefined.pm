#########################################################################
#
#  Use this for undefined functions in the Context function list.
#  They will still be recognized by the parser (so you don't get
#  'undefined variable' errors), but get a message that the function
#  is not defined in this context.
#

package Parser::Function::undefined;
use strict; use vars qw(@ISA);
@ISA = qw(Parser::Function);

sub _check {
  my $self = shift;
  $self->Error("Function '$self->{name}' is not defined in this context");
}

#########################################################################

1;
