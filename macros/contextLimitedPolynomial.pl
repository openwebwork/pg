loadMacros("Parser.pl");

sub _contextLimitedPolynomial_init {}; # don't load it again

##########################################################
#
#  Implements a context in which students can only 
#  enter (expanded) polynomials (i.e., sums of multiples
#  of powers of x).
#
#  Select the context using:
#
#      Context("LimitedPolynomial");
#
#  If you set the "singlePowers" flag, then only one monomial of
#  each degree can be included in the polynomial:
#
#      Context("LimitedPolynomial")->flags->set(singlePowers=>1);
#

#
#  Handle common checking for BOPs
#
package LimitedPolynomial::BOP;

#
#  Do original check and then if the operands are numbers, its OK.
#  Otherwise, do an operator-specific check for if the polynomial is OK.
#  Otherwise report an error.
#
sub _check {
  my $self = shift;
  my $super = ref($self); $super =~ s/LimitedPolynomial/Parser/;
  &{$super."::_check"}($self);
  return if LimitedPolynomial::isConstant($self->{lop}) &&
            LimitedPolynomial::isConstant($self->{rop});
  return if $self->checkPolynomial;
  $self->Error("Your answer doesn't look like a polynomial");
}

#
#  filled in by subclasses
#
sub checkPolynomial {return 0}

#
#  Check that the powers of combined monomials are OK
#  and record the new power list
#
sub checkPowers {
  my $self = shift;
  my ($l,$r) = ($self->{lop},$self->{rop});
  my $single = $self->{equation}{context}->flag('singlePowers');
  $self->{isPoly} = 1;
  $self->{powers} = $l->{powers}? {%{$l->{powers}}} : {};
  $r->{powers} = {1=>1} if $r->class eq 'Variable';
  return 1 unless $r->{powers};
  foreach my $n (keys(%{$r->{powers}})) {
    $self->Error("Polynomials can have at most one term of each degree")
      if $self->{powers}{$n} && $single;
    $self->{powers}{$n} = 1;
  }
  return 1;
}

package LimitedPolynomial;

#
#  Check for a constant expression
#
sub isConstant {
  my $self = shift;
  return 1 if $self->{isConstant} || $self->class eq 'Constant';
  return scalar(keys(%{$self->getVariables})) == 0;
}

##############################################
#
#  Now we get the individual replacements for the operators
#  that we don't want to allow.  We inherit everything from
#  the original Parser::BOP class, and just add the
#  polynomial checks here.  Note that checkpolynomial
#  only gets called if at least one of the terms is not
#  a number.
#

package LimitedPolynomial::BOP::add;
our @ISA = qw(LimitedPolynomial::BOP Parser::BOP::add);

sub checkPolynomial {
  my $self = shift;
  my ($l,$r) = ($self->{lop},$self->{rop});
  $self->Error("Addition is allowed only between monomials")
    if $r->{isPoly};
  $self->checkPowers;
}

##############################################

package LimitedPolynomial::BOP::subtract;
our @ISA = qw(LimitedPolynomial::BOP Parser::BOP::subtract);

sub checkPolynomial {
  my $self = shift;
  my ($l,$r) = ($self->{lop},$self->{rop});
  $self->Error("Subtraction is only allowed between monomials")
    if $r->{isPoly};
  $self->checkPowers;
}

##############################################

package LimitedPolynomial::BOP::multiply;
our @ISA = qw(LimitedPolynomial::BOP Parser::BOP::multiply);

sub checkPolynomial {
  my $self = shift;
  my ($l,$r) = ($self->{lop},$self->{rop});
  if (LimitedPolynomial::isConstant($l) && ($r->{isPower} || $r->class eq 'Variable')) {
    $r->{powers} = {1=>1} unless $r->{isPower};
    $self->{powers} = {%{$r->{powers}}};
    return 1;
  }
  $self->Error("Coefficients must come before variables in a polynomial")
    if LimitedPolynomial::isConstant($r) && ($l->{isPower} || $l->class eq 'Variable');
  $self->Error("Multiplication can only be used between coefficients and variables");
}

##############################################

package LimitedPolynomial::BOP::divide;
our @ISA = qw(LimitedPolynomial::BOP Parser::BOP::divide);

sub checkPolynomial {
  my $self = shift;
  my ($l,$r) = ($self->{lop},$self->{rop});
  $self->Error("You can only divide by a number in a polynomial")
    unless LimitedPolynomial::isConstant($r);
  $self->Error("You can only divide a single monomial by a number")
    if $l->{isPoly} && $l->{isPoly} == 1;
  $self->{isPoly} = $l->{isPoly};
  $self->{powers} = {%{$l->{powers}}} if $l->{powers};
  return 1;
}

##############################################

package LimitedPolynomial::BOP::power;
our @ISA = qw(LimitedPolynomial::BOP Parser::BOP::power);

sub checkPolynomial {
  my $self = shift;
  my ($l,$r) = ($self->{lop},$self->{rop});
  $self->{isPower} = 1;
  $self->Error("You can only raise a variable to a power in a polynomial")
    unless $l->class eq 'Variable';
  $self->Error("Exponents must be constant in a polynomial")
    unless LimitedPolynomial::isConstant($r);
  my $n = Parser::Evaluate($r);
  $r->Error($$Value::context->{error}{message}) if $$Value::context->{error}{flag};
  $self->Error("Exponents must be positive integers in a polynomial")
    unless $n > 0 && $n == int($n);
  $self->{powers} = {$n=>1};
  return 1;
}

##############################################
##############################################
#
#  Now we do the same for the unary operators
#

package LimitedPolynomial::UOP;

sub _check {
  my $self = shift;
  my $super = ref($self); $super =~ s/LimitedPolynomial/Parser/;
  &{$super."::_check"}($self);
  my $op = $self->{op};
  return if LimitedPolynomail::isConstant($op);
  $self->Error("You can only use '$self->{def}{string}' with monomials")
    if $op->{isPoly};
  $self->{isPoly} = 2;
  $self->{powers} = {%{$op->{powers}}} if $op->{powers};
}

sub checkPolynomial {return 0}

##############################################

package LimitedPolynomial::UOP::plus;
our @ISA = qw(LimitedPolynomial::UOP Parser::UOP::plus);

##############################################

package LimitedPolynomial::UOP::minus;
our @ISA = qw(LimitedPolynomial::UOP Parser::UOP::minus);

##############################################
##############################################
#
#  Don't allow absolute values
#

package LimitedPolynomial::List::AbsoluteValue;
our @ISA = qw(Parser::List::AbsoluteValue);

sub _check {
  my $self = shift;
  $self->SUPER::_check;
  return if LimitedPolynomial::isConstant($self->{coords}[0]);
  $self->Error("Can't use absolute values in polynomials");
}

##############################################
##############################################
#
#  Only allow numeric function calls
#

package LimitedPolynomial::Function;

sub _check {
  my $self = shift;
  my $super = ref($self); $super =~ s/LimitedPolynomial/Parser/;
  &{$super."::_check"}($self);
  my $arg = $self->{params}->[0];
  return if LimitedPolynomial::isConstant($arg);
  $self->Error("Function '$self->{name}' can only be used with numbers");  
}


package LimitedPolynomial::Function::numeric;
our @ISA = qw(LimitedPolynomial::Function Parser::Function::numeric);

package LimitedPolynomial::Function::trig;
our @ISA = qw(LimitedPolynomial::Function Parser::Function::trig);

##############################################
##############################################

package main;

#
#  Now build the new context that calls the
#  above classes rather than the usual ones
#

$context{LimitedPolynomial} = Context("Numeric");
$context{LimitedPolynomial}->operators->set(
   '+' => {class => 'LimitedPolynomial::BOP::add'},
   '-' => {class => 'LimitedPolynomial::BOP::subtract'},
   '*' => {class => 'LimitedPolynomial::BOP::multiply'},
  '* ' => {class => 'LimitedPolynomial::BOP::multiply'},
  ' *' => {class => 'LimitedPolynomial::BOP::multiply'},
   ' ' => {class => 'LimitedPolynomial::BOP::multiply'},
   '/' => {class => 'LimitedPolynomial::BOP::divide'},
  ' /' => {class => 'LimitedPolynomial::BOP::divide'},
  '/ ' => {class => 'LimitedPolynomial::BOP::divide'},
   '^' => {class => 'LimitedPolynomial::BOP::power'},
  '**' => {class => 'LimitedPolynomial::BOP::power'},
  'u+' => {class => 'LimitedPolynomial::UOP::plus'},
  'u-' => {class => 'LimitedPolynomial::UOP::minus'},
);
#
#  Remove these operators and functions
#
$context{LimitedPolynomial}->lists->set(
  AbsoluteValue => {class => 'LimitedPolynomial::List::AbsoluteValue'},
);
$context{LimitedPolynomial}->operators->undefine('_','!','U');
$context{LimitedPolynomial}->functions->disable("Hyperbolic","atan2");
#
#  Hook into the numeric and trig functions
#
foreach ('sin','cos','tan','sec','csc','cot',
         'asin','acos','atan','asec','acsc','acot') {
  $context{LimitedPolynomial}->functions->set(
     "$_"=>{class => 'LimitedPolynomial::Function::trig'}
  );
}
foreach ('ln','log','log10','exp','sqrt','abs','int','sgn') {
  $context{LimitedPolynomial}->functions->set(
    "$_"=>{class => 'LimitedPolynomial::Function::numeric'}
  );
}

Context("LimitedPolynomial");
