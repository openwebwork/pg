########################################################################### 

package Value::Infinity;
my $pkg = 'Value::Infinity';

use strict;
use vars qw(@ISA);
@ISA = qw(Value);

use overload
       '.'   => \&Value::_dot,
       '<=>' => \&compare,
       'cmp' => \&compare,
       'neg' => \&neg,
  'nomethod' => \&Value::nomethod,
        '""' => \&Value::stringify;

#
#  Create an infinity object
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  Value::Error("Infinity should have no parameters") if scalar(@_);
  bless {
    data => [$$Value::context->flag('infiniteWord')],
    isInfinite => 1, isNegative => 0,
  }, $class;
}

#
#  Return the appropriate data.
#
sub length {0}
sub typeRef {my $self = shift; Value::Type($self->class,$self->length)}
sub value {shift->{data}[0]}

##################################################

#
#  Return a complex if it already is one, otherwise make it one
#    (Guarantees that we have both parts in an array ref)
#
sub promote {
  my $x = shift;
  return $x if (ref($x) eq $pkg && scalar(@_) == 0);
  return $x if Value::isReal($x);
  return Value::Real->new($x) if !ref($x) && Value::matchNumber($x);
  Value::Error("Can't convert '$x' to Infinity");
}

############################################
#
#  Operations on Infinities
#

sub neg {
  my $self = shift;
  my $neg = Value::Infinity->new();
  $neg->{isNegative} = !$self->{isNegative};
  $neg->{data}[0] = '-'.$neg->{data}[0] if $neg->{isNegative};
  return $neg;
}

sub compare {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->compare($l,!$flag)}
  $r = promote($r); my $sgn = ($flag ? -1: 1);
  return 0 if $r->class ne 'Real' && $l->{isNegative} == $r->{isNegative};
  return ($l->{isNegative}? -$sgn: $sgn);
}

############################################
#
#  Generate the various output formats
#

sub TeX {(shift->{isNegative} ? '-\infty': '\infty ')}
sub perl {(shift->{isNegative} ? '-(Infinity)': '(Infinity)')}

###########################################################################

1;
