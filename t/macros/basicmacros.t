use warnings;
use strict;
package main;

use Data::Dump qw/dd/;
use Test::More;
use Test::Exception;

## the following needs to include at the top of any testing  down to TOP_MATERIAL

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::current_dir = abs_path( dirname(__FILE__) );

	die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
	die "WEBWORK_ROOT not found in environment.\n" unless $ENV{WEBWORK_ROOT};

	$main::pg_dir = $ENV{PG_ROOT};
	$main::webwork_dir = $ENV{WEBWORK_ROOT};

}

use lib "$main::webwork_dir/lib";
use lib "$main::pg_dir/lib";

require("$main::current_dir/build_PG_envir.pl");

## END OF TOP_MATERIAL

loadMacros("PGbasicmacros.pl");

use HTML::Entities;
use HTML::TagParser

my $named_box = NAMED_ANS_BOX("name");

dd $named_box;

my $html = HTML::TagParser->new( $named_box );

# dd $html;

done_testing();
