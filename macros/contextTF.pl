loadMacros("Parser.pl");

sub _contextTF_init {}; # don't load it again

##########################################################
#
#  Implements contexts for string-valued answers especially
#  for matching problems (where you match against T and F).
#
#	Context("TF");
#
#  You can add new strings to the context as needed (or remove old ones)
#  via the Context()->strings->add() and Context()-strings->remove()
#  methods
#
#	ANS(TF_cmp("T","F"));
#
#  when there are two answers, the first being "T" and the second being "F".
#

package contextTF::Variable;

sub new {
  my $self = shift; my $equation = shift;
  my $context = $equation->{context};
  my @strings = grep {not defined($context->strings->get($_)->{alias})}
                  $context->strings->names;
  my $strings = join(', ',@strings[0..$#strings-1]).' or '.$strings[-1];
  $equation->Error("Your answer should be one of $strings");
}

package contextTF::Formula;
our @ISA = qw(Value::Formula Parser Value);

sub parse {
  my $self = shift;
  foreach my $ref (@{$self->{tokens}}) {
    $self->{ref} = $ref;
    contextTF::Variable->new($self) if ($ref->[0] eq 'error'); # display the error
  }
  $self->SUPER::parse(@_);
}

package main;

$context{TF} = Context("Numeric");
$context{TF}->parens->undefine('|','{','(','[');
$context{TF}->variables->clear();
$context{TF}->constants->clear();
$context{TF}->operators->clear();
$context{TF}->functions->clear();
$context{TF}->strings->are(
 "T" => {value => 1}, "t" => {alias => "T"},
 "F" => {value => 0}, "f" => {alias => "F"},
 "True" => {alias => "T"}, "False" => {alias => "F"},
 "TRUE" => {alias => "T"}, "FALSE" => {alias => "F"},
 "true" => {alias => "T"}, "false" => {alias => "F"},
);
$context{'TF'}->{parser}{Variable} = 'contextTF::Variable';
$context{'TF'}->{parser}{Formula}  = 'contextTF::Formula';

Context("TF");

sub TF_cmp {
  my $strings = shift;
  $strings = [$strings,@_] if (scalar(@_));
  $strings = [$strings] unless ref($strings) eq 'ARRAY';
  return map {String($_)->cmp(showHints=>0,showLengthHints=>0)} @{$strings};
}

