#########################################################################
#
#  Implements equality
#
package Parser::BOP::equality;
use strict;
our @ISA = qw(Parser::BOP);

#
#  Check that the operand types are numbers.
#
sub _check {
  my $self = shift; my $name = $self->{def}{string} || $self->{bop};
  $self->Error("Only one equality is allowed in an equation")
    if ($self->{lop}->type eq 'Equality' || $self->{rop}->type eq 'Equality');
  $self->Error("Operands of '%s' must be Numbers",$name)
    unless $self->checkNumbers() || $self->context->flag("allowBadOperands");
  $self->{type} = Value::Type('Equality',1); # Make it not a number, to get errors with other operations.
}

#
#  Determine if the two sides are equal (use fuzzy reals)
#
sub _eval {
  my $self = shift; my %context = (context => $self->context);
  my ($a,$b) = @_;
  $a = Value::makeValue($a,%context) unless ref($a);
  $b = Value::makeValue($b,%context) unless ref($b);
  return ($a == $b)? 1 : 0;
}

#
#  Remove redundent minuses
#
sub _reduce {
  my $self = shift;
  my $equation = $self->{equation};
  my $reduce = $equation->{context}{reduction};
  if ($self->{lop}->isNeg && $self->{rop}->isNeg && $reduce->{'-x=-y'}) {
    $self = $self->Item("BOP")->new($equation,'=',$self->{lop}{op},$self->{rop}{op});
    $self = $self->reduce;
  }
  if ($self->{lop}->isNeg && $self->{rop}{isConstant} &&
      $self->{rop}->isNumber && $reduce->{'-x=n'}) {
    $self = $self->Item("BOP")->new($equation,"=",$self->{lop}{op},Parser::UOP::Neg($self->{rop}));
    $self = $self->reduce;
  }
  return $self;
}

$Parser::reduce->{'-x=-y'} = 1;
$Parser::reduce->{'-x=n'} = 1;

#
#  Don't add parens to the left and right parts
#
sub string {
  my ($self,$precedence,$showparens,$position,$outerRight) = @_;
  my $string; my $bop = $self->{def};
  $position = '' unless defined($position);
  $showparens = '' unless defined($showparens);
  my $extraParens = $self->context->flag('showExtraParens');
  my $addparens =
      defined($precedence) &&
      ($precedence > $bop->{precedence} || ($precedence == $bop->{precedence} &&
        ($bop->{associativity} eq 'right' || $showparens eq 'same')));
  $outerRight = !$addparens && ($outerRight || $position eq 'right');

  $string = $self->{lop}->string($bop->{precedence}).
            $bop->{string}.
            $self->{rop}->string($bop->{precedence});

  $string = $self->addParens($string) if $addparens;
  return $string;
}

sub TeX {
  my ($self,$precedence,$showparens,$position,$outerRight) = @_;
  my $TeX; my $bop = $self->{def};
  $position = '' unless defined($position);
  $showparens = '' unless defined($showparens);
  my $extraParens = $self->context->flag('showExtraParens');
  my $addparens =
      defined($precedence) &&
      ($precedence > $bop->{precedence} || ($precedence == $bop->{precedence} &&
        ($bop->{associativity} eq 'right' || $showparens eq 'same')));
  $outerRight = !$addparens && ($outerRight || $position eq 'right');

  $TeX = $self->{lop}->TeX($bop->{precedence}).
         (defined($bop->{TeX}) ? $bop->{TeX} : $bop->{string}) .
         $self->{rop}->TeX($bop->{precedence});

  $TeX = '\left('.$TeX.'\right)' if $addparens;
  return $TeX;
}

sub perl {
  my $self= shift;
  my $bop = $self->{def};
  return
     "(" .
       $self->{lop}->perl(1).
       " ".($bop->{perl} || $bop->{string})." ".
       $self->{rop}->perl(2) .
     " ? 1 : 0)";
}


#
#  Add/Remove the equality operator to/from a context
#
sub Allow {
  my $self = shift || "Value"; my $context = shift || $self->context;
  my $allow = shift; $allow = 1 unless defined($allow);
  if ($allow) {
    my $prec = $context->{operators}{','}{precedence};
    $prec = 1 unless defined($prec);
    $context->operators->add(
      '=' => {
         class => 'Parser::BOP::equality',
         precedence => $prec+.25,  #  just above comma
         associativity => 'left',  #  computed left to right
         type => 'bin',            #  binary operator
         string => ' = ',          #  output string for it
         perl => '==',             #  perl string
      }
    );
  } else {$context->operators->remove('=')}
  return;
}

#########################################################################

1;
