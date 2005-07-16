sub listFormVariables {
    # Lists all of the variables filled out on the input form
	# Useful for debugging
    TEXT($HR,"Form variables", );
    TEXT(pretty_print($inputs_ref));
    TEXT("Environment",$BR);
   TEXT(pretty_print(\%envir));
   TEXT($HR);
}
sub checkAnswer {
    # checks an answer on a given answer evaluator.
	my $answerName = shift;  # get the name of the answer
    my $ans_eval        = get_PG_ANSWERS_HASH($answerName),;   # get the answer evaluator
    my %options         = @_;
	my $debug =($options{debug})?1:0;  # give debug information

    my $answer = $main::inputs_ref->{$answerName};
    my $response = undef;
    if (defined($answer) and defined($ans_eval) ) {
		my $rh_ans_hash = $ans_eval->evaluate($answer);
                $response = (defined($rh_ans_hash) and 1 == $rh_ans_hash->{score}) ? 1:0;
		TEXT("result of evaluating $answerName",$BR, pretty_print($rh_ans_hash) ) if $debug;
	} else {
         warn "Answer evaluator for answer $answerName is not defined" unless defined($ans_eval);
         # it's ok to have a blank answer.
    }
    return $response;   # response is (undef => no answer, 1=> correct answer, 0 => not completely correct
}
sub listQueuedAnswers {
        # lists the names of the answer blanks so far;
        my %pg_answers_hash = get_PG_ANSWERS_HASH();
        join(" ", keys %pg_answers_hash);
}
sub checkQueuedAnswers {
       # gather all of the answers submitted up to this time
      my %options = @_;
      my $debug = ($options{debug}) ? 1 :0;
      my (%pg_answers_hash) = get_PG_ANSWERS_HASH();
      my %scores=();
      foreach $label (keys %pg_answers_hash) {
             $scores{$label}=checkAnswer($label,  debug=>$debug);
      }
     %scores;
}
sub all_answers_are_correct{
     # return 1 if all scores are 1, else it returns 0;
     # returns 0 if no answers have been checked yet
     my %scores = checkQueuedAnswers();
     return 0 unless %scores;
     my $result =1;
     foreach my $label (keys %scores) { if (not defined($scores{$label}) or $scores{$label} <1) {$result=0; last;} };  
     $result;
}
sub get_incorrect_answers {
	# returns only incorrect answers, not blank or undefined answers.
    my %scores = checkQueuedAnswers();
    my @incorrect = ();
    foreach my $label (keys %scores) {push( @incorrect, $label) 
          unless  (not defined($scores{$label}) or $scores{$label}==1  )
    };
    @incorrect;
}

1;


