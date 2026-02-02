
=head1 NAME

StatisticalPlots.pl - A macro to create dynamic statistics plots to include in PG problems. 

=head1 DESCRIPTION

This macro includes a number of methods to include statistical plots in PG problems. 
This is based on L<plots.pl> which will draw in either C<TikZ> or C<JSXGraph> format with the 
default for the former to be used for hardcopy and the latter for HTML output.  

The statistical plots available are

=over 

=item Box Plots

=item Bar Plots

=item Histograms

=item Scatter Plots

=back

=head2 USAGE

First, start with a C<StatPlot> object as in 

    loadMacros('StatisticsPlots.pl');
    $stat_plot = StatPlot(
        xmin        => -1,
        xmax        =>  8,
        ymin        => -1.5,
        ymax        =>  10,
        xtick_delta =>  1,
        ytick_delta => 4,
        aria_label => 'Bar plot of a set of data'
    );

The options for C<StatPlot> are identical to that of a C<Plot> object and all options are in the
L<Axes Object|Plots::Axes>. Note that each of the x- and y-axes have separate options and 
each option is preceded with a C<x> or C<y>. 

After the C<StatPlot> is created then specific plots are added to the axes.  For example:

    @y = (3, 6, 7, 8, 4, 1);
    $hist->add_barplot(
        [ 1 .. 6 ], ~~@y,
        fill_color => 'yellow',
        width      => 1,
        bar_width  => 0.9
    );

will add a barplot to the axes with heights in the C<@y> variable at the x-locations C<(1..6)>. 

See below for more details about creating a barplot and its options. 

=head1 PLOT ELEMENTS

As mentioned above, a statistical plot is a set of axes with one or more plot objects such as 
bar plots, box plots or scatter plots.  A C<StatPlot> must be created first and then one or more 
of the following can be added. 

=head2 BAR PLOTS

A bar plot is added with the C<add_barplot> method to a C<StatPlot>. The general form for a 
bar plot with vertical bars (the default) is

    $stat_plot->add_barplot($xdata, $ydata, %opts);

where C<$xdata> is an ARRAYREF of x-values where the bars will be centered and C<$ydata> is an
ARRAY of heights of the bars.  Note: if the option C<< orientation => 'horizontal' >> is included
then the bar lengths are the values in C<$xdata> and locations in C<$ydata>.  

=head3 OPTIONS

The options for the C<add_barplot> method are two fold.  The following are specific to changing
the barplot, and the rest are passed along to C<add_rectangle>, which is a wrapper function for 
C<add_dataset>. 

=over 

=item orientation

The C<orientation> option can take on C<vertical> (default) or C<horizontal> to make vertical
or horizontal bars.  Above was an example with vertical bars and an example with horizontal bars is

    @x = (3, 6, 7, 8, 4, 1);
    $hist->add_barplot(
        ~~@x, [ 1 .. 6 ],
        orientation => 'horizontal',
        fill_color => 'yellow',
        width      => 1,
        bar_width  => 0.9
    );

=item bar_width

The option C<bar_width> is a number in the range [0,1] to give the relative width of the bar.  If 
C<< bar_width => 1 >> (default), then there is no gap between bars.  In the example above, with 
C<< bar_width => 0.9 >>, there is a small gap between bars.  

=back

Any remaining options are passed to C<add_rectangle> which has the same options as C<add_dataset>, 
however, if C<fill_color> is passed to C<add_barplot>, then the C<< fill => 'self' >> is also 
passed along. 

See L<Options for add_dataset|plots.pl/DATASET OPTIONS> for specifics about other options to 
both changing fill and stroke color. 

=head2 HISTOGRAMS

A L<histogram|https://en.wikipedia.org/wiki/Histogram> is added with the `add_histogram` method 
to a C<StatPlot>. The general form is 

    $stat_plot->add_histogram($data, %options);

where C<$data> is an array ref of univariate data.  The C<%options> include both options
for the histogram like number of bins as well as options for the bars. 

An example is performed using the C<urand> function from C<PGstatisticalmacros.pl> which
produces normally distributed random variables. 

    macros('StatisticalPlots.pl', 'PGstatisticsmacros.pl');
    @data = urand(30, 9, 50, 6); # create 50 random variables with mean 30 and std. dev of 9.
    $stat_plot = StatPlot(
        xmin => 0,
        xmax => 65,
        ymin => 0,
        ymax => 12, 
        xtick_delta => 10,
        ytick_delta => 2
    );
    $stat_plot->add_histogram(
        ~~@data,
        min        => 10,
        max        => 60,
        bins       => 10,
        fill_color => 'lightgreen',
        width => 1
    );

The first argument to C<add_histogram> is an array ref of univariate data. 

=head3 Options

The following are options specific to histograms.

=over 

=item min

The left edge of the leftmost box.  If not defined, the minimum of C<$data> is used.

=item max

The right edge of the rightmost box.  If not defined, the maximum of C<$data> is used.

=item bins

The number of bins/boxes to use for the histogram.  This must be an integer greater
than 0.  If not defined, the default value of 10 is used.

=item normalize 

If the value of 0 (default) is used, the height of the bars is the count of the number
of points.  If the value is 1, then the heights are scaled so the total height of the
bars is 1.  

=back

The rest of the options are passed through to the C<add_barplot> method in which the
fill color and opacity as well as the stroke color and width.  See both L<add_barplot>
and L<add_dataset options|plots.pl/DATASET OPTIONS> for more details. 

=head2 BOX PLOTS

A box plot (also called a box and whiskers plot) can be created with the C<add_boxplot> method.  
If one performs

   $stat_plot->add_boxplot($data, %options);

or if one has multiple box plots

   $stat_plot->add_boxplot([$data1, $data2, ...], %options);

where C<$data> is an array ref of univariate data or a hash ref of the boxplot characteristics, 
then a box plot is created using the five number summary (minimum, first quartile, median,
third quartile, maximum) of the data.  These values are calculated using the C<five_point_summary> 
function from C<PGstatisticsmacros.pl>.  An example of creating a boxplot with an arrayref of
univariate data is 

    @data = urand(100,25,75,6);

    $boxplot = StatPlot(
        xmin         => 0,
        xmax         => 200,
        xtick_delta  =>  25,
        show_grid    =>  0,
        ymin         => -5,
        ymax         =>  25,
        yvisible     =>  0,
        aspect_ratio => 4,
        rounded_corners => 1
    );

    $boxplot->add_boxplot(~~@data, fill_color => 'lightblue', width => 1);

and as with other methods in this macro, one can pass options to the characteristic of the 
box plot (like fill color or stroke color and width) within the C<add_boxplot> method. 

If C<$data> is a hashref, it must contains the fields C<min, q1, median, q3, max> that are used to
define the boxplot.  Optionally, one may also include the field C<outliers> which is an array 
ref of values which will be plotted beyond the whiskers. 

An example of this is 

    $params = {
        min    => random(150, 175, 5),
        q1     => random(180, 225, 5),
        median => random(250, 275, 5),
        q3     => random(280, 320, 10),
        max    => random(325, 350, 5),
        outliers => [115,130]
    };

    $boxplot = StatPlot(
        xmin         => 100,
        xmax         => 400,
        xtick_delta  =>  50,
        show_grid    =>  0,
        ymin         => -5,
        ymax         =>  25,
        yvisible     =>  0,
        aspect_ratio => 4
    );

    $boxplot->add_boxplot($params);

=head3 Options

The following are options to the C<add_boxplot> method. 

=over 

=item orientation

This is the direction of the box plot and can take on values 'horizontal' (default)
or 'vertical'. 

=item box_center

The location of the center of the box.  This is optional and if not defined will center the 
box between the axis and the edge of the plot. 

If multiple box plots are included, this option will be created to equally space the 
box plots between the axis and the edge of the plot.  If included, this option must be an 
arrayref of values (in the x-direction for vertical plots and y-direction for horizontal).  

    box_center => [3,6,9]

as an example. 

=item box_width 

The width of the box in the direction perpendicular to the orientation.  If not define, it
will take the value of 0.5 times the space between the axis and the edge of the plot. 

If multiple box plots are defined, this should only be a single value.  

=item whisker_cap

Value of 0 (default) or 1.  If 1, his will add a short line perpendicular to the whiskers 
on the boxplot with relative size C<cap_width>

=item cap_width

The width of the cap as a fraction of the box height (if C<< orientation => 'vertical' >>)
or box width (if C<< orientation => 'horizontal' >>).  Default value is 0.2.

=item outlier_mark 

The shape of the mark to use for outliers.  Default is 'plus'.  See L<Options for add_dataset|plots.pl/DATASET OPTIONS> 
for other mark options.

=back

As with other methods in the macro, other options can be passed along to C<add_rectangle>
and C<add_dataset> which are used in the macro. 

Also, if C<fill_color> is included, then C<< fill => 'self' >> is automatically added on the 
box. 

=head2 SCATTER PLOTS

To produce a scatter plot, use the C<add_scatterplot> method to a C<StatPlot>.  The general 
form is 

    $plot->add_scatterplot($data, %options);

where the dataset in C<$data> is an array ref of C<x, y> pairs as an array ref.  For example,

    $stat_plot = StatPlot(
        xmin => -1,
        xmax => 15,
        xtick_delta => 5,
        ymin => -1,
        ymax => 15,
        ytick_delta => 5,
    );

    $data = [ [1,1], [2,3], [3,4], [5,5], [7,8], [10,9], [12,10]];

    $stat_plot->add_scatterplot($data, marks => 'diamond', mark_size => 5, color => 'orange');

This method is simply a wrapper for the C<add_dataset> method where the defaults are different.  

=over 

=item linestyle

The C<linestyle> option is set to 'none', so that lines are not drawn between the points. 

=item marks

The C<marks> is default to 'circle'.  See L<Options for add_dataset|plots.pl/DATASET OPTIONS> 
for other mark options. 

=item mark_size

The C<mark_size> is default to 3.  

=back

If more that one dataset is to be plotted, simply call the C<add_scatterplot> method multiple 
times.  This can be done with a single C<add_dataset> method call, but this wrapper makes it 
easier to set different options

=cut

BEGIN { strict->import; }

sub _StatisticalPlots_init {
	main::PG_restricted_eval('sub StatPlot { Plots::StatPlot->new(@_); }');
}

loadMacros('PGstatisticsmacros.pl');

package Plots::StatPlot;
our @ISA = qw(Plots::Plot);

sub add_histogram {
	my ($self, $data, %opts) = @_;

	my %options = (
		bins        => 10,
		normalize   => 0,
		orientation => 'vertical',
		%opts
	);

	Value::Error("The option 'bins' must be a positive integer")
		unless $options{bins} =~ /^\d+$/ && $options{bins} > 0;

	my @counts    = (0) x $options{bins};
	my $min       = $options{min} // main::min(@$data);
	my $max       = $options{max} // main::max(@$data);
	my $bin_width = ($max - $min) / $options{bins};

	# TODO: if the bin_width is 0, set the num_bins to 1 and give a non-zero bin_width.

	$counts[ int(($_ - $min) / $bin_width) ]++ for (@$data);
	if ($options{normalize}) {
		my $total = 0;
		$total += $_ for (@counts);
		@counts = map { $_ / $total } @counts;
	}
	my @xdata = map { $min + (0.5 + $_) * $bin_width } (0 .. $#counts);

	# Remove these options and pass the rest to add_barplot
	delete $options{$_} for ('min', 'max', 'bins', 'normalize');

	if ($options{orientation} eq 'vertical') {
		$self->add_barplot(\@xdata, \@counts, %options);
	} else {
		$self->add_barplot(\@counts, \@xdata, %options);
	}

	return \@counts;
}

# Create a barplot where for each x in xdata, create a bar of height y in ydata.

sub add_barplot {
	my ($self, $xdata, $ydata, %opts) = @_;

	my %options = (
		bar_width   => 1,
		orientation => 'vertical',
		%opts
	);

	Value::Error('The lengths of the data in the first two arguments must be arrayrefs of the same length')
		unless ref $xdata eq 'ARRAY' && ref $xdata eq 'ARRAY' && scalar(@$xdata) == scalar(@$ydata);

	# assume that the $xdata is equally spaced.  TODO: should we handle arbitrary spaced bars?
	my $bar_width = $options{orientation} eq 'vertical' ? $xdata->[1] - $xdata->[0] : $ydata->[1] - $ydata->[0];

	# if fill_color is passed as an option, set the 'fill' to 'self'.
	$options{fill} = 'self' if $options{fill_color};

	for my $j (0 .. scalar(@$xdata) - 1) {
		if ($options{orientation} eq 'vertical') {
			$self->SUPER::add_rectangle([ $xdata->[$j] - 0.5 * $bar_width * $options{bar_width}, 0 ],
				[ $xdata->[$j] + 0.5 * $bar_width * $options{bar_width}, $ydata->[$j] ], %options);
		} else {
			$self->SUPER::add_rectangle([ 0, $ydata->[$j] - 0.5 * $bar_width * $options{bar_width} ],
				[ $xdata->[$j], $ydata->[$j] + 0.5 * $bar_width * $options{bar_width} ], %options);
		}
	}
}

sub add_boxplot {
	my ($self, $data, %opts) = @_;

	my %options = (
		orientation  => 'horizontal',
		whisker_cap  => 0,
		cap_width    => 0.2,
		outlier_mark => 'plus',
		%opts
	);

	# Placeholder for boxplot implementation.
	if (ref $data eq 'ARRAY' && (ref $data->[0] eq 'ARRAY' || ref $data->[0] eq 'HASH')) {
		my ($box_centers, $box_width);
		if ($options{box_center}) {
			Value::Error(
				"The option 'box_center' must be an array ref with the same length as the box plots to produce.")
				unless ref $options{box_center} eq 'ARRAY' && scalar(@{ $options{box_center} }) == scalar(@$data);
			$box_centers = $options{box_center};
			delete $options{box_center};
		} else {
			my $n = scalar(@$data);
			unless ($options{box_width}) {
				$options{box_width} =
					($options{orientation} eq 'vertical' ? $self->axes->xaxis('max') : $self->axes->yaxis('max')) /
					(2.5 * $n);
			}
			$box_centers = [ map { 2 * $options{box_width} * $_ } (1 .. $n + 1) ];
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
		# check that all aspects of the boxplot are passed in.
		my %count;
		$count{$_}++ for ('min', 'q1', 'median', 'q3', 'max');
		$count{$_}-- for (keys %$data);
		for (keys %count) {
			Value::Error("The parameter $_ is missing from the boxplot attributes.") if $count{$_} > 0;
		}
		$params = $data;
	}

	# if fill_color is passed as an option, set the 'fill' to 'self'.
	$options{fill} = 'self' if $options{fill_color};

	if ($orientation eq 'horizontal') {
		my $box_center = $options{box_center} // 0.5 * $self->axes->yaxis->{max};
		my $box_width  = $options{box_width}  // 0.5 * $self->axes->yaxis->{max};

		$self->add_rectangle([ $params->{q1}, $box_center - 0.5 * $box_width ],
			[ $params->{q3}, $box_center + 0.5 * $box_width ], %options);
		$self->add_dataset([ $params->{min},    $box_center ], [ $params->{q1},  $box_center ], %options);
		$self->add_dataset([ $params->{q3},     $box_center ], [ $params->{max}, $box_center ], %options);
		$self->add_dataset([ $params->{median}, $box_center - 0.5 * $box_width ],
			[ $params->{median}, $box_center + 0.5 * $box_width ], %options);

		# add whisker caps
		if ($options{whisker_cap}) {
			$self->add_dataset([ $params->{max}, $box_center - 0.5 * $options{cap_width} * $box_width ],
				[ $params->{max}, $box_center + 0.5 * $options{cap_width} * $box_width ], %options);
			$self->add_dataset([ $params->{min}, $box_center - 0.5 * $options{cap_width} * $box_width ],
				[ $params->{min}, $box_center + 0.5 * $options{cap_width} * $box_width ], %options);
		}

		if ($params->{outliers}) {
			my @points = map { [ $_, $box_center ] } @{ $params->{outliers} };
			$self->add_dataset(@points, linestyle => 'none', marks => $options{outlier_mark}, marksize => 3);
		}
	} elsif ($orientation eq 'vertical') {

		my $box_center = $options{box_center} // 0.5 * $self->axes->xaxis->{max};
		my $box_width  = $options{box_width}  // 0.5 * $self->axes->xaxis->{max};

		$self->add_rectangle([ $box_center - 0.5 * $box_width, $params->{q1} ],
			[ $box_center + 0.5 * $box_width, $params->{q3} ], %options);
		$self->add_dataset([ $box_center, $params->{min} ], [ $box_center, $params->{q1} ],   %options);
		$self->add_dataset([ $box_center, $params->{q3} ],  [ $box_center, $params->{max}, ], %options);
		$self->add_dataset([ $box_center - 0.5 * $box_width, $params->{median} ],
			[ $box_center + 0.5 * $box_width, $params->{median} ], %options);

		if ($params->{outliers}) {
			my @points = map { [ $box_center, $_ ] } @{ $params->{outliers} };
			$self->add_dataset(@points, linestyle => 'none', marks => $options{outlier_mark}, marksize => 3);
		}

		# add whisker caps
		if ($options{whisker_cap}) {
			$self->add_dataset([ $box_center - 0.5 * $options{cap_width} * $box_width, $params->{max} ],
				[ $box_center + 0.5 * $options{cap_width} * $box_width, $params->{max}, ], %options);
			$self->add_dataset([ $box_center - 0.5 * $options{cap_width} * $box_width, $params->{min} ],
				[ $box_center + 0.5 * $options{cap_width} * $box_width, $params->{min} ], %options);
		}
	}
}

sub add_scatterplot {
	my ($self, $data, %opts) = @_;

	my %options = (
		linestyle => 'none',
		marks     => 'circle',
		mark_size => 3,
		%opts
	);

	$self->add_dataset(@$data, %options);

}

1;
