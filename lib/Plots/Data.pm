
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

Configures a function to generate data points. C<Fx> and C<Fy> are strings (which are
turned into MathObjects), MathObjects, or per subroutines. The core function data is
stored in the C<< $data->{function} >> hash, though other data is stored as a style.

    $data->set_function(
        $self->context,
        Fx    => Formula('t'),
        Fy    => Formula('t^2'),
        var   => 't',
        min   => -5,
        max   =>  5,
        steps => 50,
    );

Note, the first argument must be $self->context when called from C<Plots::Plot>
to use a single context for all C<Plost::Data> objects.

This is also used to set a two variable function (used for slope or vector fields):

    $data->set_function(
        $self->context,
        Fx     => Formula('x^2 + y^2'),
        Fy     => Formula('x - y'),
        xvar   => 'x',
        yvar   => 'y',
        xmin   => -5,
        xmax   =>  5,
        ymin   => -5,
        ymax   =>  5
        xsteps => 15,
        ysteps => 15,
    );

Note a function always stores the coordinate variables as C<xmin>, C<xmax>, C<xvar>, etc.
When using a single variable function just use the x-coordinate values. C<min>, C<max>, C<var>,
C<steps>, will set the x-coordinate values and will override any C<xmin>, C<xmax>, etc settings.

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

=item C<< $str = $data->function_string($coord, $type, $nvars); >>

Takes a MathObject function string and replaces the function with either
a JavaScript or PGF function string. If the function contains any function
tokens not supported, a warning and empty string is returned.

    $coord   'x' or 'y' coordinate function.
    $type    'js' or 'PGF' (falls back to js for any input except 'PGF').
    $nvars   1 (single variable functions) or 2 (used for slope/vector fields).

=item C<< $data->update_min_max >>

Updates a functions C<xmin>, C<xmax>, C<ymin>, and C<ymax> values to reals
using MathObjects. This allows end points like 'pi', 'e', etc.

=item C<< $data->get_start_point >>

Gets the starting (left end) point of a function. This should be used when using
function strings to avoid generating the function data.

=item C<< $data->get_end_point >>

Gets the ending (right end) point of a function. This should be used when using
function strings to avoid generating the function data.

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
	return $self->{x}[$n] if (defined($n) && defined($self->{x}[$n]));
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
	if (ref($styles[0]) eq 'HASH') {
		map { $self->{styles}{$_} = $styles[0]{$_} } keys %{ $styles[0] };
		return;
	}
	if (@styles % 2 == 0) {
		my %style_hash = @styles;
		map { $self->{styles}{$_} = $style_hash{$_} } keys %style_hash;
		return;
	}
	return $self->{styles}{ $styles[0] } // '';
}

sub get_math_object {
	my ($self, $formula, $xvar, $yvar) = @_;
	return $formula if ref($formula) eq 'CODE' || Value::isFormula($formula);
	my $context = $self->{context};
	$context->variables->add($xvar => 'Real') unless $context->variables->get($xvar);
	$context->variables->add($yvar => 'Real') if $yvar && !$context->variables->get($yvar);
	$formula = Value->Package('Formula')->new($context, $formula);
	return $formula;
}

sub set_function {
	my ($self, $context, %options) = @_;
	$self->{context} = $context;
	my $f = {
		Fx     => 't',
		Fy     => '',
		xvar   => 't',
		yvar   => '',
		xmin   => -5,
		xmax   =>  5,
		ymin   => -5,
		ymax   =>  5,
		xsteps =>  30,
		ysteps =>  15,
	};
	for my $key ('Fx', 'Fy', 'xvar', 'yvar', 'xmin', 'xmax', 'ymin', 'ymax', 'xsteps', 'ysteps') {
		next unless defined $options{$key};
		$f->{$key} = $options{$key};
		delete $options{$key};
	}
	for my $key ('var', 'min', 'max', 'steps') {
		next unless defined $options{$key};
		$f->{"x$key"} = $options{$key};
		delete $options{$key};
	}
	return unless $f->{Fy};

	$f->{Fx}          = $self->get_math_object($f->{Fx}, $f->{xvar}, $f->{yvar});
	$f->{Fy}          = $self->get_math_object($f->{Fy}, $f->{xvar}, $f->{yvar});
	$self->{function} = $f;
	$self->style(%options) if %options;
	return;
}

sub str_to_real {
	my ($self, $val) = @_;
	return $val if !$val || $val !~ /[^\d\-\.]/;
	return Value->Package('Real')->new($self->{context}, $val)->value;
}

sub update_min_max {
	my $self = shift;
	my $f    = $self->{function};
	$f->{xmin} = $self->str_to_real($f->{xmin});
	$f->{xmax} = $self->str_to_real($f->{xmax});
	$f->{ymin} = $self->str_to_real($f->{ymin});
	$f->{ymax} = $self->str_to_real($f->{ymax});
	return;
}

sub function_string {
	my ($self, $coord, $type, $nvars) = @_;
	my $f  = $self->{function};
	my $MO = $coord eq 'y' ? $f->{Fy} : $f->{Fx};
	return '' if ref($MO) eq 'CODE';

	# Ensure -x^2 gets print as -(x^2), since JavaScript finds this ambiguous.
	my $extraParens = $MO->context->flag('showExtraParens');
	$MO->context->flags->set(showExtraParens => 2);
	my $func = $MO->string;
	$func =~ s/\s//g;
	$MO->context->flags->set(showExtraParens => $extraParens);

	$nvars = 1 unless $nvars;
	my %tokens;
	if ($type eq 'PGF') {
		my %vars = ($nvars == 2 ? ($f->{xvar} => 'x', $f->{yvar} => 'y') : ($f->{xvar} => 'x'));
		%tokens = (
			sqrt   => 'sqrt',
			pow    => 'pow',
			exp    => 'e^',
			abs    => 'abs',
			round  => 'round',
			floor  => 'floor',
			ceil   => 'ceil',
			sign   => 'sign',
			int    => 'int',
			log    => 'ln',
			ln     => 'ln',
			cos    => 'cos',
			sin    => 'sin',
			tan    => 'tan',
			sec    => 'sec',
			csc    => 'csc',
			cot    => 'cot',
			acos   => 'acos',
			arccos => 'acos',
			asin   => 'asin',
			arcsin => 'asin',
			atan   => 'atan',
			arctan => 'atan',
			atan2  => 'atan2',
			cosh   => 'cosh',
			sinh   => 'sinh',
			tanh   => 'tanh',
			min    => 'min',
			max    => 'max',
			random => 'rnd',
			e      => 'e',
			pi     => 'pi',
			'^'    => '^',
			%vars
		);
	} else {
		my %vars = ($nvars == 2 ? ($f->{xvar} => 'x', $f->{yvar} => 'y') : ($f->{xvar} => 't'));
		%tokens = (
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
			%vars
		);
	}

	my $out = '';
	my $match;
	while (length($func) > 0) {
		if (($match) = ($func =~ m/^([A-Za-z]+|\^)/)) {
			$func = substr($func, length($match));
			if ($tokens{$match}) {
				$out .= $tokens{$match};
			} else {
				warn "Unsupported token $match in function. Generating points manually.";
				return '';
			}
		} elsif (($match) = ($func =~ m/^([^A-Za-z^]+)/)) {
			$func = substr($func, length($match));
			$out .= $match;
		} else {    # Shouldn't happen, but to stop an infinite loop for safety.
			warn 'Unknown error parsing function. Generating points manually.';
			return '';
		}
	}

	return $out;
}

sub stepsize {
	my ($self, $steps, $var) = @_;
	my $f = $self->{function};
	$self->update_min_max;
	return ($f->{"${var}max"} - $f->{"${var}min"}) / $steps;
}

sub get_generator_sub {
	my ($self, $coord) = @_;
	my $f = $self->{function};
	return $f->{"sub_$coord"} if $f->{"sub_$coord"};
	my $MO = $f->{"F$coord"};
	return $MO if ref($MO) eq 'CODE';
	if ($MO->string eq $f->{xvar}) {
		$f->{"sub_$coord"} = sub { return $_[0]; }
	} else {
		my $sub = $MO->perlFunction(undef, [ $f->{xvar} ]);
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
	my $steps = $f->{xsteps};
	my $dt    = $self->stepsize($steps, 'x');
	my $t     = $f->{xmin};
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
	return (&{$sub_x}($f->{xmin}), &{$sub_y}($f->{xmin}));
}

sub get_end_point {
	my $self = shift;
	return ($self->x(-1), $self->y(-1)) if $self->size;
	my $f     = $self->{function};
	my $sub_x = $self->get_generator_sub('x');
	my $sub_y = $self->get_generator_sub('y');
	return (&{$sub_x}($f->{xmax}), &{$sub_y}($f->{xmax}));
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
