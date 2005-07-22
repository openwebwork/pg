
=head1 NAME

	PGsequentialmacros.pl 
	
Provides support for writing sequential problems, where certain parts
of the problem are hidden until earlier questions are answered correctly.


=head1 SYNPOSIS

	The basic sequential problem structure:

	DOCUMENT();          
	loadMacros(.....);   
	## first segment ##                 
    BEGIN_TEXT
        The first question: Enter \(sin(0) = \) \{ans_rule\}.
    END_TEXT
	ANS(num_cmp(0));
	if (@incorrect_answers = get_incorrect_answers( ) ) {
          TEXT( "These answers are not correct  ", join(" ",@incorrect_answers),$BR); 
          foreach my $label (@incorrect_answers) {
              checkAnswer($label,debug=>1);
          }
    }
    if (all_answers_are_correct() ) {
	      TEXT("$PAR Right! Now for the next part of the problem");
    } else {
	     STOP_RENDERING();
    }
	## second segment ##    
	     ....
	if (@incorrect_answers = get_incorrect_answers( ) ) {
          TEXT( "These answers are not correct  ", join(" ",@incorrect_answers),$BR); 
          foreach my $label (@incorrect_answers) {
              checkAnswer($label,debug=>1);
          }
    }
    if (all_answers_are_correct() ) {
	      TEXT("$PAR Right! Now for the next part of the problem");
    } else {
	     STOP_RENDERING();
    }
    ## third segment ## 
	ENDDOCUMENT()        # must be the last statement in the problem



=head1 DESCRIPTION


=cut


=head2  listFormVariables

	listFormVariables();
	listVariables();

Lists all variables submitted in the problem form and all variables in the 
the Problem environment.  This is used for debugging.

=cut

sub listVariables {
	listFormVariables(@_);
}

sub listFormVariables {
    # Lists all of the variables filled out on the input form
	# Useful for debugging
    TEXT($HR,"Form variables", );
    TEXT(pretty_print($inputs_ref));
    # list the environment variables
    TEXT("Environment",$BR);
   TEXT(pretty_print(\%envir));
   TEXT($HR);
}

=head2  checkAnswer


	checkAnswer($label);

Checks the answer to the question labeled C<$label>.  The result is 1 if the answer is completely correct.
0 if the answer is wrong or partially wrong and undefined if that question has not yet
been answered. (Specifically if no answer hash is produced when the answer is evaluated
by the corresponding answer evaluator.)

=cut

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

=head2 listQueuedAnswers

	listQueuedAnswers();

Lists the labels of the answer blanks which have been printed so far.
The return value is a string which can be printed.  This is mainly
used for debugging.

=cut


sub listQueuedAnswers {
        # lists the names of the answer blanks so far;
        my %pg_answers_hash = get_PG_ANSWERS_HASH();
        join(" ", keys %pg_answers_hash);
}

=head2 checkQueuedAnswers

	checkQueuedAnswers();

Returns a hash whose key/value pairs are the labels of the questions
have been printed so far and the scores obtained by evaluating the 
answers to these questions.

=cut

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

=head2  all_answers_are_correct

	all_answers_are_correct();

Returns 1 if there is at least one answer and all of the questions
printed so far have been answered correctly.

=cut

sub all_answers_are_correct{
     # return 1 if all scores are 1, else it returns 0;
     # returns 0 if no answers have been checked yet
     my %scores = checkQueuedAnswers();
     return 0 unless %scores;
     my $result =1;
     foreach my $label (keys %scores) { if (not defined($scores{$label}) or $scores{$label} <1) {$result=0; last;} };  
     $result;
}

=head2  get_incorrect_answers

	get_incorrect_answers();

Returns a list of labels of questions which have been printed and have
been answered incorrectly.  This list does NOT include blank or undefined
answers.  It's possible for the returned list to be empty AND for all_answers_are_correct()
to return false.

=cut

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


