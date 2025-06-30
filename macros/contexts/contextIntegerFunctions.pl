# Note: the way this is used, it appears that want to allow P and C to be used by
# authors but not students, so why is this a context?

=head1 NAME

contextIntegerFunctions.pl - adds integer related functions C(n,r) and P(n,r).

=head1 DESCRIPTION

This is a Parser context that adds integer related functions C(n,r)
and P(n,r).  They can be used by the problem author and also by
students if the answer checking is done by Parser.  The latter is
the main purpose of this file.

B<Note:> by default, webwork problems do not permit students to use
C(n,r) and P(n,r) functions.  Problems which do permit this
should alert the student in their text.

=head1 SYNOPSISS

    Context("IntegerFunctions")

    $b = random(2, 5); $a = $b+random(0, 5);
    $c = C($a, $b);
    ANS(Compute("P($a, $b)")->cmp);

B<Note:> If the context is set to something else, such as Numeric, it
can be set back with Context("IntegerFunctions").

=cut

loadMacros('MathObjects.pl');

sub _contextIntegerFunctions_init { context::IntegerFunctions2::Init() };    # don't reload this file

package context::IntegerFunctions2;
our @ISA = qw(Parser::Function::numeric2);                                   # checks for 2 numeric inputs

sub C {
	shift;
	my ($n, $r) = @_;
	my $C = 1;
	return (0)   if ($r > $n);
	$r = $n - $r if ($r > $n - $r);    # find the smaller of the two
	for (1 .. $r) { $C = ($C * ($n - $_ + 1)) / $_ }
	return $C;
}

sub P {
	shift;
	my ($n, $r) = @_;
	my $P = 1;
	return (0) if ($r > $n);
	for (1 .. $r) { $P *= ($n - $_ + 1) }
	return $P;
}

sub Init {
	my $context = $main::context{IntegerFunctions} = Parser::Context->getCopy("Numeric");
	$context->{name} = "IntegerFunctions";

	$context->functions->add(
		C => { class => 'context::IntegerFunctions2' },
		P => { class => 'context::IntegerFunctions2' },
	);

	main::Context("IntegerFunctions");
}

1;
