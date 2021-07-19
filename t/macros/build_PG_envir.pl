use warnings;
use strict;
package main;

use lib "$main::webwork_dir/lib";
use lib "$main::pg_dir/lib";

# use WeBWorK::CourseEnvironment;
use WeBWorK::Localize;
# use WeBWorK::PG;
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