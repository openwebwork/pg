
=head1 NAME

plots.pl - A macro to create dynamic graphs to include in PG problems.

=head1 DESCRIPTION

This macro creates a Plots object that is used to add data of different
elements of a 2D plot, then draw the plot. The plots can be drawn using different
formats. Currently C<TikZ> (using PGFplots), C<JSXGraph>, and the legacy C<GD>
graphics format are available. Default is to use C<JSXGraph> for HTML output and
C<TikZ> for hardcopy.

Note, due to differences in features between C<JSXGraph> and C<TikZ>, not all
options work with both.

=head1 USAGE

First create a Plots object:

    loadMacros('plots.pl');
    $plot = Plot(
        xmin        => 0,
        xmax        => 10,
        ymin        => 0,
        ymax        => 500,
        xtick_delta => 2,
        ytick_delta => 50,
        xlabel      => '\(t\)',
        ylabel      => '\(h(t)\)',
        aria_label  => 'Height of an object as a function of time.',
        axes_on_top => 1,
    );

This single call configures the L<Axes Object|Plots::Axes> (see link for full list of options).
Options that start with C<x> configure the xaxis, options that start with C<y> configure the
yaxis, and all other options are Axes styles.

Add a function and other objects to the plot.

    $plot->add_function('-16t^2 + 80t + 384', 't', 0, 8, color => 'blue', width => 3);

Insert the graph into the problem.

    BEGIN_PGML
    [! Plot of a quadratic function !]{$plot}{500}
    END_PGML

=head1 PLOT ELEMENTS

A plot consists of multiple L<Data objects|Plots::Data>, which define datasets, functions,
and labels to add to the graph. Data objects should be created though the Plots object,
but can be access directly if needed

=head2 DATASETS

The core plot element is a dataset, which is a collection of points and options
to plot the data. Datasets are added to a plot via C<< $plot->add_dataset >>, and
can be added individually, or multiple at once as shown:

    # Add a single dataset
    $plot->add_dataset([$x1, $y1], [$x2, $y2], ..., [$xn, $yn], @options);
    # Add multiple datasets with single call
    $plot->add_dataset(
        [[$x11, $y11], [$x12, $y12], ..., [$x1n, $y1n], @options1],
        [[$x21, $y21], [$x22, $y22], ..., [$x2m, $y2m], @options2],
        ...
    );

For example, add a red line segment from (2,3) to (5,7):

    $plot->add_dataset([2, 3], [5, 7], color => 'red', width => 2);

Add multiple arrows by setting the C<end_mark> (or C<start_mark>) of the dataset.

    $plot->add_dataset(
        [[0, 0], [2, 3],  color => 'green', end_mark   => 'arrow'],
        [[2, 3], [4, -1], color => 'blue',  end_mark   => 'arrow'],
        [[0, 0], [4, -1], color => 'red',   start_mark => 'arrow'],
    );

If needed, the C<< $plot->add_dataset >> method returns the L<Data|Data.pm/"DATA OBJECT"> object
(or array of Data objects) which can be manipulated directly.

    $data = $plot->add_dataset(...);

=head2 PLOT FUNCTIONS

Functions can be used to generate a dataset to plot. Similar to datasets
functions can be added individually or multiple at once:

    # Add a single function
    $plot->add_function($function, $variable, $min, $max, @options)
    # Add multiple functions
    $plot->add_function(
        [$function1, $variable1, $min1, $max1, @options1],
        [$function2, $variable2, $min2, $max2, @options2],
        ...
     );

This method can be used to add both single variable functions and
parametric functions (an array of two functions) to the graph.

    # Add the function y = x^2 to the plot.
    $plot->add_function('x^2', 'x', -5, 5);
    # Add a parametric circle of radius 5 to the plot.
    $plot->add_function(['5cos(t)', '5sin(t)'], 't', 0, 2*pi);

Polar functions can be graphed using the C<< polar => 1 >> option with a single variable
function. In this case the input variable (no matter what it is) is treated as a polar angle
theta, and the function computes the radius for that angle.

    # Polar graph of r = 5cos(3theta).
    $plot->add_function("5cos(3x)", 'x', 0, 'pi', polar => 1);

Functions can also be added using function strings. Function strings are of the form:

    "$function for $variable in <$min,$max> using option1:value1 and option2:value2"

This can be used to add either single variable functions or parametric functions:

    'x^2 for x in [-5,5) using color:red, weight:3 and steps:15'
    '(5cos(t), 5sin(t)) for t in <2,2pi> using color:blue, weight:2 and steps:20'

The interval end points configure if an open_circle, C<(> or C<)>, closed_circle, C<[> or C<]>,
arrow, C<{> or C<}>, or no marker, C<< < >> or C<< > >>, are added to the ends of the plot. Options are
listed in the form C<option:value> and can be separated by either commas or the word C<and>.
Multiple functions can be added at once using a list of function strings, which can be useful
for creating piecewise functions.

    # Add two single variable functions and a parametric function to the graph.
    $plot->add_function(
        'x + 2 for x in [-4, 4] using color:blue and weight:3',
        'x^2 for x in {-4, 4} using color:red and weight:3',
        '(2cos(t), 2sin(t)) for t in <0, 2pi> using color:green and weight:2'
    );
    # Add a piecewise function to the graph.
    $plot->add_function(
        '-3-x for x in {-5,-2.5)',
        'x^2-4 for x in [-2.5,2.5)',
        '8-2x for x in [2.5,5}'
    );

Functions can be defined using strings (which are turned into MathObjects),
MathObjects, or perl subroutines:

    # Add a function from a predefined MathObject.
    $f = Compute("$a x^2 + $b x + $c");
    $plot->add_function($f, 'x', -5, 5, width => 3);
    # Define a function using a perl subroutine.
    # The variable is undefined since it is not used.
    $plot->add_function(
        [ sub { return $_[0]**2; }, sub { return $_[0]; } ],
        undef,
        -5,
        5,
        color => 'green',
        width => 2
    );

It is preferred to use strings or MathObjects instead of perl subroutines.

=head2 PLOT MULTIPATH FUNCTIONS

A multipath function is defined using multiple parametric paths pieced together into into a single
curve, whose primary use is to create a closed region to be filled using multiple boundaries.
This is done by providing a list of parametric functions, the name of the parameter, and a list
of options.

    $plot->add_multipath(
        [
            [ $function_x1, $function_y1, $min1, $max1 ],
            [ $function_x2, $function_y2, $min2, $max2 ],
            ...
        ],
        $variable,
        %options
    );

The paths have to be listed in the order they are followed, but the minimum/maximum values
of the parameter can match the parametrization. The following example creates a sector of
radius 5 between pi/4 and 3pi/4, by first drawing the line (0,0) to (5sqrt(2),5/sqrt(2)),
then the arc of the circle of radius 5 from pi/4 to 3pi/4, followed by the final line from
(-5sqrt(2), 5sqrt(2)) back to the origin.

    $plot->add_multipath(
        [
            [ 't',       't',       0,           '5/sqrt(2)' ],
            [ '5cos(t)', '5sin(t)', 'pi/4',      '3pi/4' ],
            [ '-t',      't',       '5/sqrt(2)', 0 ],
        ],
        't',
        color => 'green',
        fill  => 'self',
    );

=head2 PLOT CIRCLES

Circles can be added to the plot by specifing its center and radius using the
C<< $plot->add_circle >> method. This can either be done either one at a time
or multiple at once.

    $plot->add_circle([$x, $y], $r, %options);
    $plot->add_circle(
        [[$x1, $y1], $r1, %options1],
        [[$x2, $y2], $r2, %options2],
        ...
    );

=head2 PLOT ARCS

Arcs (or a portion of a circle) can be plotted using the C<< $plot->add_arc >> method.
This method takes three points. The first point is where the arc starts, the second point
is the center of the circle, and the third point specifies the ray from the center of
the circle the arc ends. Arcs always go in the counter clockwise direction.

    $plot->add_arc([$start_x, $start_y], [$center_x, $center_y], [$end_x, $end_y], %options);
    $plot->add_arc(
        [[$start_x1, $start_y1], [$center_x1, $center_y1], [$end_x1, $end_y1], %options1],
        [[$start_x2, $start_y2], [$center_x2, $center_y2], [$end_x2, $end_y2], %options2],
        ...
    );

=head2 PLOT VECTOR FIELDS

Vector fields and slope fields can be plotted using the C<< $plot->add_vectorfield >> method.

    $plot->add_vectorfield(
        Fx     => 'sin(y)',
        Fy     => 'cos(x)',
        xvar   => 'x',
        yvar   => 'y',
        xmin   => -4,
        xmax   => 4,
        ymin   => -4,
        ymax   => 4,
        xsteps => 20,
        ysteps => 15,
        color  => 'blue',
        scale  => 0.5,
    );

This only works if C<Fx> and C<Fy> are strings or MathObjects (no perl functions allowed),
because the functions are passed off to either JSXGraph or TikZ to do the computation.
To make all the vectors the same length, add the C<< normalize => 1 >> option. To plot a slope
field add C<< slopefield => 1 >> option (which removes the arrow heads and makes all the
lines the same length), then set C<< Fx => 1 >> and C<Fy> equal to the formula to produce
the slope field.

In addition to the dataset options below, the following additional options apply to
vector fields.

=over 5

=item xvar, yvar

Name of the x-axis and y-axis variables used. Default: x and y

=item xmin, xmax, ymin, ymax

Range of the x and y coordinates of the vector field. Default: -5 to 5

=item xsteps, ysteps

The number of arrows drawn in each direction. Note, that in TikZ output, this cannot be
set individually so only C<xsteps> is used. Default: 15

=item scale

A scale factor applied to the arrow length. Default: 1

=item normalize

Makes all the arrows the same length. This just turns C<Fx> and C<Fy> into
C<(Fx)/sqrt((Fx)^2 + (Fy)^2)> and C<(Fy)/sqrt((Fx)^2 + (Fy)^2)> for convince.
Default: 0

=item slopefield

This removes the arrow heads and implies normalized (so all the lines are the same length).
Use this in combination with setting C<Fx => 1> and C<Fy> equal to the slope field formula
to graph a slope field instead of a vector field. Default: 0

=item jsx_options

A hash reference of options to pass to the JSXGraph C<vectorfield> object.

=item tikz_options

A string of TikZ options to append to the C<\addplot3> which creates the vector field quiver.

=back

=head2 DATASET OPTIONS

The following are the options that can be used to configure how datasets and functions are plotted.

=over 5

=item color

The color of the plot. Default: 'default_color'

=item width

The line width of the plot. Default: 1

=item linestyle

Linestyle can be one of 'solid', 'dashed', 'dotted', 'short dashes', 'long dashes',
'long medium dashes' (alternates between long and medium dashes), or 'none'. If set
to 'none', only the points are shown (see marks for point options) For convince
underscores can also be used, such as 'long_dashes'. Default: 'solid'

=item marks

Configures the symbol used for plotting the points in the dataset. Marks
can be one of 'none', 'circle' (or 'closed_circle'), 'open_circle', 'square',
'open_square', 'plus', 'times', 'bar', 'dash', 'triangle', 'open_triangle',
'diamond', or 'open_diamond'. Default: 'none'

=item mark_size

Configure the size of the marks (if shown). The size is a natural number,
and represents the point (pt) size of the mark. If the size is 0, the
default size is used. Default: 0

=item start_mark

Place a mark at the start (left end) of the plot. This can be one of
'none', 'closed_circle', 'open_circle', or 'arrow'. Default: 'none'

=item end_mark

Place a mark at the end (right end) of the plot. This can be one of
'none', 'closed_circle', 'open_circle', or 'arrow'. Default: 'none'

=item arrow_size

Sets the arrow head size for C<start_mark> or C<end_mark> arrows.
Default: 10

=item name

The name assigned to the curve to reference it for filling (see below).
Each curve used to fill between curves or the xaxis must have a unique name.
Default: undefined

=item fill

Sets the fill method to use. If set to 'none', no fill will be added.
If set to 'self', the object fills within itself, best used with closed
datasets. If set to 'xaxis', this will fill the area between the curve
and the x-axis. If set to another non-empty string, this is the name of
the other dataset to fill against. The C<name> attribute must be set to
fill between the 'xaxis' or another curve.

The following creates a filled rectangle:

    $plot->add_dataset([1, 1], [2, 1], [2, 2], [1, 2], [1, 1],
        color        => 'blue',
        width        => 1.5,
        fill         => 'self',
        fill_color   => 'green',
        fill_opacity => 0.1,
    );

The following fills the area under the curve y = 4 - x^2 over its whole domain.

    $plot->add_function('4 - x^2', 'x', -2, 2,
        color        => 'blue',
        name         => 'A',
        fill         => 'xaxis',
        fill_color   => 'red',
        fill_opacity => 0.2
    );

The following fills the area between the two curves y = 4 - x^2 and y = x^2 - 4,
and only fills in the area between x=-2 and x=2:

    $plot->add_function('4 - x^2', 'x', -3, 3,
        color => 'blue',
        name  => 'A'
    );
    $plot->add_function('x^2 - 4', 'x', -3, 3,
        color        => 'blue',
        name         => 'B',
        fill         => 'A',
        fill_min     => -2,
        fill_max     => 2,
        fill_color   => 'green',
        fill_opacity => 0.2,
    );

=item fill_color

The color used when filling the region. Default: C<color>

=item fill_opacity

A number between 0 and 1 giving the opacity of the fill. Default: 0.5

=item fill_min, fill_max

The minimum and maximum x-value to fill between. If either of these are
not defined, then the fill will use the full domain of the function.
Default: undefined

=item steps

This defines the number of points to generate for a dataset from a function.
Default: 30.

=item polar

If this option is set for a single variable function, the input variable is
treated as an angle for the polar graph of C<< r = f(theta) >>. Default: 0

=item tikz_smooth

Either 0 or 1 to add the TikZ option "smooth" to the plot, which will smooth
out the plot making it look good with fewer steps. By default this is turned
on for functions but off for other datasets. This alters the look of the plot
and can mess with fills. For functions you will need to explicitly turn it
off in cases it has undesirable side effects.

=item continue, continue_left, continue_right

If set to 1, the graph of a non-parametric function using JSXGraph will keep going
both left and right beyond the bounds. This allows zooming out or panning the graph.
This requires the C<Plots::Axes> style C<jsx_navigation> set to 1. This option
implies both C<continue_left> and C<continue_right>, which can be used to extend
the function only one direction. Default: 0

=item jsx_options

A hash reference of options to add to the JSXGraph output of the associated object.

=item tikz_options

Additional pgfplots C<\addplot> options to be appeneded to the tikz output.

=back

=head2 LABELS

Labels can be added to the graph using the C<< $plot->add_label >> method.
Similar to datasets this can be added individually or multiple at once.

    # Add a label at the point ($x, $y).
    $plot->add_label($x, $y, label => $label, @options)>
    # Add multiple labels at once.
    $plot->add_label(
        [$x1, $y1, label => $label1, @options1],
        [$x2, $y2, label => $label2, @options2],
        ...
     );

Labels can be configured using the following options:

=over 5

=item label

The text to be added to the plot.

=item color

The color of the label. Default: 'default_color'

=item fontsize

The font size of the label used. This can be one of 'tiny', 'small', 'medium',
'large', or 'giant'. Default: 'medium'

=item rotate

The rotation of the label in degrees. Default: 0

=item h_align

The horizontal alignment of the text relative to the position of the label,
that states which end of the label is placed at the label's position.
Can be one of 'right', 'center', or 'left'. Default: 'center'

=item v_align

The vertical alignment of the text relative to the position of the label,
that states which end of the label is placed at the label's position.
Can be one of 'top', 'middle', or 'bottom'. Default: 'middle'

=item jsx_options

An hash reference of options to pass to JSXGraph text object.

=item tikz_options

Additional TikZ options to be appended to C<\node> when adding the label.

=back

=head2 STAMPS

Stamps are a single point with a mark drawn at the given point.
Stamps can be added individually or multiple at once:

    # Add a single stamp.
    $plot->add_stamp($x1, $y1, symbol => $symbol, color => $color, radius => $radius);
    # Add Multple stamps.
    $plot->add_stamp(
        [$x1, $y1, symbol => $symbol1, color => $color1, radius => $radius1],
        [$x2, $y2, symbol => $symbol2, color => $color2, radius => $radius2],
        ...
    );

Stamps are here for backwards compatibility with WWplot and GD output, and are
equivalent to creating a dataset with one point when not using GD output (with
the small difference that stamps are added after all other datasets have been added).

=head2 FILL REGIONS

Fill regions define a point which GD will fill with a color until it hits a boundary curve.
This is only here for backwards comparability with WWplot and GD output. This will not
work with TikZ output, instead using the fill methods mentioned above.

    # Add a single fill region.
    $plot->add_fill_region($x1, $y1, $color);
    # Add multiple fill regions.
    $plot->add_fill_region(
        [$x1, $y1, $color1],
        [$x2, $y2, $color2],
        ...
    );

=head2 COLORS

Colors are referenced by color names. The default color names, and their RGB definition are:

    Color Name        Red Grn Blu
    white             255 255 255
    gray/grey         128 128 128
    black               0   0   0
    red               255   0   0
    green               0 128   0
    blue                0   0 255
    yellow            255 255   0
    cyan                0 255 255
    magenta           255   0 255
    orange            255 128   0
    purple            128   0 128

The default color used for all plotted elements is named C<default_color>, and is initially black.
Redefining this color will change the default color used for any plot object.

New colors can be added, or existing colors can be modified, using the C<< $plot->add_color >> method.
Colors can be added individually or multiple using a single call.

    # Add a single color.
    $plot->add_color($color_name, $red, $green, $blue);
    # Add multiple colors.
    $plot->add_color(
        [$color_name1, $red1, $green1, $blue1],
        [$color_name2, $red2, $green2, $blue2],
        ...
    );

=head1 TIKZ DEBUGGING

When using Tikz output, the pgfplots code used to create the plot is stored in C<< $plot->{tikzCode} >>,
after the image has been drawn (added to the problem with insertGraph). In addition there is a special
debugging option C<< $plot->{tikzDebug} >>, which if set will bypass building the graph with latex, allowing
access to the tikz code (useful if there is an error in generating the plot). Last the method
C<< $plot->tikz_code >> will return the code in pre tags to format inside a problem. For instance to view
the tikz code of a graph that is failing to build use:

    $plot->{tikzDebug} = 1;
    $image = insertGraph($plot);
    BEGIN_PGML
    [@ $plot->tikz_code @]*
    END_PGML

=cut

BEGIN {
	strict->import;
}

sub _plots_init { }

sub Plot { Plots::Plot->new(@_); }
