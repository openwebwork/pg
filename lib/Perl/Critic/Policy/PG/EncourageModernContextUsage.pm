package Perl::Critic::Policy::PG::EncourageModernContextUsage;
use Mojo::Base 'Perl::Critic::Policy', -signatures;

# FIXME: Is this policy really a good idea? Why are these contexts so special? Just because they are newer? Many of the
# contexts that have been around for a long time are actually better than some of these, and some of them are more
# complicated to use and demonstrate a higher level of sophistication than these.

use Perl::Critic::Utils qw(:severities :classification :ppi);

use constant DESCRIPTION => 'The context %s is used from the macro %s';
use constant EXPLANATION => '%s is a modern context whose usage demonstrates currency in problem authoring.';

use constant CONTEXTS => {
	BaseN    => { macro => 'contextBaseN.pl',    score => 10 },
	Boolean  => { macro => 'contextBoolean.pl',  score => 10 },
	Reaction => { macro => 'contextReaction.pl', score => 10 },
	Units    => { macro => 'contextUnits.pl',    score => 10 }
};

sub supported_parameters ($) {return}
sub default_severity ($)     { return $SEVERITY_HIGHEST }
sub default_themes ($)       { return qw(pg) }
sub applies_to ($)           { return qw(PPI::Token::Word) }

sub violates ($self, $element, $document) {
	return unless $element eq 'Context' && is_function_call($element);
	my $context = first_arg($element);
	return $self->violation(
		sprintf(DESCRIPTION, $context->string, CONTEXTS->{ $context->string }{macro}),
		{
			score       => CONTEXTS->{ $context->string }{score},
			explanation => sprintf(EXPLANATION, CONTEXTS->{ $context->string }{macro})
		},
		$context
	) if $context && CONTEXTS->{ $context->string };
	return;
}

1;

__END__

=head1 NAME

Perl::Critic::Policy::PG::EncourageModernContextUsage - Usage of recently
created contexts demonstrates currency in problem authoring.

=head1 DESCRIPTION

Usage of recently created contexts demonstrates currency in problem authoring.
Currently this policy encourages the use of the following contexts:

=over

=item * L<contextBaseN.pl>

=item * L<contextBoolean.pl>

=item * L<contextReaction.pl>

=item * L<contextUnits.pl>

=back

=cut
