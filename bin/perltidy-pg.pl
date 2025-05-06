#!/usr/bin/env perl

=head1 NAME

pg-perltidy.pl -- Run perltidy on pg problem files.

=head1 SYNOPSIS

    pg-perltidy.pl [options] file1 file2 ...

=head1 DESCRIPTION

Run perltidy on pg problem files.

=head1 OPTIONS

This script accepts all of the options that are accepted by perltidy.  See the
perltidy documentation for details.

Note that if the -pro=file option is not given, then this script will attempt to
use the perltidy-pg.rc file in the PG bin directory for this option.  For this to
work the the perltidy-pg.rc file in the PG bin directory must be readable.

=cut

use strict;
use warnings;

use Perl::Tidy;
use Mojo::File qw(curfile);

use lib curfile->dirname->dirname . '/lib';

use WeBWorK::PG::Tidy qw(pgtidy);

pgtidy();

1;
