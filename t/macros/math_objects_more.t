use warnings;
use strict;
package main;

use Data::Dump qw/dd/;
use Test::More;
use Test::Exception;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	# $main::test_dir = abs_path( dirname(__FILE__) );

	die "WEBWORK_ROOT not found in environment.\n" unless $ENV{WEBWORK_ROOT};
	$main::webwork_dir = $ENV{WEBWORK_ROOT};
	$main::pg_dir = $ENV{PG_ROOT};
	$main::pg_dir = "$main::webwork_dir/../pg" unless $main::pg_dir;
	$main::macros_dir = "$main::pg_dir/macros";
}

use lib "$main::webwork_dir/lib";
use lib "$main::pg_dir/lib";

our %envir;

require("./build_PG_envir.pl");

use Parser;

loadMacros("MathObjects.pl");

my $ctx = Context("Numeric");

ok(Value::isContext($ctx),"math objects: check context");

my $f = Compute("x^2");

ok(Value::isFormula($f),"math objects: check for formula");
is($f->class,"Formula","math objects: check that the class is Formula");
is($f->type,"Number","math objects: check that the type is Number");





done_testing();