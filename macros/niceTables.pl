######################################################################
#
##  Subroutines for creating tables that
##      * conform to accessibility standards
##      * allow a lot of CSS flexibility for on-screen styling
##      * allow some LaTeX flexibility for hard copy styling
##
##  Hard copy data tables will always have a top rule, bottom rule, and midrule after any header row
##
##  DataTable()             Creates a table with data.
##                                   Should not be used for layout, such as displaying an array of graphs.
##                                   Should usually make use of a caption and column and/or row headers.
##
##  LayoutTable()           Creates a "table" using div boxes for layout
##
##  NOTE: In order to reduce separate setting of on-screen and hard copy settings as much as possible, Perl 5.10+
##  tools are used. These macros may behave unexpectedly or not work at all with older versions of Perl.
##  These macros use LaTeX packages inthe hard copy that wer not formerly part of a WeBWorK hard copy preamble.
##  Your LaTeX distribution needs to have the packages: booktabs, tabularx, colortbl, caption, xcolor
##  And if you have a WeBWorK version earlier than 2.10, you need to add calls to these packages to hardcopyPreamble.tex
##    in webwork2/conf/snippets/

sub _niceTables_init {}; # don't reload this file

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
 #  As much as possible, options can be declared to simultaneously apply to both on-screen and hard copy.
 #  Generally, you give settings for the hard copy tex version first. Many common such settings are automatically
 #  translated into CSS styling for the on-screen. You can then override or augment the CSS for the on-screen version.
 #
 #  Options for the WHOLE TABLE
 #
 #      Applies to on-screen *and* hard copy:
 #        center => 0 or 1              # center table
 #        caption => string             # a caption for the table
 #        midrules => 0 or 1            # if you want rules above and below every row
 #                                      #   (hard copies will always have toprule and bottomrule)
 #        align => string               # an alignment string like the kinds used in LaTeX tabular environments;
 #                                      # some of what you specify here will apply to both on-screen and hard copy
 #          (texalignment => string     #  -what won't is specified further below
 #           is really what it is,      # for example 'rccp{1in}' would be for a four-column table with a
 #           but align is a shortcut)   #   right-aligned column, two centered columns,
 #                                      #   and a paragraph column of fixed width 1in; defaults to all c's;
 #                                      # r is for right-alignment; on-screen will have no wrap
 #                                      # c for center; on-screen will have no wrap
 #                                      # l for left; on-screen will have no wrap
 #                                      # p{width} is for a fixed-width paragraph column
 #                                      #   -width should be a valid tex width; if it is also a valid css width,
 #                                      #   -it will be used on-screen too; otherwise, on-screen will have unspecified width
 #        Xratio => 0.97                # X ...if X is used in column alignment then the hard copy will have a width that
 #                                      #   is Xratio times the \linewidth, and X columns will be paragraph columns that
 #                                      #   grow to be whatever width fills the overall table width. For on-screen, X is
 #                                      #   a normal breaking-paragraph column that will expand to screen width before
 #                                      #   a break happens
 #                                      # | as with array environments in LaTeX, you may use | for vertical rules.
 #                                      # Preceding one of the above alignment types, you may use >{...} where the ... is
 #                                      #   more LaTeX commands to be applied everywhere in the column. For the simple text
 #                                      #   syling commands: \bfseries for bold, \itshape for italic, or \ttfamily for
 #                                      #   teletype (monospaced font), the on-screen version will be applied too.
 #                                      #  *You may include \color{...} here too, where ... is a coloring mixture from the
 #                                      #   xcolor package. 'blue' is an example of the simplest coloring mixture. For a much
 #                                      #   more complicated example: rgb:blue!30!green,1;-red!10!green,2 would give 1 part
 #                                      #   a 30%blue-70%green mixture, mixed with 2 parts the complement of a
 #                                      #   10%red-90%green mixture.
 #                                      #     -only mixtures like \color{blue...} will be respected on-screen, and in that
 #                                      #     -case the first color will named be used. Use columnscss (discussed below) if
 #                                      #     -want to be more picky with the on-screen version.
 #                                      #  *You may include \columncolor{...} to color the background of cells, where ...
 #                                      #   follows the same rules as for \color{...}
 #                                      #  NOTE: Any color commands (\color, \columncolor, \rowcolor, \cellcolor) can take the
 #                                      #    option [HTML] and then an HTML hexadecimal color can be declared. For example,
 #                                      #    \color[HTML]{FF0000} for red. It works for on-screen and hard copy. Color
 #                                      #    specified this way should be the same on-screen and in the hard copy, whereas
 #                                      #    color specified the other way often differs.
 #                                      #   Any more complicated tex commands will be ignored for on-screen (or cause errors
 #                                      #     or not behave as expected).
 #        encase => array ref           # You may want to encase all table entries in, say, \( and \) to save from typing
 #                                      #   them many times. To do that, use encase => ['\(','\)']. For individual cells
 #                                      #   you may set noencase=>1 to omit this (see section on modifying cells).
 #        rowheaders => 1               # Make the first element of every row a row header.
 #
 #      Applies to on-screen:
 #        tablecss => string            # css styling commands for the table element (see below for css syntax)
 #        captioncss => string          # css styling commands for the caption element (see below for css syntax)
 #        columnscss => array ref       # an array reference to css styling commands (strings) for columns
 #                                      #   use empty strings for columns for which you have no style specifications
 #                                      #   Ex: columnscss => ['','background-color:yellow;','','background-color:yellow;']
 #                                      #   -specifications made here overrule specifications from texalignment
 #        datacss => string             # css styling commands for all the td elements (see below for css syntax)
 #        headercss => string           # css styling commands for the th elements (see below for css syntax)
 #        allcellcss => string          # css styling commands for all the cells (see below for css syntax)
 #
 #
 #  MODIFYING CELLS
 #    Each cell entry (like "a" in [[a,b,c,...],...])) can be replaced with an array reference (encased in square brackets) for
 #    more detailed customization of that cell. For example, [[[a,header=>'CH'],b,c],[d,e,f]] gives a table where the a is
 #    a column header cell. The data content of the cell must be the first element listed, and what follows must be key=>value pairs.
 #    These options may be applied.
 #
 #      Applies to both on-screen and hard copy:
 #        halign => string              # same format as align at the table level (discussed above) but for one cell only
 #        header => type,               # Could be 'TH' (table header), 'CH', 'col', or 'column' (col header), 'RH', or 'row'
 #                                      #   (row header). If so, default CSS styling is used, and hard copy cell is bold.
 #                                      # Can also be 'TD' to overrule a row of all headers (see modifying rows)
 #                                      # If your table only has column headers (no row headers) it is probably best to make
 #                                      #   an entire row of headers (see modifying a row) and to not use header=> directly.
 #                                      #   But if your table has both column and row headers then use header=> for all the
 #                                      #   headers (both row- and column-) and don't use the row modification (because in
 #                                      #   that situation you probably don't want a THEAD tag).
 #        tex => tex code               # For tex commands whose scope will be entire cell, e.g. \bfseries or \itshape;
 #                                      #   \bfseries (for bold), \itshape (for italic), and \ttfamily (for monospace) will
 #                                      #   lead to CSS equivalents for the on-screen version
 #                                      # For cell coloring: like \cellcolor{blue} for the background or \color{blue} for the
 #                                      #   text, use color mixtures as described in texalignment=>, and simple colors will
 #                                      #   apply to the on-screen version too.
 #                                      # -all other tex code will be ignored for the on-screen version, so use cellcss=>
 #                                      #  below
 #        b=>1, i=>1, m=>1              # These are shortcuts for adding \bfseries, \itshape, and \ttfamily to tex, which will
 #                                      #   in turn affect he on-screen too.
 #        noencase => 1                 # If you have global encase strings (see section on modifying the whole table) then
 #                                      #   you can opt to not apply them on a cell by cell basis
 #        colspan => pos integer        # for cells that span more than one column; when using this, you must set halign for
 #                                      #   the cell too, or else the tex output will just use {c} alignment; this feature may
 #                                      #   not behave as expected for certain structures, like a two-row table, with 3 columns,
 #                                      #   but the first row has colspans 2 and 1 with the second row having colspans 1 and 2
 #                                      # **colspan is supported for DataTable only, not LayoutTable. LayoutTable uses css
 #                                      #   like display:table-cell; to achieve its output, and there is no counterpart to
 #                                      #   colspan using this approach (at least not currently)
 #
 #      Applies to on-screen:
 #        cellcss => string,            # String with cell-specific CSS styling; see below for CSS syntax
 #
 #      Applies to hard copy:
 #        texpre => tex code,           # For more fussy cell-by-cell alteration of the tex version of the table
 #                                      # TeX code here will precede the cell entry...
 #        texpost => tex code           # and code here will follow the cell entry
 #                                      # The ordering will be: tex texpre data texpost
 #        texencase => array ref        # This is just a shortcut for entering [texpre,texpost] at once.
 #
 #    The "a" in a cell can also be replaced directly with a hash reference {data=>a,options} if somehow that is of use. If you
 #    modify the cell using an array reference [a, options] instead, it is automatically converted to a hash reference anyway.
 #
 #
 #  MODIFYING ROWS
 #   You can give a row background color using arguments from colortbl's \rowcolor command:
 #      [[[a, rowcolor => '{blue!50}'],b,c,...],[d,e,f,...],[g,h,i,...],...]
 #      [[[a, rowcolor => '[HTML]{FF0000}'],b,c,...],[d,e,f,...],[g,h,i,...],...]
 #   For the on-screen version, if the first style of argument is used, only the first color mentioned will be used.
 #
 #   A rowcss key can be used anywhere in the row. Only the last instance in that row will be applied.
 #      [[[a, rowcss => extra css for the row],b,c,...],[d,e,f,...],[g,h,i,...],...]
 #
 #   You can make an entire row be made of CH (column header) elements without specifying it for each header:
 #      [[[a, headerrow=>1],b,c,...],[d,e,f,...],[g,h,i,...],...]
 #   This also encases the row in a <THEAD> tag. This should only be applied to the first row. In the hard copy,
 #      a row like this will have bold entries and be followed by a midrule.
 #
 #   And you can follow a row with a horizontal rule:
 #      [[[a, midrule => 1],b,c,...],[d,e,f,...],[g,h,i,...],...]
 #      (but this is already done once for headerrows in the hard copy, since they don't rely on surrounding CSS to stand out)
 #
 #  CSS SYNTAX PRIMER
 #        css styling commands offer a huge variety for styling the table on screen
 #        Basic elements are of the form "A:B;" like "border:1pt;" and "width:80%;"
 #        ****DON'T FORGET THE SEMICOLONS. SINCE THESE COMMANDS ACCUMULATE, SEMICOLONS ARE IMPORTANT.
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
 #            font-weight:bold;                           table, caption, tr, th, td
 #            font-style:italic;                          table, caption, tr, th, td
 #            font-family:monospace;                      table, caption, tr, th, td
 #        The properties border, padding, and margin
 #            can be specified in more detail using -left, -bottom, -right, -top as in "border-bottom:5px"
 #
 #  Example: DataTable([[[1, header => 'CH', cellcss => 'font-family:fantasy;'],2,3],
 #                      [4,5,[6, rowcss => 'padding-top:10pt; padding-bottom:10pt; ']]],
 #                       tablecss => "border:solid 1px; border-spacing:5px; border-radius: 5px; border-collapse:separate;");
 #
=cut

sub DataTable {
  my $dataref = shift;

  # this array will store the number of cells in each row
  my @numcols = ();

  # if any cells were simply entered as their data value or an array ref, convert to a hash
  for my $i (0..$#{$dataref})
    {$numcols[$i] = $#{$dataref->[$i]};
    for my $j (0..$numcols[$i])
      {# if cell was simply entered as data value, make the hash
        $dataref->[$i][$j] = {data => $dataref->[$i][$j]} unless (ref($dataref->[$i][$j]) eq "HASH" or ref($dataref->[$i][$j]) eq "ARRAY" );
        # and if it was entered as an array reference, make the hash
        if (ref($dataref->[$i][$j]) eq "ARRAY" )
          {my $temp = $dataref->[$i][$j]; $dataref->[$i][$j] = {data, @$temp};};
        #before [a, options] was an option, {d=>a,options} was a shortcut for {data=>a,options}
        ${$dataref->[$i][$j]}{data} = ${$dataref->[$i][$j]}{d} if (defined ${$dataref->[$i][$j]}{d});
        # set default values for cell
        ${$dataref->[$i][$j]}{header} = '' unless (defined ${$dataref->[$i][$j]}{header});
        ${$dataref->[$i][$j]}{tex} = '' unless (defined ${$dataref->[$i][$j]}{tex});
        ${$dataref->[$i][$j]}{b} = 0 unless (defined ${$dataref->[$i][$j]}{b});
        ${$dataref->[$i][$j]}{i} = 0 unless (defined ${$dataref->[$i][$j]}{i});
        ${$dataref->[$i][$j]}{m} = 0 unless (defined ${$dataref->[$i][$j]}{m});
        ${$dataref->[$i][$j]}{noencase} = 0 unless (defined ${$dataref->[$i][$j]}{noencase});
        ${$dataref->[$i][$j]}{halign} = '' unless (defined ${$dataref->[$i][$j]}{halign});
        ${$dataref->[$i][$j]}{colspan} = '' unless (defined ${$dataref->[$i][$j]}{colspan});
        ${$dataref->[$i][$j]}{cellcss} = '' unless (defined ${$dataref->[$i][$j]}{cellcss});
        ${$dataref->[$i][$j]}{rowcss} = '' unless (defined ${$dataref->[$i][$j]}{rowcss});
        ${$dataref->[$i][$j]}{rowcolor} = '' unless (defined ${$dataref->[$i][$j]}{rowcolor});
        ${$dataref->[$i][$j]}{midrule} = 0 unless (defined ${$dataref->[$i][$j]}{midrule});
        ${$dataref->[$i][$j]}{headerrow} = 0 unless (defined ${$dataref->[$i][$j]}{headerrow});
        ${$dataref->[$i][$j]}{texencase} = ['',''] unless (defined ${$dataref->[$i][$j]}{texencase});
        ${$dataref->[$i][$j]}{texpre} = ${$dataref->[$i][$j]}{texencase}->[0] unless (defined ${$dataref->[$i][$j]}{texpre});
        ${$dataref->[$i][$j]}{texpost} = ${$dataref->[$i][$j]}{texencase}->[1] unless (defined ${$dataref->[$i][$j]}{texpost});
      };
    };

  # total number of columns
  my $numcol = max(@numcols)+1;


  # define options
  my %options = (
    center => 1, caption => '', tablecss => '', captioncss => '', datacss => '',
    headercss => '', allcellcss => '', texalignment => join('', ('c') x $numcol), rowheaders => 0,
    midrules => 0, columnscss => [('') x $numcol], Xratio => 0.97, encase=>['',''], LaYoUt => 0,
    @_
  );
  if ($options{LaYoUt} != 1)
    {$options{allcellcss} = 'padding-left:6pt; padding-right:6pt; '.$options{allcellcss}}
    else {$options{allcellcss} = 'padding:12pt; '.$options{allcellcss}};
  $options{captioncss} = 'padding:6pt; '.$options{captioncss};
  $options{tablecss} = 'border-collapse:collapse; '.$options{tablecss};

  my $caption = $options{caption};
  my ($tablecss, $captioncss, $datacss, $headercss, $allcellcss, $texalignment, $midrules, $columnscss, $Xratio, $encase) =
    ($options{tablecss}, $options{captioncss}, $options{datacss}, $options{headercss}, $options{allcellcss},
     $options{texalignment},$options{midrules},$options{columnscss},$options{Xratio}, $options{encase});
  my $center = $options{center};
    if ($center !=0) {$tablecss .= 'text-align:center; margin:0 auto; '};

  # shortcuts introduced late
  if (defined $options{align}) {$texalignment = $options{align}};
  if ($options{rowheaders} == 1)  {for my $i (0..$#{$dataref}) {${$dataref->[$i][0]}{header} = 'RH' if (uc(${$dataref->[$i][0]}{header}) eq '') }};


  # apply contents of encase; cell shortcuts
  for my $i (0..$#{$dataref})
    {for my $j (0..$numcols[$i])
      {
        ${$dataref->[$i][$j]}{data} = $encase->[0].${$dataref->[$i][$j]}{data}.$encase->[1] unless (${$dataref->[$i][$j]}{noencase} == 1);
        if (${$dataref->[$i][$j]}{b} == 1) {${$dataref->[$i][$j]}{tex} .= '\bfseries ';};
        if (${$dataref->[$i][$j]}{i} == 1) {${$dataref->[$i][$j]}{tex} .= '\itshape ';};
        if (${$dataref->[$i][$j]}{m} == 1) {${$dataref->[$i][$j]}{tex} .= '\ttfamily ';};
      };
    };

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
      {$rowcss[$i] = ${$dataref->[$i][$j]}{rowcss} if ($rowcss[$i] eq '');
       $rowcolor[$i] = ${$dataref->[$i][$j]}{rowcolor} if ($rowcolor[$i] eq '');
       $midrule[$i] = ${$dataref->[$i][$j]}{midrule} if ($midrule[$i] == 0);
       $headerrow[$i] = ${$dataref->[$i][$j]}{headerrow} if ($headerrow[$i] == 0);
      };
    if ($rowcolor[$i] =~ /\{\s*(\w*)[}!]/)
      {
        $rowcss[$i] = 'background-color:'.$1.'; '.$rowcss[$i];
      };
    if ($rowcolor[$i] =~ /\[\s*HTML\s*\]\s*\{\s*(\w*)[}!]/)
      {
        $rowcss[$i] = 'background-color:#'.$1.'; '.$rowcss[$i];
      };
    };


  # parse tex alignment for duplicate use in html
  my $bracesregex = qr/(\{(?>[^{}]|(?R))*\})/x;
    # grabs outer level braces and their contents, including inner brace pairs
  my $bracecontentsregex = qr/((?>[^{}]|(??{$bracesregex}))*)/x;
    # grabs contents of an outer level brace pair, including inner brace pairs
  my @htmlalignment = split(/(>\s*(??{$bracesregex})\s*|\|\s*|p\s*(??{$bracesregex})\s*|[rclX]\s*)/,$texalignment);
  my @temp = ();
  foreach(@htmlalignment){
    if( ( defined $_) and ($_ ne '')){
        push(@temp, $_);
    }
  };
  @htmlalignment = @temp;
    # @htmlalignment is now an array, where the entries are the parsed pieces of $texalignment; entries parsed by
    # >{commands}, pipes (for vertical rules), p{width}, r, c, l, or X

  my @columnalignments = grep { $htmlalignment[$_] =~ /^p\s*(??{$bracesregex})\s*|^[rclX]\s*/ } 0 .. $#htmlalignment;
    # @columnalignments is an array, where the entries are the indices form @htmlalignment that actually deal with
    # alignment: p{width}, r, c, l, or X
  my @alignmentcolumns;
    for my $i (0..$#columnalignments) {$alignmentcolumns[$columnalignments[$i]] = $i};
    # @alignmentcolumns is an array with one element per column, where the elements are each one of p{width}, r, c, l, or X

  # append css to author's columnscss->[$i] that corresponds to the alignemnts in @alignmentcolumns
  for my $i (0..$#columnalignments) {
  $columnscss->[$i] = TeX_Alignment_to_CSS($htmlalignment[$columnalignments[$i]]).$columnscss->[$i];
  }
  # append css to author's columnscss->[$i] that corresponds to other formatting that is in @htmlalignment
  for my $i (0..$#htmlalignment)
    {
      if ($htmlalignment[$i] =~ /\\color\s*\{\s*(\w*)[}!]/)
        {my $j = $i; while (!defined($alignmentcolumns[$j]) && $j < $#htmlalignment) {$j += 1;};
          $columnscss->[$alignmentcolumns[$j]] = 'color:'.$1.'; '.$columnscss->[$alignmentcolumns[$j]];
        };
      if ($htmlalignment[$i] =~ /\\color\s*\[\s*HTML\s*\]\s*\{\s*(\w*)[}!]/)
        {my $j = $i; while (!defined($alignmentcolumns[$j]) && $j < $#htmlalignment) {$j += 1;};
          $columnscss->[$alignmentcolumns[$j]] = 'color:#'.$1.'; '.$columnscss->[$alignmentcolumns[$j]];
        };
      if ($htmlalignment[$i] =~ /\\columncolor\s*\{\s*(\w*)[}!]/)
        {my $j = $i; while (!defined($alignmentcolumns[$j]) && $j < $#htmlalignment) {$j += 1;};
          $columnscss->[$alignmentcolumns[$j]] = 'background-color:'.$1.'; '.$columnscss->[$alignmentcolumns[$j]];
        };
      if ($htmlalignment[$i] =~ /\\columncolor\s*\[\s*HTML\s*\]\s*\{\s*(\w*)[}!]/)
        {my $j = $i; while (!defined($alignmentcolumns[$j]) && $j < $#htmlalignment) {$j += 1;};
          $columnscss->[$alignmentcolumns[$j]] = 'background-color:#'.$1.'; '.$columnscss->[$alignmentcolumns[$j]];
        };
      if ($htmlalignment[$i] =~ /\\bfseries$|\\bfseries\W/)
        {my $j = $i; while (!defined($alignmentcolumns[$j]) && $j < $#htmlalignment) {$j += 1;};
          $columnscss->[$alignmentcolumns[$j]] = 'font-weight:bold; '.$columnscss->[$alignmentcolumns[$j]];
        };
      if ($htmlalignment[$i] =~ /\\itshape$|\\itshape\W/)
        {my $j = $i; while (!defined($alignmentcolumns[$j]) && $j < $#htmlalignment) {$j += 1;};
          $columnscss->[$alignmentcolumns[$j]] = 'font-style:italic; '.$columnscss->[$alignmentcolumns[$j]];
        };
      if ($htmlalignment[$i] =~ /\\ttfamily$|\\ttfamily\W/)
        {my $j = $i; while (!defined($alignmentcolumns[$j]) && $j < $#htmlalignment) {$j += 1;};
          $columnscss->[$alignmentcolumns[$j]] = 'font-family:monospace; '.$columnscss->[$alignmentcolumns[$j]];
        };
      if ($htmlalignment[$i] =~ /\|\s*/)
        {my $j = $i; while (!defined($alignmentcolumns[$j]) && $j < $#htmlalignment) {$j += 1;};
          if ($j < $#htmlalignment) {$columnscss->[$alignmentcolumns[$j]] = "border-left:solid 1px; ".$columnscss->[$alignmentcolumns[$j]];};
          if ($alignmentcolumns[$j] != 0) {$columnscss->[$alignmentcolumns[$j]-1] = "border-right:solid 1px; ".$columnscss->[$alignmentcolumns[$j]-1];}
          if ($j == $#htmlalignment)
            {if ($j == $i) {$columnscss->[-1] = "border-right:solid 1px; ".$columnscss->[-1];} else {$columnscss->[-1] = "border-left:solid 1px; ".$columnscss->[-1];}}
        };

    };


  # translate individual cell's tex to css

  for my $i (0..$#{$dataref})
    {
      for my $j (0..$numcols[$i])
        {
          if (${$dataref->[$i][$j]}{tex} =~ /\\color\s*\{\s*(\w*)[}!]/)
            {
              ${$dataref->[$i][$j]}{cellcss} = 'color:'.$1.'; '.${$dataref->[$i][$j]}{cellcss};
            };
          if (${$dataref->[$i][$j]}{tex} =~ /\\color\s*\[\s*HTML\s*\]\s*\{\s*(\w*)[}!]/)
            {
              ${$dataref->[$i][$j]}{cellcss} = 'color:#'.$1.'; '.${$dataref->[$i][$j]}{cellcss};
            };
          if (${$dataref->[$i][$j]}{tex} =~ /\\cellcolor\s*\{\s*(\w*)[}!]/)
            {
              ${$dataref->[$i][$j]}{cellcss} = 'background-color:'.$1.'; '.${$dataref->[$i][$j]}{cellcss};
            };
          if (${$dataref->[$i][$j]}{tex} =~ /\\cellcolor\s*\[\s*HTML\s*\]\s*\{\s*(\w*)[}!]/)
            {
              ${$dataref->[$i][$j]}{cellcss} = 'background-color:#'.$1.'; '.${$dataref->[$i][$j]}{cellcss};
            };
          if (${$dataref->[$i][$j]}{tex} =~ /\\bfseries$|\\bfseries\W/)
            {
              ${$dataref->[$i][$j]}{cellcss} = 'font-weight:bold; '.${$dataref->[$i][$j]}{cellcss};
            };
          if (${$dataref->[$i][$j]}{tex} =~ /\\itshape$|\\itshape\W/)
            {
              ${$dataref->[$i][$j]}{cellcss} = 'font-style:italic; '.${$dataref->[$i][$j]}{cellcss};
            };
          if (${$dataref->[$i][$j]}{tex} =~ /\\ttfamily$|\\ttfamily\W/)
            {
              ${$dataref->[$i][$j]}{cellcss} = 'font-family:monospace; '.${$dataref->[$i][$j]}{cellcss};
            };
        };
    };

  my @alignmentcolumns;
    for my $i (0..$#columnalignments) {$alignmentcolumns[$columnalignments[$i]] = $i};
    # @alignmentcolumns is an array with one element per column, where the elements are each one of p{width}, r, c, l, or X

  # append css to author's columnscss->[$i] that corresponds to the alignemnts in @alignmentcolumns


  # parse tex alignment for individual cells to duplicate use in html
  for my $i (0..$#{$dataref})
    {
      for my $j (0..$numcols[$i])
        {
          if (${$dataref->[$i][$j]}{halign} ne '')
            {
            my @htmlalignment = split(/(>\s*(??{$bracesregex})\s*|\|\s*|p\s*(??{$bracesregex})\s*|[rclX]\s*)/,${$dataref->[$i][$j]}{halign});
            my @temp = ();
            foreach(@htmlalignment){
              if( ( defined $_) and ($_ ne '')){
                push(@temp, $_);
              }
            };
            @htmlalignment = @temp;
              # @htmlalignment is now an array, where the entries are the parsed pieces of ${$dataref->[$i][$j]}{halign}; entries parsed by
              # >{commands}, pipes (for vertical rules), p{width}, r, c, l, or X. There should only be one of the actual alignment characters

            my @columnalignments = grep { $htmlalignment[$_] =~ /^p\s*(??{$bracesregex})\s*|^[rclX]\s*/ } 0 .. $#htmlalignment;
              # @columnalignments is an array, where the entries are the indices form @htmlalignment that actually deal with
              # alignment: p{width}, r, c, l, or X. This array should only have one entry (but structure of this whole section has been copied from above)

            my @alignmentcolumns;
              for my $k (0..$#columnalignments) {$alignmentcolumns[$columnalignments[$k]] = $k};
              # @alignmentcolumns is an array with one element per column, where the elements are each one of p{width}, r, c, l, or X
              # Again, this should only have one entry.

            for my $k (0..$#columnalignments) {
              ${$dataref->[$i][$j]}{cellcss} = TeX_Alignment_to_CSS($htmlalignment[$columnalignments[$k]]).${$dataref->[$i][$j]}{cellcss};
            }
            for my $k (0..$#htmlalignment)
              {
                if ($htmlalignment[$k] =~ /\\color\s*\{\s*(\w*)[}!]/)
                  {my $m = $k; while (!defined($alignmentcolumns[$m]) && $m < $#htmlalignment) {$m += 1;};
                    ${$dataref->[$i][$j]}{cellcss} = 'color:'.$1.'; '.${$dataref->[$i][$j]}{cellcss};
                  };
                if ($htmlalignment[$k] =~ /\\color\s*\[\s*HTML\s*\]\s*\{\s*(\w*)[}!]/)
                  {my $m = $k; while (!defined($alignmentcolumns[$m]) && $m < $#htmlalignment) {$m += 1;};
                    ${$dataref->[$i][$j]}{cellcss} = 'color:#'.$1.'; '.${$dataref->[$i][$j]}{cellcss};
                  };
                if ($htmlalignment[$k] =~ /\\cellcolor\s*\{\s*(\w*)[}!]/)
                  {my $m = $k; while (!defined($alignmentcolumns[$m]) && $m < $#htmlalignment) {$m += 1;};
                    ${$dataref->[$i][$j]}{cellcss} = 'background-color:'.$1.'; '.${$dataref->[$i][$j]}{cellcss};
                  };
                if ($htmlalignment[$k] =~ /\\cellcolor\s*\[\s*HTML\s*\]\s*\{\s*(\w*)[}!]/)
                  {my $m = $k; while (!defined($alignmentcolumns[$m]) && $m < $#htmlalignment) {$m += 1;};
                    ${$dataref->[$i][$j]}{cellcss} = 'background-color:#'.$1.'; '.${$dataref->[$i][$j]}{cellcss};
                  };
                if ($htmlalignment[$k] =~ /\\bfseries$|\\bfseries\W/)
                  {my $m = $k; while (!defined($alignmentcolumns[$m]) && $m < $#htmlalignment) {$m += 1;};
                    ${$dataref->[$i][$j]}{cellcss} = 'font-weight:bold; '.${$dataref->[$i][$j]}{cellcss};
                  };
                if ($htmlalignment[$k] =~ /\\itshape$|\\itshape\W/)
                  {my $m = $k; while (!defined($alignmentcolumns[$m]) && $m < $#htmlalignment) {$m += 1;};
                    ${$dataref->[$i][$j]}{cellcss} = 'font-style:italic; '.${$dataref->[$i][$j]}{cellcss};
                  };
                if ($htmlalignment[$k] =~ /\\ttfamily$|\\ttfamily\W/)
                  {my $m = $k; while (!defined($alignmentcolumns[$m]) && $m < $#htmlalignment) {$m += 1;};
                    ${$dataref->[$i][$j]}{cellcss} = 'font-family:monospace; '.${$dataref->[$i][$j]}{cellcss};
                  };
                if ($htmlalignment[$k] =~ /\|\s*/)
                  {my $m = $k; while (!defined($alignmentcolumns[$m]) && $m < $#htmlalignment) {$m += 1;};
                    if ($m < $#htmlalignment) {${$dataref->[$i][$j]}{cellcss} = "border-left:solid 1px; ".${$dataref->[$i][$j]}{cellcss};};
                    if ($alignmentcolumns[$m] != 0) {${$dataref->[$i][$j]}{cellcss} = "border-right:solid 1px; ".${$dataref->[$i][$j]}{cellcss};}
                    if ($m == $#htmlalignment)
                      {if ($m == $k) {${$dataref->[$i][$j]}{cellcss} = "border-right:solid 1px; ".${$dataref->[$i][$j]}{cellcss};} else {${$dataref->[$i][$j]}{cellcss} = "border-left:solid 1px; ".${$dataref->[$i][$j]}{cellcss};}}
                  };

              };
            };
         };
    };

  my $midrulescss = '';
  if ($midrules == 1) {$midrulescss = 'border-top:solid 1px; '};

  my $table = '';
  # build html string for the table
  if ($options{LaYoUt} != 1) {
  $table = '<TABLE style = "'.$tablecss.'">';
  if ($caption ne '') {$table .= '<CAPTION style = "'.$captioncss.'">'.$caption.'</CAPTION>';}
  $table .= '<colgroup>';
  for my $i (0..$#{$columnscss})
    {$columnscss->[$i] = '' unless (defined($columnscss->[$i]));
     $table .= '<col style = "'.$columnscss->[$i].'">';};
  $table .= '</colgroup>';
  my $bodystarted = 0;
  for my $i (0..$#{$dataref})
    {my $midrulecss = ($midrule[$i] == 1) ? 'border-bottom:solid 1px; ' : '';
     if ($i == $#{$dataref} and ($midrules == 1)) {$midrulescss .= 'border-bottom:solid 1px; ';}
     if ($headerrow[$i] == 1) {$table .= '<THEAD>'; }
     elsif (!$bodystarted) {$table .= '<TBODY>'; $bodystarted = 1};
    $table .= '<TR>';
    for my $j (0..$numcols[$i])
      {my $colspan = (${$dataref->[$i][$j]}{colspan} eq '') ? '' : 'colspan = "'.${$dataref->[$i][$j]}{colspan}.'" ';
      if (uc(${$dataref->[$i][$j]}{header}) eq 'TH')
        {$table .= '<TH '.$colspan.'style = "'.$allcellcss.$headercss.$columnscss->[$j].$midrulecss.$midrulescss.$rowcss[$i].${$dataref->[$i][$j]}{cellcss}.'">'.${$dataref->[$i][$j]}{data}.'</TH>';}
        elsif (uc(${$dataref->[$i][$j]}{header}) ~~ ['CH','COLUMN','COL'])
        {$table .= '<TH '.$colspan.'scope = "col" style = "'.$allcellcss.$headercss.$columnscss->[$j].$midrulecss.$midrulescss.$rowcss[$i].${$dataref->[$i][$j]}{cellcss}.'">'.${$dataref->[$i][$j]}{data}.'</TH>';}
        elsif (uc(${$dataref->[$i][$j]}{header}) ~~ ['RH','ROW'])
        {$table .= '<TH '.$colspan.'scope = "row" style = "'.$allcellcss.$headercss.$columnscss->[$j].$midrulecss.$midrulescss.$rowcss[$i].${$dataref->[$i][$j]}{cellcss}.'">'.${$dataref->[$i][$j]}{data}.'</TH>';}
        elsif (uc(${$dataref->[$i][$j]}{header}) eq 'TD')
        {$table .= '<TD '.$colspan.'style = "'.$allcellcss.$datacss.$columnscss->[$j].$midrulecss.$midrulescss.$rowcss[$i].${$dataref->[$i][$j]}{cellcss}.'">'.${$dataref->[$i][$j]}{data}.'</TD>';}
        elsif (uc($headerrow[$i]) == 1)
        {$table .= '<TH '.$colspan.'scope = "col" style = "'.$allcellcss.$headercss.$columnscss->[$j].$midrulecss.$midrulescss.$rowcss[$i].${$dataref->[$i][$j]}{cellcss}.'">'.${$dataref->[$i][$j]}{data}.'</TH>';}
        else {$table .= '<TD '.$colspan.'style = "'.$allcellcss.$datacss.$columnscss->[$j].$midrulecss.$midrulescss.$rowcss[$i].${$dataref->[$i][$j]}{cellcss}.'">'.${$dataref->[$i][$j]}{data}.'</TD>';}
      }
    $table .= "</TR>";
    if ($headerrow[$i] == 1) {$table .= '</THEAD>';}
      elsif ($bodystarted and ($i == $#{$dataref})) {$table .= '</TBODY>';};
    };
    $table .= "</TABLE>";
   }# now if it is a Layout Table...
   else {
     $table = '<SECTION style = "display:table;'.$tablecss.'">';
     for my $i (0..$#{$dataref})
     {if ($i == $#{$dataref} and ($midrules == 1)) {$midrulescss .= "border-bottom:solid 1px;";}
      my $midrulecss = ($midrule[$i] == 1) ? 'border-bottom:solid 1px; ' : '';
      $table .= '<DIV style = "display:table-row;">';
       for my $j (0..$numcols[$i])
         {$table .= '<DIV style = "display:table-cell;'.$allcellcss.$columnscss->[$j].$midrulecss.$midrulescss.$rowcss[$i].${$dataref->[$i][$j]}{cellcss}.'">'.${$dataref->[$i][$j]}{data}.'</DIV>';}
       $table .= "</DIV>";
     };
     $table .= "</SECTION>";
   };

  #when \multicolumn{}{}{} is needed...
  for my $i (0..$#{$dataref})
    {
      for my $j (0..$numcols[$i])
        {
          ${$dataref->[$i][$j]}{multicolumn} = '';
          if ((${$dataref->[$i][$j]}{halign} ne '') or (${$dataref->[$i][$j]}{colspan} ne ''))
            {
              ${$dataref->[$i][$j]}{multicolumn} = '\multicolumn{';
              if (${$dataref->[$i][$j]}{colspan} ne '') {${$dataref->[$i][$j]}{multicolumn} .= ${$dataref->[$i][$j]}{colspan}}
              else {${$dataref->[$i][$j]}{multicolumn} .= '1'};
              ${$dataref->[$i][$j]}{multicolumn} .= '}{';
              if (${$dataref->[$i][$j]}{halign} ne '') {${$dataref->[$i][$j]}{multicolumn} .= ${$dataref->[$i][$j]}{halign}}
              else {${$dataref->[$i][$j]}{multicolumn} .= 'c'};
              ${$dataref->[$i][$j]}{multicolumn} .= '}{';
            };
         };
    };

   my $textable = '';
   # build tex string for the table
    if ($options{LaYoUt} != 1)
    {my ($begintabular,$endtabular) = ('\begin{tabular}','\end{tabular}');
    if ($texalignment =~ /X/) {($begintabular,$endtabular) = ('\begin{tabularx}{'.$Xratio.'\linewidth}','\end{tabularx}');};
    $textable = '\par\begin{minipage}{\linewidth}';
    if ($center == 1) {$textable .= '\centering';};
    if ($caption ne '') {$textable .= '\captionsetup{textfont={sc},belowskip=12pt,aboveskip=4pt}\captionof*{table}{'.$caption.'}';};
    $textable .= $begintabular.'{'.$texalignment.'}'.'\toprule';
    for my $i (0..$#{$dataref})
      {
       if ($rowcolor[$i] ne '') {$textable .= '\rowcolor'.$rowcolor[$i];};
       for my $j (0..$numcols[$i])
        {if (uc(${$dataref->[$i][$j]}{header}) ~~ ['TH','CH','COLUMN','COL','RH','ROW']) {${$dataref->[$i][$j]}{tex} = '\bfseries '.${$dataref->[$i][$j]}{tex}};
        if (${$dataref->[$i][$j]}{multicolumn} ne '') {$textable .= ${$dataref->[$i][$j]}{multicolumn}};
        if (($headerrow[$i] == 1) and !(uc(${$dataref->[$i][$j]}{header}) ~~ ['TD'])) {$textable .= '\bfseries '};
        $textable .= ${$dataref->[$i][$j]}{tex}.' '.${$dataref->[$i][$j]}{texpre}.' '.${$dataref->[$i][$j]}{data}.' '.${$dataref->[$i][$j]}{texpost};
        if (${$dataref->[$i][$j]}{multicolumn} ne '') {$textable .= '}'};
        $textable .= '&' unless ($j == $numcols[$i]);
        };
      $textable .= '\\\\';
      if ($midrule[$i] == 1) {$textable .= '\midrule '};
      if ((($midrules == 1) or ($headerrow[$i] == 1)) and (($i != $#{$dataref}) or ($footerline ne ''))) {$textable .= '\midrule '};
      };
    $textable .= '\bottomrule'.$endtabular;
    $textable .= '\end{minipage}\par  \vspace{1pc}';
    }# and now if it is a Layout Table...
    else {
      my ($begintabular,$endtabular) = ('\begin{tabular}','\end{tabular}');
      if ($texalignment =~ /X/) {($begintabular,$endtabular) = ('\begin{tabularx}{'.$Xratio.'\linewidth}','\end{tabularx}');};

      $textable = ($center == 1) ? '\begin{center}' : '\begin{flushleft}';
      $textable .= '{\renewcommand{\arraystretch}{2}';
      $textable .= $begintabular.'{'.$texalignment.'}';
      for my $i (0..$#{$dataref})
        {if ($rowcolor[$i] ne '') {$textable .= '\rowcolor'.$rowcolor[$i];};
         for my $j (0..$numcols[$i])
         {
           if (${$dataref->[$i][$j]}{halign} ne '') {$textable .= '\multicolumn{1}{'.${$dataref->[$i][$j]}{halign}.'}{'};
           $textable .= ${$dataref->[$i][$j]}{tex}.' '.${$dataref->[$i][$j]}{texpre}.' '.${$dataref->[$i][$j]}{data}.' '.${$dataref->[$i][$j]}{texpost};
           if (${$dataref->[$i][$j]}{halign} ne '') {$textable .= '}'};
           $textable .= '&' unless ($j == $numcols[$i]);
         };
       $textable .= '\\\\';
       if ($midrule[$i] == 1) {$textable .= '\midrule '};
       if (($midrules == 1) and ($i != $#{$dataref})) {$textable .= '\midrule '};
       };
       $textable .= $endtabular;
       $textable .= '}';
       if ($center ==1) {$textable .= '\end{center}'} else {$textable .= '\end{flushleft}'};
    };

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
 #    used as the key for cell contents).
 #
=cut

sub LayoutTable {
  my $dataref = shift;
  DataTable($dataref,LaYoUt=>1,@_);
}


sub TeX_Alignment_to_CSS {
   my $alignmentstring = shift;
   my $bracesregex = qr/(\{(?>[^{}]|(?R))*\})/x;
     # grabs outer level braces and their contents, including inner brace pairs
   my $bracecontentsregex = qr/((?>[^{}]|(??{$bracesregex}))*)/x;
     # grabs contents of an outer level brace pair, including inner brace pairs

   my $css = '';
    if ($alignmentstring =~ /r\s*/)
      {$css .= "text-align:right; white-space:nowrap; ";
      }
    elsif ($alignmentstring =~ /c\s*/)
      {$css .= "text-align:center; white-space:nowrap; ";
      }
    elsif ($alignmentstring =~ /l\s*/)
      {$css .= "text-align:left; white-space:nowrap; ";
      }
    elsif ($alignmentstring =~ /X\s*/)
      {$css .= "text-align:justify; white-space:normal; ";
      }
    elsif ($alignmentstring =~ /p\s*\{((??{$bracecontentsregex}))\}\s*/)
      {
        $css .= "text-align:justify; white-space:normal; width:".$1."; ";
      };
   return $css;
}



1;
