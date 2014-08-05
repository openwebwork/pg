######################################################################
##
##  Subroutines for creating tables that
##      * conform to accessibility standards
##      * allow a lot of CSS flexibility for on-screen styling
##      * allow some LaTeX flexibility for hard copy styling
##        (hard copy data tables will always have a top rule, bottom rule, and midrule after any header row)  
##
##  DataTable()             Creates a table with data. 
##                                   Should not be used for layout, such as displaying an array of graphs.
##                                   Should usually make use of a caption and column or row headers.
##
##  LayoutTable()           Creates a "table" using div boxes for layout
##

sub _pccTables_init {}; # don't reload this file

=head2 pccTables.pl

 ######################################################################
 #
 #  Command for tables displaying data. In a data table the xy-position of a cell is somehow 
 #    important along with the information inside the cell.
 #
 #  Usage:  DataTable([[a,b,c,...],[d,e,f,...],[g,h,i,...],...], options);
 #
 #  [[a,b,c,...],[d,e,f,...],[g,h,i,...],...] is the table content, row by row
 #
 #  Options for the WHOLE TABLE
 #    Most options are set separately for the on-screen version and the hardcopy version
 #      Applies to on-screen and hard copy:
 #        center => 0 or 1              # center table
 #        caption => string             # a caption for the table
 #        midrules => 0 or 1            # if you want midrules after every row in the hard copy (excludes the last row)
 #
 #      Applies to on-screen:
 #        tablecss => string            # css styling commands for the table element (see below for css syntax)
 #        captioncss => string          # css styling commands for the caption element (see below for css syntax)
 #        columnscss => array ref       # an array reference to css styling commands (strings) for columns
 #                                      #   use empty strings for columns for which you have no style specifications 
 #                                      #   Ex: columnscss => ['','background-color:yellow;','','background-color:yellow;']
 #        datacss => string             # css styling commands for all the td elements (see below for css syntax)
 #        headercss => string           # css styling commands for the th elements (see below for css syntax)
 #        allcellcss => string          # css styling commands for all the cells (see below for css syntax)
 #
 #      Applies to hardcopy:
 #        texalignment => string        # for example 'rccl' would be for a four-column table; defaults to all c's;
 #                                      # r is for right-alignment
 #                                      # c for center
 #                                      # l for left
 #                                      # p{width} is for a fixed-width paragraph column
 #        Xratio => number              # if X is used in column alignment then the LaTeX tabular environment will be replaced with tabularx using
 #          (default 0.97)              #   table width that is Xratio of the entire line width and the X columns will be paragraph columns of whatever
 #                                      #   width is necessary to fill up the horizontal space.
 #                                      # You can also use column coloring commands from the colortbl package. A simple example:
 #                                      # 'r>{\columncolor{blue!50}}ccl'
 #                                      # would make background for the second column 50% blue
 #
 #  MODIFYING CELLS
 #    Each cell entry (like "a" in [[a,b,c,...],...])) can be replaced with a hash reference (encased in curly braces) for more detailed 
 #    customization of that cell. On-screen and hardcopy customization is separate.  
 #      {data => a, 
 #
 #      Applies to on-screen:
 #        header => type,               # Could be 'TH' (table header), 'CH', 'col', or 'column' (col header), 'RH', or 'row' (row header), or none of the above
 #                                      # Can also be 'TD' to overrule a row of all headers (see modifying rows)
 #                                      # If your table only has column headers (no row headers) it is probably best to make an entire row of headers 
 #                                      # (see modifying a row) and to not use header=> directly. But if your table has both column and row headers
 #                                      # then use header=> for all the headers and don't use the row modification (because in that situation you 
 #                                      # probably don't want a THEAD tag).
 #        cellcss => string,            # String with cell-specific CSS styling; see below for CSS syntax
 #
 #      Applies to hard copy:
 #        tex => tex code               # For tex commands whose scope will be entire cell, e.g. \bfseries or \itshape
 #                                      # For cell coloring: like \cellcolor{blue!50} for the background or \color{blue!50} for the text 
 #        texpre => tex code,           # For more fussy cell-by-cell alteration of the tex version of the table
 #                                      # TeX code here will precede the cell entry...
 #        texpost => tex code}          # and code here will follow the cell entry
 #                                      # The texpre/texpost code overrules the tex code
 #
 #
 #  MODIFYING ROWS  
 #   A rowcss key can be used anywhere in the row. Only the last instance in that row will be applied.
 #      [[{rowcss => extra css for the row, data=>a},b,c,...],[d,e,f,...],[g,h,i,...],...]
 #
 #   You can make an entire row be made of CH (column header) elements without specifying it for each header:
 #      [[{headerrow=>1, data=>a},b,c,...],[d,e,f,...],[g,h,i,...],...]
 #   This also encases the row in a <THEAD> tag. This should only be applied to the first row. In the hard copy,
 #      a row like this will be followed by a midrule.
 #
 #   In the hard copies, you can modify a row with background color using arguments from colortbl's rowcolor command:
 #      [[{rowcolor => '{blue!50}', data=>a},b,c,...],[d,e,f,...],[g,h,i,...],...]  
 #      [[{rowcolor => '[gray]{0.8}', data=>a},b,c,...],[d,e,f,...],[g,h,i,...],...] 
 #
 #   And you can follow the row with a horizontal rule:
 #      [[{midrule => 1, data=>a},b,c,...],[d,e,f,...],[g,h,i,...],...] 
 #      (but this is already done once for headerrows)
 #
 #  CSS SYNTAX PRIMER
 #        css styling commands offer a huge variety for styling the table on screen 
 #        Basic elements are of the form "A:B;" like "border:1pt;" and "width:80%;"
 #          DON'T FORGET THE SEMICOLONS. SINCE THESE COMMANDS AGGREGATE, THEY ARE IMPORTANT.
 #        Also, they can be of the form "A:B C;" like "border:1pt dashed;"
 #        Multiple commands can be used with the form "A1:B;A2:C;" like "border:1pt; margin:5pt;"
 #        Some properties with example values and which elements they can affect:
 #            border:2px solid blue;                      table, caption, th, td
 #            border-collapse:collapse;  (or separate)    table
 #            border-radius: 5px;                         table, caption, tr, th, td
 #            width:50%;                                  table, caption, th, td
 #            height:20ex;                                table, caption, tr, th, td
 #            text-align:center;                          table, caption, tr, th, td
 #            vertical-align:top;                         table, caption, tr, th, td
 #            padding:12pt;                               table, caption, th, td
 #            margin:20px;                                table, caption
 #            border-spacing:12pt;                        table
 #            caption-side:bottom;                        table, caption
 #            color:blue;                                 table, caption, tr, th, td
 #            background-color:yellow;                    table, caption, tr, th, td
 #        The properties border, padding, and margin
 #            can be specified in more detail using -left, -bottom, -right, -top as in "border-bottom:5px"
 #
 #  Example: DataTable([[{data=>1, header => 'CH', cellcss => 'color:blue;'},2,3],
 #                      [4,5,{rowcss => 'background-color:yellow;', data => 6}]], tablecss => "border:1pt");\}

=cut

sub DataTable {
  my $dataref = shift;

  # this array will store the number of cells in each row
  my @numcols = ();

  # if any cells were simply entered as their data value, convert to a hash
  for my $i (0..$#{$dataref})
    {$numcols[$i] = $#{$dataref->[$i]};
    for my $j (0..$numcols[$i])
      {$dataref->[$i][$j] = {data => $dataref->[$i][$j]} unless (ref($dataref->[$i][$j]) eq "HASH" );
      };
    };

  # total number of columns
  my $numcol = max(@numcols)+1;

  # define options
  my %options = (
    center => 1, caption => '', tablecss => '', captioncss => '', datacss => '',
    headercss => '', allcellcss => '', texalignment => '', midrules => 0, columnscss => [('') x $numcol],
    Xratio => '0.97',
    @_
  );
  my $caption = $options{caption};
  my ($tablecss, $captioncss, $datacss, $headercss, $allcellcss, $texalignment, $midrules, $columnscss, $Xratio) = 
    ($options{tablecss}, $options{captioncss}, $options{datacss}, $options{headercss}, $options{allcellcss},
     $options{texalignment},$options{midrules},$options{columnscss},$options{Xratio});
  my $center = $options{center};
    if ($center !=0) {$tablecss .= 'text-align:center;margin:0 auto;'};


  # for each row, store rowcss, rowcolor, midrule, headerrow
  my @rowcss = ();
  my @rowcolor = ();
  my @midrule = (); 
  my @headerrow = ();
  for my $i (0..$#{$dataref})
    {$rowcss[$i] = '';
     $rowcolor[$i] = '';
     $midrule[$i] = 0;
     $headerrow[$i] = 0;
    for my $j (0..$numcols[$i])
      {$rowcss[$i] = ${$dataref->[$i][$j]}{rowcss} if (defined ${$dataref->[$i][$j]}{rowcss} );
       $rowcolor[$i] = ${$dataref->[$i][$j]}{rowcolor} if (defined ${$dataref->[$i][$j]}{rowcolor} );
       $midrule[$i] = ${$dataref->[$i][$j]}{midrule} if (defined ${$dataref->[$i][$j]}{midrule} ); 
       $headerrow[$i] = ${$dataref->[$i][$j]}{headerrow} if (defined ${$dataref->[$i][$j]}{headerrow} );
      };
    };

  # parse tex alignment for duplicate use in html
  my @htmlalignment = split(/([rclX](?:>\{.*?\})?|p\{.*?\})/,$texalignment);

  my $midrulescss = '';
  if $midrules {$midrulescss = "border-top:solid 1px;"};

  # build html string for the table
  my $table = @htmlalignmnet.'<TABLE style = "'.$tablecss.'">';
  if ($caption ne '') {$table .= '<CAPTION style = "'.$captioncss.'">'.$caption.'</CAPTION>';}
  $table .= '<colgroup>';
  for my $i (0..$#{$columnscss})
    {$table .= '<col style = "'.$columnscss->[$i].'">';};
  $table .= '</colgroup>';
  my $bodystarted = 0;
  for my $i (0..$#{$dataref})
    {if ($i == $#{$dataref}) {$midrulescss .= "border-bottom:solid 1px;";}
     if ($headerrow[$i] == 1) {$table .= '<THEAD>'; } 
     elsif (!$bodystarted) {$table .= '<TBODY>'; $bodystarted = 1};
    $table .= '<TR>';
    for my $j (0..$numcols[$i])
      {if (uc(${$dataref->[$i][$j]}{header}) eq 'TH')
        {$table .= '<TH style = "'.$allcellcss.$headercss.$columnscss->[$j].$midrulescss.$rowcss[$i].${$dataref->[$i][$j]}{cellcss}.'">'.${$dataref->[$i][$j]}{data}.'</TH>';}
        elsif (uc(${$dataref->[$i][$j]}{header}) ~~ ['CH','COLUMN','COL']) 
        {$table .= '<TH scope = "col" style = "'.$allcellcss.$headercss.$columnscss->[$j].$midrulescss.$rowcss[$i].${$dataref->[$i][$j]}{cellcss}.'">'.${$dataref->[$i][$j]}{data}.'</TH>';}
        elsif (uc(${$dataref->[$i][$j]}{header}) ~~ ['RH','ROW']) 
        {$table .= '<TH scope = "row" style = "'.$allcellcss.$headercss.$columnscss->[$j].$midrulescss.$rowcss[$i].${$dataref->[$i][$j]}{cellcss}.'">'.${$dataref->[$i][$j]}{data}.'</TH>';}
        elsif (uc(${$dataref->[$i][$j]}{header}) eq 'TD')
        {$table .= '<TD style = "'.$allcellcss.$datacss.$columnscss->[$j].$midrulescss.$rowcss[$i].${$dataref->[$i][$j]}{cellcss}.'">'.${$dataref->[$i][$j]}{data}.'</TD>';}
        elsif (uc($headerrow[$i]) == 1)
        {$table .= '<TH scope = "col" style = "'.$allcellcss.$headercss.$columnscss->[$j].$rowcss[$i].${$dataref->[$i][$j]}{cellcss}.'">'.${$dataref->[$i][$j]}{data}.'</TH>';}
        else {$table .= '<TD style = "'.$allcellcss.$datacss.$columnscss->[$j].$midrulescss.$rowcss[$i].${$dataref->[$i][$j]}{cellcss}.'">'.${$dataref->[$i][$j]}{data}.'</TD>';}
      }
    $table .= "</TR>";
    if ($headerrow[$i] == 1) {$table .= '</THEAD>';} 
      elsif ($bodystarted and ($i == $#{$dataref})) {$table .= '</TBODY>';};
    };
    $table .= "</TABLE>";

   # build tex string for the table 
    $texalignment = join('', ('c') x $numcol) if ($texalignment eq '');
    my ($begintabular,$endtabular) = ('\begin{tabular}','\end{tabular}');
    if ($texalignment =~ /X/) {($begintabular,$endtabular) = ('\begin{tabularx}{'.$Xratio.'\linewidth}','\end{tabularx}');};

    my $textable = '\par\begin{minipage}{\linewidth}';
    if ($center == 1) {$textable .= '\centering';};
    if ($caption ne '') {$textable .= '\captionsetup{textfont={sc},belowskip=12pt,aboveskip=4pt}\captionof*{table}{'.$caption.'}';};
    $textable .= $begintabular.'{'.$texalignment.'}'.'\toprule';
    for my $i (0..$#{$dataref})
      {
       if ($rowcolor[$i] ne '') {$textable .= '\rowcolor'.$rowcolor[$i];};
       for my $j (0..$numcols[$i])
        {if ($headerrow[$i] == 1) {$textable .= '\bfseries '};
        $textable .= ${$dataref->[$i][$j]}{texpre}.' '.${$dataref->[$i][$j]}{tex}.' '.${$dataref->[$i][$j]}{data}.' '.${$dataref->[$i][$j]}{texpost};
        $textable .= '&' unless ($j == $numcols[$i]);
        };
      $textable .= '\\\\';
      if ($midrule[$i] == 1) {$textable .= '\midrule '};
      if ((($midrules == 1) or ($headerrow[$i] == 1)) and (($i != $#{$dataref}) or ($footerline ne ''))) {$textable .= '\midrule '};     
      };
    $textable .= '\bottomrule'.$endtabular;
    $textable .= '\end{minipage}\par  \vspace{1pc}';

  MODES(
    TeX => $textable,
    HTML => $table,
  );
}

=pod

 #
 #  Command for table to control layout
 #
 #  Usage:  LayoutTable(...)  
 #    See usage for DataTable. The HTML output will use section and div boxes instead of HTML tabling elements
 #    Anything having to do with headers, captions, and data cells no longer make sense (although 'data' is still
 #    used as the key for cell contents). Since all cells are the same type now, you can use the allcellcss key.
 #


=cut

sub LayoutTable {
  my $dataref = shift;

  # this array will store the number of cells in each row
  my @numcols = ();

  # if any cells were simply entered as their data value, convert to a hash
  for my $i (0..$#{$dataref})
    {$numcols[$i] = $#{$dataref->[$i]};
    for my $j (0..$numcols[$i])
      {$dataref->[$i][$j] = {data => $dataref->[$i][$j]} unless (ref($dataref->[$i][$j]) eq "HASH" );
      };
    };

  # total number of columns
  my $numcol = max(@numcols)+1;

  # define options
  my %options = (
    center => 1, tablecss => '',
     allcellcss => '', texalignment => '', midrules => 0, columnscss => [('') x $numcol],
    @_
  );
  my ($tablecss, $allcellcss, $texalignment, $midrules, $columnscss) =
    ($options{tablecss}, $options{allcellcss}, $options{texalignment}, $options{midrules}, $options{columnscss});
  my $center = $options{center};
    if ($center !=0) {$tablecss .= 'text-align:center;margin:0 auto;'};

  # for each row, store rowcss, rowcolor, midrule
  my @rowcss = ();
  my @rowcolor = ();
  my @midrule = ();
  for my $i (0..$#{$dataref})
    {$rowcss[$i] = '';
     $rowcolor[$i] = '';
     $midrule[$i] = 0;
    for my $j (0..$numcols[$i])
      {$rowcss[$i] = ${$dataref->[$i][$j]}{rowcss} if (defined ${$dataref->[$i][$j]}{rowcss} );
       $rowcolor[$i] = ${$dataref->[$i][$j]}{rowcolor} if (defined ${$dataref->[$i][$j]}{rowcolor} );
       $midrule[$i] = ${$dataref->[$i][$j]}{midrule} if (defined ${$dataref->[$i][$j]}{midrule} );
      };
    };

  # build html string for the table
  my $table =
    '<SECTION style = "display:table;'.$tablecss.'">';
  for my $i (0..$#{$dataref})
    {$table .= '<DIV style = "display:table-row;">';
    for my $j (0..$numcols[$i])
      {$table .= '<DIV style = "display:table-cell;'.$allcellcss.$columnscss->[$j].$rowcss[$i].${$dataref->[$i][$j]}{cellcss}.'">'.${$dataref->[$i][$j]}{data}.'</DIV>';}
    $table .= "</DIV>";
    };
    $table .= "</SECTION>";

   # build tex string for the table  
    $texalignment = join('', ('c') x $numcol) if ($texalignment eq '');
    my ($begintabular,$endtabular) = ('\begin{tabular}','\end{tabular}');
    if ($texalignment =~ /X/) {($begintabular,$endtabular) = ('\begin{tabularx}{0.97\linewidth}','\end{tabularx}');};

    my $textable = ($center == 1) ? '\begin{center}' : '\begin{flushleft}';
    $textable .= $begintabular.'{'.$texalignment.'}'.'\toprule';
    for my $i (0..$#{$dataref})
      {if ($rowcolor[$i] ne '') {$textable .= '\rowcolor'.$rowcolor[$i];};
       for my $j (0..$numcols[$i])
        {$textable .= ${$dataref->[$i][$j]}{texpre}.' '.${$dataref->[$i][$j]}{tex}.' '.${$dataref->[$i][$j]}{data}.' '.${$dataref->[$i][$j]}{texpost};
        $textable .= '&' unless ($j == $numcols[$i]);
        };
      $textable .= '\\\\';
      if ($midrule[$i] == 1) {$textable .= '\midrule '};
      if (($midrules == 1) and ($i != $#{$dataref})) {$textable .= '\midrule '};
      };
    $textable .= '\bottomrule'.$endtabular;
    if ($center ==1) {$textable .= '\end{center}'} else {$textable .= '\end{flushleft}'};


  MODES(
    TeX => $textable,
    HTML => $table,
  );
}

1;
