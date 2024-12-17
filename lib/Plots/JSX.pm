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

=head1 DESCRIPTION

This is the code that takes a C<Plots::Plot> and creates a jsxgraph graph of the plot.

See L<plots.pl> for more details.

=cut

package Plots::JSX;

use strict;
use warnings;

sub new {
	my ($class, $pgplot) = @_;

	$pgplot->insert_css('node_modules/jsxgraph/distrib/jsxgraph.css');
	$pgplot->insert_js('node_modules/jsxgraph/distrib/jsxgraphcore.js');

	return bless { pgplot => $pgplot }, $class;
}

sub pgplot {
	my $self = shift;
	return $self->{pgplot};
}

sub HTML {
	my $self  = shift;
	my $board = $self->{board};
	my $JS    = $self->{JS};

	return <<END_HTML;
$board
<script>
(() => {
	const draw_board = () => {
$JS
	}
	if (document.readyState === 'loading') window.addEventListener('DOMContentLoaded', draw_board);
	else draw_board();
})();
</script>
END_HTML
}

sub get_color {
	my ($self, $color) = @_;
	return sprintf("#%x%x%x", @{ $self->pgplot->colors($color) });
}

sub add_curve {
	my ($self, $data) = @_;
	my $linestyle = $data->style('linestyle');
	return if $linestyle eq 'none';

	if ($linestyle eq 'densely dashed') {
		$linestyle = ',dash: 4, dashScale: true';
	} elsif ($linestyle eq 'loosely dashed') {
		$linestyle = ',dash: 3, dashScale: true';
	} elsif ($linestyle =~ /dashed/) {
		$linestyle = ',dash: 1, dashScale: true';
	} elsif ($linestyle =~ /dotted/) {
		$linestyle = ',dash: 1';
	} else {
		$linestyle = '';
	}

	my $name        = $self->{name};
	my $color       = $self->get_color($data->style('color') || 'default_color');
	my $data_points = '[[' . join(',', $data->x) . '],[' . join(',', $data->y) . ']]';
	my $line_width  = $data->style('width') || 2;

	$self->{JS} .= "\n\t\tboard_$name.create('curve', $data_points, "
		. "{strokeColor: '$color', strokeWidth: $line_width$linestyle});";
}

sub add_points {
	my ($self, $data) = @_;
	my $mark = $data->style('marks');
	return if !$mark || $mark eq 'none';

	if ($mark eq 'plus' || $mark eq 'oplus') {
		$mark = ',face: "plus"';
	} elsif ($mark eq 'times' || $mark eq 'otimes') {
		$mark = ',face: "cross"';
	} elsif ($mark eq 'dash') {
		$mark = ',face: "minus"';
	} elsif ($mark eq 'bar') {
		$mark = ',face: "divide"';
	} elsif ($mark eq 'diamond') {
		$mark = ',face: "diamond"';
	} elsif ($mark eq 'open_circle') {
		$mark = ',fillColor: "white"';
	} else {
		$mark = '';
	}

	my $name = $self->{name};
	my $size = $data->style('mark_size') || $data->style('width') || 3;

	for my $i (0 .. $data->size - 1) {
		$self->{JS} .=
			"\n\t\tboard_$name.create('point', ["
			. $data->x($i) . ','
			. $data->y($i) . '], '
			. "{fixed: true, withLabel: false, size: $size$mark});";
	}
}

sub init_graph {
	my $self   = shift;
	my $pgplot = $self->pgplot;
	my $axes   = $pgplot->axes;
	my $grid   = $axes->grid;
	my $name   = $self->{name};
	my $title  = $axes->style('title');
	my ($xmin, $ymin, $xmax, $ymax) = $axes->bounds;
	my ($height, $width) = $pgplot->size;
	my $style = 'display: inline-block; margin: 5px; text-align: center;';

	$title = "<strong>$title</strong>" if $title;
	$self->{board} = <<END_HTML;
		<div style="$style">$title
			<div id="board_$name" class="jxgbox" style="width: ${width}px; height: ${height}px;"></div>
		</div>
END_HTML
	$self->{JS} = <<END_JS;
		const board_$name = JXG.JSXGraph.initBoard(
			'board_$name',
			{
				boundingbox: [$xmin, $ymax, $xmax, $ymin],
				axis: true,
				showNavigation: false,
				showCopyright: false,
			}
		);
END_JS
}

sub draw {
	my $self   = shift;
	my $pgplot = $self->pgplot;
	my $name   = $pgplot->get_image_name =~ s/-/_/gr;
	$self->{name} = $name;

	$self->init_graph;

	# Plot Data
	for my $data ($pgplot->data('function', 'dataset')) {
		$data->gen_data;
		$self->add_curve($data);
		$self->add_points($data);
	}

	return $self->HTML;
}

1;
