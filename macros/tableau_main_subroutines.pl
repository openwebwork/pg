# subroutines included into the main:: package.

package main;

sub isMatrix {
	my $m = shift;
	return ref($m) =~/Value::Matrix/i;
}
sub matrix_column_slice{
	matrix_from_matrix_cols(@_);
}

sub lp_basis_pivot {
	my ($old_tableau,$old_basis,$pivot) = @_;  # $pivot is a Value::Point
	my $new_tableau= lp_clone($old_tableau);
	main::lp_pivot($new_tableau, $pivot->extract(1)-1,$pivot->extract(2)-1);	
	my $new_matrix = Matrix($new_tableau);
	my ($n,$m) = $new_matrix->dimensions;
	my $param_size = $m-$n -1;	#n=constraints+1, #m = $param_size + $constraints +2
	my $new_basis = ( $old_basis - ($pivot->extract(1)+$param_size) + ($pivot->extract(2)) )->sort;
	my @statevars = get_tableau_variable_values($new_matrix, $new_basis);
	return ( $new_tableau, Set($new_basis),\@statevars); #FIXME -- force to set (from type Union) to insure that ->data is an array and not a string.
}

sub matrix_from_matrix_cols {
	my $M = shift;   # a MathObject matrix_columns
	my($n,$m) = $M->dimensions;
	my @slice = @_;
	if (ref($slice[0]) =~ /ARRAY/) { # handle array reference
		@slice = @{$slice[0]};
	}
	@slice = @slice?@slice : (1..$m);
	my @columns = map {$M->column($_)->transpose->value} @slice;   
	 #create the chosen columns as rows
	 # then transform to array_refs.
	Matrix(@columns)->transpose;	#transpose and return an n by m matrix (2 dim)	
}
sub matrix_row_slice{
	matrix_from_matrix_rows(@_);
}

sub matrix_from_matrix_rows {
	my $M = shift;   # a MathObject matrix_columns
	unless (isMatrix($M)){
		WARN_MESSAGE( "matrix_from_matrix_rows: |".ref($M)."| or |$M| is not a MathObject Matrix");
		return undef;
	}

	my($n,$m) = $M->dimensions;
	my @slice = @_;
	if (ref($slice[0]) =~ /ARRAY/) { # handle array reference
		@slice = @{$slice[0]};
	}
	@slice = @slice? @slice : (1..$n); # the default is the whole matrix.
	# DEBUG_MESSAGE("row slice in matrix from rows is @slice");
	my @rows = map {[$M->row($_)->value]} @slice;   
	 #create the chosen columns as rows
	 # then transform to array_refs.
	Matrix([@rows]); # insure that it is still an n by m matrix	(2 dim)
}

sub matrix_extract_submatrix {
	matrix_from_submatrix(@_);
}
sub matrix_from_submatrix {
	my $M=shift;
	unless (isMatrix($M)){
		warn( "matrix_from_submatrix: |".ref($M)."| or |$M| is not a MathObject Matrix");
		return undef;
	}

	my %options = @_;
	my($n,$m) = $M->dimensions;
	my $row_slice = ($options{rows})?$options{rows}:[1..$m];
	my $col_slice = ($options{columns})?$options{columns}:[1..$n];
	# DEBUG_MESSAGE("ROW SLICE", join(" ", @$row_slice));
	# DEBUG_MESSAGE("COL SLICE", join(" ", @$col_slice));
	my $M1 = matrix_from_matrix_rows($M,@$row_slice);
	# DEBUG_MESSAGE("M1 - matrix from rows) $M1");
	return matrix_from_matrix_cols($M1, @$col_slice);
}
sub matrix_extract_rows {
	my $M =shift;
		unless (isMatrix($M)){
		WARN_MESSAGE( "matrix_extract_rows: |".ref($M)."| or |$M| is not a MathObject Matrix");
		return undef;
	}

	my @slice = @_;
	if (ref($slice[0]) =~ /ARRAY/) { # handle array reference
		@slice = @{$slice[0]};
	} elsif (@slice == 0) { # export all rows to List
		@slice = ( 1..(($M->dimensions)[0]) );	
	}
	return map {$M->row($_)} @slice ;
}

sub matrix_rows_to_list {
	List(matrix_extract_rows(@_));
}
sub matrix_columns_to_list {
	List(matrix_extract_columns(@_) );
}
sub matrix_extract_columns {
	my $M =shift;   # Add error checking
	unless (isMatrix($M)){
		WARN_MESSAGE( "matrix_extract_columns: |".ref($M)."| or |$M| is not a MathObject Matrix");
		return undef;
	}

	my @slice = @_;
	if (ref($slice[0]) =~ /ARRAY/) { # handle array reference
		@slice = @{$slice[0]};
	} elsif (@slice == 0) { # export all columns to an array
		@slice = 1..($M->dimensions->[1]);	
	}
    return map {$M->column($_)} @slice;
}



########################
##############
# get_tableau_variable_values
#
# Calculates the values of the basis variables of the tableau, 
# assuming the parameter variables are 0.
#
# Usage:   ARRAY = get_tableau_variable_values($MathObjectMatrix_tableau, $MathObjectSet_basis)
# 
# feature request -- for tableau object -- allow specification of non-zero parameter variables
sub get_tableau_variable_values {
   my $mat = shift;  # a MathObject matrix
 	unless (isMatrix($mat)){
		WARN_MESSAGE( "get_tableau_variable_values: |".ref($mat)."| or |$mat| is not a MathObject Matrix");
		return Matrix([0]);
	}
   my $basis =shift; # a MathObject set
   # FIXME
   # type check ref($mat)='Matrix'; ref($basis)='Set';
   # or check that $mat has dimensions, element methods; and $basis has a contains method
   my ($n, $m) = $mat->dimensions;
   @var = ();
   #DEBUG_MESSAGE( "start new matrix");
   foreach my $j (1..$m-2) {    # the last two columns of the tableau are object variable and constants
      if (not $basis->contains($j)) {
            # DEBUG_MESSAGE( "j= $j not in basis");  # set the parameter values to zero
           $var[$j-1]=0; next; # non-basis variables (parameters) are set to 0. 
            
      } else {
            foreach my $i (1..$n-1) {  # the last row is the objective function
               # if this is a basis column there should be only one non-zero element(the pivot)
               if ( $mat->element($i,$j)->value != 0 ) { # should this have ->value?????
                  $var[$j-1] = ($mat->element($i,$m)/($mat->element($i,$j))->value);                  
                  # DEBUG_MESSAGE("i=$i j=$j var = $var[$j-1] "); # calculate basis variable value
                 next;
               }
             
            }
      }
  }                    # element($n, $m-1) is the coefficient of the objective value. 
                       # this last variable is the value of the objective function
  # check for division by zero
  if ($mat->element($n,$m-1)->value != 0 ) {
  	push @var , ($mat->element($n,$m)/$mat->element($n,$m-1))->value;
  } else {
  	push @var , '.666';
  }
  return wantarray ? @var : \@var; # return either array or reference to an array
}
#### Test -- assume matrix is this 
#    	1	2	1	0	0 |	0 |	3
#		4	5	0	1	0 |	0 |	6
#		7	8	0	0	1 |	0 |	9
#		-1	-2	0	0	0 |	1 |	10  # objective row
# and basis is {3,4,5}  (start columns with 1)
#  $n= 4;  $m = 7
#  $x1=0; $x2=0; $x3=s1=3; $x4=s2=6; $x5=s3=9; w=10=objective value
# 
#

####################################
#
#   Cover for lp_pivot which allows us to use a set object for the new and old basis

sub lp_basis_pivot {
	my ($old_tableau,$old_basis,$pivot) = @_;  # $pivot is a Value::Point
	my $new_tableau= lp_clone($old_tableau);
	# lp_pivot has 0 based indices
	main::lp_pivot($new_tableau, $pivot->extract(1)-1,$pivot->extract(2)-1);
	# lp_pivot pivots in place	
	my $new_matrix = Matrix($new_tableau);
	my ($n,$m) = $new_matrix->dimensions;
	my $param_size = $m-$n -1;	#n=constraints+1, #m = $param_size + $constraints +2
	my $new_basis = ( $old_basis - ($pivot->extract(1)+$param_size) + ($pivot->extract(2)) )->sort;
	my @statevars = get_tableau_variable_values($new_matrix, $new_basis);
	return ( $new_tableau, Set($new_basis),\@statevars); 
	# force to set (from type Union) to insure that ->data is an array and not a string.
}
