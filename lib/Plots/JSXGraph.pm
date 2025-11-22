
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
	$plots->add_js_file('node_modules/jsxgraph/distrib/jsxgraphcore.js', { defer => undef });
	$plots->add_js_file('js/Plots/plots.js',                             { defer => undef });

	return bless { plots => $plots, names => { xaxis => 1 } }, $class;
}

sub plots {
	my $self = shift;
	return $self->{plots};
}

sub HTML {
	my $self = shift;

	my $plots = $self->plots;
	my ($width, $height) = $plots->size;

	my $imageviewClass      = $plots->axes->style('jsx_navigation') ? ''                        : ' image-view-elt';
	my $tabindex            = $plots->axes->style('jsx_navigation') ? ''                        : ' tabindex="0"';
	my $roundedCornersClass = $plots->{rounded_corners}             ? ' plots-jsxgraph-rounded' : '';
	my $details             = $plots->{description_details} =~ s/LONG-DESCRIPTION-ID/$self->{name}_details/r;
	my $aria_details        = $details ? qq! aria-details="$self->{name}_details"! : '';

	my $divs =
		qq!<div id="jsxgraph-plot-$self->{name}" !
		. qq!class="jxgbox plots-jsxgraph$imageviewClass$roundedCornersClass"$tabindex!
		. qq!style="width: ${width}px; height: ${height}px;"$aria_details></div>!;
	$divs = qq!<div class="image-container">$divs$details</div>! if $details;

	my $axes      = $plots->axes;
	my $xaxis_loc = $axes->xaxis('location');
	my $yaxis_loc = $axes->yaxis('location');
	my $xaxis_pos = $axes->xaxis('position');
	my $yaxis_pos = $axes->yaxis('position');
	my $show_grid = $axes->style('show_grid');
	my $grid      = $axes->grid;
	my ($xmin, $ymin, $xmax, $ymax) = $axes->bounds;

	my ($xvisible, $yvisible) = ($axes->xaxis('visible'), $axes->yaxis('visible'));

	my $options = {};

	$options->{ariaDescription} = $axes->style('aria_description') if defined $axes->style('aria_description');

	$options->{board}{title}           = $axes->style('aria_label');
	$options->{board}{showNavigation}  = $axes->style('jsx_navigation') ? 1 : 0;
	$options->{board}{overrideOptions} = $axes->style('jsx_options') if $axes->style('jsx_options');

	# Set the bounding box. Add padding for the axes at the edge of graph if needed.
	$options->{board}{boundingBox} = [
		$xmin - (
			$yvisible
				&& ($yaxis_loc eq 'left' || $yaxis_loc eq 'box' || $xmin == $yaxis_pos) ? 0.11 * ($xmax - $xmin) : 0
		),
		$ymax + ($xvisible && ($xaxis_loc eq 'top'   || $ymax == $xaxis_pos) ? 0.11 * ($ymax - $ymin) : 0),
		$xmax + ($yvisible && ($yaxis_loc eq 'right' || $xmax == $yaxis_pos) ? 0.11 * ($xmax - $xmin) : 0),
		$ymin - (
			$xvisible
				&& ($xaxis_loc eq 'bottom' || $xaxis_loc eq 'box' || $ymin == $xaxis_pos) ? 0.11 * ($ymax - $ymin) : 0
		)
	];

	$options->{xAxis}{visible} = $xvisible;
	if ($xvisible || ($show_grid && $grid->{xmajor})) {
		($options->{xAxis}{min}, $options->{xAxis}{max}) = ($xmin, $xmax);
		$options->{xAxis}{position}          = $xaxis_pos;
		$options->{xAxis}{location}          = $xaxis_loc;
		$options->{xAxis}{ticks}{scale}      = $axes->xaxis('tick_scale');
		$options->{xAxis}{ticks}{distance}   = $axes->xaxis('tick_distance');
		$options->{xAxis}{ticks}{minorTicks} = $grid->{xminor};
	}

	$options->{yAxis}{visible} = $yvisible;
	if ($yvisible || ($show_grid && $grid->{ymajor})) {
		($options->{yAxis}{min}, $options->{yAxis}{max}) = ($ymin, $ymax);
		$options->{yAxis}{position}          = $yaxis_pos;
		$options->{yAxis}{location}          = $yaxis_loc;
		$options->{yAxis}{ticks}{scale}      = $axes->yaxis('tick_scale');
		$options->{yAxis}{ticks}{distance}   = $axes->yaxis('tick_distance');
		$options->{yAxis}{ticks}{minorTicks} = $grid->{yminor};
	}

	if ($show_grid) {
		if ($grid->{xmajor} || $grid->{ymajor}) {
			$options->{grid}{color}   = $self->get_color($axes->style('grid_color'));
			$options->{grid}{opacity} = $axes->style('grid_alpha') / 200;
		}

		if ($grid->{xmajor}) {
			$options->{grid}{x}{minorGrids}      = $grid->{xminor_grids};
			$options->{grid}{x}{overrideOptions} = $axes->xaxis('jsx_grid_options') if $axes->xaxis('jsx_grid_options');
		}

		if ($grid->{ymajor}) {
			$options->{grid}{y}{minorGrids}      = $grid->{yminor_grids};
			$options->{grid}{y}{overrideOptions} = $axes->yaxis('jsx_grid_options') if $axes->yaxis('jsx_grid_options');
		}
	}

	$options->{mathJaxTickLabels} = $axes->style('mathjax_tick_labels') if $xvisible || $yvisible;

	if ($xvisible) {
		$options->{xAxis}{name}               = $axes->xaxis('label');
		$options->{xAxis}{ticks}{show}        = $axes->xaxis('show_ticks');
		$options->{xAxis}{ticks}{labels}      = $axes->xaxis('tick_labels');
		$options->{xAxis}{ticks}{labelFormat} = $axes->xaxis('tick_label_format');
		$options->{xAxis}{ticks}{labelDigits} = $axes->xaxis('tick_label_digits');
		$options->{xAxis}{ticks}{scaleSymbol} = $axes->xaxis('tick_scale_symbol');
		$options->{xAxis}{arrowsBoth}         = $axes->xaxis('arrows_both');
		$options->{xAxis}{overrideOptions}    = $axes->xaxis('jsx_options') if $axes->xaxis('jsx_options');
	}
	if ($yvisible) {
		$options->{yAxis}{name}               = $axes->yaxis('label');
		$options->{yAxis}{ticks}{show}        = $axes->yaxis('show_ticks');
		$options->{yAxis}{ticks}{labels}      = $axes->yaxis('tick_labels');
		$options->{yAxis}{ticks}{labelFormat} = $axes->yaxis('tick_label_format');
		$options->{yAxis}{ticks}{labelDigits} = $axes->yaxis('tick_label_digits');
		$options->{yAxis}{ticks}{scaleSymbol} = $axes->yaxis('tick_scale_symbol');
		$options->{yAxis}{arrowsBoth}         = $axes->yaxis('arrows_both');
		$options->{yAxis}{overrideOptions}    = $axes->yaxis('jsx_options') if $axes->yaxis('jsx_options');
	}

	$self->{JS}             //= '';
	$plots->{extra_js_code} //= '';

	return <<~ "END_HTML";
		$divs
		<script>
		(async () => {
			const id = 'jsxgraph-plot-$self->{name}';
			const options = ${\(Mojo::JSON::encode_json($options))};
			const plotContents = (board, plot) => { $self->{JS}$plots->{extra_js_code} };
			if (document.readyState === 'loading')
				window.addEventListener('DOMContentLoaded',
					async () => { await PGplots.plot(id, plotContents, options); });
			else await PGplots.plot(id, plotContents, options);
		})();
		</script>
		END_HTML
}

sub get_color {
	my ($self, $color) = @_;
	$color = 'default_color' unless $color;
	my $colorParts = $self->plots->colors($color);
	return $color unless ref $colorParts eq 'ARRAY';    # Try to use the color by name if it wasn't defined.
	return sprintf("#%02x%02x%02x", @$colorParts);
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

# Translate pgfplots layers to JSXGraph layers.
# FIXME: JSXGraph layers work rather differently than pgfplots layers. So this is a bit fuzzy, and may need adjustment.
# The layers chosen are as close as possible to the layers that JSXGraph uses by default, although "pre main" and "main"
# don't really have an equivalent. See https://jsxgraph.uni-bayreuth.de/docs/symbols/JXG.Options.html#layer.
# This also does not honor the "axis_on_top" setting.
sub get_layer {
	my ($self, $data, $useFillLayer) = @_;
	my $layer = $data->style($useFillLayer ? 'fill_layer' : 'layer');
	return unless $layer;
	return {
		'axis background'   => 0,
		'axis grid'         => 1,
		'axis ticks'        => 2,
		'axis lines'        => 3,
		'pre main'          => 4,
		'main'              => 5,
		'axis tick labels'  => 9,
		'axis descriptions' => 9,
		'axis foreground'   => 10
	}->{$layer} // undef;
}

sub get_options {
	my ($self, $data, %extra_options) = @_;

	my $fill      = $data->style('fill') || 'none';
	my $drawLayer = $self->get_layer($data);
	my $fillLayer = $self->get_layer($data, 1) // $drawLayer;

	my $drawFillSeparate =
		$fill eq 'self'
		&& $data->style('linestyle') ne 'none'
		&& defined $fillLayer
		&& (!defined $drawLayer || $drawLayer != $fillLayer);

	my (%drawOptions, %fillOptions);

	if ($data->style('linestyle') ne 'none') {
		$drawOptions{layer}       = $drawLayer if defined $drawLayer;
		$drawOptions{dash}        = $self->get_linestyle($data);
		$drawOptions{strokeColor} = $self->get_color($data->style('color'));
		$drawOptions{strokeWidth} = $data->style('width');
		$drawOptions{firstArrow}  = { type => 2, size => $data->style('arrow_size') || 8 }
			if $data->style('start_mark') eq 'arrow';
		$drawOptions{lastArrow} = { type => 2, size => $data->style('arrow_size') || 8 }
			if $data->style('end_mark') eq 'arrow';
	}

	if ($drawFillSeparate) {
		$fillOptions{strokeWidth}           = 0;
		$fillOptions{layer}                 = $fillLayer;
		$fillOptions{fillColor}             = $self->get_color($data->style('fill_color') || $data->style('color'));
		$fillOptions{fillOpacity}           = $data->style('fill_opacity') || 0.5;
		@fillOptions{ keys %extra_options } = values %extra_options;
	} elsif ($fill eq 'self') {
		if (!%drawOptions) {
			$drawOptions{strokeWidth} = 0;
			$drawOptions{layer}       = $fillLayer if defined $fillLayer;
		}
		$drawOptions{fillColor}   = $self->get_color($data->style('fill_color') || $data->style('color'));
		$drawOptions{fillOpacity} = $data->style('fill_opacity') || 0.5;
	} elsif ($data->style('name') && $data->style('linestyle') eq 'none') {
		# This forces the curve to be drawn invisibly if it has been named, but the linestyle is 'none'.
		$drawOptions{strokeWidth} = 0;
	}

	@drawOptions{ keys %extra_options } = values %extra_options if %drawOptions;

	my $drawOptions = %drawOptions      ? Mojo::JSON::encode_json(\%drawOptions) : '';
	my $fillOptions = $drawFillSeparate ? Mojo::JSON::encode_json(\%fillOptions) : '';
	return (
		$drawOptions && $data->style('jsx_options')
		? "JXG.merge($drawOptions, " . Mojo::JSON::encode_json($data->style('jsx_options')) . ')'
		: $drawOptions,
		$fillOptions && $data->style('jsx_options')
		? "JXG.merge($fillOptions, " . Mojo::JSON::encode_json($data->style('jsx_options')) . ')'
		: $fillOptions
	);
}

sub add_curve {
	my ($self, $data) = @_;

	my $curve_name = $data->style('name');
	warn 'Duplicate plot name detected. This will most likely cause issues. Make sure that all names used are unique.'
		if $curve_name && $self->{names}{$curve_name};
	$self->{names}{$curve_name} = 1 if $curve_name;

	my ($plotOptions, $fillOptions) = $self->get_options($data, $data->style('polar') ? (curveType => 'polar') : ());

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

	$self->{JS} .= "const curve_${curve_name} = "                       if $curve_name;
	$self->{JS} .= "board.create('$type', $data_points, $plotOptions);" if $plotOptions;
	$self->{JS} .= "board.create('$type', $data_points, $fillOptions);" if $fillOptions;
	$self->add_point(
		$data, $data->get_start_point,
		1.1 * ($data->style('width') || 2),
		$data->style('width') || 2,
		$data->style('start_mark')
	) if $data->style('linestyle') ne 'none' && $data->style('start_mark') =~ /circle/;
	$self->add_point(
		$data, $data->get_end_point,
		1.1 * ($data->style('width') || 2),
		$data->style('width') || 2,
		$data->style('end_mark')
	) if $data->style('linestyle') ne 'none' && $data->style('end_mark') =~ /circle/;

	my $fill = $data->style('fill') || 'none';
	if ($fill ne 'none' && $fill ne 'self') {
		if ($self->{names}{$fill}) {
			if ($curve_name) {
				my $fill_min    = $data->str_to_real($data->style('fill_min'));
				my $fill_max    = $data->str_to_real($data->style('fill_max'));
				my $fill_min_y  = $data->str_to_real($data->style('fill_min_y'));
				my $fill_max_y  = $data->str_to_real($data->style('fill_max_y'));
				my $fill_layer  = $self->get_layer($data, 1) // $self->get_layer($data);
				my $fillOptions = Mojo::JSON::encode_json({
					strokeWidth => 0,
					fillColor   => $self->get_color($data->style('fill_color') || $data->style('color')),
					fillOpacity => $data->style('fill_opacity') || 0.5,
					defined $fill_layer ? (layer => $fill_layer) : (),
				});

				if ($fill eq 'xaxis') {
					$self->{JS} .=
						"const fill_${curve_name} = board.create('curve', [[], []], $fillOptions);"
						. "fill_${curve_name}.updateDataArray = function () {"
						. "const points = curve_${curve_name}.points";
					if ($fill_min ne '' && $fill_max ne '') {
						$self->{JS} .=
							".filter(p => {"
							. "return p.usrCoords[1] >= $fill_min && p.usrCoords[1] <= $fill_max ? true : false" . "})";
					}
					$self->{JS} .=
						";this.dataX = points.map( p => p.usrCoords[1] );"
						. "this.dataY = points.map( p => p.usrCoords[2] );"
						. "this.dataX.push(points[points.length - 1].usrCoords[1], "
						. "points[0].usrCoords[1], points[0].usrCoords[1]);"
						. "this.dataY.push(0, 0, points[0].usrCoords[2]);" . "};"
						. "board.update();";
				} else {
					$self->{JS} .=
						"const fill_${curve_name} = board.create('curve', [[], []], $fillOptions);"
						. "fill_${curve_name}.updateDataArray = function () {"
						. "const points1 = curve_${curve_name}.points";
					if ($fill_min ne '' && $fill_max ne '') {
						$self->{JS} .=
							".filter(p => {"
							. "return p.usrCoords[1] >= $fill_min && p.usrCoords[1] <= $fill_max ? true : false" . "})";
					}
					if ($fill_min_y ne '' && $fill_max_y ne '') {
						$self->{JS} .=
							".filter(p => {"
							. "return p.usrCoords[2] >= $fill_min_y && p.usrCoords[2] <= $fill_max_y ? true : false"
							. "})";
					}
					$self->{JS} .= ";const points2 = curve_${fill}.points";
					if ($fill_min ne '' && $fill_max ne '') {
						$self->{JS} .=
							".filter(p => {"
							. "return p.usrCoords[1] >= $fill_min && p.usrCoords[1] <= $fill_max ? true : false" . "})";
					}
					if ($fill_min_y ne '' && $fill_max_y ne '') {
						$self->{JS} .=
							".filter(p => {"
							. "return p.usrCoords[2] >= $fill_min_y && p.usrCoords[2] <= $fill_max_y ? true : false"
							. "})";
					}
					$self->{JS} .=
						";this.dataX = points1.map( p => p.usrCoords[1] ).concat("
						. "points2.map( p => p.usrCoords[1] ).reverse());"
						. "this.dataY = points1.map( p => p.usrCoords[2] ).concat("
						. "points2.map( p => p.usrCoords[2] ).reverse());"
						. "this.dataX.push(points1[0].usrCoords[1]);"
						. "this.dataY.push(points1[0].usrCoords[2]);" . "};"
						. "board.update();";
				}
			} else {
				warn q{Unable to create fill. Missing 'name' attribute.};
			}
		} else {
			warn q{Unable to fill between curves. Other graph has not yet been drawn.};
		}
	}
	return;
}

sub add_multipath {
	my ($self, $data) = @_;

	my @paths      = @{ $data->{paths} };
	my $var        = $data->{function}{var};
	my $curve_name = $data->style('name');
	warn 'Duplicate plot name detected. This will most likely cause issues. Make sure that all names used are unique.'
		if $curve_name && $self->{names}{$curve_name};
	$self->{names}{$curve_name} = 1 if $curve_name;
	my ($plotOptions, $fillOptions) = $self->get_options($data);

	my $count = 0;
	unless ($curve_name) {
		++$count while ($self->{names}{"_plots_internal_$count"});
		$curve_name = "_plots_internal_$count";
		$self->{names}{$curve_name} = 1;
	}

	$count = 0;
	++$count while ($self->{names}{"${curve_name}_$count"});
	my $curve_parts_name = "${curve_name}_$count";
	$self->{names}{$curve_parts_name} = 1;

	$self->{JS} .= "const $curve_parts_name = [\n";

	my $cycle = $data->style('cycle');
	my ($start_x, $start_y) = ('', '');

	for (0 .. $#paths) {
		my $path = $paths[$_];

		if (ref $path eq 'ARRAY') {
			($start_x, $start_y) = (', ' . $path->[0], ', ' . $path->[1]) if $cycle && $_ == 0;
			$self->{JS} .= "board.create('curve', [[$path->[0]], [$path->[1]]], { visible: false }),\n";
			next;
		}

		($start_x, $start_y) =
			(', ' . $path->{Fx}->eval($var => $path->{tmin}), ', ' . $path->{Fy}->eval($var => $path->{tmin}))
			if $cycle && $_ == 0;

		my $xfunction = $data->function_string($path->{Fx}, 'js', $var);
		my $yfunction = $data->function_string($path->{Fy}, 'js', $var);

		$self->{JS} .=
			"board.create('curve', "
			. "[(x) => $xfunction, (x) => $yfunction, $path->{tmin}, $path->{tmax}], { visible: false }),\n";
	}

	$self->{JS} .= "];\n";

	if ($plotOptions) {
		$self->{JS} .= <<~ "END_JS";
			const curve_$curve_name = board.create('curve', [[], []], $plotOptions);
			curve_$curve_name.updateDataArray = function () {
				this.dataX = [].concat(...$curve_parts_name.map((c) => c.points.map((p) => p.usrCoords[1]))$start_x);
				this.dataY = [].concat(...$curve_parts_name.map((c) => c.points.map((p) => p.usrCoords[2]))$start_y);
			};
			END_JS
	}
	if ($fillOptions) {
		$self->{JS} .= <<~ "END_JS";
			const fill_$curve_name = board.create('curve', [[], []], $fillOptions);
			fill_$curve_name.updateDataArray = function () {
				this.dataX = [].concat(...$curve_parts_name.map((c) => c.points.map((p) => p.usrCoords[1])));
				this.dataY = [].concat(...$curve_parts_name.map((c) => c.points.map((p) => p.usrCoords[2])));
			};
			END_JS
	}
	return;
}

sub add_point {
	my ($self, $data, $x, $y, $size, $strokeWidth, $mark) = @_;
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
		strokeWidth => $strokeWidth,
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
		$self->add_point(
			$data, $data->x($_), $data->y($_),
			$data->style('mark_size') || 2,
			$data->style('width') || 2, $mark
		);
	}
	return;
}

sub add_vectorfield {
	my ($self, $data) = @_;
	my $f         = $data->{function};
	my $xfunction = $data->function_string($f->{Fx}, 'js', $f->{xvar}, $f->{yvar});
	my $yfunction = $data->function_string($f->{Fy}, 'js', $f->{xvar}, $f->{yvar});

	if ($xfunction ne '' && $yfunction ne '') {
		my ($options) = $self->get_options(
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
		warn 'Vector field not created due to missing JavaScript functions.';
	}
}

sub add_circle {
	my ($self, $data) = @_;
	my $x = $data->x(0);
	my $y = $data->y(0);
	my $r = $data->style('radius');
	my ($circleOptions, $fillOptions) = $self->get_options($data);

	$self->{JS} .= "board.create('circle', [[$x, $y], $r], $circleOptions);" if $circleOptions;
	$self->{JS} .= "board.create('circle', [[$x, $y], $r], $fillOptions);"   if $fillOptions;
	return;
}

sub add_arc {
	my ($self, $data)              = @_;
	my ($x1, $y1)                  = ($data->x(0), $data->y(0));
	my ($x2, $y2)                  = ($data->x(1), $data->y(1));
	my ($x3, $y3)                  = ($data->x(2), $data->y(2));
	my ($arcOptions, $fillOptions) = $self->get_options(
		$data,
		anglePoint  => { visible => 0 },
		center      => { visible => 0 },
		radiusPoint => { visible => 0 },
	);

	# JSXGraph arcs cannot make a 360 degree revolution.  So in the case that the start and end point are the same,
	# move the end point back around the circle a tiny amount.
	if ($x2 == $x3 && $y2 == $y3) {
		my $theta = atan2($y2 - $y1, $x2 - $x1) + 2 * 3.14159265358979 - 0.0001;
		$x3 = $x1 + cos($theta);
		$y3 = $y1 + sin($theta);
	}

	$self->{JS} .= "board.create('arc', [[$x1, $y1], [$x2, $y2], [$x3, $y3]], $arcOptions);"  if $arcOptions;
	$self->{JS} .= "board.create('arc', [[$x1, $y1], [$x2, $y2], [$x3, $y3]], $fillOptions);" if $fillOptions;
	return;
}

sub draw {
	my $self  = shift;
	my $plots = $self->plots;
	$self->{name} = $plots->get_image_name =~ s/-/_/gr;

	# Plot data, vector/slope fields, and points.  Note that points
	# are in a separate data call so that they are drawn last.
	for my $data ($plots->data('function', 'dataset', 'circle', 'arc', 'multipath', 'vectorfield'),
		$plots->data('point'))
	{
		if ($data->name eq 'circle') {
			$self->add_circle($data);
		} elsif ($data->name eq 'arc') {
			$self->add_arc($data);
		} elsif ($data->name eq 'multipath') {
			$self->add_multipath($data);
		} elsif ($data->name eq 'vectorfield') {
			$self->add_vectorfield($data);
		} else {
			$self->add_curve($data) unless $data->name eq 'point';
			$self->add_points($data);
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

		$self->add_point($stamp, $x, $y, $size, $stamp->style('width') || 2, $mark);
	}

	# Labels
	for my $label ($plots->data('label')) {
		my $str         = $label->style('label');
		my $x           = $label->x(0);
		my $y           = $label->y(0);
		my $fontsize    = $label->style('fontsize') || 'normalsize';
		my $h_align     = $label->style('h_align')  || 'center';
		my $v_align     = $label->style('v_align')  || 'middle';
		my $anchor      = $label->style('anchor');
		my $rotate      = $label->style('rotate');
		my $padding     = $label->style('padding') || 4;
		my $textOptions = Mojo::JSON::encode_json({
			fontSize => {
				tiny       => 8,
				small      => 10,
				normalsize => 12,
				medium     => 12,    # deprecated
				large      => 14,
				Large      => 16,
				giant      => 16,    # deprecated
				Large      => 16,
				huge       => 20,
				Huge       => 23
			}->{$fontsize},
			strokeColor => $self->get_color($label->style('color')),
			$anchor ne ''
			? (angleAnchor => $anchor, anchorX => 'middle', anchorY => 'middle')
			: (anchorX => $h_align eq 'center' ? 'middle' : $h_align, anchorY => $v_align),
			$rotate ? (rotate => $rotate) : (),
			cssStyle   => "line-height: 1; padding: ${padding}px;",
			useMathJax => 1,
		});
		$textOptions = "JXG.merge($textOptions, " . Mojo::JSON::encode_json($label->style('jsx_options')) . ')'
			if $label->style('jsx_options');

		$self->{JS} .= "plot.createLabel($x, $y, '$str', $textOptions);";
	}

	# JSXGraph only produces HTML graphs and uses TikZ for hadrcopy.
	return $self->HTML;
}

1;
