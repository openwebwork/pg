package Rserve::REXP::Logical;
use parent qw(Rserve::REXP::Vector);

use strict;
use warnings;

use overload;

sub new {
	my ($class, @args) = @_;

	my $self = $class->SUPER::new(@args);

	$self->{elements} =
		[ map { defined $_ ? ($_ ? 1 : 0) : undef } Rserve::REXP::Vector::_flatten(@{ $self->{elements} }) ]
		if (ref($self->{elements}) eq 'ARRAY');

	die q{Elements of the 'elements' attribute must be 0, 1, or undef}
		if defined $self->elements
		&& grep { defined($_) && ($_ != 1 && $_ != 0) } @{ $self->elements };

	return $self;
}

sub _type    { return 'logical'; }
sub sexptype { return 'LGLSXP'; }

1;

__END__

=encoding UTF-8

=head1 NAME

Rserve::REXP::Logical - an R logical vector

=head1 SYNOPSIS

    use Rserve::REXP::Logical

    my $vec = Rserve::REXP::Logical->new([ 1, '', 'foo', undef ]);
    print $vec->elements;

=head1 DESCRIPTION

An object of this class represents an R logical vector (C<LGLSXP>).

=head1 METHODS

C<Rserve::REXP:Logical> inherits from L<Rserve::REXP::Vector>, with the added
restriction that its elements are boolean (true/false) values. Elements have
value 1 or 0, corresponding to C<TRUE> and C<FALSE>, respectively, while missing
values (C<NA> in R) have value C<undef>.

=over

=item sexptype

SEXPTYPE of logical vectors is C<LGLSXP>.

=back

=cut
