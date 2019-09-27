################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2018 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/parserMultiAnswer.pl,v 1.11 2009/06/25 23:28:44 gage Exp $
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
graph to GraphTool().  For example:

	$gt = GraphTool("{line,solid,(0,0),(1,1)}", "{circle,dashed,(2,2),(4,2)}");

or

	$gt = GraphTool("{line,solid,(0,0),(1,1)}")->with(bBox => [-20, 20, 20, -20]);

Then, for standard PG use $gt->ans_rule() to insert the JavaScript graph into the problem (or a
print graph when a hard copy is generated), and $gt->cmp to produce the answer checker.  For
example:

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

There are four types of graph objects that the students can graph.  Lines, circles, parabolas,
and fills (or shading of a region).  The syntax for each of these objects to pass to the
GraphTool constructor is summarized as follows.  Each object must be enclosed in braces.  The
first element in the braces must be the name of the object.  The following elements in the
braces depend on the type of element.

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

For fills the name "fill" must be followed by a point in the region that is to be filled.  For
example:

	"{fill,(5,5)}"

The student answers that are returned by the JavaScript will be a list of the list objects
discussed above and will be parsed by WeBWorK and passed to the checker as such.  The default
grader is the default list_checker.  Most of the time that will not work as desired, and you
will need to provide your own list_checker.  This can either be passed as part of the cmpOptions
hash discussed below, or directly to the GraphTool object's cmp() method.

=head1 OPTIONS

There are a number of options that you can supply to control the appearance and behavior of the
JavaScript graph, listed below.  These are set as parameters to the with() method called on the
GraphTool object.

=over

=item bBox (Default: bBox => [-10, 10, 10, -10])

This is an array of four numbers that represent the bounding box of the graph.  The first
two numbers in the array are the coordinates of the top left corner of the graph, and the last
two numbers are the coordinates of the bottom right corner of the graph.

=item gridX, gridY (Default: gridX => 1, gridY => 1)

These are the distances between successive grid lines in the x and y directions, respectively.

=item ticksDistanceX, ticksDistanceY (Default: ticksDistanceX => 2, ticksDistanceY => 2)

These are the distances between successive major (labeled) ticks on the x and y axes,
respectively.

=item minorTicksX, minorTicksY (Default: minorTicksX => 1, minorTicksY => 2)

These are the number of minor (unlabeled) ticks between major ticks on the x and y axes,
respectively.

=item snapSizeX, snapSizeY (Default: snapSizeX => 1, snapSizeY => 1)

These restrict the x coordinate and y coordinate of points that can be graphed to being
multiples of the respective parameter.  These values must be greater than zero.

=item staticObjects (Default: staticObjects => [])

This is an array of fixed objects that will be displayed on the graph.  These objects will not
be able to be moved around.  The format for these objects is the same as those that are passed
to the GraphTool constructor as the correct answers.

=item graphOptions (Default: undefined)

This is an advanced option that you usually do not want to use.  It is usually constructed by
the macro internally using the above options.  If defined it should be a single string
containing three comma separated arguments, and will override all of the above options.  It will
be passed directly to the JavaScript graphTool method as its final three parameters.  The first
argument in the string is JavaScript object notation that will be passed directly to the JSX
graph board when it is initialized.  It may consist of any of the valid attributes documented
for JXG.JSXGraph.initBoard at L<https://jsxgraph.org/docs/symbols/JXG.JSXGraph.html#.initBoard>.
The second and third arguments are the snapSizeX and snapSizeY options discussed above.  For
example the following value for graphOptions will give the same result for the JavaScript graph
as the default values for the options above:

	graphOptions => "{ boundingBox: [-10, 10, 10, -10]," .
		"defaultAxes: {" .
			"x: { ticks: { ticksDistance: 2, minorTicks: 1} }," .
			"y: { ticks: { ticksDistance: 2, minorTicks: 1} }" .
		"}," .
		"grid: { gridX: 1, gridY: 1 }" .
	"}, 1, 1"

=item printGraph (Default: undefined)

If the graphOptions option is set directly, then you will also need to provide a function that
will generate the corresponding hard copy graph.  Otherwise the hard copy graph will still be
generated using the above options, and will not look the same as the java script graph.

=item cmpOptions (Default: cmpOptions => {})

This is a hash of options that will be passed to the cmp() method.  These options can also be
passed as parameters directly to the GraphTool object's cmp() method.

=item texSize (Default: texSize => 400)

This is the size of the graph that will be output when a hard copy of the problem is generated.

=back

=cut

sub _parserGraphTool_init {
	if ($main::displayMode ne 'TeX' && !$main::GraphToolHeaderSet) {
		main::TEXT(
			'<link rel="stylesheet" type="text/css" href="/webwork2_files/js/vendor/jsxgraph/jsxgraph.css">' .
			'<link rel="stylesheet" type="text/css" href="/webwork2_files/js/apps/GraphTool/graphtool.css">' .
			'<script type="text/javascript" src="/webwork2_files/js/vendor/jsxgraph/jsxgraphcore.js"></script>' .
			'<script type="text/javascript" src="/webwork2_files/js/apps/GraphTool/graphtool.min.js"></script>'
		);
		$main::GraphToolHeaderSet = 1;
	}
	main::PG_restricted_eval('sub GraphTool { GraphTool->new(@_) }');
}

loadMacros("MathObjects.pl", "PGgraphmacros.pl");

package GraphTool;
our @ISA = qw(Value::List);

sub new {
	my $self = shift; my $class = ref($self) || $self;
	my $context = Parser::Context->getCopy("Point");
	$context->parens->set('{' => {close => '}', type => 'List', formList => 1, formMatrix => 0, removable => 0});
	$context->lists->set('GraphTool' => {class =>'Parser::List::List', open => '',  close => '',  separator => ', ',
			nestedOpen => '{', nestedClose => ')'});
	$context->strings->add(
		'line' => {},
		'circle' => {},
		'parabola' => {},
		'vertical' => {},
		'horizontal' => {},
		'fill' => {},
		'solid' => {},
		'dashed' => {}
	);
	my $obj = $self->SUPER::new($context, @_);
	return bless {
		data => $obj->{data}, type => $obj->{type}, context => $context,
		staticObjects => [], cmpOptions => {},
		bBox => [-10, 10, 10, -10],
		gridX => 1, gridY => 1, snapSizeX => 1, snapSizeY => 1,
		ticksDistanceX => 2, ticksDistanceY => 2,
		minorTicksX => 1, minorTicksY => 1,
		texSize => 400
	}, $class;
}

sub ANS_NAME
{
	my $self = shift;
	$self->{name} = main::NEW_ANS_NAME() unless defined($self->{name});
	return $self->{name};
}

sub type { return "List"; }

# Convert the GraphTool object's options into JSON that can be passed to the JavaScript
# graphTool method.
sub constructJSGraphOptions
{
	my $self = shift;
	return if defined($self->{graphOptions});
	$self->{graphOptions} = <<END_OPTS;
{
	boundingBox: [${\join(",", @{$self->{bBox}})}],
	defaultAxes: {
		x: { ticks: { ticksDistance: $self->{ticksDistanceX}, minorTicks: $self->{minorTicksX}} },
		y: { ticks: { ticksDistance: $self->{ticksDistanceY}, minorTicks: $self->{minorTicksY}} }
	},
	grid: { gridX: $self->{gridX}, gridY: $self->{gridY} }
}, $self->{snapSizeX}, $self->{snapSizeY}
END_OPTS
}

# Produce a hidden answer rule to contain the JavaScript result and insert the graphbox div and
# javacript to display the graph tool.  If a hard copy is being generated, then PGgraphmacros.pl
# is used to generate a printable graph instead.  An attempt is made to make the printable graph
# look as much as possible like the JavaScript graph.
sub ans_rule {
	my $self = shift;
	my $out = main::NAMED_HIDDEN_ANS_RULE($self->ANS_NAME);

	if ($main::displayMode eq 'TeX') {
		$main::refreshCachedImages = 1;

		return &{$self->{printGraph}}
		if defined($self->{printGraph}) && ref($self->{printGraph}) eq 'CODE';

		my @size = (400, 400);

		my $graph = main::init_graph($self->{bBox}[0], $self->{bBox}[3],
			$self->{bBox}[2], $self->{bBox}[1],
			axes => [0, 0],
			grid => [
				($self->{bBox}[2] - $self->{bBox}[0]) / $self->{gridX},
				($self->{bBox}[1] - $self->{bBox}[3]) / $self->{gridY}
			],
			size => [@size]);
		$graph->lb('reset');

		# Create a separate image for the fills.  This image is enlarged so that any circle
		# whose center and point are in the visible graph image will fit entirely into the fill
		# image.  This is so that a flood fill will go all the way around the circle.
		my $fill = new WWPlot(3 * $size[0] + 2, 3 * $size[1] + 2);
		my @fillBounds = (
			$self->{bBox}[0] - ($size[0] + 1) * ($self->{bBox}[2] - $self->{bBox}[0]) / $size[0],
			$self->{bBox}[2] + ($size[0] + 1) * ($self->{bBox}[2] - $self->{bBox}[0]) / $size[0],
			$self->{bBox}[3] - ($size[1] + 1) * ($self->{bBox}[1] - $self->{bBox}[3]) / $size[1],
			$self->{bBox}[1] + ($size[1] + 1) * ($self->{bBox}[1] - $self->{bBox}[3]) / $size[1]
		);
		$fill->xmin($fillBounds[0]); $fill->xmax($fillBounds[1]);
		$fill->ymin($fillBounds[2]); $fill->ymax($fillBounds[3]);
		$fill->lb('reset');

		# Tick labels
		my $x = $self->{ticksDistanceX};
		while ($x < $self->{bBox}[2])
		{
			$graph->lb(new Label($x, -5 * ($self->{bBox}[1] - $self->{bBox}[3]) / $size[1],
					$x, 'black', 'center', 'top'));
			$x += $self->{ticksDistanceX};
		}
		$x = -$self->{ticksDistanceX};
		while ($x > $self->{bBox}[0])
		{
			$graph->lb(new Label($x, -5 * ($self->{bBox}[1] - $self->{bBox}[3]) / $size[1],
					$x, 'black', 'center', 'top'));
			$x -= $self->{ticksDistanceX};
		}
		my $y = $self->{ticksDistanceY};
		while ($y < $self->{bBox}[1])
		{
			$graph->lb(new Label(-5 * ($self->{bBox}[2] - $self->{bBox}[0]) / $size[0],
					$y, $y, 'black', 'right', 'middle'));
			$y += $self->{ticksDistanceY};
		}
		$y = -$self->{ticksDistanceY};
		while ($y > $self->{bBox}[3])
		{
			$graph->lb(new Label(-5 * ($self->{bBox}[2] - $self->{bBox}[0]) / $size[0],
					$y, $y, 'black', 'right', 'middle'));
			$y -= $self->{ticksDistanceY};
		}

		# Axes labels
		$graph->lb(new Label($self->{bBox}[2] - 4 * ($self->{bBox}[2] - $self->{bBox}[0]) / $size[0],
				4 * ($self->{bBox}[1] - $self->{bBox}[3]) / $size[1],
				'x', 'black', 'bottom', 'right'));
		$graph->lb(new Label(7 * ($self->{bBox}[2] - $self->{bBox}[0]) / $size[0],
				$self->{bBox}[1] - ($self->{bBox}[1] - $self->{bBox}[3]) / $size[1],
				'y', 'black', 'top', 'left'));

		# Graph all the lines, circles, and parabolas.  The objects are all graphed solid in the
		# fill image, so that the flood fill doesn't pass through them.
		if (@{$self->{staticObjects}}) {
			my $obj = $self->SUPER::new($self->{context}, @{$self->{staticObjects}});

			# First graph lines, parabolas, and circles.
			for (@{$obj->{data}}) {
				if ($_->{data}[0] eq 'line') {
					# Lines
					my ($p1x, $p1y) = @{$_->{data}[2]{data}};
					my ($p2x, $p2y) = @{$_->{data}[3]{data}};
					if ($p1x == $p2x) {
						# Vertical line
						$graph->moveTo($p1x, $self->{bBox}[3]);
						$graph->lineTo($p1x, $self->{bBox}[1], "blue", 2,
							$_->{data}[1] eq "dashed" ? "dashed" : 0);
						$fill->moveTo($p1x, $fillBounds[2]);
						$fill->lineTo($p1x, $fillBounds[3], "blue", 2);
					} else {
						# Non-vertical line
						my $y = sub {
							my $x = shift;
							return ($p2y - $p1y) / ($p2x - $p1x) * ($x - $p1x) + $p1y;
						};
						$graph->moveTo($self->{bBox}[0], &$y($self->{bBox}[0]));
						$graph->lineTo($self->{bBox}[2], &$y($self->{bBox}[2]), "blue", 2,
							$_->{data}[1] eq "dashed" ? "dashed" : 0);
						$fill->moveTo($fillBounds[0], &$y($fillBounds[0]));
						$fill->lineTo($fillBounds[1], &$y($fillBounds[1]), "blue", 2);
					}
				} elsif ($_->{data}[0] eq 'parabola') {
					# Parabolas
					my ($h, $k) = @{$_->{data}[3]{data}};
					my ($px, $py) = @{$_->{data}[4]{data}};
					my ($x_rule, $y_rule, $dmin, $dmax);

					if ($_->{data}[2] eq 'vertical') {
						# Vertical parabola parameters
						my $a = ($py - $k) / ($px - $h) ** 2;
						$x_rule = sub { return shift; };
						$y_rule = sub { my $x = shift; return $a * ($x - $h) ** 2 + $k; };
						$dmin = $self->{bBox}[0];
						$dmax = $self->{bBox}[2];
						$fill_dmin = $fillBounds[0];
						$fill_dmax = $fillBounds[1];

					} else {
						# Horizontal parabola parameters
						my $a = ($px - $h) / ($py - $k) ** 2;
						$x_rule = sub { my $y = shift; return $a * ($y - $k) ** 2 + $h; };
						$y_rule = sub { return shift; };
						$dmin = $self->{bBox}[3];
						$dmax = $self->{bBox}[1];
						$fill_dmin = $fillBounds[2];
						$fill_dmax = $fillBounds[3];
					}

					my $stepsize = ($dmax - $dmin) / 50;
					$graph->im->setStyle($_->{data}[1] eq "dashed"
						? (($graph->{colors}{blue}) x 16, (GD::gdTransparent) x 16)
						: $graph->{colors}{blue});
					$graph->moveTo(&$x_rule($dmin), &$y_rule($dmax));
					my $fill_stepsize = ($fill_dmax - $fill_dmin) / 50;
					$fill->moveTo(&$x_rule($fill_dmin), &$y_rule($fill_dmax));
					for my $i (0 .. 50) {
						my $t = $stepsize * $i + $dmin;
						$graph->lineTo(&$x_rule($t), &$y_rule($t), GD::gdStyled, 2);
						my $fill_t = $fill_stepsize * $i + $fill_dmin;
						$fill->lineTo(&$x_rule($fill_t), &$y_rule($fill_t), "blue", 2);
					}
				} elsif ($_->{data}[0] eq 'circle') {
					# Circles
					my ($cx, $cy) = @{$_->{data}[2]{data}};
					my ($px, $py) = @{$_->{data}[3]{data}};
					my $r = sqrt(($cx - $px) ** 2 + ($cy - $py) ** 2);
					$graph->im->setThickness(2);
					$graph->im->setStyle($_->{data}[1] eq "dashed"
						? (($graph->{colors}{blue}) x 16, (GD::gdTransparent) x 16)
						: $graph->{colors}{blue});
					$graph->im->ellipse($graph->ii($cx), $graph->jj($cy),
						$graph->ii($cx + $r) - $graph->ii($cx - $r), $graph->jj($cy + $r) - $graph->jj($cy - $r),
						GD::gdStyled);
					$graph->im->setThickness(1);
					$fill->im->ellipse($fill->ii($cx), $fill->jj($cy),
						$fill->ii($cx + $r) - $fill->ii($cx - $r), $fill->jj($cy + $r) - $fill->jj($cy - $r),
						$fill->{colors}{blue});
				}
			}

			# Now graph the fills in the fill image.
			for (@{$obj->{data}}) {
				if ($_->{data}[0] eq 'fill') {
					$fill->im->fillToBorder(
						$fill->ii($_->{data}[1]{data}[0]), $fill->jj($_->{data}[1]{data}[1]),
						$fill->{colors}{blue}, $fill->{colors}{yellow});
				}
			}
			# Finally, copy the fill data into the graph image, being careful not to overwrite
			# the graphed objects.
			for my $ii (0 .. $size[0] - 1)
			{
				for my $jj (0 .. $size[1] - 1)
				{
					my $fill_index = $fill->im->getPixel($ii + $size[0] + 1, $jj + $size[1] + 1);
					my $graph_index = $graph->im->getPixel($ii, $jj);
					$graph->im->setPixel($ii, $jj, $graph->{colors}{yellow})
					if ($fill_index == $fill->{colors}{yellow} &&
						$graph_index == $graph->{colors}{background_color});
				}
			}
		}

		# Add arrows at the end of the axes.
		$graph->moveTo(0, 0);
		$graph->arrowTo($self->{bBox}[0], 0);
		$graph->arrowTo($self->{bBox}[2], 0);
		$graph->moveTo(0, 0);
		$graph->arrowTo(0, $self->{bBox}[3]);
		$graph->arrowTo(0, $self->{bBox}[1]);

		$out = main::image(main::insertGraph($graph),
			width => $size[0], height => $size[1], tex_size => $self->{texSize});
	}
	else {
		$self->constructJSGraphOptions;
		my $ans_name = $self->ANS_NAME;
		my $prefix = ($main::setNumber =~ tr/./_/r) . "_" . $main::probNum;
		$out .= "<div id='${prefix}_${ans_name}_graphbox' class='graphtool-container'></div>" .
			"<script>graphTool('${prefix}_${ans_name}_graphbox', '${ans_name}', '" .
			join(',', @{$self->{staticObjects}}) .
			"', false, $self->{graphOptions});</script>";
	}

	return $out;
}

# Modify the student's list answer returned by the graphTool JavaScript to reproduce the
# JavaScript graph of the student's answer in the "Answer Preview" box of the results table.
# The raw list form of the answer is displayed in the "Entered" box.
sub cmp_preprocess {
	my $self = shift; my $ans = shift;
	if (defined($ans->{student_value})) {
		my $ans_name = $self->ANS_NAME;
		$self->constructJSGraphOptions;
		my $graphObjs = @{$self->{staticObjects}} ?
			join(",", @{$self->{staticObjects}}, $ans->{student_ans}) : $ans->{student_ans};
		$ans->{preview_latex_string} = "${ans_name}_student_ans_placeholder";
		$ans->{student_ans} .= <<"END_ANS";
<script>
jQuery(function() {
	var resultsTableRows = jQuery("table." + ("$main::PG->{QUIZ_PREFIX}".length ? "gwA" : "a") +
		"ttemptResults tr:not(:first-child)");
	resultsTableRows.each(function() {
			// Replace the "Preview" with the student's graph.
			var preview = jQuery(this).find("td:nth-child(2)");
			if (preview.length && preview.html().indexOf("${ans_name}_student_ans_placeholder") != -1) {
				preview.html("<div id='${ans_name}_student_ans_graphbox' class='graphtool-answer-container'></div>");
				graphTool("${ans_name}_student_ans_graphbox", "", "$graphObjs", true, $self->{graphOptions});
			}
		}
	);
});
</script>
END_ANS
	}
}

# Create an answer checker to be passed to ANS().  Any parameters are passed to the checker, as
# well as any parameters passed in via cmpOptions when the GraphTool object is created.
# The correct answer is modified to reproduce the JavaScript graph of the correct answer
# displayed in the "Correct Answer" box of the results table.
sub cmp {
	my $self = shift;
	my $cmp = $self->SUPER::cmp(%{$self->{cmpOptions}}, @_);

	if ($main::displayMode ne 'TeX') {
		my $ans_name = $self->ANS_NAME;
		$self->constructJSGraphOptions;
		my $graphObjs = @{$self->{staticObjects}} ?
			join(",", @{$self->{staticObjects}}, $cmp->{rh_ans}{correct_ans}) : $cmp->{rh_ans}{correct_ans};
		$cmp->{rh_ans}{correct_ans} = << "END_ANS";
<div id="${ans_name}_correct_ans_graphbox" class="graphtool-answer-container"></div>
<script>
jQuery(function() {
	graphTool("${ans_name}_correct_ans_graphbox", "", "$graphObjs", true, $self->{graphOptions});
});
</script>
END_ANS
	}

	return $cmp;
}

# There is no tex form of the answer.
sub TeX { }

1;
