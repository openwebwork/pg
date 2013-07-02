#require 'PGstatisticsmacros.pl';

=head1 NAME

	PGstatisticsGraphMacros -- in courseScripts directory

=head1 SYNPOSIS

#		use Fun;
#		use Label;
#		use Circle;
#		use WWPlot;

=head1 DESCRIPTION

This collection of macros provides easy access for statistics graphs
using the facilities provided by the graph module WWPlot and the
modules for objects which can be drawn on a graph: functions (Fun.pm)
labels (Label.pm) and images.  

These macros provide an easy ability to produce simple graphs for
describing data sets.  More complicated projects may require direct
access to the underlying modules.  If these complicated projects are
common then it may be desirable to create additional macros.  (See
numericalmacros.pl for one example.)


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

our @accumulatedDataSets = (); # The list of data sets to be used in the graphs.

BEGIN {
	be_strict();
}
sub _PGstatisticGraphMacros_init {
		clear_stat_graph_data();
}

sub clear_stat_graph_data {
		@accumulatedDataSets = ();
}

sub push_stat_data_set {
		my $data = shift;
		push(@accumulatedDataSets,$data);
}

sub init_statistics_graph {
	my (%options) = @_;
	my $numberDataSets = 1+$#accumulatedDataSets;

	if($numberDataSets == 0)
	{
			die "No data sets are defined.";
	}


	# For each data set get the five point summary (use the default formula)
	# From that value determine the min and max x values.
	my $xmin = 'nd'; 
	my $xmax = 'nd';
	my $ymin = 0.0;
	my $ymax = $numberDataSets;
	foreach my $dataSet (@accumulatedDataSets)
	{
			# Get the five point summary for each set.
			my @summary = five_point_summary(@{$dataSet});
			# check each give point summary to see if it is a max or min.
			if(($xmin eq 'nd') || ($summary[0] < $xmin)) { $xmin = $summary[0]; }
			if(($xmax eq 'nd') || ($summary[4] > $xmax)) { $xmax = $summary[4]; }
	}


	# Add a little buffer to the left and right.
	$xmin -= ($xmax-$xmin)*0.15;
	$xmax += ($xmax-$xmin)*0.05;

	# Get the graph object.
	# Create a graph object with the given size.
	my $graphRef = init_graph($xmin,$ymin,$xmax,$ymax,%options);
	$graphRef->lb('reset');

	$graphRef;
}


sub add_boxplot {
	my $graphRef = shift;
	my $numberDataSets = 1+$#accumulatedDataSets;

	if($numberDataSets == 0)
	{
			die "No data sets are defined.";
	}

	# Get the necessary graph properties for making the plot.
	$black = $graphRef->im->colorAllocate(0,0,0);

	# Get the five point summaries for each of the defined data sets.
	# initialize the set of five point summaries
	my @fivePointSummary = ();

	# For each data set get the five point summary (use the default formula)
	# Then add the result to the graph.
	my $currentPlot = 0;
	my $bounds = '';
	my $xmin = 'nd'; 
	my $xmax = 'nd';
	foreach my $dataSet (@accumulatedDataSets)
	{
			# Get the five point summary for each set.
			my @summary = five_point_summary(@{$dataSet});
			if(($xmin eq 'nd') || ($summary[0] < $xmin)) { $xmin = $summary[0]; }
			if(($xmax eq 'nd') || ($summary[4] > $xmax)) { $xmax = $summary[4]; }
			$bounds .= "$summary[0],$summary[1],$summary[2],$summary[3],$summary[4]\n";

			# Make the big box marking the quartiles.
			$graphRef->moveTo($summary[1],$currentPlot+0.25);
			$graphRef->lineTo($summary[1],$currentPlot+0.75,$black,2);
			$graphRef->lineTo($summary[3],$currentPlot+0.75,$black,2);
			$graphRef->lineTo($summary[3],$currentPlot+0.25,$black,2);
			$graphRef->lineTo($summary[1],$currentPlot+0.25,$black,2);
			$graphRef->lineTo($summary[1],$currentPlot+0.75,$black,2);

			# Mark the median
			$graphRef->moveTo($summary[2],$currentPlot+0.25);
			$graphRef->lineTo($summary[2],$currentPlot+0.75,$black,2);

			# Mark the minimum
			$graphRef->moveTo($summary[0],$currentPlot+0.25);
			$graphRef->lineTo($summary[0],$currentPlot+0.75,$black,2);
			$graphRef->moveTo($summary[0],$currentPlot+0.5);
			$graphRef->lineTo($summary[1],$currentPlot+0.5,$black,2);

			# Mark the maximum
			$graphRef->moveTo($summary[4],$currentPlot+0.25);
			$graphRef->lineTo($summary[4],$currentPlot+0.75,$black,2);
			$graphRef->moveTo($summary[4],$currentPlot+0.5);
			$graphRef->lineTo($summary[3],$currentPlot+0.5,$black,2);


			$currentPlot++;
	}
	$xmin -= ($xmax-$xmin)*0.075;

	# No go through and add the labels.
	while($currentPlot>0)
	{
			my $label = new Label($xmin,$currentPlot-0.5,$currentPlot,'black','left');
			$label->font(GD::gdGiantFont);
			$graphRef->lb($label);
			$currentPlot--;
	}

	$bounds;
}





#########################################################


1;
