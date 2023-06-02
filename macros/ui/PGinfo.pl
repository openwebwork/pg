
################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2022 The WeBWorK Project, https://github.com/openwebwork
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

PGinfo.pl

Provides macros for determining the values of the current context in which the problem
is being written.

=cut

loadMacros("MathObjects.pl");

=head2  listVariables

Usage: 	listVariables();

Prints all variables submitted in the problem form and all variables in the
the Problem environment and all of the flag variables in Context().
This is used for debugging and to determine the current
context for the problem.

=cut

sub listVariables {
	TEXT($HR, "Form variables", $BR);
	listFormVariables();
	TEXT($HR, "Environment variables", $BR);
	listEnvironmentVariables();
	TEXT($HR, "Context flags", $BR);
	listContextFlags();
}

=head3 listFormVariables()

Called by C<listVariables> to print out the input form variables.

=cut

sub listFormVariables {
	# Lists all of the variables filled out on the input form
	# Useful for debugging
	TEXT(pretty_print($inputs_ref));

}

=head3 listEnvironmentVariables()

	Called by C<listVariables> to print out the environment variables (in %envir).

=cut

sub listEnvironmentVariables {
	# list the environment variables
	TEXT(pretty_print(\%envir));
}

=head3 listContextFlags()

	Called by listVariables to print out context flags for Math Objects.

=cut

sub listContextFlags {
	my $context = $$Value::context->{flags};
	TEXT(pretty_print($context));
}

=head2 listContext()

	Usage:  listContext(Context())

	Prints out the contents of the current context hash -- includes flags and much more

=cut

sub listContext {    # include
	my $context = shift;
	return TEXT("$PAR Error in listContext:  usage:  listContext(Context()); # must specify a context to list $BR")
		unless defined $context;
	foreach $key (keys %$context) {
		next if $key =~ /^_/;    # skip if it begins with
		TEXT($HR, $key, $BR);
		TEXT(pretty_print($context->{$key}));
	}
}

=head2 pp()

	Usage:  pp(Hash );
	        pp(Object);


	Prints out the contents of Hash or the instance variables of Object

=cut

sub pp {
	my $hash = shift;
	"printing |" . ref($hash) . "|$BR" . pretty_print($hash);
}
1;
