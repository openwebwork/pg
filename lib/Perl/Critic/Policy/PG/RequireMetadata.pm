package Perl::Critic::Policy::PG::RequireMetadata;
use Mojo::Base 'Perl::Critic::Policy', -signatures;

use Perl::Critic::Utils qw(:severities :classification :ppi);

use constant DESCRIPTION       => 'The %s metadata tag is required';
use constant EXPLANATION       => 'Include the required metadata tags at the beginning of the problem file.';
use constant SCORE             => 5;
use constant REQUIRED_METADATA => [ 'DBsubject', 'DBchapter', 'DBsection', 'KEYWORDS' ];

sub supported_parameters ($) {return}
sub default_severity ($)     { return $SEVERITY_HIGHEST }
sub default_themes ($)       { return qw(pg) }
sub applies_to ($)           { return qw(PPI::Document) }

sub violates ($self, $element, $document) {
	my $comments = $document->find('PPI::Token::Comment');
	my %foundMetadata;
	if ($comments) {
		for my $comment (@$comments) {
			my ($metadataType) = grep { $comment =~ /#\s*$_\(/i } @{ REQUIRED_METADATA() };
			$foundMetadata{$metadataType} = 1 if $metadataType;
		}
	}

	my @violations;
	for (@{ REQUIRED_METADATA() }) {
		push(@violations,
			$self->violation(sprintf(DESCRIPTION, $_), { score => SCORE, explanation => EXPLANATION }, $document))
			unless $foundMetadata{$_};
	}
	return @violations;
}

1;

__END__

=head1 NAME

Perl::Critic::Policy::PG::RequireMetadata - All problems should have the
appropriate OPL metadata tags set.

=head1 DESCRIPTION

All problems should have the appropriate OPL metadata tags set. The required
metadata attributes should be set at the beginning of the problem file before
the C<DOCUMENT> call.  The metadata tags that are required for all problems are
C<DBsubject>, C<DBchapter>, C<DBsection>, and C<KEYWORDS>.

=cut
