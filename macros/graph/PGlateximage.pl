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

=head1 NAME

PGlateximage.pl - Insert images into problems that are generated using LaTeX.

=head1 DESCRIPTION

This is a convenience macro for utilizing the LaTeXImage object to insert LaTeX
images into problems.  An example::

    $image = createLaTeXImage();
    $image->texPackages([['xy','all']]);
    $image->BEGIN_LATEX_IMAGE
    \xymatrix{ A \ar[r] & B \ar[d] \\\\
               D \ar[u] & C \ar[l] }
    END_LATEX_IMAGE

The LaTeX code is in a perl interpolated heredoc, so you may need to be careful
with backslashes. In the above, \\\\ becomes \\, because a simple \\ would
become \. But \x and \a do not require escaping the backslash. (It would be
harmless to escape these too though.)

If math content is within the LaTeX code, delimit it with \(...\) instead of
with dollar signs.

Then insert the image into the problem with

    image(insertGraph($image));

=head1 DETAILED USAGE

There are several LaTeXImage parameters that may need to be set for the
LaTeXImage object return by createLaTeXImage to generate the desired image.

    $image->tex()              Add the tex commands that define the image.
                               This takes a single string parameter.  It is
                               generally best to use single quotes around the
                               string.  Escaping of special characters may be
                               needed in some cases.

    $image->environment()      Either a string naming an environment to wrap the
                               tex() in, or an array where the first element is
                               the name of an environment and an optional second
                               argument is a string with options for the environment.
                               For example:
                               $image->texPackages(['circuitikz']);
                               $image->environment(['circuitikz','scale=1.2, transform shape']);

    $image->tikzLibraries()    Add additional tikz libraries to load.  This
                               takes a single string parameter.
                               For example:
                               $image->tikzLibraries("arrows.meta,calc");

    $image->texPackages()      Add tex packages to load.  This takes an array for
                               its parameter.  Each element of this array should
                               either be the package name as a string, or an
                               array with two elements, the first of which is the
                               package name as a string and the second of which
                               is a string containing the options for the package.
                               For example:
                               $image->texPackages([
                                   "pgfplots",
                                   ["hf-tikz", "customcolors"],
                                   ["xcolor", "cmyk,table"]
                               ]);

    $image->addToPreamble()    Additional commands to add to the TeX preamble.
                               This takes a single string parameter.

    $image->ext()              Set the file type to be used for the image.
                               The valid image types are 'png', 'gif', 'svg',
                               and 'pdf'.  The default is an 'svg' image.  You
                               should determine if an 'svg' image works well with
                               the LaTeX code that you utilize.  If not, then use
                               this method to change the exension to 'png' or
                               'gif'.

                               This macro sets the extension to 'pdf' when a
                               hardcopy is generated.

    $image->convertOptions()   If ImageMagick's convert command is used to build
                               the output image (presently only done for 'png'
                               output) these input and output options will be
                               used. For example:
                               $image->convertOptions({
                                   input => {density => 300},
                                   output => {quality => 100, resize => "500x500"}
                               });
                               For a complete list of options, see:
                               https://imagemagick.org/script/command-line-options.php

=cut

sub _PGlateximage_init {
	main::PG_restricted_eval('sub createLaTeXImage { PGlateximage->new(@_); }');
}

package PGlateximage;
our @ISA = qw(LaTeXImage);

# Not much needs to be done here.
# The real work is done in LaTeXImage.pm.
sub new {
	my $self  = shift;
	my $class = ref($self) || $self;

	my $image = $class->SUPER::new(@_);
	$image->svgMethod($main::envir{latexImageSVGMethod}           // 'pdf2svg');
	$image->convertOptions($main::envir{latexImageConvertOptions} // { input => {}, output => {} });
	$image->SUPER::ext('pdf') if $main::displayMode eq 'TeX';
	$image->SUPER::ext('tgz') if $main::displayMode eq 'PTX';
	$image->imageName($main::PG->getUniqueName($image->ext));

	return bless $image, $class;
}

sub ext {
	my $self = shift;
	my $ext  = shift;
	return $self->SUPER::ext($ext) if $ext && $main::displayMode ne 'TeX';
	return $self->SUPER::ext;
}

1;
