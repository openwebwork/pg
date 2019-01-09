#!/usr/bin/perl -w 

# this file needs documentation and unit testing.
# where is it used?

##### From gage_matrix_ops
# 2014_HKUST_demo/templates/setSequentialWordProblem/bill_and_steve.pg:"gage_matrix_ops.pl",

=head1 NAME

	macros/tableau.pl
	
=head2 TODO
	
	DONE: change find_next_basis_from_pivot  to next_basis_from_pivot
	DONE: add phase2  to some match phase1 for some of the pivots -- added as main:: subroutine
	DONE: add a generic _solve  that solves tableau once it has a filled basis  -- needs to be tested
	add something that will fill the basis.
	
	regularize the use of m and n -- should they be the number of 
	constraints and the number of decision(problem) variables or should
	they be the size of the complete tableau. 
	we probably need both -- need names for everything
	
	current tableau returns the complete tableau minus the objective function
	row. 
	(do we need a second objective function row? -- think we can skip this for now.)
	
=cut	

=head2 DESCRIPTION

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
 # state variables (assuming parameter variables are zero or when given parameter variables)
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
	Matrix A, the initial constraint matrix is n=num_problem_vars by m=num_slack_vars
	Matrix S, the initial slack variables is m by m
	Matrix b, the initial constraint constants is n by 1 (Matrix or ColumnVector)
	Matrix c, the objective function coefficients matrix is 1 by n
	
	Matrix which changes with state:
	Matrix upper_tableau: m by n+2 (A|S|0|b)
	Matrix tableau   m+1 by n+2  (A/(-c)) | S/0 | 0/1 |b/z 
	Matrix current_obj_coeff = 1 by n+m matrix (negative of current coeff for obj_function)
	Matrix current_last_row  = 1 by n+m+2 matrix  tableau is upper_tableau over current_last_row
	
	The next to the last column holds z or objective value
	z(...x^i...) = c_i* x^i  (Einstein summation convention)
	FIXME: ?? allow c to be a 2 by n matrix so that you can do phase1 calculations easily 


=cut


=head2 Package main


=item tableauEquivalence 

	ANS( $tableau->cmp(checker=>tableauEquivalence()) ); 
	
 # Note: it is important to include the () at the end of tableauEquivalence
 
 # tableauEquivalence compares two matrices up to
 # reshuffling the rows and multiplying each row by a constant.
 # It is equivalent up to multiplying on the left by a permuation matrix 
 # or a (non-uniformly constant) diagonal matrix.
 # It is appropriate for comparing augmented matrices representing a system of equations
 # since the order of the equations is unimportant.  This applies to tableaus for 
 # Linear Optimization Problems being solved using the simplex method.
 
=cut


=item  get_tableau_variable_values
 	(DEPRECATED -- use Tableau->statevars method )
	Parameters: ($MathObjectMatrix_tableau, $MathObjectSet_basis)
	Returns: ARRAY or ARRAY_ref 
	
Returns the solution variables to the tableau assuming 
that the parameter (non-basis) variables 
have been set to zero. It returns a list in 
array context and a reference to 
an array in scalar context. 

=item  lp_basis_pivot
	(DEPRECATED -- preserved for legacy problems. Use Tableau->basis method)
	Parameters: ($old_tableau,$old_basis,$pivot)
	Returns: ($new_tableau, Set($new_basis),\@statevars)


=item linebreak_at_commas

	Parameters: ()
	Return:
	
	Useage: 
	ANS($constraints->cmp()->withPostFilter(
		linebreak_at_commas()
    ));

Replaces commas with line breaks in the latex presentations of the answer checker.
Used most often when $constraints is a LinearInequality math object.


=cut 


=head3 References:

MathObject Matrix methods: L<http://webwork.maa.org/wiki/Matrix_(MathObject_Class)>
MathObject Contexts: L<http://webwork.maa.org/wiki/Common_Contexts>
CPAN RealMatrix docs: L<http://search.cpan.org/~leto/Math-MatrixReal-2.09/lib/Math/MatrixReal.pm>

More references: L<lib/Matrix.pm>

=cut

=head2 Package tableau

=cut

=item new

  Tableau->new(A=>Matrix, b=>Vector or Matrix, c=>Vector or Matrix)

	A => undef, # original constraint matrix  MathObjectMatrix
	b => undef, # constraint constants ColumnVector or MathObjectMatrix n by 1
	c => undef, # coefficients for objective function Vector or MathObjectMatrix 1 by n
	obj_row => undef, # contains the negative of the coefficients of the objective function.
	z => undef, # value for objective function Real
	n => undef, # dimension of problem variables (columns in A) 
	m => undef, # dimension of slack variables (rows in A)
	S => undef, # square m by m MathObjectMatrix for slack variables. default is the identity
	M => undef,  # matrix (m by m+n+1+1) consisting of all original columns and all 
		rows except for the objective function row. The m+n+1 column and 
		is the objective_value column. It is all zero with a pivot in the objective row. 
		The current version of this accessed by Tableau->upper_tableau (A | S |0 | b)
	#FIXME	
	obj_col_num => undef,  # have obj_col on the left or on the right? FIXME? obj_column_position
	                       # perhaps not store this column at all and add it when items are printed?
	
	basis => List | Set, # unordered list describing the current basis columns corresponding 
		to determined variables.  With a basis argument this sets a new state defined by that basis.  
	current_constraint_matrix=>(m by n matrix),  # the current version of [A | S]
	current_b=> (1 by m matrix or Column vector) # the current version of the constraint constants b
 	current_basis_matrix  => (m by m invertible matrix) a square invertible matrix 
 	     # corresponding to the current basis columns
 
 # flag indicating the column (1 or n+m+1) for the objective value
	constraint_labels => undef,   (not sure if this remains relevant after pivots)
	problem_var_labels => undef, 
	slack_var_labels => undef,
	
	Notes:  (1 by m MathObjectMatrix) <= Value::Matrix->new($self->b->transpose->value )
=cut





#	ANS( $tableau->cmp(checker=>tableauEquivalence()) ); 

package main;

sub _tableau_init {};   # don't reload this file

# loadMacros("tableau_main_subroutines.pl");
sub tableau_equivalence {  # I think this might be better -- matches linebrea_at_commas
                           # the two should be consistent.
	tableauEquivalence(@_);
}

sub tableauEquivalence {
	return sub {
		my ($correct, $student, $ansHash) = @_;
		 #DEBUG_MESSAGE("executing tableau equivalence");
		 #DEBUG_MESSAGE("$correct");
		 #DEBUG_MESSAGE("$student");
		Value::Error("correct answer is not a matrix") unless ref($correct)=~/Value::Matrix/;
		Value::Error("student answer is not a matrix") unless ref($student)=~/Value::Matrix/;

		# convert matrices to arrays of row references
		my @rows1 = $correct->extract_rows;
		my @rows2 = $student->extract_rows;
		# compare the rows as lists with each row being compared as 
		# a parallel Vector (i.e. up to multiples)
		my $score = List(@rows1)->cmp( checker =>
				sub {
					my ($listcorrect,$liststudent,$listansHash,$nth,$value)=@_;
					my $listscore = Vector($listcorrect)->cmp(parallel=>1)
						  ->evaluate(Vector($liststudent))->{score};
					return $listscore;
				}
		)->evaluate(List(@rows2))->{score};
		return $score;
	}
 }

	
#	$foochecker =  $constraints->cmp()->withPostFilter(
# 		linebreak_at_commas()
# 	);


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

	
# lop_display($tableau, align=>'cccc|cc|c|c', toplevel=>[qw(x1,x2,x3,x4,s1,s2,P,b)]) 	
# 	Pretty prints the output of a matrix as a LOP with separating labels and 
# 	variable labels.


=item lop_display
	
	Useage: 
	
	lop_display($tableau, align=>'cccc|cc|c|c', toplevel=>[qw(x1,x2,x3,x4,s1,s2,P,b)])
 	
Pretty prints the output of a matrix as a LOP with separating labels and 
variable labels.

=cut
our $max_number_of_steps = 20;

sub lop_display {
	my $tableau = shift;
	%options = @_;
	#TODO get alignment and toplevel from tableau
	#override it with explicit options.
	$alignment = ($options{align})? $options{align}:
	            ($tableau->align)? $tableau->align : "|ccccc|cc|c|c|";
	@toplevel = ();
	if (exists( ($options{toplevel})) ) {
		@toplevel = @{$options{toplevel}};
		$toplevel[0]=[$toplevel[0],headerrow=>1, midrule=>1];
	} elsif ($tableau->toplevel) {
		@toplevel =@{$tableau->toplevel};
		$toplevel[0]=[$toplevel[0],headerrow=>1, midrule=>1];
	}
	@matrix = $tableau->current_tableau->value;
	$last_row = $#matrix; # last row is objective coefficients 
	$matrix[$last_row-1]->[0]=[$matrix[$last_row-1]->[0],midrule=>1];
	$matrix[$last_row]->[0]=[$matrix[$last_row]->[0],midrule=>1];
	DataTable([[@toplevel],@matrix],align=>$alignment); 
}

# for main section of tableau.pl

# make one phase2 pivot on a tableau (works in place)
# returns flag with '', 'optimum' or 'unbounded'

sub next_tableau {
	my $self = shift;
	my $max_or_min = shift; 
	Value::Error("next_tableau requires a 'max' or 'min' argument") 
	   unless $max_or_min=~/max|min/;
	my @out = $self->find_next_basis($max_or_min);
	my $flag = pop(@out);
	if ($flag) {
	} else {  # update matrix
		$self->basis(Set(@out));
	}
	return $flag;
}


#iteratively phase2 pivots a feasible tableau until the
# flag returns 'optimum' or 'unbounded'
# tableau is returned in a "stopped" state.

sub phase2_solve {
	my $tableau = shift;
	my $max_or_min = shift; #FIXME -- this needs a sanity check
	Value::Error("phase2_solve requires a 'max' or 'min' argument")
		   unless $max_or_min=~/max|min/;
	# calculate the final state by phase2 pivoting through the tableaus. 
	my $state_flag = '';
	my $tableau_copy = $tableau->copy;
	my $i=0;
	while ((not $state_flag) and $i <=$max_number_of_steps ) {
		$state_flag = next_tableau($tableau_copy,$max_or_min);
		$i++;
	}
	return($tableau_copy,$state_flag, $i); 
	# TEXT("Number of iterations is $i $BR");
}

# make one phase 1 pivot on a tableau (works in place)
# returns flag with '', 'infeasible_lop' or 'feasible_point'
# perhaps 'feasible_point' should be 'feasible_lop'
sub next_short_cut_tableau {
	my $self = shift;
	my @out = $self->next_short_cut_basis();
	my $flag = pop(@out);
	# TEXT(" short cut tableau flag $flag $BR");
	if ($flag) {
	} else {  # update matrix
		$self->basis(Set(@out));
	}
	return $flag;
}
sub phase1_solve {
	my $tableau = shift;
	my $state_flag = '';
	my $tableau_copy = $tableau->copy;
	my $steps = 0;
	while (not $state_flag and $steps <= $max_number_of_steps) {
		$state_flag = next_short_cut_tableau($tableau_copy);
		$steps++;
	}
	return( $tableau_copy, $state_flag, $steps);
}

=item primal_basis_to_dual dual_basis_to_primal

	[complementary_basis_set] = $self->primal_basis_to_dual(primal_basis_set)
	[complementary_basis_set] = $self->dual_basis_to_primal(dual_basis_set)

<<<<<<< HEAD
########################
##############
# get_tableau_variable_values
#

# Calculates the values of the basis variables of the tableau, 
# assuming the parameter variables are 0.
#
# Usage:   get_tableau_variable_values($MathObjectMatrix_tableau, $MathObjectSet_basis)
# 
# feature request -- for tableau object -- allow specification of non-zero parameter variables
sub get_tableau_variable_values {
=======
=cut


		
# deprecated for tableaus - use $tableau->statevars instead
sub get_tableau_variable_values { 
>>>>>>> Pull updated tableau.pl from fall17mth208/templates/macro/tableau.pl
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
            #DEBUG_MESSAGE( "j= $j not in basis");
            $var[$j-1]=0; next; # non-basis variables (parameters) are set to 0. 
            
      } else {
            foreach my $i (1..$n-1) {  # the last row is the objective function
               # if this is a basis column there should be only one non-zero element(the pivot)
               if ( not $mat->element($i,$j) == 0 ) { # should this have ->value?????
                  $var[$j-1] = ($mat->element($i,$m)/$mat->element($i,$j))->value;                  
                  #DEBUG_MESSAGE("i=$i j=$j var = $var[$j-1] ");
                  next;
               }
             
            }
      }
  }                    # element($n, $m-1) is the coefficient of the objective value. 
                       # this last variable is the value of the objective function
  push @var , ($mat->element($n,$m)/$mat->element($n,$m-1))->value;

     @var;
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

##################################################
package Tableau;
our @ISA = qw(Class::Accessor Value::Matrix Value );
Tableau->mk_accessors(qw(
	A b c obj_row z n m S basis_columns B M current_constraint_matrix 
	current_objective_coeffs current_b current_basis_matrix current_basis_coeff
	obj_col_index toplevel align constraint_labels 
	problem_var_labels slack_var_labels obj_symbol var_symbol

));

<<<<<<< HEAD
 
 
sub linebreak_at_commas {
	return sub {
		my $ans=shift;
		my $foo = $ans->{correct_ans_latex_string};
<<<<<<< HEAD
		$foo =~ s/,/,\\\\/g;
		($ans->{correct_ans_latex_string})=~ s/,/,\\\\/g;
		($ans->{preview_latex_string})=~ s/,/,\\\\/g;
=======
		$foo =~ s/,/,\\\\\\\\/g;
		($ans->{correct_ans_latex_string})=~ s/,/,\\\\\\\\/g;
		($ans->{preview_latex_string})=~ s/,/,\\\\\\\\/g;
>>>>>>> Add tableau.pl
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


# We're going to have several types
# MathObject Matrices  Value::Matrix
# tableaus form John Jones macros
# MathObject tableaus
#   Containing   an  matrix $A  coefficients for constraint
#   A vertical vector $b for constants for constraints
#   A horizontal vector $c for coefficients for objective function
#   A vertical vector  $P for the value of the objective function
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
=======
our $tableauZeroLevel = Value::Real->new(1E-10); 
# consider entries zero if they are less than $tableauZeroLevel times the current_basis_coeff.
>>>>>>> Pull updated tableau.pl from fall17mth208/templates/macro/tableau.pl


sub close_enough_to_zero {
	my $self = shift;
	my $value = shift;
	#main::DEBUG_MESSAGE("value is $value");
	#main::DEBUG_MESSAGE("current_basis is ", $self->current_basis_coeff);
	#main::DEBUG_MESSAGE("cutoff is ", $tableauZeroLevel*($self->current_basis_coeff));
	return (abs($value)<= $tableauZeroLevel*($self->current_basis_coeff))? 1: 0;
}

sub class {"Matrix"};
 
 
sub _Matrix {    # can we just import this?
	Value::Matrix->new(@_);
}

# tableau constructor   Tableau->new(A=>Matrix, b=>Vector or Matrix, c=>Vector or Matrix)

sub new {
	my $self = shift; my $class = ref($self) || $self;
	my $context = (Value::isContext($_[0]) ? shift : $self->context);
	# these labels are passed only to  document what the mutators do
	my $tableau = Class::Accessor->new({
		A => undef, # constraint matrix  MathObjectMatrix
		b => undef, # constraint constants Vector or MathObjectMatrix 1 by n
		c => undef, # coefficients for objective function  MathObjectMatrix 1 by n or 2 by n matrix
		obj_row => undef, # contains the negative of the coefficients of the objective function.
		z => undef, # value for objective function
		n => undef, # dimension of problem variables (columns in A)
		m => undef, # dimension of slack variables (rows in A)
		S => undef, # square m by m matrix for slack variables
		basis_columns => undef, # list describing the current basis columns corresponding to determined variables.
		B => undef,  # square invertible matrix corresponding to the current basis columns
		M => undef,  # matrix of consisting of all columns and all rows except for the objective function row
		current_constraint_matrix=>undef,
		current_objective_coeffs=>undef,
		current_b => undef,
		obj_col_index => undef, # an array reference indicating the columns (e.g 1 or n+m+1) for the objective value or values
		toplevel => undef,
		align    => undef,
		constraint_labels => undef,
		problem_var_labels => undef, 
		slack_var_labels => undef,

		@_,
	});
	bless $tableau, $class;
	$tableau->initialize();
	return $tableau;
}


sub initialize {
	$self= shift;
	unless (ref($self->{A}) =~ /Value::Matrix/ &&
	        ref($self->{b}) =~ /Value::Vector|Value::Matrix/ && 
	        ref($self->{c}) =~ /Value::Vector|Value::Matrix/){
		Value::Error ("Error: Required inputs for creating tableau:\n". 
		"Tableau(A=> Matrix, b=>ColumnVector or Matrix, c=>Vector or Matrix)".
		"not the arguments of type ". ref($self->{A}). " |".ref($self->{b})."|  |".ref($self->{c}).
		"|");
	}
	my ($m, $n)=($self->{A}->dimensions);
<<<<<<< HEAD
	$self->{n}=$self->{n}//$n;
	$self->{m}=$self->{m}//$m;
	# main::DEBUG_MESSAGE("m $m, n $n");
	$self->{S} = Value::Matrix->I(4);
	$self->{basis} = [($n+1)...($n+$m)] unless ref($self->{basis})=~/ARRAY/;
<<<<<<< HEAD
	my @rows = $self->assemble_tableau;
=======
	my @rows = $self->assemble_matrix;
>>>>>>> Add tableau.pl
	#main::DEBUG_MESSAGE("rows", @rows);
	$self->{M} = _Matrix([@rows]);
	$self->{B} = $self->{M}->submatrix(rows=>[1..($self->{m})],columns=>$self->{basis});
	$self->{obj_row} = _Matrix($self->objective_row());
	return();	
=======
	$self->n(  ($self->n) //$n  );
	$self->m( ($self->m) //$m  );
	my $myAlignString = "c" x $n . "|" . "c" x $m ."|"."c|c"; # usual alignment for tableau.
	my $var_symbol = $self->{var_symbol}//'x';
	my $obj_symbol = $self->{obj_symbol}//'z';
	my @myTopLevel = map {$var_symbol.$_} 1..($m+$n);
	@myTopLevel = (@myTopLevel,$obj_symbol,'b' ); 
	$self->{toplevel} = ($self->{toplevel})//[@myTopLevel];
	$self->{align} = ($self->{align})//$myAlignString;
 	$self->{S} = Value::Matrix->I($m);
 	$self->{basis_columns} = [($n+1)...($n+$m)] unless ref($self->{basis_columns})=~/ARRAY/;	
 	my @rows = $self->assemble_matrix;
 	$self->M( _Matrix([@rows]) ); #original matrix
 	$self->{data}= $self->M->data;	
	my $new_obj_row = $self->objective_row;
 	$self->{obj_row} = _Matrix($self->objective_row);
 	# update everything else:
 	# current_basis_matrix, current_constraint_matrix,current_b
 	$self->basis($self->basis->value);
 	
 	return();	
>>>>>>> Pull updated tableau.pl from fall17mth208/templates/macro/tableau.pl
}
		
<<<<<<< HEAD
sub assemble_tableau {
=======
sub assemble_matrix {
>>>>>>> Add tableau.pl
	my $self = shift;
	my @rows =();
	my $m = $self->m;
	my $n = $self->n;
	# sanity check for b;
	if (ref($self->{b}) =~/Vector/) {
		# replace by n by 1 matrix
		$self->{b}=Value::Matrix->new([[$self->{b}->value]])->transpose;
	}
	my ($constraint_rows, $constraint_cols) = $self->{b}->dimensions;
	unless ($constraint_rows== $m and $constraint_cols == 1 ) {
		Value::Error("constraint matrix b is $constraint_rows by $constraint_cols but should
		be $m by 1 to match the constraint matrix A ");
	}

	foreach my $i (1..$m) {
		my @current_row=();
		foreach my $j (1..$n) {
			push @current_row, $self->{A}->element($i, $j)->value;
		}
# 		foreach my $j (1..$m) {
# 			push @current_row, $self->{S}->element($i,$j)->value; # slack variables
# 		}
		foreach my $j (1..$m) {  #FIXME
		    # 	push @current_row, $self->{S}->element($i,$j)->value; # slack variables
            # FIXME
		    # temporary fix because $matrix->I is not defined in master branch
			push @current_row, ($i==$j)?1:0;    #$self->{S}->element($i,$j)->value; # slack variables
		}

		push @current_row, 0, $self->{b}->row($i)->value;    # obj column and constant column
		push @rows, [@current_row]; 
	}

	return @rows;   # these are the matrices A | S | obj | b   
	                # the final row describing the objective function 
	                # is not in this part of the matrix
}

=head2 Accessors and mutators

=item  basis_columns

	ARRAY reference = $self->basis_columns()
	[3,4]           = $self->basis_columns([3,4])
	
	Sets or returns the basis_columns as an ARRAY reference
	
=cut 


=item  objective_row

		$self->objective_row
		Parameters: ()
		Returns: 

=cut



sub objective_row {
	my $self = shift;
	# sanity check for objective row
	Value::Error("The objective row coefficients (c) should be a 1 by n Matrix or a Vector of length n")
	     unless $self->n == $self->c->length;
	my @last_row=();
	push @last_row, ( -($self->c) )->value;  # add the negative coefficients of the obj function
	foreach my $i (1..($self->m)) { push @last_row, 0 }; # add 0s for the slack variables
	push @last_row, 1, 0; # add the 1 for the objective value and 0 for the initial value
	return \@last_row;
}

=item current_tableau

		$self->current_tableau
		Parameters: () or (list)
		Returns:  A MathObjectMatrix

	Useage:
		$MathObjectmatrix = $self->current_tableau
		$MathObjectmatrix = $self->current_tableau(3,4) #updates basis to (3,4)
		
Returns the current constraint matrix as a MathObjectMatrix, 
including the constraint constants,
problem variable coefficients, slack variable coefficients  AND the 
row containing the objective function coefficients. 
    -------------
	|A | S |0| b| 
	-------------
	| -c   |z|z*|
	-------------

If a list of basis columns is passed as an argument then $self->basis()
is called to switch the tableau to the new basis before returning
the tableau.
		
=cut

sub current_tableau {
	my $self = shift;
	Value::Error( "call current_tableau as a Tableau method") unless ref($self)=~/Tableau/;
	my @basis = @_;
	if (@basis) {
		$self->basis(@basis);
	}
	return _Matrix( @{$self->current_constraint_matrix->extract_rows},
	               $self->current_objective_coeffs );
}


=item  statevars

	[x1,.....xn,]= $self->statevars()



=cut

sub statevars {
   my $self = shift;
   my $matrix = $self->current_tableau;
   my $basis =Value::Set->new($self->basis); # a MathObject set
   # FIXME
   # type check ref($mat)='Matrix'; ref($basis)='Set';
   # or check that $mat has dimensions, element methods; and $basis has a contains method
   my ($m,$n) = $matrix->dimensions;
   # m= number of constraints + 1.  
   # n = number of constraints + number of variables +2
   @var = ();
   #print( "start new matrix $m $n \n");
   #print "tableau is ", $matrix, "\n";
   foreach my $j (1..$n-2) {    # the last two columns of the tableau are object variable and constants
      if (not $basis->contains($j)) {
            #DEBUG_MESSAGE( "j= $j not in basis");
            $var[$j-1]=0; next; # non-basis variables (parameters) are set to 0. 
            
      } else {
            foreach my $i (1..$m-1) {  # the last row is the objective function
               # if this is a basis column there should be only one non-zero element(the pivot)
               if ( not $matrix->element($i,$j) == 0 ) { # should this have ->value?????
                  $var[$j-1] = ($matrix->element($i,$n)/$matrix->element($i,$j))->value;                  
                  #DEBUG_MESSAGE("i=$i j=$j var = $var[$j-1] ");
                  next;
               }
             
            }
      }
  }                    # element($n, $m-1) is the coefficient of the objective value. 
                       # this last variable is the value of the objective function
  push @var , ($matrix->element($m,$n)/$matrix->element($m,$n-1))->value;

  [@var];
}

=item basis

	MathObjectList = $self->basis
	MathObjectList = $self->basis(3,4)
	MathObjectList = $self->basis([3,4])
	MathObjectList = $self->basis(Set(3,4))
	MathObjectList = $self->basis(List(3,4))
	
	to obtain ARRAY reference use
	[3,4]== $self->basis(Set3,4)->value

Returns a MathObjectList containing the current basis columns.  If basis columns
are provided as arguments it updates all elements of the tableau to present
the view corresponding to the new choice of basis columns. 

=cut

sub basis {
	my $self = shift;  #update basis
	                   # basis is stored as an ARRAY reference. 
	                   # basis is exported as a list
	                   # FIXME should basis be sorted?
	Value::Error( "call basis as a Tableau method") unless ref($self)=~/Tableau/;
	my @input = @_;
	return Value::List->new($self->{basis_columns}) unless @input;  #return basis if no input
	my $new_basis;
	if (ref( $input[0]) =~/ARRAY/) {
		$new_basis=$input[0];
	} elsif (ref( $input[0]) =~/List|Set/){
		$new_basis = [$input[0]->value];
	} else { # input is assumed to be an array
		$new_basis = \@input;
	}
	$self->{basis_columns}= $new_basis;  # this should always be an ARRAY
	main::WARN_MESSAGE("basis $new_basis was not stored as an array reference") 
	     unless ref($new_basis)=~/ARRAY/;
	
	# form new basis
	my $matrix = $self->M->submatrix(rows=>[1..($self->m)],columns=>$self->basis_columns);
	my $basis_det = $matrix->det;
	if ($basis_det == 0 ){
		Value::Error("The columns ".main::Set($self->basis_columns)." cannot form a basis");
	}
	$self->current_basis_matrix( $matrix  );
	$self->current_basis_coeff(abs($basis_det));
	
	#my $B = $self->current_basis_matrix;  #deprecate B
	#$self->{current_basis_matrix}= $B;
	#main::DEBUG_MESSAGE("basis: B is $B" );

	my $Badj = ($self->current_basis_coeff) * ($self->current_basis_matrix->inverse);
	my $M = $self->{M};
	my ($row_dim, $col_dim) = $M->dimensions;
	my $current_constraint_matrix = $Badj*$M;
	my $c_B  = $self->{obj_row}->extract_columns($self->basis_columns );
	my $c_B2 = Value::Vector->new([ map {$_->value} @$c_B]);
	my $correction_coeff = ($c_B2*($current_constraint_matrix) )->row(1); 
	my $obj_row_normalized =  abs($self->{current_basis_matrix}->det->value)*$self->{obj_row};
	my $current_objective_coeffs = $obj_row_normalized-$correction_coeff ;
	# updates
	$self->{data} = $current_constraint_matrix->data;
	$self->{current_constraint_matrix} = $current_constraint_matrix; 
	$self->{current_objective_coeffs}= $current_objective_coeffs; 
	$self->current_b( $current_constraint_matrix->column($col_dim)  );
	
	# the A | S | obj | b
	# main::DEBUG_MESSAGE( "basis: current_constraint_matrix $current_constraint_matrix ".
	# ref($self->{current_constraint_matrix}) );
	# main::DEBUG_MESSAGE("basis self ",ref($self), "---", ref($self->{basis_columns}));
	
	return Value::List->new($self->{basis_columns});	
} 


=item find_next_basis 

	($col1,$col2,..,$flag) = $self->find_next_basis (max/min, obj_row_number)
	
In phase 2 of the simplex method calculates the next basis.  
$optimum or $unbounded is set
if the process has found on the optimum value, or the column 
$col gives a certificate of unboundedness.

$flag can be either 'optimum' or 'unbounded' in which case the basis returned is the current basis. 
is a list of column numbers. 

FIXME  Should we change this so that ($basis,$flag) is returned instead? $basis and $flag
are very different things. $basis could be a set or list type but in that case it can't have undef
as an entry. It probably can have '' (an empty string)

=cut 


sub find_next_basis {
	my $self = shift;Value::Error( "call find_next_basis as a Tableau method") unless ref($self)=~/Tableau/;	
	my $max_or_min = shift;
	my $obj_row_number = shift//1;
	my ( $row_index, $col_index, $optimum, $unbounded)= 
	     $self->find_next_pivot($max_or_min, $obj_row_number);
	my $flag = undef;
	my $basis;
	if ($optimum or $unbounded) {
		$basis=$self->basis();
		if ($optimum) {
			$flag = 'optimum'
		} elsif ($unbounded) {
			$flag = 'unbounded'}
	} else {
		Value::Error("At least part of the pivot index (row,col) is not defined") unless
		   defined($row_index) and defined($col_index); 
		$basis =$self->find_next_basis_from_pivot($row_index,$col_index);		
	}
	return( $basis->value, $flag );	
}

=item find_next_pivot

	($row, $col,$optimum,$unbounded) = $self->find_next_pivot (max/minm obj_row_number)
	
This is used in phase2 so the possible outcomes are only $optimum and $unbounded.
$infeasible is not possible.  Use the lowest index strategy to find the next pivot
point. This calls find_pivot_row and find_pivot_column.  $row and $col are undefined if 
either $optimum or $unbounded is set.

=cut

sub find_next_pivot {
	my $self = shift;
	Value::Error( "call find_next_pivot as a Tableau method") unless ref($self)=~/Tableau/;
	my $max_or_min = shift;
	my $obj_row_number =shift;

	# sanity check max or min in find pivot column
	my ($row_index, $col_index, $value, $optimum, $unbounded) = (undef,undef,undef, 0, 0);
	($col_index, $value, $optimum) = $self->find_pivot_column($max_or_min, $obj_row_number);
#	main::DEBUG_MESSAGE("find_next_pivot: col: $col_index, value: $value opt: $optimum ");
	return ( $row_index, $col_index, $optimum, $unbounded) if $optimum;
	($row_index, $value, $unbounded) = $self->find_pivot_row($col_index);
#	main::DEBUG_MESSAGE("find_next pivot row: $row_index, value: $value unbound: $unbounded");
	return($row_index, $col_index, $optimum, $unbounded);
}
	


=item find_next_basis_from_pivot

	List(basis) = $self->find_next_basis_from_pivot (pivot_row, pivot_column) 

Calculate the next basis from the current basis 
given the pivot  position.

=cut  

sub find_next_basis_from_pivot {
	my $self = shift;
	Value::Error( "call find_next_basis_from_pivot as a Tableau method") unless ref($self)=~/Tableau/;
	my $row_index = shift;
	my $col_index =shift;
	if (Value::Set->new( $self->basis_columns)->contains(Value::Set->new($col_index))){
		Value::Error(" pivot point should not be in a basis column ($row_index, $col_index) ")
	}
	# sanity check max or min in find pivot column
 	my $basis = main::Set($self->{basis_columns});	
 	my ($leaving_col_index, $value) = $self->find_leaving_column($row_index);
 	$basis = main::Set( $basis - Value::Set->new($leaving_col_index) + main::Set($col_index));
 	# main::DEBUG_MESSAGE( "basis is $basis, leaving index $leaving_col_index
 	#    entering index is $col_index");
 	#$basis = [$basis->value, Value::Real->new($col_index)];
 	return ($basis);
} 



=item find_pivot_column

	($index, $value, $optimum) = $self->find_pivot_column (max/min, obj_row_number)
	
This finds the left most obj function coefficient that is negative (for maximizing)
or positive (for minimizing) and returns the value and the index.  Only the 
index is really needed for this method.  The row number is included because there might
be more than one objective function in the table (for example when using
the Auxiliary method in phase1 of the simplex method.)  If there is no coefficient
of the appropriate sign then the $optimum flag is set and $index and $value
are undefined.

=cut

sub find_pivot_column {
	my $self = shift;
	Value::Error( "call find_pivot_column as a Tableau method") unless ref($self)=~/Tableau/;
	my $max_or_min = shift;
	my $obj_row_index  = shift;
	# sanity check
	unless ($max_or_min =~ /max|min/) {
		Value::Error( "The optimization method must be 
		'max' or 'min'. |$max_or_min| is not defined.");
	}
	my $obj_row_matrix = $self->{current_objective_coeffs};
	#FIXME $obj_row_matrix is this a 1 by n or an n dimensional matrix??
	my ($obj_col_dim) = $obj_row_matrix->dimensions;
	my $obj_row_dim   = 1;
	$obj_col_dim=$obj_col_dim-2;
	#sanity check row	
	if (not defined($obj_row_index) ) {
		$obj_row_index = 1;
	} elsif ($obj_row_index<1 or $obj_row_index >$obj_row_dim){
		Value::Error( "The choice for the objective row $obj_row_index is out of range.");
	} 
	#FIXME -- make sure objective row is always a two dimensional matrix, often with one row.
	

	my @obj_row = @{$obj_row_matrix->extract_rows($obj_row_index)};
	my $index = undef;
	my $optimum = 1;
	my $value = undef;
	my $zeroLevelTol = $tableauZeroLevel * ($self->current_basis_coeff);
# 	main::DEBUG_MESSAGE(" coldim: $obj_col_dim , row: $obj_row_index obj_matrix: $obj_row_matrix ".ref($obj_row_matrix) );
# 	main::DEBUG_MESSAGE(" \@obj_row ",  join(' ', @obj_row ) );
	for (my $k=1; $k<=$obj_col_dim; $k++) {
#		main::DEBUG_MESSAGE("find pivot column: k $k, " .$obj_row_matrix->element($k)->value);
		
		if ( ($obj_row_matrix->element($k) < -$zeroLevelTol and $max_or_min eq 'max') or 
		     ($obj_row_matrix->element($k) > $zeroLevelTol and $max_or_min eq 'min') ) {
		    $index = $k; #memorize index
		    $value = $obj_row_matrix->element($k);
		    # main::diag("value is $value : is zero:=", (main::Real($value) == main::Real(0))?1:0);
		    $optimum = 0;
		    last;        # found first coefficient with correct sign
		 }
	}
	return ($index, $value, $optimum);
}

=item find_pivot_row

	($index, $value, $unbounded) = $self->find_pivot_row(col_number)

Compares the ratio $b[$j]/a[$j, $col_number] and chooses the smallest
non-negative entry.  It assumes that we are in phase2 of simplex methods
so that $b[j]>0; If all entries are negative (or infinity) then
the $unbounded flag is set and returned and the $index and $value
quantities are undefined.

=cut

sub find_pivot_row {
	my $self = shift;
	Value::Error( "call find_pivot_row as a Tableau method") unless ref($self)=~/Tableau/;
	my $column_index = shift;
	my ($row_dim, $col_dim) = $self->{M}->dimensions;
	$col_dim = $col_dim-2; # omit the obj_value and constraint columns
	# sanity check column_index
	unless (1<=$column_index and $column_index <= $col_dim) {
		Value::Error( "Column index must be between 1 and $col_dim" );
	}
	# main::DEBUG_MESSAGE("dim = ($row_dim, $col_dim)");
	my $value = undef;
	my $index = undef;
	my $unbounded = 1;
	my $zeroLevelTol = $tableauZeroLevel * ($self->current_basis_coeff);
	for (my $k=1; $k<=$row_dim; $k++) {
	    my $m = $self->{current_constraint_matrix}->element($k,$column_index);
	    # main::DEBUG_MESSAGE(" m[$k,$column_index] is ", $m->value);
		next if $m <=$zeroLevelTol;
		my $b = $self->{current_b}->element($k,1);
		# main::DEBUG_MESSAGE(" b[$k] is ", $b->value);
		# main::DEBUG_MESSAGE("finding pivot row in column $column_index, row: $k ", ($b/$m)->value);	
		if ( not defined($value) or $b/$m < $value-$zeroLevelTol) { # want first smallest value
			$value = $b/$m;
			$index = $k; # memorize index
			$unbounded = 0;
		}
	}
	return( $index, $value, $unbounded);	
}




=item find_leaving_column

	($index, $value) = $self->find_leaving_column(obj_row_number)

Finds the non-basis column with a non-zero entry in the given row. When
called with the pivot row number this index gives the column which will 
be removed from the basis while the pivot col number gives the basis 
column which will become a parameter column.

=cut

sub find_leaving_column {
	my $self = shift;
	Value::Error( "call find_leaving_column as a Tableau method") unless ref($self)=~/Tableau/;
	my $row_index = shift;
	my ($row_dim,$col_dim) = $self->{current_constraint_matrix}->dimensions;
	$col_dim= $col_dim - 1; # both problem and slack variables are included
	# but not the constraint column or the obj_value column(s) (the latter are zero)

	#sanity check row index;
	unless (1<=$row_index and $row_index <= $row_dim) {
		Value::Error("The row number must be between 1 and $row_dim" );
	}
	my $basis = main::Set($self->{basis_columns});
	my $index = 0;
	my $value = undef;
	foreach my $k  (1..$col_dim) {
		next unless $basis->contains(main::Set($k));
		$m_ik = $self->{current_constraint_matrix}->element($row_index, $k);
		# main::DEBUG_MESSAGE("$m_ik in col $k is close to zero ", $self->close_enough_to_zero($m_ik));
		next if $self->close_enough_to_zero($m_ik);
		# main::DEBUG_MESSAGE("leaving column is $k");
		$index = $k; # memorize index
		$value = $m_ik;
		last;
	}
	return( $index, $value);
}

=item next_short_cut_pivot 

	($row, $col, $feasible, $infeasible) = $self->next_short_cut_pivot
	
	
Following the short-cut algorithm this chooses the next pivot by choosing the row
with the most negative constraint constant entry (top most first in case of tie) and 
then the left most negative entry in that row. 

The process stops with either $feasible=1 (state variables give a feasible point for the 
constraints) or $infeasible=1 (a row in the tableau shows that the LOP has empty domain.)
	
=cut

sub next_short_cut_pivot {
	my $self = shift;
	Value::Error( "call next_short_cut_pivot as a Tableau method") unless ref($self)=~/Tableau/;

	my ($col_index, $value, $row_index, $feasible_point, $infeasible_lop) = ('','','','');
	($row_index, $value, $feasible_point) = $self->find_short_cut_row();
	if ($feasible_point) {
		$row_index=undef; $col_index=undef; $infeasible_lop=0;
	} else {
		($col_index, $value, $infeasible_lop) = $self->find_short_cut_column($row_index);
		if ($infeasible_lop){
			$row_index=undef; $col_index=undef; $feasible_point=0;
		}
	}
	return($row_index, $col_index, $feasible_point, $infeasible_lop);
}

=item next_short_cut_basis

	($basis->value, $flag) = $self->next_short_cut_basis()
	
In phase 1 of the simplex method calculates the next basis for the short cut method.  
$flag is set to 'feasible_point' if the basis and its corresponding tableau is associated with a basic feasible point
(a point on a corner of the domain of the LOP). The tableau is ready for phase 2 processing.
$flag is set to 'infeasible_lop' which means that the tableau has
a row which demonstrates that the LOP constraints are inconsistent and the domain is empty.  
In these cases the basis returned is the current basis of the tableau object.  

Otherwise the $basis->value returned is the next basis that should be used in the short_cut method
and $flag contains undef.


=cut 


sub next_short_cut_basis {
	my $self = shift;
	Value::Error( "call next_short_cut_basis as a Tableau method") unless ref($self)=~/Tableau/;	
	
	my ( $row_index, $col_index, $feasible_point, $infeasible_lop)= 
	     $self->next_short_cut_pivot();
	my $basis;
	$flag = undef;
	if ($feasible_point or $infeasible_lop) {
		$basis=$self->basis();
		if ($feasible_point) {
			$flag = 'feasible_point'; #should be feasible_lop ?
		} elsif ($infeasible_lop){
			$flag = 'infeasible_lop';
		}
	} else {
		Value::Error("At least part of the pivot index (row,col) is not defined") unless
		   defined($row_index) and defined($col_index); 
		$basis =$self->find_next_basis_from_pivot($row_index,$col_index);		
	}
	return( $basis->value, $flag );
	
}

=item find_short_cut_row

	($index, $value, $feasible)=$self->find_short_cut_row
	
Find the most negative entry in the constraint column vector $b. If all entries
are positive then the tableau represents a feasible point, $feasible is set to 1
and $index and $value are undefined.

=cut

sub find_short_cut_row {
	my $self = shift;
	Value::Error( "call find_short_cut_row as a Tableau method") unless ref($self)=~/Tableau/;
	my ($row_dim, $col_dim) = $self->{current_b}->dimensions;
	my $col_index = 1; # =$col_dim
	my $index = undef;
	my $value = undef;
	my $feasible = 1;
	my $zeroLevelTol = $tableauZeroLevel * ($self->current_basis_coeff);
	for (my $k=1; $k<=$row_dim; $k++) {
		my $b_k1 = $self->current_b->element($k,$col_index);
		#main::diag("b[$k] = $b_k1");
		next if $b_k1>=-$zeroLevelTol; #skip positive entries; 
		if ( not defined($value) or $b_k1 < $value) {
			$index =$k;
			$value = $b_k1;
			$feasible = 0;  #found at least one negative entry in the row
		}	
	}
	return ( $index, $value, $feasible);
}

=item find_short_cut_column

	($index, $value, $infeasible) = $self->find_short_cut_column(row_index)

Find the left most negative entry in the specified row.  If all coefficients are 
positive then the tableau represents an infeasible LOP, the $infeasible flag is set,
and the $index and $value are undefined.

=cut

sub find_short_cut_column {
	my $self = shift;
	Value::Error( "call find_short_cut_column as a Tableau method") unless ref($self)=~/Tableau/;
	my $row_index = shift;
	my ($row_dim,$col_dim) = $self->{M}->dimensions;
	$col_dim = $col_dim - 1; # omit constraint column
	       # FIXME to adjust for additional obj_value columns
	#sanity check row index
	unless (1<= $row_index and $row_index <= $row_dim) {
		Value::Error("The row must be between 1 and $row_dim");
	}
	my $index = undef;
	my $value = undef;
	my $infeasible = 1;
	for (my $k = 1; $k<=$col_dim; $k++ ) {
		my $m_ik = $self->{current_constraint_matrix}->element($row_index, $k);
		# main::DEBUG_MESSAGE( "in M: ($row_index, $k) contains $m_ik");
		next if $m_ik >=0;
		$index = $k;
		$value = $m_ik;
		$infeasible = 0;
		last;
	}
	return( $index, $value, $infeasible);	
}






=item row_reduce

(or tableau pivot???)

	Tableau = $self->row_reduce(3,4)
	MathObjectMatrix = $self->row_reduce(3,4)->current_tableau

	
Row reduce matrix so that column 4 is a basis column. Used in 
pivoting for simplex method. Returns tableau object.

=cut
sub row_reduce {
	my $self = shift;
	Value::Error( "call row_reduce as a Tableau method") unless ref($self)=~/Tableau/;
	my ($row_index, $col_index, $basisCoeff);
	# FIXME is $basisCoeff needed? isn't it always the same as $self->current_basis_coeff?
	my @input = @_;
	if (ref( $input[0]) =~/ARRAY/) {
		($row_index, $col_index) = @{$input[0]};
	} elsif (ref( $input[0]) =~/List|Set/){
		($row_index, $col_index) = @{$input[0]->value};
	} else { # input is assumed to be an array
		($row_index, $col_index)=@input;
	}
	# calculate new basis 	
	my $new_basis_columns = $self->find_next_basis_from_pivot($row_index,$col_index); 
		# form new basis
	my $basis_matrix = $self->M->submatrix(rows=>[1..($self->m)],columns=>$self->$new_basis_columns);
	my $basis_det = $basis_matrix->det;
	if ($basis_det == 0 ){
		Value::Error("The columns ", join(",", @$new_basis_columns)." cannot form a basis");
	}
    # updates
    $self->basis_columns($new_basis_columns);
    $self->current_basis_coeff($basis_det);
	# this should always be an ARRAY
	$basisCoeff=$basisCoeff || $self->{current_basis_coeff} || 1; 
	#basis_coeff should never be zero.
	Value::Error( "need to specify the pivot point for row_reduction") unless $row_index && $col_index;
	my $matrix = $self->current_constraint_matrix;
	my $pivot_value = $matrix->entry($row_index,$col_index);
	Value::Error( "pivot value cannot be zero") if $matrix->entry($row_index,$col_index)==0;
	# make pivot value positive
	if($pivot_value < 0) {
		foreach my $j (1..$self->m) {
			$matrix->entry($row_index, $j) *= -1;
		}
	}
	# perform row reduction to clear out column $col_index
	foreach my $i (1..$self->m){
		if ($i !=$row_index) { # skip pivot row
			my $row_value_in_pivot_col = $matrix->entry($i,$col_index);
			foreach my $j (1..$self->n){
				my $new_value = (
					($pivot_value)*($matrix->entry($i,$j))
					-$row_value_in_pivot_col*($matrix->entry($row_index,$j))
				)/$basisCoeff;
				$matrix->change_matrix_entry($i,$j, $new_value);		
			}		
		}
		
	}
	$self->{basis_coeff} = $pivot_value;
	return $self;
}
# eventually these routines should be included in the Value::Matrix 
# module?


=item dual_problem

	TableauObject = $self->dual_lop

Creates the tableau of the LOP which is dual to the linear optimization problem represented by the 
current tableau. 

=cut

sub dual_lop {
	my $self = shift;
	my $newA = $self->A->transpose; # converts m by n matrix to n by m matrix
	my $newb = $self->c; # gives a 1 by n matrix
	$newb = $newb->transpose; # converts to an n by 1 matrix
	my $newc = $self->b; # gives an m by 1 matrix
	$newc = _Matrix( $newc->transpose->value );  # convert to a 1 by m matrix
	my $newt = Tableau->new(A=>-$newA, b=>-$newb, c=>$newc);
	# rewrites the constraints as negative
	# the dual cost function is to be minimized.
	$newt;
}

=pod

These are specialized routines used in the simplex method

=cut


=item   primal2dual

		@array = $self->primal2dual(2,3,4)
		
Maps LOP column indices to dual LOP indicies (basis of complementary slack property)
		
		
=cut

=item   dual2primal

		@array = $self->dual2primal(2,3,4)
		
Maps dual LOP column indices to primal LOP indicies (basis of complementary slack property). 
Inverse of primal2dual method.
		 

=cut

sub primal2dual {
	my $self = shift;
    my $n = $self->n;
    my $m = $self->m; 
    $p2d_translate = sub {
    	my $i = shift;
		if ($i<=$n and $i>0) {
			return $m +$i;
		} elsif ($i > $n and $i<= $n+$m) {
			return $i-$n 
		} else {
			Value::Error("index $i is out of range");
		}
	};
	my @array = @_;	
	return (map {&$p2d_translate($_)} @array);   #accepts list of numbers
}


sub dual2primal {
	my $self = shift;
    my $n = $self->n;
    my $m = $self->m; 
	$d2p_translate = sub { 
		my $j = shift;
		if ($j<=$m and $j>0) {
			return $n+$j;
		} elsif ($j>$m and $j<= $n+$m) {
			return $j-$m
		}else {
			Value::Error("index $j  is out of range");
		}
	};
	my @array = @_;	
	return (map {&$d2p_translate($_)} @array);   #accepts list of numbers
}



=item isOptimal

		$self->isOptimal('min'| 'max')
		Returns  1 or 0

This checks to see if the state is a local minimum or maximum for the objective function
 -- it does not check whether the stateis feasible.


=cut

sub isOptimal {
	my $self = shift;
	Value::Error( "call isOptimalMin as a Tableau method") unless ref($self)=~/Tableau/;
	my $max_or_min = shift;
	my ($index, $value, $optimum) = $self->find_pivot_column($max_or_min);
	return $optimum;   # returns 1 or 0
}

=item isFeasible


Checks to see if the current state is feasible or whether it requires further phase 1 processing.

=cut



sub isFeasible {
	my $self = shift;
	Value::Error( "call isFeasible as a Tableau method") unless ref($self)=~/Tableau/;
    my ($index, $value, $feasible)= $self->find_short_cut_row;
    return $feasible;   # returns 1 or 0
}



=pod 

These are generic matrix routines.  Perhaps some or all of these should
be added to the file Value::Matrix?

=cut

package Value::Matrix;

sub _Matrix {
	Value::Matrix->new(@_);
}
<<<<<<< HEAD
<<<<<<< HEAD

#FIXME -- I think these need default values for slice

sub extract_rows { # preferable to use row slice
=======
sub extract_rows {
>>>>>>> Add tableau.pl
	$self = shift;
=======

=item row_slice

	$self->row_slice

	Parameter: @slice or \@slice 
	Return: MathObject matrix
		
	MathObjectMatrix = $self->row_slice(3,4)
	MathObjectMatrix = $self->row_slice([3,4])

Similar to $self->extract_rows   (or $self->rows) but returns a MathObjectmatrix

=cut

sub row_slice {
	my $self = shift;
	@slice = @_;
	return _Matrix( $self->extract_rows(@slice) );
}

=item extract_rows

	$self->extract_rows

	Parameter: @slice or \@slice 
	Return: two dimensional array ref 

	ARRAY reference = $self->extract_rows(@slice)
	ARRAY reference = $self->extract_rows([@slice])

=cut

sub extract_rows {
	my $self = shift;
>>>>>>> Pull updated tableau.pl from fall17mth208/templates/macro/tableau.pl
	my @slice = @_;
	if (ref($slice[0]) =~ /ARRAY/) { # handle array reference
		@slice = @{$slice[0]};
	} elsif (@slice == 0) { # export all rows to List
		@slice = ( 1..(($self->dimensions)[0]) );	
	}
	return [map {$self->row($_)} @slice ]; #prefer to pass references when possible
}

<<<<<<< HEAD
<<<<<<< HEAD
sub extract_columns { # preferable to use row slice 
=======
sub extract_columns {
>>>>>>> Add tableau.pl
	$self = shift;
=======
=item column_slice

	$self->column_slice()

	Parameter: @slice or \@slice 
	Return: two dimensional array ref 

	ARRAY reference = $self->extract_rows(@slice)
	ARRAY reference = $self->extract_rows([@slice])

=cut

sub column_slice {
	my $self = shift;
	return _Matrix( $self->extract_columns(@_) )->transpose;  # matrix is built as rows then transposed.
}

=item extract_columns

	$self->extract_columns

	Parameter: @slice or \@slice 
	Return: two dimensional array ref 

	ARRAY reference = $self->extract_columns(@slice)
	ARRAY reference = $self->extract_columns([@slice])

=cut

sub extract_columns { 
	my $self = shift;
>>>>>>> Pull updated tableau.pl from fall17mth208/templates/macro/tableau.pl
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

=item extract_rows_to_list

	Parameter: @slice or \@slice 
	Return: MathObject List of row references

	MathObjectList = $self->extract_rows_to_list(@slice)
	MathObjectList = $self->extract_rows_to_list([@slice])

=cut

sub extract_rows_to_list {
	my $self = shift;
	Value::List->new($self->extract_rows(@_));
}

=item extract_columns_to_list

	$self->extract_columns_to_list

	Parameter: @slice or \@slice 
	Return: MathObject List of Matrix references ?

	ARRAY reference = $self->extract_columns_to_list(@slice)
	ARRAY reference = $self->extract_columns_to_list([@slice])

=cut

sub extract_columns_to_list {
	my $self = shift;
	Value::List->new($self->extract_columns(@_) );
}

=item submatrix

	$self->submatrix

	Parameter:(rows=>\@row_slice,columns=>\@column_slice)
	Return: MathObject matrix

	MathObjectMatrix = $self->submatrix([[1,2,3],[2,4,5]])
	
Extracts a submatrix from a Matrix and returns it as MathObjectMatrix.

Indices for MathObjectMatrices start at 1. 

=cut

sub submatrix {
	my $self = shift;
	my %options = @_;
	my($m,$n) = $self->dimensions;
	my $row_slice = ($options{rows})?$options{rows}:[1..$m];
	my $col_slice = ($options{columns})?$options{columns}:[1..$n];
	return $self->row_slice($row_slice)->column_slice($col_slice);
}



=item change_matrix_entry

	$Matrix->change_matrix_entry([i,j,k],$value)

	Taken from MatrixReduce.pl.  Written by Davide Cervone.
	
	perhaps "assign" would be a better name for this?
	
=cut

#  This was written by Davide Cervone.
#  http://webwork.maa.org/moodle/mod/forum/discuss.php?d=2970
# taken from MatrixReduce.pl from Paul Pearson

sub change_matrix_entry {
    my $self = shift; my $index = shift; my $x = shift;
    my $i = shift(@$index) - 1;
    if (scalar(@$index)) {change_matrix_entry($self->{data}[$i],$index,$x);}
		else {$self->{data}[$i] = Value::makeValue($x);
	}
}


1;
