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

BEGIN {
	strict->import;
}

sub _GD_init { }

package PGplot::GD;

sub new {
	my ($class, $pgplot) = @_;
	my $self = {
		image    => '',
		pgplot   => $pgplot,
		position => [ 0, 0 ],
		colors   => {},
	};
	bless $self, $class;

	$self->{image} = new GD::Image($pgplot->size);
	return $self;
}

sub pgplot {
	my $self = shift;
	return $self->{pgplot};
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
	$self->{colors}{$color} = $self->im->colorAllocate(@{ $self->pgplot->colors($color) })
		unless $self->{colors}{$color};
	return $self->{colors}{$color};
}

# Translate x and y coordinates to pixels on the graph.
sub im_x {
	my ($self, $x) = @_;
	return unless defined($x);
	my $pgplot = $self->pgplot;
	my ($xmin, $xmax) = ($pgplot->axes->xaxis('min'), $pgplot->axes->xaxis('max'));
	return int(($x - $xmin) * ($pgplot->size)[0] / ($xmax - $xmin));
}

sub im_y {
	my ($self, $y) = @_;
	return unless defined($y);
	my $pgplot = $self->pgplot;
	my ($ymin, $ymax) = ($pgplot->axes->yaxis('min'), $pgplot->axes->yaxis('max'));
	return int(($ymax - $y) * ($pgplot->size)[1] / ($ymax - $ymin));
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
	my $pgplot = $self->pgplot;
	$pass = 0 unless $pass;
	for my $data ($pgplot->data('function', 'dataset')) {
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
			if ($start eq 'closed_circle') {
				$self->draw_circle_stamp($data->x(0), $data->y(0), $r, $color, 1);
			} elsif ($start eq 'open_circle') {
				$self->draw_circle_stamp($data->x(0), $data->y(0), $r, $color);
			} elsif ($start eq 'arrow') {
				$self->draw_arrow_head($data->x(1), $data->y(1), $data->x(0), $data->y(0), $color, $width);
			}

			my $end = $data->style('end_mark') || 'none';
			if ($end eq 'closed_circle') {
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
	return unless scalar(@_) > 4;
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
	my $head = new GD::Polygon;
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
	$self->im->filledArc($self->im_x($x), $self->im_y($y), $d, $d, 0, 360, $self->color('nearwhite'));
	$self->im->filledArc($self->im_x($x), $self->im_y($y), $d, $d, 0, 360, $color, $filled ? () : GD::gdNoFill);
	return;
}

sub draw {
	my $self   = shift;
	my $pgplot = $self->pgplot;
	my $axes   = $pgplot->axes;
	my $grid   = $axes->grid;
	my $size   = $pgplot->size;

	# Initialize image
	$self->im->interlaced('true');
	$self->im->fill(1, 1, $self->color('background_color'));

	# Plot data first, then fill in regions before adding axes, grid, etc.
	$self->draw_data(1);

	# Fill regions
	for my $region ($pgplot->data('fill_region')) {
		$self->im->fill($self->im_x($region->x(0)), $self->im_y($region->y(0)), $self->color($region->style('color')));
	}

	# Gridlines
	my ($xmin, $ymin, $xmax, $ymax) = $axes->bounds;
	my $grid_color = $axes->style('grid_color');
	my $grid_style = $axes->style('grid_style');
	my $show_grid  = $axes->style('show_grid');
	if ($show_grid && $grid->{xmajor}) {
		my $xminor = $grid->{xminor} || 0;
		my $prevx  = $xmin;
		my $dx     = 0;
		my $first  = 1;
		for my $x (@{ $grid->{xticks} }) {
			# Number comparison of $dx and $x - $prevx failed in some tests, so using string comparison.
			$xminor = 0           unless ($first || $dx == 0 || $dx eq $x - $prevx);
			$dx     = $x - $prevx unless $first;
			$prevx  = $x;
			$first  = 0;
			$self->moveTo($x, $ymin);
			$self->lineTo($x, $ymax, $grid_color, 0.5, 1);
		}
		if ($xminor) {
			$dx /= ($xminor + 1);
			for my $x (@{ $grid->{xticks} }) {
				last if $x == $prevx;
				for (1 .. $xminor) {
					my $x2 = $x + $dx * $_;
					$self->moveTo($x2, $ymin);
					$self->lineTo($x2, $ymax, $grid_color, 0.5, 1);
				}
			}
		}
	}
	if ($show_grid && $grid->{ymajor}) {
		my $yminor = $grid->{yminor} || 0;
		my $prevy;
		my $dy    = 0;
		my $first = 1;
		for my $y (@{ $grid->{yticks} }) {
			# Number comparison of $dy and $y - $prevy failed in some tests, so using string comparison.
			$yminor = 0           unless ($first || $dy == 0 || $dy eq $y - $prevy);
			$dy     = $y - $prevy unless $first;
			$prevy  = $y;
			$first  = 0;
			$self->moveTo($xmin, $y);
			$self->lineTo($xmax, $y, $grid_color, 0.5, 1);
		}
		if ($yminor) {
			$dy /= ($yminor + 1);
			for my $y (@{ $grid->{yticks} }) {
				last if $y == $prevy;
				for (1 .. $yminor) {
					my $y2 = $y + $dy * $_;
					$self->moveTo($xmin, $y2);
					$self->lineTo($xmax, $y2, $grid_color, 0.5, 1);
				}
			}
		}
	}

	# Plot axes
	my $show_x = $axes->xaxis('visible');
	my $show_y = $axes->yaxis('visible');
	my $xloc   = $axes->xaxis('location') || 'middle';
	my $yloc   = $axes->yaxis('location') || 'center';
	my $xpos   = ($yloc eq 'box' || $yloc eq 'left')   ? $xmin : $yloc eq 'right' ? $xmax : $axes->yaxis('position');
	my $ypos   = ($xloc eq 'box' || $xloc eq 'bottom') ? $ymin : $xloc eq 'top'   ? $ymax : $axes->xaxis('position');
	$xpos = $xmin if $xpos < $xmin;
	$xpos = $xmax if $xpos > $xmax;
	$ypos = $ymin if $ypos < $ymin;
	$ypos = $ymax if $ypos > $ymax;

	if ($show_x) {
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
		for my $x (@{ $grid->{xticks} }) {
			$self->draw_label($x, $x, $ypos, font => 'large', v_align => $tick_align, h_align => 'center')
				unless ($x == $xpos && $show_y);
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
		for my $y (@{ $grid->{yticks} }) {
			$self->draw_label($y, $xpos, $y, font => 'large', v_align => 'middle', h_align => $tick_align)
				unless ($y == $ypos && $show_x);
		}
	}

	# Draw data a second time to cleanup any issues with the grid and axes.
	$self->draw_data(2);

	# Print Labels
	for my $label ($pgplot->data('label')) {
		$self->draw_label($label->style('label'), $label->x(0), $label->y(0), %{ $label->style });
	}

	# Draw stamps
	for my $stamp ($pgplot->data('stamp')) {
		my $symbol = $stamp->style('symbol');
		my $color  = $stamp->style('color');
		my $r      = $stamp->style('radius') || 4;
		if ($symbol eq 'closed_circle') {
			$self->draw_circle_stamp($stamp->x(0), $stamp->y(0), $r, $color, 1);
		} elsif ($symbol eq 'open_circle') {
			$self->draw_circle_stamp($stamp->x(0), $stamp->y(0), $r, $color);
		}
	}

	# Put a black frame around the picture
	$self->im->rectangle(0, 0, $size->[0] - 1, $size->[1] - 1, $self->color('black'));

	return $pgplot->ext eq 'gif' ? $self->im->gif : $self->im->png;
}

1;
