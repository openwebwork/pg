########################################################################### 

package Value::String;
my $pkg = 'Value::String';

use strict;
use vars qw(@ISA);
@ISA = qw(Value);

use overload
       '.'   => \&Value::_dot,
       '<=>' => sub {shift->compare(@_)},
       'cmp' => sub {shift->compare(@_)},
  'nomethod' => sub {shift->nomethod(@_)},
        '""' => sub {shift->stringify(@_)};

#
#  Create a string object
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $x = join('',@_);
  my $s = bless {data => [$x]}, $class;
  if ($Parser::installed) {
    my $strings = $$Value::context->{strings};
    if (!$strings->{$x}) {
      my $X = $strings->{uc($x)};
      Value::Error("String constant '$x' is not defined in this context")
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
