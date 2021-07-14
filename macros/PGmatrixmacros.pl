
###########
#use Carp;

=head1 NAME

        Matrix macros for the PG language

=head1 SYNPOSIS



=head1 DESCRIPTION

These macros are fairly old. The most useful is display_matrix and
its variants.

Frequently it will be
most useful to use the MathObjects Matrix (defined in Value::Matrix.pm)
and Vector types which
have more capabilities and more error checking than the subroutines in 
this file. These macros have no object orientation and 
work with vectors and matrices 
stored as perl anonymous arrays. 

There are also Matrix objects defined in
RealMatrix.pm and Matrix.pm but in almost all cases the
MathObjects Matrix types are preferable.


=cut

BEGIN {
        be_strict();
}

sub _PGmatrixmacros_init {
}


############

=head4  display_matrix

	Usage  
	       \{ display_matrix( [ [1, '\(\sin x\)'], [ans_rule(5), 6] ]) \}
	       \{ display_matrix($A, align=>'crvl') \}
	       \[ \{   display_matrix_mm($A)  \} \]
	       \[ \{ display_matrix_mm([ [1, 3], [4, 6] ])  \} \]

display_matrix produces a matrix for display purposes.  It checks whether
it is producing LaTeX output, or if it is displaying on a web page in one
of the various modes.  The input can either be of type Matrix, Value::Matrix (mathobject)
or a reference to an array.

Entries can be numbers, Fraction objects, bits of math mode, or answer
boxes.  An entire row can be replaced by the string 'hline' to produce
a horizontal line in the matrix.

display_matrix_mm functions similarly, except that it should be inside
math mode.  display_matrix_mm cannot contain answer boxes in its entries.
Entries to display_matrix_mm should assume that they are already in
math mode.

Both functions take an optional alignment string, similar to ones in
LaTeX tabulars and arrays.  Here c for centered columns, l for left
flushed columns, and r for right flushed columns.

The alignment string can also specify vertical rules to be placed in the
matrix.  Here s or | denote a solid line, d is a dashed line, and v
requests the default vertical line.  This can be set on a system-wide
or course-wide basis via the variable $defaultDisplayMatrixStyle, and
it can default to solid, dashed, or no vertical line (n for none).

The matrix has left and right delimiters also specified by
$defaultDisplayMatrixStyle.  They can be parentheses, square brackets,
braces, vertical bars, or none.  The default can be overridden in
an individual problem with optional arguments such as left=>"|", or
right=>"]".

You can specify an optional argument of 'top_labels'=> ['a', 'b', 'c'].
These are placed above the columns of the matrix (as is typical for
linear programming tableau, for example).  The entries will be typeset
in math mode.

Top labels require a bit of care.  For image modes, they look better
with display_matrix_mm where it is all one big image, but they work with
display_matrix.  With tth, you pretty much have to use display_matrix
since tth can't handle the TeX tricks used to get the column headers
up there if it gets the whole matrix at once.


=cut


sub display_matrix_mm{    # will display a matrix in tex format.
                       # the matrix can be either of type array or type 'Matrix'
        return display_matrix(@_, 'force_tex'=>1);
}

sub display_matrix_math_mode {
        return display_matrix_mm(@_);
}

sub display_matrix {
        my $ra_matrix = shift;
        my %opts = @_;
        $ra_matrix = convert_to_array_ref($ra_matrix);
        my $styleParams = defined($main::defaultDisplayMatrixStyle) ?
                $main::defaultDisplayMatrixStyle : "(s)";

        set_default_options(\%opts,
				'_filter_name' => 'display_matrix',
				'force_tex' => 0,
				'left' => substr($styleParams,0,1),
				'right' => substr($styleParams,2,1),
				'midrule' => substr($styleParams,1,1),
				'top_labels' => 0,
				'box'=>[-1,-1], # pair location of boxed element
				'allow_unknown_options'=> 1,
				'num_format' => "%.0f",
		);

        my ($numRows, $numCols, @myRows);
        my $original_matrix = $ra_matrix;
        if (ref($ra_matrix) eq 'Value::Matrix') {
        	$ra_matrix = $ra_matrix->wwMatrix->array_ref; # translate
        }
        if (ref($ra_matrix) eq 'Matrix' )  { #handle Real::Matrix1 type matrices: #FIXME deprectated
                ($numRows, $numCols) = $ra_matrix->dim();
                for( my $i=0; $i<$numRows; $i++) {
                        $myRows[$i] = [];
                        for (my $j=0; $j<$numCols; $j++) {
                                my $entry = $ra_matrix->element($i+1,$j+1);
                                $entry = "#" unless defined($entry);
                                push @{ $myRows[$i] },  $entry;
                        }
                }
        } else { # matrix is input as [ [1,2,3],[4,5,6]]
                $numCols = 0;
                @myRows = @{$ra_matrix};
                $numRows = scalar(@myRows); # counts horizontal rules too
                my $tmp;
                for $tmp (@myRows) {
                        if($tmp ne 'hline') {
                                my @arow = @{$tmp};
                                $numCols= scalar(@arow);   #number of columns in table
                                last;
                        }
                }
        }

        my $out;
        my $j;
        my $alignString=''; # alignment as a string for dvi/pdf
        my $alignList;      # alignment as a list

        if(defined($opts{'align'})) {
                $alignString= $opts{'align'};
                $alignString =~ s/v/$opts{'midrule'}/g;
                $alignString =~ tr/s/|/; # Treat "s" as "|"
                $alignString =~ tr/n//;  # Remove "n" altogether
                @$alignList = split //, $alignString;
        } else {
                for($j=0; $j<$numCols; $j++) {
                        $alignList->[$j] = "c";
                        $alignString .= "c";
                }
        }
        # Before we start, we cannot let top_labels proceed if we
        # are in tth mode and force_tex is true since tth can't handle
        # the resulting code
        if($opts{'force_tex'} and $main::displayMode eq 'HTML_tth') {
                $opts{'top_labels'} = 0;
        }

        $out .= dm_begin_matrix($alignString, %opts);
        # column labels for linear programming
        $out .= dm_special_tops(%opts, 'alignList'=>$alignList) if ($opts{'top_labels'});
        $out .= dm_mat_left($numRows, %opts);
		my $cnt = 1; # we count rows in in case an element is boxed
        # vertical lines put in with first row
        $j = shift @myRows;
        my $tag = $opts{side_labels}->[$cnt-1];
        $out .= dm_mat_row($j, $alignList, %opts, 'isfirst'=>$numRows, 
		'cnt' => $cnt, 'tag'=>$tag);
		$cnt++ unless ($j eq 'hline');
        $out .= dm_mat_right($numRows, %opts);
        for $j (@myRows) {
        		$tag = $opts{side_labels}->[$cnt-1];
                $out .= dm_mat_row($j, $alignList, %opts, 'isfirst'=>0,
			'cnt' => $cnt,'tag'=>$tag);
		$cnt++ unless ($j eq 'hline');
        }
        $out .= dm_end_matrix(%opts);
        $out;
}

sub dm_begin_matrix {
        my ($aligns)=shift;   #alignments of columns in table
        my %opts = @_;
        my $out =        "";
        if ($main::displayMode eq 'TeX' or $opts{'force_tex'}) {
                # This should be doable by regexp, but it wasn't working for me
                my ($j, @tmp);
                @tmp = split //, $aligns;
                $aligns='';
                for $j (@tmp) {
                        # I still can't get an @ expression sent to TeX, so plain
                        # vertical line
                        $aligns .= ($j eq "d") ? '|' : $j;
                }
                $out .= $opts{'force_tex'} ? '' : '\(';
                if ($opts{'top_labels'} and $main::displayMode ne 'HTML_MathJax') {
                        $out .= '\begingroup\setbox3=\hbox{\ensuremath{';
                }
                $out .= '\displaystyle\left'.$opts{'left'}."\\begin{array}{$aligns} \n";
        }  elsif ($main::displayMode eq 'Latex2HTML') {
                $out .= "\n\\begin{rawhtml} <TABLE  BORDER=0>\n\\end{rawhtml}";
        }  elsif ( $main::displayMode eq 'HTML_MathJax'
                      or $main::displayMode eq 'HTML_dpng'
                      or $main::displayMode eq 'HTML_tth'
                      or $main::displayMode eq 'HTML_jsMath'
                      or $main::displayMode eq 'HTML_asciimath'
                      or $main::displayMode eq 'HTML_LaTeXMathML'
                      or $main::displayMode eq 'HTML'
                      or $main::displayMode eq 'HTML_img') {
                $out .= qq!<TABLE class="matrix" BORDER="0" style="border-collapse: separate; border-spacing:10px 0px;">\n!;
        }
        elsif ( $main::displayMode eq 'PTX' ) {
                $out .= qq!<tabular>\n!;
        }
        else {
                $out = "Error: dm_begin_matrix: Unknown displayMode: $main::displayMode.\n";
                }
        $out;
}

sub dm_special_tops {
        my %opts = @_;
        my @top_labels = @{$opts{'top_labels'}};
        my $out = '';
	my @alignList = @{$opts{'alignList'}};
        my ($j, $k);
        my ($brh, $erh) = ("",""); # Start and end raw html
        if($main::displayMode eq 'Latex2HTML') {
                $brh = "\\begin{rawhtml}";
                $erh = "\\end{rawhtml}";
        }

        if ($main::displayMode eq 'TeX' or $opts{'force_tex'}) {
                for $j (@top_labels) {
                	if ($main::displayMode ne 'HTML_MathJax') {
                       $out .= '\smash{\raisebox{2.9ex}{\ensuremath{'.
                                $j . '}}} &';
                    } else {
                         $out .= $j.'&';  #for compatibility with MathJax
                    }
                }
                chop($out); # remove last &
                #$out .= '\cr\noalign{\vskip -2.5ex}'."\n"; # want skip jump up 2.5ex
                $out.='\cr'; # mathjax compatibility
        } elsif ( $main::displayMode eq 'HTML_MathJax'
                      or $main::displayMode eq 'HTML_dpng'
                      or $main::displayMode eq 'HTML_tth'
                      or $main::displayMode eq 'HTML_jsMath'
                      or $main::displayMode eq 'HTML_asciimath'
                      or $main::displayMode eq 'HTML_LaTeXMathML'
                      or $main::displayMode eq 'HTML'
                      or $main::displayMode eq 'HTML_img') {
                $out .= "$brh<tr><td>$erh"; # Skip a column for the left brace
                for $j (@top_labels) {
			$k = shift @alignList;
			while(defined($k) and ($k !~ /[lrc]/)) {
				$out .= "$brh<td></td>$erh";
				$k = shift @alignList;
			}
                        $out .= "$brh<td align=\"center\">$erh". ' \('.$j.'\)'."$brh</td>$erh";
                }
		$out .= "<td></td>";
        }
        elsif ( $main::displayMode eq 'PTX' ) {
        } else {
                $out = "Error: dm_begin_matrix: Unknown displayMode: $main::displayMode.\n";
        }
        return $out;
}

sub dm_mat_left {
        my $numrows = shift;
        my %opts = @_;
        if ($main::displayMode eq 'TeX' or $opts{'force_tex'} or $main::displayMode eq 'PTX') {
                return ""; # left delim is built into begin matrix
        }
        my $out='';
        my $j;
        my ($brh, $erh) = ("",""); # Start and end raw html
        if($main::displayMode eq 'Latex2HTML') {
                $brh = "\\begin{rawhtml}";
                $erh = "\\end{rawhtml}";
        }

        if( $main::displayMode eq 'HTML_MathJax'
                      or $main::displayMode eq 'HTML_dpng'
                      or $main::displayMode eq 'HTML_tth'
                      or $main::displayMode eq 'HTML_jsMath'
                      or $main::displayMode eq 'HTML_asciimath'
                      or $main::displayMode eq 'HTML_LaTeXMathML'
                      or $main::displayMode eq 'HTML'
                      or $main::displayMode eq 'HTML_img') {
                $out .= "$brh<tr valign=\"center\"><td nowrap=\"nowrap\" align=\"left\" rowspan=\"$numrows\">$erh";
                $out .= dm_image_delimeter($numrows, $opts{'left'});
#               $out .= "$brh<td><table border=0  cellspacing=5>\n$erh";
                return $out;
        }
        # Mode is now tth

        $out .= "<tr valign=\"center\"><td nowrap=\"nowrap\" align=\"left\" rowspan=\"$numrows\">";
        $out .= dm_tth_delimeter($numrows, $opts{'left'});
#       $out .= "<td><table border=0  cellspacing=5>\n";
        return $out;
}

sub dm_mat_right {
        my $numrows = shift;
        my %opts = @_;
        my $out='';
        my $j;
        my ($brh, $erh) = ("",""); # Start and end raw html
        if($main::displayMode eq 'Latex2HTML') {
                $brh = "\\begin{rawhtml}";
                $erh = "\\end{rawhtml}";
        }


        if ($main::displayMode eq 'TeX' or $opts{'force_tex'} or $main::displayMode eq 'PTX') {
                return "";
        }

        if( $main::displayMode eq 'HTML_MathJax'
                      or $main::displayMode eq 'HTML_dpng'
                      or $main::displayMode eq 'HTML_tth'
                      or $main::displayMode eq 'HTML_jsMath'
                      or $main::displayMode eq 'HTML_asciimath'
                      or $main::displayMode eq 'HTML_LaTeXMathML'
                      or $main::displayMode eq 'HTML'
                      or $main::displayMode eq 'HTML_img') {
                $out .= "$brh<td nowrap=\"nowrap\" align=\"right\" rowspan=\"$numrows\">$erh";

                $out.= dm_image_delimeter($numrows, $opts{'right'});
                return $out;
        }

#       $out .= "</table>";
  $out .= '<td nowrap="nowrap" align="left" rowspan="'.$numrows.'2">';
        $out .= dm_tth_delimeter($numrows, $opts{'right'});
  $out .= '</td>';
        return $out;
}

sub dm_end_matrix {
        my %opts = @_;

        my $out = "";
        if ($main::displayMode eq 'TeX' or $opts{'force_tex'}) {
                $out .= "\\end{array}\\right$opts{right}";
                if($opts{'top_labels'} and $main::displayMode ne 'HTML_MathJax') {
                        $out .= '}} \dimen3=\ht3 \advance\dimen3 by 3ex \ht3=\dimen3'."\n".
                        '\box3\endgroup';
                }
                $out .= $opts{'force_tex'} ? '' : "\\) ";
        }
        elsif ($main::displayMode eq 'Latex2HTML') {
                $out .= "\n\\begin{rawhtml} </TABLE >\n\\end{rawhtml}";
                }
        elsif ( $main::displayMode eq 'HTML_MathJax'
                      or $main::displayMode eq 'HTML_dpng'
                      or $main::displayMode eq 'HTML_tth'
                      or $main::displayMode eq 'HTML_jsMath'
                      or $main::displayMode eq 'HTML_asciimath'
                      or $main::displayMode eq 'HTML_LaTeXMathML'
                      or $main::displayMode eq 'HTML'
                      or $main::displayMode eq 'HTML_img') {
                $out .= "</TABLE>\n";
                }
        elsif ( $main::displayMode eq 'PTX') {
                $out .= qq!</tabular>\n!;
                }
        else {
                $out = "Error: PGmatrixmacros: dm_end_matrix: Unknown displayMode: $main::displayMode.\n";
                }
        $out;
}

# Make an image of a big delimiter for a matrix
sub dm_image_delimeter {
        my $numRows = shift;
        my $char = shift;
        my ($out, $j);

        if($char eq ".") {return("");}
        if($char eq "d") { # special treatment for dashed lines
                $out='\(\vbox to '.($numRows*1.7).'\baselineskip ';
                $out .='{\cleaders\hbox{\vbox{\hrule width0pt height3pt depth0pt';
                $out .='\hrule width0.3pt height6pt depth0pt';
                $out .='\hrule width0pt height3pt depth0pt}}\vfil}\)';
                return($out);
        }

        if($char eq "{") {$char = '\lbrace';}
        if($char eq "}") {$char = '\rbrace';}
        $out .= '\(\left.\vphantom{\begin{array}{c}';
        for($j=0;$j<=$numRows;$j++) { $out .= '\!\strut\\\\'; }
        $out .= '\end{array}}\right'.$char.'\)';
        return($out);
}

# Basically uses a table of special characters and simple
# recipe to produce big delimeters a la tth mode
sub dm_tth_delimeter {
        my $numRows = shift;
        my $char = shift;

        if($char eq ".") { return("");}
        my ($top, $mid, $bot, $extra);
        my ($j, $out);

        if($char eq "(") { ($top, $mid, $bot, $extra) = ('æ','ç','è','ç');}
        elsif($char eq ")") { ($top, $mid, $bot, $extra) = ('ö','÷','ø','÷');}
        elsif($char eq "|") { ($top, $mid, $bot, $extra) = ('ê','ê','ê','ê');}
        elsif($char eq "[") { ($top, $mid, $bot, $extra) = ('é','ê','ë','ê');}
        elsif($char eq "]") { ($top, $mid, $bot, $extra) = ('ù','ú','û','ú');}
        elsif($char eq "{") { ($top, $mid, $bot, $extra) = ('ì','ï','î','í');}
        elsif($char eq "}") { ($top, $mid, $bot, $extra) = ('ü','ï','þ','ý');}
        else { warn "Unknown delimiter in dm_tth_delimeter";}

        # old version
#       $out = '<td nowrap="nowrap" align="left"><font face="symbol">';
        $out = '<font face="symbol">';
        $out .= "$top<br />";
        for($j=1;$j<$numRows; $j++) {
                $out .= "$mid<br />";
        }
        $out .= "$extra<br />";
        for($j=1;$j<$numRows; $j++) {
                $out .= "$mid<br />";
        }
        $out .= "$bot</font></td>";
        return $out;
}

# Make a row for the matrix
sub dm_mat_row {
        my $elements = shift;
        my $tmp = shift;
        my @align =  @{$tmp} ;
        my %opts = @_;

        if($elements eq 'hline') {
                if ($main::displayMode eq 'TeX' or $opts{'force_tex'}) {
                        return '\hline ';
                } else {
                        # Making a hline in a table
                        return '<tr><td colspan="'.scalar(@align).'"><hr></td></tr>';
                }
        }

        my @elements = @{$elements};
        my $out = "";
        my ($brh, $erh) = ("",""); # Start and end raw html
        my $element;
        my $colcount=0;
        if($main::displayMode eq 'Latex2HTML') {
                $brh = "\\begin{rawhtml}";
                $erh = "\\end{rawhtml}";
        }
        if ($main::displayMode eq 'TeX' or $opts{'force_tex'}) {
                while (@elements) {
			$colcount++;
			$out .= '\fbox{' if ($colcount == $opts{'box'}->[1] and $opts{'cnt'}  == $opts{'box'}->[0]);
                        $element= shift(@elements);
                        if(ref($element) eq 'Fraction') {
                                $element=  $element->print_inline();
                        }
						if($opts{'force_tex'}) {
                        	$out .= "$element";
						} else {
                        	$out .= '\\mbox{'."$element".'}';
						}
						$out .= '}' if ($colcount == $opts{'box'}->[1] and $opts{'cnt'} == $opts{'box'}->[0]);
                        $out .= " &";
                }
                if ($opts{tag}) {
                	$out.= $opts{tag};
                } else {
                	chop($out); # remove last &
                }
                $out .= "\\cr  \n";
                 # carriage returns must be added manually for tex
                } elsif ( $main::displayMode eq 'HTML_MathJax'
                      or $main::displayMode eq 'HTML_dpng'
                      or $main::displayMode eq 'HTML_tth'
                      or $main::displayMode eq 'HTML_jsMath'
                      or $main::displayMode eq 'HTML_asciimath'
                      or $main::displayMode eq 'HTML_LaTeXMathML'
                      or $main::displayMode eq 'HTML'
                      or $main::displayMode eq 'HTML_img') {
                        if(not $opts{'isfirst'}) {                $out .=  "$brh\n<TR>\n$erh";}
                while (@elements) {
                        my $myalign;
                        $myalign = shift @align;
                        if($myalign eq "|" or $myalign eq "d") {
                                if($opts{'isfirst'} && $main::displayMode ne 'HTML_tth') {
                                        $out .= $brh.'<td rowspan="'.$opts{'isfirst'}.'">'.$erh;
                                        $out .= dm_image_delimeter($opts{'isfirst'}-1, $myalign);
                                } elsif($main::displayMode eq 'HTML_tth') {
                                        if($myalign eq "d") { # dashed line in tth mode
                                                $out .= '<td> | </td>';
                                        } elsif($opts{'isfirst'}) { # solid line in tth mode
                                                $out .= '<td rowspan="'.$opts{'isfirst'}.'"<table border="0"><tr>';
                                                $out .= dm_tth_delimeter($opts{'isfirst'}-1, "|");
                                                $out .= '</td></tr></table>';
                                        }
                                }
                        } else {
                                if($myalign eq "c") { $myalign = "center";}
                                if($myalign eq "l") { $myalign = "left";}
                                if($myalign eq "r") { $myalign = "right";}
				$colcount++;
				$out .= '\fbox{' if ($colcount == $opts{'box'}->[1] and $opts{'cnt'} == $opts{'box'}->[0]);
                                $element= shift(@elements);
                                if (ref($element) eq 'Fraction') {
                                        $element=  $element->print_inline();
                                #}elsif( $element =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ and $element != sprintf($opts{'num_format'},$element) and $element - sprintf($opts{'num_format'},$element) < $main::functZeroLevelTolDefault){
				#	$element = sprintf($opts{'num_format'},$element);
				#	$element = 0 if abs($element) < $main::functZeroLevelTolDefault;
				}
                                $out .= "$brh<TD nowrap=\"nowrap\" align=\"$myalign\">$erh";
                                $out .= '<table border="1"><tr><td>' if ($colcount == $opts{'box'}->[1] and $opts{'cnt'} == $opts{'box'}->[0]);
                                $out .= $element;
                                $out .= '</td></tr></table>' if ($colcount == $opts{'box'}->[1] and $opts{'cnt'} == $opts{'box'}->[0]);
				$out .= "$brh</TD>$erh";
                        }
                }
                        if(not $opts{'isfirst'}) {$out .="$brh</TR>$erh\n";}
        }
        elsif ($main::displayMode eq 'PTX') {
                $out .= "<row>\n";
                while (@elements) {
                    $colcount++;
                    $out .= '<cell>';
                    $out .= shift(@elements);
                    $out .= "</cell>\n";
                    }
                $out .= "</row>\n";
                }
        else {
                $out = "Error: dm_mat_row: Unknown displayMode: $main::displayMode.\n";
                }
        $out;
}

=head4 side_labels

Produces an array that can be used to add labels outside a matrix.  useful
for presenting tableaus. Entries are set in mathmode

	side_labels( @array );

	\( \{lp_display_mm([$matrix3->value],
	      top_labels=>[qw(x_1 x_2 x_3 x_4 obj b)] )
	   \}
        \{side_labels(  qw(\text{cash} \text{hours} \text{profits} ) )
        \}
    \)

=cut

sub side_labels {
	my @labels;
	if (ref($_[0])=~/ARRAY/) { # accept either an array or a reference to an array
		@labels = @{$_[0]};
	} else {
		@labels = @_;
	}
	my $outputstring = "\\begin{array}{c}";
	foreach my $label (@labels) {
		$outputstring .= "$label \\\\ \n";
	}
	$outputstring .= "\\end{array}";
}

=head4  mbox

                Usage        \{ mbox(thing1, thing2, thing3) \}
          \{ mbox([thing1, thing2, thing3], valign=>'top') \}

    mbox takes a list of constructs, such as strings, or outputs of
          display_matrix, and puts them together on a line.  Without mbox, the
          output of display_matrix would always start a new line.

          The inputs can be just listed, or given as a reference to an array.
          With the latter, optional arguments can be given.

          Optional arguments are allowbreaks=>'yes' to allow line breaks in TeX
          output; and valign which sets vertical alignment on web page output.

=cut

sub mbox {
        my $inList = shift;
        my %opts;
        if(ref($inList) eq 'ARRAY') {
                %opts = @_;
        } else {
                %opts = ();
                $inList = [$inList, @_];
        }

        set_default_options(\%opts,
			'_filter_name' => 'mbox',
			'valign' => 'middle',
			'allowbreaks' => 'no',
			'allow_unknown_options'=> 0
        );
        if(! $opts{'allowbreaks'}) { $opts{'allowbreaks'}='no';}
        my $out = "";
        my $j;
        my ($brh, $erh) = ("",""); # Start and end raw html if needed
        if($main::displayMode eq 'Latex2HTML') {
                $brh = "\\begin{rawhtml}";
                $erh = "\\end{rawhtml}";
        }
        my @hlist = @{$inList};
        if($main::displayMode eq 'TeX') {
                if($opts{allowbreaks} ne 'no') {$out .= '\mbox{';}
                for $j (@hlist) { $out .= $j;}
                if($opts{allowbreaks} ne 'no') {$out .= '}';}
        } else {
                $out .= qq!$brh<table><tr valign="$opts{'valign'}">$erh!;
                for $j (@hlist) {
                        $out .= qq!$brh<td align="center" nowrap="nowrap">$erh$j$brh</td>$erh!;
                }
                $out .= "$brh</table>$erh";
        }
        return $out;
}


=head4   ra_flatten_matrix

                Usage:   ra_flatten_matrix($A)
                        returns:  [a11, a12,a21,a22]

                        where $A is a matrix object
                        The output is a reference to an array.  The matrix is placed in the array by iterating
                        over  columns on the inside
                        loop, then over the rows. (e.g right to left and then down, as one reads text)


=cut


sub ra_flatten_matrix{
        my $matrix = shift;
        warn "The argument must be a matrix object" unless ref($matrix) =~ /Matrix/;
        my @array = ();
        my ($rows, $cols ) = $matrix->dim();
        foreach my $i (1..$rows) {
                foreach my $j (1..$cols) {
                        push(@array, $matrix->element($i,$j)  );
                }
        }
        \@array;
}


=head4 apl_matrix_mult() 

	# This subroutine is probably obsolete and not generally useful.  
	# It was patterned after the APL
	# constructs for multiplying matrices. It might come in handy 
	# for non-standard multiplication of
	# of matrices (e.g. mod 2) for indice matrices.

=cut

sub apl_matrix_mult{
        my $ra_a= shift;
        my $ra_b= shift;
        my %options = @_;
        my $rf_op_times= sub {$_[0] *$_[1]};
        my $rf_op_plus = sub {my $sum = 0; my @in = @_; while(@in){ $sum = $sum + shift(@in) } $sum; };
        $rf_op_times = $options{'times'} if defined($options{'times'}) and ref($options{'times'}) eq 'CODE';
        $rf_op_plus = $options{'plus'} if defined($options{'plus'}) and ref($options{'plus'}) eq 'CODE';
        my $rows = @$ra_a;
        my $cols = @{$ra_b->[0]};
        my $k_size = @$ra_b;
        my $out ;
        my ($i, $j, $k);
        for($i=0;$i<$rows;$i++) {
                for($j=0;$j<$cols;$j++) {
                    my @r = ();
                    for($k=0;$k<$k_size;$k++) {
                            $r[$k] =  &$rf_op_times($ra_a->[$i]->[$k] , $ra_b->[$k]->[$j]);
                    }
                        $out->[$i]->[$j] = &$rf_op_plus( @r );
                }
        }
        $out;
}

sub matrix_mult {
        apl_matrix_mult($_[0], $_[1]);
}

sub make_matrix{
        my $function = shift;
        my $rows = shift;
        my $cols = shift;
        my ($i, $j, $k);
        my $ra_out;
        for($i=0;$i<$rows;$i++) {
                for($j=0;$j<$cols;$j++) {
                        $ra_out->[$i]->[$j] = &$function($i,$j);
                }
        }
        $ra_out;
}

=head4 create2d_matrix

This can be a useful method for quickly entering small matrices by hand.
 --MEG

	create2d_matrix("1 2 4, 5 6 8"); or
	create2d_matrix("1 2 4; 5 6 8");
	produces the anonymous array
	[[1,2,4],[5,6,8] ]

	Matrix(create2d_matrix($string));

=cut

sub create2d_matrix {
	my $string = shift;
	my @rows = split("\\s*[,;]\\s*",$string);
	@rows = map {[split("\\s", $_ )]} @rows;
	[@rows];
}


=head2 convert_to_array_ref {

	$output_matrix = convert_to_array_ref($input_matrix)

Converts a MathObject matrix (ref($input_matrix) eq 'Value::Matrix')
or a MatrixReal1 matrix (ref($input_matrix) eq 'Matrix') to
a reference to an array (e.g [[4,6],[3,2]]).
This adaptor allows all of the LinearProgramming.pl subroutines to be used with
MathObject arrays.

$mathobject_matrix->value outputs an array (usually an array of array references) so placing it inside
square bracket produces and array reference (of array references) which is what lp_display_mm() is
seeking.

=cut

sub convert_to_array_ref {
	my $input = shift;
	if (Value::isValue($input) && Value::classMatch($input,"Matrix")) {
		$input = [$input->value];		
	} elsif (ref($input) eq 'Matrix' ) {
		$input = $input->array_ref;
	} elsif (ref($input) =~/ARRAY/) {
		# no change to input value
	} else {
	WARN_MESSAGE("This does not appear to be a matrix ");
	}
	$input;
}

=head4 check_matrix_from_ans_box_cmp

An answer checker factory built on create2d_matrix.  This still needs
work.  It is not feature complete, particularly with regard to error messages
for incorrect input. --MEG

	$matrix = Matrix("[[1,4],[2,3]");
	ANS( check_matrix_from_ans_box($matrix) );

=cut

sub check_matrix_from_ans_box_cmp{
	my $correctMatrix = shift;
	my $string_matrix_cmp =  sub  {
      $string = shift @_;
      my $studentMatrix;
      $studentMatrix = Matrix(create2d_matrix($string)); die "I give up";
      # main::DEBUG_MESSAGE(ref($studentMatrix). "$studentMatrix with error ");
      # errors are returned as warnings.  Can't seem to trap them.
      my $rh_answer = new AnswerHash(
         score  => ($correctMatrix <=> $studentMatrix)?0:1, #fuzzy equals is zero for correct
	     correct_ans  	=> 	$correctMatrix,
	     student_ans  	=> 	$string,
	     preview_text_string => $string,
	     preview_latex_string => $studentMatrix->TeX,
	     ans_message  => 	"",
	     type		   	=> 	'matrix_from_ans_box',
      );
      $rh_answer;
	};
	$string_matrix_cmp;
}



=head4 zero_check (deprecated -- use MathObjects matrices and vectors)

	# this subroutine zero_check is not very well designed below -- if it is used much it should receive
	# more work -- particularly for checking relative tolerance.  More work needs to be done if this is
	# actually used.

=cut 

sub zero_check{
    my $array = shift;
    my %options = @_;
        my $num = @$array;
        my $i;
        my $max = 0; my $mm;
        for ($i=0; $i< $num; $i++) {
                $mm = $array->[$i] ;
                $max = abs($mm) if abs($mm) > $max;
        }
    my $tol = $options{tol};
    $tol = 0.01*$options{reltol}*$options{avg} if defined($options{reltol}) and defined $options{avg};
    $tol = .000001 unless defined($tol);
        ($max <$tol) ? 1: 0;       # 1 if the array is close to zero;
}

=head4 vec_dot() (deprecated -- use MathObjects vectors and matrices)

sub vec_dot{
        my $vec1 = shift;
        my $vec2 = shift;
        warn "vectors must have the same length" unless @$vec1 == @$vec2;  # the vectors must have the same length.
        my @vec1=@$vec1;
        my @vec2=@$vec2;
        my $sum = 0;

        while(@vec1) {
                $sum += shift(@vec1)*shift(@vec2);
        }
        $sum;
}

=head4 proj_vect (deprecated -- use MathObjects vectors and matrices)

=cut

sub proj_vec {
        my $vec = shift;
        warn "First input must be a column matrix" unless ref($vec) eq 'Matrix' and ${$vec->dim()}[1] == 1;
        my $matrix = shift;    # the matrix represents a set of vectors spanning the linear space
                               # onto which we want to project the vector.
        warn "Second input must be a matrix" unless ref($matrix) eq 'Matrix' and ${$matrix->dim()}[1] == ${$vec->dim()}[0];
        $matrix * transpose($matrix) * $vec;
}

=head4 vec_cmp (deprecated -- use MathObjects vectors and matrices)

=cut


sub vec_cmp{    #check to see that the submitted vector is a non-zero multiple of the correct vector
    my $correct_vector = shift;
    my %options = @_;
        my $ans_eval = sub {
                my $in =  shift @_;

                my $ans_hash = new AnswerHash;
                my @in = split("\0",$in);
                my @correct_vector=@$correct_vector;
                $ans_hash->{student_ans} = "( " . join(", ", @in ) . " )";
                $ans_hash->{correct_ans} = "( " . join(", ", @correct_vector ) . " )";

                return($ans_hash) unless @$correct_vector == @in;  # make sure the vectors are the same dimension

                my $correct_length = vec_dot($correct_vector,$correct_vector);
                my $in_length = vec_dot(\@in,\@in);
                return($ans_hash) if $in_length == 0;

                if (defined($correct_length) and $correct_length != 0) {
                        my $constant = vec_dot($correct_vector,\@in)/$correct_length;
                        my @difference = ();
                        for(my $i=0; $i < @correct_vector; $i++ ) {
                                $difference[$i]=$constant*$correct_vector[$i] - $in[$i];
                        }
                        $ans_hash->{score} = zero_check(\@difference);

                } else {
                        $ans_hash->{score} = 1 if vec_dot(\@in,\@in) == 0;
                }
                $ans_hash;

    };

    $ans_eval;
}


1;
