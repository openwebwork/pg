#########################################################################
#
#  Implements the Number class
#
package Parser::Number;
use strict; use vars qw(@ISA);
@ISA = qw(Parser::Item);

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $equation = shift; my $num;
  my ($value,$ref) = @_;
  return Parser::Complex->new($equation,$value,$ref) if (ref($value) eq 'ARRAY');
  $value = $value->value while Value::isReal($value);
  $value = $value + 0; # format the value as a number
  $num = bless {
    value => $value, type => $Value::Type{number}, isConstant => 1,
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
  if ($self->{value} < 0) {
    $self->{value} = -($self->{value});
    $self = Parser::UOP::Neg($self);
    $self->{op}{isOne} = 1 if Value::Real->make($self->{op}{value}) eq 1;
  }
  return $self;
}

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

#########################################################################

1;

