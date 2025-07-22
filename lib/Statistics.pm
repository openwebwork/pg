package Statistics;

use strict;
use warnings;

require WeBWorK::PG::IO;

# Write the given data to a csv file.
sub write_array_to_CSV {
	my ($fileName, @dataRefs) = @_;

	die 'No data set was provided.' unless @dataRefs && ref $dataRefs[0] eq 'ARRAY';

	# Make sure all of the data sets have the same number of elements
	my $numberDataPoints = $#{ $dataRefs[0] };
	for my $data (@dataRefs) {
		die 'The number of elements in the data sets are not all the same. No data set written to file.'
			if $numberDataPoints != $#$data;
	}

	# Add the header to the first row of the output.
	my $output = join(',', map { $_->[-1] } @dataRefs) . "\n";

	# Add each data point as another row in the output.
	for my $i (0 .. $numberDataPoints - 1) {
		$output .= join(',', map { $_->[$i] } @dataRefs) . "\n";
	}

	# Write the output to disk.
	WeBWorK::PG::IO::saveDataToFile($output, $fileName);

	return;
}

1;
