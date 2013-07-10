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

##############################################################################################
# this accomplishes the following:
#   a) clears the accumulated statistical data,
#   b) Create three random, normally distributed, and one exponentially dist. data sets.
#   c) Add the data set to the collection of data
#   d) initializes a statistical graph object
#   e) adds the relevant box plots.
##############################################################################################
#   clear_stat_graph_data();         # (a)
#
#   @data1 = urand(10.0,2.0,10,2);   # (b) - mean=10, sd=2.0, N=10, 2 dec places
#   @data2 = urand(12.0,2.0,10,2);   # (b) - mean=12, sd=2.0
#   @data3 = urand(14.0,4.0,10,2);   # (b) - mean=14, sd=4.0
#   @data4 = exprand(0.1,10,2);      # (b) - lambda=0.1, N=10, and 2 dec places (exp)
#
#   push_stat_data_set(~~@data1);    # (c)
#   push_stat_data_set(~~@data2);    # (c)
#   push_stat_data_set(~~@data3);    # (c)
#   push_stat_data_set(~~@data4);    # (c)
#
#   # Now initialize the graph (d) and add the box plots (e)
#   $graph = init_statistics_graph(axes=>[0,0.0],ticks=>[10]);
#   $bounds = add_boxplot($graph);
#
###############################################################################################


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
	my $ymin = -0.25;
	my $ymax = $numberDataSets;
	foreach my $dataSet (@accumulatedDataSets)
	{
			# Get the five point summary for each set.
			my @summary = getMinMax(@{$dataSet});
			# check each give point summary to see if it is a max or min.
			if(($xmin eq 'nd') || ($summary[0] < $xmin)) { $xmin = $summary[0]; }
			if(($xmax eq 'nd') || ($summary[1] > $xmax)) { $xmax = $summary[1]; }
	}


	# Add a little buffer to the left and right.
	$xmin -= ($xmax-$xmin)*0.15;
	$xmax += ($xmax-$xmin)*0.05;

	# Get the graph object.
	# Create a graph object with the given size.
	my $graphRef = init_graph($xmin,$ymin,$xmax,$ymax,plotVerticalAxis=>0,%options);

	$graphRef;
}


sub getMinMax {
		# Routine to return the smallest and largest value in the list of
		# numbers given for the arguments to the function.
			@data_list = (@_);
			my $xmin = 'nd'; 
			my $xmax = 'nd';
			for my $value (@data_list)
			{
					if(($xmin eq 'nd') || ($value < $xmin)) { $xmin = $value; }
					if(($xmax eq 'nd') || ($value > $xmax)) { $xmax = $value; }
			}
			($xmin,$xmax);
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

			# Mark the vertical bars
			foreach my $bound (@summary)
			{
					$graphRef->moveTo($bound,$currentPlot+0.25);
					$graphRef->lineTo($bound,$currentPlot+0.75,$black,2);
			}

			# Mark the two horizontal bars in the quartile box
			$graphRef->moveTo($summary[1],$currentPlot+0.25);
			$graphRef->lineTo($summary[3],$currentPlot+0.25,$black,2);
			$graphRef->moveTo($summary[1],$currentPlot+0.75);
			$graphRef->lineTo($summary[3],$currentPlot+0.75,$black,2);

			# Add the whiskers
			$graphRef->moveTo($summary[0],$currentPlot+0.5);
			$graphRef->lineTo($summary[1],$currentPlot+0.5,$black,2);
			$graphRef->moveTo($summary[3],$currentPlot+0.5);
			$graphRef->lineTo($summary[4],$currentPlot+0.5,$black,2);

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



sub add_histogram {
	my $graphRef   = shift;
	my $numberBins = shift;
	my $numberDataSets = 1+$#accumulatedDataSets;

	if($numberDataSets == 0)
	{
			die "No data sets are defined.";
	}

	# Get the necessary graph properties for making the plot.
	$black = $graphRef->im->colorAllocate(0,0,0);

	# For each data set get the frequencies
	# Then add the result to the graph.
	my $currentPlot = 0;
	my $xmin = 'nd';
	my $bounds = '';
	foreach my $dataSet (@accumulatedDataSets)
	{
			# Initialize the lists of frequencies and the bin end points
			my @binBoundaries = ();
			my @frequencies   = ();
			my @extrema       = getMinMax(@{$dataSet});
			my $width         = ($extrema[1]-$extrema[0])/($numberBins-1);
			$bounds .= "$extrema[0],$extrema[1]\n";
			if(($xmin eq 'nd') || ($extrema[0] < $xmin)) { $xmin = $extrema[0]; }

			# Next set the boundaries for each bin and initialize the
			# frequencies.
			my $lupe;
			for($lupe=0;$lupe<$numberBins;++$lupe)
			{
					push(@binBoundaries,$extrema[0]+$width*($lupe-0.5));
					push(@frequencies,0);
			}
			# Add the far right boundary
			push(@binBoundaries,$extrema[1]+$width*0.5);

			# Now go through all of the data points and figure out which bin
			# they belong to.
			foreach my $point(@{$dataSet})
			{
					my $bin = int(($point-$extrema[0]+$width*0.5)/$width);
					$frequencies[$bin]++;
					#$bounds .= "$point,";
			}
			#$bounds .= "$BR";

			# Draw all of the boxes for the histogram.
			my $totalDataPoints = 1+$#frequencies;
			$lupe = 0;
			foreach my $count (@frequencies)
			{
					# Mark out the rectangle.
					$graphRef->moveTo($binBoundaries[$lupe],$currentPlot+0.25);
					$graphRef->lineTo($binBoundaries[$lupe],$currentPlot+0.25+$count/$totalDataPoints,$black,2);
					$graphRef->lineTo($binBoundaries[$lupe+1],$currentPlot+0.25+$count/$totalDataPoints,$black,2);
					$graphRef->lineTo($binBoundaries[$lupe+1],$currentPlot+0.25,$black,2);
					$graphRef->lineTo($binBoundaries[$lupe],$currentPlot+0.25,$black,2);
					$lupe++;
			}


			$currentPlot++;
	}


	$bounds
}



#########################################################


1;
