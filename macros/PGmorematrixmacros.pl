#!/usr/local/bin/webwork-perl

BEGIN{
	be_strict();
}

sub _PGmorematrixmacros_init{}

sub random_inv_matrix { ## Builds and returns a random invertible \$row by \$col matrix.

    warn "Usage: \$new_matrix = random_inv_matrix(\$rows,\$cols)"
      if (@_ != 2);
    my $A = new Matrix($_[0],$_[1]);
    my $A_lr = new Matrix($_[0],$_[1]);
    my $det = 0;
    my $safety=0;
    while ($det == 0 and $safety < 6) {
        foreach my $i (1..$_[0]) {
            foreach my $j (1..$_[1]) {
                $A->assign($i,$j,random(-9,9,1) );
                }
            }
            $A_lr = $A->decompose_LR();
            $det = $A_lr->det_LR();
        }
    return $A;
}

sub swap_rows{

    warn "Usage: \$new_matrix = swap_rows(\$matrix,\$row1,\$row2);"
      if (@_ != 3);
    my $matrix = $_[0];
    my ($i,$j) = ($_[1],$_[2]);
    warn "Error:  Rows to be swapped must exist!" 
      if ($i>@$matrix or $j >@$matrix);
    warn "Warning:  Swapping the same row is pointless"
      if ($i==$j);    
    my $cols = @{$matrix->[0]};
    my $B = new Matrix(@$matrix,$cols);
    foreach my $k (1..$cols){
        $B->assign($i,$k,element $matrix($j,$k));
        $B->assign($j,$k,element $matrix($i,$k));
    }
    return $B;
}

sub row_mult{

    warn "Usage: \$new_matrix = row_mult(\$matrix,\$scalar,\$row);"
      if (@_ != 3);
    my $matrix = $_[0];
    my ($scalar,$row) = ($_[1],$_[2]);
    warn "Undefined row multiplication" 
      if ($row > @$matrix);
    my $B = new Matrix(@$matrix,@{$matrix->[0]});
    foreach my $j (1..@{$matrix->[0]}) {
        $B->assign($row,$j,$scalar*element $matrix($row,$j));
    }
    return $B;
}

sub linear_combo{

    warn "Usage: \$new_matrix = linear_combo(\$matrix,\$scalar,\$row1,\$row2);"
      if (@_ != 4);
    my $matrix = $_[0];
    my ($scalar,$row1,$row2) = ($_[1],$_[2],$_[3]);
    warn "Undefined row in multiplication"
      if ($row1>@$matrix or $row2>@$matrix);
    warn "Warning:  Using the same row"
      if ($row1==$row2);
    my $B = new Matrix(@$matrix,@{$matrix->[0]});
    foreach my $j (1..@$matrix) {
        my ($t1,$t2) = (element $matrix($row1,$j),element $matrix($row2,$j));
        $B->assign($row2,$j,$scalar*$t1+$t2);
    }
    return $B;
}

=head3 basis_cmp()

Compares a list of vectors by finding the change of coordinate matrix
from the Prof's vectors to the students, and then taking the determinant of
that to determine the existence of the change of coordinate matrix going the
other way.

ANS( basis_cmp( vectors_as_array_ref_in_array_ref, options_hash ) );

	1. a reference to an array of correct vectors
	2. a hash with the following keys (all optional):
		mode			--	'basis' (default) (only a basis allowed)
							'orthogonal' (only an orthogonal basis is allowed)
							'unit' (only unit vectors in the basis allowed)
							'orthonormal' (only orthogonal unit vectors in basis allowed)
		zeroLevelTol	--	absolute tolerance to allow when answer is close
								 to zero

		debug			--	if set to 1, provides verbose listing of
								hash entries throughout fliters.

		help		--	'none' (default) (is quiet on all errors)
					'dim' (Tells student if wrong number of vectors are entered)
					'length' (Tells student if there is a vector of the wrong length)
					'orthogonal' (Tells student if their vectors are not orthogonal)
							(This is only in orthogonal mode)
					'unit' (Tells student if there is a vector not of unit length)
							(This is only in unit mode)
					'orthonormal' (Gives errors from orthogonal and orthonormal)
							(This is only in orthonormal mode)
					'verbose' (Gives all the above answer messages)				

	Returns an answer evaluator.

EXAMPLES:

	basis_cmp([[1,0,0],[0,1,0],[0,0,1]])
									--	correct answer is any basis for R^3.
	basis_cmp([1,0,2,0],[0,1,0,0], 'mode'=>orthonormal )
									--	correct answer is any orthonormal basis
										for this space such as:
										[1/sqrt(3),0,2/sqrt(3),0],[0,1,0,0]

=cut


sub basis_cmp {
	my $correctAnswer = shift;
	my %opt	= @_;

 	set_default_options(	\%opt,
				'zeroLevelTol'				=>	$main::functZeroLevelTolDefault,
	       			'debug'					=>	0,
				'mode'					=>	'basis',
				'help'					=>	'none',
     	);
	
	# produce answer evaluator
	BASIS_CMP(
				'correct_ans'			=>	$correctAnswer,
				'zeroLevelTol'			=>	$opt{'zeroLevelTol'},
				'debug'				=>	$opt{'debug'},
				'mode'				=> 	$opt{'mode'},
				'help'				=>	$opt{'help'},				
	);
}

=head BASIS_CMP

Made to keep the same format as num_cmp and fun_cmp.

=cut

sub BASIS_CMP {
	my %mat_params = @_;
	my $zeroLevelTol				=	$mat_params{'zeroLevelTol'};
	
	# Check that everything is defined:
	$mat_params{debug} = 0 unless defined($mat_params{debug});
	$zeroLevelTol = $main::functZeroLevelTolDefault			unless defined $zeroLevelTol;
	$mat_params{'zeroLevelTol'}  			= 	$zeroLevelTol;

## This is where the correct answer should be checked someday.
	my $matrix					=	Matrix->new_from_col_vecs($mat_params{'correct_ans'});

#construct the answer evaluator
 	my $answer_evaluator = new AnswerEvaluator;

    	$answer_evaluator->{debug} = $mat_params{debug};

    	$answer_evaluator->ans_hash( 	correct_ans 		=> 	pretty_print($mat_params{correct_ans}),
					rm_correct_ans		=> 	$matrix,
					zeroLevelTol		=>	$mat_params{zeroLevelTol},
					debug			=>	$mat_params{debug},
					mode			=> 	$mat_params{mode},
					help			=>	$mat_params{help},
    	);

	$answer_evaluator->install_pre_filter(sub {my $rh_ans = shift;
		$rh_ans->{student_ans} =~ s/\s+//g;		# remove all whitespace
		$rh_ans;
	});

	$answer_evaluator->install_pre_filter(\&math_constants);
	$answer_evaluator->install_pre_filter(sub{my $rh_ans = shift; my @options = @_;
		if( $rh_ans->{ans_label} =~ /ArRaY/ ){
			$rh_ans = ans_array_filter($rh_ans,@options);		
			my @student_array = @{$rh_ans->{ra_student_ans}};
			my @array = ();
			for( my $i = 0; $i < scalar(@student_array) ; $i ++ )
			{
				push( @array, Matrix->new_from_array_ref($student_array[$i]));
			}
			$rh_ans->{ra_student_ans} = \@array;
			$rh_ans;
		}else{
			vec_list_string($rh_ans,@options);
		}
			
	});#ra_student_ans is now the students answer as an array of vectors
	# anonymous subroutine to check dimension and length of the student vectors
	# if either is wrong, the answer is wrong.
	$answer_evaluator->install_pre_filter(sub{
		my $rh_ans = shift;
		my $length = $rh_ans->{rm_correct_ans}->[1];
		my $dim = $rh_ans->{rm_correct_ans}->[2];
		if( $dim != scalar(@{$rh_ans->{ra_student_ans}}))
		{
		
			$rh_ans->{score} = 0;
			if( $rh_ans->{help} =~ /dim|verbose/ )
			{
				$rh_ans->throw_error('EVAL','You have entered the wrong number of vectors.');
			}else{
				$rh_ans->throw_error('EVAL');
			}
		}
		for( my $i = 0; $i < scalar( @{$rh_ans->{ra_student_ans} }) ; $i++ )
		{
			if( $length != $rh_ans->{ra_student_ans}->[$i]->[1])
			{
				$rh_ans->{score} = 0;
				if( $rh_ans->{help} =~ /length|verbose/ )
				{
					$rh_ans->throw_error('EVAL','You have entered vector(s) of the wrong length.');
				}else{
					$rh_ans->throw_error('EVAL');
				}
			}
		}
		$rh_ans;
	});
	# Install prefilter for various modes
	if( $mat_params{mode} ne 'basis' )
	{
		if( $mat_params{mode} =~ /orthogonal|orthonormal/ )
		{
			$answer_evaluator->install_pre_filter(sub{
				my $rh_ans = shift;
				my @vecs = @{$rh_ans->{ra_student_ans}};
				my ($i,$j) = (0,0);
				my $num = scalar(@vecs);
				my $length = $vecs[0]->[1];
				
				for( ; $i < $num ; $i ++ )
				{
					for( $j = $i+1; $j < $num ; $j++ )
					{
						my $sum = 0;
						my $k = 0;

						for( ; $k < $length; $k++ ) {
							$sum += $vecs[$i]->[0][$k][0]*$vecs[$j]->[0][$k][0];
						}
					
						if( $sum > $mat_params{zeroLevelTol} )
						{
							$rh_ans->{score} = 0;
							if( $rh_ans->{help} =~ /orthogonal|orthonormal|verbose/ )
							{
								$rh_ans->throw_error('EVAL','You have entered vectors which are not orthogonal. ');
							}else{
								$rh_ans->throw_error('EVAL');
							}			
						}
					}
				}
				
				
				$rh_ans;
			});
		}
		
		if( $mat_params{mode} =~ /unit|orthonormal/ )
		{
			$answer_evaluator->install_pre_filter(sub{
				my $rh_ans = shift;
				my @vecs = @{$rh_ans->{ra_student_ans}};
				my $i = 0;
				my $num = scalar(@vecs);
				my $length = $vecs[0]->[1];
				
				for( ; $i < $num ; $i ++ )
				{
					my $sum = 0;
					my $k = 0;

					for( ; $k < $length; $k++ ) {
						$sum += $vecs[$i]->[0][$k][0]*$vecs[$i]->[0][$k][0];
					}
					if( abs(sqrt($sum) - 1) > $mat_params{zeroLevelTol} )
					{
						$rh_ans->{score} = 0;
						
						if( $rh_ans->{help} =~ /unit|orthonormal|verbose/ )
						{
							$rh_ans->throw_error('EVAL','You have entered vector(s) which are not of unit length.');
						}else{
							$rh_ans->throw_error('EVAL');
						}				
					}
				}
				
				
				$rh_ans;
			});
					
		}
	}
    	$answer_evaluator->install_evaluator(\&compare_basis, %mat_params);
 	$answer_evaluator->install_post_filter(
		sub {my $rh_ans = shift;
				if ($rh_ans->catch_error('SYNTAX') ) {
					$rh_ans->{ans_message} = $rh_ans->{error_message};
					$rh_ans->clear_error('SYNTAX');
				}
				if ($rh_ans->catch_error('EVAL') ) {
					$rh_ans->{ans_message} = $rh_ans->{error_message};
					$rh_ans->clear_error('EVAL');
				}
				$rh_ans;
		}
	);
	$answer_evaluator;
}

=head4 compare_basis

	compare_basis( $ans_hash, %options);

	   			      {ra_student_ans},     # a reference to the array of students answer vectors
	                             {rm_correct_ans},	    # a reference to the correct answer matrix
	                             %options               
	                            )

=cut

sub compare_basis {
	my ($rh_ans, %options) = @_;
	my @ch_coord;
	my @vecs = @{$rh_ans->{ra_student_ans}};
	
	# A lot of the follosing code was taken from Matrix::proj_coeff
	# calling this method recursively would be a waste of time since
	# the prof's matrix never changes and solve_LR is an expensive
	# operation. This way it is only done once.
	my $matrix = $rh_ans->{rm_correct_ans};
	my ($dim,$x_vector, $base_matrix);
	my $errors = undef;
	my $lin_space_tr= ~ $matrix;
	$matrix = $lin_space_tr * $matrix;
	my $matrix_lr = $matrix->decompose_LR();
	
	#finds the coefficient vectors for each of the students vectors
	for( my $i = 0; $i < scalar(@{$rh_ans->{ra_student_ans}}) ; $i++ )
	{
	
		$vecs[$i] = $lin_space_tr*$vecs[$i];
		($dim,$x_vector, $base_matrix) = $matrix_lr->solve_LR($vecs[$i]);
		push( @ch_coord, $x_vector );
		$errors = "A unique adapted answer could not be determined.  Possibly the parameters have coefficient zero.<br>  dim = $dim base_matrix is $base_matrix\n" if $dim;  # only print if the dim is not zero.
	}
	
	if( defined($errors))
	{
		$rh_ans->throw_error('EVAL', $errors) ;
	}else{
		my $ch_coord_mat = Matrix->new_from_col_vecs(\@ch_coord);#creates change of coordinate matrix
									#existence of this matrix implies that
									#the all of the students answers are a
									#linear combo of the prof's
		$ch_coord_mat = $ch_coord_mat->decompose_LR();
		
		if( $ch_coord_mat->det_LR() > $options{zeroLevelTol} )# if the det of the change of coordinate matrix is
									# non-zero, this implies the existence of an inverse
									# which implies all of the prof's vectors are a linear
									# combo of the students vectors, showing containment
									# both ways.
		{ 
			# I think sometimes if the students space has the same dimension as the profs space it
			# will get projected into the profs space even if it isn't a basis for that space.
			# this just checks that the prof's matrix times the change of coordinate matrix is actually
			#the students matrix
			if(  abs(Matrix->new_from_col_vecs(\@{$rh_ans->{ra_student_ans}}) - ($rh_ans->{rm_correct_ans})*(Matrix->new_from_col_vecs(\@ch_coord))) < $options{zeroLevelTol} )
			{
				$rh_ans->{score} = 1;
			}else{
				$rh_ans->{score} = 0;
			}
		}
		else{
			$rh_ans->{score}=0;
		}
	}
	$rh_ans;
	
}


=head 2 vec_list_string

This is a check_syntax type method (in fact I borrowed some of that method's code) for vector input.
The student needs to enter vectors like:        [1,0,0],[1,2,3],[0,9/sqrt(10),1/sqrt(10)]
Each entry can contain functions and operations and the usual math constants (pi and e).
The vectors, however can not be added or multiplied or scalar multiplied by the student.
Most errors are handled well. Any error in an entry is caught by the PG_answer_eval like it is in num_cmp or fun_cmp.
Right now the method basically ignores every thing outside the vectors. Also, an unmatched open parenthesis is caught,
but a unmatched close parenthesis ends the vector, and since everything outside is ignored, no error is sent (other than the
later when the length of the vectors is checked.
In the end, the method returns an array of Matrix objects.
	

=cut

sub vec_list_string{
	my $rh_ans = shift;
	my %options = @_;
	my $i;
	my $entry = "";
	my $char;
	my @paren_stack;
	my $length = length($rh_ans->{student_ans});
	my @temp;
	my $j = 0;
	my @answers;
	my $paren;
	my $display_ans;
	
	for( $i = 0; $i < $length ; $i++ )
	{
		$char = substr($rh_ans->{student_ans},$i,1);
	
		if( $char =~ /\(|\[|\{/ ){
				push( @paren_stack, $char )
		}
		
		if( !( $char =~ /\(|\[|\{/ && scalar(@paren_stack) == 1 ) )
		{
			if( $char !~ /,|\)|\]|\}/ ){
				$entry .= $char;
			}else{
				if( $char =~ /,/ || ( $char =~ /\)|\]|\}/ && scalar(@paren_stack) == 1 ) )
				{
					if( length($entry) == 0 ){
						if( $char !~ /,/ ){
							$rh_ans->throw_error('EVAL','There is a syntax error in your answer');
						}else{
								$rh_ans->{preview_text_string}   .= ",";
								$rh_ans->{preview_latex_string}  .= ",";
								$display_ans .= ",";				
						}
					}else{
					
						# This parser code was origianally taken from PGanswermacros::check_syntax
						# but parts of it needed to be slighty modified for this context
						my $parser = new AlgParserWithImplicitExpand;
						my $ret	= $parser -> parse($entry);			#for use with loops

						if ( ref($ret) )  {		## parsed successfully
							$parser -> tostring();
							$parser -> normalize();
							$entry = $parser -> tostring();
							$rh_ans->{preview_text_string} .= $entry.",";
							$rh_ans->{preview_latex_string} .=	$parser -> tolatex().",";

						} else {					## error in	parsing

							$rh_ans->{'student_ans'}			=	'syntax error:'.$display_ans. $parser->{htmlerror},
							$rh_ans->{'ans_message'}			=	$display_ans.$parser -> {error_msg},
							$rh_ans->{'preview_text_string'}	=	'',
							$rh_ans->{'preview_latex_string'}	=	'',
							$rh_ans->throw_error('SYNTAX',	'syntax error in answer:'.$display_ans.$parser->{htmlerror} . "$main::BR" .$parser -> {error_msg}.".$main::BR");
						}
					
						my ($inVal,$PG_eval_errors,$PG_full_error_report) = PG_answer_eval($entry);
			
						if ($PG_eval_errors) {
							$rh_ans->throw_error('EVAL','There is a syntax error in your answer.') ;
							$rh_ans->{ans_message} = clean_up_error_msg($PG_eval_errors);
							last;
						} else {
							$entry = prfmt($inVal,$options{format});
							$display_ans .= $entry.",";
							push(@temp , $entry);
						}
						
						if( $char =~ /\)|\]|\}/ && scalar(@paren_stack) == 1)
						{	
							pop @paren_stack;
							chop($rh_ans->{preview_text_string});
							chop($rh_ans->{preview_latex_string});
							chop($display_ans);
							$rh_ans->{preview_text_string} .= "]";
							$rh_ans->{preview_latex_string} .= "]";
							$display_ans .= "]";
							if( scalar(@temp) > 0 )
							{
								push( @answers,Matrix->new_from_col_vecs([\@temp]));
								while(scalar(@temp) > 0 ){
									pop @temp;
								}
							}else{
								$rh_ans->throw_error('EVAL','There is a syntax error in your answer.');
							}
						}
					}
					$entry = "";	   	
				}else{	
					$paren = pop @paren_stack;
					if( scalar(@paren_stack) > 0 ){
						#this uses ASCII to check if the parens match up
						# in ASCII ord ( = 40 , ord ) = 41 , ord [ = 91 ,
						# ord ] = 93 , ord { = 123 , ord } = 125
						if( (ord($char) - ord($paren) <= 2) ){
							$entry = $entry . $char;
						}else{
							$rh_ans->throw_error('EVAL','There is a syntax error in your answer');
						}		
					}
				}
			}
		}else{
			$rh_ans->{preview_text_string}   .= "[";
			$rh_ans->{preview_latex_string}  .= "[";
			$display_ans .= "[";
		}
	}
	$rh_ans->{ra_student_ans} = \@answers;
	$rh_ans->{student_ans} = $display_ans unless $rh_ans->{error_flag};
	$rh_ans;
}

sub ans_array_filter{
	my $rh_ans = shift;
	my %options = @_;
	$rh_ans->{ans_label} =~ /ArRaY(\d+)\[\d+,\d+,\d+\]/;
	my $ans_num = $1;
	my @keys = grep /ArRaY$ans_num/, keys(%{$main::inputs_ref});
	my $key;
	my @array = ();
	my ($i,$j,$k) = (0,0,0);
	
	#the keys aren't in order, so their info has to be put into the array before doing anything with it
	foreach $key (@keys){
		$key =~ /ArRaY\d+\[(\d+),(\d+),(\d+)\]/;
		($i,$j,$k) = ($1,$2,$3);
		$array[$i][$j][$k] = ${$main::inputs_ref}{'ArRaY'.$ans_num.'['.$i.','.$j.','.$k.']'};		
	}
	
	my $display_ans = "";
	
	for( $i=0; $i < scalar(@array) ; $i ++ )
	{
		$display_ans .= " [";
	        $rh_ans->{preview_text_string} .= ' [';       
        	$rh_ans->{preview_latex_string} .= ' [';
		for( $j = 0; $j < scalar( @{$array[$i]} ) ; $j++ )
		{
			$display_ans .= " [";
	                $rh_ans->{preview_text_string} .= ' [';       
        	        $rh_ans->{preview_latex_string} .= ' ['; 
			for( $k = 0; $k < scalar( @{$array[$i][$j]} ) ; $k ++ ){
				my $entry = $array[$i][$j][$k];
				
				# This parser code was origianally taken from PGanswermacros::check_syntax
				# but parts of it needed to be slighty modified for this context
				my $parser = new AlgParserWithImplicitExpand;
				my $ret	= $parser -> parse($entry);			#for use with loops

				if ( ref($ret) )  {		## parsed successfully
					$parser -> tostring();
					$parser -> normalize();
					$entry = $parser -> tostring();
					$rh_ans->{preview_text_string} .= $entry.",";
					$rh_ans->{preview_latex_string} .=	$parser -> tolatex().",";
				} else {					## error in	parsing
					$rh_ans->{'student_ans'}			=	'syntax error:'.$display_ans. $parser->{htmlerror},
					$rh_ans->{'ans_message'}			=	$display_ans.$parser -> {error_msg},
					$rh_ans->{'preview_text_string'}	=	'',
					$rh_ans->{'preview_latex_string'}	=	'',
					$rh_ans->throw_error('SYNTAX',	'syntax error in answer:'.$display_ans.$parser->{htmlerror} . "$main::BR" .$parser -> {error_msg}.".$main::BR");
				}
				
				my ($inVal,$PG_eval_errors,$PG_full_error_report) = PG_answer_eval($entry);
				if ($PG_eval_errors) {
					$rh_ans->throw_error('EVAL','There is a syntax error in your answer.') ;
					$rh_ans->{ans_message} = clean_up_error_msg($PG_eval_errors);
					last;
				} else {
					$entry = prfmt($inVal,$options{format});
					$display_ans .= $entry.",";
					$array[$i][$j][$k] = $entry;
				}		
			}
			chop($rh_ans->{preview_text_string});
			chop($rh_ans->{preview_latex_string});
			chop($display_ans);
	                $rh_ans->{preview_text_string} .= '] ,';       
        	        $rh_ans->{preview_latex_string} .= '] ,';      
			$display_ans .= '] ,';	
		
		}
		chop($rh_ans->{preview_text_string});
		chop($rh_ans->{preview_latex_string});
		chop($display_ans);
                $rh_ans->{preview_text_string} .= '] ,';        
                $rh_ans->{preview_latex_string} .= '] ,';       
		$display_ans .= '] ,';	
	}
	chop($rh_ans->{preview_text_string});
	chop($rh_ans->{preview_latex_string});
	chop($display_ans);
	
	$rh_ans->{original_student_ans} = $display_ans;	
	$rh_ans->{ra_student_ans} = \@array;
	$rh_ans->{student_ans} = $display_ans;
	
	$rh_ans;

}

1;
