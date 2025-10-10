
=head1 AXES OBJECT

This is a hash to store information about the axes (ticks, range, grid, etc)
with some helper methods. The hash is further split into three smaller hashes:
xaxis, yaxis, and styles.

=over 5

=item xaxis

Hash of data for the horizontal axis.

=item yaxis

Hash of data for the vertical axis.

=item styles

Hash of data for options for the general axis.

=back

=head1 USAGE

The axes object should be accessed through a Plots object using C<< $plot->axes >>.
The axes object is used to configure and retrieve information about the axes,
as in the following examples.

Each axis and styles can be configured individually, such as:

    $plot->axes->xaxis(min => -10, max => 10,  tick_delta => 4);
    $plot->axes->yaxis(min => 0,   max => 100, tick_delta => 20);
    $plot->axes->style(aria_label => 'Graph of function y = f(x).', show_grid => 0);

This can be combined using the set method by prepending either C<x> or C<y> in front
of each key of the axes to configure (note keys that do not start with C<x> or C<y>
sent to C<< $plot->axes->style >>):

    $plot->axes->set(
        xmin        => -10,
        xmax        => 10,
        xtick_delta => 4,
        ymin        => 0,
        ymax        => 100,
        ytick_delta => 20,
        aria_label  => 'Graph of function y = f(x).',
        show_grid   => 0,
    );

The same methods also get the value of a single option, such as:

    $xmin        = $plot->axes->xaxis('min');
    $ytick_delta = $plot->axes->yaxis('tick_delta');
    $show_grid   = $plot->axes->style('show_grid');

The methods without any inputs return a reference to the full hash, such as:

    $xaxis  = $plot->axes->xaxis;
    $styles = $plot->axes->style;

It is also possible to get multiple options for both axes using the get method, which returns
a reference to a hash of requested keys, such as:

    $bounds = $plot->axes->get('xmin', 'xmax', 'ymin', 'ymax');
    # The following is equivlant to $plot->axes->grid
    $grid = $plot->axes->get('xmajor', 'xminor', 'xtick_delta', 'ymajor', 'yminor', 'ytick_delta');

It is also possible to get the bounds as an array in the order xmin, ymin, xmax, ymax
using the C<< $plot->axes->bounds >> method.

=head1 AXIS CONFIGURATION OPTIONS

Each axis (the xaxis and yaxis) has the following configuration options:

=over 5

=item min

The minimum value the axis shows. Default is -5.

=item max

The maximum value the axis shows. Default is 5.

=item tick_num

This is the number of major tick marks to include on the axis. This number is used
to compute the C<tick_delta> as the difference between the C<max> and C<min> values
and the number of ticks. Note that this is only used if C<tick_delta> is zero
and C<tick_distance> is undefined.  Default: 5.

=item tick_delta

This is the distance between each major tick mark, starting from the origin.  If
this is set to 0 and C<tick_distance> is not 0, then this distance is computed
to be the product of the C<tick_distance> and the C<tick_scale>, and if this is
set to 0 and C<tick_distance> is undefined then this is computed to be the
difference between the C<max> and C<min> divided by the C<tick_num>. Default: 0

=item tick_labels

This can be either 1 (show) or 0 (don't show) the labels for the major ticks.
Default: 1

=item tick_label_format

This can be one of "decimal", "fraction", "multiple", or "scinot".  If this is
"decimal", then tick labels will be displayed in decimal format.  If this is
"fraction", then tick labels will be displayed as (improper) fractions.  If this
is "mixed", then tick labels will be displayed as mixed numbers. If this is
"scinot", then tick labels will be displayed in scientific notation. Default:
"decimal"

=item tick_label_digits

The number of decimal places to round tick labels to when the
C<tick_label_format> is "decimal" or "scinot". Default: 2

=item tick_distance

This is the unscaled distance between each major tick mark starting from the
origin when the axis is scaled by the C<tick_scale> factor. If this is 0, then
this will be computed to be the C<tick_delta> divided by the C<tick_scale>.
Default: 0

=item tick_scale

This is used in combination with the C<tick_distance> above to calculate the
C<tick_delta>.  Default: 1

=item tick_scale_symbol

This is appended to major tick labels.  Default: ''

=item show_ticks

This can be either 1 (show) or 0 (don't show) the tick lines. If ticks are
not shown then tick labels won't be shown either. Default: 1

=item label

The axis label. Defaults are C<\(x\)> and C<\(y\)>.

=item major

Show (1) or don't show (0) grid lines at the tick marks. Default is 1.

=item minor

This sets the number of minor ticks (and minor grid lines if minor_grids is 1)
per major tick. If this is set to 0, no minor ticks are shown. Default: 3

=item minor_grids

If this is 1, then grid lines are shown at minor ticks, and if this is 0, then
grid lines are not shown at minor ticks. Default: 1

=item visible

This sets if the axis is shown (1) or not (0) on the plot. Default is 1.

=item location

This sets the location of the axes relative to the graph. The possible options
for each axis are:

    xaxis  =>  'top', 'middle', 'bottom'
    yaxis  =>  'left', 'center', 'right'

This places the axis at the appropriate edge of the graph. If 'center' or 'middle'
are used, the axes appear on the inside of the graph at the appropriate axis position.
Default 'middle' or 'center'.

=item position

The position in terms of the appropriate variable to draw the axis if the location is
set to 'middle' or 'center'. Default is 0.

=item jsx_options

A hash reference of options to be passed to the JSXGraph axis object.

=item jsx_grid_options

A hash reference of options to be passed to the JSXGraph grid object. Note that
the grid is implemented as an axis with ticks the extend to infinity. So the
options are really JSXGraph axis options.

=back

=head1 STYLES

The following styles configure aspects about the axes.

=over 5

=item aspect_ratio

If this style is set, then the height of the graph will be computed using
this aspect_ratio for the size of the image unless explicitly set.
Default: ''

=item aria_label

The ARIA label in JSX graph output. Default is 'Graph'.

=item aria_description

The ARIA description in JSX graph output. This will be set to the images alt tag.
Default is 'Generated graph'.

=item show_grid

Either draw (1) or don't draw (0) the grid lines for the axis. Default is 1.

=item grid_color

The color of the grid lines. Default is 'gray'.

=item grid_alpha

The alpha value to use to draw the grid lines in Tikz. This is a number from
0 (fully transparent) to 100 (fully solid). Default is 40.

=item axis_on_top

Configures if the Tikz axis should be drawn on top of the graph (1) or below the graph (0).
Useful when filling a region that covers an axis, if the axis are on top they will still
be visible after the fill, otherwise the fill will cover the axis. Default: 0

Note that this setting is not honored for the JSXGraph image type.

This is not the best way of ensuring that axis elements are not covered by a
fill. If this is used, then not only is the fill region placed behind the axis
and the grid, but all graphed elements are behind the axis and the grid which is
usually not desirable. A better way is to use the "axis background" C<layer> to
only place the fill on the "axis background" layer, and leave everything else on
top of the axis.

=item axes_arrows_both

Configures if arrows should be drawn in both directions (1) or only in the
positive direction (0) at the axes ends. In other words, this is a choice
between the convention that arrows are meant to indicate that the axes lines
continue forever, or the convention that arrows are meant to indicate the
positive direction of the axes only.  Default: 0

=item mathjax_tick_labels

If this is 1, then tick labels will be displayed using MathJax.  If this is 0,
then ticks will be displayed as basic text.  This only applies to the JSXGraph
output type. Default: 1

=item jsx_navigation

Either allow (1) or don't allow (0) the user to pan and zoom the view port of the
JSXGraph.  Best used when plotting functions with the C<continue> style. Note that if this
option is 0, then the image can be clicked on to open a dialog showing a magnified version
of the graph that can be zoomed in or out.  Default: 0

=item jsx_options

A hash reference of options to be passed to the JSXGraph board object.

=item tikz_options

Additional options to be passed to the pgfplots axis definition. This should be
a single string.  For example, to make longer and thicker x axis ticks use

    tikz_options => 'x tick style={line width=2pt},major tick length=0.6cm'

=back

=cut

package Plots::Axes;

use strict;
use warnings;

sub new {
	my ($class, @options) = @_;
	my $self = bless {
		xaxis  => {},
		yaxis  => {},
		styles => {
			aria_label          => 'Graph',
			aria_description    => 'Generated graph',
			grid_color          => 'gray',
			grid_alpha          => 40,
			show_grid           => 1,
			axis_on_top         => 0,
			axes_arrows_both    => 0,
			mathjax_tick_labels => 1,
		},
		@options
	}, $class;

	$self->xaxis($self->axis_defaults('x'));
	$self->yaxis($self->axis_defaults('y'));
	return $self;
}

sub axis_defaults {
	my ($self, $axis) = @_;
	return (
		visible           =>  1,
		min               => -5,
		max               =>  5,
		label             => $axis eq 'y' ? '\(y\)'  : '\(x\)',
		location          => $axis eq 'y' ? 'center' : 'middle',
		position          => 0,
		tick_labels       => 1,
		tick_label_format => 'decimal',
		tick_label_digits => 2,
		tick_distance     => 0,
		tick_scale        => 1,
		tick_scale_symbol => '',
		show_ticks        => 1,
		tick_delta        => 0,
		tick_num          => 5,
		major             => 1,
		minor             => 3,
		minor_grids       => 1
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
	# Deal with the tick_delta and tick_distance individually since they may need to be computed.
	return
		$item eq 'tick_delta'      ? $self->tick_delta($self->{$axis})
		: $item eq 'tick_distance' ? $self->tick_distance($self->{$axis})
		:                            $self->{$axis}{$item};
}

sub xaxis {
	my ($self, @items) = @_;
	return $self->axis('xaxis', @items);
}

sub yaxis {
	my ($self, @items) = @_;
	return $self->axis('yaxis', @items);
}

sub set {
	my ($self, %options) = @_;
	my (%xopts, %yopts, %styles);
	for (keys %options) {
		if ($_ =~ s/^x//) {
			$xopts{$_} = $options{"x$_"};
		} elsif ($_ =~ s/^y//) {
			$yopts{$_} = $options{"y$_"};
		} else {
			$styles{$_} = $options{$_};
		}
	}
	$self->xaxis(%xopts)  if %xopts;
	$self->yaxis(%yopts)  if %yopts;
	$self->style(%styles) if %styles;
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
		} else {
			$options{$_} = $self->style($_);
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

sub tick_delta {
	my ($self, $axis) = @_;
	return $axis->{tick_delta} if $axis->{tick_delta};
	if ($axis->{tick_distance}) {
		$axis->{tick_delta} = $axis->{tick_distance} * ($axis->{tick_scale} || 1);
	} elsif ($axis->{tick_num}) {
		$axis->{tick_delta} = ($axis->{max} - $axis->{min}) / $axis->{tick_num};
	} else {
		$axis->{tick_delta} = 2;
	}
	return $axis->{tick_delta};
}

sub tick_distance {
	my ($self, $axis) = @_;
	return $axis->{tick_distance} if $axis->{tick_distance};
	my $tick_delta = $self->tick_delta($axis);
	$axis->{tick_distance} = $axis->{tick_delta} / ($axis->{tick_scale} || 1);
	return $axis->{tick_distance};
}

sub grid {
	my $self = shift;
	return $self->get('xmajor', 'xminor_grids', 'xminor', 'xtick_delta', 'ymajor', 'yminor_grids', 'yminor',
		'ytick_delta');
}

sub bounds {
	my $self = shift;
	return $self->{xaxis}{min}, $self->{yaxis}{min}, $self->{xaxis}{max}, $self->{yaxis}{max};
}

1;
