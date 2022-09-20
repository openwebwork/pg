#!/usr/bin/env perl

# A simple script + PG problem to test the ability to incluce external data.

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
use lib "$ENV{PG_ROOT}/lib";

use Data::Dumper;

use WeBWorK::PG;

# The pg problem at the bottom of this file is stored in $contents.
my $contents = '';
$contents .= $_ while (<DATA>);

my $pg = WeBWorK::PG->new(r_source => \"$contents", ext_data => { mydata => [1, 2, 3, 4, 5]});

print Dumper $pg->{errors};
print Dumper $pg->{warnings};
print Dumper $pg->{body_text};

# This is the pg file to test.
__DATA__
DOCUMENT();

loadMacros('PGstandard.pl', 'PGML.pl', 'niceTables.pl');

TEXT(beginproblem());
Context("Numeric");

$sum = 0;
@array = @{$ext_data->{mydata}};
for my $val (@array) { $sum += $val; }
$n = scalar(@array);

BEGIN_PGML
Consider the dataset:

[@ DataTable([\@array]) @]*

The mean of the data is [_____]{$sum/$n}
END_PGML

ENDDOCUMENT();
