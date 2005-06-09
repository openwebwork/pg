#########################################################################
#
#  Implements the list of known functions
#
package Parser::Context::Functions;
use strict;
use vars qw (@ISA);
@ISA = qw(Value::Context::Data);

sub init {
  my $self = shift;
  $self->{dataName} = 'functions';
  $self->{name} = 'function';
  $self->{Name} = 'Function';
  $self->{namePattern} = '[a-zA-Z][a-zA-Z0-9]*';
}

#
#  Remove a function from the list by assigning it
#    the undefined function.  This means it will still
#    be recognized by the parser, but will generate an
#    error message whenever it is used.
#
sub undefine {
  my $self = shift;
  my @data = ();
  foreach my $x (@_) {push(@data,$x => {class => 'Parser::Function::undefined'})}
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
  shift if ref($_[0]) ne ""; # pop off the $self reference
  my @names = @_; my ($list,$name);
  my $context = Parser::Context->current;
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
  shift if ref($_[0]) ne ""; # pop off the $self reference
  my @names = @_; my ($list,$name);
  my $context = Parser::Context->current;
  while ($name = shift(@names)) {
    $list = $Category{$name};
    $list = [$name] if !$list && $context->{functions}{$name};
    unless (defined($list)) {warn "Undefined function or category '$name'"; next}
    if ($list->[0] eq '_alias_') 
      {unshift @names, @{$list}[1..scalar(@{$list})-1]; next}
    my @fn; foreach my $f (@{$list}) {
      push @fn, $f => 
        {class => $Parser::Context::Default::fullContext->{functions}{$f}{class}};
    }
    $context->functions->set(@fn);
  }
}

#########################################################################

1;
