#!/usr/bin/env perl

use Test2::V0 '!E', { E => 'EXISTS' };

# Quell a warning about this being used only once.
local $main::envir;

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

use lib "$ENV{PG_ROOT}/lib";

use LaTeXImage;

loadMacros('PGtikz.pl');

my $drawing = createTikZImage();
$drawing->tex(<< 'END_TIKZ');
\draw (-4,0) -- (4,0);
\draw (0,-2) -- (0,2);
\draw (0,0) circle[radius=1.5];
\draw (0, 1.5) node[anchor=south]{N} -- (2.5,0) node[above]{y};
\draw (1.2,0.9) node[right]{\((\vec x, x_{n})\)};
END_TIKZ

ok my $img = image($drawing), 'img tag is generated';

like $img, qr!
	^<IMG\s
	SRC="/pg_files/tmp/images/([a-z0-9_-]*)\.svg"\s
	class="image-view-elt"\s
	tabindex="0"\s
	role="button"\s
	WIDTH="100"\s*
	>$!x, 'img tag has correct format';

# Note that the image file is not generated until after the `image($drawing)` call.
my $image_file = "$main::envir{tempDirectory}images/" . $drawing->imageName . '.' . $drawing->ext;
ok -e $image_file, 'image file is generated';

# Delete the generated image file.
unlink $image_file;

done_testing();
