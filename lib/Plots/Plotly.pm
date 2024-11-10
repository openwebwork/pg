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

This is the code that takes a C<Plots::Plot> and creates a Plotly.js graph of the plot.

See L<plots.pl> for more details.

=cut

package Plots::Plotly;

use strict;
use warnings;

sub new {
	my ($class, $pgplot) = @_;

	$pgplot->insert_js('node_modules/plotly.js-dist-min/plotly.min.js');

	return bless { pgplot => $pgplot, plots => [] }, $class;
}

sub pgplot {
	my $self = shift;
	return $self->{pgplot};
}

sub HTML {
	my $self   = shift;
	my $pgplot = $self->pgplot;
	my $axes   = $pgplot->axes;
	my $grid   = $axes->grid;
	my $name   = $pgplot->get_image_name =~ s/-/_/gr;
	my $title  = $axes->style('title');
	my $plots  = '';
	my ($xmin, $ymin, $xmax, $ymax) = $axes->bounds;
	my ($height, $width) = $pgplot->size;
	my $style = 'border: solid 2px; display: inline-block; margin: 5px; text-align: center;';

	$title = "<strong>$title</strong>" if $title;
	for (@{ $self->{plots} }) {
		$plots .= $_;
	}

	return <<END_HTML;
<div style="$style">$title
	<div id="plotlyDiv_$name" style="width: ${width}px; height: ${height}px;"></div>
</div>
<script>
(() => {
	const draw_graph = () => {
		const plotlyData = [];
		$plots
		Plotly.newPlot(
			'plotlyDiv_$name',
			plotlyData,
			{showlegend: false}
		);
	}
	if (document.readyState === 'loading') window.addEventListener('DOMContentLoaded', draw_graph);
	else draw_graph();
})();
</script>
END_HTML
}

sub draw {
	my $self   = shift;
	my $pgplot = $self->pgplot;

	# Plot Data
	for my $data ($pgplot->data('function', 'dataset')) {
		$data->gen_data;

		my $x_points = join(',', $data->x);
		my $y_points = join(',', $data->y);
		my $plot     = <<END_JS;
			plotlyData.push({
				x: [$x_points],
				y: [$y_points],
				mode: 'lines'
			});
END_JS
		push(@{ $self->{plots} }, $plot);
	}

	return $self->HTML;
}

1;
