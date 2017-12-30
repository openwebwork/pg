#!/usr/bin/perl -w 

# this file needs documentation and unit testing.
# where is it used?

##### From gage_matrix_ops
# 2014_HKUST_demo/templates/setSequentialWordProblem/bill_and_steve.pg:"gage_matrix_ops.pl",

=head1 Tableaus and matrices

 # We're going to have several types
 # MathObject Matrices  Value::Matrix
 # tableaus form John Jones macros
 # MathObject tableaus
 #   Containing   an  matrix $A  coefficients for constraint
 #   A vertical vector $b for constants for constraints
 #   A horizontal vector $c for coefficients for objective function
 #   A vertical vector corresponding to the  value  $z of the objective function
 #   dimensions $n problem vectors, $m constraints = $m slack variables
 #   A basis Value::Set -- positions for columns which are independent and 
 #      whose associated variables can be determined
 #      uniquely from the parameter variables.  
 #      The non-basis (parameter) variables are set to zero. 
 #
 #  state variables (assuming parameter variables are zero or when given parameter variables)
 # create the methods for updating the various containers
 # create the method for printing the tableau with all its decorations 
 # possibly with switches to turn the decorations on and off. 


The structure of the tableau is: 

	-----------------------------------------------------------
	|                    |             |    |    |
	|          A         |    S        | 0  | b  |
	|                    |             |    |    |
	----------------------------------------------
	|        -c          |     0       | 1  | 0  |
	----------------------------------------------
	Matrix A, the constraint matrix is n by m
	Matrix S, the slack variables is m by m
	Matrix b, the constraint constants is n by 1
	The next to the last column holds z or objective value
	z(...x^i...) = c_i* x^i  (Einstein summation convention)


=cut

=head2 Package main

=cut

=item  get_tableau_variable_values
 
	Parameters: ($MathObjectMatrix_tableau, $MathObjectSet_basis)
	Returns: ARRAY or ARRAY_ref 
	
Returns the solution variables to the tableau assuming 
that the parameter (non-basis) variables 
have been set to zero. It returns a list in 
array context and a reference to 
an array in scalar context. 

=item  lp_basis_pivot
	
	Parameters: ($old_tableau,$old_basis,$pivot)
	Returns: ($new_tableau, Set($new_basis),\@statevars)
	
=item linebreak_at_commas

	Parameters: ()
	Return:
	
	Useage: 
	$foochecker =  $constraints->cmp()->withPostFilter(
		linebreak_at_commas()
    );

Replaces commas with line breaks in the latex presentations of the answer checker.
Used most often when $constraints is a LinearInequality math object.



=head2 Package tableau

=item  Tableau->new(A=>Matrix, b=>Vector or Matrix, c=>Vector or Matrix)

	A => undef, # constraint matrix  MathObjectMatrix
	b => undef, # constraint constants Vector or MathObjectMatrix 1 by n
	c => undef, # coefficients for objective function Vector or MathObjectMatrix 1 by n
	obj_row => undef, # contains the negative of the coefficients of the objective function.
	z => undef, # value for objective function
	n => undef, # dimension of problem variables (columns in A)
	m => undef, # dimension of slack variables (rows in A)
	S => undef, # square m by m matrix for slack variables
	basis => undef, # list describing the current basis columns corresponding to determined variables.
	B => undef,  # square invertible matrix corresponding to the current basis columns
	M => undef,  # matrix of consisting of all columns and all rows except for the objective function row 
	obj_col_num => undef, 
	# flag indicating the column (1 or n+m+1) for the objective value
	constraint_labels => undef,
	problem_var_labels => undef, 
	slack_var_labels => undef,

=item  $self->current_tableau
		Parameters: ()
		Returns:  A MathObjectMatrix_tableau
		
This represents the current version of the tableau

=item  $self->objective_row
		Parameters: ()
		Returns: 

=item  $self->basis
		Parameter: ARRAY or ARRAY_ref or ()
		Returns: MathObject_list
		
		FiXME -- this should accept a MathObject_List (or MO_Set?)
		
=head3 Package Tableau (eventually package Matrix?)

=item  $self->row_slice

		Parameter: @slice or \@slice 
		Return: MathObject matrix

=item  $self->extract_rows

		Parameter: @slice or \@slice 
		Return: two dimensional array ref 
		
=item  extract_rows_to_list

		Parameter: @slice or \@slice 
		Return: MathObject List of row references

=item   $self->extract_columns

		Parameter: @slice or \@slice 
		Return: two dimensional array ref 

=item  $self->column_slice

		Parameter: @slice or \@slice 
		Return: MathObject Matrix

=item  $self->extract_columns_to_list

		Parameter: @slice or \@slice 
		Return: MathObject List of Matrix references ?

=item $self->submatrix

		Parameter:(rows=>\@row_slice,columns=>\@column_slice)
		Return: MathObject matrix
		

=cut 


sub _tableau_init {};   # don't reload this file
package main;

sub matrix_column_slice{
	matrix_from_matrix_cols(@_);
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
	return undef unless ref($M) =~ /Value::Matrix/;
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
   my $basis =shift; # a MathObject set
   # FIXME
   # type check ref($mat)='Matrix'; ref($basis)='Set';
   # or check that $mat has dimensions, element methods; and $basis has a contains method
   my ($n, $m) = $mat->dimensions;
   @var = ();
   #DEBUG_MESSAGE( "start new matrix");
   foreach my $j (1..$m-2) {    # the last two columns of the tableau are object variable and constants
      if (not $basis->contains($j)) {
            DEBUG_MESSAGE( "j= $j not in basis");  # set the parameter values to zero
            $var[$j-1]=0; next; # non-basis variables (parameters) are set to 0. 
            
      } else {
            foreach my $i (1..$n-1) {  # the last row is the objective function
               # if this is a basis column there should be only one non-zero element(the pivot)
               if ( $mat->element($i,$j)->value != 0 ) { # should this have ->value?????
                  $var[$j-1] = ($mat->element($i,$m)/($mat->element($i,$j))->value);                  
                  DEBUG_MESSAGE("i=$i j=$j var = $var[$j-1] "); # calculate basis variable value
                  next;
               }
             
            }
      }
  }                    # element($n, $m-1) is the coefficient of the objective value. 
                       # this last variable is the value of the objective function
  push @var , ($mat->element($n,$m)/$mat->element($n,$m-1))->value;

  return wantarray ? @var : \@var;
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

 
 
sub linebreak_at_commas {
	return sub {
		my $ans=shift;
		my $foo = $ans->{correct_ans_latex_string};
		$foo =~ s/,/,\\\\\\\\/g;
		($ans->{correct_ans_latex_string})=~ s/,/,\\\\\\\\/g;
		($ans->{preview_latex_string})=~ s/,/,\\\\\\\\/g;
		#DEBUG_MESSAGE("foo", $foo);
		#DEBUG_MESSAGE( "correct", $ans->{correct_ans_latex_string} );
		#DEBUG_MESSAGE( "preview",  $ans->{preview_latex_string} );
		#DEBUG_MESSAGE("section4ans1 ", pretty_print($ans, $displayMode));
		$ans;
	};
}
# Useage
# $foochecker =  $constraints->cmp()->withPostFilter(
# 	linebreak_at_commas()
# );


### End gage_matrix_ops include 



##################################################
package Tableau;
our @ISA = qw(Value::Matrix Value);

sub _Matrix {   # can we just import this?
                # this is a function, not a method
	Value::Matrix->new(@_);
}

sub new {
	my $self = shift; my $class = ref($self) || $self;
	my $context = (Value::isContext($_[0]) ? shift : $self->context);
	my $tableau = {
		A => undef, # constraint matrix  MathObjectMatrix
		b => undef, # constraint constants Vector or MathObjectMatrix 1 by n
		c => undef, # coefficients for objective function Vector or MathObjectMatrix 1 by n
		obj_row => undef, # contains the negative of the coefficients of the objective function.
		z => undef, # value for objective function
		n => undef, # dimension of problem variables (columns in A)
		m => undef, # dimension of slack variables (rows in A)
		S => undef, # square m by m matrix for slack variables
		basis => undef, # list describing the current basis columns corresponding to determined variables.
		B => undef,  # square invertible matrix corresponding to the current basis columns
		M => undef,  # matrix of consisting of all columns and all rows except for the objective function row and column
		obj_col_num => undef, # flag indicating the column (1 or n+m+1) for the objective value
		constraint_labels => undef,
		problem_var_labels => undef, 
		slack_var_labels => undef,
		@_,
	};
	bless $tableau, $class;
	$tableau->initialize();
	return $tableau;
}

# the following are used to construct the tableau
# initialize
# assemble_matrix
# objective_row
sub initialize {
	$self= shift;
	unless (ref($self->{A}) =~ /Value::Matrix/ &&
	        ref($self->{b}) =~ /Value::Vector|Value::Matrix/ && 
	        ref($self->{c}) =~ /Value::Vector|Value::Matrix/){
		main::WARN_MESSAGE("Error: Required inputs: Tableau(A=> Matrix, b=>Vector, c=>Vector)");
		return;
	}
	my ($m, $n)=($self->{A}->dimensions);
	$self->{n}=$self->{n}//$n;
	$self->{m}=$self->{m}//$m;
	# main::DEBUG_MESSAGE("m $m, n $n");
	$self->{S} = Value::Matrix->I($m);
	$self->{basis} = [($n+1)...($n+$m)] unless ref($self->{basis})=~/ARRAY/;
	my @rows = $self->assemble_matrix;
	#main::DEBUG_MESSAGE("rows", @rows);
	$self->{M} = _Matrix([@rows]);
	$self->{B} = $self->{M}->submatrix(rows=>[1..($self->{m})],columns=>$self->{basis});
	$self->{obj_row} = _Matrix($self->objective_row());
	return();	
}
		
sub assemble_matrix {
	my $self = shift;
	my @rows =();
	my $m = $self->{m};
	my $n = $self->{n};
	foreach my $i (1..$m) {
		my @current_row=();
		foreach my $j (1..$n) {
			push @current_row, $self->{A}->element($i, $j);
		}
		foreach my $j (1..$m) {
			push @current_row, $self->{S}->element($i,$j); # slack variables
		}
		push @current_row, 0, $self->{b}->data->[$i-1];    # obj column and constant column
		push @rows, [@current_row]; 
	}

	return @rows;   # these are the matrices A | S | obj | b   
	                # the final row describing the objective function is not in this 
}

sub objective_row {
	my $self = shift;
	my @last_row=();
	push @last_row, ( -($self->{c}) )->value;
	foreach my $i (1..($self->{m})) { push @last_row, 0 };
	push @last_row, 1, 0;
	return \@last_row;
}

# return a matrix containing the entire tableau
sub current_tableau {
	my $Badj = ($self->{B}->det) * ($self->{B}->inverse);
	my $current_tableau = $Badj * $self->{M};  # the A | S | obj | b
	$self->{current_tableau}=$current_tableau;
	# find the coefficients associated with the basis columns
	my $c_B  = $self->{obj_row}->extract_columns($self->{basis} );
	my $c_B2 = Value::Vector->new([ map {$_->value} @$c_B]);
	my $correction_coeff = ($c_B2*$current_tableau )->row(1);
	# subtract the correction coefficients from the obj_row
	# this essentially extends Gauss reduction applied to the obj_row
	my $obj_row_normalized = ($self->{B}->det) *$self->{obj_row};
	my $current_coeff = $obj_row_normalized-$correction_coeff ;
	$self->{current_coeff}= $current_coeff; 

	#main::DEBUG_MESSAGE("subtract these two ", (($self->{B}->det) *$self->{obj_row}), " | ", ($c_B*$current_tableau)->dimensions);
	#main::DEBUG_MESSAGE("all coefficients", join('|', $self->{obj_row}->value ) );
	#main::DEBUG_MESSAGE("current coefficients", join('|', @current_coeff) );
    #main::DEBUG_MESSAGE("type of $self->{basis}", ref($self->{basis}) );
	#main::DEBUG_MESSAGE("current basis",join("|", @{$self->{basis}}));
	#main::DEBUG_MESSAGE("CURRENT STATE ", $current_tableau);
	return _Matrix( @{$current_tableau->extract_rows},$self->{current_coeff} );
	#return( $self->{current_coeff} );
}

sub basis {
	my $self = shift;  #update basis
	my @input = @_;
	return Value::List->new($self->{basis}) unless @input;  #return basis if no input
	my $new_basis;
	if (ref( $input[0]) =~/ARRAY/) {
		$new_basis=$input[0];
	} else {
		$new_basis = \@input;
	}
	$self->{basis}= $new_basis;
	$self->{B} = $self->{M}->submatrix(rows=>[1..($self->{m})],columns=>$self->{basis});
	return Value::List->new($self->{basis});	
} 




package Value::Matrix;

sub _Matrix {
	Value::Matrix->new(@_);
}

sub row_slice {
	$self = shift;
	@slice = @_;
	return _Matrix( $self->extract_rows(@slice) );
}
sub extract_rows {
	$self = shift;
	my @slice = @_;
	if (ref($slice[0]) =~ /ARRAY/) { # handle array reference
		@slice = @{$slice[0]};
	} elsif (@slice == 0) { # export all rows to List
		@slice = ( 1..(($self->dimensions)[0]) );	
	}
	return [map {$self->row($_)} @slice ]; #prefer to pass references when possible
}
sub column_slice {
	$self = shift;
	return _Matrix( $self->extract_columns(@_) )->transpose;  # matrix is built as rows then transposed.
}
sub extract_columns { 
	$self = shift;
	my @slice = @_;
	if (ref($slice[0]) =~ /ARRAY/) { # handle array reference
		@slice = @{$slice[0]};
	} elsif (@slice == 0) { # export all columns to an array
		@slice = ( 1..(($self->dimensions)[1] ) );	
	}
    return  [map { $self->transpose->row($_) } @slice] ; 
    # returns the columns as an array of 1 by n row matrices containing values
    # if you pull columns directly you get an array of 1 by n  column vectors.
    # prefer to pass references when possible
}
sub extract_rows_to_list {
	my $self = shift;
	Value::List->new($self->extract_rows(@_));
}
sub extract_columns_to_list {
	my $self = shift;
	Value::List->new($self->extract_columns(@_) );
}

sub submatrix {
	my $self = shift;
	my %options = @_;
	my($m,$n) = $self->dimensions;
	my $row_slice = ($options{rows})?$options{rows}:[1..$m];
	my $col_slice = ($options{columns})?$options{columns}:[1..$n];
	return $self->row_slice($row_slice)->column_slice($col_slice);
}



1;
