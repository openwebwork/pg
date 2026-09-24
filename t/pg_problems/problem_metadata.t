#!/usr/bin/env perl

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
use lib "$ENV{PG_ROOT}/lib";

use Test2::V0;

use WeBWorK::PG;
use WeBWorK::PG::Metadata qw(parse_metadata);

sub render {
	my $source = shift;
	return WeBWorK::PG->new(r_source => \$source, debuggingOptions => { view_problem_debugging_info => 1 });
}

subtest 'parse_metadata' => sub {
	is(
		parse_metadata(<<~'END_SOURCE'),
			## DESCRIPTION
			## A problem
			## ENDDESCRIPTION
			## DBsubject(WeBWorK)
			# An ordinary comment

			  ##---
			## pgAuthoringVersion: 1
			## macros:
			##   - parserMultiAnswer.pl
			##   - contextFraction.pl
			##---

			$a = 1;
			END_SOURCE
		{ pgAuthoringVersion => 1, macros => [ 'parserMultiAnswer.pl', 'contextFraction.pl' ] },
		'block preceded by comments and blank lines is parsed'
	);

	is(
		parse_metadata("##---\n##pgAuthoringVersion: 1\n##---\n"),
		{ pgAuthoringVersion => 1, macros => [] },
		'macros are optional and the space after ## is optional'
	);

	is(parse_metadata("\$a = 1;\n##---\n## pgAuthoringVersion: 1\n##---\n"),
		undef, 'block after the first line of code is ignored');

	is(
		parse_metadata("##---\n## pgAuthoringversion: 1\n## MACROS:\n##   - a.pl\n##---\n"),
		{ pgAuthoringVersion => 1, macros => ['a.pl'] },
		'keys are case insensitive'
	);

	is(parse_metadata("##---\n## pgAuthorringVersion: 1\n##---\n"),
		undef, 'a misspelled pgAuthoringVersion does not start a block');

	is(parse_metadata("## pgAuthoringVersion: 1\n"), undef, 'metadata outside of a block is ignored');

	is(
		parse_metadata(<<~'END_SOURCE'),
			##---
			## A divider comment
			##---
			## ---
			## macros:
			##   - a.pl
			## ---
			END_SOURCE
		undef,
		'## --- lines that are not immediately followed by the pgAuthoringVersion do not start a block'
	);

	is(
		parse_metadata("##---\n## A divider comment\n##---\n##---\n## pgAuthoringVersion: 1\n##---\n"),
		{ pgAuthoringVersion => 1, macros => [] },
		'block following divider comments is parsed'
	);
	is(parse_metadata(''), undef, 'empty source');

	for (
		[ "##---\n## pgAuthoringVersion: 1\n"           => qr/not terminated/, 'unterminated block' ],
		[ "##---\n## pgAuthoringVersion: 1\n\$a = 1;\n" => qr/not terminated/, 'code inside block' ],
		[ "##---\n## pgAuthoringVersion:\n##---\n"      => qr/Unsupported pgAuthoringVersion: $/m, 'empty version' ],
		[ "##---\n## pgAuthoringVersion: 2\n##---\n"    => qr/Unsupported pgAuthoringVersion: 2/,  'bad version' ],
		[
			"##---\n## pgAuthoringVersion: 1\n## macro:\n##   - a.pl\n##---\n" => qr/Unknown metadata key: macro/,
			'unknown key'
		],
		[
			"##---\n## pgAuthoringVersion: 1\n## macros:\n##   - a.pl\n## Macros:\n##   - b.pl\n##---\n" =>
				qr/The metadata key macros is declared more than once/,
			'key declared more than once with different case'
		],
		[
			"##---\n## pgAuthoringVersion: 1\n## macros: a.pl\n##---\n" => qr/must be a list/,
			'macros not a list'
		],
		[
			"# comment\n##---\n## pgAuthoringVersion: [1\n##---\n" => qr/not valid YAML.*line: 4/s,
			'invalid YAML reports the line in the source'
		],
		)
	{
		like(dies { parse_metadata($_->[0]) }, $_->[1], $_->[2]);
	}
};

subtest 'new style problem' => sub {
	my $pg = render(<<~'END_SOURCE');
		## DBsubject(WeBWorK)
		## ---
		## pgAuthoringVersion: 1
		## macros:
		##   - contextFraction.pl
		## ---

		Context('Fraction');
		$f = Fraction(1, 2);

		BEGIN_PGML
		[_]{$f}
		END_PGML
		END_SOURCE

	is($pg->{errors}, '', 'renders without errors');
	ok(defined &{"$pg->{translator}{safe_compartment_name}::_contextFraction_init"}, 'declared macro is loaded');
	ok(defined &{"$pg->{translator}{safe_compartment_name}::_PGcourse_init"},        'PGcourse.pl is loaded');
	is($pg->{translator}{rh_pgcore}{pgAuthoringVersion}, 1, 'authoring version is recorded');
	$pg->free;
};

subtest 'new style problem errors' => sub {
	my $header = "##---\n## pgAuthoringVersion: 1\n##---\n";
	for (
		[ DOCUMENT    => "${header}DOCUMENT();\n" ],
		[ ENDDOCUMENT => "${header}ENDDOCUMENT();\n" ],
		[ loadMacros  => "${header}loadMacros('contextFraction.pl');\n" ]
		)
	{
		my $pg = render($_->[1]);
		like($pg->{errors}, qr/$_->[0] must not be called/, "calling $_->[0] is an error");
		$pg->free;
	}

	my $pg = render("##---\n## pgAuthoringVersion: 2\n##---\nBEGIN_PGML\nText\nEND_PGML\n");
	like(
		$pg->{errors},
		qr/ERRORS in the PG metadata:\nUnsupported pgAuthoringVersion: 2/,
		'invalid metadata is reported'
	);
	unlike($pg->{errors}, qr/ERRORS from evaluating/, 'problem is not evaluated if the metadata is invalid');
	$pg->free;
};

subtest 'old style problem' => sub {
	my $dividers = render(<<~'END_SOURCE');
		##---
		## DESCRIPTION
		## An old style problem
		## ENDDESCRIPTION
		##---
		DOCUMENT();
		loadMacros('PGstandard.pl', 'PGML.pl');
		BEGIN_PGML
		Old style
		END_PGML
		ENDDOCUMENT();
		END_SOURCE
	is($dividers->{errors}, '', 'renders without errors with ## --- divider comments');
	$dividers->free;

	my $pg = render(<<~'END_SOURCE');
		DOCUMENT();
		##---
		## pgAuthoringVersion: 1
		## macros:
		##   - contextFraction.pl
		##---
		loadMacros('PGstandard.pl', 'PGML.pl');
		BEGIN_PGML
		Old style
		END_PGML
		ENDDOCUMENT();
		END_SOURCE

	is($pg->{errors}, '', 'renders without errors');
	ok(!defined &{"$pg->{translator}{safe_compartment_name}::_contextFraction_init"},
		'metadata after code is ignored');
	$pg->free;
};

done_testing;
