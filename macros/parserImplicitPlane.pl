loadMacros('Parser.pl');

sub _parserImplicitPlane_init {}; # don't reload this file

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

#
#  Create a context for implicit planes and activate it
#
$context{ImplicitPlane} = Context("Vector")->copy();
$context{ImplicitPlane}->{precedence}{ImplicitPlane} = Context()->{precedence}{special};
Context("ImplicitPlane");
#
# allow equalities in formulas
#
Parser::BOP::equality::Allow;

#
#  Syntactic sugar for creating implicit planes
#
sub ImplicitPlane {ImplicitPlane->new(@_)}

#
#  Define the subclass of Formula
#
package ImplicitPlane;
our @ISA = qw(Value::Formula);

sub new {
  my $self = shift; my $class = ref($self) || $self;
  return shift if scalar(@_) == 1 && ref($_[0]) eq $class;
  $_[0] = Value::Point->new($_[0]) if ref($_[0]) eq 'ARRAY';
  $_[1] = Value::Vector->new($_[1]) if ref($_[1]) eq 'ARRAY';

  my ($p,$N,$plane,$vars,$d,$type); $type = 'plane';
  if (scalar(@_) >= 2 && Value::class($_[0]) =~ m/^(Point|Vector)/ &&
      Value::class($_[1]) eq 'Vector' || Value::isRealNumber($_[1])) {
    #
    # Make a plane from a point and a vector,
    # or from a list of coefficients and the constant
    #
    $p = shift; $N = shift;
    if (Value::class($N) eq 'Vector') {$d = $p.$N}
      else {$d = Value::Real->make($N); $N = Value::Vector->new($p)}
    $vars = shift || [$$Value::context->variables->names];
    $vars = [$vars] unless ref($vars) eq 'ARRAY';
    $type = 'line' if scalar(@{$vars}) == 2;
    my @terms = (); my $i = 0;
    foreach my $x (@{$vars}) {push @terms, $N->{data}[$i++]->string.$x}
    $plane = Value::Formula->new(join(' + ',@terms).' = '.$d->string)->reduce(@_);
  } else {
    #
    #  Determine the normal vector and d value from the equation
    #
    $plane = shift;
    $plane = Value::Formula->new($plane) unless Value::isValue($plane);
    $vars = shift || [$$Value::context->variables->names];
    $vars = [$vars] unless ref($vars) eq 'ARRAY';
    $type = 'line' if scalar(@{$vars}) == 2;
    Value::Error("Your formula doesn't look like an implicit $type")
      unless $plane->type eq 'Equality';
    #
    #  Find the coefficients of the formula
    #
    my $f = Value::Formula->new($plane->{tree}{lop}) -
	    Value::Formula->new($plane->{tree}{rop});
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
      unless (Value::Formula->new($plane->{tree}{lop}) -
              Value::Formula->new($plane->{tree}{rop})) == $f;
  }
  Value::Error("The equation of a $type must be non-zero somewhere")
    if ($N->norm == 0);
  $plane->{d} = $d; $plane->{N} = $N; $plane->{implicit} = $type;
  $plane->{isValue} = $plane->{isFormula} = 1;
  return bless $plane, $class;
}

#
#  We already know the vectors are none zero, so check
#  if the equations are multiples of each other.
#
sub compare {
  my ($l,$r,$flag) = @_;
  $r = ImplicitPlane->new($r);
  if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  my ($lN,$ld) = ($l->{N},$l->{d});
  my ($rN,$rd) = ($r->{N},$r->{d});
  return $rd*$lN <=> $ld*$rN;
}

sub cmp_class {'an Implicit '.(shift->{implicit})};

sub cmp_defaults{(
  shift->SUPER::cmp_defaults,
  ignoreInfinity => 0,    # report infinity as an error
)}

#
#  Only compare two equalities
#
sub typeMatch {
  my $self = shift; my $other = shift; my $ans = shift;
  return ref($other) && $self->type eq $other->type;
}

1;
