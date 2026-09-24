#!/usr/bin/env perl

=head1 niceTables

Test niceTables.pl

=cut

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

use lib "$ENV{PG_ROOT}/lib";

loadMacros('niceTables.pl');

my $tab           = DataTable([ [ 1, 2, 3 ], [ 4, 5, 6 ] ]);
my $std_pad       = 'padding:0rem 0.425rem;';
my $talign_center = 'text-align:center;';

is $tab, qq{<table style="margin:auto;">
<tbody style="vertical-align:top;">
<tr>
<td style="$std_pad$talign_center">
1
</td>
<td style="$std_pad$talign_center">
2
</td>
<td style="$std_pad$talign_center">
3
</td>
</tr>
<tr>
<td style="$std_pad$talign_center">
4
</td>
<td style="$std_pad$talign_center">
5
</td>
<td style="$std_pad$talign_center">
6
</td>
</tr>
</tbody>
</table>}, 'test for a basic table with no options';

my $non_centered_tab = DataTable([ [ 1, 2, 3 ], [ 4, 5, 6 ] ], center => 0);

is $non_centered_tab, qq{<table>
<tbody style="vertical-align:top;">
<tr>
<td style="$std_pad$talign_center">
1
</td>
<td style="$std_pad$talign_center">
2
</td>
<td style="$std_pad$talign_center">
3
</td>
</tr>
<tr>
<td style="$std_pad$talign_center">
4
</td>
<td style="$std_pad$talign_center">
5
</td>
<td style="$std_pad$talign_center">
6
</td>
</tr>
</tbody>
</table>}, 'test for a basic table that is not centered';

my $tab_with_caption = DataTable([ [ 1, 2, 3 ], [ 4, 5, 6 ] ], caption => 'This is the caption');

is $tab_with_caption, qq{<table style="margin:auto;">
<caption>
This is the caption
</caption>
<tbody style="vertical-align:top;">
<tr>
<td style="$std_pad$talign_center">
1
</td>
<td style="$std_pad$talign_center">
2
</td>
<td style="$std_pad$talign_center">
3
</td>
</tr>
<tr>
<td style="$std_pad$talign_center">
4
</td>
<td style="$std_pad$talign_center">
5
</td>
<td style="$std_pad$talign_center">
6
</td>
</tr>
</tbody>
</table>}, 'test for a basic table with caption';

my $tab_with_hor_rules = DataTable([ [ 1, 2, 3 ], [ 4, 5, 6 ] ], horizontalrules => 1);

is $tab_with_hor_rules, qq{<table style="margin:auto;">
<tbody style="vertical-align:top;">
<tr style="border-top:solid 3px;border-bottom:solid 1px;">
<td style="$std_pad$talign_center">
1
</td>
<td style="$std_pad$talign_center">
2
</td>
<td style="$std_pad$talign_center">
3
</td>
</tr>
<tr style="border-bottom:solid 3px;">
<td style="$std_pad$talign_center">
4
</td>
<td style="$std_pad$talign_center">
5
</td>
<td style="$std_pad$talign_center">
6
</td>
</tr>
</tbody>
</table>}, 'test for a basic table with horizontal rules';

my $tex_start = "{\\par\\setlength{\\tabcolsep}{5pt}\\renewcommand{\\arraystretch}{1}\\centering%\n";
my $tex_end   = '\par}';

sub tex_table {
	my @args = @_;
	local $main::displayMode = 'TeX';
	return DataTable(@args);
}

sub tex_layout_table {
	my @args = @_;
	local $main::displayMode = 'TeX';
	return LayoutTable(@args);
}

subtest 'Caption' => sub {
	my @args = ([ [ 'a' .. 'd' ], [ 1 .. 4 ] ], caption => 'This is a caption.', captioncss => { color => 'blue' });

	like DataTable(@args),
		qr{^<table style="margin:auto;">\n<caption style="color:blue;">\nThis is a caption.\n</caption>\n},
		'HTML caption with css';
	is tex_table(@args),
		$tex_start
		. '\begin{tabular}[t]{cccc} a & b & c & d \\\\ 1 & 2 & 3 & 4 \end{tabular} '
		. '\captionsetup{textfont={sc},belowskip=12pt,aboveskip=4pt}\captionof*{table}{This is a caption.}'
		. $tex_end,
		'TeX caption';
};

subtest 'Horizontal rules' => sub {
	my $html = DataTable([ [ ['a'], 'b' ], [ 1, 2 ], [ 'A', 'B' ] ], horizontalrules => 1);
	like $html, qr{<tr style="border-top:solid 3px;border-bottom:solid 1px;">\n<td[^>]*>\na\n},
		'HTML first row rules';
	like $html, qr{<tr style="border-bottom:solid 1px;">\n<td[^>]*>\n1\n}, 'HTML middle row rule';
	like $html, qr{<tr style="border-bottom:solid 3px;">\n<td[^>]*>\nA\n}, 'HTML last row rule';

	is tex_table([ [ ['a'], 'b' ], [ 1, 2 ], [ 'A', 'B' ] ], horizontalrules => 1),
		$tex_start
		. '\begin{tabular}[t]{cc} \toprule{} a & b \\\\ \midrule{} 1 & 2 \\\\ \midrule{} A & B \\\\\bottomrule '
		. '\end{tabular}'
		. $tex_end,
		'TeX horizontal rules with booktabs';

	is tex_table([ [ [ 'a', top => 1 ], 'b' ], [ 1, 2 ], [ 'A', 'B' ] ], horizontalrules => 1, booktabs => 0),
		$tex_start
		. '\begin{tabular}[t]{cc} \cline{1-1} \hline a & b \\\\ \hline 1 & 2 \\\\ \hline A & B \\\\\hline '
		. '\end{tabular}'
		. $tex_end,
		'TeX horizontal rules without booktabs';
};

subtest 'Column alignment' => sub {
	my $html = DataTable([ [ 'a' .. 'd' ] ], texalignment => 'lcrc');
	like $html, qr{<td style="\Q$std_pad\Etext-align:left;">\na\n},   'HTML left aligned column';
	like $html, qr{<td style="\Q$std_pad\Etext-align:center;">\nb\n}, 'HTML center aligned column';
	like $html, qr{<td style="\Q$std_pad\Etext-align:right;">\nc\n},  'HTML right aligned column';
	is tex_table([ [ 'a' .. 'd' ] ], texalignment => 'lcrc'),
		"$tex_start\\begin{tabular}[t]{lcrc} a & b & c & d \\end{tabular}$tex_end", 'TeX column alignment';

	my @args = ([ [ 'Lorem ipsum', 'b', 'Lorem ipsum', 'd' ] ], texalignment => 'p{1.5in}lXc', Xratio => '0.8');
	$html = DataTable(@args);
	like $html, qr{^<table style="width:80%;margin:auto;">}, 'HTML table width from Xratio';
	like $html, qr{<colgroup>\n<col style="width:1.5in;">\n<col>\n<col>\n<col>\n</colgroup>},
		'HTML paragraph column width';
	like $html, qr{<td style="\Q$std_pad\Etext-align:left;width:1.5in;">\nLorem ipsum\n},
		'HTML paragraph column cell';
	like $html, qr{<td style="\Q$std_pad\E">\nLorem ipsum\n}, 'HTML X column cell';
	is tex_table(@args),
		"$tex_start\\begin{tabularx}{0.8\\linewidth}[t]{p{1.5in}lXc} Lorem ipsum & b & Lorem ipsum & d "
		. "\\end{tabularx}$tex_end",
		'TeX paragraph and X columns';
};

subtest 'Vertical rules' => sub {
	my $html = DataTable([ [ 'a' .. 'd' ] ], texalignment => '|c||c|||c||||c|||||');
	like $html, qr{^<table style="border-left:solid 1px;margin:auto;">}, 'HTML left border from pipes';
	like $html, qr{<colgroup>\n<col\ style="border-right:solid\ 2px;">\n<col\ style="border-right:solid\ 3px;">\n
		<col\ style="border-right:solid\ 4px;">\n<col\ style="border-right:solid\ 5px;">\n</colgroup>}x,
		'HTML column borders from pipes';
	is tex_table([ [ 'a' .. 'd' ] ], texalignment => '|c||c|||c||||c|||||'),
		"$tex_start\\begin{tabular}[t]{|c||c|||c||||c|||||} a & b & c & d \\end{tabular}$tex_end", 'TeX pipes';

	my $alignment = join('', map {"!{\\vrule width 0.${_}em}c"} qw(04 07 11 15)) . '!{\vrule width 0.20em}';
	$html = DataTable([ [ 'a' .. 'd' ] ], texalignment => $alignment);
	like $html, qr{^<table style="border-left:solid 0.04em;margin:auto;">}, 'HTML left border from vrule';
	like $html,
		qr{<colgroup>\n<col\ style="border-right:solid\ 0.07em;">\n<col\ style="border-right:solid\ 0.11em;">\n
		<col\ style="border-right:solid\ 0.15em;">\n<col\ style="border-right:solid\ 0.20em;">\n</colgroup>}x,
		'HTML column borders from vrule';
	is tex_table([ [ 'a' .. 'd' ] ], texalignment => $alignment),
		"$tex_start\\begin{tabular}[t]{$alignment} a & b & c & d \\end{tabular}$tex_end", 'TeX explicit vrule width';
};

subtest 'Column fonts and colors' => sub {
	my $alignment = '>{\bfseries}c>{\itshape}c>{\ttfamily}c>{\bfseries\itshape\ttfamily}c';
	my $html      = DataTable([ [ 'a' .. 'd' ] ], texalignment => $alignment);
	like $html, qr{<td style="\Q$std_pad\E${talign_center}font-weight:bold;">\na\n},      'HTML bold column';
	like $html, qr{<td style="\Q$std_pad\E${talign_center}font-style:italic;">\nb\n},     'HTML italic column';
	like $html, qr{<td style="\Q$std_pad\E${talign_center}font-family:monospace;">\nc\n}, 'HTML monospace column';
	like $html,
		qr{<td style="\Q$std_pad\E${talign_center}font-weight:bold;font-style:italic;font-family:monospace;">\nd\n},
		'HTML bold italic monospace column';
	is tex_table([ [ 'a' .. 'd' ] ], texalignment => $alignment),
		"$tex_start\\begin{tabular}[t]{$alignment} a & b & c & d \\end{tabular}$tex_end", 'TeX column fonts';

	$alignment = '>{\color{red}}c>{\color{green}}c>{\color[HTML]{0000FF}}c>{\color{red!20}}c';
	$html      = DataTable([ [ 'a' .. 'd' ] ], texalignment => $alignment);
	like $html, qr{<td style="\Q$std_pad\E${talign_center}color:red;">\na\n},     'HTML named column text color';
	like $html, qr{<td style="\Q$std_pad\E${talign_center}color:green;">\nb\n},   'HTML named column text color';
	like $html, qr{<td style="\Q$std_pad\E${talign_center}color:#0000FF;">\nc\n}, 'HTML hex column text color';
	like $html, qr{<td style="\Q$std_pad\E${talign_center}color:red;">\nd\n},     'HTML column text color with tint';
	is tex_table([ [ 'a' .. 'd' ] ], texalignment => $alignment),
		"$tex_start\\begin{tabular}[t]{$alignment} a & b & c & d \\end{tabular}$tex_end", 'TeX column text color';

	$alignment =
		'>{\columncolor{red}}c>{\columncolor{green}}c>{\columncolor[HTML]{0000FF}}c>{\columncolor{red!20}}c';
	like DataTable([ [ 'a' .. 'd' ] ], texalignment => $alignment),
		qr{<colgroup>\n<col\ style="background-color:red;">\n<col\ style="background-color:green;">\n
		<col\ style="background-color:\#0000FF;">\n<col\ style="background-color:red;">\n</colgroup>}x,
		'HTML column background color';
	is tex_table([ [ 'a' .. 'd' ] ], texalignment => $alignment),
		"$tex_start\\begin{tabular}[t]{$alignment} a & b & c & d \\end{tabular}$tex_end",
		'TeX column background color';
};

subtest 'Encase' => sub {
	my @args = ([ [ 'a', [ 'd', noencase => 1 ] ] ], encase => [ '\(', '\)' ]);
	my $html = DataTable(@args);
	like $html, qr{<td[^>]*>\n\\\(\na\n\\\)\n</td>}, 'HTML encased cell';
	like $html, qr{<td[^>]*>\nd\n</td>},             'HTML cell with noencase';
	is tex_table(@args), "$tex_start\\begin{tabular}[t]{cc} \\(\na\n\\) & d \\end{tabular}$tex_end", 'TeX encase';
};

subtest 'Headers' => sub {
	my @args = (
		[
			[ [ 'a', headerrow => 1 ], 'b', [ 'd', header => 'td' ] ],
			[ 1 .. 3 ],
			[ [ 'A', header => 'td' ], 'B', [ 'D', header => 'th' ] ],
		],
		rowheaders => 1,
		headercss  => { fontFamily => 'cursive' }
	);
	my $cursive = 'font-family:cursive;';

	my $html = DataTable(@args);
	like $html, qr{<colgroup>\n<col style="border-right:solid 2px;">\n<col>\n<col>\n</colgroup>},
		'HTML row header column rule';
	like $html, qr{<thead\ style="vertical-align:top;border-bottom:solid\ 2px;">\n<tr>\n
		<th\ scope="col"\ style="\Q$std_pad\E$talign_center$cursive">\na\n</th>\n
		<th\ scope="col"\ style="\Q$std_pad\E$talign_center$cursive">\nb\n</th>\n
		<td\ style="\Q$std_pad\E$talign_center">\nd\n</td>\n</tr>\n</thead>}x, 'HTML header row with an excused cell';
	like $html, qr{<th scope="row" style="\Q$std_pad\E$talign_center$cursive">\n1\n</th>}, 'HTML row header';
	like $html, qr{<td style="\Q$std_pad\E$talign_center">\nA\n</td>},                     'HTML excused row header';
	like $html, qr{<th style="\Q$std_pad\E$talign_center$cursive">\nD\n</th>},             'HTML cell made a header';

	is tex_table(@args),
		$tex_start
		. '\begin{tabular}[t]{ccc} \multicolumn{1}{c|}{\bfseries a} & \bfseries b & d \\\\ \midrule{} '
		. '\multicolumn{1}{c|}{\bfseries 1} & 2 & 3 \\\\ \multicolumn{1}{c|}{A} & B & \bfseries D \end{tabular}'
		. $tex_end,
		'TeX headers';
};

subtest 'Vertical alignment of the table' => sub {
	my @args = ([ [ 'Lorem ipsum', 'b', 'c', 'd' ] ], align => 'XccX', valign => 'middle');
	like DataTable(@args), qr{^<table style="width:97%;margin:auto;">\n<tbody>\n}, 'HTML middle alignment';
	is tex_table(@args),
		$tex_start
		. '\begin{tabularx}{0.97\linewidth}[t]{XccX} \multicolumn{1}{m{0.2425\linewidth}}{Lorem ipsum} & '
		. '\multicolumn{1}{c}{b} & \multicolumn{1}{c}{c} & \multicolumn{1}{m{0.2425\linewidth}}{d} \end{tabularx}'
		. $tex_end,
		'TeX middle alignment';
};

subtest 'Assortment of CSS' => sub {
	my $html = DataTable(
		[ [ 'a' .. 'c' ], [ 1 .. 3 ] ],
		rowheaders => 1,
		tablecss   => { border => '1pt solid black' },
		columnscss => [ {}, {}, { backgroundColor => 'yellow' } ],
		datacss    => { fontFamily => 'fantasy' },
		headercss  => { fontFamily => 'monospace' },
		allcellcss => { padding    => '20pt 20pt', 'font-size' => '40px' }
	);
	# The order of the allcellcss properties is not deterministic.
	my $all = '(?:font-size:40px;padding:20pt 20pt;|padding:20pt 20pt;font-size:40px;)';

	like $html, qr{^<table style="border:1pt solid black;margin:auto;">}, 'HTML tablecss';
	like $html,
		qr{<colgroup>\n<col style="border-right:solid 2px;">\n<col>\n<col style="background-color:yellow;">\n},
		'HTML columnscss';
	like $html, qr{<th scope="row" style="\Q$std_pad\E$talign_center${all}font-family:monospace;">\na\n},
		'HTML allcellcss and headercss';
	like $html, qr{<td style="\Q$std_pad\E$talign_center${all}font-family:fantasy;">\nb\n},
		'HTML allcellcss and datacss';
};

subtest 'Cell alignment' => sub {
	my @args = ([ [
		[ 'a',           halign => 'l' ],
		[ 'b',           halign => 'c' ],
		[ 'c',           halign => 'r' ],
		[ 'Lorem ipsum', halign => 'p{1.5in}' ]
	] ]);
	my $html = DataTable(@args);
	like $html, qr{<td style="\Q$std_pad\E${talign_center}text-align:left;">\na\n},   'HTML left aligned cell';
	like $html, qr{<td style="\Q$std_pad\E${talign_center}text-align:center;">\nb\n}, 'HTML center aligned cell';
	like $html, qr{<td style="\Q$std_pad\E${talign_center}text-align:right;">\nc\n},  'HTML right aligned cell';
	like $html, qr{<td style="\Q$std_pad\E${talign_center}text-align:left;width:1.5in;">\nLorem ipsum\n},
		'HTML paragraph cell';
	is tex_table(@args),
		$tex_start
		. '\begin{tabular}[t]{cccc} \multicolumn{1}{l}{a} & \multicolumn{1}{c}{b} & \multicolumn{1}{r}{c} & '
		. '\multicolumn{1}{p{1.5in}}{Lorem ipsum} \end{tabular}'
		. $tex_end,
		'TeX cell alignment';
};

subtest 'Cell fonts' => sub {
	my @args = ([
		[ [ 'a', tex => '\bfseries' ], [ 'b', tex => '\itshape' ], [ 'c', tex => '\ttfamily' ] ],
		[ [ 1,   b   => 1 ],           [ 2,   i   => 1 ],          [ 3,   m   => 1 ] ]
	]);
	my $html = DataTable(@args);
	like $html, qr{<td style="\Q$std_pad\E${talign_center}font-weight:bold;">\n$_\n}, "HTML bold cell $_"
		for ('a', 1);
	like $html, qr{<td style="\Q$std_pad\E${talign_center}font-style:italic;">\n$_\n}, "HTML italic cell $_"
		for ('b', 2);
	like $html, qr{<td style="\Q$std_pad\E${talign_center}font-family:monospace;">\n$_\n}, "HTML monospace cell $_"
		for ('c', 3);
	is tex_table(@args),
		$tex_start
		. '\begin{tabular}[t]{ccc} \bfseries a & \itshape b & \ttfamily c \\\\ '
		. '\bfseries 1 & \itshape 2 & \ttfamily 3 \end{tabular}'
		. $tex_end,
		'TeX cell fonts';
};

subtest 'Cell vertical rules' => sub {
	my @args = ([
		[ [ 'a', halign => '|c||' ], 'b', [ 'c', halign => '|||c||||' ] ],
		[ 1, [ 2, halign => '!{\vrule width 0.1em}c!{\vrule width 0.2em}' ], 3 ]
	]);
	my $html = DataTable(@args);
	like $html, qr{<td style="\Q$std_pad\E${talign_center}border-left:solid 1px;border-right:solid 2px;">\na\n},
		'HTML left and right rules on a cell in the first column';
	like $html, qr{<td style="\Q$std_pad\E${talign_center}border-right:solid 4px;$talign_center">\nc\n},
		'HTML left rule ignored on a cell not in the first column';
	like $html, qr{<td style="\Q$std_pad\E${talign_center}border-right:solid 0.2em;$talign_center">\n2\n},
		'HTML explicit width rules on a cell';
	is tex_table(@args),
		$tex_start
		. '\begin{tabular}[t]{ccc} \multicolumn{1}{|c||}{a} & b & \multicolumn{1}{c||||}{c} \\\\ '
		. '1 & \multicolumn{1}{c!{\vrule width 0.2em}}{2} & 3 \end{tabular}'
		. $tex_end,
		'TeX cell vertical rules';
};

subtest 'Colspan' => sub {
	my @args = ([ [ [ 'abcd', colspan => 4, halign => '|||c|||' ] ], [ 1 .. 4 ] ], align => '|cccc|');
	my $html = DataTable(@args);
	like $html, qr{^<table style="border-left:solid 1px;margin:auto;">}, 'HTML table left border';
	like $html,
		qr{<td colspan="4" style="\Q$std_pad\E${talign_center}border-left:solid 3px;border-right:solid 3px;">\nabcd\n},
		'HTML cell spanning columns';
	is tex_table(@args),
		"$tex_start\\begin{tabular}[t]{|cccc|} \\multicolumn{4}{|||c|||}{abcd} \\\\ 1 & 2 & 3 & 4 \\end{tabular}$tex_end",
		'TeX cell spanning columns';
};

subtest 'Cell horizontal rules' => sub {
	my @args = ([
		[ [ 'a', top => 1, bottom => 2 ], 'b', [ 'c', colspan => 2, top => '2pt', bottom => '0.5em' ] ],
		[ 1, [ 2, top => 3, bottom => '1em' ], 3, 4 ],
		[ 'A' .. 'D' ]
	]);
	my $html = DataTable(@args);
	like $html, qr{<colgroup>\n<col\ style="border-top:solid\ 1px;">\n<col>\n<col\ style="border-top:solid\ 2pt;">\n
		<col\ style="border-top:solid\ 2pt;">\n</colgroup>}x, 'HTML top rules on cells in the first row';
	like $html, qr{<td style="\Q$std_pad\E${talign_center}border-bottom:solid 2px;">\na\n},
		'HTML bottom rule on a cell';
	like $html, qr{<td colspan="2" style="\Q$std_pad\E${talign_center}border-bottom:solid 0.5em;">\nc\n},
		'HTML bottom rule on a cell spanning columns';
	like $html, qr{<td style="\Q$std_pad\E${talign_center}border-bottom:solid 1em;">\n2\n},
		'HTML top rule ignored on a cell not in the first row';
	is tex_table(@args),
		$tex_start
		. '\begin{tabular}[t]{cccc} \cmidrule[2pt]{3-4} \cmidrule[0.75pt]{1-1} a & b & \multicolumn{2}{c}{c} \\\\ '
		. '\cmidrule[1.5pt]{1-1} \cmidrule[0.5em]{3-4} 1 & 2 & 3 & 4 \\\\ \cmidrule[1em]{2-2} A & B & C & D '
		. '\end{tabular}'
		. $tex_end,
		'TeX cell horizontal rules';
};

subtest 'Cell color' => sub {
	my @args = ([ [
		'a',
		[ 'b', color => 'blue',    bgcolor => 'green' ],
		[ 'c', color => 'blue!50', bgcolor => 'green!50' ],
		[ 'd', color => '0000FF',  bgcolor => '00FF00' ]
	] ]);
	my $html = DataTable(@args);
	like $html, qr{<td style="\Q$std_pad\E${talign_center}background-color:green;color:blue;">\n$_\n},
		"HTML named cell colors for $_"
		for ('b', 'c');
	like $html, qr{<td style="\Q$std_pad\E${talign_center}background-color:#00FF00;color:#0000FF;">\nd\n},
		'HTML hex cell colors';
	is tex_table(@args),
		$tex_start
		. '\begin{tabular}[t]{cccc} a & \color{blue}\cellcolor{green} b & '
		. '\color{blue!50}\cellcolor{green!50} c & \color[HTML]{0000FF}\cellcolor[HTML]{00FF00} d \end{tabular}'
		. $tex_end,
		'TeX cell colors';
};

subtest 'TeX pre and post' => sub {
	my @args = ([ [ [ 'a', texpre => '\LaTeX', texpost => '\TeX' ], 'b' ] ]);
	like DataTable(@args), qr{<td style="\Q$std_pad\E$talign_center">\na\n</td>}, 'HTML ignores texpre and texpost';
	is tex_table(@args), "$tex_start\\begin{tabular}[t]{cc} \\LaTeX\na\n\\TeX & b \\end{tabular}$tex_end",
		'TeX pre and post';
};

subtest 'Row rules' => sub {
	my @args = ([ [ [ 'a', rowtop => 3 ], 'b' ], [ [ 1, rowbottom => '1em' ], 2 ], [ [ 'A', rowtop => 2 ], 'B' ] ]);
	my $html = DataTable(@args);
	like $html, qr{<tr style="border-top:solid 3px;">\n<td[^>]*>\na\n},    'HTML top rule on the first row';
	like $html, qr{<tr style="border-bottom:solid 1em;">\n<td[^>]*>\n1\n}, 'HTML bottom rule on a row';
	like $html, qr{<tr>\n<td[^>]*>\nA\n},                                  'HTML top rule ignored on other rows';
	is tex_table(@args),
		"$tex_start\\begin{tabular}[t]{cc} \\toprule[2.25pt] a & b \\\\ 1 & 2 \\\\ \\midrule[1em] A & B "
		. "\\end{tabular}$tex_end",
		'TeX row rules';
};

subtest 'Row color' => sub {
	my @args = ([
		[ [ 'a', rowcolor => 'blue' ], 'b' ],
		[ 1,   [ 2,   rowcolor => '{green!20}' ] ],
		[ 'A', [ 'B', rowcolor => 'FF0000' ] ]
	]);
	my $html = DataTable(@args);
	like $html, qr{<tr style="background-color:blue;">\n<td[^>]*>\na\n},     'HTML named row color';
	like $html, qr{<tr style="background-color:green;">\n<td[^>]*>\n1\n},    'HTML row color with tint';
	like $html, qr{<tr style="background-color:\#FF0000;">\n<td[^>]*>\nA\n}, 'HTML hex row color';
	is tex_table(@args),
		$tex_start
		. '\begin{tabular}[t]{cc} \rowcolor{blue} a & b \\\\ \hiderowcolors \rowcolor{green!20} 1 & 2 \\\\ '
		. '\hiderowcolors \rowcolor[HTML]{FF0000} A & B \hiderowcolors \end{tabular}'
		. $tex_end,
		'TeX row colors';
};

subtest 'Row vertical alignment' => sub {
	my @args = ([ [ [ 'Lorem ipsum', valign => 'bottom' ], 'b' ], [ 'Lorem ipsum', 'B' ] ], align => 'p{2in}c');
	my $html = DataTable(@args);
	like $html, qr{<tr style="vertical-align:bottom;">\n<td[^>]*>\nLorem ipsum\n}, 'HTML bottom aligned row';
	like $html, qr{<tr>\n<td[^>]*>\nLorem ipsum\n},                                'HTML default aligned row';
	is tex_table(@args),
		$tex_start
		. '\begin{tabular}[t]{p{2in}c} \multicolumn{1}{b{2in}}{Lorem ipsum} & \multicolumn{1}{c}{b} \\\\ '
		. 'Lorem ipsum & B \end{tabular}'
		. $tex_end,
		'TeX bottom aligned row';
};

subtest 'Row CSS' => sub {
	my $html = DataTable([ [ [ 'a', rowcss => { fontFamily => 'fantasy' } ], 'b' ], [ 1, 2 ] ]);
	like $html, qr{<tr style="font-family:fantasy;">\n<td[^>]*>\na\n}, 'HTML row css';
	like $html, qr{<tr>\n<td[^>]*>\n1\n},                              'HTML row without css';
};

subtest 'Layout tables' => sub {
	my $layout_cell = 'vertical-align:top;padding:0.85rem 0.85rem;text-align:center;display:table-cell;';
	is LayoutTable([ [ 'a', 'b' ], [ 1, 2 ] ]), qq{<div style="margin:auto;display:table;border-collapse:collapse;">
<div style="display:table-row;">
<div style="$layout_cell">
a
</div>
<div style="$layout_cell">
b
</div>
</div>
<div style="display:table-row;">
<div style="$layout_cell">
1
</div>
<div style="$layout_cell">
2
</div>
</div>
</div>}, 'HTML layout table with no options';
	is tex_layout_table([ [ 'a', 'b' ], [ 1, 2 ] ]),
		"{\\par\\setlength{\\tabcolsep}{10pt}\\renewcommand{\\arraystretch}{2}\\centering%\n"
		. "\\begin{tabular}[t]{cc} a & b \\\\ 1 & 2 \\end{tabular}$tex_end",
		'TeX layout table with no options';

	my $html = LayoutTable([ [ DataTable([ [ 'a', 'b' ] ]), 'Lorem ipsum' ] ], align => 'cX');
	like $html, qr{^<div\ style="width:97%;margin:auto;display:table;border-collapse:collapse;">\n
		<div\ style="display:table-row;">\n
		<div\ style="\Q$layout_cell\E">\n<table\ style="margin:auto;">\n.*</table>\n</div>\n
		<div\ style="vertical-align:top;padding:0.85rem\ 0.85rem;display:table-cell;">\nLorem\ ipsum\n</div>}sx,
		'HTML data table inside a layout table';
	{
		local $main::displayMode = 'TeX';
		is LayoutTable([ [ DataTable([ [ 'a', 'b' ] ]), 'Lorem ipsum' ] ], align => 'cX'),
			"{\\par\\setlength{\\tabcolsep}{10pt}\\renewcommand{\\arraystretch}{2}\\centering%\n"
			. "\\begin{tabularx}{0.97\\linewidth}[t]{cX} $tex_start\\begin{tabular}[t]{cc} a & b \\end{tabular}"
			. "$tex_end & Lorem ipsum \\end{tabularx}$tex_end",
			'TeX data table inside a layout table';
	}

	like LayoutTable([ [ 'x', 'Lorem ipsum' ] ], valign => 'bottom', align => 'cX'),
		qr{<div\ style="vertical-align:bottom;padding:0.85rem\ 0.85rem;text-align:center;display:table-cell;">\nx\n
		</div>\n<div\ style="vertical-align:bottom;padding:0.85rem\ 0.85rem;display:table-cell;">\nLorem\ ipsum\n}x,
		'HTML bottom aligned layout table';
	is tex_layout_table([ [ 'x', 'Lorem ipsum' ] ], valign => 'bottom', align => 'cX'),
		"{\\par\\setlength{\\tabcolsep}{10pt}\\renewcommand{\\arraystretch}{2}\\centering%\n"
		. "\\begin{tabularx}{0.97\\linewidth}[t]{cX} \\multicolumn{1}{c}{x} & "
		. "\\multicolumn{1}{b{0.485\\linewidth}}{Lorem ipsum} \\end{tabularx}$tex_end",
		'TeX bottom aligned layout table';
};

done_testing();
