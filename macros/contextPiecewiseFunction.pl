################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader$
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

contextPiecewiseFunction.pl - Allow usage of piecewise functions.

=head1 DESCRIPTION

This file implements a context in which piecewise-defined functions
can be specified by students and problem authors.  To use it, add

	loadMacros("contextPiecewiseFunction.pl");

and then use

	Context("PiecewiseFunction");

to select the context for piecewise functions.  There are several
ways to produce a piecewise function.  For example:

	$f = Compute("x if x >= 0 else -x");
	$f = Compute("x if x >= 0 else -x if x < 0");
	$f = Formula("x+1 if x > 2 else 4 if x = 2 else 1-x");
	$f = PiecewiseFunction("x^2 if 1 < x <= 2 else 2x+1");
	$f = PiecewiseFunction("1 < x <= 2" => "x^2", "2x+1");
	$f = PiecewiseFunction("(1,2]" => "x^2", "2x+1");
	$f = PiecewiseFunction(Interval("(1,2]") => "x^2", "2x+1");

You can use either Compute() or Formula() interchangeably to
convert a string containing "if" and "else" to the corresponding
PiecewiseFunction.  The PiecewiseFunction() constructor can
also do this, or you can pass it a list of interval=>formula
pairs that specify the various branches.  If there is an
unpaired final formula, it represents the "otherwise" portion
of the function (the formula to use of the input is not in
any of the given intervals).

Note that you can use Inveral, Set, or Union objects in place of
the intervals in the specification of a piecewise function.

The PiecewiseFunction object TeXifies using a LaTeX "cases"
environment, so you can use these objects to produce nice
output even if you are not asking a student to enter one.
For example:

	Context("PiecewiseFunction");
	
	$f = Formula("1-x if x > 0 else 4 if x = 0 else 1+x if x < 0");
	$a = random(-2,2,.1);
	
	Context()->texStrings;
	BEGIN_TEXT
	If \[f(x)=$f\] then \(f($a)\) = \{ans_rule(20)\}.
	END_TEXT
	Context()->normalStrings;
	
	ANS($f->eval(x=>$a)->cmp);

Normally when you use a piecewise function at the end of a sentence,
the period is placed at the end of the last case.  Since

	\[ f(x) = $f \].

would put the period centered at the right-hand side of the function,
this is not what is desired.  To get a period at the end of the last
case, use

	\[ f(x) = \{$f->with(final_period=>1)\} \]

instead.

=cut

loadMacros("MathObjects.pl");
loadMacros("contextInequalities.pl");

sub _contextPiecewiseFunction_init {PiecewiseFunction::Init()}

package PiecewiseFunction;

#
#  Create the needed context and the constructor function
#
sub Init {
  my $context = $main::context{PiecewiseFunction} = Parser::Context->getCopy("Inequalities");
  $context->{value}{PiecewiseFunction} = 'PiecewiseFunction::Function';
  $context->operators->add(
     "if " => {
        precedence =>.31, associativity => 'left', type => 'binary',
        string => ' if ', TeX => '\hbox{ if }', class => 'PiecewiseFunction::BOP::if',
     },

     "for " => {
        precedence =>.31, associativity => 'left', type => 'binary',
        string => ' for ', TeX => '\hbox{ for }', class => 'PiecewiseFunction::BOP::if',
     },

     "else" => {
        precedence =>.3, associativity => 'right', type => 'binary',
        string => " else\n", TeX => '\hbox{ else }', class => 'PiecewiseFunction::BOP::else',
     },

     "in " => {
        precedence => .35, asscoiativity => 'right', type => 'binary',
        string => ' in ', TeX => '\in ', class => 'PiecewiseFunction::BOP::in',
     },
  );
  $context->{value}{InequalityIn} = 'PiecewiseFunction::Interval';
  $context->{value}{'Formula()'} = 'PiecewiseFunction::Formula';
  $context->{cmpDefaults}{PiecewiseFunction} = {reduceSets => 1, requireParenMatch => 1};

  main::PG_restricted_eval('sub PiecewiseFunction {Value->Package("PiecewiseFunction")->new(@_)}');
}

##################################################
##################################################

#
#  A class to implement undefined values (points that
#  are not in the domain of the function)
#
package PiecewiseFunction::undefined;
our @ISA = ('Value');

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $equation = shift;
  bless {data => [], isUndefined => 1, equation => $equation}, $class;
}

sub value {undef}

sub string {die "undefined value"}
sub TeX    {die "undefined value"}
sub perl   {"PiecewiseFunction::undefined->new()"}

##################################################
#
#  Implement the "if" operator to specify a branch
#  of the piecewise function.
#
package PiecewiseFunction::BOP::if;
our @ISA = ('Parser::BOP');

#
#  Only allow inequalities on the right.
#  Mark the object with identifying values
#
sub _check {
  my $self = shift;
  $self->Error("The condition should be an inequality") unless $self->{rop}{isInequality};
  $self->{type} = {%{$self->{lop}->typeRef}};
  $self->{isIf} = $self->{canCompute} = 1;
  $self->{varName} = $self->{rop}{varName} || ($self->context->variables->names)[0];
}

#
#  Return the function's value if the variable is within
#    the inequality for this branch (otherwise return
#    and undefined value).
#
sub eval {
  my $self = shift;
  my $I = $self->{rop}->eval;
  return PiecewiseFunction::undefined->new unless $I->contains($self->{equation}{values}{$self->{varName}});
  return $self->{lop}->eval;
}

#
#  Make a piecewise function from this branch
#
sub Compute {
  my $self = shift; my $context = shift || $self->context; my $method = shift || "new";
  return $context->Package("PiecewiseFunction")->$method($context,$self->flatten($context));
}

#
#  Make an interval=>formula pair from this item
#
sub flatten {
  my $self = shift; my $context = shift || $self->context;
  my $I = $self->{rop}->eval;
  my $f = $context->Package("Formula")->new($context,$self->{lop});
  return ($I => $f);
}

#
#  Print using the TeX method of the PiecewiseFunction object
#
sub TeX {(shift)->Compute(undef,"make")->TeX}

#
#  Make an if-then-else statement that returns the function's
#    value or an undefined value (depending on whether the
#    variable is in the interval or not).
#
sub perl {
  my $self = shift; my $parens = shift;
  my $I = $self->{rop}->eval; my $x = "\$".$self->{varName};
  my $condition = $I->perl.'->contains('.$x.')';
  my $lop = $self->{lop}->perl; my $rop = 'PiecewiseFunction::undefined->new';
  return '('.$condition.' ? '.$lop.' : '.$rop.')'
}

##################################################
#
#  Implement the "else" operator to join the
#  different branches of the function.
#
package PiecewiseFunction::BOP::else;
our @ISA = ('Parser::BOP');

#
#  Make sure there is an "if" that goes with this else.
#
sub _check {
  my $self = shift;
  $self->Error("You must have an 'if' to the left of 'else'") unless $self->{lop}{isIf};
  $self->{type} = {%{$self->{lop}->typeRef}};
  $self->{isElse} = $self->{canCompute} = 1;
}

#
#  Use the result of the "if" to decide which value to return.
#
sub eval {
  my $self = shift; my $lop = $self->{lop}->eval;
  return (ref($lop) eq 'PiecewiseFunction::undefined' ? $self->{rop}->eval : $lop);
}

#
#  Make a PiecewiseFunction from the (nested) if-then-else values.
#
sub Compute {
  my $self = shift; my $context = shift || $self->context; my $method = shift || "new";
  return $context->Package("PiecewiseFunction")->$method($context,$self->flatten($context))
}

#
#  Recursively flatten the if-then-else tree to a list
#  of interval=>formula pairs.
#
sub flatten {
  my $self = shift; my $context = shift || $self->context;
  my $flatten = $self->{rop}->can("flatten");
  return ($self->{lop}->flatten($context),&$flatten($self->{rop},$context)) if $flatten;
  my $f = $context->Package("Formula")->new($context,$self->{rop});
  return ($self->{lop}->flatten($context),$f);
}

#
#  Don't do extra parens for nested else's.
#
sub string {
  my ($self,$precedence,$showparens,$position,$outerRight) = @_;
  my $string; my $bop = $self->{def};
  $position = '' unless defined($position);
  $showparens = '' unless defined($showparens);
  my $addparens = defined($precedence) && ($showparens eq 'all' || $precedence > $bop->{precedence});
  $outerRight = !$addparens && ($outerRight || $position eq 'right');

  $string = $self->{lop}->string($bop->{precedence},$bop->{leftparens},'left',$outerRight).
            $bop->{string}.
            $self->{rop}->string($bop->{precedence});

  $string = $self->addParens($string) if $addparens;
  return $string;
}

#
#  Use the PiecewiseFunction TeX method.
#
sub TeX {(shift)->Compute(undef,"make")->TeX}

#
#  Use an if-then-else to determine the value to use.
#
sub perl {
  my $self = shift; my $parens = shift;
  my $I = $self->{lop}{rop}->eval; my $x = "\$".$self->{lop}{varName};
  my $condition = $I->perl.'->contains('.$x.')';
  my $lop = $self->{lop}{lop}->perl; my $rop = $self->{rop}->perl;
  return '('.$condition.' ? '.$lop.' : '.$rop.')';
}


##################################################
#
#  Implement an "in" operator for "x in (a,b)" as an
#  alternative to inequality notation.
#
package PiecewiseFunction::BOP::in;
our @ISA = ('Parser::BOP');

#
#  Make sure the variable is to the left and an interval,
#  set, or union is to the right.
#
sub _check {
  my $self = shift;
  $self->{type} = Value::Type("Interval",2);
  $self->{isInequality} = 1;
  $self->Error("There should be a variable to the left of '%s'",$self->{bop})
    unless $self->{lop}->class eq 'Variable';
  $self->Error("There should be a set of numbers to the right of '%s'",$self->{bop})
    unless $self->{rop}->isSetOfReals;
  $self->{varName} = $self->{lop}{name};
  delete $self->{equation}{variables}{$self->{lop}{name}} if $self->{lop}{isNew};
  $self->{lop} = Inequalities::DummyVariable->new($self->{equation},$self->{lop}{name},$self->{lop}{ref});
}

#
#  Call this an Inequality so it will be allowed to the
#  right of "if" operators.
#
sub _eval {
  my $self = shift;
  bless $self->Package("Inequality")->new($_[1],$self->{varName}),
    $self->Package("InequalityIn");
}

##################################################
#
#  This implements the "in" operator as in inequality.
#  We inherit all the inequality methods, and simply
#  need to handle the string and TeX output.  The
#  underlying type is still an Inerval.
#
package PiecewiseFunction::Interval;
our @ISA = ("Inequalities::Interval");

sub string {
  my $self = shift;  my $equation = shift;
  my $x = $self->{varName} || ($self->context->variables->names)[0];
  $x = $context->{variables}{$x}{string} if defined $context->{variables}{$x}{string};
  $x . ' in ' . $self->demote->string;
}

sub TeX {
  my $self = shift;  my $equation = shift;
  my $x = $self->{varName} || ($self->context->variables->names)[0];
  $x = $context->{variables}{$x}{TeX} if defined $context->{variables}{$x}{TeX};
  $x =~ s/^([^_]+)_?(\d+)$/$1_{$2}/;
  $x . '\in ' . $self->demote->TeX;
}

##################################################
##################################################
#
#  This implements the PiecewiseFunction.  It is an unusual mix
#  of a Value object and a Formula object.  It looks like a
#  Formula for the most part, but doesn't have the same internal
#  structure.  Most of the Formula methods have been provided
#  so that eval, substitute, reduce, etc will be applied to all
#  the branches.
#
package PiecewiseFunction::Function;
our @ISA = ('Value', 'Value::Formula');

#
#  Create the PiecewiseFunction object, with error reporting
#  for problems in the data.
#
#  Usage:  PiecewiseFunction("formula")
#          PiecewiseFunction(I1 => f1, I2 => f2, ... , fn);
#
#  In the first case, the formula is parsed for "if" and "else" values
#  to produce the function.  In the second, the function is given
#  by interval/formula pairs that associate what function to map over
#  interval.  If there is an unpaired formula at the end, it is
#  the "otherwise" formula that will be used whenever the input
#  does not fall into one of the given intervals.
#
#  Note that the intervals above actually can be Interval, Set,
#  or Union objects, not just plain intervals.
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  Value->Error("You must provide at least one Formula for a Piecewise Function") unless scalar(@_);
  my $F = shift; $F = [$F,@_] if scalar(@_);
  return $F if ref($F) eq $class;
  unless (ref($F) eq 'ARRAY') {
    $F = $context->Package("Formula")->new($context,$F);
    if ($F->{tree}->can("Compute")) {
      $F = $F->{tree}->Compute($context);
      return $F if ref($F) eq $class;
    }
    $F = [$F];
  }
  my $pf = bless {data => [], context => $context, isPiecewiseFunction => 1}, $class;
  my $x = ''; $pf->{variables} = {};
  while (scalar(@$F) > 1) {
    my $I = shift(@$F); my $f = shift(@$F);
    $I = $context->Package("Interval")->new($context,$I) unless Value::classMatch($I,"Interval","Set","Union");
    $f = $context->Package("Formula")->new($context,$f) unless Value::isFormula($f);
    $I->{equation} = $f->{equation} = $pf; ### Transfer equation flag?
    push(@{$pf->{data}},[$I,$f]);
    $x = $I->{varName} unless $x;
    foreach my $v (keys %{$f->{variables}}) {$pf->{variables}{$v} = 1}
  }
  if (scalar(@$F)) {
    $pf->{otherwise} = $context->Package("Formula")->new($context,shift(@$F));
    $pf->{otherwise}{equation} = $pf;  ### transfer?
    foreach my $v (keys %{$pf->{otherwise}{variables}}) {$pf->{variables}{$v} = 1}
  }
  $pf->{varName} = ($x || ($context->variables->names)[0]);
  $pf->{variables}{$pf->{varName}} = 1;
  $pf->check;
  return $pf;
}

#
#  Create a PiecewiseFunction without error checking (so overlapping intervals,
#  incorrect variables, and so on could appear).
#
sub make {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $pf = bless {data => [], context => $context, isPiecewiseFunction => 1}, $class;
  my $x = '';
  while (scalar(@_) > 1) {
    my $I = shift; my $f = shift;
    $I->{equation} = $f->{equation} = $pf;  ### Transfer equation flag?
    $x = $I->{varName} unless $x;
    push(@{$pf->{data}},[$I,$f]);
    $self->{typeRef} = $f->typeRef unless defined $self->{typeRef};
    foreach my $v (keys %{$f->{variables}}) {$pf->{variables}{$v} = 1}
  }
  if (scalar(@_)) {
    $pf->{otherwise} = shift;
    $pf->{otherwise}{equation} = $pf;  ### transfer?
    foreach my $v (keys %{$f->{otherwise}{variables}}) {$pf->{variables}{$v} = 1}
  }
  $pf->{varName} = ($x || ($context->variables->names)[0]);
  $pf->{variables}{$pf->{varName}} = 1;
  return $pf;
}

#
#  Do the consistency checks for the separate branches.
#
sub check {
  my $self = shift;
  $self->checkVariable;
  $self->checkMultipleValued;
  $self->checkTypes;
}

#
#  Check that all the inequalities are for the same variable.
#
sub checkVariable {
  my $self = shift; my $context = $self->context;
  my $x = $self->{varName};
  foreach my $If (@{$self->{data}}) {
    my ($I,$f) = @$If;
    $I = $If->[0] = $context->Package("Inequality")->new($context,$I,$x)
      unless $I->classMatch("Inequality");
    Value->Error("All the intervals must use the same variable") if $I->{varName} ne $x;
  }
}

#
#  Check that no domain intervals overlap.
#
sub checkMultipleValued {
  my $self = shift;
  my @D = $self->domainUnion->sort->value;
  foreach my $i (0..scalar(@D)-2) {
    my ($I,$J) = @D[$i,$i+1];
    Value->Error("A piecewise function can't have overlapping domain intervals")
      if $I->intersects($J);
  }
}

#
#  Check that all the branches return the same type of result.
#
sub checkTypes {
  my $self = shift;
  foreach my $If (@{$self->{data}}) {$self->checkType($If->[1])}
  $self->checkType($self->{otherwise}) if defined $self->{otherwise};
}

sub checkType {
  my $self = shift; my $f = shift;
  if (defined $self->{typeRef}) {
    Value->Error("All the formulas must produce the same type of answer")
      unless Parser::Item::typeMatch($self->{typeRef},$f->typeRef);
  } else {$self->{typeRef} = $f->typeRef}
}

#
#  This is always considered a formula.
#
sub isConstant {0}

#
#  Look through the branches for the one that contains
#  the variable's value, and evaluate it.  If not in
#  any of the intervals, use the "otherwise" value,
#  or die with no value if there isn't one.
#
sub eval {
  my $self = shift;
  $self->setValues(@_); my $x = $self->{values}{$self->{varName}}; $self->unsetValues;
  foreach my $If (@{$self->{data}}) {
    my ($I,$f) = @{$If};
    return $f->eval(@_) if $I->contains($x);
  }
  return $self->{otherwise}->eval(@_) if defined $self->{otherwise};
  die "undefined value";
}

#
#  Reduce each branch individually.
#
sub reduce {
  my $self = shift; my @cases = ();
  foreach my $If (@{$self->{data}}) {
    my ($I,$f) = @{$If};
    push(@cases,$I->copy => $f->reduce(@_));
  }
  push(@cases,$self->{otherwise}->reduce(@_)) if defined $self->{otherwise};
  return $self->make(@cases);
}

#
#  Substitute into each branch individually.
#  If the function's variable is substituted, then
#    if it is a constant, find the branch for that value
#    and substitute into that, otherwise if it is
#    just another variable, replace the variable
#    in the inequalities as well as the formulas.
#  Otherwise, just replace in the formulas.
#
sub substitute {
  my $self = shift;
  my @cases = (); my $x = $self->{varName};
  $self->setValues(@_); my $a = $self->{values}{$x}; $self->unsetValues(@_);
  if (defined $a) {
    if (!Value::isFormula($a)) {
      my $f = $self->getFunctionFor($a);
      die "undefined value" unless defined $f;
      return $f->substitute(@_);
    }
    $x = $a->{tree}{name} if $a->{tree}->class eq 'Variable';
  }
  foreach my $If (@{$self->{data}}) {
    my ($I,$f) = @{$If};
    $I = $I->copy; if ($x ne $I->{varName}) {$I->{varName} = $x; $I->updateParts}
    push(@cases,$I => $f->substitute(@_));
  }
  push(@cases,$self->{otherwise}->substitute(@_)) if defined $self->{otherwise};
  return $self->make(@cases);
}


#
#  Return the domain of the function (will be (-inf,inf) if
#  there is an "otherwise" formula.
#
sub domain {
  my $self = shift;
  return $self->domainR if defined $self->{otherwise};
  return $self->domainUnion->reduce;
}

#
#  The set (-inf,inf).
#
sub domainR {
  my $self = shift; my $context = $self->context;
  my $Infinity = $context->Package("Infinity")->new($context);
  return $context->Package("Interval")->make($context,'(',-$Infinity,$Infinity,')');
}

#
#  The domain formed by the explicitly given intervals
#  (excludes the "otherwise" portion, if any)
#
sub domainUnion {
  my $self = shift; my $context = $self->context;
  my @cases = (); foreach my $If (@{$self->{data}}) {push(@cases,$If->[0])}
  return $context->Package("Union")->make($context,@cases);
}

#
#  Creates a copy of the PiecewiseFunction where the "otherwise"
#  formula has been given explicit intervals within the object.
#  (This makes it easier to compare two PiecewiseFormulas
#  interval by interval.)
#
sub noOtherwise {
  my $self = (shift)->copy; my $context = $self->context;
  return $self unless defined $self->{otherwise};
  my $otherwise = $self->domainR - $self->domainUnion->reduce;
  return $self if $otherwise->isEmpty;
  $otherwise = $context->Package("Union")->new($context,$otherwise) unless $otherwise->type eq 'Union';
  foreach my $I ($otherwise->value) {
    my $D = $context->Package("Inequality")->new($context,$I,$self->{varName});
    push(@{$self->{data}},[$D,$self->{otherwise}]);
  }
  delete $self->{otherwise};
  foreach my $If (@{$self->{data}}) {$If->[0]{equation} = $If->[1]{equation} = $self}
  return $self;
}

#
#  Look up the function for the nth branch (or the "otherwise"
#  function if n is omitted or too big or too small).
#
sub getFunction {
  my $self = shift; my $n = shift;
  return $self->{otherwise} if !defined $n || $n < 1 || $n > $self->length;
  return $self->{data}[$n-1][1];
}

#
#  Look up the domain for the nth branch (or the "otherwise"
#  domain if n is omitted or too big or too small).
#
sub getDomain {
  my $self = shift; my $n = shift;
  return $self->Package("Inequality")->new($self->context,
    $self->domainR - $self->domainUnion,$self->{varName})
       if !defined $n || $n < 1 || $n > $self->length;
  return $self->{data}[$n-1][0];
}

#
#  Get the function for the given value of the variable
#  (or undef if there is none).
#
sub getFunctionFor {
  my $self = shift; my $x = shift;
  foreach my $If (@{$self->{data}}) {
    my ($I,$f) = @$If;
    return $f if $I->contains($x);
  }
  return $self->{otherwise};
}

#
#  Implements the <=> operator (really only handles equality ir not)
#
sub compare {
  my ($l,$r,$flag) = @_; my $self = $l;
  my $context = $self->context; my $result;
  $r = $context->Package("PiecewiseFunction")->new($context,$r) unless Value::classMatch($r,"PiecewiseFunction");
  Value::Error("Formulas from different contexts can't be compared")
    unless $l->{context} == $r->{context};
  $l = $l->noOtherwise; $r = $r->noOtherwise;
  $result = $l->compareDomains($r); return $result if $result;
  $result = $l->compareFormulas($r); return $result if $result;
  return 0;
}

#
#  Check that the function domains have the same number of
#  components, and that those components agree, interval by interval.
#
sub compareDomains {
  my $self = shift; my $other = shift;
  my @D0 = $self->domainUnion->sort->value;
  my @D1 = $other->domainUnion->sort->value;
  return scalar(@D0) <=> scalar(@D1) unless scalar(@D0) == scalar(@D1);
  foreach my $i (0..$#D0) {
    my $result = ($D0[$i] <=> $D1[$i]);
    return $result if $result;
  }
  return 0;
}

#
#  Now that the intervals are known to agree, compare
#  the individual functions on each interval.  Do an
#  appropriate check depending on the type of each
#  branch:  Interval, Set, or Union.
#
sub compareFormulas {
  my $self = shift; my $other = shift;
  my @D0 = main::PGsort(sub {$_[0][0] < $_[1][0]}, $self->value);
  my @D1 = main::PGsort(sub {$_[0][0] < $_[1][0]}, $other->value);
  foreach my $i (0..$#D0) {
    my ($D,$f0,$f1) = (@{$D0[$i]},$D1[$i][1]);
    my $method = "compare".$D->type;
    my $result = $self->$method($D,$f0,$f1);
    return $result if $result;
  }
  return 0;
}

#
#  Use the Interval to determine the limits for use
#  in comparing the two functions.
#
sub compareInterval {
  my $self = shift; my ($D,$f0,$f1) = @_;
  my ($a,$b) = $D->value; $a = $a->value; $b = $b->value;
  return $f0 == $f1 if $D->{leftInfinite} && $D->{rightInfinite};
  $a = $b - 2 if $D->{leftInfinite};
  $b = $a + 2 if $D->{rightInfinite};
  return $f0->with(limits=>[$a,$b]) <=> $f1;
}

#
#  For a set, check that the functions agree on every point.
#
sub compareSet {
  my $self = shift; my ($D,$f0,$f1) = @_;
  my $x = $self->{varName};
  foreach my $a ($self->value) {
    my $result = $f0->eval($x=>$a) <=> $f1->eval($x=>$a);
    return $result if $result;
  }
  return 0;
}

#
#  For a union, do the appropriate check for
#  each object in the union.
#
sub compareUnion {
  my $self = shift; my ($D,$f0,$f1) = @_;
  foreach my $S ($self->value) {
    my $method = "compare".$S->type;
    my $result = $self->$method($D,$f0,$f1);
    return $result if $result;
  }
  return 0;
}


#
#  Stringify using newlines at after each "else".
#  (Otherwise the student and correct answer can
#  get unacceptably long.)
#
sub string {
  my $self = shift; my @cases = ();
  my $period = ($self->{final_period} ? "." : "");
  foreach my $If (@{$self->{data}}) {
    my ($I,$f) = @{$If};
    push(@cases,$f->string." if ".$I->string);
  }
  push(@cases,$self->{otherwise}->string) if defined $self->{otherwise};
  join(" else\n",@cases) . $period;
}

#
#  TeXify using a "cases" LaTeX environment.
#
sub TeX {
  my $self = shift; my @cases = ();
  my $period = ($self->{final_period} ? "." : "");
  foreach my $If (@{$self->{data}}) {
    my ($I,$f) = @{$If};
    push(@cases,'\displaystyle{'.$f->TeX."}&\\text{if}\\ ".$I->TeX);
  }
  if (scalar(@cases)) {
    push(@cases,'\displaystyle{'.$self->{otherwise}->TeX.'}&\text{otherwise}') if defined $self->{otherwise};
    return '\begin{cases}'.join('\cr'."\n",@cases).$period.'\end{cases}';
  } else {
    return $self->{otherwise}->TeX;
  }
}

#
#  Create a code segment that returns the correct value depending on which
#  interval contains the variable's value (or an undefined value).
#
sub perl {
  my $self = shift; my $x = "\$".$self->{varName};
  my @cases = ();
  foreach my $If (@{$self->{data}}) {
    my ($I,$f) = @{$If};
    push(@cases,'return '.$f->perl.' if '.$I->perl.'->contains('.$x.');');
  }
  if (defined($self->{otherwise})) {push(@cases,'return '.$self->{otherwise}->perl.';')}
                              else {push(@cases,'die "undefined value";')}
  return join("\n",@cases);
}


#
#  Handle the types correctly for error messages and such.
#
sub class {"PiecewiseFunction"}
sub showClass {
  my $self = shift;
  my $f = $self->{data}[0][1]; $f = $self->{otherwise} unless defined $f;
  'a Formula that returns '.Value::showType($f->{tree});
}

sub type {(shift)->{typeRef}{name}}
sub typeRef {(shift)->{typeRef}}

#
#  Allow comparison only when the two functions return
#  the same type of result.
#
sub typeMatch {
  my $self = shift; my $other = shift; my $ans = shift;
  return $self->type eq $other->type;
}

##################################################
#
#  Overrides the Formula() command so that if
#  the result is a PiecewiseFunction, it is
#  turned into one automatically.  Conversely,
#  if a PiecewiseFunction is put into Formula(),
#  this will turn it into a Formula.
#
package PiecewiseFunction::Formula;
our @ISA = ('Value::Formula');

sub new {
  my $self = shift; my $f;
  if (scalar(@_) == 1 && Value::classMatch($_[0],"PiecewiseFunction")) {
    $f = $_[0]->string; $f =~ s/\n/ /g;
    $f = $self->Package("Formula")->new($f);
  } else {
    $f = $self->Package("Formula")->new(@_);
    $f = $f->{tree}->Compute if $f->{tree}{canCompute};
  }
  return $f;
}

######################################################################

1;
