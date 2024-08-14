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

This is the main C<Plots::Plot> code for creating a Plot.

See L<plots.pl> for more details.

=cut

package Plots::Plot;

use strict;
use warnings;

use Plots::Axes;
use Plots::Data;
use Plots::Tikz;
use Plots::GD;

sub new {
	my ($class, $pg, @opts) = @_;
	my $size = $main::envir{onTheFlyImageSize} || 500;

	my $self = {
		pg        => $pg,
		imageName => {},
		type      => 'Tikz',
		ext       => 'svg',
		size      => [ $size, $size ],
		axes      => Plots::Axes->new,
		colors    => {},
		data      => [],
		@opts
	};

	bless $self, $class;
	$self->color_init;
	return $self;
}

sub colors {
	my ($self, $color) = @_;
	return defined($color) ? $self->{colors}{$color} : $self->{colors};
}

sub _add_color {
	my ($self, $color, $r, $g, $b) = @_;
	$self->{'colors'}{$color} = [ $r, $g, $b ];
	return;
}

sub add_color {
	my $self = shift;
	if (ref($_[0]) eq 'ARRAY') {
		for (@_) { $self->_add_color(@$_); }
	} else {
		$self->_add_color(@_);
	}
	return;
}

# Define some base colors.
sub color_init {
	my $self = shift;
	$self->add_color('background_color', 255, 255, 255);
	$self->add_color('default_color',    0,   0,   0);
	$self->add_color('white',            255, 255, 255);
	$self->add_color('black',            0,   0,   0);
	$self->add_color('red',              255, 0,   0);
	$self->add_color('green',            0,   255, 0);
	$self->add_color('blue',             0,   0,   255);
	$self->add_color('yellow',           255, 255, 0);
	$self->add_color('orange',           255, 100, 0);
	$self->add_color('gray',             180, 180, 180);
	$self->add_color('nearwhite',        254, 254, 254);
	return;
}

sub size {
	my $self = shift;
	return wantarray ? @{ $self->{size} } : $self->{size};
}

sub data {
	my ($self, @names) = @_;
	return wantarray ? @{ $self->{data} } : $self->{data} unless @names;
	my @data = grep { my $name = $_->name; grep(/^$name$/, @names) } @{ $self->{data} };
	return wantarray ? @data : \@data;
}

sub add_data {
	my ($self, $data) = @_;
	push(@{ $self->{data} }, $data);
	return;
}

sub axes {
	my $self = shift;
	return $self->{axes};
}

sub get_image_name {
	my $self = shift;
	my $ext  = $self->ext;
	return $self->{imageName}{$ext} if $self->{imageName}{$ext};
	$self->{imageName}{$ext} = $self->{pg}->getUniqueName($ext);
	return $self->{imageName}{$ext};
}

sub imageName {
	my ($self, $name) = @_;
	return $self->get_image_name unless $name;
	$self->{imageName}{ $self->ext } = $name;
	return;
}

sub image_type {
	my ($self, $type, $ext) = @_;
	return $self->{type} unless $type;

	# Check type and extension are valid. The first element of @validExt is used as default.
	my @validExt;
	$type = lc($type);
	if ($type eq 'tikz') {
		$self->{type} = 'Tikz';
		@validExt = ('svg', 'png', 'pdf');
	} elsif ($type eq 'gd') {
		$self->{type} = 'GD';
		@validExt = ('png', 'gif');
	} else {
		warn "PGplot: Invalid image type $type.";
		return;
	}

	if ($ext) {
		if (grep(/^$ext$/, @validExt)) {
			$self->{ext} = $ext;
		} else {
			warn "PGplot: Invalid image extension $ext.";
		}
	} else {
		$self->{ext} = $validExt[0];
	}
	return;
}

# Tikz needs to use pdf for hardcopy generation.
sub ext {
	my $self = shift;
	return 'pdf' if ($self->{type} eq 'Tikz' && $main::displayMode eq 'TeX');
	return $self->{ext};
}

# Return a copy of the tikz code (available after the image has been drawn).
# Set $plot->{tikzDebug} to 1 to just generate the tikzCode, and not create a graph.
sub tikz_code {
	my $self = shift;
	return ($self->{tikzCode} && $main::displayMode =~ /HTML/) ? '<pre>' . $self->{tikzCode} . '</pre>' : '';
}

# Add functions to the graph.
sub value_to_sub {
	my ($self, $formula, $var) = @_;
	return sub { return $_[0]; }
		if $formula eq $var;
	unless (Value::isFormula($formula)) {
		my $localContext = Parser::Context->current(\%main::context)->copy;
		$localContext->variables->add($var => 'Real') unless $localContext->variables->get($var);
		$formula = Value->Package('Formula()')->new($localContext, $formula);
	}

	my $sub = $formula->perlFunction(undef, [$var]);
	return sub {
		my $x = shift;
		my $y = Parser::Eval($sub, $x);
		return defined $y ? $y->value : undef;
	};
}

sub _add_function {
	my ($self, $Fx, $Fy, $var, $min, $max, @rest) = @_;
	$var = 't'  unless $var;
	$Fx  = $var unless defined($Fx);
	my %options = (
		x_string => ref($Fx) eq 'CODE' ? 'perl' : Value::isFormula($Fx) ? $Fx->string : $Fx,
		y_string => ref($Fy) eq 'CODE' ? 'perl' : Value::isFormula($Fy) ? $Fy->string : $Fy,
		variable => $var,
		@rest
	);
	$Fx = $self->value_to_sub($Fx, $var) unless ref($Fx) eq 'CODE';
	$Fy = $self->value_to_sub($Fy, $var) unless ref($Fy) eq 'CODE';

	my $data = Plots::Data->new(name => 'function');
	$data->style(
		color  => 'default_color',
		width  => 1,
		dashed => 0,
		%options
	);
	$data->set_function(
		sub_x => $Fx,
		sub_y => $Fy,
		min   => $min,
		max   => $max,
	);
	$self->add_data($data);
	return $data;
}

# Format: Accepts both functions y = f(x) and parametric functions (x(t), y(t)).
#   f(x) for x in <a,b> using color:red and weight:3 and steps:15
#   x(t),y(t) for t in [a,b] using color:green and weight:1 and steps:35
#   (x(t),y(t)) for t in (a,b] using color:blue and weight:2 and steps:20
sub parse_function_string {
	my ($self, $fn) = @_;
	unless ($fn =~
		/^(.+)for\s*(\w+)\s*in\s*([\(\[\<\{])\s*([^,\s]+)\s*,\s*([^,\s]+)\s*([\)\]\>\}])\s*(using)?\s*(.*)?$/)
	{
		warn "Error parsing function: $fn";
		return;
	}

	my ($rule, $var, $start, $min, $max, $end, $options) = ($1, $2, $3, $4, $5, $6, $8);
	if    ($start eq '(') { $start = 'open_circle'; }
	elsif ($start eq '[') { $start = 'closed_circle'; }
	elsif ($start eq '{') { $start = 'arrow'; }
	else                  { $start = 'none'; }
	if    ($end eq ')') { $end = 'open_circle'; }
	elsif ($end eq ']') { $end = 'closed_circle'; }
	elsif ($end eq '}') { $end = 'arrow'; }
	else                { $end = 'none'; }

	# Deal with the possibility of 'option1:value1, option2:value2, and option3:value3'.
	$options =~ s/,\s*and/,/;
	my %opts = (
		start_mark => $start,
		end_mark   => $end,
		$options ? split(/\s*and\s*|\s*:\s*|\s*,\s*|\s*=\s*|\s+/, $options) : ()
	);

	if ($rule =~ /^\s*[\(\[\<]\s*([^,]+)\s*,\s*([^,]+)\s*[\)\]\>]\s*$/ || $rule =~ /^\s*([^,]+)\s*,\s*([^,]+)\s*$/) {
		my ($rule_x, $rule_y) = ($1, $2);
		return $self->_add_function($rule_x, $rule_y, $var, $min, $max, %opts);
	}
	return $self->_add_function($var, $rule, $var, $min, $max, %opts);
}

sub add_function {
	my ($self, $f, @rest) = @_;
	if ($f =~ /for.+in/) {
		return @rest ? [ map { $self->parse_function_string($_); } ($f, @rest) ] : $self->parse_function_string($f);
	} elsif (ref($f) eq 'ARRAY' && scalar(@$f) > 2) {
		my @data;
		for ($f, @rest) {
			my ($g, @options) = @$_;
			push(@data,
				ref($g) eq 'ARRAY'
				? $self->_add_function($g->[0], $g->[1], @options)
				: $self->_add_function(undef,   $g,      @options));
		}
		return scalar(@data) > 1 ? \@data : $data[0];
	}
	return ref($f) eq 'ARRAY' ? $self->_add_function($f->[0], $f->[1], @rest) : $self->_add_function(undef, $f, @rest);
}

# Add a dataset to the graph. A dataset is basically a function in which the data
# is provided as a list of points, [$x1, $y1], [$x2, $y2], ..., [$xn, $yn].
# Datasets can be used for points, arrows, lines, polygons, scatter plots, and so on.
sub _add_dataset {
	my ($self, @points) = @_;
	my $data = Plots::Data->new(name => 'dataset');
	while (@points) {
		last unless ref($points[0]) eq 'ARRAY';
		$data->add(@{ shift(@points) });
	}
	$data->style(
		color => 'default_color',
		width => 1,
		@points
	);

	$self->add_data($data);
	return $data;
}

sub add_dataset {
	my $self = shift;
	if (ref($_[0]) eq 'ARRAY' && ref($_[0]->[0]) eq 'ARRAY') {
		return [ map { $self->_add_dataset(@$_); } @_ ];
	}
	return $self->_add_dataset(@_);
}

sub _add_label {
	my ($self, $x, $y, @options) = @_;
	my $data = Plots::Data->new(name => 'label');
	$data->add($x, $y);
	$data->style(
		color       => 'default_color',
		fontsize    => 'medium',
		orientation => 'horizontal',
		h_align     => 'center',
		v_align     => 'middle',
		label       => '',
		@options
	);

	$self->add_data($data);
	return $data;
}

sub add_label {
	my $self = shift;
	return ref($_[0]) eq 'ARRAY' ? [ map { $self->_add_label(@$_); } @_ ] : $self->_add_label(@_);
}

# Fill regions only work with GD and are ignored in TikZ images.
sub _add_fill_region {
	my ($self, $x, $y, $color) = @_;
	my $data = Plots::Data->new(name => 'fill_region');
	$data->add($x, $y);
	$data->style(color => $color || 'default_color');
	$self->add_data($data);
	return $data;
}

sub add_fill_region {
	my $self = shift;
	return ref($_[0]) eq 'ARRAY' ? [ map { $self->_add_fill_region(@$_); } @_ ] : $self->_add_fill_region(@_);
}

sub _add_stamp {
	my ($self, $x, $y, @options) = @_;
	my $data = Plots::Data->new(name => 'stamp');
	$data->add($x, $y);
	$data->style(
		color  => 'default_color',
		size   => 4,
		symbol => 'closed_circle',
		@options
	);
	$self->add_data($data);
	return $data;
}

sub add_stamp {
	my $self = shift;
	return ref($_[0]) eq 'ARRAY' ? [ map { $self->_add_stamp(@$_); } @_ ] : $self->_add_stamp(@_);
}

# Output the image based on a configurable type:
sub draw {
	my $self = shift;
	my $type = $self->{type};

	my $image;
	if ($type eq 'GD') {
		$image = Plots::GD->new($self);
	} elsif ($type eq 'Tikz') {
		$image = Plots::Tikz->new($self);
	} else {
		warn "Undefined image type: $type";
		return;
	}
	return $image->draw;
}

1;
