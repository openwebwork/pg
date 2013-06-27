
#  this module holds the graph.  Several functions
#  and labels may be plotted on
#  the graph.

# constructor   new WWPlot(300,400) constructs an image of width 300 by height 400 pixels
# plot->imageName gives the image's name


=head1 NAME

	WWPlot

=head1 SYNPOSIS

    use Global;
	use Carp;
	use GD;
	use SVG

	$graph = new WWPlot(400,400); # creates a graph 400 pixels by 400 pixels
	$graph->fn($fun1, $fun2);     # installs functions $fun1 and $fun2 in $graph
	$image_binary = $graph->draw();  # creates the gif/png or SVG image of the functions installed in the graph

=head1 DESCRIPTION

This module creates a graph object -- a canvas on which to draw functions, labels, and other symbols.
The graph can be drawn with an axis, with a grid, and/or with an axis with tick marks.
The position of the axes and the granularity of the grid and tick marks can be specified.

=head2 new

	$graph = new WWPlot(400,400);

Creates a graph object 400 pixels by 400 pixels.  The size is required.




=head2 Methods and properties

=over 4

=item xmin, xmax, ymin, ymax

These determine the world co-ordinates of the graph. The constructions

	$new_xmin = $graph->xmin($new_xmin);
and
	$current_xmin = $graph->xmin();

set and read the values.

=item fn, lb, stamps

These arrays contain references to the functions (fn), the labels (lb) and the stamped images (stamps) such
as open or closed circles which will drawn when the graph is asked to draw itself. Since each of these
objects is expected to draw itself, there is not a strong difference between the different arrays of objects.
The principle difference is the order in which they are drawn.  The axis and grids are drawn first, followed
by the functions, then the labels, then the stamps.

You can add a function with either of the commands

	@fn = $graph->fn($new_fun_ref1, $new_fun_ref2);
	@fn = $graph->install($new_fun_ref1, $new_fun_ref2);

the constructions for labels and stamps are respectively:

	@labels = $graph->lb($new_label);
	@stamps = $graph->stamps($new_stamp);

while

	@functions = $graph->fn();

will give a list of the current functions (similary for labels and stamps).

Either of the  commands

	$graph->fn('reset');
	$graph->fn('erase');

will erase the array containing the functions and similary for the label and stamps arrays.


=item h_axis, v_axis

	$h_axis_coordinate = $graph -> h_axis();
	$new_axis    =       $grpah -> h_axis($new_axis);

Respectively read and set the vertical coordinate value in real world coordinates where the
horizontal axis intersects the vertical one.  The same construction reads and sets the coordinate
value for the vertical axis. The axis is drawn more darkly than the grids.

=item h_ticks, v_ticks

	@h_ticks = $graph -> h_ticks();
	@h_ticks = $graph -> h_ticks( $tick1, $tick2, $tick3, $tick4   );

reads and sets the coordinates for the tick marks along the horizontal axis.  The values
$tick1, etc are the real world coordinate values for each of the tick marks.

=item h_grid, v_grid

	@h_grid = $graph -> h_grid();
	@h_grid = $graph -> h_grid( $grid1, $grid2, $grid3, $grid4   );

reads and sets the verical coordinates for the horizontal grid lines.  The values
$grid1, etc are the real world coordinate values where the horizontal grid meets the
vertical axis.

=item draw

	$image = $graph ->draw();

Draws the  image of the graph.

=item size

	($horizontal_pixels, $vertical_pixels) = @{$graph ->size()};

Reads the size of the graph image in pixels.  This cannot be reset. It is defined by
the new constructor and cannot be changed.

=item colors

	%colors =$graph->colors();

Returns the hash containing the colors known to the graph.  The keys are the names of the
colors and the values are the color indices used by the graph.

=item new_color

	$graph->new_color('white', 255,255,255);

defines a new color named white with red, green and blue densities 255.

=item im

	$GD_image = $graph->im();

Allows access to the GD image object contained in the graph object.  You can use this
to access methods defined in GD but not supported directly by WWPlot. (See the documentation
for GD.)

=item moveTo, lineTo, arrowTo

	$graph->moveTo($x,$y);
	$graph->lineTo($x,$y,$color);
  	$graph->lineTo($x,$y,$color,$thickness);
  	$graph->lineTo($x,$y,$color,$thickness,'dashed');
  	$graph->arrowTo($x,$y,$color);
  	$graph->arrowTo($x,$y,$color,$thickness);
  	$graph->arrowTo($x,$y,$color,$thickness,'dashed');

Moves to the point ($x, $y) (defined in real world coordinates) or draws a line or arrow
from the current position to the specified point ($x, $y) using the color $color.  $color 
is the name, e.g. 'white',  of the color, not an index value or RGB specification.  
$thickness gives the thickness of the line or arrow to draw.  If 'dashed' is specified,
the line or arrow is rendered with a dashed line.  These are low level call 
back routines used by the function, label and stamp objects to draw themselves.


=item ii, jj

These functions translate from real world to pixel coordinates.

	$pixels_down_from_top = $graph -> jj($y);


=back

=cut

BEGIN {
	be_strict(); # an alias for use strict.  This means that all global variable must contain main:: as a prefix.
}

package WWPlot;


#use Exporter;
#use DynaLoader;
#use GD;
#use PGcore;

@WWPlot::ISA=undef;
$WWPlot::AUTOLOAD = undef;

@WWPlot::ISA = qw(GD PGcore SVG);


if ( $GD::VERSION > '1.20' ) {
    	$WWPlot::use_png = 1;  # in version 1.20 and later of GD, gif's are not supported by png files are
    	                       # This only affects the draw method.
} else {
    	$WWPlot::use_png = 0;
}

my	$last_image_number=0;    #class variable.  Keeps track of how many images have been made.



my %fields = (  # initialization only!!!
	xmin   		=>  -1,
	xmax   		=>  1,
	ymin   		=>  -1,
	ymax   		=>  1,
	imageName	=>	undef,
	name        =>  undef,
	position	=>  undef,  #used internally in the draw routine lineTo
);



sub new {
	my $class =shift;
#	my (@size, $graphicsMode) = @_;   # the dimensions in pixels of the image, and the graphicsMode
	my ($width, $height, $graphicsMode) = @_;   # the dimensions in pixels of the image, and the graphicsMode
	my @size=($width, $height);
#warn "graphicsMode = |$graphicsMode|";
	my $self = { im 		=> 	new GD::Image(@size),
				svg			=>      new SVG (width => $size[0], height => $size[1]),
				type 		=>	$graphicsMode, # 'file' or 'svgInteractive'
				'_permitted'	=>	\%fields,
				%fields,
#				size		=>	[@size],
				size		=>	[$width,$height],
				canvas		=>  undef(),
				fn			=>	[],
				vectorfields => [],
				fillRegion      =>      [],
				lb			=>	[],
				stamps		=>	[],
				bars        =>  [],
#				colors 		=>	{},
				colors 		=>	{
								background_color => "white",   #background_color => [255,255,255],
								default_color => "black",      #default_color => [0,0,0],
								white => "white",              #white => [255,255,255],
								black => "black",              #black => [0,0,0],
								red => "red",                  #red => [255,0,0],
								green => "green",              #green => [0,255,0],
								blue => "blue",                #blue => [0,0,255],
								yellow => "yellow",            #yellow => [255,255,0],
								orange => "orange",            #orange => [255,100,0],			
								gray => "gray",                #gray => [180,180,180],
								nearwhite => "nearwhite",      #nearWhite => [254,254,254],
							},
				colors_rgb	=> {
								background_color => [255,255,255],
								default_color => [0,0,0],
								white => [255,255,255],
								black => [0,0,0],
								red => [255,0,0],
								green => [0,255,0],
								blue => [0,0,255],
								yellow => [255,255,0],
								orange => [255,100,0],			
								gray => [180,180,180],
								nearWhite => [254,254,254],
							},
				position	=>  [0,0],
				hticks		=>  [],
				vticks      =>  [],
				hgrid		=>	[],
				vgrid		=>	[],
				haxis       =>  [],
				vaxis       =>  [],
				imageNumber => ++$last_image_number,  # this is a fallback in case PGgraphics doesn't update the imageNumber;
		};

	bless $self, $class;
	$self ->	_initialize;		
	return $self;
}

# access methods for function list, label list and image
sub fn {
	my $self =	shift;

	if (@_ == 0) {
		# do nothing if input is empty
	} elsif ($_[0] eq 'reset' or $_[0] eq 'erase' ) {
		$self->{fn} = [];
	} else {
		push(@{$self->{fn}},@_) if @_;
	}
	@{$self->{fn}};
}
# access methods for fillRegion list, label list and image
sub fillRegion {
	my $self =	shift;

	if (@_ == 0) {
		# do nothing if input is empty
	} elsif ($_[0] eq 'reset' or $_[0] eq 'erase' ) {
		$self->{fillRegion} = [];
	} else {
		push(@{$self->{fillRegion}},@_) if @_;
	}
	@{$self->{fillRegion}};
}

sub install {  # synonym for  installing a function
	fn(@_);
}

sub lb {
	my $self =	shift;
	if (@_ == 0) {
		# do nothing if input is empty
	} elsif ($_[0] eq 'reset' or $_[0] eq 'erase' ) {
		$self->{lb} = [];
	} else {
		push(@{$self->{lb}},@_) if @_;
	}

	@{$self->{lb}};
}

sub stamps {
	my $self =	shift;
	if (@_ == 0) {
		# do nothing if input is empty
	} elsif ($_[0] eq 'reset' or $_[0] eq 'erase' ) {
		$self->{stamps} = [];
	} else {
		push(@{$self->{stamps}},@_) if @_;
	}

	@{$self->{stamps}};
}

sub bars {
	my $self =	shift;
	if (@_ == 0) {
		# do nothing if input is empty
	} elsif ($_[0] eq 'reset' or $_[0] eq 'erase' ) {
		$self->{bars} = [];
	} else {
		push(@{$self->{bars}},@_) if @_;
	}
	@{$self->{bars}};
}

sub vectorFields {
	my $self =	shift;
	if (@_ == 0) {
		# do nothing if input is empty
	} elsif ($_[0] eq 'reset' or $_[0] eq 'erase' ) {
		$self->{vectorfields} = [];
	} else {
		push(@{$self->{vectorfields}},@_) if @_;
	}
	@{$self->{vectorfields}};
}

sub colors {
	my $self = shift;
	$self -> {colors} ;
}

sub new_color {
	my $self = shift;
	my ($color,$r,$g,$b) = @_;
#	$self->{'colors'}{$color} 	= 	$self->im->colorAllocate($r, $g, $b);
	$self -> {'colors'}{$color} = [$r, $g, $b];
}
sub im {
	my $self = shift;
	$self->{im};
}

sub svg {
	my $self = shift;
	$self -> {svg};
}

#sub imageName {
#	my $self = shift;
#	if (@_) {$self -> {imageName} = shift;}
#	return ($self -> {imageName}) ;
#}

sub gifName {              # This is yields backwards compatibility.
    my $self = shift;
	$self->imageName(@_);
}
sub pngName {              # It is better to use the method imageName.
    my $self = shift;
	$self->imageName(@_);
}
sub size {
	my $self = shift;
	$self ->{size};
}

sub	_initialize {
	my $self 			= shift;
#	    $self->{position}    = [0,0];
#	$self->{width}      = $self->{'size'}[0];    # original height and width tags match pixel dimensions
#	$self->{height}     = $self->{'size'}[1];    # of the image
#	# allocate some colors
	    $self->{'colors_rgb'}->{'background_color'} 	= 	$self->im->colorAllocate(255,255,255);
	    $self->{'colors_rgb'}->{'default_color'} 	= 	$self->im->colorAllocate(0,0,0);
	    $self->{'colors_rgb'}->{'white'} 	= 	$self->im->colorAllocate(255,255,255);
	    $self->{'colors_rgb'}->{'black'} 	= 	$self->im->colorAllocate(0,0,0);
	    $self->{'colors_rgb'}->{'red'} 	= 	$self->im->colorAllocate(255,0,0);
	    $self->{'colors_rgb'}->{'green'}	= 	$self->im->colorAllocate(0,255,0);
	    $self->{'colors_rgb'}->{'blue'} 	= 	$self->im->colorAllocate(0,0,255);
	    $self->{'colors_rgb'}->{'yellow'}	=	$self->im->colorAllocate(255,255,0);
	    $self->{'colors_rgb'}->{'orange'}	=	$self->im->colorAllocate(255,100,0);
	    $self->{'colors_rgb'}->{'gray'}	=	$self->im->colorAllocate(180,180,180);
	    $self->{'colors_rgb'}->{'nearwhite'}	=	$self->im->colorAllocate(254,254,254);
	# obtain an SVG canvas
		$self -> {canvas} = $self -> {svg} -> group(id => "canvas");
}

# reference shapes
# closed circle
# open circle

#	The translation subroutines.

sub ii {
	my $self = shift;
	my $x = shift;
	return undef unless defined($x);
	my $xmax = $self-> xmax ;
	my $xmin = $self-> xmin ;
# 	int( ($x - $xmin)*(@{$self->size}[0]) / ($xmax - $xmin) );
 	int( ($x - $xmin)*(@{$self->size}[0]-1) / ($xmax - $xmin) );
#	If the size is S pixels and the counting of pixels begins at 0,
#	then the last pixel is pixel  S-1 .
}

sub jj {
	my $self = shift;
	my $y = shift;
	return undef unless defined($y);
	my $ymax = $self->ymax;
	my $ymin = $self->ymin;
	#print "ymax=$ymax y=$y ymin=$ymin size=",${$self->size}[1],"<br /><br /><br /><br />";
#	int( ($ymax - $y)*${$self->size}[1]/($ymax-$ymin) );
	int( ($ymax - $y)*(${$self->size}[1]-1)/($ymax-$ymin) );
#	If the size is S pixels and the counting of pixels begins at 0,
#	then the last pixel is pixel  S-1 .
}

#  The move and draw subroutines.  Arguments are in real world coordinates.

sub lineTo {
	my $self = shift;
	my ($x,$y,$color, $w, $d, $parent,$name) = @_;
	$w = 1 if ! defined( $w );
	$d = 0 if ! defined( $d );
	$x=$self->ii($x);
	$y=$self->jj($y);
#	$color = $self->{'colors'}{$color} if $color=~/[A-Za-z]+/ && defined($self->{'colors'}{$color}) ; # colors referenced by name works here.
#	$color = $self->{'colors'}{'default_color'} unless defined($color);
	if ($self -> type eq 'file') {
		$self->im->setThickness( $w );
		my $color_rgb = $self -> {colors_rgb}->{$color};
		if ( $d ) {
			my @dashing = ( $color_rgb )x(4*$w*$w);
			my @spacing = ( GD::gdTransparent )x(3*$w*$w);
			$self->im->setStyle( @dashing, @spacing );
			$self->im->line(@{$self->position},$x,$y,GD::gdStyled);
		} else {
			$self->im->line(@{$self->position},$x,$y,$color_rgb);
		}
		$self->im->setThickness( 1 );
	}
	elsif ($self -> type =~ /svg/ ) {
		my $xStart = ${$self -> position} [0];
		my $yStart = ${$self -> position} [1];
		if (!defined($parent) ) {
			$parent = $self -> {canvas};
		}
		if (${x} != ${xStart} || ${y} != ${yStart}) {
			if ($d) {
				my $dashing = 4*$w*$w;
				my $spacing = 3*$w*$w;
				$parent -> line( id => "line_${name}_${xStart}_${yStart}_${x}_${y}",
					x1 => $xStart, y1 => $yStart,
					x2 => $x, y2 => $y,
					stroke => $color,
					'stroke-width' => $w,
					'stroke-dasharray' => "$dashing,$spacing",
				);
			} else {
				$parent -> line( id => "line_${name}_${xStart}_${yStart}_${x}_${y}",
					x1 => $xStart, y1 => $yStart,
					x2 => $x, y2 => $y,
					stroke => $color,
					'stroke-width' => $w,
				);
			}
		}
	}
#warn "color is $color";
	@{$self->position} = ($x,$y);
}

sub moveTo {
	my $self = shift;
	my $x=shift;
	my $y=shift;
	$x=$self->ii($x);
	$y=$self->jj($y);
	#print "moving to $x,$y<br />";
	@{$self->position} = ( $x,$y );
}

sub arrowTo {
	my $self = shift;
	my ( $x1, $y1, $color, $w, $d, $parent, $name ) = @_;
	$w = 1 if ! defined( $w );
	$d = 0 if ! defined( $d );
	my $width = ( $w == 1 ) ? 2 : $w;
	$x1 = $self->ii($x1);
	$y1 = $self->jj($y1);
#	$color = $self->{'colors'}{$color} if $color=~/[A-Za-z]+/ && defined($self->{'colors'}{$color}) ;
#	$color = $self->{'colors'}{'default_color'} unless defined($color);


	my ($x0, $y0) = @{$self->position};
	my $dx = $x1 - $x0;
	my $dy = $y1 - $y0;
	my $len = sqrt($dx*$dx + $dy*$dy);
	my $ux = $dx/$len;  ## a unit vector in the direction of the arrow
	my $uy = $dy/$len;
	my $px = -1*$uy;    ## a unit vector perpendicular
	my $py = $ux;
	my $hbx = $x1 - 5*$width*$ux;  ## the base of the arrowhead
	my $hby = $y1 - 5*$width*$uy;

	if ($self -> type eq 'file') {
		## set thickness
		$self->im->setThickness($w);
		my $color_rgb = $self -> {colors_rgb}->{$color};
		my $head = new GD::Polygon;
		$head->addPt($x1,$y1);
		$head->addPt($hbx + 2*$width*$px, $hby + 2*$width*$py);
		$head->addPt($hbx - 2*$width*$px, $hby - 2*$width*$py);
		$self->im->filledPolygon( $head, $color_rgb );
		if ( $d ) {
			my @dashing = ( $color_rgb )x(4*$w*$w);
			my @spacing = ( GD::gdTransparent )x(3*$w*$w);
			$self->im->setStyle( @dashing, @spacing );
			$self->im->line( $x0,$y0,$x1,$y1,GD::gdStyled);
		} else {
			$self->im->line( $x0,$y0,$x1,$y1,$color_rgb );
		}
	
		@{$self->position} = ( $x1, $y1 );
	
		## reset thickness
		$self->im->setThickness(1);
	}
	elsif ($self -> type =~ /svg/ ) {
		my $xStart = ${$self -> position} [0];
		my $yStart = ${$self -> position} [1];
		if (!defined($parent) ) {
			$parent = $self -> {canvas};
		}
		if (${x1} != ${xStart} || ${y1} != ${yStart}) {
			my $points = $parent -> get_path(x=>[$x1, $hbx + 2*$width*$px, $hbx - 2*$width*$px],
				y=>[$y1, $hby + 2*$width*$py, $hby - 2*$width,$py], -type => 'polygon');
			$parent -> polygon(%$points, id => "arrowhead_${name}_${x1}_${y1}",
				stroke => $color, fill => $color, stroke_width => $w);
			if ($d) {
				my $dashing = 4*$w*$w;
				my $spacing = 3*$w*$w;
				$parent -> line( id => "line_${name}_${xStart}_${yStart}_${x1}_${y1}",
					x1 => $xStart, y1 => $yStart,
					x2 => $x1, y2 => $y1,
					stroke => $color,
					'stroke-width' => $w,
					'stroke-dasharray' => "$dashing,$spacing",
				);
			} else {
				$parent -> line( id => "line_${name}_${xStart}_${yStart}_${x1}_${y1}",
					x1 => $xStart, y1 => $yStart,
					x2 => $x1, y2 => $y1,
					stroke => $color,
					'stroke-width' => $w,
				);
			}
		}
	}
}


sub v_axis {
	my $self = shift;
	@{$self->{vaxis}}=@_; # y_value, color
}
sub h_axis {
	my $self = shift;
	@{$self->{haxis}}=@_; # x_value, color
}
sub h_ticks {
	my $self = shift;
	my $nudge =2;
	push(@{$self->{hticks}},$nudge,@_); # y-value, color, tick x-values.  see save_image subroutine

}
sub v_ticks {
	my $self = shift;
	my $nudge =2;
	push(@{$self->{vticks}},$nudge,@_); # x-value, color, tick y-values.  see save_image subroutine

}
sub h_grid {
	my $self = shift;
	push(@{$self->{hgrid}}, @_ ); #color,  grid y values
}
sub v_grid {
	my $self = shift;
	push(@{$self->{vgrid}},@_ );  #color, grid x values
}

sub type {
	my $self = shift;
	if (@_) { $self -> {type} = shift; }
	return ( $self -> {type} );
}

sub draw {
	my $self = shift;
	my $out=undef();
	my %colors=%{$self->{colors}};
	if ($self -> type eq 'file') {
		my $im =$self->{'im'};
		my @size = @{$self->size};
		my %colors_rgb = %{$self->{colors_rgb}};
#		my %colors_rgb;
#		$colors_rgb{'white'} = $self -> {'colors_rgb'}-> {'white'};
#		foreach my $key (keys %colors) {
#			$colors_rgb{$key} = $self ->  {'colors_rgb'}-> {$key};
#		}

# make the background transparent and interlaced
#    	$im->transparent($colors_rgb{'white'});
	    $im->interlaced('true');

	    # Put a black frame around the picture
	    $im->rectangle(0,0,$size[0]-1,$size[1]-1,$colors_rgb{'black'});

	    # draw functions   (See later.)

# 	     	foreach my $f ($self->fn) {
# 			#$self->draw_function($f);
# 			$f->draw($self);  # the graph is passed to the function so that the label can call back as needed.
# 		}

	   # and fill the regions
		foreach my $r ($self->fillRegion) {
			my ($x,$y,$color_name) = @{$r};
#			my $color = ${$self->colors_rgb}{$color_name};
#			my $color = $colors{$color_name};
			$self->im->fill($self->ii($x),$self->jj($y),$colors_rgb{$color_name});
		}

 		#draw hticks
 		my $tk;
 		my @ticks = @{$self->{hticks}};
 		if (@ticks) {
	 		my $nudge = shift(@ticks);
	 		my $j     = $self->jj(shift(@ticks));
#	 		my $tk_clr= $self->{'colors_rgb'}{shift(@ticks)};
	 		my $tk_clr= $colors_rgb{shift(@ticks)};

	 		foreach $tk (@ticks) {
	 			$tk = $self->ii($tk);
	 			# print "tk=$tk\n";
	 			$self->im->line($tk,$j+int($nudge),$tk,$j-int($nudge),$tk_clr);
	 		}
	 	}
 		#draw vticks
 		@ticks = @{$self->{vticks}};
 		if (@ticks) {
	 		my $nudge = shift(@ticks);
	 		my $i     = $self->ii(shift(@ticks));
#	 		my $tk_clr= $self->{'colors_rgb'}{shift(@ticks)};
	 		my $tk_clr= $colors_rgb{shift(@ticks)};

	 		foreach $tk (@ticks) {
	 			$tk = $self->jj($tk);
	 			# print "tk=$tk\n";
	 			$self->im->line($i+int($nudge),$tk,$i-int($nudge),$tk,$tk_clr);
	 		}
	 	}
 		#draw vgrid

 		my @grid = @{$self->{vgrid}};
 		if (@grid)  {
	 		my $x_value;
#	 		my $grid_clr= $self->{'colors_rgb'}{shift(@grid)};
	 		my $grid_clr= $colors_rgb{shift(@grid)};

	 		foreach $x_value (@grid) {
	 			$x_value = $self->ii($x_value); # scale
	 			#print "grid_line=$grid_line\n";
	 			$self->im->dashedLine($x_value,0,$x_value,$self->{'size'}[1],$grid_clr);
	 		}
	 	}
 		#draw hgrid
 		@grid = @{$self->{hgrid}};
 		if (@grid) {
#	 		my $grid_clr= $self->{'colors_rgb'}{shift(@grid)};
	 		my $grid_clr= $colors_rgb{shift(@grid)};
	        my $y_value;
	 		foreach $y_value (@grid) {
	 			$y_value = $self->jj($y_value);
	 			#print "y_value=$y_value\n";
	 			#print "width= $self->{width}\n";
	 			$self->im->dashedLine(0,$y_value,$self->{'size'}[0],$y_value,$grid_clr);
	 		}
 		}
 		# draw axes
 		if (defined ${$self->{vaxis}}[0]) {
 			my ($x, $color_name) = @{$self->{vaxis}};
#			my $color = $self->{colors_rgb}{$color_name};
#			my $color = $colors_rgb{$color_name};
			$self->moveTo($x,$self->ymin);
			$self->lineTo($x,$self->ymax,$color_name);
			#print "draw vaxis", @{$self->{vaxis}},"\n";
			#$self->im->line(0,0,300,300,$color);
	 	}
	 	if (defined $self->{haxis}[0]) {
			my ($y, $color_name) = @{$self->{haxis}};
#			my $color = $self->{colors_rgb}{$color_name};
#			my $color = $colors_rgb{$color_name};
			$self->moveTo($self->xmin,$y);
			$self->lineTo($self->xmax,$y,$color_name);
	 	    #print "draw haxis", @{$self->{haxis}},"\n";
		}

		#draw bars
 		foreach my $bar ($self->bars) {
 			$bar -> draw($self,  # the graph is passed to the bar so that the bar can call back as needed.
				(defined($self->{colors_rgb}{$bar->color})) ? $self->{colors_rgb}{$bar->color()} : $self->{colors_rgb}{'default_color'} 
			);
 		}

		# draw functions again

 		foreach my $f ($self->fn) {
 			#$self->draw_function($f);
 			$f->draw($self,   # the graph is passed to the function so that the function can call back as needed.
				(defined($colors_rgb{$f->color})) ? $colors{$f->color()} : $colors{'default_color'} 
			);
 		}

		# draw vector fields
		foreach my $vf ($self -> vectorFields) {
 			$vf->draw($self,   # the graph is passed to the vector field so that the vector field can call back as needed.
				(defined($colors_rgb{$vf->arrow_color})) ? $colors{$vf->arrow_color()} : $colors{'default_color'} ,
				(defined($colors_rgb{$vf->dot_color})) ? $colors{$vf->dot_color()} : $colors{'default_color'} 
			 );
 		}

 		#draw labels
 		my $lb;
 		foreach $lb ($self->lb) {
# 			$lb->draw($self);  # the graph is passed to the label so that the label can call back as needed.
 			$lb->draw($self, # the graph is passed to the label so that the label can call back as needed.
				(defined($colors_rgb{$lb->color})) ? $colors_rgb{$lb->color()} : $colors_rgb{'default_color'} );  
 		}
 		#draw stamps
# 		my $stamp;
 		my $stamp=undef();
 		foreach $stamp ($self->stamps) {
# 			$stamp->draw($self); # the graph is passed to the stamp so that the stamp can call back as needed.
 			$stamp->draw($self, # the graph is passed to the stamp so that the stamp can call back as needed.
					(defined($colors_rgb{$stamp -> border_color})) ? $colors_rgb{$stamp -> border_color} : $colors_rgb{'default_color'},
					(defined($colors_rgb{$stamp -> fill_color})) ? $colors_rgb{$stamp -> fill_color} : $colors_rgb{'nearWhite'}
				);
 		}
#       my $out;     # already defined outside the 'file' and 'svg' blocks.

		# Generate file
        if ($WWPlot::use_png) {
        	$out = $im->png;
        } else {
        	$out = $im->gif;
        }
	}
	elsif ($self -> type() =~ /svg/) {

		# fullSized is the existing SVG;  

		my $svg = $self -> svg;
		
		my $width = ${$self -> {size}} [0] ;
		my $height = ${$self -> {size}} [1] ;

		my $canvas = $self -> {canvas};

		# install colors as names
		my %palette =%{$self->{colors}};
		my %colors;
		foreach my $key (keys %palette) {
			$colors{$key} = $key;
		}
		$colors{'default_color'} = 'black';
		$colors{'background_color'} = 'white';
		$colors{'nearWhite'} = 'whitesmoke';
		

		# Put a black frame around the picture
		
		my $boundary = $canvas -> rectangle(x=>0, y=>0, width => $width-1, height => $height-1, id => 'boundary', 
							fill => 'none' , stroke => 'black', 'stroke-width' => '2');
#		my $boundary = $canvas -> rectangle(x=>0, y=>0, width => 99, height => 99 , id => 'boundary', 
#							style => {fill => 'none' , stroke => 'black', 'stroke-width' => '1'});


		# fill the regions
		my $regions = $canvas -> group( id => 'regions' );
		foreach my $r ($self->fillRegion) {
			my ($x,$y,$color_name) = @{$r};
#			my $color = ${$self->colors}{$color_name};
			my $color = $colors{$color_name};
#			$self->im->fill($self->ii($x),$self->jj($y),$color);
			my $begin = $self->ii($x);
			my $end = $self->jj($y);
			my $distance = $end - $begin; #FIXME  This shoud probably be $end - $begin -1.
			$regions -> rectangle(x=>$begin, y=>$begin, width=>$distance, height=>$height, fill=>$color);
		}

		# draw hticks
 		my @ticks = @{$self->{hticks}};
 		if (@ticks) {
			my $hticks =  $canvas -> group( id => 'hticks');
	 		my $nudge = shift(@ticks);
	 		my $j     = $self->jj(shift(@ticks));
#	 		my $tk_clr= $self->{'colors'}{shift(@ticks)};
	 		my $tk_clr= $colors{shift(@ticks)};

	 		foreach my $tk (@ticks) {
	 			$tk = $self->ii($tk);
	 			# print "tk=$tk\n";
	 			# $self->im->line($tk,$j+int($nudge),$tk,$j-int($nudge),$tk_clr);
				$hticks -> line( x1 => $tk, y1 => $j + int($nudge),
								 x2 => $tk, y2 => $j - int($nudge),
								 stroke => $tk_clr);
	 		}
	 	}

		# draw vticks
 		@ticks = @{$self->{vticks}};
 		if (@ticks) {
			my $vticks = $canvas -> group ( id => 'vticks');
	 		my $nudge = shift(@ticks);
	 		my $i     = $self->ii(shift(@ticks));
#	 		my $tk_clr= $self->{'colors'}{shift(@ticks)};
	 		my $tk_clr= $colors{shift(@ticks)};

	 		foreach my $tk (@ticks) {
	 			$tk = $self->jj($tk);
	 			# print "tk=$tk\n";
	 			# $self->im->line($i+int($nudge),$tk,$i-int($nudge),$tk,$tk_clr);
				$vticks -> line( x1 => $i + int($nudge), y1 => $tk,
								 x2 => $i - int($nudge), y2 => $tk,
								 stroke => $tk_clr);
	 		}
	 	}

		# draw vgrid
 		my @grid = @{$self->{vgrid}};
 		if (@grid)  {
			my $vgrid = $canvas -> group( id => 'vgrid' );
	 		my $x_value=0;
	 		my $grid_clr= $colors{shift(@grid)};

	 		foreach $x_value (@grid) {
	 			$x_value = $self->ii($x_value); # scale
	 			#print "grid_line=$grid_line\n";
#	 			$self->im->dashedLine($x_value,0,$x_value,$self->{'size'}[1],$grid_clr);
				$vgrid -> line( x1 => $x_value, y1 => 0, 
								x2 => $x_value, y2 => $self -> {'size'} [1],
								stroke => $grid_clr, 'stroke-dasharray' => "5,5");
	 		}
	 	}

		# draw hgrid
 		@grid = @{$self->{hgrid}};
 		if (@grid) {
			my $hgrid = $canvas -> group( id => 'hgrid' );
	        my $y_value=0;
	 		my $grid_clr= $colors{shift(@grid)};

	 		foreach $y_value (@grid) {
	 			$y_value = $self->jj($y_value);
#	 			$self->im->dashedLine(0,$y_value,$self->{'size'}[0],$y_value,$grid_clr);
				$hgrid -> line( x1 => 0, y1 => $y_value, 
								x2 => $self->{'size'} [0], y2 => $y_value,
								stroke => $grid_clr, 'stroke-dasharray' => "5,5");
	 		}
 		}

		# draw axes
		if (defined ${$self->{vaxis}}[0] or defined ${$self -> {haxis}} [0]) {
			my $axes = $canvas -> group( id => 'axes' );
			if (defined ${$self->{vaxis}}[0]) {
 				my ($x, $color_name) = @{$self->{vaxis}};
				$self->moveTo($x,$self->ymin);
				$self->lineTo($x,$self->ymax,$color_name, undef(), undef(),$axes);
	 		}
	 		if (defined $self->{haxis}[0]) {
				my ($y, $color_name) = @{$self->{haxis}};
				$self->moveTo($self->xmin,$y);
				$self->lineTo($self->xmax,$y,$color_name, undef(), undef(), $axes);
			}
		}

 
 		#draw bars
		my $bars = $canvas -> group ( id => 'bars' );
  		foreach my $bar ($self->bars) {
  			$bar -> draw($self,   # the graph is passed to the bar so that the bar can call back as needed.
				(defined($colors{$bar->color})) ? $colors{$bar->color()} : $colors{'default_color'} ,
				$bars );

  		}
 


		# draw functions
		my $functions = $canvas -> group ( id => 'functions' );
		foreach my $f ($self -> fn) {
 			$f->draw($self,   # the graph is passed to the function so that the function can call back as needed.
				(defined($colors{$f->color})) ? $colors{$f->color()} : $colors{'default_color'} ,
				$functions );
 		}

		# draw vector fields
		my $vector_fields = $canvas -> group ( id => 'vector_fields' );
		foreach my $vf ($self -> vectorFields) {
 			$vf->draw($self,   # the graph is passed to the vector field so that the vector field can call back as needed.
				(defined($colors{$vf->arrow_color})) ? $colors{$vf->arrow_color()} : $colors{'default_color'} ,
				(defined($colors{$vf->dot_color})) ? $colors{$vf->dot_color()} : $colors{'default_color'} ,
				$vector_fields );
 		}


		# draw labels
#		if (defined ${@{$self -> lb}} [0]) {
			my $labels = $canvas -> group( id => 'labels' );
			foreach my $lb ($self->lb) {
				$lb->draw($self, # the graph is passed to the label so that the label can call back as needed.
					(defined($colors{$lb->color})) ? $colors{$lb->color()} : $colors{'default_color'}, 
					$labels );  
			}		
#		}

		# draw stamps
		my $stamps = $canvas -> group( id => 'stamps' );
 		foreach my $stamp ($self->stamps) {
 			$stamp->draw($self, # the graph is passed to the label so that the label can call back as needed.
					(defined($colors{$stamp -> border_color})) ? $colors{$stamp -> border_color} : $colors{'default_color'},
					(defined($colors{$stamp -> fill_color})) ? $colors{$stamp -> fill_color} : $colors{'nearWhite'},
					$stamps,
				);
		}


		my $viewboxWidth = $width ;
		my $viewboxHeight = $height ;

		if ($self -> type() eq 'svgInteractive') {
#			$self -> {'fullSized'} = MIME::Base64::encode_base64(
#				   qq!<svg height="$viewboxHeight" width="$viewboxWidth" viewBox="0 0 $viewboxWidth $viewboxHeight" preserveAspectRatio="none" \n
#					xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> \n !
#				. $canvas -> xmlify
#				. "\n</svg> \n"
#				);
#			$self -> {'fullSized'} =  $svg -> xmlify();
			$self -> {'fullSized'} =  
				   qq!<svg height="800" width="800" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> \n !
				. $canvas -> xmlify
				. "\n</svg>";
#			$self -> {'fullSized'} =~ s/</\&lt;/g;
#			$self -> {'fullSized'} =~ s/>/\&gt;/g;
			$self -> {'fullSized'} =~ s/^/+'/gm;
			$self -> {'fullSized'} =~ s/$/'/gm;
			$self -> {'fullSized'} = qq!'' ! . $self->{'fullSized'};
			$self -> {'fullSized'} .= ";\n";
			$self -> {'thumbnailSized'} = 
				   qq!<svg height="100" width="100" viewBox="0 0 $viewboxWidth $viewboxHeight" preserveAspectRatio="none" \n
					xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> \n !
				. $canvas -> xmlify
				. "\n</svg> \n";
		}
		elsif ( $self -> type() eq 'svgNonInteractive') {
			$self -> {'fullSized'} = 
				   qq!<svg height="$viewboxHeight" width="$viewboxWidth" viewBox="0 0 $viewboxWidth $viewboxHeight" preserveAspectRatio="none" \n
					xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> \n !
				. $canvas -> xmlify
				. "\n</svg> \n";
		}
	}
	else {
		$out = 'ERROR: Unknown graphicsMode: ' . $self->type();
	}
	$out;
}



#sub AUTOLOAD {
#	my $self = shift;
#	my $type = ref($self) || die "$self is not an object";
#	my $name = $WWPlot::AUTOLOAD;
#	$name =~ s/.*://;  # strip fully-qualified portion
# 	unless (exists $self->{'_permitted'}->{$name} ) {
# 		die "Can't find '$name' field in object of class $type";
# 	}
#	if (@_) {
#		return $self->{$name} = shift;
#	} else {
#		return $self->{$name};
#	}
#
#}

##########################
# Access methods
##########################

sub xmin {
	my $self = shift;
	my $type = ref($self) || die "$self is not an object";
	unless (exists $self->{xmin} ) {
		die "Can't find xmin field in object of class $type";
	}
	
	if (@_) {
		return $self->{xmin} = shift;
	} else {
		return $self->{xmin}
	}
}

sub xmax {
	my $self = shift;
	my $type = ref($self) || die "$self is not an object";
	unless (exists $self->{xmax} ) {
		die "Can't find xmax field in object of class $type";
	}
	
	if (@_) {
		return $self->{xmax} = shift;
	} else {
		return $self->{xmax}
	}
}

sub ymin {
	my $self = shift;
	my $type = ref($self) || die "$self is not an object";
	unless (exists $self->{ymin} ) {
		die "Can't find ymin field in object of class $type";
	}
	
	if (@_) {
		return $self->{ymin} = shift;
	} else {
		return $self->{ymin}
	}
}

sub ymax {
	my $self = shift;
	my $type = ref($self) || die "$self is not an object";
	unless (exists $self->{ymax} ) {
		die "Can't find ymax field in object of class $type";
	}
	
	if (@_) {
		return $self->{ymax} = shift;
	} else {
		return $self->{ymax}
	}
}

sub imageName {
	my $self = shift;
	my $type = ref($self) || die "$self is not an object";
	unless (exists $self->{imageName} ) {
		die "Can't find imageName field in object of class $type";
	}
	
	if (@_) {
		return $self->{imageName} = shift;
	} else {
		return $self->{imageName};
	}
}

sub imageNumber {
	my $self = shift;
	my $type = ref($self) || die "$self is not an object";
	unless (exists $self->{imageNumber} ) {
		die "Can't find imageNumber field in object of class $type";
	}
	
	if (@_) {
		return $self->{imageNumber} = shift;
	} else {
		return $self->{imageNumber};
	}
}

sub name {
	my $self = shift;
	my $type = ref($self) || die "$self is not an object";
	unless (exists $self->{name} ) {
		die "Can't find name field in object of class $type";
	}
	
	if (@_) {
		return $self->{name} = shift;
	} else {
		return $self->{name}
	}
}

sub position {
	my $self = shift;
	my $type = ref($self) || die "$self is not an object";
	unless (exists $self->{position} ) {
		die "Can't find position field in object of class $type";
	}
	
	if (@_) {
		return $self->{position} = shift;
	} else {
		return $self->{position}
	}
}


#sub DESTROY {
#	# doing nothing about destruction, hope that isn't dangerous
#}

sub save_image {
		my $self = shift;
	warn "The method save_image is no longer supported. Use insertGraph(\$graph)";
	"The method save_image is no longer supported. Use insertGraph(\$graph)";
}


1;
