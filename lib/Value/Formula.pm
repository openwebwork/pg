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

sub isZero {(shift)->{tree}{isZero}}
sub isOne {(shift)->{tree}{isOne}}

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
  my ($bop,$l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->add($l,!$flag)}
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  my $formula = $pkg->blank; my $parser = $formula->{context}{parser};
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
  $l = $parser->{Value}->new($formula,$l) unless ref($l) =~ m/^Parser::/;
  $r = $parser->{Value}->new($formula,$r) unless ref($r) =~ m/^Parser::/;
  $bop = 'U' if $bop eq '+' &&
    ($l->type =~ m/Interval|Union/ || $r->type =~ m/Interval|Union/);
  $formula->{tree} = $parser->{BOP}->new($formula,$bop,$l,$r);
  $formula->{variables} = {%{$vars}};
  return $formula->eval if scalar(%{$vars}) == 0;
  return $formula;
}

sub add   {bop('+',@_)}
sub sub   {bop('-',@_)}
sub mult  {bop('*',@_)}
sub div   {bop('/',@_)}
sub power {bop('**',@_)}
sub cross {bop('><',@_)}

#
#  Make dot work for vector operands
#
sub dot   {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->compare($l,!$flag)}
  return bop('.',@_) if $l->type eq 'Vector' &&
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
  $formula->{tree} = $formula->{context}{parser}{UOP}->new($formula,'u-',$self->{tree}->copy($formula));
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
  #  Handle parameters
  #
  $lvalues = $l->{test_values}
    if $l->AdaptParameters($r,$self->{context}->variables->parameters);

  #
  #  Look through the two lists to see if they are equal.
  #  If not, return the comparison of the first unequal value
  #    (not good for < and >, but OK for ==).
  #
  my ($i, $cmp);
  foreach $i (0..scalar(@{$lvalues})-1) {
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
  my @vars   = $self->{context}->variables->variables;
  my @params = $self->{context}->variables->parameters;
  my @zeros  = @{$self->{parameters} || [split('',"0" x scalar(@params))]};
  my $f = $self->{f}; $f = $self->{f} = $self->perlFunction(undef,[@vars,@params]) unless $f;

  my $values = []; my $v;
  foreach my $p (@{$points}) {
    $v = eval {&$f(@{$p},@zeros)};
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

  my @vars   = $self->{context}->variables->variables;
  my @params = $self->{context}->variables->parameters;
  my @limits = $self->getVariableLimits(@vars);
  my @make   = $self->getVariableTypes(@vars);
  my @zeros  = split('',"0" x scalar(@params));
  my $f = $self->{f}; $f = $self->{f} = $self->perlFunction(undef,[@vars,@params]) unless $f;
  my $seedRandom = $self->{context}->flag('random_seed')? 'PGseedRandom' : 'seedRandom';
  my $getRandom  = $self->{context}->flag('random_seed')? 'PGgetRandom'  : 'getRandom';

  $self->$seedRandom;
  my $points = []; my $values = [];
  my (@P,@p,$v,$i); my $k = 0;
  while (scalar(@{$points}) < $num_points && $k < 10) {
    @P = (); $i = 0;
    foreach my $limit (@limits) {
      @p = (); foreach my $I (@{$limit}) {push @p, $self->$getRandom(@{$I})}
      push @P, $make[$i++]->make(@p);
    }
    $v = eval {&$f(@P,@zeros)};
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
  my $userlimits = $self->{limits};
  if (defined($userlimits)) {
    $userlimits = [[[-$userlimits,$userlimits]]] unless ref($userlimits) eq 'ARRAY';
    $userlimits = [$userlimits] unless ref($userlimits->[0]) eq 'ARRAY';
    $userlimits = [$userlimits] if scalar(@_) == 1 && ref($userlimits->[0][0]) ne 'ARRAY';
    foreach my $I (@{$userlimits}) {$I = [$I] unless ref($I->[0]) eq 'ARRAY'};
  }
  $userlimits = [] unless $userlimits; my @limits;
  my $default;  $default = $userlimits->[0][0] if defined($userlimits->[0]);
  my $default = $default || $self->{context}{flags}{limits} || [-2,2];
  my $granularity = $self->getFlag('granularity',1000);
  my $resolution = $self->getFlag('resolution');
  my $i = 0;
  foreach my $x (@_) {
    my $def = $self->{context}{variables}{$x};
    my $limit = $userlimits->[$i++] || $def->{limits} || [];
    $limit = [$limit] if defined($limit->[0]) && ref($limit->[0]) ne 'ARRAY';
    push(@{$limit},$limit->[0] || $default) while (scalar(@{$limit}) < $def->{type}{length});
    pop(@{$limit}) while (scalar(@{$limit}) > $def->{type}{length});
    push @limits, $self->addGranularity($limit,$def,$granularity,$resolution);
  }
  return @limits;
}

#
#  Add the granularity to the limit intervals
#
sub addGranularity {
  my $self = shift; my $limit = shift; my $def = shift;
  my $granularity = shift; my $resolution = shift;
  $granularity = $def->{granularity} || $granularity;
  $resolution = $def->{resolution} || $resolution;
  foreach my $I (@{$limit}) {
    my ($a,$b,$n) = @{$I}; $b = -$a unless defined $b;
    $I = [$a,$b,($n || $resolution || abs($b-$a)/$granularity)];
  }
  return $limit;
}

#
#  Get the routines to make the coordinates of the points
#
sub getVariableTypes {
  my $self = shift;
  my @make;
  foreach my $x (@_) {
    my $type = $self->{context}{variables}{$x}{type};
    if ($type->{name} eq 'Number') {
      push @make,($type->{length} == 1)? 'Value::Formula::number': 'Value::Complex';
    } else {
      push @make, "Value::$type->{name}";
    }
  }
  return @make;
}

#
#  Fake object for making reals (rather than use overhead of Value::Real)
#
sub Value::Formula::number::make {shift; shift}

#
#  Find adaptive parameters, if any
#
sub AdaptParameters {
  my $l = shift; my $r = shift;
  my @params = @_; my $d = scalar(@params);
  return 0 if $d == 0; return 0 unless $l->usesOneOf(@params);
  $l->Error("Adaptive parameters can only be used for real-valued functions")
    unless $l->{tree}->isRealNumber;
  #
  #  Get coefficient matrix of adaptive parameters
  #  and value vector for linear system
  #
  my ($p,$v) = $l->createRandomPoints($d,1);
  my @P = split('',"0" x $d); my ($f,$F) = ($l->{f},$r->{f});
  my @A = (); my @b = ();
  foreach my $i (0..$d-1) {
    my @a = (); my @p = @{$p->[$i]};
    foreach my $j (0..$d-1) {
      $P[$j] = 1; push(@a,&$f(@p,@P)-$v->[$i]);
      $P[$j] = 0;
    }
    push @A, [@a]; push @b, [&$F(@p,@P)-$v->[$i]];
  }
  #
  #  Use MatrixReal1.pm to solve system of linear equations
  #
  my $M = MatrixReal1->new($d,$d); $M->[0] = \@A;
  my $B = MatrixReal1->new($d,1);  $B->[0] = \@b;
  ($M,$B) = $M->normalize($B);
  $M = $M->decompose_LR;
  if (($d,$B,$M) = $M->solve_LR($B)) {
    if ($d == 0) {
      #
      #  Get parameter values and recompute the points using them
      #
      my @a; my $i = 0; my $max = $l->getFlag('max_adapt',1E8);
      foreach my $row (@{$B->[0]}) {
	if (abs($row->[0]) > $max) {
	  $l->Error("Constant of integration is too large: $row->[0]")
	    if ($params[$i] eq 'C0');
	  $l->Error("Adaptive constant is too large: $params[$i] = $row->[0]");
	}
	push @a, $row->[0]; $i++;
      }
      $l->{parameters} = [@a];
      $l->createPointValues;
      return 1;
    }
  }
  $l->Error("Can't solve for adaptive parameters");
}

sub usesOneOf {
  my $self = shift;
  foreach my $x (@_) {return 1 if $self->{variables}{$x}}
  return 0;
}

##
##  debugging routine
##
#sub main::Format {
#  my $v = scalar(@_) > 1? [@_]: shift;
#  $v = [%{$v}] if ref($v) eq 'HASH';
#  return $v unless ref($v) eq 'ARRAY';
#  my @V; foreach my $x (@{$v}) {push @V, main::Format($x)}
#  return '['.join(",",@V).']';
#}

#
#  Random number generator  (replaced by Value::WeBWorK.pm)
#
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
