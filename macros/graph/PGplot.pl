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

PGplot.pl - An object to create dynamic graphs to include in PG problems.

=head1 DESCRIPTION

This macro creates a PGplot object that is used to add data of different
elements of a 2D plot, then draw the plot. The plots can be drawn using different
formats. Currently the legacy GD graphics format and TikZ (using pgfplots)
are available.

=head1 USAGE

First create a PGplot object:

    loadMacros('PGplot.pl');
    $plot = PGplot();

Configure the L<Axes|Axes.pl>:

    $plot->axes->xaxis(
        min   => 0,
        max   => 10,
        ticks => [0, 2, 4, 6, 8, 10],
        label => '\(t\)',
    );
    $plot->axes->yaxis(
        min   => 0,
        max   => 500,
        ticks => [0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500],
        label => '\(h(t)\)'
    );
    $plot->axes->style(title => 'Height of an object as a function of time.');

Add a function and other objects to the plot.

    $plot->add_function('-16t^2 + 80t + 384', 't', 0, 8, color => blue, width => 3);

Insert the graph into the problem.

    BEGIN_PGML
    [@ image(insertGraph($plot), width => 500) @]*
    END_PGML

=head1 PLOT ELEMENTS

A plot consists of multiple L<Data|Data.pl> objects, which define datasets, functions,
and labels to add to the graph. Data objects should be created though the PGplot object,
but can be access directly if needed

=head2 DATASETS

The core plot element is a dataset, which is a collection of points and options
to plot the data. Datasets are added to a plot via C<$plot-E<gt>add_dataset>, and
can be added individually, or multiple at once as shown:

    # Add a single dataset
    $plot->add_dataset([$x1, $y1], [$x2, $y2], ..., [$xn, $yn], @options)>
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
        [[0, 0], [2,3], color => 'green', end_mark => 'arrow'],
        [[2, 3], [4,-1], color => 'blue', end_mark => 'arrow'],
        [[0, 0], [4, -1], color => 'red', end_mark => 'arrow'],
    );

If needed, the C<$plot-E<gt>add_dataset> method returns the L<Data|Data.pl> object
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

Functions can also be added using function strings. Function strings are of the form:

    "$function for $variable in <$min,$max> using option1:value1 and option2:value2"

This can be used to add either single variable functions or parametric functions:

    'x^2 for x in [-5,5) using color:red, weight:3 and steps:15'
    '(5cos(t), 5sin(t)) for t in <2,2pi> using color:blue, weight:2 and steps:20'

The interval end points configure if an open_circle, C<(> or C<)>, closed_circle, C<[> or C<]>,
arrow, C<{> or C<}>, or no marker, C<E<lt>> or C<E<gt>>, are added to the ends of the plot. Options are
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

=head2 DATASET OPTIONS

The following are the options that can be used to configure how datasets and functions are plotted.

=over 5

=item color

The color of the plot. Default: 'default_color'

=item width

The line width of the plot. Default: 1

=item linestyle

Linestyle can be one of 'solid', 'dashed', 'dotted', 'densely dashed',
'loosely dashed', 'densely dotted', 'loosely dotted', or 'none'. If set
to 'none', only the points are shown (see marks for point options) For
convince underscores can also be used, such as 'densely_dashed'.
Default: 'solid'

=item marks

Configures the symbol used for plotting the points in the dataset. Marks
can be one of 'none', 'open_circle', 'closed_circle', 'plus', 'times',
'dash', 'bar', 'asterisk', 'star', 'oplus', 'otimes', or 'diamond'.
Default: 'none'

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

=item name

The name assigned to the dataset to reference it for filling (see below).

=item fill

Sets the fill method to use. If set to 'none', no fill will be added.
If set to 'self', the object fills within itself, best used with closed
datasets. If set to 'xaxis', this will fill the area between the curve
and the x-axis. If set to another non-empty string, this is the name of the
other dataset to fill against.

The following creates a filled rectangle:

    $plot->add_dataset([1, 1], [2, 1], [2, 2], [1, 2], [1, 1],
        color        => 'blue',
        width        => 1.5,
        fill         => 'self',
        fill_color   => 'green',
        fill_opacity => 0.1,
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
        fill_opacity => 0.2,
        fill_range   => '-2,2',
        fill_color   => 'green',
    );

=item fill_color

The color used when filling the region. Default: 'default_color'

=item fill_opacity

A number between 0 and 1 giving the opacity of the fill. Default: 0.5

=item fill_range

This is a string that contains two number separated by a comma, C<"$min,$max">. This gives
the domain of the fill when filling between two curves or the x-axis. Useful to only fill
a piece of the curve. Default: ''

=item steps

This defines the number of points to generate for a dataset from a function.
Default: 20.

=item tikzOpts

Additional pgfplots C<\addplot> options to be added to the tikz output.

=back

=head2 LABELS

Labels can be added to the graph using the C<$plot-E<gt>add_label> method.
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

The size of the label used in GD output. This can be one of
'tiny', 'small', 'medium', 'large', or 'giant'. Default: 'medium'

=item orientation

The orientation of the font in GD output. Can be one of 'vertical' or 'horizontal'.
Default: 'horizontal'

=item h_align

The horizontal alignment of the text relative to the position of the label,
that states which end of the label is placed at the label's position.
Can be one of 'right', 'center', or 'left'. Default: 'center'

=item v_align

The vertical alignment of the text relative to the position of the label,
that states which end of the label is placed at the label's position.
Can be one of 'top', 'middle', or 'bottom'. Default: 'middle'

=item tikzOpts

Additional TikZ options to be used when adding the label using TikZ output via C<\node>.

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
    background_color  255 255 255
    default_color     0   0   0
    white             255 255 255
    black             0   0   0
    red               255 0   0
    green             0   255 0
    blue              0   0   255
    yellow            255 255 0
    orange            255 100 0
    gray              180 180 180
    nearwhite         254 254 254

New colors can be added, or existing colors can be modified, using the C<$plot-E<gt>add_color> method.
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

When using Tikz output, the pgfplots code used to create the plot is stored in C<$plot-E<gt>{tikzCode}>,
after the image has been drawn (added to the problem with insertGraph). In addition there is a special
debugging option C<$plot-E<gt>{tikzDebug}>, which if set will bypass building the graph with latex, allowing
access to the tikz code (useful if there is an error in generating the plot). Last the method
C<$plot-E<gt>tikz_code> will return the code in pre tags to format inside a problem. For instance to view
the tikz code of a graph that is failing to build use:

    $plot->{tikzDebug} = 1;
    $image = insertGraph($plot);
    $tikzCode = $plot->tikz_code;
    BEGIN_PGML
    [$tikzCode]*
    END_PGML

=cut

BEGIN {
	strict->import;
}

loadMacros('MathObjects.pl', 'PGplot/Axes.pl', 'PGplot/Data.pl', 'PGplot/GD.pl', 'PGplot/Tikz.pl');

sub _PGplot_init { }

sub PGplot { PGplot->new(@_); }

package PGplot;

sub new {
	my $class = shift;
	my $size  = $main::envir{onTheFlyImageSize} || 500;

	my $self = {
		imageName => {},
		type      => 'Tikz',
		ext       => 'svg',
		size      => [ $size, $size ],
		axes      => PGplot::Axes->new,
		colors    => {},
		data      => [],
		@_
	};

	bless $self, $class;
	$self->color_init;
	return $self;
}

sub colors {
	my ($self, $color) = @_;
	return defined($color) ? $self->{colors}{$color} : $self->{colors};
}

sub _add_color {
	my ($self, $color, $r, $g, $b) = @_;
	$self->{'colors'}{$color} = [ $r, $g, $b ];
	return;
}

sub add_color {
	my $self = shift;
	if (ref($_[0]) eq 'ARRAY') {
		for (@_) { $self->_add_color(@$_); }
	} else {
		$self->_add_color(@_);
	}
	return;
}

# Define some base colors.
sub color_init {
	my $self = shift;
	$self->add_color('background_color', 255, 255, 255);
	$self->add_color('default_color',    0,   0,   0);
	$self->add_color('white',            255, 255, 255);
	$self->add_color('black',            0,   0,   0);
	$self->add_color('red',              255, 0,   0);
	$self->add_color('green',            0,   255, 0);
	$self->add_color('blue',             0,   0,   255);
	$self->add_color('yellow',           255, 255, 0);
	$self->add_color('orange',           255, 100, 0);
	$self->add_color('gray',             180, 180, 180);
	$self->add_color('nearwhite',        254, 254, 254);
	return;
}

sub size {
	my $self = shift;
	return wantarray ? @{ $self->{size} } : $self->{size};
}

sub data {
	my ($self, @names) = @_;
	return wantarray ? @{ $self->{data} } : $self->{data} unless @names;
	my @data = grep { my $name = $_->name; grep(/^$name$/, @names) } @{ $self->{data} };
	return wantarray ? @data : \@data;
}

sub add_data {
	my ($self, $data) = @_;
	push(@{ $self->{data} }, $data);
	return;
}

sub axes {
	my $self = shift;
	return $self->{axes};
}

sub get_image_name {
	my $self = shift;
	my $ext  = $self->ext;
	return $self->{imageName}{$ext} if $self->{imageName}{$ext};
	$self->{imageName}{$ext} = $main::PG->getUniqueName($ext);
	return $self->{imageName}{$ext};
}

sub imageName {
	my ($self, $name) = @_;
	return $self->get_image_name unless $name;
	$self->{imageName}{ $self->ext } = $name;
	return;
}

sub image_type {
	my ($self, $type, $ext) = @_;
	return $self->{type} unless $type;

	# Check type and extension are valid. The first element of @validExt is used as default.
	my @validExt;
	$type = lc($type);
	if ($type eq 'tikz') {
		$self->{type} = 'Tikz';
		@validExt = ('svg', 'png', 'pdf');
	} elsif ($type eq 'gd') {
		$self->{type} = 'GD';
		@validExt = ('png', 'gif');
	} else {
		warn "PGplot: Invalid image type $type.";
		return;
	}

	if ($ext) {
		if (grep(/^$ext$/, @validExt)) {
			$self->{ext} = $ext;
		} else {
			warn "PGplot: Invalid image extension $ext.";
		}
	} else {
		$self->{ext} = $validExt[0];
	}
	return;
}

# Tikz needs to use pdf for hardcopy generation.
sub ext {
	my $self = shift;
	return 'pdf' if ($self->{type} eq 'Tikz' && $main::displayMode eq 'TeX');
	return $self->{ext};
}

# Return a copy of the tikz code (available after the image has been drawn).
# Set $plot->{tikzDebug} to 1 to just generate the tikzCode, and not create a graph.
sub tikz_code {
	my $self = shift;
	return ($self->{tikzCode} && $main::displayMode =~ /HTML/) ? '<pre>' . $self->{tikzCode} . '</pre>' : '';
}

# Add functions to the graph.
sub value_to_sub {
	my ($self, $formula, $var) = @_;
	return sub { return $_[0]; }
		if $formula eq $var;
	unless (Value::isFormula($formula)) {
		my $localContext = Parser::Context->current(\%main::context)->copy;
		$localContext->variables->add($var => 'Real') unless $localContext->variables->get($var);
		$formula = Value->Package('Formula()')->new($localContext, $formula);
	}

	my $sub = $formula->perlFunction(undef, [$var]);
	return sub {
		my $x = shift;
		my $y = Parser::Eval($sub, $x);
		return defined $y ? $y->value : undef;
	};
}

sub _add_function {
	my ($self, $Fx, $Fy, $var, $min, $max, @rest) = @_;
	$var = 't'  unless $var;
	$Fx  = $var unless defined($Fx);
	my %options = (
		x_string => ref($Fx) eq 'CODE' ? 'perl' : Value::isFormula($Fx) ? $Fx->string : $Fx,
		y_string => ref($Fy) eq 'CODE' ? 'perl' : Value::isFormula($Fy) ? $Fy->string : $Fy,
		variable => $var,
		@rest
	);
	$Fx = $self->value_to_sub($Fx, $var) unless ref($Fx) eq 'CODE';
	$Fy = $self->value_to_sub($Fy, $var) unless ref($Fy) eq 'CODE';

	my $data = PGplot::Data->new(name => 'function');
	$data->style(
		color  => 'default_color',
		width  => 1,
		dashed => 0,
		%options
	);
	$data->set_function(
		sub_x => $Fx,
		sub_y => $Fy,
		min   => $min,
		max   => $max,
	);
	$self->add_data($data);
	return $data;
}

# Format: Accepts both functions y = f(x) and parametric functions (x(t), y(t)).
#   f(x) for x in <a,b> using color:red and weight:3 and steps:15
#   x(t),y(t) for t in [a,b] using color:green and weight:1 and steps:35
#   (x(t),y(t)) for t in (a,b] using color:blue and weight:2 and steps:20
sub parse_function_string {
	my ($self, $fn) = @_;
	unless ($fn =~
		/^(.+)for\s*(\w+)\s*in\s*([\(\[\<\{])\s*([^,\s]+)\s*,\s*([^,\s]+)\s*([\)\]\>\}])\s*(using)?\s*(.*)?$/)
	{
		warn "Error parsing function: $fn";
		return;
	}

	my ($rule, $var, $start, $min, $max, $end, $options) = ($1, $2, $3, $4, $5, $6, $8);
	if    ($start eq '(') { $start = 'open_circle'; }
	elsif ($start eq '[') { $start = 'closed_circle'; }
	elsif ($start eq '{') { $start = 'arrow'; }
	else                  { $start = 'none'; }
	if    ($end eq ')') { $end = 'open_circle'; }
	elsif ($end eq ']') { $end = 'closed_circle'; }
	elsif ($end eq '}') { $end = 'arrow'; }
	else                { $end = 'none'; }

	# Deal with the possibility of 'option1:value1, option2:value2, and option3:value3'.
	$options =~ s/,\s*and/,/;
	my %opts = (
		start_mark => $start,
		end_mark   => $end,
		$options ? split(/\s*and\s*|\s*:\s*|\s*,\s*|\s*=\s*|\s+/, $options) : ()
	);

	if ($rule =~ /^\s*[\(\[\<]\s*([^,]+)\s*,\s*([^,]+)\s*[\)\]\>]\s*$/ || $rule =~ /^\s*([^,]+)\s*,\s*([^,]+)\s*$/) {
		my ($rule_x, $rule_y) = ($1, $2);
		return $self->_add_function($rule_x, $rule_y, $var, $min, $max, %opts);
	}
	return $self->_add_function($var, $rule, $var, $min, $max, %opts);
}

sub add_function {
	my ($self, $f, @rest) = @_;
	if ($f =~ /for.+in/) {
		return @rest ? [ map { $self->parse_function_string($_); } ($f, @rest) ] : $self->parse_function_string($f);
	} elsif (ref($f) eq 'ARRAY' && scalar(@$f) > 2) {
		my @data;
		for ($f, @rest) {
			my ($g, @options) = @$_;
			push(@data,
				ref($g) eq 'ARRAY'
				? $self->_add_function($g->[0], $g->[1], @options)
				: $self->_add_function(undef,   $g,      @options));
		}
		return scalar(@data) > 1 ? \@data : $data[0];
	}
	return ref($f) eq 'ARRAY' ? $self->_add_function($f->[0], $f->[1], @rest) : $self->_add_function(undef, $f, @rest);
}

# Add a dataset to the graph. A dataset is basically a function in which the data
# is provided as a list of points, [$x1, $y1], [$x2, $y2], ..., [$xn, $yn].
# Datasets can be used for points, arrows, lines, polygons, scatter plots, and so on.
sub _add_dataset {
	my ($self, @points) = @_;
	my $data = PGplot::Data->new(name => 'dataset');
	while (@points) {
		last unless ref($points[0]) eq 'ARRAY';
		$data->add(@{ shift(@points) });
	}
	$data->style(
		color => 'default_color',
		width => 1,
		@points
	);

	$self->add_data($data);
	return $data;
}

sub add_dataset {
	my $self = shift;
	if (ref($_[0]) eq 'ARRAY' && ref($_[0]->[0]) eq 'ARRAY') {
		return [ map { $self->_add_dataset(@$_); } @_ ];
	}
	return $self->_add_dataset(@_);
}

sub _add_label {
	my ($self, $x, $y, @options) = @_;
	my $data = PGplot::Data->new(name => 'label');
	$data->add($x, $y);
	$data->style(
		color       => 'default_color',
		fontsize    => 'medium',
		orientation => 'horizontal',
		h_align     => 'center',
		v_align     => 'middle',
		label       => '',
		@options
	);

	$self->add_data($data);
	return $data;
}

sub add_label {
	my $self = shift;
	return ref($_[0]) eq 'ARRAY' ? [ map { $self->_add_label(@$_); } @_ ] : $self->_add_label(@_);
}

# Fill regions only work with GD and are ignored in TikZ images.
sub _add_fill_region {
	my ($self, $x, $y, $color) = @_;
	my $data = PGplot::Data->new(name => 'fill_region');
	$data->add($x, $y);
	$data->style(color => $color || 'default_color');
	$self->add_data($data);
	return $data;
}

sub add_fill_region {
	my $self = shift;
	return ref($_[0]) eq 'ARRAY' ? [ map { $self->_add_fill_region(@$_); } @_ ] : $self->_add_fill_region(@_);
}

sub _add_stamp {
	my ($self, $x, $y, @options) = @_;
	my $data = PGplot::Data->new(name => 'stamp');
	$data->add($x, $y);
	$data->style(
		color  => 'default_color',
		size   => 4,
		symbol => 'closed_circle',
		@options
	);
	$self->add_data($data);
	return $data;
}

sub add_stamp {
	my $self = shift;
	return ref($_[0]) eq 'ARRAY' ? [ map { $self->_add_stamp(@$_); } @_ ] : $self->_add_stamp(@_);
}

# Output the image based on a configurable type:
sub draw {
	my $self = shift;
	my $type = $self->{type};

	my $image;
	if ($type eq 'GD') {
		$image = PGplot::GD->new($self);
	} elsif ($type eq 'Tikz') {
		$image = PGplot::Tikz->new($self);
	} else {
		warn "Undefined image type: $type";
		return;
	}
	return $image->draw;
}

1;
