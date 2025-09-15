BEGIN { strict->import; }

loadMacros('PGauxiliaryFunctions.pl', 'PGbasicmacros.pl', 'MathObjects.pl', 'plots.pl');

sub _SimpleGraph_init {
	my $context = $main::context{EdgeSet} = Parser::Context->getCopy('Numeric');
	$context->{name}           = 'EdgeSet';
	$context->{value}{EdgeSet} = 'GraphTheory::SimpleGraph::Value::EdgeSet';
	$context->{value}{Edge}    = 'GraphTheory::SimpleGraph::Value::Edge';
	$context->lists->set(
		# The "List" type list is set to use the GraphTheory::SimpleGraph::Parser::List class so that implicit lists can
		# be turned into edges or edge sets, and empty lists can be interpreted as edge sets for a graph with no edges.
		# All explicit lists that open with something other than a brace are untouched.
		List    => { %{ $context->lists->get('List') }, class => 'GraphTheory::SimpleGraph::Parser::List' },
		EdgeSet =>
			{ class => 'GraphTheory::SimpleGraph::Parser::List', open => '{', close => '}', separator => ', ' },
		Edge => { class => 'GraphTheory::SimpleGraph::Parser::List', open => '{', close => '}', separator => ', ' },
	);
	$context->parens->set(
		'{' => { close => '}', type => 'Edge', formList => 1, formMatrix => 0, removable => 0, emptyOK => 1 });
}

sub SimpleGraph { GraphTheory::SimpleGraph->new(@_) }
sub EdgeSet     { GraphTheory::SimpleGraph::Value::EdgeSet->new(@_) }
sub Edge        { GraphTheory::SimpleGraph::Value::Edge->new(@_) }

sub randomSimpleGraph {
	my ($size, %options) = @_;

	my $graph;
	my $edgeCount       = 0;
	my $edgeProbability = $options{edgeProbability} // 0.5;

	if (ref $size eq 'ARRAY') {
		$graph =
			GraphTheory::SimpleGraph->new($size->[0] * $size->[1], %options, gridLayout => [ $size->[0], $size->[1] ]);

		for my $i (0 .. $size->[0] - 1) {
			for my $j (0 .. $size->[1] - 1) {
				my $location = $j * $size->[0] + $i;

				if ($j < $size->[1] - 1 && main::random(0, 100) <= 100 * $edgeProbability) {
					$graph->addEdge($location, $location + $size->[0]);
					++$edgeCount;
				}
				if ($i < $size->[0] - 1 && main::random(0, 100) <= 100 * $edgeProbability) {
					$graph->addEdge($location, $location + 1);
					++$edgeCount;
				}
				if ($i < $size->[0] - 1 && $j < $size->[1] - 1 && main::random(0, 100) <= 100 * $edgeProbability) {
					$graph->addEdge($location, $location + $size->[0] + 1);
					++$edgeCount;
				}
				if ($i >= 1 && $j < $size->[1] - 1 && main::random(0, 100) <= 100 * $edgeProbability) {
					$graph->addEdge($location, $location + $size->[0] - 1);
					++$edgeCount;
				}
			}
		}
	} else {
		$graph = GraphTheory::SimpleGraph->new($size, %options);

		for my $i (0 .. $size - 1) {
			for my $j (0 .. $i - 1) {
				if (main::random(0, 100) <= 100 * $edgeProbability) {
					$graph->addEdge($i, $j);
					++$edgeCount;
				}
			}
		}
	}

	return $graph->setRandomWeights(%options, edgeCount => $edgeCount);
}

sub randomGraphWithEulerCircuit {
	my ($size, %options) = @_;

	die 'A graph with an Euler circuit must have at least 5 vertices.' if $size < 5;

	# Remove these from the options so that setting weights is deferred until the return.
	my ($startEdgeWeight, $edgeWeightIncrement, $edgeWeightRange) =
		delete @options{qw(startEdgeWeight edgeWeightIncrement edgeWeightRange)};

	my $graph;

	do {
		$graph = simpleGraphWithDegreeSequence([ map { main::random(2, $size - 1, 2) } 0 .. $size - 1 ], %options);
	} while !defined $graph || $graph->numComponents > 1;

	return $graph->setRandomWeights(
		%options,
		startEdgeWeight     => $startEdgeWeight,
		edgeWeightIncrement => $edgeWeightIncrement,
		edgeWeightRange     => $edgeWeightRange
	)->shuffle;
}

sub randomGraphWithEulerTrail {
	my ($size, %options) = @_;

	die 'A graph with an Euler trail must have at least 5 vertices.' if $size < 5;

	# Remove these from the options so that setting weights is deferred until the return.
	my ($startEdgeWeight, $edgeWeightIncrement, $edgeWeightRange) =
		delete @options{qw(startEdgeWeight edgeWeightIncrement edgeWeightRange)};

	my $graph = randomGraphWithEulerCircuit($size, %options);

	my ($vertex1, $vertex2);

	do {
		($vertex1, $vertex2) = main::random_subset(2, 0 .. $size - 1);
	} until $graph->hasEdge($vertex1, $vertex2);

	$graph->removeEdge($vertex1, $vertex2);

	return $graph->setRandomWeights(
		%options,
		startEdgeWeight     => $startEdgeWeight,
		edgeWeightIncrement => $edgeWeightIncrement,
		edgeWeightRange     => $edgeWeightRange
	);
}

sub randomGraphWithoutEulerTrail {
	my ($size, %options) = @_;

	die 'A graph without an Euler trail must have at least 5 vertices.' if $size < 5;

	# Remove these from the options so that setting weights is deferred until the return.
	my ($startEdgeWeight, $edgeWeightIncrement, $edgeWeightRange) =
		delete @options{qw(startEdgeWeight edgeWeightIncrement edgeWeightRange)};

	my $graph;

	do {
		$graph = simpleGraphWithDegreeSequence([ map { main::random(2, $size - 1, 1) } 0 .. $size - 1 ], %options);
	} while !defined $graph || $graph->hasEulerTrail;

	return $graph->setRandomWeights(
		%options,
		startEdgeWeight     => $startEdgeWeight,
		edgeWeightIncrement => $edgeWeightIncrement,
		edgeWeightRange     => $edgeWeightRange
	)->shuffle;
}

sub randomBipartiteGraph {
	my ($size, %options) = @_;

	my ($s1, $s2);

	if (ref $size eq 'ARRAY' && @$size == 2) {
		($s1, $s2) = @$size;
		die 'A bipartite graph must have at least 1 vertex in each partition.' unless $s1 > 0 && $s2 > 0;
	} else {
		die 'A bipartite graph must have at least 2 vertices.' if $size < 2;
		$s1 = main::random(1, $size - 1);
		$s2 = $size - $s1;
	}

	my $graph = GraphTheory::SimpleGraph->new($s1 + $s2, %options);

	my $edgeProbability = $options{edgeProbability} // 0.5;
	my $edgeCount       = 0;

	for my $i (0 .. $s1 - 1) {
		for my $j ($s1 .. $s1 + $s2 - 1) {
			next unless main::random(0, 100) <= 100 * $edgeProbability;
			$graph->addEdge($i, $j);
			++$edgeCount;
		}
	}

	return $graph->setRandomWeights(%options, edgeCount => $edgeCount)->shuffle;
}

sub randomTreeGraph {
	my ($size, %options) = @_;

	die 'A tree graph must have at least 2 vertices.' if $size < 2;

	my $graph = GraphTheory::SimpleGraph->new($size, %options);

	my @available = main::random_subset($size, 0 .. $size - 1);

	my @used;
	push @used, pop @available;
	do {
		my $j = pop @available;
		my $i = main::random(0, $#used);
		$graph->addEdge($used[$i], $j);
		push @used, $j;
	} while @available > 0;

	return $graph->setRandomWeights(%options, edgeCount => @used - 1);
}

sub randomForestGraph {
	my ($size, %options) = @_;

	die 'A forest graph must have at least 2 vertices.' if $size < 2;

	# Remove these from the options so that setting weights is deferred until the return.
	my ($startEdgeWeight, $edgeWeightIncrement, $edgeWeightRange) =
		delete @options{qw(startEdgeWeight edgeWeightIncrement edgeWeightRange)};

	my $graph = randomTreeGraph($size, %options);

	my ($vertex1, $vertex2);
	do {
		($vertex1, $vertex2) = main::random_subset(2, 0 .. $size - 1);
	} until $graph->hasEdge($vertex1, $vertex2);
	$graph->removeEdge($vertex1, $vertex2);

	return $graph->setRandomWeights(
		%options,
		startEdgeWeight     => $startEdgeWeight,
		edgeWeightIncrement => $edgeWeightIncrement,
		edgeWeightRange     => $edgeWeightRange
	);
}

# Returns a Hamiltonian graph of the given $size. Note that $size must be 5 or greater.
sub randomHamiltonianGraph {
	my ($size, %options) = @_;

	die 'A Hamiltonian graph must have at least 5 vertices.' if $size < 5;

	my $graph = GraphTheory::SimpleGraph->new($size, %options);

	my $comp = $size * ($size - 1) / 2;

	my ($low, $high) = $size <= 5 ? ($size + 1, $comp - 1) : (int($comp / 3) + 1, int($comp / 2) + 1);

	for my $i (0 .. $size - 1) {
		$graph->addEdge($i, ($i + 1) % $size);
	}

	my $edges = int main::random($low, $high);

	my $edgeCount = $size;
	while ($edgeCount < $edges) {
		my ($i, $j) = main::random_subset(2, 0 .. $size - 1);
		unless ($graph->hasEdge($i, $j)) {
			$graph->addEdge($i, $j);
			++$edgeCount;
		}
	}

	return $graph->setRandomWeights(%options, edgeCount => $edgeCount)->shuffle;
}

sub randomNonHamiltonianGraph {
	my ($size, $type, %options) = @_;

	my $graph     = GraphTheory::SimpleGraph->new($size);
	my $edgeCount = 0;

	if ($type % 2 == 0) {
		die 'A non Hamiltonian graph with a degree 1 vertex must have at least 5 vertices.' if $size < 5;

		my $numEdges = main::random($size + 1, ($size - 1) * ($size - 2) / 3 + 1);

		for my $i (0 .. $size - 2) {
			$graph->addEdge($i, $i + 1);
		}
		$graph->addEdge($size - 2, 0);

		$edgeCount = $size;
		do {
			my ($i, $j) = main::random_subset(2, 0 .. $size - 2);
			unless ($graph->hasEdge($i, $j)) {
				$graph->addEdge($i, $j);
				++$edgeCount;
			}
		} while $edgeCount < $numEdges;
	} else {
		die 'A non Hamiltonian graph with two cycles must have at least 6 vertices.' if $size < 6;

		my $split = int($size / 2);

		for my $i (0 .. $split - 1) {
			$graph->addEdge($i, ($i + 1) % $split);
		}
		for my $i ($split .. $size - 1) {
			$graph->addEdge($i, ($i + 1) % $size);
		}
		$graph->addEdge($size - 1, $split);

		my $numEdges = 2 * $size - 5;
		$edgeCount = $size + 1;

		my $maxtry = 4;    # Protection against a possibly infinite loop.
		while ($edgeCount < $numEdges && $maxtry > 0) {
			--$maxtry;
			my $v1 = main::random(0, $split - 1);
			my $v2 = ($v1 + 2) % $split;
			unless ($graph->hasEdge($v1, $v2)) {
				$graph->addEdge($v1, $v2);
				++$edgeCount;
			}
			unless ($graph->hasEdge($v1 + $split, $v2 + $split)) {
				$graph->addEdge($v1 + $split, $v2 + $split);
				++$edgeCount;
			}
		}
	}

	return $graph->setRandomWeights(%options, edgeCount => $edgeCount)->shuffle;
}

sub simpleGraphWithDegreeSequence {
	my ($degrees, %options) = @_;

	my @degrees = reverse num_sort(@$degrees);

	return if $degrees[0] >= @degrees;

	my $graph = GraphTheory::SimpleGraph->new(scalar @degrees, %options);

	my $value     = 0;
	my $vertex    = 0;
	my $edgeCount = 0;

	while ($vertex < @degrees && $value == 0) {
		$value = $degrees[$vertex] - $graph->vertexDegree($vertex);
		my $otherVertex = $vertex + 1;
		while ($value > 0 && $otherVertex < @degrees) {
			if ($graph->vertexDegree($otherVertex) < $degrees[$otherVertex]) {
				$graph->addEdge($vertex, $otherVertex);
				++$edgeCount;
				--$value;
			}
			++$otherVertex;
		}
		++$vertex;
	}

	return if $value != 0;

	return $graph->setRandomWeights(%options, edgeCount => $edgeCount);
}

sub cycleGraph {
	my ($size, %options) = @_;

	my $graph = GraphTheory::SimpleGraph->new($size, %options);

	for (0 .. $graph->lastVertexIndex) {
		$graph->addEdge($_, ($_ + 1) % $graph->numVertices);
	}

	return $graph->setRandomWeights(%options, edgeCount => $graph->numVertices);
}

sub completeGraph {
	my ($size, %options) = @_;

	my $graph = GraphTheory::SimpleGraph->new($size, %options);

	for my $i (0 .. $size - 1) {
		for my $j ($i + 1 .. $size - 1) {
			$graph->addEdge($i, $j);
		}
	}

	return $graph->setRandomWeights(%options, edgeCount => $graph->numVertices * ($graph->numVertices - 1) / 2);
}

sub wheelGraph {
	my ($size, %options) = @_;

	my $graph = GraphTheory::SimpleGraph->new($size, %options, wheelLayout => 0);

	for my $i (1 .. $size - 2) {
		$graph->addEdge($i, $i + 1);
		$graph->addEdge(0,  $i);
	}
	$graph->addEdge($size - 1, 1);
	$graph->addEdge(0,         $size - 1);

	return $graph->setRandomWeights(%options, edgeCount => ($graph->numVertices - 1) * 2);
}

sub completeBipartiteGraph {
	my ($m, $n, %options) = @_;

	my $graph =
		GraphTheory::SimpleGraph->new($m + $n, %options, bipartiteLayout => [ [ 0 .. $m - 1 ], [ $m .. $m + $n - 1 ] ]);

	for my $i (0 .. $m - 1) {
		for my $j ($m .. $m + $n - 1) {
			$graph->addEdge($i, $j);
		}
	}

	return $graph->setRandomWeights(%options, edgeCount => $m * $n);
}

package GraphTheory::SimpleGraph;

sub new {
	my ($class, $definition, %options) = @_;
	my $self = bless {}, ref($class) || $class;

	die 'A graph definition in the form of a numeric size, adjacency matrix, '
		. 'edge set, or another simple graph object is required.'
		unless defined $definition;

	if (ref $definition eq 'GraphTheory::SimpleGraph') {
		$self->{adjacencyMatrix} = [ map { [@$_] } @{ $definition->adjacencyMatrix } ];
		$self->{labels}          = [ @{ $definition->{labels} } ];
		$options{gridLayout}      //= $definition->{gridLayout};
		$options{bipartiteLayout} //= $definition->{bipartiteLayout};
		$options{wheelLayout}     //= $definition->{wheelLayout};
	} elsif (Value::classMatch($definition, 'Matrix')
		|| Value::classMatch($definition, 'EdgeSet')
		|| ref $definition eq 'ARRAY')
	{
		$definition = [ map { [ $_->value ] } @{ $definition->data } ] if Value::classMatch($definition, 'Matrix');
		$definition = $definition->data                                if Value::classMatch($definition, 'EdgeSet');

		my $haveLabels = ref $options{labels} eq 'ARRAY' && @{ $options{labels} };
		die 'Graphs with no vertices are not supported.' unless @$definition || $haveLabels;

		my @edgeSet;
		for (@$definition) {
			if (ref $_ ne 'GraphTheory::SimpleGraph::Value::Edge') { @edgeSet = (); last; }
			push(@edgeSet, $_->data);
		}
		if (!@edgeSet) {
			for (@$definition) {
				if (
					ref $_ ne 'ARRAY'
					|| @$_ < 2
					|| @$_ > 3
					|| (!Value::classMatch($_->[0], 'String')
						&& (Value::isReal($_->[0]) || ($_->[0] ^ $_->[0]) eq '0'))
					|| (!Value::classMatch($_->[1], 'String')
						&& (Value::isReal($_->[1]) || ($_->[1] ^ $_->[1]) eq '0'))
					)
				{
					@edgeSet = ();
					last;
				}
				push(@edgeSet, $_);
			}
		}

		if (@edgeSet || (!@$definition && $haveLabels)) {
			die 'Labels must be provided when using an edgeset definition.' unless $haveLabels;

			$definition = [ map { $_->{data} } @$definition ]
				if ref $definition->[0] eq 'GraphTheory::SimpleGraph::Value::Edge';

			$self->{labels}          = [ @{ $options{labels} } ];
			$self->{adjacencyMatrix} = [ map { [ (0) x @{ $self->{labels} } ] } @{ $self->{labels} } ];

			my %labelIndices = map { $self->{labels}[$_] => $_ } 0 .. $#{ $self->{labels} };

			for my $i (0 .. $#$definition) {
				die 'Invalid edge set format.' unless ref $definition->[$i] eq 'ARRAY';
				my @edge = @{ $definition->[$i] };
				die 'Invalid edge format.'                 unless @edge >= 2;
				die "Invalid vertex $edge[0] in edge set." unless defined $labelIndices{ $edge[0] };
				die "Invalid vertex $edge[1] in edge set." unless defined $labelIndices{ $edge[1] };
				$self->edgeWeight($labelIndices{ $edge[0] }, $labelIndices{ $edge[1] }, $edge[2] // 1);
			}
		} else {
			$self->{adjacencyMatrix} = [];
			for my $i (0 .. $#$definition) {
				die 'Invalid adjacency matrix format.' unless ref $definition->[$i] eq 'ARRAY';
				die 'The adjacency matrix for a graph must be a square matrix.'
					unless @{ $definition->[$i] } == @$definition;
				die 'The diagonal entries of the adjacency matrix must be zero.' if $definition->[$i][$i];
				for my $j ($i + 1 .. $#{ $definition->[$i] }) {
					die 'The adjacency matrix for a graph must be symmetric.'
						unless $definition->[$i][$j] == $definition->[$j][$i];
				}
				push(@{ $self->{adjacencyMatrix} }, [ @{ $definition->[$i] } ]);
			}
		}
	} else {
		die 'Graphs with no vertices are not supported.' unless $definition > 0;
		$self->{adjacencyMatrix} = [ map { [ (0) x $definition ] } 0 .. ($definition - 1) ];
	}

	if (ref $options{labels} eq 'ARRAY') {
		die 'Not enough vertex labels provided.' if @{ $options{labels} } < $self->numVertices;
		for (0 .. $self->lastVertexIndex) {
			die 'Labels cannot be undefined.' unless defined $options{labels}[$_];
		}
		$self->{labels} = [ @{ $options{labels} }[ 0 .. $self->lastVertexIndex ] ];
	}

	unless (defined $self->{labels}) {
		my $alphaOffset = main::random(0, 25 - $self->lastVertexIndex);
		$self->{labels} = [ ('A' .. 'Z')[ $alphaOffset .. $alphaOffset + $self->lastVertexIndex ] ];
	}

	$self->{gridLayout} = [ @{ $options{gridLayout} } ]
		if ref $options{gridLayout} eq 'ARRAY' && @{ $options{gridLayout} } == 2;

	if (ref $options{bipartiteLayout} eq 'ARRAY'
		&& @{ $options{bipartiteLayout} } == 2
		&& !grep { ref $_ ne 'ARRAY' } @{ $options{bipartiteLayout} })
	{
		$self->{bipartiteLayout} = [ map { [@$_] } @{ $options{bipartiteLayout} } ];
	} elsif ($options{bipartiteLayout}) {
		$self->{bipartiteLayout} = 1;
	}

	$self->{wheelLayout} = $options{wheelLayout} if defined $options{wheelLayout};

	return $self;
}

sub adjacencyMatrix {
	my $self = shift;
	return $self->{adjacencyMatrix};
}

sub edgeSet {
	my ($self, %options) = @_;

	my $context = Value::isContext($options{context}) ? $options{context} : Parser::Context->getCopy('EdgeSet');
	$self->addVerticesToContext($options{caseSensitive} // 1, $context);

	my @edgeSet;
	for my $i (0 .. $self->lastVertexIndex) {
		for my $j ($i + 1 .. $self->lastVertexIndex) {
			next unless $self->hasEdge($i, $j);
			push(
				@edgeSet,
				GraphTheory::SimpleGraph::Value::Edge->new(
					$context, $self->vertexLabel($i), $self->vertexLabel($j)
				)
			);
			$edgeSet[-1]->{open}  = '{';
			$edgeSet[-1]->{close} = '}';
		}
	}

	my $edgeSet = GraphTheory::SimpleGraph::Value::EdgeSet->new($context, @edgeSet);
	$edgeSet->{open}  = '{';
	$edgeSet->{close} = '}';
	return $edgeSet;
}

sub addVerticesToContext {
	my ($self, $caseSensitive, $context) = @_;
	$context = Value::isContext($context) ? $context : main::Context();
	$context->strings->add(
		map  { $_ => { caseSensitive => $caseSensitive // 1 } }
		grep { !defined $context->strings->all->{$_} } @{ $self->labels }
	);
	$context->strings->all->{$_}{isVertex} = 1 for @{ $self->labels };
	return;
}

sub numVertices {
	my $self = shift;
	return scalar @{ $self->{adjacencyMatrix} };
}

sub lastVertexIndex {
	my $self = shift;
	return $#{ $self->{adjacencyMatrix} };
}

sub numEdges {
	my $self      = shift;
	my $edgeCount = 0;
	for my $i (0 .. $self->lastVertexIndex) {
		for my $j (0 .. $i - 1) {
			next unless $self->hasEdge($i, $j);
			++$edgeCount;
		}
	}
	return $edgeCount;
}

sub labels {
	my ($self, $labels) = @_;
	if (ref $labels eq 'ARRAY') {
		die 'Not enough vertex labels provided.' if @$labels < $self->numVertices;
		$self->{labels} = [ @$labels[ 0 .. $self->numVertices ] ];
	}
	return $self->{labels};
}

sub labelsString {
	my $self = shift;
	return join(', ', @{ $self->{labels} });
}

sub vertexLabel {
	my ($self, $vertexIndex) = @_;
	return $self->{labels}[$vertexIndex];
}

sub vertexIndex {
	my ($self, $vertexLabel) = @_;
	for (0 .. $#{ $self->{labels} }) {
		return $_ if $vertexLabel eq $self->{labels}[$_];
	}
	return -1;
}

sub vertexDegree {
	my ($self, $vertex) = @_;
	my $degree = 0;
	for my $j (0 .. $self->lastVertexIndex) {
		++$degree if $self->hasEdge($vertex, $j);
	}
	return $degree;
}

sub degrees {
	my $self = shift;
	return map { $self->vertexDegree($_) } 0 .. $self->lastVertexIndex;
}

sub numComponents {
	my $self = shift;

	my @adjacencyMatrix = map { [@$_] } @{ $self->{adjacencyMatrix} };

	my $result = @adjacencyMatrix;
	for my $i (0 .. $#adjacencyMatrix) {
		my $connected = 0;
		for my $j ($i + 1 .. $#adjacencyMatrix) {
			if ($adjacencyMatrix[$i][$j] != 0) {
				++$connected;
				for my $k (0 .. $#adjacencyMatrix) {
					$adjacencyMatrix[$j][$k] += $adjacencyMatrix[$i][$k];
					$adjacencyMatrix[$k][$j] += $adjacencyMatrix[$k][$i];
				}
			}
		}
		--$result if $connected > 0;
	}
	return $result;
}

sub edgeWeight {
	my ($self, $i, $j, $weight) = @_;
	if (defined $weight) {
		$self->{adjacencyMatrix}[$i][$j] = $weight;
		$self->{adjacencyMatrix}[$j][$i] = $weight;
	}
	return $self->{adjacencyMatrix}[$i][$j];
}

sub addEdge {
	my ($self, $i, $j, $weight) = @_;
	$self->edgeWeight($i, $j, $weight || 1);
	return;
}

sub removeEdge {
	my ($self, $i, $j) = @_;
	$self->edgeWeight($i, $j, 0);
	return;
}

sub hasEdge {
	my ($self, $i, $j) = @_;
	return $self->edgeWeight($i, $j) != 0;
}

sub setRandomWeights {
	my ($self, %options) = @_;

	my $incrementalRandom =
		defined $options{startEdgeWeight}
		&& $options{startEdgeWeight} > 0
		&& ($options{edgeWeightIncrement} // 1) > 0;

	return $self
		unless $incrementalRandom
		|| (ref $options{edgeWeightRange} eq 'ARRAY' && @{ $options{edgeWeightRange} } >= 2);

	my $edgeCount = $options{edgeCount} // $self->numEdges;

	my @weights =
		$incrementalRandom
		? main::random_subset($edgeCount,
		map { $options{startEdgeWeight} + $_ * ($options{edgeWeightIncrement} // 1) } 0 .. $edgeCount - 1)
		: map { main::random(@{ $options{edgeWeightRange} }) } 1 .. $edgeCount;

	for my $i (0 .. $self->lastVertexIndex) {
		for my $j ($i + 1 .. $self->lastVertexIndex) {
			$self->edgeWeight($i, $j, shift(@weights) // 1) if $self->hasEdge($i, $j);
		}
	}

	return $self;
}

sub isEqual {
	my ($self, $other) = @_;
	return 0 unless ref $other eq 'GraphTheory::SimpleGraph';
	return 0 if @{ $self->{adjacencyMatrix} } != @{ $other->{adjacencyMatrix} };
	for my $i (0 .. $#{ $self->{adjacencyMatrix} }) {
		return 0 if @{ $self->{adjacencyMatrix}[$i] } != @{ $other->{adjacencyMatrix}[$i] };
		for my $j (0 .. $i - 1) {
			return 0 if $self->{adjacencyMatrix}[$i][$j] != $other->{adjacencyMatrix}[$i][$j];
		}
	}
	return 1;
}

sub isIsomorphic {
	my ($self, $other) = @_;

	return 0 unless ref $other eq 'GraphTheory::SimpleGraph' && $self->numVertices == $other->numVertices;

	my @degrees      = main::num_sort($self->degrees);
	my @otherDegrees = main::num_sort($other->degrees);
	for (0 .. $#degrees) {
		return 0 unless $degrees[$_] == $otherDegrees[$_];
	}

	my $permutations = [ [0] ];

	for my $i (1 .. $self->lastVertexIndex) {
		my @newPermutations;
		for my $permutation (@$permutations) {
			for my $j (0 .. @$permutation) {
				my @new = @$permutation;
				splice(@new, $j, 0, $i);
				push(@newPermutations, \@new);
			}
		}
		$permutations = \@newPermutations;
	}

	# The last permutation is the original vertex order, so remove it.
	pop @$permutations;

	for my $permutation (@$permutations) {
		my @shuffledGraph;
		for my $i (0 .. $other->lastVertexIndex) {
			for my $j (0 .. $other->lastVertexIndex) {
				$shuffledGraph[ $permutation->[$i] ][ $permutation->[$j] ] = $other->edgeWeight($i, $j);
			}
		}
		return 1 if $self->isEqual($self->new(\@shuffledGraph));
	}

	return 0;
}

sub image {
	my ($self, %options) = @_;

	return $self->gridLayoutImage(%options) if $self->{gridLayout};
	if ($self->{bipartiteLayout}) {
		return $self->bipartiteLayoutImage(%options) if ref $self->{bipartiteLayout} eq 'ARRAY';
		# Attempt to partition the graph into two sets in which no edge connects vertices in the same set.
		# If not found, then fall through and use the default circle layout.
		my ($top, $bottom) = $self->bipartitePartition;
		if (ref $top eq 'ARRAY' && ref $bottom eq 'ARRAY' && @$top && @$bottom) {
			$self->{bipartiteLayout} = [ $top, $bottom ];
			return $self->bipartiteLayoutImage(%options);
		}
	}
	return $self->wheelLayoutImage(%options) if defined $self->{wheelLayout};

	$options{width}      //= 250;
	$options{height}     //= $options{width};
	$options{showLabels} //= 1;

	my $plot = main::Plot(
		xmin      => -1.5,
		xmax      =>  1.5,
		ymin      => -1.5,
		ymax      =>  1.5,
		width     => $options{width},
		height    => $options{height},
		xlabel    => '',
		ylabel    => '',
		xvisible  => 0,
		yvisible  => 0,
		show_grid => 0
	);

	my $gap = 2 * $main::PI / ($self->numVertices || 1);

	for my $i (0 .. $self->lastVertexIndex) {
		my $iVertex = [ cos($i * $gap), sin($i * $gap) ];
		$plot->add_stamp(@$iVertex, color => 'blue');

		$plot->add_label(
			1.25 * $iVertex->[0], 1.25 * $iVertex->[1],
			label   => "\\\\($self->{labels}[$i]\\\\)",
			color   => 'blue',
			h_align => 'center',
			v_align => 'middle'
		) if $options{showLabels};

		my $u = 0.275;
		my $v = 1 - $u;

		for my $j ($i + 1 .. $self->lastVertexIndex) {
			if ($self->hasEdge($i, $j)) {
				my $jVertex = [ cos($j * $gap), sin($j * $gap) ];
				$plot->add_dataset($iVertex, $jVertex, color => 'black');

				if ($options{showWeights}) {
					my @vector = ($jVertex->[0] - $iVertex->[0], $jVertex->[1] - $iVertex->[1]);
					my $norm   = sqrt($vector[0]**2 + $vector[1]**2);
					my @perp   = ($vector[1] / $norm, -$vector[0] / $norm);
					$plot->add_label(
						$u * $iVertex->[0] + $v * $jVertex->[0] + $perp[0] * 0.06,
						$u * $iVertex->[1] + $v * $jVertex->[1] + $perp[1] * 0.06,
						label  => "\\\\($self->{adjacencyMatrix}->[$i][$j]\\\\)",
						color  => 'red',
						rotate => ($perp[0] < 0 ? 1 : -1) *
							atan2(sqrt(1 - $perp[1] * $perp[1]), $perp[1]) * 180 /
							$main::PI - ($perp[1] < 0 ? 180 : 0)
					);
				}
			}
		}
	}

	return $plot;
}

sub gridLayoutImage {
	my ($self, %options) = @_;

	die 'Grid layout is not defined, or is but does not have a row and column dimension.'
		unless ref $self->{gridLayout} eq 'ARRAY' && @{ $self->{gridLayout} } == 2;

	$options{showLabels} //= 1;

	my $gridGap    = 20;
	my $gridShift  = $gridGap / 2;
	my $labelShift = $gridGap / 15;

	my $plot = main::Plot(
		xmin      => -$gridShift,
		xmax      => $self->{gridLayout}[1] * $gridGap - $gridShift,
		ymin      => -$gridShift,
		ymax      => $self->{gridLayout}[0] * $gridGap - $gridShift,
		width     => 7 * ($self->{gridLayout}[1] - 1) * $gridGap,
		height    => 7 * ($self->{gridLayout}[0] - 1) * $gridGap,
		xlabel    => '',
		ylabel    => '',
		xvisible  => 0,
		yvisible  => 0,
		show_grid => 0
	);

	for my $i (0 .. $self->{gridLayout}[0] - 1) {
		for my $j (0 .. $self->{gridLayout}[1] - 1) {
			my $x = $gridGap * $j;
			my $y = $gridGap * ($self->{gridLayout}[0] - $i - 1);
			$plot->add_stamp($x, $y, color => 'blue');
			$plot->add_label(
				$x - $labelShift, $y + 2 * $labelShift,
				label   => "\\\\($self->{labels}[$i + $self->{gridLayout}[0] * $j]\\\\)",
				color   => 'blue',
				h_align => 'center',
				v_align => 'middle'
			) if $options{showLabels};
		}
	}

	my $u = 0.6666;
	my $v = 1 - $u;

	for my $i (0 .. $self->lastVertexIndex) {
		my $iVertex = [
			int($i / $self->{gridLayout}[0]) * $gridGap,
			($self->{gridLayout}[0] - ($i % $self->{gridLayout}[0]) - 1) * $gridGap
		];
		for my $j ($i + 1 .. $self->lastVertexIndex) {
			if ($self->hasEdge($i, $j)) {
				my $jVertex = [
					int($j / $self->{gridLayout}[0]) * $gridGap,
					($self->{gridLayout}[0] - ($j % $self->{gridLayout}[0]) - 1) * $gridGap
				];
				$plot->add_dataset($iVertex, $jVertex, color => 'black', width => 1);
				my $vector = [ $jVertex->[0] - $iVertex->[0], $jVertex->[1] - $iVertex->[1] ];
				if ($options{showWeights}) {
					my $norm = sqrt($vector->[0]**2 + $vector->[1]**2);
					$plot->add_label(
						$u * $iVertex->[0] + $v * $jVertex->[0] - $vector->[1] / $norm * 2,
						$u * $iVertex->[1] + $v * $jVertex->[1] + $vector->[0] / $norm * 2,
						label => "\\\\($self->{adjacencyMatrix}[$i][$j]\\\\)",
						color => 'red'
					);
				}
			}
		}
	}

	return $plot;
}

sub bipartiteLayoutImage {
	my ($self, %options) = @_;

	my ($top, $bottom);

	if (ref $self->{bipartiteLayout} eq 'ARRAY'
		&& @{ $self->{bipartiteLayout} } == 2
		&& !grep { ref $_ ne 'ARRAY' } @{ $self->{bipartiteLayout} })
	{
		($top, $bottom) = @{ $self->{bipartiteLayout} };
	} elsif ($self->{bipartiteLayout}) {
		($top, $bottom) = $self->bipartitePartition;
		die 'Graph is not bipartite.' unless ref $top eq 'ARRAY' && ref $bottom eq 'ARRAY' && @$top && @$bottom;
	} else {
		die 'Bipartite layout is not defined.';
	}

	$options{width}      //= 250;
	$options{height}     //= $options{width};
	$options{showLabels} //= 1;

	my ($low, $high, $width) = (0, 15, 20);
	my @shift = (0, 0);

	my $diff = @$top - @$bottom;

	my $x_max;
	if ($diff == 0) {
		$x_max = @$top * $width - 10;
	} elsif ($diff % 2 == 0 && $diff > 0) {
		$x_max = @$top * $width - 10;
		$shift[1] += $width * $diff / 2;
	} elsif ($diff % 2 == 0) {
		$x_max = @$bottom * $width - 10;
		$shift[0] += -$width * $diff / 2;
	} elsif ($diff > 0) {
		$x_max = @$top * $width - 10;
		$shift[1] += ($width / 2) * $diff;
	} else {
		$x_max = @$bottom * $width - 10;
		$shift[0] += (-$width / 2) * $diff;
	}

	my $plot = main::Plot(
		xmin      => -10,
		xmax      => $x_max,
		ymin      => -5,
		ymax      => 20,
		width     => $options{width},
		height    => $options{height},
		xlabel    => '',
		ylabel    => '',
		xvisible  => 0,
		yvisible  => 0,
		show_grid => 0
	);

	for my $i (0 .. $#$top) {
		$plot->add_stamp($i * $width + $shift[0], $high, color => 'blue');
		$plot->add_label(
			$i * $width + $shift[0], $high + 2 / 3,
			label   => "\\\\($self->{labels}[$top->[$i]]\\\\)",
			color   => 'blue',
			h_align => 'center',
			v_align => 'bottom'
		) if $options{showLabels};
	}
	for my $j (0 .. $#$bottom) {
		$plot->add_stamp($j * $width + $shift[1], $low, color => 'blue');
		$plot->add_label(
			$j * $width + $shift[1], $low - 2 / 3,
			label   => "\\\\($self->{labels}[$bottom->[$j]]\\\\)",
			color   => 'blue',
			h_align => 'center',
			v_align => 'top'
		) if $options{showLabels};
	}

	my ($u, $v) = $diff >= 0 ? (2 / 3, 1 / 3) : (1 / 3, 2 / 3);

	for my $i (0 .. $#$top) {
		for my $j (0 .. $#$bottom) {
			next unless $self->hasEdge($top->[$i], $bottom->[$j]);
			my $point1 = [ $i * $width + $shift[0], $high ];
			my $point2 = [ $j * $width + $shift[1], $low ];
			$plot->add_dataset($point1, $point2, color => 'black');
			if ($options{showWeights}) {
				my $vector = [ $point2->[0] - $point1->[0], $point2->[1] - $point1->[1] ];
				my $norm   = sqrt($vector->[0]**2 + $vector->[1]**2);
				$plot->add_label(
					$u * $point1->[0] + $v * $point2->[0] - $vector->[1] / $norm * 5 / 4,
					$u * $point1->[1] + $v * $point2->[1] + $vector->[0] / $norm * 5 / 4,
					label => "\\\\($self->{adjacencyMatrix}[ $top->[$i] ][ $bottom->[$j] ]\\\\)",
					color => 'red'
				);
			}
		}
	}

	return $plot;
}

sub wheelLayoutImage {
	my ($self, %options) = @_;

	die 'Wheel layout is not defined.' unless defined $self->{wheelLayout};

	$options{width}      //= 250;
	$options{height}     //= $options{width};
	$options{showLabels} //= 1;

	my $plot = main::Plot(
		xmin      => -1.5,
		xmax      =>  1.5,
		ymin      => -1.5,
		ymax      =>  1.5,
		width     => $options{width},
		height    => $options{height},
		xlabel    => '',
		ylabel    => '',
		xvisible  => 0,
		yvisible  => 0,
		show_grid => 0
	);

	my $gap = 2 * $main::PI / ($self->lastVertexIndex || 1);

	$plot->add_stamp(0, 0, color => 'blue');
	$plot->add_label(
		0.1, 0.2,
		label   => "\\\\($self->{labels}[ $self->{wheelLayout} ]\\\\)",
		color   => 'blue',
		h_align => 'center',
		v_align => 'middle'
	) if $options{showLabels};

	for my $i (0 .. $self->lastVertexIndex) {
		next if $i == $self->{wheelLayout};

		my $iRel = $i > $self->{wheelLayout} ? $i - 1 : $i;

		my $iVertex = [ cos($iRel * $gap), sin($iRel * $gap) ];
		$plot->add_stamp(@$iVertex, color => 'blue');

		$plot->add_label(
			1.25 * $iVertex->[0], 1.25 * $iVertex->[1],
			label   => "\\\\($self->{labels}[$i]\\\\)",
			color   => 'blue',
			h_align => 'center',
			v_align => 'middle'
		) if $options{showLabels};

		if ($self->hasEdge($self->{wheelLayout}, $i)) {
			$plot->add_dataset([ 0, 0 ], $iVertex, color => 'black');
			if ($options{showWeights}) {
				my $norm = sqrt($iVertex->[0]**2 + $iVertex->[1]**2);
				my @perp = ($iVertex->[1] / $norm, -$iVertex->[0] / $norm);
				$plot->add_label(
					0.5 * $iVertex->[0] + $iVertex->[1] / $norm * 0.1,
					0.5 * $iVertex->[1] - $iVertex->[0] / $norm * 0.1,
					label  => "\\\\($self->{adjacencyMatrix}->[ $self->{wheelLayout} ][$i]\\\\)",
					color  => 'red',
					rotate => ($perp[0] < 0 ? 1 : -1) *
						atan2(sqrt(1 - $perp[1] * $perp[1]), $perp[1]) * 180 /
						$main::PI - ($perp[1] < 0 ? 180 : 0)
				);
			}
		}

		for my $j ($i + 1 .. $self->lastVertexIndex) {
			next if $j == $self->{wheelLayout};

			my $jRel = $j > $self->{wheelLayout} ? $j - 1 : $j;

			if ($self->hasEdge($i, $j)) {
				my $jVertex = [ cos($jRel * $gap), sin($jRel * $gap) ];
				$plot->add_dataset($iVertex, $jVertex, color => 'black');

				if ($options{showWeights}) {
					my @vector = ($jVertex->[0] - $iVertex->[0], $jVertex->[1] - $iVertex->[1]);
					my $norm   = sqrt($vector[0]**2 + $vector[1]**2);
					my @perp   = ($vector[1] / $norm, -$vector[0] / $norm);
					$plot->add_label(
						0.5 * $iVertex->[0] + 0.5 * $jVertex->[0] + $vector[1] / $norm * 0.1,
						0.5 * $iVertex->[1] + 0.5 * $jVertex->[1] - $vector[0] / $norm * 0.1,
						label  => "\\\\($self->{adjacencyMatrix}->[$i][$j]\\\\)",
						color  => 'red',
						rotate => ($perp[0] < 0 ? 1 : -1) *
							atan2(sqrt(1 - $perp[1] * $perp[1]), $perp[1]) * 180 /
							$main::PI - ($perp[1] < 0 ? 180 : 0)
					);
				}
			}
		}
	}

	return $plot;
}

sub copy {
	my $self = shift;
	return $self->new($self);
}

sub shuffle {
	my ($self, $permuteLabels) = @_;
	my @shuffledGraph;
	my @vertexPermutation = main::random_subset($self->numVertices, 0 .. $self->lastVertexIndex);
	my @inverseVertexPermutation;    # Only needed if labels are also permuted.
	@inverseVertexPermutation[@vertexPermutation] = 0 .. $#vertexPermutation;
	for my $i (0 .. $self->lastVertexIndex) {
		for my $j (0 .. $self->lastVertexIndex) {
			$shuffledGraph[ $vertexPermutation[$i] ][ $vertexPermutation[$j] ] = $self->edgeWeight($i, $j);
		}
	}
	return $self->new(
		\@shuffledGraph,
		labels => $permuteLabels ? [ @{ $self->{labels} }[@inverseVertexPermutation] ] : $self->{labels},
		ref $self->{bipartiteLayout} eq 'ARRAY' ? () : (bipartiteLayout => $self->{bipartiteLayout}),
		defined $self->{wheelLayout}            ? (wheelLayout => $vertexPermutation[ $self->{wheelLayout} ]) : ()
	);
}

sub nearestNeighborPath {
	my ($self, $vertex) = @_;

	my @visited = (undef) x $self->numVertices;
	$visited[$vertex] = 1;

	my @path          = ($vertex);
	my $weight        = 0;
	my $currentVertex = $vertex;

	while (@path < $self->numVertices) {
		my $nearest;
		my $min = 0;
		for my $i (0 .. $self->lastVertexIndex) {
			next if $i == $currentVertex || defined $visited[$i] || $self->hasEdge($currentVertex, $i);
			if ($min == 0 || $self->edgeWeight($currentVertex, $i) < $min) {
				$min     = $self->edgeWeight($currentVertex, $i);
				$nearest = $i;
			}
		}
		last unless defined $nearest;
		push @path, $nearest;
		$visited[$nearest] = 1;
		$weight += $self->edgeWeight($currentVertex, $nearest);
		$currentVertex = $nearest;
	}

	if ($self->hasEdge($currentVertex, $vertex)) {
		push @path, $vertex;
		$weight += $self->edgeWeight($currentVertex, $vertex);
	}

	return (\@path, $weight);
}

sub kruskalGraph {
	my $self = shift;

	my $graph             = $self->copy;
	my $tree              = GraphTheory::SimpleGraph->new($graph->numVertices, labels => $graph->labels);
	my $numTreeComponents = $tree->numComponents;

	my $treeWeight = 0;

	my $weight = 0;
	my @treeWeights;

	my @weights;
	for my $i (0 .. $graph->lastVertexIndex) {
		for my $j ($i + 1 .. $graph->lastVertexIndex) {
			push(@weights, $graph->edgeWeight($i, $j)) if $graph->hasEdge($i, $j);
		}
	}
	@weights = main::num_sort(@weights);

	while (@weights > 0) {
		$weight = shift @weights;
		for my $i (0 .. $graph->lastVertexIndex) {
			for my $j ($i + 1 .. $graph->lastVertexIndex) {
				if ($graph->edgeWeight($i, $j) == $weight) {
					$graph->removeEdge($i, $j);
					$tree->addEdge($i, $j, $weight);
					my $currentTreeNumComponents = $tree->numComponents;
					if ($currentTreeNumComponents < $numTreeComponents) {
						$numTreeComponents = $currentTreeNumComponents;
						$treeWeight += $weight;
						push @treeWeights, $weight;
					} else {
						$tree->removeEdge($i, $j);
					}
					last;
				}
			}
		}
	}

	return ($tree, $treeWeight, \@treeWeights);
}

sub hasEulerCircuit {
	my $self = shift;

	return wantarray ? (0, $main::PG->maketext('This graph is not connected.')) : 0 if $self->numComponents != 1;

	for my $degree ($self->degrees) {
		return wantarray ? (0, $main::PG->maketext('The degrees of the vertices in this graph are not all even.')) : 0
			if $degree % 2 != 0;
	}

	return 1;
}

sub hasEulerTrail {
	my $self = shift;

	return wantarray ? (0, $main::PG->maketext('This graph is not connected.')) : 0 if $self->numComponents != 1;

	my ($odd, $even) = (0, 0);

	for my $degree ($self->degrees) {
		if   ($degree % 2 == 0) { ++$even }
		else                    { ++$odd }
	}

	return wantarray
		? (
			0,
			$main::PG->maketext(
				'This graph does not have two vertices of odd degree and all other vertices of even degree.')
		)
		: 0
		if $even != $self->numVertices && $odd != 2;
	return 1;
}

sub pathIsEulerTrail {
	my ($self, @path) = @_;

	my $graph = $self->copy;

	my $i = shift @path;
	do {
		my $j = shift @path;
		return
			wantarray ? (0, $main::PG->maketext('An edge traversed by this path does not exist in the graph.')) : 0
			unless $graph->hasEdge($i, $j);
		$graph->removeEdge($i, $j);
		$i = $j;
	} while @path > 0;

	for my $i (0 .. $graph->lastVertexIndex) {
		for my $j (0 .. $i - 1) {
			return wantarray ? (0, $main::PG->maketext('This path does not traverse all edges.')) : 0
				if $graph->hasEdge($i, $j);
		}
	}

	return 1;
}

sub pathIsEulerCircuit {
	my ($self, @path) = @_;
	my @isEulerTrail = $self->pathIsEulerTrail(@path);
	return wantarray ? @isEulerTrail                                           : 0 unless $isEulerTrail[0];
	return wantarray ? (0, $main::PG->maketext('This path is not a circuit.')) : 0 unless $path[0] == $path[-1];
	return 1;
}

sub hasCircuit {
	my $self = shift;

	my $graph = $self->copy;

	for (my $i = 0; $i < $graph->numVertices; ++$i) {
		my $sum = 0;
		for my $j (0 .. $graph->lastVertexIndex) {
			$sum += $graph->hasEdge($i, $j) ? 1 : 0;
		}
		if ($sum == 1) {
			for my $j (0 .. $graph->lastVertexIndex) {
				$graph->removeEdge($i, $j);
			}
			$i = -1;
		}
	}

	for my $i (0 .. $graph->lastVertexIndex) {
		for my $j ($i + 1 .. $graph->lastVertexIndex) {
			return 1 if $graph->hasEdge($i, $j);
		}
	}

	return 0;
}

sub isTree {
	my $self = shift;
	return wantarray ? (0, $main::PG->maketext('This graph has a circuit.'))    : 0 if $self->hasCircuit;
	return wantarray ? (0, $main::PG->maketext('This graph is not connected.')) : 0 if $self->numComponents > 1;
	return 1;
}

sub isForest {
	my $self = shift;
	return wantarray ? (0, $main::PG->maketext('This graph has a circuit.')) : 0 if $self->hasCircuit;
	return 1;
}

# Returns 1 if the given $graph is bipartite, and 0 otherwise.
sub isBipartite {
	my $self = shift;

	my @vertexColors = (0) x $self->numVertices;
	my @color        = (1, 2);

	my $done;
	do {
		my $i = 0;
		while ($vertexColors[$i] != 0) { ++$i; }
		$vertexColors[$i] = $color[0];

		my @verticesToClassify;
		push @verticesToClassify, $i;

		do {
			my $vertex       = shift @verticesToClassify;
			my $currentColor = $vertexColors[$vertex];
			for my $i (0 .. $self->lastVertexIndex) {
				if ($self->hasEdge($vertex, $i)) {
					return 0 if $currentColor == $vertexColors[$i];
					if ($vertexColors[$i] == 0) {
						push @verticesToClassify, $i;
						$vertexColors[$i] = $color[ 2 - $currentColor ];
					}
				}
			}
		} while @verticesToClassify;

		$done = 1;
		for my $i (0 .. $self->lastVertexIndex) {
			$done *= $vertexColors[$i];
		}
	} while $done == 0;

	return 1;
}

sub bipartitePartition {
	my $self = shift;

	my @partition = ([], []);

	my %partitionAssignments;

	my $done;
	do {
		my $i = 0;
		++$i while defined $partitionAssignments{$i};
		$partitionAssignments{$i} = 0;
		push(@{ $partition[0] }, $i);

		my @vertices;
		push @vertices, $i;

		do {
			my $vertex           = shift @vertices;
			my $currentPartition = $partitionAssignments{$vertex};
			for my $i (0 .. $self->lastVertexIndex) {
				if ($self->hasEdge($vertex, $i)) {
					return if defined $partitionAssignments{$i} && $currentPartition == $partitionAssignments{$i};
					if (!defined $partitionAssignments{$i}) {
						push @vertices, $i;
						$partitionAssignments{$i} = $currentPartition ? 0 : 1;
						push(@{ $partition[ $partitionAssignments{$i} ] }, $i);
					}
				}
			}
		} while @vertices;

		$done = 1;
		for my $i (0 .. $self->lastVertexIndex) {
			unless (defined $partitionAssignments{$i}) {
				$done = 0;
				last;
			}
		}
	} while !$done;

	$partition[0] = [ main::num_sort(@{ $partition[0] }) ];
	$partition[1] = [ main::num_sort(@{ $partition[1] }) ];

	return @partition;
}

sub dijkstraPath {
	my ($self, $start, $end) = @_;

	my ($ind, $new, @dist, @path, @prev, @used);

	for my $i (0 .. $self->lastVertexIndex) {
		$dist[$i] = -1;
		$prev[$i] = -1;
	}
	$dist[$start] = 0;

	my @available = (0 .. $self->lastVertexIndex);

	while (@available) {
		my $min = 1000000000;    # Infinity (for all practical purposes)
		for my $i (0 .. $#available) {
			my $loc = $available[$i];
			if ($dist[$loc] >= 0 && $dist[$loc] < $min) {
				$new = $loc;
				$ind = $i;
				$min = $dist[$new];
			}
		}
		push @used, $new;
		splice @available, $ind, 1;
		@used = main::num_sort(@used);

		for my $i (0 .. $self->lastVertexIndex) {
			my $weight = $self->edgeWeight($new, $i);
			if ($weight != 0) {
				if ($dist[$i] > $min + $weight || $dist[$i] < 0) {
					$dist[$i] = $min + $weight;
					$prev[$i] = $new;
				}
			}
		}
	}

	my $loc = $end;
	while ($loc != $start) {
		unshift @path, $loc;
		$loc = $prev[$loc];
	}
	unshift @path, $start;

	return ($dist[$end], @path);
}

sub sortedEdgesPath {
	my $self = shift;

	my @weights;
	my $sortedGraph = GraphTheory::SimpleGraph->new($self->numVertices, labels => $self->labels);

	for my $i (0 .. $self->lastVertexIndex) {
		for my $j ($i + 1 .. $self->lastVertexIndex) {
			next unless $self->hasEdge($i, $j);
			push @weights, $self->edgeWeight($i, $j);
		}
	}

	@weights = main::num_sort(@weights);

	# Returns 1 if an edge can be added to the sorted edges based graph and 0 otherwise. An edge can be added if it does
	# not make a vertex have more than two edges connected to it, and it does not create a circuit in the graph (unless
	# it is the last vertex in which case that is okay since it completes the circuit).
	my $goodEdge = sub {
		my $graph = shift;

		my $sum = 0;

		for my $i (0 .. $graph->lastVertexIndex) {
			my $degree = $graph->vertexDegree($i);
			return 0 if $degree > 2;
			$sum += $degree;
		}

		return $sum < 2 * $graph->numVertices && $graph->hasCircuit ? 0 : 1;
	};

	my @pathWeights;

	do {
		my $weight = shift @weights;
		for my $i (0 .. $sortedGraph->lastVertexIndex) {
			for my $j ($i + 1 .. $sortedGraph->lastVertexIndex) {
				if ($weight == $self->edgeWeight($i, $j)) {
					$sortedGraph->addEdge($i, $j, $self->edgeWeight($i, $j));
					if ($goodEdge->($sortedGraph)) {
						push @pathWeights, $weight;
					} else {
						$sortedGraph->removeEdge($i, $j);
					}
				}
			}
		}
	} while @pathWeights < $sortedGraph->numVertices && @weights > 0;

	return ($sortedGraph, \@pathWeights);
}

sub chromaticNumber {
	my $self = shift;
	return Chromatic::computeBestColoring(@{ $self->{adjacencyMatrix} });
}

sub kColoring {
	my ($self, $k) = @_;

	my @colors    = (-1) x $self->numVertices;
	my @nextColor = (0) x $self->numVertices;
	my $v         = 0;

	while ($v >= 0) {
		my $assigned = 0;
		while ($nextColor[$v] < $k) {
			my $c  = ++$nextColor[$v];
			my $ok = 1;
			for my $u (0 .. $self->lastVertexIndex) {
				if ($self->hasEdge($v, $u) && $colors[$u] == $c) {
					$ok = 0;
					last;
				}
			}
			if ($ok) {
				$colors[$v] = $c;
				++$v;
				return @colors if $v == $self->numVertices;
				$nextColor[$v] = 0;
				$assigned = 1;
				last;
			}
		}
		unless ($assigned) {
			$colors[$v]    = -1;
			$nextColor[$v] = 0;
			--$v;
		}
	}

	return;
}

# The GraphTheory::SimpleGraph::Parser::List, GraphTheory::SimpleGraph::EdgeSet and GraphTheory::SimpleGraph::Edge
# packages are special lists for the edgeSet return value context.

package GraphTheory::SimpleGraph::Parser::List;
our @ISA = qw(Parser::List::List);

sub _check {
	my $self = shift;
	$self->SUPER::_check;

	# Only handle implicit lists or lists explicitly opened with a brace.
	return if $self->{open} && $self->{open} ne '{';

	my $entryType = $self->typeRef->{entryType};

	# Since there can only be one brace paren, the distinction between an edge and an edge set needs to be made here.
	# An empty list or a list that contains another list is an edge set.  All other lists are edges.
	my $isEdgeSet = $self->length ? 0 : 1;
	for (@{ $self->{coords} }) {
		if ($_->{type}{list} && $_->{type}{list} == 1) { $isEdgeSet = 1; last; }
	}

	if ($isEdgeSet) {
		$self->{type} = Value::Type('EdgeSet', scalar(@{ $self->{coords} }), $entryType, list => 1);
	} elsif ($self->{type}{name} ne 'Edge') {
		$self->{type} = Value::Type('Edge', scalar(@{ $self->{coords} }), $entryType, list => 1);
	}

	if ($self->{type}{name} eq 'Edge') {
		my $strings = $self->context->strings->all;
		for (@{ $self->{coords} }) {
			$self->Error('An edge may only contain vertices.')
				unless ref $_ eq 'Parser::String'
				&& defined $strings->{ $_->{value} }
				&& $strings->{ $_->{value} }{isVertex};
		}
		$self->Error('An edge must contain exactly two vertices.') if $self->length != 2;
	} elsif ($self->{type}{name} eq 'EdgeSet') {
		for (@{ $self->{coords} }) {
			$self->Error('An edge set may only contain edges.') unless $_->{type}{name} eq 'Edge';
		}
	}
}

package GraphTheory::SimpleGraph::Value::EdgeSet;
our @ISA = qw(Value::List);

sub cmp_defaults {
	my ($self, %options) = @_;
	return (
		$self->SUPER::cmp_defaults(%options),
		entry_type     => 'edge',
		list_type      => 'edge set',
		removeParens   => 0,
		showParenHints => 1,
		implicitList   => 0
	);
}

sub compare {
	my ($l, $r, $flag) = @_;
	my $self = $l;
	$r = $self->promote($r);
	if ($flag) { my $tmp = $l; $l = $r; $r = $tmp }
	my @l = main::num_sort($l->value);
	my @r = main::num_sort($r->value);
	while (@l && @r) {
		my $cmp = shift(@l) <=> shift(@r);
		return $cmp if $cmp;
	}
	return @l - @r;
}

package GraphTheory::SimpleGraph::Value::Edge;
our @ISA = qw(Value::List);

sub cmp_defaults {
	my ($self, %options) = @_;
	return (
		$self->SUPER::cmp_defaults(%options),
		entry_type     => 'vertex',
		list_type      => 'edge',
		removeParens   => 0,
		showParenHints => 1,
		implicitList   => 0
	);
}

sub compare {
	my ($l, $r, $flag) = @_;
	my $self = $l;
	$r = $self->promote($r);
	if ($flag) { my $tmp = $l; $l = $r; $r = $tmp }
	my @l = main::num_sort($l->value);
	my @r = main::num_sort($r->value);
	while (@l && @r) {
		my $cmp = shift(@l) <=> shift(@r);
		return $cmp if $cmp;
	}
	return @l - @r;
}

1;

=head1 NAME

SimpleGraph.pl - Tools for displaying and manipulating simple graphs from graph
theory.

=head1 DESCRIPTION

The core of this macro is the C<GraphTheory::SimpleGraph> object which
represents simple graphs from graph theory via an adjacency matrix.

=head1 FUNCTIONS

The following functions can be used to construct a C<GraphTheory::SimpleGraph>
object.

=head2 SimpleGraph

    $graph = SimpleGraph($definition, %options);

This is an alias for the C<GraphTheory::SimpleGraph> constructor.

The C<$definition> argument is required and can be the number of vertices in the
graph, another C<GraphTheory::SimpleGraph> object, a reference to an array of
arrays of numbers, a reference to a MathObject C<Matrix>, a reference to an
array of arrays containing two strings and possibly a number (an edge set with
optional edge weights), a reference to an array of
C<GraphTheory::SimpleGraph::Value::Edge> objects, or a reference to a
C<GraphTheory::SimpleGraph::Value::EdgeSet> object.

If C<$definition> is the number of vertices in the graph, then the graph that is
returned will have that number of vertices and no edges. Note that the number of
vertices must be greater than 0.

If C<$definition> is another C<GraphTheory::SimpleGraph> object, then a copy of
the graph represented by that object will be returned.

If C<$definition> is a one of the matrix forms (a reference to an array of
arrays of numbers or a reference to a MathObject C<Matrix>), then that matrix
will be used for the adjacency matrix of the graph. Note that it must be a
square symmetric matrix with zero entries along the diagonal and must have size
greater than or equal to 1. For example,

    [
        [ 0, 1, 0],
        [ 1, 0, 2],
        [ 0, 2, 0]
    ]

represents a graph that has three vertices, an edge between the first and
second vertices with weight one, and an edge between the second and third
vertices with weight 2.

If C<$definition> is one of the edge set definition forms (a reference to an
array of arrays containing two strings and possibly a number, a reference to an
array of C<GraphTheory::SimpleGraph::Value::Edge> objects, or a reference to a
C<GraphTheory::SimpleGraph::Value::EdgeSet> object), then the C<labels> option
is required.  For the reference to an array of arrays form each edge in the edge
set must be an array containing two strings and possibly a third numeric
element. The two strings are the labels for the vertices connected by the edge.
The optional third element is the weight of the edge. If the optional third
element is not given, then the edge will have a weight of one.  Note that all
labels provided in the C<labels> option will be used with this definition, and
will all be vertices in the graph. For example, if C<$definition> is given as

    [
        [ 'A', 'B' ],
        [ 'A', 'C', 2 ],
        [ 'B', 'C', 3 ],
    ]

and the C<labels> option is C<['A', 'B', 'C', 'D']>, then the return object will
represent a graph that has at four vertices labeled 'A', 'B', 'C', and 'D',
respectively, an edge between 'A' and 'B' with weight one, an edge between 'A'
and 'C' with weight 2, an edge between 'B' and 'C' with weight 3, and no edges
connecting to the vertex 'D'. Note that setting weights when a graph is
constructed via a reference to an array of C<GraphTheory::SimpleGraph::Edge>
objects or a reference to a C<GraphTheory::SimpleGraph::EdgeSet> object is not
supported. However, weights can still be set after construction with the
L</edgeWeight> method or the L</setRandomWeights> method.

The arguments that may be passed in C<%options> are as follows. Note that all of
these options are undefined by default.

=over

=item labels

The value of this option must be a reference to an array of strings. These are
the labels for the vertices of the graph. The array must contain at least as
many strings as there are vertices of the graph. Any extraneous strings will not
be used (except in the edge set definition case as mentioned above). If this
option is not given, then a random set of consecutive letters from the alphabet
will be used for the labels of the vertices. Note that if an edge set version of
the C<$definition> argument is used, then this option must be provided.

=item gridLayout

If this option is given, then it must be a reference to an array containing two
numbers, for example, C<[3, 4]>. In this case when the L</image> method is
called to create the image of the graph, the vertices will be arranged into a
grid with the number of rows equal to the first number in the array, and the
number of columns equal to the second number in the array. Note that many graphs
will not work well in a grid layout. This is primarily intended for graphs
created via the L</randomSimpleGraph> function where its first argument is used
as the value for this option. This option is generally intended for internal use
in this macro specifically for that function. However, there may be other graphs
that may also work well in a grid layout.

=item bipartiteLayout

If this option is given, then it must either be 1 or a reference to an array
containing two arrays of vertex indices. If this is 1, then a partition of the
vertices into two sets in which no two vertices in the same set are connected by
an edge will attempt to be obtained internally via the L</bipartitePartition>
method. If the graph is not bipartite then no such partition will be found and
the L</image> method will not use the bipartite layout. Instead the image will
be displayed in the default circle layout.  If this is an array containing two
arrays of vertex indices, then the two arrays must be the partition of the
vertices of the graph in which no two vertices in the same set are connected by
an edge. In this case when the L</image> method is called to create the image of
the graph, the vertices will be arranged into to rows with the vertices in the
first set in the top row, and the vertices in the second set in the bottom row.
Note that an exception will be thrown if this option is 1 and the graph is not
bipartite.

=item wheelLayout

If this option is given, then it must be an index of one of the vertices in the
graph (0, 1, 2, ...), and when the L</image> method is called to create the image
of the graph, that vertex will be placed in the center of a circle, and the
other vertices will be evenly spaced around the perimeter of the circle.

=back

=head2 randomSimpleGraph

    $graph = randomSimpleGraph($size, %options);

This function returns a C<GraphTheory::SimpleGraph> object in which the
existence of an edge between any two vertices is randomly determined.

The C<$size> argument is required and must either be an integer that is greater
than zero, or a reference to an array containing two integers, both of which are
greater than zero. If this argument is an integer that is greater than zero,
then that will be the number of vertices of the graph. If this argument is a
reference to an array containing two integers that are greater than zero, then
the number of vertices in the graph will be the product of those two integers.
Furthermore, this array reference will be passed as the C<gridLayout> option to
the C<GraphTheory::SimpleGraph> constructor, and the image of the graph will
have the vertices arranged into rows and columns. Furthermore, in the graph will
be generated such that the only possible edges will connect vertices that are
adjacent in that grid (including diagonal adjacency).

The arguments that may be passed in C<%options> are as follows.

=over

=item labels

The value of this option, if given, must be a reference to an array of strings.
These are the labels for the vertices of the graph. The array must contain at
least as many strings as there are vertices of the graph. Any extraneous strings
will not be used (except in the edge set definition case as mentioned above). If
this option is not given, then a random set of consecutive letters from the
alphabet will be used for the labels of the vertices.

=item edgeProbability

This is the probability that there will be an edge between any two vertices. By
default this is 0.5. Note that if C<$size> is a reference to an array of
integers, then this only applies to vertices that are adjacent in the grid, and
there will never be edges between vertices that are not adjacent in the grid.

=item edgeWeightRange

If this is given, then it must be a reference to an array of two or three
numbers. In this case the weights of the edges will be a random number from the
first number to the second number with increments of the optional third number
(the increment defaults to 1). In fact the elements of this array are passed
directly to the C<random> function (see L<PGbasicmacros.pl/Pseudo-random number
generator>). Note that the C<startEdgeWeight> option takes precedence over this
option, and if it is given and is an integer greater than one, then it will be
used instead of this option. Furthermore, if neither this option nor the
C<startEdgeWeight> option are given, then all edge weights will be 1.

=item startEdgeWeight

If this option is given, then it must be an integer that is greater than zero.
In this case this will be the first edge weight used in the generated graph, and
the other edge weights will be determined by adding increments of the
following C<edgeWeightIncrement> option.

=item edgeWeightIncrement

If this option is given, then it must be an integer that is greater than zero.
Note that this is only used if C<startEdgeWeight> is also given and is greater
than zero, and in that case increments of this number will be added to the
C<startEdgeWeight> and used for the weights of the edges. If the
C<startEdgeWeight> is given, is an integer greater than 0, and this option is
undefined, then an edge weight increment of 1 will be used.

=back

The examples below demonstrate the usage of this function and its options in
more details.

    $graph = randomSimpleGraph(random(3, 5), edgeProbability => 1);

will return a complete graph with 3, 4, or 5 vertices and all edge weights equal
to 1.

    $graph = randomSimpleGraph(random(3, 5), edgeProbability => 0);

will return a graph with 3, 4, or 5 vertices that has no edges. Note that
C<$graph = SimpleGraph(random(3, 5))> is equivalent and is slightly more
efficient.

    $graph = randomSimpleGraph(
        5,
        edgeProbability   => 0.3,
        edgeWeightRange => [1, 10]
    );

will return a graph with 5 vertices with probability 0.3 of an edge between any
two vertices, and random edge weights from 1 to 10 (in increments of 1).

    $graph = randomSimpleGraph(
        5,
        startEdgeWeight     => 2,
        edgeWeightIncrement => 3
    );

will return a graph with 5 vertices with probability 0.5 of an edge between any
two vertices, and the edge weights will be 2, 5, 8, 11, ... (which will be
randomly assigned to the edges in the graph).

    $graph = randomSimpleGraph([3, 4], edgeProbability => 0.6);

will return a graph with 12 vertices and all edge weights equal to 1. When the
image of this graph is displayed the vertices will be arranged into a grid with
3 rows and 4 columns. The probability of an edge between vertices that are
adjacent in the grid is 0.6.  There will be no edges between vertices that are
not adjacent in the grid.

=head2 randomGraphWithEulerCircuit

    $graph = randomGraphWithEulerCircuit($size, %options);

This function returns a C<GraphTheory::SimpleGraph> object that represents a
random graph with C<$size> vertices that has an Euler circuit. This function
also accepts the C<labels>, C<startEdgeWeight>, C<edgeWeightIncrement>, and
C<edgeWeightRange> options accepted by the L</randomSimpleGraph> function.

=head2 randomGraphWithEulerTrail

    $graph = randomGraphWithEulerTrail($size, %options);

This function returns a C<GraphTheory::SimpleGraph> object that represents a
random graph with C<$size> vertices that has an Euler trail, but does not have
an Euler circuit.  This function also accepts the C<labels>, C<startEdgeWeight>,
C<edgeWeightIncrement>, and C<edgeWeightRange> options accepted by the
L</randomSimpleGraph> function.

=head2 randomGraphWithoutEulerTrail

    $graph = randomGraphWithoutEulerTrail($size, %options);

This function returns a C<GraphTheory::SimpleGraph> object that represents a
random graph with C<$size> vertices that does not have an Euler trail (or
circuit). This function also accepts the C<labels>, C<startEdgeWeight>,
C<edgeWeightIncrement>, and C<edgeWeightRange> options accepted by the
L</randomSimpleGraph> function.

=head2 randomBipartiteGraph

    $graph = randomBipartiteGraph($size, %options);

This function returns a C<GraphTheory::SimpleGraph> object that represents a
random bipartite graph.

The C<$size> argument can either be a number or a reference to an array of two
integers that are greater than zero. If it is a number, then the graph will have
C<$size> vertices, and the number of vertices in the two parts of the bipartite
partition will be randomly determined. If it is a reference to an array of two
integers, then graph will have the number of vertices equal to the sum of those
two numbers, and the two sets in the bipartite partition will have those numbers
of elements.

This function also accepts the C<labels>, C<edgeProbability>,
C<startEdgeWeight>, C<edgeWeightIncrement>, and C<edgeWeightRange> options
accepted by the L</randomSimpleGraph> function.

=head2 randomTreeGraph

    $graph = randomTreeGraph($size, %options);

This function returns a C<GraphTheory::SimpleGraph> object that represents a
random graph with C<$size> vertices that is a tree. This function also accepts
the C<labels>, C<startEdgeWeight>, C<edgeWeightIncrement>, and
C<edgeWeightRange> options accepted by the L</randomSimpleGraph> function.

=head2 randomForestGraph

    $graph = randomForestGraph($size, %options);

This function returns a C<GraphTheory::SimpleGraph> object that represents a
random graph with C<$size> vertices that is a forest, but is not a tree. This
function also accepts the C<labels>, C<startEdgeWeight>, C<edgeWeightIncrement>,
and C<edgeWeightRange> options accepted by the L</randomSimpleGraph> function.

=head2 randomHamiltonianGraph

    $graph = randomHamiltonianGraph($size, %options);

This function returns a C<GraphTheory::SimpleGraph> object that represents a
random graph with C<$size> vertices that is Hamiltonian. Note that C<$size> must
be 5 or more, or an exception will be thrown. The C<labels> may be passed in
C<%options>, and is the same as for the above functions.

=head2 randomNonHamiltonianGraph

    $graph = randomNonHamiltonianGraph($size, $type, %options);

This function returns a C<GraphTheory::SimpleGraph> object that represents a
random graph with C<$size> vertices that is not Hamiltonian.

If C<$type> is even, then the graph will have a vertex of degree one. If
C<$type> is odd, then the graph will consist of two cycles joined by a single
edge. Note that for the odd C<$type> graph, the C<$size> must be at least 6, or
an exception will be thrown.

This function also accepts the C<labels>, C<startEdgeWeight>,
C<edgeWeightIncrement>, and C<edgeWeightRange> options accepted by the
L</randomSimpleGraph> function.

=head2 randomGraphWithDegreeSequence

    $graph = randomGraphWithDegreeSequence($degrees, %options);

This function returns a C<GraphTheory::SimpleGraph> object that represents a
random graph that has the given C<$degree> sequence, if such a graph is
possible, and undefined otherwise.

The C<$degrees> argument must be a reference to an array containing the desired
vertex degrees.

This function also accepts the C<labels>, C<startEdgeWeight>,
C<edgeWeightIncrement>, and C<edgeWeightRange> options accepted by the
L</randomSimpleGraph> function.

=head2 cycleGraph

    $graph = cycleGraph($size, %options);

This function returns a C<GraphTheory::SimpleGraph> object that represents a
graph with C<$size> vertices that is a cycle. This function also accepts the
C<labels>, C<startEdgeWeight>, C<edgeWeightIncrement>, and C<edgeWeightRange>
options accepted by the L</randomSimpleGraph> function.

=head2 completeGraph

    $graph = completeGraph($size, %options);

This function returns a C<GraphTheory::SimpleGraph> object that represents a
graph with C<$size> vertices that is a complete graph. This function also
accepts the C<labels>, C<startEdgeWeight>, C<edgeWeightIncrement>, and
C<edgeWeightRange> options accepted by the L</randomSimpleGraph> function.

=head2 wheelGraph

    $graph = wheelGraph($size, %options);

This function returns a C<GraphTheory::SimpleGraph> object that represents a
graph with C<$size> vertices that is a wheel. This function also accepts the
C<labels>, C<startEdgeWeight>, C<edgeWeightIncrement>, and C<edgeWeightRange>
options accepted by the L</randomSimpleGraph> function.

Note that the returned graph object will have the C<wheelLayout> graph option
set to the vertex at the hub of the wheel, and that vertex will be displayed in
the center in the graph image.

=head2 completeBipartiteGraph

    $graph = completeBipartiteGraph($m, $n, %options);

This function returns a C<GraphTheory::SimpleGraph> object that represents a
graph with C<$m * $n> vertices that is a complete bipartite graph with C<$m>
vertices in first set in the bipartite partition, and C<$n> vertices in the
other set in the bipartite partition. This function also accepts the C<labels>,
C<startEdgeWeight>, C<edgeWeightIncrement>, and C<edgeWeightRange> options
accepted by the L</randomSimpleGraph> function.

Note that the returned graph object will have the C<bipartiteLayout> graph
option set so that the graph image is nicely displayed with the vertices in the
first set in the bipartite partition in a row on the top, and the vertices in
the other set in a row on the bottom.

=head2 EdgeSet

    $edgeSet = EdgeSet($edges);
    $edgeSet = EdgeSet($edge1, $edge2, ...);

This method is an alias for the C<GraphTheory::SimpleGraph::Value::EdgeSet>
MathObject constructor.  It can be passed a reference to an array of edges or
just a list of edges. An edges can be a reference to an array containing two
vertices, or can be a C<GraphTheory::SimpleGraph::Value::Edge> MathObject. As
with all MathObject constructors, the first argument can optionally be a
context. Note that vertices must be strings in the current context or the
context that is passed.

Since this derives from a MathObject C<List>, a C<list_checker> must be used for
a custom checker routine.

Usually this would only be used in the C<EdgeSet> context. Otherwise the
returned value will not display correctly in the problem and will not work well
as an answer.  However, the object can still be passed to the C<SimpleGraph>
function to create a graph with that edge set.

=head2 Edge

    $edge = Edge($vertex1, $vertex2);
    $edge = EdgeSet([ $vertex1, $vertex2 ]);

This method is an alias for the C<GraphTheory::SimpleGraph::Value::Edge>
MathObject constructor.  It can be passed a reference to an array containing two
vertices or a list of two vertices. As with all MathObject constructors, the
first argument can optionally be a context. Note that vertices must be strings
in the current context or the context that is passed.

Since this derives from a MathObject C<List>, a C<list_checker> must be used for
a custom checker routine.

Usually this would only be used in the C<EdgeSet> context. Otherwise the
returned value will not display correctly in the problem and will not work well
as an answer. However, the object can still be passed in an array reference to
the C<SimpleGraph> function to create a graph with that edge set.

=head1 GraphTheory::SimpleGraph Methods

The C<GraphTheory::SimpleGraph> package is the heart of this macro. All of the
functions described above return an object that is an instance of this package
class. See the L</SimpleGraph> function for the constructor usage. In addition,
the following object methods are available.

=head2 adjacencyMatrix

    $matrix = $graph->adjacencyMatrix;

This method returns the adjacency matrix that defines the graph. That is a
reference to an array of array references each containing numbers. The matrix
will be a symmetric square matrix with zero entries along the diagonal. The
entry in the i-th row and j-th column will be zero if there is not an edge
connecting the i-th and j-th vertex, and will be nonzero if there is such an
edge. Furthermore, the entry represents the edge weight in the case that it is
not zero.

Note that indexing of vertices is zero based. So the first vertex has index 0,
and the last vertex has index one less than the number of vertices in the graph.

=head2 edgeSet

    $edgeSet = $graph->edgeSet(%options);

This method returns the edge set for the graph as a MathObject C<EdgeSet>
containing MathObject C<Edge>s. For example, if a graph has adjacency matrix

    [
        [ 0, 1, 0, 0 ],
        [ 1, 0, 1, 0 ],
        [ 0, 1, 0, 1 ]
        [ 0, 0, 1, 0 ]
    ]

and labels 'A', 'B', 'C', and 'D', then this method would return

    {{A, B}, {B, C}, {C, D}}

where the outer set is a MathObject C<EdgeSet>, the elements of that set are
MathObject C<Edge>s, and the elements of those sets are MathObject C<String>s.
The returned C<EdgeSet> will be either be in a created C<EdgeSet> context with
the vertex labels of the graph defined as strings and marked as being vertices
in that context, or in a context provided in the C<%options> as described below.

This return value can be used as an answer to a question, and will display in
output as shown above.

Note, that edge weights are not represented in the return value of this method.

The following options that may be passed in C<%options>.

=over

=item context (Default: C<< context => undef >>)

The context to use for the returned MathObject C<EdgeSet> object. If this is not
provided, then a C<EdgeSet> context will be created, the vertex labels added as
strings to the context and marked as being vertices and the returned object will
be in the created context.

=item caseSensitive (Default: C<< caseSensitive => 1 >>)

Whether vertex labels that are added to the context are case sensitive or not.

=back

=head2 addVerticesToContext

    $graph->addVerticesToContext($caseSensitive, $context);

This adds the vertex labels of the graph to the context and marks them as being
vertices (by adding the C<isVertex> flag).

The C<$caseSensitive> and C<$context> arguments are optional.

If C<$caseSensitive> is 1 or the argument is not provided, then the vertices
will be case sensitive.  So entering "a" will not be accepted as correct for the
vertex labeled "A". If C<$caseSensitive> is 0, then vertices will not be case
sensitive.  So "a" will be accepted as correct for the vertex labeled "A".

If C<$context> is provided, then the strings will be added to that context.
Otherwise the strings will be added to the current context.

=head2 numVertices

    $n = $graph->numVertices;

This method returns the number of vertices in the graph.

=head2 lastVertex

    $n = $graph->lastVertexIndex;

This method returns the index of the last vertex in the graph (i.e., it is one
less then the number of vertices).

=head2 numEdges

    $n = $graph->numEdges;

This method returns the number of edges in the graph.

=head2 labels

    $labels = $graph->labels;
    $graph->labels($labels);

Get or set the vertex labels for the graph. In both examples above, C<$labels>
is a reference to an array of strings, for example, C<[ 'M', 'N', 'O', 'P' ]>.

=head2 labelsString

    $labelsString = $graph->labelsString;

This returns the vertex labels joined with a comma. This is a convenience method
for displaying labels in a problem. For example, the labels string can be
inserted into a PGML block with C<< [`[$graph->labelsString]`] >>.

=head2 vertexLabel

    $label = $graph->vertexLabel($index);

This method returns the label of the vertex at index C<$index> in the graph.

=head2 vertexIndex

    $index = $graph->vertexIndex($label);

This method returns the index of the vertex in the graph that is labeled
C<$label> if the given C<$label> exists for a vertex, and -1 otherwise.

=head2 vertexDegree

    $degree = $graph->vertexDegree($index);

This method returns the degree of the vertex at index C<$index> in the graph.

=head2 degrees

    @degrees = $graph->degrees;

This method returns an array of the degrees of the vertices in the graph.

=head2 numComponents

    $c = $graph->numComponents;

This method returns the number of connected components in the graph.

=head2 edgeWeight

    $c = $graph->edgeWeight($i, $j);
    $graph->edgeWeight($i, $j, $weight);

Get or set the weight of the edge between the vertices at indices C<$i> and
C<$i>. If the optional third C<$weight> argument is provided, then the weight
of the edge between the vertices at indices C<$i> and C<$j> will be set to
C<$weight>. In any case, the weight of the edge between the vertices at indices
C<$i> and C<$j> will be returned. Note that an edge weight of zero means that
there is no edge connecting the vertices.

Setting the edge weight to zero is equivalent to removing the edge if it was
nonzero, and setting the edge weight to a nonzero number when it was zero adds
an edge. However, if your only intent is to add or remove an edge, then it is
recommended to use the C<addEdge> or C<removeEdge> methods instead for clarity
in the code.

=head2 addEdge

    $graph->addEdge($i, $j, $weight);

Add and edge that connects the vertices at indices C<$i> and C<$j>. The
C<$weight> argument is optional, and if not provided the weight of the edge will
be set to 1.

=head2 removeEdge

    $graph->removeEdge($i, $j);

Remove the edge that connects the vertices at indices C<$i> and C<$j>. This is
accomplished by setting the weight of the edge between the two vertices to 0.

=head2 hasEdge

    $graph->hasEdge($i, $j);

This method returns a true value if the graph has an edge that connects the
vertices at indices C<$i> and C<$j>, and a false value otherwise.

=head2 setRandomWeights

    $graph->setRandomWeights(%options);

Set random weights for the edges of the graph.  This method does not add or
remove any edges, but randomly sets the weights of the existing edges.

The arguments that may be passed in C<%options> are as follows. If neither of
the C<startEdgeWeight> or C<edgeWeightRange> options is given, then this
method does not change the current edge weights of the graph.

=over

=item startEdgeWeight

If this option is given, then it must be an integer that is greater than zero.
In this case this will be the first edge weight used in the generated graph, and
the other edge weights will be determined by adding increments of the
following C<edgeWeightIncrement> option.

=item edgeWeightIncrement

If this option is given, then it must be an integer that is greater than zero.
Note that this is only used if C<startEdgeWeight> is also given and is greater
than zero, and in that case increments of this number will be added to the
C<startEdgeWeight> and used for the weights of the edges. If the
C<startEdgeWeight> is given, is an integer greater than 0, and this option is
undefined, then an edge weight increment of 1 will be used.

=item edgeWeightRange

If this is given, then it must be a reference to an array of two or three
numbers. In this case the weights of the edges will be a random number from the
first number to the second number with increments of the optional third number
(the increment defaults to 1). In fact the elements of this array are passed
directly to the C<random> function (see L<PGbasicmacros.pl/Pseudo-random number
generator>). Note that the C<startEdgeWeight> option takes precedence over this
option, and if it is given and is an integer greater than one, then it will be
used instead of this option.

=item edgeCount

The number of edges in the graph for which to set random weights.  If this
option is not given, then the number of edges in the graph will be computed, and
all the weights of all existing edges will be randomized. If the number of edges
in the graph is already known, then set this option to that value for efficiency
so that this method does not need to compute that number again.

=back

=head2 isEqual

    $graph->isEqual($other);

This method returns 1 if the graph object represented by C<$graph> and the graph
represented by C<$other> are the same. This does not necessarily return 1 for
isomorphic graphs. The two graphs must literally have the same adjacency matrix.

=head2 isIsomorphic

    $graph->isIsomorphic($other);

This method returns 1 if the graph represented by C<$graph> and the graph
represented by C<$other> are isomorphic.

WARNING: This method uses a brute force approach and compares the first graph to
all possible permutations of the other graph, and so should not be used for
graphs with a large number of vertices (probably no more than 8).

=head2 image

    $graph->image(%options);

Constructs and returns a L<Plots::Plot> object via the L<plots.pl> macro that
provides a pictorial representation of the graph. The returned object may be
inserted into the problem via the C<image> method (see L<PGbasicmacros.pl/Macros
for displaying images>), L<PGcore/insertGraph>, or using the PGML image syntax
(for example, C<< [!alt text!]{$graph->image} >>).

Note that the C<gridLayout>, C<bipartiteLayout>, and C<wheelLayout> options that
can be set when the C<GraphTheory::SimpleGraph> object is created affect how the
graph is displayed. See the L</SimpleGraph> function for details on those
options. Note that those options can also be set as properties of the object
anytime after construction and before this method is called (for example,
C<< $self->{bipartiteLayout = 1; >>). If none of those layout options are used,
then the vertices of the graph will be evenly spaced around the perimeter of a
circle with the vertex at index 0 on the right.

The following options can be set via the C<%options> argument.

=over

=item width

This is the width of the image. Default is 250.

Note that the width option is not honored if the C<gridLayout> is used. Note
that the width can still be set via the L<PGbasicmacros.pl> C<image> method, or
via the width option for the PGML image syntax.

=item height

This is the height of the image. Default is the value of the width option above.

Note that the height option is not honored if the C<gridLayout> is used. Note
that the height can still be set via the L<PGbasicmacros.pl> C<image> method, or
via the height option for the PGML image syntax.

=item showLabels

If this is 1, then vertex labels will be shown. If this is 0, then vertex labels
will not be shown. Default is 1 (so labels must be explicitly hidden by setting
this to 0).

=item showWeights

If this is 1, then edge weights will be shown. If this is 0, then edge weights
will not be shown. Default is 0.

Note that the display of edge weights often does not work well as it can be
unclear which edge a given weight belongs to in the image. Particularly if a
graph has a large number of edges. Graphs that are created via the
C<randomSimpleGraph> function using the row and column C<$size> argument (and
hence are displayed using the grid layout) do work quite well for this.

=back

=head2 gridLayoutImage

    $graph->gridLayoutImage(%options);

This method is not intended to be used externally. It is called by the L</image>
method if the C<gridLayout> property is set for the graph object. If this method
is called directly and the C<gridLayout> property is set, then it will still
work. Otherwise an exception will be thrown. It accepts the same options as the
L</image> method, but does not honor the C<width> and C<height> options.

=head2 bipartiteLayoutImage

    $graph->bipartiteLayoutImage(%options);

This method is not intended to be used externally. It is called by the L</image>
method if the C<bipartiteLayout> property is set for the graph object. If this
method is called directly and the C<bipartiteLayout> property is set, then it
will still work. Otherwise an exception will be thrown. Note that an exception
will also be thrown if the C<bipartiteLayout> property is set to 1, and the
graph is not bipartite. It accepts the same options as the L</image> method.

=head2 wheelLayoutImage

    $graph->wheelLayoutImage(%options);

This method is not intended to be used externally. It is called by the L</image>
method if the C<wheelLayout> property is set for the graph object. If this
method is called directly and the C<wheelLayout> property is set, then it will
still work. Otherwise an exception will be thrown. It accepts the same options
as the L</image> method.

=head2 copy

    $copy = $graph->copy;

This method returns a copy of C<$graph>. This is an exact copy with all
properties duplicated to the returned object.

=head2 shuffle

    $shuffledGraph = $graph->shuffle($permuteLabels);

This method returns a randomization of C<$graph> obtained by permuting the
vertices. The edges that connected the vertices in the original graph will still
connect the permuted vertices in the resulting graph. In other words the
returned graph is isomorphic to the original.

If the optional C<$permuteLabels> argument is provided and is true, then the
labels will also be permuted with the vertices. Otherwise the labels will remain
in the same order that they were in the original graph, but the shuffled graph
will still have the same labels.

If the C<bipartiteLayout> property is set to 1 for the original graph, then the
shuffled graph will also have also have that property set to 1. However, the
array form of the C<bipartiteLayout> property will not be preserved.

The C<gridLayout> property is not preserved in the shuffled graph in any case.

The C<wheelLayout> property is preserved in the shuffled graph, and its value
will be permuted so that the vertex it marked as the hub of the wheel is still
the hub. This means that the hub of the wheel will still be displayed in the
center when the L</image> method is used to display the graph. If that is not
desired, then delete the C<wheelLayout> property for the result. For example,

    $shuffledGraph = $graph->shuffle;
    delete $shuffledGraph->{wheelLayout};

=head2 nearestNeighborPath

    ($path, $weight) = $graph->nearestNeighborPath($vertex);

This is an implementation of the nearest neighbor algorithm. It attempts to find
the shortest path starting at the vertex indexed by C<$vertex> that visits all
vertices in the graph exactly once and returns to the starting vertex. Note that
if such a path is not possible, then the algorithm will go as far as it can, but
the path that is returned may not visit all vertices and may not be a circuit.
This method will always succeed for complete graphs.

The method returns a list whose first entry is a reference to an array
containing the path found, and whose second entry is the total weight of that
path.

=head2 kruskalGraph

    ($tree, $treeWeight, $treeWeights) = $graph->kruskalGraph($vertex);

This is an implementation of Kruskal's algorithm. It attempts to find a minimum
spanning tree or forest for the graph. Note that if the graph is connected, then
the result will be a tree, and otherwise it will be a forest consisting of
minimal spanning trees for each component.

The method returns a list with three entries.  The first entry is a
C<GraphTheory::SimpleGraph> object representing the tree or forest found. The
second entry is the total weight of that tree or forest. The last entry is a
reference to an array containing the weights of the edges in the tree or forest
in the order that they are added by the algorithm.

=head2 hasEulerCircuit

    $hasEulerCircuit             = $graph->hasEulerCircuit;
    ($hasEulerCircuit, $message) = $graph->hasEulerCircuit;

In scalar context this method returns 1 if the graph has an Euler circuit, and 0
otherwise. In list context this method returns 1 if the graph has an Euler
circuit, and if the graph does not have an Euler circuit it returns a list whose
first entry is 0 and whose second entry is a message stating the reason that the
graph does not have an Euler circuit.

=head2 hasEulerTrail

    $hasEulerTrail             = $graph->hasEulerTrail;
    ($hasEulerTrail, $message) = $graph->hasEulerTrail;

In scalar context this method returns 1 if the graph has an Euler trail, and 0
otherwise. In list context this method returns 1 if the graph has an Euler
trail, and if the graph does not have an Euler trail it returns a list whose
first entry is 0 and whose second entry is a message stating the reason that the
graph does not have an Euler trail.

=head2 pathIsEulerTrail

    $pathIsEulerTrail             = $graph->pathIsEulerTrail(@path);
    ($pathIsEulerTrail, $message) = $graph->pathIsEulerTrail(@path);

The C<@path> argument should contain a list of vertex indices in the graph
representing a path in the graph. In scalar context this method returns 1 if the
path forms an Euler trail in the graph, and 0 otherwise. In list context this
method returns 1 if the path forms an Euler trail in the graph, and if the path
does not form an Euler trail in the graph it returns a list whose first entry is
0 and whose second entry is a message stating the reason that the path does not
form an Euler trail.

=head2 pathIsEulerCircuit

    $pathIsEulerCircuit             = $graph->pathIsEulerCircuit(@path);
    ($pathIsEulerCircuit, $message) = $graph->pathIsEulerCircuit(@path);

The C<@path> argument should contain a list of vertex indices in the graph
representing a path in the graph. In scalar context this method returns 1 if the
path forms an Euler circuit in the graph, and 0 otherwise. In list context this
method returns 1 if the path forms an Euler circuit in the graph, and if the
path does not form an Euler circuit in the graph it returns a list whose first
entry is 0 and whose second entry is a message stating the reason that the path
does not form an Euler circuit.

=head2 hasCircuit

    $hasCircuit = $graph->hasCircuit;

This method returns 1 if the graph has a circuit, and 0 otherwise.

=head2 isTree

    $isTree             = $graph->isTree;
    ($isTree, $message) = $graph->isTree;

In scalar context this method returns 1 if the graph is a tree, and 0 otherwise.
In list context this method returns 1 if the graph is a tree, and if the graph
is not a tree it returns a list whose first entry is 0 and whose second entry is
a message stating the reason that the graph is not a tree.

=head2 isForest

    $isForest             = $graph->isForest;
    ($isForest, $message) = $graph->isForest;

In scalar context this method returns 1 if the graph is a forest, and 0
otherwise. In list context this method returns 1 if the graph is a forest, and
if the graph is not a forest it returns a list whose first entry is 0 and whose
second entry is a message stating the reason that the graph is not a forest.

=head2 isBipartite

    $isBipartite = $graph->isBipartite;

This method returns 1 if the graph is bipartite, and 0 otherwise.

=head2 bipartitePartition

    ($upper, $lower) = $graph->bipartitePartition;

If the graph is bipartite, then this method returns a list containing two
entries that form a partition of the vertices of the graph into two sets for
which no two vertices in the same set have an edge connecting them. If the graph
is not bipartite, then this method returns undefined.

=head2 dijkstraPath

    ($distance, @path) = $graph->dijkstraPath($start, $end);

This is an implementation of Dijkstra's algorithm for finding the shortest path
between nodes in a weighted graph.

The C<$start> and C<$end> arguments are required and should be indices of two
vertices in the graph representing the start vertex and end vertex for which to
find the shortest path between.

The return value will be a list whose first entry is the shortest distance from
the start vertex to the end vertex, and whose remaining entries are the indices
of the vertices that form the shortest path from the start vertex to the end
vertex.

=head2 sortedEdgesPath

    ($sortedEdgesPath, $edgeWeights) = $graph->sortedEdgesPath;

This is an implementation of the sorted edges algorithm for finding the shortest
Hamiltonian circuit in a graph. That is a path that visits each vertex in the
graph exactly once. The return value will be a list with two entries  The first
entry is the resulting sorted edges graph, and the second entry is a reference
to an array containing the weights of the edges in the path in the order that
they are chosen by the algorithm. Note that the returned graph will contain a
Hamiltonian circuit from the original graph if one exists. In any case the graph
will contain all edges chosen in the algorithm.

=head2 chromaticNumber

    $graph->chromaticNumber;

This method returns the chromatic number of the graph. That is the minimum
number of colors required to color the vertices such that no two adjacent
vertices share the same color.

=head2 kColoring

    $graph->kColoring($k);

The argument C<$k> is required and is the desired number of colors for which to
find a k-coloring. That is a coloring of the graph consisting of at most k
colors such that no two adjacent vertices share the same color. If such a
coloring is possible, then this method will return a list with the number of
entries equal to the number of vertices in the graph, and whose i-th entry will
be an integer from 1 to k where the integers represent a coloring for the vertex
with index i in the graph and such that the list forms a k-coloring. If a
k-coloring is not possible, then this method returns undefined.

=head1 EdgeSet Context

A context for edge sets is provided.  To activate the context Call

    Context('EdgeSet');

Then C<GraphTheory::SimpleGraph::Value::Edge> and
C<GraphTheory::SimpleGraph::Value::EdgeSet> objects can be constructed with

    $edge    = Compute('{B, E}');
    $edgeSet = Compute('{{A, B}, {A, E}, {A, F}, {E, F}}');

or by using the C<Edge> or C<EdgeSet> methods described before (those methods
can also be used outside of this context). Note that the vertices must be added
as strings to the context and marked as being vertices with the C<isVertex>
flag before constructing the C<Edge> or C<EdgeSet>.  For example, by calling

    Context()->strings->add(
        map { $_ => { isVertex => 1, caseSensitive => 1 } } 'A' .. 'F'
    );

If it is prefered that the vertices not be case sensitive, then remove
C<< caseSensitive => 1 >> from the above call.

If the vertices in the C<Edge> or C<EdgeSet> belong to a C<GraphTheory::SimpleGraph>
object that has already been constructed, then the L</addVerticesToContext>
method can instead be used to add the vertices to the context.

=cut
