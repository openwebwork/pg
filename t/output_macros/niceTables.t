#!/usr/bin/env perl

=head1 niceTables

Test niceTables.pl

=cut

use Test2::V0 '!E', { E => 'EXISTS' };

die "PG_ROOT not found in environment.\n" unless $ENV{PG_ROOT};
do "$ENV{PG_ROOT}/t/build_PG_envir.pl";

use lib "$ENV{PG_ROOT}/lib";

# This is needed for PGsort.
# use WeBWorK::PG::Translator;

loadMacros('niceTables.pl', 'PGstandard.pl');

use Data::Dumper;

my $tab           = DataTable([ [ 1, 2, 3 ], [ 4, 5, 6 ] ]);
my $std_pad       = 'padding:0pt 6pt;';
my $talign_center = 'text-align:center;';

is $tab, qq{<table style="margin:auto;">
<tbody style="vertical-align:top;">
<tr>
<td style="$std_pad$talign_center">
1
</td>
<td style="$std_pad$talign_center">
2
</td>
<td style="$std_pad$talign_center">
3
</td>
</tr>
<tr>
<td style="$std_pad$talign_center">
4
</td>
<td style="$std_pad$talign_center">
5
</td>
<td style="$std_pad$talign_center">
6
</td>
</tr>
</tbody>
</table>}, 'test for a basic table with no options';

my $non_centered_tab = DataTable([ [ 1, 2, 3 ], [ 4, 5, 6 ] ], center => 0);

is $non_centered_tab, qq{<table>
<tbody style="vertical-align:top;">
<tr>
<td style="$std_pad$talign_center">
1
</td>
<td style="$std_pad$talign_center">
2
</td>
<td style="$std_pad$talign_center">
3
</td>
</tr>
<tr>
<td style="$std_pad$talign_center">
4
</td>
<td style="$std_pad$talign_center">
5
</td>
<td style="$std_pad$talign_center">
6
</td>
</tr>
</tbody>
</table>}, 'test for a basic table that is not centered';

my $tab_with_caption = DataTable([ [ 1, 2, 3 ], [ 4, 5, 6 ] ], caption => 'This is the caption');

is $tab_with_caption, qq{<table style="margin:auto;">
<caption>
This is the caption
</caption>
<tbody style="vertical-align:top;">
<tr>
<td style="$std_pad$talign_center">
1
</td>
<td style="$std_pad$talign_center">
2
</td>
<td style="$std_pad$talign_center">
3
</td>
</tr>
<tr>
<td style="$std_pad$talign_center">
4
</td>
<td style="$std_pad$talign_center">
5
</td>
<td style="$std_pad$talign_center">
6
</td>
</tr>
</tbody>
</table>}, 'test for a basic table with caption';

my $tab_with_hor_rules = DataTable([ [ 1, 2, 3 ], [ 4, 5, 6 ] ], horizontalrules => 1);

is $tab_with_hor_rules, qq{<table style="margin:auto;">
<tbody style="vertical-align:top;">
<tr style="border-top:solid 3px;border-bottom:solid 1px;">
<td style="$std_pad$talign_center">
1
</td>
<td style="$std_pad$talign_center">
2
</td>
<td style="$std_pad$talign_center">
3
</td>
</tr>
<tr style="border-bottom:solid 3px;">
<td style="$std_pad$talign_center">
4
</td>
<td style="$std_pad$talign_center">
5
</td>
<td style="$std_pad$talign_center">
6
</td>
</tr>
</tbody>
</table>}, 'test for a basic table with horizontal rules';

done_testing();
