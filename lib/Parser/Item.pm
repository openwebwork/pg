#########################################################################
#
#  Implements the basic parse tree node.  Subclasses of this class
#  are things like binary operator, function call, and so on.
#  
package Parser::Item;
use strict;

#
#  Return the class name of an item
#
sub class {
  my $self = ref(shift);
  $self =~ s/[^:]*:://; $self =~ s/::.*//;
  return $self;
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
  return ($self->class eq 'UOP' && $self->{uop} eq 'u-');
}

#
#  These are stubs for the subclasses
#
sub getVariables {{}}   #  find out what variables are used
sub makeList {shift}    #  flatten a tree of commas into a list
sub makeUnion {shift}   #  flatten a tree of unions into a list of intervals
sub makeMatrix {}       #  convert a list to a matrix

sub reduce {shift}
sub substitute {shift}
sub string {}
sub TeX {}
sub perl {}

#
#  Recursively copy an item, and set a new equation pointer, if any
#
sub copy {
  my $self = shift; my $equation = shift;
  my $new = {%{$self}}; 
  if (ref($self) ne 'HASH') {
    bless $new, ref($self);
    $new->{equation} = $equation if defined($equation);
    $new->{ref} = undef;
  }
  $new->{type} = copy($self->{type}) if defined($self->{type});
  return $new;
}

#
#  Report an error message
#
sub Error {
  my $self = shift;
  $self->{equation}->Error(@_,$self->{ref}) if defined($self->{equation});
  Parser->Error(@_);
}

#########################################################################
#
#  Load the subclasses.
#

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

#########################################################################

1;

