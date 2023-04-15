# Directory of Sample Problems

This directory contain sample problems that mostly original written by Paul Pearson
and these have been copied from the OPL in `FortLewis/Authoring/Templates`. These
problems are all written in PGML and have been updated to use current versions of
macros.

## Structure of the code documenation

In addition, the comments that are associated with each file in on the webwork wiki
have been embedded as formatted comments in the PGML files. The format for these have the form

```perl
#:preamble:start
#:This is the documentation comments for the preamble
#:preamble:code
DOCUMENT();

loadMacros('PGstandard.pl','MathObjects.pl','PGML.pl','PGcourse.pl');

TEXT(beginproblem());
#:preamble:end
```

where each line of the documentation starts with `#:` and each section has a
`start`, `code` and `end` line that separates the documentation and the code.
The section name (`preamble` above) can be anything, and currently is used for
the coloring and a section title in the documentation.  The default ones are `preamble, setup, statement, answer` and `solution`.

In the documenation block (between the `start` and `code` lines), the format
is in markdown.  Note that since generating paragraphs in markdown requires an
empty line, do this with a `#:` line in the PG code.

## Generate the documentation

The documentation is generated with the `parse-prob-doc.pl` script in the `bin`
directory of pg.  Look at the script for help.

The script `parse-prob-doc.pl` parses each pg file and uses the `prob-template.mt`
template file to generate the html.  This template of type `Mojo::Template`.
See [the mojo documentation](https://docs.mojolicious.org/Mojo/Template) for
more information
