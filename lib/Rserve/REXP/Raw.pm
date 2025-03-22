package Rserve::REXP::Raw;
use parent qw(Rserve::REXP::Vector);

use strict;
use warnings;

use overload;

sub new {
	my ($class, @args) = @_;

	my $self = $class->SUPER::new(@args);

	if (ref($self->{elements}) eq 'ARRAY') {
		$self->{elements} =
			[ map { int $_ } Rserve::REXP::Vector::_flatten(@{ $self->{elements} }) ];
	}

	die 'Raw vectors cannot have attributes' if defined $self->attributes;
	die 'Elements of raw vectors must be 0-255'
		if defined $self->elements && grep { !($_ >= 0 && $_ <= 255) } @{ $self->elements };

	return $self;
}

sub _type    { return 'raw'; }
sub sexptype { return 'RAWSXP'; }

1;

__END__

=encoding UTF-8

=head1 NAME

Rserve::REXP::Raw - an R raw vector

=head1 SYNOPSIS

    use Rserve::REXP::Raw

    my $vec = Rserve::REXP::Raw->new([ 1, 27, 143, 33 ]);
    print $vec->elements;

=head1 DESCRIPTION

An object of this class represents an R raw vector (C<RAWSXP>). It is intended
to hold the data of arbitrary binary objects, for instance bytes read from a
socket connection.

=head1 METHODS

C<Rserve::REXP:Raw> inherits from L<Rserve::REXP::Vector>, with the added
restriction that its elements are byte values and cannot have missing values.
Trying to create a raw vectors with elements that are not numbers in range 0-255
will raise an exception.

=over

=item sexptype

SEXPTYPE of raw vectors is C<RAWSXP>.

=back

=cut
