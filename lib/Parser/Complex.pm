#########################################################################
#
#  Implements the Complex class
#
package Parser::Complex;
use strict; no strict "refs";
our @ISA = qw(Parser::Item);

$Parser::class->{Complex} = 'Parser::Complex';

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $equation = shift; my $context = $equation->{context};
  my $num; my ($value,$ref) = @_;
  $value = [$value,0] unless ref($value) eq 'ARRAY';
  $value->[1] = 0 unless defined($value->[1]);
  $equation->Error("Complex Numbers must have real and complex parts",$ref)
    if (scalar(@{$value}) != 2);
  $num = bless {
    value => $value, type => $Value::Type{complex}, isConstant => 1,
    ref => $ref, equation => $equation,
  }, $class;
  $num->weaken;
  my $z = $self->Package("Complex",$context)->make($context,@{$value});
  $num->{isOne}  = 1 if ($z cmp 1) == 0;
  $num->{isZero} = 1 if $z == 0;
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
  return $self->Package("Complex")->make($self->context,@{$self->{value}});
}

#
#  Factor out a common negative.
#
sub reduce {
  my $self = shift; my ($a,$b) = @{$self->{value}};
  my $context = $self->context; my $reduce = $context->{reduction};
  if ($reduce->{'-a-bi'} && $a <= 0 && $b <= 0 && ($a != 0 || $b != 0)) {
    $self->{value} = [-$a,-$b];
    $self = Parser::UOP::Neg($self);
    $self->{isOne} = 1 if $self->Package("Complex")->make($context,-$a,-$b) eq "1";
  }
  return $self;
}

$Parser::reduce->{'-a-bi'} = 1;

#
#  Use Value::Complex to format the number
#  Add parens if the parent oparator has higher precedence
#    than addition (and there IS an addition or subtraction).
#
sub string {
  my $self = shift; my $precedence = shift; my $show = shift;
  my $context = $self->context; my $plus = $context->{operators}{'+'}{precedence};
  my $z = $self->Package("Complex")->make($context,@{$self->{value}})->string($self->{equation});
  $z = "(".$z.")" if defined($precedence) &&
    ($precedence > $plus || $precedence == $plus && $show eq "same") && $z =~ m/[-+]/;
  return $z;
}

sub TeX {
  my $self = shift; my $precedence = shift; my $show = shift;
  my $context = $self->context; my $plus = $context->{operators}{'+'}{precedence};
  my $z = $self->Package("Complex")->make($context,@{$self->{value}})->TeX($self->{equation});
  $z = '\left('.$z.'\right)' if defined($precedence) &&
    ($precedence > $plus || $precedence == $plus && $show eq "same") && $z =~ m/[-+]/;
  return $z;
}

sub perl {
  my $self = shift; my $parens = shift;
  my $perl = $self->Package("Complex")->make($self->context,@{$self->{value}})->perl;
  $perl = '('.$perl.')' if $parens;
  return $perl;
}

#########################################################################

1;
