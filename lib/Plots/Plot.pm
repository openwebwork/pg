
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
use Plots::JSXGraph;

sub new {
	my ($class, %options) = @_;

	my $self = bless {
		imageName       => {},
		width           => eval('$main::envir{onTheFlyImageSize}') || 350,
		height          => undef,
		tex_size        => 600,
		rounded_corners => 0,
		axes            => Plots::Axes->new,
		colors          => {},
		data            => [],
	}, $class;

	# Besides for these core options, pass everything else to the Axes object.
	for ('width', 'height', 'tex_size', 'rounded_corners') {
		$self->{$_} = delete $options{$_} if $options{$_};
	}
	$self->axes->set(%options) if %options;

	$self->{pg} = eval('$main::PG');
	$self->color_init;
	$self->image_type('JSXGraph');
	return $self;
}

sub pgCall {
	my ($call, @args) = @_;
	return WeBWorK::PG::Translator::PG_restricted_eval('\&' . $call)->(@args);
}

sub add_js_file {
	my ($self, $file, $attributes) = @_;
	pgCall('ADD_JS_FILE', $file, 0, $attributes);
	return;
}

sub add_css_file {
	my ($self, $file) = @_;
	pgCall('ADD_CSS_FILE', $file);
	return;
}

sub context {
	my $self = shift;
	return $self->{context} if $self->{context};
	$self->{context} = Parser::Context->current->copy;
	return $self->{context};
}

sub colors {
	my ($self, $color) = @_;
	return defined($color) ? $self->{colors}{$color} : $self->{colors};
}

sub add_color {
	my ($self, @colors) = @_;
	if (ref($colors[0]) eq 'ARRAY') {
		for (@colors) { $self->{colors}{ $_->[0] } = [ @$_[ 1 .. 3 ] ]; }
	} else {
		$self->{colors}{ $colors[0] } = [ @colors[ 1 .. 3 ] ];
	}
	return;
}

# Define some base colors.
sub color_init {
	my $self = shift;
	$self->add_color('default_color', 0,   0,   0);
	$self->add_color('white',         255, 255, 255);
	$self->add_color('gray',          128, 128, 128);
	$self->add_color('grey',          128, 128, 128);
	$self->add_color('black',         0,   0,   0);
	# Primary and secondary RGB colors (using HTML green instead of RGB green).
	$self->add_color('red',     255, 0,   0);
	$self->add_color('green',   0,   128, 0);
	$self->add_color('blue',    0,   0,   255);
	$self->add_color('yellow',  255, 255, 0);
	$self->add_color('cyan',    0,   255, 255);
	$self->add_color('magenta', 255, 0,   255);
	# Additional RYB secondary colors.
	$self->add_color('orange', 255, 128, 0);
	$self->add_color('purple', 128, 0,   128);
	return;
}

sub size {
	my $self   = shift;
	my $axes   = $self->axes;
	my $width  = $self->{width};
	my $height = $self->{height};
	unless ($height) {
		if ($axes->style('aspect_ratio')) {
			my $x_size = $axes->xaxis('max') - $axes->xaxis('min');
			my $y_size = $axes->yaxis('max') - $axes->yaxis('min');
			$height = int($axes->style('aspect_ratio') * $width * $y_size / $x_size);
		} else {
			$height = $width;
		}
	}
	return wantarray ? ($width, $height) : [ $width, $height ];
}

sub data {
	my ($self, @names) = @_;
	return wantarray ? @{ $self->{data} } : $self->{data} unless @names;
	my @data = grep {
		my $name = $_->name;
		grep {/^$name$/} @names
	} @{ $self->{data} };
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

	# Hardcopy uses the Tikz 'pdf' extension and PTX uses the Tikz 'tgz' extension.
	if ($self->{pg}{displayMode} eq 'TeX') {
		$self->{type} = 'Tikz';
		$self->{ext}  = 'pdf';
		return;
	} elsif ($self->{pg}{displayMode} eq 'PTX') {
		$self->{type} = 'Tikz';
		$self->{ext}  = 'tgz';
		return;
	}

	# Check type and extension are valid. The first element of @validExt is used as default.
	my @validExt;
	$type = lc($type);
	if ($type eq 'jsxgraph') {
		$self->{type} = 'JSXGraph';
		@validExt = ('html');
	} elsif ($type eq 'tikz') {
		$self->{type} = 'Tikz';
		@validExt = ('svg', 'png', 'pdf', 'gif', 'tgz');
	} else {
		warn "Plots: Invalid image type $type.";
		return;
	}

	if ($ext) {
		if (grep {/^$ext$/} @validExt) {
			$self->{ext} = $ext;
		} else {
			warn "Plots: Invalid image extension $ext.";
		}
	} else {
		$self->{ext} = $validExt[0];
	}

	return;
}

sub ext {
	return (shift)->{ext};
}

# Return a copy of the tikz code (available after the image has been drawn).
# Set $plot->{tikzDebug} to 1 to just generate the tikzCode, and not create a graph.
sub tikz_code {
	my $self = shift;
	return $self->{tikzCode} && $self->{pg}{displayMode} =~ /HTML/ ? '<pre>' . $self->{tikzCode} . '</pre>' : '';
}

# Add functions to the graph.
sub _add_function {
	my ($self, $Fx, $Fy, $var, $min, $max, %rest) = @_;
	$var = 't'  unless $var;
	$Fx  = $var unless defined($Fx);

	my $data = Plots::Data->new(name => 'function');
	$data->set_function(
		$self->context,
		Fx          => $Fx,
		Fy          => $Fy,
		xvar        => $var,
		xmin        => $min,
		xmax        => $max,
		color       => 'default_color',
		width       => 2,
		mark_size   => 2,
		dashed      => 0,
		tikz_smooth => 1,
		%rest
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
	elsif ($start eq '[') { $start = 'circle'; }
	elsif ($start eq '{') { $start = 'arrow'; }
	else                  { $start = 'none'; }
	if    ($end eq ')') { $end = 'open_circle'; }
	elsif ($end eq ']') { $end = 'circle'; }
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

sub add_multipath {
	my ($self, $paths, $var, %options) = @_;
	my $data  = Plots::Data->new(name => 'multipath');
	my $steps = 100 * @$paths;                           # Steps set high to help Tikz deal with boundaries of paths.
	$steps           = delete $options{steps} if $options{steps};
	$data->{context} = $self->context;
	$data->{paths}   = [
		map { {
			Fx   => $data->get_math_object($_->[0], $var),
			Fy   => $data->get_math_object($_->[1], $var),
			tmin => $data->str_to_real($_->[2]),
			tmax => $data->str_to_real($_->[3])
		} } @$paths
	];
	$data->{function} = { var => $var, steps => $steps };
	$data->style(color => 'default_color', width => 2, mark_size => 2, %options);

	$self->add_data($data);
	return $data;
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
		color     => 'default_color',
		width     => 2,
		mark_size => 2,
		@points
	);

	$self->add_data($data);
	return $data;
}

sub add_dataset {
	my ($self, @data) = @_;
	if (ref($data[0]) eq 'ARRAY' && ref($data[0][0]) eq 'ARRAY') {
		return [ map { $self->_add_dataset(@$_); } @data ];
	}
	return $self->_add_dataset(@data);
}

sub _add_circle {
	my ($self, $point, $radius, @options) = @_;
	my $data = Plots::Data->new(name => 'circle');
	$data->add(@$point);
	$data->style(
		radius    => $radius,
		color     => 'default_color',
		width     => 2,
		mark_size => 2,
		@options
	);

	$self->add_data($data);
	return $data;
}

sub add_circle {
	my ($self, @data) = @_;
	if (ref($data[0]) eq 'ARRAY' && ref($data[0][0]) eq 'ARRAY') {
		return [ map { $self->_add_circle(@$_); } @data ];
	}
	return $self->_add_circle(@data);
}

sub _add_arc {
	my ($self, $point1, $point2, $point3, @options) = @_;
	my $data = Plots::Data->new(name => 'arc');
	$data->add($point1, $point2, $point3);
	$data->style(
		color     => 'default_color',
		width     => 2,
		mark_size => 2,
		@options
	);

	$self->add_data($data);
	return $data;
}

sub add_arc {
	my ($self, @data) = @_;
	if (ref($data[0]) eq 'ARRAY' && ref($data[0][0]) eq 'ARRAY') {
		return [ map { $self->_add_arc(@$_); } @data ];
	}
	return $self->_add_arc(@data);
}

sub add_vectorfield {
	my ($self, @options) = @_;
	my $data = Plots::Data->new(name => 'vectorfield');
	$data->set_function(
		$self->context,
		Fx        => '',
		Fy        => '',
		xvar      => 'x',
		yvar      => 'y',
		xmin      => -5,
		xmax      =>  5,
		ymin      => -5,
		ymax      =>  5,
		xsteps    =>  15,
		ysteps    =>  15,
		width     =>  1,
		mark_size =>  1,
		color     => 'default_color',
		@options
	);

	$self->add_data($data);
	return $data;
}

sub _add_label {
	my ($self, $x, $y, @options) = @_;
	my $data  = Plots::Data->new(name => 'label');
	my $label = @options % 2 ? shift @options : '';
	$data->add($x, $y);
	$data->style(
		color       => 'default_color',
		fontsize    => 'medium',
		orientation => 'horizontal',
		rotate      => 0,
		h_align     => 'center',
		v_align     => 'middle',
		label       => $label,
		@options
	);

	$self->add_data($data);
	return $data;
}

sub add_label {
	my ($self, @labels) = @_;
	return ref($labels[0]) eq 'ARRAY' ? [ map { $self->_add_label(@$_); } @labels ] : $self->_add_label(@labels);
}

sub _add_point {
	my ($self, $x, $y, %options) = @_;
	$options{marks} = delete $options{mark} if $options{mark} && !defined $options{marks};
	my $data = $self->_add_dataset([ $x, $y ], marks => 'circle', %options);
	$data->{name} = 'point';
	return $data;
}

sub add_point {
	my ($self, @points) = @_;
	return ref($points[0]) eq 'ARRAY' ? [ map { $self->_add_point(@$_); } @points ] : $self->_add_point(@points);
}

sub _add_stamp {
	my ($self, $x, $y, @options) = @_;
	my $data = Plots::Data->new(name => 'stamp');
	$data->add($x, $y);
	$data->style(
		color  => 'default_color',
		radius => 4,
		symbol => 'circle',
		@options
	);
	$self->add_data($data);
	return $data;
}

sub add_stamp {
	my ($self, @stamps) = @_;
	return ref($stamps[0]) eq 'ARRAY' ? [ map { $self->_add_stamp(@$_); } @stamps ] : $self->_add_stamp(@stamps);
}

# Output the image based on a configurable type:
sub draw {
	my $self = shift;
	my $type = $self->{type};

	my $image;
	if ($type eq 'Tikz') {
		$image = Plots::Tikz->new($self);
	} elsif ($type eq 'JSXGraph') {
		$image = Plots::JSXGraph->new($self);
	} else {
		warn "Undefined image type: $type";
		return;
	}
	return $image->draw;
}

1;
