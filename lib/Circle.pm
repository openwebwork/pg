
=head1 NAME

	Circle

=head1 SYNPOSIS

    use Carp;
	use GD;
	use WWPlot;
	use Fun;


=head1 DESCRIPTION

This module defines a circle which can be inserted as a stamp in a graph (WWPlot) object.

=head2 Command:

	$circle_object = new Circle( $center_pos_x, $center_pos_y, $radius, $border_color, $fill_color);


=head2 Examples:

	Here is the code used to define the subroutines open_circle
	and closed_circle in PGgraphmacros.pl

		sub open_circle {
		    my ($cx,$cy,$color) = @_;
			new Circle ($cx, $cy, 4,$color,'nearwhite');
		}

		sub closed_circle {
		    my ($cx,$cy, $color) = @_;
		    $color = 'black' unless defined $color;
			new Circle ($cx, $cy, 4,$color, $color);
		}

	$circle_object2 = closed_circle( $x_position, $y_position, $color );

	@circle_objects = $graph -> stamps($circle_object2);
	# puts a filled dot at ($x_position, $y_position) on the graph -- using real world coordinates.

=cut


BEGIN {
	be_strict(); # an alias for use strict.  This means that all global variable must contain main:: as a prefix.
}

package Circle;



#use WWPlot;
#Because of the way problem modules are loaded 'use' is disabled.

#use strict;
@Circle::ISA = qw(WWPlot);

my %fields =(
		colors 			=>	{},
		border_color	=>	 'black',
		fill_color		=>	 'nearwhite',
		radius			=>	 8,
		fill            =>   'TRUE',
);

sub new {
	my $class 			= shift;
	my $cx				= shift;
	my $cy				= shift;
	my $radius 			= shift;    # radius is in pixels, others are in real world coordinates
	my $border_color	= shift;
	my $fill_color	 	= shift;
	my $fill			= shift;    # TRUE or FALSE; 
	$radius =4 unless defined $radius;
	$border_color		= 	'black' unless defined($border_color);
	$fill_color			=	'black' unless defined($fill_color);

	my $self = { im 		=> 	new GD::Image(2*$radius, 2*$radius),
				 cx			=>	$cx,
				 cy			=>	$cy,
				 radius		=>	$radius,
				 border_color	=>	$border_color,
				 fill_color		=>	$fill_color,

	};

	bless $self, $class;
# 	$self ->	_initialize_colors;
#	if (defined($self->{'colors'}{$border_color} ) ) {
#		$self->{'border_color'} = $self->{'colors'}{$border_color};
#	} else {
#		$self->{'border_color'} = 'default_color';
#	}
#	if (defined($self->{'colors'}{$fill_color} ) ) {
#		$self->{'fill_color'} = $self->{'colors'}{$fill_color};
#	} else {
#		$self->{'fill_color'} = 'nearwhite';
#	}
#    $self->im->transparent($self->{'colors'}{'background_color'});
#    $self->im->arc($radius,$radius,2*$radius,2*$radius,0,360,$self->{'border_color'} );
#    $self->im->fill($radius,$radius,$self->{'fill_color'});
 	return $self;
}

sub newTransparent {
	my $self = new(@_);
	$self -> fill('FALSE');
#	bless $self, $class;
 	return $self;
}

#sub	_initialize_colors {     #### This is now done in WWPlot.pm and passed to Circle.pm
#	my $self 			= shift;
#		# allocate some colors
#		$self->{'colors'}{'background_color'} 	= 	$self->im->colorAllocate(255,255,255);
#	    $self->{'colors'}{'default_color'} 	= 	$self->im->colorAllocate(0,0,0);
#		$self->{'colors'}{'white'} 	= 	$self->im->colorAllocate(255,255,255);
#	    $self->{'colors'}{'black'} 	= 	$self->im->colorAllocate(0,0,0);
#	    $self->{'colors'}{'red'} 	= 	$self->im->colorAllocate(255,0,0);
#	    $self->{'colors'}{'green'}	= 	$self->im->colorAllocate(0,255,0);
#	    $self->{'colors'}{'blue'} 	= 	$self->im->colorAllocate(0,0,255);
#	    $self->{'colors'}{'yellow'}	=	$self->im->colorAllocate(255,255,0);
#	    $self->{'colors'}{'orange'}	=	$self->im->colorAllocate(255,100,0);
#	    $self->{'colors'}{'gray'}	=	$self->im->colorAllocate(180,180,180);
#	    $self->{'colors'}{'nearwhite'}	=	$self->im->colorAllocate(254,254,254);
#}

  ##########################
  # Access methods -- Get and Set
  ##########################
  
  
  sub colors {
  	my $self = shift;
  	my $type = ref($self) || die "$self is not an object";
  	unless (exists $self->{colors} ) {
  		die "Can't find colors field in object of class $type";
  	}
  	
  	if (@_) {
  		return $self->{colors} = shift;
  	} else {
  		return $self->{colors}
  	}
  }
  
  sub border_color {
  	my $self = shift;
  	my $type = ref($self) || die "$self is not an object";
  	unless (exists $self->{border_color} ) {
  		die "Can't find border_color field in object of class $type";
  	}
  	
  	if (@_) {
  		return $self->{border_color} = shift;
  	} else {
  		return $self->{border_color}
  	}
  }
  
  sub fill_color {
  	my $self = shift;
  	my $type = ref($self) || die "$self is not an object";
  	unless (exists $self->{fill_color} ) {
  		die "Can't find fill_color field in object of class $type";
  	}
  	
  	if (@_) {
  		return $self->{fill_color} = shift;
  	} else {
  		return $self->{fill_color}
  	}
  }
  
sub fill {
 	my $self = shift;
 	my $fill = shift;
 	if ($fill eq 'TRUE' or $fill eq 'FALSE') { $self -> {fill} = $fill ;}
 	return($self -> {fill});
  }
  

sub size {
	my $s = shift;
	(2*$s->{radius}, 2*$s->{radius});
}
sub height{
	my $s = shift;
	2*$s->{radius};
}
sub width {
	my $s = shift;
	2*$s->{radius};
}
sub radius {
	my $s = shift;
	$s->{radius};
}
sub x {
	my $s = shift;
	$s->{cx};
}
sub y {
	my $s = shift;
	$s->{cy};
}
sub image {
	my $s	= shift;
	$s->{im};
}

sub draw{
	my $self = shift;
	my $g = shift;   # the enclosing graph object
	my $arc_color = shift;
	my $fill_color = shift;
	my $parent = shift;
	my $x = $self->x;
	my $y = $self->y;
	my $radius = $self -> radius;
#	my $image = $self->image;
#	my $height = $self->height;
#	my $width	= $self->width;
#	$g->im->copy($image,
#				  ($g->ii($x)) - int($width/2),
#				  ($g->jj($y)) - int($height/2),
#				  0,  0,   $width,   $height);
	if ($g -> type eq 'file') {
		$g->im->arc($g->ii($x), $g->jj($y), 2*$radius,2*$radius,0,360,$arc_color );
		if ($self->fill eq 'TRUE') {
			$g -> im -> fill($g->ii($x), $g->jj($y), $fill_color);
		}
	}
	elsif ($g -> type =~ /svg/) {
		
		$parent -> circle ( cx => $g->ii($x), cy => $g->jj($y), r => $radius,
					stroke => $arc_color, 'stroke-width' => 1,
					fill => ($self -> fill eq 'TRUE') ? $fill_color : 'none');
	}
}

#sub DESTROY {
#	# doing nothing about destruction, hope that isn't dangerous
#}

1;
