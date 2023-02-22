
=head1 niceTables.pl

Subroutines for creating tables that
    * conform to accessibility standards
    * may use CSS for HTML styling
    * may use some LaTeX hardcopy styling

DataTable()     Creates a table displaying data.
    Should not be used for layout, such as displaying an array of graphs.

LayoutTable()   Creates a "table" without using an HTML table in HTML output
    Please use LayoutTable whenever you are simply laying out layout content
    for space-saving purposes. Ask yourself if there is any meaningful
    relation between content cells within a column or within a row. If the
    answer is no in both cases, it is likely a case for LayoutTable().


=head2 Description

Command for a typical table.

    DataTable([
        [a,b,c,...],
        [d,e,f,...],
        ...
        ],
        options
    );

    LayoutTable([
        [a,b,c,...],
        [d,e,f,...],
        ...
        ],
        options
    );

As much as possible, options apply to all output formats.
Some options only apply to HTML styling, and some options only apply to PDF hardcopy.
Not all options are supported by every output format. For example PTX cannot use color information.

All features described below apply to a DataTable.
Most also apply to a LayoutTable, with the excpetions being::
    caption
    rowheaders
    header
    colspan
    headerrow

Options for the TABLE

    All ouptut formats:

        center => 0 or 1            center the table (default 1)
        caption => string           caption for the table
        horizontalrules => 0 or 1   for rules above and below every row (default 0)
        texalignment => string      an alignment string like the kinds used in
                                    LaTeX tabular environment: for example 'r|ccp{1in}'
                                    r   right-aligned column
                                    c   center-aligned column
                                    r   left-aligned column
                                    p{width}   left-aligned paragraphs of fixed (absolute) width
                                    X          left-aligned paragraph that expands to fill
                                               (see Xratio below)
                                    |    a vertical rule
                                         (n adjacent pipes makes one rule that is n times thick)
                                    !{\vrule width ...}  vertical rule of the indicated width
                                                         (width must be an absolute width)
                                    >{commands}   execute commands at each cell in the column
                                                  For example, 'c>{\color{blue}}c' will make the
                                                  second column have blue text.
                                                  The following LaTeX commands may be used:
                                                      \color{colorname}      text color
                                                      \color[HTML]{xxxxxx}   text color
                                                          (xxxxxx is a 6-character hex color code)
                                                      \columncolor{colorname}      background color
                                                      \columncolor[HTML]{xxxxxx}   background color
                                                          (xxxxxx is a 6-character hex color code)
                                                      \bfseries   bold
                                                      \itshape    italics
                                                      \ttfamily   monospace
                                                    Other LaTeX commands apply only to hardcopy output.
        align => string             convenient short version of texalignment
        Xratio => number            applies when X is part of overall alignment
                                    Xratio must be some number with 0 < Xratio <= 1 (default 0.97)
                                    The table will only be Xratio wide, relative to the overall
                                    horizontal space. And X columns expland to fill available space.
        encase => [ , ]             Encases all table entries in the two entries. Most commonly used to
                                    wrap math delimiters if you want all content in math mode. In that
                                    case, use [$BM,$EM]. See also noencase for individual cells.
        rowheaders => 0 or 1        Make the first element of every row a row header.
        valign => 'top'             Can be 'top', 'middle', or 'bottom'. Applies to all rows. See
                                    below to override for an individual row.

    HTML output:

        Note: each css property setting should inlude a colon and a semicolon.
        For example:  'font-family: fantasy; text-decoration: underline;'

        tablecss => css string      css styling commands for the table element
        captioncss => css string    css styling commands for the caption element
        columnscss => array ref     an array reference to css strings for columns
                                    Note: only four css properties apply to a col element:
                                        border (family)
                                        background (family)
                                        width
                                        column-span
        datacss => css string       css styling commands for td elements
        headercss => css string     css styling commands for th elements
        allcellcss => css string    css styling commands for all cells

Options for CELLS

    Each cell entry can be an array reference where the first entry is the actual
    cell content, and then key-value pairs follow. For example, in a table with four columns,
    to make the first cell span two columns, enter the first cell as an array reference:
    [[a, colspan => 2], b, c]
    Alternatively, using a hash reference with a data key:
    [{data => a, colspan => 2}, b, c]

    All ouptut formats:

        halign => string            Similar to the components for texalignment above. However, only
                                    l, c, r, p{}, and vertical rule specifications should be used.
                                    With vertical rule specifiers, any left vertical rule will only
                                    be observed for cells is in the first column. Otherwise, use a
                                    right vertical rule on the cell to the left.
        header => type,             Declares the scope of the HTML th element. Case-insensitive:
                                        th   generic table header
                                        ch   column header
                                             ('col' and 'column' work too)
                                        rh   row header
                                             ('row' works too)
                                        td   overrides a headerrow or rowheaders option
        tex => commands             execute commands at start of a cell, with scope the entire cell
                                    The following LaTeX commands may be used:
                                        \color{colorname}      text color
                                        \color[HTML]{xxxxxx}   text color
                                            (xxxxxx is a 6-character hex color code)
                                        \cellcolor{colorname}      background color
                                        \cellcolor[HTML]{xxxxxx}   background color
                                            (xxxxxx is a 6-character hex color code)
                                        \bfseries   bold
                                        \itshape    italics
                                        \ttfamily   monospace
                                    Other LaTeX commands apply only to hardcopy output.
        b=>1, i=>1, m=>1            Shortcuts for \bfseries, \itshape, and \ttfamily in tex option
        noencase => 0 or 1          If you are using encase (see above) use this to opt out
        colspan => n                Positive integer; for cells that span more than one column
                                    when using this, you usually set halign as well.
                                    May not behave as expected for complicated colspan combinations

    HTML output:

        cellcss => string            css styling commands for this cell

    PDF haradcopy output:

        texpre => tex code           For more fussy cell-by-cell alteration of the tex version of 
        texpost => tex code          the table, code to place before and after the cell content
        texencase => array ref       Shortcut for entering [texpre,texpost] at once.

Options for ROWS

    Some parameters in a cell's options array actually affect the entire row.
    When there is a clash, the last declaration in the row will be used.

    All ouptut formats:

        rowcolor => string           Must either be in the form 'colorname' or '[HTML]{xxxxx}'
                                     where xxxxxx is a 6-ccharacter hex color code
                                     Sets the row's background color.
        rowcss => string             css styling commands for the row
        headerrow => 0 or 1          Makes an entire row use header cells (with column scope)
        top => +int or string        When used on the first row, creates a top rule
                                     Has no effect on other rows
                                     Thickness is either n pixels or a width like '0.04em'.
        bottom => +int or string     Creates a bottom rule
                                     Thickness is either n pixels or a width like '0.04em'.
        valign => string             Override table's overall vertical alignment for this row
                                     Can be 'top', 'middle', or 'bottom'

=cut

sub _niceTables_init { };    # don't reload this file


sub DataTable {
	return NiceTables->DataTable(@_);
}

sub LayoutTable {
	return NiceTables->LayoutTable(@_);
}

package NiceTables; 

sub DataTable {
	my $class = shift;
	my $userArray = shift;
	my $dataArray = DataArray($userArray);
	my $optsArray = OptionsArray($userArray);
	my $colCount  = ColumnCount($optsArray);
	my $tableOpts = TableOptions($colCount, @_);
	my $alignment = ParseAlignment($tableOpts->{texalignment});
	return TableEnvironment($dataArray, $optsArray, $colCount, $tableOpts, $alignment);
}

sub LayoutTable {
	return DataTable(@_, LaYoUt => 1);
}

# Make the outer table enovornment
# Handle center, caption, horizontalrules, texalignment, Xratio
# overall halign OK for tex, ptx but for html must be passed to cells
# vertical rules from alingment OK
# encase, rowheaders should be passed to cells
# various css should be self-explanatory
sub TableEnvironment {
	my ($dataArray, $optsArray, $colCount, $tableOpts, $alignment) = @_;
	my @alignment = @$alignment;

	# determine if somewhere in the overall alignment, there are X columns
	my $hasX = 0;
	for my $align (@alignment) {
		if ($align->{halign} eq 'X') {
			$hasX = 1;
			last;
		}
	}

	# determine if first row has top
	my $top;
	for my $x (@{ $optsArray->[0] }) {
		$top = $x->{top} if ($x->{top});
	}

	# get cols (only has some formatting specifications) and rows (the actual content)
	my $cols = Cols($alignment, $tableOpts, $optsArray);
	my $rows = Rows($dataArray, $optsArray, $colCount, $tableOpts, $alignment);

	# TeX
	my $tex          = $rows;
	my $tabulartype  = $hasX ? 'tabularx'                        : 'tabular';
	my $tabularwidth = $hasX ? "$tableOpts->{Xratio}\\linewidth" : '';
	$tex = latexEnvironment($tex, $tabulartype, [ $tabularwidth, $tableOpts->{texalignment} ], ' ');
	$tex = prefix($tex, '\centering')                      if $tableOpts->{center};
	$tex = prefix($tex, '\renewcommand{\arraystretch}{2}') if $tableOpts->{LaYoUt};
	$tex =
		suffix($tex,
			"\\captionsetup{textfont={sc},belowskip=12pt,aboveskip=4pt}\\captionof*{table}{$tableOpts->{caption}}")
		if ($tableOpts->{caption});
	$tex = latexEnvironment($tex, 'minipage', ['\linewidth']);
	$tex = wrap($tex, '\par', '\par\vspace{1pc}');

	# HTML
	my $css = $tableOpts->{tablecss};
	if ($hasX) {
		$css .= css('width', $tableOpts->{Xratio} * 100 . '%');
	}
	$css .= css('border-left', getRuleCSS($alignment[0]->{left}));
	$css .= css('margin',      'auto') if $tableOpts->{center};

	my $html     = $rows;
	my $htmlcols = '';
	$htmlcols = tag($cols, 'colgroup')
		unless ($cols =~ /^(<col>|\n)*$/ or $tableOpts->{LaYoUt});
	$html = prefix($html, $htmlcols);
	my $htmlcaption = tag($tableOpts->{caption}, 'caption', { style => $tableOpts->{captioncss} });
	$html = prefix($html, $htmlcaption) unless $tableOpts->{LaYoUt};

	if ($tableOpts->{LaYoUt}) {
		$css .= css('display',         'table');
		$css .= css('border-collapse', 'collapse');
		$html = tag($html, 'div', { style => $css });
	} else {
		$html = tag($html, 'table', { style => $css });
	}

	# PTX
	my $ptx     = $rows;
	my $ptxleft = getPTXthickness($alignment[0]->{left});
	my $ptxtop  = ($tableOpts->{horizontalrules}) ? 'major' : '';
	$ptxtop = getPTXthickness($top) if $top;
	my $ptxwidth;
	my $ptxmargins;

	if ($hasX) {
		$ptxwidth = $tableOpts->{Xratio} * 100;
		my $leftmargin  = ($tableOpts->{center}) ? (100 - $ptxwidth) / 2 : 0;
		my $rightmargin = 100 - $ptxwidth - $leftmargin;
		$ptxmargins = "${leftmargin}% ${rightmargin}%";
		$ptxwidth .= '%';
	} elsif (!$tableOpts->{center}) {
		$ptxwidth   = '100%';
		$ptxmargins = '0% 0%';
	}
	my $ptxbottom = ($tableOpts->{horizontalrules}) ? 'minor' : '';
	if ($tableOpts->{LaYoUt}) {
		$ptx = tag(
			$ptx,
			'sbsgroup',
			{
				width   => $ptxwidth,
				margins => $ptxmargins,
			}
		);
	} elsif (!$tableOpts->{LaYoUt}) {
		$ptx = prefix($rows, $cols);
		$ptx = tag(
			$ptx,
			'tabular',
			{
				valign  => ($tableOpts->{valign} != 'middle') ? $tableOpts->{valign} : '',
				width   => $ptxwidth,
				margins => $ptxmargins,
				left    => $ptxleft,
				top     => $ptxtop,
				bottom  => $ptxbottom
			}
		);
	}

	# We fake a caption as a following tabular
	my $ptxcaption = '';
	if ($tableOpts->{caption}) {
		$ptxcaption = $tableOpts->{caption};
		$ptxcaption = tag($ptxcaption, 'cell');
		$ptxcaption = tag($ptxcaption, 'row');
		my $ptxcapwidth = '';
		if ($hasX) {
			$ptxcapwidth = $tableOpts->{Xratio} * 100 . '%';
		} else {
			$ptxcapwidth = '50%';
		}
		$ptxcapcol  = tag('', 'col', { width => $ptxcapwidth });
		$ptxcaption = prefix($ptxcaption, $ptxcapcol);
		$ptxcaption = tag($ptxcaption, 'tabular', { width => $ptxwidth, margins => $ptxmargins });
	}
	$ptx = suffix($ptx, $ptxcaption);

	return main::MODES(
		TeX  => $tex,
		HTML => $html,
		PTX  => $ptx,
	);

}

sub Cols {
	my ($alignment, $tableOpts, $optsArray) = @_;
	my $columnscss = $tableOpts->{columnscss};
	my @html;
	my @ptx;
	my @alignment = @$alignment;
	my $leftend   = shift(@alignment);

	for my $i (0 .. $#alignment) {
		my $align = $alignment[$i];

		# determine if this column has paragraph cells
		my $width = '';
		for my $y (@$optsArray) {
			if ($y->[$i]->{halign} =~ /^p\{([^}]*?)\}/) {
				$width = $1;
			}
		}

		# HTML
		my $htmlright = '';
		$htmlright .= css('border-right', 'solid 2px')
			if ($tableOpts->{rowheaders} && $i == 0);
		$htmlright .= css('border-right', getRuleCSS($align->{right}));

		$htmlcolcss = $columnscss->[$i];
		if ($align->{tex} =~ /\\columncolor(\[HTML\])?{(.*?)[}!]/) {
			$htmlcolcss .= css('background-color', ($1 ? '#' : '') . $2);
		}

		my $html = tag('', 'col', { style => "${htmlright}${htmlcolcss}" });
		push(@html, $html);

		# PTX
		my $ptxhalign = '';
		$ptxhalign = 'center' if ($align->{halign} eq 'c');
		$ptxhalign = 'right'  if ($align->{halign} eq 'r');
		my $ptxright = '';
		$ptxright = getPTXthickness($align->{right});
		my $ptxwidth = '';
		$ptxwidth = getWidthPercent($align->{width}) if $align->{width};
		$ptxwidth = ($tableOpts->{Xratio} / ($#alignment + 1) * 100) . '%'
			if ($align->{halign} eq 'X');
		$ptxwidth = getWidthPercent($width) if $width;
		my $ptx = tag(
			'', 'col',
			{
				header => ($tableOpts->{rowheaders} && $i == 0) ? 'yes' : '',
				halign => $ptxhalign,
				right  => $ptxright,
				width  => $ptxwidth
			}
		);
		push(@ptx, $ptx);
	}

	$return = main::MODES(
		HTML => join("\n", @html),
		PTX  => join("\n", @ptx)
	);

	return $return;

}

sub Rows {
	my ($dataArray, $optsArray, $colCount, $tableOpts, $alignment) = @_;
	my @data = @$dataArray;

	my @tex;
	my @htmlhead;
	my @htmlbody;
	my $stillinhtmlhead = 1;
	my @ptx;
	for my $i (0 .. $#data) {
		my $rowData = $data[$i];
		my $rowOpts = $optsArray->[$i];
		my $row     = Row($rowData, $rowOpts, $tableOpts, $alignment);

		# establish if this row has certain things
		# non falsy last values are used
		my $bottom    = 0;
		my $top       = 0;
		my $rowcolor  = '';
		my $headerrow = '';
		my $valign    = '';
		for my $x (@$rowOpts) {
			$bottom    = $x->{bottom}   if ($x->{bottom});
			$top       = $x->{top}      if ($x->{top} && $i == 0);
			$rowcolor  = $x->{rowcolor} if ($x->{rowcolor});
			$headerrow = 'yes'          if ($x->{headerrow});
			$valign    = $x->{valign}   if ($x->{valign});
		}

		# TeX
		my $tex = $row;

		# separator argument is space to avoid PGML catcode manipulation issues
		$tex = prefix($tex, "\\rowcolor{$rowcolor}", ' ')
			if ($rowcolor =~ /^[^{]+$/);
		$tex = prefix($tex, "\\rowcolor$rowcolor", ' ')
			if ($rowcolor =~ /^(\[HTML\])?\{[^}]+\}/);
		$tex = prefix($tex, "\\toprule", ' ')
			if ($top || ($i == 0 && $tableOpts->{horizontalrules}));
		$tex = suffix($tex, "\\\\",      ' ') unless ($i == $#data);
		$tex = suffix($tex, "\\midrule", ' ')
			if ($i < $#data && ($bottom || $tableOpts->{horizontalrules})
				|| $headerrow);
		$tex = suffix($tex, "\\\\\\bottomrule", ' ')
			if ($i == $#data && ($bottom or $tableOpts->{horizontalrules}));
		push(@tex, $tex);

		# HTML
		my $css = '';
		for my $x (@$rowOpts) {
			$css .= $x->{rowcss} if $x->{rowcss};
		}
		if ($rowcolor =~ /(\[HTML\])?{(.*?)[}!]/) {
			$css .= css('background-color', ($1 ? '#' : '') . $2);
		} else {
			$css .= css('background-color', $rowcolor) if $rowcolor;
		}
		$css .= css('border-top', 'solid 3px')
			if ($i == 0 && $tableOpts->{horizontalrules});
		$css .= css('border-top',    getRuleCSS($top));
		$css .= css('border-bottom', 'solid 1px')
			if ($i < $#data && $tableOpts->{horizontalrules});
		$css .= css('border-bottom', 'solid 3px')
			if ($i == $#data && $tableOpts->{horizontalrules});
		$css .= css('border-bottom',  getRuleCSS($bottom));
		$css .= css('vertical-align', $valign);
		my $html;

		if ($tableOpts->{LaYoUt}) {
			$css .= css('display', 'table-row');
			$html = tag($row, 'div', { style => $css });
			push(@htmlbody, $html);
		} else {
			$html = tag($row, 'tr', { style => $css });
			if ($stillinhtmlhead && $headerrow) {
				push(@htmlhead, $html);
			} else {
				$stillinhtmlhead = 0;
				push(@htmlbody, $html);
			}
		}

		# PTX
		my $ptx .= $row;
		my $ptxbottom = '';
		$ptxbottom = 'minor'
			if ($i < $#data && $tableOpts->{horizontalrules});
		$ptxbottom = 'major'
			if ($i == $#data && $tableOpts->{horizontalrules});
		$ptxbottom = getPTXthickness($bottom) if $bottom;
		my $ptxleft = '';
		$ptxleft = 'minor'  if ($rowOpts->[0]->{halign} =~ /^\s*\|/);
		$ptxleft = 'medium' if ($rowOpts->[0]->{halign} =~ /^\s*\|\s*\|/);
		$ptxleft = 'major'  if ($rowOpts->[0]->{halign} =~ /^\s*\|\s*\|\s*\|/);

		if ($rowOpts->[0]->{halign} =~ /^(?:\s|\|)*!{\s*\\vrule\s+width\s+([^}]*?)\s*}/) {
			$ptxleft = 'minor'  if ($1);
			$ptxleft = 'minor'  if ($1 == '0.04em');
			$ptxleft = 'medium' if ($1 == '0.07em');
			$ptxleft = 'major'  if ($1 == '0.11em');
		}

		$ptxleft = ''     if ($ptxleft eq $alignment->[0]->{left});
		$ptxleft = "none" if (!$ptxleft && $rowOpts->[0]->{halign} && $alignment->[0]->{left});

		if ($tableOpts->{LaYoUt}) {
			my $ptxwidthsum = 0;
			my $ptxautocols = $colCount;
			for my $j (1 .. $colCount) {
				if ($rowOpts->[ $j - 1 ]->{width}) {
					$ptxwidthsum += substr getWidthPercent($optsArray->[ $j - 1 ]->{width}), 0, -1;
					$ptxautocols -= 1;
				} elsif ($alignment->[$j]->{width}) {
					$ptxwidthsum += substr getWidthPercent($alignment->[$j]->{width}), 0, -1;
					$ptxautocols -= 1;
				}
			}
			# determine if somewhere in the overall alignment, there are X columns
			my $hasX = 0;
			for my $align (@$alignment) {
				if ($align->{halign} eq 'X') {
					$hasX = 1;
					last;
				}
			}
			my $leftoverspace  = (($hasX) ? $tableOpts->{Xratio} * 100 : 100) - $ptxwidthsum;
			my $divvyuptherest = 0;
			$divvyuptherest = int($leftoverspace / $ptxautocols * 10000) / 10000 unless ($ptxautocols == 0);
			my @ptxwidths;
			for my $j (1 .. $colCount) {
				if ($rowOpts->[ $j - 1 ]->{width}) {
					push(@ptxwidths, getWidthPercent($rowOpts->[ $j - 1 ]->{width}));
				} elsif ($alignment->[$j]->{width}) {
					push(@ptxwidths, getWidthPercent($alignment->[$j]->{width}));
				} else {
					push(@ptxwidths, $divvyuptherest . '%');
				}
			}

			my $ptxwidths = join(" ", @ptxwidths);
			$ptx = tag(
				$ptx,
				'sidebyside',
				{
					valign  => ($valign) ? $valign : $tableOpts->{valign},
					margins => '0% 0%',
					widths  => $ptxwidths,
				}
			);
		} else {
			$ptx = tag(
				$ptx, 'row',
				{
					left   => $ptxleft,
					valign => $valign,
					header => $headerrow,
					bottom => $ptxbottom
				}
			);
		}
		push(@ptx, $ptx);
	}

	my $htmlout;
	if ($tableOpts->{LaYoUt}) {
		$htmlout = join("\n", @htmlbody);
	} else {
		my $htmlvalign = '';
		$htmlvalign = $tableOpts->{valign}
			unless ($tableOpts->{valign} eq 'middle');
		$htmlout = tag(join("\n", @htmlbody), 'tbody', { style => css('vertical-align', $htmlvalign) });
		$htmlout = prefix(
			$htmlout,
			tag(
				join("\n", @htmlhead),
				'thead',
				{
					style => css('vertical-align', $htmlvalign) . css('border-bottom', 'solid 2px')
				}
			)
		) if (@htmlhead);
	}

	$return = main::MODES(
		TeX  => join(" ", @tex),
		HTML => $htmlout,
		PTX  => join("\n", @ptx),
	);

	return $return;

}

sub Row {
	my ($rowData, $rowOpts, $tableOpts, $alignment) = @_;
	my @alignment = @$alignment;
	my $leftend   = shift(@alignment);
	my @data      = @$rowData;
	my $headerrow = '';
	my $valign    = '';
	for my $x (@$rowOpts) {
		$headerrow = 'yes'        if ($x->{headerrow});
		$valign    = $x->{valign} if ($x->{valign});
	}

	my @tex;
	my @html;
	my @ptx;
	for my $i (0 .. $#data) {
		my $cellOpts = $rowOpts->[$i];
		my $cell     = $data[$i];

		# TeX
		my $tex = $cell;
		$tex = prefix($tex, $cellOpts->{tex});
		$tex = wrap($tex, @{ $tableOpts->{encase} })
			unless $cellOpts->{noencase};
		$tex = wrap($tex, $cellOpts->{texpre}, $cellOpts->{texpost});
		$tex = prefix($tex, '\bfseries')
			if ($tableOpts->{rowheaders} and $i == 0
				or $headerrow
				or $cellOpts->{header} =~ /^(th|rh|ch|col|column|row)$/i);
		if ($cellOpts->{colspan} > 1
			or $cellOpts->{halign}
			or $valign
			or ($tableOpts->{valign} && $tableOpts->{valign} ne 'top'))
		{
			my $columntype = $cellOpts->{halign};
			$columntype = $alignment[$i]->{halign} // 'l' unless $columntype;
			$columntype = 'p{' . $tableOpts->{Xratio} / ($#data + 1) . "\\linewidth}"
				if ($columntype eq 'X');
			$columntype = "p{$alignment[$i]->{width}}"
				if ($alignment[$i]->{width});
			$columntype =~ s/^p/m/ if ($valign eq 'middle');
			$columntype =~ s/^p/b/ if ($valign eq 'bottom');
			$columntype =~ s/^p/m/ if ($tableOpts->{valign} eq 'middle');
			$columntype =~ s/^p/b/ if ($tableOpts->{valign} eq 'bottom');
			$tex = latexCommand('multicolumn', [ $cellOpts->{colspan}, $columntype, $tex ]);
		}
		$tex = suffix($tex, '&', ' ') unless ($i == $#data);
		push(@tex, $tex);

		# HTML
		my $t     = 'td';
		my $scope = '';
		$t     = 'th' and $scope = 'row' if ($i == 0 && $tableOpts->{rowheaders});
		$t     = 'th' and $scope = 'col' if ($headerrow);
		$t     = 'th'                 if ($cellOpts->{header} =~ /^(th|rh|ch|col|column|row)$/i);
		$scope = 'row'                if ($cellOpts->{header} =~ /^(rh|row)$/i);
		$scope = 'col'                if ($cellOpts->{header} =~ /^(ch|col|column)$/i);
		$t     = 'td' and $scope = '' if ($cellOpts->{header} =~ /^td$/i);
		my $css = '';

		# col level
		$css .= css('text-align', 'center')
			if ($alignment[$i]->{halign} eq 'c');
		$css .= css('text-align', 'right')
			if ($alignment[$i]->{halign} eq 'r');
		$css .= css('width', $alignment[$i]->{width})
			if ($alignment[$i]->{width});
		$css .= css('font-weight', 'bold')
			if ($alignment[$i]->{tex} =~ /\\bfseries/);
		$css .= css('font-style', 'italic')
			if ($alignment[$i]->{tex} =~ /\\itshape/);
		$css .= css('font-family', 'monospace')
			if ($alignment[$i]->{tex} =~ /\\ttfamily/);
		if ($alignment[$i]->{tex} =~ /\\color(\[HTML\])?{(.*?)[}!]/) {
			$css .= css('color', ($1 ? '#' : '') . $2);
		}

		# cell level
		$css .= $cellOpts->{cellcss};
		if ($cellOpts->{halign} =~ /^([|\s]*\|)/ && $i == 0) {
			my $count = $1 =~ tr/\|//;
			$css .= css('border-left', "solid ${count}px");
		}
		if ($cellOpts->{halign} =~ /^(\s\|)*!{\\vrule\s+width\s+([^}]*?)}/
			&& $i == 0)
		{
			$css .= css('border-left', "solid $2");
		}
		if ($cellOpts->{halign} =~ /(\|[|\s]*)$/) {
			my $count = $1 =~ tr/\|//;
			$css .= css('border-right', "solid ${count}px");
		}
		if ($cellOpts->{halign} =~ /!{\\vrule\s+width\s+([^}]*?)}\s*$/) {
			$css .= css('border-right', "solid $1");
		}
		$css .= css('text-align', 'left') if ($cellOpts->{halign} =~ /^l/);
		$css .= css('text-align', 'center')
			if ($cellOpts->{halign} =~ /^c/);
		$css .= css('text-align',  'right') if ($cellOpts->{halign} =~ /^r/);
		$css .= css('text-align',  'left')  if ($cellOpts->{halign} =~ /^p/);
		$css .= css('width',       $1)      if ($cellOpts->{halign} =~ /^p{([^}]*?)}/);
		$css .= css('font-weight', 'bold')
			if ($cellOpts->{tex} =~ /\\bfseries/);
		$css .= css('font-style', 'italic')
			if ($cellOpts->{tex} =~ /\\itshape/);
		$css .= css('font-family', 'monospace')
			if ($cellOpts->{tex} =~ /\\ttfamily/);

		if ($cellOpts->{tex} =~ /\\cellcolor(\[HTML\])?{(.*?)[}!]/) {
			$css .= css('background-color', ($1 ? '#' : '') . $2);
		}
		if ($cellOpts->{tex} =~ /\\color(\[HTML\])?{(.*?)[}!]/) {
			$css .= css('color', ($1 ? '#' : '') . $2);
		}
		$css .= $tableOpts->{allcellcss};
		$css .= $tableOpts->{headercss} if ($t eq 'th');
		$css .= $tableOpts->{datacss}   if ($t eq 'td');
		my $html = $cell;
		$html = wrap($cell, @{ $tableOpts->{encase} })
			unless $cellOpts->{noencase};
		if ($tableOpts->{LaYoUt}) {
			$css .= css('display', 'table-cell');
			my $cellvalign = $tableOpts->{valign};
			$cellvalign = $valign if ($valign);
			$css        = css('vertical-align', $cellvalign) . $css;
			$css        = css('padding',        '12pt') . $css;
			if ($alignment[$i]->{tex} =~ /\\columncolor(\[HTML\])?{(.*?)[}!]/) {
				$css = css('background-color', ($1 ? '#' : '') . $2) . $css;
			}
			$css  = css('border-right', getRuleCSS($alignment[$i]->{right})) . $css;
			$html = tag($html, 'div', { style => $css });
		} else {
			$css  = css('padding', '0pt 6pt') . $css;
			$html = tag(
				$html, $t,
				{
					style   => $css,
					scope   => $scope,
					colspan => ($cellOpts->{colspan} > 1) ? $cellOpts->{colspan} : ''
				}
			);
		}
		push(@html, $html);

		# PTX
		my $ptx = $cell;
		$ptx = wrap($ptx, @{ $tableOpts->{encase} })
			unless $cellOpts->{noencase};

		$ptx = tag($ptx, 'p')
			if ((
				$alignment[$i]->{width}
				or $alignment[$i]->{halign} eq 'X'
				or $cellOpts->{halign} =~ /^p/
			))
			&& !$tableOpts->{LaYoUt};
		my $ptxhalign = '';
		$ptxhalign = 'center' if ($cellOpts->{halign} =~ /c/);
		$ptxhalign = 'right'  if ($cellOpts->{halign} =~ /r/);
		my $ptxright = '';
		$ptxright = 'minor'  if ($cellOpts->{halign} =~ /\|\s*$/);
		$ptxright = 'medium' if ($cellOpts->{halign} =~ /\|\s*\|\s*$/);
		$ptxright = 'major'  if ($cellOpts->{halign} =~ /\|\s*\|\s*\|\s*$/);

		if ($cellOpts->{halign} =~ /!{\s*\\vrule\s+width\s+([^}]*?)\s*}\s*$/) {
			$ptxright = 'minor'  if ($1);
			$ptxright = 'minor'  if ($1 == '0.04em');
			$ptxright = 'medium' if ($1 == '0.07em');
			$ptxright = 'major'  if ($1 == '0.11em');
		}
		if ($tableOpts->{LaYoUt}) {
			$ptx = tag($ptx, 'p') unless ($cell =~ /<image[ >]/);
			$ptx = tag($ptx, 'stack',);

		} else {
			$ptx = tag(
				$ptx, 'cell',
				{
					halign  => $ptxhalign,
					colspan => ($cellOpts->{colspan} > 1) ? $cellOpts->{colspan} : '',
					right   => $ptxright
				},
				''
			);
		}
		push(@ptx, $ptx);
	}

	$return = main::MODES(
		TeX  => join(" ",  @tex),
		HTML => join("\n", @html),
		PTX  => join("\n", @ptx),
	);

	return $return;

}

# Takes the original nested array and returns a simplified version with only the content
# Also returns the true column count, accounting for colspan
sub DataArray {
	my $originalArrayRef = shift;
	my @originalArray    = @$originalArrayRef;
	my $lastRowIndex     = $#originalArray;
	my @outArray;
	for my $i (0 .. $lastRowIndex) {
		my @outRow;
		my $originalRowRef = $originalArray[$i];
		my @originalRow    = @$originalRowRef;
		my $lastColIndex   = $#originalRow;
		for my $j (0 .. $lastColIndex) {
			my $originalCell = $originalRow[$j];
			my $outCell;
			if (ref($originalCell) eq 'HASH') {
				$outCell = $originalCell->{'data'};
			} elsif (ref($originalCell) eq 'ARRAY') {
				$outCell = $originalCell->[0];
			} else {
				$outCell = $originalCell;
			}
			$outRow[$j] = $outCell;
		}
		my $outRowRef = \@outRow;
		$outArray[$i] = $outRowRef;
	}
	$outArrayRef = \@outArray;
	return $outArrayRef;
}

# Takes the original nested array and returns a simplified version with only the options as a hash
sub OptionsArray {
	my $originalArrayRef = shift;
	my @originalArray    = @$originalArrayRef;
	my $lastRowIndex     = $#originalArray;
	my %supportedOptions = (
		halign    => '',
		header    => '',
		tex       => '',
		noencase  => 0,
		colspan   => 1,
		cellcss   => '',
		texpre    => '',
		texpost   => '',
		rowcolor  => '',
		rowcss    => '',
		headerrow => '',
		top       => 0,
		bottom    => 0,
		valign    => '',
	);
	my @outArray;
	for my $i (0 .. $lastRowIndex) {
		my @outRow;
		my $originalRowRef = $originalArray[$i];
		my @originalRow    = @$originalRowRef;
		my $lastColIndex   = $#originalRow;
		for my $j (0 .. $lastColIndex) {
			my $originalCell = $originalRow[$j];
			my $outCell;
			my %outHash = %supportedOptions;
			if (ref($originalCell) eq 'HASH') {
				for my $key (keys(%supportedOptions)) {
					$outHash{$key} = $originalCell->{$key}
						if defined($originalCell->{$key});
				}

				# convenience
				$outHash{tex} .= '\bfseries' if ($originalCell->{b});
				$outHash{tex} .= '\itshape'  if ($originalCell->{i});
				$outHash{tex} .= '\ttfamily' if ($originalCell->{m});
				$outHash{texpre} = $outHash{texpre} . $originalCell->{texencase}->[0]
					if $originalCell->{texencase};
				$outHash{texpost} = $originalCell->{texencase}->[1] . $outHash{texpost}
					if $originalCell->{texencase};

				# legacy misnomers
				$outHash{bottom} = $originalCell->{midrule}
					if (defined($originalCell->{midrule})
						&& !$outHash{bottom});
			} elsif (ref($originalCell) eq 'ARRAY') {
				my @originalOptions = (@$originalCell);
				my $data            = shift(@originalOptions);
				my %originalOptions = @originalOptions;
				for my $key (keys(%supportedOptions)) {
					$outHash{$key} = $originalOptions{$key}
						if defined($originalOptions{$key});
				}

				# convenience
				$outHash{tex} .= '\bfseries' if ($originalOptions{b});
				$outHash{tex} .= '\itshape'  if ($originalOptions{i});
				$outHash{tex} .= '\ttfamily' if ($originalOptions{m});
				$outHash{texpre} = $outHash{texpre} . $originalOptions{texencase}->[0]
					if $originalOptions{texencase};
				$outHash{texpost} = $originalOptions{texencase}->[1] . $outHash{texpost}
					if $originalOptions{texencase};

				# legacy misnomers
				$outHash{bottom} = $originalOptions{midrule}
					if (defined($originalOptions{midrule})
						&& !$outHash{bottom});
			}

			# clean up
			# remove any left vertical rule specifications from halign
			if ($j > 0
				&& $outHash{halign} =~ /((?<!\w)[lcrp](?!\w)\s*(\{[^}]*?\})?(\||!\{[^}]*?\}|\s)*)/)
			{
				$outHash{halign} = $1;
			}

			$outCell = \%outHash;
			$outRow[$j] = $outCell;
		}
		my $outRowRef = \@outRow;
		$outArray[$i] = $outRowRef;
	}
	$outArrayRef = \@outArray;
	return $outArrayRef;
}

sub ColumnCount {
	my $optsRef      = shift;
	my @options      = @$optsRef;
	my $lastRowIndex = $#options;
	my $colCount     = 0;
	for my $i (0 .. $lastRowIndex) {
		my $rowOptsRef      = $options[$i];
		my @rowOpts         = @$rowOptsRef;
		my $lastColIndex    = $#rowOpts;
		my $thisRowColCount = 0;
		for my $j (0 .. $lastColIndex) {
			$thisRowColCount += $rowOpts[$j]->{colspan};
		}
		$colCount = main::max($colCount, $thisRowColCount);
	}
	return $colCount;
}

sub TableOptions {
	my $colCount         = shift;
	my %supportedOptions = (
		center          => 1,
		caption         => '',
		horizontalrules => 0,
		texalignment    => join('', ('c') x $colCount),
		Xratio          => 0.97,
		encase          => [ '', '' ],
		rowheaders      => 0,
		tablecss        => '',
		captioncss      => '',
		columnscss      => [ ('') x $colCount ],
		datacss         => '',
		headercss       => '',
		allcellcss      => '',
		valign          => 'top',
		LaYoUt          => 0,
	);
	%outHash = %supportedOptions;
	my %userOptions = @_;
	for my $key (keys(%supportedOptions)) {
		$outHash{$key} = $userOptions{$key} if defined($userOptions{$key});
	}

	# special user shortcut
	$outHash{texalignment} = $userOptions{align}
		if (defined($userOptions{align}) && !$userOptions{texalignment});

	# legacy misnomers
	$outHash{horizontalrules} = $userOptions{midrules}
		if (defined($userOptions{midrules}) && !$outHash{horizontalrules});
	return \%outHash;
}

sub ParseAlignment {
	my $alignment = shift;
	$alignment =~ s/\R//g;

	# first we parse things like *{20}{...} to expand them
	my $pattern = qr/\*\{(\d+)\}\{(.*?)\}/;
	while ($alignment =~ /$pattern/) {
		my @captured    = ($alignment =~ /$pattern/);
		my $replaceWith = $captured[1] x $captured[0];
		$alignment =~ s/$pattern/$replaceWith/;
	}

	my @align = ();

	# 0th entry is only for possible left border
	# other entries have only right borders,
	# the actual alignment is r, c, l, X, or p
	# explicit width vertical rules from !{...}
	# latex directives from >{...}
	# we make an array of the tokens of type:
	# r, c, l, X, |, !{...}, p{...}, >{...}
	# this is complicated because of potential nested brackets
	my @tokens             = ();
	my $bracesregex        = qr/(\{(?>[^{}]|(?R))*\})/x;
	my $bracecontentsregex = qr/((?>[^{}]|(??{$bracesregex}))*)/x;

	# . at the end is to ensure we are whittling down $alignment at least a little
	my $tokenspattern = qr/^([rclX\|]\s*|[!p>]\s*\{((??{$bracecontentsregex}))\}\s*|.)/;

	$align[0] = { left => 0 };
	$leftpattern = qr/^\s*(\|\s*|!\s*\{\s*\\vrule\s+width\s+([^}]*?)\})/x;
	while ($alignment =~ $leftpattern) {
		my $token = $1;
		if ($token =~ /^\|/) {

			# this counts how many | we have
			$align[0]->{left} = 0
				unless ($align[$i]->{left} && $align[$i]->{left} =~ /\d+/);
			$align[0]->{left} += 1;
		} elsif ($token =~ /^!\s*\{\s*\\vrule\s+width\s+([^}]*?)\}/) {
			$align[0]->{left} = $1;
		}
		$alignment =~ s/$leftpattern//;
	}

	# now that leftmost vertical rule tokens taken care of, get all the other tokens
	while ($alignment) {
		my $token = ($alignment =~ /$tokenspattern/)[0];
		$alignment =~ s/$tokenspattern//;
		push(@tokens, $token);
	}

	# now run through tokens and grow @align
	# index for @align
	my $i = 1;

	# $j is index for @tokens
	for my $j (0 .. $#tokens) {
		my $token = $tokens[$j];
		my $next  = $tokens[ $j + 1 ] // '';
		if ($token =~ /^([lcrX])/) {
			$align[$i]->{halign} = $1;
			$align[$i]->{valign} = 'top' if ($1 eq 'X');
			$i++ unless ($next =~ /^[|!]/);
		} elsif ($token =~ /^\|/) {

			# this counts how many | we have
			$align[$i]->{right} = 0
				unless ($align[$i]->{right} && $align[$i]->{right} =~ /\d+/);
			$align[$i]->{right} += 1;
			$i++ unless ($next =~ /^[|!]/);
		} elsif ($token =~ /^!\s*\{\s*\\vrule\s+width\s+([^}]*?)\}/) {

			# for this style of vertical rule we store the width instead of a small positive integer
			$align[$i]->{right} = $1;
			$i++ unless ($next =~ /^[|!]/);
		} elsif ($token =~ /^p\{((??{$bracecontentsregex}))\}\s*/) {
			$align[$i]->{halign} = 'l';

			# record top alignment, but could be overwritten by row valign
			$align[$i]->{valign} = 'top';
			$align[$i]->{width}  = $1;
			$i++ unless ($next =~ /^[|!]/);
		} elsif ($token =~ /^>\s*\{((??{$bracecontentsregex}))\}/) {
			$align[$i]->{tex} = $1;

			# could parse these further for color identification, etc
		}
	}

	return \@align;

}

sub latexEnvironment {
	my ($inside, $environment, $options, $separator) = @_;
	$separator = "\n" unless ($separator);
	my $return = "\\begin{$environment}";
	for my $x (@$options) {
		$return .= "{$x}" if ($x ne '');
	}
	$return .= "$separator$inside$separator";
	$return .= "\\end{$environment}";
	return $return;
}

sub latexCommand {
	my ($command, $arguments) = @_;
	my $return = "\\$command";
	for my $x (@$arguments) {
		$return .= "{$x}" if ($x ne '');
	}
	$return .= " ";
	return $return;
}

sub wrap {
	my ($center, $left, $right, $separator) = @_;
	$separator = "\n" unless ($separator);
	return $center                   unless ($left || $right);
	return "$left$separator$center"  unless $right;
	return "$center$separator$right" unless $left;
	return "$left$separator$center$separator$right";
}

sub prefix {
	my ($center, $left, $separator) = @_;
	$separator = "\n" unless ($separator);
	return join("$separator", ($left, $center)) if ($left ne '');
	return $center;
}

sub suffix {
	my ($center, $right, $separator) = @_;
	$separator = "\n" unless ($separator);
	return join("$separator", ($center, $right)) if ($right ne '');
	return $center;
}

sub css {
	my ($property, $value) = @_;
	return ($value) ? "$property:$value;" : '';
}

sub tag {
	my ($inner, $name, $attributes, $separator) = @_;
	$separator = "\n" unless defined $separator;
	my $return = "<$name";
	for my $x (main::lex_sort(keys %$attributes)) {
		$return .= qq( $x="$attributes->{$x}") if ($attributes->{$x} ne '');
	}
	if ($inner) {
		$return .= ">$separator";
		$return .= $inner;
		$return .= "$separator</$name>";
	} else {
		$return .= '>' unless ($main::displayMode eq 'PTX');
		$return .= '/>' if ($main::displayMode eq 'PTX');
	}
	return $return;
}

sub getRuleCSS {
	my $input  = shift;
	my $output = '';
	if ($input =~ /^\s*(\.\d+|\d+\.?\d*)\s*$/) {
		$output = "solid $1px" if $1;
	} elsif ($input) {
		$output = "solid $input" if $input;
	}
	return $output;
}

sub getPTXthickness {
	my $input  = shift;
	my $output = '';
	if ($input == 1) {
		$output = "minor";
	} elsif ($input == 2) {
		$output = "medium";
	} elsif ($input >= 3) {
		$output = "major";
	} elsif ($input eq '0.04em') {
		$output = 'minor';
	} elsif ($input eq '0.07em') {
		$output = 'medium';
	} elsif ($input eq '0.11em') {
		$output = 'major';
	} elsif ($input) {
		$output = "minor";
	}
	return $output;
}

sub getWidthPercent {
	my $absWidth = shift;
	my $x        = 0;
	my $unit     = 'cm';
	if ($absWidth =~ /^(\.\d+|\d+\.?\d*)\s*(\w+)/) {
		$x    = $1;
		$unit = $2;
	}
	my %convert_to_cm = (
		'pt' => 1 / 864 * 249 / 250 * 12 * 2.54,
		'mm' => 1 / 10,
		'cm' => 1,
		'in' => 2.54,
		'ex' => 0.15132,
		'em' => 0.35146,
		'mu' => 0.35146 / 8,
		'sp' => 1 / 864 * 249 / 250 * 12 * 2.54 / 65536,
		'bp' => 2.54 / 72,
		'dd' => 1 / 864 * 249 / 250 * 12 * 2.54 * 1238 / 1157,
		'pc' => 1 / 864 * 249 / 250 * 12 * 2.54 * 12,
		'cc' => 1 / 864 * 249 / 250 * 12 * 2.54 * 1238 / 1157 * 12,
		'px' => 2.54 / 72,
	);
	return (int($x * $convert_to_cm{$unit} / (6.25 * 2.54) * 10000) / 100) . '%';
}

1;
