################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2014 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader:$
# 
# This program is free software; you can redistribute it and/or modify it under
# the terms of either: (a) the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version, or (b) the "Artistic License" which comes with this package.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
# Artistic License for more details.
################################################################################


=head1 NAME

C<Context("Partition")> - Provides a context that allows the
entry of a partition of an integer as a sum of positive integers.


=head1 DESCRIPTION

A partition is a sum of positive integers (usually that add up to a
given number).  Different partitions are ones that are made up of
different integers in the sum.  This context allows students to enter
partitions, and provides the answer checker to determine if partitions
are equal.


=head1 USAGE

	loadMacros("contextPartition.pl");
	
	Context("Partition");
	
	$P1 = Compute("3 + 2 + 5");
	$P2 = Partition(3,2,5);          # same as $P1
	
	$P1->canonical;                  # produces "2 + 3 + 5"
	
	$P3 = Compute("5 + 3 + 2");
        $P4 = Compute("5 + 3 + 1 + 1");
        $P3 == $P1;                      # true
        $P3 == $P4;                      # false
	
	$P3->sum;                        # returns 10

=cut

###########################################################
#
#  Create the contexts and add the constructor functions
#

sub _contextPartition_init {
  my $context = $main::context{Partition} = Parser::Context->getCopy("Numeric");
  $context->{name} = "Partition";

  $context->{pattern}{number} = '-?'.$context->{pattern}{number};
  Parser::Number::NoDecimals($context);

  $context->variables->clear();
  $context->constants->clear();
  $context->strings->clear();
  $context->functions->disable("All");
  $context->operators->undefine($context->operators->names);
  $context->operators->redefine(["fn",",","+"]);
  $context->operators->remove(" ");

  $context->operators->set(
    '+' => {class => 'context::Partition::BOP::add', type => "bin"},
  );

  $context->{value}{Partition} = "context::Partition";
  $context->{precedence}{Partition} = $context->{precedence}{special};

  PG_restricted_eval("sub Partition {context::Partition->new(\@_)}");
}

###########################################################
#
#  The Partition object
#
package context::Partition;
our @ISA = ("Value");

#
#  Check the data and create the object
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $p = [@_]; $p = $p->[0] if scalar(@$p) == 1 && ref($p->[0]) eq "ARRAY";
  $p = [$p->{data}] if scalar(@$p) == 1 && Value::classMatch($p->[0],$class);
  foreach my $x (@{$p}) {
    $x = Value::makeValue($x,context => $context);
    Value->Error("An element of a Partition can't be %s",$x->showType)
       unless $x->isNumber && !$x->isFormula;
    my $i = $x->value;
    Value->Error("Elements of Partitions must be positive") unless $i > 0;
    Value->Error("Elements of Partitions must be integers") unless $i == int($i);
  }
  return bless {data => $p, context => $context}, $class;
}

#
#  Add a number to a partition, or add two partitions
#
sub add {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  $self->make(@{$self->{data}},@{$other->{data}});
}

#
#  Produce the sum for a partition
#
sub sum {
  my $self = shift;
  my $n = 0; map {$n += $_} @{$self->{data}};
  return $n;
}

#
#  Compare two partitions (numbers are promoted)
#
sub compare {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  return $l->canonical cmp $r->canonical;
}

#
#  Produce a canonical representation (numbers sorted)
#
sub canonical {
  my $self = shift;
  $self->make(main::num_sort(@{$self->{data}}));
}

#
#  Promote a number to a Real (since we can add a number to a
#  partition), and promote others to partitions, if possible.
#
sub promote {
  my $self = shift; my $other = shift;
  Value->Error("Can't promote %s to %s",Value::makeValue($other)->showType,$self->showType)
    unless $self->typeMatch($other);
  $self->SUPER::promote($other);
}

#
#  Check if types are compatible
#
sub typeMatch {
  my ($self,$other) = @_;
  return Value::classMatch($other,$self->class) ||
         Value::matchNumber($other) ||
         ref($other) eq 'ARRAY';
}

#
#  Produce a string version
#
sub string {
  my $self = shift;
  join(" + ",@{$self->{data}});
}

#
#  Produce a TeX version
#
sub string {
  my $self = shift;
  join(" + ",@{$self->{data}});
}


###########################################################
#
#  Implement special + operator that produces
#  partitions rather than sums
#
package context::Partition::BOP::add;
our @ISA = ("Parser::BOP");

#
#  Check that the operands are appropriate, and return
#  the proper type reference, or give an error.
#
sub _check {
  my $self = shift;
  my ($ltype,$rtype) = ($self->{lop}->typeRef,$self->{rop}->typeRef);
  $self->{equation}->Error(["Entries in a Partition must be positive integers"])
    unless $self->checkOp($ltype) && $self->checkOp($rtype);
  $self->{type} = Value::Type("Partition",$ltype->{length}+$rtype->{length},$Value::Type{number});
}

#
#  Check that the type of an operand is OK
#  (It must be a partiation or a number)
#
sub checkOp {
  my $self = shift; my $op = shift;
  return $op->{name} eq "Partition" || ($op->{name} eq "Number" && $op->{length} == 1);
}

#
#  Evaluate two numbers by forming a partition,
#   otherwise use addition (Value object will take over)
#
sub _eval {
  my $self = shift;
  my ($a,$b) = @_;
  return Value->Package($self->type)->new($a,$b) if !ref($a) && !ref($b);
  return $a + $b;
}

###########################################################

1;

