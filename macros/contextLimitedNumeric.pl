loadMacros("Parser.pl");

sub _contextLimitedNumeric_init {}; # don't load it again

##########################################################
#
#  Implements a context in which numbers can be entered,
#  but no operations are permitted between them.
#
#  There are two versions:  one for lists of numbers
#  and one for a single number.  Select them using
#  one of the following commands:
#
#      Context("LimitedNumeric-list");
#      Context("LimiteNumeric");
#

package LimitedNumeric::UOP::minus;
our @ISA = qw(Parser::UOP::minus);

sub _check {
  my $self = shift;
  $self->SUPER::_check;
  my $uop = $self->{def}{string} || $self->{uop};
  $self->Error("Can't use '$uop' in this context")
    unless $self->{op}->class eq 'Number';
}

package main;

$context{LimitedNumeric} = Context("Numeric");
$context{LimitedNumeric}->operators->set('u-' => {class => 'LimitedNumeric::UOP::minus'});
$context{LimitedNumeric}->operators->undefine(
   '+', '-', '*', '* ', ' *', ' ', '/', '/ ', ' /', '^', '**',
   'U', '.', '><', 'u+', '!', '_',
);
$context{LimitedNumeric}->parens->undefine('|','{','(','[');
Parser::Context::Functions::Disable('All');

$context{'LimitedNumeric-List'} = $context{LimitedNumeric}->copy;

$context{LimitedNumeric}->operators->undefine(',');

Context("LimitedNumeric");
