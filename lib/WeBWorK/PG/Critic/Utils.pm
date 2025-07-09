
=head1 NAME

WeBWorK::PG::Critic::Utils - Utility methods for PG Critic policies.

=head1 DESCRIPTION

Utility methods for PG Critic policies.

=head1 FUNCTIONS

=head2 getDeprecatedMacros

    my @deprecatedMacros = getDeprecatedMacros();

Returns a list of deprecated macros. These are the macros found in the
C<macros/deprecated> directory.

=head2 parsePGMLBlock

    my $pgmlElements = parsePGMLBlock(@lines);

Parses the given C<@lines> of code from a PGML block and returns a reference to
a hash containing details of the PGML blocks found.

If any C<[@ ... @]> blocks are found in the PGML code, then the return hash will
contain the key C<commands> which will be a reference to an array of
L<PPI::Document> objects representing the Perl code within the C<[@ ... @]>
blocks found.

If the PGML content or a block within fails to parse, then the return hash will
contain the key C<errors> with a reference to an array of errors that occurred.

=head2 parseTextBlock

    my $textElements = parseTextBlock(@lines);

Parses the given C<@lines> of code from a C<BEGIN_TEXT>/C<END_TEXT>,
C<BEGIN_HINT>/C<END_HINT>, or C<BEGIN_SOLUTION>/C<END_SOLUTION> block and
returns a reference to a hash containing details of the elements found.

If any C<\{ ... \}> blocks are found in the code, then the return hash will
contain the key C<commands> which will be a reference to an array of
L<PPI::Document> objects representing the Perl code within the C<\{ ... \}>
blocks found.

If a block within fails to parse, then the return hash will contain the key
C<errors> which is a reference to an array of errors that occurred.

=cut

package WeBWorK::PG::Critic::Utils;
use Mojo::Base 'Exporter', -signatures;

use Mojo::File qw(curfile path);
use PPI;
use Perl::Critic::Utils qw(:classification :ppi);
use Scalar::Util        qw(blessed);
use Mojo::Util          qw(md5_sum encode);
use Env                 qw(PG_ROOT);

use lib curfile->dirname->dirname->dirname->dirname->dirname->child('lib');

require WeBWorK::PG::Translator;

our @EXPORT_OK = qw(getDeprecatedMacros parsePGMLBlock parseTextBlock);

$PG_ROOT = curfile->dirname->dirname->dirname->dirname->dirname;

sub getDeprecatedMacros () {
	state $deprecatedMacros;
	return $deprecatedMacros if $deprecatedMacros;
	return $deprecatedMacros =
		{ map { $_->basename => 1 } @{ path($PG_ROOT)->child('macros', 'deprecated')->list } };
}

sub main::PG_restricted_eval ($code) { return $code; }

sub walkPGMLTree ($block, $results //= {}) {
	for my $item (@{ $block->{stack} }) {
		next unless blessed $item && $item->isa('PGML::Block');
		if ($item->{type} eq 'command') {
			my $command = PPI::Document->new(\($item->{text}));
			if ($command->errstr) {
				push(@{ $results->{errors} }, $command->errstr);
			} else {
				push(@{ $results->{commands} }, $command);
			}
		}
		walkPGMLTree($item, $results);
	}
	return $results;
}

# For now, only command blocks are returned. Add other PGML elements as needed.
sub parsePGMLBlock (@lines) {
	state %processedBlocks;

	my $source = join('', @lines);

	# Cache the results of parsing particular PGML blocks so that if multiple policies
	# use the same PGML block the parsing does not need to be done again.
	my $sourceHash = md5_sum(encode('UTF-8', $source));
	return $processedBlocks{$sourceHash} if defined $processedBlocks{$sourceHash};

	package main;    ## no critic (Modules::ProhibitMultiplePackages)

	require WeBWorK::PG::Environment;
	require WeBWorK::PG;
	require PGcore;
	require Parser;

	$WeBWorK::PG::IO::pg_envir = WeBWorK::PG::Environment->new;
	%main::envir               = %{ WeBWorK::PG::defineProblemEnvironment($WeBWorK::PG::IO::pg_envir) };

	do "$ENV{PG_ROOT}/macros/PG.pl";

	$main::PG = $main::PG = PGcore->new(\%main::envir);
	loadMacros('PGML.pl');

	$PGML::warningsFatal = $PGML::warningsFatal = 1;
	my $parser = eval { PGML::Parse->new($source =~ s/\\\\/\\/gr) };
	return { errors => [$@] } if $@;

	return $processedBlocks{$sourceHash} = WeBWorK::PG::Critic::Utils::walkPGMLTree($parser->{root});
}

# For now, only contents of \{ .. \} blocks are returned. Add other text elements as needed.
sub parseTextBlock (@lines) {
	state %processedBlocks;

	my $source = join('', @lines);

	# Cache the results of parsing particular text blocks so that if multiple policies
	# use the same text block the parsing does not need to be done again.
	my $sourceHash = md5_sum(encode('UTF-8', $source));
	return $processedBlocks{$sourceHash} if defined $processedBlocks{$sourceHash};

	my $results = {};

	while ($source ne '') {
		if ($source =~ /\Q\\{\E/s) {
			$source =~ s/^(.*?)\Q\\{\E//s;
			$source =~ s/^(.*?)\Q\\}\E//s;
			my $command = PPI::Document->new(\($1));
			if ($command->errstr) {
				push(@{ $results->{errors} }, $command->errstr);
			} else {
				push(@{ $results->{commands} }, $command);
			}
		} else {
			last;
		}

	}

	return $processedBlocks{$sourceHash} = $results;
}
1;
