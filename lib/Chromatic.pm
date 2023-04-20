################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2022 The WeBWorK Project, https://github.com/openwebwork
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of either: (a) the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version, or (b) the "Artistic License" which comes with this package.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
# Artistic License for more details.
################################################################################

package Chromatic;

use warnings;
use strict;

use Carp;

sub computeBestColoring {
	my @adj      = @_;
	my $num_node = scalar @adj;

	my $BestColoring = $num_node + 1;
	my @ColorClass;
	my $prob_count = 0;
	my @Order;
	my @Handled = (0) x $num_node;
	my @ColorAdj;
	my @ColorCount = (0) x $num_node;
	my $lb;
	my $num_prob    = 0;
	my $max_prob    = 10000;
	my @valid       = (1) x $num_node;
	my $best_clique = 0;

	my $greedy_clique = sub {
		my ($valid, $clique) = @_;
		my $place = 0;
		my @order = (0) x ($num_node + 1);
		my @weight;

		$clique->[$_] = 0 for (0 .. $num_node - 1);

		for my $i (0 .. $num_node - 1) {
			if ($valid->[$i]) {
				$order[$place] = $i;
				++$place;
			}
		}

		$weight[$_] = 0 for (0 .. $num_node - 1);

		for my $i (0 .. $num_node - 1) {
			next unless $valid->[$i];
			for my $j (0 .. $num_node - 1) {
				next unless $valid->[$j];
				++$weight[$i] if $adj[$i][$j];
			}
		}

		my $done = 0;
		while (!$done) {
			$done = 1;
			for my $i (0 .. $place - 2) {
				my $j = $order[$i];
				my $k = $order[ $i + 1 ];
				if ($weight[$j] < $weight[$k]) {
					$order[$i]       = $k;
					$order[ $i + 1 ] = $j;
					$done            = 0;
				}
			}
		}

		$clique->[ $order[0] ] = 1;
		for my $i (1 .. $place - 1) {
			my $j = $order[$i];
			my $k = 0;
			for (0 .. $i - 1) {
				if ($clique->[ $order[$_] ] && !$adj[$j][ $order[$_] ]) {
					$k = $_;
					last;
				}
			}
			if ($k == $i) {
				$clique->[$j] = 1;
			} else {
				$clique->[$j] = 0;
			}
		}

		my $max = 0;
		for my $i (0 .. $place - 1) {
			++$max if $clique->[ $order[$i] ];
		}

		return $max;
	};

	# Target is a goal value:  once a clique is found with value target it is possible to return
	#
	# Lower is a bound representing an already found clique:  once it is determined that no clique exists with value
	# better than lower, it is permitted to return with a suboptimal clique.
	#
	# Note, to find a clique of value 1, it is not permitted to just set the lower to 1:  the recursion will not work.
	# Lower represents a value that is the goal for the recursion.
	my $max_w_clique;
	$max_w_clique = sub {
		my ($valid, $clique, $lower, $target) = @_;

		my @order = (0) x ($num_node + 1);
		my @value = (0) x $num_node;

		++$num_prob;

		return -1 if $num_prob > $max_prob;

		$clique->[$_] = 0 for (0 .. $num_node - 1);

		my $total_left = 0;
		for my $i (0 .. $num_node - 1) {
			++$total_left if ($valid->[$i]);
		}

		return 0 if ($total_left < $lower);

		my $incumb = $greedy_clique->($valid, $clique);
		return $incumb if $incumb >= $target;

		$best_clique = $incumb if ($incumb > $best_clique);

		my $place = 0;
		for my $i (0 .. $num_node) {
			if ($clique->[$i]) {
				$order[$place] = $i;
				--$total_left;
				++$place;
			}
		}

		my $start = $place;
		for my $i (0 .. $num_node - 1) {
			if (!$clique->[$i] && $valid->[$i]) {
				$order[$place] = $i;
				++$place;
			}
		}

		my $finish = $place;
		for ($start .. $finish - 1) {
			my $i = $order[$_];
			$value[$i] = 0;
			for my $j (0 .. $num_node - 1) {
				++$value[$i] if $valid->[$j] && $adj[$i][$j];
			}
		}

		my $done = 0;

		while (!$done) {
			$done = 1;
			for ($start .. $finish - 2) {
				my $i = $order[$_];
				my $j = $order[ $_ + 1 ];
				if ($value[$i] < $value[$j]) {
					$order[$_]       = $j;
					$order[ $_ + 1 ] = $i;
					$done            = 0;
				}
			}
		}

		for ($start .. $finish - 1) {
			return 0 if $incumb + $total_left < $lower;

			my $j = $order[$_];
			--$total_left;

			next if $clique->[$j];

			my @valid1  = (0) x $num_node;
			my @clique1 = (0) x $num_node;
			$valid1[$_] = 0 for (0 .. $num_node - 1);

			for (0 .. $_ - 1) {
				my $k = $order[$_];
				if ($valid->[$k] && $adj[$j][$k]) {
					$valid1[$k] = 1;
				} else {
					$valid1[$k] = 0;
				}
			}

			my $new_weight = $max_w_clique->(\@valid1, \@clique1, $incumb - 1, $target - 1);

			if ($new_weight + 1 > $incumb) {
				$incumb       = $new_weight + 1;
				$clique->[$_] = $clique1[$_] for (0 .. $num_node - 1);
				$clique->[$j] = 1;
				$best_clique  = $incumb if $incumb > $best_clique;
			}

			last if $incumb >= $target;
		}

		return $incumb;
	};

	my $AssignColor = sub {
		my ($node, $color) = @_;

		$ColorClass[$node] = $color;

		for my $node1 (0 .. $num_node - 1) {
			next if ($node == $node1);
			if ($adj[$node][$node1]) {
				++$ColorCount[$node1] if $ColorAdj[$node1][$color] == 0;
				++$ColorAdj[$node1][$color];
				--$ColorAdj[$node1][0];
				warn 'ERROR on assign' if $ColorAdj[$node1][0] < 0;
			}
		}

		return;
	};

	my $RemoveColor = sub {
		my ($node, $color) = @_;

		$ColorClass[$node] = 0;

		for my $node1 (0 .. $num_node - 1) {
			next if ($node == $node1);
			if ($adj[$node][$node1]) {
				--$ColorAdj[$node1][$color];
				--$ColorCount[$node1]  if $ColorAdj[$node1][$color] == 0;
				warn 'ERROR on assign' if $ColorAdj[$node1][$color] < 0;
				++$ColorAdj[$node1][0];
			}
		}

		return;
	};

	my $print_colors = sub {
		for my $i (0 .. $num_node - 1) {
			for my $j (0 .. $num_node - 1) {
				next if $i == $j;
				warn "Error with nodes $i and $j and color $ColorClass[$i]"
					if $adj[$i][$j] && $ColorClass[$i] == $ColorClass[$j];
			}
		}

		return;
	};

	my $color;
	$color = sub {
		my ($i, $current_color) = @_;
		++$prob_count;
		return $current_color if $current_color >= $BestColoring;
		return $BestColoring  if $BestColoring <= $lb;

		return $current_color if $i >= $num_node;

		# Find node with maximum $color_adj
		my $max   = -1;
		my $place = -1;
		for my $k (0 .. $num_node - 1) {
			next if $Handled[$k];
			if ($ColorCount[$k] > $max || ($ColorCount[$k] == $max && ($ColorAdj[$k][0] > $ColorAdj[$place][0]))) {
				$max   = $ColorCount[$k];
				$place = $k;
			}
		}
		if ($place == -1) {
			croak 'Graph is disconnected.  This code needs to be updated for that case.';
		}

		my $new_val;
		$Order[$i]       = $place;
		$Handled[$place] = 1;

		for my $j (1 .. $current_color) {
			if (!$ColorAdj[$place][$j]) {
				$ColorClass[$place] = $j;
				$AssignColor->($place, $j);

				$new_val = $color->($i + 1, $current_color);
				if ($new_val < $BestColoring) {
					$BestColoring = $new_val;
					$print_colors->();
				}

				$RemoveColor->($place, $j);
				if ($BestColoring <= $current_color) {
					$Handled[$place] = 0;
					return $BestColoring;
				}
			}
		}

		if ($current_color + 1 < $BestColoring) {
			$ColorClass[$place] = $current_color + 1;
			$AssignColor->($place, $current_color + 1);

			$new_val = $color->($i + 1, $current_color + 1);
			if ($new_val < $BestColoring) {
				$BestColoring = $new_val;
				$print_colors->();
			}

			$RemoveColor->($place, $current_color + 1);
		}

		$Handled[$place] = 0;
		return $BestColoring;
	};

	for my $i (0 .. $num_node - 1) {
		for my $j (0 .. $num_node - 1) {
			$ColorAdj[$i][$j] = 0;
		}
	}

	for my $i (0 .. $num_node - 1) {
		for my $j (0 .. $num_node - 1) {
			++$ColorAdj[$i][0] if $adj[$i][$j];
		}
	}

	my @clique;
	$lb = $max_w_clique->(\@valid, \@clique, 0, $num_node);

	my $place = 0;
	for my $i (0 .. $num_node - 1) {
		if ($clique[$i]) {
			$Order[$place] = $i;
			$Handled[$i]   = 1;
			++$place;
			$AssignColor->($i, $place);
			for my $j (0 .. $num_node - 1) {
				warn 'Result is not a clique!' if $i != $j && $clique[$j] && !$adj[$i][$j];
			}
		}
	}

	return $color->($place, $place);
}

sub matrix_graph {
	my $graph = shift;
	$graph =~ s/\A\s*//;
	$graph =~ s/;\s*\Z//;

	my @m    = split /\s*[;]\s*/, $graph;
	my $size = scalar @m;
	my @matrix;
	for my $i (0 .. $size - 1) {
		my @r = split /\s+/, $m[$i];
		for my $j (0 .. $size - 1) {
			$matrix[$i][$j] = $r[$j];
		}
	}

	return @matrix;
}

# $graph input is a string adjacency matrix with rows terminted with semicolons
# and entries of each row separated by a space.
sub ChromNum {
	my $graph = shift;
	return computeBestColoring(matrix_graph($graph));
}

1;
