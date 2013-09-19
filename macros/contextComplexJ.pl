
=head1   contextComplexJ.pl

# use this technique to write problems that can switch 
from i to using j for the square root of minus one

  # DOCUMENT();      
  # 
  # # stanza that allows you to write a problem
  # # that can be used for either Math or EE 
  # # switches between the use of i  and j for the square root of minus one.
  # #
  # $complexJ =0;
  # $I = ($complexJ)? 'j': 'i';
  # 
  # loadMacros(
  #    "PGstandard.pl",     # Standard macros for PG language
  #    "MathObjects.pl",
  #      ($complexJ) ? "contextComplexJ.pl"  : "",
  #    #"source.pl",        # allows code to be displayed on certain sites.
  #    #"PGcourse.pl",      # Customization file for the course
  # );
  # 
  # 
  # # Print problem number and point value (weight) for the problem
  # TEXT(beginproblem());
  # 
  # # Show which answers are correct and which ones are incorrect
  # $showPartialCorrectAnswers = 1;
  # 
  # ##############################################################
  # #
  # #  Setup
  # #
  # #
  # Context("Complex");
  # 
  # $pi = Complex("pi +4$I");
  # 
  # ##############################################################
  # #
  # #  Text
  # #
  # #
  # 
  # Context()->texStrings;
  # BEGIN_TEXT
  # 
  # $pi
  # Enter a value for \(\pi\)
  # 
  # \{$pi->ans_rule\}
  # END_TEXT
  # Context()->normalStrings;
  # 
  # ##############################################################
  # #
  # #  Answers
  # #
  # #
  # 
  # ANS($pi->with(tolerance=>.0001)->cmp);
  # # relative tolerance --3.1412 is incorrect but 3.1413 is correct
  # # default tolerance is .01 or one percent.
  # 
  # 
  # ENDDOCUMENT();        
  # 

=cut






sub _contextComplexJ_init {
  my $context = $main::context{Complex} = Parser::Context->getCopy("Complex");
  $context->{value}{Complex} = "context::Complex";
  $context->constants->remove("i");
  $context->constants->add(j => context::Complex->new(0,1));
  $context->constants->set(j => {isConstant => 1, perl=>"j"});
}

package context::Complex;
our @ISA = ('Value::Complex');

sub string {
  my $self = shift;
  my $z = Value::Complex::format($self->{format},$self->value,'string',@_);
  $z =~ s/i/j/;
  return $z;
}
sub TeX {
  my $self = shift;
  my $z = Value::Complex::format($self->{format},$self->value,'TeX',@_);
  $z =~ s/i/j/;
  return $z;
}
