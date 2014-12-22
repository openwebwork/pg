################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader$
# 
# This program is free software; you can redistribute it and/or modify it under
# the terms of either: (a) the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version, or (b) the "Artistic License" which comes with this package.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
# Artistic License for more details.
################################################################################

=head1 NAME

LinearProgramming.pl - Macros for the simplex tableau for linear programming
problems.

=head1 SYNPOSIS

Macros related to the simplex method for Linear Programming.

	lp_pivot_element(...); # find the pivot element from a tableau
	lp_solve(...);         # pivot until done
	lp_current_value(...); # given a tableau, find the value of a requested variable
	lp_display(...);       # display a tableau
	lp_display_mm(...);    # display a tableau while in math mode
	lp_pivot(...);         # perform one pivot on a tableau

Matrix display makes use of macros from PGmatrixmacros.pl, so it must be
included too.

=head1 DESCRIPTION

These are macros for dealing with simplex tableau for linear programming
problems.  The tableau is a reference to an array of arrays, which looks like,
[[1,2,3], [4,5,6]].  The entries can be real numbers or Fractions.

Tableaus are expected to be legal for the simplex method, such as

	[[0,  3, -4,  5, 1, 0, 0, 28],
	 [0,  2,  0,  1, 0, 1, 0, 11],
	 [0,  1,  2,  3, 0, 0, 1,  3],
	 [1, -1,  2, -3, 0, 0, 0,  0]]

or something similar which arises after pivoting.

=head1 MACROS

=head2 lp_pivot

Take a tableau, the row and column number, and perform one pivot operation. The
tableau can be any matrix in the form reference to array of arrays, such as
[[1,2,3],[4,5,6]].  Row and column numbers start at 0.  An optional 4th argument
can be specified to indicate that the matrix has entries of type Fraction (and
then all entries should be of type Fraction).

	$m = [[1,2,3],[4,5,6]];
	lp_pivot($m, 0,2);

This function is destructive - it changes the values of its matrix rather than
making a copy, and also returns the matrix, so

	$m = lp_pivot([[1,2,3],[4,5,6]], 0, 2);

will have the same result as the example above.

=cut

# perform a pivot operation
# lp_pivot([[1,2,3],...,[4,5,6]], row, col, fractionmode)
# row and col indecies start at 0
# ^function lp_pivot
sub lp_pivot {
	my $a_ref = shift;
	$a_ref = convert_to_array_ref($a_ref);
	my $row = shift;
	my $col = shift;
	my $fracmode = shift;
	$fracmode = 0 unless defined($fracmode);
	my @matrows = @{$a_ref};

	if(($fracmode and $matrows[$row][$col]->scalar() == 0)
		 or $matrows[$row][$col] == 0) {
		warn "Pivoting a matrix on a zero element";
		return($a_ref);
	}
	my ($j, $k, $hld);
	$hld = $matrows[$row][$col];
	for $j (1..scalar(@{$matrows[0]})) {
		$matrows[$row][$j-1] = $fracmode ? $matrows[$row][$j-1]->divBy($hld) :
			$matrows[$row][$j-1]/$hld;
	}
	for $k (1..scalar(@matrows)) {
		if($k-1 != $row) {
			$hld = $matrows[$k-1][$col];
			for $j (1..scalar(@{$matrows[0]})) {
				$matrows[$k-1][$j-1] = $fracmode ?
					$matrows[$k-1][$j-1]->minus($matrows[$row][$j-1]->times($hld)) :
					$matrows[$k-1][$j-1] - $matrows[$row][$j-1]*$hld;
			}
		}
	}
	
	return($a_ref);
}


=head2 lp_pivot_element

Take a simplex tableau, and determine which element is the next pivot element
based on the algorithm in Mizrahi and Sullivan's Finite Mathematics, section
4.2.  The tableau must represent a point in the region of feasibility for a LP
problem.  Otherwise, it can be any matrix in the form reference to array of
arrays, such as [[1,2,3],[4,5,6]].  An optional 2nd argument can be specified to
indicate that the matrix has entries of type Fraction (and then all entries
should be of type Fraction).

It returns a pair [row, col], with the count starting at 0.  If there is no
legal pivot column (final tableau), it returns [-1,-1].  If there is a column,
but no pivot element (unbounded problem), it returns [-1, col].

=cut

# Find pivot column for standard part

# ^function lp_pivot_element
sub lp_pivot_element {
	my $a_ref = shift;
	$a_ref = convert_to_array_ref($a_ref);
	my $fracmode = shift;
	$fracmode = 0 unless defined($fracmode);
	my @m = @{$a_ref};
	my $nrows = scalar(@m)-1; # really 1 less
	my $ncols = scalar(@{$m[0]}) -1;  # really 1 less
	# looking for minimum value
	my $minv = $fracmode ? $m[$nrows][0]->scalar() : $m[$nrows][0];
	my $pcol=0;
	my $j;
	for $j (1..($ncols-1)) {
		if(($fracmode and $m[$nrows][$j]->scalar()<$minv) or $m[$nrows][$j]<$minv) {
			$minv = $fracmode ? $m[$nrows][$j]->scalar() :$m[$nrows][$j];
			$pcol = $j;
		}
	}
	return (-1, -1) if ($minv>=0); # This means we are done
	# Now find the pivot row
	my $prow=-1;
	for $j (0..($nrows-1)) {
		if($fracmode ? ($m[$j][$pcol]->scalar() >0) : ($m[$j][$pcol]>0)) { # found a candidate
			if($prow == -1) {
				$prow = $j;
			} else { # Test to see if this is an improvement
				if($fracmode ?
						($m[$prow][$ncols]->scalar())/($m[$prow][$pcol]->scalar()) >
						           ($m[$j][$ncols]->scalar()/$m[$j][$pcol]->scalar())
					 : ($m[$prow][$ncols]/$m[$prow][$pcol] >
					 $m[$j][$ncols]/$m[$j][$pcol])) {
					$prow = $j;
				}
			}
		}
	}
	return ($prow, $pcol);
}

=head2 lp_solve

Take a tableau, and perform simplex method pivoting until done. The tableau can
be any matrix in the form reference to array of arrays, such as
[[1,2,3],[4,5,6]], which represents a linear programming tableau at a feasible
point.  Options are specified in key/value pairs.

=over

=item C<S<< pivot_limit => 10 >>>

limit the number of pivots to at most 10 - default is 100

=item C<S<< fraction_mode => 1 >>>

entries are of type Fraction - defaults to 0, i.e., false

This function is destructive - it changes the values of its matrix rather than
making a copy.  It returns a triple of the final tableau, an endcode indicating
the type of result, and the number of pivots used.  The endcodes are 1 for
success, 0 for unbounded.

Example:

	$m = [[0,  3, -4,  5, 1, 0, 0, 28],
	      [0,  2,  0,  1, 0, 1, 0, 11],
	      [0,  1,  2,  3, 0, 0, 1,  3],
	      [1, -1,  2, -3, 0, 0, 0,  0]];

	($m, $endcode, $pivcount) = lp_solve($m, pivot_limit=>200);

=cut

# Solve a linear programming problem
# lp_solve([[1,2,3],[4,5,6]])
# It returns a triple of the final tableau, a code to say if we
#   succeeded, and the number of pivots
# ^function lp_solve
# ^uses set_default_options
# ^uses lp_pivot_element
# ^uses lp_pivot
sub lp_solve {
	my $a_ref_orig = shift;
	$a_ref_orig = convert_to_array_ref($a_ref_orig);
	my %opts = @_;

	set_default_options(\%opts,
											'_filter_name' => 'lp_solve',
											'pivot_limit' => 100,
											'fraction_mode' => 0,
											'allow_unknown_options'=> 0);

	my ($pcol, $prow);
	my $a_ref;
	# First we clone the matrix so that it isn't modified in place
	for $prow (1..scalar(@{$a_ref_orig})) {
		for $pcol (1..scalar(@{$a_ref_orig->[0]})) {
			$a_ref->[$prow-1][$pcol-1] = $a_ref_orig->[$prow-1][$pcol-1];
		}
	}
	
	my $piv_count = 0;
	my $piv_limit = $opts{'pivot_limit'}; # Just in case of cycling or bugs
	my $fracmode = $opts{'fraction_mode'};
	# First do alternate pivoting
	# Now do regular pivots
	do {
		($prow, $pcol) = lp_pivot_element($a_ref, $fracmode);
		if($prow>=0) {
			$a_ref = lp_pivot($a_ref, $prow, $pcol, $fracmode);
			$piv_count++;
		}
	} until($prow<0 or $piv_count>=$piv_limit);
	# code is 1 for success, 0 for unbounded
	my $endcode = 1;
	$endcode = 0 if ($pcol>=0);
	return($a_ref, $endcode, $piv_count);
}

=head2 lp_current_value

Takes a simplex tableau and returns the value of a particular variable.
Variables are associated to column numbers which are indexed starting with 0. 
So, usually this means that the objective function is 0, x_1 is 1, and so on. 
This can be used for slack variables too (assuming you know what columns they
are in).

=cut

# Get the current value of a variable from a tableau
# The variable is specified by column number, with 0 for P, 1 for x_1,
#  and so on

# ^function lp_current_value
# ^uses Fraction::new
sub lp_current_value {
  my $col = shift;
  my $aref = shift;
  $aref = convert_to_array_ref($aref);
  my $fractionmode = 0;
  $fractionmode =1 if(ref($aref->[0][0]) eq 'Fraction');

  # Count how many ones there are.  If we hit non-zero/non-one, force count
  # to fail
  my ($cnt,$row,$save) = (0,'',0);
  for $row (@{$aref}) {
    if($fractionmode) {
      if($row->[$col]->scalar() != 0) {
	$cnt += ($row->[$col]->scalar() == 1) ? 1 : 2;
	$save = $row;
      }
    } else {
      if($row->[$col] != 0) {
	$cnt += ($row->[$col] == 1) ? 1 : 2;
	$save = $row;
      }
    }
  }
  if($cnt != 1) {
  	if ($fractionmode ) {
  		if (defined &Fraction) {
  			return Fraction(0);   # MathObjects version
  		} else {
  			return new Fraction(0);	# old style Function module version
  		}
  	} else {
  		return 0;
  	}
 
  }
  $cnt = scalar(@{$save});
  return $save->[$cnt-1];
}

=head2 lp_display_mm

Display a simplex tableau while in math mode.

	$m = [[0,  3, -4,  5, 1, 0, 0, 28],
	      [0,  2,  0,  1, 0, 1, 0, 11],
	      [0,  1,  2,  3, 0, 0, 1,  3],
	      [1, -1,  2, -3, 0, 0, 0,  0]];
	
	BEGIN_TEXT
	\[ \{ lp_display_mm($m) \} \]
	END_TEXT

Accepts the same optional arguments as lp_display (see below), and produces
nicer looking results.  However, it cannot have answer rules in the tableau
(lp_display can have them for fill in the blank tableaus).

To use with a MathObject matrix use

    \[ \{lp_display_mm([$matrix->value]) \} \]
    
    FIXME?  I've added an adaptor that allows you to use $matrix directly -- MEG 
    
$matrix->value outputs an array (usually an array of array references) so placing it inside
square bracket produces and array reference (of array references) which is what lp_display_mm() is
seeking.

$matrix, by itself, produces a string representing a matrix. (This will be in TeX if the context has
enabled texStrings.

=cut

# Display a tableau in math mode
# ^function lp_display_mm
# ^uses lp_display
sub lp_display_mm {
  lp_display(@_, force_tex=>1);
}

# Make a copy of a tableau
# ^function lp_clone
sub lp_clone {
	my $a1_ref = shift;
	$a1_ref = convert_to_array_ref($a1_ref);
        my $a_ref = []; # make a copy to modify
        my $nrows = scalar(@{$a1_ref})-1; # really 1 less
	my ($j, $k);
	for $j (0..$nrows) {
	  if($a1_ref->[$j] eq 'hline') {
	    $a_ref->[$j] = 'hline';
	  } else {
	    for $k (0..(scalar(@{$a1_ref->[$j]}) -1)) {
	      $a_ref->[$j][$k] = $a1_ref->[$j][$k];
	    }
	  }
	}
  return($a_ref);
}

=head2 lp_display

Display a simplex tableau while not in math mode.

	$m = [[0,  3, -4,  5, 1, 0, 0, 28],
	      [0,  2,  0,  1, 0, 1, 0, 11],
	      [0,  1,  2,  3, 0, 0, 1,  3],
	      [1, -1,  2, -3, 0, 0, 0,  0]];
	
	BEGIN_TEXT
	\{ lp_display($m)\}
	END_TEXT

Takes the same optional arguments as display_matrix.  The default for column
alignment as "augmentation line" before the last column. It also adds a
horizontal line before the last row if it is not already specified.

=cut

# Display a tableau
# ^function lp_display
# ^uses lp_clone
# ^uses display_matrix
sub lp_display {
	my $a1_ref = shift;
	my %opts = @_;
	$a1_ref = convert_to_array_ref($a1_ref);
	my $nrows = scalar(@{$a1_ref})-1; # really 1 less
	my $ncols = scalar(@{$a1_ref->[0]}) -1;  # really 1 less
	
	if(not defined($opts{'align'})) {
	  my $align = "r" x $ncols;
	  $align .=  "|r";
	  $opts{'align'} = $align;
	}
	my $a_ref = lp_clone($a1_ref);
	
	if($a_ref->[$nrows-1] ne 'hline') {
	  $a_ref->[$nrows+1] = $a_ref->[$nrows];
	  $a_ref->[$nrows] = 'hline';
	}
	display_matrix($a_ref, %opts);
}




1;
