package Rserve::REXP::Language;
use parent qw(Rserve::REXP::List);

use strict;
use warnings;

use Scalar::Util qw(blessed);

sub new {
	my ($class, @args) = @_;

	my $self = $class->SUPER::new(@args);

	die 'The first element must be a Symbol or Language'
		if defined $self->elements
		&& !(
			blessed $self->elements->[0] && ($self->elements->[0]->isa('Rserve::REXP::Language')
				|| $self->elements->[0]->isa('Rserve::REXP::Symbol'))
		);

	return $self;
}

sub _type    { return 'language'; }
sub sexptype { return 'LANGSXP'; }

sub to_perl {
	my @elements = @_;
	return Rserve::REXP::Vector::to_perl(@elements);
}

1;

__END__

=encoding UTF-8

=head1 NAME

Rserve::REXP::Language - an R language vector

=head1 SYNOPSIS

    use Rserve::REXP::Language

    # Representation of the R call C<mean(c(1, 2, 3))>:
    my $vec = Rserve::REXP::Language->new([
        Rserve::REXP::Symbol->new('mean'),
        Rserve::REXP::Double->new([1, 2, 3])
    ]);
    print $vec->elements;

=head1 DESCRIPTION

An object of this class represents an R language vector (C<LANGSXP>).  These
objects represent calls (such as model formulae), with first element a reference
to the function being called, and the remainder the actual arguments of the
call. Names of arguments, if given, are recorded in the 'names' attribute
(itself as L<Rserve::REXP::Character> vector), with unnamed arguments having
name C<''>. If no arguments were named, the language objects will not have a
defined 'names' attribute.

=head1 METHODS

C<Rserve::REXP:Language> inherits from L<Rserve::REXP::Vector>, with the added
restriction that its first element has to be a L<Rserve::REXP::Symbol> or
another C<Language> instance. Trying to create a Language instance that doesn't
follow this restriction will raise an exception.

=over

=item sexptype

SEXPTYPE of language vectors is C<LANGSXP>.

=item to_perl

Perl value of the language vector is an array reference to the Perl values of
its C<elements>. (That is, it's equivalent to
C<< map {$_->to_perl}, $vec->elements >>.)

=back

=cut
