########################################################################### 

package Value::String;
my $pkg = 'Value::String';

use strict;
use vars qw(@ISA);
@ISA = qw(Value);

use overload
       '.'   => \&Value::_dot,
       '<=>' => \&compare,
       'cmp' => \&compare,
  'nomethod' => \&Value::nomethod,
        '""' => \&Value::stringify;

#
#  Create a string object
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $x = join('',@_);
  if ($Parser::installed) {
    Value::Error("String constant '$x' is not defined in this context")
      unless $$Value::context->{strings}{$x};
  }
  bless {data => [$x]}, $class;
}

#
#  Return the appropriate data.
#
sub length {1}
sub typeRef {$Value::Type{string}}
sub value {shift->{data}[0]}

sub isOne {0}
sub isZero {0}

##################################################

#
#  Convert to a string object
#
sub promote {
  my $x = shift; $x = [$x,@_] if scalar(@_) > 0;
  $x = Value::makeValue($x,showError=>1); $x = join('',@{$x}) if ref($x) eq 'ARRAY';
  $x = $pkg->make($x) unless Value::isValue($x);
  return $x;
}

############################################
#
#  Operations on strings
#

sub compare {
  my ($l,$r,$flag) = @_;
  if ($l->promotePrecedence($r)) {return $r->compare($l,!$flag)}
  $r = promote($r); if ($flag) {my $tmp = $l; $l = $r; $r = $tmp}
  return $l->value cmp $r->value;
}

############################################
#
#  Generate the various output formats
#

sub TeX {'{\rm '.shift->value.'}'}
sub perl {"'".shift->value."'"}

###########################################################################

1;
