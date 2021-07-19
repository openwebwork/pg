use warnings;
use strict;
package main;

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

use lib "$main::webwork_dir/lib";
use lib "$main::pg_dir/lib";

use WeBWorK::CourseEnvironment;
use WeBWorK::Localize;
use WeBWorK::PG;
use PGcore;

# build up enough of a PG environment to get things running

our %envir=();
$envir{htmlDirectory} = "/opt/webwork/courses/daemon_course/html";
$envir{htmlURL} = "http://localhost/webwork2/daemon_course/html";
$envir{tempURL} = "http://localhost/webwork2/daemon_course/tmp";
$envir{pgDirectories}->{macrosPath} = [ "$main::macros_dir"];
$envir{macrosPath} = [ "$main::macros_dir"];
$envir{displayMode} = "HTML_MathJax";
$envir{language} = "en-us";
$envir{language_subroutine} = WeBWorK::Localize::getLoc($envir{language});

sub be_strict {
	require 'ww_strict.pm';
	strict::import();
}

sub PG_restricted_eval {
	WeBWorK::PG::Translator::PG_restricted_eval(@_);
}

require "$main::macros_dir/PG.pl";
DOCUMENT();

loadMacros("PGbasicmacros.pl");

1;