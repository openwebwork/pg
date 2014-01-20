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

parserAssignment.pl - Implements assignments to variables

=head1 DESCRIPTION

This file implements an assignment operator that allows only a single
variable reference on the left and any value on the right.  You can use
this to require students to enter things like

	y = 3x + 1

rather than making the "y = " part of the text of the question.  This
also allows you to ask for lists of assignments more easily.

To use it, load the macro file, select the Context you want to use,
add any variables you may need, and enable the assignment operator as
in the following example:

	loadMacros(
	  "PGstandard.pl",
	  "MathObjects.pl",
	  "parserAssignment.pl",
	);

	Context("Numeric")->variables->add(y=>'Real');
	parser::Assignment->Allow;

Now you can use the equal sign in Formula() objects to create assignments.

	$f = Formula("y = 3x + 1");
	...
	ANS($f->cmp);

The student will have to make an assignment to the same variable in
order to get credit.  For example, he or she could enter y = 1+3x to get
credit for the answer above.

The left-hand side of an assignment must be a single variable, so

	$f = Formula("3y = 2x");

will produce an error.  The right-hand side can not include the
variable being assigned on the left, so

	$f = Formula("x = 2x+1");

also is not allowed.

You can produce lists of assignments just as easily:

	$f = Formula("y = 3x, y = 2x-1");

and the assignment can be of any type of MathObject.  For example:

	Context("Vector")->variables->add(p=>'Vector3D');
	parser::Assignment->Allow;

	$f = Formula("p = <1,2x,1-x>");

To produce a constant assignment, use Compute(), as in:

	$p = Compute("p = <1,2,3>");

(in fact, Compute() could be used for in place of Formula() in the
examples above as well, since it returns a Formula when the value is
one).

The left-hand side of an assignment can also be a function
declaration, as in

	f(x) = 3x + 1

To allow this, use

	parser::Assignment->Function("f");

You can supply more than one function name if you want.  E.g.,

	parser::Assignment->Function("f","g");

The number of variables for these functions is determined by the
assignment itself, so after declaring f to be a function, you can use
either

	f(x) = x+1
or
	f(x,y) = x^2 + y^2

provided the variables are defined in the current context.

Type-checking between the student and correct answers is performed
using the right-hand values of the assignment, and a warning message
will be issued if the types are not compatible.  The type of the
variable on the left-hand side, however, is not checked.

For function declarations, the name of the function and the order
of the variables must match the professor's answer; however, the
names of the variables don't have to match, as long as the function
returns the same results for the same inputs.  So

	f(x) = x + 1
and
	f(y) = y + 1

will be marked as equal.

=cut

#
#  FIXME:  allow any variables in declaration
#  FIXME:  Add more hints when variable name isn't right
#          or function name or number of arguments isn't right.
#

sub _parserAssignment_init {parser::Assignment::Init()}

######################################################################

package parser::Assignment;
our @ISA = qw(Parser::BOP);

sub Init {
  main::PG_restricted_eval('sub Assignment {parser::Assignment::List->new(@_)}');
}

#
#  Check that the left operand is a variable and not used on the right
#
sub _check {
  my $self = shift; my $name = $self->{def}{string} || $self->{bop};
  $self->Error("Only one assignment is allowed in an equation")
    if $self->{lop}->type eq 'Assignment' || $self->{rop}->type eq 'Assignment';
  $self->Error("The left side of an assignment must be a variable or function",$name)
    unless $self->{lop}->class eq 'Variable' || $self->{lop}{isDummy} || $self->context->flag("allowBadOperands");
  if ($self->{lop}{isDummy}) {
    my $fvars = $self->{lop}->getVariables;
    foreach my $x (keys(%{$self->{rop}->getVariables})) {
      $self->Error("The formula for %s can't use the variable '%s'",$self->{lop}->string,$x)
	unless $fvars->{$x};
    }
  } else {
    $self->Error("The right side of an assignment must not include the variable being defined")
      if $self->{rop}->getVariables->{$self->{lop}{name}};
    delete $self->{equation}{variables}{$self->{lop}{name}};
  }
  $self->{type} = Value::Type('Assignment',2,$self->{rop}->typeRef,list => 1);
}

#
#  Convert to an Assignment object
#
sub eval {
  my $self = shift; my $context = $self->context;
  my ($a,$b) = ($self->Package("String")->make($context,$self->{lop}->string),$self->{rop});
  $b = Value::makeValue($b->eval,context => $context);
  return parser::Assignment::List->make($context,$a,$b);
}

#
#  Don't count the left-hand variable
#
sub getVariables {
  my $self = shift;
  return $self->{lop}->getVariables if $self->{lop}{isDummy};
  $self->{rop}->getVariables;
}

#
#  Create an Assignment object
#
sub perl {
  my $self = shift;
  return "parser::Assignment::List->new('".$self->{lop}->string."',".$self->{rop}->perl.")";
}

#
#  Add/Remove the Assignment operator to/from a context
#
sub Allow {
  my $self = shift || "Value"; my $context = shift || $self->context;
  my $allow = shift; $allow = 1 unless defined($allow);
  if ($allow) {
    my $prec = $context->{operators}{','}{precedence};
    $prec = 1 unless defined($prec);
    $context->operators->add(
      '=' => {
         class => 'parser::Assignment',
         precedence => $prec+.25,  #  just above comma
         associativity => 'left',  #  computed left to right
         type => 'bin',            #  binary operator
         string => ' = ',          #  output string for it
      }
    );
    $context->{value}{Formula} = 'parser::Assignment::Formula';
    $context->{value}{Assignment} = 'parser::Assignment::List';
  } else {$context->operators->remove('=')}
  return;
}

sub Function {
  my $self = shift || "Value";
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  Value->Error("You must provide a function name") unless scalar(@_) > 0;
  foreach my $f (@_) {
    Value->Error("Function name '%s' is illegal",$f) unless $f =~ m/^[a-z][a-z0-9]*$/i;
    my $name = $f; $name = $1.'_{'.$2.'}' if ($name =~ m/^(\D+)(\d+)$/);
    $context->functions->add(
      $f => {class => 'parser::Assignment::Function', TeX => $name, type => $Value::Type{number}}
    );
  }
}

######################################################################

#
#  A special List object that holds a variable and a value, and
#  that prints with an equal sign.
#

package parser::Assignment::List;
our @ISA = ("Value::List");

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  Value->Error("Too many arguments") if scalar(@_) > 2;
  my ($x,$v) = @_;
  if (defined($v)) {
    my $context = $self->context;
    $v = Value::makeValue($v,context=>$context);
    if ($v->isFormula) {
      $x = $self->Package("Formula")->new($context,$x);
      $v->{tree} = parser::Assignment->new($v,"=",$x->{tree},$v->{tree});
      bless $v, $self->Package("Formula");
      return $v;
    }
    return $self->make($self->Package("String")->make($context,$x),$v);
  } else {
    $v = $self->Package("Formula")->new($x);
    Value->Error("Your formula doesn't seem to be an assignment")
	unless $v->{tree}->type eq "Assignment";
    return $v;
  }
}

sub string {
  my $self = shift; my ($x,$v) = $self->value;
  $x->string . ' = ' . $v->string;
}

sub TeX {
  my $self = shift; my ($x,$v) = $self->value;
  $x = $self->Package("Formula")->new($x->{data}[0]);
  $x->TeX . ' = ' . $v->TeX;
}

#
#  Needed since these are called explicitly without an object
#
sub cmp_defaults {
  my $self = shift;
  $self->SUPER::cmp_defaults(@_);
}

#
#  Class is an a variable assigned to whatever
#
sub cmp_class {
  my $self = shift;
  my $type = ($self->{data}[0] =~ m/\(/ ? 'Function' : 'Variable');
  "a $type equal to ".$self->{data}[1]->showClass;
}
sub showClass {cmp_class(@_)}

#
#  Return the proper type
#
sub typeRef {
  my $self = shift;
  Value::Type('Assignment',2,$self->{data}[1]->typeRef,list=>1);
}

######################################################################

#
#  A subclass of Formula that does typematching properly for Assignments
#  (the match is against the right-hand sides)
#

package parser::Assignment::Formula;
our @ISA = ("Value::Formula");

sub new {
  my $self = shift; $class = ref($self) || $self;
  my $f = $self->SUPER::new(@_);
  bless $f, $class if $f->type eq 'Assignment';
  return $f;
}

sub typeMatch {
  my $self = shift; my $other = shift; my $ans = shift;
  return 0 unless $self->type eq $other->type;
  $other = $other->Package("Formula")->new($self->context,$other) unless $other->isFormula;
  my $typeMatch = ($self->createRandomPoints(1))[1]->[0]{data}[1];
  $main::__other__ = sub {($other->createRandomPoints(1))[1]->[0]{data}[1]};
  $other = main::PG_restricted_eval('&$__other__()');
  delete $main::{__other__};
  return 1 unless defined($other); # can't really tell, so don't report type mismatch
  $typeMatch->typeMatch($other,$ans);
}

sub cmp_class {
  my $self = shift; my $value;
  if ($self->{tree}{rop}{isConstant}) {
    $value = ($self->createRandomPoints(1))[1]->[0]{data}[1];
  } else {
    $value = $self->Package("Formula")->new($self->context,$self->{tree}{rop});
  }
  my $type = ($self->{tree}{lop}{isDummy} ? "Function" : "Variable");
  return "a $type equal to ".$value->showClass;
}
sub showClass {cmp_class(@_)}

#
#  Convert varaible names to those used in the correct answer, if the
#  student answer uses different ones
#
sub compare {
  my ($l,$r) = @_; my $self = $l;
  my $context = $self->context;
  $r = $context->Package("Formula")->new($context,$r) unless Value::isFormula($r);
  if ($l->{tree}{lop}{isDummy} && $r->type eq 'Assignment' && $r->{tree}{lop}{isDummy}) {
    my ($F,$f) = ($l->{tree}{lop}{params},$r->{tree}{lop}{params});
    if (scalar(@{$F}) == scalar(@{$f})) {
      my @subs = ();
      for (my $i = 0; $i < scalar(@{$F}); $i++) {
	push(@subs,$f->[$i]{name} => $F->[$i]{name})
	  unless $F->[$i]{name} eq $f->[$i]{name};
      }
      $r = $r->substitute(@subs) if scalar(@subs);
      delete $r->{f};
    }
  }
  $l->SUPER::compare($r,@_);
}

######################################################################

#
#  A dummy function that is used for assignments like f(x) = x^2
#

package parser::Assignment::Function;
our @ISA = ("Parser::Function");

sub _check {
  my $self = shift; my %var;
  foreach my $x (@{$self->{params}}) {
    $self->Error("The arguments of '%s' must be variables",$self->{name})
      unless $x->class eq 'Variable';
    $self->Error("The arguments of '%s' must all be different",$self->{name})
      if $var{$x->{name}};
    $var{$x->{name}} = 1;
  }
  $self->{type} = $self->{def}{type};
  $self->{isDummy} = 1;
}

sub eval {
  my $self = shift;
  $self->Error("Dummy function '%s' can not be evaluated",$self->{name});
}

sub call {
  my $self = shift;
  $self->Error("Dummy function '%s' can not be called",$self->{name});
}

1;
