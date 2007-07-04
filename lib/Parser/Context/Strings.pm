#########################################################################
#
#  Implement the list of known strings
#
package Parser::Context::Strings;
use strict;
our @ISA = qw(Value::Context::Data);

sub init {
  my $self = shift;
  $self->{dataName} = 'strings';
  $self->{name} = 'string';
  $self->{Name} = 'String';
  $self->{namePattern} = qr/[\S ]+/;
  $self->{tokenType} = 'str';
  $self->{precedence} = -5;
  $self->{caseInsensitive} = {};
}

sub update {
  my $self = shift;
  my @strings = keys %{$self->{caseInsensitive}};
  if (@strings) {
    my $pattern = '(?i)(?:'.Parser::Context::getPattern(@strings).')';
    $self->{patterns} = {$pattern => [$self->{precedence},$self->{tokenType}]};
  }
  $self->SUPER::update;
}

sub copy {
  my $self = shift; my $orig = shift;
  $self->SUPER::copy($orig);
  $self->{caseInsensitive} = {%{$orig->{caseInsensitive}}};
}

sub addToken {
  my $self = shift; my $token = shift;
  my $data = $self->{context}{$self->{dataName}}{$token};
  return if $data->{hidden};
  my $field = (($data->{caseSensitive} || uc($token) eq lc($token)) ? "tokens" : "caseInsensitive");
  $self->{$field}{$token} = $self->{tokenType};
}

sub removeToken {
  my $self = shift; my $token = shift;
  my $data = $self->{context}{$self->{dataName}}{$token};
  return if $data->{hidden};
  my $field = (($data->{caseSensitive} || uc($token) eq lc($token)) ? "tokens" : "caseInsensitive");
  delete $self->{$field}{$token};
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
#  Clear the case-insensitive strings
#
sub clear {
  my $self = shift;
  $self->{caseInsensitive} = {}; $self->{patterns} = {};
  $self->SUPER::clear(@_);
}

#########################################################################

1;
