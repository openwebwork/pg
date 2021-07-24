# Done: show possible choices in TeX mode
# To do: display student answers and correct answers in TeX mode properly.
# To do: put jquery.nestable.js in a universal spot on every webwork server.

loadMacros("PGchoicemacros.pl",
"MathObjects.pl",
"levenshtein.pl",
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
	# warn main::pretty_print $ans_rule;
	
	my $dnd;
	if ($options{NumBuckets} == 2) {
		$dnd = new DragNDrop($answer_input_id, $shuffled_lines, [{indices=>[0..$numProvided-1], label=>$options{'SourceLabel'}}, {indices=>[], label=>$options{'TargetLabel'}}], AllowNewBuckets => 0);
	} elsif($options{NumBuckets} == 1) {
		$dnd = new DragNDrop($answer_input_id, $shuffled_lines, [{indices=>[0..$numProvided-1], label=>$options{'TargetLabel'}}], AllowNewBuckets => 0);
	}
	
	my $proof = $options{NumBuckets} == 2 ? 
	main::List(main::List(@unorder[$numNeeded .. $numProvided - 1]), main::List(@unorder[0..$numNeeded-1]))
	: main::List('('.join(',', @unorder[0..$numNeeded-1]).')');
		
		
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
		%options,
	}, $class;
	
	my $previous = $main::inputs_ref->{$answer_input_id} || '';
	
	if ($previous eq "") {
		if ($self->{NumBuckets} == 2) {
			$dnd->addBucket([0..$numProvided-1], label => $options{'SourceLabel'});
			$dnd->addBucket([], $options{'TargetLabel'});
		} elsif ($self->{NumBuckets} == 1) {
			$dnd->addBucket([0..$numProvided-1], label => $options{'TargetLabel'});
		}
	} else {
		my @matches = ( $previous =~ /(\(\d*(?:,\d+)*\))+/g );
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
	if ($self->{Levenshtein} == 0) {
		return $self->{proof}->cmp(ordered => 1, removeParens => 1)->withPreFilter("erase")->withPostFilter(sub {$self->filter(@_)});
	} else {
		return $self->{proof}->cmp(ordered => 1, removeParens => 1)->withPreFilter("erase")->withPostFilter(sub {$self->levenshtein_filter(@_)});
	}
}

sub filter {
	my $self = shift; my $anshash = shift;
		
	my @lines = @{$self->{lines}}; 
	my @order = @{$self->{order}};
	
	my $actual_answer = $anshash->{student_ans} =~ s/\(|\)|\s*//gr;
	my $correct = $anshash->{correct_ans} =~ s/\(|\)|\s*//gr;
	
	if ($self->{NumBuckets} == 2) {
		my @matches = ( $anshash->{student_ans} =~ /(\([^\(\)]*\))/g );
		$actual_answer = @matches == 2 ? $matches[1] =~ s/\(|\)|\s*//gr : '';
		
		@matches = ( $anshash->{correct_ans} =~ /(\([^\(\)]*\))/g );
		$correct = @matches == 2 ? $matches[1] =~ s/\(|\)|\s*//gr : '';
		
		$anshash->{correct_ans} = main::List($correct); # change to main::Set if order does not matter
		$anshash->{student_ans} = main::List($actual_answer); # change to main::Set if order does not matter
		$anshash->{original_student_ans} = $anshash->{student_ans};
		$anshash->{student_value} = $anshash->{student_ans};
		$anshash->{student_formula} = $anshash->{student_ans};
		
		if ($anshash->{correct_ans} eq $anshash->{student_ans}) {
			$anshash->{score} = 1;
		}
	}
	
	my @correct = @lines[map {@order[$_]} split(/,/, $correct)];
	my @student = @lines[map {@order[$_]} split(',', $actual_answer)];
	 
	$anshash->{student_ans} = "(see preview)";
	$anshash->{correct_ans_latex_string} = "\\begin{array}{l}\\text{".join("}\\\\\\text{",@correct)."}\\end{array}";
	$anshash->{correct_ans} = join("<br />",@correct);
	$anshash->{preview_latex_string} = "\\begin{array}{l}\\text{".join("}\\\\\\text{",@student)."}\\end{array}";
	
	return $anshash;
}

sub levenshtein_filter {
	my $self = shift; my $anshash = shift;
		
	my @lines = @{$self->{lines}}; 
	my @order = @{$self->{order}};
	
	my $actual_answer = $anshash->{student_ans} =~ s/\(|\)|\s*//gr;
	my $correct = $anshash->{correct_ans} =~ s/\(|\)|\s*//gr;
	
	if ($self->{NumBuckets} == 2) {
		my @matches = ( $anshash->{student_ans} =~ /(\([^\(\)]*\))/g );
		$actual_answer = @matches == 2 ? $matches[1] =~ s/\(|\)|\s*//gr : '';
		
		@matches = ( $anshash->{correct_ans} =~ /(\([^\(\)]*\))/g );
		$correct = @matches == 2 ? $matches[1] =~ s/\(|\)|\s*//gr : '';
		
		$anshash->{correct_ans} = main::List($correct); # change to main::Set if order does not matter
		$anshash->{student_ans} = main::List($actual_answer); # change to main::Set if order does not matter
		$anshash->{original_student_ans} = $anshash->{student_ans};
		$anshash->{student_value} = $anshash->{student_ans};
		$anshash->{student_formula} = $anshash->{student_ans};
		
	}
	
	$anshash->{score} = 1 - levenshtein::levenshtein($correct, $actual_answer, ',');
	 
	my @correct = @lines[map {@order[$_]} split(/,/, $correct)];
	my @student = @lines[map {@order[$_]} split(',', $actual_answer)];
	$anshash->{student_ans} = "(see preview)";
	$anshash->{preview_latex_string} = "\\begin{array}{l}\\text{".join("}\\\\\\text{",@student)."}\\end{array}";
    $anshash->{correct_ans_latex_string} = "\\begin{array}{l}\\text{".join("}\\\\\\text{",@correct)."}\\end{array}";
	# $anshash->{correct_ans} = join("\n\n",@correct);
    $anshash->{correct_ans} = $correct;
	return $anshash;
}
1;
