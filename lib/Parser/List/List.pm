#########################################################################
#
#  Implements the List class
#
package Parser::List::List;
use strict;
our @ISA = qw(Parser::List);

#
#  The basic List class does it all.  We only need this class
#  for its name.
#

#
#  Produce a string version with extra space
#
sub string {
  my $self = shift; my $precedence = shift; my @coords = ();
  my $def = $self->context->{lists}{$self->type};
  my $separator = $def->{separator}; $separator = ", " unless defined $separator;
  foreach my $x (@{$self->{coords}}) {push(@coords,$x->string)}
  return $self->{open}.join($separator,@coords).$self->{close};
}

#########################################################################

1;
