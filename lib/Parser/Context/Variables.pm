#########################################################################
#
#  Implements the list of known variables and their types
#
package Parser::Context::Variables;
use strict;
use vars qw(@ISA %type);
@ISA = qw(Value::Context::Data);

#
#  The named types for variables
#    (you can use arbitary types by supplying an
#     instance of the type rather than a name)
#
%type = (
  'Real'    => $Value::Type{number},
  'Complex' => $Value::Type{complex},
  'Point2D' => Value::Type('Point',2,$Value::Type{number}),
  'Point3D' => Value::Type('Point',3,$Value::Type{number}),
  'Vector2D' => Value::Type('Vector',2,$Value::Type{number}),
  'Vector3D' => Value::Type('Vector',3,$Value::Type{number}),
);

sub init {
  my $self = shift;
  $self->{dataName} = 'variables';
  $self->{name} = 'variable';
  $self->{Name} = 'Variable';
  $self->{namePattern} = '[a-zA-Z]';
  $self->{pattern} = $self->{namePattern};
}

#
#  Our pattern should match ANY variable name
#    (Parser takes care of reporting unknown ones)
# 
sub update {
  my $self = shift;
  $self->{pattern} = $self->{namePattern};
}

#
#  If the type is one of the names ones, use it's known type
#  Otherwise if it is a Value object use its type,
#  Otherwise, if it is a signed number, use the Real type
#  Otherwise report an error
#
sub create {
  my $self = shift; my $value = shift;
  return $value if ref($value) eq 'HASH';
  if (defined($type{$value})) {
    $value = $type{$value};
  } elsif (Value::isValue($value)) {
    $value = $value->typeRef;
  } elsif ($value =~ m/$self->{context}{pattern}{signedNumber}/) {
    $value = $type{'Real'};
  } else {
    Value::Error("Unrecognized variable type '$value'");
  }
  return {type => $value};
}

#
#  Return a variable's type
#
sub type {
  my $self = shift; my $x = shift;
  return $self->{context}{variables}{$x}{type};
}

#########################################################################

1;

