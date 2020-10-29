################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2018 The WeBWorK Project, http://openwebwork.sf.net/
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

PGtikz.pl - Insert images into problems that are generated using LaTeX and TikZ.

=head1 DESCRIPTION

This is a convenience macro for utilizing the TikZImage object to insert TikZ
images into problems.  Create a TikZ image as follows:

	$image = createTikZImage();
	$image->tex(<<END_TIKZ);
	\draw (-2,0) -- (2,0);
	\draw (0,-2) -- (0,2);
	\draw (0,0) circle[radius=1.5];
	END_TIKZ

Then insert the image into the problem with

	image(insertGraph($image));

=head1 DETAILED USAGE

There are several TikZImage parameters that may need to be set for the
TikZImage object return by createTikZImage to generate the desired image.

	$image->tex()              Add the tikz commands that define the image.
							   This takes a single string parameter.  It is
							   generally best to use single quotes around the
							   string.  Escaping of special characters may be
                               needed in some cases.

	$image->tikzOptions()      Add options that will be passed to
							   \begin{tikzpicture}.  This takes a single
                               string parameter.

	$image->tikzLibraries()    Add additional tikz libraries to load.  This
                               takes a single string parameter.

	$image->ext()              Set the file type to be used for the image.
							   The valid image types are 'png', 'gif', 'svg',
							   and 'pdf'.  The default is a 'png' image.  This
							   macro sets this to 'pdf' when a hardcopy is
                               generated.

=cut

sub _PGtikz_init {}

# Not much needs to be done here.  The real work is done in TikZImage.pm.
sub createTikZImage
{
	my $image = new TikZImage;
	$image->ext('pdf') if $main::displayMode eq 'TeX';
	$image->imageName($main::PG->getUniqueName($image->ext));
	return $image;
}

1;
