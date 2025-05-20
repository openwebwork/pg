package Rserve::REXP::Symbol;
use parent qw(Rserve::REXP);

use strict;
use warnings;

use Scalar::Util qw(blessed);

use overload
	'""'     => sub { 'symbol `' . shift->name . '`' },
	bool     => sub {1},
	fallback => 1;

sub new {
	my ($class, @args) = @_;

	my $attributes = {};

	if (scalar @args == 1) {
		if (ref $args[0] eq 'HASH') {
			$attributes = $args[0];
		} else {
			$attributes->{name} = $args[0];
		}
	} elsif (@args % 2) {
		die "The new method for $class expects a hash reference or a key/value list."
			. " You passed an odd number of arguments\n";
	} else {
		$attributes = {@args};
	}

	$attributes->{name} = $attributes->{name}->name
		if blessed($attributes->{name}) && $attributes->{name}->isa('Rserve::REXP::Symbol');

	$attributes->{name} //= '';

	my $self = $class->SUPER::new($attributes);

	die q{Attribute 'name' must be a scalar value} unless ref(\$self->name) eq 'SCALAR';

	return $self;
}

sub sexptype { return 'SYMSXP'; }

sub name { my $self = shift; return $self->{name}; }

sub _eq {
	my ($self, $other) = @_;
	return unless $self->SUPER::_eq($other);
	return $self->name eq $other->name;
}

sub to_perl {
	my $self = shift;
	return $self->name;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Rserve::REXP::Symbol - an R symbol

=head1 SYNOPSIS

    use Rserve::REXP::Symbol;

    my $sym = Rserve::REXP::Symbol->new('some name');
    print $sym->name;

=head1 DESCRIPTION

An object of this class represents an R symbol/name object (C<SYMSXP>).

=head1 METHODS

C<Rserve::REXP::Symbol> inherits from L<Rserve::REXP>.

=head2 ACCESSORS

=over

=item name

String value of the symbol.

=item sexptype

SEXPTYPE of symbols is C<SYMSXP>.

=item to_perl

Perl value of the symbol is just its C<name>.

=back

=cut
