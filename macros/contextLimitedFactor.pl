=head1 NAME

contextLimitedFactor.pl - Context file to check that the students answer agrees in form 
with a factored polynomial

=head1 DESCRIPTION

Answers are first compared as usual, and if they agree, then bizarroArithmetic.pl turns 
on bizarro addition, subtraction, and division. This, for example,  will cause (x+2)(x+1)
to evaluate differently than x^2+2x+1.

The flag factorableObject defaults to 'polynomial', but it could be set to say, 
'rational expression', etc. It is used in error messages.

=cut

loadMacros(
    "bizarroArithmetic.pl",

);

#
#  Set up the LimitedFactor context
#
sub _contextLimitedFactor_init {
  my $context = $main::context{LimitedFactor} = Parser::Context->getCopy("Numeric");
  $context->operators->set(
     '+'  => {class => 'bizarro::BOP::add', isCommand => 1},
     '-'  => {class => 'bizarro::BOP::subtract', isCommand => 1},
     '/'  => {class => 'bizarro::BOP::divide', isCommand => 1},
     ' /'  => {class => 'bizarro::BOP::divide', isCommand => 1},
     '/ '  => {class => 'bizarro::BOP::divide', isCommand => 1},
     '//'  => {class => 'bizarro::BOP::divide', isCommand => 1},
  );

  $context->flags->set(factorableObject => 'polynomial');
  $context->{cmpDefaults}{Formula}{checker} = sub {
    my ($correct,$student,$ans) = @_;
    return 0 if $ans->{isPreview} || $correct != $student;
    $student = $ans->{student_formula};
    $correct = $correct->{original_formula} if defined $correct->{original_formula};
    # check for equivalence when bizarro arithmetic is enforced
    Context()->flags->set(bizarroSub=> 1,bizarroAdd=> 1, bizarroDiv=> 1);
    delete $correct->{test_values}, $student->{test_values};
    my $OK = ($correct == $student);
    Context()->flags->set(bizarroSub=> 0,bizarroAdd=> 0, bizarroDiv=> 0);
    my $factorableObject = Context()->flag("factorableObject");
    Value::Error("Your answer is equivalent to the $factorableObject in the correct answer, but not completely factored or simplified") unless $OK;
    return $OK;
  };

}



1;


