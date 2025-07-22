package Rserve::REXP;

use strict;
use warnings;

use Carp         qw(croak);
use Scalar::Util qw(blessed);

use overload
	eq       => sub { shift->_eq(@_) },
	ne       => sub { !shift->_eq(@_) },
	bool     => sub {1},
	fallback => 1;

sub new {
	my ($invocant, @args) = @_;
	my $class = ref($invocant) || $invocant;

	my $self;

	if (@args == 1 && ref $args[0] eq 'HASH') {
		my %copy = eval { %{ $args[0] } };    # try shallow copy
		croak("Argument to $class->new could not be dereferenced as a hash") if $@;
		$self = \%copy;
	} elsif (@args % 2 == 0) {
		$self = {@args};
	} else {
		croak("$class->new got an odd number of elements");
	}

	$self = bless $self, $class;

	die "This is an abstract class and must be subclassed" if ref($self) eq __PACKAGE__;

	for my $req (qw/sexptype to_perl/) {
		die "$req method required" unless $self->can($req);
	}

	die "Attribute 'attributes' must be a hash reference"
		if defined $self->attributes && ref($self->attributes) ne 'HASH';

	return bless $self, $class;
}

sub attributes { my $self = shift; return $self->{attributes}; }

sub _eq {
	my ($self, $other) = (shift, shift);
	return unless _mutual_isa($self, $other);
	return _compare_deeply($self->attributes, $other->attributes);
}

# Returns true if either argument is a subclass of the other
sub _mutual_isa {
	my ($first, $second) = @_;

	return ref $first eq ref $second
		|| (blessed($first) && blessed($second) && ($first->isa(ref $second) || $second->isa(ref $first)));
}

sub _compare_deeply {
	my ($first, $second) = @_;

	if (defined($first) && defined($second)) {
		return 0 unless _mutual_isa($first, $second);
		if (ref $first eq 'ARRAY') {
			return unless @$first == @$second;
			for (my $i = 0; $i < @$first; $i++) {
				return unless _compare_deeply($first->[$i], $second->[$i]);
			}
		} elsif (ref $first eq 'HASH') {
			return unless scalar(keys %$first) == scalar(keys %$second);
			for my $name (keys %$first) {
				return
					unless exists $second->{$name}
					&& _compare_deeply($first->{$name}, $second->{$name});
			}
		} else {
			return unless $first eq $second;
		}
	} else {
		return if defined($first) || defined($second);
	}

	return 1;
}

sub is_null {
	return 0;
}

sub is_vector {
	return 0;
}

sub inherits {
	my ($self, $class) = @_;
	my $attributes = $self->attributes;
	return unless $attributes && $attributes->{class};
	return grep {/^$class$/} @{ $attributes->{class}->to_perl };
}

1;

__END__

=encoding UTF-8

=head1 NAME

Rserve::REXP - base class for R objects (C<SEXP>s)

=head1 SYNOPSIS

    use Rserve::REXP;

    # REXPs are stringifiable
    say $rexp;

    # REXPs can be converted to the closest native Perl data type
    print $rexp->to_perl;

=head1 DESCRIPTION

An object of this class represents a native R object. This class cannot be
directly instantiated (it will die if you call C<new> on it), because it is
intended as a base abstract class with concrete subclasses to represent specific
object types.

An R object has a value and an optional set of named attributes, which
themselves are R objects. Because the meaning of 'value' depends on the actual
object type (for example, a vector vs. a C<NULL>, in R terminology), C<REXP>
does not provide a generic value accessor method, although individual subclasses
will typically have one.

=head1 METHODS

=head2 attributes

Returns a hash reference to the object's attributes.

=head2 sexptype

Returns the I<name> of the corresponding R SEXP type, as listed in
L<SEXPTYPE|http://cran.r-project.org/doc/manuals/r-release/R-ints.html#SEXPTYPEs>.

=head2 to_perl

Returns I<Perl> representation of the object's value. This is an abstract
method; see concrete subclasses for the value returned by specific object types,
as well as the way to access the I<R> (-ish) value of the object, if such makes
sense.

=head2 is_null

Returns TRUE if the object is an R C<NULL> object. In C<REXP>'s class hierarchy,
this is the case only for C<Rserve::REXP::Null>.

=head2 is_vector

Returns TRUE if the object is an R vector object. In C<REXP>'s class hierarchy,
this is the case only for C<Rserve::REXP::Vector> and its descendants.

=head2 inherits CLASS_NAME

Returns TRUE if the object is an instance of R S3-style class C<CLASS_NAME>, in
the same fashion as the R function
C<L<base::inherits|http://stat.ethz.ch/R-manual/R-patched/library/base/html/class.html>>.

=head1 OVERLOADS

C<REXP> overloads the stringification, C<eq> and C<ne> methods. Subclasses
further specialize for their types if necesssary.

=cut
