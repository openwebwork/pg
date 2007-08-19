loadMacros("MathObjects.pl");

sub _contextString_init {}; # don't load it again

=head3 Context("String")

 ##########################################################
 #
 #  Implements contexts for string-valued answers.
 #
 #  You can add new strings to the context as needed
 #  via the Context()->strings->add() method.  E.g.,
 #
 #	Context("String")->strings->add(Foo=>{}, Bar=>{alias=>"Foo"});
 #
 #  Use string_cmp() to produce the answer checker(s) for your
 #  correct values.  Eg.
 #
 #	ANS(string_cmp("Foo"));
 #

=cut

package contextString::Variable;

sub new {
  my $self = shift; my $equation = shift;
  my $context = $equation->{context};
  my @strings = grep {not defined($context->strings->get($_)->{alias})}
                  $context->strings->names;
  my $strings = join(', ',@strings[0..$#strings-1]).' or '.$strings[-1];
  $equation->Error(["Your answer should be one of %s",$strings]);
}

package contextString::Formula;
our @ISA = qw(Value::Formula Parser Value);

sub parse {
  my $self = shift;
  foreach my $ref (@{$self->{tokens}}) {
    $self->{ref} = $ref;
    contextString::Variable->new($self) if ($ref->[0] eq 'error'); # display the error
  }
  $self->SUPER::parse(@_);
}

package main;

$context{String} = Parser::Context->getCopy("Numeric");
$context{String}->parens->undefine('|','{','(','[');
$context{String}->variables->clear();
$context{String}->constants->clear();
$context{String}->operators->clear();
$context{String}->functions->clear();
$context{String}->strings->clear();
$context{String}->{parser}{Variable} = 'contextString::Variable';
$context{String}->{parser}{Formula}  = 'contextString::Formula';

Context("String");

sub string_cmp {
  my $strings = shift;
  $strings = [$strings,@_] if (scalar(@_));
  $strings = [$strings] unless ref($strings) eq 'ARRAY';
  return map {String($_)->cmp(showHints=>0,showLengthHints=>0)} @{$strings};
}

1;

