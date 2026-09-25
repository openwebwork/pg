#!/usr/bin/env perl

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

use lib "$ENV{PG_ROOT}/lib";

use LaTeXImage;

loadMacros('PGtikz.pl');

subtest 'TikZ image generation' => sub {
	my $drawing = createTikZImage();
	$drawing->tex(<<~'END_TIKZ');
		\draw (-4,0) -- (4,0);
		\draw (0,-2) -- (0,2);
		\draw (0,0) circle[radius=1.5];
		\draw (0, 1.5) node[anchor=south]{N} -- (2.5,0) node[above]{y};
		\draw (1.2,0.9) node[right]{\((\vec x, x_{n})\)};
		END_TIKZ

	ok my $img = image($drawing), 'img tag is generated';

	like $img, qr!
		^<img\s
			src="/pg_files/tmp/images/([a-z0-9_-]*)\.svg"\s
			class="image-view-elt\smiddle"\s
			tabindex="0"\s
			role="button"\s
			width="200"\s*
		>$!x, 'img tag has correct format';

	# Note that the image file is not generated until after the `image($drawing)` call.
	my $image_file =
		"$WeBWorK::PG::IO::pg_envir->{directories}{html_temp}/images/" . $drawing->imageName . '.' . $drawing->ext;
	ok -e $image_file, 'image file is generated';

	# Delete the generated image file.
	unlink $image_file;
};

subtest 'TikZ image settings' => sub {
	my $drawing = createTikZImage();

	isa_ok $drawing, [ 'PGtikz', 'LaTeXImage' ], 'createTikZImage returns a PGtikz object';
	is $drawing->environment, [ 'tikzpicture', '' ], 'environment is tikzpicture';
	is join('', $drawing->header), <<~'END_TIKZ',
		\documentclass{standalone}
		\usepackage[svgnames]{xcolor}
		\usepackage{tikz}
		\begin{document}
		\begin{tikzpicture}
		END_TIKZ
		'header loads tikz and begins the tikzpicture environment';
	is join('', $drawing->footer), "\\end{tikzpicture}\n\\end{document}\n",
		'footer ends the tikzpicture environment';

	$drawing->tikzOptions('main_node/.style={circle,fill=blue!20,draw,minimum size=1em,inner sep=3pt}');
	is $drawing->environment,
		[ 'tikzpicture', 'main_node/.style={circle,fill=blue!20,draw,minimum size=1em,inner sep=3pt}' ],
		'tikzOptions are passed to the tikzpicture environment';
	like join('', $drawing->header),
		qr/\\begin\{tikzpicture\}\[main_node\/\.style=\{circle,fill=blue!20,draw,minimum size=1em,inner sep=3pt\}\]\n$/,
		'header begins the tikzpicture environment with the tikzOptions';

	$drawing->environment('center');
	is $drawing->environment->[0], 'tikzpicture', 'environment can not be changed when tikzOptions are set';

	$drawing->texPackages([ ['tikz'], 'pgfplots' ]);
	my $header = join('', $drawing->header);
	is scalar(() = $header =~ /\{tikz\}/g), 1, 'tikz is only loaded once when it is also in texPackages';
	like $header, qr/\\usepackage\{tikz\}\n\\usepackage\{pgfplots\}\n/, 'packages are loaded';
};

subtest 'Generate a pgfplots image' => sub {
	my $drawing = createTikZImage();
	$drawing->texPackages([ ['pgfplots'] ]);
	$drawing->addToPreamble('\\pgfplotsset{compat=1.15}');
	$drawing->tex(<<~'END_TIKZ');
		\huge
		\begin{axis}
			[
				ybar=0pt,
				bar width=2cm,
				width=14cm,
				height=12cm,
				enlarge x limits=0.2,
				ymajorgrids,
				ymin=0,
				ymax=11,
				ylabel={\textbf{Number of Books}},
				xtick=data,
				xticklabels={Philosophy, Math, Literature, History},
				ytick={1,...,10},
				major x tick style={opacity=0},
			]
			\addplot[fill=Blue!20] coordinates {(0, 3) (1, 5) (2, 7) (3, 9)};
		\end{axis}
		END_TIKZ

	like join('', $drawing->header), qr/\\usepackage\{pgfplots\}\n\\pgfplotsset\{compat=1.15\}\\begin\{document\}/,
		'pgfplots is loaded and the additional preamble is added';

	my $path = insertGraph($drawing);
	is $path, "$WeBWorK::PG::IO::pg_envir->{directories}{html_temp}/images/" . $drawing->imageName . '.svg',
		'insertGraph returns the image file path';
	ok -e $path, 'image file is generated';

	my $url = '/pg_files/tmp/images/' . $drawing->imageName . '.svg';
	is alias($path), $url, 'alias returns the image url';
	is image($path, width => 100, tex_size => 400),
		qq{<img src="$url" class="image-view-elt middle" tabindex="0" role="button" width="100"  >},
		'image tag has correct format';

	unlink $path;
};

done_testing();
