package Perl::Critic::Policy::PG::EncourageQualityMacroUsage;
use Mojo::Base 'Perl::Critic::Policy', -signatures;

use Perl::Critic::Utils qw(:severities :classification :ppi);

use constant DESCRIPTION => '%s is used from the macro %s';
use constant EXPLANATION => '%s is a high quality macro whose usage is encouraged.';

# FIXME: A better explanation is needed. Perhaps instead of a single explanation for all macros, add an explanation key
# to each of the methods below and give an explanation specific to the method and macro used.

use constant METHODS => {
	AnswerHints       => { macro => 'answerHints.pl',            score => 10 },
	CheckboxList      => { macro => 'parserCheckboxList.pl',     score => 10 },
	createLaTeXImage  => { macro => 'PGlateximage.pl',           score => 10 },
	createTikZImage   => { macro => 'PGtikz.pl',                 score => 10 },
	DataTable         => { macro => 'niceTables.pl',             score => 10 },
	DraggableProof    => { macro => 'draggableProof.pl',         score => 10 },
	DraggableSubset   => { macro => 'draggableSubset.pl',        score => 10 },
	DropDown          => { macro => 'parserPopUp.pl',            score => 10 },
	Graph3D           => { macro => 'plotly3D.pl',               score => 10 },
	GraphTool         => { marco => 'parserGraphTool.pl',        score => 10 },
	LayoutTable       => { macro => 'niceTables.pl',             score => 10 },
	MultiAnswer       => { macro => 'parserMultiAnswer.pl',      score => 30 },
	Plots             => { macro => 'plots.pl',                  score => 10 },
	RadioButtons      => { macro => 'parserRadioButtons.pl',     score => 10 },
	RadioMultiAnswer  => { macro => 'parserRadioMultiAnswer.pl', score => 30 },
	randomLastName    => { macro => 'randomPerson.pl',           score => 10 },
	randomPerson      => { macro => 'randomPerson.pl',           score => 10 },
	'Scaffold::Begin' => { macro => 'scaffold.pl',               score => 20 }
};

sub supported_parameters ($) {return}
sub default_severity ($)     { return $SEVERITY_HIGHEST }
sub default_themes ($)       { return qw(pg) }
sub applies_to ($)           { return qw(PPI::Token::Word) }

sub violates ($self, $element, $document) {
	return unless METHODS->{$element} && is_function_call($element);
	return $self->violation(sprintf(DESCRIPTION, $element, METHODS->{$element}{macro}),
		{ score => METHODS->{$element}{score}, explanation => sprintf(EXPLANATION, METHODS->{$element}{macro}) },
		$element);
}

1;

__END__

=head1 NAME

Perl::Critic::Policy::PG::EncourageQualityMacroUsage - Usage of macros that are
well maintained and provide advanced MathObject answers is encouraged.

=head1 DESCRIPTION

Usage of macros that are well maintained and provide advanced MathObject answers
is encouraged. This policy currently recognizes the usage of the following
macros:

=over

=item * L<answerHints.pl>

=item * L<parserCheckboxList.pl>

=item * L<PGlateximage.pl>

=item * L<PGtikz.pl>

=item * L<niceTables.pl>

=item * L<draggableProof.pl>

=item * L<draggableSubset.pl>

=item * L<parserPopUp.pl>

=item * L<plotly3D.pl>

=item * L<parserGraphTool.pl>

=item * L<niceTables.pl>

=item * L<parserMultiAnswer.pl>

=item * L<plots.pl>

=item * L<parserRadioButtons.pl>

=item * L<parserRadioMultiAnswer.pl>

=item * L<randomPerson.pl>

=item * L<randomPerson.pl>

=item * L<scaffold.pl>

=back

=cut
