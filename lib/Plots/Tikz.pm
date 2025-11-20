
=head1 DESCRIPTION

This is the code that takes a C<Plots::Plot> and creates the tikz code for generation.

See L<plots.pl> for more details.

=cut

package Plots::Tikz;

use strict;
use warnings;

sub new {
	my ($class, $plots) = @_;
	my $image = LaTeXImage->new;
	$image->environment(['tikzpicture']);
	$image->svgMethod(eval('$main::envir{latexImageSVGMethod}')           // 'dvisvgm');
	$image->convertOptions(eval('$main::envir{latexImageConvertOptions}') // { input => {}, output => {} });
	$image->ext($plots->ext);
	$image->tikzLibraries('arrows.meta,plotmarks,calc,spath3');
	$image->texPackages(['pgfplots']);

	# Set the pgfplots compatibility, add the pgfplots fillbetween library, define a save
	# box that is used to wrap the axes in a nice rectangle frame with a white background, and redefine
	# standard layers to include a background layer for the background.
	# Note that "axis tick labels" is moved after "pre main" and "main" in the standard layer set. That is different
	# than the pgfplots defaults, but is consistent with where JSXGraph places them, and is better than what pgplots
	# does.  Axis tick labels are textual elements that should be in front of the things that are drawn and together
	# with the "axis descriptions".
	$image->addToPreamble( <<~ 'END_PREAMBLE');
		\usepgfplotslibrary{fillbetween}
		\newsavebox{\axesBox}
		\pgfplotsset{
			compat = 1.18,
			layers/standard/.define layer set = {
				background,
				axis background,
				axis grid,
				axis ticks,
				axis lines,
				pre main,
				main,
				axis tick labels,
				axis descriptions,
				axis foreground
			}{
				grid style = { /pgfplots/on layer = axis grid },
				tick style = { /pgfplots/on layer = axis ticks },
				axis line style = { /pgfplots/on layer = axis lines },
				label style = { /pgfplots/on layer = axis descriptions },
				legend style = { /pgfplots/on layer = axis descriptions },
				title style = { /pgfplots/on layer = axis descriptions },
				colorbar style = { /pgfplots/on layer = axis descriptions },
				ticklabel style = { /pgfplots/on layer = axis tick labels },
				axis background@ style = { /pgfplots/on layer = axis background },
				3d box foreground style = { /pgfplots/on layer = axis foreground }
			},
		    layers/axis on top/.define layer set = {
		        background,
		        axis background,
		        pre main,
		        main,
		        axis grid,
		        axis ticks,
		        axis lines,
		        axis tick labels,
		        axis descriptions,
		        axis foreground
		    }{ /pgfplots/layers/standard }
		}
		END_PREAMBLE

	return bless { image => $image, plots => $plots, colors => {}, names => { xaxis => 1 } }, $class;
}

sub plots {
	my $self = shift;
	return $self->{plots};
}

sub im {
	my $self = shift;
	return $self->{image};
}

sub get_color {
	my ($self, $color) = @_;
	return '' if $self->{colors}{$color};
	my $colorParts = $self->plots->colors($color);
	return '' unless ref $colorParts eq 'ARRAY';    # Try to use the color by name if it wasn't defined.
	my ($r, $g, $b) = @$colorParts;
	$self->{colors}{$color} = 1;
	return "\\definecolor{$color}{RGB}{$r,$g,$b}\n";
}

sub get_mark {
	my ($self, $mark) = @_;
	return {
		circle        => '*',
		closed_circle => '*',
		open_circle   => '*, mark options={fill=white}',
		square        => 'square*',
		open_square   => 'square*, mark options={fill=white}',
		plus          => '+',
		times         => 'x',
		bar           => '|',
		dash          => '-',
		triangle      => 'triangle*',
		open_triangle => 'triangle*, mark options={fill=white}',
		diamond       => 'diamond*',
		open_diamond  => 'diamond*, mark options={fill=white}',
	}->{$mark};
}

# This is essentially copied from contextFraction.pl, and is exactly copied from parserGraphTool.pl.
# FIXME: Clearly there needs to be a single version of this somewhere that all three can use.
sub continuedFraction {
	my ($x) = @_;

	my $step = $x;
	my $n    = int($step);
	my ($h0, $h1, $k0, $k1) = (1, $n, 0, 1);

	while ($step != $n) {
		$step = 1 / ($step - $n);
		$n    = int($step);
		my ($newh, $newk) = ($n * $h1 + $h0, $n * $k1 + $k0);
		last if $newk > 10**8;    # Bail if the denominator is skyrocketing out of control.
		($h0, $h1, $k0, $k1) = ($h1, $newh, $k1, $newk);
	}

	return ($h1, $k1);
}

sub formatTickLabelText {
	my ($self, $value, $axis) = @_;
	my $tickFormat = $self->plots->axes->$axis('tick_label_format');
	if ($tickFormat eq 'fraction' || $tickFormat eq 'mixed') {
		my ($num, $den) = continuedFraction(abs($value));
		if ($num && $den != 1 && !($num == 1 && $den == 1)) {
			if ($tickFormat eq 'fraction' || $num < $den) {
				$value = ($value < 0 ? '-' : '') . "\\frac{$num}{$den}";
			} else {
				my $int       = int($num / $den);
				my $properNum = $num % $den;
				$value = ($value < 0 ? '-' : '') . "$int\\frac{$properNum}{$den}";
			}
		}
	} elsif ($tickFormat eq 'scinot') {
		my ($mantissa, $exponent) = split('e', sprintf('%e', $value));
		$value =
			Plots::Plot::pgCall('Round', $mantissa, $self->plots->axes->$axis('tick_label_digits') // 2)
			. "\\cdot 10^{$exponent}";
	} else {
		$value =
			sprintf('%f', Plots::Plot::pgCall('Round', $value, $self->plots->axes->$axis('tick_label_digits') // 2));
		if ($value =~ /\./) {
			$value =~ s/0*$//;
			$value =~ s/\.$//;
		}
	}
	my $scaleSymbol = $self->plots->axes->$axis('tick_scale_symbol');
	return '\\('
		. ($value eq '0' ? '0'
			: $scaleSymbol ? ($value eq '1' ? $scaleSymbol : $value eq '-1' ? "-$scaleSymbol" : "$value$scaleSymbol")
			:                $value) . '\\)';
}

sub generate_axes {
	my ($self, $plotContents) = @_;
	my $plots = $self->plots;
	my $axes  = $plots->axes;
	my $grid  = $axes->grid;
	my ($xmin, $ymin, $xmax, $ymax) = $axes->bounds;
	my ($axes_width, $axes_height) = $plots->size;
	my $show_grid = $axes->style('show_grid');
	my $xvisible  = $axes->xaxis('visible');
	my $yvisible  = $axes->yaxis('visible');
	my $xmajor    = $show_grid && $grid->{xmajor} ? 'true' : 'false';
	my $xminor    = $show_grid && $xmajor eq 'true' && $grid->{xminor_grids} && $grid->{xminor} > 0 ? 'true' : 'false';
	my $ymajor    = $show_grid && $grid->{ymajor} ? 'true' : 'false';
	my $yminor    = $show_grid && $ymajor eq 'true' && $grid->{yminor_grids} && $grid->{yminor} > 0 ? 'true' : 'false';
	my $grid_color     = $axes->style('grid_color');
	my $grid_color_def = $self->get_color($grid_color);
	my $grid_alpha     = $axes->style('grid_alpha') / 100;
	my $xaxis_location = $axes->xaxis('location');
	my $xaxis_pos      = $xaxis_location eq 'middle' ? $axes->xaxis('position') : 0;
	my $yaxis_location = $axes->yaxis('location');
	my $yaxis_pos      = $yaxis_location eq 'center'      ? $axes->yaxis('position')   : 0;
	my $axis_on_top    = $axes->style('axis_on_top')      ? "axis on top,\n"           : '';
	my $negativeArrow  = $axes->style('axes_arrows_both') ? 'Latex[{round,scale=1.6}]' : '';
	my $tikz_options   = $axes->style('tikz_options') // '';

	my $xlabel = $xvisible ? $axes->xaxis('label') : '';
	my $xaxis_style =
		$xvisible
		? ",\nx axis line style={$negativeArrow-Latex[{round,scale=1.6}]}"
		: ",\nx axis line style={draw=none},\nextra y ticks={0}";
	my $xtick_style =
		$xvisible && $axes->xaxis('show_ticks') ? ",\nx tick style={line width=0.6pt}" : ",\nx tick style={draw=none}";

	my $ylabel = $yvisible ? $axes->yaxis('label') : '';
	my $yaxis_style =
		$yvisible
		? ",\ny axis line style={$negativeArrow-Latex[{round,scale=1.6}]}"
		: ",\ny axis line style={draw=none},\nextra x ticks={0}";
	my $ytick_style =
		$yvisible && $axes->yaxis('show_ticks') ? ",\ny tick style={line width=0.6pt}" : ",\ny tick style={draw=none}";

	my $x_tick_distance = $axes->xaxis('tick_distance');
	my $x_tick_scale    = $axes->xaxis('tick_scale') || 1;

	my @xticks =
		grep { $_ > $xmin && $_ < $xmax }
		map  { -$_ * $x_tick_distance * $x_tick_scale }
		reverse(1 .. -$xmin / ($x_tick_distance * $x_tick_scale));
	push(@xticks, 0) if $xmin < 0 && $xmax > 0;
	push(@xticks,
		grep { $_ > $xmin && $_ < $xmax }
		map { $_ * $x_tick_distance * $x_tick_scale } (1 .. $xmax / ($x_tick_distance * $x_tick_scale)));

	my $xtick_labels =
		$xvisible
		&& $axes->xaxis('show_ticks')
		&& $axes->xaxis('tick_labels')
		? (",\nxticklabel shift=9pt,\nxticklabel style={anchor=center},\nxticklabels={"
			. join(',', map { $self->formatTickLabelText($_ / $x_tick_scale, 'xaxis') } @xticks) . '}')
		: ",\nxticklabel=\\empty";

	my @xminor_ticks;
	if ($grid->{xminor} > 0) {
		my @majorTicks = @xticks;
		unshift(@majorTicks, ($majorTicks[0] // $xmin) - $x_tick_distance * $x_tick_scale);
		push(@majorTicks, ($majorTicks[-1] // $xmax) + $x_tick_distance * $x_tick_scale);
		my $x_minor_delta = $x_tick_distance * $x_tick_scale / ($grid->{xminor} + 1);
		for my $tickIndex (0 .. $#majorTicks - 1) {
			push(@xminor_ticks,
				grep { $_ > $xmin && $_ < $xmax }
				map { $majorTicks[$tickIndex] + $_ * $x_minor_delta } 1 .. $grid->{xminor});
		}
	}

	my $y_tick_distance = $axes->yaxis('tick_distance');
	my $y_tick_scale    = $axes->yaxis('tick_scale') || 1;

	my @yticks =
		grep { $_ > $ymin && $_ < $ymax }
		map  { -$_ * $y_tick_distance * $y_tick_scale }
		reverse(1 .. -$ymin / ($y_tick_distance * $y_tick_scale));
	push(@yticks, 0) if $ymin < 0 && $ymax > 0;
	push(@yticks,
		grep { $_ > $ymin && $_ < $ymax }
		map { $_ * $y_tick_distance * $y_tick_scale } (1 .. $ymax / ($y_tick_distance * $y_tick_scale)));

	my $ytick_labels =
		$yvisible
		&& $axes->yaxis('show_ticks')
		&& $axes->yaxis('tick_labels')
		? (",\nyticklabel shift=-3pt,\nyticklabels={"
			. join(',', map { $self->formatTickLabelText($_ / $y_tick_scale, 'yaxis') } @yticks) . '}')
		: ",\nyticklabel=\\empty";

	my @yminor_ticks;
	if ($grid->{yminor} > 0) {
		my @majorTicks = @yticks;
		unshift(@majorTicks, ($majorTicks[0] // $ymin) - $y_tick_distance * $y_tick_scale);
		push(@majorTicks, ($majorTicks[-1] // $ymax) + $y_tick_distance * $y_tick_scale);
		my $y_minor_delta = $y_tick_distance * $y_tick_scale / ($grid->{yminor} + 1);
		for my $tickIndex (0 .. $#majorTicks - 1) {
			push(@yminor_ticks,
				grep { $_ > $ymin && $_ < $ymax }
				map { $majorTicks[$tickIndex] + $_ * $y_minor_delta } 1 .. $grid->{yminor});
		}
	}

	my $xaxis_plot = ($ymin <= 0 && $ymax >= 0) ? "\\path[name path=xaxis] ($xmin, 0) -- ($xmax, 0);" : '';
	$xaxis_pos = $xaxis_pos ? ",\naxis x line shift=" . (($ymin > 0 ? $ymin : $ymax < 0 ? $ymax : 0) - $xaxis_pos) : '';
	$yaxis_pos = $yaxis_pos ? ",\naxis y line shift=" . (($xmin > 0 ? $xmin : $xmax < 0 ? $xmax : 0) - $yaxis_pos) : '';

	my $roundedCorners = $plots->{rounded_corners} ? 'rounded corners = 10pt' : '';
	my $left =
		$yvisible && ($yaxis_location eq 'left' || $yaxis_location eq 'box' || $xmin == $axes->yaxis('position'))
		? 'outer west'
		: 'west';
	my $right = $yvisible && ($yaxis_location eq 'right' || $xmax == $axes->yaxis('position')) ? 'outer east' : 'east';
	my $lower =
		$xvisible && ($xaxis_location eq 'bottom' || $xaxis_location eq 'box' || $ymin == $axes->xaxis('position'))
		? 'outer south'
		: 'south';
	my $upper = $xvisible && ($xaxis_location eq 'top' || $ymax == $axes->xaxis('position')) ? 'outer north' : 'north';

	# The savebox only actually saves the main layer.  All other layers are actually drawn when the savebox is saved.
	# So clipping of anything drawn on any other layer has to be done when things are drawn on the other layers.  The
	# axisclippath is used for this. The main layer is clipped at the end when the savebox is used.
	my $tikzCode = <<~ "END_TIKZ";
		\\pgfplotsset{set layers=${\($axes->style('axis_on_top') ? 'axis on top' : 'standard')}}%
		$grid_color_def
		\\savebox{\\axesBox}{
			\\Large
			\\begin{axis}
			[
				trig format plots=rad,
				scale only axis,
				height=$axes_height,
				width=$axes_width,
				${axis_on_top}axis x line=$xaxis_location$xaxis_pos$xaxis_style,
				axis y line=$yaxis_location$yaxis_pos$yaxis_style,
				xlabel={$xlabel},
				ylabel={$ylabel},
				xtick={${\(join(',', @xticks))}}$xtick_style$xtick_labels,
				minor xtick={${\(join(',', @xminor_ticks))}},
				ytick={${\(join(',', @yticks))}}$ytick_style$ytick_labels,
				minor ytick={${\(join(',', @yminor_ticks))}},
				xtick scale label code/.code={},
				ytick scale label code/.code={},
				major tick length=0.3cm,
				minor tick length=0.2cm,
				xmajorgrids=$xmajor,
				xminorgrids=$xminor,
				ymajorgrids=$ymajor,
				yminorgrids=$yminor,
				grid style={$grid_color, opacity=$grid_alpha},
				xmin=$xmin,
				xmax=$xmax,
				ymin=$ymin,
				ymax=$ymax,$tikz_options
			]
			$xaxis_plot
			\\newcommand{\\axisclippath}{(current axis.south west) [${\(
				$roundedCorners && ($lower !~ /^outer/ || $right !~ /^outer/) ? $roundedCorners : 'sharp corners'
			)}] -- (current axis.south east) [${\(
				$roundedCorners && ($upper !~ /^outer/ || $right !~ /^outer/) ? $roundedCorners : 'sharp corners'
			)}] -- (current axis.north east) [${\(
				$roundedCorners && ($upper !~ /^outer/ || $left !~ /^outer/) ? $roundedCorners : 'sharp corners'
			)}] -- (current axis.north west) [${\(
				$roundedCorners && ($lower !~ /^outer/ || $left !~ /^outer/) ? $roundedCorners : 'sharp corners'
			)}] -- cycle}
		END_TIKZ

	$tikzCode .= $plotContents;
	$tikzCode .= $plots->{extra_tikz_code} if $plots->{extra_tikz_code};

	$tikzCode .= <<~ "END_TIKZ";
			\\end{axis}
		}
		\\pgfresetboundingbox
		\\begin{pgfonlayer}{background}
			\\filldraw[draw = DarkBlue, fill = white, $roundedCorners, line width = 0.5pt]
				(\$(current axis.$left |- current axis.$lower)-(0.25pt,0.25pt)\$)
				rectangle
				(\$(current axis.$right |- current axis.$upper)+(0.25pt,0.25pt)\$);
		\\end{pgfonlayer}
		\\begin{scope}
			\\clip[$roundedCorners]
				(\$(current axis.$left |- current axis.$lower)-(0.25pt,0.25pt)\$)
				rectangle
				(\$(current axis.$right |- current axis.$upper)+(0.25pt,0.25pt)\$);
			\\usebox{\\axesBox}
		\\end{scope}
		\\begin{pgfonlayer}{axis foreground}
			\\draw[draw = DarkBlue, $roundedCorners, line width = 0.5pt, use as bounding box]
				(\$(current axis.$left |- current axis.$lower)-(0.25pt,0.25pt)\$)
				rectangle
				(\$(current axis.$right |- current axis.$upper)+(0.25pt,0.25pt)\$);
		\\end{pgfonlayer}
		END_TIKZ
	chop($tikzCode);

	return $tikzCode;
}

sub get_options {
	my ($self, $data) = @_;

	my $fill      = $data->style('fill') || 'none';
	my $drawLayer = $data->style('layer');
	my $fillLayer = $data->style('fill_layer') || $drawLayer;
	my $marks     = $self->get_mark($data->style('marks'));

	my $drawFillSeparate =
		$fill eq 'self'
		&& ($data->style('linestyle') ne 'none' || $marks)
		&& defined $fillLayer
		&& (!defined $drawLayer || $drawLayer ne $fillLayer);

	my (@drawOptions, @fillOptions);

	if ($data->style('linestyle') ne 'none' || $marks) {
		my $linestyle = {
			none               => 'draw=none',
			solid              => 'solid',
			dashed             => 'dash={on 11pt off 8pt phase 6pt}',
			short_dashes       => 'dash pattern={on 6pt off 3pt}',
			long_dashes        => 'dash={on 20pt off 15pt phase 10pt}',
			dotted             => 'dotted',
			long_medium_dashes => 'dash={on 20pt off 7pt on 11pt off 7pt phase 10pt}',
		}->{ ($data->style('linestyle') || 'solid') =~ s/ /_/gr }
			|| 'solid';
		push(@drawOptions, $linestyle);

		my $width = $data->style('width');
		push(@drawOptions, "line width=${width}pt", "color=" . ($data->style('color') || 'default_color'));

		if ($linestyle ne 'draw=none') {
			my $start = $data->style('start_mark') || '';
			if ($start =~ /circle/) {
				$start =
					'{Circle[sep=-1.196825pt -1.595769' . ($start eq 'open_circle' ? ', open,fill=white' : '') . ']}';
			} elsif ($start eq 'arrow') {
				my $arrow_width = $width * ($data->style('arrow_size') || 8);
				$start = "{Stealth[length=${arrow_width}pt 1,width'=0pt 1,inset'=0pt 0.5]}";
			} else {
				$start = '';
			}

			my $end = $data->style('end_mark') || '';
			if ($end =~ /circle/) {
				$end = '{Circle[sep=-1.196825pt -1.595769' . ($end eq 'open_circle' ? ', open,fill=white' : '') . ']}';
			} elsif ($end eq 'arrow') {
				my $arrow_width = $width * ($data->style('arrow_size') || 8);
				$end = "{Stealth[length=${arrow_width}pt 1,width'=0pt 1,inset'=0pt 0.5]}";
			} else {
				$end = '';
			}

			push(@drawOptions, "$start-$end") if $start || $end;
		}

		if ($marks) {
			push(@drawOptions, "mark=$marks");

			my $mark_size = $data->style('mark_size') || 0;
			if ($mark_size) {
				$mark_size = $mark_size + $width / 2 if $marks =~ /^[*+]/;
				$mark_size = $mark_size + $width     if $marks eq 'x';
				push(@drawOptions, "mark size=${mark_size}pt");
			}
		}

		push(@drawOptions, 'smooth') if $data->style('tikz_smooth');
	}

	my $tikz_options = $data->style('tikz_options');

	if ($drawFillSeparate) {
		my $fill_color   = $data->style('fill_color')   || $data->style('color') || 'default_color';
		my $fill_opacity = $data->style('fill_opacity') || 0.5;
		push(@fillOptions, 'draw=none', "fill=$fill_color", "fill opacity=$fill_opacity");
		push(@fillOptions, 'smooth')      if $data->style('tikz_smooth');
		push(@fillOptions, $tikz_options) if $tikz_options;
	} elsif ($fill eq 'self') {
		if (!@drawOptions) {
			push(@drawOptions, 'draw=none');
			$drawLayer = $fillLayer if defined $fillLayer;
		}
		my $fill_color   = $data->style('fill_color')   || $data->style('color') || 'default_color';
		my $fill_opacity = $data->style('fill_opacity') || 0.5;
		push(@drawOptions, "fill=$fill_color", "fill opacity=$fill_opacity");
	} elsif (!@drawOptions) {
		push(@drawOptions, 'draw=none');
	}

	push(@drawOptions, $tikz_options) if $tikz_options;

	return ([ join(', ', @drawOptions), $drawLayer ], @fillOptions ? [ join(', ', @fillOptions), $fillLayer ] : undef);
}

sub draw_on_layer {
	my ($self, $plot, $layer) = @_;
	my $tikzCode;
	$tikzCode .= "\\begin{scope}[on layer=$layer]\\begin{pgfonlayer}{$layer}\\clip\\axisclippath;\n" if $layer;
	$tikzCode .= $plot;
	$tikzCode .= "\\end{pgfonlayer}\\end{scope}\n" if $layer;
	return $tikzCode;
}

sub draw {
	my $self  = shift;
	my $plots = $self->plots;

	# Reset colors just in case.
	$self->{colors} = {};

	my $tikzCode = '';

	# Plot data, vector/slope fields, and points.  Note that points
	# are in a separate data call so that they are drawn last.
	for my $data ($plots->data('function', 'dataset', 'circle', 'arc', 'multipath', 'vectorfield'),
		$plots->data('point'))
	{
		my $color = $data->style('color') || 'default_color';
		my $layer = $data->style('layer');

		$tikzCode .= $self->get_color($color);

		if ($data->name eq 'vectorfield') {
			my $f         = $data->{function};
			my $xfunction = $data->function_string($f->{Fx}, 'PGF', $f->{xvar}, $f->{yvar});
			my $yfunction = $data->function_string($f->{Fy}, 'PGF', $f->{xvar}, $f->{yvar});
			if ($xfunction ne '' && $yfunction ne '') {
				my $width        = $data->style('width');
				my $scale        = $data->style('scale');
				my $arrows       = $data->style('slopefield')   ? ''                                  : ', -stealth';
				my $tikz_options = $data->style('tikz_options') ? ', ' . $data->style('tikz_options') : '';
				$data->update_min_max;

				if ($data->style('normalize') || $data->style('slopefield')) {
					my $xtmp = "($xfunction)/sqrt(($xfunction)^2 + ($yfunction)^2)";
					$yfunction = "($yfunction)/sqrt(($xfunction)^2 + ($yfunction)^2)";
					$xfunction = $xtmp;
				}

				my $yDelta   = ($f->{ymax} - $f->{ymin}) / $f->{ysteps};
				my $next     = $f->{ymin} + $yDelta;
				my $last     = $f->{ymax} + $yDelta / 2;    # Adjust upward incase of rounding error in the foreach.
				my $xSamples = $f->{xsteps} + 1;
				$tikzCode .= $self->draw_on_layer(
					"\\foreach \\i in {$f->{ymin}, $next, ..., $last}\n"
						. "\\addplot[color=$color, line width=${width}pt$arrows, "
						. "quiver={u=$xfunction, v=$yfunction, scale arrows=$scale}, samples=$xSamples, "
						. "domain=$f->{xmin}:$f->{xmax}$tikz_options] {\\i};\n",
					$layer
				);
			} else {
				warn "Vector field not created due to missing PGF functions.";
			}
			next;
		}

		my $curve_name = $data->style('name');
		warn 'Duplicate plot name detected. This will most likely cause issues. '
			. 'Make sure that all names used are unique.'
			if $curve_name && $self->{names}{$curve_name};
		$self->{names}{$curve_name} = 1 if $curve_name;

		my $count = 0;
		unless ($curve_name) {
			++$count while ($self->{names}{"_plots_internal_$count"});
			$curve_name = "_plots_internal_$count";
			$self->{names}{$curve_name} = 1;
		}

		my $fill       = $data->style('fill') || 'none';
		my $fill_color = $data->style('fill_color') || $data->style('color') || 'default_color';
		$tikzCode .= $self->get_color($fill_color) unless $fill eq 'none';

		my ($draw_options, $fill_options) = $self->get_options($data);

		if ($data->name eq 'circle') {
			my $x = $data->x(0);
			my $y = $data->y(0);
			my $r = $data->style('radius');
			$tikzCode .= $self->draw_on_layer(
				"\\draw[name path=$curve_name, $draw_options->[0]] (axis cs:$x,$y) circle[radius=$r];\n",
				$draw_options->[1]);
			$tikzCode .=
				$self->draw_on_layer("\\fill[$fill_options->[0]] [spath/use=$curve_name];\n", $fill_options->[1])
				if $fill_options;
			next;
		}
		if ($data->name eq 'arc') {
			my ($x1, $y1) = ($data->x(0), $data->y(0));
			my ($x2, $y2) = ($data->x(1), $data->y(1));
			my ($x3, $y3) = ($data->x(2), $data->y(2));
			my $r      = sqrt(($x2 - $x1)**2 + ($y2 - $y1)**2);
			my $theta1 = 180 * atan2($y2 - $y1, $x2 - $x1) / 3.14159265358979;
			my $theta2 = 180 * atan2($y3 - $y1, $x3 - $x1) / 3.14159265358979;
			$theta2 += 360 if $theta2 <= $theta1;
			$tikzCode .= $self->draw_on_layer(
				"\\draw[name path=$curve_name, $draw_options->[0]] (axis cs:$x2,$y2) "
					. "arc[start angle=$theta1, end angle=$theta2, radius = $r];\n",
				$draw_options->[1]
			);
			$tikzCode .=
				$self->draw_on_layer("\\fill[$fill_options->[0]] [spath/use=$curve_name];\n", $fill_options->[1])
				if $fill_options;
			next;
		}

		my $plot;
		my $plot_options = '';

		if ($data->name eq 'function') {
			my $f = $data->{function};
			if (ref($f->{Fx}) ne 'CODE' && $f->{xvar} eq $f->{Fx}->string) {
				my $function = $data->function_string($f->{Fy}, 'PGF', $f->{xvar});
				if ($function ne '') {
					$data->update_min_max;
					my ($axes_xmin, undef, $axes_xmax) = $plots->axes->bounds;
					my $min = $data->style('continue') || $data->style('continue_left')  ? $axes_xmin : $f->{xmin};
					my $max = $data->style('continue') || $data->style('continue_right') ? $axes_xmax : $f->{xmax};
					$plot_options .= ", data cs=polar" if $data->style('polar');
					$plot_options .= ", domain=$min:$max, samples=$f->{xsteps}";
					$plot = "{$function}";
				}
			} else {
				my $xfunction = $data->function_string($f->{Fx}, 'PGF', $f->{xvar});
				my $yfunction = $data->function_string($f->{Fy}, 'PGF', $f->{xvar});
				if ($xfunction ne '' && $yfunction ne '') {
					$data->update_min_max;
					$plot_options .= ", domain=$f->{xmin}:$f->{xmax}, samples=$f->{xsteps}";
					$plot = "({$xfunction}, {$yfunction})";
				}
			}
		} elsif ($data->name eq 'multipath') {
			my $var   = $data->{function}{var};
			my @paths = @{ $data->{paths} };
			my @tikzFunctionx;
			my @tikzFunctiony;

			# This saves the internal path names and the endpoints of the paths. The endpoints are used to determine if
			# the paths meet at the endpoints. If the end of one path is not at the same place that the next path
			# starts, then the line segment from the first path end to the next path start is inserted.
			my @pathData;

			my $count = 0;

			for (0 .. $#paths) {
				my $path = $paths[$_];

				++$count while $self->{names}{"${curve_name}_$count"};
				push(@pathData, ["${curve_name}_$count"]);
				$self->{names}{ $pathData[-1][0] } = 1;

				if (ref $path eq 'ARRAY') {
					$tikzCode .=
						"\\addplot[name path=$pathData[-1][0], draw=none] coordinates {($path->[0], $path->[1])};\n";
					push(@{ $pathData[-1] }, @$path, @$path);
					next;
				}

				push(
					@{ $pathData[-1] },
					$path->{Fx}->eval($var => $path->{tmin}),
					$path->{Fy}->eval($var => $path->{tmin}),
					$path->{Fx}->eval($var => $path->{tmax}),
					$path->{Fy}->eval($var => $path->{tmax})
				);

				my $xfunction = $data->function_string($path->{Fx}, 'PGF', $var);
				my $yfunction = $data->function_string($path->{Fy}, 'PGF', $var);

				my $steps = $path->{steps} // $data->{function}{steps};

				$tikzCode .=
					"\\addplot[name path=$pathData[-1][0], draw=none, domain=$path->{tmin}:$path->{tmax}, "
					. "samples=$steps] ({$xfunction}, {$yfunction});\n";
			}

			$tikzCode .= "\\path[name path=$curve_name] " . join(
				' ',
				map {
					(
						$_ == 0 || ($pathData[ $_ - 1 ][3] == $pathData[$_][1]
							&& $pathData[ $_ - 1 ][4] == $pathData[$_][2])
						? ''
						: "-- (spath cs:$pathData[$_ - 1][0] 1) -- (spath cs:$pathData[$_][0] 0) "
						)
						. "[spath/append no move=$pathData[$_][0]]"
				} 0 .. $#pathData
			) . ($data->style('cycle') ? '-- cycle' : '') . ";\n";

			$plot = 'skip';
			$tikzCode .=
				$self->draw_on_layer("\\draw[$draw_options->[0], spath/use=$curve_name];\n", $draw_options->[1]);
		}

		unless ($plot) {
			$data->gen_data;
			$plot = 'coordinates {'
				. join(' ', map { '(' . $data->x($_) . ',' . $data->y($_) . ')'; } (0 .. $data->size - 1)) . '}';
		}

		# 'skip' is a special value of $plot for a multipath which has already been drawn.
		$tikzCode .= $self->draw_on_layer("\\addplot[name path=$curve_name, $draw_options->[0]$plot_options] $plot;\n",
			$draw_options->[1])
			unless $plot eq 'skip';
		$tikzCode .= $self->draw_on_layer("\\fill[$fill_options->[0]] [spath/use=$curve_name];\n", $fill_options->[1])
			if $fill_options;

		unless ($fill eq 'none' || $fill eq 'self') {
			if ($self->{names}{$fill}) {
				# Make sure this is the name from the data style attribute, and not an internal name.
				my $name = $data->style('name');
				if ($name) {
					my $opacity      = $data->style('fill_opacity') || 0.5;
					my $fill_min     = $data->style('fill_min');
					my $fill_max     = $data->style('fill_max');
					my $fill_min_y   = $data->style('fill_min_y');
					my $fill_max_y   = $data->style('fill_max_y');
					my $fill_reverse = $data->style('fill_reverse');
					my $fill_range =
						$fill_min ne '' && $fill_max ne '' && $fill_min_y ne '' && $fill_max_y ne ''
						? ", soft clip={($fill_min, $fill_min_y) rectangle ($fill_max, $fill_max_y)}"
						: $fill_min ne ''   && $fill_max ne ''   ? ", soft clip={domain=$fill_min:$fill_max}"
						: $fill_min_y ne '' && $fill_max_y ne '' ? ", soft clip={domain y=$fill_min_y:$fill_max_y}"
						:                                          '';
					my $fill_layer = $data->style('fill_layer') || $layer;
					my $reverse    = $fill_reverse eq '' ? '' : $fill_reverse ? ', reverse' : 'reverse=false';
					$tikzCode .=
						"\\begin{scope}[/tikz/fill between/on layer=$fill_layer]\\begin{pgfonlayer}{$fill_layer}"
						. "\\clip\\axisclippath;\n"
						if $fill_layer;
					$tikzCode .=
						"\\addplot[$fill_color, fill opacity=$opacity] "
						. "fill between[of=$name and $fill$fill_range$reverse];\n";
					$tikzCode .= "\\end{pgfonlayer}\\end{scope}\n" if $fill_layer;
				} else {
					warn q{Unable to create fill. Missing 'name' attribute.};
				}
			} else {
				warn q{Unable to fill between curves. Other graph has not yet been drawn.};
			}
		}
	}

	# Stamps
	for my $stamp ($plots->data('stamp')) {
		my $mark = $self->get_mark($stamp->style('symbol')) // '*';
		next unless $mark;

		my $color     = $stamp->style('color') || 'default_color';
		my $x         = $stamp->x(0);
		my $y         = $stamp->y(0);
		my $lineWidth = $stamp->style('width') || 2;
		my $r = ($stamp->style('radius') || 4) + ($mark =~ /^[*+]/ ? $lineWidth / 2 : $mark eq 'x' ? $lineWidth : 0);
		$tikzCode .=
			$self->get_color($color)
			. "\\addplot[$color, mark=$mark, mark size=${r}pt, line width=${lineWidth}pt, only marks] "
			. "coordinates {($x,$y)};\n";
	}

	# Labels
	for my $label ($plots->data('label')) {
		my $str          = $label->style('label');
		my $x            = $label->x(0);
		my $y            = $label->y(0);
		my $color        = $label->style('color')    || 'default_color';
		my $fontsize     = $label->style('fontsize') || 'normalsize';
		my $rotate       = $label->style('rotate');
		my $tikz_options = $label->style('tikz_options');
		my $h_align      = $label->style('h_align') || 'center';
		my $v_align      = $label->style('v_align') || 'middle';
		my $anchor       = $label->style('anchor');
		$anchor = join(' ',
			$v_align eq 'top'  ? 'north' : $v_align eq 'bottom' ? 'south' : (),
			$h_align eq 'left' ? 'west'  : $h_align eq 'right'  ? 'east'  : ())
			if $anchor eq '';
		my $padding = $label->style('padding') || 4;
		$str = {
			tiny       => '\tiny ',
			small      => '\small ',
			normalsize => '',
			medium     => '',           # deprecated
			large      => '\large ',
			Large      => '\Large ',
			giant      => '\Large ',    # deprecated
			huge       => '\huge ',
			Huge       => '\Huge '
		}->{$fontsize}
			. $str;
		$tikz_options = $tikz_options ? "$color, $tikz_options" : $color;
		$tikz_options = "anchor=$anchor, $tikz_options" if $anchor;
		$tikz_options = "rotate=$rotate, $tikz_options" if $rotate;
		$tikz_options = "inner sep=${padding}pt, $tikz_options";
		$tikzCode .= $self->get_color($color) . "\\node[$tikz_options] at (axis cs: $x,$y) {$str};\n";
	}

	$plots->{tikzCode} = $self->generate_axes($tikzCode);
	$self->im->tex($plots->{tikzCode});
	return $plots->{tikzDebug} ? '' : $self->im->draw;
}

1;
