package Rserve;

use strict;
use warnings;

my $rserve_loaded = eval {
	require Statistics::R::IO::Rserve;
	1;
};

sub access {
	die 'Statistics::R::IO::Rserve could not be loaded. Have you installed the module?'
		unless $rserve_loaded;
	return Statistics::R::IO::Rserve->new(@_);
}

# Evaluates an R expression guarding it inside an R `try` function
#
# Returns the result as a REXP if no exceptions were raised, or
# `die`s with the text of the exception message.
sub try_eval {
	my ($rserve, $query) = @_;

	my $result = $rserve->eval("try({ $query }, silent = TRUE)");
	die $result->to_pl->[0] if $result->inherits('try-error');

	return $result;
}

# Returns a REXP's Perl representation, dereferencing it if it's an
# array reference
#
# `REXP::to_pl` returns a string scalar for Symbol, undef for Null,
# and an array reference to contents for all vector types. This
# function is a utility wrapper to make it easy to assign a Vector's
# representation to an array variable, while still working sensibly
# for non-arrays.
sub unref_rexp {
	my $rexp  = shift;
	my $value = $rexp->to_pl;
	return ref($value) eq 'ARRAY' ? @$value : $value;
}

1;
