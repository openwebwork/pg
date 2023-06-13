# Directory of Sample Problems

This directory contains sample problems that were mostly original written by
Paul Pearson. These have been copied from the OPL in `FortLewis/Authoring/Templates`.
These problems have been updated to use PGML and current versions of macros.
The wiki also had a number of problems listed as _Problem Techniques_ that did
not exist in the OPL, so were generated to make runnable PG problems.

## Metadata for a Sample Problem

All metadata and documentation are embedded in a problem within comments that
start with `#:%` or `#:`.  Metadata for a problem can appear anywhere but
the standard location is just above the `DOCUMENT();` command.  The following
metadata is currently supported.

- **name**: the name of the problem as will appear in the documentation listings.
- **type**: the type of the problem can be one or more of the following
  * _sample_: a sample problem that would appear in some course.
  * _technique_: a problem from the _Problem Techniques_ on the wiki which may
  demonstrate something of interest, but may not be relevant as a sample problem.
  * _snippet_: part of a problem that is useful if embedded in another problem.

- **subject**: A subject area that a sample problem belongs to.  This may be more
that one.
- **see_also**: A listing of other problems (by the filename) that will appear
in the documentation as a reference.
- **category**: A listing of any categories that the problem would belong to.

In many of these, if more than one is desired, place the list in brackets [ ].
Also, both the singular and plural forms of the type, subject, category are
supported.

Here's an example:
```perl
#:% name = Surface Graph in Cylindrical Coordinates
#:% type = Sample
#:% subject = [Vector Calculus]
#:% see_also = [SpaceCurveGraph.pg, SurfaceGraph.pg]
#:% categories = [graph]
```

## Structure of the code documenation

The comments that are associated with each file in on the WeBWorK
wiki have been embedded as formatted
comments in the PGML files. The format for these have the form

```perl
#:% section = preamble
#: This is the documentation comments for the preamble
DOCUMENT();

loadMacros('PGstandard.pl', 'PGML.pl', 'PGcourse.pl');

#:% setup
#: We use `do { $b = random(2,9,1); } until ( $b != $a );` to generate distinct
#: random numbers.
$a = non_zero_random(-9, 9);
do { $b = random(2,9,1); } until $b != $a;

$answer1 = Compute("$a");
$answer2 = Compute("($a x^($b) + $b) / x")->reduce();
```

where the beginning of a documentation block starts with `#:%` followed by a section name, then any options in the
pattern `opt=value` or `opt:value`. The default names are `preamble`, `setup`, `statement`, `answer`, and `solution`.
Note that at this point no actual options are honored.

All documentation lines that start with `#:` and are formatted in markdown.

All lines following the documentation lines are considered code until the next `#:%` line is encountered.

## Generate the documentation

The documentation is generated with the `parse-prob-doc.pl` script in the `bin`
directory of pg. There are the following options (and many are required):

- `problem_dir` or `d`:  The directory where the sample problems are.  This is
`PG_ROOT/doc/sample-problems`, but required to add.
- `out_dir` or `o`: The directory where the resulting documentation files (HTML)
will be located.
- `pod_root` or `p`: The URL where the POD is located.  This is needed to
correctly link POD documentation from the sample problems.
- `pg_doc_home` or `h`: The URL of the directory for `out_dir`.  This is needed
for correct linking.
- `verbose` or `v`: verbose mode.

After running, each sample problem will be parsed and an HTML file will be generated
(replacing `.pg` with `.html`) as well as three files in the top directory:
`categories.html`, `techniques.html` and `subjects.html` which lists the problem
by categories, the problem techniques and by subject area respectively.  A
problem may be listed in more than one place.


The script `parse-prob-doc.pl` parses each pg file and uses the `problem-template.mt` template file to generate the
html.  This template is processed using the `Mojo::Template` Perl module.  See the
[Mojo::Template documentation](https://docs.mojolicious.org/Mojo/Template) for more information.
