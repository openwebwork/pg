#########################################################################
#
#  Implement the list of known strings
#
package Parser::Context::Strings;
use strict;
use vars qw (@ISA);
@ISA = qw(Value::Context::Data);

sub init {
  my $self = shift;
  $self->{dataName} = 'strings';
  $self->{name} = 'string';
  $self->{Name} = 'String';
  $self->{namePattern} = '[\S ]+';
}

#
#  Allow for case-insensitive strings.
#  Case-insensitive is now the default.
#  You can use
#
#       $context->strings->set(name=>{caseSensitive=>1});
#
#  to get a case-sensitive string called "name".
#
sub update {
  my $self = shift;
  my $data = $self->{context}->{$self->{dataName}};
  my $single = ''; my @multi = ();
  foreach my $x (sort byName (keys %{$data})) {
    unless ($data->{$x}{hidden}) {
      if ($data->{$x}{caseSensitive} || uc($x) eq lc($x)) {
	if (length($x) == 1) {$single .= $x}
	                else {push(@multi,protectRegexp($x))}
      } else {
	if (length($x) == 1) {$single .= uc($x).lc($x)}
	                else {push(@multi,"(?:(?i)".protectRegexp($x).")")}
      }
    }
  }
  $self->{pattern} = $self->getPattern($single,@multi);
  $self->{context}->update;
}

#
#  Must be in the same package as the sort call
#  (due to global $a and $b, I assume)
#
sub byName {
  my $result = length($b) <=> length($a);
  return $result unless $result == 0;
  return $a cmp $b;
}

#
#  Same as Value::Context::Data::getPattern, but with
#  the protectRegexp already done on the @multi list.
#
sub getPattern {
  shift; my $s = shift;
#  foreach my $x (@_) {$x = protectRegexp($x)}
  my @pattern = ();
  push(@pattern,join('|',@_)) if scalar(@_) > 0;
  push(@pattern,protectRegexp($s)) if length($s) == 1;
  push(@pattern,"[".protectChars($s)."]") if length($s) > 1;
  my $pattern = join('|',@pattern);
  $pattern = '^$' if $pattern eq '';
  return $pattern;
}

#
#  Add upper-case alias for case-insensitive strings
#  (so we can always find their definitions)
#
sub add {
  my $self = shift; return if scalar(@_) == 0;
  my $data = $self->{context}{$self->{dataName}};
  $self->SUPER::add(@_);
  my %D = (@_);
  foreach my $x (keys %D) {
    $data->{uc($x)} = {alias => $x, hidden => 1} 
      unless $data->{$x}{caseSensitive} || uc($x) eq $x;
  }
}

#
#  Call the ones in Value::Context::Data
#
sub protectRegexp {Value::Context::Data::protectRegexp(@_)}
sub protectChars {Value::Context::Data::protectChars(@_)}


#########################################################################

1;
