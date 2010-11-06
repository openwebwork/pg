################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/contextInequalities.pl,v 1.23 2010/03/22 11:01:55 dpvc Exp $
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

Context("Inequalities"), Context("Inequalities-Only") - Provides contexts that
allow intervals to be specified as inequalities.

=head1 DESCRIPTION

Implements contexts that provides for inequalities that produce
the cooresponding Interval, Set or Union MathObjects.  There are
two such contexts:  Context("Inequalities"), in which both
intervals and inequalities are defined, and Context("Inequalities-Only"),
which allows only inequalities as a means of producing intervals.

=head1 USAGE

	loadMacros("contextInequalities.pl");
	
	Context("Inequalities");
	$S1 = Compute("1 < x <= 4");
	$S2 = Inequality("(1,4]");     # force interval to be inequality
	
	Context("Inequalities-Only");
	$S1 = Compute("1 < x <= 4");
	$S2 = Inequality("(1,4]");     # generates an error
	
	$S3 = Compute("x < -2 or x > 2");  # forms the Union (-inf,-2) U (2,inf)
	$S4 = Compute("x > 2 and x <= 4"); # forms the Interval (2,4]
	$S5 = Compute("x = 1");            # forms the Set
	$S6 = Compute("x != 1");           # forms the Union (-inf,1) U (1,inf)

You can set the "noneWord" flag to specify the string to
use when the inequalities specify the empty set.  By default,
it is "NONE", but you can change it to other strings.  Be sure
that you use a string that is defined in the Context, however,
if you expect the student to be able to enter it.  For example

	Context("Inequalities");
	Context()->constants->add(EmptySet => Set());
	Context()->flags->set(noneWord=>"EmptySet");

creates an empty set as a named constant and uses that name.

In addition to the noneWord flag, the inequality contexts accept the
following additional flags:

=over

=item S<C<< showNotEquals >>>

This controls whether intervals of the form (-inf,a) U (a,inf) are
displayed as x != a or not.  The default is 1, meaning convert to
x != a.

=item S<C<< allowSloppyInequalities >>>

This controls whether <= and >= can also be represented by =< and =>
or not.  By default, both forms are allowed, to allow maximum
flexibility in student answers, but if set to 0, only the first forms
are allowed.

=back

Inequalities and interval notation both can coexist side by
side, but you may wish to convert from one to the other.
Use Inequality() to convert from an Interval, Set or Union
to an Inequality, and use Interval(), Set(), or Union() to
convert from an Inequality object to one in interval notation.
For example:

	$I0 = Compute("(1,2]");            # the interval (1,2]
	$I1 = Inequality($I1);             # the inequality 1 < x <= 2
	
	$I0 = Compute("1 < x <= 2");       # the inequality 1 < x <= 2
	$I1 = Interval($I0);               # the interval (1,2]

Note that ineqaulities and inervals can be compared and combined
regardless of the format, so $I0 == $I1 is true in either example
above.

Since Inequality objects are actually Interval objects, the variable
used to create them doesn't matter.  That is,

	$I0 = Compute("1 < x <= 2");
	$I1 = Compute("1 < y <= 2");

would both produce the same interval, so $I0 == $I1 would be true in
this case.  If you need to distinguish between these two, use

	$I0 == $I1 && $I0->{varName} eq $I1->{varName}

instead.

=cut

loadMacros("MathObjects.pl");

sub _contextInequalities_init {Inequalities::Init()}

package Inequalities;

#
#  Sets up the two inequality contexts
#
sub Init {
  my $context = $main::context{Inequalities} = Parser::Context->getCopy("Interval");
  $context->{name} = "Inequalities";
  $context->operators->add(
     '<'  => {precedence => .5, associativity => 'left', type => 'bin', string => ' < ',
              class => 'Inequalities::BOP::inequality', eval => 'evalLessThan', combine => 1},

     '>'  => {precedence => .5, associativity => 'left', type => 'bin', string => ' > ',
              class => 'Inequalities::BOP::inequality', eval => 'evalGreaterThan', combine => 1},

     '<=' => {precedence => .5, associativity => 'left', type => 'bin', string => ' <= ', TeX => '\le ',
              class => 'Inequalities::BOP::inequality', eval => 'evalLessThanOrEqualTo', combine => 1},
     '=<' => {precedence => .5, associativity => 'left', type => 'bin', string => ' <= ', TeX => '\le ',
              class => 'Inequalities::BOP::inequality', eval => 'evalLessThanOrEqualTo', combine => 1,
              isSloppy => "<="},

     '>=' => {precedence => .5, associativity => 'left', type => 'bin', string => ' >= ', TeX => '\ge ',
              class => 'Inequalities::BOP::inequality', eval => 'evalGreaterThanOrEqualTo', combine => 1},
     '=>' => {precedence => .5, associativity => 'left', type => 'bin', string => ' >= ', TeX => '\ge ',
              class => 'Inequalities::BOP::inequality', eval => 'evalGreaterThanOrEqualTo', combine => 1,
              isSloppy => ">="},

     '='  => {precedence => .5, associativity => 'left', type => 'bin', string => ' = ',
              class => 'Inequalities::BOP::inequality', eval => 'evalEqualTo'},

     '!=' => {precedence => .5, associativity => 'left', type => 'bin', string => ' != ', TeX => '\ne ',
              class => 'Inequalities::BOP::inequality', eval => 'evalNotEqualTo'},

     'and' => {precedence => .45, associateivity => 'left', type => 'bin', string => " and ",
	       TeX => '\hbox{ and }', class => 'Inequalities::BOP::and'},

     'or' => {precedence => .4, associateivity => 'left', type => 'bin', string => " or ",
	      TeX => '\hbox{ or }', class => 'Inequalities::BOP::or'},
  );
  $context->operators->set(
     '+' => {class => "Inequalities::BOP::add"},
     '-' => {class => "Inequalities::BOP::subtract"},
  );
  $context->parens->set("(" => {type => "List", formInterval => ']'});  # trap these later
  $context->parens->set("[" => {type => "List", formInterval => ')'});  # trap these later
  $context->strings->remove("NONE");
  $context->constants->add(NONE=>Value::Set->new());
  $context->flags->set(
     noneWord => 'NONE',
     showNotEquals => 1,            # display (-inf,a) U (a,inf) as x != a
     allowSloppyInequalities => 1,  # allow =< and => as equivalent to <= and >=
  );
  $context->{parser}{Variable} = "Inequalities::Variable";
  $context->{value}{'Interval()'} = "Inequalities::MakeInterval";
  $context->{value}{Inequality} = "Inequalities::Inequality";
  $context->{value}{InequalityInterval} = "Inequalities::Interval";
  $context->{value}{InequalityUnion} = "Inequalities::Union";
  $context->{value}{InequalitySet} = "Inequalities::Set";
  $context->{value}{List} = "Inequalities::List";
  $context->{precedence}{Inequality} = $context->{precedence}{special};
  $context->lists->set(List => {class => 'Inequalities::List::List'});

  #
  #  Disable interval notation in "Inequalities-Only" context
  #
  $context = $main::context{"Inequalities-Only"} = $context->copy;
  $context->lists->set(
    Interval => {class => 'Inequalities::List::notAllowed'},
    Set      => {class => 'Inequalities::List::notAllowed'},
    Union    => {class => 'Inequalities::List::notAllowed'},
  );
  $context->operators->set('U' => {class => 'Inequalities::BOP::union'});
  $context->constants->remove('R');

  #
  #  Define the Inequality() constructor
  #
  main::PG_restricted_eval('sub Inequality {Value->Package("Inequality")->new(@_)}');
}


##################################################
#
#  General BOP that handles the inequalities.
#  The difference comes in the _eval() method,
#  which tells what each computes.
#
package Inequalities::BOP::inequality;
our @ISA = ("Parser::BOP");

#
#  Check that the inequality is formed between a variable and a number,
#  or between a number and another compatible inequality.  Otherwise,
#  give an error.
#
#  varPos and numPos tell which of lop or rop is the variable and which
#  the number.  varName is the variable involved in the inequality.
#
sub _check {
  my $self = shift;
  $self->Error("'%s' should be written '%s'",$self->{bop},$self->{def}{isSloppy})
    if (!$self->context->flag("allowSloppyInequalities") && $self->{def}{isSloppy});
  $self->{type} = $Value::Type{interval};
  $self->{isInequality} = 1;
  ($self->{varPos},$self->{numPos}) =
    ($self->{lop}->class eq 'Variable' || $self->{lop}{isInequality} ? ('lop','rop') : ('rop','lop'));
  my ($v,$n) = ($self->{$self->{varPos}},$self->{$self->{numPos}});
  if (($n->isNumber || $n->{isInfinite}) && ($n->{isConstant} || scalar(keys %{$n->getVariables}) == 0)) {
    if ($v->class eq 'Variable') {
      $self->{varName} = $v->{name};
      delete $self->{equation}{variables}{$v->{name}} if $v->{isNew};
      $self->{$self->{varPos}} = Inequalities::DummyVariable->new($self->{equation},$v->{name},$v->{ref});
      return;
    }
    if ($self->{def}{combine} && $v->{isInequality}) {
      my $bop = $self->{bop}; $bop =~ s/=//; my $bope = $bop."="; my $ebop = "=".$bop;
      if (($v->{bop} eq $bop || $v->{bop} eq $bope || $v->{bop} eq $ebop) && $v->{varPos} eq $self->{numPos}) {
	$self->{varName} = $v->{varName};
	return;
      }
    }
  }
  $self->Error("'%s' should have a variable on one side and a number on the other",$self->{bop})
    unless $v->{isInequality} && $v->{varPos} eq $self->{numPos};
  $self->Error("'%s' can't be combined with '%s'",$v->{bop},$self->{bop});
}

#
#  Generate the interval for the given type of inequality.
#  If it is a combined inequality, intersect with the other
#  one to get the final set.
#
sub _eval {
  my $self = shift; my ($a,$b) = @_;
  my $eval = $self->{def}{eval};
  my $I = $self->Package("Inequality")->new($self->context,$self->$eval(@_),$self->{varName});
  return $I->intersect($a) if Value::isValue($a) && $a->type eq 'Interval';
  return $I->intersect($b) if Value::isValue($b) && $b->type eq 'Interval';
  return $I;
}

sub evalLessThan {
  my ($self,$a,$b) = @_; my $context = $self->context;
  my $I = Value::Infinity->new($context);
  return $self->Package("Interval")->new($context,'(',-$I,$b,')') if $self->{varPos} eq 'lop';
  return $self->Package("Interval")->new($context,'(',$a,$I,')');
}

sub evalGreaterThan {
  my ($self,$a,$b) = @_; my $context = $self->context;
  my $I = Value::Infinity->new;
  return $self->Package("Interval")->new($context,'(',$b,$I,')')->with(reversed=>1) if $self->{varPos} eq 'lop';
  return $self->Package("Interval")->new($context,'(',-$I,$a,')')->with(reversed=>1);
}

sub evalLessThanOrEqualTo {
  my ($self,$a,$b) = @_; my $context = $self->context;
  my $I = Value::Infinity->new;
  return $self->Package("Interval")->new($context,'(',-$I,$b,']') if $self->{varPos} eq 'lop';
  return $self->Package("Interval")->new($context,'[',$a,$I,')');
}

sub evalGreaterThanOrEqualTo {
  my ($self,$a,$b) = @_; my $context = $self->context;
  my $I = Value::Infinity->new;
  return $self->Package("Interval")->new($context,'[',$b,$I,')')->with(reversed=>1) if $self->{varPos} eq 'lop';
  return $self->Package("Interval")->new($context,'(',-$I,$a,']')->with(reversed=>1);
}

sub evalEqualTo {
  my ($self,$a,$b) = @_; my $context = $self->context;
  my $x = ($self->{varPos} eq 'lop' ? $b : $a);
  return $self->Package("Set")->new($context,$x);
}

sub evalNotEqualTo {
  my ($self,$a,$b) = @_; my $context = $self->context;
  my $x = ($self->{varPos} eq 'lop' ? $b : $a);
  my $I = Value::Infinity->new;
  return $self->Package("Union")->new($context,
            $self->Package("Interval")->new($context,'(',-$I,$x,')'),
            $self->Package("Interval")->new($context,'(',$x,$I,')')
         )->with(notEqual=>1);
}

#
#  Inequalities have dummy variables that are not really
#  variables of a formula.

sub getVariables {{}}

#
#  Avoid unwanted parentheses from the standard routines.
#
sub string {
  my ($self,$precedence) = @_;
  my $string; my $bop = $self->{def};

  $string = $self->{lop}->string($bop->{precedence}).
            $bop->{string}.
            $self->{rop}->string($bop->{precedence});

  return $string;
}

sub TeX {
  my ($self,$precedence) = @_;
  my $TeX; my $bop = $self->{def};

  $TeX = $self->{lop}->TeX($bop->{precedence}).
         (defined($bop->{TeX}) ? $bop->{TeX} : $bop->{string}) .
         $self->{rop}->TeX($bop->{precedence});

  return $TeX;
}

##################################################
#
#  Implements the "and" operation as set intersection
#
package Inequalities::BOP::and;
our @ISA = ("Parser::BOP");

sub _check {
  my $self = shift;
  $self->Error("The operands of '%s' must be inequalities",$self->{bop})
    unless $self->{lop}{isInequality} && $self->{rop}{isInequality};
  $self->Error("Inequalities combined by '%s' must both use the same variable",$self->{bop})
    unless $self->{lop}{varName} eq $self->{rop}{varName};
  $self->{type} = Value::Type("Interval",2);
  $self->{varName} = $self->{lop}{varName};
  $self->{isInequality} = 1;
}

sub _eval {$_[1]->intersect($_[2])}

##################################################
#
#  Implements the "or" operation as set union
#
package Inequalities::BOP::or;
our @ISA = ("Parser::BOP");

sub _check {
  my $self = shift;
  $self->Error("The operands of '%s' must be inequalities",$self->{bop})
    unless $self->{lop}{isInequality} && $self->{rop}{isInequality};
  $self->Error("Inequalities combined by '%s' must both use the same variable",$self->{bop})
    unless $self->{lop}{varName} eq $self->{rop}{varName};
  $self->{type} = Value::Type("Interval",2);
  $self->{varName} = $self->{lop}{varName};
  $self->{isInequality} = 1;
}

sub _eval {$_[1] + $_[2]}

##################################################
#
#  Subclass of Parser::Variable that records whether
#  this variable has already been seen in the formula
#  (so that it can be removed from the formula's
#  variable list when used in an inequality.)
#
package Inequalities::Variable;
our @ISA = ("Parser::Variable");

sub new {
  my $self = shift; my $equation = shift; my $name = shift;
  my $isNew = !defined $equation->{variables}{$name};
  my $n = $self->SUPER::new($equation,$name,@_);
  $n->{isNew} = $isNew;
  return $n;
}

##################################################
#
#  A special class used for the variables in
#  inequalities, since they are not really
#  variables for the formula.  (They don't need
#  to be substituted or given values when the
#  formula is evaluated, and so on.)  These are
#  really just placeholders, here.
#
package Inequalities::DummyVariable;
our @ISA = ("Parser::Item");

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my ($equation,$name,$ref) = @_;
  my $def = $equation->{context}{variables}{$name};
  bless {name => $name, ref => $ref, def => $def, equation => $equation}, $class;
}

sub eval {shift};

sub string {(shift)->{name}}

sub TeX {
  my $self = shift; my $name = $self->{name};
  return $self->{def}{TeX} if defined $self->{def}{TeX};
  $name = $1.'_{'.$2.'}' if ($name =~ m/^([^_]+)_?(\d+)$/);
  return $name;
}

sub perl {
  my $self = shift;
  return $self->{def}{perl} if defined $self->{def}{perl};
  return '$'.$self->{name};
}

##################################################
#
#  Give an error when U is used.
#
package Inequalities::BOP::union;
our @ISA = ("Parser::BOP::union");

sub _check {
  my $self = shift;
  $self->Error("You can't take unions of inequalities")
    if $self->{lop}{isInequality} || $self->{rop}{isInequality};
  $self->SUPER::_check(@_);
  $self->Error("Unions are not allowed in this context");
}

##################################################
#
#  Don't allow sums and differences of inequalities
#
package Inequalities::BOP::add;
our @ISA = ("Parser::BOP::add");

sub _check {
  my $self = shift;
  $self->SUPER::_check(@_);
  $self->Error("Can't add inequalities (do you mean to use 'or'?)")
    if $self->{lop}{isInequality} || $self->{rop}{isInequality};
}

##################################################
#
#  Don't allow sums and differences of inequalities
#
package Inequalities::BOP::subtract;
our @ISA = ("Parser::BOP::subtract");

sub _check {
  my $self = shift;
  $self->SUPER::_check(@_);
  $self->Error("Can't subtract inequalities")
    if $self->{lop}{isInequality} || $self->{rop}{isInequality};
}

##################################################
#
#  For the Inequalities-Only context, report
#  an error for Intervals, Sets or Union notation.
#
package Inequalities::List::notAllowed;
our @ISA = ("Parser::List::List");

sub _check {(shift)->Error("You are not allowed to use intervals or sets in this context")}


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


##################################################

package Inequalities::Interval;
our @ISA = ("Inequalities::common", "Value::Interval");

sub type {"Interval"}

sub updateParts {
  my $self = shift;
  $self->{leftInfinite} = 1 if $self->{data}[0]->{isInfinite};
  $self->{rightInfinite} = 1 if $self->{data}[1]->{isInfinite};
}

sub string {
  my $self = shift;
  my ($a,$b,$open,$close) = $self->value;
  my $x = $self->{varName} || ($self->context->variables->names)[0];
  $x = $context->{variables}{$x}{string} if defined $context->{variables}{$x}{string};
  if ($self->{leftInfinite}) {
    return "-infinity < $x < infinity" if $self->{rightInfinite};
    return $b->string . ($close eq ')' ? ' > ' : ' >= ') . $x if $self->{reversed};
    return $x . ($close eq ')' ? ' < ' : ' <= ') . $b->string;
  } elsif ($self->{rightInfinite}) {
    return $x . ($open eq '(' ? ' > ' : ' >= ') . $a->string if $self->{reversed};
    return $a->string . ($open eq '(' ? ' < ' : ' <= ') . $x;
  } else {
    return $a->string . ($open  eq '(' ? ' < ' : ' <= ') .
                   $x . ($close eq ')' ? ' < ' : ' <= ') . $b->string;
  }
}

sub TeX {
  my $self = shift;
  my ($a,$b,$open,$close) = $self->value;
  my $context = $self->context;
  my $x = $self->{varName} || ($context->variables->names)[0];
  $x = $context->{variables}{$x}{TeX} if defined $context->{variables}{$x}{TeX};
  $x =~ s/^([^_]+)_?(\d+)$/$1_{$2}/;
  if ($self->{leftInfinite}) {
    return "-\\infty < $x < \\infty" if $self->{rightInfinite};
    return $b->TeX . ($close eq ')' ? ' > ' : ' \ge ') . $x if $self->{reversed};
    return $x . ($close eq ')' ? ' < ' : ' \le ') . $b->TeX;
  } elsif ($self->{rightInfinite}) {
    return $x . ($open eq '(' ? ' > ' : ' \ge ') . $a->TeX if $self->{reversed};
    return $a->TeX . ($open eq '(' ? ' < ' : ' \le ') . $x;
  } else {
    return $a->TeX . ($open  eq '(' ? ' < ' : ' \le ') .
                $x . ($close eq ')' ? ' < ' : ' \le ') . $b->TeX;
  }
}

##################################################

package Inequalities::Union;
our @ISA = ("Inequalities::common", "Value::Union");

sub type {"Union"}

#
#  Mark all the parts of the union as inequalities
#
sub updateParts {
  my $self = shift;
  foreach my $I (@{$self->{data}}) {
    $I->{varName} = $self->{varName};
    $I->{reduceSets} = $I->{"is".$I->type} = 1;
    bless $I, $self->Package("Inequality".$I->type);
    $I->updateParts;
  }
}

#
#  Update the intervals and sets when a new union is made
#
sub make {
  my $self = (shift)->SUPER::make(@_);
  $self->updateParts;
  return $self;
}

#
#  Demote all the items in the union
#
sub makeData {
  my $self = shift; my @U = ();
  foreach my $I (@{$self->{data}}) {push(@U,$I->demote)}
  return @U;
}

sub string {
  my $self = shift;
  my $equation = shift; shift; shift; my $prec = shift;
  return $self->display("string",$equation,$prec);
}

sub TeX {
  my $self = shift;
  my $equation = shift; shift; shift; my $prec = shift;
  return $self->display("TeX",$equation,$prec);
}

sub display {
  my $self = shift; my $method = shift; my $equation = shift; my $prec = shift;
  my $context = ($equation->{context} || $self->context);
  my $X = $self->{varName} || ($context->variables->names)[0];
  $X = $context->{variables}{$X}{$method} if defined $context->{variables}{$X}{$method};
  $X =~ s/^([^_]+)_?(\d+)$/$1_{$2}/ if $method eq 'TeX';
  my $op = $context->{operators}{'or'};
  my ($and,$or,$le,$ge,$ne,$open,$close) = @{{
    string => [' and ',$op->{string} || ' or ',' <= ',' >= ',' != ','(',')'],
    TeX =>    ['\hbox{ and }',$op->{TeX} || $op->{string} || '\hbox{ or }',
               ' \le ',' \ge ',' \ne ','\left(','\right)'],
  }->{$method}};
  my $showNE = $self->getFlag("showNotEquals",1);
  my @intervals = (); my @points = (); my $interval;
  foreach my $x (@{$self->data}) {
    $x->{format} = $self->{format} if defined $self->{format};
    if ($x->type eq 'Interval' && $showNE) {
      if (defined($interval)) {
	if ($interval->{data}[1] == $x->{data}[0]) {
	  push(@points,$X.$ne.$x->{data}[0]->$method($equation));
	  $interval = $interval->with(isCopy=>1, data=>[$interval->value]) unless $interval->{isCopy};
	  $interval->{data}[1] = $x->{data}[1];
	  $interval->{rightInfinite} = 1 if $x->{rightInfinite};
	  next;
	}
	push(@intervals,$self->joinAnd($interval,$method,$and,$equation,@points));
      }
      $interval = $x; @points = (); next;
    }
    if (defined($interval)) {
      push(@intervals,$self->joinAnd($interval,$method,$and,$equation,@points));
      $interval = undef; @points = ();
    }
    push(@intervals,$x->$method($equation));
  }
  push(@intervals,$self->joinAnd($interval,$method,$and,$equation,@points)) if defined($interval);
  my $string = join($or,@intervals);
  $string = $open.$string.$close if defined($prec) && $prec > ($op->{precedence} || 1.5);
  return $string;
}

sub joinAnd {
  my $self = shift; $interval = shift; $method = shift, my $and = shift; my $equation = shift;
  unshift(@_,$interval->$method($equation)) unless $interval->{leftInfinite} && $interval->{rightInfinite};
  return join($and, @_);
}

##################################################

package Inequalities::Set;
our @ISA = ("Inequalities::common", "Value::Set");

sub type {"Set"}

sub string {
  my $self = shift;  my $equation = shift;
  my $x = $self->{varName} || ($self->context->variables->names)[0];
  $x = $context->{variables}{$x}{string} if defined $context->{variables}{$x}{string};
  my @coords = ();
  foreach my $a (@{$self->data}) {
    if (Value::isValue($a)) {
      $a->{format} = $self->{format} if defined $self->{format};
      push(@coords,$x.' = '.$a->string($equation));
    } else {
      push(@coords,$x.' = '.$a);
    }
  }
  return $self->getFlag('noneWord') unless scalar(@coords);
  return join(" or ",@coords);
}

sub TeX {
  my $self = shift;  my $equation = shift;
  my $x = $self->{varName} || ($self->context->variables->names)[0];
  $x = $context->{variables}{$x}{TeX} if defined $context->{variables}{$x}{TeX};
  $x =~ s/^([^_]+)_?(\d+)$/$1_{$2}/;
  my @coords = ();
  foreach my $a (@{$self->data}) {
    if (Value::isValue($a)) {
      $a->{format} = $self->{format} if defined $self->{format};
      push(@coords,$x.' = '.$a->TeX($equation));
    } else {
      push(@coords,$x.' = '.$a);
    }
  }
  return '\hbox{'.$self->getFlag('noneWord').'}' unless scalar(@coords);
  return join('\hbox{ or }',@coords);
}

##################################################
#
#  A class for making inequalities by hand
#
package Inequalities::Inequality;
our @ISA = ('Value');

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $S = shift; my $x = shift;
  $S = Value::makeValue($S,context=>$context);
  if (Value::classMatch($S,"Inequality")) {
    if (defined($x)) {$S->{varName} = $x; $S->updateParts}
    return $S;
  }
  $x = ($context->variables->names)[0] unless $x;
  $S = bless $S->inContext($context), $context->Package("Inequality".$S->type);
  $S->{varName} = $x; $S->{reduceSets} = $S->{"is".$S->Type} = 1;
  $S->updateParts;
  return $S;
}

##################################################
#
#  Allow Interval() to coerce types to Value::Interval
#
package Inequalities::MakeInterval;
our @ISA = ("Value::Interval");

sub new {
  my $self = shift;
  $self = $self->SUPER::new(@_);
  $self = $self->demote if $self->classMatch("Inequality");
  return $self;
}

##################################################
#
#  Mark this as a list of inequalities (if it is)
#
package Inequalities::List;
our @ISA = ("Value::List");

sub new {
  my $self = (shift)->SUPER::new(@_);
  return $self unless $self->{type} =~ m/^(unknown|Interval|Set|Union)$/;
  foreach my $x (@{$self->{data}}) {return $self unless Value::classMatch($x,'Inequality')}
  $self->{type} = 'Inequality';
  return $self;
}

package Inequalities::List::List;
our @ISA = ("Parser::List::List");

sub _check {
  my $self = shift; $self->SUPER::_check(@_);
  if ($self->canBeInUnion) {
    #
    #  Convert lists that look like intervals into intervals
    #  and then check if they are OK.
    #
    bless $self, $self->context->{lists}{Interval}{class};
    $self->{type} = $Value::Type{interval};
    $self->{parens} = $self->context->{parens}{interval};
    $self->_check;
  } else {
    my $entryType = $self->typeRef->{entryType};
    return unless $entryType->{name} =~ m/^(unknown|Interval|Set|Union)$/;
    foreach my $x (@{$self->{coords}}) {return unless $x->{isInequality}};
    $entryType->{name} = "Inequality";
  }
}

##################################################

1;
