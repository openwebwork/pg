#########################################################################
#
#  Implements equality
#
package Parser::BOP::equality;
use strict; use vars qw(@ISA);
@ISA = qw(Parser::BOP);

#
#  Check that the operand types are numbers.
#
sub _check {
  my $self = shift; my $name = $self->{def}{string} || $self->{bop};
  $self->Error("Only one equality is allowed in an equation")
    if ($self->{lop}->type eq 'Equality' || $self->{rop}->type eq 'Equality');
  $self->Error("Operands of '$name' must be Numbers") unless $self->checkNumbers();
  $self->{type} = Value::Type('Equality',1); # Make it not a number, to get errors with other operations.
}

#
#  Determine if the two sides are equal (use fuzzy reals)
#
sub _eval {
  my $self = shift; my ($a,$b) = @_;
  $a = Value::makeValue($a) unless ref($a);
  $b = Value::makeValue($b) unless ref($b);
  $a == $b;
}

#
#  Add/Remove the equality operator to/from a context
#
sub Allow {
  my $self = shift; my $context = shift || $$Value::context;
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
         string => '=',            #  output string for it
         perl => '==',             #  perl string
      }
    );
  } else {$context->operators->remove('=')}
  return;
}

#########################################################################

1;
