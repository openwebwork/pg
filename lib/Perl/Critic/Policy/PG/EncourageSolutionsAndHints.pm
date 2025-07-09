package Perl::Critic::Policy::PG::EncourageSolutionsAndHints;
use Mojo::Base 'Perl::Critic::Policy', -signatures;

use Perl::Critic::Utils qw(:severities :classification :ppi);

use constant DESCRIPTION => 'A %s is included';
use constant EXPLANATION => {
	solution => 'A solution should be added to all problems.',
	hint     => 'A hint is helpful for students.'
};
use constant SCORE => { solution => 15, hint => 10 };

sub supported_parameters ($) {return}
sub default_severity ($)     { return $SEVERITY_HIGHEST }
sub default_themes ($)       { return qw(pg) }
sub applies_to ($)           { return qw(PPI::Token::HereDoc) }

sub violates ($self, $element, $) {
	if (
		$element->terminator =~ /^END_(PGML_)?(SOLUTION|HINT)/
		&& $element->parent
		&& $element->parent->parent
		&& $element->parent->parent->parent
		&& ($element->parent->parent->parent->first_element eq 'PGML::Format2'
			|| $element->parent->parent->parent->first_element eq 'EV3P')
		&& is_function_call($element->parent->parent->parent->first_element)
		&& $element->parent->parent->parent->parent
		&& $element->parent->parent->parent->parent->parent
		&& $element->parent->parent->parent->parent->parent->first_element =~ /^(HINT|SOLUTION)$/
		&& is_function_call($element->parent->parent->parent->parent->parent->first_element)
		)
	{
		my $type = lc($1);
		return $self->violation(
			sprintf(DESCRIPTION, $type),
			{ score => SCORE->{$type}, explanation => EXPLANATION->{$type} },
			$element->parent->parent->parent->parent->parent
		);
	}
	return;
}

1;

__END__

=head1 NAME

Perl::Critic::Policy::PG::EncourageSolutionsAndHints - Solutions should be
provided in all problems, and hints are helpful for students.

=head1 DESCRIPTION

All problems should provide solutions that demonstrate how to work the problem,
and which do not just give the answers to the problem.

Hints are helpful for students that are struggling with the concepts presented
in the problem, and it is recommended that hints be added particularly for more
difficult problems.

=cut
