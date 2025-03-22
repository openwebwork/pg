package Rserve::REXP::Complex;
use parent qw(Rserve::REXP::Vector);

use strict;
use warnings;

use Scalar::Util  qw(blessed looks_like_number);
use Math::Complex ();

use overload;

sub new {
	my ($class, @args) = @_;

	my $self = $class->SUPER::new(@args);

	$self->{elements} = [
		map {
			(blessed($_) && $_->isa('Math::Complex')) ? $_ : looks_like_number $_ ? Math::Complex::cplx($_) : undef
		} Rserve::REXP::Vector::_flatten(@{ $self->{elements} })
		]
		if (ref($self->{elements}) eq 'ARRAY');

	die q{Elements of the 'elements' attribute must be scalar numbers or instances of Math::Complex}
		if defined $self->elements
		&& grep { defined($_) && !(blessed($_) && $_->isa('Math::Complex') || Scalar::Util::looks_like_number($_)) }
		@{ $self->elements };

	return $self;
}

sub _type    { return 'complex'; }
sub sexptype { return 'CPLXSXP'; }

sub _eq {
	my ($self, $other) = @_;

	return unless Rserve::REXP::_eq($self, $other);

	my $selfElements  = $self->elements;
	my $otherElements = $other->elements;
	return unless scalar(@$selfElements) == scalar(@$otherElements);
	for (my $i = 0; $i < scalar(@$selfElements); $i++) {
		my $x = $selfElements->[$i];
		my $y = $otherElements->[$i];
		if (defined($x) && defined($y)) {
			return unless $x == $y;
		} else {
			return if defined($x) or defined($y);
		}
	}

	return 1;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Rserve::REXP::Complex - an R numeric vector

=head1 SYNOPSIS

    use Rserve::REXP::Complex;
    use Math::Complex ();

    my $vec = Rserve::REXP::Complex->new([ 1, cplx(4, 2), 'foo', 42 ]);
    print $vec->elements;

=head1 DESCRIPTION

An object of this class represents an R complex vector (C<CPLXSXP>).

=head1 METHODS

C<Rserve::REXP:Complex> inherits from L<Rserve::REXP::Vector>, with the added
restriction that its elements are complex numbers. Elements that are not numbers
have value C<undef>, as do elements with R value C<NA>.

=over

=item sexptype

SEXPTYPE of complex vectors is C<CPLXSXP>.

=back

=cut
