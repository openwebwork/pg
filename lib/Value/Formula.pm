########################################################################### 
#
#  Implements the Formula class.
#
package Value::Formula;
my $pkg = 'Value::Formula';

use strict;
use vars qw(@ISA);
@ISA = qw(Parser Value);

use overload
       '+'    => \&add,
       '-'    => \&sub,
       '*'    => \&mult,
       '/'    => \&div,
       '**'   => \&power,
       '.'    => \&dot,
       'x'    => \&cross,
       '<=>'  => \&compare,
       'cmp'  => \&Value::cmp,
       '~'    => sub {Parser::Function->call('conj',$_[0])},
       'neg'  => sub {$_[0]->neg},
       'sin'  => sub {Parser::Function->call('sin',$_[0])},
       'cos'  => sub {Parser::Function->call('cos',$_[0])},
       'exp'  => sub {Parser::Function->call('exp',$_[0])},
       'abs'  => sub {Parser::Function->call('abs',$_[0])},
       'log'  => sub {Parser::Function->call('log',$_[0])},
       'sqrt' => sub {Parser::Function->call('sqrt',$_[0])},
      'atan2' => \&atan2,
   'nomethod' => \&Value::nomethod,
         '""' => \&Value::stringify;

#
#  Call Parser to make the new item
#
sub new {shift; $pkg->SUPER::new(@_)}

#
#  Create the new parser with no string
#    (we'll fill in its tree by hand)
#
sub blank {$pkg->SUPER::new('')}

#
#  Get the type from the tree
#
sub typeRef {(shift)->{tree}->typeRef}

############################################
#
#  Create a BOP from two operands
#  
#  Get the context and variables from the left and right operands
#    if they are formulas
#  Make them into Value objects if they aren't already.
#  Convert '+' to union for intervals or unions.
#  Make a new BOP with the two operands.
#  Record the variables.
#  Evaluate the formula if it is constant.
#
sub bop {
  my ($l,$r,$flag,$bop) = @_;
  if ($l->promotePrecedence($r)) {return $r->add($l,!$flag)}
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  my $formula = $pkg->blank;
  my $vars = {};
  if (ref($r) eq $pkg) {
    $formula->{context} = $r->{context};
    $vars = {%{$vars},%{$r->{variables}}};
    $r = $r->{tree}->copy($formula);
  }
  if (ref($l) eq $pkg) {
    $formula->{context} = $l->{context};
    $vars = {%{$vars},%{$l->{variables}}};
    $l = $l->{tree}->copy($formula);
  }
  $l = $pkg->new($l) if (!ref($l) && Value::getType($formula,$l) eq "unknown");
  $r = $pkg->new($r) if (!ref($r) && Value::getType($formula,$r) eq "unknown");
  $l = Parser::Value->new($formula,$l) unless ref($l) =~ m/^Parser::/;
  $r = Parser::Value->new($formula,$r) unless ref($r) =~ m/^Parser::/;
  $bop = 'U' if $bop eq '+' &&
    ($l->type =~ m/Interval|Union/ || $r->type =~ m/Interval|Union/);
  $formula->{tree} = Parser::BOP->new($formula,$bop,$l,$r);
  $formula->{variables} = {%{$vars}};
  return $formula->eval if scalar(%{$vars}) == 0;
  return $formula;
}

sub add   {bop(@_,'+')}
sub sub   {bop(@_,'-')}
sub mult  {bop(@_,'*')}
sub div   {bop(@_,'/')}
sub power {bop(@_,'**')}
sub cross {bop(@_,'><')}

#
#  Make dot work for vector operands
#
sub dot   {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->compare($l,!$flag)}
  return bop(@_,'.') if $l->type eq 'Vector' &&
     Value::isValue($r) && $r->type eq 'Vector';
  Value::_dot(@_);
}

############################################
#
#  Form the negation of a formula
#
sub neg {
  my $self = shift;
  my $formula = $self->blank;
  $formula->{context} = $self->{context};
  $formula->{variables} = $self->{variables};
  $formula->{tree} = Parser::UOP->new($formula,'u-',$self->{tree}->copy($formula));
  return $formula->eval if scalar(%{$formula->{variables}}) == 0;
  return $formula;
}

#
#  Form the function atan2 function call on two operands
#
sub atan2 {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->compare($l,!$flag)}
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  Parser::Function->call('atan2',$l,$r);
}

############################################
#
#  Compare two functions for equality
#
sub compare {
  my ($l,$r,$flag) = @_; my $self = $l;
  if ($l->promotePrecedence($r)) {return $r->compare($l,!$flag)}
  $r = Value::Formula->new($r) unless Value::isFormula($r);
  Value::Error("Functions from different contexts can't be compared")
    unless $l->{context} == $r->{context};

  #
  #  Get the test points and evaluate the functions at those points
  #
  ##  FIXME: Check given points for consistency
  my $points = $l->{test_points} || $r->{test_points} || $l->createRandomPoints;
  my $lvalues = $l->{test_values} || $l->createPointValues($points,1);
  my $rvalues = $r->createPointValues($points);
  #
  # Note: $l is bigger if $r can't be evaluated at one of the points
  return 1 unless $rvalues;

  #
  #  Look through the two lists to see if they are equal.
  #  If not, return the comparison of the first unequal value
  #    (not good for < and >, but OK for ==).
  #
  my ($i, $cmp);
  foreach $i (0..scalar(@{$lvalues})) {
    $cmp = $lvalues->[$i] <=> $rvalues->[$i];
    return $cmp if $cmp;
  }
  return 0;
}

#
#  Create the value list from a given set of test points
#
sub createPointValues {
  my $self = shift;
  my $points = shift || $self->{test_points} || $self->createRandomPoints;
  my $showError = shift;
  my $f = $self->{f};
  $f = $self->{f} = $self->perlFunction(undef,[$self->{context}->variables->names])
     unless $f;

  my $values = []; my $v;
  foreach my $p (@{$points}) {
    $v = eval {&$f(@{$p})};
    if (!defined($v)) {
      return unless $showError;
      Value::Error("Can't evaluate formula on test point (".join(',',@{$p}).")");
    }	
    push @{$values}, Value::makeValue($v);
  }

  $self->{test_points} = $points;
  $self->{test_values} = $values;
}

#
#  Create a list of random points, making sure that the function
#  is defined at the given points.  Error if we can't find enough.
#
sub createRandomPoints {
  my $self = shift;
  my $num_points = @_[0];
  $num_points = int($self->getFlag('num_points',5)) unless defined($num_points);
  $num_points = 1 if $num_points < 1;

  ## FIXME:  deal with variables of type complex, etc.
  my @vars = $self->{context}->variables->names;
  my @limits = $self->getVariableLimits(@vars);
  foreach my $limit (@limits) {$limit->[2] = abs($limit->[1]-$limit->[0])/1000}
  my $f = $self->{f}; $f = $self->{f} = $self->perlFunction(undef,[@vars]) unless $f;
  my $seedRandom = $self->{context}->flag('random_seed')? 'PGseedRandom' : 'seedRandom';
  my $getRandom  = $self->{context}->flag('random_seed')? 'PGgetRandom'  : 'getRandom';

  $self->$seedRandom;
  my $points = []; my $values = [];
  my (@P,$v); my $k = 0;
  while (scalar(@{$points}) < $num_points && $k < 10) {
    @P = (); foreach my $limit (@limits) {push @P, $self->$getRandom(@{$limit})}
    $v = eval {&$f(@P)};
    if (!defined($v)) {$k++} else {
      push @{$points}, [@P];
      push @{$values}, Value::makeValue($v);
      $k = 0; # reset count when we find a point
    }
  }

  Value::Error("Can't generate enough valid points for comparison") if $k;
  return ($points,$values) if defined(@_[0]);
  $self->{test_values} = $values;
  $self->{test_points} = $points;
}

#
#  Get the array of variable limits
#
sub getVariableLimits {
  my $self = shift;
  ## FIXME: check for consistency with @vars
  return $self->{limits} if defined($self->{limits});
  my @limits; my $default = $self->getFlag('limits',[-2,2]);
  foreach my $x (@_) {
    my $def = $self->{context}->variables->get($x);
    push @limits, $def->{limits} || $default;
  }
  return @limits;
}

sub seedRandom {srand}
sub getRandom {
  my $self = shift;
  my ($m,$M,$n) = @_; $n = 1 unless $n;
  return $m + $n*int(rand()*(int(($M-$m)/$n)+1));
}

#
#  Get the value of a flag from the object itself,
#  or from the context, or from the default context
#  or from the given default, whichever is found first.
#
sub getFlag {
  my $self = shift; my $name = shift;
  return $self->{$name} if defined($self->{$name});
  return $self->{context}{flags}{$name} if defined($self->{context}{flags}{$name});
  return $$Value::context->{flags}{$name} if defined($$Value::context->{flags}{$name});
  return shift;
}

############################################
#
#  Check if the value of a formula is constant
#    (could use shift->{tree}{isConstant}, but I don't trust it)
#
sub isConstant {scalar(%{shift->{variables}}) == 0}

###########################################################################

1;
