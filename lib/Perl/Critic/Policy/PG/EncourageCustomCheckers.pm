package Perl::Critic::Policy::PG::EncourageCustomCheckers;
use Mojo::Base 'Perl::Critic::Policy', -signatures;

use Perl::Critic::Utils qw(:severities :classification :ppi);

use constant DESCRIPTION => 'A custom checker is utilized';
use constant EXPLANATION => 'Custom checkers demonstrate a high level of sophistication in problem coding.';
use constant SCORE       => 50;

sub supported_parameters ($) {return}
sub default_severity ($)     { return $SEVERITY_HIGHEST }
sub default_themes ($)       { return qw(pg) }
sub applies_to ($)           { return qw(PPI::Token::Word) }

use Mojo::Util qw(dumper);

# FIXME: This misses some important cases.  For example, answer checking can also be performed in a post filter.  In
# fact that demonstrates an even higher level of sophistication than using a checker in some senses.  It is more
# complicated to use correctly, and can work around type limitations imposed on MathObject checkers.  However, there is
# no reliable way to determine what a post filter is in a problem for, as there are other reasons to add a post filter.
sub violates ($self, $element, $document) {
	return unless $element eq 'checker' || $element eq 'list_checker';
	return $self->violation(DESCRIPTION, { score => SCORE, explanation => EXPLANATION }, $element);
}

1;

__END__

=head1 NAME

Perl::Critic::Policy::PG::EncourageCustomCheckers - Custom checkers demonstrate
a high level of sophistication in problem coding.

=head1 DESCRIPTION

Utilization of a custom checker in a problem demonstrates a high level of
sophistication in coding a problem. Custom checkers can be used to supplement
default MathObject checkers in several ways. For example, to award partial
credit and display more meaningful messages for answers that are not entirely
correct

=cut
