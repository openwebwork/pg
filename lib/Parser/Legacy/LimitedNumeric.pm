##########################################################
#
#  Implements a context in which numbers can be entered,
#  but no operations are permitted between them.
#
#  There are two versions:  one a number with no operations,
#  and one for fractions of integers.  Select them using
#  one of the following commands:
#
#      Context("LimiteNumeric");
#      Context("LimitedNumeric-Fraction");
#


#
#  Minus can only appear in front of a number
#
package Parser::Legacy::LimitedNumeric::UOP::minus;
our @ISA = qw(Parser::UOP::minus);

sub _check {
  my $self = shift;
  $self->SUPER::_check;
  my $uop = $self->{def}{string} || $self->{uop};
  $self->Error("You can only use '%s' with (non-negative) numbers",$uop)
    unless $self->{op}->class =~ /Number|DIVIDE/;
}

sub class {'MINUS'};


#
#  Divides can only appear between numbers or a negative
#  number and a number
#
package Parser::Legacy::LimitedNumeric::BOP::divide;
our @ISA = qw(Parser::BOP::divide);

sub _check {
  my $self = shift;
  $self->SUPER::_check;
  my $bop = $self->{def}{string} || $self->{bop};
  $self->Error("You can only use '%s' between (non-negative) numbers",$bop)
    unless $self->{lop}->class =~ /Number|MINUS/ &&
           $self->{rop}->class eq 'Number';
}

sub class {'DIVIDE'};


package Parser::Legacy::LimitedNumeric;

#
#  LimitedNumeric context uses the modified minus
#  and removes all other operatots, functions and parentheses
#
my $context = $Parser::Context::Default::context{Numeric}->copy;
$Parser::Context::Default::context{'LimitedNumeric'} = $context;
$context->operators->set('u-' => {class => 'Parser::Legacy::LimitedNumeric::UOP::minus'});
$context->operators->undefine(
   '+', '-', '*', '* ', ' *', ' ', '/', '/ ', ' /', '^', '**',
   'U', '.', '><', 'u+', '!', '_', ',',
);
$context->parens->undefine('|','{','(','[');
$context->functions->disable('All');

#
#  For the Fraction versions, allow the modified division, and
#  make sure numbers are just integers
#
$context = $Parser::Context::Default::context{Numeric}->copy;
$Parser::Context::Default::context{'LimitedNumeric-Fraction'} = $context;
$context->operators->set(
  'u-' => {class => 'Parser::Legacy::LimitedNumeric::UOP::minus'},
  '/'  => {class => 'Parser::Legacy::LimitedNumeric::BOP::divide'},
  ' /' => {class => 'Parser::Legacy::LimitedNumeric::BOP::divide'},
  '/ ' => {class => 'Parser::Legacy::LimitedNumeric::BOP::divide'},
);
$context->operators->undefine(
   '+', '-', '*', '* ', ' *', ' ', '^', '**',
   'U', '.', '><', 'u+', '!', '_', ',',
);
$context->parens->undefine('|','{','[');
$context->functions->disable('All');
Parser::Number::NoDecimals($context);

1;
