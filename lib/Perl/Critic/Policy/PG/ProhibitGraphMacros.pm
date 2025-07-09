package Perl::Critic::Policy::PG::ProhibitGraphMacros;
use Mojo::Base 'Perl::Critic::Policy', -signatures;

use Perl::Critic::Utils qw(:severities :classification :ppi);

use WeBWorK::PG::Critic::Utils qw(getDeprecatedMacros);

use constant DESCRIPTION => 'The init_graph function from PGgraphmacros.pl is called';
use constant EXPLANATION => 'PGgraphmacros.pl generates poor quality graphics. Consider using a modern alternative.';
use constant SCORE       => -20;
use constant SAMPLE_PROBLEMS => [
	[ 'TikZ Graph Images'        => 'ProblemTechniques/TikZImages' ],
	[ 'Inserting Images in PGML' => 'ProblemTechniques/Images' ],
	[ 'Function Plot'            => 'Algebra/FunctionPlot' ]
];

sub supported_parameters ($) {return}
sub default_severity ($)     { return $SEVERITY_HIGHEST }
sub default_themes ($)       { return qw(pg) }
sub applies_to ($)           { return qw(PPI::Token::Word) }

sub violates ($self, $element, $) {
	return unless $element eq 'init_graph' && is_function_call($element);
	return $self->violation(DESCRIPTION,
		{ score => SCORE, explanation => EXPLANATION, sampleProblems => SAMPLE_PROBLEMS }, $element);
}

1;

__END__

=head1 NAME

Perl::Critic::Policy::PG::ProhibitGraphMacros - L<PGgraphmacros.pl> generates
poor quality graphics. Modern alternatives should be used instead.

=head1 DESCRIPTION

L<PGgraphmacros.pl> generates poor quality graphics. Replace its usage with a
modern alternative such as L<PGtikz.pl>, L<PGlateximage.pl>, or L<plots.pl>.

=cut
