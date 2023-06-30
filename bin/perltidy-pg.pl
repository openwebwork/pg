#!/usr/bin/env perl
################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2022 The WeBWorK Project, https://github.com/openwebwork
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of either: (a) the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version, or (b) the "Artistic License" which comes with this package.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
# Artistic License for more details.
################################################################################

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
