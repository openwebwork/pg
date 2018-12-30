#########################################################################
#
#  Implements other numeric functions
#
package Parser::Function::numeric;
use strict;
our @ISA = qw(Parser::Function);

#
#  Check that the argument is numeric (complex or real)
#
sub _check {(shift)->checkNumeric(@_)}

#
#  For complex arguments, call the complex version,
#  Otherwise call the version below.
#
sub _eval {
  my $self = shift; my $name = $self->{name};
  return $_[0]->$name if Value::isComplex($_[0]);
  $self->$name(@_);
}

#
#  Check the arguments and return the (real or complex) result.
#
sub _call {
  my $self = shift; my $name = shift;
  Value::Error("Function '%s' has too many inputs",$name) if scalar(@_) > 1;
  Value::Error("Function '%s' has too few inputs",$name) if scalar(@_) == 0;
  my $n = $_[0];
  return $self->$name($n) if Value::matchNumber($n);
  my $context = (Value::isValue($n) ? $n : $self)->context;
  $self->Package("Complex")->promote($context,$n)->$name;
}

#
#  Should make better errors about division by zero,
#  roots of negatives, logs of negatives.
#
sub ln    {shift; CORE::log($_[0])}
sub log10 {shift; CORE::log($_[0])/CORE::log(10)}
sub exp   {shift; CORE::exp($_[0])}
sub sqrt  {shift; CORE::sqrt($_[0])}
sub abs   {shift; CORE::abs($_[0])}
sub int   {shift; CORE::int($_[0])}
sub sgn   {shift; $_[0] <=> 0}

sub log   {
  my $self = shift; my $context = $self->context;
  return CORE::log($_[0])/CORE::log(10) if $context->flag('useBaseTenLog');
  CORE::log($_[0]);
}

#
#  Handle reduction of ln(e) and ln(e^x)
#
sub _reduce {
  my $self = shift;
  my $context = $self->context;
  my $base10 = $context->flag('useBaseTenLog');
  my $reduce = $context->{reduction};
  if ($self->{name} eq 'ln' || ($self->{name} eq 'log' && !$base10)) {
    my $arg = $self->{params}[0];
    if ($reduce->{'ln(e^x)'}) {
      return $arg->{rop} if $arg->isa('Parser::BOP::power') && $arg->{lop}->string eq 'e';
      return $arg->{params}[0] if $arg->isa('Parser::Function') && $arg->{name} eq 'exp';
    }
    return $self->Item('Value')->new($self->{equation}, [$self->eval])
      if $context->flag('reduceConstantFunctions') && $arg->string eq 'e';
  }
  return $self;
}

$Parser::reduce->{'ln(e^x)'} = 1;

#
#  Handle absolute values as a special case
#
sub string {
  my $self = shift;
  return '|'.$self->{params}[0]->string.'|' if $self->{name} eq 'abs';
  return $self->SUPER::string(@_);
}
#
#  Handle absolute values as special case.
#
sub TeX {
  my $self = shift; my $def = $self->{def};
  return '\left|'.$self->{params}[0]->TeX.'\right|' if $self->{name} eq 'abs';
  return $self->SUPER::TeX(@_);
}
#
#  Handle log (and useBaseTenLog) as a special case
#
sub perl {
  my $self = shift; my $context = $self->context;
  return $self->SUPER::perl
    unless $self->{name} eq 'log' && $context->flag('useBaseTenLog');
  '(log('.$self->{params}[0]->perl.')/log(10))';
}

#########################################################################

1;
