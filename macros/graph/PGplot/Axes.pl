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

PGplot/Axes.pl - Object used with PGplot to store data about a plot's title and axes.

=head1 DESCRIPTION

This is a hash to store information about the axes (ticks, range, grid, etc)
with some helper methods. The hash is further split into three smaller hashes:

=over 5

=item xaxis

Hash of data for the horizontal axis.

=item yaxis

Hash of data for the vertical axis.

=item styles

Hash of data for options for the general axis.

=back

=head1 USAGE

The axes object should be accessed through a L<PGplot|PGplot.pl> object using C<$plot-E<gt>axes>.
The axes object is used to configure and retrieve information about the axes,
as in the following examples.

Each axis can be configured individually, such as:

    $plot->axes->xaxis(min => -10, max => 10, ticks => [-12, -8, -4, 0, 4, 8, 12]);
    $plot->axes->yaxis(min => 0, max => 100, ticks => [20, 40, 60, 80, 100]);

This can also be combined using the set method, such as:

    $plot->axes->set(
        xmin   => -10,
        xmax   => 10,
        xticks => [-12, -8, -4, 0, 4, 8, 12],
        ymin   => 0,
        ymax   => 100,
        yticks => [20, 40, 60, 80, 100]
    );

In addition to the configuration each axis, there is a set of styles that apply to both axes.
These are access via the style method. To set one or more styles use:

    $plot->axes->style(title => '\(y = f(x)\)', show_grid => 0);

The same methods also get the value of a single option, such as:

    $xmin   = $plot->axes->xaxis('min');
    $yticks = $plot->axes->yaxis('ticks');
    $title  = $plot->axes->style('title');

The methods without any inputs return a reference to the full hash, such as:

    $xaxis  = $plot->axes->xaxis;
    $styles = $plot->axes->style;

It is also possible to get multiple options for both axes using the get method, which returns
a reference to a hash of requested keys, such as:

    $bounds = $plot->axes->get('xmin', 'xmax', 'ymin', 'ymax');
    # The following is equivlant to $plot->axes->grid
    $grid = $plot->axes->get('xmajor', 'xminor', 'xticks', 'ymajor', 'yminor', 'yticks');

It is also possible to get the bounds as an array in the order xmin, ymin, xmax, ymax
using the C<$plot-E<gt>axes-E<gt>bounds> method.

=head1 AXIS CONFIGURATION OPTIONS

Each axis (the xaxis and yaxis) has the following configuration options:

=over 5

=item min

The minimum value the axis shows. Default is -5.

=item max

The maximum value the axis shows. Default is 5.

=item ticks

An array which lists the major tick marks. If this array is empty, the ticks are
generated using either C<tick_delta> or C<tick_num>. Default is C<[]>.

=item tick_delta

This is the distance between each major tick mark, starting from the origin.
This distance is then used to generate the tick marks if the ticks array is empty.
If this is set to 0, this distance is set by using the number of ticks, C<tick_num>.
Default is 0.

=item tick_num

This is the number of major tick marks to include on the axis. This number is used
to compute the C<tick_delta> as the difference between the C<max> and C<min> values
and the number of ticks. Default: 5. 

=item label

The axis label. Defaults are C<\(x\)> and C<\(y\)>.

=item major

Show (1) or don't show (0) grid lines at the tick marks. Default is 1.

=item minor

This sets the number of minor grid lines per major grid line. If this is
set to 0, no minor grid lines are shown. Default is 3.

=item visible

This sets if the axis is shown (1) or not (0) on the plot. Default is 1.

=item location

This sets the location of the axes relative to the graph. The possible options
for each axis are:

    xaxis  =>  'box', 'top', 'middle', 'bottom'
    yaxis  =>  'box', 'left', 'center', 'right'

This places the axis at the appropriate edge of the graph. If 'center' or 'middle'
are used, the axes appear on the inside of the graph at the appropriate position.
Setting the location to 'box' creates a box or framed pot. Default 'middle' or 'center'.

=item position

The position in terms of the appropriate variable to draw the axis if the location is
set to 'middle' or 'center'. Default is 0.

=back

=head1 STYLES

The following styles configure aspects about the axes:

=over 5

=item title

The title of the graph. Default is ''.

=item show_grid

Either draw (1) or don't draw (0) the grid lines for the axis. Default is 1.

=item grid_color

The color of the grid lines. Default is 'gray'.

=item grid_style

The line style of grid lines. This can be 'dashed', 'dotted', 'solid', etc.
Default is 'solid'.

=item grid_alpha

The alpha value to use to draw the grid lines in Tikz. This is a number from
0 (fully transparent) to 100 (fully solid). Default is 40.

=item axis_on_top

Configures if the axis should be drawn on top of the graph (1) or below the graph (0).
Useful when filling a region that covers an axis, if the axis are on top they will still
be visible after the fill, otherwise the fill will cover the axis. Default: 0

=back

=cut

BEGIN {
	strict->import;
}

sub _Axes_init { }

package PGplot::Axes;

sub new {
	my $class = shift;
	my $self  = {
		xaxis  => {},
		yaxis  => {},
		styles => {
			title      => '',
			grid_color => 'gray',
			grid_style => 'solid',
			grid_alpha => 40,
			show_grid  => 1,
		},
		@_
	};

	bless $self, $class;
	$self->xaxis($self->axis_defaults('x'));
	$self->yaxis($self->axis_defaults('y'));
	return $self;
}

sub axis_defaults {
	my ($self, $axis) = @_;
	return (
		visible    => 1,
		min        => -5,
		max        => 5,
		label      => $axis eq 'y' ? '\(y\)'  : '\(x\)',
		location   => $axis eq 'y' ? 'center' : 'middle',
		position   => 0,
		ticks      => undef,
		tick_delta => 0,
		tick_num   => 5,
		major      => 1,
		minor      => 3,
	);
}

sub axis {
	my ($self, $axis, @items) = @_;
	return $self->{$axis} unless @items;
	if (scalar(@items) > 1) {
		my %item_hash = @items;
		map { $self->{$axis}{$_} = $item_hash{$_}; } (keys %item_hash);
		return;
	}
	my $item = $items[0];
	if (ref($item) eq 'HASH') {
		map { $self->{$axis}{$_} = $item->{$_}; } (keys %$item);
		return;
	}
	# Deal with ticks individually since they may need to be generated.
	return $item eq 'ticks' ? $self->{$axis}{ticks} || $self->gen_ticks($self->axis($axis)) : $self->{$axis}{$item};
}

sub xaxis {
	my $self = shift;
	return $self->axis('xaxis', @_);
}

sub yaxis {
	my $self = shift;
	return $self->axis('yaxis', @_);
}

sub set {
	my ($self, %options) = @_;
	my (%xopts, %yopts);
	for (keys %options) {
		if ($_ =~ s/^x//) {
			$xopts{$_} = $options{"x$_"};
		} elsif ($_ =~ s/^y//) {
			$yopts{$_} = $options{"y$_"};
		}
	}
	$self->xaxis(%xopts) if %xopts;
	$self->yaxis(%yopts) if %yopts;
	return;
}

sub get {
	my ($self, @keys) = @_;
	my %options;
	for (@keys) {
		if ($_ =~ s/^x//) {
			$options{"x$_"} = $self->xaxis($_);
		} elsif ($_ =~ s/^y//) {
			$options{"y$_"} = $self->yaxis($_);
		}
	}
	return \%options;
}

sub style {
	my ($self, @styles) = @_;
	return $self->{styles} unless @styles;
	if (scalar(@styles) > 1) {
		my %style_hash = @styles;
		map { $self->{styles}{$_} = $style_hash{$_}; } (keys %style_hash);
		return;
	}
	my $style = $styles[0];
	if (ref($style) eq 'HASH') {
		map { $self->{styles}{$_} = $style->{$_}; } (keys %$style);
		return;
	}
	return $self->{styles}{$style};
}

sub gen_ticks {
	my ($self, $axis) = @_;
	my $min   = $axis->{min};
	my $max   = $axis->{max};
	my $delta = $axis->{tick_delta};
	$delta = ($max - $min) / $axis->{tick_num} unless $delta;

	my @ticks = $min <= 0 && $max >= 0 ? (0) : ();
	my $point = $delta;
	# Adjust min/max to place one more tick beyond the graph's edge.
	$min -= $delta;
	$max += $delta;
	do {
		push(@ticks, $point)     unless $point < $min  || $point > $max;
		unshift(@ticks, -$point) unless -$point < $min || -$point > $max;
		$point += $delta;
	} until (-$point < $min && $point > $max);
	return \@ticks;
}

sub grid {
	my $self = shift;
	return $self->get('xmajor', 'xminor', 'xticks', 'ymajor', 'yminor', 'yticks');
}

sub bounds {
	my $self = shift;
	return $self->{xaxis}{min}, $self->{yaxis}{min}, $self->{xaxis}{max}, $self->{yaxis}{max};
}

1;
