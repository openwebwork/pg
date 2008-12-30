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
#  There is also a third version, which is a strict fraction
#  mode (not in the original num_cmp) where ONLY fractions
#  can be entered (not decimals).
#
#      Context("LimitedNumeric-StrictFraction");
#
##########################################################


##################################################
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
    unless $self->{op}->class =~ /Number|INTEGER|DIVIDE/;
}

sub class {'MINUS'};


##################################################
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
  $self->Error("You can only use '%s' between (non-negative) integers",$bop)
    unless $self->{lop}->class =~ /INTEGER|MINUS/ &&
           $self->{rop}->class eq 'INTEGER';
}

sub class {'DIVIDE'};

##################################################
#
#  Distinguish integers from decimals
#
package Parser::Legacy::LimitedNumeric::Number;
our @ISA = qw(Parser::Number);

sub class {
  my $self = shift;
  return "INTEGER" if $self->{value_string} =~ m/^[-+]?[0-9]+$/;
  return "Number";
}


##################################################

package Parser::Legacy::LimitedNumeric;

#
#  LimitedNumeric context uses the modified minus
#  and removes all other operatots, functions and parentheses
#
my $context = $Parser::Context::Default::context{Numeric}->copy;
$Parser::Context::Default::context{'LimitedNumeric'} = $context;
$context->{name} = 'LimitedNumeric';

$context->operators->set('u-' => {class => 'Parser::Legacy::LimitedNumeric::UOP::minus'});
$context->operators->undefine(
   '+', '-', '*', '* ', ' *', ' ', '/', '/ ', ' /', '^', '**',
   'U', '.', '><', 'u+', '!', '_', ',',
);
$context->parens->undefine('|','{','(','[');
$context->functions->disable('All');

##################################################
#
#  For the Fraction versions, allow the modified division, and
#  make sure numbers used in fractions are just integers
#
$context = $Parser::Context::Default::context{Numeric}->copy;
$Parser::Context::Default::context{'LimitedNumeric-Fraction'} = $context;
$context->{name} = "LimitedNumeric-Fraction";

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
$context->{parser}{Number} = "Parser::Legacy::LimitedNumeric::Number";

##################################################
#
#  For strict fractions, don't allow decimal numbers
#
$context = $context->copy;
$Parser::Context::Default::context{'LimitedNumeric-StrictFraction'} = $context;
Parser::Number::NoDecimals($context);
$context->{name} = "LimitedNumeric-StrictFraction";

######################################################################

1;
