package Perl::Critic::Policy::PG::ProhibitEnddocumentMatter;
use Mojo::Base 'Perl::Critic::Policy', -signatures;

use Perl::Critic::Utils qw(:severities :classification :ppi);

use constant DESCRIPTION => 'There is content after the ENDDOCUMENT call';
use constant EXPLANATION => 'Remove this content. The ENDDOCUMENT call should be at the end of the problem.';
use constant SCORE       => -5;

sub supported_parameters ($) {return}
sub default_severity ($)     { return $SEVERITY_HIGHEST }
sub default_themes ($)       { return qw(pg) }
sub applies_to ($)           { return qw(PPI::Token::Word) }

sub default_maximum_violations_per_document ($) { return 1; }

sub violates ($self, $element, $document) {
	return $self->violation(DESCRIPTION, { score => SCORE, explanation => EXPLANATION }, $element)
		if $element eq 'ENDDOCUMENT'
		&& is_function_call($element)
		&& ($document->{_doc}{untranslatedCode} // '') =~ /ENDDOCUMENT[^\n]*\n(.*)/s
		&& $1 =~ /\S/;
	return;
}

1;

__END__

=head1 NAME

Perl::Critic::Policy::PG::ProhibitEnddocumentMatter - There should not be any
content after the C<ENDDOCUMENT> call in a problem.

=head1 DESCRIPTION

The C<ENDDOCUMENT> call is intended to signify the end of the problem code.
Although all content after the C<ENDOCUMENT> call is ignored, there should not
be any content (text or code) in this area.

=cut
