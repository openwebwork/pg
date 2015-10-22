#########################################################################
#
#  The comma operator
#
package Parser::BOP::comma;
use strict;
our @ISA = qw(Parser::BOP);

#
#  Start forming a list, and set the list type if
#    the left and right operands are the same type.
#  If the left or right operands are already lists,
#    update the number of items in the new list.
#
sub _check {
  my $self = shift;
  my ($ltype,$rtype) = ($self->{lop}->typeRef,$self->{rop}->typeRef);
  my $type = Value::Type('Comma',2,$Value::Type{unknown});
  if ($ltype->{name} eq 'Comma') {
    $type->{length} += $self->{lop}->length - 1;
    $ltype = $self->{lop}->entryType;
  }
  if ($rtype->{name} eq 'Comma') {
    $type->{length} += $self->{rop}->length - 1;
    $rtype = $self->{rop}->entryType;
  }
  $type->{entryType} = $ltype if (Parser::Item::typeMatch($ltype,$rtype));
  $self->{type} = $type;
}

#
#  evaluate by forming a list
#
sub _eval {($_[1],$_[2])}

#
#  If the operator is listed as a comma, make a list
#    out of the lists that are the left and right operands.
#  Otherwise return the item itself
#
sub makeList {
  my $self = shift;
  return $self unless $self->{def}{isComma};
  return ($self->{lop}->makeList,$self->{rop}->makeList);
}

#########################################################################

1;
