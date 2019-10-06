
=head1 NAME

	VectorField

=head1 SYNPOSIS

	use Carp;
	use GD;
	use WWPlot;
	use VectorField;
	$vf = new VectorField( dy_rule_ref);
	$vf = new VectorField( dy_rule_ref , graph_reference);
	$vf = new VectorField( x_rule_ref, y_rule_ref );
	$vf = new VectorField( x_rule_ref, y_rule_ref, graph_ref );

=head1 DESCRIPTION

This module defines a phase plane vector field.  It can also be used to define direction fields
for differenential equations.

The following functions are provided:

=head2	new  (direction field version)

=over 4

=item	$vf = new VectorField( dy_rule_ref);

rule_reference is a reference to a subroutine which accepts a pair of numerical values
and returns a numerical value.
The vector field is also placed into the printing queue of the graph
 object pointed to by graph_reference and the
domain of the vector field object is set to the domain of the graph.
The graph_ref must come last.

=back

=head2 	new  (phase plane version)

=over 4

=item	$vf = new VectorField ( dx_rule_ref, dy_rule_ref );

A vector field object is created where the subroutines refered to by dx_rule_ref and dy_rule_ref define
the x and y components of the vector field at (x,y).  Both subroutines must be functions of two variables.

=item	$vf = new VectorField ( x_rule_ref, y_rule_ref, graph_ref );

This variant inserts the vector field object into the graph object referred to by graph_ref.  The domain
of the vector field object is set to the domain of the graph. The graph_ref must come last. 

=back

=head2 Properites

	All of the properties are set using the construction $new_value = $vf->property($new_value)
	and read using $current_value = $vf->property()

=over 4

=item xmin, xmax, ymin, ymax

The domain of the vector field defined by these values.

=item x_steps y_steps

This gives the number of intervals in the x direction (respectively the y direction) for plotting the vector
field arrows.

=item arrow_color, dot_color

The colors of the arrow bodies and the dot "base" of the arrow are
 specified by a word such as 'orange' or 'yellow'.
C<$vf->arrow_color('blue'); $vf->dot_color('red');> sets the drawing color to blue for the arrow body, with
a red dot at the base of the arrow.  The RGB values for the color are defined in the graph
object in which the vector field is drawn.  If the color, e.g. 'mauve', is not defined by the graph object
then the function is drawn using the color 'default_color' which is always defined (and usually black).

=item dx_rule

A reference to the subroutine used to calculate the dx value of the phase plane field.
This is set to the constant function 1
when using the function object in direction field mode.

=item dy_rule

A reference to the subroutine used to calculate the dy value of the phase plane field.

=item arrow_weight, dot_weight

The width in pixels of the pen used to draw the arrow (respectively the dot).

=back

=head2 Actions which affect more than one property.

=over 4


=item domain

$array_ref = $vf->domain(-1,-2,1,2) sets xmin to -1, ymin to -2, xmax to 1, and ymax to 2.


=item draw

$vf->draw($graph_ref) draws the vector field in the graph object pointed to by $graph_ref.

The graph object must
respond to the methods below.  The draw call is mainly for internal
use by the graph object. Most users will not
call it directly.

=over 4

=item   $graph_ref->{colors}

a hash containing the defined colors

=item $graph_ref ->im

a GD image object

=item $graph_ref->lineTo(x,y, color_number)

draw line to the point (x,y) from the current position using the specified color.  To obtain the color number
use a construction such as C<$color_number = $graph_ref->{colors}{'blue'};>

=item $graph_ref->lineTo(x,y,gdBrushed)

draw line to the point (x,y) using the pattern set by SetBrushed (see GD documentation)

=item $graph_ref->moveTo(x,y)

set the current position to (x,y)

=back

=back

=cut

BEGIN {
	be_strict(); # an alias for use strict.  This means that all global variable must contain main:: as a prefix.
}

package VectorField;


#use "WWPlot.pm";
#Because of the way problem modules are loaded 'use' is disabled.





@VectorField::ISA = qw(WWPlot);
# import gdBrushed from GD.  It unclear why, but a good many global methods haven't been imported.
sub gdBrushed {
	&GD::gdBrushed();
}

my $GRAPH_REFERENCE = "WWPlot";
my $VECTORFIELD_REFERENCE = "VectorField";

my %fields =(
		xmin			=>	-4,
		xmax			=>	4,
		ymin        	=>  -4,
		ymax        	=>   4,
		x_steps  		=>  10,
		y_steps			=> 	10,
		arrow_color		=>  'blue',
		arrow_weight    =>  1,  #line thickness
		dot_color       =>  'red',
		dot_radius      =>  1.5,
		dt				=>  0.1,
		dx_rule     	=> sub{1;},
		dy_rule     	=> sub{1;},
		rf_arrow_length => sub{my($dx,$dy)=@_;
		                           return(0) if sqrt($dx**2 + $dy**2) ==0;
		                           0.5*1/sqrt($dx**2 + $dy**2);
		                      },

);


sub new {
	my $class 				=	shift;

	my $self 			= {
				%fields,
	};

	bless $self, $class;
	$self -> _initialize(@_);
	return $self;
}

sub identity {  # the identity function
	shift;
}


sub _initialize {
	my	$self 	= 	shift;
	my  ($xrule,$yrule, $rule,$graphRef);
	my @input = @_;
	if (ref($input[$#input]) eq $GRAPH_REFERENCE ) {
		$graphRef = pop @input;  # get the last argument if it refers to a graph.
		$graphRef->fn($self);    # Install this vector field in the graph.
		$self->{xmin} = $graphRef->{xmin};
		$self->{xmax} = $graphRef->{xmax};
		$self->{ymin} = $graphRef->{ymin};
		$self->{ymax} = $graphRef->{ymax};
	}
    if ( @input == 1 ) {        # only one argument left -- this is a non parametric function
        $rule = $input[0];
		if ( ref($rule) eq $VECTORFIELD_REFERENCE ) {  # clone another function
			my $k;
			foreach $k (keys %fields) {
				$self->{$k} = $rule->{$k};
			}
		} else {
			$self->{dx_rule} = sub {1; };
			$self->{dy_rule} = $input[0] ;
		}
	} elsif (@input == 2 ) {   #  two arguments -- parametric functions
			$self->{dx_rule} = $input[0] ;
			$self->{dy_rule} = $input[1] ;

	} else {
		die "VectorField.pm:_initialize: Can't call VectorField with more than two arguments";
	}
}
sub draw {
    my $self = shift;  # this function
	my $g = shift;   # the graph containing the function.
	warn "This vector field is not being called from an enclosing graph" unless defined($g);
	my $arrow_color;   # get color scheme from graph
	if ( defined( $g->{'colors'}{$self->arrow_color} )  ) {
		$arrow_color = $g->{'colors'}{$self->arrow_color};
	} else {
		$arrow_color = $g->{'colors'}{'blue'};  # what you do if the color isn't there
	}
	my $dot_color = $self ->dot_color;  # colors are defined differently for Circles, then for lines.
	my $dot_radius  = $self->dot_radius;
	my $brush = new GD::Image($self->arrow_weight,$self->arrow_weight);
	my $brush_color = $brush->colorAllocate($g->im->rgb($arrow_color));  # transfer color
	$g->im->setBrush($brush);
		my $x_steps = $self->x_steps;
	my $xmin = $self->xmin;
	my $x_stepsize = ( $self->xmax - $self->xmin )/$x_steps;
	my $y_steps = $self->y_steps;
	my $ymin = $self->ymin;
	my $y_stepsize = ( $self->ymax - $self->ymin )/$y_steps;
	my $dt = $self->dt;
	my $rf_arrow_length = $self->rf_arrow_length;

    foreach my $i (0..$x_steps) {
    	my $x = $xmin + $i*$x_stepsize;
    	foreach my $j (0..$y_steps) {
    		my $y = $ymin + $j*$y_stepsize;
    		my $dx = $dt*&{$self->dx_rule}($x,$y);
    		my $dy = $dt*&{$self->dy_rule}($x,$y);
    		$g->moveTo($x,$y);
    		$g->stamps(new Circle($x, $y, $dot_radius,$dot_color,$dot_color) ) if $dot_radius > 0; 
    		    # setting the radius to zero omits the dot
    		$g->lineTo($x+$dx*&$rf_arrow_length($dx,$dy), $y+$dy*&$rf_arrow_length($dx,$dy),gdBrushed);

    	}
    }
}

sub domain {
	my $self =shift;
	my @inputs = @_;
  	$self->{xmin} = $inputs[0];
  	$self->{ymin} = $inputs[1];
  	$self->{xmax} = $inputs[2];
	$self->{ymax} = $inputs[3];
}

##########################
# Access methods
##########################
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
sub x_steps {
	my $self = shift;
	my $type = ref($self) || die "$self is not an object";
	unless (exists $self->{x_steps} ) {
		die "Can't find x_steps field in object of class $type";
	}
	
	if (@_) {
		return $self->{x_steps} = shift;
	} else {
		return $self->{x_steps}
	}
}
sub y_steps {
	my $self = shift;
	my $type = ref($self) || die "$self is not an object";
	unless (exists $self->{y_steps} ) {
		die "Can't find y_steps field in object of class $type";
	}
	
	if (@_) {
		return $self->{y_steps} = shift;
	} else {
		return $self->{y_steps}
	}
}
sub arrow_color {
	my $self = shift;
	my $type = ref($self) || die "$self is not an object";
	unless (exists $self->{arrow_color} ) {
		die "Can't find arrow_color field in object of class $type";
	}
	
	if (@_) {
		return $self->{arrow_color} = shift;
	} else {
		return $self->{arrow_color}
	}
}
sub arrow_weight {
	my $self = shift;
	my $type = ref($self) || die "$self is not an object";
	unless (exists $self->{arrow_weight} ) {
		die "Can't find arrow_weight field in object of class $type";
	}
	
	if (@_) {
		return $self->{arrow_weight} = shift;
	} else {
		return $self->{arrow_weight}
	}
}
sub dot_color {
	my $self = shift;
	my $type = ref($self) || die "$self is not an object";
	unless (exists $self->{dot_color} ) {
		die "Can't find dot_color field in object of class $type";
	}
	
	if (@_) {
		return $self->{dot_color} = shift;
	} else {
		return $self->{dot_color}
	}
}
sub dot_radius {
	my $self = shift;
	my $type = ref($self) || die "$self is not an object";
	unless (exists $self->{dot_radius} ) {
		die "Can't find dot_radius field in object of class $type";
	}
	
	if (@_) {
		return $self->{dot_radius} = shift;
	} else {
		return $self->{dot_radius}
	}
}

sub dt {
	my $self = shift;
	my $type = ref($self) || die "$self is not an object";
	unless (exists $self->{dt} ) {
		die "Can't find dt field in object of class $type";
	}
	
	if (@_) {
		return $self->{dt} = shift;
	} else {
		return $self->{dt}
	}
}
sub dx_rule {
	my $self = shift;
	my $type = ref($self) || die "$self is not an object";
	unless (exists $self->{dx_rule} ) {
		die "Can't find dx_rule field in object of class $type";
	}
	
	if (@_) {
		return $self->{dx_rule} = shift;
	} else {
		return $self->{dx_rule}
	}
}
sub dy_rule {
	my $self = shift;
	my $type = ref($self) || die "$self is not an object";
	unless (exists $self->{dy_rule} ) {
		die "Can't find dy_rule field in object of class $type";
	}
	
	if (@_) {
		return $self->{dy_rule} = shift;
	} else {
		return $self->{dy_rule}
	}
}
sub rf_arrow_length {
	my $self = shift;
	my $type = ref($self) || die "$self is not an object";
	unless (exists $self->{rf_arrow_length} ) {
		die "Can't find rf_arrow_length field in object of class $type";
	}
	
	if (@_) {
		return $self->{rf_arrow_length} = shift;
	} else {
		return $self->{rf_arrow_length}
	}
}
sub DESTROY {
	# doing nothing about destruction, hope that isn't dangerous
}

1;
