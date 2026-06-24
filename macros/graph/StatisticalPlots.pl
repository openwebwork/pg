
=head1 NAME

StatisticalPlots.pl - A macro to create statistical plots to include in PG
problems.

=head1 DESCRIPTION

This macro includes a number of methods to include statistical plots in PG
problems.  This is based on L<plots.pl> which will draw using either C<TikZ>
(default for hardcopy) or C<JSXGraph> (default for HTML).

The statistical plots that are available are

=over

=item Box Plots

=item Bar Plots

=item Histograms

=item Scatter Plots

=item Pie Charts

=back

=head2 USAGE

Create a C<StatPlot> object with

    loadMacros('StatisticalPlots.pl');

    $statPlot = StatPlot(
        xmin        => -1,
        xmax        =>  8,
        ymin        => -1.5,
        ymax        =>  10,
        xtick_delta =>  1,
        ytick_delta =>  4,
        aria_label  => 'Bar plot of a set of data'
    );

The C<StatPlot> method accepts all of the same options that the C<Plot> method
from the L<plots.pl> macro accepts.

After a C<StatPlot> object is created then specific plots can be added to the
axes. For example,

    $statPlot->add_barplot(
        [ 1 .. 6 ],
        [3, 6, 7, 8, 4, 1],
        fill_color   => 'yellow',
        stroke_width => 1,
        bar_width    => 0.9
    );

will add a bar plot to the axes. See below for more details about creating a bar
plot.

=head1 AVAILABLE PLOTS

The following plots are available to add to a C<StatPlot> object.

=head2 BAR PLOTS

A bar plot can be added with the C<add_barplot> method. The general form is

    $statPlot->add_barplot($xdata, $ydata, %opts);

This adds a bar plot with bars centered at the coordinates in the array
referenced to by C<$xdata> and heights in the array referenced to by C<$ydata>.

=head3 OPTIONS

The following options which are specific to configuring the bar plot can be
passed in addition to any of the dataset options accepted by the
L<add_rectangle|plots.pl/PLOT RECTANGLES> method which draws the bars (see
L<dataset options|plots.pl/DATASET OPTIONS>).

=over

=item orientation

This can be either C<'vertical'> (default) or C<'horizontal'> to create vertical
or horizontal bars. An example with horizontal bars was given above, and the
following is an example with with vertical bars

    $statPlot->add_barplot(
        [3, 6, 7, 8, 4, 1],
        [ 1 .. 6 ],
        orientation  => 'horizontal',
        fill_color   => 'yellow',
        stroke_width => 1,
        bar_width    => 0.9
    );

=item bar_width

This is a number from C<0> to C<1> that specifies the width of the bars as a
fraction of the distance between the bar base coordinates (the x-coordinates for
a vertical bar plot or the y-coordinates for a horizontal bar plot). If
C<< bar_width => 1 >> (the default), then the bar width will be the distance
between the bar base coordinates (and so there is no gap between bars). In the
example above, with C<< bar_width => 0.9 >> the bar width will be C<90%> of the
distance between the bar base coordinates.

=item stroke_color

This sets the color of the bar borders. It is an alias for the C<color>
L<dataset option|plots.pl/DATASET OPTIONS> option of the
L<add_rectangle|plots.pl/PLOT RECTANGLES> method. See
L<color options|plots.pl/COLORS> for more details on specifying colors.

=item stroke_width

This sets the width of the rectangle borders. This is an alias for the C<width>
L<dataset option|plots.pl/DATASET OPTIONS>.

=item fill_colors

This is either the name of a color palette, a reference to an array of colors,
or a reference to a hash containing the name of a color palette
(C<palette_name>) and number of colors to generate (C<num_colors>) (see L<COLOR
PALETTES> for more information). If this is a reference to an array and the
length of the array is smaller than the number of data values in the array
referenced to by C<$data>, then the colors will be cycled.

If C<fill_color> is included in the list of options, this will apply the same
color to each bar.  If neither C<fill_color> nor C<fill_colors> is included,
then the 'rainbow' palette will be used as default.

For example,

    fill_colors => 'rainbow'

    fill_colors => ['green', 'OliveGreen', 'DarkGreen', 'ForestGreen', 'PineGreen']

    fill_colors => { palette_name => 'random', num_colors => 7 }

=back

=head2 HISTOGRAMS

An histogram can be added to a C<StatPlot> with the C<add_histogram> method. The
general form is

    $statPlot->add_histogram($data, %options);

where C<$data> is a reference to an array of univariate data. The C<%options>
parameter includes options for the histogram such as the number of bins as well
as options for drawing the bars.

The following example generates a data set using the L<urand|PGstatisticsmacros.pl/urand>
function which produces a random set of normally distributed data values, and
constructs a histogram for that data set.

    loadMacros('StatisticalPlots.pl', 'PGstatisticsmacros.pl');

    $statPlot = StatPlot(
        xmin        => 0,
        xmax        => 65,
        ymin        => 0,
        ymax        => 12,
        xtick_delta => 10,
        ytick_delta => 2
    );
    $statPlot->add_histogram(
        [ urand(30, 9, 50, 6) ],
        min        => 10,
        max        => 60,
        bins       => 10,
        fill_color => 'LightGreen',
        width      => 1
    );

=head3 Options

The following options which are specific to configuring the histogram can be
passed in addition to any of the dataset options accepted by the
L<add_rectangle|plots.pl/PLOT RECTANGLES> method which draws the bars for the
histogram (see L<dataset options|plots.pl/DATASET OPTIONS>). Note that if the
C<fill_color> option is set, then C<< fill => 'self' >> is automatically set,
and so you do not need to specify that option.

=over

=item orientation

This can be either C<'vertical'> (default) or C<'horizontal'> to create vertical
or horizontal bars.

=item min

The left edge of the leftmost bar. If not defined, the minimum value in the
C<$data> array is used.

=item max

The right edge of the rightmost bar. If not defined, the maximum value in
C<$data> is used.

=item bins

The number of bins/bars to use for the histogram. This must be an integer
greater than 0. The default value is 10.

=item normalize

If this is set to 0 (the default), then the height of each bar is the number of
data values in the bin. If this is 1, then the heights are scaled so the sum of
the heights of the bars is 1.

=item stroke_color

This sets the color of the bar borders. It is an alias for the C<color>
L<dataset option|plots.pl/DATASET OPTIONS> option of the
L<add_rectangle|plots.pl/PLOT RECTANGLES> method. See
L<color options|plots.pl/COLORS> for more details on specifying colors.

=item stroke_width

This sets the width of the rectangle borders. This is an alias for the C<width>
L<dataset option|plots.pl/DATASET OPTIONS>.

=back

=head2 BOX PLOTS

A box plot (also called a box and whiskers plot) can be created with the
C<add_boxplot> method. The general form for adding a single box plot is

   $statPlot->add_boxplot($data, %options);

or to add multiple box plots is

   $statPlot->add_boxplot([$data1, $data2, ...], %options);

where C<$data> (or C<$data1>, C<$data2>, ...) is a reference to an array of
univariate data or a reference to a hash of the box plot characteristics. Box
plots are created using the five number summary (minimum, first quartile,
median, third quartile, maximum) of the data which is calculated using the
L<five_point_summary|PGstatisticsmacros.pl/five_point_summary> method.

An example of creating a box plot with a reference to an array of univariate
data is

    $statPlot = StatPlot(
        xmin            => 0,
        xmax            => 200,
        ymin            => -5,
        ymax            =>  25,
        xtick_delta     =>  25,
        yvisible        =>  0,
        show_grid       =>  0,
        aspect_ratio    => 4,
        rounded_corners => 1
    );

    $statPlot->add_boxplot(
        [ urand(100, 25, 75, 6) ],
        fill_color   => 'LightBlue',
        stroke_width => 1
    );

If C<$data> is a hash reference, then it must contains the fields C<min, q1,
median, q3, max> that form the five number summary. Optionally, the field
C<outliers> may also be included which is a reference to an array of values
which will be plotted outside of the whiskers. For example,

    $boxplot = StatPlot(
        xmin         => 100,
        xmax         => 400,
        ymin         => -5,
        ymax         =>  25,
        xtick_delta  =>  50,
        yvisible     =>  0,
        show_grid    =>  0,
        aspect_ratio => 4
    );

    $boxplot->add_boxplot({
        min      => random(150, 175, 5),
        q1       => random(180, 225, 5),
        median   => random(250, 275, 5),
        q3       => random(280, 320, 10),
        max      => random(325, 350, 5),
        outliers => [115, 130]
    });

=head3 Options

The following options which are specific to configuring the box plot can be
passed in addition to any of the L<dataset options|plots.pl/DATASET OPTIONS>.
Note that if the C<fill_color> option is set, then C<< fill => 'self' >> is
automatically set, and so you do not need to specify that option.

=over

=item orientation

This is the direction of the box plot and can be either 'horizontal' (the
default) or 'vertical'.

=item box_center

The location of the center of the box. This is optional and if not defined the
box plot will be centered in the range of the minor axis (the y-axis for
horizontal box plots and the x-axis for vertical box plots).

If multiple box plots are being added and this option is not set, then the box
plots will be equally spaced in the range of the minor axis.

If included, this option must be a reference to an array of values (in the
x-direction for vertical plots and y-direction for horizontal plots) at which to
center the added box plots. The number of entries in the array must be the same
as the number of box plots that are being added. For example, if three box plots
are being added this could be

    box_center => [3, 6, 9]

=item box_width

The width of the box in the direction perpendicular to the orientation. The
default is to use half of the range of the minor axis.

If multiple box plots are defined, this should only be a single value.

=item whisker_cap

This should be set to 0 (default) or 1. If this value is 1, lines that are
perpendicular to the whiskers will be added at the ends of the whiskers of the
box plot. The length of the lines are determined by the C<cap_width> option.

=item cap_width

The width of the cap as a fraction of the box width. Default value is 0.2.

=item outlier_mark

The shape of the mark to use for outliers. The default is 'plus'. See the
L<dataset options|plots.pl/DATASET OPTIONS> for other mark options.

=item stroke_color

This sets the color of the boundary of the box and the whiskers. It is an alias
for the C<color> L<dataset option|plots.pl/DATASET OPTIONS>. See
L<color options|plots.pl/COLORS> for more details on specifying colors.

=item stroke_width

This sets the width of the boundary of the rectangle and the whiskers. This is
an alias for the C<width> L<dataset option|plots.pl/DATASET OPTIONS>.

=back

=head2 SCATTER PLOTS

A scatter plot can be created with the C<add_scatterplot> method. The general
form for adding a scatter plot is

    $statPlot->add_scatterplot($data, %options);

where C<$data> is a reference to an array of array references of C<x>, C<y>
pairs. For example,

    $statPlot = StatPlot(
        xmin        => -1,
        xmax        => 15,
        ymin        => -1,
        ymax        => 15,
        xtick_delta => 5,
        ytick_delta => 5,
    );

    $statPlot->add_scatterplot(
        [ [1, 1], [2, 3], [3, 4], [5, 5], [7, 8], [10, 9], [12, 10] ],
        marks     => 'diamond',
        mark_size => 5,
        color     => 'orange'
    );

This method simply calls the L<add_dataset|plots.pl/DATASETS> method with the
following L<dataset options|plots.pl/DATASET OPTIONS> set. Any of these can be
changed or any of the other data set options set in the C<%options> parameter.

=over

=item linestyle

This sets the style of the lines between the marks is set to 'none' by this
method, so that lines are not drawn between the points.

=item marks

This sets the symbol to use for the marks and is set to C<'circle'> by this
method. See the L<dataset options|plots.pl/DATASET OPTIONS> for other mark
options.

=item mark_size

This sets the size of the marks and is set to 3 by this method.

=item mark_color

This sets the color of the marks and is an alias for the C<color>
L<dataset options|plots.pl/DATASET OPTIONS> option. See L<color options|plots.pl/COLORS>
for more details on specifying colors.

=back

If more than one dataset is to be plotted, then call the C<add_scatterplot>
method multiple times. This can be done with a single C<add_dataset> method
call, but this wrapper is convenient when the default options above are desired.

=head2 PIE CHARTS

A pie chart is a circle that divided into sectors whose size is proportional to
an input array. The sectors are each assigned a color and a label. This method
will also produce donut charts (or ring charts), which is a pie chart with a
hole.

The general form for calling the C<add_piechart> method is

    $statPlot->add_piechart($data, %options);

where C<$data> is a reference to an array of values.

=head3 Options

The following options which are specific to configuring the pie chart can be
passed in addition to any of the L<dataset options|plots.pl/DATASET OPTIONS>.

=over

=item center

The center of the circle as an array reference. The default value is C<[0, 0]>.

=item radius

The radius of the circle. The default value of 4 is chosen to fit nicely with
the default values for the bounding box of the C<StatPlot> which ranges from -5
to 5 in both the x and y directions.

=item inner_radius

This is the radius of the inner circle of the chart. Set this to a value less
than the C<radius> for a donut or ring chart. The default value is 0.

=item angle_offset

This is the angle in degrees from the positive horizontal axis at which the
first sector begins. This is 0 by default.

=item fill_colors

This is either the name of a color palette, a reference to an array of colors,
or a reference to a hash containing the name of a color palette
(C<palette_name>) and number of colors to generate (C<num_colors>) (see L<COLOR
PALETTES> for more information). If this is a reference to an array and the
length of the array is smaller than the number of data values in the array
referenced to by C<$data>, then the colors will be cycled. The default is to use
the C<'rainbow'> color palette.

For example,

    fill_colors => 'rainbow'

    fill_colors => ['green', 'OliveGreen', 'DarkGreen', 'ForestGreen', 'PineGreen']

    fill_colors => { palette_name => 'random', num_colors => 7 }

=item color_sectors

If this is 1 (the default), then colors are used for the pie chart. If 0, then
the sectors are not filled. See L<COLOR PALETTES> for details on selecting
colors.

=item sector_labels

The labels for the sector as a array reference of strings or values. The
default is for no labels. If this is used, the length of this must be the same
as the C<$data> array reference.

=back

=head2 COLOR PALETTES

The color palettes for the bar plots and pie charts can be selected with the
C<color_palette> function. This allows a number of built-in or generated color
palettes. To get an array reference of either named or generated colors call

    color_palette($name, $numColors);

For example,

    color_palette('rainbow');

returns the 6 colors of the rainbow. Some of the palettes have fixed numbers of
colors, whereas others have variable numbers. If C<$numColors> is not defined,
then some palettes return a fixed number (like 'rainbow') and if the
C<$numColors> is needed, then the default of 10 is assumed.

=head3 PALETTE NAMES

=over

=item rainbow

The 6 colors of the rainbow from violet to red. The C<$numColors> value is
ignored for this palette.

=item reds

This will return a selection of red colors. The C<$numColors> value is ignored
for this palette.

=item blues

This will return a selection of blue colors. The C<$numColors> value is ignored
for this palette.

=item greens

This will return a selection of green colors. The C<$numColors> value is ignored
for this palette.

=item random

This will return C<$numColors> random colors from the defined SVG colors.

=back

=cut

BEGIN { strict->import; }

sub _StatisticalPlots_init {
	main::PG_restricted_eval('sub StatPlot { Plots::StatPlot->new(@_); }');
}

loadMacros('PGstatisticsmacros.pl', 'PGauxiliaryFunctions.pl');

package Plots::StatPlot;
our @ISA = qw(Plots::Plot);

sub add_histogram {
	my ($self, $data, %options) = @_;

	$options{orientation} //= 'vertical';

	my $numBins = delete $options{bins} // 10;
	$numBins = 10 unless $numBins =~ /^\d+$/ && $numBins > 0;

	my $min      = delete $options{min} // main::min(@$data);
	my $max      = delete $options{max} // main::max(@$data);
	my $binWidth = ($max - $min) / $numBins;

	my @frequencies = (0) x $numBins;
	++$frequencies[ int(($_ - $min) / $binWidth) ] for @$data;

	if (delete $options{normalize}) {
		my $total = 0;
		$total += $_ for @frequencies;
		@frequencies = map { $_ / $total } @frequencies;
	}

	my @xdata = map { $min + (0.5 + $_) * $binWidth } (0 .. $#frequencies);

	return $self->add_barplot(
		$options{orientation} eq 'vertical' ? (\@xdata, \@frequencies) : (\@frequencies, \@xdata), %options
		),
		\@frequencies;
}

sub add_barplot {
	my ($self, $xdata, $ydata, %options) = @_;

	$options{bar_width}   //= 1;
	$options{orientation} //= 'vertical';
	set_plot_option_aliases(\%options);

	Value::Error('The first two arguments must be references to arrays of the same length.')
		unless (ref $xdata eq 'ARRAY' && ref $xdata eq 'ARRAY' && @$xdata == @$ydata);

	# Assume that the values in $xdata are equally spaced.
	# TODO: Should arbitrarily spaced bars be handled?
	my $bar_width = $options{orientation} eq 'vertical' ? $xdata->[1] - $xdata->[0] : $ydata->[1] - $ydata->[0];

	my $fill_colors =
		ref $options{fill_colors} eq 'HASH'
		? color_palette($options{fill_colors}{palette_name}, $options{fill_colors}{num_colors})
		: (!defined $options{fill_colors} || ref $options{fill_colors} ne 'ARRAY')
		? color_palette($options{fill_colors})
		: $options{fill_colors};

	return $self->add_rectangle(
		map { [
			$options{orientation} eq 'vertical'
			? (
				[ $xdata->[$_] - 0.5 * $bar_width * $options{bar_width}, 0 ],
				[ $xdata->[$_] + 0.5 * $bar_width * $options{bar_width}, $ydata->[$_] ]
				)
			: (
				[ 0,            $ydata->[$_] - 0.5 * $bar_width * $options{bar_width} ],
				[ $xdata->[$_], $ydata->[$_] + 0.5 * $bar_width * $options{bar_width} ]
			),
			fill_color => $fill_colors->[ $_ % @$fill_colors ],
			%options
		] } 0 .. $#$xdata
	);
}

sub add_boxplot {
	my ($self, $data, %options) = @_;

	$options{orientation}  //= 'horizontal';
	$options{whisker_cap}  //= 0;
	$options{cap_width}    //= 0.2;
	$options{outlier_mark} //= 'plus';
	set_plot_option_aliases(\%options);

	if (ref $data eq 'ARRAY' && (ref $data->[0] eq 'ARRAY' || ref $data->[0] eq 'HASH')) {
		my $box_centers;
		if ($options{box_center}) {
			Value::Error(q{The "box_center" option must be a reference to an array }
					. 'with the same length as the number of box plots being added.')
				unless (ref $options{box_center} eq 'ARRAY' && @{ $options{box_center} } == @$data);
			$box_centers = delete $options{box_center};
		} else {
			unless ($options{box_width}) {
				$options{box_width} =
					($options{orientation} eq 'vertical' ? $self->axes->xaxis('max') : $self->axes->yaxis('max')) /
					(2.5 * @$data);
			}
			$box_centers = [ map { 2 * $options{box_width} * $_ } (1 .. @$data + 1) ];
		}
		for (0 .. $#$data) {
			$options{box_center} = $box_centers->[$_];
			$self->_add_boxplot($data->[$_], %options);
		}
	} else {
		$self->_add_boxplot($data, %options);
	}
}

sub _add_boxplot {
	my ($self, $data, %options) = @_;

	my $orientation = $options{orientation} // 'horizontal';
	my $params;
	if (ref $data eq 'ARRAY') {
		my @five_point = main::five_point_summary(@$data);
		$params = {
			min    => $five_point[0],
			q1     => $five_point[1],
			median => $five_point[2],
			q3     => $five_point[3],
			max    => $five_point[4]
		};
	} elsif (ref $data eq 'HASH') {
		# Check that all elements of the five number summary were provided.
		my %missing;
		for ('min', 'q1', 'median', 'q3', 'max') {
			$missing{$_} = 1 unless defined $data->{$_};
		}
		for (keys %missing) {
			Value::Error(qq{The parameter "$_" is missing from the box plot five number summary.});
		}

		$params = $data;
	}

	if ($orientation eq 'horizontal') {
		my $box_center = $options{box_center} // 0.5 * $self->axes->yaxis->{max};
		my $box_width  = $options{box_width}  // 0.5 * $self->axes->yaxis->{max};

		$self->add_rectangle([ $params->{q1}, $box_center - 0.5 * $box_width ],
			[ $params->{q3}, $box_center + 0.5 * $box_width ], %options);
		$self->add_dataset(
			[ [ $params->{min}, $box_center ], [ $params->{q1},  $box_center ], %options ],
			[ [ $params->{q3},  $box_center ], [ $params->{max}, $box_center ], %options ],
			[
				[ $params->{median}, $box_center - 0.5 * $box_width ],
				[ $params->{median}, $box_center + 0.5 * $box_width ],
				%options
			]
		);

		if ($options{whisker_cap}) {
			$self->add_dataset(
				[
					[ $params->{max}, $box_center - 0.5 * $options{cap_width} * $box_width ],
					[ $params->{max}, $box_center + 0.5 * $options{cap_width} * $box_width ],
					%options
				],
				[
					[ $params->{min}, $box_center - 0.5 * $options{cap_width} * $box_width ],
					[ $params->{min}, $box_center + 0.5 * $options{cap_width} * $box_width ],
					%options
				]
			);
		}

		if (ref $params->{outliers} eq 'ARRAY') {
			$self->add_dataset(
				(map { [ $_, $box_center ] } @{ $params->{outliers} }),
				linestyle => 'none',
				marks     => $options{outlier_mark},
				marksize  => 3
			);
		}
	} elsif ($orientation eq 'vertical') {
		my $box_center = $options{box_center} // 0.5 * $self->axes->xaxis->{max};
		my $box_width  = $options{box_width}  // 0.5 * $self->axes->xaxis->{max};

		$self->add_rectangle([ $box_center - 0.5 * $box_width, $params->{q1} ],
			[ $box_center + 0.5 * $box_width, $params->{q3} ], %options);
		$self->add_dataset(
			[ [ $box_center, $params->{min} ], [ $box_center, $params->{q1} ],   %options ],
			[ [ $box_center, $params->{q3} ],  [ $box_center, $params->{max}, ], %options ],
			[
				[ $box_center - 0.5 * $box_width, $params->{median} ],
				[ $box_center + 0.5 * $box_width, $params->{median} ],
				%options
			]
		);

		if ($options{whisker_cap}) {
			$self->add_dataset(
				[
					[ $box_center - 0.5 * $options{cap_width} * $box_width, $params->{max} ],
					[ $box_center + 0.5 * $options{cap_width} * $box_width, $params->{max}, ],
					%options
				],
				[
					[ $box_center - 0.5 * $options{cap_width} * $box_width, $params->{min} ],
					[ $box_center + 0.5 * $options{cap_width} * $box_width, $params->{min} ],
					%options
				]
			);
		}

		if (ref $params->{outliers} eq 'ARRAY') {
			$self->add_dataset(
				(map { [ $box_center, $_ ] } @{ $params->{outliers} }),
				linestyle => 'none',
				marks     => $options{outlier_mark},
				marksize  => 3
			);
		}
	}
}

sub add_scatterplot {
	my ($self, $data, %options) = @_;

	$options{linestyle} //= 'none';
	$options{marks}     //= 'circle';
	$options{mark_size} //= 3;
	set_plot_option_aliases(\%options);

	$self->add_dataset(@$data, %options);

}

sub add_piechart {
	my ($self, $data, %options) = @_;

	$options{center}       //= [ 0, 0 ];
	$options{radius}       //= 4;
	$options{angle_offset} //= 0;
	$options{inner_radius} //= 0;
	set_plot_option_aliases(\%options);

	Value::Error('The number of labels must equal the number of sectors in the pie chart')
		unless (defined $options{labels} && @$data == @{ $options{labels} });

	my $fill_colors =
		ref $options{fill_colors} eq 'HASH'
		? color_palette($options{fill_colors}{palette_name}, $options{fill_colors}{num_colors})
		: (!defined $options{fill_colors} || ref $options{fill_colors} ne 'ARRAY')
		? color_palette($options{fill_colors})
		: $options{fill_colors};

	my $pi    = 4 * atan2(1, 1);
	my $total = 0;
	$total += $_ for @$data;

	my $theta = $options{angle_offset} * $pi / 180;    # first angle of the sector
	for (0 .. $#$data) {
		my $delta_theta = 2 * $pi * $data->[$_] / $total;
		$self->add_multipath(
			[
				[
					"$options{center}[0] + $options{radius} * cos(t)",
					"$options{center}[1] + $options{radius} * sin(t)",
					$theta,
					$theta + $delta_theta
				],
				[
					"$options{center}[0] + $options{inner_radius} * cos(t)",
					"$options{center}[1] + $options{inner_radius} * sin(t)",
					$theta + $delta_theta,
					$theta
				],
			],
			't',
			cycle      => 1,
			fill       => 'self',
			fill_color => $fill_colors->[ $_ % @$fill_colors ],
			%options
		);
		# add the labels if defined
		if ($options{labels}) {
			my $alpha = $theta + 0.5 * $delta_theta;

			$self->add_label(
				$options{radius} * cos($alpha), $options{radius} * sin($alpha), $options{labels}[$_],
				anchor  => 180 * (1 + $alpha / $pi),
				padding => 15
			);
		}
		$theta += $delta_theta;
	}

}

sub set_plot_option_aliases {
	my $options = shift;
	my %aliases = (stroke_width => 'width', stroke_color => 'color', mark_color => 'color');
	for (keys %aliases) {
		$options->{ $aliases{$_} } = delete $options->{$_} if defined $options->{$_};
	}
	return %$options;
}

sub color_palette {
	my ($palette_name, $num_colors) = @_;

	$palette_name //= 'rainbow';

	if ($palette_name eq 'rainbow') {
		return [ 'Violet', 'blue', 'green', 'yellow', 'orange', 'red' ];
	} elsif ($palette_name eq 'greens') {
		return [ 'Green', 'Olive', 'DarkGreen', 'LawnGreen', 'MediumAquamarine', 'LimeGreen' ];
	} elsif ($palette_name eq 'blues') {
		return [ 'Blue', 'MidnightBlue', 'MediumBlue', 'LightSkyBlue', 'DodgerBlue', 'DarkBlue', 'CornflowerBlue' ];
	} elsif ($palette_name eq 'reds') {
		return [ 'Red', 'Crimson', 'DarkRed', 'FireBrick', 'IndianRed', 'Maroon', 'Tomato' ];
	} elsif ($palette_name eq 'random') {
		return [
			main::random_subset(
				$num_colors // 10,
				(
					'AliceBlue',       'AntiqueWhite',      'Aqua',                 'Aquamarine',
					'Azure',           'Beige',             'Bisque',               'Black',
					'BlanchedAlmond',  'Blue',              'BlueViolet',           'Brown',
					'BurlyWood',       'CadetBlue',         'Chartreuse',           'Chocolate',
					'Coral',           'CornflowerBlue',    'Cornsilk',             'Crimson',
					'Cyan',            'DarkBlue',          'DarkCyan',             'DarkGoldenrod',
					'DarkGray',        'DarkGreen',         'DarkGrey',             'DarkKhaki',
					'DarkMagenta',     'DarkOliveGreen',    'DarkOrange',           'DarkOrchid',
					'DarkRed',         'DarkSalmon',        'DarkSeaGreen',         'DarkSlateBlue',
					'DarkSlateGray',   'DarkSlateGrey',     'DarkTurquoise',        'DarkViolet',
					'DeepPink',        'DeepSkyBlue',       'DimGray',              'DimGrey',
					'DodgerBlue',      'FireBrick',         'FloralWhite',          'ForestGreen',
					'Fuchsia',         'Gainsboro',         'GhostWhite',           'Gold',
					'Goldenrod',       'Gray',              'Green',                'GreenYellow',
					'Grey',            'Honeydew',          'HotPink',              'IndianRed',
					'Indigo',          'Ivory',             'Khaki',                'Lavender',
					'LavenderBlush',   'LawnGreen',         'LemonChiffon',         'LightBlue',
					'LightCoral',      'LightCyan',         'LightGoldenrodYellow', 'LightGray',
					'LightGreen',      'LightGrey',         'LightPink',            'LightSalmon',
					'LightSeaGreen',   'LightSkyBlue',      'LightSlateGray',       'LightSlateGrey',
					'LightSteelBlue',  'LightYellow',       'Lime',                 'LimeGreen',
					'Linen',           'Magenta',           'Maroon',               'MediumAquamarine',
					'MediumBlue',      'MediumOrchid',      'MediumPurple',         'MediumSeaGreen',
					'MediumSlateBlue', 'MediumSpringGreen', 'MediumTurquoise',      'MediumVioletRed',
					'MidnightBlue',    'MintCream',         'MistyRose',            'Moccasin',
					'NavajoWhite',     'Navy',              'OldLace',              'Olive',
					'OliveDrab',       'Orange',            'OrangeRed',            'Orchid',
					'PaleGoldenrod',   'PaleGreen',         'PaleTurquoise',        'PaleVioletRed',
					'PapayaWhip',      'PeachPuff',         'Peru',                 'Pink',
					'Plum',            'PowderBlue',        'Purple',               'RebeccaPurple',
					'Red',             'RosyBrown',         'RoyalBlue',            'SaddleBrown',
					'Salmon',          'SandyBrown',        'SeaGreen',             'Seashell',
					'Sienna',          'Silver',            'SkyBlue',              'SlateBlue',
					'SlateGray',       'SlateGrey',         'Snow',                 'SpringGreen',
					'SteelBlue',       'Tan',               'Teal',                 'Thistle',
					'Tomato',          'Turquoise',         'Violet',               'Wheat',
					'White',           'WhiteSmoke',        'Yellow',               'YellowGreen'
				)
			)
		];
	}
}

1;
