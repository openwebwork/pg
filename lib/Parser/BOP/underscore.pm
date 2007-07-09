#########################################################################
#
#  Implement vector and matrix element extraction.
#
package Parser::BOP::underscore;
use strict;
our @ISA = qw(Parser::BOP);

#
#  Check that the operand types are OK
#
sub _check {
  my $self = shift;
  return if ($self->checkStrings());
  my ($ltype,$rtype) = $self->promotePoints();
  if ($ltype->{name} =~ m/Vector|Matrix|List/) {
    if ($rtype->{name} =~ m/Number|Vector/ ||
	($rtype->{name} eq 'List' && $rtype->{entryType}{name} eq 'Number')) {
      $self->{type} = {%{$ltype}};
      $self->{type}{length} = $rtype->{length};
    } elsif ($self->context->flag("allowBadOperands")) {$self->{type} = $Value::Type{number}}
    else {$self->Error("Right-hand operand of '_' must be a Number or List of numbers")}
  } elsif ($self->context->flag("allowBadOperands")) {$self->{type} = $Value::Type{number}}
  else {$self->Error("Entries can be extracted only from Vectors, Matrices, or Lists")}
}

#
#  Perform the extraction.
#
sub _eval {
  my $self = shift; my $M = shift; my $i = shift;
  $i = $i->data if Value::isValue($i);
  $i = [$i] unless ref($i) eq 'ARRAY';
  my $n = $M->extract(@{$i});
  return $n if ref($n);
  return $self->Package("List")->new($self->context) if $n eq '';
  return $n;
}

#
#  If the right-hand side is constant and the left is a list
#    extact the given coordinate(s).  Return empty lists
#    if we run past the end of the coordinates.  Return
#    a simpler extraction if a portion of the extraction
#    can be performed.
#
sub _reduce {
  my $self = shift; my $equation = $self->{equation};
  my $context = $self->context;
  my $reduce = $context->{reduction};
  return $self unless $self->{rop}->{isConstant} && $self->{lop}{coords} && $reduce->{'V_n'};
  my $index = $self->{rop}->eval; my $M = $self->{lop};
  $index = $index->data if Value::isValue($index);
  $index = [$index] unless ref($index) eq 'ARRAY';
  my @index = @{$index};
  while (scalar(@index) > 0) {
    unless ($M->{coords}) {
      return $self->Item("Value")->new($equation,$self->Package("List")->new($context))
        unless $M->type =~ m/Point|Vector|Matrix|List/;
      return $self->Item("BOP")->new($equation,$self->{bop},
          $M,$self->Item("Value")->new($equation,@index))
    }
    my $i = shift(@index); $i-- if $i > 0;
    $self->Error("Can't extract element number '%s' (index must be an integer)",$i)
      unless $i =~ m/^-?\d+$/;
    $M = $M->{coords}[$i];
    return $self->Item("Value")->new($equation,$self->Package("List")->new($context)) unless $M;
  }
  return $M;
}

$Parser::reduce->{'V_n'} = 1;

#
#  Brace the index for TeX.  (Not really good for multiple indices.)
#
sub TeX {
  my ($self,$precedence,$showparens,$position,$outerRight) = @_;
  my $TeX; my $bop = $self->{def};
  $position = '' unless defined($position);
  $showparens = '' unless defined($showparens);
  my $addparens =
      defined($precedence) &&
      ($showparens eq 'all' || $precedence > $bop->{precedence} ||
      ($precedence == $bop->{precedence} &&
        ($bop->{associativity} eq 'right' || $showparens eq 'same')));
  $outerRight = !$addparens && ($outerRight || $position eq 'right');

  my $symbol = (defined($bop->{TeX}) ? $bop->{TeX} : $bop->{string});
  $TeX = $self->{lop}->TeX($bop->{precedence},$bop->{leftparens},'left',$outerRight).
    $symbol.'{'.$self->{rop}->TeX.'}';

  $TeX = '\left('.$TeX.'\right)' if $addparens;
  return $TeX;
}

#
#  Perl used extract method of the Value::List object.
#
sub perl {
  my ($self,$precedence,$showparens,$position) = @_;
  my $bop = $self->{def};
  $self->{lop}->perl($bop->{precedence},$bop->{leftparens},'left').
    '->extract('.$self->{rop}->perl.')';
}

#########################################################################

1;
