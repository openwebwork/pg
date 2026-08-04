package Perl::Critic::Policy::PG::ProhibitDeprecatedWeightedGrader;
use Mojo::Base 'Perl::Critic::Policy', -signatures;

use Perl::Critic::Utils qw(:severities :classification :ppi);

use constant DESCRIPTION     => 'The deprecated %s function is called';
use constant EXPLANATION     => 'The deprecated %s function should be replaced with a modern alternative.';
use constant SCORE           => 5;
use constant SAMPLE_PROBLEMS => [ [ 'Weighted Grader' => 'ProblemTechniques/WeightedGrader' ] ];
use constant WEIGHTED_GRADER_METHODS => {
	install_weighted_grader => 1,
	WEIGHTED_ANS            => 1,
	NAMED_WEIGHTED_ANS      => 1,
	weight_ans              => 1,
	CREDIT_ANS              => 1,
};

sub supported_parameters ($) {return}
sub default_severity ($)     { return $SEVERITY_HIGHEST }
sub default_themes ($)       { return qw(pg) }
sub applies_to ($)           { return qw(PPI::Token::Word) }

sub violates ($self, $element, $) {
	return unless WEIGHTED_GRADER_METHODS->{$element} && is_function_call($element);
	return $self->violation(sprintf(DESCRIPTION, $element),
		{ score => SCORE, explanation => sprintf(EXPLANATION, $element), sampleProblems => SAMPLE_PROBLEMS },
		$element);
}

1;

__END__

=head1 NAME

Perl::Critic::Policy::PG::ProhibitDeprecatedWeightedGrader - The
L<weightedGrader.pl> functionality is now included in the default
 L<avg_problem_grader|PGanswermacros.pl/avg_problem_grader>, and
this macros is no longer needed.

=head1 DESCRIPTION

The default L<avg_problem_grader|PGanswermacros.pl/avg_problem_grader>
includes all the functionality of the L<weightedGrader.pl>, and use of
this macro should be removed. Remove calling the function
C<install_weighted_grader>. Instead of calling C<WEIGHTED_ANS> or
C<NAMED_WEIGHTED_ANS>, pass C<< weight => n >> to the C<cmp> method.
In PGML use the following:

    [_]{$answer}{ cmp_options => { weight => n } }

Instead of calling C<CREDIT_ANS> pass C<< credit => $answer1 >> or
C<< credit => [$answer1, $answer2, ...] >> to the C<cmp> method.

=cut
