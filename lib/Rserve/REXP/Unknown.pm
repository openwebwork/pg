package Rserve::REXP::Unknown;
use parent qw(Rserve::REXP);

use strict;
use warnings;

use Scalar::Util qw(blessed looks_like_number);

use overload
	'""'     => sub {'Unknown'},
	bool     => sub {1},
	fallback => 1;

sub new {
	my ($class, @args) = @_;

	my $attributes = {};

	if (scalar @args == 1) {
		if (ref $args[0] eq 'HASH') {
			$attributes = $args[0];
		} else {
			$attributes->{sexptype} = $args[0];
		}
	} elsif (@args % 2) {
		die "The new method for $class expects a hash reference or a key/value list."
			. " You passed an odd number of arguments\n";
	} else {
		$attributes = {@args};
	}

	$attributes->{sexptype} = $attributes->{sexptype}->sexptype
		if (blessed($attributes->{sexptype}) && $attributes->{sexptype}->isa('Rserve::REXP::Unknown'));

	my $self = $class->SUPER::new($attributes);

	die q{Attribute 'sexptype' must be a number in range 0-255}
		unless looks_like_number($self->sexptype) && ($self->sexptype >= 0) && ($self->sexptype <= 255);

	return $self;
}

sub sexptype { my $self = shift; return $self->{sexptype}; }

sub _eq {
	my ($self, $other) = @_;
	return unless $self->SUPER::_eq($other);
	return $self->sexptype eq $other->sexptype;
}

sub to_perl { return; }

1;

__END__

=encoding UTF-8

=head1 NAME

Rserve::REXP::Unknown - R object not representable in Rserve

=head1 SYNOPSIS

    use Rserve::REXP::Unknown;

    my $unknown = Rserve::REXP::Unknown->new(4);
    say $unknown->sexptype;
    say $unknown->to_perl;

=head1 DESCRIPTION

An object of this class represents an R object that's currently not
representable by the Rserve protocol.

=head1 METHODS

C<Rserve::REXP::Unknown> inherits from L<Rserve::REXP> and adds no methods of
its own.

=head2 ACCESSORS

=over

=item sexptype

The R L<SEXPTYPE|http://cran.r-project.org/doc/manuals/r-release/R-ints.html#SEXPTYPEs>
of the object.

=item to_perl

The Perl value of the unknown type is C<undef>.

=back

=cut
