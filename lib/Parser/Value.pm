#########################################################################
#
#  Class that allows Value.pm objects to be included in formulas
#    (used to store constant Vector values, etc.)
#
package Parser::Value;
use strict; use vars qw(@ISA);
@ISA = qw(Parser::Item);

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
  my $equation = shift; my $parser = $equation->{context}{parser};
  my ($value,$ref) = @_;
  $value = $value->[0] if ref($value) eq 'ARRAY' && scalar(@{$value}) == 1;
  my $type = Value::getType($equation,$value);
  return $value->{tree}->copy($equation) if ($type eq 'Formula');
  return $parser->{String}->new($equation,$value,$ref) if ($type eq 'String');
  return $parser->{String}->newInfinity($equation,$value,$ref) if ($type eq 'Infinity');
  return $parser->{Number}->new($equation,$value,$ref) if ($type eq 'Number');
  return $parser->{Number}->new($equation,$value->{data},$ref) 
    if ($type eq 'value' && $value->class eq 'Complex');
  $equation->Error("Can't convert ".Value::showClass($value)." to a constant",$ref)
    if ($type eq 'unknown');
  $type = 'Value::'.$type, $value = $type->new(@{$value}) unless $type eq 'value';
  my $type = $value->typeRef;
  my $c = bless {
    value => $value, type => $type, isConstant => 1,
    ref => $ref, equation => $equation,
  }, $class;
  $c->{canBeInterval} = 1 if ($value->class eq 'Point' && $type->{length} == 2);
  ## check for isZero  (method of $value?)
  ## (hack for now)
  $c->{isZero} = 1 if $type->{name} eq 'Number' && $value == 0;
  $c->{isOne}  = 1 if $type->{name} eq 'Number' && $value eq 1;
  return $c;
}

#
#  Return the Value.pm object
#
sub eval {return (shift)->{value}}

#
#  Return the item's list of coordinates
#    (for points, vectors, matrices, etc.)
#
sub coords {
  my $self = shift;
  return [$self->{value}] unless $self->typeRef->{list};
  my @coords = (); my $equation = $self->{equation};
  foreach my $x (@{$self->{value}->data})
    {push(@coords,$equation->{context}{parser}{Value}->new($equation,[$x]))}
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
  $perl = 'Closed('.$perl.')'
    if $self->{canBeInterval} && $self->{open}.$self->{close} eq '[]';
  $perl = '('.$perl.')' if $parens;
  return $perl;
}

sub ijk {(shift)->{value}->ijk}

#
#  Convert the value to a Matrix object
#
sub makeMatrix {
  my $self = shift;
  my ($name,$open,$close) = @_;
  $self->{type}{name} = $name;
  $self->{value} = Value::Matrix->new($self->{value}->value);
}

#
#  Get a Union object's data
#
sub makeUnion {@{shift->{value}->{data}}}

#########################################################################

1;

