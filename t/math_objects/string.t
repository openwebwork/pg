#!/usr/bin/env perl

=head1 MathObjects - String

Test creation and manipulation of String math objects (used for special values like C<DNE> and C<none>).

=cut

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

loadMacros('MathObjects.pl');

Context('Numeric');

subtest 'Creating a String' => sub {
	my $s1 = String('DNE');
	my $s2 = Compute('DNE');

	for my $s ($s1, $s2) {
		is $s->class, 'String', 'a String has class String';

		ok Value::isValue($s),   'a String is a value';
		ok !Value::isNumber($s), 'a String is not a number';

		ok !$s->isZero, 'a String is never zero';
		ok !$s->isOne,  'a String is never one';
	}
};

subtest 'Comparing Strings' => sub {
	ok String('DNE') == String('DNE'),  'equal Strings compare as equal';
	ok String('DNE') != String('none'), 'different Strings compare as not equal';
	ok String('DNE') != Compute('5'),   'a String never equals a Number';
};

subtest 'quoteHTML escapes HTML special characters' => sub {
	is Value::String->quoteHTML(q{<a>&"}), '&lt;a&gt;&amp;&quot;', 'HTML special characters are escaped';
};

subtest 'quoteXML escapes XML special characters' => sub {
	is Value::String->quoteXML('<tag>&amp;'), '&lt;tag&gt;&amp;amp;', 'XML special characters are escaped';
};

subtest 'quoteTeX wraps plain text and verbatim-quotes special text' => sub {
	is Value::String->quoteTeX('hello, world'), '\text{hello, world}', 'plain text is wrapped in \text{}';
	like Value::String->quoteTeX('50%'), qr/^\{\\verb.*\}$/, 'text with special characters is verbatim-quoted';
};

subtest 'Errors constructing an undefined String constant' => sub {
	like(
		dies { String('banana') },
		qr/String constant 'banana' is not defined in this context/,
		'a String must be one of the constants defined in the context'
	);
};

done_testing();
