loadMacros("Parser.pl");

sub _contextABCD_init {}; # don't load it again

##########################################################
#
#  Implements contexts for string-valued answers especially
#  for matching problems (where you match against A, B, C, D,
#  and so on).
#
#  There are two contexts defined here,
#
#	Context("ABCD");
#	Context("ABCD-List");
#
#  The second allows the students to enter lists of strings,
#  while the first does not.
#
#  You can add new strings to the context as needed (or remove old ones)
#  via the Context()->strings->add() and Context()-strings->remove()
#  methods, eg.
#
#	Context("ABCD-List")->strings->add(E=>{},e=>{alias=>"E"});
#
#  Use string_cmp() to produce the answer checker(s) for your
#  correct values.  Eg.
#
#	ANS(string_cmp("A","B"));
#
#  when there are two answers, the first being "A" and the second being "B".
#

package contextABCD::Variable;

sub new {
  my $self = shift; my $equation = shift;
  my $context = $equation->{context};
  my @strings = grep {not defined($context->strings->get($_)->{alias})}
                  $context->strings->names;
  my $strings = join(', ',@strings[0..$#strings-1]).' or '.$strings[-1];
  $equation->Error("Your answer should be one of $strings");
}

package contextABCD::Formula;
our @ISA = qw(Value::Formula Parser Value);

sub parse {
  my $self = shift;
  foreach my $ref (@{$self->{tokens}}) {
    $self->{ref} = $ref;
    contextABCD::Variable->new($self) if ($ref->[0] eq 'error'); # display the error
  }
  $self->SUPER::parse(@_);
}

package main;

$context{ABCD} = Context("Numeric");
$context{ABCD}->parens->undefine('|','{','(','[');
$context{ABCD}->variables->clear();
$context{ABCD}->constants->clear();
$context{ABCD}->operators->clear();
$context{ABCD}->functions->clear();
$context{ABCD}->strings->are(
 "A" => {}, "a" => {alias => "A"},
 "B" => {}, "b" => {alias => "B"},
 "C" => {}, "c" => {alias => "C"},
 "D" => {}, "d" => {alias => "D"},
);
$context{'ABCD'}->{parser}{Variable} = 'contextABCD::Variable';
$context{'ABCD'}->{parser}{Formula}  = 'contextABCD::Formula';

$context{'ABCD-List'} = $context{ABCD}->copy;
$context{'ABCD-List'}->operators->add(
  ',' => $Parser::Context::Default::fullContext->operators->get(','),
);
$context{'ABCD-List'}->strings->add("NONE"=>{});

Context("ABCD");

sub string_cmp {
  my $strings = shift;
  $strings = [$strings,@_] if (scalar(@_));
  $strings = [$strings] unless ref($strings) eq 'ARRAY';
  return map {String($_)->cmp(showHints=>0,showLengthHints=>0)} @{$strings};
}

