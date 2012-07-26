#
#  Extend differentiation to multiple variables
#  Check differentiation for complex functions
#  Do derivatives for norm and unit.
#
#  Make shortcuts for getting numbers 1, 2, and sqrt, etc.
#

##################################################
#
#  Differentiate the formula in terms of the given variable(s)
#
sub Parser::D {
  my $self = shift;
  my $d; my @x = @_; my $x;
  if (defined($x[0]) && $x[0] =~ m/^\d+$/) {
    $d = shift(@x);
    $self->Error("You can only specify one variable when you give a derivative count")
      unless scalar(@x) <= 1;
    return($self) if $d == 0;
  }
  if (scalar(@x) == 0) {
    my @vars = keys(%{$self->{variables}});
    my $n = scalar(@vars);
    if ($n == 0) {
      return $self->new('0') if $self->{isNumber};
      $x = 'x';
    } else {
      $self->Error("You must specify a variable to differentiate by") unless $n == 1;
      $x = $vars[0];
    }
    CORE::push(@x,$x);
  }
  @x = ($x[0]) x $d if $d;
  my $f = $self->{tree};
  foreach $x (@x) {
    return (0*$self)->reduce('0*x'=>1) unless defined $self->{variables}{$x};
    $f = $f->D($x);
  }
  return $self->new($f);
}

#
#  Overridden by the classes that DO implement differentiation
#
sub Item::D {
  my $self = shift;
  my $type = ref($self); $type =~ s/.*:://;
  $self->Error("Differentiation for '%s' is not implemented",$type);
}


#########################################################################

sub Parser::BOP::comma::D {Item::D(shift)}
sub Parser::BOP::union::D {Item::D(shift)}

sub Parser::BOP::add::D {
  my $self = shift; my $x = shift;
  $self = $self->Item("BOP")->new(
    $self->{equation},$self->{bop},
    $self->{lop}->D($x),$self->{rop}->D($x)
  );
  return $self->reduce;
}


sub Parser::BOP::subtract::D {
  my $self = shift; my $x = shift;
  $self = $self->Item("BOP")->new(
    $self->{equation},$self->{bop},
    $self->{lop}->D($x),$self->{rop}->D($x)
  );
  return $self->reduce;
}

sub Parser::BOP::multiply::D {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $BOP = $self->Item("BOP");
  $self =
    $BOP->new($equation,'+',
      $BOP->new($equation,$self->{bop},
        $self->{lop}->D($x),$self->{rop}->copy($equation)),
      $BOP->new($equation,$self->{bop},
        $self->{lop}->copy($equation),$self->{rop}->D($x))
    );
  return $self->reduce;
}

sub Parser::BOP::divide::D {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $BOP = $self->Item("BOP");
  $self =
    $BOP->new($equation,$self->{bop},
      $BOP->new($equation,'-',
        $BOP->new($equation,'*',
          $self->{lop}->D($x),$self->{rop}->copy($equation)),
        $BOP->new($equation,'*',
          $self->{lop}->copy($equation),$self->{rop}->D($x))
      ),
      $BOP->new($equation,'^',$self->{rop},$self->Item("Number")->new($equation,2))
    );
  return $self->reduce;
}

sub Parser::BOP::power::D {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $BOP = $self->Item("BOP");
  my $FN = $self->Item("Function");
  my $vars = $self->{rop}->getVariables;
  if (defined($vars->{$x})) {
    $vars = $self->{lop}->getVariables;
    if (defined($vars->{$x})) {
      $self =
        $FN->new($equation,'exp',
          [$BOP->new($equation,'*',$self->{rop}->copy($equation),
            $FN->new($equation,'ln',[$self->{lop}->copy($equation)],0))]);
       return $self->D($x);
    }
    $self = $BOP->new($equation,'*',
      $FN->new($equation,'ln',[$self->{lop}->copy($equation)],0),
      $BOP->new($equation,'*',$self->copy($equation),$self->{rop}->D($x))
    );
  } else {
    $self =
      $BOP->new($equation,'*',
        $BOP->new($equation,'*',
          $self->{rop}->copy($equation),
          $BOP->new($equation,$self->{bop},
            $self->{lop}->copy($equation),
            $BOP->new($equation,'-',
              $self->{rop}->copy($equation),
              $self->Item("Number")->new($equation,1)
            )
          )
        ),
        $self->{lop}->D($x)
      );
  }
  return $self->reduce;
}

sub Parser::BOP::dot::D {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $BOP = $self->Item("BOP");
  $self =
    $BOP->new($equation,'+',
      $BOP->new($equation,$self->{bop},
        $self->{lop}->D($x),$self->{rop}->copy($equation)),
      $BOP->new($equation,$self->{bop},
        $self->{lop}->copy($equation),$self->{rop}->D($x))
    );
  return $self->reduce;
}

sub Parser::BOP::cross::D {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $BOP = $self->Item("BOP");
  $self =
    $BOP->new($equation,'+',
      $BOP->new($equation,$self->{bop},
        $self->{lop}->D($x),$self->{rop}->copy($equation)),
      $BOP->new($equation,$self->{bop},
        $self->{lop}->copy($equation),$self->{rop}->D($x))
    );
  return $self->reduce;
}

sub Parser::BOP::underscore::D {Item::D(shift)}

#########################################################################

sub Parser::UOP::plus::D {
  my $self = shift; my $x = shift;
  return $self->{op}->D($x)
}

sub Parser::UOP::minus::D {
  my $self = shift; my $x = shift;
  $self = $self->Item("UOP")->new($self->{equation},'u-',$self->{op}->D($x));
  return $self->reduce;
}

sub Parser::UOP::factorial::D  {Item::D(shift)}

#########################################################################

sub Parser::Function::D {
  my $self = shift;
  $self->Error("Differentiation of '%s' not implemented",$self->{name});
}

sub Parser::Function::D_chain {
  my $self = shift; my $x = $self->{params}[0];
  my $name = "D_" . $self->{name};
  $self = $self->Item("BOP")->new($self->{equation},'*',$self->$name($x->copy),$x->D(shift));
  return $self->reduce;
}

#############################

sub Parser::Function::trig::D {Parser::Function::D_chain(@_)}

sub Parser::Function::trig::D_sin {
  my $self = shift; my $x = shift;
  return $self->Item("Function")->new($self->{equation},'cos',[$x]);
}

sub Parser::Function::trig::D_cos {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  return
    $self->Item("UOP")->new($equation,'u-',
      $self->Item("Function")->new($equation,'sin',[$x])
    );
}

sub Parser::Function::trig::D_tan {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  return
    $self->Item("BOP")->new($equation,'^',
      $self->Item("Function")->new($equation,'sec',[$x]),
      $self->Item("Number")->new($equation,2)
    );
}

sub Parser::Function::trig::D_cot {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  return
    $self->Item("UOP")->new($equation,'u-',
      $self->Item("BOP")->new($equation,'^',
        $self->Item("Function")->new($equation,'csc',[$x]),
        $self->Item("Number")->new($equation,2)
      )
    );
}

sub Parser::Function::trig::D_sec {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $FN = $self->Item("Function");
  return
    $self->Item("BOP")->new($equation,'*',
      $FN->new($equation,'sec',[$x]),
      $FN->new($equation,'tan',[$x])
    );
}

sub Parser::Function::trig::D_csc {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $FN = $self->Item("Function");
  return
    $self->Item("UOP")->new($equation,'u-',
      $self->Item("BOP")->new($equation,'*',
        $FN->new($equation,'csc',[$x]),
        $FN->new($equation,'cot',[$x])
      )
    );
}

sub Parser::Function::trig::D_asin {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $BOP = $self->Item("BOP");
  my $NUM = $self->Item("Number");
  return
    $BOP->new($equation,'/',
      $NUM->new($equation,1),
      $self->Item("Function")->new($equation,'sqrt',[
        $BOP->new($equation,'-',
          $NUM->new($equation,1),
          $BOP->new($equation,'^',$x,$NUM->new($equation,2))
        )]
      )
    );
}

sub Parser::Function::trig::D_acos {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $BOP = $self->Item("BOP");
  my $NUM = $self->Item("Number");
  return
    $self->Item("UOP")->new($equation,'u-',
      $BOP->new($equation,'/',
        $NUM->new($equation,1),
        $self->Item("Function")->new($equation,'sqrt',[
          $BOP->new($equation,'-',
            $NUM->new($equation,1),
            $BOP->new($equation,'^',$x,$NUM->new($equation,2))
          )]
        )
      )
    );
}

sub Parser::Function::trig::D_atan {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $BOP = $self->Item("BOP");
  my $NUM = $self->Item("Number");
  return
    $BOP->new($equation,'/',
      $NUM->new($equation,1),
      $BOP->new($equation,'+',
        $NUM->new($equation,1),
        $BOP->new($equation,'^',$x,$NUM->new($equation,2))
      )
    );
}

sub Parser::Function::trig::D_acot {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $BOP = $self->Item("BOP");
  my $NUM = $self->Item("Number");
  return
    $self->Item("UOP")->new($equation,'u-',
      $BOP->new($equation,'/',
        $NUM->new($equation,1),
        $BOP->new($equation,'+',
          $NUM->new($equation,1),
          $BOP->new($equation,'^',$x,$NUM->new($equation,2))
        )
      )
    );
}

sub Parser::Function::trig::D_asec {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $BOP = $self->Item("BOP");
  my $NUM = $self->Item("Number");
  my $FN = $self->Item("Function");
  return
    $BOP->new($equation,'/',
      $NUM->new($equation,1),
      $BOP->new($equation,'*',
        $FN->new($equation,'abs',[$x]),
        $FN->new($equation,'sqrt',[
          $BOP->new($equation,'-',
            $BOP->new($equation,'^',$x,$NUM->new($equation,2)),
            $NUM->new($equation,1)
          )]
        )
      )
    );
}

sub Parser::Function::trig::D_acsc {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $BOP = $self->Item("BOP");
  my $NUM = $self->Item("Number");
  my $FN = $self->Item("Function");
  return
    $self->Item("UOP")->new($equation,'u-',
      $BOP->new($equation,'/',
        $NUM->new($equation,1),
        $BOP->new($equation,'*',
          $FN->new($equation,'abs',[$x]),
          $FN->new($equation,'sqrt',[
            $BOP->new($equation,'-',
              $BOP->new($equation,'^',$x,$NUM->new($equation,2)),
              $NUM->new($equation,1)
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
  return $self->Item("Function")->new($self->{equation},'cosh',[$x]);
}

sub Parser::Function::hyperbolic::D_cosh {
  my $self = shift; my $x = shift;
  return $self->Item("Function")->new($self->{equation},'sinh',[$x]);
}

sub Parser::Function::hyperbolic::D_tanh {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  return
    $self->Item("BOP")->new($equation,'^',
      $self->Item("Function")->new($equation,'sech',[$x]),
      $self->Item("Number")->new($equation,2)
    );
}

sub Parser::Function::hyperbolic::D_coth {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  return
    $self->Item("UOP")->new($equation,'u-',
      $self->Item("BOP")->new($equation,'^',
        $self->Item("Function")->new($equation,'csch',[$x]),
        $self->Item("Number")->new($equation,2)
      )
    );
}

sub Parser::Function::hyperbolic::D_sech {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $FN = $self->Item("Function");
  return
    $self->Item("UOP")->new($equation,'u-',
      $self->Item("BOP")->new($equation,'*',
        $FN->new($equation,'sech',[$x]),
        $FN->new($equation,'tanh',[$x])
      )
    );
}

sub Parser::Function::hyperbolic::D_csch {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $FN = $self->Item("Function");
  return
    $self->Item("UOP")->new($equation,'u-',
      $self->Item("BOP")->new($equation,'*',
        $FN->new($equation,'csch',[$x]),
        $FN->new($equation,'coth',[$x])
      )
    );
}

sub Parser::Function::hyperbolic::D_asinh {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $BOP = $self->Item("BOP");
  my $NUM = $self->Item("Number");
  return
    $BOP->new($equation,'/',
      $NUM->new($equation,1),
      $self->Item("Function")->new($equation,'sqrt',[
        $BOP->new($equation,'+',
          $NUM->new($equation,1),
          $BOP->new($equation,'^',$x,$NUM->new($equation,2))
        )]
      )
    );
}

sub Parser::Function::hyperbolic::D_acosh {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $BOP = $self->Item("BOP");
  my $NUM = $self->Item("Number");
  return
    $BOP->new($equation,'/',
      $NUM->new($equation,1),
      $self->Item("Function")->new($equation,'sqrt',[
        $BOP->new($equation,'-',
          $BOP->new($equation,'^',$x,$NUM->new($equation,2)),
          $NUM->new($equation,1)
        )]
      )
    );
}

sub Parser::Function::hyperbolic::D_atanh {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $BOP = $self->Item("BOP");
  my $NUM = $self->Item("Number");
  return
    $BOP->new($equation,'/',
      $NUM->new($equation,1),
      $BOP->new($equation,'-',
        $NUM->new($equation,1),
        $BOP->new($equation,'^',$x,$NUM->new($equation,2))
      )
    );
}

sub Parser::Function::hyperbolic::D_acoth {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $BOP = $self->Item("BOP");
  my $NUM = $self->Item("Number");
  return
    $BOP->new($equation,'/',
      $NUM->new($equation,1),
      $BOP->new($equation,'-',
        $NUM->new($equation,1),
        $BOP->new($equation,'^',$x,$NUM->new($equation,2))
      )
    );
}

sub Parser::Function::hyperbolic::D_asech {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $BOP = $self->Item("BOP");
  my $NUM = $self->Item("Number");
  return
    $self->Item("UOP")->new($equation,'u-',
      $BOP->new($equation,'/',
        $NUM->new($equation,1),
        $BOP->new($equation,'*',
          $x,
          $self->Item("Function")->new($equation,'sqrt',[
            $BOP->new($equation,'-',
              $NUM->new($equation,1),
              $BOP->new($equation,'^',$x,$NUM->new($equation,2))
            )]
          )
        )
      )
    );
}

sub Parser::Function::hyperbolic::D_acsch {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $BOP = $self->Item("BOP");
  my $NUM = $self->Item("Number");
  my $FN = $self->Item("Function");
  return
    $self->Item("UOP")->new($equation,'u-',
      $BOP->new($equation,'/',
        $NUM->new($equation,1),
        $BOP->new($equation,'*',
          $FN->new($equation,'abs',[$x]),
          $FN->new($equation,'sqrt',[
            $BOP->new($equation,'+',
              $NUM->new($equation,1),
              $BOP->new($equation,'^',$x,$NUM->new($equation,2))
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
  return $self->Item("BOP")->new($equation,'/',$self->Item("Number")->new($equation,1),$x);
}

sub Parser::Function::numeric::D_log {
  my $self = shift;
  my $base10 = $self->{equation}{context}{flags}{useBaseTenLog};
  if ($base10) {return $self->D_log10(@_)} else {return $self->D_ln(@_)}
}

sub Parser::Function::numeric::D_log10 {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  my $BOP = $self->Item("BOP");
  my $NUM = $self->Item("Number");
  return
    $BOP->new($equation,'/',
      $NUM->new($equation,1),
      $BOP->new($equation,'*',
        $NUM->new($equation,CORE::log(10)), $x
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
  my $BOP = $self->Item("BOP");
  my $NUM = $self->Item("Number");
  return
    $BOP->new($equation,'/',
      $NUM->new($equation,1),
      $BOP->new($equation,'*',
        $NUM->new($equation,2),
        $self->copy
      )
    );
}

sub Parser::Function::numeric::D_abs {
  my $self = shift; my $x = shift;
  my $equation = $self->{equation};
  return $self->Item("BOP")->new($equation,'/',$x,$self->copy);
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
  my $BOP = $self->Item("BOP");
  return
    $BOP->new($equation,"*",
      $BOP->new($equation,'/', $x, $self->copy),
      $x->D(shift),
   );
}


#########################################################################

sub Parser::Number::D {
  my $self = shift;
  $self->Item("Number")->new($self->{equation},0);
}

#########################################################################

sub Parser::Complex::D {
  my $self = shift;
  $self->Item("Number")->new($self->{equation},0);
}

#########################################################################

sub Parser::Constant::D {
  my $self = shift; my $x = shift;
  return $self->{def}{value}{tree}->D($x) if Value::isFormula($self->{def}{value});
  $self->Item("Value")->new($self->{equation},0*$self->{def}{value});
}

#########################################################################

sub Parser::Value::D {
  my $self = shift; my $x = shift; my $equation = $self->{equation};
  return $self->Item("Value")->new($equation,$self->{value}->D($x));
}

sub Value::D {
  my $self = shift; my $x = shift;
  my @coords = $self->value;
  foreach my $n (@coords)
    {if (ref($n) eq "") {$n = 0} else {$n = $n->D($x)->value}}
  return $self->new(@coords);
}

sub Value::List::D {
  my $self = shift; my $x = shift;
  my @coords = $self->value;
  foreach my $n (@coords)
    {if (ref($n) eq "") {$n = 0} else {$n = $n->D($x)}}
  return $self->new([@coords]);
}

sub Value::Interval::D {
  shift; shift; my $self = shift;
  $self->Error("Can't differentiate intervals");
}

sub Value::Set::D {
  shift; shift; my $self = shift;
  $self->Error("Can't differentiate sets");
}

sub Value::Union::D {
  shift; shift; my $self = shift;
  $self->Error("Can't differentiate unions");
}

#########################################################################

sub Parser::Variable::D {
  my $self = shift; my $x = shift;
  my $d = ($self->{name} eq $x)? 1: 0;
  return $self->Item("Number")->new($self->{equation},$d);
}

#########################################################################

sub Parser::String::D {
  my $self = shift;
  $self->Item("Number")->new($self->{equation},0);
}

#########################################################################

package Parser::Differentiation;
our $loaded = 1;

#########################################################################

1;
