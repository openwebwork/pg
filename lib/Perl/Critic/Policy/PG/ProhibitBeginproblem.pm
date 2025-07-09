package Perl::Critic::Policy::PG::ProhibitBeginproblem;
use Mojo::Base 'Perl::Critic::Policy', -signatures;

use Perl::Critic::Utils qw(:severities :classification :ppi);

use WeBWorK::PG::Critic::Utils qw(getDeprecatedMacros);

use constant DESCRIPTION => 'The beingproblem function is called';
use constant EXPLANATION => 'The beingproblem function no longer does anything and should be removed.';
use constant SCORE       => -5;

sub supported_parameters ($) {return}
sub default_severity ($)     { return $SEVERITY_HIGHEST }
sub default_themes ($)       { return qw(pg) }
sub applies_to ($)           { return qw(PPI::Token::Word) }

sub violates ($self, $element, $) {
	return unless $element eq 'beginproblem' && is_function_call($element);
	return $self->violation(DESCRIPTION, { score => SCORE, explanation => EXPLANATION }, $element);
}

1;

__END__

=head1 NAME

Perl::Critic::Policy::PG::ProhibitBeginproblem - The C<beingproblem> function is
deprecated, no longer does anything, and should be removed from all problems.

=head1 DESCRIPTION

The C<beingproblem> function is deprecated, no longer does anything, and should
be removed from all problems.

=cut
