#########################################################################
#
#  Implements the Complex class
#
package Parser::Complex;
use strict; use vars qw(@ISA);
@ISA = qw(Parser::Item);

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $equation = shift; my $num;
  my ($value,$ref) = @_;
  $value = [$value,0] unless ref($value) eq 'ARRAY';
  $value->[1] = 0 unless defined($value->[1]);
  ### set values near zero to being equal to zero?
  $equation->Error("Complex Numbers must have real and complex parts",$ref)
    if (scalar(@{$value}) != 2);
  $num = bless {
    value => $value, type => $Value::Type{complex}, isConstant => 1,
    ref => $ref, equation => $equation,
  }, $class;
  $num->{isOne}  = 1 if ($value->[0] == 1 && $value->[1] == 0);
  $num->{isZero} = 1 if ($value->[0] == 0 && $value->[1] == 0);
  return $num;
}

#
#  We know the answer to these, so no need to compute them.
#
sub isComplex {1}
sub isNumber {1}
sub isRealNumber {0}

#
#  Use Value.pm to evaluate these
#
sub eval {
  my $self = shift;
  return Value::Complex->make(@{$self->{value}});
}

#
#  Factor out a common negative.
#
sub reduce {
  my $self = shift; my ($a,$b) = @{$self->{value}};
  if ($a <= 0 && $b <= 0 && ($a != 0 || $b != 0)) {
    $self->{value} = [-$a,-$b];
    $self = Parser::UOP::Neg($self);
  }
  return $self;
}

#
#  Use Value::Complex to format the number
#  Add parens if the parent oparator has higher precedence
#    than addition.
#
sub string {
  my $self = shift; my $precedence = shift;
  my $plus = $self->{context}{operators}{'+'}{precedence};
  my $z = Value::Complex->make(@{$self->{value}})->stringify;
  $z = "(".$z.")" if defined($precedence) && $precedence > $plus;
  return $z;
}

sub TeX {(shift)->string(@_)}

sub perl {
  my $self = shift; my $parens = shift;
  my $perl = Value::Complex->make(@{$self->{value}})->perl;
  $perl = '('.$perl.')' if $parens;
  return $perl;
}

#########################################################################

1;

