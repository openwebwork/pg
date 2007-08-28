loadMacros('MathObjects.pl');

sub _contextIntegerFunctions_init {context::IntegerFunctions2::Init()}; # don't reload this file

=head3 Context("IntegerFunctions")

 ######################################################################
 #
 #  This is a Parser context that adds integer related functions C(n,r)
 #  and P(n,r).  They can be used by the problem author and also by
 #  students if the answer checking is done by Parser.  The latter is
 #  the main purpose of this file.
 #
 #  Note: by default, webwork problems do not permit students to use
 #        C(n,r) and P(n,r) functions.  Problems which do permit this
 #        should alert the student in their text.
 #
 #  Usage examples:
 #     $b = random(2, 5); $a = $b+random(0, 5);
 #     $c = C($a, $b);
 #     ANS(Compute("P($a, $b)")->cmp);
 #
 #  Note: If the context is set to something else, such as Numeric, it
 #        can be set back with Context("IntegerFunctions").

=cut

package context::IntegerFunction2;
our @ISA = qw(Parser::Function::numeric2); # checks for 2 numeric inputs

sub C {
  shift; my ($n,$r) = @_; my $C = 1;
  return (0) if($r>$n);
  $r = $n-$r if ($r > $n-$r); # find the smaller of the two
  for (1..$r) {$C = ($C*($n-$_+1))/$_}
  return $C
}

sub P {
  shift; my ($n,$r) = @_; my $P = 1;
  return (0) if($r>$n);
  for (1..$r) {$P *= ($n-$_+1)}
  return $P
}

sub Init {
  my $context = $main::context{IntegerFunctions} = Parser::Context->getCopy("Numeric");
  $context->{name} = "IntegerFunctions";

  $context->functions->add(
    C => {class => 'context::IntegerFunction2'},
    P => {class => 'context::IntegerFunction2'},
  );

  main::Context("IntegerFunctions");
}

1;
