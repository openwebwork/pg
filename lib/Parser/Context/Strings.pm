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
  $self->{ciAlternatives} = {};
}

sub update {
  my $self = shift;
  my @strings = keys %{$self->{caseInsensitive}};
  $self->{patterns} = {};
  if (@strings) {
    my $pattern = '(?i)(?:'.Parser::Context::getPattern(@strings).')';
    $self->{patterns}{$pattern} = [$self->{precedence},$self->{tokenType}];
  }
  foreach my $token (keys %{$self->{ciAlternatives}}) {
    my $pattern = '(?i)(?:'.Parser::Context::getPattern(@{$self->{ciAlternatives}{$token}}).')';
    $self->{patterns}{$pattern} = [$self->{precedence},[$self->{tokenType},$token]];
  }
  $self->SUPER::update;
}

sub copy {
  my $self = shift; my $orig = shift;
  $self->SUPER::copy($orig);
  $self->{caseInsensitive} = {%{$orig->{caseInsensitive}}};
  $self->{ciAlternatives} = {};
  foreach my $token (keys %{$orig->{ciAlternatives}}) {
    $self->{ciAlternatives}{$token} = [@{$orig->{ciAlternatives}{$token}}];
  }
}

#
#  Keep case insensitive strings separate so that they can be
#    added as a separate pattern in the update method
#
sub addToken {
  my $self = shift; my $token = shift;
  my $data = $self->{context}{$self->{dataName}}{$token};
  return if $data->{hidden};
  my $field = (($data->{caseSensitive} || uc($token) eq lc($token)) ? "tokens" : "caseInsensitive");
  $self->{$field}{$token} = $self->{tokenType};
  $self->addAlternatives($token,$data->{alternatives});
}
#
#  Add case sensitive alternatives as normal, otherwise
#    add them to the ciAlternative list
#
sub addAlternatives {
  my $self = shift; my $token = shift; my $alternatives = shift || [];
  my $data = $self->{context}{$self->{dataName}}{$token};
  return if $data->{hidden} || !@$alternatives;
  if ($data->{caseSensitive}) {
    $self->SUPER::addAlternatives($token, $data->{alternatives});
  } else {
    my @strings = ();
    foreach my $alt (@$alternatives) {
      Value::Error("Illegal %s name '%s'",$self->{name},$alt) unless $alt =~ m/^$self->{namePattern}$/;
      if (uc($alt) eq lc($alt)) {
        $self->SUPER::addAlternatives($token, [$alt]);
      } else {
        push(@strings, $alt);
      }
    }
    $self->{ciAlternatives}{$token} = [@strings] if @strings;
  }
}

sub removeToken {
  my $self = shift; my $token = shift;
  my $data = $self->{context}{$self->{dataName}}{$token};
  return if $data->{hidden};
  my $field = (($data->{caseSensitive} || uc($token) eq lc($token)) ? "tokens" : "caseInsensitive");
  delete $self->{$field}{$token};
  $self->removeAlternatives($token);
}
sub removeAlternatives {
  my $self = shift; my $token = shift;
  delete $self->{ciAlternatives}{$token};
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
