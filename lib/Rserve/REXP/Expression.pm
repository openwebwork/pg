package Rserve::REXP::Expression;
use parent qw(Rserve::REXP::List);

use strict;
use warnings;

sub _type    { return 'expression'; }
sub sexptype { return 'EXPRSXP'; }

sub to_perl {
	my @elements = @_;
	return Rserve::REXP::Vector::to_perl(@elements);
}

1;

__END__

=encoding UTF-8

=head1 NAME

Rserve::REXP::Expression - an R expression vector

=head1 SYNOPSIS

    use Rserve::REXP::Expression

    # Representation of the R call C<expresson(1 + 2))>:
    my $vec = Rserve::REXP::Expression->new([
        Rserve::REXP::Language->new([
            Rserve::REXP::Symbol->new('+'),
            Rserve::REXP::Double->new([1]),
            Rserve::REXP::Double->new([2])
        ])
    ]);
    print $vec->elements;

=head1 DESCRIPTION

An object of this class represents an R expression vectors (C<EXPRSXP>). These
objects represent a list of calls, symbols, etc., for example as returned by
calling R function C<parse> or C<expression>.

=head1 METHODS

C<Rserve::REXP:Expression> inherits from L<Rserve::REXP::List>, with no added
restrictions on the value of its elements.

=over

=item sexptype

SEXPTYPE of expressions is C<EXPRSXP>.

=item to_perl

Perl value of the expression vector is an array reference to the Perl values of
its C<elements>. (That is, it's equivalent to
C<< map {$_->to_perl}, $vec->elements >>.) Unlike L<List>, elements that are
atomic vectors of length 1 are still represented as a one-element array
reference, rather than scalar values.

=back

=cut
