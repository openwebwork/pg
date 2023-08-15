#!/bin/perl
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

# This is a Perl module which simplifies and automates the process of generating
# simple images using LaTeX, and converting them into a web-useable format.  Its
# typical usage is via the PGlateximage.pl or PGtikz.pl macros and is documented
# there.

package LaTeXImage;

use strict;
use warnings;

use File::Copy qw(move);

require WeBWorK::PG::IO;
require WeBWorK::PG::ImageGenerator;

# The constructor (it takes no parameters)
sub new {
	my $class = shift;
	my $data  = {
		tex => '',
		# If tikzOptions is nonempty, then environment will effectively be [ 'tikzpicture', tikzOptions ].
		environment    => '',
		tikzOptions    => '',
		tikzLibraries  => '',
		texPackages    => [],
		addToPreamble  => '',
		ext            => 'svg',
		svgMethod      => 'pdf2svg',
		convertOptions => { input => {}, output => {} },
		imageName      => ''
	};
	return bless sub {
		my ($field, $value) = @_;
		if (defined $value) {
			# The ext field is protected to ensure that unsafe commands can not
			# be passed to the command line in the system call it is used in.
			if ($field eq 'ext') {
				$data->{ext} = $value if $value && ($value =~ /^(png|gif|svg|pdf|tgz)$/);
			} else {
				$data->{$field} = $value;
			}
		}
		return $data->{$field};
	}, $class;
}

# Accessors

# Set LaTeX image code as a single string parameter.
sub tex {
	my ($self, $tex) = @_;
	return &$self('tex', $tex);
}

# Set an environment to surround the tex(). This can be a string naming the environment.
# Or it can be an array reference. The first element of this array should be the name of
# the environment. If there is a second element, it should be a string with options for
# the environment. This could be extended to support environments with multiple option
# fields that may use parentheses for delimiters.
# If tikzOptions is nonempty, the input is ignored and output is [ 'tikzpicture', tikzOptions ].
sub environment {
	my ($self, $environment) = @_;
	return [ 'tikzpicture', $self->tikzOptions ] if $self->tikzOptions ne '';
	return [ &$self('environment', $environment), '' ] if ref(&$self('environment', $environment)) ne 'ARRAY';
	return &$self('environment', $environment);
}

# Set TikZ picture options as a single string parameter.
sub tikzOptions {
	my ($self, $tikzOptions) = @_;
	return &$self('tikzOptions', $tikzOptions);
}

# Set additional TikZ libraries to load as a single string parameter.
sub tikzLibraries {
	my ($self, $tikzLibraries) = @_;
	return &$self('tikzLibraries', $tikzLibraries);
}

# Set additional TeX packages to load.  This accepts an array parameter.  Note
# that each element of this array should either be a string or an array with one
# or two elements (the first element the package name, and the optional second
# element the package options).
sub texPackages {
	my ($self, $texPackages) = @_;
	return &$self('texPackages', $texPackages) if ref($texPackages) eq 'ARRAY';
	return &$self('texPackages');
}

# Additional TeX commands to add to the TeX preamble
sub addToPreamble {
	my ($self, $additionalPreamble) = @_;
	return &$self('addToPreamble', $additionalPreamble);
}

# Set the image type.  The valid types are 'png', 'gif', 'svg', 'pdf', and 'tgz'.
# The 'pdf' option should be set for print.
# The 'tgz' option should be set when 'PTX' is the display mode.
# It creates a .tgz file containing .tex, .pdf, .png, and .svg versions of the image
sub ext {
	my ($self, $ext) = @_;
	return &$self('ext', $ext);
}

# Set the method to use to generate svg images.  The valid methods are 'pdf2svg' and 'dvisvgm'.
sub svgMethod {
	my ($self, $svgMethod) = @_;
	return &$self('svgMethod', $svgMethod);
}

# Set the options to be used by ImageMagick convert.
sub convertOptions {
	my ($self, $convertOptions) = @_;
	return &$self('convertOptions', $convertOptions);
}

# Set the file name.
sub imageName {
	my ($self, $imageName) = @_;
	return &$self('imageName', $imageName);
}

sub header {
	my $self = shift;
	my @output;
	push(@output, "\\documentclass{standalone}\n");
	my @xcolorOpts = grep { ref $_ eq "ARRAY" && $_->[0] eq "xcolor" && defined $_->[1] } @{ $self->texPackages };
	my $xcolorOpts = @xcolorOpts ? $xcolorOpts[0][1] : 'svgnames';
	push(@output, "\\usepackage[$xcolorOpts]{xcolor}\n");
	# Load tikz if environment is tikzpicture, but not if texPackages contains tikz already
	push(@output, "\\usepackage{tikz}\n")
		if ($self->environment->[0] eq 'tikzpicture'
			&& !grep { (ref $_ eq "ARRAY" && $_->[0] eq 'tikz') || $_ eq 'tikz' } @{ $self->texPackages });
	push(
		@output,
		map {
			"\\usepackage"
				. (ref $_ eq "ARRAY" && @$_ > 1 && $_->[1] ne "" ? "[$_->[1]]" : "") . "{"
				. (ref $_ eq "ARRAY"                             ? $_->[0]     : $_) . "}\n"
		} grep { (ref $_ eq "ARRAY" && $_->[0] ne 'xcolor') || $_ ne 'xcolor' } @{ $self->texPackages }
	);
	push(@output, "\\usetikzlibrary{" . $self->tikzLibraries . "}") if ($self->tikzLibraries ne "");
	push(@output, $self->addToPreamble);
	push(@output, "\\begin{document}\n");
	if ($self->environment->[0]) {
		push(@output, "\\begin{", $self->environment->[0] . "}");
		push(@output, "[" . $self->environment->[1] . "]")
			if (defined $self->environment->[1] && $self->environment->[1] ne "");
		push(@output, "\n");
	}
	return @output;
}

sub footer {
	my $self = shift;
	my @output;
	push(@output, "\\end{", $self->environment->[0] . "}\n") if $self->environment->[0];
	push(@output, "\\end{document}\n");
	return @output;
}

# Generate the image file and return the stored location of the image.
sub draw {
	my $self = shift;

	my $working_dir = WeBWorK::PG::ImageGenerator::makeTempDirectory(WeBWorK::PG::IO::pg_tmp_dir(), "latex");

	my $ext       = $self->ext;
	my $svgMethod = $self->svgMethod;

	# Create either one or two tex files with one small difference:
	# set pgfsysdriver to pgfsys-dvisvgm.def for a tex file that dvisvgm will use
	# Then make only the dvi, only the pdf, or both in case we are making tgz with svg via dvisvgm
	if (($ext eq 'svg' || $ext eq 'tgz') && $svgMethod eq 'dvisvgm') {
		if (open(my $fh, ">", "$working_dir/image-dvisvgm.tex")) {
			my @header = $self->header;
			splice @header, 1, 0, "\\def\\pgfsysdriver{pgfsys-dvisvgm.def}\n";
			chmod(0777, "$working_dir/image-dvisvgm.tex");
			print $fh @header;
			print $fh $self->tex =~ s/\\\\/\\/gr . "\n";
			print $fh $self->footer;
			close $fh;
			system "cd $working_dir && "
				. WeBWorK::PG::IO::externalCommand('latex')
				. " --interaction=nonstopmode image-dvisvgm.tex > latex.stdout 2> /dev/null";
			move("$working_dir/image-dvisvgm.dvi", "$working_dir/image.dvi");
			chmod(0777, "$working_dir/image.dvi");
		} else {
			warn "Can't open $working_dir/image-dvisvgm.tex for writing.";
			return '';
		}
	}
	if ($ext ne 'svg' || ($ext eq 'svg' && $svgMethod ne 'dvisvgm')) {
		if (open(my $fh, ">", "$working_dir/image.tex")) {
			chmod(0777, "$working_dir/image.tex");
			print $fh $self->header;
			print $fh $self->tex =~ s/\\\\/\\/gr . "\n";
			print $fh $self->footer;
			close $fh;
			system "cd $working_dir && "
				. WeBWorK::PG::IO::externalCommand('pdflatex')
				. " --interaction=nonstopmode image.tex > pdflatex.stdout 2> /dev/null";
			chmod(0777, "$working_dir/image.pdf");
		} else {
			warn "Can't open $working_dir/image.tex for writing.";
			return '';
		}
	}

	# Make derivatives of the dvi
	if (($ext eq 'svg' || $ext eq 'tgz') && $svgMethod eq 'dvisvgm') {
		if (-r "$working_dir/image.dvi") {
			$self->use_svgMethod($working_dir);
		} else {
			warn "The dvi file was not created.";
			if (open(my $err_fh, "<", "$working_dir/latex.stdout")) {
				while (my $error = <$err_fh>) {
					warn $error;
				}
				close($err_fh);
			}
		}
	}

	# Make derivatives of the pdf
	if (($svgMethod ne 'dvisvgm' || $ext ne 'svg') && $ext ne 'pdf') {
		if (-r "$working_dir/image.pdf") {
			if (($ext eq 'svg' || $ext eq 'tgz') && $svgMethod ne 'dvisvgm') {
				$self->use_svgMethod($working_dir);
			}
			if ($ext eq 'tgz') {
				$self->use_convert($working_dir, "png");
			} elsif ($ext ne 'svg' && $ext ne 'pdf') {
				$self->use_convert($working_dir, $ext);
			}
		} else {
			warn "The pdf file was not created.";
			if (open(my $err_fh, "<", "$working_dir/pdflatex.stdout")) {
				while (my $error = <$err_fh>) {
					warn $error;
				}
				close($err_fh);
			}
		}
	}

	# Make the tgz
	if ($ext eq 'tgz') {
		system "cd $working_dir && "
			. WeBWorK::PG::IO::externalCommand('tar')
			. " -czf image.tgz image.tex image.pdf image.svg image.png > /dev/null 2>&1";
		warn "Failed to generate tgz file." unless -r "$working_dir/image.tgz";
	}

	my $data;

	# Read the generated image file into memory
	if (-r "$working_dir/image.$ext") {
		open(my $in_fh, "<", "$working_dir/image.$ext")
			or warn "Failed to open $working_dir/image.$ext for reading.", return;
		local $/;
		$data = <$in_fh>;
		close($in_fh);
	} else {
		warn "Image file production failed.";
	}

	# Delete the files used to generate the image.
	WeBWorK::PG::IO::remove_tree($working_dir) if -e $working_dir;

	return $data;
}

sub use_svgMethod {
	my ($self, $working_dir) = @_;
	if ($self->svgMethod eq 'dvisvgm') {
		system WeBWorK::PG::IO::externalCommand('dvisvgm')
			. " $working_dir/image.dvi --no-fonts --output=$working_dir/image.svg > /dev/null 2>&1";
	} else {
		system WeBWorK::PG::IO::externalCommand($self->svgMethod)
			. " $working_dir/image.pdf $working_dir/image.svg > /dev/null 2>&1";
	}
	warn "Failed to generate svg file." unless -r "$working_dir/image.svg";

	return;
}

sub use_convert {
	my ($self, $working_dir, $ext) = @_;
	system WeBWorK::PG::IO::externalCommand('convert')
		. join('', map { " -$_ " . $self->convertOptions->{input}->{$_} } (keys %{ $self->convertOptions->{input} }))
		. " $working_dir/image.pdf"
		. join('', map { " -$_ " . $self->convertOptions->{output}->{$_} } (keys %{ $self->convertOptions->{output} }))
		. " $working_dir/image.$ext > /dev/null 2>&1";
	warn "Failed to generate $ext file." unless -r "$working_dir/image.$ext";

	return;
}

1;
