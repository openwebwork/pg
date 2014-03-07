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

parserLinearInequality.pl - Implement linear inequalities.

=head1 DESCRIPTION

This is a Parser class that implements implicit open or closed half
planes as a subclass of the Formula class.  This is built on the
implicit plane MathObject.  The first intended use case is for linear
programming problems whose domains are closed convex sets so only
closed half planes are defined at present.

Use LinearInequality(formula), Formula(formula), or Compute(formula)
to create a LinearInequality object.

Usage examples:

	$LI = LinearInequality("4x1 -3x2 <= 5");
	$LI = LinearInequality("3x2 >= 2x1");
	$LI = LinearInequality("3x2 => 2x1");       # Sloppy inequalities are allowed
        
    $LI = LinearInequality("3x1 + 4x2 < x3");
    $LI = LinearInequality("x1 - 2x2 = 5");     # equality is also supported
    $LI = Compute("x1 + 4x2 - 2x3 <= 3");       # Compute() returns a LinearInequality

Then use

	ANS($LI->cmp);

to get the answer checker for $LI.

Notice that sloppy inequality signs (i.e.  => and =< ) are allowed.

=cut

loadMacros('MathObjects.pl');

sub _parserLinearInequality_init {LinearInequality::Init()}; # don't reload this file

##################################################
#
#  Define the subclass of Formula
#
package LinearInequality;
our @ISA = qw(Value::Formula);

sub Init {
  my $context = $main::context{LinearInequality} = Parser::Context->getCopy("Vector");
  $context->{name} = "LinearInequality";
  $context->{precedence}{LinearInequality} = $context->{precedence}{special};
  $context->{value}{LinearInequality} = "LinearInequality";
  $context->{value}{Formula} = "LinearInequality::formula";
  $context->parens->remove("<");
  $context->operators->add(
     '='  => {precedence => .5, associativity => 'left', type => 'bin', string => ' = ', kind => 'eq',
	      class => 'LinearInequality::inequality', formulaClass => "LinearInequality"},

     '<'  => {precedence => .5, associativity => 'left', type => 'bin', string => ' < ', kind => 'lt',
              class => 'LinearInequality::inequality', formulaClass => "LinearInequality"},
     '>'  => {precedence => .5, associativity => 'left', type => 'bin', string => ' > ', kind => 'gt',
              reverse => 'lt', class => 'LinearInequality::inequality', formulaClass => "LinearInequality"},

     '<=' => {precedence => .5, associativity => 'left', type => 'bin', string => ' <= ', TeX => '\le ',
	      kind => "le", class => 'LinearInequality::inequality', formulaClass => "LinearInequality"},
     '=<' => {precedence => .5, associativity => 'left', type => 'bin', string => ' <= ', TeX => '\le ',
              kind => "le", class => 'LinearInequality::inequality', formulaClass => "LinearInequality"},

     '>=' => {precedence => .5, associativity => 'left', type => 'bin', string => ' >= ', TeX => '\ge ',
              kind => 'ge', reverse => 'le',
	      class => 'LinearInequality::inequality', formulaClass => "LinearInequality"},
     '=>' => {precedence => .5, associativity => 'left', type => 'bin', string => ' >= ', TeX => '\ge ',
              kind => 'ge', reverse => 'le',
	      class => 'LinearInequality::inequality', formulaClass => "LinearInequality"},

  );
  main::PG_restricted_eval('sub LinearInequality {Value->Package("LinearInequality()")->new(@_)}');
}


sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $formula = "Value::Formula";
  return shift if scalar(@_) == 1 && ref($_[0]) eq 'LinearInequality';
  $_[0] = $context->Package("Point")->new($context,$_[0]) if ref($_[0]) eq 'ARRAY';
  $_[1] = $context->Package("Vector")->new($context,$_[1]) if ref($_[1]) eq 'ARRAY';

  my ($p,$N,$plane,$vars,$d);
  if (scalar(@_) >= 2 && Value::classMatch($_[0],'Point','Vector') &&
      Value::classMatch($_[1],'Vector') || Value::isRealNumber($_[1])) {
    #
    # Make a plane from a point and a vector and optionally a 
    # symbol <= or = or =>,
    # e.g. LinearInequality($point, $vector, '<=');
    # or from a list of coefficients and the constant
    # e.g. LinearInequality($dist, [3,5,6], '<=')
    # one can optionally add new Context
    # variables ($point, $vector, '<=',[qw(a1,a2,a3)])
    $p = shift; $N = shift; my $bop = shift || "=";
    if (Value::classMatch($N,'Vector')) {
      $d = $p.$N;
    } else {
      $d = $context->Package("Real")->make($context,$N);
      $N = $context->Package("Vector")->new($context,$p);
    }
    $vars = shift || [$context->variables->names];
    $vars = [$vars] unless ref($vars) eq 'ARRAY';
    my @terms = (); my $i = 0;
    foreach my $x (@{$vars}) {push @terms, $N->{data}[$i++]->string.$x}
    $plane = $formula->new(join(' + ',@terms).$bop.$d->string)->reduce(@_);
  } else {
    #
    #  Determine the normal vector and d value from the equation
    #
    $plane = shift;
    $plane = $formula->new($context,$plane) unless Value::isValue($plane);
    $vars = shift || [$context->variables->names];
    $vars = [$vars] unless ref($vars) eq 'ARRAY';
    Value::Error("Your formula doesn't look like a linear inequality")
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
    $N = Value::Vector->new([@coeff]);
    $plane = $self->new($N,$d,$plane->{tree}{bop},$vars,'-x=-y'=>0,'-x=n'=>0)
                  ->with(original_formula => $plane);
    #
    #  Check that the student's formula really is what we thought
    #
    Value::Error("Your formula isn't a linear one") unless
      ($formula->new($plane->{tree}{lop}) - $formula->new($plane->{tree}{rop})) == $f;
  }
  Value::Error("The equation of a linear inequality must be non-zero somewhere")
    if ($N->norm == 0);
  $plane->{d} = $d; $plane->{N} = $N;
  return bless $plane, $class;
}

#
#  We already know the vectors are non-zero, so check
#  if the equations are multiples of each other.
#
sub compare {
  my ($self,$l,$r) = Value::checkOpOrder(@_);
  $l = new LinearInequality($l) unless ref($l) eq ref($self);
  $r = new LinearInequality($r) unless ref($r) eq ref($self);
  my ($lN,$ld,$ltype,$lrev) = ($l->{N},$l->{d},$l->{tree}{def}{kind},$l->{tree}{def}{reverse});
  my ($rN,$rd,$rtype,$rrev) = ($r->{N},$r->{d},$r->{tree}{def}{kind},$r->{tree}{def}{reverse});

  #
  #  Reverse inequalities if they face the wrong way
  #
  ($lN,$ld,$ltype) = (-$lN,-$ld,$lrev) if $lrev;
  ($rN,$rd,$rtype) = (-$rN,-$rd,$rrev) if $rrev;

  #
  #  First, check if the type of inequality is the same.
  #  Then check if the dividing (hyper)plane is the right one.
  #
  return 1 unless $ltype eq $rtype;
  # 'samedirection' is the second optional input to isParallel
  return $lN <=> $rN unless $lN->isParallel($rN,($ltype ne 'eq')); # inequalities require same direction which is the second optional input to isParallel
  return $ld <=> $rd if $rd == 0 || $ld == 0;
  return $rd*$lN <=> $ld*$rN;
}

sub cmp_class {'a Linear Inequality'};
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
#  things like 1 = 3, and compute the values of inequalities.
#

package LinearInequality::inequality;
our @ISA = qw(Parser::BOP::equality);

sub _check {
  my $self = shift;
  $self->SUPER::_check;
  $self->Error("An implicit equation can't be constant on both sides")
    if $self->{lop}{isConstant} && $self->{rop}{isConstant};
}

sub _eval {
  my $self = shift; my ($l,$r) = @_;
  {eq => ($l == $r), lt => ($l < $r), le => ($l <= $r),
                     gt => ($l > $r), ge => ($l >= $r)}->{$self->{def}{kind}};
}

#
#  We use a special formula object to check if the formula is a
#  LinearEquality or not, and return the proper class.  This allows
#  lists of linear equalities, for example.
#

package LinearInequality::formula;
our @ISA = ('Value::Formula');

sub new {
  my $self = shift;
  my $f = Value::Formula->new(@_);
  return $f unless $f->{tree}{def}{formulaClass};
  return $f->{tree}{def}{formulaClass}->new($f);
}
1;
