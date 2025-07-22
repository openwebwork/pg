package Rserve::REXP::Integer;
use parent qw(Rserve::REXP::Vector);

use strict;
use warnings;

use Scalar::Util qw(looks_like_number);

use overload;

sub new {
	my ($class, @args) = @_;

	my $self = $class->SUPER::new(@args);

	$self->{elements} =
		[ map { looks_like_number($_) ? int($_ + ($_ <=> 0) * 0.5) : undef }
			Rserve::REXP::Vector::_flatten(@{ $self->{elements} }) ]
		if (ref($self->{elements}) eq 'ARRAY');

	die q{Elements of the 'elements' attribute must be integers}
		if defined $self->elements
		&& grep { defined($_) && !(looks_like_number($_) && int($_) == $_) } @{ $self->elements };

	return $self;
}

sub _type    { return 'integer'; }
sub sexptype { return 'INTSXP'; }

1;

__END__

=encoding UTF-8

=head1 NAME

Rserve::REXP::Integer - an R integer vector

=head1 SYNOPSIS

    use Rserve::REXP::Integer

    my $vec = Rserve::REXP::Integer->new([ 1, 4, 'foo', 42 ]);
    print $vec->elements;

=head1 DESCRIPTION

An object of this class represents an R integer vector (C<INTSXP>).

=head1 METHODS

C<Rserve::REXP:Integer> inherits from L<Rserve::REXP::Vector>, with the added
restriction that its elements are truncated to integer values. Elements that are
not numbers have value C<undef>, as do elements with R value C<NA>.

=over

=item sexptype

SEXPTYPE of integer vectors is C<INTSXP>.

=back

=cut
