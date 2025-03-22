# ABSTRACT: Utility class that is equal to a specified object or XT_UNKNOWN

package RexpOrUnknown;

use strict;
use warnings;

use Scalar::Util qw(blessed);

use Rserve::REXP::Unknown;

use overload
	'""' => sub {
		my $self = shift;
		'maybe ' . $self->obj;
	},
	eq => sub {
		my ($self, $obj) = @_;
		return $self->obj eq $obj
		|| blessed $obj && $obj->isa('Rserve::REXP::Unknown');
	},
	bool     => sub {1},
	fallback => 1;

sub new {
	my ($class, @args) = @_;

	my $self;
	if (scalar @args == 1) {
		if   (ref $args[0] eq 'HASH') { $self = $args[0]; }
		else                          { $self = { obj => $args[0] }; }
	} else {
		$self = @args;
	}

	die 'Attribute (obj) is required' unless exists $self->{obj};

	return bless $self, $class;
}

sub obj { my $self = shift; return $self->{obj}; }

1;
