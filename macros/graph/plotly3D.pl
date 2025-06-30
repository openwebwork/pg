
=head1 NAME

plotly3D.pl - Adds Graph3D, an object for creating 3D parametric curves
and 3D parametric surface plots using the plotly JavaScript library.

=head1 DESCRIPTION

Loading this macro adds the Graph3D method which creates a 3D
graph object. The graph object can be configured by a list of
options of the form "option => value" (see below).

    loadMacros('plotly3D.pl');
    $graph = Graph3D(options => value);

Use the addCurve method to add a parametric curve to the graph.
The following adds a helix to the graph. The first array is
the parametric functions x(t), y(t), and z(t), and the second
array is the bounds with the optional number of points to plot.

    $graph->addCurve(['3*cos(t)', '3*sin(t)', 't'], [0, 6*pi, 150]);

Use the addFunction method to add a two variable function surface
to the graph. The following adds the function f(x,y) = x^2 + y^2.
The first input is the function in terms of x and y, followed
by the x-bounds and y-bounds with the optional number of points to plot.
Note the total points computed is the product of the two numbers given.

    $graph->addFunction('x^2 + y^2', [-4, 4], [-4, 4]);

Use the addSurface method to add a parametric surface to the graph.
The following adds a sphere of radius 3. The first array is the
parametric functions x(u,v), y(u,v), and z(u,v), followed by the
u-bounds and v-bounds with optional number of points to plot.
Note the total points computed is the product of the two numbers given.

    $graph->addSurface(
        ['3*sin(v)*cos(u)', '3*sin(v)*sin(u)', '3*cos(v)'],
        [0, 2*pi, 30],
        [0, pi, 30]
    );

Output the graph in PGML using the Print method.

    [@ $graph->Print @]*

Multiple curves surfaces can be added with the appropriate methods.

=head1 PARAMETRIC CURVES

The addCurve method takes two arrays as input followed by a list
of options. The first array is three parametric functions, followed
by the minimum, maximum, and optional number of points to plot.
If the number of points is not given, it defaults to 100.

    $graph->addCurve(
        [xFunction, yFunction, zFunction],
        [tMin, tMax, tCount],
        options
    );

The additional options are given in a 'option => value' format.
The current available options (and defaults) are:

=over 5

=item width => 5

The width/thickness of the curve.

=item colorscale => 'RdBu'

The colorscale for the curve, which is a heatmap
based on the z-value of the curve.
See L</"COLORSCALES"> below for more information.

=item opacity => 1

The opacity of a curve between 0 and 1.

=item funcType => 'jsmd'

How to interpret the parametric functions.
See L</"FUNCTION TYPES"> below for more information.

=item variables => ['t']

The variable to use in the JavaScript function.

=back

=head1 PARAMETRIC SURFACES

The addSurface method takes three arrays as input followed by a list
of options. The first array is three parametric functions, followed by
the minimum, maximum, and optional number of points for each of the
two variables. If the number of points is not given, it defaults to 20.

    $graph->addSurface(
        [xFunction, yFunction, zFunction],
        [uMin, uMax, uCount],
        [vMin, vMax, vCount],
        options
    );

The additional options are given in a 'option => value' format.
The current available options (and defaults) are:

=over 2

=item colorscale => 'RdBu'

The colorscale for the curve, which is a heatmap
based on the z-value of the surface. See
L</"COLORSCALES"> below for more information.

=item opacity => 1

The opacity of a curve between 0 and 1.

=item funcType => 'jsmd'

How to interpret the parametric functions.
See L</"FUNCTION TYPES"> below for more information.

=item variables => ['u', 'v']

The variables to use in the JavaScript function.

=back

=head1 FUNCTIONS

The addFunction method takes a string, which is a function f(x,y), followed by
two arrays which give the x-bounds and y-bounds, with optional number of points
to plot. This is a wrapper for addSurface in which the variables are x and y.
See addSurface for the list of options. funcType => 'data' cannot be used with
functions, use addSurface directly to plot data.

    $graph->addFunction(
        'zFunction',
        [xMin, xMax, xCount],
        [yMin, yMax, yCount],
        options
    );

=head1 COLORSCALES

The colorscale colors the points of the curve/surface based on the z-value
of the points. The colorscale can be one of the following predefined names:

    'BdBu', 'YlOrRd', 'YlGnBu', 'Portland', 'Picnic', 'Jet', 'Hot'
    'Greys', 'Greens', 'Electric', 'Earth', 'Bluered', or 'Blackbody'

You can also define a custom colorscale as a list of colors for values
ranging from 0 to 1. For example the default RdBu is the following colorscale
(note this must be a string since the array is passed to JavaScript):

    "[[0, 'rgb(5,10,172)'], [0.35, 'rgb(106,137,247)'],
      [0.5, 'rgb(190,190,190)'], [0.6, 'rgb(220,170,132)'],
      [0.7, 'rgb(230,145,90)'], [1, 'rgb(178,10,28)']]"

A colorscale can have any number of color points between 0 and 1. To make
the plot a single color, set the color for 0 and 1 to be the same:

    "[[0, 'rgb(0,200,0)'], [1, 'rgb(0,200,0)']]"

=head1 FUNCTION TYPES

The functions to generate the plot can be either mathematical, JavaScript,
Perl, or raw data, and this can be controlled using the funcType => type
option in addCurve or addSurface methods. The valid types are:

=over 2

=item jsmd

This is the default type, in which the functions are converted
from math formulas into JavaScript functions to generate the
plot. This should accept standard mathematical notation with
some exceptions: Multiplication must be an explicit "*":
"ucos(v)" is not accepted, but "u*cos(v)" is. JavaScript
considers "-u^2" not well defined, instead use "-(u^2)".

=item js

The functions are interpreted as raw JavaScript functions. The
functions will be passed the defined variables and return a
single value. This function type is useful to plot more complicated
functions, such as piecewise functions with if/then statements.
For example, this graphs the surface of the plane in the first
octant that passes through the points ($a,0,0), (0,$b,0), (0,0,$c):

    ($a, $b, $c) = (5, 3, 7);
    $graph->addSurface(
        [
            "return ($b*u < $a*v ? 0.5*u : u - 0.5*$a/$b*v);",
            "return ($b*u > $a*v ? 0.5*v : v - 0.5*$b/$a*u);",
            "const x = ($b*u < $a*v ? 0.5*u : u - 0.5*$a/$b*v);"
                . "const y = ($b*u > $a*v ? 0.5*v : v - 0.5*$b/$a*u);"
                . "return $c - $c/$a*x - $c/$b*y;",
        ],
        [0, $a],
        [0, $b],
        funcType => 'js',
    );

=item perl

The functions are interpreted as Perl subroutines. The functions
will be passed the appropriate number of inputs, and return a
single value. This uses the WeBWorK server to generate the points
for the plot, and can slow down the rendering of the problem. Using
the JavaScript methods are preferred for this reason. Here is an
example of plotting a sphere of radius $R.

    $R = 5;
    $graph->addSurface(
        [
            sub { return $R*cos($_[0])*sin($_[1]); },
            sub { return $R*sin($_[0])*sin($_[1]); },
            sub { return $R*cos($_[1]); }
        ],
        [0, 2*pi],
        [0, pi],
        funcType => 'perl',
    );

=item data

The functions are interpreted as a nested array of data points to
be sent directly to plotly to plot. The nested array needs to be
a string, since it is passed to JavaScript to plot. This array lists
all of the points which are used to create the surface. For example to
plot a surface with 9 points, use something like:

    $graph->addSurface(
        [
            "[[x1, x2, x3], [x4, x5, x6], [x7, x8, x9]]",
            "[[y1, y2, y3], [y4, y5, y6], [y7, y8, y9]]",
            "[[z1, z2, z3], [z4, z5, z6], [z7, z8, z9]]"
        ],
        [0,0],
        [0,0],
        funcType => 'data'
    );

This plots a surfacing using the points (x1,y1,z1), (x2,y2,z2), ...,
and (x9,y9,z9). The addSurface method requires bounds, but they are not
used, so [0,0] needs to be included, but is ignored. Using the perl method
to first generate the arrays, then copying the result and using the data
method can be useful to speed up rendering of nonrandomized plots.

=back

=head1 Graph3D OPTIONS

Create a graph object: C<$graph = Graph3D(option =E<gt> value)>
The valid options are:

=over 2

=item height

The height of the div containing the graph.

=item width

The width of the div containing the graph.

=item title

Graph title to print above the graph.

=item style

CSS style to style the div containing the graph.

=item bgcolor

The background color of the graph.

=item image

Image filename to be used in hardcopy TeX output.
If no image is provided, the hardcopy TeX output
has a message that image must be viewed online.

=item tex_size

Size of image in hardcopy TeX output as scale factor from 0 to 1000.
1000 is 100%, 500 is 50%, etc.

=item tex_border

Put (1) or don't put (0) a border around image in TeX output.

=item scene

Add a JavaScript scene configuration dictionary to the plotly layout.
This can be used to configure various aspects of the plot, such as
the aspect ratio, and view range of the 3D axes. The scene is a string
which contains a JavaScript dictonary to pass to plotly. Example:

  scene => 'aspectmode: "manual",'
         . 'aspectratio: {x: 1, y: 1, z: 1},'
         . 'xaxis: { range: [0,2] },'
         . 'yaxis: { range: [0,3] },'
         . 'zaxis: { range: [1,4] }'

See L<https://plotly.com/javascript/3d-axes/> for more examples
or L<https://plotly.com/javascript/reference/layout/scene/#layout-scene>
for the API reference.

=back

=head1 SEE ALSO

L<https://plotly.com/javascript/>

=cut

sub _plotly3D_init {
	ADD_JS_FILE('node_modules/plotly.js-dist-min/plotly.min.js', 0, { defer => undef });
	PG_restricted_eval("sub Graph3D {new plotly3D(\@_)}");
}

package plotly3D;

sub new {
	my $self  = shift;
	my $class = ref($self) || $self;

	$self = bless {
		id         => $main::PG->getUniqueName('plotly3D') =~ s/-/_/gr,
		plots      => [],
		width      => 500,
		height     => 500,
		title      => '',
		bgcolor    => '#f5f5f5',
		style      => 'border: solid 2px; display: inline-block; margin: 5px; text-align: center;',
		scene      => '',
		image      => '',
		tex_size   => 500,
		tex_border => 1,
		@_,
	}, $class;

	return $self;
}

sub addSurface { push(@{ shift->{plots} }, plotly3D::Plot::Surface->new(@_)); }
sub addCurve   { push(@{ shift->{plots} }, plotly3D::Plot::Curve->new(@_)); }

sub addFunction {
	my $self = shift;
	my $func = shift;
	my $b1   = shift;
	my $b2   = shift;
	my %opts = @_;
	my @vars = ($opts{variables}) ? @{ $opts{variables} } : ('x', 'y');
	my $type = $opts{funcType} || '';
	if ($type eq 'perl') {
		$self->addSurface([ sub { $_[0] }, sub { $_[1] }, $func ], $b1, $b2, %opts);
	} elsif ($type eq 'data') {
		Value::Error('Functions cannot use data. Use addSurface directly.');
	} else {
		$self->addSurface([ @vars, $func ], $b1, $b2, variables => [@vars], %opts);
	}
}

sub TeX {
	my $self = shift;
	my $size = $self->{tex_size} * 0.001;
	my $out  = ($self->{tex_border}) ? '\fbox{' : '\mbox{';
	$out .= "\\begin{minipage}{$size\\linewidth}\\centering\n";
	$out .= ($self->{title}) ? "{\\bf $self->{title}} \\\\\n" : '';
	if ($self->{image}) {
		$out .= &main::image($self->{image}, tex_size => 950);
	} else {
		$out .= '3D image not avaialble. You must view it online.';
	}
	$out .= "\n\\end{minipage}}\n";

	return $out;
}

sub HTML {
	my $self  = shift;
	my $id    = $self->{id};
	my $width = $self->{width} + 10;
	my $title = ($self->{title}) ? "<strong>$self->{title}</strong>" : '';
	my $plots = '';
	my $scene = ($self->{scene}) ? "scene: { $self->{scene} }," : '';

	foreach (@{ $self->{plots} }) {
		$plots .= $_->HTML;
	}
	$plots =~ s/^\t//;

	return "\n" . <<END_OUTPUT;
<div style="width: ${width}px; $self->{style}">
	$title
	<div id="plotlyDiv_$id" style="width: $self->{width}px; height: $self->{height}px;"></div>
</div>
<script>
(() => {
	const initialize = () => {
		const plotlyData = [];
		$plots
		Plotly.newPlot('plotlyDiv_$id', plotlyData, {
			autosize: true,
			showlegend: false,
			paper_bgcolor: "$self->{bgcolor}",
			$scene
			margin: {
				l: 5,
				r: 5,
				b: 5,
				t: 5,
			}
		},
		{ displaylogo: false }
	);
	};
	if (document.readyState === 'loading') window.addEventListener('DOMContentLoaded', initialize);
	else initialize();
})();
</script>

END_OUTPUT
}

sub Print {
	my $self = shift;
	my $out  = '';

	if ($main::displayMode =~ /HTML/) {
		$out = $self->HTML;
	} elsif ($main::displayMode eq 'TeX') {
		$out = $self->TeX;
	} else {
		$out = "Unsupported display mode: $main::displayMode\n";
	}
	return $out;
}

# Base plot class
package plotly3D::Plot;

sub cmpBounds {
	my $self   = shift;
	my $bounds = shift;
	Value::Error('Bounds must be an array with two or three items.')
		unless (ref($bounds) eq 'ARRAY' && scalar(@$bounds) > 1);

	my ($min, $max, $count) = @$bounds;
	$count = shift unless $count;
	my $step = ($max - $min) / $count;
	$max += $step / 2;    # Fudge factor to deal with rounding issues.
	return ($min, $max, $step);
}

sub parseFunc {
	my $self = shift;
	my $func = shift;
	Value::Error('First input must be an array with three items.')
		unless (ref($func) eq 'ARRAY' && scalar(@$func) == 3);

	if ($self->{funcType} eq 'data') {
		($self->{xPoints}, $self->{yPoints}, $self->{zPoints}) = @$func;
	} else {
		($self->{xFunc}, $self->{yFunc}, $self->{zFunc}) = @$func;
		if ($self->{nVars} == 2) {
			($self->{uMin}, $self->{uMax}, $self->{uStep}) = $self->cmpBounds(shift, 20);
			($self->{vMin}, $self->{vMax}, $self->{vStep}) = $self->cmpBounds(shift, 20);
		} else {
			($self->{tMin}, $self->{tMax}, $self->{tStep}) = $self->cmpBounds(shift, 100);
		}
	}
}

sub genPoints {
	my $self = shift;
	my $type = $self->{funcType};

	if ($type eq 'data') {
		# Manual data plot, nothing to do.
	} elsif ($type eq 'jsmd' || $type eq 'js') {
		if ($type eq 'jsmd') {
			foreach ('xFunc', 'yFunc', 'zFunc') {
				$self->{$_} = $self->funcToJS($self->{$_});
			}
		}
		$self->{xPoints} = 'xData';
		$self->{yPoints} = 'yData';
		$self->{zPoints} = 'zData';
	} elsif ($type eq 'perl') {
		$self->buildArray;
	} else {
		Value::Error("Unkown plot type: $type\n");
	}
}

# Takes a pseudo function string and replaces with JavaScript functions.
sub funcToJS {
	my $self   = shift;
	my $func   = shift;
	my %vars   = map { $_ => $_ } @{ $self->{variables} };
	my %tokens = (
		sqrt    => 'Math.sqrt',
		cbrt    => 'Math.cbrt',
		hypot   => 'Math.hypot',
		norm    => 'Math.hypot',
		pow     => 'Math.pow',
		exp     => 'Math.exp',
		abs     => 'Math.abs',
		round   => 'Math.round',
		floor   => 'Math.floor',
		ceil    => 'Math.ceil',
		sign    => 'Math.sign',
		int     => 'Math.trunc',
		log     => 'Math.ln',
		ln      => 'Math.ln',
		cos     => 'Math.cos',
		sin     => 'Math.sin',
		tan     => 'Math.tan',
		acos    => 'Math.acos',
		arccos  => 'Math.acos',
		asin    => 'Math.asin',
		arcsin  => 'Math.asin',
		atan    => 'Math.atan',
		arctan  => 'Math.atan',
		atan2   => 'Math.atan2',
		cosh    => 'Math.cosh',
		sinh    => 'Math.sinh',
		tanh    => 'Math.tanh',
		acosh   => 'Math.acosh',
		arccosh => 'Math.arccosh',
		asinh   => 'Math.asinh',
		arcsinh => 'Math.asinh',
		atanh   => 'Math.atanh',
		arctanh => 'Math.arctanh',
		min     => 'Math.min',
		max     => 'Math.max',
		random  => 'Math.random',
		e       => 'Math.E',
		pi      => 'Math.PI',
		'^'     => '**',
		%vars
	);
	my $out = '';
	my $match;

	$func =~ s/\s//g;
	while (length($func) > 0) {
		if (($match) = ($func =~ m/^([A-Za-z]+|\^)/)) {
			$func = substr($func, length($match));
			if ($tokens{$match}) {
				$out .= $tokens{$match};
			} else {
				Value::Error("Unknown token $match in function.");
			}
		} elsif (($match) = ($func =~ m/^([^A-Za-z^]+)/)) {
			$func = substr($func, length($match));
			$out .= $match;
		} else {    # Shouldn't happen, but to stop an infinite loop for safety.
			Value::Error("Unknown error parsing function.");
		}
	}
	return "return $out;";
}

# JavaScript Functions Output
sub genJS {
	my $self = shift;
	return '{' unless ($self->{funcType} =~ /^js/);
	my $vars  = join(', ', @{ $self->{variables} });
	my $JSout = <<END_OUTPUT;
{
	const xData = [];
	const yData = [];
	const zData = [];

	const xFunc = ($vars) => { $self->{xFunc} };
	const yFunc = ($vars) => { $self->{yFunc} };
	const zFunc = ($vars) => { $self->{zFunc} };
END_OUTPUT

	if ($self->{nVars} == 2) {
		$JSout .= <<END_OUTPUT;
	for (let u = $self->{uMin}; u < $self->{uMax}; u += $self->{uStep}) {
		const xRow = [];
		const yRow = [];
		const zRow = [];
		for (let v = $self->{vMin}; v < $self->{vMax}; v += $self->{vStep}) {
			xRow.push(xFunc(u, v));
			yRow.push(yFunc(u, v));
			zRow.push(zFunc(u, v));
		}
		xData.push(xRow);
		yData.push(yRow);
		zData.push(zRow);
	}
END_OUTPUT
	} else {
		$JSout .= <<END_OUTPUT;
	for (let t = $self->{tMin}; t < $self->{tMax}; t += $self->{tStep}) {
		xData.push(xFunc(t));
		yData.push(yFunc(t));
		zData.push(zFunc(t));
	}
END_OUTPUT
	}

	return $JSout;
}

sub buildArray {
	my $self = shift;
	my $xPts = '';
	my $yPts = '';
	my $zPts = '';

	if ($self->{nVars} == 2) {
		for (my $u = $self->{uMin}; $u < $self->{uMax}; $u += $self->{uStep}) {
			my @xTmp;
			my @yTmp;
			my @zTmp;
			for (my $v = $self->{vMin}; $v < $self->{vMax}; $v += $self->{vStep}) {
				push @xTmp, $self->{xFunc}($u, $v);
				push @yTmp, $self->{yFunc}($u, $v);
				push @zTmp, $self->{zFunc}($u, $v);
			}
			$xPts .= '[' . join(',', @xTmp) . '],';
			$yPts .= '[' . join(',', @yTmp) . '],';
			$zPts .= '[' . join(',', @zTmp) . '],';
		}
	} else {
		for (my $t = $self->{tMin}; $t < $self->{tMax}; $t += $self->{tStep}) {
			$xPts .= $self->{xFunc}($t) . ',';
			$yPts .= $self->{yFunc}($t) . ',';
			$zPts .= $self->{zFunc}($t) . ',';
		}
	}
	chop $xPts;
	chop $yPts;
	chop $zPts;
	$self->{xPoints} = "[$xPts]";
	$self->{yPoints} = "[$yPts]";
	$self->{zPoints} = "[$zPts]";
}

# plotly3D surface plots
package plotly3D::Plot::Surface;
our @ISA = ('plotly3D::Plot');

sub new {
	my $self    = shift;
	my $data    = shift;
	my $uBounds = (ref($_[0]) eq 'ARRAY') ? shift : '';
	my $vBounds = (ref($_[0]) eq 'ARRAY') ? shift : '';
	my $class   = ref($self) || $self;

	$self = bless {
		id         => $main::PG->getUniqueName('plotly3D') =~ s/-/_/gr,
		funcType   => 'jsmd',
		colorscale => 'RdBu',
		opacity    => 1,
		variables  => [ 'u', 'v' ],
		nVars      => 2,
		@_,
	}, $class;
	$self->parseFunc($data, $uBounds, $vBounds);

	return $self;
}

sub HTML {
	my $self  = shift;
	my $scale = ($self->{colorscale} =~ /^\[/) ? $self->{colorscale} : "'$self->{colorscale}'";
	$self->genPoints;

	return $self->genJS . <<END_OUTPUT;
	plotlyData.push({
		x: $self->{xPoints},
		y: $self->{yPoints},
		z: $self->{zPoints},
		type: 'surface',
		opacity: $self->{opacity},
		colorscale: $scale,
		showscale: false,
	});
}
END_OUTPUT
}

# plotly3D curve plots
package plotly3D::Plot::Curve;
our @ISA = ('plotly3D::Plot');

sub new {
	my $self    = shift;
	my $data    = shift;
	my $tBounds = (ref($_[0]) eq 'ARRAY') ? shift : '';
	my $class   = ref($self) || $self;

	$self = bless {
		id         => $main::PG->getUniqueName('plotly3D') =~ s/-/_/gr,
		funcType   => 'jsmd',
		width      => 5,
		colorscale => 'RdBu',
		opacity    => 1,
		variables  => ['t'],
		nVars      => 1,
		@_,
	}, $class;
	$self->parseFunc($data, $tBounds);

	return $self;
}

sub HTML {
	my $self  = shift;
	my $scale = ($self->{colorscale} =~ /^\[/) ? $self->{colorscale} : "'$self->{colorscale}'";
	$self->genPoints;

	return $self->genJS . <<END_OUTPUT;
	plotlyData.push({
		x: $self->{xPoints},
		y: $self->{yPoints},
		z: $self->{zPoints},
		type: 'scatter3d',
		mode: 'lines',
		opacity: $self->{opacity},
		line: {
			width: $self->{width},
			color: $self->{zPoints},
			colorscale: $scale,
		},
	});
}
END_OUTPUT
}
