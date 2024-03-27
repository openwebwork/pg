
=head1 NAME

parserMultipleChoice.pl - Load all the multiple choice parsers: PopUp, CheckboxList, RadioButtons, RadioMultiAnswer.

=head1 SYNOPSIS

 loadMacros('parserMultipleChoice.pl');

=head1 DESCRIPTION

parserMultipleChoice.pl loads the following macro files:

=over

=item * parserPopUp.pl

=item * parserCheckboxList.pl

=item * parserRadioButtons.pl

=item * parserRadioMultiAnswer.pl

=back

=cut

sub _parserMultipleChoice_init { }

loadMacros("parserPopUp.pl", "parserCheckboxList.pl", "parserRadioButtons.pl", "parserRadioMultiAnswer.pl");

1;
