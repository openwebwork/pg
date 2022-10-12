#!/usr/bin/env perl

use strict;
use warnings;

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
use lib "$ENV{PG_ROOT}/lib";

my $macros_dir = "$ENV{PG_ROOT}/macros";

use WeBWorK::PG::Environment;
use WeBWorK::PG;
use PGcore;
use Parser;

%main::envir = %{ WeBWorK::PG::defineProblemEnvironment(WeBWorK::PG::Environment->new) };

sub be_strict {
	require ww_strict;
	strict::import();
	return;
}

sub PG_restricted_eval {
	my @input = @_;
	return WeBWorK::PG::Translator::PG_restricted_eval(@input);
}

sub check_score {
	my ($correct_answer, $ans) = @_;
	return $correct_answer->cmp->evaluate($ans)->{score};
}

do "$macros_dir/PG.pl";

DOCUMENT();

loadMacros('PGbasicmacros.pl');

1;
