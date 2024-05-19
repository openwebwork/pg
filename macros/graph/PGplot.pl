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

Configure the L<Axes|/"AXES OBJECT">:

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

A plot consists of multiple L<Data|/"DATA OBJECT"> objects, which define datasets, functions,
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

If needed, the C<$plot-E<gt>add_dataset> method returns the L<Data|/"DATA OBJECT"> object
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

# Tikz/PGFPlots output
package PGplot::Tikz;

sub new {
	my ($class, $pgplot) = @_;
	my $image = new LaTeXImage;
	$image->environment('tikzpicture');
	$image->svgMethod($main::envir{latexImageSVGMethod}           // 'pdf2svg');
	$image->convertOptions($main::envir{latexImageConvertOptions} // { input => {}, output => {} });
	$image->ext($pgplot->ext);
	$image->tikzLibraries('arrows.meta');
	$image->texPackages(['pgfplots']);
	$image->addToPreamble('\pgfplotsset{compat=1.18}\usepgfplotslibrary{fillbetween}');

	my $self = {
		image  => $image,
		pgplot => $pgplot,
		colors => {},
	};
	bless $self, $class;

	return $self;
}

sub pgplot {
	my $self = shift;
	return $self->{pgplot};
}

sub im {
	my $self = shift;
	return $self->{image};
}

sub get_color {
	my ($self, $color) = @_;
	return '' if $self->{colors}{$color};
	my ($r, $g, $b) = @{ $self->pgplot->colors($color) };
	$self->{colors}{$color} = 1;
	return "\\definecolor{$color}{RGB}{$r,$g,$b}\n";
}

sub configure_axes {
	my $self   = shift;
	my $pgplot = $self->pgplot;
	my $axes   = $pgplot->axes;
	my $grid   = $axes->grid;
	my ($xmin, $ymin, $xmax, $ymax) = $axes->bounds;
	my ($axes_height, $axes_width) = $pgplot->size;
	my $show_grid   = $axes->style('show_grid');
	my $xmajor      = $show_grid && $grid->{xmajor} ? 'true'          : 'false';
	my $xminor_num  = $show_grid && $grid->{xmajor} ? $grid->{xminor} : 0;
	my $xminor      = $xminor_num > 0 ? 'true' : 'false';
	my $ymajor      = $show_grid && $grid->{ymajor} ? 'true'          : 'false';
	my $yminor_num  = $show_grid && $grid->{ymajor} ? $grid->{yminor} : 0;
	my $yminor      = $yminor_num > 0 ? 'true' : 'false';
	my $xticks      = join(',', @{ $grid->{xticks} });
	my $yticks      = join(',', @{ $grid->{yticks} });
	my $grid_color  = $axes->style('grid_color');
	my $grid_color2 = $self->get_color($grid_color);
	my $grid_alpha  = $axes->style('grid_alpha');
	my $grid_style  = $axes->style('grid_style');
	my $xlabel      = $axes->xaxis('label');
	my $axis_x_line = $axes->xaxis('location');
	my $ylabel      = $axes->yaxis('label');
	my $axis_y_line = $axes->yaxis('location');
	my $title       = $axes->style('title');
	my $axis_on_top = $axes->style('axis_on_top') ? "axis on top,\n\t\t\t" : '';
	my $hide_x_axis = '';
	my $hide_y_axis = '';
	my $xaxis_plot  = ($xmin <= 0 && $xmax >= 0) ? "\\path[name path=xaxis] ($xmin, 0) -- ($xmax,0);\n" : '';

	unless ($axes->xaxis('visible')) {
		$xlabel = '';
		$hide_x_axis =
			"\n\t\t\tx axis line style={draw=none},\n"
			. "\t\t\tx tick style={draw=none},\n"
			. "\t\t\txticklabel=\\empty,";
	}
	unless ($axes->yaxis('visible')) {
		$ylabel = '';
		$hide_y_axis =
			"\n\t\t\ty axis line style={draw=none},\n"
			. "\t\t\ty tick style={draw=none},\n"
			. "\t\t\tyticklabel=\\empty,";
	}
	my $tikzCode = <<END_TIKZ;
		\\begin{axis}
		[
			height=$axes_height,
			width=$axes_width,
			${axis_on_top}axis x line=$axis_x_line,
			axis y line=$axis_y_line,
			xlabel={$xlabel},
			ylabel={$ylabel},
			title={$title},
			xtick={$xticks},
			ytick={$yticks},
			xmajorgrids=$xmajor,
			xminorgrids=$xminor,
			minor x tick num=$xminor_num,
			ymajorgrids=$ymajor,
			yminorgrids=$yminor,
			minor y tick num=$yminor_num,
			grid style={$grid_color!$grid_alpha, $grid_style},
			xmin=$xmin,
			xmax=$xmax,
			ymin=$ymin,
			ymax=$ymax,$hide_x_axis$hide_y_axis
		]
		$grid_color2$xaxis_plot
END_TIKZ
	chop($tikzCode);
	$tikzCode =~ s/^\t\t//;
	$tikzCode =~ s/\n\t\t/\n/g;

	return $tikzCode;
}

sub get_plot_opts {
	my ($self, $data) = @_;
	my $color        = $data->style('color')        || 'default_color';
	my $width        = $data->style('width')        || 1;
	my $linestyle    = $data->style('linestyle')    || 'solid';
	my $marks        = $data->style('marks')        || 'none';
	my $mark_size    = $data->style('mark_size')    || 0;
	my $start        = $data->style('start_mark')   || 'none';
	my $end          = $data->style('end_mark')     || 'none';
	my $name         = $data->style('name')         || '';
	my $fill         = $data->style('fill')         || 'none';
	my $fill_color   = $data->style('fill_color')   || 'default_color';
	my $fill_opacity = $data->style('fill_opacity') || 0.5;
	my $tikzOpts     = $data->style('tikzOpts')     || '';

	if ($start =~ /circle/) {
		$start = '{Circle[sep=-1.196825pt -1.595769' . ($start eq 'open_circle' ? ', open' : '') . ']}';
	} elsif ($start eq 'arrow') {
		$start = '{Latex}';
	} else {
		$start = '';
	}
	if ($end =~ /circle/) {
		$end = '{Circle[sep=-1.196825pt -1.595769' . ($end eq 'open_circle' ? ', open' : '') . ']}';
	} elsif ($end eq 'arrow') {
		$end = '{Latex}';
	} else {
		$end = '';
	}
	my $end_markers = ($start || $end) ? ", $start-$end" : '';
	$marks = {
		closed_circle => '*',
		open_circle   => 'o',
		plus          => '+',
		times         => 'x',
		bar           => '|',
		dash          => '-',
		asterisk      => 'asterisk',
		star          => 'star',
		oplus         => 'oplus',
		otimes        => 'otimes',
		diamond       => 'diamond',
		none          => '',
	}->{$marks};
	$marks = $marks ? $mark_size ? ", mark=$marks, mark size=${mark_size}px" : ", mark=$marks" : '';
	$linestyle = $linestyle eq 'none' ? ', only marks' : ', ' . ($linestyle =~ s/_/ /gr);
	if ($fill eq 'self') {
		$fill = ", fill=$fill_color, fill opacity=$fill_opacity";
	} else {
		$fill = '';
	}
	$name     = ", name path=$name" if $name;
	$tikzOpts = ", $tikzOpts"       if $tikzOpts;

	return "color=$color, line width=${width}pt$marks$linestyle$end_markers$fill$name$tikzOpts";
}

sub draw {
	my $self   = shift;
	my $pgplot = $self->pgplot;

	# Reset colors just in case.
	$self->{colors} = {};

	# Add Axes
	my $tikzCode = $self->configure_axes;

	# Plot Data
	for my $data ($pgplot->data('function', 'dataset')) {
		$data->gen_data;
		my $n          = $data->size;
		my $color      = $data->style('color')      || 'default_color';
		my $fill       = $data->style('fill')       || 'none';
		my $fill_color = $data->style('fill_color') || 'default_color';
		my $tikzData   = join(' ', map { '(' . $data->x($_) . ',' . $data->y($_) . ')'; } (0 .. $n - 1));
		my $tikzOpts   = $self->get_plot_opts($data);
		$tikzCode .= $self->get_color($fill_color) unless $fill eq 'none';
		$tikzCode .= $self->get_color($color) . "\\addplot[$tikzOpts] coordinates {$tikzData};\n";

		unless ($fill eq 'none' || $fill eq 'self') {
			my $opacity    = $data->style('fill_opacity') || 0.5;
			my $fill_range = $data->style('fill_range')   || '';
			my $name       = $data->style('name')         || '';
			$opacity *= 100;
			if ($fill_range) {
				my ($min_fill, $max_fill) = split(',', $fill_range);
				$fill_range = ", soft clip={domain=$min_fill:$max_fill}";
			}
			$tikzCode .= "\\addplot[$fill_color!$opacity] fill between[of=$name and $fill$fill_range];\n";
		}
	}

	# Stamps
	for my $stamp ($pgplot->data('stamp')) {
		my $mark = {
			closed_circle => '*',
			open_circle   => 'o',
			plus          => '+',
			times         => 'x',
			bar           => '|',
			dash          => '-',
			asterisk      => 'asterisk',
			star          => 'star',
			oplus         => 'oplus',
			otimes        => 'otimes',
			diamond       => 'diamond',
			none          => '',
		}->{ $stamp->style('symbol') };
		my $color = $stamp->style('color') || 'default_color';
		my $x     = $stamp->x(0);
		my $y     = $stamp->y(0);
		my $r     = $stamp->style('radius') || 4;
		$tikzCode .= $self->get_color($color)
			. "\\addplot[$color, mark=$mark, mark size=${r}pt, only marks] coordinates {($x,$y)};\n";
	}

	# Labels
	for my $label ($pgplot->data('label')) {
		my $str         = $label->style('label');
		my $x           = $label->x(0);
		my $y           = $label->y(0);
		my $color       = $label->style('color')       || 'default_color';
		my $fontsize    = $label->style('fontsize')    || 'medium';
		my $orientation = $label->style('orientation') || 'horizontal';
		my $tikzOpts    = $label->style('tikzOpts')    || '';
		my $h_align     = $label->style('h_align')     || 'center';
		my $v_align     = $label->style('v_align')     || 'middle';
		my $anchor      = $v_align eq 'top' ? 'north' : $v_align eq 'bottom' ? 'south' : '';
		$str = {
			tiny   => '\tiny ',
			small  => '\small ',
			medium => '',
			large  => '\large ',
			giant  => '\Large ',
		}->{$fontsize}
			. $str;
		$anchor .= $h_align eq 'left' ? ' west' : $h_align eq 'right' ? ' east' : '';
		$tikzOpts = $tikzOpts ? "$color, $tikzOpts" : $color;
		$tikzOpts = "anchor=$anchor, $tikzOpts" if $anchor;
		$tikzOpts = "rotate=90, $tikzOpts"      if $orientation eq 'vertical';
		$tikzCode .= $self->get_color($color) . "\\node[$tikzOpts] at (axis cs: $x,$y) {$str};\n";
	}
	$tikzCode .= '\end{axis}' . "\n";

	$pgplot->{tikzCode} = $tikzCode;
	$self->im->tex($tikzCode);
	return $pgplot->{tikzDebug} ? '' : $self->im->draw;
}

# GD Output
package PGplot::GD;

sub new {
	my ($class, $pgplot) = @_;
	my $self = {
		image    => '',
		pgplot   => $pgplot,
		position => [ 0, 0 ],
		colors   => {},
	};
	bless $self, $class;

	$self->{image} = new GD::Image($pgplot->size);
	return $self;
}

sub pgplot {
	my $self = shift;
	return $self->{pgplot};
}

sub im {
	my $self = shift;
	return $self->{image};
}

sub position {
	my ($self, $x, $y) = @_;
	return wantarray ? @{ $self->{position} } : $self->{position} unless (defined($x) && defined($y));
	$self->{position} = [ $x, $y ];
	return;
}

sub color {
	my ($self, $color) = @_;
	$self->{colors}{$color} = $self->im->colorAllocate(@{ $self->pgplot->colors($color) })
		unless $self->{colors}{$color};
	return $self->{colors}{$color};
}

# Translate x and y coordinates to pixels on the graph.
sub im_x {
	my ($self, $x) = @_;
	return unless defined($x);
	my $pgplot = $self->pgplot;
	my ($xmin, $xmax) = ($pgplot->axes->xaxis('min'), $pgplot->axes->xaxis('max'));
	return int(($x - $xmin) * ($pgplot->size)[0] / ($xmax - $xmin));
}

sub im_y {
	my ($self, $y) = @_;
	return unless defined($y);
	my $pgplot = $self->pgplot;
	my ($ymin, $ymax) = ($pgplot->axes->yaxis('min'), $pgplot->axes->yaxis('max'));
	return int(($ymax - $y) * ($pgplot->size)[1] / ($ymax - $ymin));
}

sub moveTo {
	my ($self, $x, $y) = @_;
	$x = $self->im_x($x);
	$y = $self->im_y($y);
	$self->position($x, $y);
	return;
}

sub lineTo {
	my ($self, $x, $y, $color, $width, $dashed) = @_;
	$color  = 'default_color' unless defined($color);
	$color  = $self->color($color);
	$width  = 1 unless defined($width);
	$dashed = 0 unless defined($dashed);
	$x      = $self->im_x($x);
	$y      = $self->im_y($y);

	$self->im->setThickness($width);
	if ($dashed =~ /dash/) {
		my @dashing = ($color) x (4 * $width * $width);
		my @spacing = (GD::gdTransparent) x (3 * $width * $width);
		$self->im->setStyle(@dashing, @spacing);
		$self->im->line($self->position, $x, $y, GD::gdStyled);
	} elsif ($dashed =~ /dot/) {
		my @dashing = ($color) x (1 * $width * $width);
		my @spacing = (GD::gdTransparent) x (2 * $width * $width);
		$self->im->setStyle(@dashing, @spacing);
		$self->im->line($self->position, $x, $y, GD::gdStyled);
	} else {
		$self->im->line($self->position, $x, $y, $color);
	}
	$self->im->setThickness(1);
	$self->position($x, $y);
	return;
}

# Draw functions / lines / arrows
sub draw_data {
	my ($self, $pass) = @_;
	my $pgplot = $self->pgplot;
	$pass = 0 unless $pass;
	for my $data ($pgplot->data('function', 'dataset')) {
		$data->gen_data;
		my $n     = $data->size - 1;
		my $x     = $data->x;
		my $y     = $data->y;
		my $color = $data->style('color');
		my $width = $data->style('width');
		$self->moveTo($x->[0], $y->[0]);
		for (1 .. $n) {
			$self->lineTo($x->[$_], $y->[$_], $color, $width, $data->style('linestyle'));
		}

		if ($pass == 2) {
			my $r     = int(3 + $width);
			my $start = $data->style('start_mark') || 'none';
			if ($start eq 'closed_circle') {
				$self->draw_circle_stamp($data->x(0), $data->y(0), $r, $color, 1);
			} elsif ($start eq 'open_circle') {
				$self->draw_circle_stamp($data->x(0), $data->y(0), $r, $color);
			} elsif ($start eq 'arrow') {
				$self->draw_arrow_head($data->x(1), $data->y(1), $data->x(0), $data->y(0), $color, $width);
			}

			my $end = $data->style('end_mark') || 'none';
			if ($end eq 'closed_circle') {
				$self->draw_circle_stamp($data->x($n), $data->y($n), $r, $color, 1);
			} elsif ($end eq 'open_circle') {
				$self->draw_circle_stamp($data->x($n), $data->y($n), $r, $color);
			} elsif ($end eq 'arrow') {
				$self->draw_arrow_head($data->x($n - 1), $data->y($n - 1), $data->x($n), $data->y($n), $color, $width);
			}
		}
	}
	return;
}

# Label helpers
sub get_gd_font {
	my ($self, $font) = @_;
	if    ($font eq 'tiny')  { return GD::gdTinyFont; }
	elsif ($font eq 'small') { return GD::gdSmallFont; }
	elsif ($font eq 'large') { return GD::gdLargeFont; }
	elsif ($font eq 'giant') { return GD::gdGiantFont; }
	return GD::gdMediumBoldFont;
}

sub label_offset {
	my ($self, $loc, $str, $fontsize) = @_;
	my $offset = 0;
	# Add an additional 2px offset for the edges 'right', 'bottom', 'left', and 'top'.
	if    ($loc eq 'right')  { $offset -= length($str) * $fontsize + 2; }
	elsif ($loc eq 'bottom') { $offset -= $fontsize + 2; }
	elsif ($loc eq 'center') { $offset -= length($str) * $fontsize / 2; }
	elsif ($loc eq 'middle') { $offset -= $fontsize / 2; }
	else                     { $offset = 2; }    # Both 'left' and 'top'.
	return $offset;
}

sub draw_label {
	my ($self, $str, $x, $y, %options) = @_;
	my $font  = $self->get_gd_font($options{fontsize} || 'medium');
	my $color = $self->color($options{color}          || 'default_color');
	my $xoff  = $self->label_offset($options{h_align} || 'center', $str, $font->width);
	my $yoff  = $self->label_offset($options{v_align} || 'middle', $str, $font->height);

	if ($options{orientation} && $options{orientation} eq 'vertical') {
		$self->im->stringUp($font, $self->im_x($x) + $xoff, $self->im_y($y) + $yoff, $str, $color);
	} else {
		$self->im->string($font, $self->im_x($x) + $xoff, $self->im_y($y) + $yoff, $str, $color);
	}
	return;
}

sub draw_arrow_head {
	my ($self, $x1, $y1, $x2, $y2, $color, $w) = @_;
	return unless scalar(@_) > 4;
	$color = $self->color($color || 'default_color');
	$w     = 1 unless $w;
	($x1, $y1) = ($self->im_x($x1), $self->im_y($y1));
	($x2, $y2) = ($self->im_x($x2), $self->im_y($y2));

	my $dx   = $x2 - $x1;
	my $dy   = $y2 - $y1;
	my $len  = sqrt($dx * $dx + $dy * $dy);
	my $ux   = $dx / $len;                    # Unit vector in direction of arrow.
	my $uy   = $dy / $len;
	my $px   = -1 * $uy;                      # Unit vector perpendicular to arrow.
	my $py   = $ux;
	my $hbx  = $x2 - 7 * $w * $ux;
	my $hby  = $y2 - 7 * $w * $uy;
	my $head = new GD::Polygon;
	$head->addPt($x2,                 $y2);
	$head->addPt($hbx + 3 * $w * $px, $hby + 3 * $w * $py);
	$head->addPt($hbx - 3 * $w * $px, $hby - 3 * $w * $py);
	$self->im->setThickness($w);
	$self->im->filledPolygon($head, $color);
	$self->im->setThickness(1);
	return;
}

sub draw_circle_stamp {
	my ($self, $x, $y, $r, $color, $filled) = @_;
	my $d = $r ? 2 * $r : 8;
	$color = $self->color($color || 'default_color');
	$self->im->filledArc($self->im_x($x), $self->im_y($y), $d, $d, 0, 360, $self->color('nearwhite'));
	$self->im->filledArc($self->im_x($x), $self->im_y($y), $d, $d, 0, 360, $color, $filled ? () : GD::gdNoFill);
	return;
}

sub draw {
	my $self   = shift;
	my $pgplot = $self->pgplot;
	my $axes   = $pgplot->axes;
	my $grid   = $axes->grid;
	my $size   = $pgplot->size;

	# Initialize image
	$self->im->interlaced('true');
	$self->im->fill(1, 1, $self->color('background_color'));

	# Plot data first, then fill in regions before adding axes, grid, etc.
	$self->draw_data(1);

	# Fill regions
	for my $region ($pgplot->data('fill_region')) {
		$self->im->fill($self->im_x($region->x(0)), $self->im_y($region->y(0)), $self->color($region->style('color')));
	}

	# Gridlines
	my ($xmin, $ymin, $xmax, $ymax) = $axes->bounds;
	my $grid_color = $axes->style('grid_color');
	my $grid_style = $axes->style('grid_style');
	my $show_grid  = $axes->style('show_grid');
	if ($show_grid && $grid->{xmajor}) {
		my $xminor = $grid->{xminor} || 0;
		my $prevx  = $xmin;
		my $dx     = 0;
		my $first  = 1;
		for my $x (@{ $grid->{xticks} }) {
			# Number comparison of $dx and $x - $prevx failed in some tests, so using string comparison.
			$xminor = 0           unless ($first || $dx == 0 || $dx eq $x - $prevx);
			$dx     = $x - $prevx unless $first;
			$prevx  = $x;
			$first  = 0;
			$self->moveTo($x, $ymin);
			$self->lineTo($x, $ymax, $grid_color, 0.5, 1);
		}
		if ($xminor) {
			$dx /= ($xminor + 1);
			for my $x (@{ $grid->{xticks} }) {
				last if $x == $prevx;
				for (1 .. $xminor) {
					my $x2 = $x + $dx * $_;
					$self->moveTo($x2, $ymin);
					$self->lineTo($x2, $ymax, $grid_color, 0.5, 1);
				}
			}
		}
	}
	if ($show_grid && $grid->{ymajor}) {
		my $yminor = $grid->{yminor} || 0;
		my $prevy;
		my $dy    = 0;
		my $first = 1;
		for my $y (@{ $grid->{yticks} }) {
			# Number comparison of $dy and $y - $prevy failed in some tests, so using string comparison.
			$yminor = 0           unless ($first || $dy == 0 || $dy eq $y - $prevy);
			$dy     = $y - $prevy unless $first;
			$prevy  = $y;
			$first  = 0;
			$self->moveTo($xmin, $y);
			$self->lineTo($xmax, $y, $grid_color, 0.5, 1);
		}
		if ($yminor) {
			$dy /= ($yminor + 1);
			for my $y (@{ $grid->{yticks} }) {
				last if $y == $prevy;
				for (1 .. $yminor) {
					my $y2 = $y + $dy * $_;
					$self->moveTo($xmin, $y2);
					$self->lineTo($xmax, $y2, $grid_color, 0.5, 1);
				}
			}
		}
	}

	# Plot axes
	my $show_x = $axes->xaxis('visible');
	my $show_y = $axes->yaxis('visible');
	my $xloc   = $axes->xaxis('location') || 'middle';
	my $yloc   = $axes->yaxis('location') || 'center';
	my $xpos   = ($yloc eq 'box' || $yloc eq 'left')   ? $xmin : $yloc eq 'right' ? $xmax : $axes->yaxis('position');
	my $ypos   = ($xloc eq 'box' || $xloc eq 'bottom') ? $ymin : $xloc eq 'top'   ? $ymax : $axes->xaxis('position');
	$xpos = $xmin if $xpos < $xmin;
	$xpos = $xmax if $xpos > $xmax;
	$ypos = $ymin if $ypos < $ymin;
	$ypos = $ymax if $ypos > $ymax;

	if ($show_x) {
		my $xlabel      = $axes->xaxis('label') =~ s/\\[\(\[\)\]]//gr;
		my $tick_align  = ($self->im_y($ymin) - $self->im_y($ypos) < 5)             ? 'bottom' : 'top';
		my $label_align = ($self->im_y($ypos) - $self->im_y($ymax) < 5)             ? 'top'    : 'bottom';
		my $label_loc   = $yloc eq 'right' && ($xloc eq 'top' || $xloc eq 'bottom') ? $xmin    : $xmax;

		$self->moveTo($xmin, $ypos);
		$self->lineTo($xmax, $ypos, 'black', 1.5, 0);
		$self->draw_label(
			$xlabel, $label_loc, $ypos,
			fontsize => 'large',
			v_align  => $label_align,
			h_align  => $label_loc == $xmin ? 'left' : 'right'
		);
		for my $x (@{ $grid->{xticks} }) {
			$self->draw_label($x, $x, $ypos, font => 'large', v_align => $tick_align, h_align => 'center')
				unless ($x == $xpos && $show_y);
		}
	}
	if ($axes->yaxis('visible')) {
		my $ylabel      = $axes->yaxis('label') =~ s/\\[\(\[\)\]]//gr;
		my $tick_align  = ($self->im_x($xpos) - $self->im_x($xmin) < 5) ? 'left'                              : 'right';
		my $label_align = ($self->im_x($xmax) - $self->im_x($xpos) < 5) ? 'right'                             : 'left';
		my $label_loc   = ($yloc eq 'left' && $xloc eq 'top') || ($yloc eq 'right' && $xloc eq 'top') ? $ymin : $ymax;

		$self->moveTo($xpos, $ymin);
		$self->lineTo($xpos, $ymax, 'black', 1.5, 0);
		$self->draw_label(
			$ylabel, $xpos, $label_loc,
			fontsize => 'large',
			v_align  => $label_loc == $ymin ? 'bottom' : 'top',
			h_align  => $label_align
		);
		for my $y (@{ $grid->{yticks} }) {
			$self->draw_label($y, $xpos, $y, font => 'large', v_align => 'middle', h_align => $tick_align)
				unless ($y == $ypos && $show_x);
		}
	}

	# Draw data a second time to cleanup any issues with the grid and axes.
	$self->draw_data(2);

	# Print Labels
	for my $label ($pgplot->data('label')) {
		$self->draw_label($label->style('label'), $label->x(0), $label->y(0), %{ $label->style });
	}

	# Draw stamps
	for my $stamp ($pgplot->data('stamp')) {
		my $symbol = $stamp->style('symbol');
		my $color  = $stamp->style('color');
		my $r      = $stamp->style('radius') || 4;
		if ($symbol eq 'closed_circle') {
			$self->draw_circle_stamp($stamp->x(0), $stamp->y(0), $r, $color, 1);
		} elsif ($symbol eq 'open_circle') {
			$self->draw_circle_stamp($stamp->x(0), $stamp->y(0), $r, $color);
		}
	}

	# Put a black frame around the picture
	$self->im->rectangle(0, 0, $size->[0] - 1, $size->[1] - 1, $self->color('black'));

	return $pgplot->ext eq 'gif' ? $self->im->gif : $self->im->png;
}

=head1 AXES OBJECT

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

The axes object should be accessed through a PGplot object using C<$plot-E<gt>axes>.
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

=head1 DATA OBJECT

This object holds data about the different types of elements that can be added
to a PGplot graph. This is a hash with some helper methods. Data objects are created
and modified using the PGplot methods, and do not need to generally be
modified in a PG problem.  Each PG add method returns the related data object which
can be used if needed.

Each data object contains the following:

=over 5

=item name

The name is used to identify what type of data is being stored,
such as a function, dataset, label, etc.

=item x

The array of the data points x-value.

=item y

The array of the data points y-value.

=item function

A function (stored as a hash) to generate the x and y data points.

=item styles

An hash of different style options and values that can be used
to store additional data for things like color, width, etc.

=back

=head1 USAGE

The main methods for adding data and accessing the data are:

=over 5

=item C<$data-E<gt>name>

Sets, C<$data-E<gt>name($string)>, or gets C<$data-E<gt>name> the name of the data object.

=item C<$data-E<gt>add>

Adds a single data point, C<$data-E<gt>add($x, $y)>, or adds multiple data points,
C<$data-E<gt>add([$x1, $y1], [$x2, $y2], ..., [$xn, $yn])>.

=item C<$data-E<gt>set_function>

Configures a function to generate data points. C<sub_x> and C<sub_y> are are perl subroutines.

    $data->set_function(
        sub_x => sub { return $_[0]; },
        sub_y => sub { return $_[0]**2; },
        min   => -5,
        max   => 5,
    );

The number of steps used to generate the data is a style and needs to be set separately.

    $data->style(steps => 50);

=item C<$data-E<gt>gen_data>

Generate the data points from a function. This can only be done when there is no data, so
once the data has been generated this will do nothing (to avoid generating data again).

=item C<$data-E<gt>size>

Returns the current number of points being stored.

=item C<$data-E<gt>x> and C<$data-E<gt>y>

Without any inputs, these return either the x array or y array of data points being stored.
A single input can be used to return only the n-th data point, C<$data-E<gt>x($n)>.

=item C<$data-E<gt>style>

Sets or gets style information. Use C<$data-E<gt>style($name)> to get the style value of a single
style name. C<$data-E<gt>style> will returns a reference to the full style hash. Last, input a hash
to add / change the styles.

    $data->style(color => 'blue', width => 3);

=back

=cut

package PGplot::Data;

sub new {
	my $class = shift;
	my $self  = {
		name     => '',
		x        => [],
		y        => [],
		function => {},
		styles   => {},
		@_
	};

	bless $self, $class;
	return $self;
}

sub name {
	my ($self, $name) = @_;
	return $self->{name} unless $name;
	$self->{name} = $name;
	return;
}

sub size {
	my $self = shift;
	return scalar(@{ $self->{x} });
}

sub x {
	my ($self, $n) = @_;
	return $self->{x}->[$n] if (defined($n) && defined($self->{x}->[$n]));
	return wantarray ? @{ $self->{x} } : $self->{x};
}

sub y {
	my ($self, $n) = @_;
	return $self->{y}[$n] if (defined($n) && defined($self->{y}[$n]));
	return wantarray ? @{ $self->{y} } : $self->{y};
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

sub set_function {
	my $self = shift;
	$self->{function} = {
		sub_x => sub { return $_[0]; },
		sub_y => sub { return $_[0]; },
		min   => -5,
		max   => 5,
		@_
	};
	$self->style(steps => $self->{function}{steps}) if $self->{funciton}{steps};
	return;
}

sub _stepsize {
	my $self  = shift;
	my $f     = $self->{function};
	my $steps = $self->style('steps') || 20;
	# Using MathObjects allows bounds like 2pi/3, e^2, et, etc.
	$f->{min} = &main::Real($f->{min})->value if ($f->{min} =~ /[^\d\-\.]/);
	$f->{max} = &main::Real($f->{max})->value if ($f->{max} =~ /[^\d\-\.]/);
	return ($f->{max} - $f->{min}) / $steps;
}

sub gen_data {
	my $self = shift;
	my $f    = $self->{function};
	return if !$f || $self->size;
	my $steps = $self->style('steps') || 20;
	my $dt    = $self->_stepsize;
	my $t     = $f->{min};
	for (0 .. $steps) {
		$self->add(&{ $f->{sub_x} }($t), &{ $f->{sub_y} }($t));
		$t += $dt;
	}
	return;
}

sub _add {
	my ($self, $x, $y) = @_;
	return unless defined($x) && defined($y);
	push(@{ $self->{x} }, $x);
	push(@{ $self->{y} }, $y);
	return;
}

sub add {
	my $self = shift;
	if (ref($_[0]) eq 'ARRAY') {
		for (@_) { $self->_add(@$_); }
	} else {
		$self->_add(@_);
	}
	return;
}

1;
