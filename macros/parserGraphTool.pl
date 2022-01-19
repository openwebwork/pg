################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2020 The WeBWorK Project, http://openwebwork.sf.net/
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

=item JSXGraphOptions (Default: undefined)

This is an advanced option that you usually do not want to use.  It is usually constructed by
the macro internally using the above options.  If defined it should be a single string that is
formatted in javascript object notation, and will override all of the above options.  It will be
passed to the JavaScript graphTool method which will pass it on to the JSX graph board when it
is initialized.  It may consist of any of the valid attributes documented for
JXG.JSXGraph.initBoard at L<https://jsxgraph.org/docs/symbols/JXG.JSXGraph.html#.initBoard>.
For example the following value for JSXGraphOptions will give the same result for the JavaScript
graph as the default values for the options above:

	JSXGraphOptions => "{ boundingBox: [-10, 10, 10, -10]," .
		"defaultAxes: {" .
			"x: { ticks: { ticksDistance: 2, minorTicks: 1} }," .
			"y: { ticks: { ticksDistance: 2, minorTicks: 1} }" .
		"}," .
		"grid: { gridX: 1, gridY: 1 }" .
	"}"

=item snapSizeX, snapSizeY (Default: snapSizeX => 1, snapSizeY => 1)

These restrict the x coordinate and y coordinate of points that can be graphed to being
multiples of the respective parameter.  These values must be greater than zero.

=item availableTools (Default: availableTools => [ "LineTool", "CircleTool",
	"VerticalParabolaTool", "HorizontalParabolaTool", "FillTool", "SolidDashTool" ])

This is an array of tools that will be made available for students to use in the graph tool.
The order the tools are listed here will also be the order the tools are presented in the graph
tool button box.  All of the tools that may be included are listed in the default options above.
Note that the case of the tool names must match what is shown.

=item staticObjects (Default: staticObjects => [])

This is an array of fixed objects that will be displayed on the graph.  These objects will not
be able to be moved around.  The format for these objects is the same as those that are passed
to the GraphTool constructor as the correct answers.

=item printGraph (Default: undefined)

If the JSXGraphOptions option is set directly, then you will also need to provide a function that
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
	ADD_CSS_FILE("js/vendor/jsxgraph/jsxgraph.css");
	ADD_CSS_FILE("js/apps/GraphTool/graphtool.css");
	ADD_JS_FILE("js/vendor/jsxgraph/jsxgraphcore.js", 0, { defer => undef });
	ADD_JS_FILE("js/apps/GraphTool/graphtool.min.js", 0, { defer => undef });

	main::PG_restricted_eval('sub GraphTool { parser::GraphTool->new(@_) }');
}

loadMacros("MathObjects.pl", "PGtikz.pl");

package parser::GraphTool;
our @ISA = qw(Value::List);

our %contextStrings = (
	line => {},
	circle => {},
	parabola => {},
	vertical => {},
	horizontal => {},
	fill => {},
	solid => {},
	dashed => {}
);

sub new {
	my $self = shift; my $class = ref($self) || $self;
	my $context = Parser::Context->getCopy("Point");
	$context->parens->set('{' => {close => '}', type => 'List', formList => 1, formMatrix => 0, removable => 0});
	$context->lists->set('GraphTool' => {class =>'Parser::List::List', open => '',  close => '',  separator => ', ',
			nestedOpen => '{', nestedClose => ')'});
	$context->strings->add(%contextStrings);
	my $obj = $self->SUPER::new($context, @_);
	return bless {
		data => $obj->{data}, type => $obj->{type}, context => $context,
		staticObjects => [], cmpOptions => {},
		bBox => [-10, 10, 10, -10],
		gridX => 1, gridY => 1, snapSizeX => 1, snapSizeY => 1,
		ticksDistanceX => 2, ticksDistanceY => 2,
		minorTicksX => 1, minorTicksY => 1,
		availableTools => [
			"LineTool",
			"CircleTool",
			"VerticalParabolaTool",
			"HorizontalParabolaTool",
			"FillTool",
			"SolidDashTool"
		],
		texSize => 400
	}, $class;
}

our %graphObjectTikz = (
	line => {
		code => sub {
			my $self = shift;

			my ($p1x, $p1y) = @{$_->{data}[2]{data}};
			my ($p2x, $p2y) = @{$_->{data}[3]{data}};

			if ($p1x == $p2x) {
				# Vertical line
				my $line = "($p1x,$self->{bBox}[3]) -- ($p1x,$self->{bBox}[1])";
				return ("\\draw[thick,blue,line width=2.5pt,$_->{data}[1]] $line;\n", [
						$line . "-- ($self->{bBox}[2],$self->{bBox}[1]) -- ($self->{bBox}[2],$self->{bBox}[3]) -- cycle",
						sub { return $_[0] - $p1x; }
					]);
			} else {
				# Non-vertical line
				my $m = ($p2y - $p1y) / ($p2x - $p1x);
				my $y = sub { return $m * ($_[0] - $p1x) + $p1y; };
				my $line = "($self->{bBox}[0]," . &$y($self->{bBox}[0]) . ") -- " .
				"($self->{bBox}[2]," . &$y($self->{bBox}[2]) . ")";
				return ("\\draw[thick,blue,line width=2.5pt,$_->{data}[1]] $line;\n", [
						$line .  "-- ($self->{bBox}[2],$self->{bBox}[1]) -- ($self->{bBox}[0],$self->{bBox}[1]) -- cycle",
						sub { return $_[1] - &$y($_[0]); }
					]);
			}
		}
	},
	circle => {
		code => sub {
			my $self = shift;
			my ($cx, $cy) = @{$_->{data}[2]{data}};
			my ($px, $py) = @{$_->{data}[3]{data}};
			my $r = sqrt(($cx - $px) ** 2 + ($cy - $py) ** 2);
			my $circle = "($cx, $cy) circle[radius=$r]";
			return ("\\draw[thick,blue,line width=2.5pt,$_->{data}[1]] $circle;\n",
				[ $circle, sub { return $r - sqrt(($cx - $_[0]) ** 2 + ($cy - $_[1]) ** 2); } ]);
		}
	},
	parabola => {
		code => sub {
			my $self = shift;
			my ($h, $k) = @{$_->{data}[3]{data}};
			my ($px, $py) = @{$_->{data}[4]{data}};

			if ($_->{data}[2] eq 'vertical') {
				# Vertical parabola
				my $a = ($py - $k) / ($px - $h) ** 2;
				my $diff = sqrt((($a >= 0 ? $self->{bBox}[1] : $self->{bBox}[3]) - $k) / $a);
				my $dmin = $h - $diff;
				my $dmax = $h + $diff;
				my $parabola = "plot[domain=$dmin:$dmax,smooth](\\x,{$a*(\\x-($h))^2+($k)})";
				return ("\\draw[thick,blue,line width=2.5pt,$_->{data}[1]] $parabola;\n",
					[ $parabola, sub { return $a * ($_[1] - $a * ($_[0] - $h) ** 2 - $k); } ]);
			} else {
				# Horizontal parabola
				my $a = ($px - $h) / ($py - $k) ** 2;
				my $diff = sqrt((($a >= 0 ? $self->{bBox}[2] : $self->{bBox}[0]) - $h) / $a);
				my $dmin = $k - $diff;
				my $dmax = $k + $diff;
				my $parabola = "plot[domain=$dmin:$dmax,smooth]({$a*(\\x-($k))^2+($h)},\\x)";
				return ("\\draw[thick,blue,line width=2.5pt,$_->{data}[1]] $parabola;\n",
					[ $parabola, sub { return $a * ($_[0] - $a * ($_[1] - $k) ** 2 - $h); } ]);
			}
		}
	},
	fill => {
		code => sub {
			my ($self, $fill, $obj_data) = @_;
			my ($fx, $fy) = @{$fill->{data}[1]{data}};
			my $clip_code = "";
			for (@$obj_data) {
				my $clip_dir = &{$_->[1]}($fx, $fy);
				return "" if $clip_dir == 0;
				$clip_code .= "\\clip " . ($clip_dir < 0 ? "[inverse clip]" : "") . $_->[0] . ";\n";
			}
			return "\\begin{scope}\n\\clip[rounded corners=14pt] " .
			"($self->{bBox}[0],$self->{bBox}[3]) rectangle ($self->{bBox}[2],$self->{bBox}[1]);\n" .
			$clip_code .
			"\\fill[yellow!40] ($self->{bBox}[0],$self->{bBox}[3]) rectangle ($self->{bBox}[2],$self->{bBox}[1]);\n" .
			"\\end{scope}";
		},
		fillType => 1
	}
);

our $customGraphObjects = "";
our $customTools = "";

sub addGraphObjects {
	my $self = shift;
	my %objects = @_;
	$customGraphObjects .= join(",", map { "$_: $objects{$_}{js}" } keys %objects) . ",";

	# Add the object's name and any other custom strings to the context strings, and add the
	# code for generating the object in print to the %graphObjectTikz hash.
	for (keys %objects) {
		$contextStrings{$_} = {};
		$contextStrings{$_} = {} for (@{$objects{$_}{strings}});
		$graphObjectTikz{$_} = $objects{$_}{tikz} if defined $objects{$_}{tikz};
	}
}

sub addTools {
	my $self = shift;
	my %tools = @_;
	$customTools .= join(",", map { "$_: $tools{$_}" } keys %tools) . ",";
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
sub constructJSXGraphOptions
{
	my $self = shift;
	return if defined($self->{JSXGraphOptions});
	$self->{JSXGraphOptions} = JSON->new->encode({
			boundingBox => $self->{bBox},
			defaultAxes => {
				x => { ticks => { ticksDistance => $self->{ticksDistanceX}, minorTicks => $self->{minorTicksX}} },
				y => { ticks => { ticksDistance => $self->{ticksDistanceY}, minorTicks => $self->{minorTicksY}} }
			},
			grid => { gridX => $self->{gridX}, gridY => $self->{gridY} }
		});
}

# Produce a hidden answer rule to contain the JavaScript result and insert the graphbox div and
# javacript to display the graph tool.  If a hard copy is being generated, then PGgraphmacros.pl
# is used to generate a printable graph instead.  An attempt is made to make the printable graph
# look as much as possible like the JavaScript graph.
sub ans_rule {
	my $self = shift;
	my $out = main::NAMED_HIDDEN_ANS_RULE($self->ANS_NAME);

	if ($main::displayMode eq 'TeX') {
		return &{$self->{printGraph}}
		if defined($self->{printGraph}) && ref($self->{printGraph}) eq 'CODE';

		my @size = (500, 500);

		my $graph = main::createTikZImage();
		$graph->tikzLibraries("arrows.meta");
		$graph->tikzOptions("x=" . ($size[0] / 96 / ($self->{bBox}[2] - $self->{bBox}[0])) . "in," .
			"y=" . ($size[1] / 96 / ($self->{bBox}[1] - $self->{bBox}[3])) . "in");

		my $tikz = <<END_TIKZ;
\n\\tikzset{
	>={Stealth[scale=1.8]},
	clip even odd rule/.code={\\pgfseteorule},
	inverse clip/.style={ clip,insert path=[clip even odd rule]{
		($self->{bBox}[0],$self->{bBox}[3]) rectangle ($self->{bBox}[2],$self->{bBox}[1]) }
	}
}
\\definecolor{borderblue}{HTML}{356AA0}
\\pgfdeclarelayer{background}
\\pgfdeclarelayer{foreground}
\\pgfsetlayers{background,main,foreground}
\\begin{pgfonlayer}{background}
	\\fill[white,rounded corners=14pt]
	($self->{bBox}[0],$self->{bBox}[3]) rectangle ($self->{bBox}[2],$self->{bBox}[1]);
\\end{pgfonlayer}
END_TIKZ

		# Vertical grid lines
		my @xGridLines = grep { $_ < $self->{bBox}[2] } map { $_ * $self->{gridX} }
			(1 .. $self->{bBox}[2] / $self->{gridX});
		push(@xGridLines, grep { $_ > $self->{bBox}[0] } map { -$_ * $self->{gridX} }
			(1 .. -$self->{bBox}[0] / $self->{gridX}));
		$tikz .= "\\foreach \\x in {" . join(",", @xGridLines) .
			"}{\\draw[line width=0.2pt,color=lightgray] (\\x,$self->{bBox}[3]) -- (\\x,$self->{bBox}[1]);}\n"
		if (@xGridLines);

		# Horizontal grid lines
		my @yGridLines = grep { $_ < $self->{bBox}[1] } map { $_ * $self->{gridY} }
			(1 .. $self->{bBox}[1] / $self->{gridY});
		push(@yGridLines, grep { $_ > $self->{bBox}[3] } map { -$_ * $self->{gridY} }
			(1 .. -$self->{bBox}[3] / $self->{gridY}));
		$tikz .= "\\foreach \\y in {" . join(",", @yGridLines) .
			"}{\\draw[line width=0.2pt,color=lightgray] ($self->{bBox}[0],\\y) -- ($self->{bBox}[2],\\y);}\n"
		if (@yGridLines);

		# Axis and labels.
		$tikz .= <<END_TIKZ;
\\huge
\\draw[<->,thick] ($self->{bBox}[0],0) -- ($self->{bBox}[2],0) node[above left,outer sep=2pt]{\$x\$};
\\draw[<->,thick] (0,$self->{bBox}[3]) -- (0,$self->{bBox}[1]) node[below right,outer sep=2pt]{\$y\$};
END_TIKZ

		# Horizontal axis ticks and labels
		my @xTicks = grep { $_ < $self->{bBox}[2] } map { $_ * $self->{ticksDistanceX} }
			(1 .. $self->{bBox}[2] / $self->{ticksDistanceX});
		push(@xTicks, grep { $_ > $self->{bBox}[0] } map { -$_ * $self->{ticksDistanceX} }
			(1 .. -$self->{bBox}[0] / $self->{ticksDistanceX}));
		$tikz .= "\\foreach \\x in {" . join(",", @xTicks) .
			"}{\\draw[thin] (\\x,5pt) -- (\\x,-5pt) node[below]{\$\\x\$};}\n"
		if (@xTicks);

		# Vertical axis ticks and labels
		my @yTicks = grep { $_ < $self->{bBox}[1] } map { $_ * $self->{ticksDistanceY} }
			(1 .. $self->{bBox}[1] / $self->{ticksDistanceY});
		push(@yTicks, grep { $_ > $self->{bBox}[3] } map { -$_ * $self->{ticksDistanceY} }
			(1 .. -$self->{bBox}[3] / $self->{ticksDistanceY}));
		$tikz .= "\\foreach \\y in {" . join(",", @yTicks) .
			"}{\\draw[thin] (5pt,\\y) -- (-5pt,\\y) node[left]{\$\\y\$};}\n"
		if (@yTicks);

		# Border box
		$tikz .= "\\draw[borderblue,rounded corners=14pt,thick] " .
			"($self->{bBox}[0],$self->{bBox}[3]) rectangle ($self->{bBox}[2],$self->{bBox}[1]);\n";


		# Graph the lines, circles, and parabolas.
		if (@{$self->{staticObjects}}) {
			my $obj = $self->SUPER::new($self->{context}, @{$self->{staticObjects}});

			# Switch to the foreground layer and clipping box for the objects.
			$tikz .= "\\begin{pgfonlayer}{foreground}\n";
			$tikz .= "\\clip[rounded corners=14pt] " .
				"($self->{bBox}[0],$self->{bBox}[3]) rectangle ($self->{bBox}[2],$self->{bBox}[1]);\n";

			my @obj_data;

			# First graph lines, parabolas, and circles.  Cache the clipping path and a function
			# for determining which side of the object to shade for filling later.
			for (@{$obj->{data}}) {
				next unless (ref($graphObjectTikz{$_->{data}[0]}) eq 'HASH' &&
					ref($graphObjectTikz{$_->{data}[0]}{code}) eq 'CODE' &&
					!$graphObjectTikz{$_->{data}[0]}{fillType});
				my ($object_tikz, $object_data) = $graphObjectTikz{$_->{data}[0]}{code}->($self, $_);
				$tikz .= $object_tikz;
				push(@obj_data, $object_data);
			}

			# Switch from the foreground layer to the background layer for the fills.
			$tikz .= "\\end{pgfonlayer}\n\\begin{pgfonlayer}{background}\n";

			# Now shade the fill regions.
			for (@{$obj->{data}}) {
				next unless (ref($graphObjectTikz{$_->{data}[0]}) eq 'HASH' &&
					ref($graphObjectTikz{$_->{data}[0]}{code}) eq 'CODE' &&
					$graphObjectTikz{$_->{data}[0]}{fillType});
				$tikz .= $graphObjectTikz{fill}{code}->($self, $_, [@obj_data], $obj);
			}

			# End the background layer.
			$tikz .= "\\end{pgfonlayer}";
		}

		$graph->tex($tikz);

		$out = main::image(main::insertGraph($graph),
			width => $size[0], height => $size[1], tex_size => $self->{texSize});
	} elsif ($main::displayMode ne 'PTX') {
		$self->constructJSXGraphOptions;
		my $ans_name = $self->ANS_NAME;
		$out .= <<END_SCRIPT
<div id='${ans_name}_graphbox' class='graphtool-container'></div>
<script>
(() => {
	const initialize = () => {
		graphTool('${ans_name}_graphbox', {
			htmlInputId: '${ans_name}',
			staticObjects: '${\(join(',', @{$self->{staticObjects}}))}',
			snapSizeX: $self->{snapSizeX},
			snapSizeY: $self->{snapSizeY},
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

	return $out;
}

# Modify the student's list answer returned by the graphTool JavaScript to reproduce the
# JavaScript graph of the student's answer in the "Answer Preview" box of the results table.
# The raw list form of the answer is displayed in the "Entered" box.
sub cmp_preprocess {
	my $self = shift; my $ans = shift;
	if (defined($ans->{student_value})) {
		my $ans_name = $self->ANS_NAME;
		$self->constructJSXGraphOptions;
		my $graphObjs = @{$self->{staticObjects}} ?
			join(",", @{$self->{staticObjects}}, $ans->{student_ans}) : $ans->{student_ans};

		$ans->{preview_latex_string} = <<"END_ANS";
<div id='${ans_name}_student_ans_graphbox' class='graphtool-answer-container'></div>
<script>
(() => {
	const initialize = () => {
		graphTool("${ans_name}_student_ans_graphbox", {
			staticObjects: "$graphObjs",
			isStatic: true,
			snapSizeX: $self->{snapSizeX},
			snapSizeY: $self->{snapSizeY},
			customGraphObjects: {$customGraphObjects},
			JSXGraphOptions: $self->{JSXGraphOptions}
		});
	};
	if (document.readyState === 'loading') window.addEventListener('DOMContentLoaded', initialize);
	else initialize();
})();
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
	my $cmp = $self->SUPER::cmp(non_tex_preview => 1, %{$self->{cmpOptions}}, @_);

	if ($main::displayMode ne 'TeX' && $main::displayMode ne 'PTX') {
		my $ans_name = $self->ANS_NAME;
		$self->constructJSXGraphOptions;
		my $graphObjs = @{$self->{staticObjects}} ?
			join(",", @{$self->{staticObjects}}, $cmp->{rh_ans}{correct_ans}) : $cmp->{rh_ans}{correct_ans};

		$cmp->{rh_ans}{correct_ans_latex_string} = << "END_ANS";
<div id='${ans_name}_correct_ans_graphbox' class='graphtool-answer-container'></div>
<script>
(() => {
	const initialize = () => {
		graphTool("${ans_name}_correct_ans_graphbox", {
			staticObjects: "$graphObjs",
			isStatic: true,
			snapSizeX: $self->{snapSizeX},
			snapSizeY: $self->{snapSizeY},
			customGraphObjects: {$customGraphObjects},
			JSXGraphOptions: $self->{JSXGraphOptions}
		});
	};
	if (document.readyState === 'loading') window.addEventListener('DOMContentLoaded', initialize);
	else initialize();
})();
</script>
END_ANS
	}

	return $cmp;
}

1;
