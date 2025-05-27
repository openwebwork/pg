# Note: perhaps deprecate or add to inequalities as a flag.

=head1 NAME

contextInequalitiesAllowStrings.pl -- allows use of R, the set of real numbers, in intervals.

=head1 DESCRIPTION

Allows string answers for the set of real numbers and the empty set

=cut

loadMacros("contextInequalities.pl");

sub _contextInequalitiesAllowStrings_init {
	my $context = $main::context{"Inequalities-AllowStrings"} = Parser::Context->getCopy("Inequalities");

	$context->constants->{namePattern} = qr/.*/;

	#----Add variations of "All real numbers"

	$context->constants->redefine("All real numbers", from => "Interval", using => "R");
	$context->constants->set("All real numbers" => { TeX => "\\mbox{All real numbers}" });

	$context->constants->redefine("all real numbers", from => "Interval", using => "R");
	$context->constants->set("all real numbers" => { TeX => "\\mbox{all real numbers}" });

	$context->constants->redefine("All Real numbers", from => "Interval", using => "R");
	$context->constants->set("All Real numbers" => { TeX => "\\mbox{All Real numbers}" });

	$context->constants->redefine("ALL REAL NUMBERS", from => "Interval", using => "R");
	$context->constants->set("ALL REAL NUMBERS" => { TeX => "\\mbox{ALL REAL NUMBERS}" });

	#-----Add variations of "No solution" = NONE
	#************This part does not work. Can't get it to "take" the empty set
	# Tried Set(), NONE and DNE

	#    $context->constants->redefine("No solution"",from=>"Interval",using=>"{}");
	#    $context->constants->set("No solution"=>{TeX=>"\\mbox{No solution}"});

	#    $context->constants->redefine("no solution"",from=>"Interval",using=>"{}");
	#    $context->constants->set("no solution"=>{TeX=>"\\mbox{no solution}"});

	#    $context->constants->redefine("NO SOLUTION"",from=>"Interval",using=>"{}");
	#    $context->constants->set("NO SOLUTION"=>{TeX=>"\\mbox{NO SOLUTION}"});

}
1;
