
=head1 DESCRIPTION

This is the code that takes a C<Plots::Plot> and creates the GD code for generation.

See L<plots.pl> for more details.

=cut

package Plots::GD;

use GD;

use strict;
use warnings;

sub new {
	my ($class, $plots) = @_;
	return bless {
		image    => '',
		plots    => $plots,
		position => [ 0, 0 ],
		colors   => {},
		image    => GD::Image->new($plots->size)
	}, $class;
}

sub plots {
	my $self = shift;
	return $self->{plots};
}

sub im {
	my $self = shift;
	return $self->{image};
}

sub position {
	my ($self, $x, $y) = @_;
	return wantarray ? @{ $self->{position} } : $self->{position} unless (defined($x) && defined($y));
	$self->{position} = [ $x, $y ];
	return;
}

sub color {
	my ($self, $color) = @_;
	$self->{colors}{$color} = $self->im->colorAllocate(@{ $self->plots->colors($color) })
		unless $self->{colors}{$color};
	return $self->{colors}{$color};
}

# Translate x and y coordinates to pixels on the graph.
sub im_x {
	my ($self, $x) = @_;
	return unless defined($x);
	my $plots = $self->plots;
	my ($xmin, $xmax) = ($plots->axes->xaxis('min'), $plots->axes->xaxis('max'));
	return int(($x - $xmin) * $plots->{width} / ($xmax - $xmin));
}

sub im_y {
	my ($self, $y) = @_;
	return unless defined($y);
	my $plots = $self->plots;
	my ($ymin, $ymax) = ($plots->axes->yaxis('min'), $plots->axes->yaxis('max'));
	(undef, my $height) = $plots->size;
	return int(($ymax - $y) * $height / ($ymax - $ymin));
}

sub moveTo {
	my ($self, $x, $y) = @_;
	$x = $self->im_x($x);
	$y = $self->im_y($y);
	$self->position($x, $y);
	return;
}

sub lineTo {
	my ($self, $x, $y, $color, $width, $dashed) = @_;
	$color  = 'default_color' unless defined($color);
	$color  = $self->color($color);
	$width  = 1 unless defined($width);
	$dashed = 0 unless defined($dashed);
	$x      = $self->im_x($x);
	$y      = $self->im_y($y);

	$self->im->setThickness($width);
	if ($dashed =~ /dash/) {
		my @dashing = ($color) x (4 * $width * $width);
		my @spacing = (GD::gdTransparent) x (3 * $width * $width);
		$self->im->setStyle(@dashing, @spacing);
		$self->im->line($self->position, $x, $y, GD::gdStyled);
	} elsif ($dashed =~ /dot/) {
		my @dashing = ($color) x (1 * $width * $width);
		my @spacing = (GD::gdTransparent) x (2 * $width * $width);
		$self->im->setStyle(@dashing, @spacing);
		$self->im->line($self->position, $x, $y, GD::gdStyled);
	} else {
		$self->im->line($self->position, $x, $y, $color);
	}
	$self->im->setThickness(1);
	$self->position($x, $y);
	return;
}

# Draw functions / lines / arrows
sub draw_data {
	my ($self, $pass) = @_;
	my $plots = $self->plots;
	$pass = 0 unless $pass;
	for my $data ($plots->data('function', 'dataset')) {
		$data->gen_data;
		my $n     = $data->size - 1;
		my $x     = $data->x;
		my $y     = $data->y;
		my $color = $data->style('color');
		my $width = $data->style('width');
		$self->moveTo($x->[0], $y->[0]);
		for (1 .. $n) {
			$self->lineTo($x->[$_], $y->[$_], $color, $width, $data->style('linestyle'));
		}

		if ($pass == 2) {
			my $r     = int(3 + $width);
			my $start = $data->style('start_mark') || 'none';
			if ($start eq 'circle' || $start eq 'closed_circle') {
				$self->draw_circle_stamp($data->x(0), $data->y(0), $r, $color, 1);
			} elsif ($start eq 'open_circle') {
				$self->draw_circle_stamp($data->x(0), $data->y(0), $r, $color);
			} elsif ($start eq 'arrow') {
				$self->draw_arrow_head($data->x(1), $data->y(1), $data->x(0), $data->y(0), $color, $width);
			}

			my $end = $data->style('end_mark') || 'none';
			if ($end eq 'circle' || $end eq 'closed_circle') {
				$self->draw_circle_stamp($data->x($n), $data->y($n), $r, $color, 1);
			} elsif ($end eq 'open_circle') {
				$self->draw_circle_stamp($data->x($n), $data->y($n), $r, $color);
			} elsif ($end eq 'arrow') {
				$self->draw_arrow_head($data->x($n - 1), $data->y($n - 1), $data->x($n), $data->y($n), $color, $width);
			}
		}
	}
	return;
}

# Label helpers
sub get_gd_font {
	my ($self, $font) = @_;
	if    ($font eq 'tiny')  { return GD::gdTinyFont; }
	elsif ($font eq 'small') { return GD::gdSmallFont; }
	elsif ($font eq 'large') { return GD::gdLargeFont; }
	elsif ($font eq 'giant') { return GD::gdGiantFont; }
	return GD::gdMediumBoldFont;
}

sub label_offset {
	my ($self, $loc, $str, $fontsize) = @_;
	my $offset = 0;
	# Add an additional 2px offset for the edges 'right', 'bottom', 'left', and 'top'.
	if    ($loc eq 'right')  { $offset -= length($str) * $fontsize + 2; }
	elsif ($loc eq 'bottom') { $offset -= $fontsize + 2; }
	elsif ($loc eq 'center') { $offset -= length($str) * $fontsize / 2; }
	elsif ($loc eq 'middle') { $offset -= $fontsize / 2; }
	else                     { $offset = 2; }    # Both 'left' and 'top'.
	return $offset;
}

sub draw_label {
	my ($self, $str, $x, $y, %options) = @_;
	my $font  = $self->get_gd_font($options{fontsize} || 'medium');
	my $color = $self->color($options{color}          || 'default_color');
	my $xoff  = $self->label_offset($options{h_align} || 'center', $str, $font->width);
	my $yoff  = $self->label_offset($options{v_align} || 'middle', $str, $font->height);

	if ($options{orientation} && $options{orientation} eq 'vertical') {
		$self->im->stringUp($font, $self->im_x($x) + $xoff, $self->im_y($y) + $yoff, $str, $color);
	} else {
		$self->im->string($font, $self->im_x($x) + $xoff, $self->im_y($y) + $yoff, $str, $color);
	}
	return;
}

sub draw_arrow_head {
	my ($self, $x1, $y1, $x2, $y2, $color, $w) = @_;
	return unless @_ > 4;
	$color = $self->color($color || 'default_color');
	$w     = 1 unless $w;
	($x1, $y1) = ($self->im_x($x1), $self->im_y($y1));
	($x2, $y2) = ($self->im_x($x2), $self->im_y($y2));

	my $dx   = $x2 - $x1;
	my $dy   = $y2 - $y1;
	my $len  = sqrt($dx * $dx + $dy * $dy);
	my $ux   = $dx / $len;                    # Unit vector in direction of arrow.
	my $uy   = $dy / $len;
	my $px   = -1 * $uy;                      # Unit vector perpendicular to arrow.
	my $py   = $ux;
	my $hbx  = $x2 - 7 * $w * $ux;
	my $hby  = $y2 - 7 * $w * $uy;
	my $head = GD::Polygon->new;
	$head->addPt($x2,                 $y2);
	$head->addPt($hbx + 3 * $w * $px, $hby + 3 * $w * $py);
	$head->addPt($hbx - 3 * $w * $px, $hby - 3 * $w * $py);
	$self->im->setThickness($w);
	$self->im->filledPolygon($head, $color);
	$self->im->setThickness(1);
	return;
}

sub draw_circle_stamp {
	my ($self, $x, $y, $r, $color, $filled) = @_;
	my $d = $r ? 2 * $r : 8;
	$color = $self->color($color || 'default_color');
	$self->im->filledArc($self->im_x($x), $self->im_y($y), $d, $d, 0, 360, $self->color('white'));
	$self->im->filledArc($self->im_x($x), $self->im_y($y), $d, $d, 0, 360, $color, $filled ? () : GD::gdNoFill);
	return;
}

sub draw {
	my $self  = shift;
	my $plots = $self->plots;
	my $axes  = $plots->axes;
	my $grid  = $axes->grid;
	my ($width, $height) = $plots->size;

	# Initialize image
	$self->im->interlaced('true');
	$self->im->fill(1, 1, $self->color('white'));

	# Plot data first, then fill in regions before adding axes, grid, etc.
	$self->draw_data(1);

	# Fill regions
	for my $region ($plots->data('fill_region')) {
		$self->im->fill($self->im_x($region->x(0)), $self->im_y($region->y(0)), $self->color($region->style('color')));
	}

	# Gridlines
	my ($xmin, $ymin, $xmax, $ymax) = $axes->bounds;
	my $grid_color = $axes->style('grid_color');
	my $grid_style = $axes->style('grid_style');
	my $show_grid  = $axes->style('show_grid');
	if ($show_grid && $grid->{xmajor}) {
		my $xminor = $grid->{xminor}      || 0;
		my $dx     = $grid->{xtick_delta} || 1;
		my $x      = (int($xmax / $dx) + 1) * $dx;
		my $end    = (int($xmin / $dx) - 1) * $dx;
		while ($x >= $end) {
			$self->moveTo($x, $ymin);
			$self->lineTo($x, $ymax, $grid_color, 0.5, 1);
			for (0 .. $xminor) {
				my $tmp_x = $x + $_ * $dx / ($xminor + 1);
				$self->moveTo($tmp_x, $ymin);
				$self->lineTo($tmp_x, $ymax, $grid_color, 0.5, 1);
			}
			$x -= $dx;
		}
	}
	if ($show_grid && $grid->{ymajor}) {
		my $yminor = $grid->{yminor}      || 0;
		my $dy     = $grid->{ytick_delta} || 1;
		my $y      = (int($ymax / $dy) + 1) * $dy;
		my $end    = (int($ymin / $dy) - 1) * $dy;
		while ($y >= $end) {
			$self->moveTo($xmin, $y);
			$self->lineTo($xmax, $y, $grid_color, 0.5, 1);
			for (0 .. $yminor) {
				my $tmp_y = $y + $_ * $dy / ($yminor + 1);
				$self->moveTo($xmin, $tmp_y);
				$self->lineTo($xmax, $tmp_y, $grid_color, 0.5, 1);
			}
			$y -= $dy;
		}
	}

	# Plot axes
	my $xloc = $axes->xaxis('location') || 'middle';
	my $yloc = $axes->yaxis('location') || 'center';
	my $xpos = ($yloc eq 'box' || $yloc eq 'left')   ? $xmin : $yloc eq 'right' ? $xmax : $axes->yaxis('position');
	my $ypos = ($xloc eq 'box' || $xloc eq 'bottom') ? $ymin : $xloc eq 'top'   ? $ymax : $axes->xaxis('position');
	$xpos = $xmin if $xpos < $xmin;
	$xpos = $xmax if $xpos > $xmax;
	$ypos = $ymin if $ypos < $ymin;
	$ypos = $ymax if $ypos > $ymax;

	if ($axes->xaxis('visible')) {
		my $xlabel      = $axes->xaxis('label') =~ s/\\[\(\[\)\]]//gr;
		my $tick_align  = ($self->im_y($ymin) - $self->im_y($ypos) < 5)             ? 'bottom' : 'top';
		my $label_align = ($self->im_y($ypos) - $self->im_y($ymax) < 5)             ? 'top'    : 'bottom';
		my $label_loc   = $yloc eq 'right' && ($xloc eq 'top' || $xloc eq 'bottom') ? $xmin    : $xmax;

		$self->moveTo($xmin, $ypos);
		$self->lineTo($xmax, $ypos, 'black', 1.5, 0);
		$self->draw_label(
			$xlabel, $label_loc, $ypos,
			fontsize => 'large',
			v_align  => $label_align,
			h_align  => $label_loc == $xmin ? 'left' : 'right'
		);
		my $dx  = $grid->{xtick_delta} || 1;
		my $x   = int($xmax / $dx) * $dx;
		my $end = int($xmin / $dx) * $dx;

		while ($x >= $end) {
			$self->draw_label($x, $x, $ypos, font => 'large', v_align => $tick_align, h_align => 'center')
				unless $x == $xpos && $axes->yaxis('visible');
			$x -= $dx;
		}
	}
	if ($axes->yaxis('visible')) {
		my $ylabel      = $axes->yaxis('label') =~ s/\\[\(\[\)\]]//gr;
		my $tick_align  = ($self->im_x($xpos) - $self->im_x($xmin) < 5) ? 'left'                              : 'right';
		my $label_align = ($self->im_x($xmax) - $self->im_x($xpos) < 5) ? 'right'                             : 'left';
		my $label_loc   = ($yloc eq 'left' && $xloc eq 'top') || ($yloc eq 'right' && $xloc eq 'top') ? $ymin : $ymax;

		$self->moveTo($xpos, $ymin);
		$self->lineTo($xpos, $ymax, 'black', 1.5, 0);
		$self->draw_label(
			$ylabel, $xpos, $label_loc,
			fontsize => 'large',
			v_align  => $label_loc == $ymin ? 'bottom' : 'top',
			h_align  => $label_align
		);

		my $dy  = $grid->{ytick_delta} || 1;
		my $y   = int($ymax / $dy) * $dy;
		my $end = int($ymin / $dy) * $dy;
		while ($y >= $end) {
			$self->draw_label($y, $xpos, $y, font => 'large', v_align => 'middle', h_align => $tick_align)
				unless $y == $ypos && $axes->xaxis('visible');
			$y -= $dy;
		}
	}

	# Draw data a second time to cleanup any issues with the grid and axes.
	$self->draw_data(2);

	# Print Labels
	for my $label ($plots->data('label')) {
		$self->draw_label($label->style('label'), $label->x(0), $label->y(0), %{ $label->style });
	}

	# Draw stamps
	for my $stamp ($plots->data('stamp')) {
		my $symbol = $stamp->style('symbol');
		my $color  = $stamp->style('color');
		my $r      = $stamp->style('radius') || 4;
		if ($symbol eq 'circle' || $symbol eq 'closed_circle') {
			$self->draw_circle_stamp($stamp->x(0), $stamp->y(0), $r, $color, 1);
		} elsif ($symbol eq 'open_circle') {
			$self->draw_circle_stamp($stamp->x(0), $stamp->y(0), $r, $color);
		}
	}

	# Put a black frame around the picture
	$self->im->rectangle(0, 0, $width - 1, $height - 1, $self->color('black'));

	return $plots->ext eq 'gif' ? $self->im->gif : $self->im->png;
}

1;
