
=head1 NAME

customizeLaTeX.pl - Defines default LaTeX constructs for certain mathematical
                    ideas.

=head1 DESCRIPTION

The functions are loaded by default.  Any/all can be overridden 
in your course's PGcourse.pl
=cut

sub _customizeLaTeX_init {

}    #prevents this file from being loaded twice.

##### Set theory macros
sub set_minus {
	#return "\\setminus";
	return '-';
}

#####  Logic macros
sub negate {
	return "\\mathbin{\\sim}";
	#return "\\lnot";
}

sub implies {
	return "\\implies";
	#return "\\Rightarrow";
}

##### Linear algebra macros

sub vectorstyle {
	my $v = shift;
	return "\\vec{$v}"
		#return "$v";
}

sub polynomials_of_degree_up_to_degree_over_ring_in_variable {
	my ($n, $R, $variable) = @_;
	return $R . "[" . $variable . "]_{\\mathrm{Grad} \\leq " . $n . "}";
}

sub matrix_of_homomorphism_with_respect_to_bases {
	my ($homomorphism, $basis_source, $basis_target) = @_;
	return "{}^{$basis_target}{" . $homomorphism . "}^{$basis_source}";
}

sub coordinates_of_vector_with_respect_to_basis {
	my ($vector, $basis) = @_;
	return "{}^{$basis}{(" . $vector . ")}";
}

sub span {
	my ($set) = @_;
	return "\\langle $set \\rangle";
}

sub matrices_over_ring {
	my ($rows, $columns, $ring) = @_;
	return "{$ring}^{$rows \\times $columns}";
	# return "M_{$rows \\times $columns}($ring)";
	# return "M_{$rows, $columns}($ring)";
}

##### Algebra macros

sub cyclic {

	my $n = shift;

# leave one of the following return commands uncommented, depending on what notation you want to use for finite cyclic groups (e.g., Z/nZ)

	# display order n cyclic group as Z_n
	return "\\mathbb{Z}_{$n}";

	# display order n cyclic group as C_n
	# return "C_{$n}";

	# display order n cyclic group as Z/nZ
	# return "\\mathbb{Z}/{$n}\\mathbb{Z}";

}

# Macro to display the ring Z/nZ
sub ZmodnZ {
	my $n = shift;
	return "\\mathbb{Z} / $n \\mathbb{Z}";
}

sub dihedral {

	my $n = shift;

# if you want to display dihedral groups as D_n (for instance, D_4 is the dihedral group of order 8), then leave this subroutine unmodified

# if you want to display dihedral groups as D_{2n} (for instance, D_8 is the dihedral group of order 8), then uncomment this set of if/else statements. The regular expression conditionals are to make sure it handles different types of arguments correctly.
# if( "$n" =~ m/^\s*(\d+)\s*$/ )
# {
# $n = 2 * $1;
# }
# elsif( "$n" =~ m/^\s*(\w+)\s*$/ )
# {
# $n = "2$1";
# }
# else
# {
# $n = "2($n)";
# }

	return "D_{$n}";

}

sub quaternions {

	# if you want to display the Quaternion group as Q_8, then leave this subroutine unmodified

	return "Q_8"

		# Alternatives

		# return "H_8"
		# return "Q"
}

1;
