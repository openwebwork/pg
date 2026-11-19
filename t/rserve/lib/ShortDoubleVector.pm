package ShortDoubleVector;
use parent qw(Rserve::REXP::Double);

use strict;
use warnings;

use Exporter               qw(import);
use Scalar::Util           qw(blessed reftype looks_like_number);
use Test2::Compare::Custom ();
use Test2::Tools::Compare  qw(float);

use Rserve::REXP;

our @EXPORT_OK = qw(rexp_cmp);

# This creates a Test2 check for an expected value that tolerates the last-digit drift R can produce between builds.
# Used as `is($got, rexp_cmp($expected), ...)`.
sub rexp_cmp {
	my ($expected) = @_;

	if (blessed($expected)) {
		# Only REXP objects carry the tolerant `eq` overload.
		# Any other object is left for Test2 to compare structurally.
		return $expected unless $expected->isa('Rserve::REXP');
		return Test2::Compare::Custom->new(
			name     => 'REXP',
			operator => 'eq',
			code     => sub { my %param = @_; return $expected eq $param{got}; }
		);
	}

	my $type = reftype($expected) // '';
	return [ map { rexp_cmp($_) } @$expected ]                           if $type eq 'ARRAY';
	return { map { ($_ => rexp_cmp($expected->{$_})) } keys %$expected } if $type eq 'HASH';
	return float($expected)
		if looks_like_number($expected) && $expected == $expected && abs($expected) != 9**9**9;
	return $expected;
}

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

sub _compare_deeply {
	my @in = @_;
	return Rserve::REXP::Double::_compare_deeply(@in);
}

sub _type { return 'shortdouble'; }

1;
