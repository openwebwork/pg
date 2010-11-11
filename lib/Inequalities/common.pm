##################################################
##################################################
#
#  Subclasses of the Interval, Set, and Union classes
#  that stringify as inequalities
#

#
#  Some common routines to all three classes
#
package Inequalities::common;

#
#  Turn the object back into its usual Value version
#
sub demote {
  my $self = shift;  my $context = $self->context;
  my $other = shift; $other = $self unless defined $other;
  return $other unless Value::classMatch($other,"Inequality");
  $context->Package($other->type)->make($context,$other->makeData);
}

#
#  Needed to get Interval data in the right order for make(),
#  and demote all the items in a Union
#
sub makeData {(shift)->value}

#
#  Recursively mark Intervals and Sets in a Union as Inequalities
#
sub updateParts {}

#
#  Demote the operands to normal Value objects and
#  perform the action, then remake the result into
#  an Inequality again.
#
sub apply {
  my $self = shift; my $context = $self->context;
  my $method = shift;  my $other = shift;
  $context->Package("Inequality")->new($context,
    $self->demote->$method($self->demote($other),@_),
    $self->{varName});
}

sub add {(shift)->apply("add",@_)}
sub sub {(shift)->apply("sub",@_)}
sub reduce {(shift)->apply("reduce",@_)}
sub intersect {(shift)->apply("intersect",@_)}

#
#  The name to use for error messages in answer checkers
#
sub class {"Inequality"}
sub cmp_class {"an Inequality"}
sub showClass {"an Inequality"}
sub typeRef {
  my $self = shift;
  return Value::Type($self->type, $self->length, $Value::Type{number});
}

#
#  Get the precedence based on the type rather than the class.
#
sub precedence {
  my $self = shift; my $precedence = $self->context->{precedence};
  return $precedence->{$self->type}-$precedence->{Interval}+$precedence->{$self->class};
}

#
#  Produce better error messages for inequalities
#
sub cmp_checkUnionReduce {
  my $self = shift; my $student = shift; my $ans = shift; my $nth = shift || '';
  if (Value::classMatch($student,"Inequality")) {
    return unless $ans->{studentsMustReduceUnions} &&
                  $ans->{showUnionReduceWarnings} &&
                  !$ans->{isPreview} && !Value::isFormula($student);
    my ($result,$error) = $student->isReduced;
    return unless $error;
    return {
      "overlaps" => "Your$nth answer contains overlapping inequalities",
      "overlaps in sets" => "Your$nth answer contains equalities that are already included elsewhere",
      "uncombined intervals" => "Your$nth answer can be simplified by combining some inequalities",
      "uncombined sets" => "",          #  shouldn't get this from inequalities
      "repeated elements in set" => "Your$nth answer contains repeated values",
      "repeated elements" => "Your$nth answer contains repeated values",
    }->{$error};
  } else {
    return unless Value::can($student,"isReduced");
    return Value::cmp_checkUnionReduce($self,$student,$ans,$nth,@_)
  }
}

1;