##########################################################
#
#  Implements a context in which complex numbers can be entered,
#  but no complex operations are permitted.  So students will
#  be able to perform operations within the real and imaginary
#  parts of the complex numbers, but not between complex numbers.
#
#
#  Complex Numbers can still be entered in a+bi or a*e^(bt) form.
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
#  You can require that the a and b used in these forms be strictly
#  numbers (not expressions) by setting the strict_numeric flag and
#  disabling all the functions:
#
#      Context()->flags->set(strict_numeric=>1);
#      Context()->functions->disable('All');
#
#  There are predefined contexts that already have these values
#  set:
#
#      Context("LimitedComplex-cartesian-strict");
#      Context("LimitedComplex-polar-strict");
#      Context("LimitedComplex-strict");
#

#
#  Handle common checking for BOPs
#
package Parser::Legacy::LimitedComplex::BOP;

#
#  Do original check and then if the operands are numbers, its OK.
#  Otherwise, do an operator-specific check for if complex numbers are OK.
#  Otherwise report an error.
#
sub _check {
  my $self = shift;
  my $super = ref($self); $super =~ s/Legacy::LimitedComplex:://;
  &{$super."::_check"}($self);
  if ($self->{lop}->isRealNumber && $self->{rop}->isRealNumber) {
    return unless $self->{equation}{context}{flags}{strict_numeric};
  } else {
    Value::Error("The constant 'i' may appear only once in your formula")
      if ($self->{lop}->isComplex and $self->{rop}->isComplex);
    return if $self->checkComplex;
    $self->Error("Exponential form is 'a*e^(bi)'")
      if $self->{lop}{isPower} || $self->{rop}{isPower};
  }
  $self->Error("Your answer should be of the form %s",$self->theForm)
}

#
#  filled in by subclasses
#
sub checkComplex {return 0}

#
#  Get the form for use in error messages
#
sub theForm {
  my $self = shift;
  my $format = $self->{equation}{context}{flags}{complex_format};
  return 'a+bi' if $format eq 'cartesian';
  return 'a*e^(bi)' if $format eq 'polar';
  return 'a+bi or a*e^(bi)';
}

##############################################
#
#  Now we get the individual replacements for the operators
#  that we don't want to allow.  We inherit everything from
#  the original Parser::BOP class, and just add the
#  complex checks here.  Note that checkComplex only
#  gets called if exactly one of the terms is complex
#  and the other is real.
#

package Parser::Legacy::LimitedComplex::BOP::add;
our @ISA = qw(Parser::Legacy::LimitedComplex::BOP Parser::BOP::add);

sub checkComplex {
  my $self = shift;
  return 0 if $self->{equation}{context}{flags}{complex_format} eq 'polar';
  my ($l,$r) = ($self->{lop},$self->{rop});
  if ($l->isComplex) {my $tmp = $l; $l = $r; $r = $tmp};
  return $r->class eq 'Constant' || $r->{isMult} ||
    ($r->class eq 'Complex' && $r->{value}[0] == 0);
}

##############################################

package Parser::Legacy::LimitedComplex::BOP::subtract;
our @ISA = qw(Parser::Legacy::LimitedComplex::BOP Parser::BOP::subtract);

sub checkComplex {
  my $self = shift;
  return 0 if $self->{equation}{context}{flags}{complex_format} eq 'polar';
  my ($l,$r) = ($self->{lop},$self->{rop});
  if ($l->isComplex) {my $tmp = $l; $l = $r; $r = $tmp};
  return $r->class eq 'Constant' || $r->{isMult} ||
    ($r->class eq 'Complex' && $r->{value}[0] == 0);
}

##############################################

package Parser::Legacy::LimitedComplex::BOP::multiply;
our @ISA = qw(Parser::Legacy::LimitedComplex::BOP Parser::BOP::multiply);

sub checkComplex {
  my $self = shift;
  my ($l,$r) = ($self->{lop},$self->{rop});
  $self->{isMult} = !$r->{isPower};
  return (($l->class eq 'Constant' || $l->isRealNumber) &&
	  ($r->class eq 'Constant' || $r->isRealNumber || $r->{isPower}));
}

##############################################

package Parser::Legacy::LimitedComplex::BOP::divide;
our @ISA = qw(Parser::Legacy::LimitedComplex::BOP Parser::BOP::divide);

##############################################

package Parser::Legacy::LimitedComplex::BOP::power;
our @ISA = qw(Parser::Legacy::LimitedComplex::BOP Parser::BOP::power);

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
	       ($r->class eq 'Constant' || $r->{isMult} || $r->{isOp} ||
		$r->class eq 'Complex' && $r->{value}[0] == 0));
  $self->Error("Exponentials can only be of the form 'e^(ai)' in this context");
}

##############################################
##############################################
#
#  Now we do the same for the unary operators
#

package Parser::Legacy::LimitedComplex::UOP;

sub _check {
  my $self = shift;
  my $super = ref($self); $super =~ s/Legacy::LimitedComplex:://;
  &{$super."::_check"}($self);
  my $op = $self->{op}; $self->{isOp} = 1;
  if ($op->isRealNumber) {
    return unless $self->{equation}{context}{flags}{strict_numeric};
    return if $op->class eq 'Number';
  } else {
    return if $self->{op}{isMult} || $self->{op}{isPower};
    return if $op->class eq 'Constant' && $op->{name} eq 'i';
  }
  $self->Error("Your answer should be of the form %s",$self->theForm)
}

sub checkComplex {return 0}

sub theForm {Parser::Legacy::LimitedComplex::BOP::theForm(@_)}

##############################################

package Parser::Legacy::LimitedComplex::UOP::plus;
our @ISA = qw(Parser::Legacy::LimitedComplex::UOP Parser::UOP::plus);

##############################################

package Parser::Legacy::LimitedComplex::UOP::minus;
our @ISA = qw(Parser::Legacy::LimitedComplex::UOP Parser::UOP::minus);

##############################################
##############################################
#
#  Absolute value does complex norm, so we
#  trap that as well.
#

package Parser::Legacy::LimitedComplex::List::AbsoluteValue;
our @ISA = qw(Parser::List::AbsoluteValue);

sub _check {
  my $self = shift;
  $self->SUPER::_check;
  return if $self->{coords}[0]->isRealNumber;
  $self->Error("Can't take absolute value of Complex Numbers in this context");
}

##############################################
##############################################

package Parser::Legacy::LimitedComplex;

#
#  Now build the new context that calls the
#  above classes rather than the usual ones
#

my $context = $Parser::Context::Default::context{Complex}->copy;
$Parser::Context::Default::context{LimitedComplex} = $context;
$context->{name} = "LimtedComplex";

#
#  Override operator classes
#
$context->operators->set(
   '+' => {class => 'Parser::Legacy::LimitedComplex::BOP::add'},
   '-' => {class => 'Parser::Legacy::LimitedComplex::BOP::subtract'},
   '*' => {class => 'Parser::Legacy::LimitedComplex::BOP::multiply'},
  '* ' => {class => 'Parser::Legacy::LimitedComplex::BOP::multiply'},
  ' *' => {class => 'Parser::Legacy::LimitedComplex::BOP::multiply'},
   ' ' => {class => 'Parser::Legacy::LimitedComplex::BOP::multiply'},
   '/' => {class => 'Parser::Legacy::LimitedComplex::BOP::divide'},
  ' /' => {class => 'Parser::Legacy::LimitedComplex::BOP::divide'},
  '/ ' => {class => 'Parser::Legacy::LimitedComplex::BOP::divide'},
   '^' => {class => 'Parser::Legacy::LimitedComplex::BOP::power'},
  '**' => {class => 'Parser::Legacy::LimitedComplex::BOP::power'},
  'u+' => {class => 'Parser::Legacy::LimitedComplex::UOP::plus'},
  'u-' => {class => 'Parser::Legacy::LimitedComplex::UOP::minus'},
);
#
#  Remove these operators and functions
#
$context->lists->set(
  AbsoluteValue => {class => 'Parser::Legacy::LimitedComplex::List::AbsoluteValue'},
);
$context->operators->undefine('_','U');
$context->functions->disable('Complex');
foreach my $fn ($context->functions->names) {$context->{functions}{$fn}{nocomplex} = 1}
#
#  Format can be 'cartesian', 'polar', or 'either'
#
$context->flags->set(complex_format => 'either');

##################################################

$context = $context->copy;
$Parser::Context::Default::context{'LimitedComplex-cartesian'} = $context;
$context->flags->set(complex_format => 'cartesian');
$context->{name} = "LimtedComplex-cartesian";

##################################################

$context = $context->copy;
$Parser::Context::Default::context{'LimitedComplex-cartesian-strict'} = $context;
$context->flags->set(strict_numeric => 1);
$context->functions->disable('All');
$context->{name} = "LimtedComplex-cartesian-strinct";

##################################################

$context = $Parser::Context::Default::context{'LimitedComplex'}->copy;
$Parser::Context::Default::context{'LimitedComplex-polar'} = $context;
$context->flags->set(complex_format => 'polar');
$context->{name} = "LimtedComplex-polar";

##################################################

$context = $context->copy;
$Parser::Context::Default::context{'LimitedComplex-polar-strict'} = $context;
$context->flags->set(strict_numeric => 1);
$context->functions->disable('All');
$context->{name} = "LimtedComplex-polar-strict";

##################################################

$context = $Parser::Context::Default::context{'LimitedComplex'}->copy;
$Parser::Context::Default::context{'LimitedComplex-strict'} = $context;
$context->flags->set(strict_numeric => 1);
$context->functions->disable('All');
$context->{name} = "LimtedComplex-strict";

##################################################

1;
