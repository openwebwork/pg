# Testing PG

This directory houses the resources for testing PG. It includes a mix
of strategies for testing at different scales. It helps to catch errors
before they are found in production and prevent regressions from being
re-introduced.

The philosophy of
[Test Driven Design](https://en.wikipedia.org/wiki/Test-driven_development)
is that when a bug is found, a test is written to show it failing
and when it is fixed, the test will pass.
The unit tests are easy to run and amenable to automation. Some services
can be "mocked" so that behaviour can be tested in their absence.
All of this is to provide confidence that the code does what is intended
and a working test can be better than documentation because it shows how
the code currently works in practice.

Old references can be found on the WebWork wiki page
[Unit Testing](https://webwork.maa.org/wiki/Unit_Testing)

## Unit Tests

[Unit tests](https://en.wikipedia.org/wiki/Unit_testing) look at small chunks
of self-coherent code to verify the behaviour of a subroutine or module.
This is the test you write to catch corner cases or to explore code branches.
In this repository, all files with the `.t` extension are unit tests which
are found by Perl's [prove](https://perldoc.perl.org/prove) command.

The individual unit tests are located in each of the directories.
Best practice is to create a directory for each module being tested and
group similar tests together in separate files with a descriptive name,
such as **t/units/** for testing the **Units.pm** module.

Formal unit tests are located in the the `macros` and `contexts` directories
that are designed to test the pg macros and contexts respectively.

## Running the tests

```bash
cd $PG_ROOT
prove -lr t/
```

will run all of the tests in `.t` files within subdirectories of `t`.

### Running an individual test

If instead, you want to run an individual test, for example the `pgaux.t` test suite,

```bash
cd $PG_ROOT/t/macros
prove -v pgaux.t
```

which will be verbose (`-v`).
Or you could use `prove -lv t/macros/pgaux.t` from the root directory.

## Writing a Unit Test

To write a unit test, the following is needed at the top of the file:

```perl
use Test2::V0;

use lib 't/lib';
use Test::PG;
```

and ensure that `PG_ROOT` is in your environmental variables.

### Example: Running a test

The following shows how to test a Math object

```perl
loadMacros("MathObjects.pl");

Context("Numeric");

my $f = Compute("x^2");

# evaluate f at x=2

is check_score($f->eval(x=>2), '4'), 1, 'math objects: eval x^2 at x=2';
```

The `check_score` subroutine evaluates and compares a MathObject with a string representation of the answer.
If the score is 1, then the two are equal.

## Integration tests

[Integration testing](https://en.wikipedia.org/wiki/Integration_testing)
tests components working together as a group. The files with the `.pg`
extension are used to demonstrate the output of the rendering engine.

**TODO:** add an explanation of how to run these integration tests
and their requirements.

## Test Dependencies

The tests for **Units.pm** have brought in a new module dependency,
[Test2](https://metacpan.org/pod/Test2::V0) which is the state of the art in
testing Perl modules. It can compare data structures, examine warnings and
catch fatal errors thrown under expected conditions. It provides many tools
for testing and randomly executes its subtests to avoid the programmer
depending on stateful data.

To make these easier to install with
[cpanm](https://metacpan.org/dist/App-cpanminus/view/bin/cpanm), there is a
[cpanfile](https://metacpan.org/dist/Module-CPANfile/view/lib/cpanfile.pod)
in the root directory. Use

cpanm --installdeps .

which will install the runtime and test dependencies.
To use the cpanfile for a minimal install skipping the test requirements,
use the `--notest` option with cpanm.
