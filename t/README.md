# Unit Tests for PG

The individual unit tests are located in each of the directories.

Formal unit tests are located in the the `macros` and `contexts` directories that are designed to test the pg macros and contexts respectively.

## Running the tests

```bash
cd $PG_ROOT
prove -r .
```

will run all of the tests in `.t` files within subdirectories of `t`.

### Running an individual test

If instead, you want to run an individual test, for example the `pgaux.t` test suite,

```bash
cd $PG_ROOT/t/macros
prove -v pgaux.t
```

which will be verbose (`-v`).

## Writing a Unit Test

To write a unit test, the following is needed at the top of the file:

```perl
use warnings;
use strict;

package main;

use Test::More;
use Test::Exception;

## the following needs to include at the top of any testing  down to TOP_MATERIAL

BEGIN {
    die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
    $main::pg_dir = $ENV{PG_ROOT};
}

use lib "$main::pg_dir/lib";

require("$main::pg_dir/t/build_PG_envir.pl");

## END OF TOP_MATERIAL
```

and ensure that `PG_ROOT` is in your environmental variables.

### Example: Running a test

The following shows how to test a Math object

```perl
loadMacros("MathObjects.pl");

Context("Numeric");

my $f = Compute("x^2");

# evaluate f at x=2

is(check_score($f->eval(x=>2),"4"),1,"math objects: eval x^2 at x=2");
```

The `check_score` subroutine evaluates and compares a MathObject with a string representation of the answer.  If the score is 1, then the two are equal.
