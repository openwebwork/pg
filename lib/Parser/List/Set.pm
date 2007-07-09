#########################################################################
#
#  Implements the Set class
#
package Parser::List::Set;
use strict;
our @ISA = qw(Parser::List);

#
#  Check that the entries are numbers.
#
sub _check {
  my $self = shift; return if $self->context->flag("allowBadOperands");
  foreach my $x (@{$self->{coords}}) {
    $self->Error("Sets can't contain infinity") if $x->{isInfinite};
    $self->Error("Entries in a set must be real numbers") unless $x->isRealNumber;
  }
}

sub canBeInUnion {1}

#########################################################################

1;
