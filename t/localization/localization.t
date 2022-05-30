use warnings;
use strict;

package main;

use Test::More;
use Test::Exception;

# The following needs to include at the top of any testing down to END OF TOP_MATERIAL.

BEGIN {
	die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
	$main::pg_dir = $ENV{PG_ROOT};
}

use lib "$main::pg_dir/lib";

use PGEnvironment;
use Data::Dumper;
use Renderer::Localize;

my $pg_env = PGEnvironment->new(course_name => '');
my $mt =  Renderer::Localize::getLoc('en');

is(&$mt('Answer Preview'), 'Answer Preview', 'localize: test english passes through');
is(&$mt('not in pg.pot'), 'not in pg.pot', 'localize: test if not in list, return in English');

note('French tests');

$mt =  Renderer::Localize::getLoc('fr');
print Dumper &$mt('Answer Preview');
is(&$mt('Answer Preview'), 'Aper\x{e7}u des r\x{e9}ponses', 'localize: test english passes through');

done_testing;
