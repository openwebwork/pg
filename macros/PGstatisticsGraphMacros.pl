
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

my @dataSets = (); # The list of data sets to be used in the graphs.



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
sub _PGstatisticGraphMacros_init {


}

sub clear_stat_graph_data {
		@dataSets = ();
}

sub push_stat_data_set {
		push(@dataSets,@_);
}

sub init_statistics_graph {
	my (%options) = @_;
	my $numberDataSets = 1+$#dataSets;

	if($numberDataSets == 0)
	{
			die "No data sets are defined.";
	}


	# Get the five point summaries for each of the defined data sets.
	# initialize the set of five point summaries
	my @fivePointSummary = ();

	# For each data set get the five point summary (use the default formula)
	# From that value determine the min and max x values.
	# First get all of the five point summaries.
	foreach my $dataSet (@dataSets)
	{
			my @summary = five_point_summary(@{$dataSet});
			#print("$summary[0]/$summary[1]/$summary[2]/$summary[3]/$summary[4]\n");
			push(@fivePointSummary,\@summary);
	}

	# Now get the min and max for the graphs.
	my $xmin = $fivePointSummary[0][0];
	my $xmax = $fivePointSummary[0][4];
	my $ymin = 0.0;
	my $ymax = $numberDataSets+1;
	foreach my $dataSet (@fivePointSummary)
	{
			#print("$dataSet->[0]/$dataSet->[1]/$dataSet->[2]/$dataSet->[3]/$dataSet->[4]\n");
			if($dataSet->[0] < $xmin) { $xmin = $dataSet->[0]; }
			if($dataSet->[4] > $xmax) { $xmax = $dataSet->[4]; }
	}


	# Get the graph object.
	# Create a graph object with the given size.
	my $graphRef = init_graph($xmin,$ymin,$xmax,$ymax,%options);


	$graphRef;
}





#########################################################


1;
