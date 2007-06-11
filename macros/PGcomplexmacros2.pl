
# This file     is PGcomplexmacros2.pl
# This includes the subroutines for the ANS macros, that
# is, macros allowing a more flexible answer checking
####################################################################
# Copyright @ 2006-2007 The WeBWorK Team
# All Rights Reserved
####################################################################


=head1 NAME

	More macros for handling multivalued functions of a complex variable

=head1 SYNPOSIS



=head1 DESCRIPTION

=cut


BEGIN{
	be_strict();
	
}



sub _PGcomplexmacros2_init {
}

### for handling multivalued functions of a complex variable
###### subroutines ###########
sub pg_mod {      #calculate complex number mod $b i.e $a = k$b + ($a mod $b) for some integer k
		my $a =shift;
		my $b =shift;
		return $a if $b ==0;  # modulo 0 returns $a itself.
		$a-int(Complex($a/$b)->Re)*$b;  
                #int takes the integer real part of a complex number
}
	
sub compareMod {
	my $mod_factor = shift;
	sub {
		my ($correct, $response, $ans_checker) = @_;		
		my $New_Comp;
		# my $residue = pg_mod ($correct - $response, $mod_factor);
		#($residue == Complex(0,0)) ? 1:0;
		
		
		
		if($mod_factor->isComplex) 	{
			my $Abs_mod_factor = sqrt((($mod_factor)->Re)**2+(($mod_factor)->Im)**2);
	    $New_Comp = $Abs_mod_factor + ($Abs_mod_factor)*i;
	  } else		{		
	  	$New_Comp = $mod_factor;	  
	  }
		 
		 my $residue = pg_mod ($correct - $response + ($New_Comp / 2), $mod_factor);
		($residue == ($New_Comp)/2) ? 1:0;
	
	}
}

sub uniqueList {
	my $ra_list = shift;
	my $rf_equiv = shift;
	my $listSize = @$ra_list;
	my @equalPairs = ();
	my ($i,$j);
	for ($i=0;  $i<$listSize; $i++) {
		for($j=$i+1;  $j<$listSize; $j++) {
			push( @equalPairs, [$i,$j] ) if &$rf_equiv($ra_list->[$i],$ra_list->[$j]);
		}
	}
	@equalPairs;

}

# compares (z1 to z2 mod 4pi/3)




sub compareListsMod {
	my $alpha = shift;             # responses in list are compared mod $alpha to the correct answers
	my $equiv = shift || "2pi*i";  # responses in list are considered duplicates if they are equivalent mod $equiv
	$alpha = Complex($alpha); $equiv = Complex($equiv);
	my $cmp_mod_alpha = compareMod($alpha);  # this must be the smallest interval mod 2pi
    my $cmp_mod2pi = compareMod($equiv);
	sub {
		my ($correct, $student, $ans) = @_;
		my @equalPairs = uniqueList($student, $cmp_mod2pi);
		if (@equalPairs) {
			my $msg = "";
			for my $pair (@equalPairs) {
				my ($pos1, $pos2) = @$pair;
				$msg .= $student->[$pos1]." and ".$student->[$pos2]. " are equivalent.  ";
			}
			Value::Error("Some of your answers are equivalent. ".$msg);
			return 0
		} else {
			my $result=0; my $msg = '';
			my @correct = @$correct; my @student=@$student;
			return 0 unless scalar(@correct) == scalar(@student);
			foreach my $i (0..$#correct) {
				if ( &$cmp_mod_alpha($correct[$i],$student[$i]) ) {
					$result++ 
				} else {
					$msg .= "Your $i answer is incorrect. ";
				}
			}
			Value::Error($msg) unless $result == @correct;
			return $result;
		}
	}


}

sub compareFormulaMod {
	sub {
		my ($correct, $student, $ans) = @_;
		my $result = 1;
		#  evaluate the formulas at 0 and 1 to find coefficients of powers of k
		my $correct_a0 = $correct->eval(k=>0);
		my $student_a0 = $student->eval(k=>0);
		my $correct_a1 = $correct->eval(k=>1) - $correct_a0;
		my $student_a1 = $student->eval(k=>1) - $student_a0;
		
		
		my $cmp_mod = compareMod($correct_a1);
		&$cmp_mod($correct_a0, $student_a0) && (
		
		#&cmp($correct_a0,$student_a0) && (		
				  $correct_a1 == $student_a1 or $correct_a1 == - $student_a1
				  # - $student_a1 to make sure it is equal to correct_a1 rather than a multiple of it.
		);
	}

}
##### end subroutines ##################


