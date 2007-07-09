#########################################################################
#
#  Implement the Union operand
#

package Parser::BOP::union;
use strict;
our @ISA = qw(Parser::BOP);

#
#  Check that the two operands are Intervals, Unions,
#    or points of length two (which can be promoted).
#
sub _check {
  my $self = shift;
  return if ($self->checkStrings());
  if ($self->{lop}->canBeInUnion && $self->{rop}->canBeInUnion) {
    $self->{type} = Value::Type('Union',2,$Value::Type{number});
    foreach my $op ('lop','rop') {
      if (!$self->{$op}->isSetOfReals) {
	if ($self->{$op}->class eq 'Value') {
	  $self->{$op}{value} =
	    $self->Package("Interval")->promote($self->context,$self->{$op}{value});
	} else  {
	  $self->{$op} = bless $self->{$op}, 'Parser::List::Interval';
	}
	$self->{$op}->typeRef->{name} = $self->context->{parens}{interval}{type};
      }
    }
  }
  elsif ($self->context->flag("allowBadOperands")) {$self->{type} = Value::Type("Union",2,$Value::Type{number})}
  else {$self->Error("Operands of '%s' must be intervals or sets",$self->{bop})}
}

sub canBeInUnion {(shift)->type eq 'Union'}


#
#  Make a union of the two operands.
#
sub _eval {$_[1] + $_[2]}

#
#  Make a union of intervals or sets.
#
sub perl {
  my $self = shift; my $parens = shift; my @union = ();
  foreach my $x ($self->makeUnion) {push(@union,$x->perl)}
  my $perl = $self->Package("Union").'->new('.join(',',@union).')';
  $perl = '('.$perl.')' if $parens;
  return $perl;
}

#
#  Turn a union into a list of the intervals or sets in the union.
#
sub makeUnion {
  my $self = shift;
  return (
    $self->{lop}{def}{isUnion}? $self->{lop}->makeUnion : $self->{lop},
    $self->{rop}{def}{isUnion}? $self->{rop}->makeUnion : $self->{rop},
  );
}

#########################################################################

1;
