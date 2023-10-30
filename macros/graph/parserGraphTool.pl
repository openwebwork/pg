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

parserGraphTool.pl - Allow students to enter basic graphical answers via interactive JavaScript.

=head1 DESCRIPTION

GraphTool objects let you provide an interactive graphing tool for students to enter graphical
answers.

To create a GraphTool object pass a list of graph objects (discussed below) for the students to
graph to C<GraphTool()>.  For example:

    $gt = GraphTool("{line,solid,(0,0),(1,1)}", "{circle,dashed,(2,2),(4,2)}");

or

    $gt = GraphTool("{line,solid,(0,0),(1,1)}")->with(bBox => [-20, 20, 20, -20]);

Then, for standard PG use C<< $gt->ans_rule() >> to insert the JavaScript graph into the problem
(or a print graph when a hard copy is generated), and C<< $gt->cmp >> to produce the answer
checker.  For example:

    BEGIN_TEXT
    Graph the line \(y = x\).
    $PAR
    \{$gt->ans_rule()\}
    END_TEXT

    ANS($gt->cmp);

For PGML you can just do

    BEGIN_PGML
    Graph the line [`y = x`].

    [_]{$gt}
    END_PGML

=head1 GRAPH OBJECTS

There are eight types of graph objects that the students can graph.  Points, lines, circles,
parabolas, quadratics, cubics, intervals, and fills (or shading of a region).  The syntax for each
of these objects to pass to the GraphTool constructor is summarized as follows.  Each object must
be enclosed in braces.  The first element in the braces must be the name of the object.  The
following elements in the braces depend on the type of element.

For points the name "point" must be followed by the coordinates. For example:

    "{point,(3,5)}"

For lines the name "line" must be followed by the word "solid" or "dashed" to indicate if the
line is expected to be drawn solid or dashed.  That is followed by two distinct points on the
line.  For example:

    "{line,dashed,(1,5),(3,4)}"

For circles the name "circle" must be followed by the word "solid" or "dashed" to indicate if
the circle is expected to be drawn solid or dashed.  That is followed by the point that is to be
the center of circle, and then by a point on the circle.  For example:

    "{circle,solid,(1,1),(4,5)}"

For parabolas the name "parabola" must be followed by the word "solid" or "dashed" to indicate
if the parabola is expected to be drawn solid or dashed.  The next element in the braces must be
the word "vertical" for a parabola that opens up or down, or "horizontal" for a parabola that
opens to the left or right.  That is followed by the vertex and then another point on the
parabola.  For example:

    "{parabola,solid,vertical,(1,0),(3,3)}"

For three point quadratics the name "quadratic" must be followed by the word "solid" or "dashed"
to indicate if the quadratic is expected to be drawn solid or dashed.  That is followed by the
three points that define the quadratic.  For example:

    "{quadratic,solid,(-1,2),(1,0),(3,3)}"

For four point cubics the name "cubic" must be followed by the word "solid" or "dashed"
to indicate if the cubic is expected to be drawn solid or dashed.  That is followed by the
four points that define the cubic.  For example:

    "{cubic,solid,(1,-3),(-1,2),(4,3),(3,2)}"

For fills the name "fill" must be followed by a point in the region that is to be filled.  For
example:

    "{fill,(5,5)}"

For intervals the name "interval" must be followed by a single interval.  Some examples are:

    "{interval,[3,10)}"
    "{interval,(-infinity,8]}"
    "{interval,(2,infinity)}"

Note that for an infinite interval endpoint in a correct answer you may use "inf", or anything
that is interpreted into a MathObject infinity.  However, for static graph objects it must be
"infinity".  The JavaScript will always return "infinity" for student answers.

The student answers that are returned by the JavaScript will be a list of the list objects
discussed above and will be parsed by WeBWorK and passed to the checker as such.  The default
checker is designed to grade the graph based on appearance.  This means that if a student graphs
duplicate objects, then the duplicates are ignored.  Furthermore, if two objects are graphed
whose only difference is that one is solid and the other is dashed (in this case the dashed
object is covered by the solid object and only the solid object is really visible), then the
dashed object is ignored.

A custom list_checker may be provided instead of using the default checker. This can either be
passed as part of the C<cmpOptions> hash discussed below, or directly to the GraphTool object's
C<cmp()> method.  The variable C<$graphToolObjectCmps> can be used in a custom checker and
contains a hash whose keys are the types of the objects described above, and whose values are
methods that can be called passing a MathObject list constructed from one of the objects
described above.  When one of these methods is called it will return two methods.  The first
method when called passing a MathObject point will return 0 if the point satisfies the equation
of the object, -1 if the equation evaluated at the point is negative, and 1 if the equation
evaluated at the point is positive.  The second method when called passing another MathObject
list constructed from one of the objects described as above will return 1 if the two objects are
exactly the same, and 0 otherwise.  A second parameter may be passed and if that parameter is 1,
then the method will return 1 if the two objects are the same ignoring if the two objects are
solid or dashed, and 0 otherwise.  In the following example, the C<$lineCmp> method is defined
to be the second method (indexed by 1) that is returned by calling the C<'line'> method on the
first correct answer in the example.

    $m = 2 * random(1, 4);

    $gt = GraphTool("{line, solid, ($m / 2, 0), (0, -$m)}")->with(
        bBox       => [ -11, 11, 11, -11 ],
        cmpOptions => {
            list_checker => sub {
                my ($correct, $student, $ans, $value) = @_;
                return 0 if $ans->{isPreview};

                my $score = 0;
                my @errors;

                my $lineCmp = ($graphToolObjectCmps->{line}->($correct->[0]))[1];

             for (0 .. $#$student) {
                    if ($lineCmp->($student->[$_])) { ++$score; next; }

                    my $nth = Value::List->NameForNumber($_ + 1);

                    if ($student->[$_]->extract(1) ne 'line') {
                        push(@errors, "The $nth object graphed is not a line.");
                        next;
                    }

                    if ($student->[$_]->extract(2) ne 'solid') {
                        push(@errors, "The $nth object graphed should be a solid line.");
                        next;
                    }

                    push(@errors, "The $nth object graphed is incorrect.");
                }

                return ($score, @errors);
            }
        }
    }

=head1 OPTIONS

There are a number of options that you can supply to control the appearance and behavior of the
JavaScript graph, listed below.  These are set as parameters to the C<with()> method called on the
C<GraphTool> object.

=over

=item bBox (Default: C<< bBox => [-10, 10, 10, -10] >>)

This is an array of four numbers that represent the bounding box of the graph.  The first
two numbers in the array are the coordinates of the top left corner of the graph, and the last
two numbers are the coordinates of the bottom right corner of the graph.

=item gridX, gridY (Default: C<< gridX => 1, gridY => 1 >>)

These are the distances between successive grid lines in the x and y directions, respectively.

=item ticksDistanceX, ticksDistanceY (Default: C<< ticksDistanceX => 2, ticksDistanceY => 2 >>)

These are the distances between successive major (labeled) ticks on the x and y axes,
respectively.

=item minorTicksX, minorTicksY (Default: C<< minorTicksX => 1, minorTicksY => 1 >>)

These are the number of minor (unlabeled) ticks between major ticks on the x and y axes,
respectively.

=item xAxisLabel, yAxisLabel (Default: C<< xAxisLabel => 'x', yAxisLabel => 'y' >>)

Labels that will be added to the ends of the horizontal (x) and vertical (y) axes.  Note that the
values of these options will be used in MathJax online and in LaTeX math mode in print.  These can
also be set to the empty string '' to remove the labels.

=item ariaDescription (Default: C<< ariaDescription => '' >>)

This will be added to a hidden div that will be referenced in an aria-describedby attribute of
the jsxgraph board.

=item JSXGraphOptions (Default: C<< undef >>)

This is an advanced option that you usually do not want to use.  It is usually constructed by
the macro internally using the above options.  If defined it should be a single string that is
formatted in JavaScript object notation, and will override all of the above options.  It will be
passed to the JavaScript C<graphTool> method which will pass it on to the JSX graph board when it
is initialized.  It may consist of any of the valid attributes documented for
C<JXG.JSXGraph.initBoard> at L<https://jsxgraph.org/docs/symbols/JXG.JSXGraph.html#.initBoard>.
For example the following value for C<JSXGraphOptions> will give the same result for the
JavaScript graph as the default values for the options above:

    JSXGraphOptions => JSON->new->encode({
        boundingBox => [-10, 10, 10, -10],
        defaultAxes => {
            x => { ticks => { ticksDistance => 2, minorTicks => 1} },
            y => { ticks => { ticksDistance => 2, minorTicks => 1} }
        },
        grid => { gridX => 1, gridY => 1 }
    })

=item snapSizeX, snapSizeY (Default: C<< snapSizeX => 1, snapSizeY => 1 >>)

These restrict the x coordinate and y coordinate of points that can be graphed to being
multiples of the respective parameter.  These values must be greater than zero.

=item showCoordinateHints (Default: C<< showCoordinateHints => 1 >>)

Set this to 0 to disable the display of the coordinates.  These are in the lower right corner of
the graph for the default 2 dimensional graphing mode, and in the top left corner of the graph
for the 1 dimensional mode when numberLine is 1.

=item coordinateHintsType (Default: C<< coordinateHintsType => 'decimal' >>)

This changes the way coordinate hints are shown.  By default the coordinates are displayed as
decimal numbers accurate to five decimal places.  If this is set to 'fraction', then those
decimals will be converted and displayed as fractions.  If this is set to 'mixed', then those
decimals will be converted and displayed as mixed numbers.  For example, if the snapSizeX is set
to 1/3, then what would be displayed as 4.66667 with the default 'decimal' setting, would be
instead be displayed as 14/3 with the 'fraction' setting, and '4 2/3' with the 'mixed' setting.
Note that these fractions are typeset by MathJax.

Make sure that the snap size is given with decent accuracy.  For example, if the snap size to
0.33333, then instead of 1/3 being displayed, 33333/1000000 will be displayed.  It is
recommended to actually give an actual fraction for the snap size (like 1/3), and let perl and
javascript compute that to get the best result.

=item coordinateHintsTypeX (Default: C<< coordinateHintsTypeX => undef >>)

This does the same as the coordinateHintsType option, but only for the x-coordinate.
If this is undefined then the coordinateHintsType option is used for the x-coordinate.

=item coordinateHintsTypeY (Default: C<< coordinateHintsTypeY => undef >>)

This does the same as the coordinateHintsType option, but only for the y-coordinate.
If this is undefined then the coordinateHintsType option is used for the y-coordinate.

=item availableTools (Default: C<< availableTools => [ "LineTool", "CircleTool",
    "VerticalParabolaTool", "HorizontalParabolaTool", "FillTool", "SolidDashTool" ] >>)

This is an array of tools that will be made available for students to use in the graph tool.
The order the tools are listed here will also be the order the tools are presented in the graph
tool button box.  All of the tools that may be included are listed in the default options above,
except for the "PointTool", the three point "QuadraticTool", and the four point "CubicTool".
Note that the case of the tool names must match what is shown.

=item staticObjects (Default: C<< staticObjects => [] >>)

This is an array of fixed objects that will be displayed on the graph.  These objects will not
be able to be moved around.  The format for these objects is the same as those that are passed
to the GraphTool constructor as the correct answers.

=item printGraph (Default: C<undef>)

If the JSXGraphOptions option is set directly, then you will also need to provide a function that
will generate the corresponding hard copy graph.  Otherwise the hard copy graph will still be
generated using the above options, and will not look the same as the JavaScript graph.

=item cmpOptions (Default: C<< cmpOptions => {} >>)

This is a hash of options that will be passed to the C<cmp()> method.  These options can also be
passed as parameters directly to the GraphTool object's C<cmp()> method.

=item texSize (Default: C<< texSize => 400 >>)

This is the size of the graph that will be output when a hard copy of the problem is generated.

=item showInStatic (Default: 1)

In "static" output forms (TeX, PTX) you may not want to print the graph if it is just taking
space. In that case, set this to 0.

=item numberLine (Default: C<< numberLine => 0 >>)

If set to 0, then the graph will show both the horizontal and vertical axes.  This is the
default. If set to 1, then only the horizontal axis will be shown, and the graph can be
interpreted as a number line.  In this case the graph will also be displayed with a smaller
height.

Note that if this option is set to 1, then some of the options listed above have different
default values.  The options with different default values and their corresponding default
values are:

    bBox           => [ -10, 0.4, 10, -0.4 ],
    xAxisLabel     => '',
    availableTools => [ 'IntervalTool', 'IncludeExcludePointTool' ],

In addition, C<bBox> may be provided as an array reference with only two entries which will
be interpreted as a horizontal range.  For example,

    bBox => [ -12, 12 ]

will give a graph with horizontal extremes C<-12> and C<12>.

Note that the horizontal extremes of the number line are interpreted as points at infinity.  So in
the above example, a point graphed at -12 will be interpreted to be a point at -infinity, and a
point graphed at 12 will be interpreted to be a point at infinity.

The only graph objects that will work well with this graphing mode are the "point" and "interval"
objects, which are created by the "PointTool" and "IntervalTool" respectively.  Usually the
"IncludeExcludePointTool" will be desired to control when interval end points are included or
excluded from an interval.  Of course "interval"s and the "IntervalTool" will not work well if
this graph mode is not used.

=item useBracketEnds (Default: C<< useBracketEnds => 0 >>)

If set to 1, then parentheses and brackets will be used for interval end point delimiters
instead of open and closed dots.  This option only has effect when C<numberLine> is 1, and
the C<IntervalTool> is used.

=back

=head1 METHODS

=over

=item generateAnswerGraph

This method may be called for a GraphTool object to output a static version of the graph into the
problem. The typical place where this might be desired is in the solution for the problem. For
example

    BEGIN_PGML_SOLUTION
    The correct graph is

    [@ $gt->generateAnswerGraph(ariaDescription => 'a better description than the default') @]*
    END_PGML_SOLUTION

The following options may be passed to this method.

=over

=item C<showCorrect>

Whether to show correct answers in the graph. This is 1 by default.

=item C<cssClass>

A css class that will be added to the containing div. The default value is
'graphtool-solution-container'. Note that this default class is provided in the graphtool.css file.
A custom class may also be used, and injected into the header via HEADER_TEXT. It is recommended
that this class be prefixed with the graph tool answer name to avoid possible conflict with other
problems. This may be obtained with C<< $gt->ANS_NAME >>. This class must set the width and height
of the div.graphtool-graph contained within, or the div.graphtool-number-line contained within if
numberLine is set. Note that this option is only used in HTML output.

=item C<ariaDescription>

An aria description that will be added to the graph. The default value is 'graph of solution'. Note
that this option is only used in HTML output.

=item C<objects>

Additional objects to display in the graph. The default value is the empty string.

=item C<width> and C<height>

The width and height of the answer graph in HTML output.  If neither of these are given, then the
css class will be used instead.  If only one of these is given, then the other will be computed from
the given value.

=item C<texSize>

This is the size of the image that will be output when a hard copy of the problem is generated.
The default value is the value of the graph tool object C<texSize> option which defaults to 400.

=back

=back

=cut

sub _parserGraphTool_init {
	ADD_CSS_FILE('node_modules/jsxgraph/distrib/jsxgraph.css');
	ADD_CSS_FILE('js/GraphTool/graphtool.css');
	ADD_JS_FILE('node_modules/jsxgraph/distrib/jsxgraphcore.js', 0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/graphtool.js',                     0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/pointtool.js',                     0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/quadratictool.js',                 0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/cubictool.js',                     0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/intervaltools.js',                 0, { defer => undef });

	return;
}

loadMacros('MathObjects.pl', 'PGtikz.pl');

sub GraphTool { parser::GraphTool->new(@_) }

$graphToolObjectCmps = \%parser::GraphTool::graphObjectCmps;

package parser::GraphTool;
our @ISA = qw(Value::List);

my %contextStrings = (
	line       => {},
	circle     => {},
	parabola   => {},
	vertical   => {},
	horizontal => {},
	fill       => {},
	solid      => {},
	dashed     => {}
);

sub new {
	my ($self, @options) = @_;
	my $class   = ref($self) || $self;
	my $context = Parser::Context->getCopy('Point');
	$context->parens->set('{' => { close => '}', type => 'List', formList => 1, formMatrix => 0, removable => 0 });
	$context->lists->set(
		'GraphTool' => {
			class       => 'Parser::List::List',
			open        => '',
			close       => '',
			separator   => ', ',
			nestedOpen  => '{',
			nestedClose => '}'
		}
	);
	$context->strings->add(%contextStrings);
	my $obj = $self->SUPER::new($context, @options);
	return bless {
		data                 => $obj->{data},
		type                 => $obj->{type},
		context              => $context,
		staticObjects        => [],
		cmpOptions           => {},
		bBox                 => [ -10, 10, 10, -10 ],
		gridX                => 1,
		gridY                => 1,
		snapSizeX            => 1,
		snapSizeY            => 1,
		ticksDistanceX       => 2,
		ticksDistanceY       => 2,
		minorTicksX          => 1,
		minorTicksY          => 1,
		xAxisLabel           => 'x',
		yAxisLabel           => 'y',
		ariaDescription      => '',
		showCoordinateHints  => 1,
		coordinateHintsType  => 'decimal',
		coordinateHintsTypeX => undef,
		coordinateHintsTypeY => undef,
		showInStatic         => 1,
		numberLine           => 0,
		useBracketEnds       => 0,
		availableTools       =>
			[ 'LineTool', 'CircleTool', 'VerticalParabolaTool', 'HorizontalParabolaTool', 'FillTool', 'SolidDashTool' ],
		texSize    => 400,
		graphCount => 0
	}, $class;
}

sub with {
	my ($self, %options) = @_;

	if ($options{numberLine}) {
		%options = (
			%$self,
			bBox           => [ -10, 0.4, 10, -0.4 ],
			xAxisLabel     => '',
			availableTools => [ 'IntervalTool', 'IncludeExcludePointTool' ],
			%options,
			ref $options{bBox} eq 'ARRAY'
				&& @{ $options{bBox} } == 2 ? (bBox => [ $options{bBox}[0], 0.4, $options{bBox}[1], -0.4 ]) : ()
		);
	}

	return $self->SUPER::with(%options);
}

my %graphObjectTikz = (
	line => {
		code => sub {
			my $self = shift;

			my ($p1x, $p1y) = @{ $_->{data}[2]{data} };
			my ($p2x, $p2y) = @{ $_->{data}[3]{data} };

			if ($p1x == $p2x) {
				# Vertical line
				my $line = "($p1x,$self->{bBox}[3]) -- ($p1x,$self->{bBox}[1])";
				return (
					"\\draw[thick,blue,line width=2.5pt,$_->{data}[1]] $line;\n",
					[
						$line
							. "-- ($self->{bBox}[2],$self->{bBox}[1]) -- ($self->{bBox}[2],$self->{bBox}[3]) -- cycle",
						sub { return $_[0] - $p1x; }
					]
				);
			} else {
				# Non-vertical line
				my $m = ($p2y - $p1y) / ($p2x - $p1x);
				my $y = sub { return $m * ($_[0] - $p1x) + $p1y; };
				my $line =
					"($self->{bBox}[0],"
					. &$y($self->{bBox}[0]) . ') -- '
					. "($self->{bBox}[2],"
					. &$y($self->{bBox}[2]) . ')';
				return (
					"\\draw[thick,blue,line width=2.5pt,$_->{data}[1]] $line;\n",
					[
						$line
							. "-- ($self->{bBox}[2],$self->{bBox}[1]) -- ($self->{bBox}[0],$self->{bBox}[1]) -- cycle",
						sub { return $_[1] - &$y($_[0]); }
					]
				);
			}
		}
	},
	circle => {
		code => sub {
			my $self = shift;
			my ($cx, $cy) = @{ $_->{data}[2]{data} };
			my ($px, $py) = @{ $_->{data}[3]{data} };
			my $r      = sqrt(($cx - $px)**2 + ($cy - $py)**2);
			my $circle = "($cx, $cy) circle[radius=$r]";
			return (
				"\\draw[thick,blue,line width=2.5pt,$_->{data}[1]] $circle;\n",
				[ $circle, sub { return $r - sqrt(($cx - $_[0])**2 + ($cy - $_[1])**2); } ]
			);
		}
	},
	parabola => {
		code => sub {
			my $self = shift;
			my ($h,  $k)  = @{ $_->{data}[3]{data} };
			my ($px, $py) = @{ $_->{data}[4]{data} };

			if ($_->{data}[2] eq 'vertical') {
				# Vertical parabola
				my $a        = ($py - $k) / ($px - $h)**2;
				my $diff     = sqrt((($a >= 0 ? $self->{bBox}[1] : $self->{bBox}[3]) - $k) / $a);
				my $dmin     = $h - $diff;
				my $dmax     = $h + $diff;
				my $parabola = "plot[domain=$dmin:$dmax,smooth](\\x,{$a*(\\x-($h))^2+($k)})";
				return (
					"\\draw[thick,blue,line width=2.5pt,$_->{data}[1]] $parabola;\n",
					[ $parabola, sub { return $a * ($_[1] - $a * ($_[0] - $h)**2 - $k); } ]
				);
			} else {
				# Horizontal parabola
				my $a        = ($px - $h) / ($py - $k)**2;
				my $diff     = sqrt((($a >= 0 ? $self->{bBox}[2] : $self->{bBox}[0]) - $h) / $a);
				my $dmin     = $k - $diff;
				my $dmax     = $k + $diff;
				my $parabola = "plot[domain=$dmin:$dmax,smooth]({$a*(\\x-($k))^2+($h)},\\x)";
				return (
					"\\draw[thick,blue,line width=2.5pt,$_->{data}[1]] $parabola;\n",
					[ $parabola, sub { return $a * ($_[0] - $a * ($_[1] - $k)**2 - $h); } ]
				);
			}
		}
	},
	fill => {
		code => sub {
			my ($self, $fill, $object_data) = @_;
			my ($fx, $fy) = @{ $fill->{data}[1]{data} };
			my $clip_code = '';
			for (@$object_data) {
				my $clip_dir = &{ $_->[1] }($fx, $fy);
				return '' if $clip_dir == 0;
				$clip_code .= "\\clip " . ($clip_dir < 0 ? '[inverse clip]' : '') . $_->[0] . ";\n";
			}
			return
				"\\begin{scope}\n\\clip[rounded corners=14pt] "
				. "($self->{bBox}[0],$self->{bBox}[3]) rectangle ($self->{bBox}[2],$self->{bBox}[1]);\n"
				. $clip_code
				. "\\fill[fillpurple] "
				. "($self->{bBox}[0],$self->{bBox}[3]) rectangle ($self->{bBox}[2],$self->{bBox}[1]);\n"
				. "\\end{scope}";
		},
		fillType => 1
	}
);

our %graphObjectCmps = (
	line => sub {
		my ($line) = @_;

		my $solid_dashed = $line->{data}[1];
		my ($x1, $y1) = $line->{data}[2]->value;
		my ($x2, $y2) = $line->{data}[3]->value;

		# These are the coefficients a, b, and c in ax + by + c = 0.
		my @stdform = ($y1 - $y2, $x2 - $x1, $x1 * $y2 - $x2 * $y1);

		my $linePointCmp = sub {
			my $point = shift;
			my ($x, $y) = $point->value;
			return $stdform[0] * $x + $stdform[1] * $y + $stdform[2] <=> 0;
		};

		return (
			$linePointCmp,
			sub {
				my ($other, $fuzzy) = @_;
				return
					$other->{data}[0] eq 'line'
					&& ($fuzzy || $other->{data}[1] eq $solid_dashed)
					&& $linePointCmp->($other->{data}[2]) == 0
					&& $linePointCmp->($other->{data}[3]) == 0;
			}
		);
	},
	circle => sub {
		my $circle = shift;

		my $solid_dashed = $circle->{data}[1];
		my $center       = $circle->{data}[2];
		my ($cx, $cy) = $center->value;
		my ($px, $py) = $circle->{data}[3]->value;
		my $r_squared = ($cx - $px)**2 + ($cy - $py)**2;

		my $circlePointCmp = sub {
			my $point = shift;
			my ($x, $y) = $point->value;
			return ($x - $cx)**2 + ($y - $cy)**2 <=> $r_squared;
		};

		return (
			$circlePointCmp,
			sub {
				my ($other, $fuzzy) = @_;
				return
					$other->{data}[0] eq 'circle'
					&& ($fuzzy || $other->{data}[1] eq $solid_dashed)
					&& $other->{data}[2] == $center
					&& $circlePointCmp->($other->{data}[3]) == 0;
			}
		);
	},
	parabola => sub {
		my $parabola = shift;

		my $solid_dashed        = $parabola->{data}[1];
		my $vertical_horizontal = $parabola->{data}[2];
		my $vertex              = $parabola->{data}[3];
		my ($h, $k)   = $vertex->value;
		my ($px, $py) = $parabola->{data}[4]->value;

		my $x_pow = $vertical_horizontal eq 'vertical' ? 2 : 1;
		my $y_pow = $vertical_horizontal eq 'vertical' ? 1 : 2;

		my $parabolaPointCmp = sub {
			my $point = shift;
			my ($x, $y) = $point->value;
			return ($px - $h)**$x_pow * ($y - $k)**$y_pow <=> ($py - $k)**$y_pow * ($x - $h)**$x_pow;
		};

		return (
			$parabolaPointCmp,
			sub {
				my ($other, $fuzzy) = @_;
				return
					$other->{data}[0] eq 'parabola'
					&& ($fuzzy || $other->{data}[1] eq $solid_dashed)
					&& $other->{data}[2] eq $vertical_horizontal
					&& $other->{data}[3] == $vertex
					&& $parabolaPointCmp->($other->{data}[4]) == 0;
			}
		);
	},
	fill => sub {
		my ($fill, $object_fill_cmps) = @_;

		my $fill_point = $fill->{data}[1];

		my $pointInFillRegion = sub {
			my $point = shift;

			for (@$object_fill_cmps) {
				return 0 if $_->($fill_point) != $_->($point);
			}
			return 1;
		};

		return (
			$pointInFillRegion,
			sub {
				my $other = shift;
				return $other->{data}[0] eq 'fill' && $pointInFillRegion->($other->{data}[1]);
			}
		);
	}
);

my $customGraphObjects = '';
my $customTools        = '';

sub addGraphObjects {
	my ($self, %objects) = @_;
	$customGraphObjects .= join(',', map {"$_: $objects{$_}{js}"} keys %objects) . ',';

	# Add the object's name and any other custom strings to the context strings, add the
	# code for generating the object in print to the %graphObjectTikz hash, and add the
	# cmp subroutine to the %graphObjectCmps hash.
	for (keys %objects) {
		$contextStrings{$_}  = {};
		$contextStrings{$_}  = {} for (@{ $objects{$_}{strings} });
		$graphObjectTikz{$_} = $objects{$_}{tikz} if defined $objects{$_}{tikz};
		$graphObjectCmps{$_} = $objects{$_}{cmp}  if ref($objects{$_}{cmp}) eq 'CODE';
	}

	return;
}

sub addTools {
	my ($self, %tools) = @_;
	$customTools .= join(',', map {"$_: $tools{$_}"} keys %tools) . ',';
	return;
}

parser::GraphTool->addGraphObjects(
	# The point graph object.
	point => {
		js   => 'graphTool.pointTool.Point',
		tikz => {
			code => sub {
				my $gt = shift;
				my ($x, $y) = @{ $_->{data}[1]{data} };
				return (
					"\\draw[line width=4pt,blue,fill=red] ($x,$y) circle[radius=5pt];",
					[ '', sub { return ($_[0] - $x)**2 + ($_[1] - $y)**2; } ]
				);
			}
		},
		cmp => sub {
			my $pointObject = shift;

			my $point = $pointObject->{data}[1];

			return (
				sub { return 1 },
				sub {
					my $other = shift;
					return $other->{data}[0] eq 'point' && $point == $other->{data}[1];
				}
			);
		}
	},
	# A three point quadratic graph object.
	quadratic => {
		js   => 'graphTool.quadraticTool.Quadratic',
		tikz => {
			code => sub {
				my $gt = shift;
				my ($x1, $y1) = @{ $_->{data}[2]{data} };
				my ($x2, $y2) = @{ $_->{data}[3]{data} };
				my ($x3, $y3) = @{ $_->{data}[4]{data} };

				my $den = ($x1 - $x2) * ($x1 - $x3) * ($x2 - $x3);
				my $a   = (($x2 - $x3) * $y1 + ($x3 - $x1) * $y2 + ($x1 - $x2) * $y3) / $den;

				if ($a == 0) {
					# Colinear points
					my $y = sub { return ($y2 - $y1) / ($x2 - $x1) * ($_[0] - $x1) + $y1; };
					my $line =
						"($gt->{bBox}[0]," . &$y($gt->{bBox}[0]) . ") -- ($gt->{bBox}[2]," . &$y($gt->{bBox}[2]) . ")";
					return (
						"\\draw[thick,blue,line width=2.5pt,$_->{data}[1]] $line;\n",
						[
							"$line -- ($gt->{bBox}[2],$gt->{bBox}[1]) -- ($gt->{bBox}[0],$gt->{bBox}[1]) -- cycle",
							sub { return $_[1] - &$y($_[0]); }
						]
					);
				} else {
					# Non-degenerate quadratic
					my $b = (($x3**2 - $x2**2) * $y1 + ($x1**2 - $x3**2) * $y2 + ($x2**2 - $x1**2) * $y3) / $den;
					my $c =
						(($x2 - $x3) * $x2 * $x3 * $y1 + ($x3 - $x1) * $x1 * $x3 * $y2 + ($x1 - $x2) * $x1 * $x2 * $y3)
						/ $den;
					my $h         = -$b / (2 * $a);
					my $k         = $c - $b**2 / (4 * $a);
					my $diff      = sqrt((($a >= 0 ? $gt->{bBox}[1] : $gt->{bBox}[3]) - $k) / $a);
					my $dmin      = $h - $diff;
					my $dmax      = $h + $diff;
					my $quadratic = "plot[domain=$dmin:$dmax,smooth](\\x,{$a*(\\x)^2+($b)*\\x+($c)})";
					return (
						"\\draw[thick,blue,line width=2.5pt,$_->{data}[1]] $quadratic;",
						[ $quadratic, sub { return $a * ($_[1] - $a * $_[0]**2 - $b * $_[0] - $c); } ]
					);
				}
			}
		},
		cmp => sub {
			my $quadratic = shift;

			my $solid_dashed = $quadratic->{data}[1];
			my ($x1, $y1) = $quadratic->{data}[2]->value;
			my ($x2, $y2) = $quadratic->{data}[3]->value;
			my ($x3, $y3) = $quadratic->{data}[4]->value;

			my @coeffs = (($x1 - $x2) * $y3, ($x1 - $x3) * $y2, ($x2 - $x3) * $y1);
			my $den    = ($x1 - $x2) * ($x1 - $x3) * ($x2 - $x3);

			my $quadraticPointCmp = sub {
				my $point = shift;
				my ($x, $y) = $point->value;
				return ($x - $x2) * ($x - $x3) * $coeffs[2] - ($x - $x1) * ($x - $x3) * $coeffs[1] +
					($x - $x1) * ($x - $x2) * $coeffs[0] <=> $den * $y;
			};

			return (
				$quadraticPointCmp,
				sub {
					my ($other, $fuzzy) = @_;
					return
						$other->{data}[0] eq 'quadratic'
						&& ($fuzzy || $other->{data}[1] eq $solid_dashed)
						&& $quadraticPointCmp->($other->{data}[2]) == 0
						&& $quadraticPointCmp->($other->{data}[3]) == 0
						&& $quadraticPointCmp->($other->{data}[4]) == 0;
				}
			);
		}
	},
	# A four point cubic graph object.
	cubic => {
		js   => "graphTool.cubicTool.Cubic",
		tikz => {
			code => sub {
				my $gt = shift;
				my ($x1, $y1) = @{ $_->{data}[2]{data} };
				my ($x2, $y2) = @{ $_->{data}[3]{data} };
				my ($x3, $y3) = @{ $_->{data}[4]{data} };
				my ($x4, $y4) = @{ $_->{data}[5]{data} };

				my $c3 =
					($y1 / (($x1 - $x2) * ($x1 - $x3) * ($x1 - $x4)) +
						$y2 / (($x2 - $x1) * ($x2 - $x3) * ($x2 - $x4)) +
						$y3 / (($x3 - $x1) * ($x3 - $x2) * ($x3 - $x4)) +
						$y4 / (($x4 - $x1) * ($x4 - $x2) * ($x4 - $x3)));
				my $c2 =
					((-$x2 - $x3 - $x4) * $y1 / (($x1 - $x2) * ($x1 - $x3) * ($x1 - $x4)) +
						(-$x1 - $x3 - $x4) * $y2 / (($x2 - $x1) * ($x2 - $x3) * ($x2 - $x4)) +
						(-$x1 - $x2 - $x4) * $y3 / (($x3 - $x1) * ($x3 - $x2) * ($x3 - $x4)) +
						(-$x1 - $x2 - $x3) * $y4 / (($x4 - $x1) * ($x4 - $x2) * ($x4 - $x3)));

				if ($c3 == 0 && $c2 == 0) {
					# Colinear points
					my $y = sub { return ($y2 - $y1) / ($x2 - $x1) * ($_[0] - $x1) + $y1; };
					my $line =
						"($gt->{bBox}[0]," . &$y($gt->{bBox}[0]) . ") -- ($gt->{bBox}[2]," . &$y($gt->{bBox}[2]) . ")";
					return (
						"\\draw[thick,blue,line width=2.5pt,$_->{data}[1]] $line;\n",
						[
							"$line -- ($gt->{bBox}[2],$gt->{bBox}[1]) -- ($gt->{bBox}[0],$gt->{bBox}[1]) -- cycle",
							sub { return $_[1] - &$y($_[0]); }
						]
					);
				} elsif ($c3 == 0) {
					# Quadratic
					my $den = ($x1 - $x2) * ($x1 - $x3) * ($x2 - $x3);
					my $a   = (($x2 - $x3) * $y1 + ($x3 - $x1) * $y2 + ($x1 - $x2) * $y3) / $den;
					my $b   = (($x3**2 - $x2**2) * $y1 + ($x1**2 - $x3**2) * $y2 + ($x2**2 - $x1**2) * $y3) / $den;
					my $c =
						(($x2 - $x3) * $x2 * $x3 * $y1 + ($x3 - $x1) * $x1 * $x3 * $y2 + ($x1 - $x2) * $x1 * $x2 * $y3)
						/ $den;
					my $h        = -$b / (2 * $a);
					my $k        = $c - $b**2 / (4 * $a);
					my $diff     = sqrt((($a >= 0 ? $gt->{bBox}[1] : $gt->{bBox}[3]) - $k) / $a);
					my $dmin     = $h - $diff;
					my $dmax     = $h + $diff;
					my $parabola = "plot[domain=$dmin:$dmax,smooth](\\x,{$a*(\\x)^2+($b)*\\x+($c)})";
					return (
						"\\draw[thick,blue,line width=2.5pt,$_->{data}[1]] $parabola;",
						[ $parabola, sub { return $a * ($_[1] - $a * $_[0]**2 - $b * $_[0] - $c); } ]
					);
				} else {
					# Non-degenerate cubic
					my $cubic_function = sub {
						return (($_[0] - $x2) *
								($_[0] - $x3) *
								($_[0] - $x4) *
								$y1 /
								(($x1 - $x2) * ($x1 - $x3) * ($x1 - $x4)) +
								($_[0] - $x1) *
								($_[0] - $x3) *
								($_[0] - $x4) *
								$y2 /
								(($x2 - $x1) * ($x2 - $x3) * ($x2 - $x4)) +
								($_[0] - $x1) *
								($_[0] - $x2) *
								($_[0] - $x4) *
								$y3 /
								(($x3 - $x1) * ($x3 - $x2) * ($x3 - $x4)) +
								($_[0] - $x1) *
								($_[0] - $x2) *
								($_[0] - $x3) *
								$y4 /
								(($x4 - $x1) * ($x4 - $x2) * ($x4 - $x3)));
					};

					my $height     = $gt->{bBox}[1] - $gt->{bBox}[3];
					my $lowerBound = $gt->{bBox}[3] - $height;
					my $upperBound = $gt->{bBox}[1] + $height;
					my $step       = ($gt->{bBox}[2] - $gt->{bBox}[0]) / 200;
					my $x          = $gt->{bBox}[0];

					my $coords;
					do {
						my $y = $cubic_function->($x);
						$coords .= "($x,$y) " if $y >= $lowerBound && $y <= $upperBound;
						$x += $step;
					} while ($x < $gt->{bBox}[2]);

					my $cubic = "plot[smooth] coordinates { $coords }";
					return (
						"\\draw[thick,blue,line width=2.5pt,$_->{data}[1]] $cubic;",
						[
							$cubic
								. (
									$c3 > 0
									? ("-- ($gt->{bBox}[2],$gt->{bBox}[1]) -- ($gt->{bBox}[0],$gt->{bBox}[1])"
										. "-- ($gt->{bBox}[0],$gt->{bBox}[3]) -- cycle")
									: ("-- ($gt->{bBox}[2],$gt->{bBox}[3]) -- ($gt->{bBox}[0],$gt->{bBox}[3])"
										. "-- ($gt->{bBox}[0],$gt->{bBox}[1]) -- cycle")
								),
							sub { return $c3 * ($_[1] - $cubic_function->($_[0])); }
						]
					);
				}
			}
		},
		cmp => sub {
			my $cubic = shift;

			my $solid_dashed = $cubic->{data}[1];
			my ($x1, $y1) = $cubic->{data}[2]->value;
			my ($x2, $y2) = $cubic->{data}[3]->value;
			my ($x3, $y3) = $cubic->{data}[4]->value;
			my ($x4, $y4) = $cubic->{data}[5]->value;

			my @coeffs = (
				($x1 - $x2) * ($x1 - $x3) * ($x2 - $x3) * $y4,
				($x1 - $x2) * ($x1 - $x4) * ($x2 - $x4) * $y3,
				($x1 - $x3) * ($x1 - $x4) * ($x3 - $x4) * $y2,
				($x2 - $x3) * ($x2 - $x4) * ($x3 - $x4) * $y1
			);
			my $den = ($x1 - $x2) * ($x1 - $x3) * ($x1 - $x4) * ($x2 - $x3) * ($x2 - $x4) * ($x3 - $x4);

			my $cubicPointCmp = sub {
				my $point = shift;
				my ($x, $y) = $point->value;
				return ($x - $x2) * ($x - $x3) * ($x - $x4) * $coeffs[3] -
					($x - $x1) * ($x - $x3) * ($x - $x4) * $coeffs[2] +
					($x - $x1) * ($x - $x2) * ($x - $x4) * $coeffs[1] -
					($x - $x1) * ($x - $x2) * ($x - $x3) * $coeffs[0] <=> $den * $y;
			};

			return (
				$cubicPointCmp,
				sub {
					my ($other, $fuzzy) = @_;
					return
						$other->{data}[0] eq 'cubic'
						&& ($fuzzy || $other->{data}[1] eq $solid_dashed)
						&& $cubicPointCmp->($other->{data}[2]) == 0
						&& $cubicPointCmp->($other->{data}[3]) == 0
						&& $cubicPointCmp->($other->{data}[4]) == 0
						&& $cubicPointCmp->($other->{data}[5]) == 0;
				}
			);
		}
	},
	# The interval graph object.
	interval => {
		js   => 'graphTool.intervalTool.Interval',
		tikz => {
			code => sub {
				my $gt = shift;
				my ($start, $end) = @{ $_->{data}[1]{data} };

				my $openEnd =
					$gt->{useBracketEnds}
					? '{Parenthesis[round,width=28pt,line width=3pt,length=14pt]}'
					: '{Circle[scale=1.1,open]}';
				my $closedEnd =
					$gt->{useBracketEnds} ? '{Bracket[width=24pt,line width=3pt,length=8pt]}' : '{Circle[scale=1.1]}';

				my $open =
					$start eq '-infinity' ? '{Stealth[scale=1.1]}' : $_->{data}[1]{open} eq '[' ? $closedEnd : $openEnd;
				my $close =
					$end eq 'infinity' ? '{Stealth[scale=1.1]}' : $_->{data}[1]{close} eq ']' ? $closedEnd : $openEnd;

				$start = $gt->{bBox}[0] if $start eq '-infinity';
				$end   = $gt->{bBox}[2] if $end eq 'infinity';

				# This centers an open/close dot or a parenthesis or bracket on the tick.
				# TikZ by default puts the end with its outer edge at the tick.
				my $shortenLeft =
					$open   =~ /Circle/              ? ',shorten <=-8.25pt'
					: $open =~ /Parenthesis|Bracket/ ? ',shorten <=-1.5pt'
					:                                  '';
				my $shortenRight =
					$close  =~ /Circle/              ? ',shorten >=-8.25pt'
					: $open =~ /Parenthesis|Bracket/ ? ',shorten >=-1.5pt'
					:                                  '';

				return (
					"\\draw[thick,blue,line width=4pt,$open-$close$shortenRight$shortenLeft] ($start,0) -- ($end,0);\n",
					[ '', sub { return 0; } ]
				);
			}
		},
		cmp => sub {
			my $intervalObj = shift;

			my $interval = $intervalObj->{data}[1];

			return (
				sub { return 1 },
				sub {
					my $other = shift;
					return $other->{data}[0] eq 'interval' && $interval == $other->{data}[1];
				}
			);
		}
	},
);

parser::GraphTool->addTools(
	# The point tool.
	PointTool => 'graphTool.pointTool.PointTool',
	# A three point quadratic tool.
	QuadraticTool => 'graphTool.quadraticTool.QuadraticTool',
	# A four point cubic tool.
	CubicTool => 'graphTool.cubicTool.CubicTool',
	# An interval tool.
	IntervalTool => 'graphTool.intervalTool.IntervalTool',
	# Include/Exclude point tool.
	IncludeExcludePointTool => 'graphTool.includeExcludePointTool.IncludeExcludePointTool',
);

sub ANS_NAME {
	my $self = shift;
	$self->{name} = main::NEW_ANS_NAME() unless defined($self->{name});
	return $self->{name};
}

sub type { return 'List'; }

# Convert the GraphTool object's options into JSON that can be passed to the JavaScript
# graphTool method.
sub constructJSXGraphOptions {
	my $self = shift;
	return if defined($self->{JSXGraphOptions});
	$self->{JSXGraphOptions} = JSON->new->encode({
		boundingBox => $self->{bBox},
		$self->{numberLine}
		? (
			defaultAxes => {
				x => {
					ticks => {
						label         => { offset => [ 0, -12 ], anchorY => 'top', anchorX => 'middle' },
						drawZero      => 1,
						ticksDistance => $self->{ticksDistanceX},
						minorTicks    => $self->{minorTicksX},
						strokeWidth   => 2,
						strokeOpacity => 0.5,
						minorHeight   => 10,
						majorHeight   => 14
					}
				}
			},
			grid => 0
			)
		: (
			defaultAxes => {
				x => { ticks => { ticksDistance => $self->{ticksDistanceX}, minorTicks => $self->{minorTicksX} } },
				y => { ticks => { ticksDistance => $self->{ticksDistanceY}, minorTicks => $self->{minorTicksY} } }
			},
			grid => { gridX => $self->{gridX}, gridY => $self->{gridY} }
		)
	});

	return;
}

# Produce a hidden answer rule to contain the JavaScript result and insert the graphbox div and
# JavaScript to display the graph tool.  If a hard copy is being generated, then PGtikz.pl is used
# to generate a printable graph instead.  An attempt is made to make the printable graph look
# as much as possible like the JavaScript graph.
sub ans_rule {
	my $self         = shift;
	my $answer_value = $main::envir{inputs_ref}{ $self->ANS_NAME } // '';
	my $ans_name     = main::RECORD_ANS_NAME($self->ANS_NAME, $answer_value);

	if ($main::displayMode =~ /^(TeX|PTX)$/ && $self->{showInStatic}) {
		return $self->generateTeXGraph(showCorrect => 0)
			. ($main::displayMode eq 'PTX' ? qq!<p><fillin name="$ans_name"/></p>! : '');
	} elsif ($main::displayMode eq 'PTX') {
		return qq!<p><fillin name="$ans_name"/></p>!;
	} elsif ($main::displayMode eq 'TeX') {
		return '';
	} else {
		$self->constructJSXGraphOptions;
		return main::tag(
			'div',
			data_feedback_insert_element => $ans_name,
			class                        => 'graphtool-outer-container',
			main::tag('input', type => 'hidden', name => $ans_name, id => $ans_name, value => $answer_value)
				. main::tag(
					'input',
					type  => 'hidden',
					name  => "previous_$ans_name",
					id    => "previous_$ans_name",
					value => $answer_value
				)
				. <<END_SCRIPT);
<div id='${ans_name}_graphbox' class='graphtool-container'></div>
<script>
(() => {
	const initialize = () => {
		graphTool('${ans_name}_graphbox', {
			htmlInputId: '${ans_name}',
			staticObjects: '${\(join(',', @{$self->{staticObjects}}))}',
			snapSizeX: $self->{snapSizeX},
			snapSizeY: $self->{snapSizeY},
			xAxisLabel: '$self->{xAxisLabel}',
			yAxisLabel: '$self->{yAxisLabel}',
			ariaDescription: '${\(main::encode_pg_and_html($self->{ariaDescription}))}',
			showCoordinateHints: $self->{showCoordinateHints},
			coordinateHintsTypeX: '${\($self->{coordinateHintsTypeX} // $self->{coordinateHintsType})}',
			coordinateHintsTypeY: '${\($self->{coordinateHintsTypeY} // $self->{coordinateHintsType})}',
			numberLine: $self->{numberLine},
			useBracketEnds: $self->{useBracketEnds},
			customGraphObjects: {$customGraphObjects},
			customTools: {$customTools},
			availableTools: ['${\(join("','", @{$self->{availableTools}}))}'],
			JSXGraphOptions: $self->{JSXGraphOptions}
		});
	};
	if (document.readyState === 'loading') window.addEventListener('DOMContentLoaded', initialize);
	else initialize();
})();
</script>
END_SCRIPT
	}
}

sub cmp_defaults {
	my ($self, %options) = @_;
	return (
		$self->SUPER::cmp_defaults(%options),
		ordered    => 0,
		entry_type => 'object',
		list_type  => 'graph'
	);
}

# Modify the student's list answer returned by the graphTool JavaScript to reproduce the
# JavaScript graph of the student's answer in the "Answer Preview" box of the results table.
# The raw list form of the answer is displayed in the "Entered" box.
sub cmp_preprocess {
	my ($self, $ans) = @_;

	if ($main::displayMode ne 'TeX' && defined($ans->{student_value})) {
		$ans->{preview_latex_string} = $self->generateHTMLAnswerGraph(
			idSuffix        => 'student_ans_graphbox',
			cssClass        => 'graphtool-answer-container',
			ariaDescription => 'answer preview graph',
			objects         => join(',', $ans->{student_ans}),
			showCorrect     => 0
		);
	}

	return;
}

# Create an answer checker to be passed to ANS().  Any parameters are passed to the checker, as
# well as any parameters passed in via cmpOptions when the GraphTool object is created.
# The correct answer is modified to reproduce the JavaScript graph of the correct answer
# displayed in the "Correct Answer" box of the results table.
sub cmp {
	my ($self, %options) = @_;
	my $cmp = $self->SUPER::cmp(
		feedback_options => sub {
			my ($ansHash, $options, $problemContents) = @_;
			$options->{wrapPreviewInTex} = 0;
			$options->{showEntered}      = 0;
			$options->{feedbackElements} = $problemContents->find('[id="' . $self->ANS_NAME . '_graphbox"]');
			$options->{insertElement} =
				$problemContents->at('[data-feedback-insert-element="' . $self->ANS_NAME . '"]');
			$options->{insertMethod} = 'append_content';
		},
		%{ $self->{cmpOptions} },
		%options
	);

	unless (ref($cmp->{rh_ans}{list_checker}) eq 'CODE' || ref($cmp->{rh_ans}{checker}) eq 'CODE') {
		$cmp->{rh_ans}{list_checker} = sub {
			my ($correct, $student, $ans, $value) = @_;
			return 0 if $ans->{isPreview};

			# If there are no correct answers, then the answer is correct if the student doesn't graph anything, and is
			# incorrect if the student does graph something.  Although, this checker won't actually be called if the
			# student doesn't graph anything.  So if it is desired for that to be correct, then that must be handled in
			# a post filter.
			return @$student ? 0 : 1 if !@$correct;

			# If the student graphed multiple objects, then remove the duplicates.  Note that a fuzzy comparison is
			# done.  This means that the solid/dashed status of the objects is ignored for the comparison. Only the
			# solid variant is kept if both appear.  The idea is that solid covers dashed.  Fills are all kept and
			# the duplicates dealt with later.
			my @student;
		ANSWER: for my $answer (@$student) {
				my $answer_type = $answer->{data}[0];
				unless ($answer_type eq 'fill') {
					for (0 .. $#student) {
						my $other_type = $student[$_]{data}[0];
						next unless $other_type eq $answer_type;
						if (($graphObjectCmps{ $student[$_]{data}[0] }->($student[$_]))[1]->($answer, 1)) {
							$student[$_] = $answer if $answer->{data}[1] eq 'solid';
							next ANSWER;
						}
					}
				}
				push(@student, $answer);
			}

			# Cache the correct graph object comparison methods.  Also cache the correct graph object fill comparison
			# methods.  These must be passed to the fill compare method generator.  Fills need to have all of these to
			# determine the correct regions of the graph that are to be filled.  Note that the fill comparison methods
			# for static objects are added to this list later.
			my @object_cmps;
			my @object_fill_cmps;
			for (@$correct) {
				my $type = $_->{data}[0];
				next if $type eq 'fill' || ref($graphObjectCmps{$type}) ne 'CODE';
				my ($fill_cmp, $object_cmp) = $graphObjectCmps{$type}->($_);
				push(@object_cmps,      $object_cmp);
				push(@object_fill_cmps, $fill_cmp);
			}

			my @object_scores = (0) x @object_cmps;
			my @incorrect_objects;

		ENTRY: for my $student_index (0 .. $#student) {
				my $student_type = $student[$student_index]{data}[0];

				# Grading of fills is deferred until after the other objects, and is only done if they are all correct.
				next if $student_type eq 'fill';

				for (0 .. $#object_cmps) {
					if ($object_cmps[$_]->($student[$student_index])) {
						++$object_scores[$_];
						next ENTRY;
					}
				}

				push(@incorrect_objects, $student[$student_index]);
			}

			my $object_score = 0;
			for (@object_scores) { ++$object_score if $_; }

			my $fill_score = 0;
			my @fill_scores;
			my @incorrect_fill_cmps;

			# Now check the fills if all of the objects were correctly graphed.
			if ($object_score == @object_scores) {
				# Add the fill comparison methods for the static graph objects.
				for (@{ $self->SUPER::new($self->{context}, @{ $self->{staticObjects} })->{data} }) {
					my $type = $_->{data}[0];
					next if $type eq 'fill';
					push(@object_fill_cmps, ($graphObjectCmps{$type}->($_))[0])
						if ref($graphObjectCmps{$type}) eq 'CODE';
				}

				# Cache the correct fill comparison methods.
				my @fill_cmps;
				for (@$correct) {
					next unless $_->{data}[0] eq 'fill';
					push(@fill_cmps, ($graphObjectCmps{fill}->($_, \@object_fill_cmps))[1]);
				}

				@fill_scores = (0) x @fill_cmps;

			ENTRY: for my $student_index (0 .. $#student) {
					my $student_type = $student[$student_index]{data}[0];
					next unless $student_type eq 'fill';

					for (0 .. $#fill_cmps) {
						if ($fill_cmps[$_]->($student[$student_index])) {
							++$fill_scores[$_];
							next ENTRY;
						}
					}

					# Skip incorrect fills in the same region as another incorrect fill.
					for (@incorrect_fill_cmps) { next ENTRY if $_->($student[$student_index]); }

					# Cache comparison methods for incorrect fills.
					push(
						@incorrect_fill_cmps,
						(
							$graphObjectCmps{ $student[$student_index]{data}[0] }
								->($student[$student_index], \@object_fill_cmps)
						)[1]
					);
				}

				for (@fill_scores) { ++$fill_score if $_; }
			}

			my $score =
				($object_score + $fill_score) /
				(@$correct +
					(@incorrect_objects   ? (@incorrect_objects - (@object_scores - $object_score)) : 0) +
					(@incorrect_fill_cmps ? (@incorrect_fill_cmps - (@fill_scores - $fill_score))   : 0));

			return $score > 0 ? main::Round($score * (@$student > @$correct ? @$student : @$correct), 2) : 0;
		};
	}

	if ($main::displayMode ne 'TeX' && $main::displayMode ne 'PTX') {
		$cmp->{rh_ans}{correct_ans_latex_string} = $self->generateHTMLAnswerGraph(
			idSuffix        => 'correct_ans_graphbox',
			cssClass        => 'graphtool-answer-container',
			ariaDescription => 'correct answer graph'
		);
	}

	return $cmp;
}

sub generateHTMLAnswerGraph {
	my ($self, %options) = @_;
	$options{showCorrect} //= 1;

	++$self->{graphCount} unless defined $options{idSuffix};

	my $idSuffix        = $options{idSuffix}        // "ans_graphbox_$self->{graphCount}";
	my $cssClass        = $options{cssClass}        // 'graphtool-solution-container';
	my $ariaDescription = $options{ariaDescription} // 'graph of solution';
	my $answerObjects   = $options{showCorrect} ? join(',', @{ $self->{data} }) : '';
	$answerObjects = join(',', $options{objects}, $answerObjects) if defined $options{objects};

	my $ans_name = $self->ANS_NAME;
	$self->constructJSXGraphOptions;

	if ($options{width} || $options{height}) {
		# This enforces a sane minimum width and height for the image.  The minimum width is 200 pixels.  The minimum
		# height is the 200 pixels for two dimensional graphs, and is 50 pixels for number line graphs.  Two is added to
		# the width and height to account for the container border, and so that the graph image will be the given width
		# and height.
		my $width =
			main::max($options{width} || ($self->{numberLine} ? ($options{height} / 0.1625) : $options{height}), 200) +
			2;
		my $height = main::max($options{height} || ($self->{numberLine} ? (0.1625 * $options{width}) : $options{width}),
			$self->{numberLine} ? 50 : 200) + 2;

		main::HEADER_TEXT(
			"<style>#${ans_name}_$idSuffix .graphtool-graph{width:${width}px;height:${height}px;}</style>");
	}

	return << "END_SCRIPT";
<div id="${ans_name}_$idSuffix" class="$cssClass"></div>
<script>
(() => {
	const initialize = () => {
		graphTool('${ans_name}_$idSuffix', {
			staticObjects: '${\(join(',', @{$self->{staticObjects}}))}',
			answerObjects: '$answerObjects',
			isStatic: true,
			snapSizeX: $self->{snapSizeX},
			snapSizeY: $self->{snapSizeY},
			xAxisLabel: '$self->{xAxisLabel}',
			yAxisLabel: '$self->{yAxisLabel}',
			numberLine: $self->{numberLine},
			useBracketEnds: $self->{useBracketEnds},
			customGraphObjects: {$customGraphObjects},
			JSXGraphOptions: $self->{JSXGraphOptions},
			ariaDescription: '$ariaDescription'
		});
	};
	if (document.readyState === 'loading') window.addEventListener('DOMContentLoaded', initialize);
	else {
		const trampoline = () => {
			if (typeof window.graphTool === 'undefined') setTimeout(trampoline, 100);
			else initialize();
		}
		setTimeout(trampoline);
	}
})();
</script>
END_SCRIPT
}

sub generateTeXGraph {
	my ($self, %options) = @_;

	$options{showCorrect} //= 1;
	$options{texSize}     //= $self->{texSize};

	return &{ $self->{printGraph} } if ref($self->{printGraph}) eq 'CODE';

	my @size = $self->{numberLine} ? (500, 100) : (500, 500);

	my $graph = main::createTikZImage();
	$graph->tikzLibraries('arrows.meta');
	$graph->tikzOptions('x='
			. ($size[0] / 96 / ($self->{bBox}[2] - $self->{bBox}[0])) . 'in,y='
			. ($size[1] / 96 / ($self->{bBox}[1] - $self->{bBox}[3]))
			. 'in');

	my $tikz = <<END_TIKZ;
\n\\tikzset{
	>={Stealth[scale=1.8]},
	clip even odd rule/.code={\\pgfseteorule},
	inverse clip/.style={ clip,insert path=[clip even odd rule]{
		($self->{bBox}[0],$self->{bBox}[3]) rectangle ($self->{bBox}[2],$self->{bBox}[1]) }
	}
}
\\definecolor{borderblue}{HTML}{356AA0}
\\definecolor{fillpurple}{HTML}{A384E5}
\\pgfdeclarelayer{background}
\\pgfdeclarelayer{foreground}
\\pgfsetlayers{background,main,foreground}
\\begin{pgfonlayer}{background}
	\\fill[white,rounded corners=14pt]
	($self->{bBox}[0],$self->{bBox}[3]) rectangle ($self->{bBox}[2],$self->{bBox}[1]);
\\end{pgfonlayer}
END_TIKZ

	unless ($self->{numberLine}) {
		# Vertical grid lines
		my @xGridLines =
			grep { $_ < $self->{bBox}[2] } map { $_ * $self->{gridX} } (1 .. $self->{bBox}[2] / $self->{gridX});
		push(@xGridLines,
			grep { $_ > $self->{bBox}[0] } map { -$_ * $self->{gridX} } (1 .. -$self->{bBox}[0] / $self->{gridX}));
		$tikz .=
			"\\foreach \\x in {"
			. join(',', @xGridLines)
			. "}{\\draw[line width=0.2pt,color=lightgray] (\\x,$self->{bBox}[3]) -- (\\x,$self->{bBox}[1]);}\n"
			if (@xGridLines);

		# Horizontal grid lines
		my @yGridLines =
			grep { $_ < $self->{bBox}[1] } map { $_ * $self->{gridY} } (1 .. $self->{bBox}[1] / $self->{gridY});
		push(@yGridLines,
			grep { $_ > $self->{bBox}[3] } map { -$_ * $self->{gridY} } (1 .. -$self->{bBox}[3] / $self->{gridY}));
		$tikz .=
			"\\foreach \\y in {"
			. join(',', @yGridLines)
			. "}{\\draw[line width=0.2pt,color=lightgray] ($self->{bBox}[0],\\y) -- ($self->{bBox}[2],\\y);}\n"
			if (@yGridLines);
	}

	# Axis and labels.
	$tikz .= "\\huge\n\\draw[<->,thick] ($self->{bBox}[0],0) -- ($self->{bBox}[2],0)\n"
		. "node[above left,outer sep=2pt]{\\($self->{xAxisLabel}\\)};\n";
	unless ($self->{numberLine}) {
		$tikz .= "\\draw[<->,thick] (0,$self->{bBox}[3]) -- (0,$self->{bBox}[1])\n"
			. "node[below right,outer sep=2pt]{\\($self->{yAxisLabel}\\)};\n";
	}

	# Horizontal axis ticks and labels
	my @xTicks = grep { $_ < $self->{bBox}[2] }
		map { $_ * $self->{ticksDistanceX} } (1 .. $self->{bBox}[2] / $self->{ticksDistanceX});
	push(@xTicks,
		grep { $_ > $self->{bBox}[0] }
		map { -$_ * $self->{ticksDistanceX} } (1 .. -$self->{bBox}[0] / $self->{ticksDistanceX}));
	# Add zero if this is a number line and 0 is in the given range.
	push(@xTicks, 0) if ($self->{numberLine} && $self->{bBox}[2] > 0 && $self->{bBox}[0] < 0);
	my $tickSize = $self->{numberLine} ? '9' : '5';
	$tikz .=
		"\\foreach \\x in {"
		. join(',', @xTicks)
		. "}{\\draw[thin] (\\x,${tickSize}pt) -- (\\x,-${tickSize}pt) node[below]{\\(\\x\\)};}\n"
		if (@xTicks);

	# Vertical axis ticks and labels
	unless ($self->{numberLine}) {
		my @yTicks = grep { $_ < $self->{bBox}[1] }
			map { $_ * $self->{ticksDistanceY} } (1 .. $self->{bBox}[1] / $self->{ticksDistanceY});
		push(@yTicks,
			grep { $_ > $self->{bBox}[3] }
			map { -$_ * $self->{ticksDistanceY} } (1 .. -$self->{bBox}[3] / $self->{ticksDistanceY}));
		$tikz .=
			"\\foreach \\y in {"
			. join(',', @yTicks)
			. "}{\\draw[thin] (5pt,\\y) -- (-5pt,\\y) node[left]{\$\\y\$};}\n"
			if (@yTicks);
	}

	# Border box
	$tikz .= "\\draw[borderblue,rounded corners=14pt,thick] "
		. "($self->{bBox}[0],$self->{bBox}[3]) rectangle ($self->{bBox}[2],$self->{bBox}[1]);\n";

	# This works in two passes if both static objects are present and correct answers are present and to be graphed.
	# First static objects are graphed, and then correct answers are graphed. The point is that static fills should not
	# be affected (clipped) by the correct answer objects. Note that the @object_data containing the clipping code is
	# cumulative. This is because the correct answer fills should be clipped by the static graph objects.
	my (@object_group, @object_data);
	push(@object_group, $self->{staticObjects})            if @{ $self->{staticObjects} };
	push(@object_group, [ map {"$_"} @{ $self->{data} } ]) if $options{showCorrect} && @{ $self->{data} };

	for my $fill_group (@object_group) {
		# Graph the points, lines, circles, and parabolas in this group.
		my $obj = $self->SUPER::new($self->{context}, @{$fill_group});

		# Switch to the foreground layer and clipping box for the objects.
		$tikz .= "\\begin{pgfonlayer}{foreground}\n";
		$tikz .= "\\clip[rounded corners=14pt] "
			. "($self->{bBox}[0],$self->{bBox}[3]) rectangle ($self->{bBox}[2],$self->{bBox}[1]);\n";

		# First graph lines, parabolas, and circles.  Cache the clipping path and a function
		# for determining which side of the object to shade for filling later.
		for (@{ $obj->{data} }) {
			next
				unless (ref($graphObjectTikz{ $_->{data}[0] }) eq 'HASH'
					&& ref($graphObjectTikz{ $_->{data}[0] }{code}) eq 'CODE'
					&& !$graphObjectTikz{ $_->{data}[0] }{fillType});
			my ($object_tikz, $object_data) = $graphObjectTikz{ $_->{data}[0] }{code}->($self, $_);
			$tikz .= $object_tikz;
			push(@object_data, $object_data);
		}

		# Switch from the foreground layer to the background layer for the fills.
		$tikz .= "\\end{pgfonlayer}\n\\begin{pgfonlayer}{background}\n";

		# Now shade the fill regions.
		for (@{ $obj->{data} }) {
			next
				unless (ref($graphObjectTikz{ $_->{data}[0] }) eq 'HASH'
					&& ref($graphObjectTikz{ $_->{data}[0] }{code}) eq 'CODE'
					&& $graphObjectTikz{ $_->{data}[0] }{fillType});
			$tikz .= $graphObjectTikz{fill}{code}->($self, $_, [@object_data], $obj);
		}

		# End the background layer.
		$tikz .= "\\end{pgfonlayer}";
	}

	$graph->tex($tikz);

	return main::image(
		main::insertGraph($graph),
		width    => $size[0],
		height   => $size[1],
		tex_size => $options{texSize}
	);
}

sub generateAnswerGraph {
	my ($self, %options) = @_;
	return $main::displayMode =~ /^(TeX|PTX)$/
		? $self->generateTeXGraph(%options)
		: $self->generateHTMLAnswerGraph(%options);
}

1;
