
=head1 NAME

problemPreserveAnswers.pl - Allow sticky answers to preserve special characters.

=head1 DESCRIPTION

This file implements a fragile hack to overcome a problem with
PGbasicmacros.pl, which removes special characters from student
answers (in order to prevent EV3 from mishandling them).

NOTE: This file has been depreciated and doesn't do anything any more.
Encoding of special characters is now handled by PGbasicmacros.pl

=cut

sub _problemPreserveAnswers_init { PreserveAnswers::Init() }

package PreserveAnswers;

sub Init {

}

our $ENDDOCUMENT;    # holds pointer to original ENDDOCUMENT

######################################################################

1;
