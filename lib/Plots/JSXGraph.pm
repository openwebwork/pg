
=head1 DESCRIPTION

This is the code that takes a C<Plots::Plot> and creates a JSXGraph graph of the plot.

See L<plots.pl> for more details.

=cut

package Plots::JSXGraph;

use strict;
use warnings;

sub new {
	my ($class, $plots) = @_;

	$plots->add_css_file('node_modules/jsxgraph/distrib/jsxgraph.css');
	$plots->add_css_file('js/Plots/plots.css');
	$plots->add_js_file('node_modules/jsxgraph/distrib/jsxgraphcore.js');

	return bless { plots => $plots }, $class;
}

sub plots {
	my $self = shift;
	return $self->{plots};
}

sub HTML {
	my $self = shift;
	my $name = $self->{name};
	my ($width, $height) = $self->plots->size;

	return <<END_HTML;
<div id="board_$name" class="jxgbox plots-jsxgraph" style="width: ${width}px; height: ${height}px;"></div>
<script>
(() => {
	const draw_board_$name = () => {
$self->{JS}
$self->{JSend}
	}
	if (document.readyState === 'loading') window.addEventListener('DOMContentLoaded', draw_board_$name);
	else draw_board_$name();
})();
</script>
END_HTML
}

sub get_color {
	my ($self, $color) = @_;
	return sprintf("#%02x%02x%02x", @{ $self->plots->colors($color) });
}

sub add_curve {
	my ($self, $data) = @_;
	my $linestyle = $data->style('linestyle') || '';
	return if $linestyle eq 'none';

	my %linestyles;
	if ($linestyle eq 'densely dashed') {
		$linestyles{dash}      = 4;
		$linestyles{dashScale} = 1;
	} elsif ($linestyle eq 'loosely dashed') {
		$linestyles{dash}      = 3;
		$linestyles{dashScale} = 1;
	} elsif ($linestyle =~ /dashed/) {
		$linestyles{dash}      = 1;
		$linestyles{dashScale} = 1;
	} elsif ($linestyle =~ /dotted/) {
		$linestyles{dash} = 1;
	}

	my $start        = $data->style('start_mark') || '';
	my $end          = $data->style('end_mark')   || '';
	my $name         = $self->{name};
	my $curve_name   = $data->style('name');
	my $color        = $self->get_color($data->style('color') || 'default_color');
	my $line_width   = $data->style('width') || 2;
	my $arrow_size   = $line_width < 3 ? 12 / $line_width : 6;
	my $fill         = $data->style('fill') || 'none';
	my $fill_color   = $self->get_color($data->style('fill_color') || 'default_color');
	my $fill_opacity = $data->style('fill_opacity') || 0.5;
	my $plotOptions  = Mojo::JSON::encode_json({
		highlight   => 0,
		strokeColor => $color,
		strokeWidth => $line_width,
		$start eq 'arrow' ? (firstArrow => { type => 5, size => $arrow_size })        : (),
		$end eq 'arrow'   ? (lastArrow  => { type => 5, size => $arrow_size })        : (),
		$fill eq 'self'   ? (fillColor  => $fill_color, fillOpacity => $fill_opacity) : (),
		%linestyles,
	});
	$plotOptions = "JXG.merge($plotOptions, " . Mojo::JSON::encode_json($data->style('jsx_options')) . ')'
		if $data->style('jsx_options');

	my $type = 'curve';
	my $data_points;
	if ($data->name eq 'function') {
		my $f = $data->{function};
		if (ref($f->{Fx}) ne 'CODE' && $f->{xvar} eq $f->{Fx}->string) {
			my $function = $data->function_string('y', 'js', 1);
			if ($function ne '') {
				my $min = $data->style('continue') || $data->style('continue_left')  ? '' : $f->{xmin};
				my $max = $data->style('continue') || $data->style('continue_right') ? '' : $f->{xmax};
				$data->update_min_max;
				$type        = 'functiongraph';
				$data_points = "[t => $function, $min, $max]";
			}
		} else {
			my $xfunction = $data->function_string('x', 'js', 1);
			my $yfunction = $data->function_string('y', 'js', 1);
			if ($xfunction ne '' && $yfunction ne '') {
				$data->update_min_max;
				$data_points = "[t => $xfunction, t => $yfunction, $f->{xmin}, $f->{xmax}]";
			}
		}
	}
	unless ($data_points) {
		$data->gen_data;
		$data_points = '[[' . join(',', $data->x) . '],[' . join(',', $data->y) . ']]';
	}

	$self->{JS} .= "\n\t\t";
	if ($curve_name) {
		$self->{JS} .= "const curve_${curve_name}_$name = ";
	}
	$self->{JS} .= "board_$name.create('$type', $data_points, $plotOptions);";
	$self->add_point($data, $data->get_start_point, $line_width, $start, $color) if $start =~ /circle/;
	$self->add_point($data, $data->get_end_point,   $line_width, $end,   $color) if $end   =~ /circle/;
	if ($curve_name && $fill ne 'none' && $fill ne 'self') {
		my $fill_min    = $data->str_to_real($data->style('fill_min'));
		my $fill_max    = $data->str_to_real($data->style('fill_max'));
		my $fillOptions = Mojo::JSON::encode_json({
			strokeColor => $color,
			strokeWidth => 0,
			fillColor   => $fill_color,
			fillOpacity => $fill_opacity,
			highlight   => 0,
		});

		if ($fill eq 'xaxis') {
			$self->{JSend} .=
				"\n\t\tconst fill_${curve_name}_$name = board_$name.create('curve', [[], []], $fillOptions);\n"
				. "\t\tfill_${curve_name}_$name.updateDataArray = function () {\n"
				. "\t\t\tconst points = curve_${curve_name}_$name.points";
			if (defined $fill_min && defined $fill_max) {
				$self->{JSend} .=
					".filter(p => {\n"
					. "\t\t\t\treturn p.usrCoords[1] >= $fill_min && p.usrCoords[1] <= $fill_max ? true : false\n"
					. "\t\t\t})";
			}
			$self->{JSend} .=
				";\n\t\t\tthis.dataX = points.map( p => p.usrCoords[1] );\n"
				. "\t\t\tthis.dataY = points.map( p => p.usrCoords[2] );\n"
				. "\t\t\tthis.dataX.push(points[points.length - 1].usrCoords[1], "
				. "points[0].usrCoords[1], points[0].usrCoords[1]);\n"
				. "\t\t\tthis.dataY.push(0, 0, points[0].usrCoords[2]);\n"
				. "\t\t};\n"
				. "\t\tboard_$name.update();";
		} else {
			$self->{JSend} .=
				"\n\t\tconst fill_${curve_name}_$name = board_$name.create('curve', [[], []], $fillOptions);\n"
				. "\t\tfill_${curve_name}_$name.updateDataArray = function () {\n"
				. "\t\t\tconst points1 = curve_${curve_name}_$name.points";
			if (defined $fill_min && defined $fill_max) {
				$self->{JSend} .=
					".filter(p => {\n"
					. "\t\t\t\treturn p.usrCoords[1] >= $fill_min && p.usrCoords[1] <= $fill_max ? true : false\n"
					. "\t\t\t})";
			}
			$self->{JSend} .= ";\n\t\t\tconst points2 = curve_${fill}_$name.points";
			if (defined $fill_min && defined $fill_max) {
				$self->{JSend} .=
					".filter(p => {\n"
					. "\t\t\t\treturn p.usrCoords[1] >= $fill_min && p.usrCoords[1] <= $fill_max ? true : false\n"
					. "\t\t\t})";
			}
			$self->{JSend} .=
				";\n\t\t\tthis.dataX = points1.map( p => p.usrCoords[1] ).concat("
				. "points2.map( p => p.usrCoords[1] ).reverse());\n"
				. "\t\t\tthis.dataY = points1.map( p => p.usrCoords[2] ).concat("
				. "points2.map( p => p.usrCoords[2] ).reverse());\n"
				. "\t\t\tthis.dataX.push(points1[0].usrCoords[1]);\n"
				. "\t\t\tthis.dataY.push(points1[0].usrCoords[2]);\n"
				. "\t\t};\n"
				. "\t\tboard_$name.update();";
		}
	}
}

sub add_point {
	my ($self, $data, $x, $y, $size, $mark, $color) = @_;
	my $fill = $color;
	my $name = $self->{name};

	if ($mark eq 'circle' || $mark eq 'closed_circle') {
		$mark = 'o';
	} elsif ($mark eq 'open_circle') {
		$mark = 'o';
		$fill = '#ffffff';
	} elsif ($mark eq 'square') {
		$mark = '[]';
	} elsif ($mark eq 'open_square') {
		$mark = '[]';
		$fill = '#ffffff';
	} elsif ($mark eq 'plus') {
		$mark = '+';
	} elsif ($mark eq 'times') {
		$mark = 'x';
	} elsif ($mark eq 'bar') {
		$mark = '|';
	} elsif ($mark eq 'dash') {
		$mark = '-';
	} elsif ($mark eq 'triangle') {
		$mark = '^';
	} elsif ($mark eq 'open_triangle') {
		$mark = '^';
		$fill = '#ffffff';
	} elsif ($mark eq 'diamond') {
		$mark = '<>';
	} elsif ($mark eq 'open_diamond') {
		$mark = '<>';
		$fill = '#ffffff';
	} else {
		return;
	}

	my $pointOptions = Mojo::JSON::encode_json({
		fixed       => 1,
		withLabel   => 0,
		face        => $mark,
		strokeColor => $color,
		fillColor   => $fill,
		size        => $size,
		highlight   => 0,
		showInfoBox => 0,
	});
	$pointOptions = "JXG.merge($pointOptions, " . Mojo::JSON::encode_json($data->style('jsx_options')) . ')'
		if $data->style('jsx_options');

	$self->{JS} .= "\n\t\tboard_$name.create('point', [$x, $y], $pointOptions);";
}

sub add_points {
	my ($self, $data) = @_;
	my $mark = $data->style('marks');
	return if !$mark || $mark eq 'none';

	my $size  = $data->style('mark_size') || $data->style('width') || 3;
	my $color = $self->get_color($data->style('color') || 'default_color');

	for (0 .. $data->size - 1) {
		$self->add_point($data, $data->x($_), $data->y($_), $size, $mark, $color);
	}
}

sub init_graph {
	my $self             = shift;
	my $plots            = $self->plots;
	my $axes             = $plots->axes;
	my $name             = $self->{name};
	my $xaxis_loc        = $axes->xaxis('location');
	my $yaxis_loc        = $axes->yaxis('location');
	my $xaxis_pos        = $axes->xaxis('position');
	my $yaxis_pos        = $axes->yaxis('position');
	my $show_grid        = $axes->style('show_grid');
	my $allow_navigation = $axes->style('jsx_navigation') ? 1 : 0;
	my ($xmin, $ymin, $xmax, $ymax) = $axes->bounds;

	# Adjust bounding box to add padding for axes at edge of graph.
	$xaxis_loc = 'bottom' if $xaxis_loc eq 'box';
	$yaxis_loc = 'left'   if $yaxis_loc eq 'box';
	$xmin -= 0.11 * ($xmax - $xmin) if $yaxis_loc eq 'left'   || $xmin == $yaxis_pos;
	$xmax += 0.11 * ($xmax - $xmin) if $yaxis_loc eq 'right'  || $xmax == $yaxis_pos;
	$ymin -= 0.11 * ($ymax - $ymin) if $xaxis_loc eq 'bottom' || $ymin == $xaxis_pos;
	$ymax += 0.11 * ($ymax - $ymin) if $xaxis_loc eq 'top'    || $ymax == $xaxis_pos;

	my $JSXOptions = Mojo::JSON::encode_json({
		title          => $axes->style('title') || 'Graph',
		description    => $plots->{ariaDescription},
		boundingBox    => [ $xmin, $ymax, $xmax, $ymin ],
		axis           => 0,
		showNavigation => $allow_navigation,
		pan            => { enabled => $allow_navigation },
		zoom           => { enabled => $allow_navigation },
		showCopyright  => 0,
	});
	$JSXOptions = "JXG.merge($JSXOptions, " . Mojo::JSON::encode_json($axes->style('jsx_options')) . ')'
		if $axes->style('jsx_options');
	my $XAxisOptions = Mojo::JSON::encode_json({
		name      => $axes->xaxis('label'),
		withLabel => 1,
		position  => $xaxis_loc eq 'middle'  ? 'sticky' : 'fixed',
		anchor    => $xaxis_loc eq 'top'     ? 'left'   : $xaxis_loc eq 'bottom' ? 'right' : 'right left',
		visible   => $axes->xaxis('visible') ? 1        : 0,
		highlight => 0,
		label     => {
			position  => 'rt',
			offset    => [ -10, 10 ],
			highlight => 0
		},
		ticks => {
			drawLabels    => $axes->xaxis('tick_labels') && $axes->xaxis('show_ticks')       ? 1 : 0,
			drawZero      => $axes->style('jsx_navigation') || $axes->yaxis('position') != 0 ? 1 : 0,
			insertTicks   => 0,
			ticksDistance => $axes->xaxis('tick_delta'),
			majorHeight   => $axes->xaxis('show_ticks') ? ($show_grid && $axes->xaxis('major') ? -1 : 10) : 0,
			minorTicks    => $axes->xaxis('major')      ? $axes->xaxis('minor')                           : 0,
			minorHeight   => $axes->xaxis('show_ticks') ? ($show_grid ? -1 : 7)                           : 0,
			label         => { highlight => 0 },
		},
	});
	$XAxisOptions = "JXG.merge($XAxisOptions, " . Mojo::JSON::encode_json($axes->xaxis('jsx_options')) . ')'
		if $axes->xaxis('jsx_options');
	my $YAxisOptions = Mojo::JSON::encode_json({
		name      => $axes->yaxis('label'),
		withLabel => 1,
		position  => $yaxis_loc eq 'center'  ? 'sticky'     : 'fixed',
		anchor    => $yaxis_loc eq 'center'  ? 'right left' : $yaxis_loc,
		visible   => $axes->yaxis('visible') ? 1            : 0,
		highlight => 0,
		label     => {
			position  => 'rt',
			offset    => [ 10, -10 ],
			highlight => 0,
		},
		ticks => {
			drawLabels    => $axes->yaxis('tick_labels') && $axes->yaxis('show_ticks')       ? 1 : 0,
			drawZero      => $axes->style('jsx_navigation') || $axes->xaxis('position') != 0 ? 1 : 0,
			insertTicks   => 0,
			ticksDistance => $axes->yaxis('tick_delta'),
			majorHeight   => $axes->yaxis('show_ticks') ? ($show_grid && $axes->yaxis('major') ? -1 : 10) : 0,
			minorTicks    => $axes->yaxis('major')      ? $axes->yaxis('minor')                           : 0,
			minorHeight   => $axes->yaxis('show_ticks') ? ($show_grid ? -1 : 7)                           : 0,
			label         => { highlight => 0 },
		},
	});
	$YAxisOptions = "JXG.merge($YAxisOptions, " . Mojo::JSON::encode_json($axes->yaxis('jsx_options')) . ')'
		if $axes->yaxis('jsx_options');

	$self->{JSend} = '';
	$self->{JS}    = <<END_JS;
		const board_$name = JXG.JSXGraph.initBoard('board_$name', $JSXOptions);
		board_$name.create('axis', [[0, $xaxis_pos], [1, $xaxis_pos]], $XAxisOptions);
		board_$name.create('axis', [[$yaxis_pos, 0], [$yaxis_pos, 1]], $YAxisOptions);
END_JS
}

sub draw {
	my $self  = shift;
	my $plots = $self->plots;
	my $name  = $plots->get_image_name =~ s/-/_/gr;
	$self->{name} = $name;

	$self->init_graph;

	# Plot Data
	for my $data ($plots->data('function', 'dataset')) {
		$self->add_curve($data);
		$self->add_points($data);
	}

	# Vector/Slope Fields
	for my $data ($plots->data('vectorfield')) {
		my $xfunction = $data->function_string('x', 'js', 2);
		my $yfunction = $data->function_string('y', 'js', 2);

		if ($xfunction ne '' && $yfunction ne '') {
			my $f       = $data->{function};
			my $options = Mojo::JSON::encode_json({
				highlight   => 0,
				strokeColor => $self->get_color($data->style('color')),
				strokeWidth => $data->style('width'),
				scale       => $data->style('scale') || 1,
				($data->style('slopefield') ? (arrowhead => { enabled => 0 }) : ()),
			});
			$data->update_min_max;
			$options = "JXG.merge($options, " . Mojo::JSON::encode_json($data->style('jsx_options')) . ')'
				if $data->style('jsx_option');

			if ($data->style('normalize') || $data->style('slopefield')) {
				my $xtmp = "($xfunction)/Math.sqrt(($xfunction)**2 + ($yfunction)**2)";
				$yfunction = "($yfunction)/Math.sqrt(($xfunction)**2 + ($yfunction)**2)";
				$xfunction = $xtmp;
			}

			$self->{JS} .= "\n\t\tboard_$name.create('vectorfield', [[(x,y) => $xfunction, (x,y) => $yfunction], "
				. "[$f->{xmin}, $f->{xsteps}, $f->{xmax}], [$f->{ymin}, $f->{ysteps}, $f->{ymax}]], $options);";
		} else {
			warn "Vector field not created due to missing JavaScript functions.";
		}
	}

	# Stamps
	for my $stamp ($plots->data('stamp')) {
		my $mark = $stamp->style('symbol');
		next unless $mark;

		my $color = $self->get_color($stamp->style('color') || 'default_color');
		my $x     = $stamp->x(0);
		my $y     = $stamp->y(0);
		my $size  = $stamp->style('radius') || 4;

		$self->add_point($stamp, $x, $y, $size, $mark, $color);
	}

	# Labels
	for my $label ($plots->data('label')) {
		my $str         = $label->style('label');
		my $x           = $label->x(0);
		my $y           = $label->y(0);
		my $color       = $self->get_color($label->style('color') || 'default_color');
		my $fontsize    = $label->style('fontsize')    || 'medium';
		my $orientation = $label->style('orientation') || 'horizontal';
		my $h_align     = $label->style('h_align')     || 'center';
		my $v_align     = $label->style('v_align')     || 'middle';
		my $anchor      = $v_align eq 'top' ? 'north' : $v_align eq 'bottom' ? 'south' : '';
		my $textOptions = Mojo::JSON::encode_json({
			highlight   => 0,
			fontSize    => { tiny => 8, small => 10, medium => 12, large => 14, giant => 16 }->{$fontsize},
			rotate      => $orientation eq 'vertical' ? 90 : 0,
			strokeColor => $color,
			anchorX     => $h_align eq 'center' ? 'middle' : $h_align,
			anchorY     => $v_align,
			cssStyle    => 'padding: 3px;',
		});
		$textOptions = "JXG.merge($textOptions, " . Mojo::JSON::encode_json($label->style('jsx_options')) . ')'
			if $label->style('jsx_options');

		$self->{JS} .= "\n\t\tboard_$name.create('text', [$x, $y, '$str'], $textOptions);";
	}

	# JSXGraph only produces HTML graphs and uses TikZ for hadrcopy.
	return $self->HTML;
}

1;
