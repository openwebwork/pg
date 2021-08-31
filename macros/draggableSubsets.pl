################################################################
=head1 NAME
draggableSubsets.pl
  
=head1 DESCRIPTION
draggableSubsets.pl helps the instructor create a drag-and-drop environment in which a pre-specified set of elements may be dragged to different "buckets", effectively partitioning the original set into subsets.

=head1 TERMINOLOGY
An HTML element into or out of which other elements may be dragged will be called a "bucket".
An HTML element which houses a collection of buckets will be called a "bucket pool".

=head1 USAGE
To initialize a DraggableSubset bucket pool in a .pg problem, insert the line:

$draggable = DraggableSubsets($full_set, $ans, Options1 => ..., Options2 => ...);

before BEGIN_TEXT.

Then, call:

$draggable->Print

within the BEGIN_TEXT / END_TEXT environment;

$full_set, e.g. ["statement1", "statement2", ...], is an array reference to the list of elements, given as strings, in the original full set.
$ans, e.g. [[1, 2, 3], [4, 5], ...], is an array reference to the list of array references corresponding to the correct answer which is a set of subsets. Each subset is specified via the indices of the elements according to their positions in $full_set, with the first element having index 0.

Available Options:
DefaultSubsets => <array reference>
OrderedSubsets => 0 or 1
AllowNewBuckets => 0 or 1

Their usage is explained in the example below.

=head1 EXAMPLE
DOCUMENT();
loadMacros(
  "PGstandard.pl",
  "MathObjects.pl",
  "draggableSubsets.pl",
);

TEXT(beginproblem());
$D3 = [
"\(e\)", #0
"\(r\)", #1
"\(r^2\)", #2
"\(s\)", #3
"\(sr\)", #4
"\(sr^2\)", #5
];

$subgroup = "e, s"; 

$subsets = [
[0, 3],
[1, 4],
[2, 5]
];

$draggable = DraggableSubsets(
$D3, # full set. Square brackets must be used.
$subsets, # reference to array of arrays of indices, corresponding to correct set of subsets. Square brackets must be used.
DefaultSubsets => [ # default instructor-provided subsets. Default value = [].
{
    label => 'coset 1', # label of the bucket.
    indices => [ 1, 3, 4, 5 ], # specifies pre-included elements in the bucket via their indices.
    removable => 0 # specifies whether student may remove bucket.
},
{
    label => 'coset 2',
    indices => [ 0 ],
    removable => 1
},
{
    label => 'coset 3',
    indices => [ 2 ],
    removable => 1
}
],
# OrderedSubsets => 0, # OrderedSubsets => 0 means order of subsets does not matter. 1 means otherwise. (The order of elements within each subset never matters.) Default value = 0. 
# AllowNewBuckets => 1, # AllowNewBuckets => 0 means no new buckets may be added by student. 1 means otherwise. Default value = 1. 
);

Context()->texStrings;

BEGIN_TEXT

Let \[
G=D_3=\lbrace e,r,r^2, s,sr,sr^2 \rbrace
\]
be the Dihedral group of order \(6\), where \(r\) is counter-clockwise rotation by \(2\pi/3\), and \(s\) is the reflection across the \(x\)-axis.

Partition \(G=D_3\) into $BBOLD right $EBOLD cosets of the subgroup
\(H=\lbrace $subgroup \rbrace\).  Give your result by dragging the following elements into separate buckets, each corresponding to a coset.

$PAR
\{ $draggable->Print \}

END_TEXT
Context()->normalStrings;

# Answer Evaluation

ANS($draggable->cmp);

ENDDOCUMENT();
=cut
################################################################

loadMacros(
"PGchoicemacros.pl",
"MathObjects.pl",
);

sub _draggableSubsets_init {
	ADD_CSS_FILE("https://cdnjs.cloudflare.com/ajax/libs/nestable2/1.6.0/jquery.nestable.min.css", 1);
	ADD_JS_FILE("https://cdnjs.cloudflare.com/ajax/libs/nestable2/1.6.0/jquery.nestable.min.js", 1);
	ADD_CSS_FILE("js/apps/DragNDrop/dragndrop.css", 0);
	ADD_JS_FILE("js/apps/DragNDrop/dragndrop.js", 0, { defer => undef });
	PG_restricted_eval("sub DraggableSubsets {new draggableSubsets(\@_)}");
}

package draggableSubsets;

sub new {
	my $self = shift; 
	my $class = ref($self) || $self;
	
	# user arguments
	my $set = shift; 
	my $subsets = shift; 
	my %options = (
	DefaultSubsets => [],
	OrderedSubsets => 0,
	AllowNewBuckets => 1,
    @_
    );
	# end user arguments
	
	my $numProvided = scalar(@$set);
	my @order = main::shuffle($numProvided);
	my @unorder = main::invert(@order);

	my $shuffledSet = [ map {$set->[$_]} @order ];
	
	my $defaultBuckets = $options{DefaultSubsets};
	my $defaultShuffledBuckets = [];
	if (@$defaultBuckets) {
		for my $defaultBucket (@$defaultBuckets) {
			my $shuffledIndices = [ map {$unorder[$_]} @{ $defaultBucket->{indices} } ];
			my $default_shuffled_bucket = { 
				label => $defaultBucket->{label}, 
				indices => $shuffledIndices,
				removable => $defaultBucket->{removable},
			};
			push(@$defaultShuffledBuckets, $default_shuffled_bucket);			
		} 
	} else {
		push(@$defaultShuffledBuckets, [ { 
			label => '', 
			indices => [ 0..$numProvided-1 ]
		} ]);
	}
		
	my $answerInputId = main::NEW_ANS_NAME() unless $self->{answerInputId};	
	my $ans_rule = main::NAMED_HIDDEN_ANS_RULE($answerInputId);
	my $dnd = new DragNDrop(
	$answerInputId, 
	$shuffledSet, 
	$defaultShuffledBuckets, 
	AllowNewBuckets => $options{AllowNewBuckets},
	);	
	
	my $previous = $main::inputs_ref->{$answerInputId} || '';
	
	if ($previous eq '') {
		for my $defaultBucket ( @$defaultShuffledBuckets ) {
			$dnd->addBucket($defaultBucket->{indices}, label => $defaultBucket->{label});
		}
	} else {
		my @matches = ( $previous =~ /(\([^\(\)]*\)|-?\d+)+/g );
		for(my $i = 0; $i < @matches; $i++) {
			my $match = @matches[$i] =~ s/\(|\)//gr;			
			my $indices = [ split(',', $match) ];
			my $label = $i < @$defaultShuffledBuckets ? $defaultShuffledBuckets->[$i]->{label} : '';
			my $removable = $i < @$defaultShuffledBuckets ? $defaultShuffledBuckets->[$i]->{removable} : 1;
			$dnd->addBucket($indices->[0] != -1 ? $indices : [], label => $label, removable => $removable);
		}
	}	
		
	my @shuffled_subsets_array = ();
	for my $subset ( @$subsets ) {
		my @shuffled_subset = map {$unorder[$_]} @$subset;
		push(@shuffled_subsets_array, @$subset != 0 ? main::Set(join(',', @shuffled_subset)) : main::Set());
	}	
	my $shuffled_subsets = main::List(@shuffled_subsets_array);
		
	$self = bless {
		set => $set,
		shuffledSet => $shuffledSet,
		numProvided => $numProvided,
		order => \@order, 
		unordered => \@unorder,
		shuffled_subsets => $shuffled_subsets,
		answerInputId => $answerInputId,
		dnd => $dnd,
		ans_rule => $ans_rule,
		OrderedSubsets => $options{OrderedSubsets},
		AllowNewBuckets => $options{AllowNewBuckets},
	}, $class;
	
	return $self;
}

sub Print {
	my $self = shift;
	
	my $ans_rule = $self->{ans_rule};
	
	if ($main::displayMode ne "TeX") {
		# HTML mode
		return join("\n",
			'<div style="min-width:750px;">',
			$ans_rule,
			$self->{dnd}->HTML,
			'<br clear="all" />',
			'</div>',
		);
	} else {
		# TeX mode
	    return $self->{dnd}->TeX;		
	}
}

sub cmp {
	my $self = shift;	
	return $self->{shuffled_subsets}->cmp(ordered => $self->{OrderedSubsets}, removeParens => 1, partialCredit => 1)->withPreFilter(sub {$self->prefilter(@_)})->withPostFilter(sub {$self->filter(@_)});
}

sub prefilter {
	my $self = shift; my $anshash = shift;	
	
	my @student = ( $anshash->{original_student_ans} =~ /(\([^\(\)]*\)|-?\d+)/g );	
	
	my @studentAnsArray;
	for my $match ( @student ) {
		if ($match =~ /-1/) {
			push(@studentAnsArray, main::Set()); # index -1 corresponds to empty set
		} else {
			push(@studentAnsArray, main::Set($match =~ s/\(|\)//gr));
		}
	}
	
	$anshash->{student_ans} = main::List(@studentAnsArray);
		
	return $anshash;
}

sub filter {
	my $self = shift; my $anshash = shift;	
	
	my @order = @{ $self->{order} };
	my @student = ( $anshash->{original_student_ans} =~ /(\([^\(\)]*\)|-?\d+)/g );
	my @correct = ( $anshash->{correct_ans} =~ /({[^{}]*}|-?\d+)/g );
	
	$anshash->{correct_ans_latex_string} = join (",", map { 
		"\\{\\text{".join(",", (map { 
			$_ != -1 ? $self->{shuffledSet}->[$_] : ''
		} (split(',', $_ =~ s/{|}//gr)) ))."}\\}" 
	} @correct);
	
	$anshash->{preview_latex_string} = join (",", map { 
		"\\{\\text{".join(",", (map { 
			$_ != -1 ? $self->{shuffledSet}->[$_] : ''
		} (split(',', $_ =~ s/\(|\)//gr)) ))."}\\}" 
	} @student);
	
	$anshash->{student_ans} = "(see preview)";
	
	return $anshash;
}
1;