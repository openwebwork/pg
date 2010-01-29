####################################################################
#
#  Implements a context in which the student's answer is treated as a
#  literal string, and not parsed further.  The real answer checking
#  should be performed in a custom checker passed to the answer
#  string's cmp() method.  E.g.,
#
#        loadMacros("contextArbitraryString.pl");
#        Context("ArbitraryString");
#
#        ANS(Compute("The string I want")->cmp(checker => sub {
#          my ($correct,$student,$ans) = @_;
#          $correct = $correct->value; # get perl string from String object
#          $student = $student->value; # ditto
#          ##
#          ## do your checking here, and return true if correct
#          ## or false if incorrect.  For example
#          ##   return $correct eq $student;
#          ##
#          return $score;
#        }));
#

sub _contextArbitraryString_init {
  my $context = $main::context{ArbitraryString} = Parser::Context->getCopy("Numeric");
  $context->{name} = "ArbitraryString";
  $context->parens->clear();
  $context->variables->clear();
  $context->constants->clear();
  $context->operators->clear();
  $context->functions->clear();
  $context->strings->clear();
  $context->{pattern}{number} = "^\$";
  $context->variables->{patterns} = {};
  $context->strings->{patterns}{".*"} = [-20,'str'];
  $context->{value}{"String()"} = "context::ArbitraryString";
  $context->{parser}{String} = "context::ArbitraryString::String";
  $context->update;
}

package context::ArbitraryString;
sub new {shift; main::Compute(@_)}

package context::ArbitraryString::String;
our @ISA = ('Parser::String');

sub new {
  my $self = shift;
  my ($equation,$value,$ref) = @_;
  $value = $equation->{string};
  $self->SUPER::new($equation,$value,$ref);
}

1;
