#########################################################################
#
#  Implements subtraction
#
package Parser::BOP::subtract;
use strict;
our @ISA = qw(Parser::BOP);

#
#  Check that the operand types match.
#
sub _check {
  my $self = shift;
  return if ($self->checkStrings());
  return if ($self->checkLists());
  return if ($self->checkNumbers());
  if ($self->{lop}->canBeInUnion && $self->{rop}->canBeInUnion) {
    if ($self->{lop}->isSetOfReals || $self->{rop}->isSetOfReals) {
      $self->{type} = Value::Type('Union',2,$Value::Type{number});
      foreach my $op ('lop','rop') {
	if (!$self->{$op}->isSetOfReals) {
	  if ($self->{$op}->class eq 'Value') {
	    $self->{$op}{value} =
	      $self->Package("Interval")->promote($self->context,$self->{$op}{value});
	  } else {
	    $self->{$op} = bless $self->{$op}, 'Parser::List::Interval';
	  }
	  $self->{$op}->typeRef->{name} = $self->context->{parens}{interval}{type};
	}
      }
    }
    return;
  }
  my ($ltype,$rtype) = $self->promotePoints();
  if (Parser::Item::typeMatch($ltype,$rtype)) {$self->{type} = $ltype}
  else {$self->matchError($ltype,$rtype)}
}

sub canBeInUnion {(shift)->type eq 'Union'}

#
#  Do subtraction
#
sub _eval {$_[1] - $_[2]}

#
#  Remove subtracting zero
#  Turn subtraction from zero into negation.
#  Turn subtracting a negative into addition.
#  Factor out common negatives.
#
sub _reduce {
  my $self = shift; my $equation = $self->{equation};
  my $reduce = $equation->{context}{reduction};
  return $self->{lop} if $self->{rop}{isZero} && $reduce->{'x-0'};
  return Parser::UOP::Neg($self->{rop}) if $self->{lop}{isZero} && $reduce->{'0-x'};
  if ($self->{rop}->isNeg && $reduce->{'x-(-y)'}) {
    $self = $self->Item("BOP")->new($equation,'+',$self->{lop},$self->{rop}{op});
    $self = $self->reduce;
  } elsif ($self->{lop}->isNeg && $reduce->{'(-x)-y'}) {
    $self = Parser::UOP::Neg
      ($self->Item("BOP")->new($equation,'+',$self->{lop}{op},$self->{rop}));
    $self = $self->reduce;
  }
  return $self;
}

$Parser::reduce->{'x-0'} = 1;
$Parser::reduce->{'0-x'} = 1;
$Parser::reduce->{'x-(-y)'} = 1;
$Parser::reduce->{'(-x)-y'} = 1;

#########################################################################

1;
