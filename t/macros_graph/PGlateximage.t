#!/usr/bin/env perl

=head1 PGlateximage

Test PGlateximage.pl

=cut

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

use lib "$ENV{PG_ROOT}/lib";

use LaTeXImage;

loadMacros('PGlateximage.pl');

my $images_dir = "$WeBWorK::PG::IO::pg_envir->{directories}{html_temp}/images";

subtest 'Default image settings' => sub {
	my $drawing = createLaTeXImage();

	isa_ok $drawing, [ 'PGlateximage', 'LaTeXImage' ], 'createLaTeXImage returns a PGlateximage object';
	is $drawing->ext,       'svg',                             'default extension is svg';
	is $drawing->svgMethod, $main::envir{latexImageSVGMethod}, 'svg method is set from the environment';
	like $drawing->imageName, qr/^[a-z0-9_-]+$/, 'image name is generated';
	isnt createLaTeXImage()->imageName, $drawing->imageName, 'each image gets a unique name';

	is [ $drawing->header ],
		[ "\\documentclass{standalone}\n", "\\usepackage[svgnames]{xcolor}\n", '', "\\begin{document}\n" ],
		'header with no packages or environment';
	is [ $drawing->footer ], ["\\end{document}\n"], 'footer with no environment';
};

subtest 'TeX packages' => sub {
	my $drawing = createLaTeXImage();
	$drawing->texPackages([ [ 'xy', 'all' ], 'amsmath', ['bm'], [ 'xcolor', 'dvipsnames' ] ]);

	my $header = join('', $drawing->header);
	like $header,   qr/\\usepackage\[all\]\{xy\}\n/,            'package with options is loaded';
	like $header,   qr/\\usepackage\{amsmath\}\n/,              'package given as a string is loaded';
	like $header,   qr/\\usepackage\{bm\}\n/,                   'package given as an array without options is loaded';
	like $header,   qr/\\usepackage\[dvipsnames\]\{xcolor\}\n/, 'xcolor options can be overridden';
	unlike $header, qr/svgnames/,                               'default xcolor options are not used when overridden';
	is scalar(() = $header =~ /\{xcolor\}/g), 1, 'xcolor is only loaded once';
	unlike $header, qr/\{tikz\}/, 'tikz is not loaded without a tikzpicture environment';

	$drawing->texPackages('amsmath');
	is $drawing->texPackages, [ [ 'xy', 'all' ], 'amsmath', ['bm'], [ 'xcolor', 'dvipsnames' ] ],
		'texPackages ignores a non-array argument';
};

subtest 'Environments' => sub {
	my $drawing = createLaTeXImage();

	$drawing->environment('center');
	is $drawing->environment, [ 'center', '' ], 'environment given as a string';
	like join('', $drawing->header), qr/\\begin\{document\}\n\\begin\{center\}\n$/, 'header begins the environment';
	is [ $drawing->footer ], [ '\end{', "center}\n", "\\end{document}\n" ], 'footer ends the environment';

	$drawing->environment([ 'circuitikz', 'scale=1.2, transform shape' ]);
	is $drawing->environment, [ 'circuitikz', 'scale=1.2, transform shape' ], 'environment given as an array';
	like join('', $drawing->header),
		qr/\\begin\{document\}\n\\begin\{circuitikz\}\[scale=1.2, transform shape\]\n$/,
		'header begins the environment with options';
	is join('', $drawing->footer), "\\end{circuitikz}\n\\end{document}\n", 'footer ends the environment';

	$drawing->environment('tikzpicture');
	like join('', $drawing->header), qr/\\usepackage\{tikz\}\n/, 'tikz is loaded for a tikzpicture environment';
};

subtest 'Additional preamble and TikZ libraries' => sub {
	my $drawing = createLaTeXImage();
	$drawing->tikzLibraries('arrows.meta,calc');
	$drawing->addToPreamble("\\newcommand{\\R}{\\mathbb{R}}\n");

	like join('', $drawing->header),
		qr/\\usetikzlibrary\{arrows.meta,calc\}\n\\newcommand\{\\R\}\{\\mathbb\{R\}\}\n\\begin\{document\}/,
		'TikZ libraries and additional preamble are added before the document begins';
};

subtest 'Image extension' => sub {
	my $drawing = createLaTeXImage();

	for (qw(png gif pdf tgz svg)) {
		$drawing->ext($_);
		is $drawing->ext, $_, "extension can be set to $_";
	}

	$drawing->ext('sh; rm -rf /');
	is $drawing->ext, 'svg', 'invalid extension is rejected';

	{
		local $main::displayMode = 'TeX';
		my $tex_drawing = createLaTeXImage();
		is $tex_drawing->ext, 'pdf', 'extension is pdf in TeX display mode';
		$tex_drawing->ext('png');
		is $tex_drawing->ext, 'pdf', 'extension can not be changed in TeX display mode';
	}

	{
		local $main::displayMode = 'PTX';
		is createLaTeXImage()->ext, 'tgz', 'extension is tgz in PTX display mode';
	}
};

subtest 'Convert options' => sub {
	my $drawing = createLaTeXImage();

	is $drawing->convertOptions, $main::envir{latexImageConvertOptions},
		'convert options are set from the environment';

	$drawing->convertOptions({ input => { density => 300 }, output => { quality => 100, resize => '500x500' } });
	is $drawing->convertOptions, { input => { density => 300 }, output => { quality => 100, resize => '500x500' } },
		'valid convert options are accepted';

	like warnings {
		$drawing->convertOptions(
			{ input => { 'bad;name' => 1, density => '300; rm -rf /' }, output => { quality => 90 } })
	}, bag {
		item qr/^Invalid convert option name: bad;name/;
		item qr/^Invalid convert option value for density/;
		end;
	}, 'invalid convert options produce warnings';
	is $drawing->convertOptions, { input => {}, output => { quality => 90 } },
		'invalid convert options are dropped';
};

subtest 'Generate an image using xy' => sub {
	my $drawing = createLaTeXImage();
	$drawing->texPackages([ [ 'xy', 'all' ] ]);
	$drawing->tex(<<~'END_LATEX_IMAGE');
		\xymatrix{ A \ar[r] & B \ar[d] \\\\
		           D \ar[u] & C \ar[l] }
		END_LATEX_IMAGE

	my $path = insertGraph($drawing);
	is $path, "$images_dir/" . $drawing->imageName . '.svg', 'insertGraph returns the image file path';
	ok -e $path, 'image file is generated';

	open(my $fh, '<', $path) or die "Unable to open $path: $!";
	my $svg = do { local $/; <$fh> };
	close $fh;
	like $svg, qr/<svg\b/, 'image file is an svg image';

	my $url = '/pg_files/tmp/images/' . $drawing->imageName . '.svg';
	is alias($path), $url, 'alias returns the image url';

	is image($path, width => 228, height => 114, tex_size => 400),
		qq{<img src="$url" class="image-view-elt middle" tabindex="0" role="button" width="228" height="114"  >},
		'image tag has correct format';

	like embedSVG($path), qr/^\s*<img src="\Q$url\E">$/, 'embedSVG returns an img tag';

	unlink $path;
};

subtest 'Generate an image using circuitikz' => sub {
	my $drawing = createLaTeXImage();
	$drawing->texPackages(['circuitikz']);
	$drawing->environment([ 'circuitikz', 'scale=1.2, transform shape' ]);
	$drawing->tex(<<~'END_LATEX_IMAGE');
		\draw (0,1) to [battery2, v_=\(V_{cc}\), name=B] ++(0,2);
		\node[draw,red,circle,inner sep=4pt] at(B.left) {};
		\node[draw,red,circle,inner sep=4pt] at(B.right) {};
		END_LATEX_IMAGE

	my $url = '/pg_files/tmp/images/' . $drawing->imageName . '.svg';
	is image($drawing, width => 228, tex_size => 400),
		qq{<img src="$url" class="image-view-elt middle" tabindex="0" role="button" width="228"  >},
		'image tag has correct format';

	# Note that the image file is not generated until after the `image($drawing)` call.
	my $image_file = "$images_dir/" . $drawing->imageName . '.svg';
	ok -e $image_file, 'image file is generated';

	unlink $image_file;
};

subtest 'Image generation failure' => sub {
	my $drawing = createLaTeXImage();
	$drawing->tex('\begin{notanenvironment}');

	my $image_file = "$images_dir/" . $drawing->imageName . '.svg';
	like warnings { insertGraph($drawing) }, bag {
		item qr/^The (dvi|pdf) file was not created/;
		item qr/^Image file production failed/;
		etc;
	}, 'warnings are issued when the LaTeX code does not compile';
	ok !-e $image_file, 'image file is not generated';
};

done_testing();
