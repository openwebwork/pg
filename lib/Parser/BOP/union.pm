#########################################################################
#
#  Implement the Union operand
#

package Parser::BOP::union;
use strict; use vars qw(@ISA);
@ISA = qw(Parser::BOP);

#
#  Check that the two operands are Intervals, Unions,
#    or points of length two (which can be promoted).
#
sub _check {
  my $self = shift;
  return if ($self->checkStrings());
  if ($self->{lop}->{canBeInterval} && $self->{rop}->{canBeInterval}) {
    $self->{type} = Value::Type('Union',2,$Value::Type{number});
  } else {$self->Error("Operands of '$self->{bop}' must be intervals")}
}


#
#  Make a union of the two operands.
#
sub _eval {shift; Value::Union->new(@_)}

#
#  Make a union of intervals.
#
sub perl {
  my $self = shift; my $parens = shift; my @union = ();
  foreach my $x ($self->makeUnion) {push(@union,$x->perl)}
  my $perl = 'Union('.join(',',@union).')';
  $perl = '('.$perl.')' if $parens;
  return $perl;
}

#
#  Turn a union into a list of the intervals in the union.
#
sub makeUnion {
  my $self = shift;
  return $self unless ($self->{def}{isUnion});
  return ($self->{lop}->makeUnion,$self->{rop}->makeUnion);
}

#########################################################################

1;

