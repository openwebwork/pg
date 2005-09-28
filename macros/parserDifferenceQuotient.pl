loadMacros('Parser.pl');

sub _parserDifferenceQuotient_init {}; # don't reload this file

######################################################################
#
#  This is a Parser class that implements an answer checker for
#  difference quotients as a subclass of the Formula class.  The
#  standard ->cmp routine will work for this.  The difference quotient
#  is just a special type of formula with a special variable
#  for 'dx'.  The checker will give an error message if the
#  student's result contains a dx in the denominator, meaning it
#  is not fully reduced.
#
#  Use DifferenceQuotient(formula) to create a difference equation
#  object.  If the context has more than one variable, the first one
#  alphabetically is used to form the dx.  Otherwise, you can specify
#  the variable used for dx as the second argument to
#  DifferenceQuotient().  You could use a variable like h instead of
#  dx if you prefer.
#
#  Usage examples:
#
#      $df = DifferenceQuotient("2x+dx");
#      ANS($df->cmp);
#
#      $df = DifferenceQuotient("2x+h","h");
#      ANS($df->cmp);
#
#      Context()->variables->are(t=>'Real',a=>'Real');
#      ANS(DifferenceQuotient("-a/[t(t+dt)]","dt")->cmp);
#

Context("Numeric");

sub DifferenceQuotient {new DifferenceQuotient(@_)}

package DifferenceQuotient;
our @ISA = qw(Value::Formula);

sub new {
  my $self = shift; my $class = ref($self) || $self;
  my $formula = shift;
  my $dx = shift || 'd'.($$Value::context->variables->names)[0];
  #
  #  Save the original context, and make a copy to which we
  #  add a variable for 'dx'
  #
  my $current = $$Value::context;
  my $context = main::Context($current->copy);
  $context->{_variables}->{pattern} = $context->{_variables}->{namePattern} =
    $dx . '|' . $context->{_variables}->{pattern};
  $context->update;
  $context->variables->add($dx=>'Real');
  $q = bless $self->SUPER::new($formula), $class;
  $q->{isValue} = 1; $q->{isFormula} = 1; $q->{dx} = $dx;
  main::Context($current);  # put back the original context;
  return $q;
}

sub cmp_class {'a Difference Quotient'}

sub cmp_defaults{(
  shift->SUPER::cmp_defaults,
  ignoreInfinity => 0,
)}

sub cmp_postprocess {
  my $self = shift; my $ans = shift; my $dx = $self->{dx};
  return if $ans->{score} == 0 || $ans->{isPreview};
  $main::__student_value__ = $ans->{student_value};
  my ($value,$err) = main::PG_restricted_eval('$__student_value__->substitute('.$dx.'=>0)->reduce');
  $self->cmp_Error($ans,"It looks like you didn't finish simplifying your answer")
    if $err && $err =~ m/division by zero/i;
}

