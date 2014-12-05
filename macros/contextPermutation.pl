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

C<Context("Permutation")> - Provides contexts that allow the
entry of cycles and permutations.


=head1 DESCRIPTION

These contexts allow you to enter permutations using cycle notation.
The entries in a cycle are separated by spaces and enclosed in
parentheses.  Cycles are multiplied by juxtaposition.  A permutation
can be multiplied on the left by a number in order to obtain the
result of that number under the action of the permutation.
Exponentiation is alos allowed (as described below).

There are three contexts included here: C<Context("Permutation")>, which
allows permutations in any form, C<Context("Permutation-Strict")>, which
only allows permutations that use disjoint cycles, and
C<Context("Permutation-Canonical")>, which only allows permutations that
are written in canonical form (as described below).


=head1 USAGE

	loadMacros("contextPermutation.pl");
	
	Context("Permutation");
	
	$P1 = Compute("(1 4 2)(3 5)");
	$P2 = Permutation([1,4,2],[3,5]);  # same as $P1
        $C1 = Cycle(1,4,2);
        $P3 = Cycle(1,4,2)*Cycle(3,5);     # same as $P1
        
        $n = 3 * $P1;                      # sets $n to 5
        $m = Compute("3 (2 4 3 1)");       # sets $m to 1
	
	$P4 = Compute("(1 2 3)^2");        # square a cycle
        $P5 = Compute("((1 2)(3 4))^2");   # square a permutation
        $I = Comptue("(1 2 3)^-1");        # inverse
	
	$L = Compute("(1 2),(1 3 2)");     # list of permutations
	
	$P = $P1->inverse;                 # inverse
	$P = $P1->canonical;               # canonical representation
	
	$P1 = Compute("(1 2 3)(4 5)");
	$P2 = Compute("(5 4)(3 1 2)");
	$P1 == $P2;                        # is true

Cycles and permutations can be multiplied to obtain the permutation
that consists of one followed by the other, or multiplied on the left
by a number to obtain the image of the number under the permutation.
A permutation raised to a positive integer is the permutation
multiplied by itself that many times.  A power of -1 is the inverse of
the permutation, while a larger negative number is the inverse
multiplied by itself that many times (the absolute value of the
power).

There are times when you might not want to allow inverses to be
computed automatically.  In this case, set

	Context()->flags->set(noInverses => 1);

This will cause an error message if a student enters a negative power
for a cycle or permutation.

If you don't want to allow any powers at all, then set

	Context()->flags->set(noPowers => 1);

Similarly, if you don't want to allow grouping of cycles via
parentheses (e.g., "((1 2)(3 4))^2 (5 6)"), then use

	Context()->flags->set(noGroups => 1);

The comparison between permutations is done by comparing the
canonical forms, so even if they are entered in different orders or
with the cycles rotated, two equivalent permutations will be counted
as equal.  If you want to perform more sophisticated checks, then a
custom error checker could be used.

You can require that permutations be entered using disjoint cycles by
setting

	Context()->flags->set(requireDisjoint => 1);

When this is set, Compute("(1 2) (1 3)") will produce an error
indicating that the permutation doesn't have disjoint cycles.

You can also require that students enter permutations in a canonical
form.  The canonical form has each cycle listed with its lowest entry
first, and with the cycles ordered by their initial entries.  So the
canonical form for

	(5 4 6) (3 1 2)

is

	(1 2 3) (4 6 5)

To require that permutations be entered in canonical form, use

	Context()->flags->set(requireCanonical => 1);

The C<Permutation-Strict> context has C<noInverses>, C<noPowers>, C<noGroups>, and
C<requireDisjoint> all set to 1, while the C<Permutation-Canonical> has
C<noInverses>, C<noPowers>, C<noGroups>, and C<requireCanonical> all set to 1.
The C<Permutation> context has all the flags set to 0, so any permutation
is allowed.  All three contexts allow lists of permutations to be
entered.

=cut

###########################################################
#
#  Create the contexts and add the constructor functions
#

sub _contextPermutation_init {
  my $context = $main::context{Permutation} = Parser::Context->getCopy("Numeric");
  $context->{name} = "Permutation";
  Parser::Number::NoDecimals($context);
  $context->variables->clear();
  $context->operators->clear();
  $context->constants->clear();
  $context->strings->clear();
  $context->functions->disable("All");

  $context->{pattern}{number} = '(?:(?:^|(?<=[( ^*]))-)?(?:\d+(?:\.\d*)?|\.\d+)(?:E[-+]?\d+)?',

  $context->operators->add(
    ',' => {precedence => 0, associativity => 'left', type => 'bin', string => ',',
            class => 'Parser::BOP::comma', isComma => 1},

    'fn'=> {precedence => 7.5, associativity => 'left', type => 'unary', string => '',
            parenPrecedence => 5, hidden => 1},

    ' ' => {precedence => 3, associativity => 'right', type => 'bin', string => ' ',
            class => 'context::Permutation::BOP::space', hidden => 1, isComma => 1},

    '^' => {precedence => 7, associativity => 'right', type => 'bin', string => '^', perl => '**',
            class => 'context::Permutation::BOP::power'},

    '**'=> {precedence => 7, associativity => 'right', type => 'bin', string => '^', perl => '**',
            class => 'context::Permutation::BOP::power'},
  );

  $context->{value}{Cycle} = "context::Permutation::Cycle";
  $context->{value}{Permutation} = "context::Permutation::Permutation";
  $context->{precedence}{Cycle} = $context->{precedence}{special};
  $context->{precedence}{Permutation} = $context->{precedence}{special}+1;
  $context->lists->add(
    "Cycle" => {class => "context::Permutation::List::Cycle", open => "(", close => ")", separator => " "},
    "Permutation" => {open => "", close => "", separator => " "},  # used for output only
  );
  $context->parens->set(
    '(' => {close => ')', type => 'Cycle', formList => 0, removable => 0, emptyOK => 0, function => 1},
  );
  $context->flags->set(reduceConstants => 0);

  $context->flags->set(
    requireDisjoint => 0,    # require disjoint cycles as answers?
    requireCanonical => 0,   # require canonical form?
    noPowers => 0,           # allow powers of cycles and permutations?
    noInverses => 0,         # allow negative powers to mean inverse?
    noGroups => 0,           # allow parens for grouping (for powers)?
  );

  $context->{error}{msg}{"Entries in a Cycle must be of the same type"} =
     "Entries in a Cycle must be positive integers";

  #
  #  A context in which permutations must be entered as
  #  products of disjoint cycles.
  #
  $context = $main::context{"Permutation-Strict"} = $context->copy;
  $context->{name} = "Permutation-Strict";
  $context->flags->set(
    requireDisjoint => 1,
    noPowers => 1,
    noInverses => 1,
    noGroups => 1,
  );

  #
  #  A context in which permutation must be entered
  #  in canonical form.
  #
  $context = $main::context{"Permutation-Canonical"} = $context->copy;
  $context->{name} = "Permutation-Canonical";
  $context->flags->set(
    requireCanonical => 1,
    requireDisjoint => 0,     # requireCanonical already covers that
  );


  PG_restricted_eval("sub Cycle {context::Permutation::Cycle->new(\@_)}");
  PG_restricted_eval("sub Permutation {context::Permutation::Permutation->new(\@_)}");

}

###########################################################
#
#  Methods common to cycles and permutations
#

package context::Permutation;
our @ISA = ("Value");

#
#  Use the usual make(), and then add the permutation data
#
sub make {
  my $self = shift;
  $self = $self->SUPER::make(@_);
  $self->makeP;
  return $self;
}

#
#  Permform multiplication of a number by a cycle or permutation,
#  or a product of two cycles or permutations.
#
sub mult {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  if ($l->isReal) {
    $l = $l->value;
    Value->Error("Can't multiply %s by a non-integer value",$self->showType) unless $l == int($l);
    Value->Error("Can't multiply %s by a negative value",$self->showType) if $l < 0;
    my $n = $self->{P}{$l}; $n = $l unless defined $n;
    return $self->Package("Real")->make($n);
  } else {
    Value->Error("Can't multiply %s by %s",$l->showType,$r->showType)
      unless $r->classMatch("Cycle","Permutation");
    return $self->Package("Permutation")->new($l,$r);
  }
}

#
#  Perform powers by repeated multiplication;
#  Negative powers are inverses.
#
sub power {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  Value->Error("Can't raise %s to %s",$l->showType,$r->showType) unless $r->isNumber;
  Value->Error("Powers are not allowed") if $self->getFlag("noPowers");
  if ($r < 0) {
    Value->Error("Inverses are not allowed",$l->showType) if $self->getFlag("noInverses");
    $r = -$r; $l = $l->inverse;
  }
  $self->Package("Permutation")->make(map {$l} (1..$r))->canonical;
}

#
#  Compare canonical representations
#
sub compare {
  my ($self,$l,$r,$other) = Value::checkOpOrderWithPromote(@_);
  Value->Error("Can't compare %s and %s",$self->showType,$other->showType)
    unless $other->classMatch("Cycle","Permutation");
  return $l->canonical cmp $r->canonical;
}

#
#  True if the permutation is in canonical form
#
sub isCanonical {
  my $self = shift;
  return $self eq $self->canonical;
}

#
#  Promote a number to a Real (since we can take a number times a
#  permutation, or a permutation to a power), and anything else to a
#  Cycle or Permutation.
#
sub promote {
  my $self = shift; my $other = shift;
  return Value::makeValue($other,context => $self->{context}) if Value::matchNumber($other);
  return $self->SUPER::promote($other);
}

#
#  Produce a canonical representation as a collection of
#  cycles that have their lowest entry first, sorted
#  by initial entry.
#
sub canonical {
  my $self = shift;
  my @P = (); my @C;
  my %N = (map {$_ => 1} (keys %{$self->{P}}));
  while (scalar(keys %N)) {
    $i = (main::num_sort(keys %N))[0]; @C = ();
    do {
      push(@C,$self->Package("Real")->new($i)); delete $N{$i};
      $i = $self->{P}{$i} if defined $self->{P}{$i};
    } while ($i != $C[0]);
    push(@P,$self->Package("Cycle")->make($self->{context},@C));
  }
  return $P[0] if scalar(@P) == 1;
  return $self->Package("Permutation")->make($self->{context},@P);
}

#
#  Produce the inverse of a permutation or cycle.
#
sub inverse {
  my $self = shift;
  my $P = {map {$self->{P}{$_} => $_} (keys %{$self->{P}})};
  return $self->with(P => $P)->canonical;
}

#
#  Produce a string version (use "(1)" as the identity).
#
sub string {
  my $self = shift;
  my $string = $self->SUPER::string(@_);
  $string = "(1)" unless length($string);
  return $string;
}

#
#  Produce a TeX version (uses \; for spaces)
#
sub TeX {
  my $self = shift;
  my $tex = $self->string;
  $tex =~ s/\) \(/)\\,(/g; $tex =~ s/ /\\;/g;
  return $tex;
}

###########################################################
#
#  A single cycle
#

package context::Permutation::Cycle;
our @ISA = ("context::Permutation");

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $p = [@_]; $p = $p->[0] if scalar(@$p) == 1 && ref($p->[0]) eq "ARRAY";
  return $p->[0] if scalar(@$p) == 1 && Value::classMatch($p->[0],"Cycle","Permutation");
  my %N;
  foreach my $x (@{$p}) {
    $x = Value::makeValue($x,context => $context);
    Value->Error("An entry of a Cycle can't be %s",$x->showType)
       unless $x->isNumber && !$x->isFormula;
    my $i = $x->value;
    Value->Error("An entry of a Cycle can't be negative") if $i < 0;
    Value->Error("Cycles can't contain repeated values") if $N{$i}; $N{$i} = 1;
  }
  my $cycle = bless {data => $p, context => $context}, $class;
  $cycle->makeP;
  return $cycle;
}

#
#  Find the internal representation of the permutation
#  (a hash representing where each element goes)
#
sub makeP {
  my $self = shift;
  my $p = $self->{data}; my $P = {};
  if (@$p) {
    my $i = $p->[scalar(@$p)-1]->value;
    foreach my $x (@{$p}) {
      my $j = $x->value;
      $P->{$i} = $j unless $i == $j;  # don't record identity
      $i = $j;
    }
  }
  $self->{P} = $P;
}

###########################################################
#
#  A combination of cycles
#

package context::Permutation::Permutation;
our @ISA = ("context::Permutation");

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $disjoint = $self->getFlag("requireDisjoint");
  my $p = [@_]; my %N;
  foreach my $x (@$p) {
    $x = Value::makeValue($x,context=>$context) unless ref($x);
    $x = Value->Package("Cycle")->new($context,$x) if ref($x) eq "ARRAY";
    Value->Error("An entry of a Permutation can't be %s",Value::showClass($x))
      unless Value::classMatch($x,"Cycle","Permutation");
    if ($disjoint) {
      foreach my $i (keys %{$x->{P}}) {
	Value->Error("Your Permutation does not have disjoint Cycles") if $N{$i};
	$N{$i} = 1;
      }
    }
  }
  my $perm = bless {data => $p, context => $context}, $class;
  $perm->makeP;
  Value->Error("Your Permutation is not in canonical form")
    if $perm->getFlag("requireCanonical") && $perm ne $perm->canonical;
  return $perm;
}

#
#  Find the internal representation of the permutation
#  (a hash representing where each element goes)
#
sub makeP {
  my $self = shift; my $p = $self->{data};
  my $P = {}; my %N;
  foreach my $x (@$p) {map {$N{$_} = 1} (keys %{$x->{P}})}  # get all elements used
  foreach my $i (keys %N) {
    my $j = $i;
    map {$j = $_->{P}{$j} if defined $_->{P}{$j}} @$p;   # apply all cycles/permutations
    $P->{$i} = $j unless $i == $j;                       # don't record identity
  }
  $self->{P} = $P;
}


###########################################################
#
#  Space between numbers forms a cycle.
#  Space between cycles forms a permutation.
#  Space between a number and a cycle or
#    permutation evaluates the permutation
#    on the number.
#
package context::Permutation::BOP::space;
our @ISA = ("Parser::BOP");

#
#  Check that the operands are appropriate, and return
#  the proper type reference, or give an error.
#
sub _check {
  my $self = shift; my $type;
  my ($ltype,$rtype) = ($self->{lop}->typeRef,$self->{rop}->typeRef);
  if ($ltype->{name} eq "Number") {
    if ($rtype->{name} eq "Number") {
      $type = Value::Type("Comma",2,$Value::Type{number});
    } elsif ($rtype->{name} eq "Comma") {
      $type = Value::Type("Comma",$rtype->{length}+1,$Value::Type{number});
    } elsif ($rtype->{name} eq "Cycle" || $rtype->{name} eq "Permutation") {
      $type = $Value::Type{number};
    }
  } elsif ($ltype->{name} eq "Cycle") {
    if ($rtype->{name} eq "Cycle") {
      $type = Value::Type("Permutation",2,$ltype);
    } elsif ($rtype->{name} eq "Permutation") {
      $type = Value::Type("Permutation",$rtype->{length}+1,$ltype);
    }
  }
  if (!$type) {
    $ltype = $ltype->{name}; $rtype = $rtype->{name};
    $ltype = (($ltype =~ m/^[aeiou]/i)? "An ": "A ") . $ltype;
    $rtype = (($rtype =~ m/^[aeiou]/i)? "an ": "a ") . $rtype;
    $self->{equation}->Error(["%s can not be multiplied by %s",$ltype,$rtype]);
  }
  $self->{type} = $type;
}

#
#  Evaluate by forming a list if this is acting as a comma,
#  othewise take a product (Value object will take care of things).
#
sub _eval {
  my $self = shift;
  my ($a,$b) = @_;
  return ($a,$b) if $self->type eq "Comma";
  return $a * $b;
}

#
#  If the operator is not a comma, return the item itself.
#  Otherwise, make a list out of the lists that are the left
#    and right operands.
#
sub makeList {
  my $self = shift; my $prec = shift;
  return $self unless $self->{def}{isComma} && $self->type eq 'Comma';
  return ($self->{lop}->makeList,$self->{rop}->makeList);
}

#
#  Produce the TeX form
#
sub TeX {
  my $self = shift;
  return $self->{lop}->TeX."\\,".$self->{rop}->TeX;
}


###########################################################
#
#  Powers of cycles form permutations
#
package context::Permutation::BOP::power;
our @ISA = ("Parser::BOP::power");

#
#  Check that the operands are appropriate,
#    and return the proper type reference
#
sub _check {
  my $self = shift; my $equation = $self->{equation};
  $equation->Error(["Powers are not allowed"]) if $equation->{context}->flag("noPowers");
  $equation->Error(["You can only take powers of Cycles or Permutations"])
    unless $self->{lop}->type eq "Cycle";
  $self->{rop} = $self->{rop}{coords}[0] if $self->{rop}->type eq "Cycle" && $self->{rop}->length == 1;
  $equation->Error(["Powers of Cycles and Permutations must be Numbers"])
    unless $self->{rop}->type eq "Number";
  $self->{type} = Value::Type("Permutation",1,$self->{lop}->typeRef);
}


###########################################################
#
#  The List subclass for cycles in the parse tree
#

package context::Permutation::List::Cycle;
our @ISA = ("Parser::List");

#
#  Check that the coordinates are numbers.
#  If there is one parameter and it is a cycle or permutation
#   treat this as plain parentheses, not cycle parentheses
#   (so you can take groups of cycles to a power).
#
sub _check {
  my $self = shift;
  if ($self->length == 1 && !$self->{equation}{context}->flag("noGroups")) {
    my $value = $self->{coords}[0];
    return if ($value->type eq "Cycle" || $value->typeRef->{name} eq "Permutation" ||
              ($value->class eq "Value" && $value->{value}->classMatch("Cycle","Permutation")));
  }
  foreach my $x (@{$self->{coords}}) {
    unless ($x->isNumber) {
      my $type = $x->type;
      $type = (($type =~ m/^[aeiou]/i)? "an ": "a ") . $type;
      $self->{equation}->Error(["An entry in a Cycle must be a Number not %s",$type]);
    }
  }
}

#
#  Produce a string version.  (Shouldn't be needed, but there is
#  a bug in the Value.pm version that neglects the separator value.)
#
sub string {
  my $self = shift; my $precedence = shift; my @coords = ();
  foreach my $x (@{$self->{coords}}) {push(@coords,$x->string)}
  my $comma = $self->{equation}{context}{lists}{$self->{type}{name}}{separator};
  return $self->{open}.join($comma,@coords).$self->{close};
}

#
#  Produce a TeX version.
#
sub TeX {
  my $self = shift; my $precedence = shift; my @coords = ();
  foreach my $x (@{$self->{coords}}) {push(@coords,$x->TeX)}
  my $comma = $self->{equation}{context}{lists}{$self->{type}{name}}{separator};
  $comma =~ s/ /\\;/g;
  return $self->{open}.join($comma,@coords).$self->{close};
}

###########################################################

1;

