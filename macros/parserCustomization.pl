sub _parserCustomization_init {}

=head1 parserCustomization

 #
 #  Copy this file to your course templates directory and put any
 #  customization for the Parser that you want for your course
 #  here.  For example, you can make vectors display using
 #  ijk notation (and force students to use it for entering
 #  vectors) by uncommenting:
 #
 #    $context{Vector} = Parser::Context->getCopy(undef,"Vector");
 #    $context{Vector}->flags->set(ijk=>1);
 #    $context{Vector}->parens->remove('<');
 #
 #  To allow vectors to be entered with parens (and displayed with
 #  parens) rather than angle-brakets, uncomment
 #
 #    $context{Vector} = Parser::Context->getCopy(undef,"Vector");
 #    $context{Vector}->{cmpDefaults}{Vector} = {promotePoints => 1};
 #    $context{Vector}->lists->set(Vector=>{open=>'(', close=>')'});
 #
 #  (This actually just turns points into vectors in the answer checker
 #  for vectors, and displays vectors using parens rather than angle
 #  brakets.  The student is really still entering what the Parser
 #  thinks is a point, but since points get promoted automatically
 #  in the Value package, that should work.  But if a problem checks
 #  if a student's value is actually a Vector, that will not be true.)
 #

=cut


1;
