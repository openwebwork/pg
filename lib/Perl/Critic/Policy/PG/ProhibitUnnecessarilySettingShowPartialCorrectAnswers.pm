package Perl::Critic::Policy::PG::ProhibitUnnecessarilySettingShowPartialCorrectAnswers;
use Mojo::Base 'Perl::Critic::Policy', -signatures;

use Perl::Critic::Utils qw(:severities :classification :ppi);

use WeBWorK::PG::Critic::Utils qw(getDeprecatedMacros);

use constant DESCRIPTION => '$showPartialCorrectAnswers is set to 1';
use constant EXPLANATION => 'The value of $showPartialCorrectAnswers is 1 by default, '
	. 'so it should only ever be set to 0 to change the value.';
use constant SCORE => -5;

sub supported_parameters ($) {return}
sub default_severity ($)     { return $SEVERITY_HIGHEST }
sub default_themes ($)       { return qw(pg) }
sub applies_to ($)           { return qw(PPI::Token::Operator) }

sub violates ($self, $element, $) {
	return unless is_assignment_operator($element);
	my $left  = $element->sprevious_sibling;
	my $right = $element->snext_sibling;
	return $self->violation(DESCRIPTION, { score => SCORE, explanation => EXPLANATION }, $left)
		if $left && $left eq '$showPartialCorrectAnswers' && $element eq '=' && $right && $right eq '1';
	return;
}

1;

__END__

=head1 NAME

Perl::Critic::Policy::PG::ProhibitUnnecessarilySettingShowPartialCorrectAnswers
- There is no need to set C<$showPartialCorrectAnswers> to 1 since that is the
default value.

=head1 DESCRIPTION

The value of C<$showPartialCorrectAnswers> is 1 by default, so it should only
ever be set to 0 to change the value.

=cut
