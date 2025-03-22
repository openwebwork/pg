package Rserve::REXP::Character;
use parent qw(Rserve::REXP::Vector);

use strict;
use warnings;

use overload;

sub new {
	my ($class, @args) = @_;

	my $self = $class->SUPER::new(@args);
	$self->{elements} = [ Rserve::REXP::Vector::_flatten(@{ $self->{elements} }) ]
		if ref($self->{elements}) eq 'ARRAY';

	die q{Elements of the 'elements' attribute must be scalar values}
		if defined($self->elements) && grep { ref($_) } @{ $self->elements };

	return $self;
}

sub _type    { return 'character'; }
sub sexptype { return 'STRSXP'; }

1;

__END__

=encoding UTF-8

=head1 NAME

Rserve::REXP::Character - an R character vector

=head1 SYNOPSIS

    use Rserve::REXP::Character

    my $vec = Rserve::REXP::Character->new([ 1, '', 'foo', [] ]);
    print $vec->elements;

=head1 DESCRIPTION

An object of this class represents an R character vector (C<STRSXP>).

=head1 METHODS

C<Rserve::REXP:Character> inherits from L<Rserve::REXP::Vector>, with the added
restriction that its elements are scalar values. Elements that are not scalars
(i.e., numbers or strings) have value C<undef>, as do elements with R value
C<NA>.

=over

=item sexptype

SEXPTYPE of character vectors is C<STRSXP>.

=back

=cut
