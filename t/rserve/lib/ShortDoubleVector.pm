package ShortDoubleVector;
use parent qw(Rserve::REXP::Double);

use strict;
use warnings;

use Scalar::Util qw(looks_like_number);

use Rserve::REXP;

sub _eq {
	my ($self, $other) = @_;

	return unless Rserve::REXP::_eq($self, $other);

	my $first  = $self->elements;
	my $second = $other->elements;
	return unless scalar(@$first) == scalar(@$second);
	for (my $i = 0; $i < scalar(@{$first}); $i++) {
		my $x = $first->[$i];
		my $y = $second->[$i];
		if (defined $x && defined $y) {
			return unless $x eq $y || (abs($x - $y) < 1e-13);
		} else {
			return if defined $x || defined $y;
		}
	}

	return 1;
}

# we have to REXPs `_compare_deeply` this way because private methods aren't available in the subclass
sub _compare_deeply {
	my @in = @_;
	return Rserve::REXP::Double::_compare_deeply(@in);
}

sub _type { return 'shortdouble'; }

1;
