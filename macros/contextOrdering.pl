=head1 NAME

contextOrdering.pl - Parses ordered lists of letters like "B > A = C > D"

=head1 DESCRIPTION

This context provides a structured way to parse and check answers that
are ordered lists of letters, where the letters are separated by
greater-than signs or equal signs.  The only operators allowed are >
and =, and the only letters allowed are the ones you specify explicitly.

To access the context, you must include

	loadMacros("contextOrdering.pl");

at the top of your problem file, and then specify the Ordering context:

	Context("Ordering");

There are two main ways to use the Ordering context.  The first is to
use the Ordering() command to generate your ordering.  This command
creates a context in which the proper letters are defined, and returns
a MathObject that represents the ordering you have provided.  For
example,

	$ans = Ordering("B > A > C");

or

	$ans = Ordering(A => 2, B => 2.5, C => 1);

would both produce the same ordering.  The first form gives the
ordering as the student must type it, and the second gives the
ordering by specifying numeric values for the various letters that
induce the resulting order.  Note that equality is determined using
the default tolerances for the Ordering context.  You can change these
using commands like the following:

	Context("Ordering");
	Context()->flags->set(tolerance => .01, tolType => 'absolute');

If you want to allow lists of orderings, use the Ordering-List context:

	Context("Ordering-List");
	$ans = Ordering("A > B , B = C");

Note that each Ordering() call uses its own copy of the current
context.  If you need to modify the actual context used, then use the
context() method of the resulting object.

The second method of generating orderings is to declare the letters
you wish to use explicitly, and then build the Ordering objects using
the standard Compute() method:

	Context("Ordering");
	Letters("A","B","C","D");
	$a = Compute("A > B = C");
	$b = Compute("C > D");

Note that in this case, D is still a valid letter that students can
enter in response to an answer checker for $a, and similarly for A and
B with $b.  Note also that both $a and $b use the same context, unlike
orderings produced by calls to the Ordering() function.  Changes to
the current context WILL affect $a and $b.

If the ordering contains duplicate letters (e.g., "A > B > A"), then a
warning message will be issued.  If not all the letters are used by
the student, then that also produces a warning message.  The latter
can be controlled by the showMissingLetterHints flag to the cmp()
method.  For example:

	ANS(Ordering("A > B > C")->cmp(showMissingLetterHints => 0));

would prevent the message from being issued if the student submitted
just "A > B".

=cut

loadMacros("MathObjects.pl");

sub _contextOrdering_init {context::Ordering::Init()}

###########################################
#
#  The main Ordering routines
#

package context::Ordering;

#
#  Here we set up the prototype contexts and define the needed
#  functions in the main:: namespace.  Some error messages are
#  modified to read better for these contexts.
#
sub Init {
  my $context = $main::context{Ordering} = Parser::Context->getCopy("Numeric");
  $context->{name} = "Ordering";
  $context->parens->clear();
  $context->variables->clear();
  $context->constants->clear();
  $context->operators->clear();
  $context->functions->clear();
  $context->strings->clear();
  $context->operators->add(
   '>' => {precedence => 1.5, associativity => 'left', type => 'bin', class => 'context::Ordering::BOP::ordering'},
   '=' => {precedence => 1.7, associativity => 'left', type => 'bin', class => 'context::Ordering::BOP::ordering'},
  );
  $context->{parser}{String}  = "context::Ordering::Parser::String";
  $context->{parser}{Value}   = "context::Ordering::Parser::Value";
  $context->{value}{String}   = "context::Ordering::Value::String";
  $context->{value}{Ordering} = "context::Ordering::Value::Ordering";
  $context->strings->add('='=>{hidden=>1},'>'=>{hidden=>1});
  $context->{error}{msg}{"Variable '%s' is not defined in this context"} = "'%s' is not defined in this context";
  $context->{error}{msg}{"Unexpected character '%s'"} = "Can't use '%s' in this context";
  $context->{error}{msg}{"Missing operand before '%s'"} = "Missing letter before '%s'";
  $context->{error}{msg}{"Missing operand after '%s'"} = "Missing letter after '%s'";

  $context = $main::context{'Ordering-List'} = $context->copy;
  $context->{name} = 'Ordering-List';
  $context->operators->redefine(',',from => "Full");
  $context->{value}{List} = "context::Ordering::Value::List";

  main::PG_restricted_eval('sub Letters {context::Ordering::Letters(@_)}');
  main::PG_restricted_eval('sub Ordering {context::Ordering::Ordering(@_)}');
}

#
#  A routine to set the letters allowed in this context.
#  (Old letters are cleared, and > and = are allowed, but hidden,
#   since they are used in the List() objects that implement the context).
#
sub Letters {
  my $context = (Value::isContext($_[0]) ? shift : main::Context());
  my @strings;
  foreach my $x (@_) {push(@strings, $x => {isLetter => 1, caseSensitive => 1})}
  $context->strings->are(@strings);
  $context->strings->add('='=>{hidden=>1},'>'=>{hidden=>1});
}

#
#  Create orderings from strings or lists of letter => value pairs.
#  A copy of the current context is created that contains the proper
#  letters, and the correct string is created and parsed into an
#  Ordering object.
#
sub Ordering {
  my $context = main::Context()->copy; my $string;
  Value->Error("The current context is not the Ordering context")
    unless $context->{name} =~ m/Ordering/;
  if (scalar(@_) == 1) {
    $string = shift;
    my $letters = $string; $letters =~ s/ //g;
    context::Ordering::Letters($context,split(/[>=]/,$letters));
  } else {
    my %letter = @_; my @letters = keys %letter;
    context::Ordering::Letters($context,@letters);
    foreach my $x (@letters) {$letter{$x} = Value::Real->new($context,$letter{$x})}
    my @order = main::PGsort(
      sub {$letter{$_[0]} == $letter{$_[1]} ?  $_[0] lt $_[1] : $letter{$_[0]} > $letter{$_[1]}},
      @letters
    );
    my $a = shift(@order); my $b; $string = $a;
    while ($b = shift(@order)) {
      $string .= ($letter{$a} == $letter{$b} ? " = " : " > ") . $b;
      $a = $b;
    }
  }
  return main::Formula($context,$string)->eval;
}

#############################################################
#
#  This is a Parser BOP used to create the Ordering objects
#  used internally.  They are actually lists with the operator
#  and the two operands, and the comparisons is based on the
#  standard list comparisons.  The operands are either the strings
#  for individual letters, or another Ordering object as a
#  nested List.
#

package context::Ordering::BOP::ordering;
our @ISA = ('Parser::BOP');

sub class {"Ordering"}

sub isOrdering {
  my $self = shift; my $obj = shift; my $class = $obj->class;
  return $class eq 'Ordering' || $obj->{def}{isLetter};
}

sub _check {
  my $self = shift;
  $self->Error("Operands of %s must be letters",$self->{bop})
    unless $self->isOrdering($self->{lop}) && $self->isOrdering($self->{rop});
  $self->{letters} = $self->{lop}{letters}; # we modify {lop}{letters} this way, but that doesn't matter
  foreach my $x (keys %{$self->{rop}{letters}}) {
    if (defined($self->{letters}{$x})) {
      $self->{ref} = $self->{rop}{letters}{$x};
      $self->Error("Each letter may appear only once in an ordering");
    }
    $self->{letters}{$x} = $self->{rop}{letters}{$x};
  }
}

sub _eval {
  my $self = shift;
  my $ordering = $self->Package("Ordering")->new($self->context,$self->{bop},@_);
  $ordering->{letters} = $self->{letters};
  return $ordering;
}

sub string {
  my $self = shift;
  return $self->{lop}->string." ".$self->{bop}." ".$self->{rop}->string;
}

sub TeX {
  my $self = shift;
  return $self->{lop}->TeX." ".$self->{bop}." ".$self->{rop}->TeX;
}


#############################################################
#
#  This is the Value object used to implement the list That represents
#  one ordering operation.  It is simply a normal Value::List with the
#  operator as the first entry and the two operands as the remaing
#  entries in the list.  The new() method is overriden to make binary
#  trees of equal operators into flat sorted lists.  We override the
#  List string and TeX methods so that they print correctly as binary
#  operators.  The cmp_equal method is overriden to make sure the that
#  the lists are treated as a unit during answer checking.  There is
#  also a routine for adding letters to the object's context.
#

package context::Ordering::Value::Ordering;
our @ISA = ('Value::List');

#
#  Put all equal letters into one list and sort them
#
sub new {
  my $self = shift;
  my $context = (Value::isContext($_[0]) ? shift : $self->context);
  my $bop = shift; my @letters = @_;
  if ($bop eq '=') {
    if (Value::classMatch($letters[0],'Ordering') && $letters[0]->{data}[0] eq '=')
      {@letters = ($letters[0]->value,$letters[1]); shift @letters}
    @letters = main::lex_sort(@letters);
  }
  return $self->SUPER::new($context,$bop,@letters);
}

sub string {
  my $self = shift;
  my ($bop,@rest) = $self->value;
  foreach my $x (@rest) {$x = $x->string};
  return join(" $bop ",@rest);
}

sub TeX {
  my $self = shift;
  my ($bop,@rest) = $self->value;
  foreach my $x (@rest) {$x = $x->TeX};
  return join(" $bop ",@rest);
}

#
#  Make sure we do comparison as a list of lists (rather than as the
#  individual entries in the underlying Value::List that encodes
#  the ordering)
#
sub cmp_equal {
  my $self = shift; my $ans = $_[0];
  $ans->{typeMatch} = $ans->{firstElement} = $self;
  $ans->{correct_formula} = $self->{equation};
  $self = $ans->{correct_value} = Value::List->make($self);
  $ans->{student_value} = Value::List->make($ans->{student_value})
      if Value::classMatch($ans->{student_value},'Ordering');
  return $self->SUPER::cmp_equal(@_);
}

sub cmp_defaults {
  my $self = shift;
  return (
    $self->SUPER::cmp_defaults(@_),
    showMissingLetterHints => 1,
  );
}

sub cmp_postprocess {
  my $self = shift; my $ans = shift;
  return if $ans->{isPreview} || $ans->{score} != 0;
  $self->cmp_Error($ans,"Your ordering should include all the letters")
    if $ans->{showMissingLetterHints} &&
       scalar(keys %{$ans->{correct_formula}{tree}{letters}}) !=
       scalar(keys %{$ans->{student_formula}{tree}{letters}});
}

#
#  Add more letters to the ordering's context (so student answers
#  can include them even if they aren't in the correct answer).
#
sub AddLetters {
  my $self = shift; my $context = $self->context;
  my @strings;
  foreach my $x (@_) {
    push(@strings, $x => {isLetter => 1, caseSensitive => 1})
      unless $context->strings->get($x);
  }
  $context->strings->add(@strings) if scalar(@strings);
}

#############################################################
#
#  This overrides the TeX method of the letters
#  so that they don't print using the \rm font.
#

package context::Ordering::Value::String;
our @ISA = ('Value::String');

sub TeX {shift->value}


#############################################################
#
#  Override Parser classes so that we can check for repeated letters
#

package context::Ordering::Parser::String;
our @ISA = ('Parser::String');

#
#  Save the letters positional reference
#
sub new {
  my $self = shift;
  $self = $self->SUPER::new(@_);
  $self->{letters}{$self->{value}} = $self->{ref} if $self->{def}{isLetter};
  return $self;
}

#########################

package context::Ordering::Parser::Value;
our @ISA = ('Parser::Value');

#
#  Move letters to Value object
#
sub new {
  my $self = shift;
  $self = $self->SUPER::new(@_);
  $self->{letters} = $self->{value}{letters} if defined $self->{value}{letters};
  return $self;
}

#
#  Return Ordering class if the object is one
#
sub class {
  my $self = shift;
  return "Ordering" if $self->{value}->classMatch('Ordering');
  return $self->SUPER::class;
}

#############################################################
#
#  This overrides the cmp_equal method to make sure that
#  Ordering lists are put into nested lists (since the
#  underlying ordering is a list, we don't want the
#  list checker to test the individual parts of the list,
#  but rather the list as a whole).
#

package context::Ordering::Value::List;
our @ISA = ('Value::List');

sub cmp_equal {
  my $self = shift;  my $ans = $_[0];
  $ans->{student_value} = Value::List->make($ans->{student_value})
    if Value::classMatch($ans->{student_value},'Ordering');
  return $self->SUPER::cmp_equal(@_);
}

#############################################################

1;
