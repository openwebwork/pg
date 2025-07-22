package Rserve::REXP::List;
use parent qw(Rserve::REXP::Vector);

use strict;
use warnings;

use Scalar::Util qw(blessed weaken);

use overload;

sub _type    { return 'list'; }
sub sexptype { return 'VECSXP'; }

sub _to_s {
	my $self = shift;

	my ($u, $unfold);
	$u = $unfold = sub {
		return join(', ', map { ref $_ eq 'ARRAY' ? '[' . $unfold->(@$_) . ']' : ($_ // 'undef') } @_);
	};
	weaken $unfold;
	return $self->_type . '(' . $unfold->(@{ $self->elements }) . ')';
}

sub to_perl {
	my $self = shift;
	return [
		map {
			if (blessed $_ && $_->can('to_perl')) {
				my $x = $_->to_perl;
				if (ref $x eq 'ARRAY') {
					unless (@$x > 1 || $_->isa('Rserve::REXP::List')) {
						@$x;
					} else {
						$x;
					}
				} else {
					$x;
				}
			} else {
				$_;
			}
		} @{ $self->elements }
	];
}

1;

__END__

=encoding UTF-8

=head1 NAME

Rserve::REXP::List - an R generic vector (list)

=head1 SYNOPSIS

    use Rserve::REXP::List

    my $vec = Rserve::REXP::List->new([
        1, '', 'foo', ['x', 22]
    ]);
    print $vec->elements;

=head1 DESCRIPTION

An object of this class represents an R list, also called a generic vector
(C<VECSXP>). List elements can themselves be lists, and so can form a tree
structure.

=head1 METHODS

C<Rserve::REXP:List> inherits from L<Rserve::REXP::Vector>, with no added
restrictions on the value of its elements. Missing values (C<NA> in R) have
value C<undef>.

=over

=item sexptype

SEXPTYPE of generic vectors is C<VECSXP>.

=item to_perl

Perl value of the list is an array reference to the Perl values of its
C<elements>, but using a scalar value to represent elements that are atomic
vectors of length 1, rather than a one-element array reference.

The idea is that in R, C<1:3>, and C<list(1, 2, 3)> can often be used
interchangeably, even though the list is really composed of three integer
vectors, each of length one. Now, both will have native Perl representation of
C<[1, 2, 3]>.

This only applies to elements that are atomic vectors. An element of type list
will always be represented as an array reference. For example,

C<< list(list(1), list(2), list(3))->to_perl >> will be represented as
C<[ [ 1 ], [ 2 ], [ 3 ] ]>

=back

=cut
