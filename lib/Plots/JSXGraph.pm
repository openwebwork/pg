
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

	my $imageviewClass = $self->plots->axes->style('jsx_navigation') ? '' : ' image-view-elt';
	my $tabindex       = $self->plots->axes->style('jsx_navigation') ? '' : ' tabindex="0"';
	my $details        = $self->plots->{description_details} =~ s/LONG-DESCRIPTION-ID/${name}_details/r;
	my $aria_details   = $details ? qq! aria-details="${name}_details"! : '';
	my $divs           = qq!<div id="jsxgraph-plot-$name" class="jxgbox plots-jsxgraph$imageviewClass"$tabindex!
		. qq!style="width: ${width}px; height: ${height}px;"$aria_details></div>!;
	$divs = qq!<div class="image-container">$divs$details</div>! if ($details);

	return <<~ "END_HTML";
		$divs
		<script>
		(async () => {
			const drawBoard = (id) => {
				$self->{JS}
				$self->{JSend}
				board.unsuspendUpdate();
				return board;
			}

			const drawPromise = (id) => new Promise((resolve) => {
				const container = document.getElementById(id);
				if (!container || container.offsetWidth === 0) {
					setTimeout(async () => resolve(await drawPromise(id)), 100);
					return;
				}
				resolve(drawBoard(id));
			});

			if (document.readyState === 'loading')
				window.addEventListener('DOMContentLoaded', async () => {
					await drawPromise('jsxgraph-plot-$name')
				});
			else await drawPromise('jsxgraph-plot-$name');

			const jsxPlotDiv = document.getElementById('jsxgraph-plot-$name');

			let jsxBoard = null;
			jsxPlotDiv?.addEventListener('shown.imageview', async () => {
				document.getElementById('magnified-jsxgraph-plot-$name')?.classList.add('jxgbox', 'plots-jsxgraph');
				jsxBoard = await drawPromise('magnified-jsxgraph-plot-$name');
			});
			jsxPlotDiv?.addEventListener('resized.imageview', () => {
				jsxBoard?.resizeContainer(jsxBoard.containerObj.clientWidth, jsxBoard.containerObj.clientHeight, true);
			});
			jsxPlotDiv?.addEventListener('hidden.imageview', () => {
				if (jsxBoard) JXG.JSXGraph.freeBoard(jsxBoard);
				jsxBoard = null;
			});
		})();
		</script>
		END_HTML
}

sub get_color {
	my ($self, $color) = @_;
	$color = 'default_color' unless $color;
	return sprintf("#%02x%02x%02x", @{ $self->plots->colors($color) });
}

sub get_linestyle {
	my ($self, $data) = @_;
	my $linestyle = $data->style('linestyle');
	return 0 unless $linestyle;
	$linestyle =~ s/ /_/g;
	return {
		solid              => 0,
		dashed             => 3,
		short_dashes       => 2,
		long_dashes        => 4,
		dotted             => $data->name eq 'dataset' || $data->name eq 'function' ? 7 : 1,
		long_medium_dashes => 5,
	}->{$linestyle}
		|| 0;
}

sub get_options {
	my ($self, $data, %extra_options) = @_;
	my $options = Mojo::JSON::encode_json({
		highlight   => 0,
		strokeColor => $self->get_color($data->style('color')),
		strokeWidth => $data->style('width'),
		$data->style('start_mark') eq 'arrow'
		? (firstArrow => { type => 4, size => $data->style('arrow_size') || 8 })
		: (),
		$data->style('end_mark') eq 'arrow' ? (lastArrow => { type => 4, size => $data->style('arrow_size') || 8 })
		: (),
		$data->style('fill') eq 'self'
		? (
			fillColor   => $self->get_color($data->style('fill_color') || $data->style('color')),
			fillOpacity => $data->style('fill_opacity')
				|| 0.5
			)
		: (),
		dash => $self->get_linestyle($data),
		%extra_options,
	});
	return $data->style('jsx_options')
		? "JXG.merge($options, " . Mojo::JSON::encode_json($data->style('jsx_options')) . ')'
		: $options;
}

sub add_curve {
	my ($self, $data) = @_;
	return if $data->style('linestyle') eq 'none';

	my $curve_name  = $data->style('name');
	my $fill        = $data->style('fill') || 'none';
	my $plotOptions = $self->get_options($data, $data->style('polar') ? (curveType => 'polar') : ());

	my $type = 'curve';
	my $data_points;
	if ($data->name eq 'function') {
		my $f = $data->{function};
		if (ref($f->{Fx}) ne 'CODE' && $f->{xvar} eq $f->{Fx}->string) {
			my $function = $data->function_string($f->{Fy}, 'js', $f->{xvar});
			if ($function ne '') {
				$data->update_min_max;
				my $min = $data->style('continue') || $data->style('continue_left')  ? '' : $f->{xmin};
				my $max = $data->style('continue') || $data->style('continue_right') ? '' : $f->{xmax};
				if ($data->style('polar')) {
					$data_points = "[x => $function, [0, 0], $min, $max]";
				} else {
					$type        = 'functiongraph';
					$data_points = "[x => $function, $min, $max]";
				}
			}
		} else {
			my $xfunction = $data->function_string($f->{Fx}, 'js', $f->{xvar});
			my $yfunction = $data->function_string($f->{Fy}, 'js', $f->{xvar});
			if ($xfunction ne '' && $yfunction ne '') {
				$data->update_min_max;
				$data_points = "[x => $xfunction, x => $yfunction, $f->{xmin}, $f->{xmax}]";
			}
		}
	}
	unless ($data_points) {
		$data->gen_data;
		$data_points = '[[' . join(',', $data->x) . '],[' . join(',', $data->y) . ']]';
	}

	$self->{JS} .= "const curve_${curve_name} = " if $curve_name;
	$self->{JS} .= "board.create('$type', $data_points, $plotOptions);";
	$self->add_point($data, $data->get_start_point, $data->style('width'), $data->style('start_mark'))
		if $data->style('start_mark') =~ /circle/;
	$self->add_point($data, $data->get_end_point, $data->style('width'), $data->style('end_mark'))
		if $data->style('end_mark') =~ /circle/;

	if ($fill ne 'none' && $fill ne 'self') {
		if ($curve_name) {
			my $fill_min    = $data->str_to_real($data->style('fill_min'));
			my $fill_max    = $data->str_to_real($data->style('fill_max'));
			my $fillOptions = Mojo::JSON::encode_json({
				strokeWidth => 0,
				fillColor   => $self->get_color($data->style('fill_color') || $data->style('color')),
				fillOpacity => $data->style('fill_opacity') || 0.5,
				highlight   => 0,
			});

			if ($fill eq 'xaxis') {
				$self->{JSend} .=
					"const fill_${curve_name} = board.create('curve', [[], []], $fillOptions);"
					. "fill_${curve_name}.updateDataArray = function () {"
					. "const points = curve_${curve_name}.points";
				if ($fill_min ne '' && $fill_max ne '') {
					$self->{JSend} .=
						".filter(p => {"
						. "return p.usrCoords[1] >= $fill_min && p.usrCoords[1] <= $fill_max ? true : false" . "})";
				}
				$self->{JSend} .=
					";this.dataX = points.map( p => p.usrCoords[1] );"
					. "this.dataY = points.map( p => p.usrCoords[2] );"
					. "this.dataX.push(points[points.length - 1].usrCoords[1], "
					. "points[0].usrCoords[1], points[0].usrCoords[1]);"
					. "this.dataY.push(0, 0, points[0].usrCoords[2]);" . "};"
					. "board.update();";
			} else {
				$self->{JSend} .=
					"const fill_${curve_name} = board.create('curve', [[], []], $fillOptions);"
					. "fill_${curve_name}.updateDataArray = function () {"
					. "const points1 = curve_${curve_name}.points";
				if ($fill_min ne '' && $fill_max ne '') {
					$self->{JSend} .=
						".filter(p => {"
						. "return p.usrCoords[1] >= $fill_min && p.usrCoords[1] <= $fill_max ? true : false" . "})";
				}
				$self->{JSend} .= ";const points2 = curve_${fill}.points";
				if ($fill_min ne '' && $fill_max ne '') {
					$self->{JSend} .=
						".filter(p => {"
						. "return p.usrCoords[1] >= $fill_min && p.usrCoords[1] <= $fill_max ? true : false" . "})";
				}
				$self->{JSend} .=
					";this.dataX = points1.map( p => p.usrCoords[1] ).concat("
					. "points2.map( p => p.usrCoords[1] ).reverse());"
					. "this.dataY = points1.map( p => p.usrCoords[2] ).concat("
					. "points2.map( p => p.usrCoords[2] ).reverse());"
					. "this.dataX.push(points1[0].usrCoords[1]);"
					. "this.dataY.push(points1[0].usrCoords[2]);" . "};"
					. "board.update();";
			}
		} else {
			warn "Unable to create fill. Missing 'name' attribute.";
		}
	}
	return;
}

sub add_multipath {
	my ($self, $data) = @_;
	return if $data->style('linestyle') eq 'none';

	my @paths       = @{ $data->{paths} };
	my $n           = scalar(@paths);
	my $var         = $data->{function}{var};
	my $curve_name  = $data->style('name');
	my $plotOptions = $self->get_options($data);
	my $jsFunctionx = 'function (x){';
	my $jsFunctiony = 'function (x){';

	for (0 .. $#paths) {
		my $path = $paths[$_];
		my $a    = $_ / $n;
		my $b    = ($_ + 1) / $n;
		my $tmin = $path->{tmin};
		my $tmax = $path->{tmax};
		my $m    = ($tmax - $tmin) / ($b - $a);
		my $tmp  = $a < 0 ? 'x+' . (-$a)       : "x-$a";
		my $t    = $m < 0 ? "($tmin$m*($tmp))" : "($tmin+$m*($tmp))";

		my $xfunction = $data->function_string($path->{Fx}, 'js', $var, undef, $t);
		my $yfunction = $data->function_string($path->{Fy}, 'js', $var, undef, $t);
		$jsFunctionx .= "if(x<=$b){return $xfunction;}";
		$jsFunctiony .= "if(x<=$b){return $yfunction;}";
	}
	$jsFunctionx .= 'return 0;}';
	$jsFunctiony .= 'return 0;}';

	$self->{JS} .= "const curve_${curve_name} = " if $curve_name;
	$self->{JS} .= "board.create('curve', [$jsFunctionx, $jsFunctiony, 0, 1], $plotOptions);";
	return;
}

sub add_point {
	my ($self, $data, $x, $y, $size, $mark) = @_;
	my $color = $self->get_color($data->style('color'));
	my $fill  = $color;

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

	$self->{JS} .= "board.create('point', [$x, $y], $pointOptions);";
	return;
}

sub add_points {
	my ($self, $data) = @_;
	my $mark = $data->style('marks');
	return if !$mark || $mark eq 'none';

	# Need to generate points for functions.
	$data->gen_data if $data->name eq 'function';

	for (0 .. $data->size - 1) {
		$self->add_point($data, $data->x($_), $data->y($_), $data->style('mark_size') || $data->style('width'), $mark);
	}
	return;
}

sub add_circle {
	my ($self, $data) = @_;
	my $x             = $data->x(0);
	my $y             = $data->y(0);
	my $r             = $data->style('radius');
	my $linestyle     = $self->get_linestyle($data);
	my $circleOptions = $self->get_options($data);

	$self->{JS} .= "board.create('circle', [[$x, $y], $r], $circleOptions);";
	return;
}

sub add_arc {
	my ($self, $data) = @_;
	my ($x1, $y1)     = ($data->x(0), $data->y(0));
	my ($x2, $y2)     = ($data->x(1), $data->y(1));
	my ($x3, $y3)     = ($data->x(2), $data->y(2));
	my $arcOptions = $self->get_options(
		$data,
		anglePoint  => { visible => 0 },
		center      => { visible => 0 },
		radiusPoint => { visible => 0 },
	);

	$self->{JS} .= "board.create('arc', [[$x1, $y1], [$x2, $y2], [$x3, $y3]], $arcOptions);";
	return;
}

sub init_graph {
	my $self             = shift;
	my $plots            = $self->plots;
	my $axes             = $plots->axes;
	my $xaxis_loc        = $axes->xaxis('location');
	my $yaxis_loc        = $axes->yaxis('location');
	my $xaxis_pos        = $axes->xaxis('position');
	my $yaxis_pos        = $axes->yaxis('position');
	my $show_grid        = $axes->style('show_grid');
	my $allow_navigation = $axes->style('jsx_navigation') ? 1 : 0;
	my ($xmin, $ymin, $xmax, $ymax) = $axes->bounds;
	$xaxis_loc = 'bottom' if $xaxis_loc eq 'box';
	$yaxis_loc = 'left'   if $yaxis_loc eq 'box';

	# Determine if zero should be drawn on the axis.
	my $x_draw_zero =
		$allow_navigation
		|| ($yaxis_loc eq 'center' && $yaxis_pos != 0)
		|| ($yaxis_loc eq 'left'   && $ymin != 0)
		|| ($yaxis_loc eq 'right'  && $ymax != 0) ? 1 : 0;
	my $y_draw_zero =
		$allow_navigation
		|| ($xaxis_loc eq 'middle' && $xaxis_pos != 0)
		|| ($xaxis_loc eq 'bottom' && $xmin != 0)
		|| ($xaxis_loc eq 'top'    && $xmax != 0) ? 1 : 0;

	# Adjust bounding box to add padding for axes at edge of graph.
	$xmin -= 0.11 * ($xmax - $xmin) if $yaxis_loc eq 'left'   || $xmin == $yaxis_pos;
	$xmax += 0.11 * ($xmax - $xmin) if $yaxis_loc eq 'right'  || $xmax == $yaxis_pos;
	$ymin -= 0.11 * ($ymax - $ymin) if $xaxis_loc eq 'bottom' || $ymin == $xaxis_pos;
	$ymax += 0.11 * ($ymax - $ymin) if $xaxis_loc eq 'top'    || $ymax == $xaxis_pos;

	my $JSXOptions = Mojo::JSON::encode_json({
		title          => $axes->style('aria_label'),
		boundingBox    => [ $xmin, $ymax, $xmax, $ymin ],
		axis           => 0,
		showNavigation => $allow_navigation,
		pan            => { enabled => $allow_navigation },
		zoom           => { enabled => $allow_navigation },
		showCopyright  => 0,
		drag           => { enabled => 0 },
	});
	$JSXOptions = "JXG.merge($JSXOptions, " . Mojo::JSON::encode_json($axes->style('jsx_options')) . ')'
		if $axes->style('jsx_options');
	my $XAxisOptions = Mojo::JSON::encode_json({
		name          => $axes->xaxis('label'),
		withLabel     => 1,
		position      => $xaxis_loc eq 'middle'  ? ($allow_navigation ? 'sticky' : 'static') : 'fixed',
		anchor        => $xaxis_loc eq 'top'     ? 'left' : $xaxis_loc eq 'bottom' ? 'right' : 'right left',
		visible       => $axes->xaxis('visible') ? 1      : 0,
		highlight     => 0,
		firstArrow    => 0,
		lastArrow     => { size => 7 },
		straightFirst => $allow_navigation,
		straightLast  => $allow_navigation,
		label         => {
			anchorX    => 'middle',
			anchorY    => 'middle',
			position   => '100% left',
			offset     => [ -10, 0 ],
			highlight  => 0,
			useMathJax => 1
		},
		ticks => {
			drawLabels    => $axes->xaxis('tick_labels') && $axes->xaxis('show_ticks') ? 1 : 0,
			drawZero      => $x_draw_zero,
			strokeColor   => $self->get_color($axes->style('grid_color')),
			strokeOpacity => $axes->style('grid_alpha') / 200,
			insertTicks   => 0,
			ticksDistance => $axes->xaxis('tick_delta'),
			majorHeight   => $axes->xaxis('show_ticks') ? ($show_grid && $axes->xaxis('major') ? -1 : 10) : 0,
			minorTicks    => $axes->xaxis('minor'),
			minorHeight   => $axes->xaxis('show_ticks') ? ($show_grid && $axes->xaxis('major') ? -1 : 7) : 0,
			label         => {
				highlight => 0,
				anchorX   => 'middle',
				anchorY   => $xaxis_loc eq 'top' ? 'bottom' : 'top',
				offset    => $xaxis_loc eq 'top' ? [ 0, 3 ] : [ 0, -3 ]
			},
		},
	});
	$XAxisOptions = "JXG.merge($XAxisOptions, " . Mojo::JSON::encode_json($axes->xaxis('jsx_options')) . ')'
		if $axes->xaxis('jsx_options');
	my $YAxisOptions = Mojo::JSON::encode_json({
		name          => $axes->yaxis('label'),
		withLabel     => 1,
		position      => $yaxis_loc eq 'center'  ? ($allow_navigation ? 'sticky' : 'static') : 'fixed',
		anchor        => $yaxis_loc eq 'center'  ? 'right left'                              : $yaxis_loc,
		visible       => $axes->yaxis('visible') ? 1                                         : 0,
		highlight     => 0,
		firstArrow    => 0,
		lastArrow     => { size => 7 },
		straightFirst => $allow_navigation,
		straightLast  => $allow_navigation,
		label         => {
			anchorX    => 'middle',
			anchorY    => 'middle',
			position   => '100% right',
			offset     => [ 6, -10 ],
			highlight  => 0,
			useMathJax => 1
		},
		ticks => {
			drawLabels    => $axes->yaxis('tick_labels') && $axes->yaxis('show_ticks') ? 1 : 0,
			drawZero      => $y_draw_zero,
			strokeColor   => $self->get_color($axes->style('grid_color')),
			strokeOpacity => $axes->style('grid_alpha') / 200,
			insertTicks   => 0,
			ticksDistance => $axes->yaxis('tick_delta'),
			majorHeight   => $axes->yaxis('show_ticks') ? ($show_grid && $axes->yaxis('major') ? -1 : 10) : 0,
			minorTicks    => $axes->yaxis('minor'),
			minorHeight   => $axes->yaxis('show_ticks') ? ($show_grid && $axes->yaxis('major') ? -1 : 7) : 0,
			label         => {
				highlight => 0,
				anchorX   => $yaxis_loc eq 'right' ? 'left' : 'right',
				anchorY   => 'middle',
				offset    => $yaxis_loc eq 'right' ? [ 6, 0 ] : [ -6, 0 ]
			},
		},
	});
	$YAxisOptions = "JXG.merge($YAxisOptions, " . Mojo::JSON::encode_json($axes->yaxis('jsx_options')) . ')'
		if $axes->yaxis('jsx_options');

	$self->{JSend} = '';
	$self->{JS}    = <<~ "END_JS";
			const board = JXG.JSXGraph.initBoard(id, $JSXOptions);
			const descriptionSpan = document.createElement('span');
			descriptionSpan.id = `\${id}_description`;
			descriptionSpan.classList.add('visually-hidden');
			descriptionSpan.textContent = '${\($axes->style('aria_description'))}';
			board.containerObj.after(descriptionSpan);
			board.containerObj.setAttribute('aria-describedby', descriptionSpan.id);
			board.suspendUpdate();
			board.create('axis', [[$xmin, $xaxis_pos], [$xmax, $xaxis_pos]], $XAxisOptions);
			board.create('axis', [[$yaxis_pos, $ymin], [$yaxis_pos, $ymax]], $YAxisOptions);
		END_JS
}

sub draw {
	my $self  = shift;
	my $plots = $self->plots;
	$self->{name} = $plots->get_image_name =~ s/-/_/gr;

	$self->init_graph;

	# Plot Data
	for my $data ($plots->data('function', 'dataset', 'circle', 'arc', 'multipath')) {
		if ($data->name eq 'circle') {
			$self->add_circle($data);
		} elsif ($data->name eq 'arc') {
			$self->add_arc($data);
		} elsif ($data->name eq 'multipath') {
			$self->add_multipath($data);
		} else {
			$self->add_curve($data);
			$self->add_points($data);
		}
	}

	# Vector/Slope Fields
	for my $data ($plots->data('vectorfield')) {
		my $f         = $data->{function};
		my $xfunction = $data->function_string($f->{Fx}, 'js', $f->{xvar}, $f->{yvar});
		my $yfunction = $data->function_string($f->{Fy}, 'js', $f->{xvar}, $f->{yvar});

		if ($xfunction ne '' && $yfunction ne '') {
			my $options = $self->get_options(
				$data,
				scale => $data->style('scale') || 1,
				($data->style('slopefield') ? (arrowhead => { enabled => 0 }) : ()),
			);
			$data->update_min_max;

			if ($data->style('normalize') || $data->style('slopefield')) {
				my $xtmp = "($xfunction)/Math.sqrt(($xfunction)**2 + ($yfunction)**2)";
				$yfunction = "($yfunction)/Math.sqrt(($xfunction)**2 + ($yfunction)**2)";
				$xfunction = $xtmp;
			}

			$self->{JS} .= "board.create('vectorfield', [[(x,y) => $xfunction, (x,y) => $yfunction], "
				. "[$f->{xmin}, $f->{xsteps}, $f->{xmax}], [$f->{ymin}, $f->{ysteps}, $f->{ymax}]], $options);";
		} else {
			warn "Vector field not created due to missing JavaScript functions.";
		}
	}

	# Stamps
	for my $stamp ($plots->data('stamp')) {
		my $mark = $stamp->style('symbol');
		next unless $mark;

		my $color = $self->get_color($stamp->style('color'));
		my $x     = $stamp->x(0);
		my $y     = $stamp->y(0);
		my $size  = $stamp->style('radius') || 4;

		$self->add_point($stamp, $x, $y, $size, $mark);
	}

	# Labels
	for my $label ($plots->data('label')) {
		my $str         = $label->style('label');
		my $x           = $label->x(0);
		my $y           = $label->y(0);
		my $fontsize    = $label->style('fontsize') || 'medium';
		my $h_align     = $label->style('h_align')  || 'center';
		my $v_align     = $label->style('v_align')  || 'middle';
		my $anchor      = $v_align eq 'top' ? 'north' : $v_align eq 'bottom' ? 'south' : '';
		my $textOptions = Mojo::JSON::encode_json({
			highlight   => 0,
			fontSize    => { tiny => 8, small => 10, medium => 12, large => 14, giant => 16 }->{$fontsize},
			rotate      => $label->style('rotate') || 0,
			strokeColor => $self->get_color($label->style('color')),
			anchorX     => $h_align eq 'center' ? 'middle' : $h_align,
			anchorY     => $v_align,
			cssStyle    => 'padding: 3px;',
			useMathJax  => 1,
		});
		$textOptions = "JXG.merge($textOptions, " . Mojo::JSON::encode_json($label->style('jsx_options')) . ')'
			if $label->style('jsx_options');

		$self->{JS} .= "board.create('text', [$x, $y, '$str'], $textOptions);";
	}

	# JSXGraph only produces HTML graphs and uses TikZ for hadrcopy.
	return $self->HTML;
}

1;
