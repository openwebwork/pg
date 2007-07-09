#########################################################################
#
#  Implements the Absolute Value class
#    (it works like a list, since it has "parens" at both ends)
#
package Parser::List::AbsoluteValue;
use strict;
our @ISA = qw(Parser::List);

#
#  Check that only one number is inside the |...|
#
sub _check {
  my $self = shift;
  $self->{type}{list} = 0;
  $self->Error("Only one value allowed within absolute values")
    if ($self->{type}{length} != 1);
  my $arg = $self->{coords}[0];
  $self->Error("Absolute value can't be taken of %s",$arg->type)
    unless $arg->type =~ /Number|Point|Vector/ || $self->context->flag("allowBadOperands");
  $self->{type} = $Value::Type{number};
}

sub class {'AbsoluteValue'}; # don't report List

#
#  Compute using abs()
#
sub _eval {abs($_[1][0])}

#
#  Use abs() in perl mode
#
sub perl {
  my $self = shift; my $parens = shift;
  my $perl = 'abs('.$self->{coords}[0]->perl.')';
  $perl = '('.$perl.')' if $parens;
  return $perl;
}

#########################################################################

1;
