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
  $value = $value + 0; # format the value as a number
     ###  set equal to zero if near zero?
  $num = bless {
    value => $value, type => $Value::Type{number}, isConstant => 1,
    ref => $ref, equation => $equation,
  }, $class;
  $num->{isOne}  = 1 if ($value == 1);
  $num->{isZero} = 1 if ($value == 0);
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
  }
  return $self;
}

#
#  Call the Value::Real versions to format numbers
#
sub string {Value::Real->make(shift->{value})->string(@_)}
sub TeX {Value::Real->make(shift->{value})->TeX(@_)}
sub perl {(shift)->{value}}

#########################################################################

1;

