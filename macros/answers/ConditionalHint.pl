
=head1 NAME

ConditionalHint.pl - Allows a hint to be revealed after a student
has entered an answer correctly.

=head1 DESCRIPTION

The subroutine C<ConditionalHint()> allows a hint to be revealed
after a student has entered an answer correctly.  It is useful
for multi-part questions in which a hint for answering one part
should not be revealed until a previous part has been answered
correctly.

A subroutine C<IsAnswerCorrect()> that returns 0 or 1 is also
provided.

=head1 MACROS

=head2 ConditionalHint

    loadMacros("ConditionalHint.pl");

    $ans = Compute("x^2");

    BEGIN_TEXT
    Enter \( x^2 \) \{ ans_rule(20) \}
    \{
    ConditionalHint(
      ans_name=>$ans,
      ans_number=>1,
      html_hint=>"$BR ${BBOLD}Hint:${EBOLD}
      \( \displaystyle \int x^2 \, dx = \frac{x^3}{3} + C.\) $BR",
      tex_hint=>'',
    );
    \}
    END_TEXT

    ANS( $ans->cmp() );


=head3 Complete Working Example of ConditionalHint

    DOCUMENT();

    loadMacros(
    "PGstandard.pl",
    "MathObjects.pl",
    "ConditionalHint.pl",
    );

    TEXT( beginproblem() );

    ###################################
    #  Setup

    Context("Numeric");

    @answers = ();
    $answers[1] = Compute("x^2");
    $answers[2] = Compute("4^3 / 3");

    #$hint = IsAnswerCorrect(ans_name=>$answers[1],ans_number=>1);

    $myhint = ConditionalHint(
    ans_name=>$answers[1],
    ans_number=>1,
    html_hint=>"$BR ${BBOLD}Hint:${EBOLD} \( \displaystyle \int x^2 \, dx = \frac{x^3}{3} + C.\) $BR"
    );


    ##################################
    #  Main text

    Context()->texStrings;
    BEGIN_TEXT
    (a) Enter \( x^2 \).
    \{ ans_rule(30) \}
    $BR
    $BR
    (b) When you answer part (a) correctly, a hint will appear here with an integral formula.
    $BR
    $myhint
    $BR
    \( \displaystyle \int_0^4 \frac{x^3}{3} \, dx = \)
    \{ans_rule(20)\}
    END_TEXT
    Context()->normalStrings;


    ##################################
    #  Answer evaluation

    $showPartialCorrectAnswers = 1;

    ANS( $answers[1]->cmp() );
    ANS( $answers[2]->cmp() );

    COMMENT('When the first answer is correct, a hint appears with an integral formula (using ConditionalHint.pl).');

    ENDDOCUMENT();

=cut

sub _ConditionalHint_init { };    # don't reload this file

sub ConditionalHint {

	my %options = (
		ans_name   => '',
		ans_number => '',
		html_hint  => '',
		tex_hint   => '',
		@_
	);

	my $showhint = $options{ans_name}->cmp()->evaluate($inputs_ref->{ ANS_NUM_TO_NAME($options{ans_number}) })->{score};

	my $hint;

	if ($showhint == 1) {
		$hint = MODES(HTML => $options{html_hint}, TeX => $options{tex_hint});
	} else {
		$hint = '';
	}

	return $hint;

}

sub IsAnswerCorrect {

	my %options = (
		ans_name   => '',
		ans_number => '',
		@_
	);

	return $options{ans_name}->cmp()->evaluate($inputs_ref->{ ANS_NUM_TO_NAME($options{ans_number}) })->{score};

}

1;
