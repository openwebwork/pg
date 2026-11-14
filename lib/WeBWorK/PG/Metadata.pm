package WeBWorK::PG::Metadata;
use parent qw(Exporter);

use strict;
use warnings;
use feature 'signatures';
no warnings qw(experimental::signatures);

use Encode qw(encode);
use YAML::XS;

our @EXPORT_OK = qw(parse_metadata);

=head1 NAME

WeBWorK::PG::Metadata - Parse the metadata block of a PG problem.

=head1 SYNOPSIS

    use WeBWorK::PG::Metadata qw(parse_metadata);

    my $metadata = eval { parse_metadata($source) };
    die "Invalid PG metadata: $@" if $@;

=head1 DESCRIPTION

The metadata block of a PG problem is a YAML document written in Perl comments
and delimited by lines consisting of C<## --->.  The first line of the block
must declare the C<pgAuthoringVersion>.  For example,

    ## DESCRIPTION
    ## A problem
    ## ENDDESCRIPTION
    ## DBsubject(WeBWorK)

    ## ---
    ## pgAuthoringVersion: 1
    ## macros:
    ##   - parserMultiAnswer.pl
    ##   - contextFraction.pl
    ## ---

    Context('Fraction');
    ...

The block may be preceded by any number of comment lines (such as OPL tags) and
lines consisting entirely of whitespace, but must occur before the first line of
code.  Any C<## ---> line after the first line of code is ignored, so text
within the problem (for example in a PGML block) can never be interpreted as
metadata.

The leading C<##> and at most one following space or tab are removed from each
line in the block, and the remaining text is parsed as YAML.

The presence of the block indicates that the problem is a new style problem.
Such problems should not call C<DOCUMENT>, C<ENDDOCUMENT>, or C<loadMacros>.
The C<DOCUMENT> and C<ENDDOCUMENT> calls are added by the translator, and the
C<DOCUMENT> call loads C<PGbasicmacros.pl>, C<PGauxiliaryFunctions.pl>,
C<PGML.pl>, the macros declared in the metadata, and finally C<PGcourse.pl>.

Problems that do not have the block are evaluated exactly as they always have
been, and must call C<DOCUMENT>, C<ENDDOCUMENT>, and C<loadMacros> themselves.

The following keys are recognized in the block.  Keys are case insensitive (so
C<pgauthoringversion> is the same as C<pgAuthoringVersion>), but otherwise any
other key is an error.

=over

=item pgAuthoringVersion

The version of the PG authoring expectations that the problem is written for.
This is required, and currently must be 1.

=item macros

A list of the macro files used by the problem.  This is optional.

=back

=head1 FUNCTIONS

=head2 parse_metadata

    my $metadata = parse_metadata($source);

Parse the metadata block from the problem source.  If the source does not have a
metadata block, then this returns undefined.  Otherwise the returned hash
reference has the keys C<pgAuthoringVersion> and C<macros>.  This dies with a
message describing the problem if the block is not terminated, is not valid
YAML, or does not conform to the requirements above.

=cut

my @supportedVersions = (1);
my %knownKeys         = map { lc($_) => $_ } qw(pgAuthoringVersion macros);

sub parse_metadata($source) {
	$source //= '';

	my @lines = split(/\r?\n/, $source);

	my $blockStart;
	for (0 .. $#lines - 1) {
		last unless $lines[$_] =~ /^\h*(#.*)?$/;
		if ($lines[$_] =~ /^\h*##\h*---\h*$/ && $lines[ $_ + 1 ] =~ /^\h*##\h*pgAuthoringVersion\h*:/i) {
			$blockStart = $_;
			last;
		}
	}

	return unless defined $blockStart;

	my (@yaml, $terminated);
	for my $line (@lines[ $blockStart + 1 .. $#lines ]) {
		if ($line =~ /^\h*##\h*---\h*$/) {
			$terminated = 1;
			last;
		}
		last unless $line =~ /^\h*##\h?(.*)$/;
		push(@yaml, $1);
	}
	die "The metadata block that starts on line @{[ $blockStart + 1 ]} is not terminated with a ## --- line.\n"
		unless $terminated;

	my $data = eval {
		local $YAML::XS::LoadBlessed = 0;
		local $YAML::XS::LoadCode    = 0;
		YAML::XS::Load(encode('UTF-8', join("\n", @yaml, '')));
	};
	# Make the line numbers in the YAML error message relative to the problem source.
	die 'The metadata block is not valid YAML: ' . ($@ =~ s/line: (\d+)/'line: ' . ($1 + $blockStart + 1)/ger)
		if $@;

	my @unknownKeys = grep { !$knownKeys{ lc($_) } } keys %$data;
	die 'Unknown metadata key' . (@unknownKeys > 1 ? 's' : '') . ': ' . join(', ', @unknownKeys) . "\n"
		if @unknownKeys;

	# Keys are case insensitive, so convert them to their canonical form.
	my %canonical;
	for (keys %$data) {
		my $key = $knownKeys{ lc($_) };
		die "The metadata key $key is declared more than once.\n" if exists $canonical{$key};
		$canonical{$key} = $data->{$_};
	}
	$data = \%canonical;

	my $version = $data->{pgAuthoringVersion};
	die 'Unsupported pgAuthoringVersion: ' . ($version // '') . "\n"
		if !defined $version || ref $version || !(grep { $version eq $_ } @supportedVersions);

	my $macros = $data->{macros} // [];
	die "The macros in the metadata block must be a list of macro file names.\n"
		unless ref $macros eq 'ARRAY' && !grep { !defined $_ || ref $_ || $_ eq '' } @$macros;

	return { pgAuthoringVersion => $version, macros => [@$macros] };
}

1;
