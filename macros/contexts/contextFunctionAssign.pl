
=head1 NAME

contextFunctionAssign.pl - allow an answer to have an function or variable assignment.

=head1 DESCRIPTION

This allows a answer to be a function or variable assignment change the error
message to be more specific for a function.

=cut

loadMacros("parserAssignment.pl");

sub parser::Assignment::Formula::cmp_equal {
	my $self = shift;
	my $ans  = shift;
	Value::cmp_equal($self, $ans);
	if ($ans->{ans_message} =~ m/Your answer isn't.*it looks like/s) {
		$ans->{ans_message} =
			"Warning: Your answer should be of the form: '" . $self->{tree}{lop}->string . "= formula'";
	}
}

1;
