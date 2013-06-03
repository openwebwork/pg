#########################################################################
#
#  Implements the basic parse tree node.  Subclasses of this class
#  are things like binary operator, function call, and so on.
#
package Parser::Item;
use strict; no strict "refs";
use UNIVERSAL;
use Scalar::Util;

#
#  Make these available to Parser items
#
sub isa {UNIVERSAL::isa(@_)}
sub can {UNIVERSAL::can(@_)}

sub weaken {Scalar::Util::weaken((shift)->{equation})}

#
#  Return the class name of an item
#
sub class {
  my @parts = split(/::/,ref(shift));
  return $parts[(scalar(@parts) > 2 ? -2 : -1)];
}

#
#  Get the equation context
#
sub context {
  my $self = shift;
  return (ref($self) ? $self->{equation}{context} : Value->context);
}

#
#  Get the package for a given Parser class
#
sub Item {
  my $self = shift; my $class = shift;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  return $context->{parser}{$class} if defined $context->{parser}{$class};
  return "Parser::$class" if @{"Parser::${class}::ISA"};
  Value::Error("No such package 'Parser::%s'",$class);
}

#
#  Same but for Value classes
#
sub Package {
  my $self = shift; my $class = shift;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  $context->Package($class);
}

#
#  Get various type information
#
sub type {my $self = shift; return $self->{type}{name}}
sub typeRef {my $self = shift; return $self->{type}}
sub length {my $self = shift; return $self->{type}{length}}
sub entryType {
  my $self = shift; my $type = $self->{type};
  return $type->{list} ? $type->{entryType}: $type;
}

#
#  True if two types agree
#
sub typeMatch {
  my ($ltype,$rtype) = @_;
  return 0 if ($ltype->{name} ne $rtype->{name});
  return 1 if (!$ltype->{list} && !$rtype->{list});
  return 0 if ($ltype->{list} != $rtype->{list});
  return 0 if ($ltype->{length} ne $rtype->{length});
  return typeMatch($ltype->{entryType},$rtype->{entryType});
}

#
#  Check if an item is a number, complex, etc.
#
sub isRealNumber {my $self = shift; return $self->isNumber && !$self->isComplex}
sub isNumber {my $self = shift; return ($self->typeRef->{name} eq 'Number')}
sub isComplex {
  my $self = shift; my $type = $self->typeRef;
  return ($type->{name} eq 'Number' && $type->{length} == 2);
}
sub isNumOrInfinity {
  my $self = shift;
  return ($self->isRealNumber || $self->{isInfinite});
}

#
#  Check if an item is a unary negation
#
sub isNeg {
  my $self = shift;
  return ($self->class eq 'UOP' && $self->{uop} eq 'u-' && !$self->{op}->{isInfinite});
}

#
#  Check if an item can be in a union or is a set or reals
#    (overridden in subclasses)
#
sub canBeInUnion {0}
sub isSetOfReals {(shift)->type =~ m/^(Interval|Union|Set)$/}

#
#  Add parens to an expression (alternating the type of paren)
#
sub addParens {
  my $self = shift; my $string = shift;
  if ($string =~ m/^[^\[]*\(/) {return '['.$string.']'}
  return '('.$string.')';
}

#
#  These are stubs for the subclasses
#
sub getVariables {{}}   #  find out what variables are used
sub makeList {shift}    #  flatten a tree of commas into a list
sub makeMatrix {}       #  convert a list to a matrix

sub reduce {shift}
sub substitute {shift}
sub string {}
sub TeX {}
sub perl {}

sub ijk {
  my $self = shift;
  $self->Error("Can't use method 'ijk' with objects of type '%s'",$self->type);
}

#
#  Recursively copy an item, and set a new equation pointer, if any
#
sub copy {
  my $self = shift; my $equation = shift;
  my $new = {%{$self}};
  if (ref($self) ne 'HASH') {
    $new->{equation} = $equation if defined($equation);
    $new->{ref} = undef;
    bless $new, ref($self);
    $new->weaken;
  }
  $new->{type} = copy($self->{type}) if defined($self->{type});
  return $new;
}

#
#  Report an error message
#
sub Error {
  my $self = shift;
  my $message = shift; $message = [$message,@_] if scalar(@_) > 0;
  $self->{equation}->Error($message,$self->{ref}) if defined($self->{equation});
  Parser->Error($message);
}

#########################################################################
#
#  Load the subclasses.
#

END {
  use Parser::BOP;
  use Parser::UOP;
  use Parser::List;
  use Parser::Function;
  use Parser::Variable;
  use Parser::Constant;
  use Parser::Value;
  use Parser::Number;
  use Parser::Complex;
  use Parser::String;
}

#########################################################################

1;
