#########################################################################
#
#  Implements the list of known functions
#
package Parser::Context::Functions;
use strict;
our @ISA = qw(Value::Context::Data);

sub init {
  my $self = shift;
  $self->{dataName} = 'functions';
  $self->{name} = 'function';
  $self->{Name} = 'Function';
  $self->{namePattern} = qr/\w+|\x{221A}/;  # U+221A is the square root surd symbol
  $self->{tokenType} = 'fn';
}

#
#  Remove a function from the list by assigning it
#    the undefined function.  This means it will still
#    be recognized by the parser, but will generate an
#    error message whenever it is used.  The old class
#    is saved so that it can be redefined again.
#
sub undefine {
  my $self = shift;
  my @data = ();
  foreach my $x (@_) {
    push(@data,$x => {
      oldClass => $self->get($x)->{class},
      class => 'Parser::Function::undefined',
    });
  }
  $self->set(@data);
}

sub redefine {
  my $self = shift; my $X = shift;
  return $self->SUPER::redefine($X,@_) if scalar(@_) > 0;
  $X = [$X] unless ref($X) eq 'ARRAY';
  my @data = ();
  foreach my $x (@{$X}) {
    my $oldClass = $self->get($x)->{oldClass};
    push(@data,$x => {class => $oldClass, oldClass => undef})
      if $oldClass;
  }
  $self->set(@data);
}

#########################################################################
#
#  Handle enabling and disabling functions
#

my %Category = (
   SimpleTrig  => [qw(sin cos tan sec csc cot)],
   InverseTrig => [qw(asin acos atan asec acsc acot
		      arcsin arccos arctan arcsec arccsc arccot atan2)],

   SimpleHyperbolic  => [qw(sinh cosh tanh sech csch coth)],
   InverseHyperbolic => [qw(asinh acosh atanh asech acsch acoth
                            arcsinh arccosh arctanh arcsech arccsch arccoth)],

   Numeric     => [qw(log log10 exp sqrt abs int sgn ln logten)],

   Vector      => [qw(norm unit)],

   Complex     => [qw(arg mod Re Im conj)],

   Hyperbolic  => [qw(_alias_ SimpleHyperbolic InverseHyperbolic)],
   Trig        => [qw(_alias_ SimpleTrig InverseTrig Hyperbolic)],
   All         => [qw(_alias_ Trig Numeric Vector Complex)],
);

sub disable {Disable(@_)}
sub Disable {
  my $context = Parser::Context->current;
  if (ref($_[0]) ne "") {$context = (shift)->{context}}
  my @names = @_; my ($list,$name);
  while ($name = shift(@names)) {
    $list = $Category{$name};
    $list = [$name] if !$list && $context->{functions}{$name};
    unless (defined($list)) {warn "Undefined function or category '$name'"; next}
    if ($list->[0] eq '_alias_')
      {unshift @names, @{$list}[1..scalar(@{$list})-1]; next}
    $context->functions->undefine(@{$list});
  }
}

sub enable {Enable(@_)}
sub Enable {
  my $context = Parser::Context->current;
  my $functions = $Parser::Context::Default::context{Full}->{functions};
  if (ref($_[0]) ne "") {$context = (shift)->{context}}
  my @names = @_; my ($list,$name);
  while ($name = shift(@names)) {
    $list = $Category{$name};
    $list = [$name] if !$list && $context->{functions}{$name};
    unless (defined($list)) {warn "Undefined function or category '$name'"; next}
    if ($list->[0] eq '_alias_')
      {unshift @names, @{$list}[1..scalar(@{$list})-1]; next}
    my @fn; foreach my $f (@{$list})
      {push @fn, $f => {class => $functions->{$f}{class}}}
    $context->functions->set(@fn);
  }
}

#########################################################################

1;
