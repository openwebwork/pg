sub _PGanalyzeGraph_init {}

################################################################
# subroutines
################################################################

=head1 NAME

PGanalyzeGraph.pl

=head1 DESCRIPTION

These routines support the
analysis of  graphical input from students.

=cut


=head4  detect_intervals



   input:   $pointDisplayString 
         
   return: (\@combined_intervals, \@values)
           @values contains the y values of the function in order
           @combined_intervals contains anonymous arrays of the form
               [ $slope, $left_x, $right_x]  indicating the gradient on that segment.
               successive intervals will have different slopes.
               

=cut



sub detect_intervals {
	my $pointDisplayString = shift;
	my @intervals;
	my @combined_intervals=();
	my @points;
	my @values;
	$out_string ='';
	return "" unless defined $pointDisplayString and $pointDisplayString =~/\S/;
	@pointDisplayLines = split("\n",$pointDisplayString);
	#drop first line
	#shift @pointDisplayLines;
	my ($prev_x, $prev_y, $prev_yp) = (undef);
	my $slope;
	
    #first calculate the average gradient on each interval
    
	foreach my $line (@pointDisplayLines) {
	    chomp($line);
	    next unless $line =~/\S/;  # skip blank lines
	    ($x,$y,$yp) = split(/\s+/, $line);

	    if (defined $prev_x) {
	    	 $slope = $y - $prev_y;
			
			if ($slope >0) {
				$slope_str="increasing";
			} elsif ($slope <0) {
				$slope_str="decreasing";
			} else {
				$slope_str = "constant";
			}
			push @intervals, [$slope_str, $prev_x, $x];  
			
			#TEXT("f is $slope_str on the interval [$prev_x, $x]$BR");
		}
		#TEXT("x=$x y = $y yp = $yp $BR");
		push @points, [$x, $y, $yp];
		push @values, $y; 
		$prev_x =$x; $prev_y=$y; $prev_yp = $yp;
		
	}
	my $prev_slope = undef;
	my ($left_x, $right_x);
	
	########
	# Combine adjacent intervals with the same properites
	########
	foreach my $item (@intervals) {
		if (defined $prev_slope) {
			if ($prev_slope eq $item->[0]) {
				$right_x = $item->[2];			
			} else {
				push @combined_intervals, [$prev_slope, $left_x, $right_x];
				$left_x = $item->[1];
				$right_x = $item->[2];
			}
		
		} else {
			$left_x = $item->[1];
			$right_x = $item->[2];
		}
		$prev_slope = $item->[0]; 
		# warn "intervals",join(" ", @combined_intervals);
	}
	push @combined_intervals, [$prev_slope, $left_x, $right_x];
	
  (\@combined_intervals, \@values);
}






1;