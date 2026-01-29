
=head1 DESCRIPTION

This is the main C<Plots::StatPlots> code for creating statistical plots.

See L<StatisticalPlots.pl> for more details.
=cut

package Plots::StatPlot;

use strict;
use warnings;

use WeBWorK::Utils qw(min max);

sub new {
	my ($class, %options) = @_;
	return Plots::Plot->new(%options);
}

sub add_histogram {
	my ($self, $data, %opts) = @_;

	my %options = (
		bins => 10,
		%opts
	);

	my $min      = min(@$data);
	my $max      = max(@$data);
	my $bin_size = ($max - $min) / $options{bins};

	my @counts;
	$counts[ int(($_ - $min) / $bin_size) ]++ for (@$data);

}

1;
