
BEGIN {
	be_strict(); # an alias for use strict.  This means that all global variable must contain main:: as a prefix.

}
package Matrix;
@Matrix::ISA = qw(MatrixReal1);

use Carp;

$Matrix::DEFAULT_FORMAT = '% #-19.12E ';
# allows specification of the format
sub _stringify
{
    my($object,$argument,$flag) = @_;
#   my($name) = '""'; #&_trace($name,$object,$argument,$flag);
    my($rows,$cols) = ($object->[1],$object->[2]);
    my($i,$j,$s);

    $s = '';
    for ( $i = 0; $i < $rows; $i++ )
    {
        $s .= "[ ";
        for ( $j = 0; $j < $cols; $j++ )
        {
            my $format = (defined($object->rh_options->{display_format}))
            		     ?   $object->[3]->{display_format} :
										$Matrix::DEFAULT_FORMAT;
            $s .= sprintf($Matrix::DEFAULT_FORMAT, $object->[0][$i][$j]);
        }
        $s .= "]\n";
    }
    return($s);
}

sub rh_options {
    my $self = shift;
    my $last_element = $#$self;
    $self->[$last_element] = {} unless defined($self->[3]); # not sure why this needs to be done
	$self->[$last_element];     # provides a reference to the options hash MEG
}


sub trace {
	my $self = shift;
	my $rows = $self->[1];
	my $cols = $self->[2];
	warn "Can't take trace of non-square matrix " unless $rows == $cols;
	my $sum = 0;
	for( my $i = 0; $i<$rows;$i++) {
		$sum +=$self->[0][$i][$i];
	}
	$sum;
}
sub new_from_array_ref {  # this will build a matrix or a row vector from  [a, b, c, ]
	my $class = shift;
	my $array = shift;
	my $rows = @$array;
	my $cols = @{$array->[0]};
	my $matrix = new Matrix($rows,$cols);
	$matrix->[0]=$array;
	$matrix;
}

sub array_ref {
	my $this = shift;
	$this->[0];
}

sub list {           # this is used only for column vectors
	my $self = shift;
	my @list = ();
	warn "This only works with column vectors" unless $self->[2] == 1;
	my $rows = $self->[1];
	for(my $i=1; $i<=$rows; $i++) {
		push(@list, $self->element($i,1) );
	}
	@list;
}
sub new_from_list {   # this builds a row vector from an array
	my $class = shift;
	my @list = @_;
	my $cols = @list;
	my $rows = 1;
	my $matrix = new Matrix($rows, $cols);
	my $i=1;
	while(@list) {
	    my $elem = shift(@list);
		$matrix->assign($i++,1, $elem);
	}
	$matrix;
}
sub new_row_matrix {   # this builds a row vector from an array
	my $class = shift;
	my @list = @_;
	my $cols = @list;
	my $rows = 1;
	my $matrix = new Matrix($rows, $cols);
	my $i=1;
	while(@list) {
	    my $elem = shift(@list);
		$matrix->assign($i++,1, $elem);
	}
	$matrix;
}
sub proj{
	my $self = shift;
	my ($vec) = @_;
	$self * $self ->proj_coeff($vec);
}
sub proj_coeff{
	my $self= shift;
	my ($vec) = @_;
	warn 'The vector must be of type Matrix',ref($vec),"|" unless ref($vec) eq 'Matrix';
	my $lin_space_tr= ~ $self;
	my $matrix = $lin_space_tr * $self;
	$vec = $lin_space_tr*$vec;
	my $matrix_lr = $matrix->decompose_LR;
	my ($dim,$x_vector, $base_matrix) = $matrix_lr->solve_LR($vec);
	warn "A unique adapted answer could not be determined.  Possibly the parameters have coefficient zero.<br>  dim = $dim base_matrix is $base_matrix\n" if $dim;  # only print if the dim is not zero.
	$x_vector;
}
sub new_column_matrix {
	my $class = shift;
	my $vec = shift;
	warn "The argument to assign column must be a reference to an array" unless ref($vec) =~/ARRAY/;
	my $cols = 1;
	my $rows = @{$vec};
	my $matrix = new Matrix($rows,1);
	foreach my $i (1..$rows) {
		$matrix->assign($i,1,$vec->[$i-1]);
	}
	$matrix;
}
=head4

	This method takes an array of column vectors, or an array of arrays,
	and converts them to a matrix where each column is one of the previous
	vectors.

=cut

sub new_from_col_vecs
{
	my $class = shift;
 	my($vecs) = shift;
 	my($rows,$cols);

	if(ref($vecs->[0])eq 'Matrix' ){
		($rows,$cols) = (scalar($vecs->[0]->[1]),scalar(@$vecs));
	}else{
		($rows,$cols) = (scalar(@{$vecs->[0]}),scalar(@$vecs));
	}

	my($i,$j);
    	my $matrix = Matrix->new($rows,$cols);

  	if(ref($vecs->[0])eq 'Matrix' ){
	    	for ( $i = 0; $i < $cols; $i++ )
    		{
    			for( $j = 0; $j < $rows; $j++ )
			{
	        		$matrix->[0][$j][$i] = $vecs->[$i][0][$j][0];
			}
    		}
	}else{
		for ( $i = 0; $i < $cols; $i++ )
    		{
    			for( $j = 0; $j < $rows; $j++ )
			{
	        		$matrix->[0][$j][$i] = $vecs->[$i]->[$j];
			}
    		}
	}
    	return($matrix);
}

######################################################################
#  Modifications to MatrixReal.pm which allow use of complex entries
######################################################################

sub cp  { # MEG  makes new copies of complex number
	my $z = shift;
	return $z unless ref($z);
	my $w = Complex1::cplx($z->Re,$z->Im);
	return $w;
}
sub copy
{
    croak "Usage: \$matrix1->copy(\$matrix2);"
      if (@_ != 2);

    my($matrix1,$matrix2) = @_;
    my($rows1,$cols1) = ($matrix1->[1],$matrix1->[2]);
    my($rows2,$cols2) = ($matrix2->[1],$matrix2->[2]);
    my($i,$j);

    croak "MatrixReal1::copy(): matrix size mismatch"
      unless (($rows1 == $rows2) && ($cols1 == $cols2));

    for ( $i = 0; $i < $rows1; $i++ )
    {
	my $r1 = []; # New array ref
	my $r2 = $matrix2->[0][$i];
	#@$r1 = @$r2; # Copy whole array directly  #MEG
	# if the array contains complex objects new objects must be created.
	foreach (@$r2) {
		push(@$r1,cp($_) );
	}
	$matrix1->[0][$i] = $r1;
    }
        $matrix1->[3] = $matrix2->[3]; # sign or option
    if (defined $matrix2->[4]) # is an LR decomposition matrix!
    {
    #    $matrix1->[3] = $matrix2->[3]; # $sign
        $matrix1->[4] = $matrix2->[4]; # $perm_row
        $matrix1->[5] = $matrix2->[5]; # $perm_col
        $matrix1->[6] = $matrix2->[6]; # $option
    }
}
###################################################################

# MEG added 6/25/03 to accomodate complex entries
sub conj {
	my $elem = shift;
    $elem = (ref($elem)) ? ($elem->conjugate) : $elem;
    $elem;
}
sub transpose
{
    croak "Usage: \$matrix1->transpose(\$matrix2);"
      if (@_ != 2);

    my($matrix1,$matrix2) = @_;
    my($rows1,$cols1) = ($matrix1->[1],$matrix1->[2]);
    my($rows2,$cols2) = ($matrix2->[1],$matrix2->[2]);

    croak "MatrixReal1::transpose(): matrix size mismatch"
      unless (($rows1 == $cols2) && ($cols1 == $rows2));

    $matrix1->_undo_LR();

    if ($rows1 == $cols1)
    {
        # more complicated to make in-place possible!
        # # conj added by MEG
        for (my $i = 0; $i < $rows1; $i++)
        {
            for (my $j = ($i + 1); $j < $cols1; $j++)
            {   
                my $swap              = conj($matrix2->[0][$i][$j]);
                $matrix1->[0][$i][$j] = conj($matrix2->[0][$j][$i]);
                $matrix1->[0][$j][$i] = $swap;
            }
            $matrix1->[0][$i][$i] = conj($matrix2->[0][$i][$i]);
        }
       
    }
    else # ($rows1 != $cols1)
    {
        for (my $i = 0; $i < $rows1; $i++)
        {
            for (my $j = 0; $j < $cols1; $j++)
            {
                $matrix1->[0][$i][$j] = conj($matrix2->[0][$j][$i]);
            }
        }
    }
    $matrix1;
}




1;