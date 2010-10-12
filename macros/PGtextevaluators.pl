################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader$
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

PGtextevaluators.pl - Macros that generate answer evaluators that handle
questionnaires.

=head1 SYNOPSIS

	BEGIN_TEXT
	WeBWorK is great.
	\{ ans_radio_buttons(1=>"Agree",2=>"Disagree") \}
	$PAR
	If you disagree, why?
	\{ ans_rule() \}
	END_TEXT
	
	ANS(ansradio(1));
	ANS(anstext(2));
	
	# FIXME show how to make a grader that sends email here!

=head1 DESCRIPTION

This file contians macros for handling questionnaires. Questionnaires can
consist of textual answers and radio buttons, and responses are reported
via email.

=cut

BEGIN { be_strict() }

# Until we get the PG cacheing business sorted out, we need to use
# PG_restricted_eval to get the correct values for some(?) PG environment
# variables. We do this once here and place the values in lexicals for later
# access.
my $BR;
my $PAR;
my $QUESTIONNAIRE_ANSWERS;
my $rh_envir;
sub _PGtextevaluators_init {
	$BR                    = PG_restricted_eval(q/$BR/);
	$PAR                   = PG_restricted_eval(q/$PAR/);
	$QUESTIONNAIRE_ANSWERS = '';
	$rh_envir              = PG_restricted_eval(q/\%envir/);
}

=head1 ANSWER EVALUATORS

=cut

# these	next three subroutines show how to modify	the	"store_ans_at()" answer
# evaluator	to add extra information before	storing	the	info
# They provide a good model	for	how	to tweak answer	evaluators in special cases.

=head2 anstext

	ANS(anstext($num))

anstext() returns an answer evaluator which records the student's answer to a
free-response question in the variable $QUESTIONNAIRE_ANSWERS for later
retrieval. A header is added to the answer before it is added. The header format
is:

	"\n${setNumber}_${courseName}_$psvn-Problem-$probNum-Question-$num:\n"

Where $num is the argument passed to anstext().

To send the accumulated answers to the instructor via email, use
mail_answers_to2().

=cut

sub anstext {
	my $num	= shift;
	my $ans_eval_template =	store_ans_at(\$QUESTIONNAIRE_ANSWERS);
	my $psvn  = PG_restricted_eval(q!$main::psvn!);
	my $probNum     = PG_restricted_eval(q!$main::probNum!);
	my $courseName  = PG_restricted_eval(q!$main::courseName!);
	my $setNumber     = PG_restricted_eval(q!$main::setNumber!);
	
	my $ans_eval    = sub {
				 my	$text =	shift;
				 $text = ''	unless defined($text);
				 my	$new_text =	"\n${setNumber}_${courseName}_$psvn-Problem-$probNum-Question-$num:\n $text "; #	modify entered text
				 my	$out = &$ans_eval_template($new_text);			 # standard	evaluator
				 #warn "$QUESTIONNAIRE_ANSWERS";
				 $out->{student_ans} = escapeHTML($text);  #	restore	original entered text
				 $out->{correct_ans} = "Question  $num answered";
				 $out->{original_student_ans} = escapeHTML($text);
				 $out;
   	};
   $ans_eval;
}

=head2 anstext

	ANS(anstext_non_anonymous($num))

anstext_non_anonymous() works like anstext(), except that the header added to the
student's answer includes personally identifying information:

	\n$psvn-Problem-$probNum-Question-$num:\n
	$studentLogin $studentID $studentName\n

Where $num is the argument passed to anstext_non_anonymous().

=cut

sub anstext_non_anonymous {
	## this emails identifying information
	my $num	         = shift;
    my $psvn   = PG_restricted_eval(q!$main::psvn!);
	my $probNum      = PG_restricted_eval(q!$main::probNum!);
    my $studentLogin = PG_restricted_eval(q!$main::studentLogin!);
	my $studentID    = PG_restricted_eval(q!$main::studentID!);
    my $studentName  = PG_restricted_eval(q!$main::studentName!);


	my $ans_eval_template =	store_ans_at(\$QUESTIONNAIRE_ANSWERS);
	my $ans_eval = sub {
				 my	$text =	shift;
				 $text = ''	unless defined($text);
				 my	$new_text =	"\n$psvn-Problem-$probNum-Question-$num:\n$studentLogin $main::studentID $studentName\n$text "; #	modify entered text
				 my	$out = &$ans_eval_template($new_text);			 # standard	evaluator
				 #warn "$QUESTIONNAIRE_ANSWERS";
				 $out->{student_ans} = escapeHTML($text);  #	restore	original entered text
				 $out->{correct_ans} = "Question  $num answered";
				 $out->{original_student_ans} = escapeHTML($text);
				 $out;
   	};
   $ans_eval;
}

=head2 ansradio

	ANS(ansradio($num))

ansradio() returns an answer evaluator which records the student's answer to a
multiple-choice question in the variable $QUESTIONNAIRE_ANSWERS for later
retrieval. A header is added to the answer before it is added. The header format
is:

	"\n$psvn-Problem-$probNum-RADIO-$num:\n"

Where $num is the question number passed to ansradio().

To send the accumulated answers to the instructor via email, use
mail_answers_to2().

=cut

sub ansradio {
	my $num	= shift;
	my $psvn  = PG_restricted_eval(q!$main::psvn!);
	my $probNum  = PG_restricted_eval(q!$main::probNum!);

	my $ans_eval_template =	store_ans_at(\$QUESTIONNAIRE_ANSWERS);
	my $ans_eval = sub {
				 my	$text =	shift;
				 $text = ''	unless defined($text);
				 my	$new_text =	"\n$psvn-Problem-$probNum-RADIO-$num:\n $text	";		   # modify	entered	text
				 my	$out = $ans_eval_template->($new_text);			  #	standard evaluator
				 $out->{student_ans} =escapeHTML($text);  #	restore	original entered text
				 $out->{original_student_ans} = escapeHTML($text);
				 $out;
	 };

   $ans_eval;
}

=head2 store_ans_at

	$answer = "";
	ANS(store_ans_at(\$answer));
	TEXT("Stored answer: '$answer');

Generates an answer evaluator which appends the student's answer to a scalar
variable. In addition, the score for the answer is always set to 1. This macro
is used internally by anstext(), anstest_non_anonymous(), and ans_radio().

=cut

sub store_ans_at {
	my $answerStringRef	= shift;
	my %options	= @_;
	my $ans_eval= '';
	if ( ref($answerStringRef) eq 'SCALAR' ) {
		$ans_eval= sub {
			my $text = shift;
			$text =	'' unless defined($text);
			$$answerStringRef =	$$answerStringRef  . $text;
			my $ans_hash = new AnswerHash(
							 'score'			=>	1,
							 'correct_ans'			=>	'',
							 'student_ans'			=>	$text,
							 'ans_message'			=>	'',
							 'type'				=>	'store_ans_at',
							 'original_student_ans'		=>	$text,
							 'preview_text_string'		=>	''
			);

		return $ans_hash;
		};
	}
	else {
		die	"Syntax	error: \n The argument to store_ans_at() must be a pointer to a	scalar.\n(e.g.	store_ans_at(~~\$MSG) )\n\n";
	}

	return $ans_eval;
}

=head2 [DEPRECATED] mail_answers_to

	ANS(mail_answers_to($to_address))

Returns an answer evaluator which accepts the last answer and then mails the
answer to $to_address. It is unsupported and may not even work.

Use a normal textans() answer evaluator and mail_answers_to2() instead.

=cut

#  This	is another example of how to modify	an	answer evaluator to	obtain
#  the desired behavior	in a special case.	Here the object	is to have
#  have	the	last answer	trigger	the	send_mail_to subroutine	which mails
#  all of the answers to the designated	address.
#  (This address must be listed	in PG_environment{'ALLOW_MAIL_TO'} or an error occurs.)

# Fix me?? why is the body hard wired to the string QUESTIONNAIRE_ANSWERS?

sub mail_answers_to {  #accepts	the	last answer	and	mails off the result
	my $user_address = shift;
	my $ans_eval = sub {

		# then mail out	all of the answers, including this last one.

		# this is the old mechanism for sending mail (via IO.pl)
		#send_mail_to(	$user_address,
		#			'subject'		    =>	"$main::courseName WeBWorK questionnaire",
		#			'body'			    =>	$QUESTIONNAIRE_ANSWERS,
		#			'ALLOW_MAIL_TO'		=>	$rh_envir->{ALLOW_MAIL_TO}
		#);
		
		# DelayedMailer is the new method (for now)
		$rh_envir->{mailer}->add_message(
			to => $user_address,
			subject => "$main::courseName WeBWorK questionnaire",
			msg => $QUESTIONNAIRE_ANSWERS,
		);

		my $ans_hash = new AnswerHash(	'score'		=>	1,
						'correct_ans'	=>	'',
						'student_ans'	=>	'Answer	recorded',
						'ans_message'	=>	'',
						'type'		=>	'send_mail_to',
		);

		return $ans_hash;
	};

	return $ans_eval; 
}

=head2 [DEPRECATED] save_answer_to_file

Returns an answer evaluator which accepts the last answer and then stores the
answer to a file. It is unsupported and may not even work.

=cut

sub save_answer_to_file {  #accepts	the	last answer	and	mails off the result
	my $fileID = shift;
	my $ans_eval = new AnswerEvaluator;
	$ans_eval->install_evaluator(
			sub {
				 my $rh_ans = shift;

       		 	 unless ( defined( $rh_ans->{student_ans} ) ) {
        			$rh_ans->throw_error("save_answers_to_file","{student_ans} field not defined");
        			return $rh_ans;
       			}

				my $error;
				my $string = '';
				$string = qq![[<$main::studentLogin> $main::studentName /!. time() . qq!/]]\n!.
					$rh_ans->{student_ans}. qq!\n\n============================\n\n!;

				if ($error = AnswerIO::saveAnswerToFile('preflight',$string) ) {
					$rh_ans->throw_error("save_answers_to_file","Error:  $error");
				} else {
					$rh_ans->{'student_ans'} = 'Answer saved';
					$rh_ans->{'score'} = 1;
				}
				$rh_ans;
			}
	);

	return $ans_eval;
}

=head1 OTHER MACROS

=head2 mail_answers_to2

	mail_answers_to2($to, $subject);

Sends the text accumulated in $QUESTIONNAIRE_ANSWERS to the address specified in
$to. The email is given the subject line $subject.

The mail message is not sent right away; instead, the message is recorded and
sent by WeBWorK after PG rendering has completed. 

=cut

sub mail_answers_to2 {
	my ($to, $subject, $ra_allow_mail_to) = @_;
	
	$subject = "$main::courseName WeBWorK questionnaire" unless defined $subject;
	warn "The third argument (ra_allow_mail_to) to mail_answers_to2() is ignored. The list of allowed addresses is fixed."
		if defined $ra_allow_mail_to;
	
	$rh_envir->{mailer}->add_message(
		to => $to,
		subject => $subject,
		msg => $QUESTIONNAIRE_ANSWERS,
	);
	
	return;
}

=head2 escapeHTML

	escapeHTML($string)

The misnamed macro returns a copy of $string in which each newline has been replaced with
an HTML BR element.

=cut

sub escapeHTML {
	my $string = shift;
	$string	=~ s/\n/$BR/ge;
	$string;
}

=head2 [DEPRECATED] save_questionnaire_answers_to

=cut

sub save_questionnaire_answers_to {
	my $fileName =shift;
	SaveFile::printAnswerFile($fileName,[$QUESTIONNAIRE_ANSWERS]);
}

#### subroutines used in producing a questionnaire
#### these are at least	good models	for	other answers of this type

# my $QUESTIONNAIRE_ANSWERS='';	#  stores the answers until	it is time to send them
		   #  this must	be initialized before the answer evaluators	are	run
		   #  but that happens long	after all of the text in the problem is
		   #  evaluated.
# this is a	utility	script for cleaning	up the answer output for display in
#the answers.

=head2 [DEPRECATED] DUMMY_ANSWER

=cut

sub DUMMY_ANSWER {
	my $num	= shift;
	qq{<INPUT TYPE="HIDDEN"	NAME="answer$num" VALUE="">}
}

=head1 SEE ALSO

L<PGanswermacros.pl>, L<MathObjects>.

=cut

1;
