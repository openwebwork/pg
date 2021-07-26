################################################################
=head1 NAME
draggableSubsets.pl
  
=head1 DESCRIPTION

=head1 TERMINOLOGY
An HTML element into or out of which other elements may be dragged will be called a "bucket".
An HTML element which houses a collection of buckets will be called a "bucket pool".

=head1 USAGE

=head1 EXAMPLES
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
$ans = [
[0, 3],
[1, 4],
[2, 5]
];

$CorrectProof = DraggableSubsets($D3, $ans, [
{
    label => 'coset 1',
    indices => [ 1, 3, 4, 5 ],
    removable => 0
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
]);

Context()->texStrings;

BEGIN_TEXT

Let \[
G=D_3=\lbrace e,r,r^2, s,sr,sr^2 \rbrace
\]
be the Dihedral group of order \(6\), where \(r\) is rotation by \(2\pi/3\), and \(s\) is the reflection across the \(x\)-axis.

Partition \(G=D_3\) into $BBOLD right $EBOLD cosets of the subgroup
\(H=\lbrace $subgroup \rbrace\).  Give your result by dragging the following elements into separate buckets, each corresponding to a coset.

$PAR
\{ $CorrectProof->Print \}

END_TEXT
Context()->normalStrings;

# Answer Evaluation

ANS($CorrectProof->cmp);

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
	my $set = shift || []; 
	my $subsets = shift || []; 
	my $default_buckets = shift || [];
	# end user arguments
	
	my $numProvided = scalar(@$set);
	my @order = main::shuffle($numProvided);
	my @unorder = main::invert(@order);

	my $shuffled_set = [ map {$set->[$_]} @order ];
	
	my $default_shuffled_buckets = [];
	if (@$default_buckets) {
		for my $default_bucket (@$default_buckets) {
			my $shuffled_indices = [ map {$unorder[$_]} @{ $default_bucket->{indices} } ];
			my $default_shuffled_bucket = { 
				label => $default_bucket->{label}, 
				indices => $shuffled_indices,
				removable => $default_bucket->{removable},
			};
			push(@$default_shuffled_buckets, $default_shuffled_bucket);			
		} 
	} else {
		push(@$default_shuffled_buckets, [ { 
			label => '', 
			indices => [ 0..$numProvided-1 ]
		} ]);
	}
		
	my $answer_input_id = main::NEW_ANS_NAME() unless $self->{answer_input_id};	
	my $ans_rule = main::NAMED_HIDDEN_ANS_RULE($answer_input_id);
	my $dnd = new DragNDrop($answer_input_id, $shuffled_set, $default_shuffled_buckets, AllowNewBuckets => 1);	
	
	my $previous = $main::inputs_ref->{$answer_input_id} || '';
	
	if ($previous eq '') {
		for my $default_bucket ( @$default_shuffled_buckets ) {
			$dnd->addBucket($default_bucket->{indices}, label => $default_bucket->{label});
		}
	} else {
		my @matches = ( $previous =~ /(\([^\(\)]*\)|-?\d+)+/g );
		for(my $i = 0; $i < @matches; $i++) {
			my $match = @matches[$i] =~ s/\(|\)//gr;			
			my $indices = [ split(',', $match) ];
			my $label = $i < @$default_shuffled_buckets ? $default_shuffled_buckets->[$i]->{label} : '';
			my $removable = $i < @$default_shuffled_buckets ? $default_shuffled_buckets->[$i]->{removable} : 1;
			$dnd->addBucket($indices->[0] != -1 ? $indices : [], label => $label, removable => $removable);
		}
	}	
		
	my @shuffled_subsets_array = ();
	for my $subset ( @$subsets ) {
		my @shuffled_subset = map {$unorder[$_]} @$subset;
		push(@shuffled_subsets_array, main::Set(join(',', @shuffled_subset)));
	}	
	my $shuffled_subsets = main::List(@shuffled_subsets_array);
			
	
	$self = bless {
		set => $set,
		shuffled_set => $shuffled_set,
		numProvided => $numProvided,
		order => \@order, 
		unordered => \@unorder,
		shuffled_subsets => $shuffled_subsets,
		answer_input_id => $answer_input_id,
		dnd => $dnd,
		ans_rule => $ans_rule,
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
	return $self->{shuffled_subsets}->cmp(ordered => 0, removeParens => 1, partialCredit => 1)->withPreFilter(sub {$self->prefilter(@_)})->withPostFilter(sub {$self->filter(@_)});
}

sub prefilter {
	my $self = shift; my $anshash = shift;	
	
	my @student = ( $anshash->{original_student_ans} =~ /(\([^\(\)]*\)|-?\d+)/g );	
	
	my @student_ans_array;
	for my $match ( @student ) {
		if ($match eq "\(\)") {
			push(@student_ans_array, main::Set('{}'));
		} else {
			push(@student_ans_array, main::Set($match =~ s/\(|\)//gr));
		}
	}
	
	$anshash->{student_ans} = main::List(@student_ans_array);
		
	return $anshash;
}

sub filter {
	my $self = shift; my $anshash = shift;	
	
	my @order = @{ $self->{order} };
	my @student = ( $anshash->{original_student_ans} =~ /(\([^\(\)]*\)|-?\d+)/g );
	my @correct = ( $anshash->{correct_ans} =~ /({[^{}]*}|-?\d+)/g );
	
	$anshash->{correct_ans_latex_string} = join (",", map { 
		"\\{\\text{".join(",", (map { 
			$_ != -1 ? $self->{shuffled_set}->[$_] : ''
		} (split(',', $_ =~ s/{|}//gr)) ))."}\\}" 
	} @correct);
	
	$anshash->{preview_latex_string} = join (",", map { 
		"\\{\\text{".join(",", (map { 
			$_ != -1 ? $self->{shuffled_set}->[$_] : ''
		} (split(',', $_ =~ s/\(|\)//gr)) ))."}\\}" 
	} @student);
	
	$anshash->{student_ans} = "(see preview)";
	
	return $anshash;
}
1;