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

LiveGraphics3D.pl - provides the ability to have an interactive 3D plot.

=head1 DESCRIPTION

Macros for handling interactive 3D graphics.

This parses LiveGraphics3D data into L<Plotly|https://plotly.com/javascript>
traces. See L<https://www-users.cse.umn.edu/~rogness/lg3d/mma_syntax.html> for
information about the Mathematica syntax of the LiveGraphics3D format. Note that
not all of the syntax is supported by this macro. Instead of creating this data
directly, it is recommended to use one of the other LiveGraphics PG macros that
generate this data. See L<LiveGraphicsCylindricalPlot3D.pl>,
L<LiveGraphicsParametricCurve3D.pl>, L<LiveGraphicsParametricSurface3D.pl>,
L<LiveGraphicsRectangularPlot3D.pl>, L<LiveGraphicsVectorField2D.pl>, and
L<LiveGraphicsVectorField3D.pl>.

=head1 METHODS

The following methods are provided.

=head2 LiveGraphics3D

Usage: C<LiveGraphics3D(options)>

The following options can be given.

=over

=item * C<< file => name >>

Name of the C<.m> file to load.

=item * C<< archive => name >>

Name of a C<.zip> file to load.  If this is set, then the C<file> option must
also be given, and must be set to the name of the file in the zip archive that
contains the data.

=item * C<< input => 3Ddata >>

String containing Graphics3D data to be displayed by the applet.

=item * C<< size => [w, h] >>

Width and height of applet.

=item * C<< max_ticks => n >>

Maximum number of ticks to show on the C<x>, C<y>, and C<z> axes.  This can be
given as a single positive integer, or can be a reference to an array of three
positive integers.

=item * C<< vars => [vars] >>

Hash of variables to pass as independent variables to the applet, together with
their initial values, e.g., C<< vars => [ a => 1, b => 1 ] >>.

=item * C<< background => "#RRGGBB" >>

The background color to use (default is white).

=item * C<< scale => n >>

Scaling factor for applet (default is 1).

=item * C<< image => file >>

A file containing an image to use in TeX mode.

=item * C<< tex_size => ratio >>

A scaling factor for the TeX image (as a portion of the line width).  1000 is
100%, 500 is 50%, etc.

=item * C<< tex_center => 0 or 1 >>

Whether to center the image in TeX mode.

=back

=head2 Live3Dfile

Usage: C<< Live3Dfile($file, options) >>

Load a data file.  This just calls C<LiveGraphics3D> with the C<file> option set
to C<$file>.  All other options supported by C<LiveGraphics3D> can also be
given.

=head2 Live3Ddata

Usage: C<< Live3Ddata($input, options) >>

Load raw Graphics3D data.  This just calls C<LiveGraphics3D> with the C<input>
option set to C<$input>.  All other options supported by C<LiveGraphics3D> can
also be given.

=cut

sub _LiveGraphics3D_init {
	ADD_JS_FILE('node_modules/plotly.js-dist-min/plotly.min.js',    0, { defer => undef });
	ADD_JS_FILE('node_modules/jszip/dist/jszip.min.js',             0, { defer => undef });
	ADD_JS_FILE('node_modules/jszip-utils/dist/jszip-utils.min.js', 0, { defer => undef });
	ADD_JS_FILE('js/LiveGraphics/liveGraphics.js',                  0, { defer => undef });
}

sub LiveGraphics3D {
	my %options = (
		size       => [ 250, 250 ],
		background => '#FFFFFF',
		scale      => 1,
		tex_size   => 500,
		tex_center => 0,
		max_ticks  => 6,
		@_
	);

	if ($main::displayMode eq "TeX") {
		# In TeX mode, include the image, if there is one, or
		# else give the user a message about using it on line.
		if ($options{image}) {
			my $ratio = $options{tex_size} * 0.001;
			my $out   = "\\includegraphics[width=$ratio\\linewidth]{$options{image}}";
			$out = "\\centerline{$out}" if $options{tex_center};
			$out .= "\n";
			return $out;
		} else {
			return "[ This image is created by an interactive applet. You must view it on line. ]\n";
		}
	} else {
		my ($w, $h) = @{ $options{size} };

		# Include independent variables.
		my %vars;
		%vars = @{ $options{vars} } if $options{vars};

		return tag(
			'div',
			class        => 'live-graphics-3d-container',
			style        => "width:${w}px;height:${h}px;border:1px solid black;",
			data_options => JSON->new->encode({
				width    => $w - 2,
				height   => $h - 2,
				maxTicks => $options{max_ticks},
				file     => $options{file} // '',
				input    => ($options{input} // '') =~ s/\n//gr,
				archive  => $options{archive} // '',
				vars     => \%vars
			})
		);
	}
}

# Syntactic sugar to make it easier to pass files and data to LiveGraphics3D.
sub Live3Dfile {
	my $file = shift;
	LiveGraphics3D(file => $file, @_);
}

# Syntactic sugar to make it easier to pass raw Graohics3D data to LiveGraphics3D.
sub Live3Ddata {
	my $data = shift;
	LiveGraphics3D(input => $data, @_);
}

# A message you can use for a caption under a graph.
$main::LIVEMESSAGE = MODES(
	TeX  => '',
	HTML => $BCENTER . "Drag the surface to rotate it" . $ECENTER
);

1;
