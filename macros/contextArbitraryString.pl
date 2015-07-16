####################################################################
#
#  Implements a context in which the student's answer is treated as a
#  literal string, and not parsed further.  The real answer checking
#  should be performed in a custom checker passed to the answer
#  string's cmp() method.  E.g.,
#
#        loadMacros("contextArbitraryString.pl");
#        Context("ArbitraryString");
#
#        ANS(Compute("The string I want")->cmp(checker => sub {
#          my ($correct,$student,$ans) = @_;
#          $correct = $correct->value; # get perl string from String object
#          $student = $student->value; # ditto
#          ##
#          ## do your checking here, and return true if correct
#          ## or false if incorrect.  For example
#          ##   return $correct eq $student;
#          ##
#          return $score;
#        }));
#
#  The default checker is essentially that given above, so if you want
#  the student answer to match the correct one exactly (spacing and
#  case are significant), then you don't have to use a custom checker.
#  But if you want, for example, to collapse multiple white-space, or
#  trim leading and trailing blanks, or treat upper- and lower-case
#  letters as quivalent, then you will need to provide your own
#  checker that does that.
#
#  This context handles multi-line answers properly.  If your answers
#  are particularly long, the results listed in the results table when
#  a student submits the answer may be too long, and you might want to
#  reduce the space taken up.  Since the Entered and Preview columns
#  will contain essentially the same data, you can turn off the Preview
#  column by using
#
#       ANS($ans->cmp(noLaTeXresults=>1));
#
#  or by setting the flag globally
#
#       Context()->flags->set(noLaTeXresults => 1);
#
#  This will put a message in the Preview column saying to look at
#  the Entered column, and will make the correct answer be shown
#  in HTML rather than TeX.
#

sub _contextArbitraryString_init {
  my $context = $main::context{ArbitraryString} = Parser::Context->getCopy("Numeric");
  $context->{name} = "ArbitraryString";
  $context->parens->clear();
  $context->variables->clear();
  $context->constants->clear();
  $context->operators->clear();
  $context->functions->clear();
  $context->strings->clear();
  $context->{pattern}{number} = "^\$";
  $context->variables->{patterns} = {};
  $context->strings->{patterns}{"(.|\n)*"} = [-20,'str'];
  $context->{value}{"String()"} = "context::ArbitraryString";
  $context->{value}{"String"} = "context::ArbitraryString::Value::String";
  $context->{parser}{String} = "context::ArbitraryString::Parser::String";
#  $context->flags->set(noLaTeXstring => "{{\\rm See\\ Entered}\\atop{\\rm Column}}");
  $context->flags->set(noLaTeXstring => "\\longleftarrow");
  $context->update;
}

#
#  Handle creating String() constants
#
package context::ArbitraryString;
sub new {shift; main::Compute(@_)}

#
#  Replacement for Parser::String that uses the original string verbatim
#  (but replaces \r and \r\n by \n to handle different browser multiline input)
#
package context::ArbitraryString::Parser::String;
our @ISA = ('Parser::String');

sub new {
  my $self = shift;
  my ($equation,$value,$ref) = @_;
  $value = $equation->{string};
  $value =~ s/\r\n?/\n/g;
  $self->SUPER::new($equation,$value,$ref);
}

#
#  Replacement for Value::String that creates preview strings
#  that work for multiline input
#
package context::ArbitraryString::Value::String;
our @ISA = ("Value::String");

#
#  Mark a multi-line string to be displayed verbatim in TeX
#
sub quoteTeX {
  my $self = shift; my $s = shift;
  return $self->verb($s) unless $s =~ m/\n/;
  my @tex = split(/\n/,$s);
  foreach (@tex) {$_ = $self->verb($_) if $_ =~ m/\S/}
  "\\begin{array}{l}".join("\\\\ ",@tex)."\\end{array}";
}

#
#  Quote HTML special characters
#
sub quoteHTML {
  my $self = shift;
  my $s = $self->SUPER::quoteHTML(shift);
  $s = "<pre style=\"text-align:left; padding-left:.2em\">$s</pre>"
    unless $main::displayMode eq "TeX";
  return $s;
}

#
#  Adjust preview and strings so they display
#  multiline answers properly.
#
sub cmp_preprocess {
  my $self = shift; my $ans = shift;
  if ($self->getFlag("noLaTeXresults")) {
    $ans->{preview_latex_string} = $self->getFlag("noLaTeXstring");
    $ans->{correct_ans_latex_string} = "";
  } else {
    $ans->{preview_latex_string} = $ans->{student_value}->TeX
      if defined $ans->{student_value};
  }
  $ans->{student_ans} = $self->quoteHTML($ans->{student_value}->string)
    if defined $ans->{student_value};
}

1;
