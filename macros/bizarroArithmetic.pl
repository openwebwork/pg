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
This has been extended below to a choice for f that works with complex numbers too.

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
'u-' => {class => 'bizarro::UOP::minus', isCommand => 1},
);

At this point the arithmetic operators will still be behaving as normal.
Turn on the bizarro arithmetic with:

Context()->flags->set(bizarroAdd=>1);
Context()->flags->set(bizarroSub=>1);
Context()->flags->set(bizarroMul=>1);
Context()->flags->set(bizarroDiv=>1);
Context()->flags->set(bizarroPow=>1);
Context()->flags->set(bizarroNeg=>1);


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
      Context()->flags->set(bizarroDiv=>1);
      delete $correct->{test_values};
      delete $student->{test_values};
      my $OK = ($correct == $student);
      Context()->flags->set(bizarroDiv=>0);
      Value::Error("Your answer is equivalent to the correct answer, but not in the expected form.
                    Maybe it needs to be simplified, factored, expanded, have its denominator rationalized, etc.") unless $OK;
      return $OK;
}));

=cut




###########################
#
#  functions used in defining bizarro arithmetic
#

package bizarro;

#This f just stretches complex numbers by a positve real that
#depends in a nontrivial away on the magnitude of z
sub f {
  my $z = shift;
  my $r = abs($z);
  return 0 if ($r == 0);
  return $z * ($r**2 + 3);
}

#The inverse of f.
sub g {
  my $z = shift;
  my $r = abs($z);
  return 0 if ($r == 0);
  my $k = sqrt(($r)**2+4);
  #Note that in what follows, base of (1/3) exponent is always a positive real
  #because $k > $r > 0 
  return $z/$r * ((($k+$r)/2)**(1/3) - (($k-$r)/2)**(1/3));
}


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

###########################
#
#  Subclass the negation
#
package bizarro::UOP::minus;
our @ISA = ('Parser::UOP::minus');

sub _eval {
  my $self = shift;
  my $context = $self->context;
  my $a = shift;
  if ($context->flag("bizarroNeg")) {
    return bizarro::f(bizarro::g(-1) * bizarro::g($a));
  } else {
    return -$a;
  }
};

sub call {(shift)->_eval(@_)};





1;


