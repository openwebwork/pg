loadMacros("PGchoicemacros.pl",
"MathObjects.pl",
# "levenshtein.pl",
 );

sub _draggableProof_init {
    ADD_CSS_FILE("https://cdnjs.cloudflare.com/ajax/libs/nestable2/1.6.0/jquery.nestable.min.css", 1);
    ADD_JS_FILE("https://cdnjs.cloudflare.com/ajax/libs/nestable2/1.6.0/jquery.nestable.min.js", 1);
    ADD_CSS_FILE("js/apps/DragNDrop/dragndrop.css", 0);
    ADD_JS_FILE("js/apps/DragNDrop/dragndrop.js", 0, { defer => undef });
    PG_restricted_eval("sub DraggableProof {new draggableProof(\@_)}");
}

package draggableProof;

sub new {
	my $self = shift; 
	my $class = ref($self) || $self;
	
	my $proof = shift || []; 
	my $extra = shift || [];	
	my %options = (
		SourceLabel => "Choose from these sentences:",
		TargetLabel => "Your Proof:",
		NumBuckets => 2,
		Levenshtein => 0,
        Leitfaden => '',
        InferenceMatrix => [],
		@_
	);
	
	my $lines = [@$proof,@$extra];	
	my $numNeeded = scalar(@$proof);
	my $numProvided = scalar(@$lines);
	my @order = main::shuffle($numProvided);
	my @unorder = main::invert(@order);

	my $shuffled_lines = [ map {$lines->[$_]} @order ];
	
	my $answer_input_id = main::NEW_ANS_NAME() unless $self->{answer_input_id};
	my $ans_rule = main::NAMED_HIDDEN_ANS_RULE($answer_input_id);
	
	my $dnd;
	if ($options{NumBuckets} == 2) {
		$dnd = new DragNDrop($answer_input_id, $shuffled_lines, [{indices=>[0..$numProvided-1], label=>$options{'SourceLabel'}}, {indices=>[], label=>$options{'TargetLabel'}}], AllowNewBuckets => 0);
	} elsif($options{NumBuckets} == 1) {
		$dnd = new DragNDrop($answer_input_id, $shuffled_lines, [{indices=>[0..$numProvided-1], label=>$options{'TargetLabel'}}], AllowNewBuckets => 0);
	}
	
	my $proof = $options{NumBuckets} == 2 ? 
	main::List(main::List(@unorder[$numNeeded .. $numProvided - 1]), main::List(@unorder[0..$numNeeded-1]))
	: main::List('('.join(',', @unorder[0..$numNeeded-1]).')');
	
    
    my $InferenceMatrix = $options{InferenceMatrix};
    if (@{ $InferenceMatrix } == 0) {
        if ($options{Leitfaden} ne '') {            
            $InferenceMatrix = _LeitfadenToMatrix($options{Leitfaden}, $numProvided);
        } 
    }

	$self = bless {
		lines => $lines,
		shuffled_lines => $shuffled_lines,
		numNeeded => $numNeeded, 
		numProvided => $numProvided,
		order => \@order, 
		unorder => \@unorder,
		proof => $proof,
		answer_input_id => $answer_input_id,
		dnd => $dnd,
		ans_rule => $ans_rule,
        inference_matrix => $InferenceMatrix,
		%options,
	}, $class;
	
	my $previous = $main::inputs_ref->{$answer_input_id} || '';
	
	if ($previous eq "") {
		if ($self->{NumBuckets} == 2) {
			$dnd->addBucket([0..$numProvided-1], label => $options{'SourceLabel'});
			$dnd->addBucket([], $options{'TargetLabel'});
		} elsif ($self->{NumBuckets} == 1) {
			$dnd->addBucket([0..$numProvided-1], label =>  $options{'TargetLabel'});
		}
	} else {
		my @matches = ( $previous =~ /(\([^\(\)]*\))/g );
		if ($self->{NumBuckets} == 2) {
			my $indices1 = [ split(',', @matches[0] =~ s/\(|\)//gr) ];		
			$dnd->addBucket($indices1, label => $options{'SourceLabel'});		
			my $indices2 = [ split(',', @matches[1] =~ s/\(|\)//gr) ];
			$dnd->addBucket($indices2, label => $options{'TargetLabel'});
		} else {
			my $indices1 = [ split(',', @matches[0] =~ s/\(|\)//gr) ];
			$dnd->addBucket($indices1, label => $options{'TargetLabel'});
		}
	}
		
	return $self;
}

sub _LeitfadenToMatrix { # for internal use

    my $leitfaden = shift;    
    my $numProvided = shift;

    my @matrix = ();

    for (1..$numProvided) {
        push(@matrix, [ (0) x $numProvided ]);
    }
    
    my @chains = split(',', $leitfaden);
    for my $chain ( @chains ) {
        my @entries = split('>', $chain);
        for (my $i = 0; $i < @entries - 1; $i++) {
            $matrix[$entries[$i] - 1]->[$entries[$i + 1] - 1] = 1;
        }
    }
    return [ @matrix ];
}

sub _levenshtein { # for internal use
    my @ar1 = split /$_[2]/, $_[0];
    my @ar2 = split /$_[2]/, $_[1];
    
    my @dist = ([0 .. @ar2]);
    $dist[$_][0] = $_ for (1 .. @ar1);

    for my $i (0 .. $#ar1) {
        for my $j (0 .. $#ar2) {
            $dist[$i+1][$j+1] = main::min($dist[$i][$j+1] + 1, $dist[$i+1][$j] + 1,
            $dist[$i][$j] + ($ar1[$i] ne $ar2[$j]) );
        }
    }
    main::min(1, $dist[-1][-1]/(@ar1));
}

sub Print {
	my $self = shift;

	my $ans_rule = $self->{ans_rule};
	
	if ($main::displayMode ne "TeX") { # HTML mode
		return join("\n",
			'<div style="min-width:750px;">',
			$ans_rule,
			$self->{dnd}->HTML,
			'<br clear="all" />',
			'</div>',
		);
	} else { # TeX mode
		return $self->{dnd}->TeX;
	}
}

sub cmp {
	my $self = shift;
    
    return $self->{proof}->cmp(ordered => 1, removeParens => 1)->withPreFilter("erase")->withPostFilter(sub {$self->filter(@_)});
}

sub filter {
	my $self = shift; 
    my $anshash = shift;
		
	my @lines = @{$self->{lines}}; 
	my @order = @{$self->{order}};
	
	my $actual_answer = $anshash->{student_ans} =~ s/\(|\)|\s*//gr;
	my $correct = $anshash->{correct_ans} =~ s/\(|\)|\s*//gr;
	if ($self->{NumBuckets} == 2) {
		my @matches = ( $anshash->{student_ans} =~ /(\([^\(\)]*\))/g );
		$actual_answer = @matches == 2 ? $matches[1] =~ s/\(|\)|\s*//gr : '';
		
		@matches = ( $anshash->{correct_ans} =~ /(\([^\(\)]*\))/g );
		$correct = @matches == 2 ? $matches[1] =~ s/\(|\)|\s*//gr : '';		
	}
    $anshash->{correct_ans} = main::List($correct); # change to main::Set if order does not matter
    $anshash->{student_ans} = main::List($actual_answer); # change to main::Set if order does not matter
    $anshash->{original_student_ans} = $anshash->{student_ans};
    $anshash->{student_value} = $anshash->{student_ans};
    $anshash->{student_formula} = $anshash->{student_ans};		
    
    if ($self->{Levenshtein} == 1) {
        $anshash->{score} = 1 - _levenshtein($correct, $actual_answer, ',');
    } elsif ($self->{Leitfaden} ne "") {        
        my @student_indices = map { $self->{order}[$_]} split(',', $actual_answer);
        my @inference_matrix = @{ $self->{inference_matrix} };
        my $inference_score = 0;
        for (my $j = 0; $j < @student_indices; $j++ ) {
            for (my $i = $j - 1; $i >= 0; $i--)  {
                $inference_score += $inference_matrix[$student_indices[$i]][$student_indices[$j]];
            }
        }
        my $total = 0;
        for my $row ( @inference_matrix ) {
            foreach (@$row) {
                $total += $_;
            }
        }
        $anshash->{score} = $inference_score / $total;
    } else {
        $anshash->{score} = $anshash->{correct_ans} eq $anshash->{student_ans} ? 1 : 0;
    }
	
	my @correct = @lines[map {@order[$_]} split(/,/, $correct)];
	my @student = @lines[map {@order[$_]} split(',', $actual_answer)];
	 
	$anshash->{student_ans} = "(see preview)";
	$anshash->{correct_ans_latex_string} = "\\begin{array}{l}\\text{".join("}\\\\\\text{",@correct)."}\\end{array}";
	$anshash->{correct_ans} = join("<br />",@correct);
	$anshash->{preview_latex_string} = "\\begin{array}{l}\\text{".join("}\\\\\\text{",@student)."}\\end{array}";
	
	return $anshash;
}

1;
