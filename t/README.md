# Testing

This directory houses the resources for testing PG.  It includes a mix
of strategies, some of which are standalone and some of which require
services to be in operation.  It helps to catch errors before they are
found in production and prevent regressions from being re-introduced.

The philosophy of
[Test Driven Design](https://en.wikipedia.org/wiki/Test-driven_development)
is that when a bug is found, a test is written to show it failing
and when it is fixed, the test will pass.
The unit tests are easy to run and amenable to automation.  Some services
can be "mocked" so that behaviour can be tested in their absence.
All of this is to provide confidence that the code does what is intended
and a working test can be better than documentation because it shows how
the code currently works in practice.


## Integration tests

[Integration testing](https://en.wikipedia.org/wiki/Integration_testing)
tests components working together as a group.  The files with the `.pg`
extension are used to demonstrate the output of the rendering engine.

**TODO:** add an explanation of how to run these integration tests
and their requirements.


## Unit tests

[Unit tests](https://en.wikipedia.org/wiki/Unit_testing) look at small chunks
of self-coherent code to verify the behaviour of a subroutine or module.
This is the test you write to catch corner cases or to explore code branches.
In this repository, all files with the `.t` extension are unit tests which
are found by Perl's [prove](https://perldoc.perl.org/prove) command.
Best practice is to create a directory for each module being tested and
group similar tests together in separate files with a descriptive name.
See **t/units/** for examples (named because it tests the **Units.pm** module,
not that it is where unit tests should be kept)

You can run all the unit tests in the repository from the root directory with

  prove -lr t/

or you can specify a single file to test with `prove -l t/units/electron_volt.t`
The equivalent Perl command to `prove -l` is `perl -Ilib`

See older references on the WebWork page for
[Unit Testing](https://webwork.maa.org/wiki/Unit_Testing)

## Test Dependencies

The unit tests have brought in a new module dependency,
[Test2](https://metacpan.org/pod/Test2::V0) which is the state of the art in
testing Perl modules.  It can compare data structures, examine warnings and
catch fatal errors thrown under expected conditions.  It provides many tools
for testing and randomly executes its subtests to avoid the programmer
depending on stateful data.

To make these easier to install with
[cpanm](https://metacpan.org/dist/App-cpanminus/view/bin/cpanm), there is a
[cpanfile](https://metacpan.org/dist/Module-CPANfile/view/lib/cpanfile.pod)
in the root directory.  Use

  cpanm --installdeps .

which will install the runtime and test dependencies.  To use the cpanfile
skipping all the test module installs, use the `--notest` option with cpanm.
