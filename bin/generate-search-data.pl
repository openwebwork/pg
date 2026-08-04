#!/usr/bin/env perl

=head1 NAME

generate-search-data.pl - Generate search data for macro and sample problem
documentation.

=head1 SYNOPSIS

generate-search-data.pl [options]

 Options:
   -o|--out-file   File to save the search data to. (required)

=head1 DESCRIPTION

Generate search data for macro and sample problem documentation.

=cut

use strict;
use warnings;

my $pgRoot;

use Mojo::File qw(curfile);
BEGIN { $pgRoot = curfile->dirname->dirname; }

use lib "$pgRoot/lib";

use Getopt::Long;
use Pod::Usage;

use WeBWorK::PG::SampleProblemParser qw(getSearchData);

my $outFile;
GetOptions("o|out-file=s" => \$outFile);
pod2usage(2) unless $outFile;

getSearchData($outFile);

1;
