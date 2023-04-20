
=head1 NAME

AnswerFormatHelp.pl

=head1 SYNOPSIS

THIS MACRO IS DEPRECATED. DO NOT USE THIS MACRO IN NEWLY WRITTEN PROBLEMS.
Use C<helpLink> from PGbasicmacros.pl instead.

Creates links for students to help documentation on formatting
answers and allows for custom help links.

=head1 DESCRIPTION

There are 16 predefined help links: angles, decimals, equations,
exponents, formulas, fractions, inequalities, intervals, limits,
logarithms, matrices, numbers, points, syntax, units, vectors.

Usage:

     DOCUMENT();
     loadMacros("PGstandard.pl","AnswerFormatHelp.pl",);
     TEXT(beginproblem());
     BEGIN_TEXT
     \{ ans_rule(20) \}
     \{ AnswerFormatHelp("formulas") \} $PAR
     \{ ans_rule(20) \}
     \{ AnswerFormatHelp("equations","help entering equations") \} $PAR
     END_TEXT
     ENDDOCUMENT();


The first example use defaults and displays the help link right next to
the answer blank, which is recommended.  The second example customizes
the link text displayed to the student, but the actual help document
is unaffected.

=cut

sub _AnswerFormatHelp_init { };    # don't reload this file

sub AnswerFormatHelp {
	my ($helptype, $customstring) = @_;
	return helpLink($helptype, $customstring);
}

1;
