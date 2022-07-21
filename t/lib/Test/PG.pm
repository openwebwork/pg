package Test::PG;

BEGIN {
    die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
    $main::pg_dir = $ENV{PG_ROOT};
}

use warnings;
use strict;

use lib "$main::pg_dir/lib"; # only needed if not using prove with -l


=head1 Test::PG

This module provides the environment and some generic functions for
writing tests for PG macros.  Mostly copied from F<t/build_PG_envir.pl>,
it also redefines Test2's "exists" function from C<E()> to C<EXISTS()>
to avoid the conflict with WebWork's exponential function.
Its final action is to load C<PGbasicmacros.pl>.

The reason for the module is that There Is More Than One Way To Do It
and people develop different styles.  This is my coding style.
Also we learn the underlying structures better by re-inventing the wheel.
We just try to make a better wheel, but success is not guaranteed.

This module strives for elegance in reducing boiler plate in test files,
a minimum of duplicated code and adheres to the principle of least surprise
by locating modules below the C<t/lib> directory.
It does not make a decent cup of tea.

=head2 Usage

To test a macro that needs to be loaded, include this preamble
at the top of your test file and customize.

  use Test2::V0;

  use MyPGLib;   # does your macro need a module?

  use lib 't/lib';
  use Test::PG;    # setup a minimal WW environment

  loadMacros("parserMyPGMacro.pl");

  Context("Numeric");

And run your test from the $PG_ROOT directory with

  prove -l t/my_macro/my_test.t


=head2 TODO

=head3 Quiet warnings in F<t/contexts/trig_degrees.t>

The functions sin, cos and atan2 are redefined and generate warnings.
C<delete> them from the symbol table before loading the macro.

F<macros/contextTrigDegrees.pl> declares C<$deg> twice, it being
a required file, the package scope isn't heeded by the second C<my $deg>.
I wonder if this happens every time this macro is loaded.

=cut


package main;

$main::{EXISTS} = delete $main::{E}; # redefine Test2's E() function as EXISTS()

my $macros_dir = "$main::pg_dir/macros";

# use WeBWorK::Localize;
use PGcore;
use Parser;

# build up enough of a PG environment to get things running
our %envir = (
    htmlDirectory       => '/opt/webwork/courses/daemon_course/html',
    htmlURL             => 'http://localhost/webwork2/daemon_course/html',
    tempURL             => 'http://localhost/webwork2/daemon_course/tmp',
    pgDirectories       => { macrosPath => ["$macros_dir"] },
    macrosPath          => ["$macros_dir"],
    displayMode         => 'HTML_MathJax',
    language            => 'en-us',
    language_subroutine => sub { return @_; },    # return the string passed in instead going to maketext
);

sub be_strict {
        require 'ww_strict.pm';
        strict::import();
}

sub PG_restricted_eval {
        WeBWorK::PG::Translator::PG_restricted_eval(@_);
}

sub check_score {
        my ($correct_answer, $ans) = @_;
        return $correct_answer->cmp->evaluate($ans)->{score};
}

require "$macros_dir/PG.pl";
DOCUMENT();

loadMacros('PGbasicmacros.pl');

1;
