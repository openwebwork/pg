################################################################################
# WeBWorK mod_perl (c) 2000-2002 WeBWorK Project
# $Id$
################################################################################

package WeBWorK::PG::IO;

=head1 NAME

WeBWorK::PG::IO - Load 

=cut

use strict;
use warnings;

BEGIN {
	my $mod;
	for ($main::VERSION) {
		/^2\./ and $mod = "WeBWorK::PG::IO::WW2";
		/^1\./ and $mod = "WeBWorK::PG::IO::WW1";
	}
	
	eval "package Main; require $mod; import $mod";
	die $@ if $@;
}

1;
