sub _LiveGraphics3D_init {
	ADD_JS_FILE('node_modules/x3dom/x3dom.js');
	ADD_JS_FILE('node_modules/jszip/dist/jszip.min.js');
	ADD_JS_FILE('node_modules/jszip-utils/dist/jszip-utils.min.js');
	ADD_JS_FILE('js/apps/LiveGraphics/liveGraphics.js');
	ADD_CSS_FILE('node_modules/x3dom/x3dom.css');
}

=head2 LiveGraphics3D.pl

 ###########################################################################
 #
 #   Macros for handling interactive 3D graphics via the LiveGraphics3D
 #   Java applet.  The applet needs to be in the course html directory.
 #   (If it is in the system html area, you will need to change the
 #   default below or supply the jar option explicitly).
 #
 #   The LiveGraphics3D applet displays a mathematica Graphics3D object
 #   that is stored in a .m file (or a compressed one).  Use Mathematica
 #   to create one.  (In the future, I plan to write a perl class that
 #   will create these for you on the fly. -- DPVC)
 #
 #   The main routines are
 #
 #      Live3Dfile          load a data file
 #      Live3Ddata          load raw Graphics3D data
 #      LiveGraphics3D      access to all parameters
 #
 
 #
 #  LiveGraphics3D(options)
 #
 #  Options are from:
 #
 #     file => name           name of .m file to load
 #
 #     archive => name        name of a .zip file to load
 #
 #     input => 3Ddata        string containing Graphics3D data to
 #                            be displayed by the applet
 #
 #     size => [w,h]          width and height of applet
 #
 #     vars => [vars]         hash of variables to pass as independent
 #                            variables to the applet, togther with
 #                            their initial values
 #                              e.g., vars => [a=>1,b=>1]
 #
 #     depend => [list]       list of dependent variables to pass to
 #                            the applet with their replacement strings
 #                            (see LiveGraphics3D documentation)
 #
 #     background=>"#RRGGBB"  the background color to use (default is white)
 #
 #     scale => n             scaling factor for applet (default is 1.)
 #
 #     image => file          a file containing an image to use in TeX mode
 #                            or when Java is disabled
 #
 #     tex_size => ratio      a scaling factor for the TeX image (as a portion
 #                            of the line width).  
 #                                1000 is 100%, 500 is 50%, etc.
 #
 #     tex_center => 0 or 1   center the image in TeX mode or not
 #
 #     Live3D => [params]     hash of additional parameters to pass to
 #                            the Live3D applet.
 #                              e.g. Live3D => [VISIBLE_FACES => "FRONT"]
 #

=cut


sub LiveGraphics3D {
  my %options = (
    size => [250,250],
    background => "#FFFFFF",
    scale => 1.,
    tex_size => 500,
    tex_center => 0,
    @_
  );
  my $out = ""; my $p; my %pval;
  my $ratio = $options{tex_size} * (.001);

  if ($main::displayMode eq "TeX") {
    #
    #  In TeX mode, include the image, if there is one, or
    #   else give the user a message about using it on line
    #
    if ($options{image}) {
      $out = "\\includegraphics[width=$ratio\\linewidth]{$options{image}}";
      $out = "\\centerline{$out}" if $options{tex_center};
      $out .= "\n";
    } else {
      $out = "\\vbox{
         \\hbox{[ This image is created by}
         \\hbox{\\quad an interactive applet;}
         \\hbox{you must view it on line ]}
      }";
    }
    # In html mode check to see if we use javascript or not
  } else {
    my ($w,$h) = @{$options{size}};
    $out .= $bHTML if ($main::displayMode eq "Latex2HTML");
    #
    #  Put the js in a table
    #
    $out .= qq{\n<TABLE BORDER="1" CELLSPACING="2" CELLPADDING="0">\n<TR>};
    $out .= qq{<TD WIDTH="$w" HEIGHT="$h" ALIGN="CENTER">};

    $archive_input = $options{archive} // '';
    $file_input = $options{file} // '';
    $direct_input = $options{input} // '';

    $direct_input =~ s/\n//g;

    #
    #  include any independent variables
    #
    $ind_vars = '{}';
    
    if ($options{vars}) {
	$ind_vars = "{";
	%vars = @{$options{vars}};

	foreach $var (keys %vars ) {
	    $ind_vars .= "\"$var\":\"".$vars{$var}."\",";
	}
	
	$ind_vars .= "}";
    }
    
    $out .= <<EOS;
    <script>
    var thisTD = jQuery('script:last').parent();
    var options = { width : $w,
		    height : $h,
		    file : '$file_input',
		    input : '$direct_input',
		    archive : '$archive_input',
		    vars : $ind_vars,
    };

    if (typeof LiveGraphics3D !== 'undefined') {
        var graph = new LiveGraphics3D(thisTD[0],options);
    }

    </script>
EOS



    $out .= "</TD></TD>\n</TABLE>\n";
    $out .= $eHTML if ($main::displayMode eq "Latex2HTML");
    # otherwise use the applet
  }

  return $out;
}

#
#  Syntactic sugar to make it easier to pass files and data to
#  LiveGraphics3D.
#
sub Live3Dfile {
  my $file = shift;
  LiveGraphics3D(file => $file, @_);
}

#
#  Syntactic sugar to make it easier to pass raw Graohics3D data
#  to LiveGraphics3D.
#
sub Live3Ddata {
  my $data = shift;
  LiveGraphics3D(input => $data, @_);
}


#
#  A message you can use for a caption under a graph
#
$LIVEMESSAGE = MODES(
  TeX => '',
  Latex2HTML =>
     $BCENTER.$BSMALL."Drag the surface to rotate it".$ESMALL.$ECENTER,
  HTML => $BCENTER.$BSMALL."Drag the surface to rotate it".$ESMALL.$ECENTER
);

1;
