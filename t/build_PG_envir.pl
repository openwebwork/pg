#!/usr/bin/env perl

use strict;
use warnings;

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
use lib "$ENV{PG_ROOT}/lib";

my $macros_dir = "$ENV{PG_ROOT}/macros";

use PGcore;
use Parser;

# Build up enough of a PG environment to get things running.
$main::envir{htmlDirectory}             = '/opt/webwork/courses/daemon_course/html';
$main::envir{htmlURL}                   = 'http://localhost/webwork2/daemon_course/html';
$main::envir{tempURL}                   = 'http://localhost/webwork2/daemon_course/tmp';
$main::envir{pgDirectories}{macrosPath} = [$macros_dir];
$main::envir{macrosPath}                = [$macros_dir];
$main::envir{displayMode}               = 'HTML_MathJax';
$main::envir{language}                  = 'en';
$main::envir{language_subroutine}       = sub { return $_[0]; };

$main::envir{functAbsTolDefault}            = 0.001;
$main::envir{functLLimitDefault}            = 0.0000001;
$main::envir{functMaxConstantOfIntegration} = 1E8;
$main::envir{functNumOfPoints}              = 3;
$main::envir{functRelPercentTolDefault}     = 0.1;
$main::envir{functULimitDefault}            = 0.9999999;
$main::envir{functVarDefault}               = 'x';
$main::envir{functZeroLevelDefault}         = 1E-14;
$main::envir{functZeroLevelTolDefault}      = 1E-12;
$main::envir{numAbsTolDefault}              = 0.001;
$main::envir{numFormatDefault}              = '';
$main::envir{numRelPercentTolDefault}       = 0.1;
$main::envir{numZeroLevelDefault}           = 1E-14;
$main::envir{numZeroLevelTolDefault}        = 1E-12;
$main::envir{useBaseTenLog}                 = 0;
$main::envir{defaultDisplayMatrixStyle}     = '[s]';

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
