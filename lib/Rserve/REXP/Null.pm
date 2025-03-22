package Rserve::REXP::Null;
use parent qw(Rserve::REXP);

use strict;
use warnings;

use overload
	'""'     => sub {'NULL'},
	bool     => sub {1},
	fallback => 1;

sub new {
	my ($class, @args) = @_;
	die 'Null cannot have attributes' if scalar @args;
	return $class->SUPER::new(@args);
}

sub sexptype { return 'NILSXP'; }

sub is_null { return 1; }

sub to_perl { return; }

1;

__END__

=encoding UTF-8

=head1 NAME

Rserve::REXP::Null - the R null object

=head1 SYNOPSIS

    use Rserve::REXP;

    my $null = Rserve::REXP::Null->new;
    say $rexp->is_null;
    print $rexp->to_perl;

=head1 DESCRIPTION

An object of this class represents the null R object (C<NILSXP>). The null
object does not have a value or attributes, and trying to set them will cause an
exception.

=head1 METHODS

C<Rserve::REXP::Null> inherits from L<Rserve::REXP> and adds no methods of its
own.

=head2 ACCESSORS

=over

=item sexptype

SEXPTYPE of null objects is C<NILSXP>.

=item to_perl

The Perl value of C<NULL> is C<undef>.

=item attributes

Null objects have no attributes, so the attributes accessor always returns
C<undef>.

=back

=cut
