use warnings;
use strict;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	# $main::test_dir = abs_path( dirname(__FILE__) );

	die "WEBWORK_ROOT not found in environment.\n" unless $ENV{WEBWORK_ROOT};
	$main::webwork_dir = $ENV{WEBWORK_ROOT};
	$main::pg_dir = $ENV{PG_ROOT};
	$main::pg_dir = "$main::webwork_dir/../pg" unless $main::pg_dir;
	$main::macros_dir  = "$main::pg_dir/macros";
}

use Data::Dump qw/dd/;
use Test::More;

use lib "$main::webwork_dir/lib";
use lib "$main::pg_dir/lib";

use WeBWorK::CourseEnvironment;
use WeBWorK::PG;
use PGcore;

my $ce = WeBWorK::CourseEnvironment->new({webwork_dir => $main::webwork_dir, pg_dir => $main::pg_dir});

# dd $ce;

our %envir=();
$envir{htmlDirectory} = "/opt/webwork/courses/daemon_course/html";
$envir{htmlURL} = "http://localhost/webwork2/daemon_course/html";
$envir{tempURL} = "http://localhost/webwork2/daemon_course/tmp";

sub be_strict {
	require 'ww_strict.pm';
	strict::import();
}

sub PG_restricted_eval {
	my $self = shift;
	WeBWorK::PG::Translator::PG_restricted_eval(@_);
}


require("$main::macros_dir/PG.pl");
$main::PG = PGcore->new(\%envir);

$main::PG->{envir}->{macrosPath} = [ $main::macros_dir];

be_strict();

# dd $main::PG;
loadMacros("PGauxiliaryFunctions.pl");

# dd $main::PG;


## note: bug in random_coprime that list_random cannot run in this without
## the PGbasicmacros.pl

loadMacros("PGbasicmacros.pl");

## random_coprime

dd random_coprime([1..9],[1..9]);

#my $PG = WeBWorK::PG->defineProblemEnvir($ce);