########################################################################### 
#
#  Implements the Formula class.
#
package Value::Formula;
my $pkg = 'Value::Formula';

use strict;
our @ISA = qw(Parser Value);

my $UNDEF = bless {}, "UNDEF"; # used for undefined points

#
#  Call Parser to make the new Formula
#
sub new {
  my $self = shift;
  my $f = $self->SUPER::new(@_);
  foreach my $id ('open','close') {$f->{$id} = $f->{tree}{$id}}
  return $f;
}

#
#  Create a new Formula with no string
#    (we'll fill in its tree by hand)
#
sub blank {shift->SUPER::new(@_)}

#
#  with() changes tree element as well
#    as the formula itself.
#
sub with {
  my $self = shift; my %hash = @_;
  foreach my $id (keys(%hash)) {
    $self->{tree}{$id} = $hash{$id};
    $self->{$id} = $hash{$id};
  }
  return $self;
}

#
#  Get the type from the tree
#
sub typeRef {(shift)->{tree}->typeRef}
sub length {(shift)->{tree}->typeRef->{length}}

sub isZero {(shift)->{tree}{isZero}}
sub isOne {(shift)->{tree}{isOne}}

sub isSetOfReals {(shift)->{tree}->isSetOfReals}
sub canBeInUnion {(shift)->{tree}->canBeInUnion}

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
  my $bop = shift;
  my ($self,$l,$r) = Value::checkOpOrder(@_);
  my $class = ref($self) || $self;
  my $call = $self->context->{method}{$bop};
  my $formula = $self->blank($self->context);
  my $parser = $formula->{context}{parser};
  if (ref($r) eq $class || ref($r) eq $pkg) {
    $formula->{context} = $r->{context};
    $r = $r->{tree}->copy($formula);
  }
  if (ref($l) eq $class || ref($l) eq $pkg) {
    $formula->{context} = $l->{context};
    $l = $l->{tree}->copy($formula);
  }
  $l = $self->new($l) if (!ref($l) && Value::getType($formula,$l) eq "unknown");
  $r = $self->new($r) if (!ref($r) && Value::getType($formula,$r) eq "unknown");
  $l = $parser->{Value}->new($formula,$l) unless ref($l) =~ m/^Parser::/;
  $r = $parser->{Value}->new($formula,$r) unless ref($r) =~ m/^Parser::/;
  $bop = 'U' if $bop eq '+' &&
    ($l->type =~ m/Interval|Set|Union/ || $r->type =~ m/Interval|Set|Union/);
  $formula->{tree} = $parser->{BOP}->new($formula,$bop,$l,$r);
  $formula->{variables} = $formula->{tree}->getVariables;
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
sub _dot   {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->_dot($l,!$flag)}
  return bop('.',@_) if ($l->type eq 'Vector' || $l->{isVector}) &&
     Value::isValue($r) && ($r->type eq 'Vector' || $r->{isVector});
  $l->SUPER::_dot($r,$flag);
}

sub pdot {'('.(shift->stringify).')'}

#
#  Call the Parser::Function call function
#
sub call {
  my $self = shift; my $name = shift;
  Parser::Function->call($name,$self);
}

############################################
#
#  Form the negation of a formula
#
sub neg {
  my $self = shift;
  my $formula = $self->blank($self->context);
  $formula->{variables} = $self->{variables};
  $formula->{tree} = $formula->{context}{parser}{UOP}->new($formula,'u-',$self->{tree}->copy($formula));
  return $formula;
}

#
#  Form the function atan2 function call on two operands
#
sub atan2 {
  my ($self,$l,$r) = Value::checkOpOrder(@_);
  Parser::Function->call('atan2',$l,$r);
}

sub sin  {shift->call('sin',@_)}
sub cos  {shift->call('cos',@_)}
sub abs  {shift->call('abs',@_)}
sub exp  {shift->call('exp',@_)}
sub log  {shift->call('log',@_)}
sub sqrt {shift->call('sqrt',@_)}

sub twiddle {shift->call('conj',@_)}

############################################
#
#  Compare two functions for equality
#
sub compare {
  my ($l,$r) = @_; my $self = $l;
  $r = $self->Package("Formula")->new($self->context,$r) unless Value::isFormula($r);
  Value::Error("Functions from different contexts can't be compared")
    unless $l->{context} == $r->{context};

  #
  #  Get the test points and evaluate the functions at those points
  #
  ##  FIXME: Check given points for consistency
  my $points  = $l->{test_points} || $l->createRandomPoints(undef,$l->{test_at});
  my $lvalues = $l->{test_values} || $l->createPointValues($points,1,1);
  my $rvalues = $r->createPointValues($points,0,1,$l->{checkUndefinedPoints});
  #
  # Note: $l is bigger if $r can't be evaluated at one of the points
  return 1 unless $rvalues;

  my ($i, $cmp);

  #
  #  Handle adaptive parameters:
  #    Get the tolerances, and check each adapted point relative
  #    to the ORIGINAL correct answer.  (This will have to be
  #    fixed if we ever do adaptive parameters for non-real formulas)
  #
  if ($l->AdaptParameters($r,$self->{context}->variables->parameters)) {
    my $avalues = $l->{test_adapt};
    my $tolerance    = $self->getFlag('tolerance',1E-4);
    my $isRelative   = $self->getFlag('tolType','relative') eq 'relative';
    my $zeroLevel    = $self->getFlag('zeroLevel',1E-14);
    my $zeroLevelTol = $self->getFlag('zeroLevelTol',1E-12);
    foreach $i (0..scalar(@{$lvalues})-1) {
      my $tol = $tolerance;
      my ($lv,$rv,$av) = ($lvalues->[$i]->value,$rvalues->[$i]->value,$avalues->[$i]->value);
      if ($isRelative) {
	if (abs($lv) <= $zeroLevel) {$tol = $zeroLevelTol}
	                       else {$tol *= abs($lv)}
      }
      return $rv <=> $av unless abs($rv - $av) < $tol;
    }
    return 0;
  }

  #
  #  Look through the two lists of values to see if they are equal.
  #  If not, return the comparison of the first unequal value
  #    (not good for < and >, but OK for ==).
  #
  my $domainError = 0;
  foreach $i (0..scalar(@{$lvalues})-1) {
    if (ref($lvalues->[$i]) eq 'UNDEF' ^ ref($rvalues->[$i]) eq 'UNDEF') {$domainError = 1; next}
    $cmp = $lvalues->[$i] <=> $rvalues->[$i];
    return $cmp if $cmp;
  }
  $l->{domainMismatch} = $domainError;  # return this value
}

#
#  Create the value list from a given set of test points
#
sub createPointValues {
  my $self = shift;
  my $points = shift || $self->{test_points} || $self->createRandomPoints;
  my $showError = shift; my $cacheResults = shift;
  my @vars   = $self->{context}->variables->variables;
  my @params = $self->{context}->variables->parameters;
  my @zeros  = (0) x scalar(@params);
  my $f = $self->{f}; $f = $self->{f} = $self->perlFunction(undef,[@vars,@params]) unless $f;
  my $checkUndef = scalar(@params) == 0 && (shift || $self->getFlag('checkUndefinedPoints',0));

  my $values = []; my $v;
  foreach my $p (@{$points}) {
    $v = eval {&$f(@{$p},@zeros)};
    if (!defined($v) && !$checkUndef) {
      return unless $showError;
      Value::Error("Can't evaluate formula on test point (%s)",join(',',@{$p}));
    }
    push @{$values}, (defined($v)? Value::makeValue($v,context=>$self->context): $UNDEF);
  }
  if ($cacheResults) {
    $self->{test_points} = $points;
    $self->{test_values} = $values;
  }
  return $values;
}

#
#  Create the adapted value list for the test points
#
sub createAdaptedValues {
  my $self = shift;
  my $points = shift || $self->{test_points} || $self->createRandomPoints;
  my $showError = shift;
  my @vars   = $self->{context}->variables->variables;
  my @params = $self->{context}->variables->parameters;
  my $f = $self->{f}; $f = $self->{f} = $self->perlFunction(undef,[@vars,@params]) unless $f;

  my $values = []; my $v;
  my @adapt = @{$self->{parameters}};
  foreach my $p (@{$points}) {
    $v = eval {&$f(@{$p},@adapt)};
    if (!defined($v)) {
      return unless $showError;
      Value::Error("Can't evaluate formula on test point (%s) with parameters (%s)",
		   join(',',@{$p}),join(',',@adapt));
    }
    push @{$values}, Value::makeValue($v,context=>$self->context);
  }
  $self->{test_adapt} = $values;
}

#
#  Create a list of random points, making sure that the function
#  is defined at the given points.  Error if we can't find enough.
#
sub createRandomPoints {
  my $self = shift; my $context = $self->context;
  my ($num_points,$include) = @_; my $cacheResults = !defined($num_points);
  $num_points = int($self->getFlag('num_points',5)) unless defined($num_points);
  $num_points = 1 if $num_points < 1;

  my @vars   = $context->variables->variables;
  my @params = $context->variables->parameters;
  my @limits = $self->getVariableLimits(@vars);
  my @make   = $self->getVariableTypes(@vars);
  my @zeros  = (0) x scalar(@params);
  my $f = $self->{f}; $f = $self->{f} = $self->perlFunction(undef,[@vars,@params]) unless $f;
  my $seedRandom = $context->flag('random_seed')? 'PGseedRandom' : 'seedRandom';
  my $getRandom  = $context->flag('random_seed')? 'PGgetRandom'  : 'getRandom';
  my $checkUndef = scalar(@params) == 0 && $self->getFlag('checkUndefinedPoints',0);
  my $max_undef  = $self->getFlag('max_undefined',$num_points);

  $self->$seedRandom;
  my $points = []; my $values = []; my $num_undef = 0;
  if ($include) {
    push(@{$points},@{$include});
    push(@{$values},@{$self->createPointValues($include,1,$cacheResults,$self->{checkundefinedPoints})});
  }
  my (@P,@p,$v,$i); my $k = 0;
  while (scalar(@{$points}) < $num_points+$num_undef && $k < 10) {
    @P = (); $i = 0;
    foreach my $limit (@limits) {
      @p = (); foreach my $I (@{$limit})
        {push @p, $self->Package("Real")->make($context,$self->$getRandom(@{$I}))}
      push @P, $make[$i++]->make($context,@p);
    }
    $v = eval {&$f(@P,@zeros)};
    if (!defined($v)) {
      if ($checkUndef && $num_undef < $max_undef) {
	push @{$points}, [@P];
	push @{$values}, $UNDEF;
	$num_undef++;
      }
      $k++;
    } else {
      push @{$points}, [@P];
      push @{$values}, Value::makeValue($v,context=>$context);
      $k = 0; # reset count when we find a point
    }
  }

  if ($k) {
    my $error = "Can't generate enough valid points for comparison";
    $error .= ':<div style="margin-left:1em">'.($context->{error}{message} || $@).'</div>'
      if ($self->getFlag('showTestPointErrors'));
    $error =~ s/ (in \S+ )?at line \d+.*//s;
    Value::Error($error);
  }

  return ($points,$values) unless $cacheResults;
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
  $default = $default || $self->getFlag('limits',[-2,2]);
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
      push @make,($type->{length} == 1)? 'Value::Formula::number': $self->Package("Complex");
    } else {
      push @make, $self->Package($type->{name});
    }
  }
  return @make;
}

#
#  Fake object for making reals (rather than use overhead of Value::Real)
#
sub Value::Formula::number::make {shift; shift; shift->value}

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
  my ($p,$v) = $l->createRandomPoints($d);
  my @P = (0) x $d; my ($f,$F) = ($l->{f},$r->{f});
  my @A = (); my @b = ();
  foreach my $i (0..$d-1) {
    my @a = (); my @p = @{$p->[$i]};
    foreach my $j (0..$d-1) {
      $P[$j] = 1; push(@a,(&$f(@p,@P)-$v->[$i])->value);
      $P[$j] = 0;
    }
    push @A, [@a]; push @b, [(&$F(@p,@P)-$v->[$i])->value];
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
	  $max = Value::makeValue($max);
	  $l->Error("Constant of integration is too large: %s\n(maximum allowed is %s)",
		    $row->[0]->string,$max->string) if ($params[$i] eq 'C0');
	  $l->Error("Adaptive constant is too large: %s = %s\n(maximum allowed is %s)",
		    $params[$i],$row->[0]->string,$max->string);
	}
	push @a, $row->[0]; $i++;
      }
      $l->{parameters} = [@a];
      $l->createAdaptedValues;
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

############################################
#
#  Check if the value of a formula is constant
#    (could use shift->{tree}{isConstant}, but I don't trust it)
#
sub isConstant {
  my @vars = (%{shift->{variables}});
  return scalar(@vars) == 0;
}

############################################
#
#  Provide output formats
#
sub stringify {
  my $self = shift;
  return $self->TeX if $self->getFlag('StringifyAsTeX');
  $self->string;
}

###########################################################################

1;
