################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2024 The WeBWorK Project, https://github.com/openwebwork
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

unionTables.pl - Functions for creating tables of various kinds.

=cut

sub _unionTables_init {
	ADD_CSS_FILE('js/UnionTables/union-tables.css');
}

=head1 METHODS

=head2 ColumnTable

Make a two-column table.

Usage:

    ColumnTable(col1, col2, [ options ])

The following options control formatting of the table:

=over

=item C<< indent => n >>

The width to indent the first column (default: 0).

=item C<< separation => n >>

The width of the separating gutter (default: 50).

=item C<< valign => type >>

Vertical alignment (default: "middle").

=back

=cut

sub ColumnTable {
	my ($col1, $col2, %options) = @_;

	my ($indent, $separation, $valign) =
		($options{indent} // 0, $options{separation} // 50, $options{valign} // 'middle');

	MODES(
		TeX => '\par\medskip\hbox{\qquad\vtop{'
			. '\advance\hsize by -3em '
			. $col1 . '}}'
			. '\medskip\hbox{\qquad\vtop{'
			. '\advance\hsize by -3em '
			. $col2
			. '}}\medskip',
		HTML => qq{<table><tr style="vertical-align:$valign"><td style="width:${indent}px">&nbsp;</td>}
			. qq{<td>$col1</td><td style="width:${separation}px">&nbsp;</td><td>$col2</td></tr></table>},
		PTX => qq!\n<tabular valign="!
			. lc($valign)
			. qq!">\n<row>\n<cell>$col1</cell>\n<cell>$col2</cell>\n</row>\n</tabular>\n!,

	);
}

=head2 ColumnMatchTable

Use columns for a match-list output

Usage:

    ColumnMatchTable($ml, options)

where C<$ml> is a math list reference and options are those
allowed for ColumnTable above.

=cut

sub ColumnMatchTable {
	my $ml = shift;

	ColumnTable($ml->print_q, $ml->print_a, @_);
}

=head2 BeginTable

Command for tables with no borders.

Usage:  C<BeginTable(options);>

The following options control formatting of the table:

=over

=item C<< border => n >>

Integer value for the width of cell borders
(default: 0, supported values: 0 - 3).

=item C<< spacing => n >>

Integer value for the distance between the borders of adjacent cells
(default: 0, supported values: 0 - 10).

=item C<< padding => n >>

Integer value for cell padding (default: 0, supported values: 0 - 20).

=item C<< tex_spacing => dimen >>

Value for spacing between columns in TeX (default: '1em').

=item C<< tex_border => dimen >>

Value for left- and right border in TeX (default: '0pt').

=item C<< center => 0 or 1 >>

Center the table or not (default: 1).

=back

=cut

sub BeginTable {
	my %options = (
		border      => 0,
		padding     => 0,
		spacing     => 0,
		center      => 1,
		tex_spacing => '1em',
		tex_border  => '0pt',
		@_
	);

	# Sanity checks.
	$options{border}  = 0 unless $options{border}  =~ /^[1-9]\d*$/;
	$options{spacing} = 0 unless $options{spacing} =~ /^[1-9]\d*$/;
	$options{padding} = 0 unless $options{padding} =~ /^[1-9]\d*$/;
	$options{spacing} = 10 if $options{spacing} =~ /^[1-9]\d*$/ && $options{spacing} > 10;
	$options{padding} = 20 if $options{padding} =~ /^[1-9]\d*$/ && $options{padding} > 20;

	my @classes = ('union-table');

	push(@classes, 'union-table-centered') if $options{center};

	my $ptxborder = 'none';
	if ($options{border} == 1) {
		$ptxborder = 'minor';
		push(@classes, 'union-table-bordered-minor');
	} elsif ($options{border} == 2) {
		$ptxborder = 'medium';
		push(@classes, 'union-table-bordered-medium');
	} elsif ($options{border} >= 3) {
		$ptxborder = 'major';
		push(@classes, 'union-table-bordered-major');
	}

	push(@classes, "union-table-s$options{spacing}") if $options{spacing};
	push(@classes, "union-table-p$options{padding}") if $options{padding};

	MODES(
		TeX => '\par\medskip'
			. ($options{center} ? '\centerline' : '')
			. '{\kern '
			. $options{tex_border}
			. '\vbox{\halign{#\hfil&&\kern '
			. $options{tex_spacing}
			. ' #\hfil',
		HTML => '<table class="' . join(' ', @classes) . '">',
		PTX  => qq!\n<tabular top="$ptxborder" bottom="$ptxborder" left="$ptxborder" right="$ptxborder">\n!,
	);
}

=head2 EndTable

Usage:

    EndTable(options)

The following options are supported:

=over

=item C<< tex_border => dimen >>

Extra vertical space in TeX mode (default: 0pt).

=back

=cut

sub EndTable {
	my %options = (tex_border => "0pt", @_);
	my $tbd     = $options{tex_border};
	MODES(
		TeX  => '\cr}}\kern ' . $tbd . '}\medskip' . "\n",
		HTML => '</table>',
		PTX  => "\n</tabular>\n",
	);
}

=head2 Row

Creates a row in the table

Usage:

    Row([ item1, item2, ... ], options);

Each item appears as a separate entry in the table.

The following options control how the row is displayed:

=over

=item C<< indent => num >>

Specifies size of blank column on the left (default: 0).

=item C<< separation => num >>

Specifies separation of columns (default: 30).

=item C<< tex_vspace => "dimen" >>

Specifies additional vertical spacing for TeX.

=item C<< align => "type" >>

Specifies alignment of initial column (default: "left").

=item C<< valign => "type" >>

Specified vertical alignment of row (default: "middle").

=back

=cut

sub Row {
	my ($row, %options) = @_;

	$options{indent}     //= 0;
	$options{separation} //= 30;
	$options{align}      //= 'left';
	$options{valign}     //= 'middle';

	my $indent =
		($options{indent} =~ /^[1-9]\d*$/ && $options{indent} > 0)
		? qq{<td style="padding:0;width:$options{indent}px">&nbsp;</td>}
		: '';
	my $separation =
		($options{separation} =~ /^[1-9]\d*$/ && $options{separation} > 0)
		? qq{<td style="padding:0;width:$options{separation}px">&nbsp;</td>}
		: '';

	my $fill   = lc($options{align}) eq 'center' ? '\hfil' : lc($options{align}) eq 'right' ? '\hfill' : '';
	my $vspace = $options{tex_vspace} ? "\\noalign{\\vskip $options{tex_vspace}}" : '';

	if ($displayMode ne 'PTX' && $displayMode ne 'TeX') {
		$options{align} = 'start' if lc($options{align}) eq 'left';
		$options{align} = 'end'   if lc($options{align}) eq 'right';
	}

	MODES(
		TeX  => '\cr' . $vspace . "\n" . $fill . join('& ', @$row),
		HTML => qq{<tr style="vertical-align:$options{valign}">$indent<td style="text-align:$options{align}">}
			. join("</td>$separation<td>", @$row)
			. '</td></tr>',
		PTX => qq!<row halign="!
			. lc($options{align})
			. qq!" valign="!
			. lc($options{valign})
			. qq!">\n<cell>!
			. join("</cell>\n<cell>", @$row)
			. "</cell>\n</row>\n",
	);
}

=head2 AlignedRow

Usage:

    AlignedRow([ item1, item2, ... ], options);

The following options control how the row is displayed:

=over

=item C<< indent => num >>

Specifies size of blank column on the left (default: 0).

=item C<< separation => num >>

Specifies separation of columns (default: 30).

=item C<< tex_vspace => "dimen" >>

Specifies additional vertical spacing for TeX.

=item C<< align => "type" >>

Specifies text alignment of all cells (default: "center").

=item C<< valign => "type" >>

Specified vertical alignment of row (default: "middle").

=back

=cut

sub AlignedRow {
	my ($row, %options) = @_;

	$options{indent}     //= 0;
	$options{separation} //= 30;
	$options{align}      //= 'center';
	$options{valign}     //= 'middle';

	my $indent =
		($options{indent} =~ /^[1-9]\d*$/ && $options{indent} > 0)
		? qq{<td style="padding:0;width:$options{indent}px">&nbsp;</td>}
		: '';
	my $separation =
		($options{separation} =~ /^[1-9]\d*$/ && $options{separation} > 0)
		? qq{<td style="padding:0;width:$options{separation}px;">&nbsp;</td>}
		: '';

	my $fill   = lc($options{align}) eq 'center' ? '\hfil' : lc($options{align}) eq 'right' ? '\hfill' : '';
	my $vspace = $options{tex_vspace} ? "\\noalign{\\vskip $options{tex_vspace}}" : '';

	if ($displayMode ne 'PTX' && $displayMode ne 'TeX') {
		$options{align} = 'start' if lc($options{align}) eq 'left';
		$options{align} = 'end'   if lc($options{align}) eq 'right';
	}

	MODES(
		TeX  => '\cr' . $vspace . "\n" . $fill . join('&' . $fill, @$row),
		HTML => qq{<tr style="vertical-align:$options{valign}">$indent<td style="text-align:$options{align}">}
			. join(qq{</td>$separation<td style="text-align:$options{align}">}, @$row)
			. '</td></tr>',
		PTX => q!<row halign="!
			. lc($options{align})
			. q!" valign="!
			. lc($options{valign})
			. qq!">\n<cell>!
			. join("</cell>\n<cell>", @$row)
			. "</cell>\n</row>\n",
	);
}

=head2 TableSpace

Add extra space between rows of a table

Usage:

    TableSpace(pixels, points)

where pixels is the number of pixels of space in HTML mode and
points is the number of points to use in TeX mode.

=cut

sub TableSpace {
	my ($rsep, $tsep) = @_;

	$rsep = $tsep if $main::displayMode eq 'TeX' && defined $tsep;
	return ''     if $rsep < 1 || $rsep !~ /^[1-9]\d*$/;

	MODES(
		TeX  => '\vadjust{\kern ' . $rsep . 'pt}' . "\n",
		HTML => qq{<tr><td colspan="10" style="border:none;padding:0;height:${rsep}px;"></td></tr>},
		PTX  => '',
	);
}

=head2 TableLine

A horizontal rule within a table.

=cut

# This could have been a variable,
# but all the other table commands are subroutines, so kept it
# one to be consistent.

sub TableLine {
	MODES(
		TeX  => '\vadjust{\kern2pt\hrule\kern2pt}',
		HTML => '<tr class="union-table-line"><td colspan="10"><hr></td></tr>',
		PTX  => ''
	);
}

1;
