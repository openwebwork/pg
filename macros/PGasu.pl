###

=head1 NAME

        PGasu.pl -- located in the pg/macros directory

=head1 SYNPOSIS


	Macros contributed by John Jones

=cut


# Answer evaluator which always marks things correct

=head3 auto_right()

=pod

	Usage: ANS(auto_right()); 
          or
               ANS(auto_right("this answer can be left blank"));

This answer checker marks any answer correct.  It is useful when you want
to leave multiple answer blanks, only some of which will be used.  If you
turn off showing partial correct answers and partial credit, the effect is
not visible to the students.  The comment in the second case is what will
be displayed as the correct answer.  This helps avoid confusion.

=cut

# ^function auto_right
# ^uses AnswerEvaluator::new
# ^uses auto_right_checker
sub auto_right {
        my $cmt = shift;
        my %params = @_;
        $cmt = '' unless defined($cmt);
        
        my $answerEvaluator = new AnswerEvaluator;
        $answerEvaluator->ans_hash(
            type => "auto_right", 
            correct_ans => "$cmt"
        );
        $answerEvaluator->install_pre_filter('reset');
        $answerEvaluator->install_evaluator(\&auto_right_checker,%params);

        return $answerEvaluator;
}

# used in auto_right above

# ^function auto_right_checker
sub auto_right_checker {
 my $ans = shift;
 $ans->score(1);
 return($ans);
}


=head3	no_decs()

=pod

Can be wrapped around an numerical evaluation.  It marks the answer wrong
if it contains a decimal point.  Usage:

  ANS(no_decs(num_cmp("sqrt(3)")));

This will accept "sqrt(3)" or "3^(1/2)" as answers, but not 1.7320508

=cut

# ^function no_decs
# ^uses must_have_filter
# ^uses raw_student_answer_filter
# ^uses catch_errors_filter
sub no_decs {
	my ($old_evaluator) = @_;

  my $msg= "Your answer contains a decimal.  You must provide an exact answer, e.g. sqrt(5)/3";
	$old_evaluator->install_pre_filter(must_have_filter(".", 'no', $msg));
	$old_evaluator->install_post_filter(\&raw_student_answer_filter);
	$old_evaluator->install_post_filter(\&catch_errors_filter);

	return $old_evaluator;
	}

=head3     must_include()

=pod

Wrapper for other answer evaluators.  It insists that a string is part of
the answer to be marked right. 

=cut

# ^function must_include
# ^uses must_have_filter
# ^uses raw_student_answer_filter
# ^uses catch_errors_filter
sub must_include {
	my ($old_evaluator) = shift;
	my $muststr = shift;

	$old_evaluator->install_pre_filter(must_have_filter($muststr));
	$old_evaluator->install_post_filter(\&raw_student_answer_filter);
	$old_evaluator->install_post_filter(\&catch_errors_filter);
	return $old_evaluator;
	}

=head3      no_trig_fun()

Wrapper for other answer evaluators.  It marks the answer wrong if
it contains one of the six basic trig functions.

This is useful if you want students to report the value of sin(pi/4),
but you don't want to allow "sin(pi/4)" as the answer.

A similar effect can be accomplished with Contexts() by undefining 
the trig functions.  
See http://webwork.maa.org/wiki/Modifying_contexts_%28advanced%29#.282.29_Functions


=cut

# ^function no_trig_fun
# ^uses fun_cmp
# ^uses must_have_filter
# ^uses catch_errors_filter
sub no_trig_fun {
	my ($ans) = shift;
	my $new_eval = fun_cmp($ans);
	my ($msg) = "Your answer to this problem may not contain a trig function.";
	$new_eval->install_pre_filter(must_have_filter("sin", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("cos", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("tan", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("sec", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("csc", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("cot", 'no', $msg));

	$new_eval->install_post_filter(\&catch_errors_filter);
	return $new_eval;
}

=head3      no_trig()



=cut

# ^function no_trig
# ^uses num_cmp
# ^uses must_have_filter
# ^uses catch_errors_filter
sub no_trig {
	my ($ans) = shift;
	my $new_eval = num_cmp($ans);
	my ($msg) = "Your answer to this problem may not contain a trig function.";
	$new_eval->install_pre_filter(must_have_filter("sin", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("cos", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("tan", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("sec", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("csc", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("cot", 'no', $msg));

	$new_eval->install_post_filter(\&catch_errors_filter);
	return $new_eval;
}

=head3      exact_no_trig()



=cut

# ^function exact_no_trig
# ^uses num_cmp
# ^uses no_decs
# ^uses must_have_filter
sub exact_no_trig {
	my ($ans) = shift;
	my $old_eval = num_cmp($ans);
	my $new_eval = no_decs($old_eval);
	my ($msg) = "Your answer to this problem may not contain a trig function.";
	$new_eval->install_pre_filter(must_have_filter("sin", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("cos", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("tan", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("sec", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("csc", 'no', $msg));
	$new_eval->install_pre_filter(must_have_filter("cot", 'no', $msg));

	return $new_eval;
}


=head3      must_have_filter()

=pod

Filter for checking that an answer has (or doesn't have) a certain
string in it.  This can be used to screen answers where you want them
in a particular form (e.g., if you allow most functions, but not trig
functions in the answer, or if the answer must include some string).
     
First argument is the string to have, or not have
Second argument is optional, and tells us whether yes or no
Third argument is the error message to produce (if any).

When using this filter directly, you also need to install catch_errors_filter
as a post filter.

A similar effect can be accomplished with Contexts() by undefining 
the trig functions.  
See http://webwork.maa.org/wiki/Modifying_contexts_%28advanced%29

=cut


# First argument is the string to have, or not have
# Second argument is optional, and tells us whether yes or no
# Third argument is the error message to produce (if any).
# ^function must_have_filter
sub must_have_filter {
	my $str = shift;
	my $yesno = shift;
	my $errm = shift;

	$str =~ s/\./\\./g;
	if(!defined($yesno)) {
		$yesno=1;
	} else {
		$yesno = ($yesno eq 'no') ? 0 :1;
	}

	my $newfilt = sub {
		my $num = shift;
		my $process_ans_hash = ( ref( $num ) eq 'AnswerHash' ) ? 1 : 0 ;
		my ($rh_ans);
		if ($process_ans_hash) {
			$rh_ans = $num;
			$num = $rh_ans->{original_student_ans};
		}
		my $is_ok = 0;

		return $is_ok unless defined($num);

		if (($yesno and ($num =~ /$str/)) or (!($yesno) and !($num=~ /$str/))) {
			$is_ok = 1;
		}

		if ($process_ans_hash)   {
			if ($is_ok == 1 ) {
				$rh_ans->{original_student_ans}=$num;
				return $rh_ans;
			} else {
				if(defined($errm)) {
					$rh_ans->{ans_message} = $errm;
					$rh_ans->{student_ans} = $rh_ans->{original_student_ans};
#					$rh_ans->{student_ans} = "Your answer was \"$rh_ans->{original_student_ans}\". $errm";
					$rh_ans->throw_error('SYNTAX', $errm);
				} else {
					$rh_ans->throw_error('NUMBER', "");
				}
				return $rh_ans;
			}

		} else {
			return $is_ok;
		}
	};
	return $newfilt;
}

=head3      catch_errors_filter()

=cut

# ^function catch_errors_filter
sub catch_errors_filter {
	my ($rh_ans) = shift;
	if ($rh_ans->catch_error('SYNTAX') ) {
		$rh_ans->{ans_message} = $rh_ans->{error_message};
		$rh_ans->clear_error('SYNTAX');
	}
	if ($rh_ans->catch_error('NUMBER') ) {
		$rh_ans->{ans_message} = $rh_ans->{error_message};
		$rh_ans->clear_error('NUMBER');
	}
	$rh_ans;
}

=head3      raw_student_answer_filter()



=cut

# ^function raw_student_answer_filter
sub raw_student_answer_filter {
	my ($rh_ans) = shift;
#	warn "answer was ".$rh_ans->{student_ans};
	$rh_ans->{student_ans} = $rh_ans->{original_student_ans}
		unless ($rh_ans->{student_ans} =~ /[a-zA-Z]/);
#	warn "2nd time ... answer was ".$rh_ans->{student_ans};

	return $rh_ans;
}

=head3      no_decimal_list()



=cut

# ^function no_decimal_list
# ^uses number_list_cmp
sub no_decimal_list {
	my ($ans) = shift;
	my (%jopts) = @_;
	my $old_evaluator = number_list_cmp($ans);

	my $answer_evaluator = sub {
		my $tried = shift;
		my $ans_hash;
			if  ( ref($old_evaluator) eq 'AnswerEvaluator' ) { # new style
				$ans_hash = $old_evaluator->evaluate($tried);
			} elsif (ref($old_evaluator) eq  'CODE' )     { #old style
				$ans_hash = &$old_evaluator($tried);
		}
		if(defined($jopts{'must'}) && ! ($tried =~ /$jopts{'must'}/)) {
			$ans_hash->{score}=0;
			$ans_hash->setKeys( 'ans_message' => 'Your answer needs to be exact.');
		}
		if($tried =~ /\./) {
			$ans_hash->{score}=0;
			$ans_hash->setKeys( 'ans_message' => 'You may not use decimals in your answer.');
		}
		return $ans_hash;
	};
	return $answer_evaluator;
}


=head3      no_decimals()



=cut

# ^function no_decimals
# ^uses std_num_cmp
sub no_decimals {
	my ($ans) = shift;
	my (%jopts) = @_;
	my $old_evaluator = std_num_cmp($ans);

	my $answer_evaluator = sub {
		my $tried = shift;
		my $ans_hash;
			if  ( ref($old_evaluator) eq 'AnswerEvaluator' ) { # new style
				$ans_hash = $old_evaluator->evaluate($tried);
			} elsif (ref($old_evaluator) eq  'CODE' )     { #old style
				$ans_hash = &$old_evaluator($tried);
		}
		if(defined($jopts{'must'}) && ! ($tried =~ /$jopts{'must'}/)) {
			$ans_hash->{score}=0;
			$ans_hash->setKeys( 'ans_message' => 'Your answer needs to be exact.');
		}
		if($tried =~ /\./) {
			$ans_hash->{score}=0;
			$ans_hash->setKeys( 'ans_message' => 'You may not use decimals in your answer.');
		}
		return $ans_hash;
	};
	return $answer_evaluator;
}

=head3      with_comments()


	# Wrapper for an answer evaluator which can also supply comments

=cut

# Wrapper for an answer evaluator which can also supply comments

# ^function with_comments
sub with_comments {
	my ($old_evaluator, $cmt) = @_;

# 	$mdm = $main::displayMode;
# 	$main::displayMode = 'HTML_tth';
# 	$cmt = EV2($cmt);
# 	$main::displayMode =$mdm;

	my $ans_evaluator =  sub  {
		my $tried = shift;
		my $ans_hash;

		if  ( ref($old_evaluator) eq 'AnswerEvaluator' ) { # new style
			$ans_hash = $old_evaluator->evaluate($tried);
		} elsif (ref($old_evaluator) eq  'CODE' )     { #old style
			$ans_hash = &$old_evaluator($tried);
		} else {
			warn "There is a problem using the answer evaluator";
		}

    if($ans_hash->{score}>0) {
      $ans_hash -> setKeys( 'ans_message' => $cmt);
    }
		return $ans_hash;
	};

  $ans_evaluator;
}


=head3      pc_evaluator()


		# Wrapper for multiple answer evaluators, it takes a list of the following as inputs
		# [answer_evaluator, partial credit factor, comment]
		# it applies evaluators from the list until it hits one with positive credit,
		# weights it by the partial credit factor, and throws in its comment


=cut


# Wrapper for multiple answer evaluators, it takes a list of the following as inputs
# [answer_evaluator, partial credit factor, comment]
# it applies evaluators from the list until it hits one with positive credit,
# weights it by the partial credit factor, and throws in its comment
# ^function pc_evaluator
sub pc_evaluator {
        my @ev_list;
        if(ref($_[0]) ne 'ARRAY') {
                warn "Improper input to pc_evaluator";
        }
        if(ref($_[0]->[0]) ne 'ARRAY') {
                @ev_list = @_;
        } else {
                @ev_list = @{$_[0]};
        }
        
        my $ans_evaluator =  sub  {
                my $tried = shift;
                my $ans_hash;
                for($j=0;$j<scalar(@ev_list); $j++) {
                        my $old_evaluator = $ev_list[$j][0];
                        my $cmt = $ev_list[$j][2];
                        my $weight = $ev_list[$j][1];
                        $weight = 1 unless defined($weight);

                        if  ( ref($old_evaluator) eq 'AnswerEvaluator' ) { # new style
                                $ans_hash = $old_evaluator->evaluate($tried);
                        } elsif (ref($old_evaluator) eq  'CODE' )     { #old style
                                $ans_hash = &$old_evaluator($tried);
                        } else {
                                warn "There is a problem using the answer evaluator";
                        }
                        
                        if($ans_hash->{score}>0) {
                                $ans_hash -> setKeys( 'ans_message' => $cmt) if defined($cmt);
                                $ans_hash->{score} *= $weight;
                                return $ans_hash;
                        };
                };
                return $ans_hash;
        };
        
  $ans_evaluator;
}



=head3      weighted_partial_grader

=pod

This is a grader which weights the different parts of the problem
differently.  The weights passed to it through the environment.  In
the problem:

 $ENV{'partial_weights'} = [.2,.2,.2,.3];

This will soon be superceded by a better grader.

=cut

# ^function weighted_partial_grader
# ^uses $ENV{grader_message}
# ^uses $ENV{partial_weights}
sub weighted_partial_grader {
    my $rh_evaluated_answers = shift;
    my $rh_problem_state = shift;
    my %form_options = @_;
    my %evaluated_answers = %{$rh_evaluated_answers};
        #  The hash $rh_evaluated_answers typically contains: 
        #      'answer1' => 34, 'answer2'=> 'Mozart', etc.
       
        # By default the  old problem state is simply passed back out again.
    my %problem_state = %$rh_problem_state;
        
        
        # %form_options might include
        # The user login name 
        # The permission level of the user
        # The studentLogin name for this psvn.
        # Whether the form is asking for a refresh or
        #     is submitting a new answer.
        
        # initial setup of the answer
    my      $total=0; 
        my %problem_result = ( score => 0,
                errors => '',
                type => 'custom_problem_grader',
                msg => $ENV{'grader_message'}
                               );


    # Return unless answers have been submitted
    unless ($form_options{answers_submitted} == 1) {
        return(\%problem_result,\%problem_state);
    }
        # Answers have been submitted -- process them.
        
        ########################################################
        # Here's where we compute the score.  The variable     #
        # $numright is the number of correct answers.          #
        ########################################################


    my      $numright=0;
    my      $i;
    my      $ans_ref;

    warn "Partial value weights not defined" if not defined($ENV{'partial_weights'});
    my      @partial_weights = @{$ENV{'partial_weights'}};
    my      $total_weight=0;

    # Renormalize weights so they add to 1
    for $i (@partial_weights) { $total_weight += $i; }
    warn("Weights do not add to a positive number") unless ($total_weight >0);
    for $i (0..$#partial_weights) { $partial_weights[$i] /= $total_weight; }

    $i = 1;
    my $nextanswername = $PG->new_label($i);
    while (defined($ans_ref = $evaluated_answers{$nextanswername})) { 
      $total += $ans_ref->{score}*$partial_weights[$i-1];
      $i++;
      $nextanswername = $PG->new_label($i);
    }
    
    $problem_result{score} = $total; 
        # increase recorded score if the current score is greater.
    $problem_state{recorded_score} = $problem_result{score} if $problem_result{score} > $problem_state{recorded_score};

    $problem_state{num_of_correct_ans}++ if $total == 1;
    $problem_state{num_of_incorrect_ans}++ if $total < 1 ;
        
    (\%problem_result, \%problem_state);
}

1;

## Local Variables:
## mode: CPerl
## font-lock-mode: t
## End:
