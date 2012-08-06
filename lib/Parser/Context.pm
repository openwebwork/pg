#########################################################################

package Parser::Context;
my $pkg = "Parser::Context";
use strict; no strict "refs";
our @ISA = ("Value::Context");

#
#  Create a new Context object and initialize its data lists
#
sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $context = $Value::defaultContext->copy;
  bless $context, $class;
  $context->{parser} = {%{$Parser::class}};
  push(@{$context->{data}{values}},'parser');
  $context->{_initialized} = 0;
  my %data = (
    functions => {},
    variables => {},
    constants => {},
    operators => {},
    strings   => {},
    parens    => {},
    lists     => {},
    flags     => {},
    reduction => {},
    @_
  );
  $context->{_functions} = new Parser::Context::Functions($context,%{$data{functions}});
  $context->{_variables} = new Parser::Context::Variables($context,%{$data{variables}});
  $context->{_constants} = new Parser::Context::Constants($context,%{$data{constants}});
  $context->{_operators} = new Parser::Context::Operators($context,%{$data{operators}});
  $context->{_strings}   = new Parser::Context::Strings($context,%{$data{strings}});
  $context->{_parens}    = new Parser::Context::Parens($context,%{$data{parens}});
  $context->{_reduction} = new Parser::Context::Reduction($context,%{$data{reduction}});
  $context->lists->set(%{$data{lists}});
  $context->flags->set(%{$data{flags}});
  $context->{_initialized} = 1;
  $context->update;
  return $context;
}

#
#  Update the token pattern
#
sub update {
  my $self = shift; return unless $self->{_initialized};
  my @patterns = ([$self->{pattern}{number},-10,'num']);
  my @tokens;
  foreach my $name (@{$self->{data}{objects}}) {
    my $data = $self->{$name};
    foreach my $pattern (keys %{$data->{patterns}}) {
      my $def = $data->{patterns}{$pattern};
      $def = [$def,$data->{tokenType}] unless ref($def) eq 'ARRAY';
      push @patterns,[$pattern,@{$def}];
    }
    push @tokens,%{$data->{tokens}};
  }
  $self->{pattern}{type} = [];
  $self->{pattern}{tokenType} = {@tokens};
  push @patterns,[getPattern(keys %{$self->{pattern}{tokenType}}),0,''];
  @patterns = sort byPrecedence @patterns;
  foreach my $pattern (@patterns) {
    push @{$self->{pattern}{type}}, $pattern->[2];
    $pattern = $pattern->[0];
  }
  my $pattern = '('.join(')|(',@patterns).')';
  $self->{pattern}{token} = qr/$pattern/;
}

#
#  Build a regexp pattern from the characters and list of names
#  (protect special characters)
#
sub getPattern {
  my $single = ''; my @multi = ();
  foreach my $x (sort byName (@_))
    {if (length($x) == 1) {$single .= $x} else {push(@multi,$x)}}
  foreach my $x (@multi) {$x = protectRegexp($x) unless substr($x,0,3) eq '(?:'}
  my @pattern = ();
  push(@pattern,join('|',@multi)) if scalar(@multi) > 0;
  push(@pattern,protectRegexp($single)) if length($single) == 1;
  push(@pattern,"[".protectChars($single)."]") if length($single) > 1;
  my $pattern = join('|',@pattern);
  $pattern = '^$' if $pattern eq '';
  return $pattern;
}

sub protectRegexp {
  my $string = shift;
  $string =~ s/[\[\](){}|+.*?\\^\$]/\\$&/g;
  return $string;
}

sub protectChars {
  my $string = shift;
  $string =~ s/([\^\]\\])/\\$1/g;
  $string =~ s/^(.*)-(.*)$/-$1$2/g;
  return $string;
}

#
#  Sort names so that they can be joined for regexp matching
#  (longest first, then alphabetically)
#
sub byName {
  my $result = length($b) <=> length($a);
  $result = $a cmp $b unless $result;
  return $result;
}
#
#  Sort by precedence, then type
#
sub byPrecedence {
  my $result = $a->[1] <=> $b->[1];
  $result = $a->[2] cmp $b->[2] unless $result;
  $result = $b->[0] cmp $a->[0] unless $result;
  return $result;
}



#
#  Access to the data lists
#
sub operators {(shift)->{_operators}}
sub functions {(shift)->{_functions}}
sub constants {(shift)->{_constants}}
sub variables {(shift)->{_variables}}
sub strings   {(shift)->{_strings}}
sub parens    {(shift)->{_parens}}
sub reduction {(shift)->{_reduction}}

sub reduce     {(shift)->{_reduction}->reduce(@_)}
sub noreduce   {(shift)->{_reduction}->noreduce(@_)}
sub reductions {(shift)->{_reduction}}

#
#  Store pointer to user's context table
#
my $userContext;

#
#  Set/Get the current Context object
#
sub current {
  my $self = shift; my $contextTable = shift; my $context = shift;
  if ($contextTable) {$userContext = $contextTable} else {$contextTable = $userContext}
  if (defined($context)) {
    if (!ref($context)) {
      my $name = $context;
      $context = Parser::Context->getCopy($contextTable,$context);
      Value::Error("Unknown context '%s'",$name) unless defined($context);
    }
    $contextTable->{current} = $context;
    $Value::context = \$contextTable->{current};
  } elsif (!defined($contextTable->{current})) {
    $contextTable->{current} = $Parser::Context::Default::context{Numeric}->copy;
    $Value::context = \$contextTable->{current};
  }
  return $contextTable->{current};
}

#
#  Get a copy of a named context
#   (either from the (optional) list provided, the main user's list
#    or from the default list)
#
sub getCopy {
  my $self = shift; my $contextTable;
  $contextTable = shift if !defined $_[0] || ref($_[0]) eq 'HASH';
  $contextTable = $userContext unless $contextTable;
  my $name = shift; my $context = $contextTable->{$name};
  $context = $Parser::Context::Default::context{$name} unless $context;
  return unless $context;
  $context = $context->copy;
  $context->{name} = $name;
  return $context;
}

#
#  Obsolete:  use "getCopy" instead
#
sub get {shift->getCopy(@_)}

#
#  Update the precedences of multiplication so that they
#  are the standard or non-standard ones, depending on the
#  argument.  It should be 'Standard' or 'Non-Standard'.
#
sub usePrecedence {
  my $self = shift;
  for (shift) {

    /^Standard/i  and do {
      $self->operators->set(
        ' *' => {precedence => 3},
        '* ' => {precedence => 3},
        ' /' => {precedence => 3},
        '/ ' => {precedence => 3},
         fn  => {precedence => 7.5},
         ' ' => {precedence => 3},
      );
      last;
    };

    /^Non-Standard/i and do {
      $self->operators->set(
        ' *' => {precedence => 2.8},
        '* ' => {precedence => 2.8},
        ' /' => {precedence => 2.8},
        '/ ' => {precedence => 2.8},
         fn  => {precedence => 2.9},
         ' ' => {precedence => 3.1},
      );
      last;
    };

    Value::Error("Precedence type should be one of 'Standard' or 'Non-Standard'");
  }
}

#########################################################################
#
#  Load the subclasses.
#

END {
  use Parser::Context::Constants;
  use Parser::Context::Functions;
  use Parser::Context::Operators;
  use Parser::Context::Parens;
  use Parser::Context::Strings;
  use Parser::Context::Variables;
  use Parser::Context::Reduction;
}

#########################################################################

1;
