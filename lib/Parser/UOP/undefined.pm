#########################################################################
#
#  Use this for undefined operators in the Context operator list.
#  They will still be recognized by the parser (so you don't get
#  'unexpected character' errors), but get a message that the operation
#  is not defined in this context.
#

package Parser::UOP::undefined;
use strict; use vars qw(@ISA);
@ISA = qw(Parser::UOP);

sub _check {
  my $self = shift;
  $self->Error("Can't use '$self->{op}' in this context");
}

#########################################################################

1;

