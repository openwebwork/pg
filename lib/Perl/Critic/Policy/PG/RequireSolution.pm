package Perl::Critic::Policy::PG::RequireSolution;
use Mojo::Base 'Perl::Critic::Policy', -signatures;

use Perl::Critic::Utils qw(:severities :classification :ppi);

use constant DESCRIPTION => 'A solution is not included in this problem';
use constant EXPLANATION => 'A solution should be included in all problems.';
use constant SCORE       => 25;

sub supported_parameters ($) {return}
sub default_severity ($)     { return $SEVERITY_HIGHEST }
sub default_themes ($)       { return qw(pg) }
sub applies_to ($)           { return qw(PPI::Document) }

sub default_maximum_violations_per_document ($) { return 1; }

sub violates ($self, $element, $document) {
	my $solutionFound = 0;
	if (my $heredocs = $document->find('PPI::Token::HereDoc')) {
		for (@$heredocs) {
			if (
				$_->terminator =~ /^END_(PGML_)?SOLUTION$/
				&& $_->parent
				&& $_->parent->parent
				&& $_->parent->parent->parent
				&& ($_->parent->parent->parent->first_element eq 'PGML::Format2'
					|| $_->parent->parent->parent->first_element eq 'EV3P')
				&& is_function_call($_->parent->parent->parent->first_element)
				&& $_->parent->parent->parent->parent
				&& $_->parent->parent->parent->parent->parent
				&& $_->parent->parent->parent->parent->parent->first_element eq 'SOLUTION'
				&& is_function_call($_->parent->parent->parent->first_element)
				)
			{
				$solutionFound = 1;
				last;
			}
		}
	}
	return $self->violation(DESCRIPTION, { score => SCORE, explanation => EXPLANATION }, $document)
		unless $solutionFound;
	return;
}

1;

__END__

=head1 NAME

Perl::Critic::Policy::PG::RequireSolution - All problems should provide a
solution.

=head1 DESCRIPTION

A solution should be included in all problems. Note that a solution should
demonstrate all steps to solve a problem, and should certainly not just give the
answers to questions in the problem. This is one of the most challenging parts
of PG problem authoring, but the solution should not be omitted.

=cut
