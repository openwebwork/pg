package Rserve::REXP::Double;
use parent qw(Rserve::REXP::Vector);

use strict;
use warnings;

use Scalar::Util qw(looks_like_number);

use overload;

sub new {
	my ($class, @args) = @_;

	my $self = $class->SUPER::new(@args);

	$self->{elements} =
		[ map { looks_like_number($_) ? $_ : undef } Rserve::REXP::Vector::_flatten(@{ $self->{elements} }) ]
		if (ref($self->{elements}) eq 'ARRAY');

	die q{Elements of the 'elements' attribute must be numbers or undef}
		if defined($self->elements)
		&& grep { defined($_) && !looks_like_number($_) } @{ $self->elements };

	return $self;
}

sub _type    { return 'double'; }
sub sexptype { return 'REALSXP'; }

1;

__END__

=encoding UTF-8

=head1 NAME

Rserve::REXP::Double - an R numeric vector

=head1 SYNOPSIS

    use Rserve::REXP::Double

    my $vec = Rserve::REXP::Double->new([ 1, 4, 'foo', 42 ]);
    print $vec->elements;

=head1 DESCRIPTION

An object of this class represents an R numeric (aka double) vector
(C<REALSXP>).

=head1 METHODS

C<Rserve::REXP:Double> inherits from L<Rserve::REXP::Vector>, with the added
restriction that its elements are real numbers. Elements that are not numbers
have value C<undef>, as do elements with R value C<NA>.

=over

=item sexptype

SEXPTYPE of complex vectors is C<REALSXP>.

=back

=cut
