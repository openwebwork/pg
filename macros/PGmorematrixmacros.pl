
BEGIN{
    be_strict();
}
# set the prefix used for arrays.
our $ArRaY = $main::PG->{ARRAY_PREFIX};

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

=head4 random_diag_matrix

This method returns a random nxn diagonal matrix.

=cut

sub random_diag_matrix{ ## Builds and returns a random diagonal \$n by \$n matrix
    
    warn "Usage: \$new_matrix = random_diag_matrix(\$n)" if (@_ != 1);
    
    my $D = new Matrix($_[0],$_[0]);
    my $norm = 0;
    while( $norm == 0 ){
        foreach my $i (1..$_[0]){
            foreach my $j (1..$_[0]){
                if( $i != $j ){
                    $D->assign($i,$j,0);
                }else{
                    $D->assign($i,$j,random(-9,9,1));
                }           
            }       
        }
        $norm = abs($D);
    }
    return $D;
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
        mode            --  'basis' (default) (only a basis allowed)
                            'orthogonal' (only an orthogonal basis is allowed)
                            'unit' (only unit vectors in the basis allowed)
                            'orthonormal' (only orthogonal unit vectors in basis allowed)
        zeroLevelTol    --  absolute tolerance to allow when answer is close
                                 to zero

        debug           --  if set to 1, provides verbose listing of
                                hash entries throughout fliters.

        help        --  'none' (default) (is quiet on all errors)
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
                                    --  correct answer is any basis for R^3.
    basis_cmp([1,0,2,0],[0,1,0,0], 'mode'=>orthonormal )
                                    --  correct answer is any orthonormal basis
                                        for this space such as:
                                        [1/sqrt(3),0,2/sqrt(3),0],[0,1,0,0]

=cut


sub basis_cmp {
    my $correctAnswer = shift;
    my %opt = @_;

    set_default_options(    \%opt,
            'zeroLevelTol'          =>  $main::functZeroLevelTolDefault,
            'debug'                 =>  0,
            'mode'                  =>  'basis',
            'help'                  =>  'none',
    );
    
    # produce answer evaluator
    BASIS_CMP(
            'correct_ans'       =>  $correctAnswer,
            'zeroLevelTol'      =>  $opt{'zeroLevelTol'},
            'debug'             =>  $opt{'debug'},
            'mode'              =>  $opt{'mode'},
            'help'              =>  $opt{'help'},               
    );
}

=head1 BASIS_CMP

Made to keep the same format as num_cmp and fun_cmp.

=cut

sub BASIS_CMP {
    my %mat_params = @_;
    my $zeroLevelTol                =   $mat_params{'zeroLevelTol'};
    
    # Check that everything is defined:
    $mat_params{debug} = 0 unless defined($mat_params{debug});
    $zeroLevelTol = $main::functZeroLevelTolDefault         unless defined $zeroLevelTol;
    $mat_params{'zeroLevelTol'}             =   $zeroLevelTol;

## This is where the correct answer should be checked someday.
    my $matrix                  =   Matrix->new_from_col_vecs($mat_params{'correct_ans'});

#construct the answer evaluator
    my $answer_evaluator = new AnswerEvaluator;

    $answer_evaluator->{debug} = $mat_params{debug};
    $answer_evaluator->ans_hash(    
        correct_ans         =>  display_correct_vecs($mat_params{correct_ans}),
        rm_correct_ans      =>  $matrix,
        zeroLevelTol        =>  $mat_params{zeroLevelTol},
        debug               =>  $mat_params{debug},
        mode                =>  $mat_params{mode},
        help                =>  $mat_params{help},
    );

    $answer_evaluator->install_pre_filter(
        sub {my $rh_ans              = shift;
            $rh_ans->{_filter_name}  = 'remove_white_space';
            $rh_ans->{student_ans}   =~ s/\s+//g;       # remove all whitespace
            $rh_ans;
        }
    );
    $answer_evaluator->install_pre_filter(
        sub{my $rh_ans      = shift; 
            my @options     = @_;
            $rh_ans->{_filter_name}  = 'mung_student_answer';
            if( $rh_ans->{ans_label} =~ /$ArRaY/ ){
                $rh_ans           = ans_array_filter($rh_ans,@options);     
                my @student_array = @{$rh_ans->{ra_student_ans}};
                my @array         = ();
                for( my $i = 0; $i < scalar(@student_array) ; $i ++ )
                {
                    push( @array, Matrix->new_from_array_ref($student_array[$i]));
                }
                $rh_ans->{ra_student_ans} = \@array;
                $rh_ans;
            }else{
                $rh_ans->{student_ans}    = math_constants($rh_ans->{student_ans});
                vec_list_string($rh_ans, '_filter_name' => 'vec_list_string', @options);
            }
        }
    );#ra_student_ans is now the students answer as an array of vectors
    # anonymous subroutine to check dimension and length of the student vectors
    # if either is wrong, the answer is wrong.
    $answer_evaluator->install_pre_filter(
        sub{
            my $rh_ans               = shift;
            $rh_ans->{_filter_name}  = 'check_vector_size';
            my $length               = $rh_ans->{rm_correct_ans}->[1];
            my $dim                  = $rh_ans->{rm_correct_ans}->[2];
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
        }
    );
    # Install prefilter for various modes
    if( $mat_params{mode} ne 'basis' )
    {
        if( $mat_params{mode} =~ /orthogonal|orthonormal/ )
        {
            $answer_evaluator->install_pre_filter(\&are_orthogonal_vecs);
        }
        
        if( $mat_params{mode} =~ /unit|orthonormal/ )
        {
            $answer_evaluator->install_pre_filter(\&are_unit_vecs);
                    
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

    compare_basis( $ans_hash, 
        %options
        ra_student_ans     # a reference to the array of students answer vectors
        rm_correct_ans,    # a reference to the correct answer matrix
        %options               
    )


=cut



sub compare_basis {
    my ($rh_ans, %options) = @_;
    $rh_ans->{_filter_name} = "compare_basis";
    my @ch_coord;
    my @vecs = @{$rh_ans->{ra_student_ans}};
    
    # A lot of the following code was taken from Matrix::proj_coeff
    # calling this method recursively would be a waste of time since
    # the prof's matrix never changes and solve_LR is an expensive
    # operation. This way it is only done once.
    my $matrix = $rh_ans->{rm_correct_ans};
    my ($dim,$x_vector, $base_matrix);
    my $errors = undef;
    my $lin_space_tr= ~ $matrix; #transpose of the matrix
    $matrix = $lin_space_tr * $matrix;  #(~A * A)
    my $matrix_lr = $matrix->decompose_LR();
    
    #finds the coefficient vectors for each of the students vectors
    for( my $i = 0; $i < scalar(@{$rh_ans->{ra_student_ans}}) ; $i++ ) {
    
        $vecs[$i] = $lin_space_tr*$vecs[$i];
        ($dim,$x_vector, $base_matrix) = $matrix_lr->solve_LR($vecs[$i]);
        push( @ch_coord, $x_vector );
        $errors = "A unique adapted answer could not be determined.  
        Possibly the parameters have coefficient zero.<br>  dim = $dim base_matrix 
        is $base_matrix\n" if $dim;  # only print if the dim is not zero.
    }
    
    if( defined($errors)) {
        $rh_ans->throw_error('EVAL', $errors) ;
    } else {
        my $ch_coord_mat = Matrix->new_from_col_vecs(\@ch_coord);
            #creates change of coordinate matrix
            #existence of this matrix implies that
            #the all of the students answers are a
            #linear combo of the prof's
        $ch_coord_mat = $ch_coord_mat->decompose_LR();
        
        if( abs($ch_coord_mat->det_LR()) > $options{zeroLevelTol} ) {
            # if the det of the change of coordinate  matrix is
            # non-zero, this implies the existence of an inverse
            # which implies all of the prof's vectors are a linear
            # combo of the students vectors, showing containment
            # both ways.

            # I think sometimes if the students space has the same dimension as the profs space it
            # will get projected into the profs space even if it isn't a basis for that space.
            # this just checks that the prof's matrix times the change of coordinate matrix is actually
            #the students matrix
            if(  abs(Matrix->new_from_col_vecs(\@{$rh_ans->{ra_student_ans}}) - 
                ($rh_ans->{rm_correct_ans})*(Matrix->new_from_col_vecs(\@ch_coord))) 
                < $options{zeroLevelTol} ) {
                $rh_ans->{score} = 1;
            } else {
                $rh_ans->{score} = 0;
            }
        } else {
            $rh_ans->{score}=0;
        }
    }
    $rh_ans;
    
}


=head2 vec_list_string

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
    
    for( $i = 0; $i < $length ; $i++ ) {
        $char = substr($rh_ans->{student_ans},$i,1);
    
        if( $char =~ /\(|\[|\{/ ){
                push( @paren_stack, $char )
        }
        
        if( !( $char =~ /\(|\[|\{/ && scalar(@paren_stack) == 1 ) ) {
            if( $char !~ /,|\)|\]|\}/ ){
                $entry .= $char;
            } else {
                if( $char =~ /,/ || ( $char =~ /\)|\]|\}/ && scalar(@paren_stack) == 1 ) ) {
                    if( length($entry) == 0 ){
                        if( $char !~ /,/ ){
                            $rh_ans->throw_error('EVAL','There is a syntax error in your answer');
                        } else {
                                $rh_ans->{preview_text_string}   .= ",";
                                $rh_ans->{preview_latex_string}  .= ",";
                                $display_ans .= ",";                
                        }
                    } else {
                    
                        # This parser code was origianally taken from PGanswermacros::check_syntax
                        # but parts of it needed to be slighty modified for this context
                        my $parser = new AlgParserWithImplicitExpand;
                        my $ret = $parser -> parse($entry);         #for use with loops

                        if ( ref($ret) )  {     ## parsed successfully
                            $parser -> tostring();
                            $parser -> normalize();
                            $entry = $parser -> tostring();
                            $rh_ans->{preview_text_string} .= $entry.",";
                            $rh_ans->{preview_latex_string} .=  $parser -> tolatex().",";

                        } else {                    ## error in parsing

                            $rh_ans->{'student_ans'}            =   'syntax error:'.$display_ans. $parser->{htmlerror},
                            $rh_ans->{'ans_message'}            =   $display_ans.$parser -> {error_msg},
                            $rh_ans->{'preview_text_string'}    =   '',
                            $rh_ans->{'preview_latex_string'}   =   '',
                            $rh_ans->throw_error('SYNTAX',  'syntax error in answer:'.$display_ans.$parser->{htmlerror} . "$main::BR" .$parser -> {error_msg}.".$main::BR");
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
                        
                        if( $char =~ /\)|\]|\}/ && scalar(@paren_stack) == 1) { 
                            pop @paren_stack;
                            chop($rh_ans->{preview_text_string});
                            chop($rh_ans->{preview_latex_string});
                            chop($display_ans);
                            $rh_ans->{preview_text_string} .= "]";
                            $rh_ans->{preview_latex_string} .= "]";
                            $display_ans .= "]";
                            if( scalar(@temp) > 0 ) {
                                push( @answers,Matrix->new_from_col_vecs([\@temp]));
                                while(scalar(@temp) > 0 ){
                                    pop @temp;
                                }
                            } else {
                                $rh_ans->throw_error('EVAL','There is a syntax error in your answer.');
                            }
                        }
                    }
                    $entry = "";        
                } else {    
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
        } else {
            $rh_ans->{preview_text_string}   .= "[";
            $rh_ans->{preview_latex_string}  .= "[";
            $display_ans .= "[";
        }
    }
    $rh_ans->{ra_student_ans} = \@answers;
    $rh_ans->{student_ans} = $display_ans unless $rh_ans->{error_flag};
    $rh_ans;
}

=head5 ans_array_filter

    This filter was created to get, format, and evaluate each entry of the ans_array and ans_array_extension
    answer entry methods. Running this filter is necessary to get all the entries out of the answer
    hash. Each entry is evaluated and the resulting number is put in the display for student answer
    as a string. For evaluation purposes an array of arrays of arrays is created called ra_student_ans
    and placed in the hash. The entries are [array_number][row_number][column_number]. The latex strings
    for each entry are taken from the parser and put, as a matrix, into the previewer. The preview text
    string is also created, but this display method becomes confusing when large matrices are used.

=cut


sub ans_array_filter{
    my $rh_ans = shift;
    my %options = @_;
#   assign_option_aliases( \%opt,
#     );
    set_default_options(\%options,
		_filter_name  =>  'ans_array_filter',             
    );
#   $rh_ans->{ans_label} =~ /$ArRaY(\d+)\[\d+,\d+,\d+\]/;  # CHANGE made to accomodate HTML 4.01 standards for name attribute
    $rh_ans->{ans_label} =~ /$ArRaY(\d+)\_\_\d+\-\d+\-\d+\_\_/;
    my $ans_num = $1;
    my @keys = grep /$ArRaY$ans_num/, keys(%{$main::inputs_ref});
    my $key;
    my @array = ();
    my ($i,$j,$k) = (0,0,0);
    
    #the keys aren't in order, so their info has to be put into the array before doing anything with it
    foreach $key (@keys){
#       $key =~ /ArRaY\d+\[(\d+),(\d+),(\d+)\]/;
#       ($i,$j,$k) = ($1,$2,$3);
#       $array[$i][$j][$k] = ${$main::inputs_ref}{'ArRaY'.$ans_num.'['.$i.','.$j.','.$k.']'};
        $key =~ /$ArRaY\d+\_\_(\d+)\-(\d+)\-(\d+)\_\_/;
        ($i,$j,$k) = ($1,$2,$3);
        $array[$i][$j][$k] = ${$main::inputs_ref}{"$ArRaY".$ans_num.'__'.$i.'-'.$j.'-'.$k.'__'};     

    }
    #$rh_ans->{debug_student_answer }=  \@array;
    my $display_ans = "";
        
    for( $i=0; $i < scalar(@array) ; $i ++ ) {
        $display_ans .= " [";
            $rh_ans->{preview_text_string} .= ' [';       
            $rh_ans->{preview_latex_string} .= '\begin{pmatrix} ';
        for( $j = 0; $j < scalar( @{$array[$i]} ) ; $j++ ) {
            $display_ans .= " [";
                    $rh_ans->{preview_text_string} .= ' [';       
                    for( $k = 0; $k < scalar( @{$array[$i][$j]} ) ; $k ++ ){
                my $entry = $array[$i][$j][$k];
                $entry = math_constants($entry);
                # This parser code was origianally taken from PGanswermacros::check_syntax
                # but parts of it needed to be slighty modified for this context
                my $parser = new AlgParserWithImplicitExpand;
                my $ret = $parser -> parse($entry);         #for use with loops

                if ( ref($ret) )  {     ## parsed successfully
                    $parser -> tostring();
                    $parser -> normalize();
                    $entry = $parser -> tostring();
                    $rh_ans->{preview_text_string} .= $entry.",";
                    $rh_ans->{preview_latex_string} .= $parser -> tolatex() . '& ';
                    
                } else {                    ## error in parsing
                    $rh_ans->{'student_ans'}            =   'syntax error:'.$display_ans. $parser->{htmlerror},
                    $rh_ans->{'ans_message'}            =   $display_ans.$parser -> {error_msg},
                    $rh_ans->{'preview_text_string'}    =   '',
                    $rh_ans->throw_error('SYNTAX',  'syntax error in answer:'.$display_ans.$parser->{htmlerror} . "$main::BR" .$parser -> {error_msg}.".$main::BR");
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
            chop($display_ans);
                    $rh_ans->{preview_text_string} .= '] ,';       
                   $rh_ans->{preview_latex_string} .= '\\\\';     
            $display_ans .= '] ,';  
        
        }
        chop($rh_ans->{preview_text_string});
        chop($display_ans);
                $rh_ans->{preview_text_string} .= '] ,';        
                $rh_ans->{preview_latex_string} .= '\end{pmatrix}'.' , ';
        $display_ans .= '] ,';  
    }
    chop($rh_ans->{preview_text_string});
    chop($rh_ans->{preview_latex_string});
    chop($rh_ans->{preview_latex_string});
    chop($rh_ans->{preview_latex_string});
    chop($display_ans);

    my @temp = ();
    for( $i = 0 ; $i < scalar( @array ); $i++ ){
        push @temp , display_matrix($array[$i], 'left'=>'.', 'right'=>'.');
        push @temp , "," unless $i == scalar(@array) - 1;
    }
    $rh_ans->{student_ans} = mbox(\@temp);
    $rh_ans->{ra_student_ans} = \@array;
    
    $rh_ans;

}


sub are_orthogonal_vecs{
    my ($vec_ref , %opts) = @_;
    $vec_ref->{_filter_name}  = 'are_orthogonal_vecs';
    my @vecs = ();
    if( ref($vec_ref) eq 'AnswerHash' )
    {
        @vecs = @{$vec_ref->{ra_student_ans}};
    }else{
        @vecs = @{$vec_ref};
    }
     
    my $num = scalar(@vecs);
    my $length = $vecs[0]->[1];
    
    for( my $i=0; $i < $num ; $i ++ ) {
        for( my $j = $i+1; $j < $num ; $j++ ) {
            if( $vecs[$i]->scalar_product($vecs[$j]) > $main::functZeroLevelTolDefault ) {
                if( ref( $vec_ref ) eq 'AnswerHash' ){
                    $vec_ref->{score} = 0;
                    if( $vec_ref->{help} =~ /orthogonal|orthonormal|verbose/ )
                    {
                        $vec_ref->throw_error('EVAL','You have entered vectors which are not orthogonal. ');
                    }else{
                        $vec_ref->throw_error('EVAL');
                    }
                    return $vec_ref;
                } else {
                    return 0;
                }               
            }
        }
    }
    if( ref( $vec_ref ) eq 'AnswerHash' ){
        $vec_ref->{score} = 1;
        $vec_ref;
    } else {
        1;
    }
}

sub is_diagonal{
    my $matrix  =   shift;
    my %options     =   @_;
    my $process_ans_hash = ( ref( $matrix ) eq 'AnswerHash' ) ? 1 : 0 ;
    my ($rh_ans);
    if ($process_ans_hash) {
        $rh_ans = $matrix;
        $matrix = $rh_ans->{ra_student_ans};
    }

    return 0 unless defined($matrix);

    if( ref($matrix) eq 'ARRAY' ) {
        my @matrix = @{$matrix};
        @matrix = @{$matrix[0]} if ref($matrix[0][0]) eq 'ARRAY';
        if( ref($matrix[0]) ne 'ARRAY' or scalar( @matrix ) != scalar( @{$matrix[0]} ) ){
            warn "It is impossible for a non-square matrix to be diagonal, if you are a student, please tell your professor that there is a problem."; 
        }
        
        for( my $i = 0; $i < scalar( @matrix ) ; $i++ ) {
            for( my $j = 0; $j < scalar( @{$matrix[0]} ); $j++ ){
                if( $matrix[$i][$j] != 0 and $i != $j )
                {
                        if ($process_ans_hash){
                            $rh_ans->throw_error('EVAL');
                            return $rh_ans;
                        } else {
                        return 0;
                    }                   
                }               
            }       
        }
        if ($process_ans_hash){
            return $rh_ans;
            } else {
            return 1;
        }
    } elsif ( ref($matrix) eq 'Matrix' ) {
        if( $matrix->[1] != $matrix->[2] ) {
            warn "It is impossible for a non-square matrix to be diagonal, if you are a student, please tell your professor that there is a problem."; 
            if ($process_ans_hash){
                $rh_ans->throw_error('EVAL');
                    return $rh_ans;
                } else {
                return 0;
            }
        }
        for( my $i = 0; $i < $matrix->[1] ; $i++ ) {
            for( my $j = 0; $j < $matrix->[2] ; $j++ ) {
                if( $matrix->[0][$i][$j] != 0 and $i != $j ){
                        if ($process_ans_hash){
                            $rh_ans->throw_error('EVAL');
                        return $rh_ans;
                        } else {
                        return 0;
                    }
                }
            }
        }
        if ($process_ans_hash) {
            return $rh_ans;
            } else {
            return 1;
        }
    } else {
        warn "There is a problem with the problem, please alert your professor.";
        if ($process_ans_hash){
            $rh_ans->throw_error('EVAL');
                return $rh_ans;
            } else {
            return 0;
        }
    }

}


sub are_unit_vecs{
    my ( $vec_ref,%opts ) = @_;
    $vec_ref->{_filter_name}  = 'are_unit_vecs';
    my @vecs = ();
    if( ref($vec_ref) eq 'AnswerHash' )
    {
        @vecs = @{$vec_ref->{ra_student_ans}};
    }else{
        @vecs = @{$vec_ref};
    }
    
    my $i = 0;
    my $num = scalar(@vecs);
    my $length = $vecs[0]->[1];
        
    for( ; $i < $num ; $i ++ ) {
        if( abs(sqrt($vecs[$i]->scalar_product($vecs[$i]))- 1) > $main::functZeroLevelTolDefault )
        {
            if( ref( $vec_ref ) eq 'AnswerHash' ){
                $vec_ref->{score} = 0;
                if( $vec_ref->{help} =~ /unit|orthonormal|verbose/ )
                {
                    $vec_ref->throw_error('EVAL','You have entered vector(s) which are not of unit length.');
                }else{
                    $vec_ref->throw_error('EVAL');
                }
                return $vec_ref;
            }else{
                return 0;
            }
                                
        }
    }
                
    if( ref( $vec_ref ) eq 'AnswerHash' ){
        $vec_ref->{score} = 1;
        $vec_ref;
    }else{
        1;
    }
}

sub display_correct_vecs{
    my ( $ra_vecs,%opts ) = @_;
    my @ra_vecs = @{$ra_vecs};
    my @temp = ();
    
    for( my $i = 0 ; $i < scalar(@ra_vecs) ; $i++ ) {
        push @temp, display_matrix(Matrix->new_from_col_vecs([$ra_vecs[$i]]),'left'=>'.','right'=>'.');
        push @temp, ",";
    }
    
    pop @temp;
    
    mbox(\@temp);

}

sub vec_solution_cmp{
    my $correctAnswer = shift;
    my %opt = @_;

    set_default_options(    \%opt,
                'zeroLevelTol'          =>  $main::functZeroLevelTolDefault,
                'debug'                 =>  0,
                'mode'                  =>  'basis',
                'help'                  =>  'none',
    );
    
    
## This is where the correct answer should be checked someday.
    my $matrix                  =   Matrix->new_from_col_vecs($correctAnswer);
    
    
#construct the answer evaluator
    my $answer_evaluator = new AnswerEvaluator;

    $answer_evaluator->{debug}           = $opt{debug};
    $answer_evaluator->ans_hash(    
                    correct_ans         =>  display_correct_vecs($correctAnswer),
                    old_correct_ans     =>  $correctAnswer,
                    rm_correct_ans      =>  $matrix,
                    zeroLevelTol        =>  $opt{zeroLevelTol},
                    debug               =>  $opt{debug},
                    mode                =>  $opt{mode},
                    help                =>  $opt{help},
    );

    $answer_evaluator->install_pre_filter(\&ans_array_filter);
    $answer_evaluator->install_pre_filter(
    	sub{
            my ($rh_ans,@options) = @_; 
            $rh_ans->{_filter_name} = "create student answer as an array of vectors";
            my @student_array = @{$rh_ans->{ra_student_ans}};
            my @array = ();
            for( my $i = 0; $i < scalar(@student_array) ; $i ++ ) {
                push( @array, Matrix->new_from_array_ref($student_array[$i]));
            }
            $rh_ans->{ra_student_ans} = \@array;
            $rh_ans;
    	}
    );
    #ra_student_ans is now the students answer as an array of vectors
    # anonymous subroutine to check dimension and length of the student vectors
    # if either is wrong, the answer is wrong.
    $answer_evaluator->install_pre_filter(
    	sub{
			my $rh_ans = shift;
			$rh_ans->{_filter_name} = "check_dimension_and_length";
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
			for( my $i = 0; $i < scalar( @{$rh_ans->{ra_student_ans} }) ; $i++ ) {
				if( $length != $rh_ans->{ra_student_ans}->[$i]->[1]) {
					$rh_ans->{score} = 0;
					if( $rh_ans->{help} =~ /length|verbose/ ) {
						$rh_ans->throw_error('EVAL','You have entered vector(s) of the wrong length.');
					}else{
						$rh_ans->throw_error('EVAL');
					}
				}
			}
			$rh_ans;
    	}
    );
    # Install prefilter for various modes
    if( $opt{mode} ne 'basis' )  {
        if( $opt{mode} =~ /orthogonal|orthonormal/ ) {
            $answer_evaluator->install_pre_filter(\&are_orthogonal_vecs);
        }
        
        if( $opt{mode} =~ /unit|orthonormal/ ) {
            $answer_evaluator->install_pre_filter(\&are_unit_vecs);
                    
        }
    }
        
    $answer_evaluator->install_evaluator(\&compare_vec_solution, %opt);
    
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

        
sub compare_vec_solution {
    my ( $rh_ans, %options ) = @_ ;
    $rh_ans->{_filter_name} = "compare_vec_solution";
    my @space = @{$rh_ans->{ra_student_ans}};
    my $solution = shift @space;
    
    # A lot of the following code was taken from Matrix::proj_coeff
    # calling this method recursively would be a waste of time since
    # the prof's matrix never changes and solve_LR is an expensive
    # operation. This way it is only done once.
    my $matrix = $rh_ans->{rm_correct_ans};
    my ($dim,$x_vector, $base_matrix);
    my $errors = undef;
    my $lin_space_tr= ~ $matrix;
    $matrix = $lin_space_tr * $matrix;
    my $matrix_lr = $matrix->decompose_LR();
    
    #this section determines whether or not the first vector, a solution to
    #the system, is a linear combination of the prof's vectors in which there
    #is a nonzero coefficient on the first term, the prof's solution to the system
    $solution = $lin_space_tr*$solution;
    ($dim,$x_vector, $base_matrix) = $matrix_lr->solve_LR($solution);
    #$rh_ans->{debug_compare_vec_solution} = $x_vector->element(1,1);
    if( $dim ){
        $rh_ans->throw_error('EVAL', "A unique adapted answer could not be determined.  Possibly the parameters have coefficient zero.<br>  dim = $dim base_matrix is $base_matrix\n" );  # only print if the dim is not zero.
        $rh_ans->{score} = 0;
        $rh_ans;
    } elsif( abs($x_vector->element(1,1) -1) >= $options{zeroLevelTol} ) { 
    	# changes by MEG 6/24/05
        # the student answer needs to be a linear combination of the instructors vectors
        # and the coefficient of the first vector needs to be 1 (it is NOT enough that it be non-zero).
        # if this is not the case, then the answer is wrong.
        # replaced   $x_vector->[0][0][0]  by $x_vector->element(1,1)  since this doesn't depend on the internal structure of the matrix object.
        
        $rh_ans->{score} = 0;
        $rh_ans;
    } else {
        $rh_ans->{score} = 1;
        my @correct_space = @{$rh_ans->{old_correct_ans}};
        shift @correct_space;
        $rh_ans->{rm_correct_ans} = Matrix->new_from_col_vecs(\@correct_space);
        $rh_ans->{ra_student_ans} = \@space;
        return compare_basis( $rh_ans, %options );
    }
}

1;
