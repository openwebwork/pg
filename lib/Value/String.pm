########################################################################### 

package Value::String;
my $pkg = 'Value::String';

use strict; no strict "refs";
our @ISA = qw(Value);

#
#  Create a string object
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $x = join('',@_);
  my $s = bless {data => [$x], context => $context}, $class;
  if ($Parser::installed && !($x eq '' && $self->getFlag('allowEmptyStrings'))) {
    my $strings = $context->{strings};
    if (!$strings->{$x}) {
      my $X = $strings->{uc($x)};
      Value::Error("String constant '%s' is not defined in this context",$x)
        unless $X && !$X->{caseSensitive};
      $x = uc($x); while ($strings->{$x}{alias}) {$x = $strings->{$x}{alias}}
    }
    $s->{caseSensitive} = 1 if $strings->{$x}{caseSensitive};
  }
  return $s;
}

#
#  Return the appropriate data.
#
sub length {1}
sub typeRef {$Value::Type{string}}
sub value {shift->{data}[0]}

sub isOne {0}
sub isZero {0}

sub transferFlags {}

##################################################

#
#  Convert to a string object
#
sub promote {
  my $self = shift;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $x = (scalar(@_) ? shift : $self); $x = [$x,@_] if scalar(@_) > 0;
  $x = Value::makeValue($x,showError=>1,context=>$context);
  $x = join('',@{$x}) if ref($x) eq 'ARRAY';
  $x = $self->make($context,$x) unless Value::isValue($x);
  return $x;
}

############################################
#
#  Operations on strings
#
sub compare {
  my ($self,$l,$r) = Value::checkOpOrderWithPromote(@_);
  return $l->value cmp $r->value if $l->{caseSensitive} || $r->{caseSensitive};
  return uc($l->value) cmp uc($r->value);
}

############################################
#
#  Generate the various output formats
#

sub TeX {'{\rm '.shift->value.'}'}
sub perl {"'".shift->value."'"}

###########################################################################

1;
