package Perl::Critic::Policy::PG::ProhibitMultipleLoadMacrosCalls;
use Mojo::Base 'Perl::Critic::Policy', -signatures;

use Perl::Critic::Utils qw(:severities :classification :ppi);

use constant DESCRIPTION => 'loadMacros is called multiple times';
use constant EXPLANATION => 'Consolidate multiple loadMacros calls into a single call.';
use constant SCORE       => 20;

sub supported_parameters ($) {return}
sub default_severity ($)     { return $SEVERITY_HIGHEST }
sub default_themes ($)       { return qw(pg) }
sub applies_to ($)           { return qw(PPI::Document) }

sub violates ($self, $element, $document) {
	my $tokens = $document->find('PPI::Token');
	return unless $tokens;
	my @loadMacrosCalls = grep { $_ eq 'loadMacros' && is_function_call($_) } @$tokens;
	shift @loadMacrosCalls;
	return map { $self->violation(DESCRIPTION, { score => SCORE, explanation => EXPLANATION }, $_) } @loadMacrosCalls;
}

1;

__END__

=head1 NAME

Perl::Critic::Policy::PG::ProhibitMultipleLoadMacrosCalls - The C<loadMacros>
function should only be called once in each problem.

=head1 DESCRIPTION

The C<loadMacros> function should only be called once in each problem.
Consolidate multiple C<loadMacros> calls into a single call and make sure that
all macros that are loaded are actually used in the problem.

=cut
