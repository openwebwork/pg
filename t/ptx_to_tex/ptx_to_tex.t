#!/usr/bin/env perl

use Test2::V0;

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};

use lib "$ENV{PG_ROOT}/lib";

use WeBWorK::PG::PTXToTeX qw(ptx_to_tex);

subtest 'Paragraphs and text' => sub {
	is ptx_to_tex('<p>One.</p><p>Two.</p>'), "One.\n\nTwo.", 'paragraphs are separated by a blank line';
	is ptx_to_tex('<p>50% of $3 &amp; #1 a_b {c}</p>'), '50\% of \$3 \& \#1 a\_b \{c\}',
		'characters that are special to LaTeX are escaped';
	is ptx_to_tex('<p>a \ b ~ c ^ d &lt; e &gt; f</p>'),
		'a \textbackslash{} b \textasciitilde{} c \textasciicircum{} d \textless{} e \textgreater{} f',
		'characters that need a command are converted';
	is ptx_to_tex("<p>a\x{A0}b</p>"), 'a b', 'a non-breaking space becomes a space';
};

subtest 'Mathematics' => sub {
	is ptx_to_tex('<p>Let <m>x_1 = \frac{1}{2}</m>.</p>'), 'Let \(x_1 = \frac{1}{2}\).',
		'inline mathematics is not escaped';
	is ptx_to_tex('<me>x^2 \lt y \amp z \gt 1</me>'), '\[x^2 < y & z > 1\]',
		'displayed mathematics and the PreTeXt macros for characters';
	is ptx_to_tex('<p><m>a &lt; b &amp; c</m></p>'), '\(a < b & c\)', 'entities in mathematics are decoded';
};

subtest 'Answer blanks' => sub {
	is ptx_to_tex('<p>x = <fillin name="AnSwEr0001" characters="12" /></p>'), 'x = {\answerRule[AnSwEr0001]{12}}',
		'a blank with a name and a width';
	is ptx_to_tex('<fillin characters="1"/>'), '{\answerRule[]{3}}', 'a blank with no name has a minimum width';
	is ptx_to_tex('<fillin name="a_b" characters="5"></fillin>'), '{\answerRule[a_b]{5}}',
		'a blank with a closing tag, and a name that is not escaped';
};

subtest 'Lists' => sub {
	is ptx_to_tex('<ul><li>a</li><li>b</li></ul>'), "\\begin{itemize}\n\\item a\\item b\n\\end{itemize}",
		'an unordered list';
	is ptx_to_tex('<ol><li>a</li><li>b</li></ol>'), "\\begin{itemize}\n\\item[1.] a\\item[2.] b\n\\end{itemize}",
		'an ordered list is numbered';
	is ptx_to_tex('<ol marker="A."><li>a</li><li>b</li><li>c</li></ol>'),
		"\\begin{itemize}\n\\item[A.] a\\item[B.] b\\item[C.] c\n\\end{itemize}",
		'an ordered list with upper case letters';
	is ptx_to_tex('<ol marker="(a)"><li>x</li><li>y</li></ol>'),
		"\\begin{itemize}\n\\item[(a)] x\\item[(b)] y\n\\end{itemize}",
		'an ordered list with lower case letters in parentheses';
	is ptx_to_tex('<ol><li>a<ul><li>b</li></ul></li><li>c</li></ol>'),
		"\\begin{itemize}\n\\item[1.] a\n\\begin{itemize}\n\\item b\n\\end{itemize}\n\\item[2.] c\n\\end{itemize}",
		'a list in a list keeps its own count';
};

subtest 'Tables' => sub {
	is ptx_to_tex(
		'<tabular><row><cell>a</cell><cell>b</cell></row><row><cell>c</cell><cell>d</cell></row></tabular>'),
		"\\begin{center}\n\\begin{tabular}{|c|c|}\n\\hline\na & b \\\\ \\hline\nc & d \\\\ \\hline\n"
		. "\\end{tabular}\n\\end{center}",
		'a table with two rows and two columns';
	like ptx_to_tex(
		'<tabular><row><cell>a</cell></row><row><cell>b</cell><cell>c</cell><cell>d</cell></row></tabular>'),
		qr/\\begin\{tabular\}\{\|c\|c\|c\|\}/, 'the number of columns is that of the longest row';
	unlike ptx_to_tex("<tabular>\n\n<row>\n<cell>a</cell>\n\n<cell>b</cell>\n</row>\n\n</tabular>"), qr/\n\s*\n/,
		'there are no blank lines in a table';
};

subtest 'Other elements' => sub {
	is ptx_to_tex('<p><em>a</em> <alert>b</alert> <c>c</c> <u>d</u></p>'),
		'\emph{a} \textbf{b} \texttt{c} \underline{d}', 'emphasis, bold, verbatim, and underlined text';
	is ptx_to_tex('<p>x<sup>2</sup> and y<sub>1</sub></p>'), 'x\textsuperscript{2} and y\textsubscript{1}',
		'superscripts and subscripts';
	is ptx_to_tex('<p><q>a</q></p>'), q{``a''},        'a quotation';
	is ptx_to_tex('<p>a<br/>b</p>'),  "a\\newline\nb", 'a line break';
	is ptx_to_tex('<p>5<percent/> <ndash/> <lbrace/>x<rbrace/> <ellipsis/> 2<asterisk/>3</p>'),
		'5\% -- \{x\} \ldots{} 2*3',
		'elements for characters';
	is ptx_to_tex('<image source="a.png" />'), '[An image that is not shown here.]', 'an image is not shown';
	is ptx_to_tex('<p>See <url href="https://example.com">this page</url> and <unknown>that</unknown>.</p>'),
		'See this page and that.', 'the text of an element that is not converted is kept';
};

done_testing;
