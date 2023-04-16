# Directory of Sample Problems

This directory contain sample problems that mostly original written by Paul Pearson
and these have been copied from the OPL in `FortLewis/Authoring/Templates`. These
problems are all written in PGML and have been updated to use current versions of
macros.

## Structure of the code documenation

In addition, the comments that are associated with each file in on the webwork wiki
have been embedded as formatted comments in the PGML files. The format for these have the form

```perl
#:%preamble color:blue
#:This is the documentation comments for the preamble
DOCUMENT();

loadMacros('PGstandard.pl','MathObjects.pl','PGML.pl','PGcourse.pl');

TEXT(beginproblem());
#:%setup
#:We use `do { $b = random(2,9,1); } until ( $b != $a );` to generate distinct
#:random numbers.
Context("Numeric");

$a = non_zero_random(-9,9,1);
do { $b = random(2,9,1); } until ( $b != $a );

$answer1 = Compute("$a");
$answer2 = Compute("($a x^($b) + $b)/x")->reduce();
```

where the beginning of a documentation block starts with `#:%` followed by a section name, then any options in the pattern `opt=value` or `opt:value`. The default names are `preamble, setup, statement, answer` and `solution`.

All documentation lines following a `#:%` start with `#:` and are formating in
markdown.

After the documentation lines, the code is then stored up until the next `#:%` line.


## Generate the documentation

The documentation is generated with the `parse-prob-doc.pl` script in the `bin`
directory of pg.  Look at the script for help.

The script `parse-prob-doc.pl` parses each pg file and uses the `prob-template.mt`
template file to generate the html.  This template of type `Mojo::Template`.
See [the mojo documentation](https://docs.mojolicious.org/Mojo/Template) for
more information.
