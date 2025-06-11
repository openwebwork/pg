
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
	$image->environment([ 'tikzpicture', 'framed' ]);
	$image->svgMethod(eval('$main::envir{latexImageSVGMethod}')           // 'dvisvgm');
	$image->convertOptions(eval('$main::envir{latexImageConvertOptions}') // { input => {}, output => {} });
	$image->ext($plots->ext);
	$image->tikzLibraries('arrows.meta,plotmarks,backgrounds');
	$image->texPackages(['pgfplots']);

	# Set the pgfplots compatibility, add the pgfplots fillbetween library, set a nice rectangle frame with white
	# background for the backgrounds library, and redefine standard layers since the backgrounds library uses layers
	# that conflict with the layers used by the fillbetween library.
	$image->addToPreamble( <<~ 'END_PREAMBLE');
		\usepgfplotslibrary{fillbetween}
		\tikzset{inner frame sep = 0pt, background rectangle/.style = { thick, draw = DarkBlue, fill = white }}
		\pgfplotsset{
			compat = 1.18,
			layers/standard/.define layer set = {
				background,
				axis background,
				axis grid,
				axis ticks,
				axis lines,
				axis tick labels,
				pre main,
				main,
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

	return bless { image => $image, plots => $plots, colors => {} }, $class;
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
	my ($r, $g, $b) = @{ $self->plots->colors($color) };
	$self->{colors}{$color} = 1;
	return "\\definecolor{$color}{RGB}{$r,$g,$b}\n";
}

sub get_mark {
	my ($self, $mark) = @_;
	return {
		circle        => '*',
		closed_circle => '*',
		open_circle   => 'o',
		square        => 'square*',
		open_square   => 'square',
		plus          => '+',
		times         => 'x',
		bar           => '|',
		dash          => '-',
		triangle      => 'triangle*',
		open_triangle => 'triangle',
		diamond       => 'diamond*',
		open_diamond  => 'diamond',
	}->{$mark};
}

sub configure_axes {
	my $self  = shift;
	my $plots = $self->plots;
	my $axes  = $plots->axes;
	my $grid  = $axes->grid;
	my ($xmin, $ymin, $xmax, $ymax) = $axes->bounds;
	my ($axes_width, $axes_height) = $plots->size;
	my $show_grid    = $axes->style('show_grid');
	my $xmajor       = $show_grid && $grid->{xmajor} ? 'true' : 'false';
	my $xminor_num   = $grid->{xminor};
	my $xminor       = $show_grid && $xminor_num > 0 ? 'true' : 'false';
	my $ymajor       = $show_grid && $grid->{ymajor} ? 'true' : 'false';
	my $yminor_num   = $grid->{yminor};
	my $yminor       = $show_grid && $yminor_num > 0 ? 'true'                                      : 'false';
	my $xticks       = $axes->xaxis('show_ticks')    ? '{' . join(',', @{ $grid->{xticks} }) . '}' : 'none';
	my $yticks       = $axes->yaxis('show_ticks')    ? '{' . join(',', @{ $grid->{yticks} }) . '}' : 'none';
	my $xtick_labels = $axes->xaxis('tick_labels')   ? '' : "\n\t\t\txticklabel=\\empty,";
	my $ytick_labels = $axes->yaxis('tick_labels')   ? '' : "\n\t\t\tyticklabel=\\empty,";
	my $grid_color   = $axes->style('grid_color');
	my $grid_color2  = $self->get_color($grid_color);
	my $grid_alpha   = $axes->style('grid_alpha');
	my $grid_style   = $axes->style('grid_style');
	my $xlabel       = $axes->xaxis('label');
	my $axis_x_line  = $axes->xaxis('location');
	my $axis_x_pos   = $axes->xaxis('position');
	my $ylabel       = $axes->yaxis('label');
	my $axis_y_line  = $axes->yaxis('location');
	my $axis_y_pos   = $axes->yaxis('position');
	my $axis_on_top  = $axes->style('axis_on_top') ? "axis on top,\n\t\t\t" : '';
	my $hide_x_axis  = '';
	my $hide_y_axis  = '';
	my $xaxis_plot   = ($xmin <= 0 && $xmax >= 0) ? "\\path[name path=xaxis] ($xmin, 0) -- ($xmax,0);\n" : '';
	$axis_x_pos = $axis_x_pos ? ",\n\t\t\taxis x line shift=" . (-$axis_x_pos) : '';
	$axis_y_pos = $axis_y_pos ? ",\n\t\t\taxis y line shift=" . (-$axis_y_pos) : '';

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
			trig format plots=rad,
			view={0}{90},
			height=$axes_height,
			width=$axes_width,
			${axis_on_top}axis x line=$axis_x_line$axis_x_pos,
			axis y line=$axis_y_line$axis_y_pos,
			xlabel={$xlabel},
			ylabel={$ylabel},
			xtick=$xticks,$xtick_labels
			ytick=$yticks,$ytick_labels
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
	my $tikz_options = $data->style('tikz_options') ? ', ' . $data->style('tikz_options') : '';
	my $smooth       = $data->style('tikz_smooth')  ? 'smooth, '                          : '';

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
	$marks     = $self->get_mark($marks);
	$marks     = $marks ? $mark_size ? ", mark=$marks, mark size=${mark_size}px" : ", mark=$marks" : '';
	$linestyle = $linestyle eq 'none' ? ', only marks' : ', ' . ($linestyle =~ s/_/ /gr);
	if ($fill eq 'self') {
		$fill = ", fill=$fill_color, fill opacity=$fill_opacity";
	} else {
		$fill = '';
	}
	$name = ", name path=$name" if $name;

	return "${smooth}color=$color, line width=${width}pt$marks$linestyle$end_markers$fill$name$tikz_options";
}

sub draw {
	my $self  = shift;
	my $plots = $self->plots;

	# Reset colors just in case.
	$self->{colors} = {};

	# Add Axes
	my $tikzCode = $self->configure_axes;

	# Plot Data
	for my $data ($plots->data('function', 'dataset')) {
		my $n            = $data->size;
		my $color        = $data->style('color')      || 'default_color';
		my $fill         = $data->style('fill')       || 'none';
		my $fill_color   = $data->style('fill_color') || 'default_color';
		my $tikz_options = $self->get_plot_opts($data);
		$tikzCode .= $self->get_color($color);
		my $plot;
		if ($data->name eq 'function') {
			my $f = $data->{function};
			if (ref($f->{Fx}) ne 'CODE' && $f->{xvar} eq $f->{Fx}->string) {
				my $function = $data->function_string('y', 'PGF', 1);
				if ($function ne '') {
					$data->update_min_max;
					$tikz_options .= ", domain=$f->{xmin}:$f->{xmax}, samples=$f->{xsteps}";
					$plot = "{$function}";
				}
			} else {
				my $xfunction = $data->function_string('x', 'PGF', 1);
				my $yfunction = $data->function_string('y', 'PGF', 1);
				if ($xfunction ne '' && $yfunction ne '') {
					$data->update_min_max;
					$tikz_options .= ", domain=$f->{xmin}:$f->{xmax}, samples=$f->{xsteps}";
					$plot = "({$xfunction}, {$yfunction})";
				}
			}
		}
		unless ($plot) {
			$data->gen_data;
			my $tikzData = join(' ', map { '(' . $data->x($_) . ',' . $data->y($_) . ')'; } (0 .. $n - 1));
			$plot = "coordinates {$tikzData}";
		}
		$tikzCode .= "\\addplot[$tikz_options] $plot;\n";

		$tikzCode .= $self->get_color($fill_color) unless $fill eq 'none';
		unless ($fill eq 'none' || $fill eq 'self') {
			my $name       = $data->style('name')         || '';
			my $opacity    = $data->style('fill_opacity') || 0.5;
			my $fill_min   = $data->style('fill_min');
			my $fill_max   = $data->style('fill_max');
			my $fill_range = defined $fill_min && defined $fill_max ? ", soft clip={domain=$fill_min:$fill_max}" : '';
			$opacity *= 100;
			$tikzCode .= "\\addplot[$fill_color!$opacity] fill between[of=$name and $fill$fill_range];\n";
		}
	}

	# Vector/Slope Fields
	for my $data ($plots->data('vectorfield')) {
		my $xfunction = $data->function_string('x', 'PGF', 2);
		my $yfunction = $data->function_string('y', 'PGF', 2);
		my $arrows    = $data->style('slopefield') ? '' : ', -stealth';
		if ($xfunction ne '' && $yfunction ne '') {
			my $f            = $data->{function};
			my $color        = $data->style('color');
			my $width        = $data->style('width');
			my $scale        = $data->style('scale');
			my $tikz_options = $data->style('tikz_options') ? ', ' . $data->style('tikz_options') : '';
			$data->update_min_max;

			if ($data->style('normalize') || $data->style('slopefield')) {
				my $xtmp = "($xfunction)/sqrt(($xfunction)^2 + ($yfunction)^2)";
				$yfunction = "($yfunction)/sqrt(($xfunction)^2 + ($yfunction)^2)";
				$xfunction = $xtmp;
			}

			$tikzCode .= $self->get_color($color);
			$tikzCode .=
				"\\addplot3[color=$color, line width=${width}pt$arrows, "
				. "quiver={u=$xfunction, v=$yfunction, scale arrows=$scale}, samples=$f->{xsteps}, "
				. "domain=$f->{xmin}:$f->{xmax}, domain y=$f->{ymin}:$f->{ymax}$tikz_options] {1};\n";
		} else {
			warn "Vector field not created due to missing PGF functions.";
		}
	}

	# Stamps
	for my $stamp ($plots->data('stamp')) {
		my $mark = $self->get_mark($stamp->style('symbol'));
		next unless $mark;

		my $color = $stamp->style('color') || 'default_color';
		my $x     = $stamp->x(0);
		my $y     = $stamp->y(0);
		my $r     = $stamp->style('radius') || 4;
		$tikzCode .= $self->get_color($color)
			. "\\addplot[$color, mark=$mark, mark size=${r}pt, only marks] coordinates {($x,$y)};\n";
	}

	# Labels
	for my $label ($plots->data('label')) {
		my $str          = $label->style('label');
		my $x            = $label->x(0);
		my $y            = $label->y(0);
		my $color        = $label->style('color')        || 'default_color';
		my $fontsize     = $label->style('fontsize')     || 'medium';
		my $orientation  = $label->style('orientation')  || 'horizontal';
		my $tikz_options = $label->style('tikz_options') || '';
		my $h_align      = $label->style('h_align')      || 'center';
		my $v_align      = $label->style('v_align')      || 'middle';
		my $anchor       = $v_align eq 'top' ? 'north' : $v_align eq 'bottom' ? 'south' : '';
		$str = {
			tiny   => '\tiny ',
			small  => '\small ',
			medium => '',
			large  => '\large ',
			giant  => '\Large ',
		}->{$fontsize}
			. $str;
		$anchor .= $h_align eq 'left' ? ' west' : $h_align eq 'right' ? ' east' : '';
		$tikz_options = $tikz_options ? "$color, $tikz_options" : $color;
		$tikz_options = "anchor=$anchor, $tikz_options" if $anchor;
		$tikz_options = "rotate=90, $tikz_options"      if $orientation eq 'vertical';
		$tikzCode .= $self->get_color($color) . "\\node[$tikz_options] at (axis cs: $x,$y) {$str};\n";
	}
	$tikzCode .= '\end{axis}';

	$plots->{tikzCode} = $tikzCode;
	$self->im->tex($tikzCode);
	return $plots->{tikzDebug} ? '' : $self->im->draw;
}

1;
