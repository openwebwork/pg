


=head1 NAME

	PGinfomacros.pl 
	
Provides information about the current problem environment.

ATTENTION.  This file will require some modifications if it is cached to insure
that the environmnet being printed is the current environment and not a cached 
environment.


=cut

=head3  listFormVariables

	listFormVariables();
	listVariables();

Prints all variables submitted in the problem form and all variables in the 
the Problem environment.  This is used for debugging.

=cut

sub listVariables {
	listFormVariables(@_);
}

sub listFormVariables {
    # Lists all of the variables filled out on the input form
	# Useful for debugging
    TEXT($HR,"Form variables", );
    TEXT(pretty_print($inputs_ref));
    # list the environment variables
    TEXT("Environment",$BR);
   TEXT(pretty_print(\%envir));
   TEXT($HR);
}

=head3 listHash

     listHash(~~%envir); ( in a .pg file)
     listHash(\%envir);  ( in a .pl file)
     
Lists all of the variables in the hash reference.  Notice that you must pass 
an object or a reference to a hash (or to an array ) not the hash itself and you 
must execute this macro inside a TEXT or BEGIN_TEXT/END_TEXT block in order
to print the output.

=cut

sub listHash {
	my $rh_hash = shift;
	unless (ref($rh_hash)=~/HASH/ or ref($rh_hash)=~/ARRAY/) {
		return "Error:  This function requires a reference to an array or to 
		a hash.  e.g.  listHash(~~%hash);";
	} else {
		return(pretty_print($rh_hash));
	}




}


=head2 listQueuedAnswers

	listQueuedAnswers();

Lists the labels of the answer blanks which have been printed so far.
The return value is a string which can be printed.  This is mainly
used for debugging.

=cut


sub listQueuedAnswers {
        # lists the names of the answer blanks so far;
        my %pg_answers_hash = get_PG_ANSWERS_HASH();
        join(" ", keys %pg_answers_hash);
}