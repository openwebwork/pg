
=head1 DATA OBJECT

This object holds data about the different types of elements that can be added to a
Plots graph. This is a hash with some helper methods. Data objects are created and
modified using the Plots methods, and do not need to generally be modified in a PG
problem.  Each PG add method returns the related data object which can be used if needed.

Each data object contains the following:

=over 5

=item name

The name is used to identify what type of data is being stored,
such as a function, dataset, label, etc.

=item x

The array of the data points x-value.

=item y

The array of the data points y-value.

=item function

A function (stored as a hash) to generate the x and y data points.

=item styles

An hash of different style options and values that can be used
to store additional data for things like color, width, etc.

=back

=head1 USAGE

The main methods for adding data and accessing the data are:

=over 5

=item C<< $data->name >>

Sets, C<< $data->name($string) >>, or gets C<< $data->name >> the name of the data object.

=item C<< $data->add >>

Adds a single data point, C<< $data->add($x, $y) >>, or adds multiple data points,
C<< $data->add([$x1, $y1], [$x2, $y2], ..., [$xn, $yn]) >>.

=item C<< $data->set_function >>

Configures a function to generate data points. C<Fx> and C<Fy> are MathObjects
or perl subroutines.

    $data->set_function(
        Fx  => Formula('t'),
        Fy  => Formula('t^2'),
        min => -5,
        max =>  5,
    );

The number of steps used to generate the data is a style and needs to be set separately.

    $data->style(steps => 50);

=item C<< $data->gen_data >>

Generate the data points from a function. This can only be done when there is no data, so
once the data has been generated this will do nothing (to avoid generating data again).

=item C<< $data->size >>

Returns the current number of points being stored.

=item C<< $data->x >> and C<< $data->y >>

Without any inputs, these return either the x array or y array of data points being stored.
A single input can be used to return only the n-th data point, C<< $data->x($n) >>.

=item C<< $data->style >>

Sets or gets style information. Use C<< $data->style($name) >> to get the style value of a single
style name. C<< $data->style >> will returns a reference to the full style hash. Last, input a hash
to add / change the styles.

    $data->style(color => 'blue', width => 3);

=back

=cut

package Plots::Data;

use strict;
use warnings;

sub new {
	my ($class, %options) = @_;
	return bless { name => '', x => [], y => [], function => {}, styles => {}, %options }, $class;
}

sub name {
	my ($self, $name) = @_;
	return $self->{name} unless $name;
	$self->{name} = $name;
	return;
}

sub size {
	my $self = shift;
	return scalar(@{ $self->{x} });
}

sub x {
	my ($self, $n) = @_;
	return $self->{x}->[$n] if (defined($n) && defined($self->{x}->[$n]));
	return wantarray ? @{ $self->{x} } : $self->{x};
}

sub y {
	my ($self, $n) = @_;
	return $self->{y}[$n] if (defined($n) && defined($self->{y}[$n]));
	return wantarray ? @{ $self->{y} } : $self->{y};
}

sub style {
	my ($self, @styles) = @_;
	return $self->{styles} unless @styles;
	if (scalar(@styles) > 1) {
		my %style_hash = @styles;
		map { $self->{styles}{$_} = $style_hash{$_}; } (keys %style_hash);
		return;
	}
	my $style = $styles[0];
	if (ref($style) eq 'HASH') {
		map { $self->{styles}{$_} = $style->{$_}; } (keys %$style);
		return;
	}
	return $self->{styles}{$style};
}

sub get_math_object {
	my ($self, $formula, $var) = @_;
	return $formula if ref($formula) eq 'CODE' || Value::isFormula($formula);
	my $localContext = Parser::Context->current(\%main::context)->copy;
	$localContext->variables->are($var => 'Real') unless $localContext->variables->get($var);
	$formula = Value->Package('Formula')->new($localContext, $formula);
	return $formula;
}

sub set_function {
	my ($self, %options) = @_;
	my $f = { Fx => 't', Fy => '', var => 't', min => -5, max => 5 };
	for my $key ('Fx', 'Fy', 'var', 'min', 'max') {
		next unless defined $options{$key};
		$f->{$key} = $options{$key};
		delete $options{$key};
	}
	return unless $f->{Fy};

	$f->{Fx}          = $self->get_math_object($f->{Fx}, $f->{var});
	$f->{Fy}          = $self->get_math_object($f->{Fy}, $f->{var});
	$self->{function} = $f;
	$self->style(%options) if %options;
	return;
}

# Using MathObjects allows string values like 2pi/3, e^2, sqrt(2), etc.
sub str_to_real {
	my ($self, $val) = @_;
	return $val if !$val || $val !~ /[^\d\-\.]/;
	my $localContext = Parser::Context->current(\%main::context);
	return Value->Package('Real')->new($localContext, $val)->value;
}

sub update_min_max {
	my $self = shift;
	my $f    = $self->{function};
	$f->{min} = $self->str_to_real($f->{min});
	$f->{max} = $self->str_to_real($f->{max});
	return;
}

# Takes a MathObject function string and replaces with JavaScript functions.
# Function takes either 'x' or 'y' for the corresponding coordinate function.
sub func_to_js {
	my ($self, $coord) = @_;
	my $f  = $self->{function};
	my $MO = $coord eq 'x' ? $f->{Fx} : $coord eq 'y' ? $f->{Fy} : '';
	unless ($MO) {
		warn "Invalid coordinate: $coord";
		return '';
	}

	# Ensure -x^2 gets print as -(x^2), since JavaScript finds this ambiguous.
	my $extraParens = $MO->context->flag('showExtraParens');
	$MO->context->flags->set(showExtraParens => 2);
	my $func = $MO->string;
	$func =~ s/\s//g;
	$MO->context->flags->set(showExtraParens => $extraParens);

	my $var    = $f->{var};
	my %tokens = (
		sqrt    => 'Math.sqrt',
		cbrt    => 'Math.cbrt',
		hypot   => 'Math.hypot',
		norm    => 'Math.hypot',
		pow     => 'Math.pow',
		exp     => 'Math.exp',
		abs     => 'Math.abs',
		round   => 'Math.round',
		floor   => 'Math.floor',
		ceil    => 'Math.ceil',
		sign    => 'Math.sign',
		int     => 'Math.trunc',
		log     => 'Math.ln',
		ln      => 'Math.ln',
		cos     => 'Math.cos',
		sin     => 'Math.sin',
		tan     => 'Math.tan',
		acos    => 'Math.acos',
		arccos  => 'Math.acos',
		asin    => 'Math.asin',
		arcsin  => 'Math.asin',
		atan    => 'Math.atan',
		arctan  => 'Math.atan',
		atan2   => 'Math.atan2',
		cosh    => 'Math.cosh',
		sinh    => 'Math.sinh',
		tanh    => 'Math.tanh',
		acosh   => 'Math.acosh',
		arccosh => 'Math.arccosh',
		asinh   => 'Math.asinh',
		arcsinh => 'Math.asinh',
		atanh   => 'Math.atanh',
		arctanh => 'Math.arctanh',
		min     => 'Math.min',
		max     => 'Math.max',
		random  => 'Math.random',
		e       => 'Math.E',
		pi      => 'Math.PI',
		'^'     => '**',
		$var    => $var
	);

	my $out = '';
	my $match;
	while (length($func) > 0) {
		if (($match) = ($func =~ m/^([A-Za-z]+|\^)/)) {
			$func = substr($func, length($match));
			if ($tokens{$match}) {
				$out .= $tokens{$match};
			} else {
				warn "Unknown token $match in function.";
				return '';
			}
		} elsif (($match) = ($func =~ m/^([^A-Za-z^]+)/)) {
			$func = substr($func, length($match));
			$out .= $match;
		} else {    # Shouldn't happen, but to stop an infinite loop for safety.
			warn 'Unknown error parsing function.';
			last;
		}
	}

	return "function($var){ return $out; }";
}

sub stepsize {
	my ($self, $steps) = @_;
	my $f = $self->{function};
	$self->update_min_max;
	return ($f->{max} - $f->{min}) / $steps;
}

sub get_generator_sub {
	my ($self, $coord) = @_;
	my $f = $self->{function};
	return $f->{"sub_$coord"} if $f->{"sub_$coord"};
	my $MO = $f->{"F$coord"};
	return $MO if ref($MO) eq 'CODE';
	if ($MO->string eq $f->{var}) {
		$f->{"sub_$coord"} = sub { return $_[0]; }
	} else {
		my $sub = $MO->perlFunction(undef, [ $f->{var} ]);
		$f->{"sub_$coord"} = sub {
			my $x = shift;
			my $y = Parser::Eval($sub, $x);
			return defined $y ? $y->value : undef;
		}
	}
	return $f->{"sub_$coord"};
}

sub gen_data {
	my $self = shift;
	my $f    = $self->{function};
	return if !$f || $self->size;    # Only generate the data once.
	my $steps = $self->style('steps') || 30;
	my $dt    = $self->stepsize($steps);
	my $t     = $f->{min};
	my $sub_x = $self->get_generator_sub('x');
	my $sub_y = $self->get_generator_sub('y');

	for (0 .. $steps) {
		$self->add(&{$sub_x}($t), &{$sub_y}($t));
		$t += $dt;
	}
	return;
}

sub get_start_point {
	my $self = shift;
	return ($self->x(0), $self->y(0)) if $self->size;
	my $f     = $self->{function};
	my $sub_x = $self->get_generator_sub('x');
	my $sub_y = $self->get_generator_sub('y');
	return (&{$sub_x}($f->{min}), &{$sub_y}($f->{min}));
}

sub get_end_point {
	my $self = shift;
	return ($self->x(-1), $self->y(-1)) if $self->size;
	my $f     = $self->{function};
	my $sub_x = $self->get_generator_sub('x');
	my $sub_y = $self->get_generator_sub('y');
	return (&{$sub_x}($f->{max}), &{$sub_y}($f->{max}));
}

sub _add {
	my ($self, $x, $y) = @_;
	return unless defined($x) && defined($y);
	push(@{ $self->{x} }, $x);
	push(@{ $self->{y} }, $y);
	return;
}

sub add {
	my ($self, @points) = @_;
	if (ref($points[0]) eq 'ARRAY') {
		for (@points) { $self->_add(@$_); }
	} else {
		$self->_add(@points);
	}
	return;
}

1;
