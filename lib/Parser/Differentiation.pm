#
#  Extend differentiation to multiple variables
#  Check differentiation for complex functions
#  Do derivatives for norm and unit.
#  
#  Make shortcuts for getting numbers 1, 2, and sqrt, etc.
#  

##################################################
#
#  Differentiate the formula in terms of the given variable
#
sub Parser::D {
  my $self = shift; my $x = shift;
  if (!defined($x)) {
    my @vars = keys(%{$self->{variables}});
    my $n = scalar(@vars);
    if ($n == 0) {
      return $self->new('0') if $self->{isNumber};
      $x = 'x';
    } else {
      $self->Error("You must specify a variable to differentiate by") unless $n ==1;
      $x = $vars[0];
    }
  } else {
    return $self->new('0') unless defined $self->{variables}{$x};
  }
  return $self->new($self->{tree}->D($x));
}

sub Item::D {
  my $self = shift;
  my $type = ref($self); $type =~ s/.*:://;
  $self->Error("Differentiation for '$type' is not implemented");
}


#########################################################################

sub Parser::BOP::comma::D {Item::D(shift)}
sub Parser::BOP::union::D {Item::D(shift)}

sub Parser::BOP::add::D {
  my $self = shift; my $x = shift;
  $self = $self->{equation}{context}{parser}{BOP}->new(
    $self->{equation},$self->{bop},
    $self->{lop}->D($x),$self->{rop}->D($x)
  );
  return $self->reduce;
}


sub Parser::BOP::subtract::D {
  my $self = shift; my $x = shift;
  $self = $self->{equation}{context}{parser}{BOP}->new(
    $self->{equation},$self->{bop},
    $self->{lop}->D($x),$self->{rop}->D($x)
  );
  return $self->reduce;
}

sub Parser::BOP::multiply::D {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  $self =
    $parser->{BOP}->new($equation,'+',
      $parser->{BOP}->new($equation,$self->{bop},
        $self->{lop}->D($x),$self->{rop}->copy($equation)),
      $parser->{BOP}->new($equation,$self->{bop},
        $self->{lop}->copy($equation),$self->{rop}->D($x))
    );
  return $self->reduce;
}

sub Parser::BOP::divide::D {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  $self =
    $parser->{BOP}->new($equation,$self->{bop},
      $parser->{BOP}->new($equation,'-',
        $parser->{BOP}->new($equation,'*',
          $self->{lop}->D($x),$self->{rop}->copy($equation)),
        $parser->{BOP}->new($equation,'*',
          $self->{lop}->copy($equation),$self->{rop}->D($x))
      ),
      $parser->{BOP}->new($equation,'^',
        $self->{rop},$parser->{Number}->new($equation,2)
      )
    );
  return $self->reduce;
}

sub Parser::BOP::power::D {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  my $vars = $self->{rop}->getVariables;
  if (defined($vars->{$x})) {
    $vars = $self->{lop}->getVariables;
    if (defined($vars->{$x})) {
      $self =
        $parser->{Function}->new($equation,'exp',
          [$parser->{BOP}->new($equation,'*',$self->{rop}->copy($equation),
            $parser->{Function}->new($equation,'ln',[$self->{lop}->copy($equation)],0))]);
       return $self->D($x);
    }
    $self = $parser->{BOP}->new($equation,'*',
      $parser->{Function}->new($equation,'ln',[$self->{lop}->copy($equation)],0),
      $parser->{BOP}->new($equation,'*',
        $self->copy($equation),$self->{rop}->D($x))
    );
  } else {
    $self =
      $parser->{BOP}->new($equation,'*',
        $parser->{BOP}->new($equation,'*',
          $self->{rop}->copy($equation),
          $parser->{BOP}->new($equation,$self->{bop},
            $self->{lop}->copy($equation),
            $parser->{BOP}->new($equation,'-',
              $self->{rop}->copy($equation),
              $parser->{Number}->new($equation,1)
            )
          )
        ),
        $self->{lop}->D($x)
      );
  }
  return $self->reduce;
}

sub Parser::BOP::cross::D      {Item::D(shift)}
sub Parser::BOP::dot::D        {Item::D(shift)}
sub Parser::BOP::underscore::D {Item::D(shift)}

#########################################################################

sub Parser::UOP::plus::D {
  my $self = shift; my $x = shift;
  return $self->{op}->D($x)
}

sub Parser::UOP::minus::D {
  my $self = shift; my $x = shift;
  $self = $self->{equation}{context}{parser}{UOP}->
    new($self->{equation},'u-',$self->{op}->D($x));
  return $self->reduce;
}

sub Parser::UOP::factorial::D  {Item::D(shift)}

#########################################################################

sub Parser::Function::D {
  my $self = shift;
  $self->Error("Differentiation of '$self->{name}' not implemented");
}

sub Parser::Function::D_chain {
  my $self = shift; my $x = $self->{params}[0];
  my $name = "D_" . $self->{name};
  $self = $self->{equation}{context}{parser}{BOP}->
    new($self->{equation},'*',$self->$name($x->copy),$x->D(shift));
  return $self->reduce;
}

#############################

sub Parser::Function::trig::D {Parser::Function::D_chain(@_)}

sub Parser::Function::trig::D_sin {
  my $self = shift; my $x = shift;
  return $self->{equation}{context}{parser}{Function}->
    new($self->{equation},'cos',[$x]);
}

sub Parser::Function::trig::D_cos {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  return 
    $parser->{UOP}->new($equation,'u-',
      $parser->{Function}->new($equation,'sin',[$x])
    );
}

sub Parser::Function::trig::D_tan {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  return 
    $parser->{BOP}->new($equation,'^',
      $parser->{Function}->new($equation,'sec',[$x]),
      $parser->{Number}->new($equation,2)
    );
}

sub Parser::Function::trig::D_cot {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  return 
    $parser->{UOP}->new($equation,'u-',
      $parser->{BOP}->new($equation,'^',
        $parser->{Function}->new($equation,'csc',[$x]),
        $parser->{Number}->new($equation,2)
      )
    );
}
 
sub Parser::Function::trig::D_sec {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  return 
    $parser->{BOP}->new($equation,'*',
      $parser->{Function}->new($equation,'sec',[$x]),
      $parser->{Function}->new($equation,'tan',[$x])
    );
}

sub Parser::Function::trig::D_csc {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  return
    $parser->{UOP}->new($equation,'u-',
      $parser->{BOP}->new($equation,'*',
        $parser->{Function}->new($equation,'csc',[$x]),
        $parser->{Function}->new($equation,'cot',[$x])
      )
    );
}

sub Parser::Function::trig::D_asin {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  return
    $parser->{BOP}->new($equation,'/',
      $parser->{Number}->new($equation,1),
      $parser->{Function}->new($equation,'sqrt',[
        $parser->{BOP}->new($equation,'-',
          $parser->{Number}->new($equation,1),
          $parser->{BOP}->new($equation,'^',
            $x,$parser->{Number}->new($equation,2)
          )
        )]
      )
    );
}

sub Parser::Function::trig::D_acos {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  return
    $parser->{UOP}->new($equation,'u-',
      $parser->{BOP}->new($equation,'/',
        $parser->{Number}->new($equation,1),
        $parser->{Function}->new($equation,'sqrt',[
          $parser->{BOP}->new($equation,'-',
            $parser->{Number}->new($equation,1),
            $parser->{BOP}->new($equation,'^',
              $x,$parser->{Number}->new($equation,2)
            )
          )]
        )
      )
    );
}

sub Parser::Function::trig::D_atan {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  return
    $parser->{BOP}->new($equation,'/',
      $parser->{Number}->new($equation,1),
      $parser->{BOP}->new($equation,'+',
        $parser->{Number}->new($equation,1),
        $parser->{BOP}->new($equation,'^',
          $x, $parser->{Number}->new($equation,2)
        )
      )
    );
}

sub Parser::Function::trig::D_acot {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  return
    $parser->{UOP}->new($equation,'u-',
      $parser->{BOP}->new($equation,'/',
        $parser->{Number}->new($equation,1),
        $parser->{BOP}->new($equation,'+',
          $parser->{Number}->new($equation,1),
          $parser->{BOP}->new($equation,'^',
            $x, $parser->{Number}->new($equation,2)
          )
        )
      )
    );
}

sub Parser::Function::trig::D_asec {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  return
    $parser->{BOP}->new($equation,'/',
      $parser->{Number}->new($equation,1),
      $parser->{BOP}->new($equation,'*',
        $parser->{Function}->new($equation,'abs',[$x]),
        $parser->{Function}->new($equation,'sqrt',[
          $parser->{BOP}->new($equation,'-',
            $parser->{BOP}->new($equation,'^',
              $x, $parser->{Number}->new($equation,2)
            ),
            $parser->{Number}->new($equation,1)
          )]
        )
      )
    );
}

sub Parser::Function::trig::D_acsc {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  return
    $parser->{UOP}->new($equation,'u-',
      $parser->{BOP}->new($equation,'/',
        $parser->{Number}->new($equation,1),
        $parser->{BOP}->new($equation,'*',
          $parser->{Function}->new($equation,'abs',[$x]),
          $parser->{Function}->new($equation,'sqrt',[
            $parser->{BOP}->new($equation,'-',
              $parser->{BOP}->new($equation,'^',
                $x, $parser->{Number}->new($equation,2)
              ),
              $parser->{Number}->new($equation,1)
            )]
          )
        )
      )
    );
}


#############################

sub Parser::Function::hyperbolic::D {Parser::Function::D_chain(@_)}

sub Parser::Function::hyperbolic::D_sinh {
  my $self = shift; my $x = shift;
  return $self->{equation}{context}{parser}{Function}->
    new($self->{equation},'cosh',[$x]);
}

sub Parser::Function::hyperbolic::D_cosh {
  my $self = shift; my $x = shift;
  return $self->{equation}{context}{parser}{Function}->new($self->{equation},'sinh',[$x]);
}

sub Parser::Function::hyperbolic::D_tanh {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  return 
    $parser->{BOP}->new($equation,'^',
      $parser->{Function}->new($equation,'sech',[$x]),
      $parser->{Number}->new($equation,2)
    );
}

sub Parser::Function::hyperbolic::D_coth {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  return 
    $parser->{UOP}->new($equation,'u-',
      $parser->{BOP}->new($equation,'^',
        $parser->{Function}->new($equation,'csch',[$x]),
        $parser->{Number}->new($equation,2)
      )
    );
}
 
sub Parser::Function::hyperbolic::D_sech {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  return 
    $parser->{UOP}->new($equation,'u-',
      $parser->{BOP}->new($equation,'*',
        $parser->{Function}->new($equation,'sech',[$x]),
        $parser->{Function}->new($equation,'tanh',[$x])
      )
    );
}

sub Parser::Function::hyperbolic::D_csch {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  return
    $parser->{UOP}->new($equation,'u-',
      $parser->{BOP}->new($equation,'*',
        $parser->{Function}->new($equation,'csch',[$x]),
        $parser->{Function}->new($equation,'coth',[$x])
      )
    );
}

sub Parser::Function::hyperbolic::D_asinh {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  return
    $parser->{BOP}->new($equation,'/',
      $parser->{Number}->new($equation,1),
      $parser->{Function}->new($equation,'sqrt',[
        $parser->{BOP}->new($equation,'+',
          $parser->{Number}->new($equation,1),
          $parser->{BOP}->new($equation,'^',
            $x, $parser->{Number}->new($equation,2)
          )
        )]
      )
    );
}

sub Parser::Function::hyperbolic::D_acosh {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  return
    $parser->{BOP}->new($equation,'/',
      $parser->{Number}->new($equation,1),
      $parser->{Function}->new($equation,'sqrt',[
        $parser->{BOP}->new($equation,'-',
          $parser->{BOP}->new($equation,'^',
            $x, $parser->{Number}->new($equation,2)
          ),
          $parser->{Number}->new($equation,1)
        )]
      )
    );
}

sub Parser::Function::hyperbolic::D_atanh {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  return
    $parser->{BOP}->new($equation,'/',
      $parser->{Number}->new($equation,1),
      $parser->{BOP}->new($equation,'-',
        $parser->{Number}->new($equation,1),
        $parser->{BOP}->new($equation,'^',
          $x, $parser->{Number}->new($equation,2)
        )
      )
    );
}

sub Parser::Function::hyperbolic::D_acoth {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  return
    $parser->{BOP}->new($equation,'/',
      $parser->{Number}->new($equation,1),
      $parser->{BOP}->new($equation,'-',
        $parser->{Number}->new($equation,1),
        $parser->{BOP}->new($equation,'^',
          $x, $parser->{Number}->new($equation,2)
        )
      )
    );
}

sub Parser::Function::hyperbolic::D_asech {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  return
    $parser->{UOP}->new($equation,'u-',
      $parser->{BOP}->new($equation,'/',
        $parser->{Number}->new($equation,1),
        $parser->{BOP}->new($equation,'*',
          $x,
          $parser->{Function}->new($equation,'sqrt',[
            $parser->{BOP}->new($equation,'-',
              $parser->{Number}->new($equation,1),
              $parser->{BOP}->new($equation,'^',
                $x, $parser->{Number}->new($equation,2)
              )
            )]
          )
        )
      )
    );
}

sub Parser::Function::hyperbolic::D_acsch {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  return
    $parser->{UOP}->new($equation,'u-',
      $parser->{BOP}->new($equation,'/',
        $parser->{Number}->new($equation,1),
        $parser->{BOP}->new($equation,'*',
          $parser->{Function}->new($equation,'abs',[$x]),
          $parser->{Function}->new($equation,'sqrt',[
            $parser->{BOP}->new($equation,'+',
              $parser->{Number}->new($equation,1),
              $parser->{BOP}->new($equation,'^',
                $x, $parser->{Number}->new($equation,2)
              )
            )]
          )
        )
      )
    );
}


#############################

sub Parser::Function::numeric::D {Parser::Function::D_chain(@_)}

sub Parser::Function::numeric::D_ln {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  return $parser->{BOP}->new($equation,'/',$parser->{Number}->new($equation,1),$x);
}

sub Parser::Function::numeric::D_log {
  my $self = $_[0];
  my $base10 = $self->{equation}{context}{flags}{useBaseTenLog};
  if ($base10) {return D_log10(@_)} else {return D_ln(@_)}
}

sub Parser::Function::numeric::D_log10 {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  return
    $parser->{BOP}->new($equation,'/',
      $parser->{Number}->new($equation,1),
      $parser->{BOP}->new($equation,'*',
        $parser->{Number}->new($equation,CORE::log(10)), $x
      )
    );
}

sub Parser::Function::numeric::D_exp {
  my $self = shift;
  return $self->copy();
}

sub Parser::Function::numeric::D_sqrt {
  my $self = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  return
    $parser->{BOP}->new($equation,'/',
      $parser->{Number}->new($equation,1),
      $parser->{BOP}->new($equation,'*',
        $parser->{Number}->new($equation,2),
        $self->copy
      )
    );
}
 
sub Parser::Function::numeric::D_abs {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  return $parser->{BOP}->new($equation,'/',$x,$self->copy);
} 

sub Parser::Function::numeric::D_int {Parser::Function::D(@_)} 
sub Parser::Function::numeric::D_sgn {Parser::Function::D(@_)} 

#########################################################################

sub Parser::List::D {
  my $self = shift; my $x = shift;
  $self = $self->copy($self->{equation});
  foreach my $f (@{$self->{coords}}) {$f = $f->D($x)}
  return $self->reduce;
}


sub Parser::List::Interval::D {
  my $self = shift;
  $self->Error("Can't differentiate intervals");
}

sub Parser::List::AbsoluteValue::D {
  my $self = shift; my $x = $self->{coords}[0]->copy;
  my $equation = $self->{equation};
  my $parser = $equation->{context}{parser};
  return $parser->{BOP}->new($equation,'/', $x, $self->copy);
}


#########################################################################

sub Parser::Number::D {
  my $self = shift;
  $self->{equation}{context}{parser}{Number}->new($self->{equation},0);
}

#########################################################################

sub Parser::Complex::D {
  my $self = shift;
  $self->{equation}{context}{parser}{Number}->new($self->{equation},0);
}

#########################################################################

sub Parser::Constant::D {
  my $self = shift;
  $self->{equation}{context}{parser}{Number}->new($self->{equation},0);
}

#########################################################################

sub Parser::Value::D {
  my $self = shift; my $x = shift; my $equation = $self->{equation};
  return $equation->{context}{parser}{Value}->new($equation,$self->{value}->D($x,$equation));
}

sub Value::D {
  my $self = shift; my $x = shift; my $equation = shift;
  return 0 if $self->isComplex;
  my @coords = @{$self->{data}};
  foreach my $n (@coords)
    {if (ref($n) eq "") {$n = 0} else {$n = $n->D($x,$equation)->data}}
  return $self->new([@coords]);
}

sub Value::List::D {
  my $self = shift; my $x = shift; my $equation = shift;
  my @coords = @{$self->{data}};
  foreach my $n (@coords)
    {if (ref($n) eq "") {$n = 0} else {$n = $n->D($x)}}
  return $self->new([@coords]);
}

sub Value::Interval::D {
  shift; shift; my $self = shift;
  $self->Error("Can't differentiate intervals");
}

sub Value::Union::D {
  shift; shift; my $self = shift;
  $self->Error("Can't differentiate unions");
}

#########################################################################

sub Parser::Variable::D {
  my $self = shift; my $x = shift;
  my $d = ($self->{name} eq $x)? 1: 0;
  return $self->{equation}{context}{parser}{Number}->new($self->{equation},$d);
}

#########################################################################

sub Parser::String::D {
  my $self = shift;
  $self->{equation}{context}{parser}{Number}->new($self->{equation},0);
}

#########################################################################

package Parser::Differentiation;
our $loaded = 1;

#########################################################################

1;

