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
# typical usage is via the macro PGtikz.pl and is documented there.

use strict;
use warnings;
use Carp;
use WeBWorK::PG::IO;
use WeBWorK::PG::ImageGenerator;

package LaTeXImage;

# The constructor (it takes no parameters)
sub new {
	my $class = shift;
	my $data  = {
		tex         => '',
		environment => '',
		# if tikzOptions is nonempty, then environment
		# will effectively be ['tikzpicture', tikzOptions]
		tikzOptions    => '',
		tikzLibraries  => '',
		texPackages    => [],
		addToPreamble  => '',
		ext            => 'svg',
		svgMethod      => 'pdf2svg',
		convertOptions => { input => {}, output => {} },
		imageName      => ''
	};
	my $self = sub {
		my $field = shift;
		if (@_) {
			# The ext field is protected to ensure that unsafe commands can not
			# be passed to the command line in the system call it is used in.
			if ($field eq 'ext') {
				my $ext = shift;
				$data->{ext} = $ext
					if ($ext && ($ext =~ /^(png|gif|svg|pdf|tgz)$/));
			} else {
				$data->{$field} = shift;
			}
		}
		return $data->{$field};
	};
	return bless $self, $class;
}

# Accessors

# Set LaTeX image code as a single string parameter.  Works best single quoted.
sub tex {
	my $self = shift;
	return &$self('tex', @_);
}

# Set an environment to surround the tex(). This can be a string naming the environment.
# Or it can be an array reference. The first element of this array should be the name of
# the environment. If there is a second element, it should be a string with options for
# the environment. This could be extended to support environments with multiple option
# fields that may use parentheses for delimiters.
# If tikzOptions is nonempty, the input is ignored and output is ['tikzpicture',tikzOptions].
sub environment {
	my $self = shift;
	return [ 'tikzpicture', $self->tikzOptions ] if ($self->tikzOptions ne '');
	return [ &$self('environment', @_), '' ] if (ref(&$self('environment', @_)) ne 'ARRAY');
	return &$self('environment', @_);
}

# Set TikZ picture options as a single string parameter.
sub tikzOptions {
	my $self = shift;
	return &$self('tikzOptions', @_);
}

# Set additional TikZ libraries to load as a single string parameter.
sub tikzLibraries {
	my $self = shift;
	return &$self('tikzLibraries', @_);
}

# Set additional TeX packages to load.  This accepts an array parameter.  Note
# that each element of this array should either be a string or an array with one
# or two elements (the first element the package name, and the optional second
# element the package options).
sub texPackages {
	my $self = shift;
	return &$self('texPackages', $_[0]) if ref($_[0]) eq "ARRAY";
	return &$self('texPackages');
}

# Additional TeX commands to add to the TeX preamble
sub addToPreamble {
	my $self = shift;
	return &$self('addToPreamble', @_);
}

# Set the image type.  The valid types are 'png', 'gif', 'svg', 'pdf', and 'tgz'.
# The 'pdf' option should be set for print.
# The 'tgz' option should be set when 'PTX' is the display mode.
# It creates a .tgz file containing .tex, .pdf, .png, and .svg versions of the image
sub ext {
	my $self = shift;
	return &$self('ext', @_);
}

# Set the method to use to generate svg images.  The valid methods are 'pdf2svg' and 'dvisvgm'.
sub svgMethod {
	my $self = shift;
	return &$self('svgMethod', @_);
}

# Set the options to be used by ImageMagick convert.
sub convertOptions {
	my $self = shift;
	return &$self('convertOptions', @_);
}

# Set the file name.
sub imageName {
	my $self = shift;
	return &$self('imageName', @_);
}

sub header {
	my $self   = shift;
	my @output = ();
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
	@output;
}

sub footer {
	my $self   = shift;
	my @output = ();
	push(@output, "\\end{", $self->environment->[0] . "}\n") if $self->environment->[0];
	push(@output, "\\end{document}\n");
	@output;
}

# Generate the image file and return the stored location of the image.
sub draw {
	my $self = shift;

	my $working_dir = WeBWorK::PG::ImageGenerator::makeTempDirectory(WeBWorK::PG::IO::pg_tmp_dir(), "latex");
	my $data;

	my $ext       = $self->ext;
	my $svgMethod = $self->svgMethod;

	my $fh;

	# Create either one or two tex files with one small difference:
	# set pgfsysdriver to pgfsys-dvisvgm.def for a tex file that dvisvgm will use
	# Then make only the dvi, only the pdf, or both in case we are making tgz with svg via dvisvgm
	if (($ext eq 'svg' || $ext eq 'tgz') && $svgMethod eq 'dvisvgm') {
		open($fh, ">", "$working_dir/image-dvisvgm.tex")
			or warn "Can't open $working_dir/image-dvisvgm.tex for writing.";
		my @header = $self->header;
		splice @header, 1, 0, "\\def\\pgfsysdriver{pgfsys-dvisvgm.def}\n";
		chmod(0777, "$working_dir/image-dvisvgm.tex");
		print $fh @header;
		print $fh $self->tex =~ s/\\\\/\\/gr . "\n";
		print $fh $self->footer;
		close $fh;
		system "cd $working_dir && "
			. WeBWorK::PG::IO::externalCommand('latex')
			. " --interaction=nonstopmode image-dvisvgm.tex > latex.stdout 2> /dev/null && "
			. WeBWorK::PG::IO::externalCommand('mv')
			. " image-dvisvgm.dvi image.dvi";
		chmod(0777, "$working_dir/image.dvi");
	}
	if ($ext ne 'svg' || ($ext eq 'svg' && $svgMethod ne 'dvisvgm')) {
		open($fh, ">", "$working_dir/image.tex")
			or warn "Can't open $working_dir/image.tex for writing.";
		chmod(0777, "$working_dir/image.tex");
		print $fh $self->header;
		print $fh $self->tex =~ s/\\\\/\\/gr . "\n";
		print $fh $self->footer;
		close $fh;
		system "cd $working_dir && "
			. WeBWorK::PG::IO::externalCommand('pdflatex')
			. " --interaction=nonstopmode image.tex > pdflatex.stdout 2> /dev/null";
		chmod(0777, "$working_dir/image.pdf");
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
	if (-e $working_dir) {
		system WeBWorK::PG::IO::externalCommand('rm') . " -rf $working_dir";
	}

	return $data;
}

sub use_svgMethod {
	my $self        = shift;
	my $working_dir = shift;
	if ($self->svgMethod eq 'dvisvgm') {
		system WeBWorK::PG::IO::externalCommand('dvisvgm')
			. " $working_dir/image.dvi --no-fonts --output=$working_dir/image.svg > /dev/null 2>&1";
	} else {
		system WeBWorK::PG::IO::externalCommand($self->svgMethod)
			. " $working_dir/image.pdf $working_dir/image.svg > /dev/null 2>&1";
	}
	warn "Failed to generate svg file." unless -r "$working_dir/image.svg";
}

sub use_convert {
	my $self        = shift;
	my $working_dir = shift;
	my $ext         = shift;
	system WeBWorK::PG::IO::externalCommand('convert')
		. join('', map { " -$_ " . $self->convertOptions->{input}->{$_} } (keys %{ $self->convertOptions->{input} }))
		. " $working_dir/image.pdf"
		. join('', map { " -$_ " . $self->convertOptions->{output}->{$_} } (keys %{ $self->convertOptions->{output} }))
		. " $working_dir/image.$ext > /dev/null 2>&1";
	warn "Failed to generate $ext file." unless -r "$working_dir/image.$ext";
}

1;
