#########################################################################
#
#  Implements the Point class
#
package Parser::List::Point;
use strict;
our @ISA = qw(Parser::List);

#
#  The basic List class does most of the checking.
#

sub _check {
  my $self = shift; return if $self->context->flag("allowBadOperands");
  foreach my $x (@{$self->{coords}}) {
    unless ($x->isNumber) {
      my $type = $x->type;
      $type = (($type =~ m/^[aeiou]/i)? "an ": "a ") . $type;
      $self->{equation}->Error(["Coordinates of Points must be Numbers, not %s",$type]);
    }
  }
}

#########################################################################

1;
