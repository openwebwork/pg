package Perl::Critic::Policy::PG::ProhibitContextStrings;
use Mojo::Base 'Perl::Critic::Policy', -signatures;

use Perl::Critic::Utils qw(:severities :classification :ppi);

use WeBWorK::PG::Critic::Utils qw(getDeprecatedMacros);

use constant DESCRIPTION => 'Context()->%s is called';
use constant EXPLANATION => 'Context()->%s no longer necessary and should be removed.';
use constant SCORE       => 5;

sub supported_parameters ($) {return}
sub default_severity ($)     { return $SEVERITY_HIGHEST }
sub default_themes ($)       { return qw(pg) }
sub applies_to ($)           { return qw(PPI::Token::Word) }

sub violates ($self, $element, $) {
	return
		unless ($element eq 'texStrings' || $element eq 'normalStrings')
		&& is_method_call($element)
		&& $element->parent =~ /^Context/;
	return $self->violation(sprintf(DESCRIPTION, $element),
		{ score => SCORE, explanation => sprintf(EXPLANATION, $element) }, $element);
}

1;

__END__

=head1 NAME

Perl::Critic::Policy::PG::RequireContextStrings - C<< Context()->texStrings >>
and C<< Context->normalStrings >> calls are not necessary and should be removed.

=head1 DESCRIPTION

Calling C<< Context()->texStrings >> and C<< Context->normalStrings >> is no
longer necessary and should be removed from problems.

=cut
