#!/usr/local/bin/webwork-perl

###########
#use Carp;

=head1 NAME

	Matrix macros for the PG language

=head1 SYNPOSIS



=head1 DESCRIPTION

Almost all of the macros in the file are very rough at best.  The most useful is display_matrix.
Many of the other macros work with vectors and matrices stored as anonymous arrays. 

Frequently it may be
more useful to use the Matrix objects defined RealMatrix.pm and Matrix.pm and the constructs listed there.


=cut

BEGIN {
	be_strict();
}

sub _PGmatrixmacros_init {
}

# this subroutine zero_check is not very well designed below -- if it is used much it should receive
# more work -- particularly for checking relative tolerance.  More work needs to be done if this is 
# actually used.

sub zero_check{
    my $array = shift;
    my %options = @_;
	my $num = @$array;
	my $i;
	my $max = 0; my $mm;
	for ($i=0; $i< $num; $i++) {
		$mm = $array->[$i] ;
		$max = abs($mm) if abs($mm) > $max;
	}
    my $tol = $options{tol};
    $tol = 0.01*$options{reltol}*$options{avg} if defined($options{reltol}) and defined $options{avg};
    $tol = .000001 unless defined($tol);
	($max <$tol) ? 1: 0;       # 1 if the array is close to zero;
}
sub vec_dot{
	my $vec1 = shift;
	my $vec2 = shift;
	warn "vectors must have the same length" unless @$vec1 == @$vec2;  # the vectors must have the same length.
	my @vec1=@$vec1;
	my @vec2=@$vec2;
	my $sum = 0;

	while(@vec1) {
		$sum += shift(@vec1)*shift(@vec2);
	}
	$sum;
}
sub proj_vec {
	my $vec = shift;
	warn "First input must be a column matrix" unless ref($vec) eq 'Matrix' and ${$vec->dim()}[1] == 1; 
	my $matrix = shift;    # the matrix represents a set of vectors spanning the linear space 
	                       # onto which we want to project the vector.
	warn "Second input must be a matrix" unless ref($matrix) eq 'Matrix' and ${$matrix->dim()}[1] == ${$vec->dim()}[0];
	$matrix * transpose($matrix) * $vec;
}
	        
sub vec_cmp{    #check to see that the submitted vector is a non-zero multiple of the correct vector
    my $correct_vector = shift;
    my %options = @_;
	my $ans_eval = sub {
		my $in =  shift @_;
		
		my $ans_hash = new AnswerHash;
		my @in = split("\0",$in);
		my @correct_vector=@$correct_vector;		
		$ans_hash->{student_ans} = "( " . join(", ", @in ) . " )";
		$ans_hash->{correct_ans} = "( " . join(", ", @correct_vector ) . " )";

		return($ans_hash) unless @$correct_vector == @in;  # make sure the vectors are the same dimension
		
		my $correct_length = vec_dot($correct_vector,$correct_vector);
		my $in_length = vec_dot(\@in,\@in);
		return($ans_hash) if $in_length == 0; 

		if (defined($correct_length) and $correct_length != 0) {
			my $constant = vec_dot($correct_vector,\@in)/$correct_length;
			my @difference = ();
			for(my $i=0; $i < @correct_vector; $i++ ) {
				$difference[$i]=$constant*$correct_vector[$i] - $in[$i];
			}
			$ans_hash->{score} = zero_check(\@difference);
			
		} else {
			$ans_hash->{score} = 1 if vec_dot(\@in,\@in) == 0;
		}
		$ans_hash;
		
    };
    
    $ans_eval;
}

############

=head4  display_matrix

		Usage   \[ \{   display_matrix($A)  \} \]
		         \[ \{ display_matrix([ [ 1, 3], [4, 6] ])  \} \]
		
		Output is text which represents the matrix in TeX format used in math display mode.


=cut


sub display_matrix{    # will display a matrix in tex format.  
                       # the matrix can be either of type array or type 'Matrix'
	my $ra_matrix = shift;
	my $out='';
	if (ref($ra_matrix) eq 'Matrix' )  {
		my ($rows, $cols) = $ra_matrix->dim();
		$out = q!\\left(\\begin{array}{! . 'c'x$cols . q!}!;
		for( my $i=1; $i<=$rows; $i++) {
		    for (my $j=1; $j<=$cols; $j++) {
		   		my $entry = $ra_matrix->element($i,$j);
		    	$entry = "#" unless defined($entry);
		    	$out.= $entry;
		    	$out .= ($j < $cols) ? ' & ' : "\\cr\n";
		    }
		}
		$out .= "\\end{array}\\right)";
	} elsif( ref($ra_matrix) eq 'ARRAY') {
		my $rows = @$ra_matrix;
		my $cols = @{$ra_matrix->[0]};
		$out = q!\\left(\\begin{array}{! . 'c' x$cols . q!}!;
		for(my $i=0; $i<$rows; $i++) {
		    my @row = @{$ra_matrix->[$i]};
		    while (@row) {
		    	my $entry = shift(@row);
		    	$entry = "#" unless defined($entry);
		    	$out.= $entry;
		    	if (@row) {
		    		$out .= "& ";
		    	} else {
		    		next;
		    	}
		    }
			$out .=  "\\cr\n";
		}
	    $out .= "\\end{array}\\right)";
	} else {
		warn "The input" . ref($ra_matrix) . " doesn't make sense as input to display_matrix. ";
	}
	$out;
}


=head4   ra_flatten_matrix

		Usage:   ra_flatten_matrix($A)
		
			where $A is a matrix object
			The output is a reference to an array.  The matrix is placed in the array by iterating
			over  columns on the inside
			loop, then over the rows. (e.g right to left and then down, as one reads text)


=cut


sub ra_flatten_matrix{
	my $matrix = shift;
	warn "The argument must be a matrix object" unless ref($matrix) =~ /Matrix/;
	my @array = ();
 	my ($rows, $cols ) = $matrix->dim();
	foreach my $i (1..$rows) {
		foreach my $j (1..$cols) {
   			push(@array, $matrix->element($i,$j)  );
   		}
   	}
   	\@array;
}

# This subroutine is probably obsolete and not generally useful.  It was patterned after the APL
# constructs for multiplying matrices. It might come in handy for non-standard multiplication of 
# of matrices (e.g. mod 2) for indice matrices.
sub apl_matrix_mult{
	my $ra_a= shift;
	my $ra_b= shift;
	my %options = @_;
	my $rf_op_times= sub {$_[0] *$_[1]};
	my $rf_op_plus = sub {my $sum = 0; my @in = @_; while(@in){ $sum = $sum + shift(@in) } $sum; };
	$rf_op_times = $options{'times'} if defined($options{'times'}) and ref($options{'times'}) eq 'CODE';
	$rf_op_plus = $options{'plus'} if defined($options{'plus'}) and ref($options{'plus'}) eq 'CODE';
	my $rows = @$ra_a;
	my $cols = @{$ra_b->[0]};
	my $k_size = @$ra_b;
	my $out ;
	my ($i, $j, $k);
	for($i=0;$i<$rows;$i++) {
		for($j=0;$j<$cols;$j++) {
		    my @r = ();
		    for($k=0;$k<$k_size;$k++) {
		    	$r[$k] =  &$rf_op_times($ra_a->[$i]->[$k] , $ra_b->[$k]->[$j]);
		    }
			$out->[$i]->[$j] = &$rf_op_plus( @r );
		}
	}
	$out;
}

sub matrix_mult {
	apl_matrix_mult($_[0], $_[1]);
}

sub make_matrix{
	my $function = shift;
	my $rows = shift;
	my $cols = shift;
	my ($i, $j, $k);
	my $ra_out;
	for($i=0;$i<$rows;$i++) {
		for($j=0;$j<$cols;$j++) {
			$ra_out->[$i]->[$j] = &$function($i,$j);
		}
	}
	$ra_out;
}

     
# sub format_answer{
# 	my $ra_eigenvalues = shift;
# 	my $ra_eigenvectors = shift;
# 	my $functionName = shift;
# 	my @eigenvalues=@$ra_eigenvalues;
# 	my $size= @eigenvalues;
# 	my $ra_eigen = make_matrix( sub {my ($i,$j) = @_; ($i==$j) ? "e^{$eigenvalues[$j] t}": 0 }, $size,$size);
# 	my $out = qq!
# 				$functionName(t) =! .
# 				                    displayMatrix(apl_matrix_mult($ra_eigenvectors,$ra_eigen,
#                                     'times'=>sub{($_[0] and $_[1]) ? "$_[0]$_[1]"  : ''},
#                                     'plus'=>sub{ my $out = join("",@_); ($out) ?$out : '0' }
#                                     ) ) ;
#        $out;
# }
# sub format_vector_answer{
# 	my $ra_eigenvalues = shift;
# 	my $ra_eigenvectors = shift;
# 	my $functionName = shift;
# 	my @eigenvalues=@$ra_eigenvalues;
# 	my $size= @eigenvalues;
# 	my $ra_eigen = make_matrix( sub {my ($i,$j) = @_; ($i==$j) ? "e^{$eigenvalues[$j] t}": 0 }, $size,$size);
# 	my $out = qq!
# 				$functionName(t) =! .
# 				                    displayMatrix($ra_eigenvectors)."e^{$eigenvalues[0] t}" ;
#        $out;
# }
# sub format_question{
# 	my $ra_matrix = shift;
# 	my $out = qq! y'(t) = ! . displayMatrix($B). q! y(t)!
# 
# }

1;
