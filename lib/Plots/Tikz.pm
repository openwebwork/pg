
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
	$image->environment('tikzpicture');
	$image->svgMethod($main::envir{latexImageSVGMethod}           // 'dvisvgm');
	$image->convertOptions($main::envir{latexImageConvertOptions} // { input => {}, output => {} });
	$image->ext($plots->ext);
	$image->tikzLibraries('arrows.meta,plotmarks');
	$image->texPackages(['pgfplots']);
	$image->addToPreamble('\pgfplotsset{compat=1.18}\usepgfplotslibrary{fillbetween}');

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
	my $show_grid   = $axes->style('show_grid');
	my $xmajor      = $show_grid && $grid->{xmajor} ? 'true'          : 'false';
	my $xminor_num  = $show_grid && $grid->{xmajor} ? $grid->{xminor} : 0;
	my $xminor      = $xminor_num > 0 ? 'true' : 'false';
	my $ymajor      = $show_grid && $grid->{ymajor} ? 'true'          : 'false';
	my $yminor_num  = $show_grid && $grid->{ymajor} ? $grid->{yminor} : 0;
	my $yminor      = $yminor_num > 0 ? 'true' : 'false';
	my $xticks      = join(',', @{ $grid->{xticks} });
	my $yticks      = join(',', @{ $grid->{yticks} });
	my $grid_color  = $axes->style('grid_color');
	my $grid_color2 = $self->get_color($grid_color);
	my $grid_alpha  = $axes->style('grid_alpha');
	my $grid_style  = $axes->style('grid_style');
	my $xlabel      = $axes->xaxis('label');
	my $axis_x_line = $axes->xaxis('location');
	my $axis_x_pos  = $axes->xaxis('position');
	my $ylabel      = $axes->yaxis('label');
	my $axis_y_line = $axes->yaxis('location');
	my $axis_y_pos  = $axes->yaxis('position');
	my $title       = $axes->style('title');
	my $axis_on_top = $axes->style('axis_on_top') ? "axis on top,\n\t\t\t" : '';
	my $hide_x_axis = '';
	my $hide_y_axis = '';
	my $xaxis_plot  = ($xmin <= 0 && $xmax >= 0) ? "\\path[name path=xaxis] ($xmin, 0) -- ($xmax,0);\n" : '';
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
			height=$axes_height,
			width=$axes_width,
			${axis_on_top}axis x line=$axis_x_line$axis_x_pos,
			axis y line=$axis_y_line$axis_y_pos,
			xlabel={$xlabel},
			ylabel={$ylabel},
			title={$title},
			xtick={$xticks},
			ytick={$yticks},
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
	my $tikzOpts     = $data->style('tikzOpts')     || '';
	my $smooth       = $data->style('tikz_smooth') ? 'smooth, ' : '';

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
	$name     = ", name path=$name" if $name;
	$tikzOpts = ", $tikzOpts"       if $tikzOpts;

	return "${smooth}color=$color, line width=${width}pt$marks$linestyle$end_markers$fill$name$tikzOpts";
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
		$data->gen_data;
		my $n          = $data->size;
		my $color      = $data->style('color')      || 'default_color';
		my $fill       = $data->style('fill')       || 'none';
		my $fill_color = $data->style('fill_color') || 'default_color';
		my $tikzData   = join(' ', map { '(' . $data->x($_) . ',' . $data->y($_) . ')'; } (0 .. $n - 1));
		my $tikzOpts   = $self->get_plot_opts($data);
		$tikzCode .= $self->get_color($fill_color) unless $fill eq 'none';
		$tikzCode .= $self->get_color($color) . "\\addplot[$tikzOpts] coordinates {$tikzData};\n";

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
		my $str         = $label->style('label');
		my $x           = $label->x(0);
		my $y           = $label->y(0);
		my $color       = $label->style('color')       || 'default_color';
		my $fontsize    = $label->style('fontsize')    || 'medium';
		my $orientation = $label->style('orientation') || 'horizontal';
		my $tikzOpts    = $label->style('tikzOpts')    || '';
		my $h_align     = $label->style('h_align')     || 'center';
		my $v_align     = $label->style('v_align')     || 'middle';
		my $anchor      = $v_align eq 'top' ? 'north' : $v_align eq 'bottom' ? 'south' : '';
		$str = {
			tiny   => '\tiny ',
			small  => '\small ',
			medium => '',
			large  => '\large ',
			giant  => '\Large ',
		}->{$fontsize}
			. $str;
		$anchor .= $h_align eq 'left' ? ' west' : $h_align eq 'right' ? ' east' : '';
		$tikzOpts = $tikzOpts ? "$color, $tikzOpts" : $color;
		$tikzOpts = "anchor=$anchor, $tikzOpts" if $anchor;
		$tikzOpts = "rotate=90, $tikzOpts"      if $orientation eq 'vertical';
		$tikzCode .= $self->get_color($color) . "\\node[$tikzOpts] at (axis cs: $x,$y) {$str};\n";
	}
	$tikzCode .= '\end{axis}' . "\n";

	$plots->{tikzCode} = $tikzCode;
	$self->im->tex($tikzCode);
	return $plots->{tikzDebug} ? '' : $self->im->draw;
}

1;
