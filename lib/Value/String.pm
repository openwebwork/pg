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

sub make {
  my $self = shift;
  my $s = $self->SUPER::make(@_);
  my $def = $self->context->strings->get($s->{data}[0]);
  $s->{caseSensitive} = 1 if $def->{caseSensitive};
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

#
#  Mark a string to be display verbatim
#
sub verb {
  shift;
  my $s = shift;
  $s =~ s/\r/ /g;
  # different verbatim delimiters because in general 0xD would be nicest,
  # but browsers want to change that to 0xA
  # eval() needed because this .pm file loaded outside the safe compartment,
  # and eval() runs it inside the safe compartment, where problem context is in place.
  my $d = eval ('main::MODES(HTML => chr(0x1F), TeX => chr(0xD), PTX=> chr(0xD))');
  return "{\\verb$d$s$d}";
  # Note this does not handle \n in the input string
  # A future effort to address that should concurrently
  # handle it similarly for HTML output.
  # And something similar should be done for the ArbitraryString context
}

#
#  Put normal strings into \text{} and others into \verb
#
sub quoteTeX {
  my $self = shift; my $s = shift;
  return $self->verb($s) unless $s =~ m/^[-a-z0-9 ,.;:+=?()\[\]]*$/i;
  "\\text{$s}";
}


#
#  Quote HTML special characters
#
sub quoteHTML {
  shift; my $s = shift; my $nospan = shift;
  return unless defined $s;
  return $s if eval ('$main::displayMode') eq 'TeX';
  $s =~ s/&/\&amp;/g;
  $s =~ s/</\&lt;/g;
  $s =~ s/>/\&gt;/g;
  $s =~ s/"/\&quot;/g;
  return $s if $nospan || $s !~ m/(\$|\\\(|\\\[)/;
  return '<span class="tex2jax_ignore">'.$s.'</span>';
}

#
#  Render the value verbatim
#
sub TeX {
  my $self = shift;
  $self->quoteTeX($self->value);
}

sub perl {
 my $s = shift->value;
 $s =~ s/'/\\'/g;
 "'$s'";
}

###########################################################################

1;
