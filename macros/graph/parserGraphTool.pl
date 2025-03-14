################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2024 The WeBWorK Project, https://github.com/openwebwork
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

The following types of graph objects can be graphed:

    points                          (GraphTool::GraphObject::Point)
    lines                           (GraphTool::GraphObject::Line)
    circles                         (GraphTool::GraphObject::Circle)
    parabolas                       (GraphTool::GraphObject::Parabola)
    quadratics                      (GraphTool::GraphObject::Qudratic)
    cubics                          (GraphTool::GraphObject::Cubic)
    intervals                       (GraphTool::GraphObject::Interval)
    sine waves                      (GraphTool::GraphObject::SineWave)
    triangles                       (GraphTool::GraphObject::Triangle)
    quadrilaterals                  (GraphTool::GraphObject::Quadrilateral)
    line segments                   (GraphTool::GraphObject::Segment)
    vectors                         (GraphTool::GraphObject::Vector)
    fills (or shading of a region)  (GraphTool::GraphObject::Fill)

The syntax for each of these objects to pass to the GraphTool constructor is summarized as
follows.  Each object must be enclosed in braces. The first element in the braces must be the
name of the object. The following elements in the braces depend on the type of element.

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

For sine waves the name "sineWave" must be followed by the word "solid" or "dashed" to indicate
if the sine wave is expected to be drawn solid or dashed. That is followed by a point whose
x-coordinate gives the phase shift (or x-translation) and y-coordinate gives the y-translation.
The last two elements are the period and amplitude. For Example:

    "{sineWave,solid,(2,-4),3,5}"

represents the function C<f(x) = 5 sin((2 pi / 3)(x - (-4))) + 2>.

For triangles the name "triangle" must be followed by the word "solid" or "dashed" to indicate
if the triangle is expected to be drawn solid or dashed. That is followed by the three vertices
of the triangle. For example:

    "{triangle,solid,(-1,2),(1,0),(3,3)}"

For quadrilaterals the name "quadrilateral" must be followed by the word "solid" or "dashed" to
indicate if the triangle is expected to be drawn solid or dashed. That is followed by the four
vertices of the quadrilateral. For example:

    "{quadrilateral,solid,(0,0),(4,3),(2,3),(4,-3)}"

For line segments the name "segment" must be followed by the word "solid" or "dashed" to
indicate if the segment is expected to be drawn solid or dashed.  That is followed by the two
points that are at the ends of the line segment. For example:

    "{segment,solid,(0,0),(3,4)}"

For vectors the name "vector" must be followed by the word "solid" or "dashed" to indicate if
the vector is expected to be drawn solid or dashed.  That is followed by the initial point and
the terminal point. For example:

    "{vector,solid,(0,0),(3,4)}"

The student answers that are returned by the JavaScript will be a list of the list objects
discussed above and will be parsed by WeBWorK and passed to the checker as such.  The default
checker is designed to grade the graph based on appearance.  This means that if a student graphs
duplicate objects, then the duplicates are ignored.  Furthermore, if two objects are graphed
whose only difference is that one is solid and the other is dashed (in this case the dashed
object is covered by the solid object and only the solid object is really visible), then the
dashed object is ignored.

=head1 CUSTOM CHECKERS

A custom list_checker may be provided instead of using the default checker. This can either be
passed as part of the C<cmpOptions> hash discussed below, or directly to the GraphTool object's
C<cmp()> method.

In a custom list checker the correct and student answers will have the MathObject class
C<GraphObject> and will be objects that derive from the C<GraphTool::GraphObject> package (the
specific packages for the various objects are listed above).  If the C<==> comparison operator
is used between these objects it will return true if the objects are visually exactly the same,
and false otherwise. For example, if a correct answer is C<$correct = {line, solid, (0, 0), (1, 1)}>
and the student graphs the line that is represented by C<$student = {line, solid, (-2, -2), (3, 3)}>,
then C<$correct == $student> will be true.

In addition there are two methods all C<GraphTool::GraphObject>s have that are useful.

The first is the C<pointCmp> method. When it is called for most C<GraphTool::GraphObject>s,
passing a MathObject point it will return 0 if the point satisfies the equation of the object,
-1 if the equation evaluated at the point is negative, and 1 if the equation evaluated at the
point is positive. For a segment or vector it will return 0 if it is a point on the segment or
vector, 1 if the point is on the segment or vector extended to infinity but not on the segment
or vector, and otherwise it will return the same that it would for a line. For a triangle it
will return 0 if the point is on an edge, 1 if it is inside, and -1 if it is outside. For a
quadrilateral it will return 0 if the point is on an edge, and -1 if it is outside.  But if the
point is inside then it depends on if the quadrilateral is crossed or not.  If the quadrilateral
is not crossed it will return 1. If it is crossed, then it will return a positive number that is
different depending on which part of the interior it is in. For a fill, the C<pointCmp> method
will return 0 if the point is in the same region as the fill point, and 1 otherwise.

The second method is the C<cmp> method.  When it is called for a C<GraphTool::GraphObject>
object passing it another C<GraphTool::GraphObject> object it will return 1 if the two objects
are visually exactly the same, and 0 otherwise (this is equivalent to using the C<==> operator).
A second parameter may be passed and if that parameter is 1, then the method will return 1 if
the two objects are the same ignoring if the two objects are solid or dashed, and 0 otherwise.
For example, if a correct answer is C<$correct = {line, solid, (0, 0), (1, 1)}> and the student
graphs the line that is represented by C<$student = {line, dashed, (-2, -2), (3, 3)}>, then
C<< $correct->cmp($student, 1) >> will return 1.

Further note that a C<GraphTool::GraphObject> derives from a MathObject C<List>, and so the
things that can be done with MathObject C<List>s can also be done with
C<GraphTool::GraphObject>s.

An example of a custom checker follows:

    $m = 2 * random(1, 4);

    $gt = GraphTool("{line, solid, ($m / 2, 0), (0, -$m)}")->with(
        cmpOptions => {
            list_checker => sub {
                my ($correct, $student, $ans, $value) = @_;

                my $score = 0;
                my @errors;

                for (0 .. $#$student) {
                    if ($correct->[0] == $student->[$_]) { ++$score; next; }

                    my $nth = Value::List->NameForNumber($_ + 1);

                    if ($student->[$_]->extract(1) ne 'line') {
                        push(@errors, "The $nth object graphed is not a line.");
                        next;
                    }

                    if ($student->[$_]->extract(2) ne 'solid') {
                        push(@errors, "The $nth object graphed should be a solid line.");
                        next;
                    }

                    if (!$correct->[0]->pointCmp($student->[$_]->extract(3))
                        || !$correct->[0]->pointCmp($student->[$_]->extract(4)))
                    {
                        $score += 0.5;
                        push(@errors,
                            "One of points graphed on the $nth object is incorrect."
                        );
                        next;
                    }

                    push(@errors, "The $nth object graphed is incorrect.");
                }

                return ($score, @errors);
            }
        }
    }

B<The following is deprecated. Do not use it in new problems. Existing problems that use this
approach should be rewritten to use the above approach instead.>

The variable C<$graphToolObjectCmps> can be used in a custom checker and contains
a hash whose keys are the types of the objects described above, and whose values are methods
that can be called passing a MathObject list constructed from one of the objects described
above.  When one of these methods is called it will return two methods.  The first method when
called passing a MathObject point will return 0 if the point satisfies the equation of the
object, -1 if the equation evaluated at the point is negative, and 1 if the equation evaluated
at the point is positive.  The second method when called passing another MathObject list
constructed from one of the objects described as above will return 1 if the two objects are
exactly the same, and 0 otherwise.  A second parameter may be passed and if that parameter is 1,
then the method will return 1 if the two objects are the same ignoring if the two objects are
solid or dashed, and 0 otherwise.

In the following example, the C<$lineCmp> method is defined to be the second method (indexed by
1) that is returned by calling the C<'line'> method on the first correct answer in the example.

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

Note that for C<'vector'> graph objects the C<GraphTool> object must be passed in addition to
the correct C<'vector'> object to compare to. For example,

    my $vectorCmp = ($graphToolObjectCmps->{vector}->($correct->[0], $gt))[1];

This is so that the correct methods can be returned that take into account the
C<vectorsArePositional> option that is set for the particular C<$gt> object.

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

=item scaleX, scaleY (Default: C<< scaleX => 1, scaleY => 1 >>)

These are the scale of the ticks on the x and y axes. That is the distance between two
successive ticks on the axis (including both major and minor ticks).

=item scaleSymbolX, scaleSymbolY (Default: C<< scaleSymbolX => '', scaleSymbolY => '' >>)

These are the scale symbols for the ticks on the x and y axes. The tick labels on the axis will
be shown as multiples of this symbol.

This can be used in combination with the C<scaleX> option to show tick labels at multiples of
pi, for instance. This can be accomplished using the settings C<< scaleX => pi->value >> and
C<< scaleSymbolX => '\pi' >>.

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

    JSXGraphOptions => Mojo::JSON::encode_json({
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

This changes the way coordinate hints and axes tick labels are shown.  By default these are
displayed as decimal numbers accurate to five decimal places.  If this is set to 'fraction',
then those decimals will be converted and displayed as fractions.  If this is set to 'mixed',
then those decimals will be converted and displayed as mixed numbers.  For example, if the
snapSizeX is set to 1/3, then what would be displayed as 4.66667 with the default 'decimal'
setting, would be instead be displayed as 14/3 with the 'fraction' setting, and '4 2/3' with the
'mixed' setting.  Note that these fractions are typeset by MathJax.

Make sure that the snap size is given with decent accuracy.  For example, if the snap size is
set to 0.33333, then instead of 1/3 being displayed, 33333/1000000 will be displayed.  It is
recommended to actually give an actual fraction for the snap size (like 1/3), and let perl and
javascript compute that to get the best result.

=item coordinateHintsTypeX (Default: C<< coordinateHintsTypeX => undef >>)

This does the same as the coordinateHintsType option, but only for the x-coordinate and x-axis
tick labels.  If this is undefined then the coordinateHintsType option is used for the
x-coordinate and x-axis tick labels.

=item coordinateHintsTypeY (Default: C<< coordinateHintsTypeY => undef >>)

This does the same as the coordinateHintsType option, but only for the y-coordinate and y-axis
tick labels.  If this is undefined then the coordinateHintsType option is used for the
y-coordinate and y-axis tick labels.

=item availableTools (Default: C<< availableTools => [ "LineTool", "CircleTool",
    "VerticalParabolaTool", "HorizontalParabolaTool", "FillTool", "SolidDashTool" ] >>)

This is an array of tools that will be made available for students to use in the graph tool.
The order the tools are listed here will also be the order the tools are presented in the graph
tool button box.  In addition to the tools listed in the default options above, the following
tools may be used:

    "PointTool"
    three point "QuadraticTool"
    four point "CubicTool"
    "IntervalTool"
    "IncludeExcludePointTool"
    "SineWaveTool"
    "TriangleTool"
    "QuadrilateralTool"
    "SegmentTool"
    "VectorTool"

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

=item vectorsArePositional (Default: C<< vectorsArePositional => 0 >>)

If set to 1, then the default checker will consider two vectors that have the same magnitude and
direction but different initial points to be different vectors.  Otherwise two vectors that have
the same magnitude and direction will be considered equal. This option only has effect when a
C<vector> is part of the answer, and the C<VectorTool> is used.

=item useFloodFill (Default: C<< useFloodFill => 0 >>)

If set to 1, then a flood fill algorithm is used for filling regions. The flood fill algorithm
fills from the selected point outward and stops at boundaries created by the graphed objects.
The alternate fill that is used if C<useFloodFill> is 0 (the default) is an inequality fill. It
shades all points that satisfy the same inequalities relative to the graphed objects.  The
inequality fill algorithm is highly efficient and more reliable, but does not work well and
doesn't even make sense with some graph objects. For example, it is quite counter intuitive for
quadrilaterals, triangles, line segments and vectors.

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

BEGIN { strict->import }

sub _parserGraphTool_init {
	ADD_CSS_FILE('node_modules/jsxgraph/distrib/jsxgraph.css');
	ADD_CSS_FILE('js/GraphTool/graphtool.css');
	ADD_JS_FILE('node_modules/jsxgraph/distrib/jsxgraphcore.js', 0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/graphtool.js',                     0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/pointtool.js',                     0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/linetool.js',                      0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/circletool.js',                    0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/parabolatool.js',                  0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/quadratictool.js',                 0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/cubictool.js',                     0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/intervaltools.js',                 0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/sinewavetool.js',                  0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/triangle.js',                      0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/quadrilateral.js',                 0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/segments.js',                      0, { defer => undef });
	ADD_JS_FILE('js/GraphTool/filltool.js',                      0, { defer => undef });

	return;
}

loadMacros('MathObjects.pl', 'PGtikz.pl');

sub GraphTool { parser::GraphTool->create(@_) }

$main::graphToolObjectCmps = \%parser::GraphTool::graphObjectCmps;

package parser::GraphTool;
our @ISA = qw(Value::List);

my %contextStrings = (solid => {}, dashed => {});
my %graphObjects;
our %graphObjectCmps = ();

my $fillResolution = 400;

sub create {
	my ($invocant, @options) = @_;

	my $context;
	if (Value::isContext($options[0])) {
		# This supports a context being passed in for the first argument. This should be used with care.  At the very
		# least the context needs to derive from the Point context. There are advanced use cases that this allows for.
		$context = shift @options;
	} else {
		$context = Parser::Context->getCopy('Point');
		$context->{name} = 'GraphTool';
	}

	$context->{value}{List} = 'parser::GraphTool';
	$context->parens->set(
		'{' => { close => '}', type => 'List', formList => 1, formMatrix => 0, removable => 0 },
		'[' => { type  => 'Interval' }
	);
	$context->lists->set(
		GraphTool => {
			class       => 'Parser::List::List',
			open        => '',
			close       => '',
			separator   => ', ',
			nestedOpen  => '{',
			nestedClose => '}'
		},
		GraphObject => { class => 'Parser::List::List', open => '{', close => '}', separator => ', ' }
	);
	$context->strings->add(%contextStrings);

	my $self = $invocant->SUPER::new($context, @options);
	$self->{toolObject}           = 1;
	$self->{staticObjects}        = $self->SUPER::new([]);
	$self->{cmpOptions}           = {};
	$self->{bBox}                 = [ -10, 10, 10, -10 ];
	$self->{gridX}                = 1;
	$self->{gridY}                = 1;
	$self->{snapSizeX}            = 1;
	$self->{snapSizeY}            = 1;
	$self->{ticksDistanceX}       = 2;
	$self->{ticksDistanceY}       = 2;
	$self->{minorTicksX}          = 1;
	$self->{minorTicksY}          = 1;
	$self->{scaleX}               = 1;
	$self->{scaleY}               = 1;
	$self->{scaleSymbolX}         = '';
	$self->{scaleSymbolY}         = '';
	$self->{xAxisLabel}           = 'x';
	$self->{yAxisLabel}           = 'y';
	$self->{ariaDescription}      = '';
	$self->{showCoordinateHints}  = 1;
	$self->{coordinateHintsType}  = 'decimal';
	$self->{coordinateHintsTypeX} = undef;
	$self->{coordinateHintsTypeY} = undef;
	$self->{showInStatic}         = 1;
	$self->{numberLine}           = 0;
	$self->{useBracketEnds}       = 0;
	$self->{vectorsArePositional} = 0;
	$self->{useFloodFill}         = 0;
	$self->{unitX}                = ($fillResolution - 1) / 20;
	$self->{unitY}                = ($fillResolution - 1) / 20;
	$self->{availableTools} =
		[ 'LineTool', 'CircleTool', 'VerticalParabolaTool', 'HorizontalParabolaTool', 'FillTool', 'SolidDashTool' ];
	$self->{texSize}    = 400;
	$self->{graphCount} = 0;

	$context->flags->set(graphToolObject => $self);

	return $self;
}

sub new {
	my ($invocant, @options) = @_;

	my $context;
	if (Value::isContext($options[0])) {
		$context = shift @options;
		if (@options == 1 && $graphObjects{ $options[0][0] }) {
			return GraphTool::GraphObject->new($context, Value::List->new($options[0]),
				$graphObjects{ $options[0][0] });
		}
	}

	return $invocant->SUPER::new($context, @options);
}

sub class { return 'GraphTool'; }
sub type  { return 'List'; }

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

	$options{staticObjects} = $self->SUPER::new($options{staticObjects}) if ref($options{staticObjects}) eq 'ARRAY';

	$self = $self->SUPER::with(%options);
	if ($self->{toolObject}) {
		# This ensures that both the original $self and the new $self have their own context that has the
		# graphToolObject context flag referring to the correct copy of $self. Furthermore, all of the objects for each
		# copy also have the correct context with the flag referring to their copy of $self.
		$self = $self->copy;
		my $context = $self->context->copy;
		$context->flags->set(graphToolObject => $self);
		$self->context($context);
		$self->{staticObjects} = $self->{staticObjects}->copy;
		$self->{staticObjects}->context($context);

		# These must be recomputed in case the bounding box changed.  This also prevents someone from changing these
		# directly.  They must be defined correctly in terms of the fill resolution and the bounding box with the
		# formulas below or the flood fill algorithm won't work right and could even be thrown into an infinite loop.
		$self->{unitX} = ($fillResolution - 1) / ($self->{bBox}[2] - $self->{bBox}[0]);
		$self->{unitY} = ($fillResolution - 1) / ($self->{bBox}[1] - $self->{bBox}[3]);
	}
	return $self;
}

sub sign {
	my $x = shift;
	return -1 if $x < -0.000001;
	return 1  if $x > 0.000001;
	return 0;
}

my $customGraphObjects = '';
my $customTools        = '';

sub addGraphObjects {
	my ($self, @objects) = @_;

	while (@objects) {
		my ($name, $object) = (shift @objects, shift @objects);
		$customGraphObjects .= "['$name', $object->{js}]" . ',';
		$contextStrings{$name} = {};
		$contextStrings{$_}    = {} for (@{ $object->{strings} });

		if ($object->{perlClass}) {
			$graphObjects{$name} = $object->{perlClass};

			# Add a backwards compatibility entry to the %graphObjectCmps hash.
			$graphObjectCmps{$name} = sub {
				my $object = shift;
				return (sub { $object->pointCmp(@_) }, sub { $object->cmp(@_) });
			};
		} else {
			# Backwards compatibility for the deprecated old way of adding objects.
			$graphObjects{$name} = {
				defined $object->{tikz}       ? (tikz => $object->{tikz}) : (),
				ref($object->{cmp}) eq 'CODE' ? (cmp  => $object->{cmp})  : ()
			};

			$graphObjectCmps{$name} = $object->{cmp} if ref($object->{cmp}) eq 'CODE';
		}
	}

	return;
}

sub addTools {
	my ($self, @tools) = @_;
	while (@tools) {
		my ($name, $tool) = (shift @tools, shift @tools);
		$customTools .= "['$name', $tool]" . ',';
	}
	return;
}

parser::GraphTool->addGraphObjects(
	point    => { js => 'graphTool.pointTool.Point',   perlClass => 'GraphTool::GraphObject::Point' },
	line     => { js => 'graphTool.lineTool.Line',     perlClass => 'GraphTool::GraphObject::Line' },
	circle   => { js => 'graphTool.circleTool.Circle', perlClass => 'GraphTool::GraphObject::Circle' },
	parabola => {
		js        => 'graphTool.parabolaTool.Parabola',
		perlClass => 'GraphTool::GraphObject::Parabola',
		strings   => [qw(vertical horizontal)]
	},
	quadratic     => { js => 'graphTool.quadraticTool.Quadratic', perlClass => 'GraphTool::GraphObject::Quadratic' },
	cubic         => { js => 'graphTool.cubicTool.Cubic',         perlClass => 'GraphTool::GraphObject::Cubic' },
	interval      => { js => 'graphTool.intervalTool.Interval',   perlClass => 'GraphTool::GraphObject::Interval' },
	sineWave      => { js => 'graphTool.sineWaveTool.SineWave',   perlClass => 'GraphTool::GraphObject::SineWave' },
	triangle      => { js => 'graphTool.triangleTool.Triangle',   perlClass => 'GraphTool::GraphObject::Triangle' },
	quadrilateral =>
		{ js => 'graphTool.quadrilateralTool.Quadrilateral', perlClass => 'GraphTool::GraphObject::Quadrilateral' },
	segment => { js => 'graphTool.segmentTool.Segment', perlClass => 'GraphTool::GraphObject::Segment' },
	vector  => { js => 'graphTool.vectorTool.Vector',   perlClass => 'GraphTool::GraphObject::Vector' },
	fill    => { js => 'graphTool.fillTool.Fill',       perlClass => 'GraphTool::GraphObject::Fill' }
);

parser::GraphTool->addTools(
	PointTool               => 'graphTool.pointTool.PointTool',
	LineTool                => 'graphTool.lineTool.LineTool',
	CircleTool              => 'graphTool.circleTool.CircleTool',
	ParabolaTool            => 'graphTool.parabolaTool.ParabolaTool',
	VerticalParabolaTool    => 'graphTool.parabolaTool.VerticalParabolaTool',
	HorizontalParabolaTool  => 'graphTool.parabolaTool.HorizontalParabolaTool',
	QuadraticTool           => 'graphTool.quadraticTool.QuadraticTool',
	CubicTool               => 'graphTool.cubicTool.CubicTool',
	IntervalTool            => 'graphTool.intervalTool.IntervalTool',
	SineWaveTool            => 'graphTool.sineWaveTool.SineWaveTool',
	TriangleTool            => 'graphTool.triangleTool.TriangleTool',
	QuadrilateralTool       => 'graphTool.quadrilateralTool.QuadrilateralTool',
	SegmentTool             => 'graphTool.segmentTool.SegmentTool',
	VectorTool              => 'graphTool.vectorTool.VectorTool',
	FillTool                => 'graphTool.fillTool.FillTool',
	IncludeExcludePointTool => 'graphTool.includeExcludePointTool.IncludeExcludePointTool'
);

sub ANS_NAME {
	my $self = shift;
	main::RECORD_IMPLICIT_ANS_NAME($self->{name} = main::NEW_ANS_NAME()) unless defined $self->{name};
	return $self->{name};
}

# Convert the GraphTool object's options into JSON that can be passed to the JavaScript
# graphTool method.
sub constructJSXGraphOptions {
	my $self = shift;
	return if defined($self->{JSXGraphOptions});
	$self->{JSXGraphOptions} = Mojo::JSON::encode_json({
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
						scale         => $self->{scaleX},
						scaleSymbol   => $self->{scaleSymbolX},
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
				x => {
					ticks => {
						ticksDistance => $self->{ticksDistanceX},
						minorTicks    => $self->{minorTicksX},
						scale         => $self->{scaleX},
						scaleSymbol   => $self->{scaleSymbolX}
					}
				},
				y => {
					ticks => {
						ticksDistance => $self->{ticksDistanceY},
						minorTicks    => $self->{minorTicksY},
						scale         => $self->{scaleY},
						scaleSymbol   => $self->{scaleSymbolY}
					}
				}
			},
			grid => { majorStep => [ $self->{gridX}, $self->{gridY} ] }
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
			staticObjects: '${\(join(',', $self->{staticObjects}->value))}',
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
			useFloodFill: $self->{useFloodFill},
			customGraphObjects: [ $customGraphObjects ],
			customTools: [ $customTools ],
			availableTools: [ '${\(join("','", @{$self->{availableTools}}))}' ],
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

			my @incorrect_objects;

			# If the student graphed multiple objects, then remove the duplicates.  Note that a fuzzy comparison is
			# done.  This means that the solid/dashed status of the objects is ignored for the comparison. Only the
			# solid variant is kept if both appear.  The idea is that solid covers dashed.  Fills are all kept and
			# the duplicates dealt with later.
			my (@student_objects, @student_fills);
		ANSWER: for my $answer (@$student) {
				if (!Value::classMatch($answer, 'GraphObject')) {
					push(@incorrect_objects, $answer);
					next;
				}
				if ($answer->{fillType}) {
					push(@student_fills, $answer);
					next;
				}
				for (0 .. $#student_objects) {
					next unless $student_objects[$_]{data}[0] eq $answer->{data}[0];
					if ($student_objects[$_]->cmp($answer, 1)) {
						$student_objects[$_] = $answer if $answer->{data}[1] eq 'solid';
						next ANSWER;
					}
				}
				push(@student_objects, $answer);
			}

			# Cache the correct graph objects. The fill graph objects are separated from the others.  The others must be
			# passed to the fill graph object compare methods.  Fills need to have all of these to determine the correct
			# regions of the graph that are to be filled.  Note that the graph objects for static objects are added to
			# this list later.
			my @objects;
			my @fillObjects;
			for (@$correct) {
				if   ($_->{fillType}) { push(@fillObjects, $_); }
				else                  { push(@objects,     $_); }
			}

			my @object_scores = (0) x @objects;

		ENTRY: for my $student_object (@student_objects) {
				for (0 .. $#objects) {
					if ($objects[$_]->cmp($student_object)) {
						++$object_scores[$_];
						next ENTRY;
					}
				}

				push(@incorrect_objects, $student_object);
			}

			my $object_score = 0;
			for (@object_scores) { ++$object_score if $_; }

			my $fill_score = 0;
			my @fill_scores;
			my @incorrect_fills;

			# Now check the fills if all of the objects were correctly graphed.
			if ($object_score == @object_scores && $object_score == @student_objects) {
				@fill_scores = (0) x @fillObjects;

			ENTRY: for my $student_index (0 .. $#student_fills) {
					for (0 .. $#fillObjects) {
						if ($fillObjects[$_]->cmp($student_fills[$student_index])) {
							++$fill_scores[$_];
							next ENTRY;
						}
					}

					# Skip incorrect fills in the same region as another incorrect fill.
					for (@incorrect_fills) {
						next ENTRY if $_->cmp($student_fills[$student_index]);
					}

					# Cache incorrect fill objects.
					push(@incorrect_fills, $student_fills[$student_index]);
				}

				for (@fill_scores) { ++$fill_score if $_; }
			}

			my $score =
				($object_score + $fill_score) /
				(@$correct +
					(@incorrect_objects ? (@incorrect_objects - (@object_scores - $object_score)) : 0) +
					(@incorrect_fills   ? (@incorrect_fills - (@fill_scores - $fill_score))       : 0));

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
	my $answerObjects   = $options{showCorrect} ? join(',', $self->value) : '';
	$answerObjects = join(',', $options{objects}, $answerObjects || ()) if defined $options{objects};

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
			staticObjects: '${\(join(',', $self->{staticObjects}->value))}',
			answerObjects: '$answerObjects',
			isStatic: true,
			snapSizeX: $self->{snapSizeX},
			snapSizeY: $self->{snapSizeY},
			xAxisLabel: '$self->{xAxisLabel}',
			yAxisLabel: '$self->{yAxisLabel}',
			numberLine: $self->{numberLine},
			useBracketEnds: $self->{useBracketEnds},
			useFloodFill: $self->{useFloodFill},
			customGraphObjects: [ $customGraphObjects ],
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
	my (@object_group, @objects);
	push(@object_group, $self->{staticObjects}) if $self->{staticObjects};
	push(@object_group, $self)                  if $options{showCorrect};

	for my $obj (@object_group) {
		# Graph the points, lines, circles, and parabolas in this group.

		# Switch to the foreground layer and clipping box for the objects.
		$tikz .= "\\begin{pgfonlayer}{foreground}\n";
		$tikz .= "\\clip[rounded corners=14pt] "
			. "($self->{bBox}[0],$self->{bBox}[3]) rectangle ($self->{bBox}[2],$self->{bBox}[1]);\n";

		my @fills;

		# First graph lines, parabolas, and circles.  Cache the clipping path and a function
		# for determining which side of the object to shade for filling later.
		for ($obj->value) {
			next unless Value::classMatch($_, 'GraphObject');
			if ($_->{fillType}) {
				push(@fills, $_);
				next;
			}
			$tikz .= $_->tikz;
			push(@objects, $_);
		}

		# Switch from the foreground layer to the background layer for the fills.
		$tikz .= "\\end{pgfonlayer}\n\\begin{pgfonlayer}{background}\n";

		# Now shade the fill regions.
		$tikz .= $_->tikz(\@objects) for @fills;

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

package GraphTool::GraphObject;
our @ISA = qw(Value::List);

# It is important that the parser::GraphTool object saved in the context flags is not accessed directly in the new
# method for any package that derives from the GraphTool::GraphObject package.  The objects for correct answers are
# constructed when the parser::GraphTool "create" method is called, and at that time only the default GraphTool options
# are available.  If the constructor uses one of those options (for example many of the objects use the bBox option) and
# that option is later changed when calling the "with" method, then the computations in the constructor will be
# incorrect and not updated.
sub new {
	my ($invocant, @arguments) = @_;
	my $context = Value::isContext($arguments[0]) ? shift @arguments : $invocant->context;
	my ($object, $definition) = @arguments;

	return $definition->new($context, $object) if (defined $definition && ref($definition) ne 'HASH');

	my $self = $invocant->SUPER::new($context, $object);

	if (ref($definition) eq 'HASH') {
		$self->{compatibility} = $definition;
		$self->{fillType}      = 1 if $self->{compatibility}{tikz}{fillType};
	}

	return $self;
}

sub class {'GraphObject'}

# This should return 0 if the $point is satisfies the defining equation of the object or is on an edge of the object.
# Otherwise it should return a nonzero number indicating a side or region of the object that the point is in.
sub pointCmp {
	my ($self, $point) = @_;
	$self->compatibility;
	return ref($self->{pointCmp}) eq 'CODE' ? $self->{pointCmp}->($point) : 1;
}

# If $fuzzy is false, then this should return true (or 1) if the $other object is visually the same as this object, and
# false (or 0) otherwise. If $fuzzy is true, then this should return true if the $other object is visually the same as
# the object ignoring if one object is solid and the other is dashed, and zero otherwise.
sub cmp {
	my ($self, $other, $fuzzy) = @_;
	$self->compatibility;
	return ref($self->{cmp}) eq 'CODE' ? $self->{cmp}->($other, $fuzzy) : 1;
}

# This makes the == operator work for GraphTool::GraphObjects. It should usually not be overridden.  Instead override
# the cmp method above.
sub compare { my ($self, @args) = @_; return !$self->cmp(@args); }

# The TikZ code to draw the object.
sub tikz { my $self = shift; $self->compatibility; return $self->{tikz} // ''; }

# The TikZ clipping path for the object (used by the inequality fill method) with out the \clip command and its options.
sub clipCode { my $self = shift; $self->compatibility; return $self->{clipCode} // ''; }

# The TikZ clipping path for the object (used by the inequality fill method) with the \clip command and options. Most
# objects only override the clipCode method and let this method add in the default \clip command and inverse clip option
# based on the fillCmp return value.
sub clip {
	my ($self, $fx, $fy) = @_;
	$self->compatibility;
	return $self->{clipCode}->($self->{fx}, $self->{fy}) if ref($self->{clipCode}) eq 'CODE';
	my $clip_dir = $self->fillCmp($fx, $fy);
	return if $clip_dir == 0;
	return "\\clip " . ($clip_dir < 0 ? '[inverse clip]' : '') . $_->clipCode . ";\n";
}

# This method should return discrete values that represent which region the point ($x, $y) is in of the regions the
# object breaks the plane into.  The same value must be returned for all points in the same region.  This method should
# return 0 for all points on a border of the object.
sub fillCmp {
	my ($self, $x, $y) = @_;
	$self->compatibility;
	return ref($self->{fillCmp}) eq 'CODE' ? $self->{fillCmp}->($x, $y) : 1;
}

# This is only used by the flood fill algorithm, and should return 1 if $point is on the border of an object, and 0
# otherwise. This only needs to be overridden if the flood fill algorithm could potentially bleed across a boundary from
# one region to another (as determined by the return value of the fillCmp method) or the flood fill algorithm could
# potentially go around an end of the object.
sub onBoundary {
	my ($self, $point, $aVal, $from) = @_;
	$self->compatibility;
	return
		ref($self->{onBoundary}) eq 'CODE'
		? $self->{onBoundary}->($point, $aVal, $from)
		: $self->fillCmp(@$point) != $aVal;
}

# This method provides backward compatibility for objects defined the old way not deriving from the
# GraphTool::GraphObject package. The old methods must be called after construction because they may perform
# computations using options that are not set to their final values at that time. This is only called once and the
# results cached for later use.
sub compatibility {
	my $self = shift;
	return unless $self->{compatibility};
	my $graphToolObject = $self->context->flags->get('graphToolObject');
	($self->{pointCmp}, $self->{cmp}) = $self->{compatibility}{cmp}->($self, $graphToolObject)
		if ref($self->{compatibility}{cmp}) eq 'CODE';
	if (ref($self->{compatibility}{tikz}{code}) eq 'CODE') {
		# Make sure that $self is set as $_ because previously there
		# was an assumption that the object would be passed as $_.
		for ($self) {
			($self->{tikz}, my $fillData) = $self->{compatibility}{tikz}{code}->($graphToolObject, $self);
			($self->{clipCode}, $self->{fillCmp}, $self->{onBoundary}) = @$fillData if ref($fillData) eq 'ARRAY';
		}
	}
	delete $self->{compatibility};
}

package GraphTool::GraphObject::Point;
our @ISA = qw(GraphTool::GraphObject);

sub new {
	my ($invocant, @arguments) = @_;
	my $context = Value::isContext($arguments[0]) ? shift @arguments : $invocant->context;
	my $self    = $invocant->SUPER::new($context, @arguments);

	$self->{point} = $self->{data}[1];
	($self->{x}, $self->{y}) = map { $_->value } @{ $self->{point}{data} };
	$self->{clipCode} = '';

	return $self;
}

sub pointCmp {
	my ($self, $point) = @_;
	return $self->{point} == $point ? 0 : 1;
}

sub cmp {
	my ($self, $other, $fuzzy) = @_;
	return $other->{data}[0] eq 'point' && $self->{point} == $other->{data}[1];
}

sub tikz {
	my $self = shift;
	return "\\draw[line width = 4pt, blue, fill = red] ($self->{x}, $self->{y}) circle[radius = 5pt];\n";
}

package GraphTool::GraphObject::Line;
our @ISA = qw(GraphTool::GraphObject);

sub new {
	my ($invocant, @arguments) = @_;
	my $context = Value::isContext($arguments[0]) ? shift @arguments : $invocant->context;
	my $self    = $invocant->SUPER::new($context, @arguments);

	$self->{solid_dashed} = $self->{data}[1];
	($self->{x1}, $self->{y1}) = $self->{data}[2]->value;
	($self->{x2}, $self->{y2}) = $self->{data}[3]->value;

	$self->{isVertical} = $self->{x1}->value == $self->{x2}->value;
	$self->{stdform} =
		[ $self->{y1} - $self->{y2}, $self->{x2} - $self->{x1}, $self->{x1} * $self->{y2} - $self->{x2} * $self->{y1} ];

	$self->{normalLength}   = sqrt(($self->{stdform}[0]->value)**2 + ($self->{stdform}[1]->value)**2);
	$self->{drawAttributes} = '';

	if (!$self->{isVertical}) {
		my $m = ($self->{y2}->value - $self->{y1}->value) / ($self->{x2}->value - $self->{x1}->value);
		my ($x1, $y1) = ($self->{x1}->value, $self->{y1}->value);
		$self->{y} = sub { return $m * ($_[0] - $x1) + $y1; };
	}

	return $self;
}

sub pointCmp {
	my ($self, $point) = @_;
	my ($x,    $y)     = $point->value;
	return $self->{stdform}[0] * $x + $self->{stdform}[1] * $y + $self->{stdform}[2] <=> 0;
}

sub cmp {
	my ($self, $other, $fuzzy) = @_;
	return
		$other->{data}[0] eq 'line'
		&& ($fuzzy || $other->{data}[1] eq $self->{solid_dashed})
		&& $self->pointCmp($other->{data}[2]) == 0
		&& $self->pointCmp($other->{data}[3]) == 0;
}

sub tikzCode {
	my $self = shift;
	my $bBox = $self->context->flags->get('graphToolObject')->{bBox};
	if ($self->{isVertical}) {
		return "($self->{x1}, $bBox->[3]) -- ($self->{x1}, $bBox->[1])";
	} else {
		return "($bBox->[0]," . $self->{y}->($bBox->[0]) . ') -- ' . "($bBox->[2]," . $self->{y}->($bBox->[2]) . ')';
	}
}

sub tikz {
	my $self = shift;
	return
		"\\draw[thick, blue, line width = 2.5pt, $self->{solid_dashed}$self->{drawAttributes}] "
		. $self->tikzCode . ";\n";
}

sub clipCode {
	my $self = shift;
	my $bBox = $self->context->flags->get('graphToolObject')->{bBox};
	$self->tikzCode
		. " -- ($bBox->[2], $bBox->[1]) -- "
		. ($self->{isVertical} ? "($bBox->[2], $bBox->[3])" : "($bBox->[0], $bBox->[1])")
		. ' -- cycle';
}

sub fillCmp {
	my ($self, $x, $y) = @_;
	return $self->{isVertical}
		? parser::GraphTool::sign($x - $self->{x1}->value)
		: parser::GraphTool::sign($y - $self->{y}->($x));
}

package GraphTool::GraphObject::Circle;
our @ISA = qw(GraphTool::GraphObject);

sub new {
	my ($invocant, @arguments) = @_;
	my $context = Value::isContext($arguments[0]) ? shift @arguments : $invocant->context;
	my $self    = $invocant->SUPER::new($context, @arguments);

	$self->{solid_dashed} = $self->{data}[1];
	$self->{center}       = $self->{data}[2];
	($self->{cx}, $self->{cy}) = $self->{center}->value;
	($self->{px}, $self->{py}) = $self->{data}[3]->value;

	$self->{r_squared} = ($self->{cx} - $self->{px})**2 + ($self->{cy} - $self->{py})**2;
	$self->{r}         = sqrt($self->{r_squared}->value);
	$self->{tikzCode}  = "($self->{cx}, $self->{cy}) circle[radius = $self->{r}]";
	$self->{clipCode}  = $self->{tikzCode};

	return $self;
}

sub pointCmp {
	my ($self, $point) = @_;
	my ($x,    $y)     = $point->value;
	return ($x - $self->{cx})**2 + ($y - $self->{cy})**2 <=> $self->{r_squared};
}

sub cmp {
	my ($self, $other, $fuzzy) = @_;
	return
		$other->{data}[0] eq 'circle'
		&& ($fuzzy || $other->{data}[1] eq $self->{solid_dashed})
		&& $other->{data}[2] == $self->{center}
		&& $self->pointCmp($other->{data}[3]) == 0;
}

sub tikz {
	my $self = shift;
	return "\\draw[thick, blue, line width = 2.5pt, $self->{solid_dashed}] $self->{tikzCode};\n";
}

sub fillCmp {
	my ($self, $x, $y) = @_;
	return parser::GraphTool::sign($self->{r} - sqrt(($self->{cx}->value - $x)**2 + ($self->{cy}->value - $y)**2));
}

package GraphTool::GraphObject::Parabola;
our @ISA = qw(GraphTool::GraphObject);

sub new {
	my ($invocant, @arguments) = @_;
	my $context = Value::isContext($arguments[0]) ? shift @arguments : $invocant->context;
	my $self    = $invocant->SUPER::new($context, @arguments);

	$self->{solid_dashed}        = $self->{data}[1];
	$self->{vertical_horizontal} = $self->{data}[2];
	$self->{vertex}              = $self->{data}[3];
	($self->{h}, $self->{k})   = $self->{vertex}->value;
	($self->{px}, $self->{py}) = $self->{data}[4]->value;

	if ($self->{vertical_horizontal} eq 'vertical') {
		$self->{a}         = (($self->{py} - $self->{k}) / ($self->{px} - $self->{h})**2)->value;
		$self->{yFunction} = sub { return $self->{a} * ($_[0] - $self->{h}->value)**2 + $self->{k}->value; };
	} else {
		$self->{a}         = (($self->{px} - $self->{h}) / ($self->{py} - $self->{k})**2)->value;
		$self->{xFunction} = sub { return $self->{a} * ($_[0] - $self->{k}->value)**2 + $self->{h}->value; };
	}

	return $self;
}

sub pointCmp {
	my ($self, $point) = @_;
	my ($x,    $y)     = $point->value;
	my $x_pow = $self->{vertical_horizontal} eq 'vertical' ? 2 : 1;
	my $y_pow = $self->{vertical_horizontal} eq 'vertical' ? 1 : 2;
	return ($self->{px} - $self->{h})**$x_pow *
		($y - $self->{k})**$y_pow <=> ($self->{py} - $self->{k})**$y_pow *
		($x - $self->{h})**$x_pow;
}

sub cmp {
	my ($self, $other, $fuzzy) = @_;
	return
		$other->{data}[0] eq 'parabola'
		&& ($fuzzy || $other->{data}[1] eq $self->{solid_dashed})
		&& $other->{data}[2] eq $self->{vertical_horizontal}
		&& $other->{data}[3] == $self->{vertex}
		&& $self->pointCmp($other->{data}[4]) == 0;
}

sub tikzCode {
	my $self = shift;
	my $bBox = $self->context->flags->get('graphToolObject')->{bBox};
	if ($self->{vertical_horizontal} eq 'vertical') {
		my $diff = sqrt((($self->{a} >= 0 ? $bBox->[1] : $bBox->[3]) - $self->{k}->value) / $self->{a});
		my $dmin = $self->{h}->value - $diff;
		my $dmax = $self->{h}->value + $diff;
		return "plot[domain = $dmin:$dmax, smooth] (\\x, {$self->{a} * (\\x - ($self->{h}))^2 + ($self->{k})})";
	} else {
		$self->{a} = (($self->{px} - $self->{h}) / ($self->{py} - $self->{k})**2)->value;
		my $diff = sqrt((($self->{a} >= 0 ? $bBox->[2] : $bBox->[0]) - $self->{h}->value) / $self->{a});
		my $dmin = $self->{k}->value - $diff;
		my $dmax = $self->{k}->value + $diff;
		return "plot[domain = $dmin:$dmax, smooth] ({$self->{a} * (\\x - ($self->{k}))^2 + ($self->{h})}, \\x)";
	}
}

sub tikz {
	my $self = shift;
	return "\\draw[thick, blue, line width = 2.5pt, $self->{solid_dashed}] " . $self->tikzCode . ";\n";
}

sub clipCode {
	my $self = shift;
	return $self->tikzCode;
}

sub fillCmp {
	my ($self, $x, $y) = @_;
	return $self->{vertical_horizontal} eq 'vertical'
		? parser::GraphTool::sign($self->{a} * ($y - $self->{yFunction}->($x)))
		: parser::GraphTool::sign($self->{a} * ($x - $self->{xFunction}->($y)));
}

package GraphTool::GraphObject::Quadratic;
our @ISA = qw(GraphTool::GraphObject);

sub new {
	my ($invocant, @arguments) = @_;
	my $context = Value::isContext($arguments[0]) ? shift @arguments : $invocant->context;
	my $self    = $invocant->SUPER::new($context, @arguments);

	$self->{solid_dashed} = $self->{data}[1];
	($self->{x1}, $self->{y1}) = $self->{data}[2]->value;
	($self->{x2}, $self->{y2}) = $self->{data}[3]->value;
	($self->{x3}, $self->{y3}) = $self->{data}[4]->value;

	$self->{coeffs} = [
		($self->{x1} - $self->{x2}) * $self->{y3},
		($self->{x1} - $self->{x3}) * $self->{y2},
		($self->{x2} - $self->{x3}) * $self->{y1}
	];
	$self->{den} = ($self->{x1} - $self->{x2}) * ($self->{x1} - $self->{x3}) * ($self->{x2} - $self->{x3});

	my ($x1, $y1) = ($self->{x1}->value, $self->{y1}->value);
	my ($x2, $y2) = ($self->{x2}->value, $self->{y2}->value);
	my ($x3, $y3) = ($self->{x3}->value, $self->{y3}->value);

	my $den = $self->{den}->value;
	$self->{a} = (($x2 - $x3) * $y1 + ($x3 - $x1) * $y2 + ($x1 - $x2) * $y3) / $den;

	$self->{isLine} = abs($self->{a}) < 0.000001;

	if ($self->{isLine}) {
		# Colinear points
		$self->{a}        = 1;
		$self->{function} = sub { return ($y2 - $y1) / ($x2 - $x1) * ($_[0] - $x1) + $y1; };
	} else {
		# Non-degenerate quadratic
		$self->{b} = (($x3**2 - $x2**2) * $y1 + ($x1**2 - $x3**2) * $y2 + ($x2**2 - $x1**2) * $y3) / $den;
		$self->{c} =
			(($x2 - $x3) * $x2 * $x3 * $y1 + ($x3 - $x1) * $x1 * $x3 * $y2 + ($x1 - $x2) * $x1 * $x2 * $y3) / $den;
		$self->{function} = sub { return $self->{a} * $_[0]**2 + $self->{b} * $_[0] + $self->{c}; };
	}

	return $self;
}

sub pointCmp {
	my ($self, $point) = @_;
	my ($x,    $y)     = $point->value;
	return ($x - $self->{x2}) * ($x - $self->{x3}) * $self->{coeffs}[2] -
		($x - $self->{x1}) * ($x - $self->{x3}) * $self->{coeffs}[1] +
		($x - $self->{x1}) * ($x - $self->{x2}) * $self->{coeffs}[0] <=> $self->{den} * $y;
}

sub cmp {
	my ($self, $other, $fuzzy) = @_;
	return
		$other->{data}[0] eq 'quadratic'
		&& ($fuzzy || $other->{data}[1] eq $self->{solid_dashed})
		&& $self->pointCmp($other->{data}[2]) == 0
		&& $self->pointCmp($other->{data}[3]) == 0
		&& $self->pointCmp($other->{data}[4]) == 0;
}

sub tikzCode {
	my $self = shift;
	my $bBox = $self->context->flags->get('graphToolObject')->{bBox};
	if ($self->{isLine}) {
		return
			"($bBox->[0],"
			. $self->{function}->($bBox->[0])
			. ") -- ($bBox->[2],"
			. $self->{function}->($bBox->[2]) . ")";
	} else {
		my $h    = -$self->{b} / (2 * $self->{a});
		my $k    = $self->{c} - $self->{b}**2 / (4 * $self->{a});
		my $diff = sqrt((($self->{a} >= 0 ? $bBox->[1] : $bBox->[3]) - $k) / $self->{a});
		my $dmin = $h - $diff;
		my $dmax = $h + $diff;
		return "plot[domain = $dmin:$dmax, smooth] (\\x, {$self->{a} * (\\x)^2 + ($self->{b}) * \\x + ($self->{c})})";
	}
}

sub tikz {
	my $self = shift;
	return "\\draw[thick, blue, line width = 2.5pt, $self->{solid_dashed}] " . $self->tikzCode . ";\n";
}

sub clipCode {
	my $self = shift;
	my $bBox = $self->context->flags->get('graphToolObject')->{bBox};
	return $self->{isLine}
		? $self->tikzCode . " -- ($bBox->[2], $bBox->[1]) -- ($bBox->[0], $bBox->[1]) -- cycle"
		: $self->tikzCode;
}

sub fillCmp {
	my ($self, $x, $y) = @_;
	return parser::GraphTool::sign($self->{a} * ($y - $self->{function}->($x)));
}

package GraphTool::GraphObject::Cubic;
our @ISA = qw(GraphTool::GraphObject);

sub new {
	my ($invocant, @arguments) = @_;
	my $context = Value::isContext($arguments[0]) ? shift @arguments : $invocant->context;
	my $self    = $invocant->SUPER::new($context, @arguments);

	$self->{solid_dashed} = $self->{data}[1];
	($self->{x1}, $self->{y1}) = $self->{data}[2]->value;
	($self->{x2}, $self->{y2}) = $self->{data}[3]->value;
	($self->{x3}, $self->{y3}) = $self->{data}[4]->value;
	($self->{x4}, $self->{y4}) = $self->{data}[5]->value;

	$self->{coeffs} = [
		($self->{x1} - $self->{x2}) * ($self->{x1} - $self->{x3}) * ($self->{x2} - $self->{x3}) * $self->{y4},
		($self->{x1} - $self->{x2}) * ($self->{x1} - $self->{x4}) * ($self->{x2} - $self->{x4}) * $self->{y3},
		($self->{x1} - $self->{x3}) * ($self->{x1} - $self->{x4}) * ($self->{x3} - $self->{x4}) * $self->{y2},
		($self->{x2} - $self->{x3}) * ($self->{x2} - $self->{x4}) * ($self->{x3} - $self->{x4}) * $self->{y1}
	];
	$self->{den} =
		($self->{x1} - $self->{x2}) *
		($self->{x1} - $self->{x3}) *
		($self->{x1} - $self->{x4}) *
		($self->{x2} - $self->{x3}) *
		($self->{x2} - $self->{x4}) *
		($self->{x3} - $self->{x4});

	my ($x1, $y1) = ($self->{x1}->value, $self->{y1}->value);
	my ($x2, $y2) = ($self->{x2}->value, $self->{y2}->value);
	my ($x3, $y3) = ($self->{x3}->value, $self->{y3}->value);
	my ($x4, $y4) = ($self->{x4}->value, $self->{y4}->value);

	$self->{c3} =
		($y1 / (($x1 - $x2) * ($x1 - $x3) * ($x1 - $x4)) +
			$y2 / (($x2 - $x1) * ($x2 - $x3) * ($x2 - $x4)) +
			$y3 / (($x3 - $x1) * ($x3 - $x2) * ($x3 - $x4)) +
			$y4 / (($x4 - $x1) * ($x4 - $x2) * ($x4 - $x3)));
	my $c2 =
		((-$x2 - $x3 - $x4) * $y1 / (($x1 - $x2) * ($x1 - $x3) * ($x1 - $x4)) +
			(-$x1 - $x3 - $x4) * $y2 / (($x2 - $x1) * ($x2 - $x3) * ($x2 - $x4)) +
			(-$x1 - $x2 - $x4) * $y3 / (($x3 - $x1) * ($x3 - $x2) * ($x3 - $x4)) +
			(-$x1 - $x2 - $x3) * $y4 / (($x4 - $x1) * ($x4 - $x2) * ($x4 - $x3)));

	$self->{degree} = abs($self->{c3}) < 0.000001 && abs($c2) < 0.000001 ? 1 : abs($self->{c3}) < 0.000001 ? 2 : 3;

	if ($self->{degree} == 1) {
		# Colinear points
		$self->{c3}       = 1;
		$self->{function} = sub { return ($y2 - $y1) / ($x2 - $x1) * ($_[0] - $x1) + $y1; };
	} elsif ($self->{degree} == 2) {
		# Quadratic
		my $den = ($x1 - $x2) * ($x1 - $x3) * ($x2 - $x3);
		$self->{a}  = (($x2 - $x3) * $y1 + ($x3 - $x1) * $y2 + ($x1 - $x2) * $y3) / $den;
		$self->{c3} = $self->{a};
		$self->{b}  = (($x3**2 - $x2**2) * $y1 + ($x1**2 - $x3**2) * $y2 + ($x2**2 - $x1**2) * $y3) / $den;
		$self->{c} =
			(($x2 - $x3) * $x2 * $x3 * $y1 + ($x3 - $x1) * $x1 * $x3 * $y2 + ($x1 - $x2) * $x1 * $x2 * $y3) / $den;
		$self->{function} = sub { return $self->{a} * $_[0]**2 + $self->{b} * $_[0] + $self->{c}; };
	} else {
		# Non-degenerate cubic
		$self->{function} = sub {
			return (
				($_[0] - $x2) * ($_[0] - $x3) * ($_[0] - $x4) * $y1 / (($x1 - $x2) * ($x1 - $x3) * ($x1 - $x4)) +
					($_[0] - $x1) * ($_[0] - $x3) * ($_[0] - $x4) * $y2 / (($x2 - $x1) * ($x2 - $x3) * ($x2 - $x4)) +
					($_[0] - $x1) * ($_[0] - $x2) * ($_[0] - $x4) * $y3 / (($x3 - $x1) * ($x3 - $x2) * ($x3 - $x4)) +
					($_[0] - $x1) * ($_[0] - $x2) * ($_[0] - $x3) * $y4 / (($x4 - $x1) * ($x4 - $x2) * ($x4 - $x3)));
		};
	}

	return $self;
}

sub pointCmp {
	my ($self, $point) = @_;
	my ($x,    $y)     = $point->value;
	return ($x - $self->{x2}) * ($x - $self->{x3}) * ($x - $self->{x4}) * $self->{coeffs}[3] -
		($x - $self->{x1}) * ($x - $self->{x3}) * ($x - $self->{x4}) * $self->{coeffs}[2] +
		($x - $self->{x1}) * ($x - $self->{x2}) * ($x - $self->{x4}) * $self->{coeffs}[1] -
		($x - $self->{x1}) * ($x - $self->{x2}) * ($x - $self->{x3}) * $self->{coeffs}[0] <=> $self->{den} * $y;
}

sub cmp {
	my ($self, $other, $fuzzy) = @_;
	return
		$other->{data}[0] eq 'cubic'
		&& ($fuzzy || $other->{data}[1] eq $self->{solid_dashed})
		&& $self->pointCmp($other->{data}[2]) == 0
		&& $self->pointCmp($other->{data}[3]) == 0
		&& $self->pointCmp($other->{data}[4]) == 0
		&& $self->pointCmp($other->{data}[5]) == 0;
}

sub tikzCode {
	my $self = shift;

	my $bBox = $self->context->flags->get('graphToolObject')->{bBox};

	if ($self->{degree} == 1) {
		return
			"($bBox->[0],"
			. $self->{function}->($bBox->[0])
			. ") -- ($bBox->[2],"
			. $self->{function}->($bBox->[2]) . ')';
	} elsif ($self->{degree} == 2) {
		my $h    = -$self->{b} / (2 * $self->{a});
		my $k    = $self->{c} - $self->{b}**2 / (4 * $self->{a});
		my $diff = sqrt((($self->{a} >= 0 ? $bBox->[1] : $bBox->[3]) - $k) / $self->{a});
		my $dmin = $h - $diff;
		my $dmax = $h + $diff;
		return "plot[domain = $dmin:$dmax, smooth] (\\x, {$self->{a} * (\\x)^2 + ($self->{b}) * \\x + ($self->{c})})";
	} else {
		my $height     = $bBox->[1] - $bBox->[3];
		my $lowerBound = $bBox->[3] - $height;
		my $upperBound = $bBox->[1] + $height;
		my $step       = ($bBox->[2] - $bBox->[0]) / 200;
		my $x          = $bBox->[0];

		my $coords;
		do {
			my $y = $self->{function}->($x);
			$coords .= "($x,$y) " if $y >= $lowerBound && $y <= $upperBound;
			$x += $step;
		} while ($x < $bBox->[2]);

		return "plot[smooth] coordinates { $coords }";
	}
}

sub tikz {
	my $self = shift;
	return "\\draw[thick, blue, line width = 2.5pt, $self->{solid_dashed}] " . $self->tikzCode . ";\n";
}

sub clipCode {
	my $self = shift;
	my $bBox = $self->context->flags->get('graphToolObject')->{bBox};
	return
		$self->{degree} == 1   ? $self->tikzCode . " -- ($bBox->[2], $bBox->[1]) -- ($bBox->[0], $bBox->[1]) -- cycle"
		: $self->{degree} == 2 ? $self->tikzCode
		: $self->tikzCode
		. ($self->{c3} > 0
			? ("-- ($bBox->[2], $bBox->[1]) -- ($bBox->[0], $bBox->[1])" . "-- ($bBox->[0], $bBox->[3]) -- cycle")
			: ("-- ($bBox->[2], $bBox->[3]) -- ($bBox->[0], $bBox->[3])" . "-- ($bBox->[0], $bBox->[1]) -- cycle"));
}

sub fillCmp {
	my ($self, $x, $y) = @_;
	return parser::GraphTool::sign($self->{c3} * ($y - $self->{function}->($x)));
}

package GraphTool::GraphObject::Interval;
our @ISA = qw(GraphTool::GraphObject);

sub new {
	my ($invocant, @arguments) = @_;
	my $context = Value::isContext($arguments[0]) ? shift @arguments : $invocant->context;
	my $self    = $invocant->SUPER::new($context, @arguments);

	$self->{interval} = $self->{data}[1];
	$self->{clipCode} = '';

	return $self;
}

sub pointCmp {
	my ($self, $point) = @_;
	my ($x,    $y)     = $point->value;
	return
		$x < $self->{interval}{data}[0]
		&& $x > $self->{interval}{data}[1] ? 1 : $x == $self->{interval}{data}[0]
		&& $self->{interval}{open} eq '['  ? 0 : $x == $self->{interval}{data}[1]
		&& $self->{interval}{close} eq ']' ? 0 : -1;
}

sub cmp {
	my ($self, $other, $fuzzy) = @_;
	return $other->{data}[0] eq 'interval' && $self->{interval} == $other->{data}[1];
}

sub tikz {
	my $self = shift;

	my ($start, $end) = map { $_->value } @{ $self->{interval}{data} };

	my $useBracketEnds = $self->context->flags->get('graphToolObject')->{useBracketEnds};

	my $openEnd =
		$useBracketEnds
		? '{ Parenthesis[round, width = 28pt, line width = 3pt, length = 14pt] }'
		: '{ Circle[scale = 1.1, open] }';
	my $closedEnd =
		$useBracketEnds ? '{ Bracket[width = 24pt,line width = 3pt, length = 8pt] }' : '{ Circle[scale = 1.1] }';

	my $open =
		$start eq '-infinity' ? '{ Stealth[scale = 1.1] }' : $self->{interval}{open} eq '[' ? $closedEnd : $openEnd;
	my $close =
		$end eq 'infinity' ? '{ Stealth[scale = 1.1] }' : $self->{interval}{close} eq ']' ? $closedEnd : $openEnd;

	my $bBox = $self->context->flags->get('graphToolObject')->{bBox};

	$start = $bBox->[0] if $start eq '-infinity';
	$end   = $bBox->[2] if $end eq 'infinity';

	# This centers an open/close dot or a parenthesis or bracket on the tick.
	# TikZ by default puts the end with its outer edge at the tick.
	my $shortenLeft =
		$open =~ /Circle/ ? ', shorten < = -8.25pt' : $open =~ /Parenthesis|Bracket/ ? ', shorten < = -1.5pt' : '';
	my $shortenRight =
		$close =~ /Circle/ ? ', shorten > = -8.25pt' : $open =~ /Parenthesis|Bracket/ ? ', shorten > = -1.5pt' : '';

	return "\\draw[thick, blue, line width = 4pt, $open-$close$shortenLeft$shortenRight] ($start, 0) -- ($end, 0);\n";
}

package GraphTool::GraphObject::SineWave;
our @ISA = qw(GraphTool::GraphObject);

sub new {
	my ($invocant, @arguments) = @_;
	my $context = Value::isContext($arguments[0]) ? shift @arguments : $invocant->context;
	my $self    = $invocant->SUPER::new($context, @arguments);

	$self->{solid_dashed} = $self->{data}[1];
	($self->{phase}, $self->{yshift}) = map { $_->value } $self->{data}[2]->value;
	$self->{period}    = $self->{data}[3]->value;
	$self->{amplitude} = $self->{data}[4]->value;

	$self->{sinFormula} =
		main::Formula("$self->{amplitude} sin(2 * pi / abs($self->{period}) (x - $self->{phase})) + $self->{yshift}");

	my $pi = main::pi->value;

	$self->{function} = sub {
		return $self->{amplitude} * CORE::sin(2 * $pi / $self->{period} * ($_[0] - $self->{phase})) +
			$self->{yshift};
	};

	return $self;
}

sub pointCmp {
	my ($self, $point) = @_;
	my ($x,    $y)     = $point->value;
	return $self->{sinFormula}->eval(x => $point->{data}[0])->value <=> $point->{data}[1];
}

sub cmp {
	my ($self, $other, $fuzzy) = @_;
	return 0 unless $other->{data}[0] eq 'sineWave';

	my ($phase, $yshift) = $other->{data}[2]->value;
	my $period          = $other->{data}[3]->value;
	my $amplitude       = $other->{data}[4]->value;
	my $otherSinFormula = main::Formula("$amplitude sin(2 * pi / abs($period) (x - $phase)) + $yshift");

	return ($fuzzy || $other->{data}[1] eq $self->{solid_dashed}) && $self->{sinFormula} == $otherSinFormula;
}

sub tikzCode {
	my $self = shift;

	my $bBox = $self->context->flags->get('graphToolObject')->{bBox};

	my $height     = $bBox->[1] - $bBox->[3];
	my $lowerBound = $bBox->[3] - $height;
	my $upperBound = $bBox->[1] + $height;
	my $step       = ($bBox->[2] - $bBox->[0]) / 200;
	my $x          = $bBox->[0];

	my $coords;
	do {
		my $y = $self->{function}->($x);
		$coords .= "($x,$y) " if $y >= $lowerBound && $y <= $upperBound;
		$x += $step;
	} while $x < $bBox->[2];

	return "plot[smooth] coordinates { $coords }";
}

sub tikz {
	my $self = shift;
	return "\\draw[thick, blue, line width = 2.5pt, $self->{solid_dashed}] " . $self->tikzCode . ";\n";
}

sub clipCode {
	my $self = shift;
	my $bBox = $self->context->flags->get('graphToolObject')->{bBox};
	return $self->tikzCode . "-- ($bBox->[2], $bBox->[1]) -- ($bBox->[0], $bBox->[1]) -- cycle";
}

sub fillCmp {
	my ($self, $x, $y) = @_;
	return parser::GraphTool::sign($y - $self->{function}->($x));
}

package GraphTool::GraphObject::Triangle;
our @ISA = qw(GraphTool::GraphObject);

sub new {
	my ($invocant, @arguments) = @_;
	my $context = Value::isContext($arguments[0]) ? shift @arguments : $invocant->context;
	my $self    = $invocant->SUPER::new($context, @arguments);

	$self->{solid_dashed} = $self->{data}[1];
	$self->{vertices}     = [ @{ $self->{data} }[ 2, 3, 4 ] ];

	$self->{points} = [ map { [ $_->{data}[0]->value, $_->{data}[1]->value ] } @{ $self->{vertices} } ];

	($self->{x1}, $self->{y1}) = @{ $self->{points}[0] };
	($self->{x2}, $self->{y2}) = @{ $self->{points}[1] };
	($self->{x3}, $self->{y3}) = @{ $self->{points}[2] };
	$self->{denominator} = ($self->{y2} - $self->{y3}) * ($self->{x1} - $self->{x3}) +
		($self->{x3} - $self->{x2}) * ($self->{y1} - $self->{y3});

	$self->{borderStdForms} = [];
	$self->{normalLengths}  = [];
	for (0 .. $#{ $self->{points} }) {
		my ($x1, $y1) = @{ $self->{points}[$_] };
		my ($x2, $y2) = @{ $self->{points}[ ($_ + 1) % 3 ] };
		push(@{ $self->{borderStdForms} }, [ $y1 - $y2, $x2 - $x1, $x1 * $y2 - $x2 * $y1 ]);
		push(@{ $self->{normalLengths} },  sqrt($self->{borderStdForms}[-1][0]**2 + $self->{borderStdForms}[-1][1]**2));
	}

	$self->{tikzCode} = join(' -- ', map {"($_->[0], $_->[1])"} @{ $self->{points} }) . ' -- cycle';
	$self->{clipCode} = $self->{tikzCode};

	return $self;
}

sub pointCmp {
	my ($self, $point) = @_;
	my ($x,    $y)     = $point->value;
	return $self->fillCmp($x, $y);
}

sub cmp {
	my ($self, $other, $fuzzy) = @_;
	return 0 if $other->{data}[0] ne 'triangle' || (!$fuzzy && $other->{data}[1] ne $self->{solid_dashed});

	for my $otherPoint (@{ $other->{data} }[ 2 .. 4 ]) {
		return 0 if !(grep { $_ == $otherPoint } @{ $self->{vertices} });
	}

	return 1;
}

sub tikz {
	my $self = shift;
	return "\\draw[thick, blue, line width = 2.5pt, $self->{solid_dashed}] $self->{tikzCode};\n";
}

sub fillCmp {
	my ($self, $x, $y) = @_;
	my $s =
		(($self->{y2} - $self->{y3}) * ($x - $self->{x3}) + ($self->{x3} - $self->{x2}) * ($y - $self->{y3})) /
		$self->{denominator};
	my $t =
		(($self->{y3} - $self->{y1}) * ($x - $self->{x3}) + ($self->{x1} - $self->{x3}) * ($y - $self->{y3})) /
		$self->{denominator};
	if ($s >= 0 && $t >= 0 && $s + $t <= 1) {
		return 0 if ($s == 0 || $t == 0 || $s + $t == 1);
		return 1;
	}
	return -1;
}

sub onBoundary {
	my ($self, $point, $aVal, $from) = @_;
	return 1 if $self->fillCmp(@$point) != $aVal;

	my $gt = $self->context->flags->get('graphToolObject');

	for (0 .. $#{ $self->{borderStdForms} }) {
		my @stdform = @{ $self->{borderStdForms}[$_] };
		my ($x1, $y1) = @{ $self->{points}[$_] };
		my ($x2, $y2) = @{ $self->{points}[ ($_ + 1) % 3 ] };
		return 1
			if (abs($point->[0] * $stdform[0] + $point->[1] * $stdform[1] + $stdform[2]) / $self->{normalLengths}[$_])
			< 0.5 / sqrt($gt->{unitX} * $gt->{unitY})
			&& $point->[0] > main::min($x1, $x2) - 0.5 / $gt->{unitX}
			&& $point->[0] < main::max($x1, $x2) + 0.5 / $gt->{unitX}
			&& $point->[1] > main::min($y1, $y2) - 0.5 / $gt->{unitY}
			&& $point->[1] < main::max($y1, $y2) + 0.5 / $gt->{unitY};
	}
	return 0;
}

package GraphTool::GraphObject::Quadrilateral;
our @ISA = qw(GraphTool::GraphObject);

sub new {
	my ($invocant, @arguments) = @_;
	my $context = Value::isContext($arguments[0]) ? shift @arguments : $invocant->context;
	my $self    = $invocant->SUPER::new($context, @arguments);

	$self->{solid_dashed} = $self->{data}[1];
	$self->{vertices}     = [ @{ $self->{data} }[ 2 .. 5 ] ];

	$self->{points} = [ map { [ $_->{data}[0]->value, $_->{data}[1]->value ] } @{ $self->{vertices} } ];

	($self->{borderCmps}, $self->{borderStdForms}, $self->{borderClipCode}, $self->{normalLengths}) = ([], [], [], []);
	for my $i (0 .. $#{ $self->{points} }) {
		my ($x1, $y1) = @{ $self->{points}[$i] };
		my ($x2, $y2) = @{ $self->{points}[ ($i + 1) % 4 ] };

		if ($x1 == $x2) {
			# Vertical line
			push(@{ $self->{borderCmps} }, sub { return parser::GraphTool::sign($_[0] - $x1) });

			push(
				@{ $self->{borderClipCode} },
				sub {
					my $bBox = $self->context->flags->get('graphToolObject')->{bBox};
					return
						"\\clip"
						. ($_[0] < $x1 ? '[inverse clip]' : '')
						. "($x1, $bBox->[3]) -- ($x1, $bBox->[1]) -- "
						. "($bBox->[2], $bBox->[1]) -- ($bBox->[2], $bBox->[3]) -- cycle;\n";
				}
			);
		} else {
			# Non-vertical line
			my $m   = ($y2 - $y1) / ($x2 - $x1);
			my $eqn = sub { return $m * ($_[0] - $x1) + $y1; };

			push(@{ $self->{borderCmps} }, sub { return parser::GraphTool::sign($_[1] - $eqn->($_[0])); });

			push(
				@{ $self->{borderClipCode} },
				sub {
					my $bBox = $self->context->flags->get('graphToolObject')->{bBox};
					return
						"\\clip"
						. ($_[1] < $eqn->($_[0]) ? '[inverse clip]' : '')
						. "($bBox->[0],"
						. $eqn->($bBox->[0]) . ') -- '
						. "($bBox->[2],"
						. $eqn->($bBox->[2]) . ') -- '
						. "($bBox->[2],$bBox->[1]) -- ($bBox->[0],$bBox->[1]) -- cycle;\n";
				}
			);
		}

		push(@{ $self->{borderStdForms} }, [ $y1 - $y2, $x2 - $x1, $x1 * $y2 - $x2 * $y1 ]);
		push(@{ $self->{normalLengths} },  sqrt($self->{borderStdForms}[-1][0]**2 + $self->{borderStdForms}[-1][1]**2));
	}

	$self->{isCrossed} = (
		(
			$self->{points}[0][0] * $self->{borderStdForms}[2][0] +
				$self->{points}[0][1] * $self->{borderStdForms}[2][1] +
				$self->{borderStdForms}[2][2] > 0
		) != (
			$self->{points}[1][0] * $self->{borderStdForms}[2][0] +
				$self->{points}[1][1] * $self->{borderStdForms}[2][1] +
				$self->{borderStdForms}[2][2] > 0
			)
			&& ($self->{points}[2][0] * $self->{borderStdForms}[0][0] +
				$self->{points}[2][1] * $self->{borderStdForms}[0][1] +
				$self->{borderStdForms}[0][2] > 0) != (
				$self->{points}[3][0] * $self->{borderStdForms}[0][0] +
				$self->{points}[3][1] * $self->{borderStdForms}[0][1] +
				$self->{borderStdForms}[0][2] > 0
				)
		)
		|| (
			(
				$self->{points}[0][0] * $self->{borderStdForms}[1][0] +
				$self->{points}[0][1] * $self->{borderStdForms}[1][1] +
				$self->{borderStdForms}[1][2] > 0
			) != (
				$self->{points}[3][0] * $self->{borderStdForms}[1][0] +
				$self->{points}[3][1] * $self->{borderStdForms}[1][1] +
				$self->{borderStdForms}[1][2] > 0
			)
			&& ($self->{points}[1][0] * $self->{borderStdForms}[3][0] +
				$self->{points}[1][1] * $self->{borderStdForms}[3][1] +
				$self->{borderStdForms}[3][2] > 0) != (
				$self->{points}[2][0] * $self->{borderStdForms}[3][0] +
				$self->{points}[2][1] * $self->{borderStdForms}[3][1] +
				$self->{borderStdForms}[3][2] > 0
				)
		);

	return $self;
}

sub pointCmp {
	my ($self, $point) = @_;
	my ($x,    $y)     = $point->value;
	return $self->fillCmp($x, $y);
}

sub cmp {
	my ($self, $other, $fuzzy) = @_;
	return 0
		if $other->{data}[0] ne 'quadrilateral' || (!$fuzzy && $other->{data}[1] ne $self->{solid_dashed});

	# Check for the four possible cycles that give the same quadrilateral in both directions.
	for my $i (0 .. 3) {
		my $correct = 1;
		for my $j (0 .. 3) {
			if ($self->{vertices}[ ($i + $j) % 4 ] != $other->{data}[ $j + 2 ]) {
				$correct = 0;
				last;
			}
		}
		return 1 if $correct;

		$correct = 1;
		for my $j (0 .. 3) {
			if ($self->{vertices}[ 3 - ($i + $j) % 4 ] != $other->{data}[ $j + 2 ]) {
				$correct = 0;
				last;
			}
		}
		return 1 if $correct;
	}

	return 0;
}

sub tikzCode {
	my $self = shift;
	return join(' -- ', map {"($_->[0], $_->[1])"} @{ $self->{points} }) . ' -- cycle';
}

sub tikz {
	my $self = shift;
	return "\\draw[thick, blue, line width = 2.5pt, $self->{solid_dashed}] " . $self->tikzCode . ";\n";
}

sub clip {
	my ($self, $fx, $fy) = @_;
	my $cmp = $self->fillCmp($fx, $fy);
	return                                                                  if $cmp == 0;
	return join('', map { $self->{borderClipCode}[$_]->($fx, $fy) } 0 .. 3) if $self->{isCrossed} && $cmp > 0;
	return
		'\\clip'
		. ($cmp < 0 ? '[inverse clip] ' : ' ')
		. join(' -- ', map {"($_->[0], $_->[1])"} @{ $self->{points} })
		. " -- cycle;\n";
}

sub fillCmp {
	my ($self, $x, $y) = @_;

	# Check to see if the point is on the border.
	for my $i (0 .. 3) {
		my ($x1, $y1) = @{ $self->{points}[$i] };
		my ($x2, $y2) = @{ $self->{points}[ ($i + 1) % 4 ] };
		return 0
			if ($x <= main::max($x1, $x2)
				&& $x >= main::min($x1, $x2)
				&& $y <= main::max($y1, $y2)
				&& $y >= main::min($y1, $y2)
				&& ($y - $y1) * ($x2 - $x1) - ($y2 - $y1) * ($x - $x1) == 0);
	}

	# Check to see if the point is inside.
	my $isIn = 0;
	for my $i (0 .. 3) {
		my ($x1, $y1) = @{ $self->{points}[$i] };
		my ($x2, $y2) = @{ $self->{points}[ ($i + 1) % 4 ] };
		if ($y1 > $y != $y2 > $y && $x - $x1 < (($x2 - $x1) * ($y - $y1)) / ($y2 - $y1)) {
			$isIn = !$isIn;
		}
	}
	if ($isIn) {
		return 1 if !$self->{isCrossed};

		my $result = 1;
		for my $i (0 .. 3) {
			$result |= 1 << ($i + 1) if $self->{borderCmps}[$i]->($x, $y) > 0;
		}
		return $result;
	}

	return -1;
}

sub onBoundary {
	my ($self, $point, $aVal, $from) = @_;
	return 1 if $self->fillCmp(@$point) != $aVal;
	my $gt = $self->context->flags->get('graphToolObject');
	for (0 .. $#{ $self->{borderStdForms} }) {
		my @stdform = @{ $self->{borderStdForms}[$_] };
		my ($x1, $y1) = @{ $self->{points}[$_] };
		my ($x2, $y2) = @{ $self->{points}[ ($_ + 1) % 4 ] };
		return 1
			if (
				abs($point->[0] * $stdform[0] + $point->[1] * $stdform[1] + $stdform[2]) / $self->{normalLengths}[$_] <
				0.5 / sqrt($gt->{unitX} * $gt->{unitY}))
			&& $point->[0] > main::min($x1, $x2) - 0.5 / $gt->{unitX}
			&& $point->[0] < main::max($x1, $x2) + 0.5 / $gt->{unitX}
			&& $point->[1] > main::min($y1, $y2) - 0.5 / $gt->{unitY}
			&& $point->[1] < main::max($y1, $y2) + 0.5 / $gt->{unitY};
	}
	return 0;
}

package GraphTool::GraphObject::Segment;
our @ISA = qw(GraphTool::GraphObject::Line);

sub new {
	my ($invocant, @arguments) = @_;
	my $context = Value::isContext($arguments[0]) ? shift @arguments : $invocant->context;
	my $self    = $invocant->SUPER::new($context, @arguments);

	$self->{points} = [ @{ $self->{data} }[ 2, 3 ] ];

	return $self;
}

sub cmp {
	my ($self, $other, $fuzzy) = @_;
	return
		$other->{data}[0] eq 'segment'
		&& ($fuzzy || $other->{data}[1] eq $self->{solid_dashed})
		&& (($self->{points}[0] == $other->{data}[2] && $self->{points}[1] == $other->{data}[3])
			|| ($self->{points}[1] == $other->{data}[2] && $self->{points}[0] == $other->{data}[3]));
}

sub fillCmp {
	my ($self, $x, $y) = @_;
	return $self->SUPER::fillCmp($x, $y)
		|| ($x >= main::min($self->{x1}->value, $self->{x2}->value)
			&& $x <= main::max($self->{x1}->value, $self->{x2}->value)
			&& $y >= main::min($self->{y1}->value, $self->{y2}->value)
			&& $y <= main::max($self->{y1}->value, $self->{y2}->value) ? 0 : 1);
}

sub tikzCode {
	my $self = shift;
	return "($self->{x1}, $self->{y1}) -- ($self->{x2}, $self->{y2})";
}

sub clipCode {
	my $self = shift;
	my $bBox = $self->context->flags->get('graphToolObject')->{bBox};
	if ($self->{isVertical}) {
		return
			"($self->{x1}, $bBox->[3])"
			. "-- ($self->{x1}, $bBox->[1])"
			. "-- ($bBox->[2], $bBox->[1])"
			. "-- ($bBox->[2], $bBox->[3]) -- cycle";
	} else {
		return
			"($bBox->[0],"
			. $self->{y}->($bBox->[0]) . ')'
			. "-- ($bBox->[2],"
			. $self->{y}->($bBox->[2]) . ')'
			. "-- ($bBox->[2], $bBox->[1])"
			. "-- ($bBox->[0], $bBox->[1]) -- cycle";
	}
}

sub onBoundary {
	my ($self, $point, $aVal, $from) = @_;

	my $gt = $self->context->flags->get('graphToolObject');

	return 0
		if !($point->[0] > main::min($self->{x1}->value, $self->{x2}->value) - 0.5 / $gt->{unitX}
			&& $point->[0] < main::max($self->{x1}->value, $self->{x2}->value) + 0.5 / $gt->{unitX}
			&& $point->[1] > main::min($self->{y1}->value, $self->{y2}->value) - 0.5 / $gt->{unitY}
			&& $point->[1] < main::max($self->{y1}->value, $self->{y2}->value) + 0.5 / $gt->{unitY});

	my @crossingStdForm =
		($point->[1] - $from->[1], $from->[0] - $point->[0], $point->[0] * $from->[1] - $point->[1] * $from->[0]);
	my $pointSide =
		$point->[0] * $self->{stdform}[0]->value +
		$point->[1] * $self->{stdform}[1]->value +
		$self->{stdform}[2]->value;

	return (
		(
			$from->[0] * $self->{stdform}[0]->value +
				$from->[1] * $self->{stdform}[1]->value +
				$self->{stdform}[2]->value > 0
		) != $pointSide > 0
			&& ($self->{x1}->value * $crossingStdForm[0] +
				$self->{y1}->value * $crossingStdForm[1] +
				$crossingStdForm[2] > 0) != (
				$self->{x2}->value * $crossingStdForm[0] +
				$self->{y2}->value * $crossingStdForm[1] +
				$crossingStdForm[2] > 0
				)
		)
		|| abs($pointSide) / $self->{normalLength} < 0.5 / sqrt($gt->{unitX} * $gt->{unitY});
}

package GraphTool::GraphObject::Vector;
our @ISA = qw(GraphTool::GraphObject::Segment);

sub new {
	my ($invocant, @arguments) = @_;
	my $context = Value::isContext($arguments[0]) ? shift @arguments : $invocant->context;
	my $self    = $invocant->SUPER::new($context, @arguments);

	# The comparison method for this object will only return that the other vector is correct once. If the same vector
	# is graphed again at a different location it will be considered incorrect for this answer.
	$self->{foundCorrect} = 0;

	$self->{drawAttributes} = ', ->';

	return $self;
}

sub positionalCmp {
	my ($self, $other, $fuzzy) = @_;
	return
		$other->{data}[0] eq 'vector'
		&& ($fuzzy || $other->{data}[1] eq $self->{solid_dashed})
		&& $self->{points}[0] == $other->{data}[2]
		&& $self->{points}[1] == $other->{data}[3];
}

sub cmp {
	my ($self, $other, $fuzzy) = @_;
	return $self->positionalCmp($other, $fuzzy)
		if $fuzzy || $self->context->flags->get('graphToolObject')->{vectorsArePositional};
	return 0
		unless !$self->{foundCorrect}
		&& $other->{data}[0] eq 'vector'
		&& $other->{data}[1] eq $self->{solid_dashed}
		&& ($other->{data}[3]{data}[0] - $other->{data}[2]{data}[0] ==
			$self->{points}[1]{data}[0] - $self->{points}[0]{data}[0])
		&& ($other->{data}[3]{data}[1] - $other->{data}[2]{data}[1] ==
			$self->{points}[1]{data}[1] - $self->{points}[0]{data}[1]);
	$self->{foundCorrect} = 1;
	return 1;
}

package GraphTool::GraphObject::Fill;
our @ISA = qw(GraphTool::GraphObject);

sub new {
	my ($invocant, @arguments) = @_;
	my $context = Value::isContext($arguments[0]) ? shift @arguments : $invocant->context;
	my $self    = $invocant->SUPER::new($context, @arguments);

	$self->{fillType} = 1;
	($self->{fx}, $self->{fy}) = map { $_->value } $self->{data}[1]->value;

	return $self;
}

sub pointCmp {
	my ($self, $point) = @_;

	my $gt      = $self->context->flags->get('graphToolObject');
	my $objects = ref($gt) eq 'parser::GraphTool' ? $gt->data : [];
	$objects = [ grep { !$_->{fillType} } @$objects ];

	push(@$objects, grep { !$_->{fillType} } $gt->{staticObjects}->value)
		if ref($gt) eq 'parser::GraphTool'
		&& ref($gt->{staticObjects}) eq 'parser::GraphTool';

	my ($px, $py) = map { $_->value } @{ $point->{data} };

	if ($gt->{useFloodFill}) {
		return 0 if $self->{fx} == $px && $self->{fy} == $py;

		my $result = $self->floodMap(
			$gt, $objects,
			[
				main::round(($px - $gt->{bBox}[0]) * $gt->{unitX}),
				main::round(($gt->{bBox}[1] - $py) * $gt->{unitY})
			]
		);
		return !$result if defined $result;

		# This is the case that the fill point is on a graphed object, so that there is no filled region.
		# FIXME: How should this case be graded? Really, it never should happen. It means the problem author
		# chose a fill point on another object. Probably because of carelessness with random parameters.
		for (0 .. $#$objects) {
			return 0 if $objects->[$_]->fillCmp($px, $py) == 0;
		}

		return 1;
	} else {
		for (@$objects) {
			return 1 if $_->fillCmp($self->{fx}, $self->{fy}) != $_->fillCmp($px, $py);
		}
		return 0;
	}
}

sub cmp {
	my ($self, $other) = @_;

	return $other->{data}[0] eq 'fill' && !$self->pointCmp($other->{data}[1]);
}

sub floodMap {
	my ($self, $gt, $objects, $searchPoint) = @_;

	my @aVals = (0) x @$objects;

	# If the point is on a graphed object, then don't fill.
	for (0 .. $#$objects) {
		$aVals[$_] = $objects->[$_]->fillCmp($self->{fx}, $self->{fy});
		return if $aVals[$_] == 0;
	}

	my $isBoundaryPixel = sub {
		my ($x, $y, $fromDir) = @_;
		my $curPoint = [ $gt->{bBox}[0] + $x / $gt->{unitX}, $gt->{bBox}[1] - $y / $gt->{unitY} ];
		my $from     = [ $curPoint->[0] + $fromDir->[0] / $gt->{unitX}, $curPoint->[1] + $fromDir->[1] / $gt->{unitY} ];
		for (0 .. $#$objects) {
			return 1 if $objects->[$_]->onBoundary($curPoint, $aVals[$_], $from);
		}
		return 0;
	};

	my @floodMap   = (0) x $fillResolution**2;
	my @pixelStack = ([
		main::round(($self->{fx} - $gt->{bBox}[0]) * $gt->{unitX}),
		main::round(($gt->{bBox}[1] - $self->{fy}) * $gt->{unitY})
	]);

	# Perform the flood fill algorithm.
	while (@pixelStack) {
		my ($x, $y) = @{ pop(@pixelStack) };

		# Get current pixel position.
		my $pixelPos = $y * $fillResolution + $x;

		# Go up until the boundary of the fill region or the edge of board is reached.
		while ($y >= 0 && !$isBoundaryPixel->($x, $y, [ 0, 1 ])) {
			$y        -= 1;
			$pixelPos -= $fillResolution;
		}

		$y        += 1;
		$pixelPos += $fillResolution;
		my $reachLeft  = 0;
		my $reachRight = 0;

		# Go down until the boundary of the fill region or the edge of the board is reached.
		while ($y < $fillResolution && !$isBoundaryPixel->($x, $y, [ 0, -1 ])) {
			return 1 if defined $searchPoint && $x == $searchPoint->[0] && $y == $searchPoint->[1];

			# This is a protection against infinite loops.  I have not seen this occur with this code unlike
			# the corresponding JavaScript code, but it doesn't hurt to add the protection.
			last if $floodMap[$pixelPos];

			# Fill the pixel
			$floodMap[$pixelPos] = 1;

			# While proceeding down check to the left and right to
			# see if the fill region extends in those directions.
			if ($x > 0) {
				if (!$floodMap[ $pixelPos - 1 ] && !$isBoundaryPixel->($x - 1, $y, [ 1, 0 ])) {
					if (!$reachLeft) {
						push(@pixelStack, [ $x - 1, $y ]);
						$reachLeft = 1;
					}
				} else {
					$reachLeft = 0;
				}
			}

			if ($x < $fillResolution - 1) {
				if (!$floodMap[ $pixelPos + 1 ] && !$isBoundaryPixel->($x + 1, $y, [ -1, 0 ])) {
					if (!$reachRight) {
						push(@pixelStack, [ $x + 1, $y ]);
						$reachRight = 1;
					}
				} else {
					$reachRight = 0;
				}
			}

			$y        += 1;
			$pixelPos += $fillResolution;
		}
	}

	return defined $searchPoint ? 0 : \@floodMap;
}

sub tikz {
	my ($self, $objects) = @_;

	my $gt = $self->context->flags->get('graphToolObject');

	if ($gt->{useFloodFill}) {
		my $floodMap = $self->floodMap($gt, $objects);
		return '' unless defined $floodMap;

		# Next zero out the interior of the filled region so that only the boundary is left.
		my @floodMapCopy = @$floodMap;
		for ($fillResolution + 1 .. $#$floodMap - $fillResolution - 1) {
			$floodMap->[$_] = 0
				if $floodMapCopy[$_]
				&& $_ % $fillResolution > 0
				&& $_ % $fillResolution < $fillResolution - 1
				&& ($floodMapCopy[ $_ - $fillResolution ]
					&& $floodMapCopy[ $_ - 1 ]
					&& $floodMapCopy[ $_ + 1 ]
					&& $floodMapCopy[ $_ + $fillResolution ]);
		}

		my $tikz =
			"\\begin{scope}[fillpurple, line width = 2.5pt]\n"
			. "\\clip[rounded corners = 14pt] "
			. "($gt->{bBox}[0], $gt->{bBox}[3]) rectangle ($gt->{bBox}[2], $gt->{bBox}[1]);\n";

		my $border = '';
		my $pass   = 1;

		# This converts the fill boundaries into curves. On the first pass the outer border is obtained. On
		# subsequent passes borders of inner holes are found.  The outer border curve is filled, and the inner
		# hole curves are clipped out.
		while (1) {
			my $pos = 0;
			for ($pos = 0; $pos < @$floodMap && !$floodMap->[$pos]; ++$pos) { }
			last if ($pos == @$floodMap);

			my $followPath;
			$followPath = sub {
				my $pos = shift;

				my $length = 0;
				my @coordinates;

				while (1) {
					++$length;
					my $x = $gt->{bBox}[0] + ($pos % $fillResolution) / $gt->{unitX};
					my $y = $gt->{bBox}[1] - int($pos / $fillResolution) / $gt->{unitY};
					if (@coordinates > 1
						&& ($y - $coordinates[-2][1]) * ($coordinates[-1][0] - $coordinates[-2][0]) ==
						($coordinates[-1][1] - $coordinates[-2][1]) * ($x - $coordinates[-2][0]))
					{
						$coordinates[-1] = [ $x, $y ];
					} else {
						push(@coordinates, [ $x, $y ]);
					}

					$floodMap->[$pos] = 0;

					my $haveRight = $pos % $fillResolution < $fillResolution - 1;
					my $haveLower = $pos < @$floodMap - $fillResolution;
					my $haveLeft  = $pos % $fillResolution > 0;
					my $haveUpper = $pos >= $fillResolution;

					my @neighbors;

					push(@neighbors, $pos + 1) if ($haveRight && $floodMap->[ $pos + 1 ]);
					push(@neighbors, $pos + $fillResolution + 1)
						if ($haveRight && $haveLower && $floodMap->[ $pos + $fillResolution + 1 ]);
					push(@neighbors, $pos + $fillResolution)
						if ($haveLower && $floodMap->[ $pos + $fillResolution ]);
					push(@neighbors, $pos + $fillResolution - 1)
						if ($haveLeft && $haveLower && $floodMap->[ $pos + $fillResolution - 1 ]);
					push(@neighbors, $pos - 1) if ($haveLeft && $floodMap->[ $pos - 1 ]);
					push(@neighbors, $pos - $fillResolution - 1)
						if ($haveLeft && $haveUpper && $floodMap->[ $pos - $fillResolution - 1 ]);
					push(@neighbors, $pos - $fillResolution)
						if ($haveUpper && $floodMap->[ $pos - $fillResolution ]);
					push(@neighbors, $pos - $fillResolution + 1)
						if ($haveUpper && $haveRight && $floodMap->[ $pos - $fillResolution + 1 ]);

					last unless @neighbors;

					if (@coordinates == 1 || @neighbors == 1) { $pos = $neighbors[0]; }
					else {
						my $maxLength = 0;
						my $maxPath;
						$floodMap->[$_] = 0 for @neighbors;
						for (@neighbors) {
							my ($pathLength, @path) = $followPath->($_);
							if ($pathLength > $maxLength) {
								$maxLength = $pathLength;
								$maxPath   = \@path;
							}
						}
						push(@coordinates, @$maxPath);
						last;
					}
				}

				return ($length, @coordinates);
			};

			(undef, my @coordinates) = $followPath->($pos);

			if ($pass == 1) {
				$border = "\\filldraw plot coordinates {" . join('', map {"($_->[0],$_->[1])"} @coordinates) . "};\n";
			} elsif (@coordinates > 2) {
				$tikz .= "\\clip[inverse clip] plot coordinates {"
					. join('', map {"($_->[0],$_->[1])"} @coordinates) . "};\n";
			}
			++$pass;
		}

		$tikz .= "$border\\end{scope}\n";

		return $tikz;
	} else {
		my $clip_code = '';
		for (@$objects) {
			my $objectClipCode = $_->clip($self->{fx}, $self->{fy});
			return '' unless defined $objectClipCode;
			$clip_code .= $objectClipCode;
		}
		return
			"\\begin{scope}\n\\clip[rounded corners=14pt] "
			. "($gt->{bBox}[0], $gt->{bBox}[3]) rectangle ($gt->{bBox}[2], $gt->{bBox}[1]);\n"
			. $clip_code
			. "\\fill[fillpurple] "
			. "($gt->{bBox}[0], $gt->{bBox}[3]) rectangle ($gt->{bBox}[2], $gt->{bBox}[1]);\n"
			. "\\end{scope}";
	}
}

1;
