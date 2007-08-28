loadMacros('MathObjects.pl');

sub _parserImplicitPlane_init {ImplicitPlane::Init()}; # don't reload this file

=head1 DESCRIPTION

 ######################################################################
 #
 #  This is a Parser class that implements implicit planes as
 #  a subclass of the Formula class.  The standard ->cmp routine
 #  will work for this, provided we define the compare() function
 #  needed by the overloaded ==.  We assign the special precedence
 #  so that overloaded operations will be promoted to the ones below.
 #
 #
 #  Use ImplicitPlane(point,vector), ImplicitPlane(point,number) or
 #  ImplicitPlane(formula) to create an ImplicitPlane object.
 #  The first form uses the point as a point on the plane and the
 #  vector as the normal for the plane.  The second form uses the point
 #  as the coefficients of the variables and the number as the value
 #  that the formula must equal.  The third form uses the formula
 #  directly.
 #
 #  The number of variables in the Context determines the dimension of
 #  the "plane" being defined.  If there are only two, the formula
 #  produces an implicit line, but if there are four variables, it will
 #  be a hyperplane in four-space.  You can specify the variables you
 #  want to use by supplying an additional parameter, which is a
 #  reference to an array of variable names.
 #
 #
 #  Usage examples:
 #
 #     $P = ImplicitPlane(Point(1,0,2),Vector(-1,1,3)); #  -x+y+3z = 5
 #     $P = ImplicitPlane([1,0,2],[-1,1,3]);            #  -x+y+3z = 5
 #     $P = ImplicitPlane([1,0,2],4);                   #  x+2z = 4
 #     $P = ImplicitPlane("x+2y-z=5");
 #
 #     Context()->variables->are(x=>'Real',y=>'Real',z=>'Real',w=>'Real');
 #     $P = ImplicitPlane([1,0,2,-1],10);               # w+2y-z = 10 (alphabetical order)
 #     $P = ImplicitPlane([3,-1,2,4],5,['x','y','z','w']);  # 3x-y+2z+4w = 5
 #     $P = ImplicitPlane([3,-1,2],5,['y','z','w']);  # 3y-z+2w = 5
 #
 #  Then use
 #
 #     ANS($P->cmp);
 #
 #  to get the answer checker for $P.
 #

=cut

##################################################
#
#  Define the subclass of Formula
#
package ImplicitPlane;
our @ISA = qw(Value::Formula);

sub Init {
  my $context = $main::context{ImplicitPlane} = Parser::Context->getCopy("Vector");
  $context->{name} = "ImplicitPlane";
  $context->{precedence}{ImplicitPlane} = $context->{precedence}{special};
  #$context->{value}{Equality} = "ImplicitPlane::equality";
  Parser::BOP::equality->Allow($context);
  $context->operators->set('=' => {class => 'ImplicitPlane::equality'});

  main::Context("ImplicitPlane");  ### FIXME:  probably should require authors to set this explicitly

  main::PG_restricted_eval('sub ImplicitPlane {ImplicitPlane->new(@_)}');
}

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  return shift if scalar(@_) == 1 && ref($_[0]) eq 'ImplicitPlane';
  $_[0] = $context->Package("Point")->new($context,$_[0]) if ref($_[0]) eq 'ARRAY';
  $_[1] = $context->Package("Vector")->new($context,$_[1]) if ref($_[1]) eq 'ARRAY';

  my ($p,$N,$plane,$vars,$d,$type); $type = 'plane';
  if (scalar(@_) >= 2 && Value::classMatch($_[0],'Point','Vector') &&
      Value::classMatch($_[1],'Vector') || Value::isRealNumber($_[1])) {
    #
    # Make a plane from a point and a vector,
    # or from a list of coefficients and the constant
    #
    $p = shift; $N = shift;
    if (Value::classMatch($N,'Vector')) {
      $d = $p.$N;
    } else {
      $d = $context->Package("Real")->make($context,$N);
      $N = $context->Package("Vector")->new($context,$p);
    }
    $vars = shift || [$context->variables->names];
    $vars = [$vars] unless ref($vars) eq 'ARRAY';
    $type = 'line' if scalar(@{$vars}) == 2;
    my @terms = (); my $i = 0;
    foreach my $x (@{$vars}) {push @terms, $N->{data}[$i++]->string.$x}
    $plane = $context->Package("Formula")->new(join(' + ',@terms).' = '.$d->string)->reduce(@_);
  } else {
    $formula = $context->Package("Formula");
    #
    #  Determine the normal vector and d value from the equation
    #
    $plane = shift;
    $plane = $formula->new($context,$plane) unless Value::isValue($plane);
    $vars = shift || [$context->variables->names];
    $vars = [$vars] unless ref($vars) eq 'ARRAY';
    $type = 'line' if scalar(@{$vars}) == 2;
    Value::Error("Your formula doesn't look like an implicit %s",$type)
      unless $plane->type eq 'Equality';
    #
    #  Find the coefficients of the formula
    #
    my $f = ($formula->new($context,$plane->{tree}{lop}) -
	     $formula->new($context,$plane->{tree}{rop}))->reduce;
    my $F = $f->perlFunction(undef,[@{$vars}]);
    my @v = split('','0' x scalar(@{$vars}));
    $d = -&$F(@v); my @coeff = (@v);
    foreach my $i (0..scalar(@v)-1)
      {$v[$i] = 1; $coeff[$i] = &$F(@v) + $d; $v[$i] = 0}
    #
    #  Check that the student's formula really is what we thought
    #
    $N = Value::Vector->new([@coeff]);
    $plane = ImplicitPlane->new($N,$d,$vars,'-x=-y'=>0,'-x=n'=>0);
    Value::Error("Your formula isn't a linear one")
      unless ($formula->new($plane->{tree}{lop}) -
              $formula->new($plane->{tree}{rop})) == $f;
    $plane = $plane->reduce;
  }
  Value::Error("The equation of a %s must be non-zero somewhere",$type)
    if ($N->norm == 0);
  $plane->{d} = $d; $plane->{N} = $N; $plane->{implicit} = $type;
  return bless $plane, $class;
}

#
#  We already know the vectors are non-zero, so check
#  if the equations are multiples of each other.
#
sub compare {
  my ($self,$l,$r) = Value::checkOpOrder(@_);
  $r = new ImplicitPlane($r);# if ref($r) ne ref($self);
  my ($lN,$ld) = ($l->{N},$l->{d});
  my ($rN,$rd) = ($r->{N},$r->{d});
  if ($rd == 0 || $ld == 0) {
    return $rd <=> $ld unless $ld == $rd;
    return $lN <=> $rN unless (areParallel $lN $rN);
    return 0;
  }
  return $rd*$lN <=> $ld*$rN;
}

sub cmp_class {'an Implicit '.(shift->{implicit})};
sub showClass {shift->cmp_class};

sub cmp_defaults{(
  Value::Real::cmp_defaults(shift),
  ignoreInfinity => 0,    # report infinity as an error
)}

#
#  Only compare two equalities
#
sub typeMatch {
  my $self = shift; my $other = shift; my $ans = shift;
  return ref($other) && $other->type eq 'Equality' unless ref($self);
  return ref($other) && $self->type eq $other->type;
}

#
#  We subclass BOP::equality so that we can give a warning about
#  things like 1 = 3
#
package ImplicitPlane::equality;
our @ISA = qw(Parser::BOP::equality);

sub _check {
  my $self = shift;
  $self->SUPER::_check;
  $self->Error("An implicit equation can't be constant on both sides")
    if $self->{lop}{isConstant} && $self->{rop}{isConstant};
}

1;
