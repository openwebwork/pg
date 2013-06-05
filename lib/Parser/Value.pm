#########################################################################
#
#  Class that allows Value.pm objects to be included in formulas
#    (used to store constant Vector values, etc.)
#
package Parser::Value;
use strict; no strict "refs";
our @ISA = qw(Parser::Item);

$Parser::class->{Value} = 'Parser::Value';

#
#  Get the Value.pm type of the constant
#  Return it if it is an equation
#  Make a new string or number if it is one of those
#  Error if we don't know what it is
#  Otherwise, get a Value object for the item and use it.
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $equation = shift; my $context = $equation->{context};
  my ($value,$ref) = @_;
  $value = $value->[0] if ref($value) eq 'ARRAY' && scalar(@{$value}) == 1;
  my $type = Value::getType($equation,$value);
  return $value->{tree}->copy($equation) if ($type eq 'Formula');
  return $self->Item("String",$context)->new($equation,$value,$ref) if ($type eq 'String');
  return $self->Item("String",$context)->newInfinity($equation,$value,$ref) if ($type eq 'Infinity');
  return $self->Item("Number",$context)->new($equation,$value,$ref) if ($type eq 'Number');
  return $self->Item("Number",$context)->new($equation,$value->{data},$ref)
    if ($type eq 'value' && $value->class eq 'Complex');
  $equation->Error(["Can't convert %s to a constant",Value::showClass($value)],$ref)
    if ($type eq 'unknown');
  $type = $context->Package($type), $value = $type->new($context,@{$value}) unless $type eq 'value';
  $type = $value->typeRef;

  $value->inContext($context);  # force context to be the equation's context
  my $c = bless {
    value => $value, type => $type, isConstant => 1,
    ref => $ref, equation => $equation,
  }, $class;
  $c->weaken;
  $c->check;
  return $c;
}

#
#  Set flags for the object
#
sub check {
  my $self = shift; my $value = $self->{value};
  $self->{isZero} = $value->isZero;
  $self->{isOne}  = $value->isOne;
}

#
#  Return the Value object
#
sub eval {(shift)->{value}}

#
#  Call the Value object's reduce method and reset the flags
#
sub reduce {
  my $self = shift;
  $self->{value} = $self->{value}->reduce;
  $self->check;
  return $self;
}

#
#  Pass on the request to the Value object
#
sub canBeInUnion {(shift)->{value}->canBeInUnion}

#
#  Return the item's list of coordinates
#    (for points, vectors, matrices, etc.)
#
sub coords {
  my $self = shift;
  return [$self->{value}] unless $self->typeRef->{list};
  my @coords = (); my $equation = $self->{equation};
  my $value = $self->Item("Value");
  foreach my $x (@{$self->{value}->data}) {push(@coords,$value->new($equation,[$x]))}
  return [@coords];
}

#
#  Call the appropriate formatter from Value.pm
#
sub string {
  my $self = shift; my $precedence = shift;
  my $string = $self->{value}->string($self->{equation},$self->{open},$self->{close},$precedence);
  return $string;
}
sub TeX {
  my $self = shift; my $precedence = shift;
  my $TeX = $self->{value}->TeX($self->{equation},$self->{open},$self->{close},$precedence);
  return $TeX;
}
sub perl {
  my $self = shift; my $parens = shift; my $matrix = shift;
  my $perl = $self->{value}->perl(0,$matrix);
  $perl = '('.$perl.')' if $parens;
  return $perl;
}

sub ijk {(shift)->{value}->ijk}

#
#  Convert the value to a Matrix object
#
sub makeMatrix {
  my $self = shift; my $context = $self->context;
  my ($name,$open,$close) = @_;
  $self->{type}{name} = $name;
  $self->{value} = $self->Package("Matrix",$context)->new($context,$self->{value}->value);
}

#
#  Get a Union object's data
#
sub makeUnion {@{shift->{value}{data}}}

#########################################################################

1;
