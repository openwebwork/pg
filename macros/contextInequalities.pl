
=pod

#########################################################################
#
#  Implements contexts that provides for inequalities that produce
#  the cooresponding Interval, Set or Union MathObjects.  There are
#  two such contexts:  Context("Inequalities"), in which both
#  intervals and inequalities are defined, and Context("Inequalities-Only"),
#  which allows only inequalities as a means of producing intervals.
#
#  Usage:    loadMacros("contextInequalities.pl");
#
#            Context("Inequalities");
#            $S1 = Formula("1 < x <= 4");
#            $S2 = Formula("(1,4]");        # either form is OK
#
#            Context("Inequalities-Only");
#            $S1 = Formula("1 < x <= 4");
#            $S2 = Formula("(1,4]");        # generates an error
#
#            $S3 = Formula("x < -2 or x > 2");  # forms a Union
#            $S4 = Formula("x = 1");            # forms a Set
#
#  You can set the "stringifyAsInequalities" flag to 1 to force
#  output from the intervals, sets, and unions created in this
#  context to be output as inequalities rather than their
#  usual Inerval, Set or Union forms.
#
#     Context("Inequalities")->flags->set(stringifyAsInequalities=>1);
#
#  You can also set the "noneWord" flag to specify the string to
#  use when the inequalities specify the empty set.  By default,
#  it is "NONE", but you can change it to other strings.  Be sure
#  that you use a string that is defined in the Context, however,
#  if you expect the student to be able to enter it.  For example
#
#    Context("Inequalities");
#    Context()->constants->add(EmptySet => Set());
#    Context()->flags->set(noneWord=>"EmptySet");
#
#  creates an empty set as a named constant and uses that name.
#

=cut

loadMacros("MathObjects.pl");

sub _contextInequalities_init {Inequalities::Init()}

##################################################

package Inequalities;

#
#  Sets up the two inequality contexts
#
sub Init {
  my $context = $main::context{Inequalities} = Parser::Context->getCopy("Interval");
  $context->operators->add(
     '<'  => {precedence => .5, associativity => 'left', type => 'bin', string => ' < ',
              class => 'Inequalities::BOP::inequality', eval => 'evalLessThan', combine => 1},

     '>'  => {precedence => .5, associativity => 'left', type => 'bin', string => ' > ',
              class => 'Inequalities::BOP::inequality', eval => 'evalGreaterThan', combine => 1},

     '<=' => {precedence => .5, associativity => 'left', type => 'bin', string => ' <= ',
              class => 'Inequalities::BOP::inequality', eval => 'evalLessThanOrEqualTo', combine => 1},

     '>=' => {precedence => .5, associativity => 'left', type => 'bin', string => ' >= ',
              class => 'Inequalities::BOP::inequality', eval => 'evalGreaterThanOrEqualTo', combine => 1},

     '='  => {precedence => .5, associativity => 'left', type => 'bin', string => ' = ',
              class => 'Inequalities::BOP::inequality', eval => 'evalEqualTo'},

     '!=' => {precedence => .5, associativity => 'left', type => 'bin', string => ' != ',
              class => 'Inequalities::BOP::inequality', eval => 'evalNotEqualTo'},

     'and' => {precedence => .45, associateivity => 'left', type => 'bin', string => " and ",
	       TeX => '\hbox{ and }', class => 'Inequalities::BOP::and'},

     'or' => {precedence => .4, associateivity => 'left', type => 'bin', string => " or ",
	      TeX => '\hbox{ or }', class => 'Inequalities::BOP::or'},
  );
  $context->flags->set(stringifyAsInequalities => 0, noneWord => 'NONE');
  $context->strings->remove("NONE");
  $context->constants->add(NONE=>Value::Set->new());
  $context->{parser}{Variable} = "Inequalities::Variable";
  $context->{value}{Interval} = "Inequalities::Interval";
  $context->{value}{Union} = "Inequalities::Union";
  $context->{value}{Set} = "Inequalities::Set";

  #
  #  Disable interval notation in Context("Inequalities-Only");
  #
  $context = $main::context{"Inequalities-Only"} = $context->copy;
  $context->parens->remove('(','[','{');
  $context->parens->redefine('(',from=>"Numeric");
  $context->parens->redefine('[',from=>"Numeric");
  $context->parens->redefine('{',from=>"Numeric");
  $context->parens->set(
    '(' => {formInterval=>0},
    '[' => {formInterval=>0}
  );
  $context->lists->set(List => {class => 'Inequalities::List::List'});
  $context->operators->remove('U');
  $context->constants->remove('R');
  return;
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
#  or between a number and another compatable inequality.  Otherwise,
#  give an error.
#
#  varPos and numPos tell which of lop or rop is the variable and which
#  the number.  varName is the variable involved in the inequality.
#
sub _check {
  my $self = shift;
  $self->{type} = Value::Type("Interval",2);
  $self->{isInequality} = 1;
  ($self->{varPos},$self->{numPos}) =
    ($self->{lop}->class eq 'Variable' || $self->{lop}{isInequality} ? ('lop','rop') : ('rop','lop'));
  my ($v,$n) = ($self->{$self->{varPos}},$self->{$self->{numPos}});
  if ($n->isNumber && $n->{isConstant}) {
    if ($v->class eq 'Variable') {
      $self->{varName} = $v->{name};
      delete $self->{equation}{variables}{$v->{name}} if $v->{isNew};
      $self->{$self->{varPos}} = Inequalities::DummyVariable->new($self->{equation},$v->{name},$v->{ref});
      return;
    }
    if ($self->{def}{combine} && $v->{isInequality}) {
      my $bop = substr($self->{bop},0,1); my $ebop = $bop."=";
      if (($v->{bop} eq $bop || $v->{bop} eq $ebop) && $v->{varPos} eq $self->{numPos}) {
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
  my $I = $self->$eval(@_);
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
  return $self->Package("Interval")->new($context,'(',$b,$I,')') if $self->{varPos} eq 'lop';
  return $self->Package("Interval")->new($context,'(',-$I,$a,')');
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
  return $self->Package("Interval")->new($context,'[',$b,$I,')') if $self->{varPos} eq 'lop';
  return $self->Package("Interval")->new($context,'(',-$I,$a,']');
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
         );
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
  $self->Error("The operands of '%s' must be Intervals, Sets or Unions")
    unless $self->{lop}->isSetOfReals && $self->{rop}->isSetOfReals;
  $self->{type} = Value::Type("Interval",2);
  $self->{varName} = $self->{lop}{varName} || $self->{rop}{varName};
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
  $self->Error("The operands of '%s' must be Intervals, Sets or Unions")
    unless $self->{lop}->isSetOfReals && $self->{rop}->isSetOfReals;
  $self->{type} = Value::Type("Interval",2);
  $self->{varName} = $self->{lop}{varName} || $self->{rop}{varName};
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
#  A special class usd for the variables in
#  inequalities, since they are not really
#  variables for the formula.  (They don't need
#  to be subtituted or given values when the
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
#  For the Inequalities-Only context, we make lists
#  that report errors, so that students MUST produce
#  their intervals via inequalities.
#
package Inequalities::List::List;
our @ISA = ("Parser::List::List");

sub _check {
  my $self = shift;
  $self->SUPER::_check(@_);
  $self->Error("You are not allowed to use intervals in this context") if $self->{open};
}

##################################################
#
#  Override the string and TeX methods
#  so that we can strinfigy as inequalities
#  rather than intervals.
#
package Inequalities::Interval;
our @ISA = ("Value::Interval");

sub new {
  my $self = shift; $self = $self->SUPER::new(@_);
  $self->{isValue} = 1;
  return $self;
}

sub make {
  my $self = shift; $self = $self->SUPER::make(@_);
  $self->{isValue} = 1;
  return $self;
}

sub string {
  my $self = shift;
  return $self->SUPER::string(@_) unless $self->getFlag('stringifyAsInequalities');
  my ($a,$b,$open,$close) = $self->value;
  my $x = ($self->context->variables->names)[0];
  $x = $context->{variables}{$x}{string} if defined $context->{variables}{$x}{string};
  my $left  = ($open  eq '(' ? ' < ' : ' <= ');
  my $right = ($close eq ')' ? ' < ' : ' <= ');
  my $inequality = "";
  $inequality .= $a->string.$left unless $self->{leftInfinite};
  $inequality .= $x;
  $inequality .= $right.$b->string unless $self->{rightInfinite};
  $inequality = "-infinity < $x < infinity" if $inequality eq $x;
  return $inequality;
}

sub TeX {
  my $self = shift;
  return $self->SUPER::TeX(@_) unless $self->getFlag('stringifyAsInequalities');
  my ($a,$b,$open,$close) = $self->value;
  my $context = $self->context;
  my $x = ($context->variables->names)[0];
  $x = $context->{variables}{$x}{TeX} if defined $context->{variables}{$x}{TeX};
  $x =~ s/^([^_]+)_?(\d+)$/$1_{$2}/;
  my $left  = ($open  eq '(' ? ' < ' : ' <= ');
  my $right = ($close eq ')' ? ' < ' : ' <= ');
  my $inequality = "";
  $inequality .= $a->string.$left unless $self->{leftInfinite};
  $inequality .= $x;
  $inequality .= $right.$b->string unless $self->{rightInfinite};
  $inequality = "-\\infty < $x < \\infty " if $inequality eq $x;
  return $inequality;
}

##################################################
#
#  Override the string and TeX methods
#  so that we can strinfigy as inequalities
#  rather than unions.
#
package Inequalities::Union;
our @ISA = ("Value::Union");

sub new {
  my $self = shift; $self = $self->SUPER::new(@_);
  $self->{isValue} = 1;
  return $self;
}

sub make {
  my $self = shift; $self = $self->SUPER::make(@_);
  $self->{isValue} = 1;
  return $self;
}

sub string {
  my $self = shift;
  return $self->SUPER::string(@_) unless $self->getFlag('stringifyAsInequality');
  my $equation = shift; shift; shift; my $prec = shift;
  my $op = ($equation->{context} || $self->context)->{operators}{'or'};
  my @intervals = ();
  foreach my $x (@{$self->data}) {
    $x->{format} = $self->{format} if defined $self->{format};
    push(@intervals,$x->string($equation))
  }
  my $string = join($op->{string} || ' or ',@intervals);
  $string = '('.$string.')' if $prec > ($op->{precedence} || 1.5);
  return $string;
}

sub TeX {
  my $self = shift;
  return $self->SUPER::TeX(@_) unless $self->getFlag('stringifyAsInequality');
  my $equation = shift; shift; shift; my $prec = shift;
  my $op = ($equation->{context} || $self->context)->{operators}{'or'};
  my @intervals = ();
  foreach my $x (@{$self->data}) {push(@intervals,$x->TeX($equation))}
  my $TeX = join($op->{TeX} || $op->{string} || ' or ',@intervals);
  $TeX = '\left('.$TeX.'\right)' if $prec > ($op->{precedence} || 1.5);
  return $TeX;
}

##################################################
#
#  Override the string and TeX methods
#  so that we can strinfigy as inequalities
#  rather than sets.
#
package Inequalities::Set;
our @ISA = ("Value::Set");

sub new {
  my $self = shift; $self = $self->SUPER::new(@_);
  $self->{isValue} = 1;
  return $self;
}

sub make {
  my $self = shift; $self = $self->SUPER::make(@_);
  $self->{isValue} = 1;
  return $self;
}

sub string {
  my $self = shift;  my $equation = shift;
  return $self->SUPER::string($equation,@_) unless $self->getFlag('stringifyAsInequality');
  my $x = ($self->context->variables->names)[0];
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
  return $self->SUPER::TeX($equation,@_) unless $self->getFlag('stringifyAsInequality');
  my $x = ($self->context->variables->names)[0];
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
  return join(" or ",@coords);
}

##################################################

1;
