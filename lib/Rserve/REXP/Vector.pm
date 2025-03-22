package Rserve::REXP::Vector;
use parent qw(Rserve::REXP);

use strict;
use warnings;

use Scalar::Util qw(blessed);

use overload
	'""'     => sub { shift->_to_s; },
	bool     => sub {1},
	fallback => 1;

sub new {
	my ($class, @args) = @_;

	my $attributes;
	if (scalar @args == 1) {
		if (ref $args[0] eq 'HASH') {
			$attributes = $args[0];
		} elsif (blessed($args[0]) && $args[0]->isa('Rserve::REXP::Vector')) {
			$attributes = { elements => $args[0]->elements };
		} else {
			$attributes = { elements => $args[0] };
		}
	} elsif (@args % 2) {
		die "The new method for $class expects a hash reference or a key/value list."
			. " You passed an odd number of arguments\n";
	} else {
		$attributes = {@args};
	}

	$attributes->{elements} //= [];

	my $self = $class->SUPER::new($attributes);

	die 'This is an abstract class and must be subclassed' if ref($self) eq __PACKAGE__;

	# Required methods
	for my $req (qw/_type/) {
		die "$req method required" unless $self->can($req);
	}

	# Required attribute type
	die q{Attribute 'elements' must be an array reference}
		if defined $self->elements && ref($self->elements) ne 'ARRAY';

	return $self;
}

sub type     { my $self = shift; return $self->_type; }
sub elements { my $self = shift; return $self->{elements}; }

sub _eq {
	my ($self, $other) = @_;
	return unless $self->SUPER::_eq($other);
	return Rserve::REXP::_compare_deeply($self->elements, $other->elements);
}

sub _to_s {
	my $self      = shift;
	my $stringify = sub {
		map { defined $_ ? $_ : 'undef' } @_;
	};
	return $self->_type . '(' . join(', ', $stringify->(@{ $self->elements })) . ')';
}

# Turns any references (nested lists) into a plain-old flat list.
# Lists can nest to an arbitrary level, but having references to
# anything other than arrays is not supported.
sub _flatten {
	my @in = @_;
	return map { ref $_ eq 'ARRAY' ? _flatten(@$_) : $_ } @in;
}

sub is_vector { return 1; }

sub to_perl {
	my $self = shift;
	return [ map { (blessed $_ && $_->can('to_perl')) ? $_->to_perl : $_ } @{ $self->elements } ];
}

1;

__END__

=encoding UTF-8

=head1 NAME

Rserve::REXP::Vector - an R vector

=head1 SYNOPSIS

    use Rserve::REXP::Vector;

    # $vec is an instance of Vector
    $vec->does('Rserve::REXP::Vector');
    print $vec->elements;

=head1 DESCRIPTION

An object of this class represents an R vector. This class cannot be directly
instantiated (it will die if you call C<new> on it), because it is intended as a
base abstract class with concrete subclasses to represent specific types of
vectors, such as numeric or list.

=head1 METHODS

C<Rserve::REXP::Vector> inherits from L<Rserve::REXP>.

=head2 ACCESSORS

=over

=item elements

Returns an array reference to the vector's elements.

=item to_perl

Perl value of the language vector is an array reference to the Perl
values of its C<elements>. (That is, it's equivalent to
C<< map {$_->to_perl}, $vec->elements >>.)

=item type

Human-friendly description of the vector type (e.g., "double" vs.  "list"). For
the true R type, use L<sexptype>.

=back

=cut
