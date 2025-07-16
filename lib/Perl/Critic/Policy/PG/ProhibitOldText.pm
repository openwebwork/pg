package Perl::Critic::Policy::PG::ProhibitOldText;
use Mojo::Base 'Perl::Critic::Policy', -signatures;

use Perl::Critic::Utils qw(:severities :classification :ppi);

use constant DESCRIPTION => 'A BEGIN_%1$s/END_%1$s block is used for problem text';
use constant EXPLANATION => 'Load the macro PGML.pl and replace the BEGIN_%1$s/END_%1$s '
	. 'block with a BEGIN_PGML%2$s/END_PGML%2$s block.';
use constant SCORE => 20;

sub supported_parameters ($) {return}
sub default_severity ($)     { return $SEVERITY_HIGHEST }
sub default_themes ($)       { return qw(pg) }
sub applies_to ($)           { return qw(PPI::Token::HereDoc) }

sub violates ($self, $element, $document) {
	if ($element->terminator =~ /^END_(TEXT|SOLUTION|HINT)?$/
		&& $element->parent
		&& $element->parent->parent
		&& $element->parent->parent->parent
		&& $element->parent->parent->parent->first_element eq 'EV3P'
		&& is_function_call($element->parent->parent->parent->first_element)
		&& $element->parent->parent->parent->parent
		&& $element->parent->parent->parent->parent->parent
		&& $element->parent->parent->parent->parent->parent->first_element =~ /^(STATEMENT|HINT|SOLUTION)$/
		&& is_function_call($element->parent->parent->parent->parent->parent->first_element))
	{
		my $oldType = $1 eq 'STATEMENT' ? 'TEXT' : $1;
		return $self->violation(
			sprintf(DESCRIPTION, $oldType),
			{ score => SCORE, explanation => sprintf(EXPLANATION, $oldType, $1 eq 'STATEMENT' ? '' : "_$1") },
			$element->parent->parent->parent->parent->parent
		);
	}
	return;
}

1;

__END__

=head1 NAME

Perl::Critic::Policy::PG::ProhibitOldText - Replace old PG text usage with PGML.

=head1 DESCRIPTION

Load the C<PGML.pl> macro and replace all C<BEGIN_TEXT>/C<END_TEXT>,
C<BEGIN_HINT>/C<END_HINT>, and C<BEGIN_SOLUTION>/C<END_SOLUTION> blocks with
C<BEGIN_PGML>/C<END_PGML>, C<BEGIN_PGML_HINT>/C<END_PGML_HINT>, and
C<BEGIN_PGML_SOLUTION>/C<END_PGML_SOLUTION> blocks.

=cut
