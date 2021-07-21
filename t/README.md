# Unit Tests for PG

The individual unit tests are located in each of the directories.

Formal unit tests are located in the the `macros` and `contexts` directories that are designed to test the pg macros and contexts respectively.

## Running the tests

```
cd t
prove -r .
```

will run all of the tests in `.t` files within subdirectories.

### Running an individual test

If instead, you want to run an individual test, for example the `pgaux.t` test suite,
```
cd t/macros
prove -lv pgaux.t
```

which will be verbose (`-v`) and report the result of each test (`-l`).

## Writing a Unit Test

To write a unit test, the following is needed at the top of the file:

```perl
use warnings;
use strict;
package main;

use Data::Dump qw/dd/;
use Test::More;


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
```
and ensure that both `PG_ROOT` and `WEBWORK_ROOT` are in your environmental variables.

Now, run some tests. (__SHOW AN EXAMPLE__)

