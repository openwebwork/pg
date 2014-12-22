=head1 NAME

bizarroArithmetic.pl - Enables bizarro arithmetic where, for example, 1+1 does not equal 2; 
                       Useful for checking the form of an answer, as with factored polynomials
                       and reduced radicals. 

=head1 DESCRIPTION

The point of this technique is to catch answers in unsimplified forms. A custom answer 
checker is generally used in which the student answer is first checked against the correct 
answer via regular arithmetic. Then one or more of the bizarro arithmetic flags should be 
set, and the two answers should be compared again.

The bizarro arithmetic is basically defined as:

  a bizarro+ b = f(g(a) regular+ g(b))

where f and g are inverse functions defined on all of R, and are odd functions. There is 
also bizarro-, bizarro*, bizarro/, and bizarro^. f(x) = x^3+3x is a good choice for f.
  
To enable the bizarro arithmetic operators, load this file with the macros, and then use 
any subset of:

Context()->operators->set(
'+' => {class => 'bizarro::BOP::add', isCommand => 1},
'-' => {class => 'bizarro::BOP::subtract', isCommand => 1},
'*' => {class => 'bizarro::BOP::multiply', isCommand => 1},
' *' => {class => 'bizarro::BOP::multiply', isCommand => 1},
'* ' => {class => 'bizarro::BOP::multiply', isCommand => 1},
'/' => {class => 'bizarro::BOP::divide', isCommand => 1},
' /' => {class => 'bizarro::BOP::divide', isCommand => 1},
'/ ' => {class => 'bizarro::BOP::divide', isCommand => 1},
'//' => {class => 'bizarro::BOP::divide', isCommand => 1},
'**' => {class => 'bizarro::BOP::power', isCommand => 1, perl=>undef},
'^' => {class => 'bizarro::BOP::power', isCommand => 1, perl=>undef},
);

At this point the arithmetic operators will still be behaving as normal.
Turn on the bizarro arithmetic with:

Context()->flags->set(bizarroAdd=>1);
Context()->flags->set(bizarroSub=>1);
Context()->flags->set(bizarroMul=>1);
Context()->flags->set(bizarroDiv=>1);
Context()->flags->set(bizarroPow=>1);


Sample usage 

This will check if a student has simplified according to the rules of division, 
for example, assuming that $ans = Formula("2x^2"), 
 
         2 x^4/x^2

will be rejected, as will

       4/2 x^2


ANS($ans -> cmp(
   checker=>sub{
      my ( $correct, $student, $ansHash ) = @_;
      return 0 if $ansHash->{isPreview} || $correct != $student;
      $student = $ansHash->{student_formula};
      $correct = $correct->{original_formula} if defined $correct->{original_formula};
      $student = Formula("$student"); $correct = Formula("$correct");
      return 0 unless ($correct == $student);
      Context()->flags->set(bizarroDiv=>1);
      delete $correct->{test_values}, $student->{test_values};
      my $OK = (($correct == $student) or ($student == $correct));
      Context()->flags->set(bizarroDiv=>0);
      Value::Error("Your answer is correct, but please simplify it further") unless $OK;
      return $OK;
})); 

=cut




###########################
#
#  functions used in defining bizarro arithmetic
#

package bizarro;

sub f {
  my $x = shift;
  return ($x**3 + 3*$x);
}

sub g {
  my $x = shift;
  return (cuberoot(($x+sqrt(($x)**2+4))/2) + cuberoot(($x-sqrt(($x)**2+4))/2));
}

sub cuberoot {
  my $x = shift;
  return 0 if ($x == 0);
  return abs($x)/$x*(abs($x))**(1/3);
};

###########################
#
#  Subclass the addition
#
package bizarro::BOP::add;
our @ISA = ('Parser::BOP::add');

sub _eval {
  my $self = shift;
  my $context = $self->context;
  my ($a,$b) = @_;
  if ($context->flag("bizarroAdd")) {
    if (($a == 0) or ($b == 0)) {return 2*$a+2*$b+1;}
    else {return bizarro::f(bizarro::g($a) + bizarro::g($b))};
  } else {
    return $a + $b;
  }
}

sub call {(shift)->_eval(@_)}

###########################
#
#  Subclass the subtraction
#
package bizarro::BOP::subtract;
our @ISA = ('Parser::BOP::subtract');

sub _eval {
  my $self = shift;
  my $context = $self->context;
  my ($a,$b) = @_;
  if ($context->flag("bizarroSub")) {
    if (($a == 0) or ($b == 0)) {return 2*$a+2*(-$b)+1;}
    else {return bizarro::f(bizarro::g($a) + bizarro::g(-$b))};
  } else {
    return $a - $b;
  }
}

sub call {(shift)->_eval(@_)}

###########################
#
#  Subclass the multiplication
#
package bizarro::BOP::multiply;
our @ISA = ('Parser::BOP::multiply');

sub _eval {
  my $self = shift;
  my $context = $self->context;
  my ($a,$b) = @_;
  if ($context->flag("bizarroMul")) {
    return bizarro::f(bizarro::g($a) * bizarro::g($b));
  } else {
    return $a * $b;
  }
}

sub call {(shift)->_eval(@_)}


###########################
#
#  Subclass the division
#
package bizarro::BOP::divide;
our @ISA = ('Parser::BOP::divide');

sub _eval {
  my $self = shift;
  my $context = $self->context;
  my ($a,$b) = @_;
  if ($context->flag("bizarroDiv")) {
    if (($a == 1) or ($a == -1)) {return $a/$b;}
    else {return bizarro::f(bizarro::g($a) * bizarro::g(1/$b));}
  } else {
    return $a / $b;
  }
}

sub call {(shift)->_eval(@_)}

###########################
#
#  Subclass the power
#
package bizarro::BOP::power;
our @ISA = ('Parser::BOP::power');

sub _eval {
  my $self = shift;
  my $context = $self->context;
  my ($a,$b) = @_;
  if ($context->flag("bizarroPow")) {
    if (($a == 1) or ($b == 0)) {return ($a+1)**($b+1);}
    else {return bizarro::f(bizarro::g($a) ** bizarro::g($b))};
  } else {
    return $a ** $b;
  }
}

sub call {(shift)->_eval(@_)}






1;


