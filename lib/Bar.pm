=head1 NAME

	Bar


=head1 SYNPOSIS

	use Carp;
	use GD;
	use WWPlot;
	use Bar;


=head1 DESCRIPTION

This module defines labels for the graph objects (WWPlot).


=head2 Usage

	$bar = new Bar ($x_left, $x_right, $y_top, $fill_color) 


=head2  Example

	$new_bar 	= new Bar (1.5, 2.5, 0.2, 'red' )
	@bars 		= $graph -> bars($new_bar);

=cut


BEGIN {
	be_strict(); # an alias for use strict.  This means that all global variable must contain main:: as a prefix.
}

package Bar;
use strict;
#use Exporter;
#use DynaLoader;
#use GD;   # this is needed to be able to define GD::gdMediumBoldFont and other terms used by GD
#          # however  constants from GD need to be addressed fully, they have not been imported.
#use  "WWPlot.pm";
#Because of the way problem modules are loaded 'use' is disabled.


@Label::ISA = qw(WWPlot);

my %fields =(
		'x_left'	=>	0,  
		'x_right'	=>	0,  
		'y_top'		=>	0,
		'color'		=>  'blue',
		'name'		=>  'bar_b',
);


sub new {
	my $class 	=	shift;
	my $self 	= { 
			_permitted	=>	\%fields,
			%fields,
	};
	
	bless $self, $class;
	$self->_initialize(@_);
	return $self;
}

sub _initialize {
	my $self 				=	shift;
	my ($x_left, $x_right, $y_top, $color)	=   @_;
	$self -> x_left($x_left);
	$self -> x_right($x_right);
	$self -> y_top($y_top);
	$self -> color($color) if defined($color);
}

sub color {
	my $self = shift;
	if (@_) {$self -> {color} = shift;}
	return ($self -> {color});
}

sub name {
	my $self = shift;
	if (@_) {$self -> {name} = shift;}
	return ($self -> {name});
}

sub draw {
	my $self = shift;
	my $g = shift;   #the containing graph
	my $color = shift;
	my $parent = shift;
	my $name = $self-> name();
	if ($g -> type() eq 'file') {
		my $poly = new GD::Polygon;
		$poly -> addPt($g->ii($self->x_left), $g->jj(0));
		$poly -> addPt($g->ii($self->x_left), $g->jj($self->y_top));
		$poly -> addPt($g->ii($self->x_right), $g->jj($self->y_top));
		$poly -> addPt($g->ii($self->x_right), $g->jj(0));
#		$g -> im ->filledPolygon($poly, $g -> {'colors'} {$self->color});
		$g -> im ->filledPolygon($poly, $color );
	}
	elsif ($g -> type() =~/svg/) {
		$parent -> rectangle (x => $g->ii($self->x_left),
					y => $g->jj($self-> y_top),
					width => $g->ii($self->x_right) - $g->ii($self->x_left),
					height => - $g->jj($self->y_top) + $g->jj(0),
#					id => $name,
					fill => $self -> color() ,
		);
					
	}
}

sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self) || die "$self is not an object";
	my $name = $Bar::AUTOLOAD;
	$name =~ s/.*://;  # strip fully-qualified portion
 	unless (exists $self->{'_permitted'}->{$name} ) {
 		die "Can't find '$name' field in object of class $type";
 	}
	if (@_) {
		return $self->{$name} = shift;
	} else {
		return $self->{$name};
	}

}	

sub DESTROY {
	# doing nothing about destruction, hope that isn't dangerous
}

1;

		
	
