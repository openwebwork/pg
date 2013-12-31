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

This is a Parser class that implements implicit closed half planes as
a subclass of the Formula class.  This is built on the implicit plane 
MathObject.  The first intended use case is for linear programming problems
whose domains are closed convex sets so only closed half planes are defined
at present.

From implicitPlanes: "The standard ->cmp routine
will work for this, provided we define the compare() function
needed by the overloaded ==.  We assign the special precedence
so that overloaded operations will be promoted to the ones below."
(I'm not sure I completely understand this  yet. )

Use LinearInequality(formula) to create an LinearInequality object.


Usage examples:

	$LI = LinearInequality("4x1 -3x2 <= 5");
	$LI = LinearInequality("3x2 >= 2x1"); 
	$LI = LinearInequality("3x2 => 2x1");
	
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
  #$context->{value}{Equality} = "LinearInequality::equality";
  Parser::BOP::equality->Allow($context);
  $context->operators->set('=' => {class => 'LinearInequality::equality'});
  $context->operators->add(
#      '<'  => {precedence => .5, associativity => 'left', type => 'bin', string => ' < ',
#               class => 'LinearInequality::inequality', eval => 'evalLessThan', combine => 1},
# 
#      '>'  => {precedence => .5, associativity => 'left', type => 'bin', string => ' > ',
#               class => 'LinearInequality::inequality', eval => 'evalGreaterThan', combine => 1},

     '<=' => {precedence => .5, associativity => 'left', type => 'bin', string => ' <= ', TeX => '\le ',
              class => 'LinearInequality::inequality', eval => 'evalLessThanOrEqualTo', combine => 1},
     '=<' => {precedence => .5, associativity => 'left', type => 'bin', string => ' <= ', TeX => '\le ',
              class => 'LinearInequality::inequality', eval => 'evalLessThanOrEqualTo', combine => 1,
              isSloppy => "<="},

     '>=' => {precedence => .5, associativity => 'left', type => 'bin', string => ' >= ', TeX => '\ge ',
              class => 'LinearInequality::inequality', eval => 'evalGreaterThanOrEqualTo', combine => 1},
     '=>' => {precedence => .5, associativity => 'left', type => 'bin', string => ' >= ', TeX => '\ge ',
              class => 'LinearInequality::inequality', eval => 'evalGreaterThanOrEqualTo', combine => 1,
              isSloppy => ">="},

  );
  # main::Context("LinearInequality");  ### FIXME:  probably should require authors to set this explicitly
  main::PG_restricted_eval('sub LinearInequality { 
                                warn("Must set context to \'LinearInequality\' in order to use LinearInequality()\n") # FIXME --warning method needs work
                                  unless Context()->{name} eq "LinearInequality"; 
                                LinearInequality->new(@_);
                            }'                      
  );
}
  

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  return shift if scalar(@_) == 1 && ref($_[0]) eq 'LinearInequality';
  $_[0] = $context->Package("Point")->new($context,$_[0]) if ref($_[0]) eq 'ARRAY';
  $_[1] = $context->Package("Vector")->new($context,$_[1]) if ref($_[1]) eq 'ARRAY';

  my ($p,$N,$plane,$vars,$d,$type); 
  $type = 'plane';
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
    my $original_formula = $plane;
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
    
    $plane = $plane->reduce; 
    # Find type of formula (inequality or equality)
    #
    my $implicit_type = $plane->{tree}{bop}; 
    # main::DEBUG_MESSAGE("original implicit type ", $plane->{tree}{bop});   
    #  Check that the student's formula really is what we thought
    #
    $N = Value::Vector->new([@coeff]);
    my $test_plane = LinearInequality->new($N,$d,$vars,'-x=-y'=>0,'-x=n'=>0);
    #main::DEBUG_MESSAGE("compute new plane");
    Value::Error("Your formula isn't a linear one") unless ($formula->new($test_plane->{tree}{lop}) -
              $formula->new($test_plane->{tree}{rop})) == $f;
              
    # we use the original equation instead of the test_plane since the original equation has the original formula
    # determine type of equation and record
    if ($implicit_type eq '=') {
    	$plane->{implicit_type}= "equal";
    } elsif ($implicit_type eq "<=" or $implicit_type eq "=<" ) {
    	$plane->{implicit_type}= "lessthanorequal"
    } elsif (($implicit_type eq ">=" or $implicit_type eq "=>" )) {
     	$plane->{implicit_type}= "greaterthanorequal"
    } else {
    	Value::Error("Your formula should use only = or <= or >=  inequalities");
    }
    
    $plane->{original_formula} = $original_formula;
    #main::DEBUG_MESSAGE("next implicit type ", $plane->{implicit_type} );
  }
  Value::Error("The equation of a %s must be non-zero somewhere",$type)
    if ($N->norm == 0);
  $plane->{d} = $d; $plane->{N} = $N; $plane->{implicit} = $type;
#   main::DEBUG_MESSAGE("original formula ", $plane->{original_formula}  );
#   main::DEBUG_MESSAGE(" full tree is ", PGcore::pretty_print($plane->{tree}) ) if $plane->{original_formula};
#   main::DEBUG_MESSAGE(" plane is ", PGcore::pretty_print({ 
#          string=>$plane->{string}, 
#          tokens=> $plane->{tokens},
#          variables => $plane->{variables}  }) ) if $plane->{original_formula};
  return bless $plane, $class;
}

#
#  We already know the vectors are non-zero, so check
#  if the equations are multiples of each other.
#
sub compare {
  my ($self,$l,$r) = Value::checkOpOrder(@_);
  $r = new LinearInequality($r);# if ref($r) ne ref($self);
  $l = new LinearInequality($self) unless ref($l);# if ref($r) ne ref($self); #FIXME is this needed?
  my ($lN,$ld, $ltype) = ($l->{N},$l->{d},$l->{implicit_type});
  my ($rN,$rd, $rtype) = ($r->{N},$r->{d},$r->{implicit_type});
  
  # main::DEBUG_MESSAGE("comparison1 ltype $ltype, rtype $rtype, lN $lN, ld $ld, rN $rN, rd $rd");
  
  # normalize inequalities for checking
  if ($ltype eq "greaterthanorequal") {
  	  $ltype = "lessthanorequal";
  	  $lN = -$lN;
  	  $ld = -$ld;
  }
  if ($rtype eq "greaterthanorequal") {
  	  $rtype = "lessthanorequal";
  	  $rN = -$rN;
  	  $rd = -$rd;
  }
  # main::DEBUG_MESSAGE("comparison2 ltype $ltype, rtype $rtype, lN $lN, ld $ld, rN $rN, rd $rd");
  my $does_not_match = 0<=>1; 
  return $does_not_match unless ($ltype eq $rtype); #equality and lessthanorequal  types cannot be made to match
  # main::DEBUG_MESSAGE('types are the same '. $rd*$ld);
  if ($ltype ne 'equal' and ( $rd*$ld ) < 0 ) { # inequalities must have the same sign on the rhs.
    # main::DEBUG_MESSAGE("first case");
  	return $does_not_match;
  } elsif ($rd*$ld == 0 ) {
    # main::DEBUG_MESSAGE("second case");
    return $rd <=> $ld unless $rd == $ld; # will match if they are both fuzzy zero, otherwise no
    my $sameDirection = ($ltype eq 'equal') ? 0: 1;
    return $lN <=> $rN unless $lN->isParallel($rN, $sameDirection) ; # directions must match for inequality but not equalities
    return 0;           # they do  match -- the normals are parallel.
  } else {
    # main::DEBUG_MESSAGE("last case");
  	return $rd*$lN <=> $ld*$rN # normals are parallel and the correct multiples of each other
  }
}

sub cmp_class {'a LinearInequality '.(shift->{implicit})};
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

package LinearInequality::equality;
our @ISA = qw(Parser::BOP::equality);

sub _check {
  my $self = shift;
  $self->SUPER::_check;
  $self->Error("An implicit equation can't be constant on both sides")
    if $self->{lop}{isConstant} && $self->{rop}{isConstant};
}

#
#  We subclass BOP::equality so that we can give a warning about
#  things like 1 = 3
#

package LinearInequality::inequality;
our @ISA = qw(Parser::BOP::equality);

sub _check {
  my $self = shift;
  $self->SUPER::_check;
  $self->Error("An implicit equation can't be constant on both sides")
    if $self->{lop}{isConstant} && $self->{rop}{isConstant};
}

1;
