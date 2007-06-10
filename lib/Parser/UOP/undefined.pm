#########################################################################
#
#  Use this for undefined operators in the Context operator list.
#  They will still be recognized by the parser (so you don't get
#  'unexpected character' errors), but get a message that the operation
#  is not defined in this context.
#

package Parser::UOP::undefined;
use strict;
our @ISA = qw(Parser::UOP);

sub _check {
  my $self = shift;
  my $uop = $self->{def}{string} || $self->{uop};
  $self->Error("Can't use '%s' in this context",$uop);
}

#########################################################################

1;
