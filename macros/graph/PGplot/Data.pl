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

=head1 NAME

Data.pl - Base data class for PGplot elements (functions, labels, etc).

=head1 DESCRIPTION

This is a data class to hold data about the different types of elements
that can be added to a PGplot graph. This is a hash with some helper methods.
Data objects are created and modified using the L<PGplot|PGplot.pl> methods,
and do not need to generally be modified in a PG problem.  Each PG add method
returns the related data object which can be used if needed.

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

=item C<$data-E<gt>name>

Sets, C<$data-E<gt>name($string)>, or gets C<$data-E<gt>name> the name of the data object.

=item C<$data-E<gt>add>

Adds a single data point, C<$data-E<gt>add($x, $y)>, or adds multiple data points,
C<$data-E<gt>add([$x1, $y1], [$x2, $y2], ..., [$xn, $yn])>.

=item C<$data-E<gt>set_function>

Configures a function to generate data points. C<sub_x> and C<sub_y> are are perl subroutines.

    $data->set_function(
        sub_x => sub { return $_[0]; },
        sub_y => sub { return $_[0]**2; },
        min   => -5,
        max   => 5,
    );

The number of steps used to generate the data is a style and needs to be set separately.

    $data->style(steps => 50);

=item C<$data-E<gt>gen_data>

Generate the data points from a function. This can only be done when there is no data, so
once the data has been generated this will do nothing (to avoid generating data again).

=item C<$data-E<gt>size>

Returns the current number of points being stored.

=item C<$data-E<gt>x> and C<$data-E<gt>y>

Without any inputs, these return either the x array or y array of data points being stored.
A single input can be used to return only the n-th data point, C<$data-E<gt>x($n)>.

=item C<$data-E<gt>style>

Sets or gets style information. Use C<$data-E<gt>style($name)> to get the style value of a single
style name. C<$data-E<gt>style> will returns a reference to the full style hash. Last, input a hash
to add / change the styles.

    $data->style(color => 'blue', width => 3);

=back

=cut

BEGIN {
	strict->import;
}

sub _Data_init { }

package PGplot::Data;

sub new {
	my $class = shift;
	my $self  = {
		name     => '',
		x        => [],
		y        => [],
		function => {},
		styles   => {},
		@_
	};

	bless $self, $class;
	return $self;
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

sub set_function {
	my $self = shift;
	$self->{function} = {
		sub_x => sub { return $_[0]; },
		sub_y => sub { return $_[0]; },
		min   => -5,
		max   => 5,
		@_
	};
	$self->style(steps => $self->{function}{steps}) if $self->{funciton}{steps};
	return;
}

sub _stepsize {
	my $self  = shift;
	my $f     = $self->{function};
	my $steps = $self->style('steps') || 20;
	# Using MathObjects allows bounds like 2pi/3, e^2, et, etc.
	$f->{min} = &main::Real($f->{min})->value if ($f->{min} =~ /[^\d\-\.]/);
	$f->{max} = &main::Real($f->{max})->value if ($f->{max} =~ /[^\d\-\.]/);
	return ($f->{max} - $f->{min}) / $steps;
}

sub gen_data {
	my $self = shift;
	my $f    = $self->{function};
	return if !$f || $self->size;
	my $steps = $self->style('steps') || 20;
	my $dt    = $self->_stepsize;
	my $t     = $f->{min};
	for (0 .. $steps) {
		$self->add(&{ $f->{sub_x} }($t), &{ $f->{sub_y} }($t));
		$t += $dt;
	}
	return;
}

sub _add {
	my ($self, $x, $y) = @_;
	return unless defined($x) && defined($y);
	push(@{ $self->{x} }, $x);
	push(@{ $self->{y} }, $y);
	return;
}

sub add {
	my $self = shift;
	if (ref($_[0]) eq 'ARRAY') {
		for (@_) { $self->_add(@$_); }
	} else {
		$self->_add(@_);
	}
	return;
}

1;
