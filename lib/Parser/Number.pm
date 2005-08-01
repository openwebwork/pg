#########################################################################
#
#  Implements the Number class
#
package Parser::Number;
use strict; use vars qw(@ISA);
@ISA = qw(Parser::Item);

$Parser::class->{Number} = 'Parser::Number';

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $equation = shift; my $num;
  my ($value,$ref) = @_;
  return $equation->{context}{parser}{Complex}->new($equation,$value,$ref)
    if (ref($value) eq 'ARRAY');
  $value = $value->value while Value::isReal($value);
  $num = bless {
    value => $value + 0, # format the value as a number, just in case
    value_string => $value, # for decimal checking, etc.
    type => $Value::Type{number}, isConstant => 1,
    ref => $ref, equation => $equation,
  }, $class;
  my $x = Value::Real->make($value);
  $num->{isOne}  = 1 if $x eq 1;
  $num->{isZero} = 1 if $x == 0;
  return $num;
}

#
#  We know the answers to these, so no need to compute them
#
sub isComplex {0}
sub isNumber {1}
sub isRealNumber {1}

#
#  Return the value
#
sub eval {(shift)->{value}}

#
#  If the number is negative, factor it out and
#    try using that in the reductions of the parent objects.
#
sub reduce {
  my $self = shift;
  my $reduce = $self->{equation}{context}{reduction};
  if ($reduce->{'-n'} && $self->{value} < 0) {
    $self->{value} = -($self->{value});
    $self = Parser::UOP::Neg($self);
    $self->{op}{isOne} = 1 if Value::Real->make($self->{op}{value}) eq 1;
  }
  return $self;
}

$Parser::reduce->{'-n'} = 1;


#
#  Call the Value::Real versions to format numbers
#
sub string {
  my $self = shift;
  Value::Real->make($self->{value})->string($self->{equation},@_);
}
sub TeX {
  my $self = shift;
  Value::Real->make($self->{value})->TeX($self->{equation},@_);
}
sub perl {shift->{value}}

###########################################

sub NoDecimals {
  my $context = shift || $$Value::context;
  $context->flags->set(NumberCheck=>\&_NoDecimals);
}

sub _NoDecimals {
  my $self = shift;
  $self->Error("You are not allowed to type decimal numbers in this problem")
    unless $self->{value_string} =~ m/^[-+]?[0-9]+$/;
}


#########################################################################

1;

