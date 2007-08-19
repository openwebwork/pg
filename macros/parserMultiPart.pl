sub _parserMultiPart_init {}

=head3 MultiPart

 ######################################################################
 #
 #  This object has been renamed MultiAnswer and is now available in
 #  parserMultiAnswer.pl.  Using a MultiPart object will produce a
 #  warning to that effect.
 #
 ######################################################################

=cut

loadMacros("parserMultiAnswer.pl");
sub MultiPart {
  warn "The MultiPart object has been depricated.${BR}You should use MultiAnswer object instead";
  MultiAnswer->new(@_);
}


1;
