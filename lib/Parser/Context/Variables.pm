#########################################################################
#
#  Implements the list of known variables and their types
#
package Parser::Context::Variables;
use strict;
use vars qw(@ISA %type);
@ISA = qw(Parser::Context::Data);

#
#  The types that variables can be
#  @@@ Should also include domain ranges for when
#      we use these in answer checkers @@@
#
%type = (
  'Real'    => $Value::Type{number},
  'Complex' => $Value::Type{complex},
);

sub init {
  my $self = shift;
  $self->{dataName} = 'variables';
  $self->{name} = 'variable';
  $self->{Name} = 'Variable';
  $self->{namePattern} = '[a-zA-Z]';
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

