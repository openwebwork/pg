
=head1 NAME

MathObjects.pl - Macro-based fronted to the MathObjects system.

=head1 DESCRIPTION

This file loads Parser.pl which in turn loads Value.pl The purpose of this file
is to encourage the use of the name MathObjects instead of Parser (which is not
as intuitive for those who don't know the history).

It may later be used for other purposes as well.

=head1 SEE ALSO

L<Parser.pl>.

=cut

# ^uses loadMacros
loadMacros("Parser.pl");

1;
