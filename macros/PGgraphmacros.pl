

=head1 NAME

	PGgraphmacros -- in courseScripts directory

=head1 SYNPOSIS


#		use Fun;
#		use Label;
#		use Circle;
#		use WWPlot;

=head1 DESCRIPTION

This collection of macros provides easy access to the facilities provided by the graph
module WWPlot and the modules for objects which can be drawn on a graph: functions (Fun.pm)
labels (Label.pm) and images.  The only images implemented currently are open and closed circles
(Circle) which can be used to mark graphs of functions defined on open and closed intervals.

These macros provide an easy ability to graph simple functions.  More complicated projects
may require direct access to the underlying modules.  If these complicated projects are common
then it may be desirable to create additional macros.  (See numericalmacros.pl for one example.)


=cut

=head2 Other constructs

See F<PGbasicmacros> for definitions of C<image> and C<caption>

=cut


#my $User = $main::studentLogin;
#my $psvn = $main::psvn; #$main::in{'probSetKey'};  #in{'probSetNumber'}; #$main::probSetNumber;
#my $setNumber     = $main::setNumber;
#my $probNum       = $main::probNum;

#########################################################
# this initializes a graph object
#########################################################
# graphObject = init_graph(xmin,ymin,xmax,ymax,options)
# options include  'grid' =>[8,8] or
#				   'ticks'=>[8,8] and/or
#                  'axes'
#########################################################

#loadMacros("MathObjects.pl");   # avoid loading the entire package
                                 # of MathObjects since that can mess up 
                                 # problems that don't use MathObjects but use Matrices.

my %images_created = ();  # this keeps track of the base names of the images created during this session.
                     #  We tack on
                     # $imageNum  = ++$images_created{$imageName} to keep from overwriting files
                     # when we don't want to.




=head2 init_graph

=pod

		$graphObject = init_graph(xmin,ymin,xmax,ymax,'ticks'=>[4,4],'axes'=>[0,0])
		options are
			'grid' =>[8,8] or
			# there are 8 evenly spaced lines intersecting the horizontal axis
			'ticks'=>[8,8] and/or
			# there are 8 ticks on the horizontal axis, 8 on the vertical
			'axes' => [0,0]
			# axes pass through the point (0,0) in real coordinates
			'size' => [200,200]
			# dimensions of the graph in pixels.
			'pixels' =>[200,200]  # synonym for size

Creates a graph object with the default size 200 by 200 pixels.
If you want axes or grids you need to specify them in options. But the default values can be selected for you.


=cut
BEGIN {
	be_strict();
}
sub _PGgraphmacros_init {


}
#sub _PGgraphmacros_export {
#
#	my @EXPORT = (
#		'&init_graph', '&add_functions', '&plot_functions', '&open_circle',
#		'&closed_circle', '&my_math_constants', '&string_to_sub',
#    );
#    @EXPORT;
#}

sub init_graph {
	my ($xmin,$ymin,$xmax,$ymax,%options) = @_;
	my @size;
	if ( defined($options{'size'}) ) {
		@size = @{$options{'size'}};
	}	elsif ( defined($options{'pixels'}) ) {
		@size = @{$options{'pixels'}};
	}   else {
		my $defaultSize = $main::envir{onTheFlyImageSize} || 200;
		@size=($defaultSize,  $defaultSize);
	}
    my $graphRef = new WWPlot(@size);
	# select a  name for this graph based on the user, the psvn and the problem
	my $setName = $main::setNumber;
	# replace dots, commmas and @ signs in set and user names to keep latex and html happy
	# this should be abstracted and placed in PGalias.pm or PGcore.pm or perhaps PG.pm
	#FIXME
	$setName =~ s/Q/QQ/g;
	$setName =~ s/\./-Q-/g;
	my $studentLogin = $main::studentLogin;
	$studentLogin =~ s/Q/QQ/g;
	$studentLogin =~ s/\./-Q-/g;
	$studentLogin =~ s/\,/-Q-/g;
	$studentLogin =~ s/\@/-Q-/g;
	my $imageName = "$studentLogin-$main::problemSeed-set${setName}prob${main::probNum}";
	# $imageNum counts the number of graphs with this name which have been created since PGgraphmacros.pl was initiated.
	my $imageNum  = ++$main::images_created{$imageName};
	# this provides a unique name for the graph -- it does not include an extension.
	$graphRef->imageName("${imageName}image${imageNum}");

	$graphRef->xmin($xmin) if defined($xmin);
	$graphRef->xmax($xmax) if defined($xmax);
	$graphRef->ymin($ymin) if defined($ymin);
	$graphRef->ymax($ymax) if defined($ymax);
	my $x_delta = ($graphRef->xmax -  $graphRef->xmin)/8;
	my $y_delta = ($graphRef->ymax -  $graphRef->ymin)/8;
	if (defined($options{grid})) {   #   draw grid
	    my $xdiv = ( ${$options{'grid'}}[0]) ? ${$options{'grid'}}[0] : 8; # number of ticks (8 is default)
	    my $ydiv = ( ${$options{'grid'}}[1] )  ? ${$options{'grid'}}[1] : 8;
		my $x_delta = ($graphRef->xmax -  $graphRef->xmin)/$xdiv;
	    my $y_delta = ($graphRef->ymax -  $graphRef->ymin)/$ydiv;
	    my $i; my @x_values=(); my @y_values=();
	    foreach $i (1..($xdiv-1) ) {
	    	push( @x_values, $i*$x_delta+$graphRef->{xmin});
	    }
	    foreach $i (1..($ydiv-1) ) {
	    	push( @y_values, $i*$y_delta+$graphRef->{ymin});
	    }
		$graphRef->v_grid('gray',@x_values);
		$graphRef->h_grid('gray',@y_values);
		$graphRef->lb(new Label($x_delta,0,sprintf("%1.1f",$x_delta),'black','center','middle'));
		$graphRef->lb(new Label(0,$y_delta,sprintf("%1.1f",$y_delta),'black','center','middle'));

		$graphRef->lb(new Label($xmax,0,$xmax,'black','right'));
		$graphRef->lb(new Label($xmin,0,$xmin,'black','left'));
		$graphRef->lb(new Label(0,$ymax,$ymax,'black','top'));
		$graphRef->lb(new Label(0,$ymin,$ymin,'black','bottom','right'));

	} elsif ($options{ticks}) {   #   draw ticks -- grid over rides ticks
		my $xdiv = ${$options{ticks}}[0]? ${$options{ticks}}[0] : 8; # number of ticks (8 is default)
	        my $ydiv = ${$options{ticks}}[1]? ${$options{ticks}}[1] : 8;
		my $x_delta = ($graphRef->xmax -  $graphRef->xmin)/$xdiv;
	        my $y_delta = ($graphRef->ymax -  $graphRef->ymin)/$ydiv;
	        my $i; my @x_values=(); my @y_values=();
	    foreach $i (1..($xdiv-1) ) {
	    	push( @x_values, $i*$x_delta+$graphRef->{xmin});
	    }
	    foreach $i (1..($ydiv-1) ) {
	    	push( @y_values, $i*$y_delta+$graphRef->{ymin});
	    }
		$graphRef->h_ticks(0,'black',@x_values);
		$graphRef->v_ticks(0,'black',@y_values);
		$graphRef->lb(new Label($x_delta,0,$x_delta,'black','right'));
		$graphRef->lb(new Label(0,$y_delta,$y_delta,'black','top'));

		$graphRef->lb(new Label($xmax,0,$xmax,'black','right'));
		$graphRef->lb(new Label($xmin,0,$xmin,'black','left'));
		$graphRef->lb(new Label(0,$ymax,$ymax,'black','top'));
		$graphRef->lb(new Label(0,$ymin,$ymin,'black','bottom','right'));
	}

	if ($options{axes}) {   #   draw axis
	    my $ra_axes = $options{axes};
		$graphRef->h_axis($ra_axes->[1],'black');
		$graphRef->v_axis($ra_axes->[0],'black');
	}


	$graphRef;
}

sub init_graph_no_labels {
	my ($xmin,$ymin,$xmax,$ymax,%options) = @_;
	my @size;
	if ( defined($options{'size'}) ) {
		@size = @{$options{'size'}};
	}	elsif ( defined($options{'pixels'}) ) {
		@size = @{$options{'pixels'}};
	}   else {
		my $defaultSize = $main::envir{onTheFlyImageSize} || 200;
		@size=($defaultSize,  $defaultSize);
	}
    my $graphRef = new WWPlot(@size);
	# select a  name for this graph based on the user, the psvn and the problem
	my $imageName = "$main::studentLogin-$main::psvn-set${main::setNumber}prob${main::probNum}";
	# $imageNum counts the number of graphs with this name which have been created since PGgraphmacros.pl was initiated.
	my $imageNum  = ++$main::images_created{$imageName};
	# this provides a unique name for the graph -- it does not include an extension.
	$graphRef->imageName("${imageName}image${imageNum}");

	$graphRef->xmin($xmin) if defined($xmin);
	$graphRef->xmax($xmax) if defined($xmax);
	$graphRef->ymin($ymin) if defined($ymin);
	$graphRef->ymax($ymax) if defined($ymax);
	my $x_delta = ($graphRef->xmax -  $graphRef->xmin)/8;
	my $y_delta = ($graphRef->ymax -  $graphRef->ymin)/8;
	if (defined($options{grid})) {   #   draw grid
	    my $xdiv = ( ${$options{'grid'}}[0]) ? ${$options{'grid'}}[0] : 8; # number of ticks (8 is default)
	    my $ydiv = ( ${$options{'grid'}}[1] )  ? ${$options{'grid'}}[1] : 8;
		my $x_delta = ($graphRef->xmax -  $graphRef->xmin)/$xdiv;
	    my $y_delta = ($graphRef->ymax -  $graphRef->ymin)/$ydiv;
	    my $i; my @x_values=(); my @y_values=();
	    foreach $i (1..($xdiv-1) ) {
	    	push( @x_values, $i*$x_delta+$graphRef->{xmin});
	    }
	    foreach $i (1..($ydiv-1) ) {
	    	push( @y_values, $i*$y_delta+$graphRef->{ymin});
	    }
		$graphRef->v_grid('gray',@x_values);
		$graphRef->h_grid('gray',@y_values);
		#$graphRef->lb(new Label($x_delta,0,sprintf("%1.1f",$x_delta),'black','center','top'));
		#$graphRef->lb(new Label($x_delta,0,"|",'black','center','middle'));
		#$graphRef->lb(new Label(0,$y_delta,sprintf("%1.1f ",$y_delta),'black','right','middle'));
		#$graphRef->lb(new Label(0,$y_delta,"-",'black','center','middle'));


		$graphRef->lb(new Label($xmax,0,$xmax,'black','right'));
		$graphRef->lb(new Label($xmin,0,$xmin,'black','left'));
		$graphRef->lb(new Label(0,$ymax,$ymax,'black','top','right'));
		$graphRef->lb(new Label(0,$ymin,$ymin,'black','bottom','right'));

	} elsif ($options{ticks}) {   #   draw ticks -- grid over rides ticks
		my $xdiv = ${$options{ticks}}[0]? ${$options{ticks}}[0] : 8; # number of ticks (8 is default)
	        my $ydiv = ${$options{ticks}}[1]? ${$options{ticks}}[1] : 8;
		my $x_delta = ($graphRef->xmax -  $graphRef->xmin)/$xdiv;
	        my $y_delta = ($graphRef->ymax -  $graphRef->ymin)/$ydiv;
	        my $i; my @x_values=(); my @y_values=();
	    foreach $i (1..($xdiv-1) ) {
	    	push( @x_values, $i*$x_delta+$graphRef->{xmin});
	    }
	    foreach $i (1..($ydiv-1) ) {
	    	push( @y_values, $i*$y_delta+$graphRef->{ymin});
	    }
		$graphRef->v_ticks(0,'black',@x_values);
		$graphRef->h_ticks(0,'black',@y_values);
		$graphRef->lb(new Label($x_delta,0,$x_delta,'black','right'));
		$graphRef->lb(new Label(0,$y_delta,$y_delta,'black','top'));

		$graphRef->lb(new Label($xmax,0,$xmax,'black','right'));
		$graphRef->lb(new Label($xmin,0,$xmin,'black','left'));
		$graphRef->lb(new Label(0,$ymax,$ymax,'black','top'));
		$graphRef->lb(new Label(0,$ymin,$ymin,'black','bottom','right'));
	}

	if ($options{axes}) {   #   draw axis
	    my $ra_axes = $options{axes};
		$graphRef->h_axis($ra_axes->[1],'black');
		$graphRef->v_axis($ra_axes->[0],'black');
	}


	$graphRef;
}



=head2  plot_functions

=pod

	Usage:  ($f1, $f2, $f3) = plot_functions($graph, $f1, $f2, $f3);
	Synonym: add_functions($graph,$f1,$f2,$f3);

Where $f1 is a string of the form

	$f1 = qq! x^2 - 3*x + 45 for x in [0, 45) using color:red and weight:2!

The phrase translates as: formula    B<for> variable B<in>  interval B<using>   option-list.
The option-list contains pairs of the form attribute:value.
The default for color is "default_color" which is usually black.
The default for the weight (pixel width) of the pen is 2 pixels.

The string_to_sub subroutine is used to translate the formula into a subroutine.

The functions in the list are installed in the graph object $graph and will appear when the graph object is next drawn.

=cut

sub add_functions {
	&plot_functions;
}

sub plot_functions {
	my $graph = shift;
	my @function_list = @_;
	my $error = "";
	$error .= "The first argument to plot_functions must be a graph object" unless ref($graph) =~/WWPlot/;
	my $fn;
	my @functions=();
	foreach $fn (@function_list) {

	    # model:   "2.5-x^2 for x in <-1,0> using color:red and weight:2"
		if ($fn =~ /^(.+)for\s*(\w+)\s*in\s*([\(\[\<])\s*([\d\.\-]+)\s*,\s*([\d\.\-]+)\s*([\)\]\>])\s*using\s*(.*)$/ )  {
			my ($rule,$var, $left_br, $left_end, $right_end, $right_br, $options)=  ($1, $2, $3, $4, $5, $6, $7);

			my %options = split( /\s*and\s*|\s*:\s*|\s*,\s*|\s*=\s*|\s+/,$options);
			my ($color, $weight);
			if ( defined($options{'color'})  ){
				$color = $options{'color'}; #set pen color
			}	else {
				$color = 'default_color';
			}
			if ( defined($options{'weight'}) ) {
				$weight = $options{'weight'}; # set pen weight (width in pixels)
			} else {
				$weight =2;
			}
			# a workaround to call Parser code without loading MathObjects.
			my $localContext= Parser::Context->current(\%main::context)->copy;
			$localContext->variables->add($var=>'Real') unless $localContext->variables->get($var);
			my $formula = Value->Package("Formula()")->new($localContext,$rule)->perlFunction(undef,[$var]);
			my $subRef = sub {
			  my $x = shift;
			  my $y = Parser::Eval($formula,$x);  # traps errors, e.g. graph domain is larger than
			  				      #  the function's domain.
			  $y = $y->value if defined $y;
			  return $y;
			};
        	#my $subRef    = string_to_sub($rule,$var);
			my $funRef = new Fun($subRef,$graph);
			$funRef->color($color);
			$funRef->weight($weight);
			$funRef->domain($left_end , $right_end);
			push(@functions,$funRef);
		    # place open (1,3) or closed (1,3) circle at the endpoints or do nothing <1,3>
		    if ($left_br eq '[' ) {
		    	$graph->stamps(closed_circle($left_end,&$subRef($left_end),$color) );
		    } elsif ($left_br eq '(' ) {
		    	$graph->stamps(open_circle($left_end, &$subRef($left_end), $color) );
		    }
		    if ($right_br eq ']' ) {
		    	$graph->stamps(closed_circle($right_end,&$subRef($right_end),$color) );
		    } elsif ($right_br eq ')' ) {
		    	$graph->stamps(open_circle($right_end, &$subRef($right_end), $color) );
		    }

		} else {
			$error .= "Error in parsing: $fn $main::BR";
		}

	}
	die ("Error in plot_functions: \n\t $error ") if $error;
	@functions;   # return function references unless there is an error.
}




=head2 insertGraph

	$filePath = insertGraph(graphObject);
		  returns a path to the file containing the graph image.

B<Note:> insertGraph is defined in PGcore.pl, because it involves writing to the disk.

insertGraph(graphObject) writes a image file to the C<html/tmp/gif> directory of the current course.
The file name is obtained from the graphObject.  Warnings are issued if errors occur while writing to
the file.

The permissions and ownership of the file are controlled by C<$main::tmp_file_permission>
and C<$main::numericalGroupID>.

B<Returns:>   A string containing the full path to the temporary file containing the  image.



InsertGraph draws the object $graph, stores it in "${tempDirectory}gif/$imageName.gif (or .png)" where
the $imageName is obtained from the graph object.  ConvertPath and surePathToTmpFile are used to insure
that the correct directory separators are used for the platform and that the necessary directories
are created if they are not already present.  The directory address to the file is the result.

The most common use of C,insertGraph> is

	TEXT(image(insertGraph($graph)) );

where C<image> takes care of creating the proper URL for accessing the graph and for creating the HTML code to display the image.

Another common usage is:

	TEXT(htmlLink( alias(insertGraph($graph), "picture" ) ) );

which inserts the URL pointing to the picture.

alias() converts the directory address to a URL when serving HTML pages and insures that
an eps file is generated when creating TeX code for downloading. (Image, automatically applies alias to its input 
in order to obtain the URL.)

See the documentation in F<PGcore.pl> for the latest details.

=cut

=head2  'Circle' lables

	Usage: $circle_object = open_circle( $x_position, $y_position, $color );
	        $circle_object2 = closed_circle( $x_position, $y_position, $color );

Creates a small open (resp. filled in or closed) circle for use as a stamp in marking graphs.
For example

	$graph -> stamps($circle_object2); # puts a filled dot at $x_position, $y_position

=cut

#########################################################
sub open_circle {
    my ($cx,$cy,$color) = @_;
	new Circle ($cx, $cy, 4,$color,'nearwhite');
}

sub closed_circle {
    my ($cx,$cy, $color) = @_;
    $color = 'black' unless defined $color;
	new Circle ($cx, $cy, 4,$color, $color);
}


=head2 Auxiliary macros

=head3  string_to_sub and my_math_constants


These are internal macros which govern the interpretation of equations.


	Usage: $string = my_math_constants($string)
	       $subroutine_reference = my_string_to_sub($string)

C<my_math_constants>
interprets pi, e  as mathematical constants 3.1415926... and 2.71828... respectively. (Case is important).
The power operator ^ is replaced by ** to conform with perl constructs

C<string_to_sub>
converts a string defining a single perl arithmetic expression with independent variable $XVAR into a subroutine.
The string is first filtered through C<my_math_macros>. The resulting subroutine
takes a single real number as input and produces a single output value.

=cut

sub my_math_constants {
	my($in) = @_;
	$in =~s/\bpi\b/(4*atan2(1,1))/g;
	$in =~s/\be\b/(exp(1))/g;
	$in =~s/\^/**/g;
	$in;
}

sub string_to_sub {
	my $str_in = shift;
	my $var    = shift;
	my $out = undef;
	if ( defined(&check_syntax)  ) {
		#prepare the correct answer and check it's syntax
	    my $rh_correct_ans = new AnswerHash;
		$rh_correct_ans->input($str_in);
		$rh_correct_ans = check_syntax($rh_correct_ans);
 		warn  $rh_correct_ans->{error_message} if $rh_correct_ans->{error_flag};
 		$rh_correct_ans->clear_error();
 		$rh_correct_ans = function_from_string2($rh_correct_ans, ra_vars => ['x'], store_in =>'rf_correct_ans');
 		my $correct_eqn_sub = $rh_correct_ans->{rf_correct_ans};
 		warn $rh_correct_ans->{error_message} if $rh_correct_ans->{error_flag};
		$out = sub{ scalar( &$correct_eqn_sub(@_) ) };  #ignore the error messages from the function.

	} else {
		my $in =$str_in;

		$in =~ s/\b$var\b/\$XVAR/g;
		$in = &my_math_constants($in);
		my ($subRef, $PG_eval_errors,$PG_full_error_report) = PG_restricted_eval( " sub { my \$XVAR = shift; my \$out = $in; \$out; } ");
		if ($PG_eval_errors) {
			die " ERROR while defining a function from the string:\n\n$main::BR $main::BR $str_in $main::BR $main::BR\n\n  $PG_eval_errors"
		} else {
			$out = $subRef;
		}

	}
	$out;
}

#########################################################

1;
