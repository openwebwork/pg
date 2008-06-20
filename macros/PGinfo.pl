
####################################################################
# Copyright @ 1995-2007 University of Rochester
# All Rights Reserved
####################################################################

=head1 NAME

	PGinfo.pl


Provides macros for determining the values of the current context in which the problem
is being written.

=cut


loadMacros("MathObjects.pl");





=head3  listVariables

Usage: 	listVariables();

Prints all variables submitted in the problem form and all variables in the
the Problem environment and all of the flag variables in Context().
This is used for debugging and to determine the current
context for the problem.

=cut


sub listVariables {
	TEXT($HR,"Form variables",$BR );
	listFormVariables();
	TEXT($HR,"Environment variables",$BR );
	listEnvironmentVariables();
	TEXT($HR,"Context flags",$BR );
	listContextFlags();
}

=head4 listFormVariables()

	Called by listVariables to print out the input form variables.

=cut

sub listFormVariables {
    # Lists all of the variables filled out on the input form
	# Useful for debugging
    TEXT(pretty_print($inputs_ref));

}

=head4 listEnvironmentVariables()

	Called by listVariables to print out the environment variables (in %envir).

=cut


sub listEnvironmentVariables {
    # list the environment variables
    TEXT(pretty_print(\%envir));
}

=head4 listContextFlags()

	Called by listVariables to print out context flags for Math Objects.

=cut

sub listContextFlags {
	my $context = $$Value::context->{flags};
	TEXT(pretty_print($context));
}

=head3 listContext()

	Usage:  listContext(Context())

	Prints out the contents of the current context hash -- includes flags and much more

=cut

sub listContext {  # include
	my $context = shift;
	return TEXT("$PAR Error in listContext:  usage:  listContext(Context()); # must specify a context to list $BR") unless defined $context;
	foreach $key (keys %$context) {
		next if $key =~/^_/; # skip if it begins with
		TEXT($HR, $key, $BR);
		TEXT( pretty_print($context->{$key}) );
	}
}

=head3 pp()

	Usage:  pp(Hash );
	        pp(Object);
	        

	Prints out the contents of Hash or the instance variables of Object

=cut

sub pp {
    my $hash = shift;
    "printing |". ref($hash)."|$BR". pretty_print($hash);
}
1;