################################################################
=head1 NAME
draggableProof.pl
  
=head1 DESCRIPTION

=head1 TERMINOLOGY
An HTML element into or out of which other elements may be dragged will be called a "bucket".
An HTML element which houses a collection of buckets will be called a "bucket pool".

=head1 USAGE
To initialize a DraggableSubset bucket pool in a .pg problem, do:

$draggable = DraggableSubsets($statements, $extra, Options1 => ..., Options2 => ...);

before BEGIN_TEXT.

Then, call:

$draggable->Print

within the BEGIN_TEXT / END_TEXT environment;

$statements, e.g. ["Socrates is a man.", "Socrates is mortal.", ...], is an array reference to the list of statements used in the correct proof. It is imperative that square brackets be used.

$extra, e.g. ["Roses are red."], is an array reference to the list statements extraneous to the proof. It can be left empty [].

By default, the score of the student answer is 100% if the draggable statements are placed in the exact same order as in the array referenced by $statements, with no inclusion of any statement from $extra. The score is 0% otherwise.

Available Options:
NumBuckets => 1 or 2
SourceLabel => <string>
TargetLabel => <string>
Levenshtein => 0 or 1
DamerauLevenshtein => 0 or 1
Inference => <string>
InferenceMatrix => <array reference>
IrrelevancePenalty => <float>

Their usage is explained in the example below.

=head1 EXAMPLE
DOCUMENT();
loadMacros(
  "PGstandard.pl",
  "MathObjects.pl",
  "draggableProof.pl"
);

TEXT(beginproblem());

$statements = [
"All men are mortal.", #0
"Socrates is a man.", #1
"Socrates is mortal." #2
];

$extra = [
"Some animals are men.",
"Beauty is immortal.",
"Not all animals are men."
];

$draggable = DraggableProof(
$statements,
$extra,
NumBuckets => 2, # either 1 or 2.
SourceLabel => "Axioms", # label of first bucket if NumBuckets = 2.
TargetLabel => "<strong>Reasoning</strong>", # label of second bucket if NumBuckets = 2, of the only bucket if NumBuckets = 1.
################################################################
# Levenshtein => 1, 
# if equal to one scoring is determined by the Levenshtein edit distance between student answer and correct proof. 
################################################################
# DamerauLevenshtein => 1, 
# if equal to one scoring is determined by the Damerau-Levenshtein distance between student answer and correct proof. A pair of transposed adjacent statements is counted as two mistakes under Levenshtein scoring, but as one mistake under Damerau-Levenshtein scoring.
################################################################
InferenceMatrix => [
[0, 0, 1],
[0, 0, 1],
[0, 0, 0]
],
# (i, j)-entry is nonzero <=> statement i implies statement j. The score of each corresponding inference is weighted according to the value of the matrix entry. This matrix is automatically generated from the Inference option, if provided, with each inference given equal weight.
################################################################
IrrelevancePenalty => 1 # Penalty for each irrelevant statement is IrrelevancePenalty times the score equivalent to one correct instance of inference. Default value = 1.
);

Context()->texStrings;

BEGIN_TEXT

Show that Socrates is mortal by dragging the relevant $BBOLD Axioms $EBOLD
into the $BBOLD Reasoning $EBOLD box in an appropriate order.

$PAR 

\{ $draggable->Print \}

END_TEXT
Context()->normalStrings;

ANS($draggable->cmp);

ENDDOCUMENT();
=cut
################################################################

loadMacros(
"PGchoicemacros.pl",
"MathObjects.pl",
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
    
    # user arguments
    my $proof = shift; 
    my $extra = shift;	
    my %options = (
    SourceLabel => "Choose from these sentences:",
    TargetLabel => "Your Proof:",
    NumBuckets => 2,
    Levenshtein => 0,
    DamerauLevenshtein => 0,
    InferenceMatrix => [],
    IrrelevancePenalty => 1,
    @_
    );
    # end user arguments
    
    my $lines = [ @$proof, @$extra ];
    my $numNeeded = scalar(@$proof);
    my $numProvided = scalar(@$lines);
    my @order = main::shuffle($numProvided);
    my @unorder = main::invert(@order);
    my $shuffledLines = [ map {$lines->[$_]} @order ];
    
    my $answerInputId = main::NEW_ANS_NAME() unless $self->{answerInputId};
    my $ans_rule = main::NAMED_HIDDEN_ANS_RULE($answerInputId);
    
    my $dnd;
    if ($options{NumBuckets} == 2) {
        $dnd = new DragNDrop($answerInputId, $shuffledLines,
        [
        {
            indices => [0..$numProvided-1],
            label => $options{'SourceLabel'}
        }, 
        {
            indices => [],
            label => $options{'TargetLabel'}
        }
        ],
        AllowNewBuckets => 0);
    } elsif($options{NumBuckets} == 1) {
        $dnd = new DragNDrop($answerInputId, $shuffledLines,
        [
        {
            indices => [0..$numProvided-1],
            label => $options{'TargetLabel'}
        }
        ],
        AllowNewBuckets => 0);
    }
    
    my $proof = $options{NumBuckets} == 2 ? main::List(
    main::List(@unorder[$numNeeded .. $numProvided - 1]),
    main::List(@unorder[0..$numNeeded-1])
    ) : main::List('('.join(',', @unorder[0..$numNeeded-1]).')');
    
    my $extra = main::Set(@unorder[$numNeeded .. $numProvided - 1]);
    
    my $InferenceMatrix = $options{InferenceMatrix};
    
    $self = bless {
        lines => $lines,
        shuffledLines => $shuffledLines,
        numNeeded => $numNeeded, 
        numProvided => $numProvided,
        order => \@order, 
        unorder => \@unorder,
        proof => $proof,
        extra => $extra,
        answerInputId => $answerInputId,
        dnd => $dnd,
        ans_rule => $ans_rule,
        inferenceMatrix => $InferenceMatrix,
        %options,
    }, $class;
    
    my $previous = $main::inputs_ref->{$answerInputId} || '';
    
    if ($previous eq "") {
        if ($self->{NumBuckets} == 2) {
            $dnd->addBucket([0..$numProvided-1], label => $options{'SourceLabel'});
            $dnd->addBucket([], label => $options{'TargetLabel'});
        } elsif ($self->{NumBuckets} == 1) {
            $dnd->addBucket([0..$numProvided-1], label =>  $options{'TargetLabel'});
        }
    } else {
        my @matches = ( $previous =~ /(\([^\(\)]*\)|-?\d+)/g );
        if ($self->{NumBuckets} == 2) {
            my $indices1 = [ split(',', @matches[0] =~ s/\(|\)//gr) ];	
            $dnd->addBucket($indices1->[0] != -1 ? $indices1 : [], label => $options{'SourceLabel'});
            my $indices2 = [ split(',', @matches[1] =~ s/\(|\)//gr) ];
            $dnd->addBucket($indices2->[0] != -1 ? $indices2 : [], label => $options{'TargetLabel'});
        } else {
            my $indices1 = [ split(',', @matches[0] =~ s/\(|\)//gr) ];
            $dnd->addBucket($indices1->[0] != -1 ? $indices1 : [], label => $options{'TargetLabel'});
        }
    }
    
    return $self;
}

sub Levenshtein {    
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
    $dist[-1][-1];    
}

sub DamerauLevenshtein {
    # Damerau–Levenshtein distance with adjacent transpositions
    # https://en.wikipedia.org/wiki/Damerau%E2%80%93Levenshtein_distance
    
    my $discourse1 = shift;
    my $discourse2 = shift;
    my $delimiter = shift;
    my $numProvided = shift;
    
    my @ar1 = split /$delimiter/, $discourse1;
    my @ar2 = split /$delimiter/, $discourse2;
    
    my @da = (0) x $numProvided;    
    my @d = ();
    
    my $maxdist = @ar1 + @ar2;
    for my $i (1 .. @ar1 + 1) {
        push(@d, [ (0) x (@ar2 + 2) ] );
        $d[$i][0] = $maxdist;
        $d[$i][1] = $i - 1;
    }
    for my $j (1 .. @ar2 + 1) {
        $d[0][$j] = $maxdist;
        $d[1][$j] = $j - 1;
    }
    my $db;
    for my $i (2 .. @ar1 + 1) {
        $db = 0;
        my $k, $l, $cost;
        for my $j (2 .. @ar2 + 1) {
            $k = $da[$ar2[$j - 2]];
            $l = $db;
            if ($ar1[$i - 2] == $ar2[$j - 2]) {
                $cost = 0;
                $db = $j;
            } else {
                $cost = 1;
            }
            $d[$i][$j] = main::min($d[$i-1][$j-1] + $cost,
            $d[$i][$j-1] + 1,
            $d[$i-1][$j] + 1,
            $d[$k-1][$l-1] + ($i - $k - 1) + 1 + ($j - $l - 1));
        }
        $da[$ar1[$i - 2]] = $i;
    }
    $d[-1][-1];
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
    return $self->{proof}->cmp(ordered => 1, removeParens => 1)->withPreFilter("erase")->withPostFilter(sub {$self->filter(@_)});
}

sub filter {
    my $self = shift; 
    my $anshash = shift;
    
    my @lines = @{$self->{lines}}; 
    my @order = @{$self->{order}};
    
    my $actualAnswer = $anshash->{student_ans} =~ s/\(|\)|\s*//gr;
    my $correct = $anshash->{correct_ans} =~ s/\(|\)|\s*//gr;
    
    if ($self->{NumBuckets} == 2) {
        my @matches = ( $anshash->{student_ans} =~ /(\([^\(\)]*\)|-?\d+)/g );
        $actualAnswer = @matches == 2 ? $matches[1] =~ s/\(|\)|\s*//gr : '';        
        @matches = ( $anshash->{correct_ans} =~ /(\([^\(\)]*\)|-?\d+)/g );
        $correct = @matches == 2 ? $matches[1] =~ s/\(|\)|\s*//gr : '';
    }
        
    $anshash->{correct_ans} = main::List($correct); # change to main::Set if order does not matter
    $anshash->{student_ans} = main::List($actualAnswer); # change to main::Set if order does not matter
    $anshash->{original_student_ans} = $anshash->{student_ans};
    $anshash->{student_value} = $anshash->{student_ans};
    $anshash->{student_formula} = $anshash->{student_ans};		    
    
    if ($self->{Levenshtein} == 1) {
        $anshash->{score} = 1 - main::min(1, Levenshtein($correct, $actualAnswer, ',')/$self->{numNeeded});
    } elsif ($self->{DamerauLevenshtein} == 1) {
        $anshash->{score} = 1 - main::min(1, DamerauLevenshtein($correct, $actualAnswer, ',', $self->{numProvided})/$self->{numNeeded});
    } elsif (@{ $self->{inferenceMatrix} } != 0) {
        my @unshuffledStudentIndices = map { $self->{order}[$_]} split(',', $actualAnswer);
        my @inferenceMatrix = @{ $self->{inferenceMatrix} };
        my $inferenceScore = 0;
        for (my $j = 0; $j < @unshuffledStudentIndices; $j++ ) {        
            for (my $i = $j - 1; $i >= 0; $i--)  {
                $inferenceScore += $inferenceMatrix[$unshuffledStudentIndices[$i]]->[$unshuffledStudentIndices[$j]];
            }
        }
        my $total = 0;
        for my $row ( @inferenceMatrix ) {
            foreach (@$row) {
                $total += $_;
            }
        }
        $anshash->{score} = $inferenceScore / $total;
        
        my %invoked = map { $_ => 1 } split(',', $actualAnswer);
        foreach ( split(',', $self->{extra}->string =~ s/{|}|\s*//gr ) ) {
            if ( exists($invoked{$_}) ) {
                $anshash->{score} = main::max(0, $anshash->{score} - ($self->{IrrelevancePenalty}/$total));
            }
        }
    } else {
        $anshash->{score} = $anshash->{correct_ans} eq $anshash->{student_ans} ? 1 : 0;
    }
            
    my @correct = map { $_ >= 0 ? $lines[$order[$_]] : '' } split(',', $correct);
    my @student = map { $_ >= 0 ? $lines[$order[$_]] : '' } split(',', $actualAnswer);
    
    
    $anshash->{student_ans} = "(see preview)";
    $anshash->{correct_ans_latex_string} = "\\begin{array}{l}\\text{".join("}\\newline\\text{",@correct)."}\\end{array}";
    $anshash->{correct_ans} = join("<br />",@correct);
    $anshash->{preview_latex_string} = "\\begin{array}{l}\\text{".join("}\\newline\\text{",@student)."}\\end{array}";
        
    return $anshash;
}
1;
