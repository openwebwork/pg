package Perl::Critic::Policy::PG::ProhibitDeprecatedMacros;
use Mojo::Base 'Perl::Critic::Policy', -signatures;

use Perl::Critic::Utils qw(:severities :classification :ppi);

use WeBWorK::PG::Critic::Utils qw(getDeprecatedMacros);

use constant DESCRIPTION => 'The deprecated macro %s is loaded';
use constant EXPLANATION => 'Remove this macro and replace methods used from this macro with modern alternatives.';
use constant SCORE       => -10;

sub supported_parameters ($) {return}
sub default_severity ($)     { return $SEVERITY_HIGHEST }
sub default_themes ($)       { return qw(pg) }
sub applies_to ($)           { return qw(PPI::Token::Word) }

sub violates ($self, $element, $) {
	return unless $element eq 'loadMacros' && is_function_call($element);
	my $deprecatedMacros = getDeprecatedMacros;
	return unless $deprecatedMacros;
	return map {
		$self->violation(
			sprintf(DESCRIPTION, $_->[0]->string),
			{ score => SCORE, explanation => EXPLANATION },
			$_->[0]
		)
		}
		grep { $deprecatedMacros->{ $_->[0]->string } } parse_arg_list($element);
}

1;

__END__

=head1 NAME

Perl::Critic::Policy::PG::ProhibitDeprecatedMacros - Replace deprecated macro
usage with modern alternatives.

=head1 DESCRIPTION

All problems that use a deprecated macro (those in the C<deprecated> directory)
should be rewritten to use modern alternatives.

=cut
