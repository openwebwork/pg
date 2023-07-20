################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2023 The WeBWorK Project, https://github.com/openwebwork
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of either: (a) the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version, or (b) the "Artistic License" which comes with this package.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
# Artistic License for more details.
################################################################################

package WeBWorK::PG::Constants;

=head1 NAME

WeBWorK::PG::Constants - provide constant values used by PG.

=cut

use strict;
use warnings;

# ImageGenerator

# Arguments to pass to dvipng. This is dependant on the version of dvipng.
#
# For dvipng versions 0.x
#     $ImageGenerator::DvipngArgs = "-x4000.5 -bgTransparent -Q6 -mode toshiba -D180";
# For dvipng versions 1.0 to 1.5
#     $ImageGenerator::DvipngArgs = "-bgTransparent -D120 -q -depth";
#
# For dvipng versions 1.6 (and probably above)
#     $ImageGenerator::DvipngArgs = "-bgtransparent -D120 -q -depth";
# Note: In 1.6 and later, bgTransparent gives alpha-channel transparency while
# bgtransparent gives single-bit transparency. If you use alpha-channel transparency,
# the images will not be viewable with MSIE.  bgtransparent works for version 1.5,
# but does not give transparent backgrounds. It does not work for version 1.2. It has not
# been tested with other versions.
$WeBWorK::PG::ImageGenerator::DvipngArgs = "-bgTransparent -D120 -q -depth";

# If true, don't delete temporary files
$WeBWorK::PG::ImageGenerator::PreserveTempFiles = 0;

# TeX to prepend to equations to be processed.
$WeBWorK::PG::ImageGenerator::TexPreamble = <<'EOF';
\documentclass[12pt]{article}
\nonstopmode
\usepackage{amsmath,amsfonts,amssymb}
\def\gt{>}
\def\lt{<}
\usepackage[active,textmath,displaymath]{preview}
\begin{document}
EOF

# TeX to append to equations to be processed.
$WeBWorK::PG::ImageGenerator::TexPostamble = <<'EOF';
\end{document}
EOF

# WeBWorK::PG
# The maximum amount of time (in seconds) to work on a single problem.
# At the end of this time a timeout message is sent to the browser.
$WeBWorK::PG::TIMEOUT = 60;

1;
