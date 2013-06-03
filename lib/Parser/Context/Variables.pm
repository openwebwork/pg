#########################################################################
#
#  Implements the list of known variables and their types
#
package Parser::Context::Variables;
use strict;
our @ISA = qw(Value::Context::Data);

#
#  The named types for variables
#    (you can use arbitary types by supplying an
#     instance of the type rather than a name)
#
our %type = (
  'Real'    => $Value::Type{number},
  'Complex' => $Value::Type{complex},
  'Point2D' => Value::Type('Point',2,$Value::Type{number}),
  'Point3D' => Value::Type('Point',3,$Value::Type{number}),
  'Vector2D' => Value::Type('Vector',2,$Value::Type{number}),
  'Vector3D' => Value::Type('Vector',3,$Value::Type{number}),
  'Parameter' => $Value::Type{number},
);

sub init {
  my $self = shift;
  $self->{dataName} = 'variables';
  $self->{name} = 'variable';
  $self->{Name} = 'Variable';
  $self->{namePattern} = qr/[a-zA-Z][a-zA-Z0-9]*/;
  $self->{tokenType} = 'var';
  $self->{precedence} = 5;
  $self->{patterns}{$self->{namePattern}} = [$self->{precedence},$self->{tokenType}];
}

#sub addToken {}    # no tokens needed
#sub removeToken {}

#
#  If the type is one of the named ones, use it's known type
#  Otherwise if it is a Value object use its type,
#  Otherwise, if it is a signed number, use the Real type
#  Otherwise report an error
#
sub create {
  my $self = shift; my $value = shift; my @extra;
  return $value if ref($value) eq 'HASH';
  ($value,@extra) = @{$value} if ref($value) eq 'ARRAY';
  if (defined($type{$value})) {
    push(@extra,(parameter => 1)) if $value eq 'Parameter';
    $value = $type{$value};
  } elsif (Value::isValue($value)) {
    $value = $value->typeRef;
  } elsif ($value =~ m/$self->{context}{pattern}{signedNumber}/) {
    $value = $type{'Real'};
  } else {
    Value::Error("Unrecognized variable type '%s'",$value);
  }
  return {type => $value, @extra};
}
sub uncreate {shift; (shift)->{type}};

#
#  Return a variable's type
#
sub type {
  my $self = shift; my $x = shift;
  return $self->{context}{variables}{$x}{type};
}

#
#  Return a parameter's value
#
sub value {
  my $self = shift; my $x = shift;
  return $self->{context}{variables}{$x}{value};
}

#
#  Get the names of all variables
#
sub variables {
  my $self = shift; my @names;
  foreach my $x ($self->SUPER::names)
    {push(@names,$x) unless $self->{context}{variables}{$x}{parameter}}
  return @names;
}

#
#  Get the names of all parameters
#
sub parameters {
  my $self = shift; my @names;
  foreach my $x ($self->SUPER::names)
    {push(@names,$x) if $self->{context}{variables}{$x}{parameter}}
  return @names;
}

#########################################################################

1;
