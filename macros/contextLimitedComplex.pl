loadMacros("Parser.pl");

sub _contextLimitedComplex_init {}; # don't load it again

##########################################################
#
#  Implements a context in which complex numbers can be entered,
#  but no complex operations are permitted.  So students will
#  be able to perform operations within the real and imaginary
#  parts of the complex numbers, but not between complex numbers.
#
#
#  Complex Numbers can still be entered in a+bi or r*e^(it) form.
#  The e and i are allowed to be entered only once, so we have
#  to keep track of that, and allow SOME complex operations,
#  but only when one term is one of these constants (or an expression
#  involving it that we've already OKed).
#
#  You control which format to use by setting the complex_format
#  context flag to 'cartesian', 'polar' or 'either'. E.g.,
#
#      Context()->flags->set(complex_format => 'polar');
#  
#  The default is 'either'.  There are predefined contexts that
#  already have these values set:
#
#      Context("LimitedComplex-cartesian");
#      Context("LimitedComplex-polar");
#

#
#  Handle common checking for BOPs
#
package LimitedComplex::BOP;

#
#  Do original check and then if the operands are numbers, its OK.
#  Otherwise, do an operator-specific check for if complex numbers are OK.
#  Otherwise report an error.
#
sub _check {
  my $self = shift;
  my $super = ref($self); $super =~ s/LimitedComplex/Parser/;
  &{$super."::_check"}($self);
  return if $self->{lop}->isRealNumber && $self->{rop}->isRealNumber;
  Value::Error("The constant 'i' may appear only once in your formula")
    if ($self->{lop}->isComplex and $self->{rop}->isComplex);
  return if $self->checkComplex;
  my $bop = $self->{def}{string} || $self->{bop};
  $self->Error("Exponential form is 'r*e^(ai)'")
    if $self->{lop}{isPower} || $self->{rop}{isPower};
  $self->Error("Your answer should be of the form a+bi")
    if $self->{equation}{context}{flags}{complex_format} eq 'cartesian';
  $self->Error("Your answer should be of the form r*e^(ai)")
    if $self->{equation}{context}{flags}{complex_format} eq 'polar';
  $self->Error("Your answer should be of the form a+bi or r*e^(ai)");
}

#
#  filled in by subclasses
#
sub checkComplex {return 0}

##############################################
#
#  Now we get the individual replacements for the operators
#  that we don't want to allow.  We inherit everything from
#  the original Parser::BOP class, and just add the
#  complex checks here.  Note that checkComplex only
#  gets called if exactly one of the terms is complex
#  and the other is real.
#

package LimitedComplex::BOP::add;
our @ISA = qw(LimitedComplex::BOP Parser::BOP::add);

sub checkComplex {
  my $self = shift;
  return 0 if $self->{equation}{context}{flags}{complex_format} eq 'polar';
  my ($l,$r) = ($self->{lop},$self->{rop});
  if ($l->isComplex) {my $tmp = $l; $l = $r; $r = $tmp};
  return $r->class eq 'Constant' || $r->{isMult} ||
    ($r->class eq 'Complex' && $r->{value}[0] == 0);
}

##############################################

package LimitedComplex::BOP::subtract;
our @ISA = qw(LimitedComplex::BOP Parser::BOP::subtract);

sub checkComplex {
  my $self = shift;
  return 0 if $self->{equation}{context}{flags}{complex_format} eq 'polar';
  my ($l,$r) = ($self->{lop},$self->{rop});
  if ($l->isComplex) {my $tmp = $l; $l = $r; $r = $tmp};
  return $r->class eq 'Constant' || $r->{isMult} ||
    ($r->class eq 'Complex' && $r->{value}[0] == 0);
}

##############################################

package LimitedComplex::BOP::multiply;
our @ISA = qw(LimitedComplex::BOP Parser::BOP::multiply);

sub checkComplex {
  my $self = shift;
  my ($l,$r) = ($self->{lop},$self->{rop});
  $self->{isMult} = !$r->{isPower};
  return (($l->class eq 'Constant' || $l->isRealNumber) &&
	  ($r->class eq 'Constant' || $r->isRealNumber || $r->{isPower}));
}

##############################################

package LimitedComplex::BOP::divide;
our @ISA = qw(LimitedComplex::BOP Parser::BOP::divide);

##############################################

package LimitedComplex::BOP::power;
our @ISA = qw(LimitedComplex::BOP Parser::BOP::power);

#
#  Base must be 'e' (then we know the other is the complex
#  since we only get here if exactly one term is complex)
#
sub checkComplex {
  my $self = shift;
  return 0 if $self->{equation}{context}{flags}{complex_format} eq 'cartesian';
  my ($l,$r) = ($self->{lop},$self->{rop});
  $self->{isPower} = 1;
  return 1 if ($l->class eq 'Constant' && $l->{name} eq 'e' &&
	       ($r->class eq 'Constant' || $r->{isMult} ||
		$r->class eq 'Complex' && $r->{value}[0] == 0));
  $self->Error("Exponentials can only be of the form 'e^(ai)' in this context");
}

##############################################
##############################################
#
#  Now we do the same for the unary operators
#

package LimitedComplex::UOP;

sub _check {
  my $self = shift;
  my $super = ref($self); $super =~ s/LimitedComplex/Parser/;
  &{$super."::_check"}($self);
  my $op = $self->{op};
  return if $op->isRealNumber;
  return if $self->{op}{isMult} || $self->{op}{isPower};
  return if $op->class eq 'Constant' && $op->{name} eq 'i';
  my $uop = $self->{def}{string} || $self->{uop};
  $self->Error("Your answer should be of the form a+bi")
    if $self->{equation}{context}{flags}{complex_format} eq 'cartesian';
  $self->Error("Your answer should be of the form r*e^(ai)")
    if $self->{equation}{context}{flags}{complex_format} eq 'polar';
  $self->Error("Your answer should be of the form a+bi or r*e^(ai)");
}

sub checkComplex {return 0}

##############################################

package LimitedComplex::UOP::plus;
our @ISA = qw(LimitedComplex::UOP Parser::UOP::plus);

##############################################

package LimitedComplex::UOP::minus;
our @ISA = qw(LimitedComplex::UOP Parser::UOP::minus);

##############################################
##############################################
#
#  Absolute value does complex norm, so we
#  trap that as well.
#

package LimitedComplex::List::AbsoluteValue;
our @ISA = qw(Parser::List::AbsoluteValue);

sub _check {
  my $self = shift;
  $self->SUPER::_check;
  return if $self->{coords}[0]->isRealNumber;
  $self->Error("Can't take absolute value of Complex Numbers in this context");
}

##############################################
##############################################

package main;

#
#  Now build the new context that calls the
#  above classes rather than the usual ones
#

$context{LimitedComplex} = Context("Complex");
$context{LimitedComplex}->operators->set(
   '+' => {class => 'LimitedComplex::BOP::add'},
   '-' => {class => 'LimitedComplex::BOP::subtract'},
   '*' => {class => 'LimitedComplex::BOP::multiply'},
  '* ' => {class => 'LimitedComplex::BOP::multiply'},
  ' *' => {class => 'LimitedComplex::BOP::multiply'},
   ' ' => {class => 'LimitedComplex::BOP::multiply'},
   '/' => {class => 'LimitedComplex::BOP::divide'},
  ' /' => {class => 'LimitedComplex::BOP::divide'},
  '/ ' => {class => 'LimitedComplex::BOP::divide'},
   '^' => {class => 'LimitedComplex::BOP::power'},
  '**' => {class => 'LimitedComplex::BOP::power'},
  'u+' => {class => 'LimitedComplex::UOP::plus'},
  'u-' => {class => 'LimitedComplex::UOP::minus'},
);
#
#  Remove these operators and functions
#
$context{LimitedComplex}->lists->set(
  AbsoluteValue => {class => 'LimitedComplex::List::AbsoluteValue'},
);
$context{LimitedComplex}->operators->undefine('_','U');
Parser::Context::Functions::Disable('Complex');
foreach my $fn ($context{LimitedComplex}->functions->names) 
  {$context{LimitedComplex}->{functions}{$fn}{nocomplex} = 1}
#
#  Format can be 'cartesian', 'polar', or 'either'
#
$context{LimitedComplex}->flags->set(complex_format => 'either');

$context{'LimitedComplex-cartesian'} = $context{LimitedComplex}->copy;
$context{'LimitedComplex-cartesian'}->flags->set(complex_format => 'cartesian');

$context{'LimitedComplex-polar'} = $context{LimitedComplex}->copy;
$context{'LimitedComplex-polar'}->flags->set(complex_format => 'polar');

Context("LimitedComplex");
