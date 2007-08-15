
loadMacros("Parser.pl");

sub _contextLimitedPowers_init {}; # don't load it again

=head3 Context("LimitedPowers")

##########################################################
#
#  Implements subclasses of the "^" operator that restrict
#  the base or power that is allowed.  There are three
#  available restrictions:
#
#    No raising e to a power
#    Only allowing integer powers (positive or negative)
#    Only allowing positive interger powers
#    Only allowing positive interger powers (and 0)
#
#  You install these via one of the commands:
#
#    Context()->operators->set(@LimitedPowers::NoBaseE);
#    Context()->operators->set(@LimitedPowers::OnlyIntegers);
#    Context()->operators->set(@LimitedPowers::OnlyPositiveIntegers);
#    Context()->operators->set(@LimitedPowers::OnlyNonNegativeIntegers);
#
#  Only one of the three can be in effect at a time; setting
#  a second one overrides the first.
#
##########################################################

=cut

package LimitedPowers;

our @NoBaseE = (
  '^'  => {class => LimitedPowers::NoBaseE, isCommand=>1, perl=>'LimitedPowers::NoBaseE->_eval'},
  '**' => {class => LimitedPowers::NoBaseE, isCommand=>1, perl=>'LimitedPowers::NoBaseE->_eval'},
);

our @OnlyIntegers = (
  '^'  => {class => LimitedPowers::OnlyIntegers},
  '**' => {class => LimitedPowers::OnlyIntegers},
);

our @OnlyPositiveIntegers = (
  '^'  => {class => LimitedPowers::OnlyPositiveIntegers},
  '**' => {class => LimitedPowers::OnlyPositiveIntegers},
);

our @OnlyNonNegativeIntegers = (
  '^'  => {class => LimitedPowers::OnlyNonNegativeIntegers},
  '**' => {class => LimitedPowers::OnlyNonNegativeIntegers},
);

##################################################

package LimitedPowers::NoBaseE;
@ISA = qw(Parser::BOP::power);

my $e = CORE::exp(1);

sub _check {
  my $self = shift;
  $self->SUPER::_check(@_);
  $self->Error("Can't raise e to a power") if $self->{lop}->string eq 'e';
}

sub _eval {
  my $self = shift;
  Value::cmp_Message("Can't raise e to a power") if $_[0] - $e == 0;
  $self->SUPER::_eval(@_);
}

##################################################

package LimitedPowers::OnlyIntegers;
@ISA = qw(Parser::BOP::power);

sub _check {
  my $self = shift; my $p = $self->{rop};
  $self->SUPER::_check(@_);
  $self->Error("Powers must be integer constants")
    if $p->type ne 'Number' || !$p->{isConstant} || !isInteger($p->eval);
}

sub isInteger {
  my $n = shift;
  return (Value::Real->make($n) - int($n)) == 0;
}

##################################################

package LimitedPowers::OnlyPositiveIntegers;
@ISA = qw(Parser::BOP::power);

sub _check {
  my $self = shift; my $p = $self->{rop};
  $self->SUPER::_check(@_);
  $self->Error("Powers must be positive integer constants")
    if $p->type ne 'Number' || !$p->{isConstant} || !isPositiveInteger($p->eval);
}

sub isPositiveInteger {
  my $n = shift;
  return $n > 0 && (Value::Real->make($n) - int($n)) == 0;
}

##################################################

package LimitedPowers::OnlyNonNegativeIntegers;
@ISA = qw(Parser::BOP::power);

sub _check {
  my $self = shift; my $p = $self->{rop};
  $self->SUPER::_check(@_);
  $self->Error("Powers must be non-negative integer constants")
    if $p->type ne 'Number' || !$p->{isConstant} || !isNonNegativeInteger($p->eval);
}

sub isNonNegativeInteger {
  my $n = shift;
  return $n >= 0 && (Value::Real->make($n) - int($n)) == 0;
}

##################################################

1;
