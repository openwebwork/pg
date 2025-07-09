package Perl::Critic::Policy::PG::EncouragePGMLUsage;
use Mojo::Base 'Perl::Critic::Policy', -signatures;

use Perl::Critic::Utils qw(:severities :classification :ppi);

use constant DESCRIPTION => 'PGML is used for problem text';
use constant EXPLANATION => 'PGML should be used for problem text.';
use constant SCORE       => 20;

sub supported_parameters ($) {return}
sub default_severity ($)     { return $SEVERITY_HIGHEST }
sub default_themes ($)       { return qw(pg) }
sub applies_to ($)           { return qw(PPI::Token::HereDoc) }

# Only report this once even if there are multiple PGML blocks in the problem.
sub default_maximum_violations_per_document ($) { return 1; }

sub violates ($self, $element, $document) {
	return $self->violation(
		DESCRIPTION,
		{ score => SCORE, explanation => EXPLANATION },
		$element->parent->parent->parent->parent->parent
		)
		if $element->terminator =~ /^END_PGML(_SOLUTION|_HINT)?$/
		&& $element->parent
		&& $element->parent->parent
		&& $element->parent->parent->parent
		&& $element->parent->parent->parent->first_element eq 'PGML::Format2'
		&& is_function_call($element->parent->parent->parent->first_element)
		&& $element->parent->parent->parent->parent
		&& $element->parent->parent->parent->parent->parent
		&& $element->parent->parent->parent->parent->parent->first_element =~ /^(STATEMENT|HINT|SOLUTION)$/
		&& is_function_call($element->parent->parent->parent->parent->parent->first_element);
	return;
}

1;

__END__

=head1 NAME

Perl::Critic::Policy::PG::EncouragePGMLUsages - All problems should use PGML to
insert problem text.

=head1 DESCRIPTION

All problems should use PGML via C<BEGIN_PGML>/C<END_PGML>,
C<BEGIN_PGML_HINT>/C<END_PGML_HINT>, or
C<BEGIN_PGML_SOLUTION>/C<END_PGML_SOLUTION> blocks to insert problem text,
instead of the older C<BEGIN_TEXT>/C<END_TEXT>, C<BEGIN_HINT>/C<END_HINT>, or
C<BEGIN_SOLUTION>/C<END_SOLUTION> blocks. The PGML syntax is much easier to read
for other problem authors looking at the code, and PGML helps to ensure that
many text elements (for example images and tables) are inserted correctly for
recent requirements for accessibility.

=cut
