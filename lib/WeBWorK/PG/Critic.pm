
=head1 NAME

WeBWorK::PG::Critic - Critique PG problem source code for best-practices.

=head1 DESCRIPTION

Analyze a pg file for use of old and current methods.

=head1 FUNCTIONS

=head2 critiquePGCode

    my $results = critiquePGCode($code, $force = 0);

Parses and critiques the given PG problem source provided in C<$code>. An array
of "violations" that are found is returned.  Note that the elements of this
return array are L<Perl::Critic::Violation> objects.  However, not all of these
"violations" are bad.  Some are actually noting good things that are used in the
source code for the problem. The C<explanation> method can be called for each
element, and that will either return a string or a reference to a hash.  The
string return type will occur for a violation of a default L<Perl::Critic::Policy>
policy.  The last return type will occur with a C<Perl::Critic::Policy::PG>
policy, and the hash will contain a C<score> key and an C<explanation> key
containing the actual explanation.  If the C<score> is positive, then it is not
actually a violation, but something good. In some cases the C<explanation>
return hash will also contain the key C<sampleProblems> which will be a
reference to an array each of whose entries will be a reference to a two element
array whose first element is the title of a sample problem and whose second
element is the path for that sample problem where the sample problem
demonstrates a way to fix the policy violation.

Note that C<## no critic> annotations can be used in the code to disable a
violation for a line or the entire file.  See L<"BENDING THE
RULES"|https://metacpan.org/pod/Perl::Critic#BENDING-THE-RULES>.  However, if
C<$force> is true, then C<## no critic> annotations are ignored, and all
policies are enforced regardless.

=head2 critiquePGFile

    my $results = critiquePGFile($file, $force);

This just executes C<critiquePGCode> on the contents of C<$file> and returns
the result.
=cut

package WeBWorK::PG::Critic;
use Mojo::Base 'Exporter', -signatures;

use Mojo::File qw(path);
use PPI;
use Perl::Critic;

our @EXPORT_OK = qw(critiquePGFile critiquePGCode);

sub critiquePGCode ($code, $force = 0) {
	my $critic = Perl::Critic->new(
		-severity => 4,
		-exclude  => [
			'Perl::Critic::Policy::Modules::ProhibitMultiplePackages',
			'Perl::Critic::Policy::Modules::RequireEndWithOne',
			'Perl::Critic::Policy::Modules::RequireExplicitPackage',
			'Perl::Critic::Policy::Modules::RequireFilenameMatchesPackage',
			'Perl::Critic::Policy::Subroutines::ProhibitBuiltinHomonyms',
			'Perl::Critic::Policy::Subroutines::RequireArgUnpacking',
			'Perl::Critic::Policy::TestingAndDebugging::RequireUseStrict',
			'Perl::Critic::Policy::TestingAndDebugging::RequireUseWarnings',
			'Perl::Critic::Policy::Variables::RequireLocalizedPunctuationVars',

			# Make sure that Community and Freenode policies are not used if installed on the system.
			'.*::Community::.*', '.*::Freenode::.*'
		],
		-force => $force
	);

	my $translatedCode = WeBWorK::PG::Translator::default_preprocess_code($code);

	my $document = PPI::Document->new(\$translatedCode);

	# Provide the untranslated code so that policies can access it. It will be in the _doc key of the $document that is
	# passed as the third argument to the violates method. See Perl::Critic::Policy::PG::ProhibitEnddocumentMatter which
	# uses this for example.
	$document->{untranslatedCode} = $code;

	return $critic->critique($document);
}

sub critiquePGFile ($file, $force = 0) {
	my $code = eval { path($file)->slurp('UTF-8') };
	die qq{Unable to read contents of "$file": $@} if $@;
	return critiquePGCode($code, $force);
}

1;
