################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/macros/answerComposition.pl,v 1.8 2009/06/25 23:28:44 gage Exp $
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

answerComposition.pl - An answer checker that determines if two functions
compose to form a given function.

=head1 DESCRIPTION

answerComposition.pl provides an answer checker that determines if two functions
compose to form a given function. This can be used in problems where you ask a
student to break a given function into a composition of two simpler functions,
neither of which is allowed to be the identity function.

=cut

sub _answerComposition_init {}; # don't reload this file

=head1 MACROS

=head2 COMPOSITION_ANS

	COMPOSITION_ANS($f, $g, %options)

An answer checked to see if $f composed with $g matches a given function,where
$f and $g are one possible decomposition of the target function, and options are
any of the options allowed by composition_ans_list() below.

$f and $g are used to display the "correct" answer, and the composition is
computed from them.

This function actually supplies TWO answer checkers, for the two previous answer
blanks.  So be sure to call it immediately after the answer blanks have been
supplied. (It may be best to use the NAMED_COMPOSITION_ANS checker below, which
specifies the answer blanks explicitly.)

Example:

	BEGIN_TEXT
	\(f\circ g = (1+x)^2\) when
	\(f(x)\) = \{ans_rule(20)\} and \(g(x)\) = \{ans_rule(20)\}
	END_TEXT
	COMPOSITION_ANS("x^2","1+x");

=cut

sub COMPOSITION_ANS {
  my $f = shift; my $g = shift;
  my $num_of_answers = main::ans_rule_count();
  my $fID = ANS_NUM_TO_NAME($num_of_answers-1);
  my $gID = ANS_NUM_TO_NAME($num_of_answers);
  my %ans = composition_ans_list($fID=>$f,$gID=>$g,@_);
  ANS($ans{$fID},$ans{$gID});
}

=head2 NAMED_COMPOSITION_ANS

 NAMED_COMPOSITION_ANS($fID=>$f, $gID=>$g, %options)

An answer checked to see if $f composed with $g matches a given function, where
$fID and $gID are the names of the answer rules for the functions $f and $g, and
$f and $g are the answers for the functions. %options are any of the options
allowed by composition_ans_list() below.

This routine allows you to put the answer blanks for $f and $g at any location
in the problem, and in any order.

Example:

 BEGIN_TEXT
 \(g\circ f = (1+x)^2\) when
 \(f(x)\) = \{NAMED_ANS('f',20)\} and \(g(x)\) = \{NAMED_ANS('g',20)\}
 END_TEXT
 NAMED_COMPOSITION_ANS(f => "x^2", g => "1+x");

=cut

sub NAMED_COMPOSITION_ANS {NAMED_ANS(composition_ans_list(@_))}

=head2 composition_ans_list

 composition_ans_list($fID=>$f, $gID=>$g, %options)

This is an internal routine that returns the named answer checkers
used by COMPOSITION_ANS and NAMED_COMPOSITION_ANS above.

$fID and $gID are the names of the answer rules for the functions and $f and $g
are the answers for these functions. %options are from among:

=over

=item S<C<< var => 'x' >>>

the name of the variable to use when
both functions use the same one

=item S<C<< vars => ['x','t'] >>>

the names of the variables for $f and $g

=item S<C<< showVariableHints => 1 or 0 >>>

do/don't show errors when the variable
used by the student is incorrect

=back

=cut

sub composition_ans_list {
  my ($fID,$f,$gID,$g,%params) = @_; my @IDs = ($fID,$gID);
  #
  #  Get options
  #
  $params{vars} = [$params{var},$params{var}] if $params{var} && !$params{vars};
  $params{showVariableHints} = 1 unless defined($params{showVariableHints});
  my $isPreview = $main::inputs_ref->{previewAnswers};
  my $vars = $params{vars} || [];
  my @options = (ignoreInfinity=>0,ignoreStrings=>0);
  my ($i,$error);

  #
  #  Get correct answer data and determine which variables to use
  #
  $f = Value->Package("Formula")->new($f); $g = Value->Package("Formula")->new($g);
  my %correct = ($fID => $f, $gID => $g);
  my %x = ($fID => $vars->[0], $gID => $vars->[1]);
  foreach $i (@IDs) {
    unless ($x{$i}) {
      die "Can't tell which variable to use for $correct{$i}: ".
             "use var=>'x' or vars=>['x','y'] to specify it"
	if scalar(keys %{$correct{$i}->{variables}}) > 1;
      $x{$i} = (keys %{$correct{$i}->{variables}})[0];
    }
    die "$correct{$i} is not a function of $x{$i}"
      unless defined($correct{$i}->{variables}{$x{$i}});
  }
  my %y = ($fID => $x{$gID}, $gID => $x{$fID});
  my %ans = ($fID => message_cmp($f), $gID => message_cmp($g));
  my $fog = $f->substitute($x{$fID}=>$g);  #  the composition

  #
  #  Check that the student formulas parse OK,
  #  produce a number, contain the correct variable,
  #  don't contain the composition itself in a simple way,
  #  and aren't the identity.
  #
  my %student = ($fID => $main::inputs_ref->{$fID},
		 $gID => $main::inputs_ref->{$gID});
  foreach $i (@IDs) {
    next unless defined($student{$i});
    $student{$i} = Parser::Formula($student{$i});
    if (!defined($student{$i})) {$error = 1; next}
    $ans{$i}->{rh_ans}{preview_latex_string} = $student{$i}->TeX;
    if ($student{$i}->type ne 'Number') {
      $ans{$i} = $correct{$i}->cmp(@options);
      $error = 1; next;
    }
    if ($x{$fID} ne $x{$gID} && defined($student{$i}->{variables}{$y{$i}})) {
      $ans{$i}->{rh_ans}{ans_message} = "Your formula may not contain $y{$i}"
	unless $isPreview || !$params{showVariableHints};
      $error = 1; next;
    }
    if (!defined($student{$i}->{variables}{$x{$i}})) {
      $ans{$i}->{rh_ans}{ans_message} = "Your formula is not a function of $x{$i}"
	unless $isPreview || !$params{showVariableHints};
      $error = 1; next;
    }
    if (($student{$i}->{tree}->class eq 'BOP' &&
	 ($fog == $student{$i}->{tree}{lop} || $fog == $student{$i}->{tree}{rop})) ||
	($student{$i}->{tree}->class eq 'UOP' && $fog == $student{$i}->{tree}{op})) {
      $ans{$i}->{rh_ans}{ans_message} =
        "Your formula may not have the composition as one of its terms";
      $error = 1; next;
    }
    if ($fog == $student{$i}) {
      $ans{$i}->{rh_ans}{ans_message} =
	"Your formula my not be the composition itself";
      $error = 1; next;
    }
    if (Parser::Formula($x{$i}) == $student{$i}) {
      $ans{$i}->{rh_ans}{ans_message} = "The identity function is not allowed"
	unless $isPreview;
      $error = 1; next;
    }

  }

  #
  #  If no error, and both answers are given, check if compositions are equal
  #
  if (!$error && defined($student{$fID}) && defined($student{$gID})) {
    if ($fog == $student{$fID}->substitute($x{$fID}=>$student{$gID})) {
      $ans{$fID}->{rh_ans}{score} = $ans{$gID}->{rh_ans}{score} = 1;
    }
  }

  return (%ans);
}

=head2 message_cmp

 message_cmp($correct)

Returns an answer evaluator that always returns incorrect, with a given error
message. Used by COMPOSITION_ANS to produce "dummy" answer checkers for the two
parts of the composition.

=cut

sub message_cmp {
  my $correct = shift;
  my $answerEvaluator = new AnswerEvaluator;
  $answerEvaluator->ans_hash(
     type => "message",
     correct_ans => $correct->string,
     ans_message => $message,
  );
  $answerEvaluator->install_evaluator(sub {shift});
  return $answerEvaluator;
}

1;

