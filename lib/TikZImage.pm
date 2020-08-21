#!/bin/perl
################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2018 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/parserMultiAnswer.pl,v 1.11 2009/06/25 23:28:44 gage Exp $
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
# simple images using TikZ, and converting them into a web-useable format.  Its
# typical usage is via the macro PGtikz.pl and is documented there.

use strict;
use warnings;
use Carp;
use WeBWorK::PG::IO;
use WeBWorK::PG::ImageGenerator;

package TikZImage;

# The constructor (it takes no parameters)
sub new {
	my $class = shift;
	my $data = {
		tex           => '',
		tikzOptions   => '',
		tikzLibraries => '',
		ext           => 'png',
        imageName     => ''
	};
	my $self = sub {
		my $field = shift;
		if (@_) {
			# The ext field is protected to ensure that unsafe commands can not
			# be passed to the command line in the system call it is used in.
			if ($field eq 'ext') {
				my $ext = shift;
				$data->{ext} = $ext
				if ($ext eq 'png' || $ext eq 'gif' || $ext eq 'svg' || $ext eq 'pdf');
			}
			else {
				$data->{$field} = shift;
			}
		}
		return $data->{$field};
	};
	return bless $self, $class;
}

# Accessors

# Set TikZ image code, not including begin and end tags, as a single
# string parameter.  Works best single quoted.
sub tex {
	my $self = shift;
	return &$self('tex', @_);
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

# Set the image type.  The valid types are 'png', 'gif', 'svg', and 'pdf'.
# The 'pdf' option should be set for print.
sub ext {
	my $self = shift;
	return &$self('ext', @_);
}

# Set the file name.
sub imageName {
	my $self = shift;
	return &$self('imageName', @_);
}

sub header {
	my $self = shift;
	my @output = ();
	push(@output, "\\documentclass{standalone}\n");
	push(@output, "\\usepackage{tikz}\n");
	push(@output, "\\usetikzlibrary{" . $self->tikzLibraries . "}") if ($self->tikzLibraries ne "");
	push(@output, "\\begin{document}\n");
	push(@output, "\\begin{tikzpicture}");
	push(@output, "[" . $self->tikzOptions . "]") if ($self->tikzOptions ne "");
	@output;
}

sub footer {
	my $self = shift;
	my @output = ();
	push(@output, "\\end{tikzpicture}\n");
	push(@output, "\\end{document}\n");
	@output;
}

# Generate the image file and return the stored location of the image.
sub draw {
	my $self = shift;

	my $working_dir = WeBWorK::PG::ImageGenerator::makeTempDirectory(WeBWorK::PG::IO::ww_tmp_dir(), "tikz");
	my $data;

	my $fh;
	open($fh, ">", "$working_dir/image.tex")
		or warn "Can't open $working_dir/image.tex for writing.";
	chmod(0777, "$working_dir/image.tex");
	print $fh $self->header;
	print $fh $self->tex . "\n";
	print $fh $self->footer;
	close $fh;

	my $pdflatex_command = "cd " . $working_dir . " && " .
		WeBWorK::PG::IO::pdflatexCommand() . " > pdflatex.stdout 2> pdflatex.stderr image.tex";

	# Generate the pdf file.
	system "$pdflatex_command";
	if (-r "$working_dir/image.pdf" ) {
		my $ext = $self->ext;

		# Convert the file to the appropriate type of image file
		system WeBWorK::PG::IO::convertCommand() . " $working_dir/image.pdf $working_dir/image.$ext"
		if $ext ne 'pdf';

		if (-r "$working_dir/image.$ext") {
			# Read the generated image file into memory
			open(my $in_fh,  "<", "$working_dir/image.$ext")
				or warn "Failed to open $working_dir/image.$ext for reading.", return;
			local $/;
			$data = <$in_fh>;
            close($in_fh);
		} else {
			warn "Convert operation failed.";
		}
	} else {
		warn "File $working_dir/image.pdf was not created.";
		if (open(my $err_fh, "<", "$working_dir/pdflatex.stdout"))
		{
			while (my $error = <$err_fh>) {
				warn $error;
			}
			close($err_fh);
		}
	}

	# Delete the files used to generate the image.
	if (-e $working_dir) {
		system "rm -rf $working_dir";
	}

	return $data;
}

1;
